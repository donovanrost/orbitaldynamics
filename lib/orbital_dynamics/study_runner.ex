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

  alias OrbitalDynamics.{
    CentralBody,
    Environment,
    GroundStation,
    ResultSet,
    ScenarioRunner,
    Study,
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
    ground_track_crossings = Keyword.get(opts, :ground_track_crossings, [])
    sun_direction = Keyword.get(opts, :sun_direction, {1.0, 0.0, 0.0})
    max_concurrency = Keyword.get(opts, :max_concurrency, System.schedulers_online())
    timeout = Keyword.get(opts, :timeout, :infinity)
    requested_task_chunk_size = Keyword.get(opts, :task_chunk_size, 1)
    task_supervisors = Keyword.get(opts, :task_supervisors)
    external_provider_policy = external_provider_policy(opts)

    explicit_task_distribution? =
      Keyword.has_key?(opts, :task_supervisor) or Keyword.has_key?(opts, :task_supervisors)

    task_supervisor =
      if is_nil(task_supervisors),
        do: Keyword.get(opts, :task_supervisor, default_task_supervisor())

    batch_propagation? = batch_propagation?(study.propagator, opts, explicit_task_distribution?)
    backend_selection_policy = backend_selection_policy(study.propagator, batch_propagation?)

    with :ok <- validate_run_inputs(study, opts),
         :ok <- validate_task_supervisor_config(task_supervisor, task_supervisors) do
      execution_plan =
        execution_plan(study,
          max_concurrency: max_concurrency,
          requested_task_chunk_size: requested_task_chunk_size,
          task_supervisor: task_supervisor,
          task_supervisors: task_supervisors,
          batch_propagation?: batch_propagation?
        )

      task_chunk_size = execution_plan.resolved_task_chunk_size

      {propagation_results, propagation_ms} =
        timed(fn ->
          propagate_scenarios(study,
            max_concurrency: max_concurrency,
            timeout: timeout,
            task_supervisor: task_supervisor,
            task_supervisors: task_supervisors,
            task_chunk_size: task_chunk_size,
            batch_propagation?: batch_propagation?
          )
        end)

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
            sun_direction
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
          ground_track_crossings,
          sun_direction,
          external_provider_policy,
          backend_selection_policy
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
             phase_timings_ms: %{
               propagation: propagation_ms,
               event_detection: event_detection_ms
             }
           )
       })}
    end
  end

  @doc """
  Validates study run inputs without propagating scenarios or checking task-supervisor reachability.
  """
  def validate_run_inputs(%Study{} = study, opts \\ []) do
    ground_stations = Keyword.get(opts, :ground_stations, [])
    targets = Keyword.get(opts, :targets, [])
    ground_track_crossings = Keyword.get(opts, :ground_track_crossings, [])

    with :ok <- validate_outputs(study.outputs),
         :ok <- validate_ground_stations(study.outputs, ground_stations),
         :ok <- validate_targets(study.outputs, targets),
         :ok <- validate_ground_track_crossings(study, ground_track_crossings) do
      :ok
    end
  end

  defp validate_outputs(outputs) do
    unsupported = outputs -- @supported_outputs
    if unsupported == [], do: :ok, else: {:error, {:unsupported_outputs, unsupported}}
  end

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

  defp validate_ground_track_crossings(%Study{outputs: outputs} = study, ground_track_crossings) do
    cond do
      :ground_track_crossings not in outputs ->
        :ok

      ground_track_crossings == [] ->
        {:error, {:missing_option, :ground_track_crossings}}

      not is_list(ground_track_crossings) or
          not Enum.all?(ground_track_crossings, &valid_ground_track_crossing?(&1, study)) ->
        {:error, {:invalid_option, :ground_track_crossings}}

      true ->
        :ok
    end
  end

  defp valid_ground_track_crossing?(%{crossing: :latitude, latitude_deg: value} = request, study)
       when is_number(value),
       do: valid_ground_track_rotation_opts?(request, study)

  defp valid_ground_track_crossing?(
         %{crossing: :longitude, longitude_deg: value} = request,
         study
       )
       when is_number(value),
       do: valid_ground_track_rotation_opts?(request, study)

  defp valid_ground_track_crossing?(_request, _study), do: false

  defp valid_ground_track_rotation_opts?(request, study) do
    numeric_opts? =
      [:rotation_rate_rad_s, :rotation_epoch_s, :rotation_angle_offset_rad]
      |> Enum.all?(fn key ->
        case Map.fetch(request, key) do
          {:ok, value} -> is_number(value)
          :error -> true
        end
      end)

    numeric_opts? and
      valid_earth_rotation_provider?(Map.get(request, :earth_rotation_provider), study)
  end

  defp valid_earth_rotation_provider?(nil, _study), do: true

  defp valid_earth_rotation_provider?(provider, study) when is_atom(provider) do
    valid_earth_rotation_provider?({provider, []}, study)
  end

  defp valid_earth_rotation_provider?({provider, provider_opts}, study)
       when is_atom(provider) and is_list(provider_opts) do
    Keyword.keyword?(provider_opts) and provider_fetchable?(provider) and
      Environment.configured_provider_supports_request?(
        provider,
        earth_rotation_provider_request(study),
        provider_opts
      )
  end

  defp valid_earth_rotation_provider?(_provider, _study), do: false

  defp provider_fetchable?(provider) do
    Code.ensure_loaded?(provider) and function_exported?(provider, :fetch, 2) and
      function_exported?(provider, :capabilities, 0)
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

  defp propagate_scenarios(%Study{} = study, opts) do
    if Keyword.fetch!(opts, :batch_propagation?) do
      propagate_batch(study)
    else
      ScenarioRunner.run(study.scenarios,
        propagator: study.propagator,
        propagator_opts: study.propagator_opts,
        max_concurrency: Keyword.fetch!(opts, :max_concurrency),
        timeout: Keyword.fetch!(opts, :timeout),
        task_supervisor: Keyword.fetch!(opts, :task_supervisor),
        task_supervisors: Keyword.fetch!(opts, :task_supervisors),
        task_chunk_size: Keyword.fetch!(opts, :task_chunk_size)
      )
    end
  end

  defp propagate_batch(%Study{} = study) do
    case study.propagator.propagate_many(study.scenarios, study.propagator_opts) do
      {:ok, trajectories} ->
        trajectories
        |> Enum.with_index()
        |> Enum.map(fn {trajectory, index} ->
          %ScenarioRunner.Result{
            scenario_id: trajectory.scenario_id,
            scenario_index: index,
            status: :ok,
            value: trajectory,
            node: node()
          }
        end)

      {:error, reason} ->
        study.scenarios
        |> Enum.with_index()
        |> Enum.map(fn {scenario, index} ->
          %ScenarioRunner.Result{
            scenario_id: scenario.id,
            scenario_index: index,
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
         sun_direction
       ) do
    []
    |> maybe_add_access_window_results(outputs, trajectory_results, ground_stations, central_body)
    |> maybe_add_eclipse_results(outputs, trajectory_results, central_body, sun_direction)
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
         sun_direction
       ) do
    if :eclipses in outputs do
      results ++ eclipse_results(trajectory_results, central_body, sun_direction)
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

  defp eclipse_results(trajectory_results, central_body, sun_direction) do
    Enum.map(trajectory_results, fn trajectory_result ->
      case Eclipses.detect(trajectory_result.trajectory,
             central_body: central_body,
             sun_direction: sun_direction
           ) do
        {:ok, events} ->
          {:ok,
           %{
             scenario_id: trajectory_result.scenario_id,
             event_type: :eclipse,
             events: events,
             source: %{shadow_model: :cylindrical_central_body_shadow}
           }}

        {:error, reason} ->
          {:error,
           %{
             scenario_id: trajectory_result.scenario_id,
             scenario_index: trajectory_result.scenario_index,
             stage: :eclipses,
             error: reason,
             source: %{shadow_model: :cylindrical_central_body_shadow}
           }}
      end
    end)
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
      :earth_rotation_provider
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
         external_provider_policy,
         backend_selection_policy
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
  end

  defp execution_plan(%Study{} = study, opts) do
    scenario_count = length(study.scenarios)
    max_concurrency = Keyword.fetch!(opts, :max_concurrency)
    requested_task_chunk_size = Keyword.fetch!(opts, :requested_task_chunk_size)
    task_supervisors = Keyword.fetch!(opts, :task_supervisors)
    batch_propagation? = Keyword.fetch!(opts, :batch_propagation?)
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
      resumability: "not_resumable"
    }
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
end
