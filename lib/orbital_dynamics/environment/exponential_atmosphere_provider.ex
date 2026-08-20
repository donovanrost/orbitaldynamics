defmodule OrbitalDynamics.Environment.ExponentialAtmosphereProvider do
  @moduledoc """
  Internal single-scale-height atmosphere density provider.

  This adapter is an interface and provenance boundary for drag work. It returns
  a deterministic reference density at a requested altitude. The atmospheric-
  drag evaluator and opt-in scalar two-body-drag and J2-drag propagators consume it.
  """

  @behaviour OrbitalDynamics.Environment.Provider

  @reference_altitude_km 400.0
  @reference_density_kg_m3 3.89e-12
  @scale_height_km 60.0

  @impl OrbitalDynamics.Environment.Provider
  def capabilities do
    %{
      "id" => "environment.provider.atmosphere.exponential_reference",
      "schema_contract" => "environment_provider_capability.v1",
      "category" => "atmosphere_density",
      "model" => "single_scale_height_exponential_atmosphere",
      "source" => "internal_reference_model",
      "validation_level" => "assumption_declared",
      "coverage" => %{
        "starts_at_s" => nil,
        "ends_at_s" => nil,
        "time_scale" => "seconds_since_j2000",
        "coverage_policy" => "all_times"
      },
      "interpolation" => "analytic_single_scale_height",
      "supported_bodies" => ["earth"],
      "network_access" => false,
      "outputs" => ["density_kg_m3", "altitude_km"],
      "parameters" => %{
        "reference_altitude_km" => @reference_altitude_km,
        "reference_density_kg_m3" => @reference_density_kg_m3,
        "scale_height_km" => @scale_height_km
      },
      "known_limits" => [
        "reference atmosphere only",
        "not calibrated to space weather or epoch",
        "consumed only by opt-in scalar two-body-drag and J2-drag propagation"
      ]
    }
  end

  @doc false
  def configured_capability(opts) when is_list(opts) do
    if Keyword.keyword?(opts) do
      configured_capability_for_keyword(opts)
    else
      {:error, {:invalid_option, :atmosphere_provider}}
    end
  end

  def configured_capability(_opts), do: {:error, {:invalid_option, :atmosphere_provider}}

  defp configured_capability_for_keyword(opts) do
    reference_altitude_km =
      Keyword.get(opts, :reference_altitude_km, @reference_altitude_km)

    reference_density_kg_m3 =
      Keyword.get(opts, :reference_density_kg_m3, @reference_density_kg_m3)

    scale_height_km = Keyword.get(opts, :scale_height_km, @scale_height_km)

    with :ok <- validate_number(:reference_altitude_km, reference_altitude_km),
         :ok <- validate_non_negative(:reference_density_kg_m3, reference_density_kg_m3),
         :ok <- validate_positive(:scale_height_km, scale_height_km) do
      {:ok,
       put_in(capabilities(), ["parameters"], %{
         "reference_altitude_km" => reference_altitude_km * 1.0,
         "reference_density_kg_m3" => reference_density_kg_m3 * 1.0,
         "scale_height_km" => scale_height_km * 1.0
       })}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def fetch(kind, opts \\ [])

  @impl OrbitalDynamics.Environment.Provider
  def fetch(:atmosphere_density, opts) do
    altitude_km = Keyword.get(opts, :altitude_km)
    reference_altitude_km = Keyword.get(opts, :reference_altitude_km, @reference_altitude_km)

    reference_density_kg_m3 =
      Keyword.get(opts, :reference_density_kg_m3, @reference_density_kg_m3)

    scale_height_km = Keyword.get(opts, :scale_height_km, @scale_height_km)

    with :ok <- validate_number(:altitude_km, altitude_km),
         :ok <- validate_number(:reference_altitude_km, reference_altitude_km),
         :ok <- validate_non_negative(:reference_density_kg_m3, reference_density_kg_m3),
         :ok <- validate_positive(:scale_height_km, scale_height_km) do
      density =
        reference_density_kg_m3 *
          :math.exp(-(altitude_km - reference_altitude_km) / scale_height_km)

      {:ok,
       %{
         "provider_id" => capabilities()["id"],
         "model" => "single_scale_height_exponential_atmosphere",
         "altitude_km" => altitude_km * 1.0,
         "density_kg_m3" => density,
         "reference_altitude_km" => reference_altitude_km * 1.0,
         "reference_density_kg_m3" => reference_density_kg_m3 * 1.0,
         "scale_height_km" => scale_height_km * 1.0,
         "force_model_status" => "consumed_by_opt_in_two_body_drag_and_j2_drag_propagators"
       }}
    end
  end

  def fetch(kind, _opts), do: {:error, {:unsupported_environment_product, kind}}

  defp validate_number(_field, value) when is_number(value), do: :ok
  defp validate_number(field, _value), do: {:error, {:invalid_option, field}}

  defp validate_non_negative(_field, value) when is_number(value) and value >= 0.0, do: :ok
  defp validate_non_negative(field, _value), do: {:error, {:invalid_option, field}}

  defp validate_positive(_field, value) when is_number(value) and value > 0.0, do: :ok
  defp validate_positive(field, _value), do: {:error, {:invalid_option, field}}
end
