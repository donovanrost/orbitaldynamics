defmodule OrbitalDynamics.ScenarioRunner do
  @moduledoc """
  Concurrent scenario execution using BEAM tasks.

  Results preserve input ordering even though scenarios are evaluated in
  parallel. By default the runner uses the application `Task.Supervisor` when it
  is available; callers may also pass a supervisor name or `{name, node}` tuple
  to move the task boundary onto a connected BEAM node. For distributed batches,
  callers may pass multiple supervisors with `:task_supervisors`; work is spread
  round-robin while the returned results preserve input order. Distributed work
  can be chunked so one remote task evaluates multiple scenarios.
  """

  alias OrbitalDynamics.Propagators.TwoBody

  defmodule Result do
    @moduledoc """
    Outcome from one scenario evaluation.
    """

    @enforce_keys [:scenario_id, :status, :node]
    defstruct [:scenario_id, :scenario_index, :status, :value, :error, :node]

    @type t :: %__MODULE__{
            scenario_id: term(),
            scenario_index: non_neg_integer() | nil,
            status: :ok | :error,
            value: term(),
            error: term(),
            node: node()
          }
  end

  @doc """
  Runs scenarios concurrently.

  Options:

    * `:propagator` - module or function, default `OrbitalDynamics.Propagators.TwoBody`
    * `:max_concurrency` - default `System.schedulers_online()`
    * `:timeout` - task timeout in milliseconds, default `:infinity`
    * `:task_supervisor` - local or remote task supervisor, default app supervisor when running
    * `:task_supervisors` - local and/or remote task supervisors for round-robin distribution
    * `:task_chunk_size` - scenarios per distributed task, default `1`
    * `:propagator_opts` - options forwarded to module propagators
    * `:scenario_indexes` - optional source-manifest indexes for a selected retry batch
  """
  def run(scenarios, opts \\ []) when is_list(scenarios) do
    propagator = Keyword.get(opts, :propagator, TwoBody)
    max_concurrency = Keyword.get(opts, :max_concurrency, System.schedulers_online())
    timeout = Keyword.get(opts, :timeout, :infinity)
    task_supervisor = Keyword.get(opts, :task_supervisor, default_task_supervisor())
    task_supervisors = Keyword.get(opts, :task_supervisors)
    requested_task_chunk_size = Keyword.get(opts, :task_chunk_size, 1)
    propagator_opts = Keyword.get(opts, :propagator_opts, [])
    indexed_scenarios = indexed_scenarios(scenarios, Keyword.get(opts, :scenario_indexes))

    validate_max_concurrency!(max_concurrency)

    task_chunk_size =
      resolve_task_chunk_size(scenarios,
        max_concurrency: max_concurrency,
        task_supervisors: task_supervisors,
        task_chunk_size: requested_task_chunk_size
      )

    validate_task_chunk_size!(task_chunk_size)

    if is_list(task_supervisors) and task_supervisors != [] do
      run_with_task_supervisors(
        indexed_scenarios,
        task_supervisors,
        propagator,
        propagator_opts,
        max_concurrency,
        timeout,
        task_chunk_size
      )
    else
      indexed_scenarios
      |> async_stream(
        task_supervisor,
        fn {scenario, index} -> {index, evaluate(scenario, propagator, propagator_opts)} end,
        max_concurrency: max_concurrency,
        ordered: true,
        timeout: timeout,
        on_timeout: :kill_task
      )
      |> Enum.zip(indexed_scenarios)
      |> Enum.map(fn
        {{:ok, {index, %Result{} = result}}, _indexed_scenario} ->
          put_result_index(result, index)

        {{:exit, reason}, {scenario, index}} ->
          %Result{
            scenario_id: Map.get(scenario, :id),
            scenario_index: index,
            status: :error,
            error: {:task_exit, reason},
            node: node()
          }
      end)
    end
  end

  @doc """
  Resolves the task chunk size that should be applied for a scenario run.

  Integer chunk sizes are preserved. `:auto` is a deterministic V1 adaptive
  policy for task-supervisor distribution: it targets roughly two waves of
  distributed task batches and falls back to `1` when chunking is not applicable.
  """
  def resolve_task_chunk_size(scenarios_or_count, opts \\ []) do
    scenarios_or_count
    |> task_chunking_recommendation(opts)
    |> Map.fetch!(:applied_task_chunk_size)
  end

  @doc """
  Returns deterministic task chunking guidance for execution reports.
  """
  def task_chunking_recommendation(scenarios_or_count, opts \\ []) do
    scenario_count = scenario_count(scenarios_or_count)
    max_concurrency = Keyword.get(opts, :max_concurrency, System.schedulers_online())
    task_supervisors = Keyword.get(opts, :task_supervisors)
    requested_task_chunk_size = Keyword.get(opts, :task_chunk_size, 1)

    validate_max_concurrency!(max_concurrency)

    supervisor_count =
      if is_list(task_supervisors) and task_supervisors != [] do
        length(task_supervisors)
      else
        0
      end

    concurrent_task_batches =
      if supervisor_count > 0 do
        max_concurrency * supervisor_count
      else
        max_concurrency
      end

    case requested_task_chunk_size do
      :auto ->
        auto_task_chunking_recommendation(
          scenario_count,
          supervisor_count,
          concurrent_task_batches
        )

      task_chunk_size when is_integer(task_chunk_size) and task_chunk_size > 0 ->
        %{
          policy: :explicit,
          requested_task_chunk_size: task_chunk_size,
          recommended_task_chunk_size: task_chunk_size,
          applied_task_chunk_size: task_chunk_size,
          supervisor_count: supervisor_count,
          concurrent_task_batches: concurrent_task_batches,
          target_wave_count: nil,
          reason: "operator_supplied_task_chunk_size"
        }

      _other ->
        raise ArgumentError, "task_chunk_size must be a positive integer or :auto"
    end
  end

  defp async_stream(scenarios, nil, fun, opts), do: Task.async_stream(scenarios, fun, opts)

  defp async_stream(scenarios, task_supervisor, fun, opts) do
    Task.Supervisor.async_stream_nolink(task_supervisor, scenarios, fun, opts)
  end

  defp run_with_task_supervisors(
         indexed_scenarios,
         task_supervisors,
         propagator,
         propagator_opts,
         max_concurrency,
         timeout,
         task_chunk_size
       ) do
    indexed_scenarios
    |> Enum.chunk_every(task_chunk_size)
    |> Enum.with_index()
    |> Enum.chunk_every(max_concurrency * length(task_supervisors))
    |> Enum.flat_map(fn task_chunks ->
      task_chunks
      |> Enum.map(fn {indexed_scenarios, chunk_index} ->
        supervisor = Enum.at(task_supervisors, rem(chunk_index, length(task_supervisors)))

        task =
          Task.Supervisor.async_nolink(supervisor, fn ->
            Enum.map(indexed_scenarios, fn {scenario, index} ->
              {index,
               scenario |> evaluate(propagator, propagator_opts) |> put_result_index(index)}
            end)
          end)

        {indexed_scenarios, task}
      end)
      |> await_distributed_chunk(timeout)
    end)
    |> Enum.sort_by(fn {index, _result} -> index end)
    |> Enum.map(fn {_index, result} -> result end)
  end

  defp await_distributed_chunk(indexed_tasks, timeout) do
    tasks = Enum.map(indexed_tasks, fn {_indexed_scenarios, task} -> task end)

    task_metadata =
      Map.new(indexed_tasks, fn {indexed_scenarios, task} ->
        {task.ref, indexed_scenarios}
      end)

    tasks
    |> Task.yield_many(timeout)
    |> Enum.flat_map(fn
      {%Task{ref: _ref}, {:ok, results}} when is_list(results) ->
        results

      {%Task{ref: ref}, {:exit, reason}} ->
        ref
        |> Map.fetch!(task_metadata)
        |> Enum.map(fn {scenario, index} ->
          {index,
           %Result{
             scenario_id: Map.get(scenario, :id),
             scenario_index: index,
             status: :error,
             error: {:task_exit, reason},
             node: node()
           }}
        end)

      {%Task{ref: ref} = task, nil} ->
        indexed_scenarios = Map.fetch!(task_metadata, ref)
        Task.shutdown(task, :brutal_kill)

        Enum.map(indexed_scenarios, fn {scenario, index} ->
          {index,
           %Result{
             scenario_id: Map.get(scenario, :id),
             scenario_index: index,
             status: :error,
             error: {:task_timeout, timeout},
             node: node()
           }}
        end)
    end)
  end

  defp validate_max_concurrency!(max_concurrency)
       when is_integer(max_concurrency) and max_concurrency > 0,
       do: :ok

  defp validate_max_concurrency!(_max_concurrency) do
    raise ArgumentError, "max_concurrency must be a positive integer"
  end

  defp validate_task_chunk_size!(task_chunk_size)
       when is_integer(task_chunk_size) and task_chunk_size > 0,
       do: :ok

  defp validate_task_chunk_size!(_task_chunk_size) do
    raise ArgumentError, "task_chunk_size must be a positive integer or :auto"
  end

  defp indexed_scenarios(scenarios, nil), do: Enum.with_index(scenarios)

  defp indexed_scenarios(scenarios, scenario_indexes) when is_list(scenario_indexes) do
    valid_indexes? =
      length(scenarios) == length(scenario_indexes) and
        Enum.all?(scenario_indexes, &(is_integer(&1) and &1 >= 0)) and
        Enum.uniq(scenario_indexes) == scenario_indexes and
        Enum.sort(scenario_indexes) == scenario_indexes

    if valid_indexes? do
      Enum.zip(scenarios, scenario_indexes)
    else
      raise ArgumentError,
            "scenario_indexes must contain one unique ascending non-negative integer per scenario"
    end
  end

  defp indexed_scenarios(_scenarios, _scenario_indexes) do
    raise ArgumentError,
          "scenario_indexes must contain one unique ascending non-negative integer per scenario"
  end

  defp scenario_count(scenarios) when is_list(scenarios), do: length(scenarios)
  defp scenario_count(count) when is_integer(count) and count >= 0, do: count

  defp scenario_count(_scenarios_or_count) do
    raise ArgumentError, "scenarios_or_count must be a list or non-negative integer"
  end

  defp auto_task_chunking_recommendation(
         scenario_count,
         supervisor_count,
         concurrent_task_batches
       )
       when supervisor_count > 0 do
    target_wave_count = 2

    recommended_task_chunk_size =
      if scenario_count == 0 do
        1
      else
        ceil_div(scenario_count, concurrent_task_batches * target_wave_count)
      end

    %{
      policy: :auto,
      requested_task_chunk_size: :auto,
      recommended_task_chunk_size: recommended_task_chunk_size,
      applied_task_chunk_size: recommended_task_chunk_size,
      supervisor_count: supervisor_count,
      concurrent_task_batches: concurrent_task_batches,
      target_wave_count: target_wave_count,
      reason: "target_two_distributed_task_waves"
    }
  end

  defp auto_task_chunking_recommendation(
         _scenario_count,
         supervisor_count,
         concurrent_task_batches
       ) do
    %{
      policy: :not_applicable,
      requested_task_chunk_size: :auto,
      recommended_task_chunk_size: 1,
      applied_task_chunk_size: 1,
      supervisor_count: supervisor_count,
      concurrent_task_batches: concurrent_task_batches,
      target_wave_count: nil,
      reason: "task_chunking_requires_task_supervisors"
    }
  end

  defp ceil_div(value, divisor), do: div(value + divisor - 1, divisor)

  defp default_task_supervisor do
    if Process.whereis(OrbitalDynamics.ScenarioSupervisor) do
      OrbitalDynamics.ScenarioSupervisor
    end
  end

  defp evaluate(scenario, propagator, propagator_opts) do
    scenario_id = Map.get(scenario, :id)

    try do
      case call_propagator(propagator, scenario, propagator_opts) do
        {:ok, value} ->
          %Result{scenario_id: scenario_id, status: :ok, value: value, node: node()}

        {:error, reason} ->
          %Result{scenario_id: scenario_id, status: :error, error: reason, node: node()}

        value ->
          %Result{scenario_id: scenario_id, status: :ok, value: value, node: node()}
      end
    rescue
      exception ->
        %Result{
          scenario_id: scenario_id,
          status: :error,
          error: {exception.__struct__, Exception.message(exception)},
          node: node()
        }
    end
  end

  defp put_result_index(%Result{} = result, index), do: %{result | scenario_index: index}

  defp call_propagator(propagator, scenario, opts) when is_atom(propagator) do
    propagator.propagate(scenario, opts)
  end

  defp call_propagator(propagator, scenario, _opts) when is_function(propagator, 1) do
    propagator.(scenario)
  end

  defp call_propagator(propagator, scenario, opts) when is_function(propagator, 2) do
    propagator.(scenario, opts)
  end
end
