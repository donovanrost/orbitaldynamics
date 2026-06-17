defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ObjectiveGap.Summary.Values do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ObjectiveGap.Summary.Helpers

  def values(satisfaction_summary, tradeoff_summary, score_term_summary) do
    satisfaction_gap_count = Helpers.summary_integer(satisfaction_summary, "gap_row_count")

    satisfaction_downlink_count =
      Helpers.summary_integer(satisfaction_summary, "downlink_gap_row_count")

    satisfaction_target_count =
      Helpers.summary_integer(satisfaction_summary, "target_gap_row_count")

    satisfaction_collection_count =
      Helpers.summary_integer(satisfaction_summary, "collection_latency_gap_row_count")

    tradeoff_downlink_count = Helpers.summary_integer(tradeoff_summary, "downlink_gap_row_count")
    tradeoff_target_count = Helpers.summary_integer(tradeoff_summary, "target_gap_row_count")

    tradeoff_collection_count =
      Helpers.summary_integer(tradeoff_summary, "collection_latency_gap_row_count")

    score_downlink_count = Helpers.summary_integer(score_term_summary, "downlink_gap_row_count")
    score_target_count = Helpers.summary_integer(score_term_summary, "target_gap_row_count")

    score_collection_count =
      Helpers.summary_integer(score_term_summary, "collection_latency_gap_row_count")

    downlink_gap_count =
      satisfaction_downlink_count + tradeoff_downlink_count + score_downlink_count

    target_gap_count = satisfaction_target_count + tradeoff_target_count + score_target_count

    collection_latency_gap_count =
      satisfaction_collection_count + tradeoff_collection_count + score_collection_count

    routed_gap_signal_count =
      satisfaction_gap_count + tradeoff_downlink_count + tradeoff_target_count +
        tradeoff_collection_count + score_downlink_count + score_target_count +
        score_collection_count

    status_counts = Map.get(satisfaction_summary, "status_counts", %{})
    objective_type_counts = Map.get(satisfaction_summary, "objective_type_counts", %{})
    term_key_counts = Map.get(score_term_summary, "term_key_counts", %{})

    ground_station_counts =
      merged_counts(
        "ground_station_counts",
        summaries(satisfaction_summary, tradeoff_summary, score_term_summary)
      )

    target_counts =
      merged_counts(
        "target_counts",
        summaries(satisfaction_summary, tradeoff_summary, score_term_summary)
      )

    collection_counts =
      merged_counts(
        "collection_counts",
        summaries(satisfaction_summary, tradeoff_summary, score_term_summary)
      )

    source_activity_id_counts =
      merged_counts(
        "source_activity_id_counts",
        summaries(satisfaction_summary, tradeoff_summary, score_term_summary)
      )

    objective_status_pressure =
      map_size(status_counts) > 0 or map_size(objective_type_counts) > 0

    score_term_pressure = map_size(term_key_counts) > 0

    routing_pressure =
      map_size(ground_station_counts) > 0 or map_size(target_counts) > 0 or
        map_size(collection_counts) > 0 or map_size(source_activity_id_counts) > 0

    %{
      contracts: contracts(satisfaction_summary, tradeoff_summary, score_term_summary),
      source_report_count:
        summary_total("count", satisfaction_summary, tradeoff_summary, score_term_summary),
      source_report_row_count:
        summary_total("row_count", satisfaction_summary, tradeoff_summary, score_term_summary),
      source_report_paths:
        source_report_paths(satisfaction_summary, tradeoff_summary, score_term_summary),
      routed_gap_signal_count: routed_gap_signal_count,
      downlink_gap_count: downlink_gap_count,
      target_gap_count: target_gap_count,
      collection_latency_gap_count: collection_latency_gap_count,
      satisfaction_gap_count: satisfaction_gap_count,
      status_counts: status_counts,
      objective_type_counts: objective_type_counts,
      tradeoff_downlink_count: tradeoff_downlink_count,
      tradeoff_target_count: tradeoff_target_count,
      tradeoff_collection_count: tradeoff_collection_count,
      score_downlink_count: score_downlink_count,
      score_target_count: score_target_count,
      score_collection_count: score_collection_count,
      term_key_counts: term_key_counts,
      ground_station_counts: ground_station_counts,
      target_counts: target_counts,
      collection_counts: collection_counts,
      source_activity_id_counts: source_activity_id_counts,
      trust_boundary_status_counts:
        trust_boundary_status_counts(satisfaction_summary, tradeoff_summary, score_term_summary),
      trust_boundaries:
        trust_boundaries(satisfaction_summary, tradeoff_summary, score_term_summary),
      branch_local_objective_gap_pressure:
        routed_gap_signal_count > 0 or objective_status_pressure or score_term_pressure or
          routing_pressure,
      branch_local_downlink_gap_pressure: downlink_gap_count > 0,
      branch_local_target_gap_pressure: target_gap_count > 0,
      branch_local_collection_latency_gap_pressure: collection_latency_gap_count > 0,
      objective_status_pressure: objective_status_pressure,
      score_term_pressure: score_term_pressure,
      routing_pressure: routing_pressure
    }
  end

  defp summaries(satisfaction_summary, tradeoff_summary, score_term_summary) do
    [satisfaction_summary, tradeoff_summary, score_term_summary]
  end

  defp merged_counts(field, summaries) do
    summaries
    |> Enum.map(&Map.get(&1, field))
    |> Helpers.merge_count_maps()
    |> then(&(&1 || %{}))
  end

  defp summary_total(field, satisfaction_summary, tradeoff_summary, score_term_summary) do
    Helpers.summary_integer(satisfaction_summary, field) +
      Helpers.summary_integer(tradeoff_summary, field) +
      Helpers.summary_integer(score_term_summary, field)
  end

  defp source_report_paths(satisfaction_summary, tradeoff_summary, score_term_summary) do
    [satisfaction_summary, tradeoff_summary, score_term_summary]
    |> Enum.flat_map(&(Map.get(&1, "paths") || []))
    |> Helpers.sorted_string_values()
  end

  defp contracts(satisfaction_summary, tradeoff_summary, score_term_summary) do
    [
      Helpers.source_report_summary_contract(
        satisfaction_summary,
        "objective_satisfaction_report.v1"
      ),
      Helpers.source_report_summary_contract(tradeoff_summary, "objective_tradeoff_report.v1"),
      Helpers.source_report_summary_contract(score_term_summary, "score_term_report.v1")
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp trust_boundary_status_counts(satisfaction_summary, tradeoff_summary, score_term_summary) do
    [satisfaction_summary, tradeoff_summary, score_term_summary]
    |> Enum.map(&Map.get(&1, "trust_boundary_status"))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.reduce(%{}, fn status, counts -> Map.update(counts, status, 1, &(&1 + 1)) end)
    |> Helpers.non_empty_map()
  end

  defp trust_boundaries(satisfaction_summary, tradeoff_summary, score_term_summary) do
    [satisfaction_summary, tradeoff_summary, score_term_summary]
    |> Enum.flat_map(&(Map.get(&1, "trust_boundaries") || []))
    |> Helpers.normalize_trust_boundaries()
  end
end
