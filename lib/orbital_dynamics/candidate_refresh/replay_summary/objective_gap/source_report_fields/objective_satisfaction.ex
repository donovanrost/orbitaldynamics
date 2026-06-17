defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ObjectiveGap.SourceReportFields.ObjectiveSatisfaction do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.ObjectiveGap.SourceReportFields.Aggregation

  @family "objective_satisfaction_report"

  def source_report_objective_satisfaction_fields(source_reports) do
    %{
      "source_report_objective_satisfaction_gap_row_count" =>
        source_report_family_count(source_reports, @family, "gap_row_count"),
      "source_report_objective_satisfaction_downlink_gap_row_count" =>
        source_report_family_count(source_reports, @family, "downlink_gap_row_count"),
      "source_report_objective_satisfaction_target_gap_row_count" =>
        source_report_family_count(source_reports, @family, "target_gap_row_count"),
      "source_report_objective_satisfaction_collection_latency_gap_row_count" =>
        source_report_family_count(source_reports, @family, "collection_latency_gap_row_count"),
      "source_report_objective_satisfaction_status_counts" =>
        source_report_family_merge_count_maps(source_reports, @family, "status_counts"),
      "source_report_objective_satisfaction_objective_type_counts" =>
        source_report_family_merge_count_maps(source_reports, @family, "objective_type_counts"),
      "source_report_objective_satisfaction_ground_station_counts" =>
        source_report_family_merge_count_maps(source_reports, @family, "ground_station_counts"),
      "source_report_objective_satisfaction_target_counts" =>
        source_report_family_merge_count_maps(source_reports, @family, "target_counts"),
      "source_report_objective_satisfaction_collection_counts" =>
        source_report_family_merge_count_maps(source_reports, @family, "collection_counts"),
      "source_report_objective_satisfaction_source_activity_id_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          @family,
          "source_activity_id_counts"
        )
    }
  end
end
