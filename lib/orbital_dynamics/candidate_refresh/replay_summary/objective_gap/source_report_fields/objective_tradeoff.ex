defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ObjectiveGap.SourceReportFields.ObjectiveTradeoff do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.ObjectiveGap.SourceReportFields.Aggregation

  @family "objective_tradeoff_report"

  def source_report_objective_tradeoff_fields(source_reports) do
    %{
      "source_report_objective_tradeoff_downlink_gap_row_count" =>
        source_report_family_count(source_reports, @family, "downlink_gap_row_count"),
      "source_report_objective_tradeoff_target_gap_row_count" =>
        source_report_family_count(source_reports, @family, "target_gap_row_count"),
      "source_report_objective_tradeoff_collection_latency_gap_row_count" =>
        source_report_family_count(source_reports, @family, "collection_latency_gap_row_count"),
      "source_report_objective_tradeoff_ground_station_counts" =>
        source_report_family_merge_count_maps(source_reports, @family, "ground_station_counts"),
      "source_report_objective_tradeoff_target_counts" =>
        source_report_family_merge_count_maps(source_reports, @family, "target_counts"),
      "source_report_objective_tradeoff_collection_counts" =>
        source_report_family_merge_count_maps(source_reports, @family, "collection_counts"),
      "source_report_objective_tradeoff_source_activity_id_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          @family,
          "source_activity_id_counts"
        )
    }
  end
end
