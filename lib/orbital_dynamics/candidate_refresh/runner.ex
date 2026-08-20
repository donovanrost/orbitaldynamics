defmodule OrbitalDynamics.CandidateRefresh.Runner do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.{Build, ExecutionPolicy}
  alias OrbitalDynamics.Environment.ExponentialAtmosphereProvider
  alias OrbitalDynamics.EventDetectors.{AccessWindows, Eclipses}
  alias OrbitalDynamics.Propagators.J2Drag

  alias OrbitalDynamics.{
    CentralBody,
    Epoch,
    Frame,
    GroundStation,
    ResultSet,
    Scenario,
    Schema,
    Spacecraft,
    StateVector
  }

  @allowed_option_keys [
    :bundle,
    :bundle_id,
    :execution_bundle,
    :execution_bundle_id,
    :execution_policy,
    :generated_at,
    :ground_station,
    :spacecraft,
    :spacecraft_properties,
    :station,
    :study_id
  ]

  @bundle_aliases ~w(bundle bundle_id execution_bundle execution_bundle_id)
  @spacecraft_aliases ~w(spacecraft spacecraft_properties)
  @station_aliases ~w(ground_station station)
  @runner_only_refresh_keys @bundle_aliases ++
                              @spacecraft_aliases ++
                              @station_aliases ++
                              ["execution_policy", "study_id"]
  @geometry_fields ~w(latitude_deg longitude_deg altitude_km minimum_elevation_deg)
  @coverage_keys ~w(ends_at_s output_step_s starts_at_s)
  @order_invariant_list_fields ~w(
    ground_network
    prior_candidate_activities
    resource_summaries
    station_calendar
    targets
  )

  @type stage ::
          :validate_input
          | :capture_policy
          | :build_scenario
          | :propagate
          | :detect_ground_station_access
          | :detect_eclipse
          | :build_artifact
          | :validate_artifact

  @type execution_error :: {:candidate_refresh_execution_failed, stage(), term()}

  def run(refresh, opts) do
    with {:ok, context} <-
           stage(:validate_input, fn -> validate_input(refresh, opts) end),
         {:ok, policy} <-
           stage(:capture_policy, fn -> ExecutionPolicy.capture(context.policy_input) end),
         {:ok, scenario} <-
           stage(:build_scenario, fn -> build_scenario(context, policy) end),
         {:ok, trajectory} <-
           stage(:propagate, fn -> propagate(scenario, policy) end),
         {:ok, access_events} <-
           stage(:detect_ground_station_access, fn ->
             detect_ground_station_access(trajectory, context.ground_station, policy)
           end),
         {:ok, eclipse_events} <-
           stage(:detect_eclipse, fn -> detect_eclipse(trajectory, policy) end),
         {:ok, artifact} <-
           stage(:build_artifact, fn ->
             build_artifact(context, policy, trajectory, access_events, eclipse_events)
           end),
         {:ok, _report} <-
           stage(:validate_artifact, fn -> Schema.validate_artifact(artifact) end) do
      {:ok, artifact}
    end
  end

  defp validate_input(%{} = input, opts) do
    with {:ok, refresh} <- ExecutionPolicy.normalize_json_input(input),
         {:ok, options} <- normalize_options(opts),
         :ok <- reject_reserved_collision(refresh),
         :ok <- reject_execution_output_collision(refresh),
         :ok <- reject_external_execution_providers(refresh),
         {:ok, accepted_state} <- direct_accepted_state(refresh),
         :ok <- validate_accepted_state_contract(accepted_state),
         {:ok, state} <- single_spacecraft_state(accepted_state),
         :ok <- reject_maneuvers(accepted_state, state),
         {:ok, current_epoch_s, horizon} <- aligned_horizon(refresh, state),
         {:ok, policy_source} <- policy_source(refresh, accepted_state, state, options),
         {:ok, preliminary_policy} <- ExecutionPolicy.validate_request(policy_source),
         :ok <- validate_policy_state_match(preliminary_policy, state),
         {:ok, canonical_state} <- canonical_initial_state(accepted_state, state),
         canonical_coverage = canonical_coverage(horizon),
         {:ok, policy_input} <-
           complete_policy_input(policy_source, canonical_state, canonical_coverage),
         {:ok, normalized_policy} <- ExecutionPolicy.validate_request(policy_input),
         :ok <- validate_ground_network(refresh, accepted_state, normalized_policy.ground_station),
         {:ok, generated_at} <- generated_at(options),
         {:ok, study_id} <- study_id(refresh, options, state),
         {:ok, normalized_refresh} <-
           normalize_refresh(refresh, accepted_state, current_epoch_s, horizon) do
      {:ok,
       %{
         refresh: normalized_refresh,
         policy_input: policy_input,
         spacecraft: normalized_policy.spacecraft,
         ground_station: normalized_policy.ground_station,
         generated_at: generated_at,
         study_id: study_id
       }}
    end
  end

  defp validate_input(_refresh, _opts), do: {:error, {:invalid_input, :candidate_refresh}}

  defp normalize_options(opts) when is_list(opts) do
    cond do
      not Keyword.keyword?(opts) ->
        {:error, {:invalid_option, :options}}

      duplicate_values(Keyword.keys(opts)) != [] ->
        {:error, {:duplicate_option_aliases, duplicate_values(Keyword.keys(opts))}}

      unsupported = Keyword.keys(opts) -- @allowed_option_keys ->
        case unsupported do
          [] ->
            {:ok,
             Enum.reduce(opts, %{}, fn {key, value}, acc ->
               Map.put(acc, Atom.to_string(key), value)
             end)}

          [key | _rest] ->
            {:error, {:unsupported_option, key}}
        end
    end
  end

  defp normalize_options(_opts), do: {:error, {:invalid_option, :options}}

  defp direct_accepted_state(refresh) do
    case cross_source_alias_value([refresh], ["accepted_planning_state"], :required) do
      {:ok, %{} = accepted_state} -> {:ok, accepted_state}
      {:ok, _value} -> {:error, {:invalid_input, :accepted_planning_state}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_accepted_state_contract(accepted_state) do
    case Schema.validate_artifact(accepted_state,
           schema_contract: "accepted_planning_state.v1"
         ) do
      {:ok, _report} -> :ok
      {:error, report} -> {:error, {:invalid_accepted_planning_state, report}}
    end
  end

  defp single_spacecraft_state(%{"spacecraft_states" => []}),
    do: {:error, {:missing_spacecraft_state, :accepted_planning_state}}

  defp single_spacecraft_state(%{"spacecraft_states" => [%{} = state]}), do: {:ok, state}

  defp single_spacecraft_state(%{"spacecraft_states" => states}) when is_list(states),
    do: {:error, {:multiple_spacecraft_states, length(states)}}

  defp single_spacecraft_state(_accepted_state),
    do: {:error, {:invalid_input, :spacecraft_states}}

  defp reject_maneuvers(accepted_state, state) do
    deltas = Map.get(accepted_state, "maneuver_execution_deltas", [])
    maneuvers = Map.get(state, "maneuvers", [])

    cond do
      deltas != [] -> {:error, {:unsupported_input, :maneuver_execution_deltas}}
      maneuvers not in [nil, []] -> {:error, {:unsupported_input, :maneuvers}}
      true -> :ok
    end
  end

  defp aligned_horizon(refresh, state) do
    with {:ok, current_epoch_s} <-
           cross_source_alias_value([refresh], ["current_epoch_s"], :required),
         {:ok, current_epoch_s} <- finite_number(current_epoch_s, :current_epoch_s),
         {:ok, state_epoch_s} <-
           state
           |> get_in(["epoch", "seconds_since_j2000"])
           |> finite_number(:state_epoch_s),
         :ok <-
           require_equal(
             current_epoch_s,
             state_epoch_s,
             {:misaligned_epoch, :current_epoch_s}
           ),
         {:ok, horizon} <-
           cross_source_alias_value([refresh], ["remaining_horizon"], :required),
         {:ok, horizon} <- validate_horizon(horizon, current_epoch_s) do
      {:ok, current_epoch_s, horizon}
    end
  end

  defp validate_horizon(%{} = horizon, current_epoch_s) do
    with {:ok, starts_at_s} <-
           cross_source_alias_value([horizon], ["starts_at_s"], :required),
         {:ok, ends_at_s} <-
           cross_source_alias_value([horizon], ["ends_at_s"], :required),
         {:ok, output_step_s} <-
           cross_source_alias_value([horizon], ["output_step_s"], :required),
         {:ok, starts_at_s} <- finite_number(starts_at_s, :starts_at_s),
         {:ok, ends_at_s} <- finite_number(ends_at_s, :ends_at_s),
         {:ok, output_step_s} <- finite_number(output_step_s, :output_step_s),
         :ok <- require_equal(starts_at_s, current_epoch_s, {:misaligned_horizon, :starts_at_s}),
         :ok <- require_equal(output_step_s, 10.0, {:unsupported_cadence, output_step_s}),
         :ok <- validate_horizon_duration(starts_at_s, ends_at_s),
         :ok <- validate_optional_duration(horizon, starts_at_s, ends_at_s) do
      {:ok,
       %{
         "starts_at_s" => starts_at_s,
         "ends_at_s" => ends_at_s,
         "output_step_s" => output_step_s
       }}
    end
  end

  defp validate_horizon(_horizon, _current_epoch_s),
    do: {:error, {:invalid_input, :remaining_horizon}}

  defp validate_horizon_duration(starts_at_s, ends_at_s) do
    duration_s = ends_at_s - starts_at_s

    cond do
      duration_s <= 0.0 -> {:error, {:invalid_horizon, :non_positive_duration}}
      duration_s > 86_400.0 -> {:error, {:unsupported_horizon, :maximum_24_hours}}
      true -> :ok
    end
  end

  defp validate_optional_duration(horizon, starts_at_s, ends_at_s) do
    case cross_source_alias_value([horizon], ["duration_s"], :missing) do
      {:ok, :missing} ->
        :ok

      {:ok, value} ->
        with {:ok, duration_s} <- finite_number(value, :duration_s),
             :ok <-
               require_equal(
                 duration_s,
                 ends_at_s - starts_at_s,
                 {:misaligned_horizon, :duration_s}
               ) do
          :ok
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp policy_source(refresh, accepted_state, state, options) do
    execution_policy_sources = [options, refresh]

    case cross_source_alias_value(execution_policy_sources, ["execution_policy"], :missing) do
      {:ok, :missing} ->
        flat_policy_source(refresh, accepted_state, state, options)

      {:ok, %{} = policy} ->
        with :ok <- reject_flat_policy_aliases_when_captured(refresh, options),
             {:ok, policy} <-
               enrich_policy_source(policy, refresh, accepted_state, state, options) do
          {:ok, policy}
        end

      {:ok, _value} ->
        {:error, {:invalid_policy_input, :execution_policy}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp flat_policy_source(refresh, accepted_state, state, options) do
    with {:ok, bundle} <-
           cross_source_alias_value(
             [options, refresh],
             @bundle_aliases,
             ExecutionPolicy.bundle_id()
           ),
         {:ok, spacecraft} <- explicit_spacecraft(refresh, state, options),
         {:ok, ground_station} <-
           explicit_ground_station(refresh, accepted_state, options) do
      {:ok,
       %{
         "bundle_id" => bundle,
         "spacecraft" => spacecraft,
         "ground_station" => ground_station
       }}
    end
  end

  defp enrich_policy_source(policy, refresh, accepted_state, state, options) do
    with {:ok, spacecraft} <-
           policy_value_or(policy, "spacecraft", fn ->
             explicit_spacecraft(refresh, state, options)
           end),
         {:ok, ground_station} <-
           policy_value_or(policy, "ground_station", fn ->
             explicit_ground_station(refresh, accepted_state, options)
           end) do
      {:ok,
       policy
       |> put_alias_if_missing("spacecraft", spacecraft)
       |> put_alias_if_missing("ground_station", ground_station)}
    end
  end

  defp policy_value_or(policy, field, fallback) do
    case cross_source_alias_value([policy], [field], :missing) do
      {:ok, :missing} -> fallback.()
      {:ok, value} -> {:ok, value}
      {:error, reason} -> {:error, reason}
    end
  end

  defp explicit_spacecraft(refresh, state, options) do
    case cross_source_alias_value([options, refresh], @spacecraft_aliases, :missing) do
      {:ok, :missing} -> spacecraft_from_state_metadata(state)
      {:ok, %{} = spacecraft} -> {:ok, enrich_spacecraft_identity(spacecraft, state)}
      {:ok, _value} -> {:error, {:invalid_policy_input, :spacecraft}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp spacecraft_from_state_metadata(state) do
    case Map.get(state, "metadata") do
      %{} = metadata ->
        {:ok, enrich_spacecraft_identity(metadata, state)}

      _metadata ->
        {:error, {:missing_policy_input, :spacecraft}}
    end
  end

  defp enrich_spacecraft_identity(spacecraft, state) do
    spacecraft
    |> put_alias_if_missing("spacecraft_id", state["spacecraft_id"])
    |> put_alias_if_missing("scenario_id", state["scenario_id"])
  end

  defp explicit_ground_station(refresh, accepted_state, options) do
    case cross_source_alias_value([options, refresh], @station_aliases, :missing) do
      {:ok, :missing} -> station_from_ground_network(refresh, accepted_state)
      {:ok, %{} = station} -> {:ok, station}
      {:ok, _value} -> {:error, {:invalid_policy_input, :ground_station}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp station_from_ground_network(refresh, accepted_state) do
    with {:ok, rows} <- ground_network_rows(refresh, accepted_state),
         full_rows = Enum.filter(rows, &full_geometry_row?/1),
         [%{} = station | _rest] <- full_rows do
      {:ok, station}
    else
      [] -> {:error, {:missing_policy_input, :ground_station}}
      {:error, reason} -> {:error, reason}
      _value -> {:error, {:invalid_policy_input, :ground_station}}
    end
  end

  defp reject_flat_policy_aliases_when_captured(refresh, options) do
    flat_aliases = @bundle_aliases ++ @spacecraft_aliases ++ @station_aliases

    case cross_source_alias_value([options, refresh], flat_aliases, :missing) do
      {:ok, :missing} -> :ok
      {:ok, _value} -> {:error, {:duplicate_aliases, :execution_policy}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_policy_state_match(%{spacecraft: nil}, _state),
    do: {:error, {:missing_policy_input, :spacecraft}}

  defp validate_policy_state_match(%{ground_station: nil}, _state),
    do: {:error, {:missing_policy_input, :ground_station}}

  defp validate_policy_state_match(policy, state) do
    cond do
      policy.spacecraft["spacecraft_id"] != state["spacecraft_id"] ->
        {:error, {:mismatched_spacecraft_state, :spacecraft_id}}

      policy.spacecraft["scenario_id"] != state["scenario_id"] ->
        {:error, {:mismatched_spacecraft_state, :scenario_id}}

      true ->
        :ok
    end
  end

  defp canonical_initial_state(accepted_state, state) do
    body = declared_body(state, accepted_state)

    input = %{
      "snapshot_id" => accepted_state["snapshot_id"],
      "spacecraft_id" => state["spacecraft_id"],
      "scenario_id" => state["scenario_id"],
      "body" => body,
      "frame" => state["frame"],
      "time_scale" => get_in(state, ["epoch", "time_scale"]),
      "epoch_s" => get_in(state, ["epoch", "seconds_since_j2000"]),
      "position_km" => get_in(state, ["state_vector", "position_km"]),
      "velocity_km_s" => get_in(state, ["state_vector", "velocity_km_s"])
    }

    with {:ok, request} <-
           ExecutionPolicy.validate_request(%{
             "spacecraft" => %{
               "spacecraft_id" => state["spacecraft_id"],
               "scenario_id" => state["scenario_id"],
               "dry_mass_kg" => 1.0,
               "propellant_mass_kg" => 0.0,
               "drag_area_m2" => 0.0,
               "drag_coefficient" => 0.0
             },
             "ground_station" => %{
               "ground_station_id" => "validation_station",
               "latitude_deg" => 0.0,
               "longitude_deg" => 0.0,
               "altitude_km" => 0.0,
               "minimum_elevation_deg" => 0.0
             },
             "initial_state" => input
           }) do
      {:ok, request.initial_state}
    end
  end

  defp declared_body(state, accepted_state) do
    values = [
      Map.get(state, "body"),
      get_in(state, ["metadata", "body"]),
      get_in(state, ["metadata", "center_name"]),
      get_in(accepted_state, ["source", "body"]),
      get_in(accepted_state, ["source", "center_name"]),
      "earth"
    ]

    values
    |> Enum.find(&(&1 not in [nil, ""]))
    |> case do
      value when is_binary(value) -> String.downcase(value)
      value when is_atom(value) -> value |> Atom.to_string() |> String.downcase()
      value -> value
    end
  end

  defp canonical_coverage(horizon), do: Map.take(horizon, @coverage_keys)

  defp complete_policy_input(policy, canonical_state, canonical_coverage) do
    with {:ok, policy} <- put_verified_alias(policy, "initial_state", canonical_state),
         {:ok, policy} <- put_verified_alias(policy, "coverage", canonical_coverage) do
      {:ok, policy}
    end
  end

  defp put_verified_alias(map, field, value) do
    case cross_source_alias_value([map], [field], :missing) do
      {:ok, :missing} -> {:ok, Map.put(map, field, value)}
      {:ok, ^value} -> {:ok, map}
      {:ok, _other} -> {:error, {:policy_state_mismatch, field}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_ground_network(refresh, accepted_state, ground_station) do
    with {:ok, rows} <- ground_network_rows(refresh, accepted_state) do
      Enum.reduce_while(rows, :ok, fn row, :ok ->
        case validate_ground_network_row(row, ground_station) do
          :ok -> {:cont, :ok}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)
    end
  end

  defp ground_network_rows(refresh, accepted_state) do
    sources = [
      Map.get(refresh, "ground_network"),
      Map.get(accepted_state, "ground_network"),
      get_in(refresh, ["mission_state", "ground_network"])
    ]

    Enum.reduce_while(sources, {:ok, []}, fn
      nil, {:ok, rows} ->
        {:cont, {:ok, rows}}

      [], {:ok, rows} ->
        {:cont, {:ok, rows}}

      source_rows, {:ok, rows} when is_list(source_rows) ->
        if Enum.all?(source_rows, &is_map/1),
          do: {:cont, {:ok, rows ++ source_rows}},
          else: {:halt, {:error, {:invalid_station_input, :ground_network}}}

      _source, _acc ->
        {:halt, {:error, {:invalid_station_input, :ground_network}}}
    end)
  end

  defp validate_ground_network_row(row, ground_station) do
    with :ok <- reject_duplicate_row_aliases(row),
         :ok <- reject_ground_network_provider(row),
         {:ok, station_id} <- ground_network_station_id(row),
         :ok <-
           require_equal(
             station_id,
             ground_station["ground_station_id"],
             {:multiple_ground_station_geometry, station_id}
           ),
         :ok <- compare_geometry(row, ground_station) do
      :ok
    end
  end

  defp ground_network_station_id(row) do
    case cross_source_alias_value([row], ~w(ground_station_id station_id id), :required) do
      {:ok, value} when is_atom(value) -> {:ok, Atom.to_string(value)}
      {:ok, value} when is_binary(value) -> {:ok, value}
      {:ok, _value} -> {:error, {:invalid_station_input, :ground_station_id}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp compare_geometry(row, expected) do
    Enum.reduce_while(@geometry_fields, :ok, fn field, :ok ->
      expected_value = Map.fetch!(expected, field)

      case cross_source_alias_value([row], [field], :missing) do
        {:ok, :missing} ->
          {:cont, :ok}

        {:ok, value} when is_number(value) and value == expected_value ->
          {:cont, :ok}

        {:ok, _value} ->
          {:halt, {:error, {:conflicting_ground_network_geometry, field}}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
  end

  defp reject_duplicate_row_aliases(row) do
    alias_groups = [~w(ground_station_id station_id id)] ++ Enum.map(@geometry_fields, &[&1])

    Enum.reduce_while(alias_groups, :ok, fn aliases, :ok ->
      case cross_source_alias_value([row], aliases, :missing) do
        {:ok, _value} -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp reject_ground_network_provider(row) do
    provider_fields = ~w(provider provider_id station_calendar_provider campaign_environment)

    cond do
      Enum.any?(provider_fields, &map_has_alias?(row, &1)) ->
        {:error, :campaign_provider_rejected}

      Map.get(row, "network_access") == true ->
        {:error, :network_access_rejected}

      true ->
        :ok
    end
  end

  defp full_geometry_row?(row) do
    is_map(row) and Enum.all?(@geometry_fields, &map_has_alias?(row, &1)) and
      Enum.any?(~w(ground_station_id station_id id), &map_has_alias?(row, &1))
  end

  defp generated_at(options) do
    case Map.get(options, "generated_at") do
      nil -> {:ok, DateTime.utc_now()}
      %DateTime{} = generated_at -> {:ok, generated_at}
      _value -> {:error, {:invalid_option, :generated_at}}
    end
  end

  defp study_id(refresh, options, state) do
    case cross_source_alias_value([options, refresh], ["study_id"], state["scenario_id"]) do
      {:ok, value} when is_binary(value) -> validate_study_id(value)
      {:ok, _value} -> {:error, {:invalid_input, :study_id}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_study_id(value) do
    if OrbitalDynamics.Schema.StableIdValidation.valid?(value),
      do: {:ok, value},
      else: {:error, {:invalid_input, :study_id}}
  end

  defp normalize_refresh(refresh, accepted_state, current_epoch_s, horizon) do
    normalized =
      refresh
      |> Map.drop(@runner_only_refresh_keys)
      |> Map.put("accepted_planning_state", accepted_state)
      |> Map.put("current_epoch_s", current_epoch_s)
      |> Map.put("remaining_horizon", horizon)
      |> canonicalize_refresh_order()

    {:ok, normalized}
  end

  defp canonicalize_refresh_order(refresh) do
    Enum.reduce(@order_invariant_list_fields, refresh, fn field, acc ->
      case Map.get(acc, field) do
        values when is_list(values) ->
          Map.put(acc, field, Enum.sort_by(values, &stable_sort_key/1))

        _value ->
          acc
      end
    end)
  end

  defp reject_reserved_collision(refresh) do
    case cross_source_alias_value([refresh], ["model_assumptions"], :missing) do
      {:ok, :missing} ->
        :ok

      {:ok, %{} = assumptions} ->
        if map_has_alias?(assumptions, ExecutionPolicy.reserved_key()),
          do: {:error, {:reserved_key_collision, ExecutionPolicy.reserved_key()}},
          else: :ok

      {:ok, _value} ->
        {:error, {:invalid_input, :model_assumptions}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp reject_execution_output_collision(refresh) do
    if map_has_alias?(refresh, "candidate_refresh_execution"),
      do: {:error, {:reserved_key_collision, "candidate_refresh_execution"}},
      else: :ok
  end

  defp reject_external_execution_providers(refresh) do
    forbidden_paths = [
      ["atmosphere_provider"],
      ["earth_rotation_provider"],
      ["sun_direction_provider"],
      ["propagator"],
      ["access_detector"],
      ["eclipse_detector"],
      ["campaign_environment"],
      ["station_calendar_provider"],
      ["accepted_planning_state", "campaign_environment"],
      ["accepted_planning_state", "station_calendar_provider"],
      ["mission_state", "campaign_environment"],
      ["mission_state", "station_calendar_provider"]
    ]

    cond do
      Enum.any?(forbidden_paths, &(get_in(refresh, &1) not in [nil, :null, []])) ->
        {:error, :custom_or_campaign_provider_rejected}

      contains_true_network_access?(refresh) ->
        {:error, :network_access_rejected}

      true ->
        :ok
    end
  end

  defp contains_true_network_access?(%{} = map) do
    Enum.any?(map, fn {key, value} ->
      (key == "network_access" and value == true) or
        contains_true_network_access?(value)
    end)
  end

  defp contains_true_network_access?(values) when is_list(values),
    do: Enum.any?(values, &contains_true_network_access?/1)

  defp contains_true_network_access?(_value), do: false

  defp build_scenario(context, policy) do
    spacecraft_policy = context.spacecraft
    state_policy = ExecutionPolicy.serialize(policy)["initial_state"]
    coverage = ExecutionPolicy.serialize(policy)["coverage"]

    spacecraft =
      Spacecraft.new!(
        spacecraft_policy["spacecraft_id"],
        spacecraft_policy["dry_mass_kg"],
        propellant_mass_kg: spacecraft_policy["propellant_mass_kg"],
        area_m2: spacecraft_policy["drag_area_m2"],
        drag_coefficient: spacecraft_policy["drag_coefficient"]
      )

    initial_state =
      StateVector.new!(
        List.to_tuple(state_policy["position_km"]),
        List.to_tuple(state_policy["velocity_km_s"]),
        Epoch.new!(state_policy["epoch_s"], :tdb),
        Frame.earth_inertial_j2000()
      )

    {:ok,
     Scenario.new!(
       spacecraft_policy["scenario_id"],
       spacecraft,
       initial_state,
       duration_s: coverage["ends_at_s"] - coverage["starts_at_s"],
       output_step_s: coverage["output_step_s"],
       central_body: CentralBody.earth(),
       maneuvers: [],
       metadata: %{
         candidate_refresh_execution_policy_fingerprint: ExecutionPolicy.fingerprint(policy)
       }
     )}
  end

  defp propagate(scenario, policy) do
    document = ExecutionPolicy.serialize(policy)

    J2Drag.propagate(scenario,
      max_step_s: document["propagation"]["max_step_s"],
      atmosphere_provider: ExponentialAtmosphereProvider,
      atmosphere_source_revision:
        document["environment"]["atmosphere_provider"]["source_revision"]
    )
  end

  defp detect_ground_station_access(trajectory, station_policy, policy) do
    access_policy = ExecutionPolicy.serialize(policy)["access"]

    station =
      GroundStation.new!(
        station_policy["ground_station_id"],
        station_policy["latitude_deg"],
        station_policy["longitude_deg"],
        altitude_km: station_policy["altitude_km"],
        minimum_elevation_deg: station_policy["minimum_elevation_deg"]
      )

    AccessWindows.detect(trajectory,
      ground_station: station,
      central_body: CentralBody.earth(),
      boundary_refinement: :bracketed_bisection,
      root_tolerance_s: access_policy["root_tolerance_s"],
      root_max_iterations: access_policy["root_max_iterations"]
    )
  end

  defp detect_eclipse(trajectory, policy) do
    sun_direction =
      policy
      |> ExecutionPolicy.serialize()
      |> get_in(["environment", "sun_direction", "vector_eci_j2000"])
      |> List.to_tuple()

    Eclipses.detect(trajectory,
      central_body: CentralBody.earth(),
      sun_direction: sun_direction
    )
  end

  defp build_artifact(context, policy, trajectory, access_events, eclipse_events) do
    serialized_policy = ExecutionPolicy.serialize(policy)

    refresh =
      update_in(context.refresh, [Access.key("model_assumptions", %{})], fn assumptions ->
        Map.put(assumptions, ExecutionPolicy.reserved_key(), serialized_policy)
      end)

    result_set =
      ResultSet.new!(%{
        study_id: context.study_id,
        trajectory_results: [
          %{scenario_id: trajectory.scenario_id, trajectory: trajectory}
        ],
        event_results: [
          %{
            scenario_id: trajectory.scenario_id,
            event_type: :ground_station_access,
            events: access_events,
            source: %{ground_station_id: context.ground_station["ground_station_id"]}
          },
          %{
            scenario_id: trajectory.scenario_id,
            event_type: :eclipse,
            events: eclipse_events,
            source: %{shadow_model: :cylindrical_central_body_shadow}
          }
        ],
        errors: [],
        assumptions: %{
          propagator: J2Drag,
          propagator_opts: [
            max_step_s: serialized_policy["propagation"]["max_step_s"],
            atmosphere_provider: ExponentialAtmosphereProvider,
            atmosphere_source_revision:
              serialized_policy["environment"]["atmosphere_provider"]["source_revision"]
          ],
          outputs: [:access_windows, :eclipses],
          candidate_refresh_execution_policy_fingerprint: ExecutionPolicy.fingerprint(policy)
        },
        metadata: %{}
      })

    artifact =
      Build.build(result_set,
        candidate_refresh: refresh,
        generated_at: context.generated_at
      )

    {:ok,
     Map.put(
       artifact,
       "candidate_refresh_execution",
       execution_report(artifact, policy, trajectory, access_events, eclipse_events)
     )}
  end

  defp execution_report(artifact, policy, trajectory, access_events, eclipse_events) do
    document = ExecutionPolicy.serialize(policy)
    candidate_activities = Map.get(artifact, "candidate_activities", [])

    %{
      "schema_contract" => "candidate_refresh_execution.v1",
      "bundle_id" => ExecutionPolicy.bundle_id(),
      "execution_mode" => ExecutionPolicy.execution_mode(),
      "policy_fingerprint" => ExecutionPolicy.fingerprint(policy),
      "snapshot_id" => artifact["snapshot_id"],
      "counts" => %{
        "spacecraft_state_count" => 1,
        "ground_station_count" => 1,
        "trajectory_count" => 1,
        "trajectory_sample_count" => length(trajectory.states),
        "event_result_count" => 2,
        "access_window_count" => length(access_events),
        "eclipse_interval_count" => length(eclipse_events),
        "candidate_activity_count" => length(candidate_activities),
        "downlink_candidate_count" =>
          Enum.count(candidate_activities, &(&1["type"] == "downlink"))
      },
      "policies" => %{
        "propagation" => document["propagation"],
        "environment" => document["environment"],
        "access" => document["access"],
        "eclipse" => document["eclipse"]
      },
      "external_validation" => %{
        "case_id" => ExecutionPolicy.external_case_id(),
        "validation_scope" => "exact_case_only",
        "status" => "referenced_not_evaluated_by_runner"
      },
      "model_limits" => ExecutionPolicy.model_limits()
    }
  end

  defp stage(stage, fun) do
    try do
      case fun.() do
        {:ok, value} -> {:ok, value}
        {:error, reason} -> {:error, {:candidate_refresh_execution_failed, stage, reason}}
        other -> {:error, {:candidate_refresh_execution_failed, stage, {:invalid_return, other}}}
      end
    rescue
      error ->
        {:error,
         {:candidate_refresh_execution_failed, stage,
          {:exception, error.__struct__, Exception.message(error)}}}
    catch
      kind, reason ->
        {:error, {:candidate_refresh_execution_failed, stage, {:caught, kind, reason}}}
    end
  end

  defp cross_source_alias_value(sources, aliases, default) do
    present =
      for source <- sources,
          is_map(source),
          alias_key <- aliases,
          Map.has_key?(source, alias_key),
          do: {source, alias_key}

    case present do
      [] when default == :required -> {:error, {:missing_input, List.first(aliases)}}
      [] -> {:ok, default}
      [{source, key}] -> {:ok, Map.get(source, key)}
      _values -> {:error, {:duplicate_aliases, List.first(aliases)}}
    end
  end

  defp put_alias_if_missing(map, field, value) do
    case cross_source_alias_value([map], [field], :missing) do
      {:ok, :missing} -> Map.put(map, field, value)
      _value -> map
    end
  end

  defp map_has_alias?(map, field) do
    case cross_source_alias_value([map], [field], :missing) do
      {:ok, :missing} -> false
      _value -> true
    end
  end

  defp finite_number(value, _field)
       when is_number(value) and value >= -1.0e300 and value <= 1.0e300,
       do: {:ok, value * 1.0}

  defp finite_number(_value, field), do: {:error, {:invalid_numeric_input, field}}

  defp require_equal(value, value, _reason), do: :ok
  defp require_equal(_value, _expected, reason), do: {:error, reason}

  defp stable_sort_key(value), do: ExecutionPolicy.canonical_sort_key(value)

  defp duplicate_values(values) do
    values
    |> Enum.frequencies()
    |> Enum.filter(fn {_value, count} -> count > 1 end)
    |> Enum.map(&elem(&1, 0))
    |> Enum.sort()
  end
end
