defmodule OrbitalDynamics.CandidateRefresh.SourceWindowLineage do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common

  def build(candidates) do
    candidates
    |> Enum.map(fn candidate ->
      %{
        "schema_contract" => "source_window_lineage.v1",
        "candidate_activity_id" => candidate["id"],
        "source_window_id" => candidate["source_window_id"],
        "source_window_type" => get_in(candidate, ["source_window", "type"]),
        "scenario_id" => candidate["scenario_id"],
        "source_window" => source_window(candidate)
      }
      |> Map.merge(context(candidate))
      |> Common.compact_map()
    end)
    |> Enum.sort_by(&{&1["scenario_id"], &1["source_window_id"], &1["candidate_activity_id"]})
  end

  def context(candidate) do
    candidate
    |> Map.take([
      "target_id",
      "ground_station_id",
      "direction",
      "collection_id",
      "product_id",
      "product_ids",
      "payload_id",
      "instrument_id",
      "source_activity_id",
      "source_activity_ids",
      "missed_downlink_activity_id",
      "missed_downlink_activity_ids",
      "objective_id",
      "objective_type",
      "collection_latency_objective_count",
      "collection_latency_objective_ids",
      "collection_latency_objective_source",
      "collection_latency_objective_types",
      "latency_objective",
      "max_latency_s",
      "planned_latency_s",
      "required_downlink_mb",
      "candidate_downlink_mb",
      "downlink_completion_ratio",
      "selected_downlink_shortfall_mb",
      "downlink_requirement_status",
      "downlink_completion_source",
      "downlink_completion_sources",
      "downlink_completion_objective_count",
      "source_capacity_adjusted_throughput_mb",
      "source_selected_capacity_adjusted_throughput_mb",
      "source_unused_capacity_adjusted_throughput_mb",
      "feedback_source",
      "feedback_scope",
      "trust_boundary"
    ])
    |> Common.compact_map()
  end

  defp source_window(%{"source_window" => %{} = source_window} = candidate) do
    source_window
    |> Map.merge(%{
      "id" => candidate["source_window_id"],
      "type" => Map.get(source_window, "type"),
      "scenario_id" => candidate["scenario_id"],
      "target_id" => candidate["target_id"],
      "ground_station_id" => candidate["ground_station_id"],
      "starts_at_s" => candidate["starts_at_s"],
      "ends_at_s" => candidate["ends_at_s"],
      "duration_s" => candidate["duration_s"]
    })
    |> Map.merge(context(candidate))
    |> Common.compact_map()
  end

  defp source_window(_candidate), do: nil
end
