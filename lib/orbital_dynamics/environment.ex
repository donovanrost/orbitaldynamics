defmodule OrbitalDynamics.Environment do
  @moduledoc """
  Environment-model capability records.

  These records are intentionally declarative. They describe simplified models
  used by the current analysis pipeline without claiming to provide external
  ephemerides, Earth orientation parameters, or atmosphere data.
  """

  alias OrbitalDynamics.AccessGeometry

  alias OrbitalDynamics.Environment.{
    ConstantEarthRotationProvider,
    ExponentialAtmosphereProvider,
    FixedSunProvider,
    Provider,
    TabularEarthOrientationProvider
  }

  @fixed_sun_id "environment.solar.fixed_inertial_direction"
  @constant_earth_rotation_id "environment.earth_rotation.constant_rate"

  @doc """
  Returns internal environment provider capability records.
  """
  def provider_capabilities do
    [
      FixedSunProvider.capabilities(),
      ConstantEarthRotationProvider.capabilities(),
      TabularEarthOrientationProvider.capabilities(),
      ExponentialAtmosphereProvider.capabilities()
    ]
  end

  @doc """
  Returns a provider capability record for a configured provider adapter.
  """
  def configured_provider_capability(provider, opts \\ [])

  def configured_provider_capability({provider, opts}, _opts) when is_atom(provider) do
    configured_provider_capability(provider, opts)
  end

  def configured_provider_capability(provider, opts) when is_atom(provider) and is_list(opts) do
    with true <- Code.ensure_loaded?(provider),
         true <- function_exported?(provider, :capabilities, 0) do
      configured_capability =
        if function_exported?(provider, :configured_capability, 1) do
          provider.configured_capability(opts)
        else
          {:ok, provider.capabilities()}
        end

      with {:ok, capability} <- configured_capability,
           :ok <- validate_provider_capability(capability) do
        {:ok, capability}
      end
    else
      _error -> {:error, {:invalid_option, :environment_provider}}
    end
  end

  def configured_provider_capability(_provider, _opts),
    do: {:error, {:invalid_option, :environment_provider}}

  @doc """
  Verifies and consumes a file-backed tabular Earth-orientation provider input.

  The caller must supply an explicit SHA-256 content identity. Verification is
  opt-in and does not change the existing inline `samples` provider path.
  """
  def fetch_tabular_earth_orientation_from_file(path, content_identity, opts \\ []) do
    TabularEarthOrientationProvider.fetch_from_file(
      :earth_rotation,
      path,
      content_identity,
      opts
    )
  end

  @doc """
  Returns true when a configured provider adapter supports a request.
  """
  def configured_provider_supports_request?(provider, request, opts \\ [])

  def configured_provider_supports_request?(provider, request, opts) when is_map(request) do
    case configured_provider_capability(provider, opts) do
      {:ok, capability} -> provider_supports_request?(capability, request)
      {:error, _reason} -> false
    end
  end

  def configured_provider_supports_request?(_provider, _request, _opts), do: false

  @doc """
  Returns the built-in environment-model capability records.
  """
  def model_capabilities do
    [
      fixed_sun_direction(),
      constant_earth_rotation()
    ]
  end

  @doc """
  Validates an environment provider capability record.
  """
  def validate_provider_capability(record) do
    with :ok <- Provider.validate_capability(record) do
      validate_known_provider_limits(record)
    end
  end

  @doc """
  Returns true when a provider capability covers a requested time span.
  """
  def provider_covers_time_span?(record, request), do: Provider.covers_time_span?(record, request)

  @doc """
  Returns true when a provider capability covers a requested time span, body, and output.
  """
  def provider_supports_request?(record, request), do: Provider.supports_request?(record, request)

  @doc """
  Returns internal provider capability records that support a requested time span, body, and output.
  """
  def provider_capabilities_for_request(request) when is_map(request) do
    provider_capabilities()
    |> Enum.filter(&provider_supports_request?(&1, request))
  end

  def provider_capabilities_for_request(_request), do: []

  @doc """
  Returns environment-model records implied by a result set.
  """
  def records_for_result_set(%{assumptions: assumptions}) when is_map(assumptions) do
    records_for_assumptions(assumptions)
  end

  def records_for_result_set(%{"assumptions" => assumptions}) when is_map(assumptions) do
    records_for_assumptions(assumptions)
  end

  @doc """
  Returns environment-model records implied by study assumptions.
  """
  def records_for_assumptions(%{} = assumptions) do
    outputs = Map.get(assumptions, :outputs) || Map.get(assumptions, "outputs") || []

    campaign_environment =
      Map.get(assumptions, :campaign_environment) ||
        Map.get(assumptions, "campaign_environment")

    if is_map(campaign_environment) do
      campaign_environment_records(outputs, assumptions, campaign_environment)
    else
      []
      |> maybe_add_fixed_sun(outputs, assumptions)
      |> maybe_add_constant_earth_rotation(outputs, assumptions)
      |> Enum.reverse()
    end
  end

  @doc """
  Describes the fixed inertial Sun-direction model used by eclipse detection.
  """
  def fixed_sun_direction(direction \\ {1.0, 0.0, 0.0}, opts \\ []) do
    %{
      "id" => @fixed_sun_id,
      "schema_contract" => "environment_model_capability.v1",
      "category" => "solar_direction",
      "model" => "fixed_inertial_solar_direction",
      "source" => Keyword.get(opts, :source, "study_runner_option"),
      "validation_level" => "assumption_declared",
      "coordinate_frame" => "eci_j2000_inertial",
      "interpolation" => "constant",
      "time_span" => "study_horizon",
      "supported_bodies" => ["earth"],
      "network_access" => false,
      "parameters" => %{
        "sun_direction" => encode_direction(direction)
      },
      "known_limits" => [
        "not an ephemeris provider",
        "no Sun range or light-time correction",
        "no time-varying apparent solar direction"
      ]
    }
  end

  @doc """
  Describes the constant Earth-rotation model used by surface geometry.
  """
  def constant_earth_rotation(opts \\ []) do
    assumptions = AccessGeometry.assumptions()

    %{
      "id" => @constant_earth_rotation_id,
      "schema_contract" => "environment_model_capability.v1",
      "category" => "body_rotation",
      "model" => "constant_earth_rotation",
      "source" => Keyword.get(opts, :source, "internal_simplified_geometry"),
      "validation_level" => "assumption_declared",
      "coordinate_frame" => "earth_body_fixed_to_eci_j2000_approximation",
      "interpolation" => "analytic_constant_rate",
      "time_span" => "study_horizon",
      "supported_bodies" => ["earth"],
      "network_access" => false,
      "parameters" => %{
        "earth_rotation_rate_rad_s" => Map.fetch!(assumptions, :earth_rotation_rate_rad_s),
        "geometry_model" => Atom.to_string(Map.fetch!(assumptions, :geometry_model))
      },
      "known_limits" => [
        "no Earth orientation parameters",
        "no UT1 or polar-motion correction",
        "spherical surface geometry"
      ]
    }
  end

  @doc """
  Validates the minimal record shape expected by result artifacts.
  """
  def validate_capability(%{} = record) do
    required = [
      "id",
      "schema_contract",
      "category",
      "model",
      "source",
      "validation_level",
      "time_span",
      "supported_bodies",
      "network_access",
      "parameters",
      "known_limits"
    ]

    missing = Enum.reject(required, &Map.has_key?(record, &1))

    cond do
      missing != [] ->
        {:error, {:missing_keys, missing}}

      record["schema_contract"] != "environment_model_capability.v1" ->
        {:error, {:invalid_field, "schema_contract"}}

      not is_list(record["supported_bodies"]) ->
        {:error, {:invalid_field, "supported_bodies"}}

      not string_list?(record["supported_bodies"]) ->
        {:error, {:invalid_field, "supported_bodies"}}

      not is_boolean(record["network_access"]) ->
        {:error, {:invalid_field, "network_access"}}

      record["network_access"] == true and not trust_boundary_declared?(record) ->
        {:error, {:missing_trust_boundary, "network_access"}}

      not is_map(record["parameters"]) ->
        {:error, {:invalid_field, "parameters"}}

      not is_list(record["known_limits"]) ->
        {:error, {:invalid_field, "known_limits"}}

      not string_list?(record["known_limits"]) ->
        {:error, {:invalid_field, "known_limits"}}

      known_model_limits_drift?(record) ->
        {:error, {:invalid_field, "known_limits"}}

      true ->
        :ok
    end
  end

  def validate_capability(_record), do: {:error, :invalid_record}

  defp string_list?(values), do: Enum.all?(values, &is_binary/1)

  defp known_model_limits_drift?(record) do
    case known_model_limits(record) do
      nil -> false
      expected -> normalize_limits(record["known_limits"]) != normalize_limits(expected)
    end
  end

  defp known_model_limits(%{"id" => id}) do
    model_capabilities()
    |> Enum.find(&(&1["id"] == id))
    |> case do
      %{"known_limits" => limits} -> limits
      _record -> nil
    end
  end

  defp known_model_limits(_record), do: nil

  defp validate_known_provider_limits(%{} = record) do
    case known_provider_limits(record) do
      nil ->
        :ok

      expected ->
        if normalize_limits(record["known_limits"]) == normalize_limits(expected) do
          :ok
        else
          {:error, {:invalid_field, "known_limits"}}
        end
    end
  end

  defp known_provider_limits(%{"id" => id}) do
    provider_capabilities()
    |> Enum.find(&(&1["id"] == id))
    |> case do
      %{"known_limits" => limits} -> limits
      _record -> nil
    end
  end

  defp known_provider_limits(_record), do: nil

  defp normalize_limits(limits) when is_list(limits), do: limits |> Enum.uniq() |> Enum.sort()

  defp trust_boundary_declared?(record) do
    case Map.get(record, "trust_boundary") || get_in(record, ["provenance", "trust_boundary"]) do
      value when is_binary(value) and value != "" -> true
      _value -> false
    end
  end

  defp maybe_add_fixed_sun(records, outputs, assumptions) do
    if output?(outputs, :eclipses) do
      direction = Map.get(assumptions, :sun_direction) || Map.get(assumptions, "sun_direction")
      [fixed_sun_direction(direction || {1.0, 0.0, 0.0}) | records]
    else
      records
    end
  end

  defp campaign_environment_records(outputs, assumptions, provenance) do
    []
    |> maybe_add_campaign_sun(outputs, provenance)
    |> maybe_add_campaign_earth_rotation(outputs, assumptions, provenance)
    |> Enum.reverse()
  end

  defp maybe_add_campaign_sun(records, outputs, provenance) do
    if output?(outputs, :eclipses) do
      [campaign_environment_model(:solar_direction, provenance) | records]
    else
      records
    end
  end

  defp maybe_add_campaign_earth_rotation(records, outputs, assumptions, provenance) do
    if body_fixed_ground_track?(outputs, assumptions) do
      [campaign_environment_model(:earth_rotation, provenance) | records]
    else
      records
    end
  end

  defp campaign_environment_model(:solar_direction, provenance) do
    %{
      "id" => "environment.solar.campaign_tabular_geocentric_direction",
      "schema_contract" => "environment_model_capability.v1",
      "category" => "solar_direction",
      "model" => "tabular_geocentric_geometric_sun_direction",
      "source" => provenance_value(provenance, "source_table_id"),
      "validation_level" => "analysis",
      "coordinate_frame" => provenance_value(provenance, "provider_inertial_frame"),
      "interpolation" => provenance_value(provenance, "interpolation"),
      "time_span" => campaign_time_span(provenance),
      "supported_bodies" => [provenance_value(provenance, "body")],
      "network_access" => false,
      "parameters" => campaign_environment_parameters(provenance),
      "known_limits" => provenance_value(provenance, "known_limits")
    }
  end

  defp campaign_environment_model(:earth_rotation, provenance) do
    %{
      "id" => "environment.earth_rotation.campaign_era_from_eci_j2000_approximation",
      "schema_contract" => "environment_model_capability.v1",
      "category" => "body_rotation",
      "model" => "earth_fixed_era_from_eci_j2000_approximation",
      "source" => provenance_value(provenance, "source_table_id"),
      "validation_level" => "analysis",
      "coordinate_frame" => provenance_value(provenance, "earth_fixed_frame"),
      "interpolation" => provenance_value(provenance, "interpolation"),
      "time_span" => campaign_time_span(provenance),
      "supported_bodies" => [provenance_value(provenance, "body")],
      "network_access" => false,
      "parameters" =>
        campaign_environment_parameters(provenance)
        |> Map.put("polar_motion_applied", false),
      "known_limits" => provenance_value(provenance, "known_limits")
    }
  end

  defp campaign_environment_parameters(provenance) do
    %{
      "provider_id" => provenance_value(provenance, "provider_id"),
      "provider_revision" => provenance_value(provenance, "provider_revision"),
      "dataset_revision" => provenance_value(provenance, "dataset_revision"),
      "dataset_semantic_sha256" => provenance_value(provenance, "dataset_semantic_sha256"),
      "content_sha256" => provenance_value(provenance, "content_sha256"),
      "coverage" => provenance_value(provenance, "coverage"),
      "sample_count" => provenance_value(provenance, "sample_count")
    }
  end

  defp campaign_time_span(provenance) do
    coverage = provenance_value(provenance, "coverage")

    "#{provenance_value(coverage, "starts_at_s")}..#{provenance_value(coverage, "ends_at_s")} seconds_since_j2000"
  end

  defp provenance_value(map, key) do
    Map.get(map, key) || Map.get(map, String.to_existing_atom(key))
  rescue
    ArgumentError -> Map.get(map, key)
  end

  defp maybe_add_constant_earth_rotation(records, outputs, assumptions) do
    if output?(outputs, :access_windows) or output?(outputs, :target_visibility) or
         body_fixed_ground_track?(outputs, assumptions) do
      [constant_earth_rotation() | records]
    else
      records
    end
  end

  defp body_fixed_ground_track?(outputs, assumptions) do
    output?(outputs, :ground_track_crossings) and
      (ground_track_crossings_unknown?(assumptions) or
         assumptions
         |> ground_track_crossings()
         |> Enum.any?(&body_fixed_ground_track_request?/1))
  end

  defp ground_track_crossings_unknown?(assumptions) do
    not Map.has_key?(assumptions, :ground_track_crossings) and
      not Map.has_key?(assumptions, "ground_track_crossings")
  end

  defp ground_track_crossings(assumptions) do
    Map.get(assumptions, :ground_track_crossings) ||
      Map.get(assumptions, "ground_track_crossings") ||
      []
  end

  defp body_fixed_ground_track_request?(%{frame: :body_fixed}), do: true
  defp body_fixed_ground_track_request?(%{"frame" => "body_fixed"}), do: true
  defp body_fixed_ground_track_request?(_request), do: false

  defp output?(outputs, output) when is_list(outputs) do
    output in outputs or Atom.to_string(output) in outputs
  end

  defp output?(_outputs, _output), do: false

  defp encode_direction({x, y, z}), do: [x, y, z]
  defp encode_direction([_x, _y, _z] = direction), do: direction
  defp encode_direction(direction), do: direction
end
