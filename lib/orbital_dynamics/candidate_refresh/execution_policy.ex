defmodule OrbitalDynamics.CandidateRefresh.ExecutionPolicy do
  @moduledoc """
  Immutable policy for the opt-in executable candidate-refresh bundle.

  The policy is captured from explicit spacecraft, station, state, and horizon
  inputs plus fixed built-in module capabilities. The resulting document is
  JSON-serializable and carries a canonical SHA-256 fingerprint. Callers never
  select a module dynamically; the executable runner calls the allowlisted
  modules directly.
  """

  alias OrbitalDynamics.Environment

  alias OrbitalDynamics.Environment.{
    ConstantEarthRotationProvider,
    ExponentialAtmosphereProvider
  }

  alias OrbitalDynamics.EventDetectors.{AccessWindows, Eclipses}
  alias OrbitalDynamics.Propagators.J2Drag
  alias OrbitalDynamics.{AccessGeometry, CentralBody, Vector3}

  @bundle_id "candidate_refresh.earth_j2_drag_access_eclipse.v1"
  @schema_contract "candidate_refresh_execution_policy.v1"
  @execution_mode "offline_deterministic"
  @reserved_key "candidate_refresh_execution_policy"
  @external_case_id "orekit_13_1_7_leo_j2_drag_access_eclipse"
  @output_step_s 10.0
  @max_step_s 10.0
  @root_tolerance_s 1.0e-6
  @root_max_iterations 64

  @atmosphere_revision "exponential-reference.v1"
  @earth_rotation_revision "constant-earth-rotation.v1"
  @sun_revision "fixed-sun-plus-x.v1"
  @propagator_revision "j2-drag-rk4-10s.v1"
  @access_revision "access-windows-bracketed-bisection-1e-6-64.v1"
  @eclipse_revision "eclipses-cylindrical-linear-interpolation.v1"

  @atmosphere_capability ExponentialAtmosphereProvider.capabilities()
  @earth_rotation_capability ConstantEarthRotationProvider.capabilities()
  @fixed_sun_capability Environment.fixed_sun_direction(
                          {1.0, 0.0, 0.0},
                          source: "candidate_refresh_execution_policy"
                        )
  @propagator_capability J2Drag.capabilities()
  @access_capability AccessWindows.capabilities()
  @eclipse_capability Eclipses.capabilities()
  @access_geometry AccessGeometry.assumptions()
  @central_body CentralBody.earth()
  @state_numeric_envelope @propagator_capability.supported_numeric_envelope.state
  @spacecraft_numeric_envelope @propagator_capability.supported_numeric_envelope.spacecraft
  @duration_envelope @propagator_capability.duration_envelope_s
  @initial_altitude_envelope @propagator_capability.initial_altitude_envelope_km

  @module_allowlist [
    "OrbitalDynamics.Propagators.J2Drag",
    "OrbitalDynamics.Environment.ExponentialAtmosphereProvider",
    "OrbitalDynamics.Environment.ConstantEarthRotationProvider",
    "OrbitalDynamics.EventDetectors.AccessWindows",
    "OrbitalDynamics.EventDetectors.Eclipses"
  ]

  @model_limits [
    "single_spacecraft_single_station_exact_bundle_only",
    "earth_eci_j2000_tdb_only",
    "positive_horizon_at_most_24_hours",
    "ten_second_output_cadence_and_fixed_rk4_step",
    "fixed_ballistic_properties_for_full_horizon",
    "built_in_offline_environment_providers_only",
    "constant_earth_rotation_and_fixed_plus_x_sun",
    "spherical_access_without_terrain_or_refraction",
    "access_roots_bounded_on_interpolated_state_only",
    "cylindrical_eclipse_without_penumbra",
    "access_only_candidate_generation_eclipse_archive_only",
    "external_validation_applies_to_exact_case_only",
    "no_network_config_source_or_campaign_provider_rereads_after_capture",
    "not_flight_certified"
  ]

  @request_top_level_keys ~w(
    access
    access_detector
    access_source_revision
    atmosphere_provider
    atmosphere_source_revision
    bundle
    bundle_id
    campaign_environment
    central_body
    coverage
    eclipse
    eclipse_detector
    eclipse_source_revision
    environment
    earth_rotation_provider
    earth_rotation_source_revision
    execution_bundle
    execution_bundle_id
    execution_mode
    ground_station
    initial_state
    model_limits
    module_allowlist
    network_access
    policies
    policy_fingerprint
    propagation
    propagator
    propagator_source_revision
    provider_capabilities
    provider_coverage
    provider_revisions
    schema_contract
    spacecraft
    sun_direction_provider
    sun_direction_source_revision
  )

  @spacecraft_keys ~w(
    area_m2
    drag_area_m2
    drag_coefficient
    dry_mass_kg
    id
    mass_kg
    propellant_mass_kg
    scenario_id
    spacecraft_id
    total_mass_kg
  )

  @station_keys ~w(
    altitude_km
    ground_station_id
    id
    latitude_deg
    longitude_deg
    minimum_elevation_deg
    station_id
  )

  @initial_state_keys ~w(
    body
    epoch_s
    frame
    position_km
    scenario_id
    snapshot_id
    spacecraft_id
    time_scale
    velocity_km_s
  )

  @coverage_keys ~w(ends_at_s output_step_s starts_at_s)

  @enforce_keys [:document]
  defstruct [:document]

  @type t :: %__MODULE__{document: map()}

  @doc "Returns the only executable bundle supported by this runner."
  def bundle_id, do: @bundle_id

  @doc "Returns the reserved model-assumptions key used to bind refresh identity."
  def reserved_key, do: @reserved_key

  @doc "Returns the fixed offline execution mode."
  def execution_mode, do: @execution_mode

  @doc "Returns the Domain 18 external-truth case referenced by the bundle."
  def external_case_id, do: @external_case_id

  @doc "Returns the executable bundle's declared limits."
  def model_limits, do: @model_limits

  @doc """
  Losslessly normalizes one public JSON-shaped input.

  Plain maps may use atom or UTF-8 binary keys, but two keys that normalize to
  the same JSON key are rejected before a normalized map is constructed.
  Values are limited to JSON-safe scalars, proper lists, and plain maps.
  """
  def normalize_json_input(value), do: normalize_public_value(value, "$")

  @doc false
  def canonical_sort_key(value) do
    case normalize_json_input(value) do
      {:ok, normalized} -> normalized |> canonical_term() |> :erlang.term_to_binary()
      {:error, _reason} -> raise ArgumentError, "invalid canonical input"
    end
  end

  @doc """
  Validates and normalizes the caller-controlled portion of a policy request.

  This phase does not read module capabilities. It is used by the runner before
  capture so input and selection errors are reported at the validation stage.
  """
  def validate_request(input) do
    with {:ok, map} <- input_map(input),
         :ok <- reject_unknown_keys(map, @request_top_level_keys, :execution_policy),
         :ok <- validate_fixed_module_assertions(map),
         :ok <- validate_network_assertion(map),
         :ok <- reject_campaign_provider(map),
         {:ok, bundle_id} <-
           alias_value(
             map,
             ~w(bundle bundle_id execution_bundle execution_bundle_id),
             @bundle_id,
             :bundle_id
           ),
         :ok <- require_equal(bundle_id, @bundle_id, {:unsupported_bundle, bundle_id}),
         {:ok, spacecraft_input} <- alias_value(map, ["spacecraft"], nil, :spacecraft),
         {:ok, station_input} <-
           alias_value(map, ["ground_station"], nil, :ground_station),
         {:ok, spacecraft} <- normalize_optional_spacecraft(spacecraft_input),
         {:ok, ground_station} <- normalize_optional_station(station_input),
         {:ok, initial_state_input} <-
           alias_value(map, ["initial_state"], nil, :initial_state),
         {:ok, initial_state} <- normalize_optional_initial_state(initial_state_input),
         {:ok, coverage_input} <- alias_value(map, ["coverage"], nil, :coverage),
         {:ok, coverage} <- normalize_optional_coverage(coverage_input) do
      {:ok,
       %{
         bundle_id: bundle_id,
         spacecraft: spacecraft,
         ground_station: ground_station,
         initial_state: initial_state,
         coverage: coverage,
         raw: map
       }}
    end
  end

  @doc """
  Captures one immutable, offline execution policy.

  The request must include normalized-equivalent spacecraft, ground-station,
  initial-state, and coverage values. A previously serialized policy may also
  be supplied; every captured capability, revision, coverage record, and the
  fingerprint must still match the current fixed bundle.
  """
  def capture(input) do
    with {:ok, request} <- validate_request(input),
         :ok <- require_capture_inputs(request),
         {:ok, document} <- build_document(request),
         :ok <- validate_assertions(request.raw, document) do
      {:ok, %__MODULE__{document: document}}
    end
  end

  @doc "Returns the JSON-serializable captured policy document."
  def serialize(%__MODULE__{document: document}), do: document

  @doc "Returns the captured policy fingerprint."
  def fingerprint(%__MODULE__{document: document}), do: Map.fetch!(document, "policy_fingerprint")

  def fingerprint(%{} = document) do
    case normalize_json_input(document) do
      {:ok, normalized} ->
        fingerprint_normalized(normalized)

      {:error, _reason} ->
        raise ArgumentError, "invalid policy fingerprint input"
    end
  end

  @doc "Revalidates a serialized policy against the fixed bundle and its fingerprint."
  def validate_serialized(%{} = document) do
    with {:ok, normalized} <- normalize_json_input(document),
         {:ok, policy} <- capture(normalized) do
      if serialize(policy) == normalized,
        do: :ok,
        else: {:error, :captured_policy_drift}
    end
  end

  def validate_serialized(_document), do: {:error, :invalid_execution_policy}

  defp build_document(request) do
    try do
      with :ok <- Environment.validate_provider_capability(@atmosphere_capability),
           :ok <- Environment.validate_provider_capability(@earth_rotation_capability),
           :ok <- Environment.validate_capability(@fixed_sun_capability),
           :ok <- validate_offline_capability(@atmosphere_capability, :atmosphere),
           :ok <- validate_offline_capability(@earth_rotation_capability, :earth_rotation),
           :ok <-
             validate_provider_coverage(
               @atmosphere_capability,
               request.coverage,
               :density_kg_m3
             ),
           :ok <-
             validate_provider_coverage(
               @earth_rotation_capability,
               request.coverage,
               :earth_rotation
             ) do
        raw_document =
          captured_document(
            request,
            @atmosphere_capability,
            @earth_rotation_capability,
            @fixed_sun_capability,
            @propagator_capability,
            @access_capability,
            @eclipse_capability
          )

        with {:ok, document} <- normalize_internal_value(raw_document, "$capture") do
          {:ok,
           Map.put(
             document,
             "policy_fingerprint",
             fingerprint_normalized(document)
           )}
        end
      end
    rescue
      error -> {:error, {:policy_capture_exception, error.__struct__}}
    catch
      kind, reason -> {:error, {:policy_capture_throw, kind, reason}}
    end
  end

  defp captured_document(
         request,
         atmosphere,
         earth_rotation,
         fixed_sun,
         propagator_capability,
         access_capability,
         eclipse_capability
       ) do
    provider_capabilities = %{
      "atmosphere" => atmosphere,
      "earth_rotation" => earth_rotation,
      "sun_direction" => fixed_sun
    }

    provider_revisions = %{
      "atmosphere" => @atmosphere_revision,
      "earth_rotation" => @earth_rotation_revision,
      "sun_direction" => @sun_revision
    }

    provider_coverage = %{
      "atmosphere" => atmosphere["coverage"],
      "earth_rotation" => earth_rotation["coverage"],
      "requested_horizon" => request.coverage
    }

    %{
      "schema_contract" => @schema_contract,
      "bundle_id" => @bundle_id,
      "execution_mode" => @execution_mode,
      "network_access" => false,
      "module_allowlist" => @module_allowlist,
      "spacecraft" => request.spacecraft,
      "ground_station" => request.ground_station,
      "initial_state" => request.initial_state,
      "coverage" => request.coverage,
      "central_body" => %{
        "name" => "earth",
        "mu_km3_s2" => @central_body.mu_km3_s2,
        "equatorial_radius_km" => @central_body.equatorial_radius_km,
        "j2" => @central_body.j2
      },
      "propagation" => %{
        "module" => "OrbitalDynamics.Propagators.J2Drag",
        "source_revision" => @propagator_revision,
        "force_models" => ["point_mass_two_body", "j2", "atmospheric_drag"],
        "numerical_method" => "rk4_fixed_step",
        "max_step_s" => @max_step_s,
        "output_step_s" => @output_step_s,
        "capability" => propagator_capability
      },
      "environment" => %{
        "mode" => "built_in_offline_fixed",
        "atmosphere_provider" => %{
          "module" => "OrbitalDynamics.Environment.ExponentialAtmosphereProvider",
          "source_revision" => @atmosphere_revision,
          "capability" => atmosphere
        },
        "earth_rotation_provider" => %{
          "module" => "OrbitalDynamics.Environment.ConstantEarthRotationProvider",
          "source_revision" => @earth_rotation_revision,
          "capability" => earth_rotation
        },
        "sun_direction" => %{
          "source_revision" => @sun_revision,
          "vector_eci_j2000" => [1.0, 0.0, 0.0],
          "capability" => fixed_sun
        }
      },
      "access" => %{
        "module" => "OrbitalDynamics.EventDetectors.AccessWindows",
        "source_revision" => @access_revision,
        "geometry" => @access_geometry,
        "boundary_refinement" => "bracketed_bisection",
        "root_solver" => "bisection",
        "root_tolerance_s" => @root_tolerance_s,
        "root_max_iterations" => @root_max_iterations,
        "capability" => access_capability
      },
      "eclipse" => %{
        "module" => "OrbitalDynamics.EventDetectors.Eclipses",
        "source_revision" => @eclipse_revision,
        "shadow_model" => "cylindrical_central_body_shadow",
        "interpolation" => "linear_sample_crossing",
        "candidate_source" => false,
        "archive_only" => true,
        "capability" => eclipse_capability
      },
      "provider_capabilities" => provider_capabilities,
      "provider_revisions" => provider_revisions,
      "provider_coverage" => provider_coverage,
      "model_limits" => @model_limits
    }
  end

  defp validate_provider_coverage(capability, coverage, output) do
    request = %{
      starts_at_s: coverage["starts_at_s"],
      ends_at_s: coverage["ends_at_s"],
      body: :earth,
      output: output
    }

    if Environment.provider_supports_request?(capability, request),
      do: :ok,
      else: {:error, {:unsupported_provider_coverage, output}}
  end

  defp validate_offline_capability(%{"network_access" => false}, _provider), do: :ok

  defp validate_offline_capability(%{"network_access" => true}, provider),
    do: {:error, {:network_provider_rejected, provider}}

  defp validate_offline_capability(_capability, provider),
    do: {:error, {:invalid_network_policy, provider}}

  defp validate_assertions(raw, document) do
    full_policy? =
      has_alias?(raw, ["schema_contract"]) or has_alias?(raw, ["policy_fingerprint"])

    if full_policy? do
      if raw == document,
        do: :ok,
        else: {:error, :captured_policy_drift}
    else
      validate_partial_assertions(raw, document)
    end
  end

  defp validate_partial_assertions(raw, document) do
    assertions = [
      {"schema_contract", ["schema_contract"]},
      {"execution_mode", ["execution_mode"]},
      {"network_access", ["network_access"]},
      {"module_allowlist", ["module_allowlist"]},
      {"central_body", ["central_body"]},
      {"propagation", ["propagation"]},
      {"environment", ["environment"]},
      {"access", ["access"]},
      {"eclipse", ["eclipse"]},
      {"provider_capabilities", ["provider_capabilities"]},
      {"provider_revisions", ["provider_revisions"]},
      {"provider_coverage", ["provider_coverage"]},
      {"policy_fingerprint", ["policy_fingerprint"]},
      {"model_limits", ["model_limits"]}
    ]

    Enum.reduce_while(assertions, :ok, fn {document_field, aliases}, :ok ->
      case optional_alias_value(raw, aliases) do
        :missing ->
          {:cont, :ok}

        {:ok, asserted} ->
          if asserted == document[document_field],
            do: {:cont, :ok},
            else: {:halt, {:error, {:policy_drift, document_field}}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
  end

  defp require_capture_inputs(request) do
    cond do
      not is_map(request.spacecraft) ->
        {:error, {:missing_policy_input, :spacecraft}}

      not is_map(request.ground_station) ->
        {:error, {:missing_policy_input, :ground_station}}

      not is_map(request.initial_state) ->
        {:error, {:missing_policy_input, :initial_state}}

      not is_map(request.coverage) ->
        {:error, {:missing_policy_input, :coverage}}

      request.spacecraft["spacecraft_id"] != request.initial_state["spacecraft_id"] ->
        {:error, {:policy_state_mismatch, :spacecraft_id}}

      request.spacecraft["scenario_id"] != request.initial_state["scenario_id"] ->
        {:error, {:policy_state_mismatch, :scenario_id}}

      request.coverage["starts_at_s"] != request.initial_state["epoch_s"] ->
        {:error, {:policy_state_mismatch, :epoch_s}}

      true ->
        :ok
    end
  end

  defp normalize_optional_spacecraft(nil), do: {:ok, nil}
  defp normalize_optional_spacecraft(value), do: normalize_spacecraft(value)

  defp normalize_spacecraft(%{} = spacecraft) do
    with :ok <- reject_unknown_keys(spacecraft, @spacecraft_keys, :spacecraft),
         {:ok, spacecraft_id} <-
           alias_value(spacecraft, ~w(spacecraft_id id), :required, :spacecraft_id),
         {:ok, scenario_id} <-
           alias_value(spacecraft, ["scenario_id"], :required, :scenario_id),
         {:ok, dry_mass_kg} <-
           alias_value(spacecraft, ~w(dry_mass_kg mass_kg), :required, :dry_mass_kg),
         {:ok, propellant_mass_kg} <-
           alias_value(
             spacecraft,
             ["propellant_mass_kg"],
             :required,
             :propellant_mass_kg
           ),
         {:ok, drag_area_m2} <-
           alias_value(spacecraft, ~w(drag_area_m2 area_m2), :required, :drag_area_m2),
         {:ok, drag_coefficient} <-
           alias_value(
             spacecraft,
             ["drag_coefficient"],
             :required,
             :drag_coefficient
           ),
         {:ok, spacecraft_id} <- stable_id(spacecraft_id, :spacecraft_id),
         {:ok, scenario_id} <- stable_id(scenario_id, :scenario_id),
         {:ok, dry_mass_kg} <-
           number(
             dry_mass_kg,
             0.0,
             @spacecraft_numeric_envelope.total_mass_kg.maximum,
             :dry_mass_kg
           ),
         {:ok, propellant_mass_kg} <-
           number(
             propellant_mass_kg,
             0.0,
             @spacecraft_numeric_envelope.total_mass_kg.maximum,
             :propellant_mass_kg
           ),
         :ok <- validate_total_mass(dry_mass_kg, propellant_mass_kg),
         {:ok, drag_area_m2} <-
           number(
             drag_area_m2,
             @spacecraft_numeric_envelope.drag_area_m2.minimum,
             @spacecraft_numeric_envelope.drag_area_m2.maximum,
             :drag_area_m2
           ),
         {:ok, drag_coefficient} <-
           number(
             drag_coefficient,
             @spacecraft_numeric_envelope.drag_coefficient.minimum,
             @spacecraft_numeric_envelope.drag_coefficient.maximum,
             :drag_coefficient
           ),
         :ok <- validate_asserted_total_mass(spacecraft, dry_mass_kg + propellant_mass_kg) do
      {:ok,
       %{
         "spacecraft_id" => spacecraft_id,
         "scenario_id" => scenario_id,
         "dry_mass_kg" => dry_mass_kg,
         "propellant_mass_kg" => propellant_mass_kg,
         "total_mass_kg" => dry_mass_kg + propellant_mass_kg,
         "drag_area_m2" => drag_area_m2,
         "drag_coefficient" => drag_coefficient
       }}
    end
  end

  defp normalize_spacecraft(_spacecraft), do: {:error, {:invalid_policy_input, :spacecraft}}

  defp normalize_optional_station(nil), do: {:ok, nil}
  defp normalize_optional_station(value), do: normalize_station(value)

  defp normalize_station(%{} = station) do
    with :ok <- reject_unknown_keys(station, @station_keys, :ground_station),
         {:ok, ground_station_id} <-
           alias_value(
             station,
             ~w(ground_station_id station_id id),
             :required,
             :ground_station_id
           ),
         {:ok, latitude_deg} <-
           alias_value(station, ["latitude_deg"], :required, :latitude_deg),
         {:ok, longitude_deg} <-
           alias_value(station, ["longitude_deg"], :required, :longitude_deg),
         {:ok, altitude_km} <-
           alias_value(station, ["altitude_km"], :required, :altitude_km),
         {:ok, minimum_elevation_deg} <-
           alias_value(
             station,
             ["minimum_elevation_deg"],
             :required,
             :minimum_elevation_deg
           ),
         {:ok, ground_station_id} <- stable_id(ground_station_id, :ground_station_id),
         {:ok, latitude_deg} <- number(latitude_deg, -90.0, 90.0, :latitude_deg),
         {:ok, longitude_deg} <- number(longitude_deg, -180.0, 180.0, :longitude_deg),
         {:ok, altitude_km} <- number(altitude_km, -1.0, 100.0, :altitude_km),
         {:ok, minimum_elevation_deg} <-
           number(minimum_elevation_deg, -90.0, 90.0, :minimum_elevation_deg) do
      {:ok,
       %{
         "ground_station_id" => ground_station_id,
         "latitude_deg" => latitude_deg,
         "longitude_deg" => longitude_deg,
         "altitude_km" => altitude_km,
         "minimum_elevation_deg" => minimum_elevation_deg
       }}
    end
  end

  defp normalize_station(_station), do: {:error, {:invalid_policy_input, :ground_station}}

  defp normalize_optional_initial_state(nil), do: {:ok, nil}
  defp normalize_optional_initial_state(value), do: normalize_initial_state(value)

  defp normalize_initial_state(%{} = state) do
    with :ok <- reject_unknown_keys(state, @initial_state_keys, :initial_state),
         {:ok, snapshot_id} <- alias_value(state, ["snapshot_id"], :required, :snapshot_id),
         {:ok, spacecraft_id} <-
           alias_value(state, ["spacecraft_id"], :required, :spacecraft_id),
         {:ok, scenario_id} <-
           alias_value(state, ["scenario_id"], :required, :scenario_id),
         {:ok, body} <- alias_value(state, ["body"], :required, :body),
         {:ok, frame} <- alias_value(state, ["frame"], :required, :frame),
         {:ok, time_scale} <- alias_value(state, ["time_scale"], :required, :time_scale),
         {:ok, epoch_s} <- alias_value(state, ["epoch_s"], :required, :epoch_s),
         {:ok, position_km} <-
           alias_value(state, ["position_km"], :required, :position_km),
         {:ok, velocity_km_s} <-
           alias_value(state, ["velocity_km_s"], :required, :velocity_km_s),
         {:ok, snapshot_id} <- stable_id(snapshot_id, :snapshot_id),
         {:ok, spacecraft_id} <- stable_id(spacecraft_id, :spacecraft_id),
         {:ok, scenario_id} <- stable_id(scenario_id, :scenario_id),
         :ok <- require_equal(body, "earth", {:unsupported_body, body}),
         :ok <-
           require_equal(
             frame,
             "earth_inertial_j2000",
             {:unsupported_frame, frame}
           ),
         :ok <-
           require_equal(time_scale, "tdb", {:unsupported_time_scale, time_scale}),
         {:ok, epoch_s} <-
           number(
             epoch_s,
             -@state_numeric_envelope.epoch_abs_max_s_since_j2000,
             @state_numeric_envelope.epoch_abs_max_s_since_j2000,
             :epoch_s
           ),
         {:ok, position_km} <-
           vector(
             position_km,
             @state_numeric_envelope.position_component_abs_max_km,
             :position_km
           ),
         {:ok, velocity_km_s} <-
           vector(
             velocity_km_s,
             @state_numeric_envelope.velocity_component_abs_max_km_s,
             :velocity_km_s
           ),
         :ok <- validate_altitude(position_km) do
      {:ok,
       %{
         "snapshot_id" => snapshot_id,
         "spacecraft_id" => spacecraft_id,
         "scenario_id" => scenario_id,
         "body" => "earth",
         "frame" => "earth_inertial_j2000",
         "time_scale" => "tdb",
         "epoch_s" => epoch_s,
         "position_km" => position_km,
         "velocity_km_s" => velocity_km_s
       }}
    end
  end

  defp normalize_initial_state(_state), do: {:error, {:invalid_policy_input, :initial_state}}

  defp normalize_optional_coverage(nil), do: {:ok, nil}
  defp normalize_optional_coverage(value), do: normalize_coverage(value)

  defp normalize_coverage(%{} = coverage) do
    with :ok <- reject_unknown_keys(coverage, @coverage_keys, :coverage),
         {:ok, starts_at_s} <-
           alias_value(coverage, ["starts_at_s"], :required, :starts_at_s),
         {:ok, ends_at_s} <- alias_value(coverage, ["ends_at_s"], :required, :ends_at_s),
         {:ok, output_step_s} <-
           alias_value(coverage, ["output_step_s"], :required, :output_step_s),
         {:ok, starts_at_s} <-
           number(
             starts_at_s,
             -@state_numeric_envelope.epoch_abs_max_s_since_j2000,
             @state_numeric_envelope.epoch_abs_max_s_since_j2000,
             :starts_at_s
           ),
         {:ok, ends_at_s} <-
           number(
             ends_at_s,
             -@state_numeric_envelope.epoch_abs_max_s_since_j2000,
             @state_numeric_envelope.epoch_abs_max_s_since_j2000,
             :ends_at_s
           ),
         {:ok, output_step_s} <-
           number(output_step_s, 0.0, @duration_envelope.maximum, :output_step_s),
         :ok <- validate_horizon(starts_at_s, ends_at_s, output_step_s) do
      {:ok,
       %{
         "starts_at_s" => starts_at_s,
         "ends_at_s" => ends_at_s,
         "output_step_s" => output_step_s
       }}
    end
  end

  defp normalize_coverage(_coverage), do: {:error, {:invalid_policy_input, :coverage}}

  defp validate_horizon(starts_at_s, ends_at_s, output_step_s) do
    duration_s = ends_at_s - starts_at_s

    cond do
      duration_s <= 0.0 ->
        {:error, {:invalid_horizon, :non_positive_duration}}

      duration_s > @duration_envelope.maximum ->
        {:error, {:unsupported_horizon, :maximum_24_hours}}

      output_step_s != @output_step_s ->
        {:error, {:unsupported_cadence, output_step_s}}

      true ->
        :ok
    end
  end

  defp validate_total_mass(dry_mass_kg, propellant_mass_kg) do
    total = dry_mass_kg + propellant_mass_kg

    cond do
      total < @spacecraft_numeric_envelope.total_mass_kg.minimum ->
        {:error, {:invalid_policy_input, :total_mass_kg}}

      total > @spacecraft_numeric_envelope.total_mass_kg.maximum ->
        {:error, {:unsupported_policy_input, :total_mass_kg}}

      true ->
        :ok
    end
  end

  defp validate_asserted_total_mass(spacecraft, expected) do
    case optional_alias_value(spacecraft, ["total_mass_kg"]) do
      :missing -> :ok
      {:ok, value} when is_number(value) and value == expected -> :ok
      {:ok, _value} -> {:error, {:policy_drift, :total_mass_kg}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_altitude([x, y, z]) do
    radius_km = Vector3.norm({x, y, z})
    altitude_km = radius_km - @central_body.equatorial_radius_km

    if altitude_km >= @initial_altitude_envelope.minimum and
         altitude_km <= @initial_altitude_envelope.maximum,
       do: :ok,
       else: {:error, {:unsupported_state, :initial_altitude_km}}
  end

  defp validate_fixed_module_assertions(map) do
    assertions = [
      {"propagator", J2Drag},
      {"atmosphere_provider", ExponentialAtmosphereProvider},
      {"earth_rotation_provider", ConstantEarthRotationProvider},
      {"access_detector", AccessWindows},
      {"eclipse_detector", Eclipses}
    ]

    Enum.reduce_while(assertions, :ok, fn {field, expected}, :ok ->
      case optional_alias_value(map, [field]) do
        :missing ->
          {:cont, :ok}

        {:ok, value} ->
          if module_assertion_matches?(value, expected),
            do: {:cont, :ok},
            else: {:halt, {:error, {:unsupported_module, field}}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
  end

  defp module_assertion_matches?(value, expected) when is_binary(value) do
    expected_name = expected |> Atom.to_string() |> String.trim_leading("Elixir.")
    value in [expected_name, "Elixir." <> expected_name]
  end

  defp module_assertion_matches?(_value, _expected), do: false

  defp validate_network_assertion(map) do
    case optional_alias_value(map, ["network_access"]) do
      :missing -> :ok
      {:ok, false} -> :ok
      {:ok, _value} -> {:error, :network_access_rejected}
      {:error, reason} -> {:error, reason}
    end
  end

  defp reject_campaign_provider(map) do
    case optional_alias_value(map, ["campaign_environment"]) do
      :missing -> :ok
      {:ok, nil} -> :ok
      {:ok, _value} -> {:error, :campaign_provider_rejected}
      {:error, reason} -> {:error, reason}
    end
  end

  defp input_map(%_{}), do: {:error, {:unsupported_json_value, "$", :struct}}
  defp input_map(%{} = map), do: normalize_public_value(map, "$")
  defp input_map(_input), do: {:error, {:invalid_policy_input, :execution_policy}}

  defp reject_unknown_keys(map, allowed_keys, field) do
    allowed = MapSet.new(allowed_keys)

    unknown =
      map
      |> Map.keys()
      |> Enum.reject(&MapSet.member?(allowed, &1))
      |> Enum.uniq()
      |> Enum.sort()

    if unknown == [], do: :ok, else: {:error, {:unsupported_policy_fields, field, unknown}}
  end

  defp alias_value(map, aliases, default, field) do
    present = Enum.filter(aliases, &Map.has_key?(map, &1))

    case present do
      [] when default == :required -> {:error, {:missing_policy_input, field}}
      [] -> {:ok, default}
      [key] -> {:ok, Map.get(map, key)}
      _keys -> {:error, {:duplicate_aliases, field}}
    end
  end

  defp optional_alias_value(map, aliases) do
    case alias_value(map, aliases, :missing, List.first(aliases)) do
      {:ok, :missing} -> :missing
      {:ok, value} -> {:ok, value}
      {:error, reason} -> {:error, reason}
    end
  end

  defp has_alias?(map, aliases), do: optional_alias_value(map, aliases) != :missing

  defp stable_id(value, field) when is_binary(value) do
    if OrbitalDynamics.Schema.StableIdValidation.valid?(value),
      do: {:ok, value},
      else: {:error, {:invalid_stable_id, field}}
  end

  defp stable_id(_value, field), do: {:error, {:invalid_stable_id, field}}

  defp number(value, minimum, maximum, _field)
       when is_number(value) and value >= minimum and value <= maximum,
       do: {:ok, value * 1.0}

  defp number(value, _minimum, _maximum, field) when is_number(value),
    do: {:error, {:unsupported_numeric_input, field}}

  defp number(_value, _minimum, _maximum, field),
    do: {:error, {:invalid_numeric_input, field}}

  defp vector(values, maximum, field) when is_list(values) and length(values) == 3 do
    values
    |> Enum.reduce_while({:ok, []}, fn value, {:ok, acc} ->
      case number(value, -maximum, maximum, field) do
        {:ok, number} -> {:cont, {:ok, [number | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, normalized} -> {:ok, Enum.reverse(normalized)}
      error -> error
    end
  end

  defp vector(_values, _maximum, field), do: {:error, {:invalid_vector, field}}

  defp require_equal(value, value, _reason), do: :ok
  defp require_equal(_value, _expected, reason), do: {:error, reason}

  defp canonical_term(%{} = map) do
    {:map,
     map
     |> Enum.map(fn {key, value} -> {key, canonical_term(value)} end)
     |> Enum.sort_by(&elem(&1, 0))}
  end

  defp canonical_term(values) when is_list(values),
    do: {:list, Enum.map(values, &canonical_term/1)}

  defp canonical_term(value), do: {:value, value}

  defp fingerprint_normalized(document) do
    document
    |> Map.delete("policy_fingerprint")
    |> canonical_term()
    |> :erlang.term_to_binary()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp normalize_public_value(value, path), do: normalize_value(value, path, :public)
  defp normalize_internal_value(value, path), do: normalize_value(value, path, :internal)

  defp normalize_value(value, path, mode) do
    cond do
      is_struct(value) ->
        unsupported_value(mode, path, :struct)

      is_map(value) ->
        normalize_map(value, path, mode)

      list_shaped?(value) and proper_list?(value) ->
        normalize_list(value, path, mode)

      list_shaped?(value) ->
        unsupported_value(mode, path, :improper_list)

      is_boolean(value) or is_nil(value) ->
        {:ok, value}

      is_binary(value) and not String.valid?(value) ->
        {:error, {:invalid_utf8_string, path}}

      is_binary(value) ->
        {:ok, value}

      is_number(value) and finite_number?(value) ->
        {:ok, value}

      is_number(value) ->
        {:error, {:non_finite_number, path}}

      is_tuple(value) ->
        unsupported_value(mode, path, :tuple)

      is_bitstring(value) ->
        unsupported_value(mode, path, :bitstring)

      is_atom(value) and mode == :internal ->
        {:ok, Atom.to_string(value)}

      is_atom(value) ->
        unsupported_value(mode, path, :atom)

      is_pid(value) ->
        unsupported_value(mode, path, :pid)

      is_reference(value) ->
        unsupported_value(mode, path, :reference)

      is_function(value) ->
        unsupported_value(mode, path, :function)

      true ->
        unsupported_value(mode, path, :port_or_unknown)
    end
  end

  defp normalize_map(map, path, mode) do
    map
    |> Enum.reduce_while({:ok, %{}, MapSet.new()}, fn {key, value}, {:ok, acc, seen} ->
      with {:ok, normalized_key} <- normalize_public_key(key, path),
           false <- MapSet.member?(seen, normalized_key),
           {:ok, normalized_value} <-
             normalize_value(value, path <> "." <> normalized_key, mode) do
        {:cont,
         {:ok, Map.put(acc, normalized_key, normalized_value), MapSet.put(seen, normalized_key)}}
      else
        true ->
          {:halt, {:error, {:duplicate_normalized_key, path, encoded_public_key(key)}}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, normalized, _seen} -> {:ok, normalized}
      {:error, reason} -> {:error, reason}
    end
  end

  defp normalize_list(values, path, mode) do
    values
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {value, index}, {:ok, acc} ->
      case normalize_value(value, "#{path}[#{index}]", mode) do
        {:ok, normalized} -> {:cont, {:ok, [normalized | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, normalized} -> {:ok, Enum.reverse(normalized)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp unsupported_value(:public, path, type),
    do: {:error, {:unsupported_json_value, path, type}}

  defp unsupported_value(:internal, path, type),
    do: {:error, {:unsupported_internal_value, path, type}}

  defp normalize_public_key(key, path) when is_atom(key) do
    key
    |> Atom.to_string()
    |> normalize_public_key(path)
  end

  defp normalize_public_key(key, path) when is_binary(key) do
    if String.valid?(key),
      do: {:ok, key},
      else: {:error, {:invalid_utf8_key, path}}
  end

  defp normalize_public_key(_key, path),
    do: {:error, {:unsupported_map_key, path}}

  defp encoded_public_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encoded_public_key(key) when is_binary(key), do: key
  defp encoded_public_key(_key), do: :unsupported_key

  defp list_shaped?([]), do: true
  defp list_shaped?([_head | _tail]), do: true
  defp list_shaped?(_value), do: false

  defp proper_list?([]), do: true
  defp proper_list?([_head | tail]), do: proper_list?(tail)
  defp proper_list?(_value), do: false

  defp finite_number?(value),
    do: is_number(value) and value >= -1.0e300 and value <= 1.0e300
end
