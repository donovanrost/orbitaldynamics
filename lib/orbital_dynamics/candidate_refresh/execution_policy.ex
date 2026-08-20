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
    ExponentialAtmosphereProvider,
    FixedSunProvider,
    Provider
  }

  alias OrbitalDynamics.EventDetectors.{AccessWindows, Eclipses}
  alias OrbitalDynamics.ForceModels.AtmosphericDrag
  alias OrbitalDynamics.Propagators.{J2, J2Drag}
  alias OrbitalDynamics.CandidateRefresh.CandidateActivityFields

  alias OrbitalDynamics.{
    AccessGeometry,
    CentralBody,
    Epoch,
    EventTiming,
    Frame,
    GroundStation,
    Scenario,
    Spacecraft,
    StateVector,
    Vector3
  }

  @bundle_id "candidate_refresh.earth_j2_drag_access_eclipse.v1"
  @schema_contract "candidate_refresh_execution_policy.v1"
  @execution_mode "offline_deterministic"
  @reserved_key "candidate_refresh_execution_policy"
  @evidence_key "candidate_refresh_execution_evidence"
  @external_case_id "orekit_13_1_7_leo_j2_drag_access_eclipse"
  @output_step_s 10.0
  @max_step_s 10.0
  @root_tolerance_s 1.0e-6
  @root_max_iterations 64
  @max_normalization_depth 32
  @max_collection_size 10_000
  @max_key_bytes 512
  @max_binary_bytes 1_048_576
  @max_visited_terms 100_000
  @max_total_byte_work 4_194_304

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

  @executable_modules [
    {"OrbitalDynamics.Environment", Environment},
    {"OrbitalDynamics.Environment.Provider", Provider},
    {"OrbitalDynamics.Environment.ExponentialAtmosphereProvider", ExponentialAtmosphereProvider},
    {"OrbitalDynamics.Environment.ConstantEarthRotationProvider", ConstantEarthRotationProvider},
    {"OrbitalDynamics.Environment.FixedSunProvider", FixedSunProvider},
    {"OrbitalDynamics.Propagators.J2Drag", J2Drag},
    {"OrbitalDynamics.Propagators.J2", J2},
    {"OrbitalDynamics.ForceModels.AtmosphericDrag", AtmosphericDrag},
    {"OrbitalDynamics.EventDetectors.AccessWindows", AccessWindows},
    {"OrbitalDynamics.EventDetectors.Eclipses", Eclipses},
    {"OrbitalDynamics.AccessGeometry", AccessGeometry},
    {"OrbitalDynamics.EventTiming", EventTiming},
    {"OrbitalDynamics.Vector3", Vector3},
    {"OrbitalDynamics.Epoch", Epoch},
    {"OrbitalDynamics.Frame", Frame},
    {"OrbitalDynamics.CentralBody", CentralBody},
    {"OrbitalDynamics.GroundStation", GroundStation},
    {"OrbitalDynamics.Scenario", Scenario},
    {"OrbitalDynamics.Spacecraft", Spacecraft},
    {"OrbitalDynamics.StateVector", StateVector}
  ]
  @module_allowlist Enum.map(@executable_modules, &elem(&1, 0))

  @execution_module_aliases [
    {"propagator", "OrbitalDynamics.Propagators.J2Drag"},
    {"atmosphere_provider", "OrbitalDynamics.Environment.ExponentialAtmosphereProvider"},
    {"earth_rotation_provider", "OrbitalDynamics.Environment.ConstantEarthRotationProvider"},
    {"sun_direction_provider", "OrbitalDynamics.Environment.FixedSunProvider"},
    {"access_detector", "OrbitalDynamics.EventDetectors.AccessWindows"},
    {"eclipse_detector", "OrbitalDynamics.EventDetectors.Eclipses"}
  ]
  @structured_provider_aliases ~w(atmosphere_provider earth_rotation_provider)

  @serialized_execution_identity_surfaces [
    {~w(propagation module), "OrbitalDynamics.Propagators.J2Drag"},
    {~w(environment atmosphere_provider module),
     "OrbitalDynamics.Environment.ExponentialAtmosphereProvider"},
    {~w(environment atmosphere_provider evaluation_api), "fetch_captured/3"},
    {~w(environment earth_rotation_provider module),
     "OrbitalDynamics.Environment.ConstantEarthRotationProvider"},
    {~w(access module), "OrbitalDynamics.EventDetectors.AccessWindows"},
    {~w(eclipse module), "OrbitalDynamics.EventDetectors.Eclipses"}
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
    executable_beam_digests
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
    refresh_identity_input
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

  @doc false
  def evidence_key, do: @evidence_key

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
  def validate_json_term(value) do
    case normalize_root(value, "$", :artifact) do
      {:ok, _normalized} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @doc false
  def validate_serialized_json_term(value) do
    case normalize_root(value, "$", :serialized) do
      {:ok, _normalized} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @doc false
  def canonical_sort_key(value) do
    case normalize_json_input(value) do
      {:ok, normalized} -> normalized |> canonical_term() |> :erlang.term_to_binary()
      {:error, _reason} -> raise ArgumentError, "invalid canonical input"
    end
  end

  @doc false
  def canonical_sha256(value) do
    with {:ok, normalized} <- normalize_json_input(value) do
      {:ok,
       normalized
       |> canonical_term()
       |> :erlang.term_to_binary()
       |> then(&:crypto.hash(:sha256, &1))
       |> Base.encode16(case: :lower)}
    end
  end

  @doc false
  def candidate_source_window_bindings(access_windows) when is_list(access_windows) do
    access_windows
    |> Enum.with_index(1)
    |> Enum.reduce_while({:ok, []}, fn
      {%{} = window, index}, {:ok, acc} ->
        case candidate_source_window_binding(window, index) do
          {:ok, binding} -> {:cont, {:ok, [binding | acc]}}
          {:error, reason} -> {:halt, {:error, reason}}
        end

      {_window, index}, _acc ->
        {:halt, {:error, {:invalid_access_window_binding, index}}}
    end)
    |> case do
      {:ok, bindings} -> {:ok, Enum.reverse(bindings)}
      {:error, reason} -> {:error, reason}
    end
  end

  def candidate_source_window_bindings(_access_windows),
    do: {:error, {:invalid_access_window_binding, :collection}}

  @doc false
  def verify_executable_modules(%__MODULE__{document: document}),
    do: verify_executable_modules(document)

  def verify_executable_modules(%{} = document) do
    expected = Map.get(document, "executable_beam_digests")

    with {:ok, actual} <- current_executable_beam_digests(),
         true <- is_map(expected) do
      case Enum.find(executable_modules(), fn {name, _module} ->
             Map.get(expected, name) != Map.get(actual, name)
           end) do
        nil -> :ok
        {name, _module} -> {:error, {:execution_policy_drift, {:executable_beam_digest, name}}}
      end
    else
      false -> {:error, {:execution_policy_drift, :executable_beam_digests}}
      {:error, reason} -> {:error, reason}
    end
  end

  def verify_executable_modules(_document),
    do: {:error, {:execution_policy_drift, :executable_beam_digests}}

  @doc """
  Validates and normalizes the caller-controlled portion of a policy request.

  This phase does not read module capabilities. It is used by the runner before
  capture so input and selection errors are reported at the validation stage.
  """
  def validate_request(input) do
    with {:ok, map} <- input_map(input, policy_normalization_mode(input)),
         :ok <- reject_unknown_keys(map, @request_top_level_keys, :execution_policy),
         :ok <- validate_execution_identity_aliases(map, "$"),
         :ok <- validate_serialized_execution_identity_surfaces(map),
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
         {:ok, coverage} <- normalize_optional_coverage(coverage_input),
         {:ok, refresh_identity_input} <-
           alias_value(map, ["refresh_identity_input"], nil, :refresh_identity_input),
         {:ok, refresh_identity_input} <-
           normalize_optional_refresh_identity(refresh_identity_input),
         :ok <-
           validate_refresh_execution_identity_surfaces(
             refresh_identity_input,
             "$.refresh_identity_input"
           ) do
      {:ok,
       %{
         bundle_id: bundle_id,
         spacecraft: spacecraft,
         ground_station: ground_station,
         initial_state: initial_state,
         coverage: coverage,
         refresh_identity_input: refresh_identity_input,
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
    with {:ok, normalized} <- normalize_serialized_value(document, "$"),
         {:ok, policy} <- capture(normalized) do
      if serialize(policy) == normalized,
        do: :ok,
        else: {:error, :captured_policy_drift}
    end
  end

  def validate_serialized(_document), do: {:error, :invalid_execution_policy}

  @doc false
  def validate_refresh_execution_identity_surfaces(value, path \\ "$")

  def validate_refresh_execution_identity_surfaces(nil, _path), do: :ok
  def validate_refresh_execution_identity_surfaces(:null, _path), do: :ok

  def validate_refresh_execution_identity_surfaces(%{} = map, path) do
    with :ok <- validate_execution_identity_aliases(map, path) do
      map
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.reduce_while(:ok, fn {field, value}, :ok ->
        case validate_refresh_execution_identity_surfaces(value, path <> "." <> field) do
          :ok -> {:cont, :ok}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)
    end
  end

  def validate_refresh_execution_identity_surfaces(values, path) when is_list(values) do
    values
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {value, index}, :ok ->
      case validate_refresh_execution_identity_surfaces(value, "#{path}[#{index}]") do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  def validate_refresh_execution_identity_surfaces(_value, _path), do: :ok

  @doc false
  def validate_refresh_identity_aliases(%{} = refresh, %{} = initial_state, %{} = coverage) do
    accepted_state = Map.get(refresh, "accepted_planning_state")
    mission_state = Map.get(refresh, "mission_state", %{})

    state =
      case accepted_state do
        %{"spacecraft_states" => [%{} = value]} -> value
        _value -> nil
      end

    with true <- is_map(accepted_state),
         true <- is_map(state),
         true <- is_map(mission_state),
         :ok <-
           validate_projection(
             :snapshot_id,
             [
               accepted_state["snapshot_id"],
               state["snapshot_id"],
               get_in(state, ["metadata", "snapshot_id"]),
               get_in(state, ["metadata", "scenario_snapshot_id"]),
               get_in(state, ["source", "snapshot_id"]),
               refresh["snapshot_id"],
               refresh["scenario_snapshot_id"],
               mission_state["snapshot_id"],
               mission_state["scenario_snapshot_id"]
             ],
             initial_state["snapshot_id"],
             &identity_string/1
           ),
         :ok <-
           validate_projection(
             :spacecraft_id,
             [
               state["spacecraft_id"],
               get_in(state, ["metadata", "spacecraft_id"]),
               accepted_state["spacecraft_id"],
               refresh["spacecraft_id"],
               mission_state["spacecraft_id"]
             ],
             initial_state["spacecraft_id"],
             &identity_string/1
           ),
         :ok <-
           validate_projection(
             :scenario_id,
             [
               state["scenario_id"],
               get_in(state, ["metadata", "scenario_id"]),
               accepted_state["scenario_id"],
               refresh["scenario_id"],
               mission_state["scenario_id"]
             ],
             initial_state["scenario_id"],
             &identity_string/1
           ),
         :ok <-
           validate_projection(
             :body,
             [
               state["body"],
               get_in(state, ["metadata", "body"]),
               get_in(state, ["metadata", "center_name"]),
               accepted_state["body"],
               get_in(accepted_state, ["source", "body"]),
               get_in(accepted_state, ["source", "center_name"]),
               refresh["body"],
               refresh["center_name"],
               mission_state["body"],
               mission_state["center_name"]
             ],
             initial_state["body"],
             &identity_token/1
           ),
         :ok <-
           validate_projection(
             :frame,
             [
               state["frame"],
               get_in(state, ["metadata", "frame"]),
               accepted_state["frame"],
               refresh["frame"],
               mission_state["frame"]
             ],
             initial_state["frame"],
             &identity_token/1
           ),
         :ok <-
           validate_projection(
             :time_scale,
             [
               get_in(state, ["epoch", "time_scale"]),
               get_in(state, ["metadata", "time_scale"]),
               get_in(accepted_state, ["current_epoch", "time_scale"]),
               get_in(refresh, ["current_epoch", "time_scale"]),
               get_in(mission_state, ["current_epoch", "time_scale"]),
               accepted_state["time_scale"],
               refresh["time_scale"],
               mission_state["time_scale"]
             ],
             initial_state["time_scale"],
             &identity_token/1
           ),
         :ok <-
           validate_projection(
             :current_epoch_s,
             [
               get_in(state, ["epoch", "seconds_since_j2000"]),
               accepted_state["current_epoch_s"],
               get_in(accepted_state, ["current_epoch", "seconds_since_j2000"]),
               refresh["current_epoch_s"],
               get_in(refresh, ["current_epoch", "seconds_since_j2000"]),
               mission_state["current_epoch_s"],
               get_in(mission_state, ["current_epoch", "seconds_since_j2000"]),
               coverage["starts_at_s"]
             ],
             initial_state["epoch_s"],
             &identity_number/1
           ),
         :ok <- validate_horizon_projections(refresh, accepted_state, mission_state, coverage) do
      :ok
    else
      false -> {:error, {:invalid_policy_input, :refresh_identity_input}}
      {:error, reason} -> {:error, reason}
    end
  end

  def validate_refresh_identity_aliases(_refresh, _initial_state, _coverage),
    do: {:error, {:invalid_policy_input, :refresh_identity_input}}

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
             ),
           {:ok, executable_beam_digests} <- current_executable_beam_digests() do
        raw_document =
          captured_document(
            request,
            @atmosphere_capability,
            @earth_rotation_capability,
            @fixed_sun_capability,
            @propagator_capability,
            @access_capability,
            @eclipse_capability,
            executable_beam_digests
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
         eclipse_capability,
         executable_beam_digests
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
      "executable_beam_digests" => executable_beam_digests,
      "spacecraft" => request.spacecraft,
      "ground_station" => request.ground_station,
      "initial_state" => request.initial_state,
      "coverage" => request.coverage,
      "refresh_identity_input" => request.refresh_identity_input,
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
          "evaluation_api" => "fetch_captured/3",
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
      with :ok <- verify_executable_modules(raw) do
        if raw == document,
          do: :ok,
          else: {:error, :captured_policy_drift}
      end
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
      {"executable_beam_digests", ["executable_beam_digests"]},
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

      not is_map(request.refresh_identity_input) ->
        {:error, {:missing_policy_input, :refresh_identity_input}}

      request.spacecraft["spacecraft_id"] != request.initial_state["spacecraft_id"] ->
        {:error, {:policy_state_mismatch, :spacecraft_id}}

      request.spacecraft["scenario_id"] != request.initial_state["scenario_id"] ->
        {:error, {:policy_state_mismatch, :scenario_id}}

      request.coverage["starts_at_s"] != request.initial_state["epoch_s"] ->
        {:error, {:policy_state_mismatch, :epoch_s}}

      true ->
        validate_refresh_identity_input(request)
    end
  end

  defp validate_refresh_identity_input(request) do
    refresh = request.refresh_identity_input
    accepted_state = Map.get(refresh, "accepted_planning_state")
    horizon = Map.get(refresh, "remaining_horizon")

    state =
      case accepted_state do
        %{"spacecraft_states" => [%{} = state]} -> state
        _value -> nil
      end

    with true <- is_map(accepted_state),
         true <- is_map(state),
         true <- is_map(horizon),
         :ok <-
           require_equal(
             accepted_state["snapshot_id"],
             request.initial_state["snapshot_id"],
             {:policy_refresh_identity_mismatch, :snapshot_id}
           ),
         :ok <-
           require_equal(
             state["spacecraft_id"],
             request.initial_state["spacecraft_id"],
             {:policy_refresh_identity_mismatch, :spacecraft_id}
           ),
         :ok <-
           require_equal(
             state["scenario_id"],
             request.initial_state["scenario_id"],
             {:policy_refresh_identity_mismatch, :scenario_id}
           ),
         :ok <-
           require_equal(
             get_in(state, ["epoch", "seconds_since_j2000"]),
             request.initial_state["epoch_s"],
             {:policy_refresh_identity_mismatch, :state_epoch_s}
           ),
         :ok <-
           require_equal(
             get_in(state, ["epoch", "time_scale"]),
             request.initial_state["time_scale"],
             {:policy_refresh_identity_mismatch, :time_scale}
           ),
         :ok <-
           require_equal(
             state["frame"],
             request.initial_state["frame"],
             {:policy_refresh_identity_mismatch, :frame}
           ),
         :ok <-
           require_equal(
             get_in(state, ["state_vector", "position_km"]),
             request.initial_state["position_km"],
             {:policy_refresh_identity_mismatch, :position_km}
           ),
         :ok <-
           require_equal(
             get_in(state, ["state_vector", "velocity_km_s"]),
             request.initial_state["velocity_km_s"],
             {:policy_refresh_identity_mismatch, :velocity_km_s}
           ),
         :ok <-
           require_equal(
             refresh["current_epoch_s"],
             request.initial_state["epoch_s"],
             {:policy_refresh_identity_mismatch, :current_epoch_s}
           ),
         :ok <-
           require_equal(
             Map.take(horizon, @coverage_keys),
             request.coverage,
             {:policy_refresh_identity_mismatch, :remaining_horizon}
           ),
         :ok <-
           validate_refresh_identity_aliases(
             refresh,
             request.initial_state,
             request.coverage
           ) do
      :ok
    else
      false -> {:error, {:invalid_policy_input, :refresh_identity_input}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp normalize_optional_refresh_identity(nil), do: {:ok, nil}
  defp normalize_optional_refresh_identity(%{} = refresh), do: {:ok, refresh}

  defp normalize_optional_refresh_identity(_refresh),
    do: {:error, {:invalid_policy_input, :refresh_identity_input}}

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

  defp validate_execution_identity_aliases(map, path) do
    aliases =
      if String.ends_with?(path, ".capability"),
        do: [],
        else: @execution_module_aliases ++ [{"evaluation_api", "fetch_captured/3"}]

    Enum.reduce_while(aliases, :ok, fn {field, expected}, :ok ->
      case Map.fetch(map, field) do
        :error ->
          {:cont, :ok}

        {:ok, value} when field in @structured_provider_aliases and is_map(value) ->
          {:cont, :ok}

        {:ok, value} ->
          if execution_identity_matches?(value, expected),
            do: {:cont, :ok},
            else: {:halt, execution_identity_conflict(path <> "." <> field, expected, value)}
      end
    end)
  end

  defp validate_serialized_execution_identity_surfaces(map) do
    if serialized_policy_request?(map) do
      Enum.reduce_while(@serialized_execution_identity_surfaces, :ok, fn {fields, expected},
                                                                         :ok ->
        path = "$." <> Enum.join(fields, ".")

        case fetch_path(map, fields) do
          {:ok, ^expected} -> {:cont, :ok}
          {:ok, actual} -> {:halt, execution_identity_conflict(path, expected, actual)}
          :error -> {:halt, execution_identity_conflict(path, expected, :missing)}
        end
      end)
    else
      :ok
    end
  end

  defp execution_identity_matches?(value, expected) when is_binary(value) do
    value == expected or
      (String.starts_with?(expected, "OrbitalDynamics.") and value == "Elixir." <> expected)
  end

  defp execution_identity_matches?(_value, _expected), do: false

  defp execution_identity_conflict(path, expected, actual),
    do: {:error, {:conflicting_execution_identity, path, expected, actual}}

  defp fetch_path(map, fields) do
    Enum.reduce_while(fields, {:ok, map}, fn field, {:ok, value} ->
      case value do
        %{} ->
          case Map.fetch(value, field) do
            {:ok, child} -> {:cont, {:ok, child}}
            :error -> {:halt, :error}
          end

        _value ->
          {:halt, :error}
      end
    end)
  end

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

  defp policy_normalization_mode(%{} = input) do
    if serialized_policy_request?(input), do: :serialized, else: :public
  end

  defp policy_normalization_mode(_input), do: :public

  defp serialized_policy_request?(map) do
    Enum.any?(
      ["schema_contract", :schema_contract, "policy_fingerprint", :policy_fingerprint],
      &Map.has_key?(map, &1)
    )
  end

  defp input_map(%_{} = value, _mode),
    do: {:error, {:unsupported_json_value, "$", {:struct, value.__struct__}}}

  defp input_map(%{} = map, :serialized), do: normalize_serialized_value(map, "$")
  defp input_map(%{} = map, :public), do: normalize_public_value(map, "$")
  defp input_map(_input, _mode), do: {:error, {:invalid_policy_input, :execution_policy}}

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

  defp validate_projection(field, values, expected, normalizer) do
    normalized_expected = normalizer.(expected)

    normalized =
      values
      |> Enum.reject(&is_nil/1)
      |> Enum.map(normalizer)

    cond do
      is_nil(normalized_expected) ->
        {:error, {:invalid_identity_projection, field}}

      Enum.any?(normalized, &is_nil/1) ->
        {:error, {:invalid_identity_projection, field}}

      Enum.all?(normalized, &(&1 == normalized_expected)) ->
        :ok

      true ->
        {:error, {:conflicting_identity_projection, field}}
    end
  end

  defp validate_horizon_projections(refresh, accepted_state, mission_state, coverage) do
    [
      refresh["remaining_horizon"],
      accepted_state["remaining_horizon"],
      mission_state["remaining_horizon"]
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.reduce_while(:ok, fn projection, :ok ->
      case normalize_horizon_identity(projection) do
        {:ok, ^coverage} -> {:cont, :ok}
        {:ok, _other} -> {:halt, {:error, {:conflicting_identity_projection, :remaining_horizon}}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp normalize_horizon_identity(%{} = horizon) do
    starts_at_s = Map.get(horizon, "starts_at_s")
    ends_at_s = Map.get(horizon, "ends_at_s")
    output_step_s = Map.get(horizon, "output_step_s")
    stated_duration_s = Map.get(horizon, "duration_s")

    with starts_at_s when not is_nil(starts_at_s) <- identity_number(starts_at_s),
         ends_at_s when not is_nil(ends_at_s) <- identity_number(ends_at_s),
         output_step_s when not is_nil(output_step_s) <- identity_number(output_step_s),
         duration_s when not is_nil(duration_s) <-
           identity_number(
             if(is_nil(stated_duration_s),
               do: ends_at_s - starts_at_s,
               else: stated_duration_s
             )
           ),
         true <- duration_s == ends_at_s - starts_at_s do
      {:ok,
       %{
         "starts_at_s" => starts_at_s,
         "ends_at_s" => ends_at_s,
         "output_step_s" => output_step_s
       }}
    else
      _value -> {:error, {:invalid_identity_projection, :remaining_horizon}}
    end
  rescue
    ArithmeticError -> {:error, {:invalid_identity_projection, :remaining_horizon}}
  end

  defp normalize_horizon_identity(_horizon),
    do: {:error, {:invalid_identity_projection, :remaining_horizon}}

  defp identity_string(value) when is_binary(value) and value != "", do: value
  defp identity_string(_value), do: nil

  defp identity_token(value) when is_binary(value) do
    case value |> String.trim() |> String.downcase() do
      "" -> nil
      normalized -> normalized
    end
  end

  defp identity_token(_value), do: nil

  defp identity_number(value) when is_number(value) and value >= -1.0e300 and value <= 1.0e300,
    do: value * 1.0

  defp identity_number(_value), do: nil

  defp candidate_source_window_binding(
         %{
           "id" => source_window_id,
           "type" => "ground_station_access",
           "scenario_id" => scenario_id,
           "ground_station_id" => ground_station_id,
           "assumptions" => %{} = assumptions
         } = window,
         index
       )
       when is_binary(source_window_id) and is_binary(scenario_id) and
              is_binary(ground_station_id) do
    timing_fields =
      CandidateActivityFields.event_timing_keys()
      |> Enum.map(&Atom.to_string/1)

    source_window =
      window
      |> Map.take(["id", "type", "max_elevation_deg", "minimum_elevation_deg"])
      |> Map.merge(Map.take(assumptions, timing_fields))

    {:ok,
     %{
       "candidate_activity_id" =>
         CandidateActivityFields.activity_id(
           scenario_id,
           "downlink",
           ground_station_id,
           index
         ),
       "source_window_id" => source_window_id,
       "source_window" => source_window
     }}
  end

  defp candidate_source_window_binding(_window, index),
    do: {:error, {:invalid_access_window_binding, index}}

  defp current_executable_beam_digests do
    executable_modules()
    |> Enum.reduce_while({:ok, %{}}, fn {name, module}, {:ok, acc} ->
      case executable_beam_digest(module) do
        {:ok, digest} -> {:cont, {:ok, Map.put(acc, name, digest)}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp executable_modules, do: @executable_modules

  for {_name, module} <- @executable_modules do
    defp executable_beam_digest(unquote(module)) do
      executable_beam_digest(unquote(module), fn ->
        encode_beam_md5(unquote(module), unquote(module).module_info(:md5))
      end)
    end
  end

  defp executable_beam_digest(module, digest_fun) do
    try do
      digest_fun.()
    rescue
      _error -> unavailable_executable_beam_digest(module)
    catch
      _kind, _reason -> unavailable_executable_beam_digest(module)
    end
  end

  defp encode_beam_md5(_module, digest) when is_binary(digest) and byte_size(digest) == 16,
    do: {:ok, Base.encode16(digest, case: :lower)}

  defp encode_beam_md5(module, _digest),
    do: unavailable_executable_beam_digest(module)

  defp unavailable_executable_beam_digest(module),
    do: {:error, {:execution_policy_drift, {:unavailable_executable_beam_digest, module}}}

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

  defp normalize_public_value(value, path), do: normalize_root(value, path, :public)
  defp normalize_internal_value(value, path), do: normalize_root(value, path, :internal)
  defp normalize_serialized_value(value, path), do: normalize_root(value, path, :serialized)

  defp normalize_root(value, path, mode) do
    budget = %{visited_terms: 0, total_byte_work: 0}

    case normalize_value(value, path, mode, 0, budget) do
      {:ok, normalized, _budget} -> {:ok, normalized}
      {:error, reason} -> {:error, reason}
    end
  end

  defp normalize_value(_value, path, _mode, depth, _budget)
       when depth > @max_normalization_depth,
       do: normalization_limit(path, :max_depth, @max_normalization_depth)

  defp normalize_value(value, path, mode, depth, budget) do
    with {:ok, budget} <- visit_term(path, budget) do
      cond do
        is_struct(value) ->
          unsupported_value(mode, path, :struct)

        is_map(value) ->
          normalize_map(value, path, mode, depth, budget)

        list_shaped?(value) ->
          normalize_list(value, path, mode, depth, budget, 0, [])

        is_boolean(value) ->
          {:ok, value, budget}

        value == :null ->
          {:ok, value, budget}

        is_nil(value) and mode in [:public, :internal] ->
          {:ok, :null, budget}

        is_nil(value) and mode == :artifact ->
          {:ok, nil, budget}

        is_nil(value) ->
          {:error, {:noncanonical_null, path}}

        is_binary(value) and byte_size(value) > @max_binary_bytes ->
          normalization_limit(path, :max_binary_bytes, @max_binary_bytes)

        is_binary(value) and not String.valid?(value) ->
          {:error, {:invalid_utf8_string, path}}

        is_binary(value) ->
          with {:ok, budget} <- consume_byte_work(path, budget, byte_size(value)) do
            {:ok, value, budget}
          end

        is_number(value) and finite_number?(value) ->
          {:ok, value, budget}

        is_number(value) ->
          {:error, {:non_finite_number, path}}

        is_tuple(value) ->
          unsupported_value(mode, path, :tuple)

        is_bitstring(value) ->
          unsupported_value(mode, path, :bitstring)

        is_atom(value) and mode == :internal ->
          normalized = Atom.to_string(value)

          with {:ok, budget} <- consume_byte_work(path, budget, byte_size(normalized)) do
            {:ok, normalized, budget}
          end

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
  end

  defp normalize_map(map, path, _mode, _depth, _budget)
       when map_size(map) > @max_collection_size,
       do: normalization_limit(path, :max_map_size, @max_collection_size)

  defp normalize_map(map, path, mode, depth, budget) do
    map
    |> Enum.sort_by(fn {key, _value} -> encoded_public_key(key) end)
    |> Enum.reduce_while({:ok, %{}, MapSet.new(), budget}, fn
      {key, value}, {:ok, acc, seen, current_budget} ->
        with {:ok, current_budget} <- visit_term(path, current_budget),
             {:ok, normalized_key} <- normalize_public_key(key, path),
             {:ok, current_budget} <-
               consume_byte_work(path, current_budget, byte_size(normalized_key)),
             false <- MapSet.member?(seen, normalized_key),
             {:ok, normalized_value, current_budget} <-
               normalize_value(
                 value,
                 path <> "." <> normalized_key,
                 mode,
                 depth + 1,
                 current_budget
               ) do
          {:cont,
           {:ok, Map.put(acc, normalized_key, normalized_value), MapSet.put(seen, normalized_key),
            current_budget}}
        else
          true ->
            {:halt, {:error, {:duplicate_normalized_key, path, encoded_public_key(key)}}}

          {:error, reason} ->
            {:halt, {:error, reason}}
        end
    end)
    |> case do
      {:ok, normalized, _seen, current_budget} -> {:ok, normalized, current_budget}
      {:error, reason} -> {:error, reason}
    end
  end

  defp normalize_list([], _path, _mode, _depth, budget, _index, acc),
    do: {:ok, Enum.reverse(acc), budget}

  defp normalize_list([_head | _tail], path, _mode, _depth, _budget, index, _acc)
       when index >= @max_collection_size,
       do: normalization_limit(path, :max_list_size, @max_collection_size)

  defp normalize_list([head | tail], path, mode, depth, budget, index, acc) do
    case normalize_value(head, "#{path}[#{index}]", mode, depth + 1, budget) do
      {:ok, normalized, current_budget} ->
        normalize_list(
          tail,
          path,
          mode,
          depth,
          current_budget,
          index + 1,
          [normalized | acc]
        )

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp normalize_list(_improper, path, mode, _depth, _budget, _index, _acc),
    do: unsupported_value(mode, path, :improper_list)

  defp visit_term(path, %{visited_terms: visited}) when visited >= @max_visited_terms,
    do: normalization_limit(path, :max_visited_terms, @max_visited_terms)

  defp visit_term(_path, budget),
    do: {:ok, Map.update!(budget, :visited_terms, &(&1 + 1))}

  defp consume_byte_work(path, %{total_byte_work: total}, bytes)
       when total + bytes > @max_total_byte_work,
       do: normalization_limit(path, :max_total_byte_work, @max_total_byte_work)

  defp consume_byte_work(_path, budget, bytes),
    do: {:ok, Map.update!(budget, :total_byte_work, &(&1 + bytes))}

  defp normalization_limit(path, limit, maximum),
    do: {:error, {:normalization_limit_exceeded, path, limit, maximum}}

  defp unsupported_value(:public, path, type),
    do: {:error, {:unsupported_json_value, path, type}}

  defp unsupported_value(:internal, path, type),
    do: {:error, {:unsupported_internal_value, path, type}}

  defp unsupported_value(:artifact, path, type),
    do: {:error, {:unsupported_json_value, path, type}}

  defp unsupported_value(:serialized, path, type),
    do: {:error, {:unsupported_json_value, path, type}}

  defp normalize_public_key(key, path) when is_atom(key) do
    key
    |> Atom.to_string()
    |> normalize_public_key(path)
  end

  defp normalize_public_key(key, path) when is_binary(key) do
    cond do
      byte_size(key) > @max_key_bytes ->
        normalization_limit(path, :max_key_bytes, @max_key_bytes)

      not String.valid?(key) ->
        {:error, {:invalid_utf8_key, path}}

      true ->
        {:ok, key}
    end
  end

  defp normalize_public_key(_key, path),
    do: {:error, {:unsupported_map_key, path}}

  defp encoded_public_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encoded_public_key(key) when is_binary(key), do: key
  defp encoded_public_key(_key), do: :unsupported_key

  defp list_shaped?([]), do: true
  defp list_shaped?([_head | _tail]), do: true
  defp list_shaped?(_value), do: false

  defp finite_number?(value),
    do: is_number(value) and value >= -1.0e300 and value <= 1.0e300
end
