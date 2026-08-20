defmodule OrbitalDynamics.StudyRunner do
  @moduledoc """
  Study-level workflow runner.

  The first workflow composes propagation with sample-based ground-station access
  and eclipse detection. It intentionally uses `ScenarioRunner` instead of
  backend-specific batch execution so heterogeneous studies remain
  straightforward.
  """

  alias OrbitalDynamics.EventDetectors.{
    AccessWindows,
    Eclipses,
    GroundTrackCrossings,
    TargetVisibility
  }

  alias OrbitalDynamics.Environment.CampaignEnvironmentProvider

  alias OrbitalDynamics.{
    CentralBody,
    Environment,
    GroundStation,
    ResultSet,
    ScenarioRunner,
    Study,
    StudyCheckpoint,
    StudyRun,
    Target
  }

  @supported_outputs [
    :trajectories,
    :access_windows,
    :eclipses,
    :target_visibility,
    :ground_track_crossings
  ]

  @doc """
  Runs a study and returns a result set.
  """
  def run(%Study{} = study, opts \\ []) do
    started_at = DateTime.utc_now()
    started_monotonic = System.monotonic_time()
    central_body = Keyword.get(opts, :central_body, CentralBody.earth())
    ground_stations = Keyword.get(opts, :ground_stations, [])
    targets = Keyword.get(opts, :targets, [])
    declared_ground_track_crossings = Keyword.get(opts, :ground_track_crossings, [])
    sun_direction = Keyword.get(opts, :sun_direction, {1.0, 0.0, 0.0})
    max_concurrency = Keyword.get(opts, :max_concurrency, System.schedulers_online())
    timeout = Keyword.get(opts, :timeout, :infinity)
    requested_task_chunk_size = Keyword.get(opts, :task_chunk_size, 1)
    task_supervisors = Keyword.get(opts, :task_supervisors)
    scenario_indexes = Keyword.get(opts, :scenario_indexes)
    retry_plan = Keyword.get(opts, :retry_plan)
    checkpoint_config = Keyword.get(opts, :checkpoint)
    external_provider_policy = external_provider_policy(opts)

    explicit_task_distribution? =
      Keyword.has_key?(opts, :task_supervisor) or Keyword.has_key?(opts, :task_supervisors)

    task_supervisor =
      if is_nil(task_supervisors),
        do: Keyword.get(opts, :task_supervisor, default_task_supervisor())

    batch_propagation? = batch_propagation?(study.propagator, opts, explicit_task_distribution?)
    backend_selection_policy = backend_selection_policy(study.propagator, batch_propagation?)

    with {:ok, campaign_environment} <- prepare_campaign_environment(study, opts),
         {:ok, ground_track_crossings} <-
           effective_ground_track_crossings(
             declared_ground_track_crossings,
             campaign_environment
           ),
         :ok <-
           validate_prepared_run_inputs(
             study,
             ground_stations,
             targets,
             ground_track_crossings,
             campaign_environment
           ),
         :ok <- validate_scenario_indexes(study, scenario_indexes),
         :ok <- validate_task_supervisor_config(task_supervisor, task_supervisors),
         :ok <-
           validate_checkpoint_execution(
             checkpoint_config,
             task_supervisor,
             task_supervisors,
             batch_propagation?,
             scenario_indexes,
             retry_plan,
             opts
           ) do
      execution_plan =
        execution_plan(study,
          max_concurrency: max_concurrency,
          requested_task_chunk_size: requested_task_chunk_size,
          task_supervisor: task_supervisor,
          task_supervisors: task_supervisors,
          batch_propagation?: batch_propagation?,
          retry_plan: retry_plan,
          checkpoint: checkpoint_config
        )

      task_chunk_size = execution_plan.resolved_task_chunk_size

      {propagation_outcome, propagation_ms} =
        timed(fn ->
          propagate_scenarios(study,
            max_concurrency: max_concurrency,
            timeout: timeout,
            task_supervisor: task_supervisor,
            task_supervisors: task_supervisors,
            task_chunk_size: task_chunk_size,
            batch_propagation?: batch_propagation?,
            scenario_indexes: scenario_indexes,
            checkpoint: checkpoint_config,
            checkpoint_identity_inputs:
              checkpoint_identity_inputs(study, opts,
                central_body: central_body,
                ground_stations: ground_stations,
                targets: targets,
                ground_track_crossings: declared_ground_track_crossings,
                sun_direction: sun_direction,
                campaign_environment: campaign_environment_provenance(campaign_environment),
                max_concurrency: max_concurrency,
                timeout: timeout,
                requested_task_chunk_size: requested_task_chunk_size,
                resolved_task_chunk_size: task_chunk_size,
                task_supervisor: task_supervisor,
                batch_propagation?: batch_propagation?
              ),
            checkpoint_test_hook: Keyword.get(opts, :checkpoint_test_hook),
            checkpoint_initial_publish_test_hook:
              Keyword.get(opts, :checkpoint_initial_publish_test_hook)
          )
        end)

      with {:ok, propagation_results, checkpoint_provenance} <- propagation_outcome do
        execution_plan =
          put_checkpoint_execution_provenance(execution_plan, checkpoint_provenance)

        trajectory_results = trajectory_results(propagation_results)
        propagation_errors = propagation_errors(propagation_results)

        {{event_results, event_errors}, event_detection_ms} =
          timed(fn ->
            event_results(
              study,
              trajectory_results,
              ground_stations,
              targets,
              ground_track_crossings,
              central_body,
              sun_direction,
              campaign_environment
            )
          end)

        errors = propagation_errors ++ event_errors
        completed_at = DateTime.utc_now()
        duration_ms = elapsed_ms(started_monotonic)

        assumptions =
          assumptions(
            study,
            central_body,
            ground_stations,
            targets,
            declared_ground_track_crossings,
            sun_direction,
            campaign_environment,
            external_provider_policy,
            backend_selection_policy,
            retry_plan,
            checkpoint_provenance
          )

        {:ok,
         ResultSet.new!(%{
           study_id: study.id,
           trajectory_results: maybe_include_trajectories(study.outputs, trajectory_results),
           event_results: event_results,
           errors: errors,
           assumptions: assumptions,
           metadata:
             metadata(study, opts,
               started_at: started_at,
               completed_at: completed_at,
               duration_ms: duration_ms,
               assumptions: assumptions,
               trajectory_results: trajectory_results,
               event_results: event_results,
               errors: errors,
               max_concurrency: max_concurrency,
               effective_task_concurrency:
                 effective_task_concurrency(max_concurrency, task_supervisors),
               timeout: timeout,
               task_chunk_size: task_chunk_size,
               task_supervisor: task_supervisor,
               task_supervisors: task_supervisors,
               batch_propagation?: batch_propagation?,
               external_provider_policy: external_provider_policy,
               backend_selection_policy: backend_selection_policy,
               execution_plan: execution_plan,
               retry_plan: retry_plan,
               checkpoint_provenance: checkpoint_provenance,
               phase_timings_ms: %{
                 propagation: propagation_ms,
                 event_detection: event_detection_ms
               }
             )
         })}
      end
    end
  end

  @doc """
  Builds a deterministic retry plan from failed rows in an execution report.

  Failed rows are validated against the study's scenario IDs and zero-based
  indexes, deduplicated, and returned in source-manifest order regardless of the
  report row order.
  """
  def failed_scenario_retry_plan(%Study{} = study, execution_report)
      when is_map(execution_report) do
    with :ok <- validate_retry_report_contract(execution_report),
         :ok <- validate_retry_study(study, execution_report),
         {:ok, failed_scenarios} <- retry_failed_scenarios(execution_report),
         {:ok, rows} <- validate_retry_rows(study, failed_scenarios) do
      ordered_rows = Enum.sort_by(rows, & &1.scenario_index)

      {:ok,
       %{
         mode: "failed_scenario_retry",
         selection_source: "execution_report.failed_scenarios",
         ordering: "source_manifest_scenario_order",
         source_study_id: retry_identity(study.id),
         source_run_id: report_value(execution_report, :run_id),
         source_execution_status: report_value(execution_report, :status),
         source_scenario_count: length(study.scenarios),
         scenario_count: length(ordered_rows),
         scenario_indexes: Enum.map(ordered_rows, & &1.scenario_index),
         scenario_ids: Enum.map(ordered_rows, & &1.scenario_id)
       }}
    end
  end

  def failed_scenario_retry_plan(%Study{}, _execution_report),
    do: {:error, :invalid_execution_report}

  @doc """
  Retries only the failed scenarios selected by `failed_scenario_retry_plan/2`.

  The returned results retain their original source-manifest scenario indexes.
  This is an explicit retry batch, not a checkpoint merge or persistent queue.
  """
  def retry_failed(%Study{} = study, execution_report, opts \\ []) do
    with {:ok, retry_plan} <- failed_scenario_retry_plan(study, execution_report) do
      retry_plan =
        maybe_put_map(retry_plan, :source_artifact, Keyword.get(opts, :retry_source))

      retry_study = %{
        study
        | scenarios: Enum.map(retry_plan.scenario_indexes, &Enum.at(study.scenarios, &1))
      }

      retry_opts =
        opts
        |> Keyword.delete(:retry_source)
        |> Keyword.put(:scenario_indexes, retry_plan.scenario_indexes)
        |> Keyword.put(:retry_plan, retry_plan)

      run(retry_study, retry_opts)
    end
  end

  @doc """
  Validates study run inputs without propagating scenarios or checking task-supervisor reachability.
  """
  def validate_run_inputs(%Study{} = study, opts \\ []) do
    ground_stations = Keyword.get(opts, :ground_stations, [])
    targets = Keyword.get(opts, :targets, [])
    declared_ground_track_crossings = Keyword.get(opts, :ground_track_crossings, [])

    with {:ok, campaign_environment} <- prepare_campaign_environment(study, opts),
         {:ok, ground_track_crossings} <-
           effective_ground_track_crossings(
             declared_ground_track_crossings,
             campaign_environment
           ) do
      validate_prepared_run_inputs(
        study,
        ground_stations,
        targets,
        ground_track_crossings,
        campaign_environment
      )
    end
  end

  defp validate_prepared_run_inputs(
         study,
         ground_stations,
         targets,
         ground_track_crossings,
         campaign_environment
       ) do
    with :ok <- validate_outputs(study.outputs),
         :ok <- validate_ground_stations(study.outputs, ground_stations),
         :ok <- validate_targets(study.outputs, targets),
         :ok <-
           validate_ground_track_crossings(
             study,
             ground_track_crossings,
             campaign_environment
           ) do
      :ok
    end
  end

  defp prepare_campaign_environment(%Study{} = study, opts) do
    case Keyword.get(opts, :campaign_environment) do
      nil ->
        {:ok, nil}

      {CampaignEnvironmentProvider, provider_opts} when is_list(provider_opts) ->
        prepare_campaign_environment_provider(
          study,
          CampaignEnvironmentProvider,
          provider_opts
        )

      {provider, _provider_opts} when is_atom(provider) ->
        {:error, {:untrusted_campaign_environment_provider, provider}}

      _campaign_environment ->
        {:error, {:invalid_option, :campaign_environment}}
    end
  end

  defp prepare_campaign_environment_provider(study, provider, provider_opts) do
    request = campaign_environment_request(study)

    with true <- provider == CampaignEnvironmentProvider,
         {:ok, configuration} <- provider.trusted_configuration(provider_opts),
         :ok <- validate_campaign_environment_request(configuration.capability, request) do
      {:ok,
       %{
         provider: provider,
         provider_opts: configuration.provider_opts,
         capability: configuration.capability,
         provenance: configuration.provenance
       }}
    else
      false -> {:error, {:invalid_option, :campaign_environment}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp campaign_environment_request(%Study{scenarios: scenarios}) do
    spans =
      Enum.map(scenarios, fn scenario ->
        starts_at_s = scenario.initial_state.epoch.seconds_since_j2000 * 1.0
        {starts_at_s, starts_at_s + scenario.duration_s}
      end)

    {starts_at_s, ends_at_s} =
      Enum.reduce(spans, fn {start_s, end_s}, {min_start_s, max_end_s} ->
        {min(start_s, min_start_s), max(end_s, max_end_s)}
      end)

    %{
      starts_at_s: starts_at_s,
      ends_at_s: ends_at_s,
      bodies: Enum.map(scenarios, & &1.central_body.name) |> Enum.uniq(),
      outputs: [:sun_direction, :earth_rotation],
      frames:
        (Enum.map(scenarios, & &1.initial_state.frame.name) ++
           [:earth_fixed_era_from_eci_j2000_approximation])
        |> Enum.uniq(),
      time_scales: Enum.map(scenarios, & &1.initial_state.epoch.scale) |> Enum.uniq()
    }
  end

  defp validate_campaign_environment_request(capability, request) do
    cond do
      Environment.provider_supports_request?(capability, request) ->
        :ok

      not Environment.provider_covers_time_span?(capability, request) ->
        {:error,
         {:campaign_environment_request_outside_coverage,
          %{starts_at_s: request.starts_at_s, ends_at_s: request.ends_at_s}}}

      true ->
        {:error, {:campaign_environment_request_mismatch, request}}
    end
  end

  defp effective_ground_track_crossings(ground_track_crossings, nil),
    do: {:ok, ground_track_crossings}

  defp effective_ground_track_crossings(ground_track_crossings, campaign_environment)
       when is_list(ground_track_crossings) do
    ground_track_crossings
    |> Enum.reduce_while({:ok, []}, fn request, {:ok, acc} ->
      case effective_ground_track_crossing(request, campaign_environment) do
        {:ok, effective} -> {:cont, {:ok, [effective | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, effective} -> {:ok, Enum.reverse(effective)}
      error -> error
    end
  end

  defp effective_ground_track_crossings(_ground_track_crossings, _campaign_environment),
    do: {:error, {:invalid_option, :ground_track_crossings}}

  defp effective_ground_track_crossing(%{} = request, campaign_environment) do
    rotation_keys = [
      :earth_rotation_provider,
      :rotation_rate_rad_s,
      :rotation_epoch_s,
      :rotation_angle_offset_rad,
      :campaign_environment
    ]

    cond do
      Enum.any?(rotation_keys, &Map.has_key?(request, &1)) or
          Map.has_key?(request, "campaign_environment") ->
        {:error, {:campaign_environment_conflict, :earth_rotation_provider}}

      Map.get(request, :frame, :inertial) in [:body_fixed, "body_fixed"] ->
        provider_opts =
          campaign_environment.provider_opts
          |> Keyword.put(:body, :earth)
          |> Keyword.put(:frame, :earth_fixed_era_from_eci_j2000_approximation)
          |> Keyword.put(:time_scale, :utc)

        {:ok,
         request
         |> Map.put(
           :earth_rotation_provider,
           {campaign_environment.provider, provider_opts}
         )
         |> Map.put(:campaign_environment, campaign_environment.provenance)}

      true ->
        {:ok, request}
    end
  end

  defp effective_ground_track_crossing(request, _campaign_environment), do: {:ok, request}

  defp campaign_environment_provenance(nil), do: nil
  defp campaign_environment_provenance(campaign_environment), do: campaign_environment.provenance

  defp validate_outputs(outputs) do
    unsupported = outputs -- @supported_outputs
    if unsupported == [], do: :ok, else: {:error, {:unsupported_outputs, unsupported}}
  end

  defp validate_scenario_indexes(_study, nil), do: :ok

  defp validate_scenario_indexes(%Study{} = study, scenario_indexes)
       when is_list(scenario_indexes) do
    valid? =
      length(study.scenarios) == length(scenario_indexes) and
        Enum.all?(scenario_indexes, &(is_integer(&1) and &1 >= 0)) and
        Enum.uniq(scenario_indexes) == scenario_indexes and
        Enum.sort(scenario_indexes) == scenario_indexes

    if valid?, do: :ok, else: {:error, {:invalid_option, :scenario_indexes}}
  end

  defp validate_scenario_indexes(_study, _scenario_indexes),
    do: {:error, {:invalid_option, :scenario_indexes}}

  defp validate_retry_report_contract(execution_report) do
    if report_value(execution_report, :schema_contract) == "execution_report.v1" do
      :ok
    else
      {:error, :invalid_execution_report_contract}
    end
  end

  defp validate_retry_study(%Study{} = study, execution_report) do
    expected_study_id = retry_identity(study.id)
    actual_study_id = retry_identity(report_value(execution_report, :study_id))
    expected_scenario_count = length(study.scenarios)
    actual_scenario_count = report_value(execution_report, :scenario_count)

    cond do
      actual_study_id != expected_study_id ->
        {:error, {:retry_study_id_mismatch, expected_study_id, actual_study_id}}

      actual_scenario_count != expected_scenario_count ->
        {:error, {:retry_scenario_count_mismatch, expected_scenario_count, actual_scenario_count}}

      true ->
        :ok
    end
  end

  defp retry_failed_scenarios(execution_report) do
    case report_value(execution_report, :failed_scenarios) do
      failed_scenarios when is_list(failed_scenarios) and failed_scenarios != [] ->
        {:ok, failed_scenarios}

      [] ->
        {:error, :no_failed_scenarios}

      _value ->
        {:error, :invalid_failed_scenarios}
    end
  end

  defp validate_retry_rows(%Study{} = study, failed_scenarios) do
    failed_scenarios
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, [], MapSet.new()}, fn {row, row_index},
                                                     {:ok, rows, seen_indexes} ->
      case validate_retry_row(study, row, row_index) do
        {:ok, validated_row} ->
          if MapSet.member?(seen_indexes, validated_row.scenario_index) do
            {:halt, {:error, {:duplicate_retry_scenario_index, validated_row.scenario_index}}}
          else
            {:cont,
             {:ok, [validated_row | rows], MapSet.put(seen_indexes, validated_row.scenario_index)}}
          end

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, rows, _seen_indexes} -> {:ok, Enum.reverse(rows)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_retry_row(%Study{} = study, row, row_index) when is_map(row) do
    scenario_index = report_value(row, :scenario_index)
    scenario_id = retry_identity(report_value(row, :scenario_id))

    cond do
      not (is_integer(scenario_index) and scenario_index >= 0 and
               scenario_index < length(study.scenarios)) ->
        {:error, {:invalid_retry_scenario_index, row_index, scenario_index}}

      true ->
        expected_scenario_id =
          study.scenarios |> Enum.at(scenario_index) |> Map.fetch!(:id) |> retry_identity()

        if scenario_id == expected_scenario_id do
          {:ok, %{scenario_index: scenario_index, scenario_id: expected_scenario_id}}
        else
          {:error,
           {:retry_scenario_id_mismatch, scenario_index, expected_scenario_id, scenario_id}}
        end
    end
  end

  defp validate_retry_row(_study, _row, row_index),
    do: {:error, {:invalid_retry_scenario_row, row_index}}

  defp report_value(map, key) do
    Map.get(map, key, Map.get(map, Atom.to_string(key)))
  end

  defp retry_identity(nil), do: nil
  defp retry_identity(value) when is_atom(value), do: Atom.to_string(value)
  defp retry_identity(value) when is_binary(value), do: value
  defp retry_identity(value), do: to_string(value)

  defp validate_ground_stations(outputs, ground_stations) do
    cond do
      :access_windows not in outputs ->
        :ok

      ground_stations == [] ->
        {:error, {:missing_option, :ground_stations}}

      not is_list(ground_stations) or
          not Enum.all?(ground_stations, &match?(%GroundStation{}, &1)) ->
        {:error, {:invalid_option, :ground_stations}}

      true ->
        :ok
    end
  end

  defp validate_targets(outputs, targets) do
    cond do
      :target_visibility not in outputs ->
        :ok

      targets == [] ->
        {:error, {:missing_option, :targets}}

      not is_list(targets) or not Enum.all?(targets, &match?(%Target{}, &1)) ->
        {:error, {:invalid_option, :targets}}

      true ->
        :ok
    end
  end

  defp validate_ground_track_crossings(
         %Study{outputs: outputs} = study,
         ground_track_crossings,
         campaign_environment
       ) do
    cond do
      :ground_track_crossings not in outputs ->
        :ok

      ground_track_crossings == [] ->
        {:error, {:missing_option, :ground_track_crossings}}

      not is_list(ground_track_crossings) ->
        {:error, {:invalid_option, :ground_track_crossings}}

      true ->
        Enum.reduce_while(ground_track_crossings, :ok, fn request, :ok ->
          case validate_ground_track_crossing(request, study, campaign_environment) do
            :ok -> {:cont, :ok}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)
    end
  end

  defp validate_ground_track_crossing(
         %{crossing: :latitude, latitude_deg: value} = request,
         study,
         campaign_environment
       )
       when is_number(value) do
    validate_ground_track_rotation_opts(request, study, campaign_environment)
  end

  defp validate_ground_track_crossing(
         %{crossing: :longitude, longitude_deg: value} = request,
         study,
         campaign_environment
       )
       when is_number(value) do
    validate_ground_track_rotation_opts(request, study, campaign_environment)
  end

  defp validate_ground_track_crossing(_request, _study, _campaign_environment),
    do: {:error, {:invalid_option, :ground_track_crossings}}

  defp validate_ground_track_rotation_opts(request, study, campaign_environment) do
    numeric_opts? =
      [:rotation_rate_rad_s, :rotation_epoch_s, :rotation_angle_offset_rad]
      |> Enum.all?(fn key ->
        case Map.fetch(request, key) do
          {:ok, value} -> is_number(value)
          :error -> true
        end
      end)

    with true <- numeric_opts?,
         :ok <- validate_campaign_ground_track_evidence(request, campaign_environment),
         :ok <-
           validate_earth_rotation_provider(
             Map.get(request, :earth_rotation_provider),
             study
           ) do
      :ok
    else
      false -> {:error, {:invalid_option, :ground_track_crossings}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_campaign_ground_track_evidence(request, nil) do
    if Map.has_key?(request, :campaign_environment) or
         Map.has_key?(request, "campaign_environment") do
      {:error, {:untrusted_campaign_environment_evidence, :ground_track_crossings}}
    else
      :ok
    end
  end

  defp validate_campaign_ground_track_evidence(request, campaign_environment) do
    declared =
      [:campaign_environment, "campaign_environment"]
      |> Enum.filter(&Map.has_key?(request, &1))
      |> Enum.map(&Map.fetch!(request, &1))

    if declared == [] or Enum.all?(declared, &(&1 == campaign_environment.provenance)) do
      :ok
    else
      {:error, {:campaign_environment_provenance_mismatch, :ground_track_crossings}}
    end
  end

  defp validate_earth_rotation_provider(nil, _study), do: :ok

  defp validate_earth_rotation_provider(provider, study) do
    request = earth_rotation_provider_request(study)

    case GroundTrackCrossings.validate_earth_rotation_provider(provider, request) do
      :ok ->
        :ok

      {:error, {:untrusted_campaign_environment_provider, _provider} = reason} ->
        {:error, reason}

      {:error, {:untrusted_campaign_environment_evidence, _source} = reason} ->
        {:error, reason}

      {:error, {:invalid_campaign_environment_configuration, _detail} = reason} ->
        {:error, reason}

      {:error, _reason} ->
        {:error, {:invalid_option, :ground_track_crossings}}
    end
  end

  defp earth_rotation_provider_request(%Study{scenarios: scenarios}) do
    spans =
      Enum.map(scenarios, fn scenario ->
        starts_at_s = scenario.initial_state.epoch.seconds_since_j2000 * 1.0
        {starts_at_s, starts_at_s + scenario.duration_s}
      end)

    {starts_at_s, ends_at_s} =
      Enum.reduce(spans, fn {start_s, end_s}, {min_start_s, max_end_s} ->
        {min(start_s, min_start_s), max(end_s, max_end_s)}
      end)

    %{
      starts_at_s: starts_at_s,
      ends_at_s: ends_at_s,
      bodies: Enum.map(scenarios, & &1.central_body.name) |> Enum.uniq(),
      output: :earth_rotation
    }
  end

  defp validate_task_supervisor(nil), do: :ok

  defp validate_task_supervisor({supervisor, remote_node})
       when is_atom(supervisor) and is_atom(remote_node) do
    if remote_node == node() or remote_node in Node.list() do
      :ok
    else
      {:error, {:node_unavailable, remote_node}}
    end
  end

  defp validate_task_supervisor(supervisor) when is_atom(supervisor), do: :ok
  defp validate_task_supervisor(_supervisor), do: {:error, {:invalid_option, :task_supervisor}}

  defp validate_task_supervisor_config(_task_supervisor, supervisors)
       when is_list(supervisors) do
    cond do
      supervisors == [] ->
        {:error, {:invalid_option, :task_supervisors}}

      true ->
        supervisors
        |> Enum.reduce_while(:ok, fn supervisor, :ok ->
          case validate_task_supervisor(supervisor) do
            :ok -> {:cont, :ok}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)
    end
  end

  defp validate_task_supervisor_config(task_supervisor, nil),
    do: validate_task_supervisor(task_supervisor)

  defp validate_task_supervisor_config(_task_supervisor, _supervisors),
    do: {:error, {:invalid_option, :task_supervisors}}

  defp validate_checkpoint_execution(
         nil,
         _task_supervisor,
         _task_supervisors,
         _batch?,
         _scenario_indexes,
         _retry_plan,
         _opts
       ),
       do: :ok

  defp validate_checkpoint_execution(
         checkpoint,
         task_supervisor,
         task_supervisors,
         batch_propagation?,
         scenario_indexes,
         retry_plan,
         opts
       )
       when is_map(checkpoint) do
    cond do
      not is_nil(retry_plan) or not is_nil(scenario_indexes) ->
        {:error, {:unsupported_checkpoint_mode, :failed_scenario_retry}}

      is_list(task_supervisors) ->
        {:error, {:unsupported_checkpoint_mode, :task_supervisors}}

      is_tuple(task_supervisor) ->
        {:error, {:unsupported_checkpoint_mode, :distributed_task_supervisor}}

      batch_propagation? ->
        {:error, {:unsupported_checkpoint_mode, :batch_propagation}}

      not is_map(Keyword.get(opts, :manifest)) ->
        {:error, {:checkpoint_identity_required, :manifest}}

      true ->
        :ok
    end
  end

  defp validate_checkpoint_execution(
         _checkpoint,
         _task_supervisor,
         _task_supervisors,
         _batch_propagation?,
         _scenario_indexes,
         _retry_plan,
         _opts
       ),
       do: {:error, {:invalid_checkpoint_option, :checkpoint}}

  defp propagate_scenarios(%Study{} = study, opts) do
    case Keyword.fetch!(opts, :checkpoint) do
      nil ->
        {:ok, propagate_scenarios_without_checkpoint(study, opts), nil}

      checkpoint_config ->
        StudyCheckpoint.execute(
          study,
          checkpoint_config,
          Keyword.fetch!(opts, :checkpoint_identity_inputs),
          Keyword.fetch!(opts, :task_chunk_size),
          fn scenarios, scenario_indexes ->
            ScenarioRunner.run(scenarios,
              propagator: study.propagator,
              propagator_opts: study.propagator_opts,
              max_concurrency: Keyword.fetch!(opts, :max_concurrency),
              timeout: Keyword.fetch!(opts, :timeout),
              task_supervisor: Keyword.fetch!(opts, :task_supervisor),
              task_supervisors: nil,
              task_chunk_size: 1,
              scenario_indexes: scenario_indexes
            )
          end,
          test_hook: Keyword.fetch!(opts, :checkpoint_test_hook),
          initial_publish_test_hook: Keyword.fetch!(opts, :checkpoint_initial_publish_test_hook)
        )
    end
  end

  defp propagate_scenarios_without_checkpoint(%Study{} = study, opts) do
    if Keyword.fetch!(opts, :batch_propagation?) do
      propagate_batch(study, Keyword.fetch!(opts, :scenario_indexes))
    else
      ScenarioRunner.run(study.scenarios,
        propagator: study.propagator,
        propagator_opts: study.propagator_opts,
        max_concurrency: Keyword.fetch!(opts, :max_concurrency),
        timeout: Keyword.fetch!(opts, :timeout),
        task_supervisor: Keyword.fetch!(opts, :task_supervisor),
        task_supervisors: Keyword.fetch!(opts, :task_supervisors),
        task_chunk_size: Keyword.fetch!(opts, :task_chunk_size),
        scenario_indexes: Keyword.fetch!(opts, :scenario_indexes)
      )
    end
  end

  defp propagate_batch(%Study{} = study, scenario_indexes) do
    source_indexes = scenario_indexes || Enum.to_list(0..(length(study.scenarios) - 1))

    case study.propagator.propagate_many(study.scenarios, study.propagator_opts) do
      {:ok, trajectories} ->
        trajectories
        |> Enum.zip(source_indexes)
        |> Enum.map(fn {trajectory, source_index} ->
          %ScenarioRunner.Result{
            scenario_id: trajectory.scenario_id,
            scenario_index: source_index,
            status: :ok,
            value: trajectory,
            node: node()
          }
        end)

      {:error, reason} ->
        study.scenarios
        |> Enum.zip(source_indexes)
        |> Enum.map(fn {scenario, source_index} ->
          %ScenarioRunner.Result{
            scenario_id: scenario.id,
            scenario_index: source_index,
            status: :error,
            error: reason,
            node: node()
          }
        end)
    end
  end

  defp batch_propagation?(propagator, opts, explicit_task_distribution?) do
    preference = Keyword.get(opts, :batch_propagation, :auto)

    cond do
      preference == false ->
        false

      explicit_task_distribution? ->
        false

      batch_propagator?(propagator) ->
        true

      preference == true ->
        false

      true ->
        false
    end
  end

  defp batch_propagator?(propagator) do
    Code.ensure_loaded?(propagator) and function_exported?(propagator, :propagate_many, 2)
  end

  defp trajectory_results(propagation_results) do
    propagation_results
    |> Enum.filter(&(&1.status == :ok))
    |> Enum.map(fn result ->
      %{
        scenario_id: result.scenario_id,
        scenario_index: result.scenario_index,
        trajectory: result.value,
        node: result.node
      }
    end)
  end

  defp propagation_errors(propagation_results) do
    propagation_results
    |> Enum.filter(&(&1.status == :error))
    |> Enum.map(fn result ->
      %{
        scenario_id: result.scenario_id,
        scenario_index: result.scenario_index,
        stage: :propagation,
        error: result.error,
        node: result.node
      }
    end)
  end

  defp event_results(
         %Study{outputs: outputs},
         trajectory_results,
         ground_stations,
         targets,
         ground_track_crossings,
         central_body,
         sun_direction,
         campaign_environment
       ) do
    []
    |> maybe_add_access_window_results(outputs, trajectory_results, ground_stations, central_body)
    |> maybe_add_eclipse_results(
      outputs,
      trajectory_results,
      central_body,
      sun_direction,
      campaign_environment
    )
    |> maybe_add_target_visibility_results(outputs, trajectory_results, targets, central_body)
    |> maybe_add_ground_track_crossing_results(
      outputs,
      trajectory_results,
      ground_track_crossings
    )
    |> split_results()
  end

  defp maybe_add_access_window_results(
         results,
         outputs,
         trajectory_results,
         ground_stations,
         central_body
       ) do
    if :access_windows in outputs do
      results ++ access_window_results(trajectory_results, ground_stations, central_body)
    else
      results
    end
  end

  defp maybe_add_eclipse_results(
         results,
         outputs,
         trajectory_results,
         central_body,
         sun_direction,
         campaign_environment
       ) do
    if :eclipses in outputs do
      results ++
        eclipse_results(
          trajectory_results,
          central_body,
          sun_direction,
          campaign_environment
        )
    else
      results
    end
  end

  defp maybe_add_target_visibility_results(
         results,
         outputs,
         trajectory_results,
         targets,
         central_body
       ) do
    if :target_visibility in outputs do
      results ++ target_visibility_results(trajectory_results, targets, central_body)
    else
      results
    end
  end

  defp access_window_results(trajectory_results, ground_stations, central_body) do
    trajectory_results
    |> Enum.flat_map(fn trajectory_result ->
      Enum.map(ground_stations, fn station ->
        case AccessWindows.detect(trajectory_result.trajectory,
               ground_station: station,
               central_body: central_body
             ) do
          {:ok, events} ->
            {:ok,
             %{
               scenario_id: trajectory_result.scenario_id,
               event_type: :ground_station_access,
               events: events,
               source: %{ground_station_id: station.id}
             }}

          {:error, reason} ->
            {:error,
             %{
               scenario_id: trajectory_result.scenario_id,
               scenario_index: trajectory_result.scenario_index,
               stage: :access_windows,
               error: reason,
               source: %{ground_station_id: station.id}
             }}
        end
      end)
    end)
  end

  defp eclipse_results(trajectory_results, central_body, sun_direction, campaign_environment) do
    Enum.map(trajectory_results, fn trajectory_result ->
      case Eclipses.detect(
             trajectory_result.trajectory,
             eclipse_detector_opts(central_body, sun_direction, campaign_environment)
           ) do
        {:ok, events} ->
          {:ok,
           %{
             scenario_id: trajectory_result.scenario_id,
             event_type: :eclipse,
             events: events,
             source:
               %{shadow_model: :cylindrical_central_body_shadow}
               |> maybe_put_map(
                 :campaign_environment,
                 campaign_environment_provenance(campaign_environment)
               )
           }}

        {:error, reason} ->
          {:error,
           %{
             scenario_id: trajectory_result.scenario_id,
             scenario_index: trajectory_result.scenario_index,
             stage: :eclipses,
             error: reason,
             source:
               %{shadow_model: :cylindrical_central_body_shadow}
               |> maybe_put_map(
                 :campaign_environment,
                 campaign_environment_provenance(campaign_environment)
               )
           }}
      end
    end)
  end

  defp eclipse_detector_opts(central_body, sun_direction, nil) do
    [central_body: central_body, sun_direction: sun_direction]
  end

  defp eclipse_detector_opts(central_body, _sun_direction, campaign_environment) do
    [
      central_body: central_body,
      sun_direction_provider: {campaign_environment.provider, campaign_environment.provider_opts}
    ]
  end

  defp target_visibility_results(trajectory_results, targets, central_body) do
    trajectory_results
    |> Enum.flat_map(fn trajectory_result ->
      Enum.map(targets, fn target ->
        case TargetVisibility.detect(trajectory_result.trajectory,
               target: target,
               central_body: central_body
             ) do
          {:ok, events} ->
            {:ok,
             %{
               scenario_id: trajectory_result.scenario_id,
               event_type: :target_visibility,
               events: events,
               source: %{target_id: target.id}
             }}

          {:error, reason} ->
            {:error,
             %{
               scenario_id: trajectory_result.scenario_id,
               scenario_index: trajectory_result.scenario_index,
               stage: :target_visibility,
               error: reason,
               source: %{target_id: target.id}
             }}
        end
      end)
    end)
  end

  defp maybe_add_ground_track_crossing_results(
         results,
         outputs,
         trajectory_results,
         ground_track_crossings
       ) do
    if :ground_track_crossings in outputs do
      results ++ ground_track_crossing_results(trajectory_results, ground_track_crossings)
    else
      results
    end
  end

  defp ground_track_crossing_results(trajectory_results, ground_track_crossings) do
    trajectory_results
    |> Enum.flat_map(fn trajectory_result ->
      Enum.map(ground_track_crossings, fn request ->
        case GroundTrackCrossings.detect(
               trajectory_result.trajectory,
               ground_track_detector_opts(request)
             ) do
          {:ok, events} ->
            {:ok,
             %{
               scenario_id: trajectory_result.scenario_id,
               event_type: :ground_track_crossing,
               events: events,
               source: ground_track_source(request)
             }}

          {:error, reason} ->
            {:error,
             %{
               scenario_id: trajectory_result.scenario_id,
               scenario_index: trajectory_result.scenario_index,
               stage: :ground_track_crossings,
               error: reason,
               source: ground_track_source(request)
             }}
        end
      end)
    end)
  end

  defp ground_track_detector_opts(%{crossing: :latitude, latitude_deg: latitude_deg} = request) do
    request
    |> ground_track_rotation_opts()
    |> Keyword.merge(
      crossing: :latitude,
      latitude_deg: latitude_deg,
      frame: Map.get(request, :frame, :inertial)
    )
  end

  defp ground_track_detector_opts(%{crossing: :longitude, longitude_deg: longitude_deg} = request) do
    request
    |> ground_track_rotation_opts()
    |> Keyword.merge(
      crossing: :longitude,
      longitude_deg: longitude_deg,
      frame: Map.get(request, :frame, :inertial)
    )
  end

  defp ground_track_rotation_opts(request) do
    request
    |> Map.take([
      :rotation_rate_rad_s,
      :rotation_epoch_s,
      :rotation_angle_offset_rad,
      :earth_rotation_provider,
      :campaign_environment
    ])
    |> Map.to_list()
  end

  defp ground_track_source(%{crossing: :latitude, latitude_deg: latitude_deg} = request) do
    %{
      crossing: :latitude,
      target_deg: latitude_deg,
      frame: Map.get(request, :frame, :inertial),
      rotation_rate_rad_s: Map.get(request, :rotation_rate_rad_s),
      rotation_epoch_s: Map.get(request, :rotation_epoch_s),
      rotation_angle_offset_rad: Map.get(request, :rotation_angle_offset_rad),
      earth_rotation_provider: Map.get(request, :earth_rotation_provider),
      campaign_environment: Map.get(request, :campaign_environment),
      request_id: Map.get(request, :id)
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp ground_track_source(%{crossing: :longitude, longitude_deg: longitude_deg} = request) do
    %{
      crossing: :longitude,
      target_deg: longitude_deg,
      frame: Map.get(request, :frame, :inertial),
      rotation_rate_rad_s: Map.get(request, :rotation_rate_rad_s),
      rotation_epoch_s: Map.get(request, :rotation_epoch_s),
      rotation_angle_offset_rad: Map.get(request, :rotation_angle_offset_rad),
      earth_rotation_provider: Map.get(request, :earth_rotation_provider),
      campaign_environment: Map.get(request, :campaign_environment),
      request_id: Map.get(request, :id)
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp split_results(results) do
    Enum.reduce(results, {[], []}, fn
      {:ok, result}, {ok, errors} -> {[result | ok], errors}
      {:error, error}, {ok, errors} -> {ok, [error | errors]}
    end)
    |> then(fn {ok, errors} -> {Enum.reverse(ok), Enum.reverse(errors)} end)
  end

  defp maybe_include_trajectories(outputs, trajectory_results) do
    if :trajectories in outputs, do: trajectory_results, else: []
  end

  defp assumptions(
         study,
         central_body,
         ground_stations,
         targets,
         ground_track_crossings,
         sun_direction,
         campaign_environment,
         external_provider_policy,
         backend_selection_policy,
         retry_plan,
         checkpoint_provenance
       ) do
    %{
      propagator: study.propagator,
      propagator_opts: study.propagator_opts,
      outputs: study.outputs,
      central_body: central_body.name,
      ground_station_ids: Enum.map(ground_stations, & &1.id),
      target_ids: Enum.map(targets, & &1.id),
      ground_track_crossings: ground_track_crossings,
      sun_direction: sun_direction,
      seed_manifest: study.seed_manifest,
      study_metadata: study.metadata,
      external_provider_policy: external_provider_policy,
      backend_selection_policy: backend_selection_policy
    }
    |> maybe_put_map(:campaign_environment, campaign_environment_provenance(campaign_environment))
    |> maybe_put_map(:retry, retry_plan)
    |> maybe_put_map(:checkpoint, checkpoint_provenance)
  end

  defp metadata(study, opts, run_data) do
    trajectory_results = Keyword.fetch!(run_data, :trajectory_results)
    event_results = Keyword.fetch!(run_data, :event_results)
    errors = Keyword.fetch!(run_data, :errors)

    run =
      StudyRun.new!(
        Keyword.get(opts, :run_id, default_run_id(study, run_data)),
        study,
        status: :completed,
        backend: study.propagator,
        node: node(),
        options: run_options(study, run_data),
        started_at: Keyword.fetch!(run_data, :started_at),
        completed_at: Keyword.fetch!(run_data, :completed_at),
        duration_ms: Keyword.fetch!(run_data, :duration_ms),
        assumptions: Keyword.fetch!(run_data, :assumptions),
        results: Enum.map(trajectory_results, & &1.scenario_id),
        errors: errors,
        metadata: run_metadata(study, opts, run_data)
      )

    %{
      output_count: %{
        trajectories: length(trajectory_results),
        event_results: length(event_results),
        errors: length(errors)
      },
      run: StudyRun.to_map(run)
    }
  end

  defp run_options(study, run_data) do
    [
      propagator_opts: study.propagator_opts,
      max_concurrency: Keyword.fetch!(run_data, :max_concurrency),
      effective_task_concurrency: Keyword.fetch!(run_data, :effective_task_concurrency),
      timeout: Keyword.fetch!(run_data, :timeout),
      task_chunk_size: Keyword.fetch!(run_data, :task_chunk_size),
      batch_propagation: Keyword.fetch!(run_data, :batch_propagation?),
      task_supervisor: Keyword.fetch!(run_data, :task_supervisor)
    ]
    |> maybe_put(:task_supervisors, Keyword.fetch!(run_data, :task_supervisors))
  end

  defp run_metadata(study, opts, run_data) do
    task_supervisor = Keyword.fetch!(run_data, :task_supervisor)
    task_supervisors = Keyword.fetch!(run_data, :task_supervisors)
    batch_propagation? = Keyword.fetch!(run_data, :batch_propagation?)

    %{
      execution_mode: execution_mode(task_supervisor, task_supervisors, batch_propagation?),
      batch_propagation: batch_propagation?,
      task_supervisor_node: task_supervisor_node(task_supervisor),
      task_supervisor_nodes: task_supervisor_nodes(task_supervisors),
      phase_timings_ms: Keyword.fetch!(run_data, :phase_timings_ms),
      scenario_count: length(study.scenarios),
      trajectory_count: length(Keyword.fetch!(run_data, :trajectory_results)),
      event_result_count: length(Keyword.fetch!(run_data, :event_results)),
      failure_count: length(Keyword.fetch!(run_data, :errors)),
      scheduler_count: System.schedulers_online(),
      effective_task_concurrency: Keyword.fetch!(run_data, :effective_task_concurrency),
      elixir_version: System.version(),
      otp_release: List.to_string(:erlang.system_info(:otp_release)),
      system_architecture: List.to_string(:erlang.system_info(:system_architecture)),
      propagator_capabilities: propagator_capabilities(study.propagator),
      external_provider_policy: Keyword.fetch!(run_data, :external_provider_policy),
      backend_selection_policy: Keyword.fetch!(run_data, :backend_selection_policy),
      execution_plan: Keyword.fetch!(run_data, :execution_plan),
      manifest: Keyword.get(opts, :manifest),
      git_revision: Keyword.get_lazy(opts, :git_revision, &git_revision/0)
    }
    |> maybe_put_map(:retry, Keyword.fetch!(run_data, :retry_plan))
    |> maybe_put_map(:checkpoint, Keyword.fetch!(run_data, :checkpoint_provenance))
  end

  defp execution_plan(%Study{} = study, opts) do
    scenario_count = length(study.scenarios)
    max_concurrency = Keyword.fetch!(opts, :max_concurrency)
    requested_task_chunk_size = Keyword.fetch!(opts, :requested_task_chunk_size)
    task_supervisors = Keyword.fetch!(opts, :task_supervisors)
    batch_propagation? = Keyword.fetch!(opts, :batch_propagation?)
    retry_plan = Keyword.fetch!(opts, :retry_plan)
    checkpoint = Keyword.fetch!(opts, :checkpoint)
    supervisor_count = supervisor_count(Keyword.fetch!(opts, :task_supervisor), task_supervisors)
    effective_task_concurrency = effective_task_concurrency(max_concurrency, task_supervisors)

    chunking_recommendation =
      ScenarioRunner.task_chunking_recommendation(scenario_count,
        max_concurrency: max_concurrency,
        task_supervisors: task_supervisors,
        task_chunk_size: requested_task_chunk_size
      )

    resolved_task_chunk_size = chunking_recommendation.applied_task_chunk_size
    chunking_enabled? = is_list(task_supervisors) and resolved_task_chunk_size > 1

    effective_chunk_size =
      cond do
        batch_propagation? -> max(scenario_count, 1)
        chunking_enabled? -> resolved_task_chunk_size
        true -> 1
      end

    task_batch_count =
      cond do
        scenario_count == 0 -> 0
        batch_propagation? -> 1
        true -> ceil_div(scenario_count, effective_chunk_size)
      end

    batches_per_wave =
      cond do
        batch_propagation? -> 1
        is_list(task_supervisors) -> max_concurrency * supervisor_count
        true -> max_concurrency
      end

    %{
      scenario_count: scenario_count,
      distribution_mode:
        execution_mode(
          Keyword.fetch!(opts, :task_supervisor),
          task_supervisors,
          batch_propagation?
        ),
      batch_propagation: batch_propagation?,
      chunking_enabled: chunking_enabled?,
      requested_task_chunk_size: requested_task_chunk_size,
      resolved_task_chunk_size: resolved_task_chunk_size,
      effective_task_chunk_size: effective_chunk_size,
      adaptive_chunking: chunking_recommendation,
      task_batch_count: task_batch_count,
      max_concurrency: max_concurrency,
      supervisor_count: supervisor_count,
      effective_task_concurrency: effective_task_concurrency,
      batches_per_wave: batches_per_wave,
      wave_count:
        if(task_batch_count == 0, do: 0, else: ceil_div(task_batch_count, batches_per_wave)),
      resumability:
        cond do
          retry_plan -> "failed_scenario_retry"
          checkpoint -> "local_checkpoint_resume"
          true -> "not_resumable"
        end
    }
    |> maybe_put_map(:retry, retry_plan)
    |> maybe_put_map(:checkpoint, checkpoint_execution_config(checkpoint))
  end

  defp checkpoint_execution_config(nil), do: nil

  defp checkpoint_execution_config(checkpoint) do
    %{
      schema_contract: StudyCheckpoint.schema_contract(),
      checkpoint_mode: checkpoint[:mode] || checkpoint["mode"],
      checkpoint_path: checkpoint[:path] || checkpoint["path"]
    }
  end

  defp put_checkpoint_execution_provenance(execution_plan, nil), do: execution_plan

  defp put_checkpoint_execution_provenance(execution_plan, checkpoint_provenance) do
    Map.put(execution_plan, :checkpoint, checkpoint_provenance)
  end

  defp supervisor_count(_task_supervisor, task_supervisors) when is_list(task_supervisors),
    do: length(task_supervisors)

  defp supervisor_count(nil, _task_supervisors), do: 0
  defp supervisor_count(_task_supervisor, _task_supervisors), do: 1

  defp ceil_div(value, divisor), do: div(value + divisor - 1, divisor)

  defp backend_selection_policy(propagator, batch_propagation?) do
    capabilities = propagator_capabilities(propagator)
    backend = Map.get(capabilities, :backend, :custom)
    supports_batching? = Map.get(capabilities, :supports_batching, false)
    acceptance = backend_acceptance_evidence(propagator)

    %{
      selected_propagator: propagator,
      backend: backend,
      validation_level: Map.get(capabilities, :validation_level, :unknown),
      policy: Map.get(acceptance, "tier", backend_policy_label(backend, supports_batching?)),
      backend_acceptance_policy: Map.get(acceptance, "backend_acceptance_policy"),
      backend_acceptance_evidence: acceptance,
      requires_reference_match: Map.get(acceptance, "requires_reference_match"),
      requires_benchmark_artifact: Map.get(acceptance, "requires_benchmark_artifact"),
      reference_backend: Map.get(acceptance, "reference_backend", false),
      selection_source: "study_manifest_or_study_struct",
      batch_propagation_selected: batch_propagation?,
      batch_selection_reason: batch_selection_reason(supports_batching?, batch_propagation?),
      performance_claim:
        "backend selection is explicit; benchmark artifacts are required before claiming speedups"
    }
  end

  defp backend_policy_label(:scalar_elixir, _supports_batching?), do: "reference_default"
  defp backend_policy_label(:nx, true), do: "experimental_accelerator"
  defp backend_policy_label(:nx_compiled, true), do: "experimental_accelerator"
  defp backend_policy_label(:exla_cpu, true), do: "experimental_accelerator"
  defp backend_policy_label(_backend, true), do: "custom_batch_backend"
  defp backend_policy_label(_backend, _supports_batching?), do: "custom_scalar_backend"

  defp backend_acceptance_evidence(propagator) do
    case OrbitalDynamics.Validation.backend_acceptance_evidence(propagator) do
      {:ok, evidence} ->
        evidence

      {:error, {_reason, implementation}} ->
        %{"implementation" => implementation, "tier" => "custom"}
    end
  end

  defp batch_selection_reason(true, true),
    do: "propagator_supports_batching_and_no_explicit_task_distribution"

  defp batch_selection_reason(true, false),
    do: "batch_backend_available_but_explicit_task_distribution_or_options_used"

  defp batch_selection_reason(false, false), do: "propagator_does_not_support_batching"
  defp batch_selection_reason(false, true), do: "batch_selected_without_declared_capability"

  defp checkpoint_identity_inputs(%Study{} = study, opts, run_data) do
    %{
      manifest: Keyword.get(opts, :manifest),
      model: %{
        propagator: study.propagator,
        propagator_opts: study.propagator_opts,
        implementation_sha256: module_implementation_sha256(study.propagator)
      },
      run_options: %{
        central_body: Keyword.fetch!(run_data, :central_body),
        ground_stations: Keyword.fetch!(run_data, :ground_stations),
        targets: Keyword.fetch!(run_data, :targets),
        ground_track_crossings: Keyword.fetch!(run_data, :ground_track_crossings),
        sun_direction: Keyword.fetch!(run_data, :sun_direction),
        campaign_environment: Keyword.fetch!(run_data, :campaign_environment),
        external_providers: Keyword.get(opts, :external_providers, []),
        max_concurrency: Keyword.fetch!(run_data, :max_concurrency),
        timeout: Keyword.fetch!(run_data, :timeout),
        requested_task_chunk_size: Keyword.fetch!(run_data, :requested_task_chunk_size),
        resolved_task_chunk_size: Keyword.fetch!(run_data, :resolved_task_chunk_size),
        task_supervisor: Keyword.fetch!(run_data, :task_supervisor),
        task_supervisor_explicit: Keyword.has_key?(opts, :task_supervisor),
        batch_propagation: Keyword.fetch!(run_data, :batch_propagation?),
        batch_propagation_preference: Keyword.get(opts, :batch_propagation, :auto),
        run_id: Keyword.get(opts, :run_id),
        git_revision: Keyword.get_lazy(opts, :git_revision, &git_revision/0),
        elixir_version: System.version(),
        otp_release: List.to_string(:erlang.system_info(:otp_release)),
        system_architecture: List.to_string(:erlang.system_info(:system_architecture))
      }
    }
  end

  defp module_implementation_sha256(module) do
    case :code.get_object_code(module) do
      {^module, object_code, _path} ->
        :crypto.hash(:sha256, object_code)
        |> Base.encode16(case: :lower)

      :error ->
        nil
    end
  end

  defp external_provider_policy(opts) do
    providers = Keyword.get(opts, :external_providers, [])
    provider_rows = Enum.map(List.wrap(providers), &external_provider_row/1)

    %{
      network_access: if(provider_rows == [], do: "none", else: "explicitly_configured"),
      hidden_network_calls: false,
      external_provider_count: length(provider_rows),
      external_providers: provider_rows,
      rule:
        "planning runs must not call external services unless an external provider is explicitly configured"
    }
  end

  defp external_provider_row(%{} = provider), do: provider

  defp external_provider_row(provider) when is_atom(provider),
    do: %{"id" => Atom.to_string(provider)}

  defp external_provider_row(provider), do: %{"id" => provider}

  defp execution_mode(_task_supervisor, _supervisors, true), do: :local_batch

  defp execution_mode(_task_supervisor, supervisors, false) when is_list(supervisors) do
    if Enum.any?(supervisors, &remote_supervisor?/1) do
      :distributed_task_supervisors
    else
      :local_tasks
    end
  end

  defp execution_mode({supervisor, remote_node}, nil, false)
       when is_atom(supervisor) and is_atom(remote_node) do
    if remote_node == node(), do: :local_tasks, else: :remote_task_supervisor
  end

  defp execution_mode(_task_supervisor, nil, false), do: :local_tasks

  defp remote_supervisor?({_supervisor, supervisor_node}), do: supervisor_node != node()
  defp remote_supervisor?(_supervisor), do: false

  defp task_supervisor_node({_supervisor, supervisor_node}), do: supervisor_node
  defp task_supervisor_node(_task_supervisor), do: node()

  defp task_supervisor_nodes(nil), do: nil
  defp task_supervisor_nodes(supervisors), do: Enum.map(supervisors, &task_supervisor_node/1)

  defp effective_task_concurrency(max_concurrency, supervisors)
       when is_integer(max_concurrency) and is_list(supervisors) do
    max_concurrency * length(supervisors)
  end

  defp effective_task_concurrency(max_concurrency, _supervisors), do: max_concurrency

  defp propagator_capabilities(propagator) do
    if function_exported?(propagator, :capabilities, 0) do
      propagator.capabilities()
    else
      %{}
    end
  end

  defp default_run_id(study, run_data) do
    "#{study.id}-#{DateTime.to_unix(Keyword.fetch!(run_data, :started_at), :microsecond)}"
  end

  defp elapsed_ms(started_monotonic) do
    (System.monotonic_time() - started_monotonic)
    |> System.convert_time_unit(:native, :millisecond)
  end

  defp timed(fun) when is_function(fun, 0) do
    started_monotonic = System.monotonic_time()
    value = fun.()
    {value, elapsed_ms(started_monotonic)}
  end

  defp git_revision do
    case System.cmd("git", ["rev-parse", "--short", "HEAD"], stderr_to_stdout: true) do
      {revision, 0} -> String.trim(revision)
      {_output, _status} -> nil
    end
  rescue
    _error -> nil
  end

  defp default_task_supervisor do
    if Process.whereis(OrbitalDynamics.ScenarioSupervisor) do
      OrbitalDynamics.ScenarioSupervisor
    end
  end

  defp maybe_put(keyword, _key, nil), do: keyword
  defp maybe_put(keyword, key, value), do: Keyword.put(keyword, key, value)

  defp maybe_put_map(map, _key, nil), do: map
  defp maybe_put_map(map, key, value), do: Map.put(map, key, value)
end
