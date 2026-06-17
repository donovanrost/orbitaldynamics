defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ObjectiveGap.SourceReportFields.Flattened do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ObjectiveGap.SourceReportFields.{
    ObjectiveSatisfaction,
    ObjectiveTradeoff,
    ScoreTerm
  }

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.ObjectiveGap.SourceReportFields.Aggregation

  def fields(source_reports) do
    %{
      "source_report_objective_gap_contracts" =>
        source_report_objective_gap_contracts(source_reports),
      "source_report_objective_gap_count" =>
        source_report_objective_gap_identity_count(source_reports, "count"),
      "source_report_objective_gap_row_count" =>
        source_report_objective_gap_identity_count(source_reports, "row_count"),
      "source_report_objective_gap_paths" =>
        source_report_objective_gap_identity_paths(source_reports),
      "source_report_objective_gap_routed_gap_signal_count" =>
        source_report_routed_gap_signal_count(source_reports),
      "source_report_objective_gap_downlink_gap_row_count" =>
        source_report_downlink_gap_row_count(source_reports),
      "source_report_objective_gap_target_gap_row_count" =>
        source_report_target_gap_row_count(source_reports),
      "source_report_objective_gap_collection_latency_gap_row_count" =>
        source_report_collection_latency_gap_row_count(source_reports),
      "source_report_objective_gap_ground_station_counts" =>
        source_report_objective_gap_merge_count_maps(source_reports, "ground_station_counts"),
      "source_report_objective_gap_target_counts" =>
        source_report_objective_gap_merge_count_maps(source_reports, "target_counts"),
      "source_report_objective_gap_collection_counts" =>
        source_report_objective_gap_merge_count_maps(source_reports, "collection_counts"),
      "source_report_objective_gap_source_activity_id_counts" =>
        source_report_objective_gap_merge_count_maps(source_reports, "source_activity_id_counts")
    }
    |> Map.merge(
      ObjectiveSatisfaction.source_report_objective_satisfaction_fields(source_reports)
    )
    |> Map.merge(ObjectiveTradeoff.source_report_objective_tradeoff_fields(source_reports))
    |> Map.merge(ScoreTerm.source_report_score_term_fields(source_reports))
  end

  defp source_report_routed_gap_signal_count(source_reports) do
    source_report_family_count_or_zero(
      source_reports,
      "objective_satisfaction_report",
      "gap_row_count"
    ) +
      source_report_family_count_or_zero(
        source_reports,
        "objective_tradeoff_report",
        "downlink_gap_row_count"
      ) +
      source_report_family_count_or_zero(
        source_reports,
        "objective_tradeoff_report",
        "target_gap_row_count"
      ) +
      source_report_family_count_or_zero(
        source_reports,
        "objective_tradeoff_report",
        "collection_latency_gap_row_count"
      ) +
      source_report_family_count_or_zero(
        source_reports,
        "score_term_report",
        "downlink_gap_row_count"
      ) +
      source_report_family_count_or_zero(
        source_reports,
        "score_term_report",
        "target_gap_row_count"
      ) +
      source_report_family_count_or_zero(
        source_reports,
        "score_term_report",
        "collection_latency_gap_row_count"
      )
  end

  defp source_report_downlink_gap_row_count(source_reports) do
    source_report_family_count_or_zero(
      source_reports,
      "objective_satisfaction_report",
      "downlink_gap_row_count"
    ) +
      source_report_family_count_or_zero(
        source_reports,
        "objective_tradeoff_report",
        "downlink_gap_row_count"
      ) +
      source_report_family_count_or_zero(
        source_reports,
        "score_term_report",
        "downlink_gap_row_count"
      )
  end

  defp source_report_target_gap_row_count(source_reports) do
    source_report_family_count_or_zero(
      source_reports,
      "objective_satisfaction_report",
      "target_gap_row_count"
    ) +
      source_report_family_count_or_zero(
        source_reports,
        "objective_tradeoff_report",
        "target_gap_row_count"
      ) +
      source_report_family_count_or_zero(
        source_reports,
        "score_term_report",
        "target_gap_row_count"
      )
  end

  defp source_report_collection_latency_gap_row_count(source_reports) do
    source_report_family_count_or_zero(
      source_reports,
      "objective_satisfaction_report",
      "collection_latency_gap_row_count"
    ) +
      source_report_family_count_or_zero(
        source_reports,
        "objective_tradeoff_report",
        "collection_latency_gap_row_count"
      ) +
      source_report_family_count_or_zero(
        source_reports,
        "score_term_report",
        "collection_latency_gap_row_count"
      )
  end
end
