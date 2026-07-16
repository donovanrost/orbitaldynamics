defmodule OrbitalDynamics.Schema.ResourceProjectionFlowSummaryLatencyContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionAggregation, only: [sorted_stable_values: 1]

  def status(_evidence_count, review_count) when review_count > 0, do: "review_required"

  def status(evidence_count, _review_count) when evidence_count > 0, do: "clear"

  def status(_evidence_count, _review_count), do: nil

  def evidence_count(flow_rows) do
    Enum.count(flow_rows, fn row ->
      Enum.any?(
        ~w(collection_ends_at_s planned_delivery_at_s actual_delivery_at_s max_latency_s planned_latency_s actual_latency_s),
        &Map.has_key?(row, &1)
      )
    end)
  end

  def review_activity_ids(flow_rows) do
    flow_rows
    |> Enum.filter(&(Map.get(&1, "latency_status") == "late"))
    |> Enum.map(&Map.get(&1, "activity_id"))
    |> sorted_stable_values()
  end
end
