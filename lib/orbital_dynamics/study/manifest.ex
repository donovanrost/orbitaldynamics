defmodule OrbitalDynamics.Study.Manifest do
  @moduledoc """
  JSON manifest loader for reproducible study execution.

  The first manifest schema is intentionally narrow. It supports explicit
  Cartesian scenarios, mission-plan timelines, and the deterministic
  `circular_leo` scenario generator used by benchmark/demo studies.
  """

  alias OrbitalDynamics.Benchmark.ScenarioFixture
  alias OrbitalDynamics.Maneuver.ImpulsiveBurn
  alias OrbitalDynamics.MissionPlan
  alias OrbitalDynamics.ResultSet.Report

  alias OrbitalDynamics.{
    CentralBody,
    Epoch,
    Frame,
    GroundStation,
    Scenario,
    ResourceSummary,
    Schema,
    Spacecraft,
    StateVector,
    Study,
    StudyRunner,
    Target,
    Search.Grid,
    Search.MonteCarlo
  }

  alias OrbitalDynamics.Study.Manifest.{
    ActivityInput,
    AtmosphereProviderInput,
    CandidateRefreshPlanningState,
    CandidateRefreshRunInputSources,
    FieldReference,
    GroundNetworkInput,
    GroundStationCatalogInput,
    GroundTrackCrossingInput,
    InputField,
    SchemaDocument,
    TargetCatalogInput,
    ValidationError
  }

  alias OrbitalDynamics.Propagators.{
    J2,
    J2ExlaCpu,
    TwoBody,
    TwoBodyDrag,
    TwoBodyExlaCpu,
    TwoBodyNx,
    TwoBodyNxCompiled
  }

  @schema_version 1
  @propagators %{
    "two_body" => TwoBody,
    "two_body_drag" => TwoBodyDrag,
    "two_body_nx" => TwoBodyNx,
    "two_body_nx_compiled" => TwoBodyNxCompiled,
    "two_body_exla_cpu" => TwoBodyExlaCpu,
    "j2" => J2,
    "j2_exla_cpu" => J2ExlaCpu
  }
  @propagator_opts %{
    "atmosphere_provider" => :atmosphere_provider,
    "max_step_s" => :max_step_s,
    "integration" => :integration,
    "min_step_s" => :min_step_s,
    "adaptive_position_tolerance_km" => :adaptive_position_tolerance_km,
    "adaptive_velocity_tolerance_km_s" => :adaptive_velocity_tolerance_km_s
  }
  @outputs %{
    "trajectories" => :trajectories,
    "access_windows" => :access_windows,
    "eclipses" => :eclipses,
    "target_visibility" => :target_visibility,
    "ground_track_crossings" => :ground_track_crossings
  }
  @json_schema_draft "https://json-schema.org/draft/2020-12/schema"
  @json_schema_contract "study_manifest.v1"
  @lint_schema_contract "study_manifest_lint.v1"
  @semantic_validator "OrbitalDynamics.Study.Manifest.from_map/1 + OrbitalDynamics.StudyRunner.validate_run_inputs/2"
  @lint_error_codes [
    "file_error",
    "invalid_field",
    "invalid_json",
    "invalid_json_object",
    "invalid_manifest",
    "invalid_output",
    "invalid_run_option",
    "manifest_error",
    "missing_field",
    "missing_run_option",
    "unsupported_central_body",
    "unsupported_option",
    "unsupported_output",
    "unsupported_propagator",
    "unsupported_schema_version"
  ]
  @run_option_keys %{
    "max_concurrency" => :max_concurrency,
    "timeout" => :timeout,
    "task_chunk_size" => :task_chunk_size
  }
  @search_objectives Report.supported_objectives()

  @enforce_keys [:study, :run_opts, :central_body, :ground_stations, :targets, :source]
  defstruct [:study, :run_opts, :central_body, :ground_stations, :targets, :source]

  @type t :: %__MODULE__{
          study: Study.t(),
          run_opts: keyword(),
          central_body: CentralBody.t(),
          ground_stations: [GroundStation.t()],
          targets: [Target.t()],
          source: map()
        }

  @doc """
  Loads a study manifest from JSON on disk.
  """
  def from_file(path) when is_binary(path) do
    with {:ok, content} <- File.read(path),
         {:ok, source} <- decode_json(content),
         {:ok, manifest} <- from_map(source) do
      manifest_metadata = %{
        path: path,
        sha256: sha256(content)
      }

      {:ok,
       %{
         manifest
         | run_opts: manifest.run_opts ++ [manifest: manifest_metadata],
           source: Map.put(manifest.source, "manifest_path", path)
       }}
    else
      {:error, %File.Error{} = error} -> {:error, {:file_error, error.reason, path}}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Decodes a JSON study manifest string.
  """
  def from_json(json) when is_binary(json) do
    with {:ok, source} <- decode_json(json), do: from_map(source)
  end

  @doc """
  Builds a runnable study manifest from a decoded JSON map.
  """
  def from_map(%{} = source) do
    with :ok <- validate_schema_version(source),
         {:ok, central_body} <- central_body(source),
         {:ok, scenarios} <- scenarios(source, central_body),
         {:ok, mission_plan_metadata} <- mission_plan_metadata(scenarios),
         {:ok, propagator} <- propagator(source),
         {:ok, propagator_opts} <- propagator_opts(source, propagator),
         {:ok, outputs} <- outputs(source),
         {:ok, ground_stations} <- GroundStationCatalogInput.parse(source),
         {:ok, targets} <- TargetCatalogInput.parse(source),
         {:ok, ground_track_crossings} <- ground_track_crossings(source),
         {:ok, sun_direction} <- sun_direction(source),
         {:ok, run_options} <- run_options(source),
         {:ok, metadata} <- metadata(source),
         {:ok, campaign_metadata} <- campaign_metadata(source),
         {:ok, candidate_refresh_metadata} <- candidate_refresh_metadata(source),
         {:ok, search_metadata} <- search_metadata(source),
         {:ok, monte_carlo_metadata} <- monte_carlo_metadata(source),
         {:ok, constraints} <- constraints(source),
         {:ok, seed_manifest} <- seed_manifest(source),
         {:ok, study_id} <- required(source, "study_id") do
      metadata =
        metadata
        |> Map.put("manifest_schema_version", @schema_version)
        |> maybe_put("campaign", campaign_metadata)
        |> maybe_put("candidate_refresh", candidate_refresh_metadata)
        |> maybe_put("search", search_metadata)
        |> maybe_put("monte_carlo", monte_carlo_metadata)
        |> maybe_put("mission_plans", mission_plan_metadata)
        |> maybe_put("constraints", constraints)

      study =
        Study.new!(study_id, scenarios,
          propagator: propagator,
          propagator_opts: propagator_opts,
          outputs: outputs,
          seed_manifest: seed_manifest,
          metadata: metadata
        )

      run_opts =
        [
          central_body: central_body,
          ground_stations: ground_stations,
          targets: targets,
          ground_track_crossings: ground_track_crossings,
          sun_direction: sun_direction
        ] ++ run_options

      {:ok,
       %__MODULE__{
         study: study,
         run_opts: run_opts,
         central_body: central_body,
         ground_stations: ground_stations,
         targets: targets,
         source: source
       }}
    end
  rescue
    error in ArgumentError -> {:error, {:invalid_manifest, Exception.message(error)}}
  end

  def from_map(_source), do: {:error, {:invalid_manifest, :expected_object}}

  @doc """
  Validates a study manifest file and returns a JSON-serializable lint report.

  The report is intended for CLI and integration tooling that needs stable error
  codes and paths instead of raw Elixir tuples.
  """
  def validation_report(path) when is_binary(path) do
    base_report = validation_report_base()

    case from_file(path) do
      {:ok, manifest} ->
        case StudyRunner.validate_run_inputs(manifest.study, manifest.run_opts) do
          :ok ->
            Map.merge(base_report, %{
              "manifest" => manifest_report_metadata(manifest, path),
              "status" => "pass",
              "study_id" => to_string(manifest.study.id),
              "scenario_count" => length(manifest.study.scenarios),
              "outputs" => Enum.map(manifest.study.outputs, &Atom.to_string/1),
              "error_count" => 0,
              "warning_count" => 0,
              "errors" => [],
              "warnings" => []
            })

          {:error, reason} ->
            Map.merge(base_report, %{
              "manifest" => manifest_report_metadata(manifest, path),
              "status" => "fail",
              "study_id" => to_string(manifest.study.id),
              "scenario_count" => length(manifest.study.scenarios),
              "outputs" => Enum.map(manifest.study.outputs, &Atom.to_string/1),
              "error_count" => 1,
              "warning_count" => 0,
              "errors" => [manifest_error(reason)],
              "warnings" => []
            })
        end

      {:error, reason} ->
        Map.merge(base_report, %{
          "manifest" => %{"path" => path},
          "status" => "fail",
          "study_id" => nil,
          "scenario_count" => nil,
          "outputs" => [],
          "error_count" => 1,
          "warning_count" => 0,
          "errors" => [manifest_error(reason)],
          "warnings" => []
        })
    end
  end

  @doc """
  Exports the accepted study manifest shape as a JSON Schema document.

  This schema is intentionally structural. `from_map/1` and the manifest lint
  task remain the executable semantic validators for scenario generation,
  domain constraints, accepted planning state contracts, and artifact imports.
  """
  def json_schema do
    SchemaDocument.build(%{
      schema_version: @schema_version,
      propagators: Map.keys(@propagators),
      outputs: Map.keys(@outputs),
      search_objectives: @search_objectives,
      json_schema_draft: @json_schema_draft,
      json_schema_contract: @json_schema_contract,
      semantic_validator: @semantic_validator,
      lint_error_codes: @lint_error_codes
    })
  end

  @doc """
  Writes the exported study manifest JSON Schema document to disk.
  """
  def write_json_schema!(path) when is_binary(path) do
    json =
      json_schema()
      |> :json.encode()
      |> IO.iodata_to_binary()

    OrbitalDynamics.Release.SafeOutput.write!(path, json <> "\n")
  end

  @doc """
  Returns a compact JSON-serializable manifest field reference.

  The reference is derived from the exported JSON Schema so CLI docs and
  integration tooling do not need to maintain a separate field list.
  """
  def field_reference do
    schema = json_schema()

    FieldReference.build(schema, %{
      schema_contract: @json_schema_contract,
      schema_version: @schema_version,
      compatibility_policy: Schema.compatibility_policy(),
      identity_policy: Schema.identity_policy(),
      supported: validation_report_base()["supported"]
    })
  end

  defp decode_json(json) do
    case :json.decode(json) do
      decoded when is_map(decoded) -> {:ok, decoded}
      _decoded -> {:error, {:invalid_json, :expected_object}}
    end
  rescue
    _error -> {:error, :invalid_json}
  end

  defp validate_schema_version(source) do
    case Map.get(source, "schema_version") do
      @schema_version -> :ok
      nil -> {:error, {:missing_field, "schema_version"}}
      other -> {:error, {:unsupported_schema_version, other}}
    end
  end

  defp sha256(content) do
    :crypto.hash(:sha256, content)
    |> Base.encode16(case: :lower)
  end

  defp manifest_report_metadata(manifest, path) do
    metadata =
      manifest.run_opts
      |> Keyword.get(:manifest, %{})

    %{"path" => path}
    |> maybe_put("sha256", metadata[:sha256])
  end

  defp manifest_error(reason), do: ValidationError.build(reason, @schema_version)

  defp validation_report_base do
    %{
      "schema_contract" => @lint_schema_contract,
      "schema_version" => @schema_version,
      "schema_id" =>
        "https://orbital-dynamics.local/schemas/#{@lint_schema_contract}.schema.json",
      "manifest_schema_contract" => @json_schema_contract,
      "manifest_schema_id" =>
        "https://orbital-dynamics.local/schemas/#{@json_schema_contract}.schema.json",
      "validation_mode" => "study_manifest_lint",
      "semantic_validator" => @semantic_validator,
      "lint_task" => "mix orbital_dynamics.manifest.lint --manifest PATH",
      "schema_export_command" =>
        "mix orbital_dynamics.manifest.schema.export --output schemas/study_manifest.v1.schema.json",
      "supported" => %{
        "lint_error_codes" => @lint_error_codes,
        "outputs" => Enum.sort(Map.keys(@outputs)),
        "propagators" => Enum.sort(Map.keys(@propagators)),
        "search_objectives" => Enum.sort(@search_objectives)
      }
    }
  end

  defp central_body(source) do
    case Map.get(source, "central_body", "earth") do
      "earth" -> {:ok, CentralBody.earth()}
      %{} = body -> custom_central_body(body)
      other -> {:error, {:unsupported_central_body, other}}
    end
  end

  defp custom_central_body(body) do
    with {:ok, name} <- required_atom(body, "name"),
         {:ok, mu_km3_s2} <- required_number(body, "mu_km3_s2"),
         {:ok, opts} <- central_body_opts(body) do
      {:ok, CentralBody.new!(name, mu_km3_s2, opts)}
    end
  end

  defp central_body_opts(body) do
    with {:ok, radius} <- optional_number(body, "equatorial_radius_km"),
         {:ok, j2} <- optional_number(body, "j2") do
      {:ok, compact_keyword(equatorial_radius_km: radius, j2: j2)}
    end
  end

  defp scenarios(source, central_body) do
    with {:ok, scenario_specs} <- optional_list(source, "scenarios"),
         {:ok, explicit_scenarios} <- scenario_specs(scenario_specs, central_body),
         {:ok, mission_plan_scenarios} <- mission_plan_scenarios(source, central_body),
         {:ok, campaign_scenarios} <- campaign_scenarios(source, central_body),
         {:ok, candidate_refresh_scenarios} <- candidate_refresh_scenarios(source, central_body),
         {:ok, search_scenarios} <- search_scenarios(source, central_body),
         {:ok, monte_carlo_scenarios} <- monte_carlo_scenarios(source, central_body),
         scenarios =
           explicit_scenarios ++
             mission_plan_scenarios ++
             campaign_scenarios ++
             candidate_refresh_scenarios ++ search_scenarios ++ monte_carlo_scenarios,
         :ok <- validate_non_empty_scenarios(scenarios) do
      {:ok, scenarios}
    end
  end

  defp scenario_specs(scenario_specs, central_body) do
    scenario_specs
    |> Enum.reduce_while({:ok, []}, fn scenario_spec, {:ok, scenarios} ->
      case scenario(scenario_spec, central_body) do
        {:ok, built} -> {:cont, {:ok, scenarios ++ built}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp validate_non_empty_scenarios([]), do: {:error, {:missing_field, "scenarios"}}
  defp validate_non_empty_scenarios(_scenarios), do: :ok

  defp mission_plan_metadata(scenarios) do
    scenarios
    |> Enum.map(&get_in(&1.metadata, [:mission_plan]))
    |> Enum.reject(&is_nil/1)
    |> case do
      [] -> {:ok, nil}
      plans -> {:ok, plans}
    end
  end

  defp scenario(%{"generator" => "circular_leo"} = spec, central_body) do
    with :ok <- reject_generated_maneuvers(spec),
         {:ok, opts} <- circular_leo_opts(spec, central_body) do
      {:ok, ScenarioFixture.circular_leo(opts)}
    end
  end

  defp scenario(%{} = spec, central_body) do
    with {:ok, id} <- required(spec, "id"),
         {:ok, spacecraft} <- spacecraft(spec),
         {:ok, initial_state} <- initial_state(spec),
         {:ok, duration_s} <- required_number(spec, "duration_s"),
         {:ok, output_step_s} <- required_number(spec, "output_step_s"),
         {:ok, maneuvers} <- maneuvers(spec) do
      {:ok,
       [
         Scenario.new!(id, spacecraft, initial_state,
           duration_s: duration_s,
           output_step_s: output_step_s,
           central_body: central_body,
           maneuvers: maneuvers
         )
       ]}
    end
  end

  defp scenario(_spec, _central_body), do: {:error, {:invalid_field, "scenarios"}}

  defp mission_plan_scenarios(%{"mission_plans" => plans}, central_body) when is_list(plans) do
    plans
    |> Enum.reduce_while({:ok, []}, fn plan_spec, {:ok, scenarios} ->
      case mission_plan_scenario(plan_spec, central_body) do
        {:ok, scenario} -> {:cont, {:ok, scenarios ++ [scenario]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp mission_plan_scenarios(%{"mission_plans" => _plans}, _central_body),
    do: {:error, {:invalid_field, "mission_plans"}}

  defp mission_plan_scenarios(_source, _central_body), do: {:ok, []}

  defp mission_plan_scenario(%{} = spec, central_body) do
    with {:ok, id} <- required(spec, "id"),
         {:ok, spacecraft} <- spacecraft(spec),
         {:ok, initial_state} <- initial_state(spec),
         {:ok, horizon_s} <- required_number(spec, "horizon_s"),
         {:ok, output_step_s} <- required_number(spec, "output_step_s"),
         {:ok, activities} <- activities(spec),
         {:ok, activities} <- scoped_activities(activities, id, spacecraft.id),
         {:ok, metadata} <- metadata(spec) do
      plan =
        MissionPlan.new!(id, spacecraft, initial_state,
          horizon_s: horizon_s,
          output_step_s: output_step_s,
          central_body: central_body,
          activities: activities,
          metadata: metadata
        )

      MissionPlan.to_scenario(plan)
    end
  end

  defp mission_plan_scenario(_spec, _central_body),
    do: {:error, {:invalid_field, "mission_plans"}}

  defp campaign_scenarios(%{"campaign" => %{} = campaign}, central_body) do
    with {:ok, horizon} <- required_map(campaign, "planning_horizon"),
         {:ok, duration_s} <- required_number(horizon, "duration_s"),
         {:ok, output_step_s} <- required_number(horizon, "output_step_s"),
         {:ok, spacecraft_specs} <- required_list(campaign, "spacecraft") do
      spacecraft_specs
      |> Enum.reduce_while({:ok, []}, fn spacecraft_spec, {:ok, scenarios} ->
        case campaign_spacecraft_scenario(
               spacecraft_spec,
               duration_s,
               output_step_s,
               central_body
             ) do
          {:ok, scenario} -> {:cont, {:ok, scenarios ++ [scenario]}}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)
    end
  end

  defp campaign_scenarios(%{"campaign" => _campaign}, _central_body),
    do: {:error, {:invalid_field, "campaign"}}

  defp campaign_scenarios(_source, _central_body), do: {:ok, []}

  defp candidate_refresh_scenarios(%{"candidate_refresh" => %{} = refresh}, central_body) do
    with {:ok, accepted_state} <- accepted_planning_state(refresh),
         {:ok, horizon} <- candidate_refresh_horizon(refresh),
         {:ok, output_step_s} <- required_number(horizon, "output_step_s"),
         {:ok, end_s} <- candidate_refresh_horizon_end(refresh, horizon),
         spacecraft_states = Map.get(accepted_state, "spacecraft_states", []),
         :ok <- validate_spacecraft_states(spacecraft_states) do
      spacecraft_states
      |> Enum.reduce_while({:ok, []}, fn state, {:ok, scenarios} ->
        case candidate_refresh_scenario(state, accepted_state, end_s, output_step_s, central_body) do
          {:ok, scenario} -> {:cont, {:ok, scenarios ++ [scenario]}}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)
    end
  end

  defp candidate_refresh_scenarios(%{"candidate_refresh" => _refresh}, _central_body),
    do: {:error, {:invalid_field, "candidate_refresh"}}

  defp candidate_refresh_scenarios(_source, _central_body), do: {:ok, []}

  defp candidate_refresh_scenario(
         %{} = state,
         accepted_state,
         end_s,
         output_step_s,
         central_body
       ) do
    with {:ok, scenario_id} <- required(state, "scenario_id"),
         {:ok, spacecraft_id} <- required(state, "spacecraft_id"),
         {:ok, initial_state} <- planning_state_vector(state),
         {:ok, dry_mass_kg} <- spacecraft_dry_mass(state),
         duration_s = end_s - initial_state.epoch.seconds_since_j2000,
         :ok <- validate_positive_duration(duration_s, "candidate_refresh.remaining_horizon") do
      spacecraft = Spacecraft.new!(spacecraft_id, dry_mass_kg)

      {:ok,
       Scenario.new!(scenario_id, spacecraft, initial_state,
         duration_s: duration_s,
         output_step_s: output_step_s,
         central_body: central_body,
         metadata: %{
           candidate_refresh: %{
             accepted_snapshot_id: Map.get(accepted_state, "snapshot_id"),
             spacecraft_id: spacecraft_id,
             state_source: Map.get(state, "source", %{}),
             state_quality: Map.get(state, "quality", %{})
           }
         }
       )}
    end
  end

  defp candidate_refresh_scenario(_state, _accepted_state, _end_s, _output_step_s, _central_body),
    do: {:error, {:invalid_field, "candidate_refresh.accepted_planning_state.spacecraft_states"}}

  defp campaign_spacecraft_scenario(%{} = spec, duration_s, output_step_s, central_body) do
    with {:ok, id} <- required(spec, "id"),
         {:ok, spacecraft} <- campaign_spacecraft(spec),
         {:ok, initial_state} <- initial_state(spec) do
      {:ok,
       Scenario.new!(id, spacecraft, initial_state,
         duration_s: duration_s,
         output_step_s: output_step_s,
         central_body: central_body,
         metadata: %{campaign_spacecraft_id: id}
       )}
    end
  end

  defp campaign_spacecraft_scenario(_spec, _duration_s, _output_step_s, _central_body),
    do: {:error, {:invalid_field, "campaign.spacecraft"}}

  defp search_scenarios(%{"search" => %{} = search}, central_body) do
    case Map.get(search, "generator", "impulsive_burn_grid") do
      "impulsive_burn_grid" -> impulsive_burn_grid(search, central_body)
      other -> {:error, {:unsupported_search_generator, other}}
    end
  end

  defp search_scenarios(%{"search" => _search}, _central_body),
    do: {:error, {:invalid_field, "search"}}

  defp search_scenarios(_source, _central_body), do: {:ok, []}

  defp monte_carlo_scenarios(%{"monte_carlo" => %{} = monte_carlo}, central_body) do
    case Map.get(monte_carlo, "generator", "state_vector_dispersion") do
      "state_vector_dispersion" -> state_vector_dispersion(monte_carlo, central_body)
      other -> {:error, {:unsupported_monte_carlo_generator, other}}
    end
  end

  defp monte_carlo_scenarios(%{"monte_carlo" => _monte_carlo}, _central_body),
    do: {:error, {:invalid_field, "monte_carlo"}}

  defp monte_carlo_scenarios(_source, _central_body), do: {:ok, []}

  defp impulsive_burn_grid(search, central_body) do
    with {:ok, base_scenario_spec} <- required_map(search, "base_scenario"),
         {:ok, [base_scenario]} <- scenario(base_scenario_spec, central_body),
         {:ok, burn_epoch_s_values} <- required_number_list(search, "burn_epoch_s"),
         {:ok, delta_v_values} <- required_vector_list(search, "delta_v_km_s"),
         {:ok, id_prefix} <- optional_string(search, "id_prefix", "#{base_scenario.id}_grid") do
      {:ok,
       Grid.impulsive_burn_grid(base_scenario,
         burn_epoch_s: burn_epoch_s_values,
         delta_v_km_s: delta_v_values,
         id_prefix: id_prefix
       )}
    else
      {:ok, _other} -> {:error, {:invalid_field, "search.base_scenario"}}
      {:error, reason} -> {:error, reason}
    end
  rescue
    error in ArgumentError -> {:error, {:invalid_search, Exception.message(error)}}
  end

  defp state_vector_dispersion(monte_carlo, central_body) do
    with {:ok, base_scenario_spec} <- required_map(monte_carlo, "base_scenario"),
         {:ok, [base_scenario]} <- scenario(base_scenario_spec, central_body),
         {:ok, count} <- required_positive_integer(monte_carlo, "count"),
         {:ok, seed} <- required_non_negative_integer(monte_carlo, "seed"),
         {:ok, position_sigma_km} <- required_vector(monte_carlo, "position_sigma_km"),
         {:ok, velocity_sigma_km_s} <- required_vector(monte_carlo, "velocity_sigma_km_s"),
         :ok <- validate_non_negative_vector(position_sigma_km, "position_sigma_km"),
         :ok <- validate_non_negative_vector(velocity_sigma_km_s, "velocity_sigma_km_s"),
         {:ok, id_prefix} <- optional_string(monte_carlo, "id_prefix", "#{base_scenario.id}_mc") do
      {:ok,
       MonteCarlo.state_vector_dispersion(base_scenario,
         count: count,
         seed: seed,
         position_sigma_km: position_sigma_km,
         velocity_sigma_km_s: velocity_sigma_km_s,
         id_prefix: id_prefix
       )}
    else
      {:ok, _other} -> {:error, {:invalid_field, "monte_carlo.base_scenario"}}
      {:error, reason} -> {:error, reason}
    end
  rescue
    error in ArgumentError -> {:error, {:invalid_monte_carlo, Exception.message(error)}}
  end

  defp search_metadata(%{"search" => %{} = search}) do
    with {:ok, generator} <- search_generator(search),
         {:ok, burn_epoch_s_values} <- required_number_list(search, "burn_epoch_s"),
         {:ok, delta_v_values} <- required_vector_list(search, "delta_v_km_s"),
         {:ok, id_prefix} <- optional_string(search, "id_prefix"),
         {:ok, objective} <- optional_search_objective(search),
         {:ok, objective_direction} <- optional_search_objective_direction(search, objective),
         {:ok, rank_limit} <- optional_search_rank_limit(search, objective) do
      {:ok,
       %{
         "generator" => generator,
         "burn_epoch_s" => burn_epoch_s_values,
         "delta_v_km_s" => delta_v_values
       }
       |> maybe_put("id_prefix", id_prefix)
       |> maybe_put("objective", objective)
       |> maybe_put("objective_direction", objective_direction)
       |> maybe_put("rank_limit", rank_limit)}
    end
  end

  defp search_metadata(%{"search" => _search}), do: {:error, {:invalid_field, "search"}}
  defp search_metadata(_source), do: {:ok, nil}

  defp monte_carlo_metadata(%{"monte_carlo" => %{} = monte_carlo}) do
    with {:ok, generator} <- monte_carlo_generator(monte_carlo),
         {:ok, count} <- required_positive_integer(monte_carlo, "count"),
         {:ok, seed} <- required_non_negative_integer(monte_carlo, "seed"),
         {:ok, position_sigma_km} <- required_vector(monte_carlo, "position_sigma_km"),
         {:ok, velocity_sigma_km_s} <- required_vector(monte_carlo, "velocity_sigma_km_s"),
         :ok <- validate_non_negative_vector(position_sigma_km, "position_sigma_km"),
         :ok <- validate_non_negative_vector(velocity_sigma_km_s, "velocity_sigma_km_s"),
         {:ok, id_prefix} <- optional_string(monte_carlo, "id_prefix"),
         {:ok, objective} <- optional_objective(monte_carlo, "monte_carlo.objective"),
         {:ok, objective_direction} <-
           optional_objective_direction(
             monte_carlo,
             objective,
             "monte_carlo.objective_direction"
           ),
         {:ok, rank_limit} <-
           optional_rank_limit(monte_carlo, objective, "monte_carlo.rank_limit") do
      {:ok,
       %{
         "generator" => generator,
         "count" => count,
         "seed" => seed,
         "position_sigma_km" => Tuple.to_list(position_sigma_km),
         "velocity_sigma_km_s" => Tuple.to_list(velocity_sigma_km_s)
       }
       |> maybe_put("id_prefix", id_prefix)
       |> maybe_put("objective", objective)
       |> maybe_put("objective_direction", objective_direction)
       |> maybe_put("rank_limit", rank_limit)}
    end
  end

  defp monte_carlo_metadata(%{"monte_carlo" => _monte_carlo}),
    do: {:error, {:invalid_field, "monte_carlo"}}

  defp monte_carlo_metadata(_source), do: {:ok, nil}

  defp campaign_metadata(%{"campaign" => %{} = campaign}) do
    with {:ok, horizon} <- required_map(campaign, "planning_horizon"),
         {:ok, duration_s} <- required_number(horizon, "duration_s"),
         {:ok, output_step_s} <- required_number(horizon, "output_step_s"),
         {:ok, spacecraft_specs} <- required_list(campaign, "spacecraft"),
         {:ok, target_specs} <- required_list(campaign, "targets"),
         {:ok, constraints} <- campaign_constraints(campaign),
         {:ok, scoring_policy} <- campaign_scoring_policy(campaign),
         {:ok, ground_network} <- campaign_ground_network(campaign),
         {:ok, resource_summaries} <- campaign_resource_summaries(campaign) do
      {:ok,
       %{
         "planning_horizon" => %{
           "duration_s" => duration_s * 1.0,
           "output_step_s" => output_step_s * 1.0
         },
         "spacecraft" => Enum.map(spacecraft_specs, &campaign_spacecraft_metadata/1),
         "targets" => Enum.map(target_specs, &target_metadata/1),
         "constraints" => constraints,
         "scoring_policy" => scoring_policy,
         "ground_network" => ground_network,
         "resource_summaries" => resource_summaries
       }}
    end
  rescue
    error in ArgumentError -> {:error, {:invalid_campaign, Exception.message(error)}}
  end

  defp campaign_metadata(%{"campaign" => _campaign}), do: {:error, {:invalid_field, "campaign"}}
  defp campaign_metadata(_source), do: {:ok, nil}

  defp campaign_ground_network(campaign), do: GroundNetworkInput.campaign(campaign)

  defp campaign_resource_summaries(campaign) do
    with {:ok, summaries} <- optional_list(campaign, "resource_summaries") do
      {:ok, ResourceSummary.to_maps(summaries)}
    end
  rescue
    error in ArgumentError ->
      {:error, {:invalid_campaign, Exception.message(error)}}
  end

  defp candidate_refresh_metadata(%{"candidate_refresh" => %{} = refresh} = source) do
    with {:ok, accepted_state} <- accepted_planning_state(refresh),
         {:ok, horizon} <- candidate_refresh_horizon(refresh),
         {:ok, current_epoch_s} <- candidate_refresh_current_epoch(refresh, accepted_state),
         {:ok, targets} <- candidate_refresh_target_metadata(refresh),
         {:ok, constraints} <- candidate_refresh_constraints(refresh),
         {:ok, scoring_policy} <- candidate_refresh_scoring_policy(refresh),
         {:ok, objectives} <- candidate_refresh_objectives(refresh),
         {:ok, freshness_policy} <- candidate_refresh_freshness_policy(refresh),
         {:ok, resource_filter_policy} <- candidate_refresh_resource_filter_policy(refresh),
         {:ok, candidate_limit_policy} <- candidate_refresh_candidate_limit_policy(refresh),
         {:ok, approval_policy} <- candidate_refresh_approval_policy(refresh),
         {:ok, operational_feedback} <- candidate_refresh_operational_feedback(refresh),
         {:ok, mission_state} <- candidate_refresh_mission_state(refresh),
         {:ok, source_timeline_feedback_report} <-
           candidate_refresh_timeline_feedback_report(refresh, "source_timeline_feedback_report"),
         {:ok, timeline_feedback_report} <-
           candidate_refresh_timeline_feedback_report(refresh, "timeline_feedback_report"),
         {:ok, source_operational_timeline_report} <-
           candidate_refresh_operational_timeline_report(
             refresh,
             "source_operational_timeline_report"
           ),
         {:ok, operational_timeline_report} <-
           candidate_refresh_operational_timeline_report(refresh, "operational_timeline_report"),
         {:ok, model_assumptions} <- candidate_refresh_model_assumptions(refresh),
         {:ok, resource_summaries} <- candidate_refresh_resource_summaries(refresh),
         {:ok, ground_network} <- candidate_refresh_ground_network(refresh),
         {:ok, prior_candidate_activities} <- candidate_refresh_prior_candidates(refresh) do
      refresh_metadata =
        %{
          "accepted_planning_state" => accepted_state,
          "current_epoch_s" => current_epoch_s,
          "remaining_horizon" => horizon,
          "targets" => targets,
          "constraints" => constraints,
          "scoring_policy" => scoring_policy,
          "objectives" => objectives,
          "freshness_policy" => freshness_policy,
          "resource_filter_policy" => resource_filter_policy,
          "candidate_limit_policy" => candidate_limit_policy,
          "approval_policy" => approval_policy,
          "operational_feedback" => operational_feedback,
          "mission_state" => mission_state,
          "model_assumptions" => model_assumptions,
          "resource_summaries" => resource_summaries,
          "ground_network" => ground_network,
          "prior_candidate_activities" => prior_candidate_activities,
          "run_input_sources" => CandidateRefreshRunInputSources.build(source)
        }
        |> maybe_put("source_timeline_feedback_report", source_timeline_feedback_report)
        |> maybe_put("timeline_feedback_report", timeline_feedback_report)
        |> maybe_put("source_operational_timeline_report", source_operational_timeline_report)
        |> maybe_put("operational_timeline_report", operational_timeline_report)

      {:ok, refresh_metadata}
    end
  end

  defp candidate_refresh_metadata(%{"candidate_refresh" => _refresh}),
    do: {:error, {:invalid_field, "candidate_refresh"}}

  defp candidate_refresh_metadata(_source), do: {:ok, nil}

  defp campaign_spacecraft_metadata(%{} = spec) do
    %{
      "id" => Map.get(spec, "id"),
      "dry_mass_kg" => Map.get(spec, "dry_mass_kg"),
      "propellant_mass_kg" => Map.get(spec, "propellant_mass_kg"),
      "area_m2" => Map.get(spec, "area_m2"),
      "drag_coefficient" => Map.get(spec, "drag_coefficient")
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp campaign_constraints(campaign) do
    case Map.get(campaign, "constraints", %{}) do
      %{} = constraints ->
        with {:ok, min_activity_duration_s} <-
               optional_number(constraints, "min_activity_duration_s"),
             {:ok, max_timeline_activities} <-
               optional_positive_integer(constraints, "max_timeline_activities", nil),
             {:ok, avoid_eclipse?} <- optional_boolean(constraints, "avoid_eclipse", true) do
          {:ok,
           %{}
           |> maybe_put("min_activity_duration_s", min_activity_duration_s || 0.0)
           |> maybe_put("max_timeline_activities", max_timeline_activities)
           |> Map.put("avoid_eclipse", avoid_eclipse?)}
        end

      _constraints ->
        {:error, {:invalid_field, "campaign.constraints"}}
    end
  end

  defp campaign_scoring_policy(campaign) do
    case Map.get(campaign, "scoring_policy", %{}) do
      %{} = policy ->
        with {:ok, target_value_weight} <- optional_number(policy, "target_value_weight"),
             {:ok, contact_value_weight} <- optional_number(policy, "contact_value_weight"),
             {:ok, eclipse_penalty_weight} <- optional_number(policy, "eclipse_penalty_weight"),
             {:ok, activity_count_penalty} <- optional_number(policy, "activity_count_penalty"),
             {:ok, rank_limit} <- optional_positive_integer(policy, "rank_limit", 10) do
          {:ok,
           %{
             "target_value_weight" => target_value_weight || 1.0,
             "contact_value_weight" => contact_value_weight || 0.1,
             "eclipse_penalty_weight" => eclipse_penalty_weight || 1.0,
             "activity_count_penalty" => activity_count_penalty || 0.0,
             "rank_limit" => rank_limit
           }}
        end

      _policy ->
        {:error, {:invalid_field, "campaign.scoring_policy"}}
    end
  end

  defp monte_carlo_generator(monte_carlo) do
    case Map.get(monte_carlo, "generator", "state_vector_dispersion") do
      "state_vector_dispersion" -> {:ok, "state_vector_dispersion"}
      other -> {:error, {:unsupported_monte_carlo_generator, other}}
    end
  end

  defp search_generator(search) do
    case Map.get(search, "generator", "impulsive_burn_grid") do
      "impulsive_burn_grid" -> {:ok, "impulsive_burn_grid"}
      other -> {:error, {:unsupported_search_generator, other}}
    end
  end

  defp optional_search_objective(search) do
    optional_objective(search, "search.objective")
  end

  defp optional_search_objective_direction(search, nil) do
    optional_objective_direction(search, nil, "search.objective_direction")
  end

  defp optional_search_objective_direction(search, objective) do
    optional_objective_direction(search, objective, "search.objective_direction")
  end

  defp optional_search_rank_limit(search, nil) do
    optional_rank_limit(search, nil, "search.rank_limit")
  end

  defp optional_search_rank_limit(search, objective) do
    optional_rank_limit(search, objective, "search.rank_limit")
  end

  defp optional_objective(map, field) do
    case Map.fetch(map, "objective") do
      {:ok, objective} when objective in @search_objectives -> {:ok, objective}
      {:ok, _objective} -> {:error, {:invalid_field, field}}
      :error -> {:ok, nil}
    end
  end

  defp optional_objective_direction(map, nil, field) do
    case Map.fetch(map, "objective_direction") do
      {:ok, _direction} -> {:error, {:invalid_field, field}}
      :error -> {:ok, nil}
    end
  end

  defp optional_objective_direction(map, objective, field) do
    inferred_direction = Report.objective_direction_label(objective)

    case Map.fetch(map, "objective_direction") do
      {:ok, ^inferred_direction} ->
        {:ok, inferred_direction}

      {:ok, direction} when direction in ["maximize", "minimize"] ->
        {:error, {:invalid_objective_direction, objective, direction, inferred_direction}}

      {:ok, _direction} ->
        {:error, {:invalid_field, field}}

      :error ->
        {:ok, inferred_direction}
    end
  end

  defp optional_rank_limit(map, nil, field) do
    case Map.fetch(map, "rank_limit") do
      {:ok, _limit} -> {:error, {:invalid_field, field}}
      :error -> {:ok, nil}
    end
  end

  defp optional_rank_limit(map, _objective, _field) do
    optional_positive_integer(map, "rank_limit", 10)
  end

  defp constraints(source) do
    with {:ok, specs} <- optional_list(source, "constraints") do
      specs
      |> Enum.reduce_while({:ok, []}, fn spec, {:ok, constraints} ->
        case constraint(spec) do
          {:ok, constraint} -> {:cont, {:ok, constraints ++ [constraint]}}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)
      |> case do
        {:ok, []} -> {:ok, nil}
        result -> result
      end
    end
  end

  defp constraint(%{} = spec) do
    with {:ok, id} <- required(spec, "id"),
         {:ok, metric} <- required_constraint_metric(spec),
         {:ok, operator} <- required_constraint_operator(spec),
         {:ok, value} <- required_number(spec, "value") do
      {:ok,
       %{
         "id" => id,
         "metric" => metric,
         "operator" => operator,
         "value" => value * 1.0
       }}
    end
  end

  defp constraint(_spec), do: {:error, {:invalid_field, "constraints"}}

  defp required_constraint_metric(spec) do
    case Map.fetch(spec, "metric") do
      {:ok, metric} when metric in @search_objectives -> {:ok, metric}
      {:ok, _metric} -> {:error, {:invalid_field, "constraints.metric"}}
      :error -> {:error, {:missing_field, "constraints.metric"}}
    end
  end

  defp required_constraint_operator(spec) do
    case Map.fetch(spec, "operator") do
      {:ok, operator} when operator in ["<", "<=", "==", ">=", ">"] -> {:ok, operator}
      {:ok, _operator} -> {:error, {:invalid_field, "constraints.operator"}}
      :error -> {:error, {:missing_field, "constraints.operator"}}
    end
  end

  defp reject_generated_maneuvers(%{"maneuvers" => _maneuvers}),
    do: {:error, {:unsupported_field, "scenarios.maneuvers_for_generator"}}

  defp reject_generated_maneuvers(_spec), do: :ok

  defp circular_leo_opts(spec, central_body) do
    with {:ok, count} <- required_positive_integer(spec, "count"),
         {:ok, duration_s} <- required_number(spec, "duration_s"),
         {:ok, output_step_s} <- required_number(spec, "output_step_s"),
         {:ok, radius_km} <- optional_number(spec, "radius_km"),
         {:ok, dry_mass_kg} <- optional_number(spec, "dry_mass_kg"),
         {:ok, propellant_mass_kg} <- optional_number(spec, "propellant_mass_kg"),
         {:ok, area_m2} <- optional_number(spec, "area_m2"),
         {:ok, drag_coefficient} <- optional_number(spec, "drag_coefficient"),
         {:ok, id_prefix} <- optional_string(spec, "id_prefix", "manifest_leo"),
         {:ok, epoch} <- optional_epoch(spec),
         {:ok, frame} <- optional_frame(spec) do
      {:ok,
       compact_keyword(
         count: count,
         duration_s: duration_s,
         output_step_s: output_step_s,
         radius_km: radius_km,
         dry_mass_kg: dry_mass_kg,
         propellant_mass_kg: propellant_mass_kg,
         area_m2: area_m2,
         drag_coefficient: drag_coefficient,
         id_prefix: id_prefix,
         epoch: epoch,
         frame: frame,
         central_body: central_body
       )}
    end
  end

  defp spacecraft(spec) do
    with {:ok, spacecraft} <- required_map(spec, "spacecraft"),
         {:ok, id} <- required(spacecraft, "id"),
         {:ok, dry_mass_kg} <- required_number(spacecraft, "dry_mass_kg"),
         {:ok, propellant_mass_kg} <- optional_number(spacecraft, "propellant_mass_kg"),
         {:ok, area_m2} <- optional_number(spacecraft, "area_m2"),
         {:ok, drag_coefficient} <- optional_number(spacecraft, "drag_coefficient") do
      {:ok,
       Spacecraft.new!(
         id,
         dry_mass_kg,
         compact_keyword(
           propellant_mass_kg: propellant_mass_kg,
           area_m2: area_m2,
           drag_coefficient: drag_coefficient
         )
       )}
    end
  end

  defp campaign_spacecraft(spec) do
    with {:ok, id} <- required(spec, "id"),
         {:ok, dry_mass_kg} <- required_number(spec, "dry_mass_kg"),
         {:ok, propellant_mass_kg} <- optional_number(spec, "propellant_mass_kg"),
         {:ok, area_m2} <- optional_number(spec, "area_m2"),
         {:ok, drag_coefficient} <- optional_number(spec, "drag_coefficient") do
      {:ok,
       Spacecraft.new!(
         id,
         dry_mass_kg,
         compact_keyword(
           propellant_mass_kg: propellant_mass_kg,
           area_m2: area_m2,
           drag_coefficient: drag_coefficient
         )
       )}
    end
  end

  defp initial_state(spec) do
    with {:ok, initial_state} <- required_map(spec, "initial_state"),
         {:ok, position_km} <- required_vector(initial_state, "position_km"),
         {:ok, velocity_km_s} <- required_vector(initial_state, "velocity_km_s"),
         {:ok, epoch} <- epoch(initial_state),
         {:ok, frame} <- frame(initial_state) do
      {:ok, StateVector.new!(position_km, velocity_km_s, epoch, frame)}
    end
  end

  defp maneuvers(spec) do
    spec
    |> Map.get("maneuvers", [])
    |> case do
      maneuvers when is_list(maneuvers) ->
        maneuvers
        |> Enum.reduce_while({:ok, []}, fn maneuver_spec, {:ok, maneuvers} ->
          case maneuver(maneuver_spec) do
            {:ok, maneuver} -> {:cont, {:ok, maneuvers ++ [maneuver]}}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)

      _other ->
        {:error, {:invalid_field, "maneuvers"}}
    end
  end

  defp maneuver(%{} = spec) do
    with {:ok, id} <- required(spec, "id"),
         {:ok, epoch} <- epoch(spec),
         {:ok, delta_v_km_s} <- required_vector(spec, "delta_v_km_s"),
         {:ok, frame} <- frame(spec) do
      {:ok, ImpulsiveBurn.new!(id, epoch, delta_v_km_s, frame)}
    end
  end

  defp maneuver(_spec), do: {:error, {:invalid_field, "maneuvers"}}

  defp activities(spec), do: ActivityInput.activities(spec)

  defp scoped_activities(activities, scenario_id, spacecraft_id),
    do: ActivityInput.scoped_activities(activities, scenario_id, spacecraft_id)

  defp epoch(source) do
    with {:ok, epoch} <- required_map(source, "epoch"),
         {:ok, seconds_since_j2000} <- required_number(epoch, "seconds_since_j2000"),
         {:ok, scale} <- optional_atom(epoch, "scale", :tdb, ["tdb", "tai", "utc"]) do
      {:ok, Epoch.new!(seconds_since_j2000, scale)}
    end
  end

  defp optional_epoch(source) do
    case Map.fetch(source, "epoch") do
      {:ok, _epoch} -> epoch(source)
      :error -> {:ok, nil}
    end
  end

  defp frame(source) do
    case Map.get(source, "frame", "earth_inertial_j2000") do
      "earth_inertial_j2000" -> {:ok, Frame.earth_inertial_j2000()}
      other -> {:error, {:unsupported_frame, other}}
    end
  end

  defp optional_frame(source) do
    case Map.fetch(source, "frame") do
      {:ok, _frame} -> frame(source)
      :error -> {:ok, nil}
    end
  end

  defp propagator(source) do
    case Map.get(source, "propagator", "two_body") do
      key when is_binary(key) ->
        case Map.fetch(@propagators, key) do
          {:ok, module} -> {:ok, module}
          :error -> {:error, {:unsupported_propagator, key}}
        end

      other ->
        {:error, {:unsupported_propagator, other}}
    end
  end

  defp propagator_opts(source, propagator) do
    with {:ok, opts} <-
           source
           |> Map.get("propagator_opts", %{})
           |> known_keyword_map("propagator_opts", @propagator_opts) do
      normalize_propagator_opts(propagator, opts)
    end
  end

  defp normalize_propagator_opts(TwoBodyDrag, opts) do
    case Keyword.keys(opts) -- [:max_step_s, :atmosphere_provider] do
      [] ->
        with {:ok, atmosphere_provider} <-
               AtmosphereProviderInput.parse(Keyword.get(opts, :atmosphere_provider)) do
          {:ok, maybe_keyword_replace(opts, :atmosphere_provider, atmosphere_provider)}
        end

      [unsupported | _rest] ->
        {:error, {:unsupported_option, "propagator_opts", Atom.to_string(unsupported)}}
    end
  end

  defp normalize_propagator_opts(_propagator, opts) do
    if Keyword.has_key?(opts, :atmosphere_provider) do
      {:error, {:unsupported_option, "propagator_opts", "atmosphere_provider"}}
    else
      {:ok, opts}
    end
  end

  defp maybe_keyword_replace(keyword, key, nil), do: Keyword.delete(keyword, key)

  defp maybe_keyword_replace(keyword, key, value),
    do:
      if(Keyword.has_key?(keyword, key), do: Keyword.replace(keyword, key, value), else: keyword)

  defp outputs(source) do
    with {:ok, outputs} <- required_list(source, "outputs") do
      outputs
      |> Enum.reduce_while({:ok, []}, fn
        output, {:ok, acc} when is_binary(output) ->
          case Map.fetch(@outputs, output) do
            {:ok, output_atom} -> {:cont, {:ok, acc ++ [output_atom]}}
            :error -> {:halt, {:error, {:unsupported_output, output}}}
          end

        output, {:ok, _acc} ->
          {:halt, {:error, {:invalid_output, output}}}
      end)
    end
  end

  defp ground_track_crossings(source) do
    GroundTrackCrossingInput.parse(source)
  end

  defp target_metadata(%{} = spec) do
    %{
      "id" => Map.get(spec, "id"),
      "latitude_deg" => Map.get(spec, "latitude_deg"),
      "longitude_deg" => Map.get(spec, "longitude_deg"),
      "altitude_km" => Map.get(spec, "altitude_km", 0.0),
      "minimum_elevation_deg" => Map.get(spec, "minimum_elevation_deg", 0.0),
      "priority" => Map.get(spec, "priority", 1.0)
    }
  end

  defp accepted_planning_state(refresh), do: CandidateRefreshPlanningState.resolve(refresh)

  defp candidate_refresh_horizon(%{"remaining_horizon" => %{} = horizon}) do
    with {:ok, output_step_s} <- required_number(horizon, "output_step_s"),
         {:ok, normalized} <- candidate_refresh_horizon_bounds(horizon) do
      {:ok, Map.put(normalized, "output_step_s", output_step_s * 1.0)}
    end
  end

  defp candidate_refresh_horizon(%{"remaining_horizon" => _horizon}),
    do: {:error, {:invalid_field, "candidate_refresh.remaining_horizon"}}

  defp candidate_refresh_horizon(_refresh),
    do: {:error, {:missing_field, "candidate_refresh.remaining_horizon"}}

  defp candidate_refresh_horizon_bounds(%{"starts_at_s" => _start_s, "ends_at_s" => _end_s} = h) do
    with {:ok, start_s} <- required_number(h, "starts_at_s"),
         {:ok, end_s} <- required_number(h, "ends_at_s"),
         :ok <- validate_positive_duration(end_s - start_s, "candidate_refresh.remaining_horizon") do
      {:ok, %{"starts_at_s" => start_s * 1.0, "ends_at_s" => end_s * 1.0}}
    end
  end

  defp candidate_refresh_horizon_bounds(%{"duration_s" => _duration_s} = h) do
    with {:ok, duration_s} <- required_number(h, "duration_s"),
         :ok <- validate_positive_duration(duration_s, "candidate_refresh.remaining_horizon") do
      {:ok, %{"duration_s" => duration_s * 1.0}}
    end
  end

  defp candidate_refresh_horizon_bounds(_horizon),
    do: {:error, {:missing_field, "candidate_refresh.remaining_horizon.ends_at_s"}}

  defp candidate_refresh_horizon_end(_refresh, %{"ends_at_s" => end_s}), do: {:ok, end_s}

  defp candidate_refresh_horizon_end(refresh, %{"duration_s" => duration_s}) do
    with {:ok, accepted_state} <- accepted_planning_state(refresh),
         {:ok, current_epoch_s} <- candidate_refresh_current_epoch(refresh, accepted_state) do
      {:ok, current_epoch_s + duration_s}
    end
  end

  defp candidate_refresh_current_epoch(%{"current_epoch_s" => value}, _accepted_state)
       when is_integer(value) or is_float(value),
       do: {:ok, value * 1.0}

  defp candidate_refresh_current_epoch(
         %{"current_epoch" => %{"seconds_since_j2000" => value}},
         _accepted_state
       )
       when is_integer(value) or is_float(value),
       do: {:ok, value * 1.0}

  defp candidate_refresh_current_epoch(_refresh, %{"spacecraft_states" => [state | _]}) do
    case get_in(state, ["epoch", "seconds_since_j2000"]) do
      value when is_integer(value) or is_float(value) -> {:ok, value * 1.0}
      _value -> {:error, {:missing_field, "candidate_refresh.current_epoch_s"}}
    end
  end

  defp candidate_refresh_current_epoch(_refresh, _accepted_state),
    do: {:error, {:missing_field, "candidate_refresh.current_epoch_s"}}

  defp candidate_refresh_target_metadata(%{"targets" => target_specs})
       when is_list(target_specs) do
    {:ok, Enum.map(target_specs, &target_metadata/1)}
  end

  defp candidate_refresh_target_metadata(%{"targets" => _targets}),
    do: {:error, {:invalid_field, "candidate_refresh.targets"}}

  defp candidate_refresh_target_metadata(_refresh), do: {:ok, []}

  defp candidate_refresh_constraints(%{"constraints" => %{} = constraints}) do
    with {:ok, min_activity_duration_s} <-
           optional_number(constraints, "min_activity_duration_s"),
         {:ok, avoid_eclipse?} <- optional_boolean(constraints, "avoid_eclipse", true) do
      {:ok,
       %{
         "min_activity_duration_s" => min_activity_duration_s || 0.0,
         "avoid_eclipse" => avoid_eclipse?
       }}
    end
  end

  defp candidate_refresh_constraints(%{"constraints" => _constraints}),
    do: {:error, {:invalid_field, "candidate_refresh.constraints"}}

  defp candidate_refresh_constraints(_refresh),
    do: {:ok, %{"min_activity_duration_s" => 0.0, "avoid_eclipse" => true}}

  defp candidate_refresh_scoring_policy(%{"scoring_policy" => %{} = policy}) do
    with {:ok, target_value_weight} <- optional_number(policy, "target_value_weight"),
         {:ok, contact_value_weight} <- optional_number(policy, "contact_value_weight"),
         {:ok, eclipse_penalty_weight} <- optional_number(policy, "eclipse_penalty_weight"),
         {:ok, downlink_rate_mb_s} <- optional_number(policy, "downlink_rate_mb_s"),
         {:ok, downlink_completion_weight} <-
           optional_number(policy, "downlink_completion_weight"),
         {:ok, observation_objective_weight} <-
           optional_number(policy, "observation_objective_weight"),
         {:ok, collection_latency_observation_weight} <-
           optional_number(policy, "collection_latency_observation_weight") do
      {:ok,
       %{
         "target_value_weight" => target_value_weight || 1.0,
         "contact_value_weight" => contact_value_weight || 0.1,
         "eclipse_penalty_weight" => eclipse_penalty_weight || 1.0,
         "downlink_rate_mb_s" => downlink_rate_mb_s || 1.0,
         "downlink_completion_weight" => downlink_completion_weight,
         "observation_objective_weight" => observation_objective_weight,
         "collection_latency_observation_weight" => collection_latency_observation_weight
       }
       |> Enum.reject(fn {_key, value} -> is_nil(value) end)
       |> Map.new()}
    end
  end

  defp candidate_refresh_scoring_policy(%{"scoring_policy" => _policy}),
    do: {:error, {:invalid_field, "candidate_refresh.scoring_policy"}}

  defp candidate_refresh_scoring_policy(_refresh) do
    {:ok,
     %{
       "target_value_weight" => 1.0,
       "contact_value_weight" => 0.1,
       "eclipse_penalty_weight" => 1.0,
       "downlink_rate_mb_s" => 1.0
     }}
  end

  defp candidate_refresh_objectives(%{"objectives" => objectives}) when is_list(objectives),
    do: {:ok, objectives}

  defp candidate_refresh_objectives(%{"objectives" => _objectives}),
    do: {:error, {:invalid_field, "candidate_refresh.objectives"}}

  defp candidate_refresh_objectives(_refresh), do: {:ok, []}

  defp candidate_refresh_model_assumptions(%{"model_assumptions" => %{} = assumptions}),
    do: {:ok, assumptions}

  defp candidate_refresh_model_assumptions(%{"model_assumptions" => _assumptions}),
    do: {:error, {:invalid_field, "candidate_refresh.model_assumptions"}}

  defp candidate_refresh_model_assumptions(_refresh), do: {:ok, %{}}

  defp candidate_refresh_freshness_policy(refresh),
    do: optional_map(refresh, "freshness_policy")

  defp candidate_refresh_resource_filter_policy(refresh),
    do: optional_map(refresh, "resource_filter_policy")

  defp candidate_refresh_candidate_limit_policy(refresh),
    do: optional_map(refresh, "candidate_limit_policy")

  defp candidate_refresh_approval_policy(refresh),
    do: optional_map(refresh, "approval_policy")

  defp candidate_refresh_operational_feedback(refresh),
    do: optional_map(refresh, "operational_feedback")

  defp candidate_refresh_mission_state(%{"mission_state" => %{} = mission_state}),
    do: {:ok, mission_state}

  defp candidate_refresh_mission_state(%{"mission_state" => _mission_state}),
    do: {:error, {:invalid_field, "candidate_refresh.mission_state"}}

  defp candidate_refresh_mission_state(_refresh), do: {:ok, %{}}

  defp candidate_refresh_timeline_feedback_report(refresh, key),
    do: optional_map_or_nil(refresh, key)

  defp candidate_refresh_operational_timeline_report(refresh, key) do
    case Map.fetch(refresh, key) do
      {:ok, %{} = report} -> {:ok, report}
      {:ok, reports} when is_list(reports) -> {:ok, reports}
      {:ok, nil} -> {:ok, nil}
      {:ok, _value} -> {:error, {:invalid_field, key}}
      :error -> {:ok, nil}
    end
  end

  defp candidate_refresh_resource_summaries(%{"resource_summaries" => summaries})
       when is_list(summaries),
       do: {:ok, summaries}

  defp candidate_refresh_resource_summaries(%{"resource_summaries" => _summaries}),
    do: {:error, {:invalid_field, "candidate_refresh.resource_summaries"}}

  defp candidate_refresh_resource_summaries(_refresh), do: {:ok, []}

  defp candidate_refresh_ground_network(%{"ground_network" => ground_network})
       when is_list(ground_network),
       do: GroundNetworkInput.parse(ground_network, "candidate_refresh.ground_network")

  defp candidate_refresh_ground_network(%{"ground_network" => _ground_network}),
    do: {:error, {:invalid_field, "candidate_refresh.ground_network"}}

  defp candidate_refresh_ground_network(_refresh), do: {:ok, []}

  defp candidate_refresh_prior_candidates(%{"prior_candidate_activities" => candidates})
       when is_list(candidates),
       do: {:ok, candidates}

  defp candidate_refresh_prior_candidates(%{"prior_candidate_activities" => _candidates}),
    do: {:error, {:invalid_field, "candidate_refresh.prior_candidate_activities"}}

  defp candidate_refresh_prior_candidates(_refresh), do: {:ok, []}

  defp validate_spacecraft_states([_ | _]), do: :ok

  defp validate_spacecraft_states(_states),
    do: {:error, {:missing_field, "candidate_refresh.accepted_planning_state.spacecraft_states"}}

  defp planning_state_vector(%{} = state) do
    with {:ok, state_vector} <- required_map(state, "state_vector"),
         {:ok, position_km} <- required_vector(state_vector, "position_km"),
         {:ok, velocity_km_s} <- required_vector(state_vector, "velocity_km_s"),
         {:ok, epoch} <- planning_state_epoch(state),
         {:ok, frame} <- frame(state) do
      {:ok, StateVector.new!(position_km, velocity_km_s, epoch, frame)}
    end
  end

  defp planning_state_epoch(%{"epoch" => %{} = epoch}) do
    with {:ok, seconds_since_j2000} <- required_number(epoch, "seconds_since_j2000"),
         {:ok, scale} <- planning_state_time_scale(epoch) do
      {:ok, Epoch.new!(seconds_since_j2000, scale)}
    end
  end

  defp planning_state_epoch(_state),
    do: {:error, {:missing_field, "candidate_refresh.spacecraft_states.epoch"}}

  defp planning_state_time_scale(%{"time_scale" => scale})
       when scale in ["tdb", "tai", "utc"],
       do: {:ok, String.to_atom(scale)}

  defp planning_state_time_scale(%{"scale" => scale}) when scale in ["tdb", "tai", "utc"],
    do: {:ok, String.to_atom(scale)}

  defp planning_state_time_scale(_epoch), do: {:ok, :tdb}

  defp spacecraft_dry_mass(%{"dry_mass_kg" => value}) when is_integer(value) or is_float(value),
    do: {:ok, value * 1.0}

  defp spacecraft_dry_mass(%{"spacecraft" => %{"dry_mass_kg" => value}})
       when is_integer(value) or is_float(value),
       do: {:ok, value * 1.0}

  defp spacecraft_dry_mass(_state), do: {:ok, 0.0}

  defp validate_positive_duration(duration_s, _field) when duration_s > 0.0, do: :ok
  defp validate_positive_duration(_duration_s, field), do: {:error, {:invalid_field, field}}

  defp sun_direction(source) do
    case Map.fetch(source, "sun_direction") do
      {:ok, value} -> vector(value, "sun_direction")
      :error -> {:ok, {1.0, 0.0, 0.0}}
    end
  end

  defp run_options(source) do
    case Map.get(source, "run_options", %{}) do
      %{} = run_options ->
        with {:ok, known_options} <- known_run_options(run_options),
             {:ok, task_supervisor_options} <- task_supervisor_options(run_options) do
          {:ok, known_options ++ task_supervisor_options}
        end

      _run_options ->
        {:error, {:invalid_field, "run_options"}}
    end
  end

  defp known_run_options(run_options) do
    run_options
    |> Map.drop(["task_supervisor_node", "task_supervisor_nodes"])
    |> known_keyword_map("run_options", @run_option_keys)
  end

  defp task_supervisor_options(%{
         "task_supervisor_node" => _node_name,
         "task_supervisor_nodes" => _node_names
       }),
       do: {:error, {:invalid_field, "run_options.task_supervisor"}}

  defp task_supervisor_options(%{"task_supervisor_nodes" => node_names})
       when is_list(node_names) and node_names != [] do
    node_names
    |> Enum.reduce_while({:ok, []}, fn node_name, {:ok, supervisors} ->
      case task_supervisor(node_name) do
        {:ok, supervisor} -> {:cont, {:ok, supervisors ++ [supervisor]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, supervisors} -> {:ok, [task_supervisors: supervisors]}
      {:error, reason} -> {:error, reason}
    end
  end

  defp task_supervisor_options(%{"task_supervisor_nodes" => _node_names}),
    do: {:error, {:invalid_field, "run_options.task_supervisor_nodes"}}

  defp task_supervisor_options(%{"task_supervisor_node" => node_name})
       when is_binary(node_name) and node_name != "" do
    with {:ok, supervisor} <- task_supervisor(node_name) do
      {:ok, [task_supervisor: supervisor]}
    end
  end

  defp task_supervisor_options(%{"task_supervisor_node" => _node_name}),
    do: {:error, {:invalid_field, "run_options.task_supervisor_node"}}

  defp task_supervisor_options(_run_options), do: {:ok, []}

  defp task_supervisor("local"), do: {:ok, OrbitalDynamics.ScenarioSupervisor}

  defp task_supervisor(node_name) when is_binary(node_name) and node_name != "" do
    {:ok, {OrbitalDynamics.ScenarioSupervisor, String.to_atom(node_name)}}
  end

  defp task_supervisor(_node_name),
    do: {:error, {:invalid_field, "run_options.task_supervisor_nodes"}}

  defp metadata(source) do
    case Map.get(source, "metadata", %{}) do
      metadata when is_map(metadata) -> {:ok, metadata}
      _metadata -> {:error, {:invalid_field, "metadata"}}
    end
  end

  defp seed_manifest(source) do
    case Map.get(source, "seed_manifest", %{}) do
      seed_manifest when is_map(seed_manifest) -> {:ok, seed_manifest}
      _seed_manifest -> {:error, {:invalid_field, "seed_manifest"}}
    end
  end

  defp known_keyword_map(map, field, known_keys) when is_map(map) do
    map
    |> Enum.reduce_while({:ok, []}, fn {key, value}, {:ok, acc} ->
      case Map.fetch(known_keys, key) do
        {:ok, atom_key} -> {:cont, {:ok, acc ++ [{atom_key, value}]}}
        :error -> {:halt, {:error, {:unsupported_option, field, key}}}
      end
    end)
  end

  defp known_keyword_map(_map, field, _known_keys), do: {:error, {:invalid_field, field}}

  defp required(map, key), do: InputField.required(map, key)

  defp required_map(map, key), do: InputField.required_map(map, key)
  defp required_list(map, key), do: InputField.required_list(map, key)
  defp optional_list(map, key), do: InputField.optional_list(map, key)
  defp required_number(map, key), do: InputField.required_number(map, key)
  defp required_number_list(map, key), do: InputField.required_number_list(map, key)
  defp optional_number(map, key), do: InputField.optional_number(map, key)
  defp optional_string(map, key), do: InputField.optional_string(map, key)

  defp optional_boolean(map, key, default),
    do: InputField.optional_boolean(map, key, default)

  defp optional_string(map, key, default), do: InputField.optional_string(map, key, default)

  defp optional_map(map, key), do: InputField.optional_map(map, key)
  defp optional_map_or_nil(map, key), do: InputField.optional_map_or_nil(map, key)

  defp required_positive_integer(map, key),
    do: InputField.required_positive_integer(map, key)

  defp required_non_negative_integer(map, key),
    do: InputField.required_non_negative_integer(map, key)

  defp optional_positive_integer(map, key, default),
    do: InputField.optional_positive_integer(map, key, default)

  defp required_vector(map, key), do: InputField.required_vector(map, key)
  defp vector(value, key), do: InputField.vector(value, key)

  defp validate_non_negative_vector(vector, key),
    do: InputField.validate_non_negative_vector(vector, key)

  defp required_vector_list(map, key), do: InputField.required_vector_list(map, key)
  defp required_atom(map, key), do: InputField.required_atom(map, key)

  defp optional_atom(map, key, default, allowed),
    do: InputField.optional_atom(map, key, default, allowed)

  defp compact_keyword(keyword) do
    Enum.reject(keyword, fn {_key, value} -> is_nil(value) end)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
