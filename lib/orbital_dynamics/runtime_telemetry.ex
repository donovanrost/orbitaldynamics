defmodule OrbitalDynamics.RuntimeTelemetry do
  @moduledoc """
  Lightweight BEAM runtime snapshots for benchmark diagnostics.
  """

  @doc """
  Captures runtime counters on every reachable node.
  """
  def snapshot(nodes \\ [node()]) when is_list(nodes) do
    nodes
    |> Enum.uniq()
    |> Map.new(fn telemetry_node ->
      {telemetry_node, node_snapshot(telemetry_node)}
    end)
  end

  @doc """
  Builds per-node runtime deltas between two snapshots.
  """
  def diff(before_snapshot, after_snapshot)
      when is_map(before_snapshot) and is_map(after_snapshot) do
    after_snapshot
    |> Map.new(fn {telemetry_node, after_node_snapshot} ->
      before_node_snapshot = Map.get(before_snapshot, telemetry_node, %{})

      {telemetry_node, diff_node(before_node_snapshot, after_node_snapshot)}
    end)
  end

  defp node_snapshot(telemetry_node) when telemetry_node == node() do
    local_snapshot()
  end

  defp node_snapshot(telemetry_node) do
    case :rpc.call(telemetry_node, __MODULE__, :local_snapshot, []) do
      {:badrpc, reason} ->
        %{available: false, error: inspect(reason)}

      snapshot ->
        snapshot
    end
  end

  @doc false
  def local_snapshot do
    enable_scheduler_wall_time()

    memory = :erlang.memory()

    %{
      available: true,
      node: node(),
      monotonic_time_ms: System.monotonic_time(:millisecond),
      process_count: :erlang.system_info(:process_count),
      run_queue: :erlang.statistics(:run_queue),
      reductions: reductions_total(),
      memory_total_bytes: Keyword.fetch!(memory, :total),
      scheduler_wall_time: scheduler_wall_time()
    }
  end

  defp enable_scheduler_wall_time do
    :erlang.system_flag(:scheduler_wall_time, true)
    :ok
  rescue
    _error -> :ok
  end

  defp reductions_total do
    :erlang.statistics(:reductions)
    |> elem(0)
  end

  defp scheduler_wall_time do
    :erlang.statistics(:scheduler_wall_time)
  rescue
    _error -> :unavailable
  end

  defp diff_node(%{available: true} = before_snapshot, %{available: true} = after_snapshot) do
    scheduler_delta =
      scheduler_wall_time_delta(
        Map.get(before_snapshot, :scheduler_wall_time),
        Map.get(after_snapshot, :scheduler_wall_time)
      )

    %{
      available: true,
      elapsed_ms:
        delta(
          Map.get(before_snapshot, :monotonic_time_ms),
          Map.get(after_snapshot, :monotonic_time_ms)
        ),
      process_count_before: Map.get(before_snapshot, :process_count),
      process_count_after: Map.get(after_snapshot, :process_count),
      run_queue_before: Map.get(before_snapshot, :run_queue),
      run_queue_after: Map.get(after_snapshot, :run_queue),
      reductions_delta:
        delta(Map.get(before_snapshot, :reductions), Map.get(after_snapshot, :reductions)),
      memory_total_bytes_before: Map.get(before_snapshot, :memory_total_bytes),
      memory_total_bytes_after: Map.get(after_snapshot, :memory_total_bytes),
      scheduler_wall_time_active_ms: scheduler_delta.active_ms,
      scheduler_wall_time_total_ms: scheduler_delta.total_ms,
      scheduler_utilization: scheduler_delta.utilization
    }
  end

  defp diff_node(_before_snapshot, after_snapshot) do
    %{
      available: false,
      error: Map.get(after_snapshot, :error, "unavailable")
    }
  end

  defp scheduler_wall_time_delta(before_wall_time, after_wall_time)
       when is_list(before_wall_time) and is_list(after_wall_time) do
    before_by_id = Map.new(before_wall_time, fn {id, active, total} -> {id, {active, total}} end)

    {active_native, total_native} =
      Enum.reduce(after_wall_time, {0, 0}, fn {id, active_after, total_after},
                                              {active_acc, total_acc} ->
        {active_before, total_before} = Map.get(before_by_id, id, {active_after, total_after})

        {
          active_acc + max(active_after - active_before, 0),
          total_acc + max(total_after - total_before, 0)
        }
      end)

    active_ms = System.convert_time_unit(active_native, :native, :millisecond)
    total_ms = System.convert_time_unit(total_native, :native, :millisecond)

    %{
      active_ms: active_ms,
      total_ms: total_ms,
      utilization: utilization(active_ms, total_ms)
    }
  end

  defp scheduler_wall_time_delta(_before_wall_time, _after_wall_time) do
    %{active_ms: nil, total_ms: nil, utilization: nil}
  end

  defp utilization(_active_ms, 0), do: nil

  defp utilization(active_ms, total_ms) when is_number(active_ms) and is_number(total_ms),
    do: active_ms / total_ms

  defp delta(before_value, after_value) when is_number(before_value) and is_number(after_value),
    do: after_value - before_value

  defp delta(_before_value, _after_value), do: nil
end
