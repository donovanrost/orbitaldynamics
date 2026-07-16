defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ObjectiveGap.Summary.Values.GapCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ObjectiveGap.Summary.Helpers

  def counts(satisfaction_summary, tradeoff_summary, score_term_summary) do
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

    %{
      routed_gap_signal_count: routed_gap_signal_count,
      downlink_gap_count: downlink_gap_count,
      target_gap_count: target_gap_count,
      collection_latency_gap_count: collection_latency_gap_count,
      satisfaction_gap_count: satisfaction_gap_count,
      tradeoff_downlink_count: tradeoff_downlink_count,
      tradeoff_target_count: tradeoff_target_count,
      tradeoff_collection_count: tradeoff_collection_count,
      score_downlink_count: score_downlink_count,
      score_target_count: score_target_count,
      score_collection_count: score_collection_count
    }
  end
end
