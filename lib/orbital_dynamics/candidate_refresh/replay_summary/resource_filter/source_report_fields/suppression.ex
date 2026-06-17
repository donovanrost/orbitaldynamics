defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ResourceFilter.SourceReportFields.Suppression do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.ResourceFilter.SourceReportFields.Aggregation

  def fields(source_reports) do
    %{
      "source_report_resource_filter_suppressed_candidate_count" =>
        source_report_family_count(source_reports, "suppressed_candidate_count"),
      "source_report_resource_filter_invalid_resource_summary_input_count" =>
        source_report_family_count(source_reports, "invalid_resource_summary_input_count"),
      "source_report_resource_filter_invalid_resource_summary_input_ids" =>
        source_report_family_merge_string_lists(
          source_reports,
          "invalid_resource_summary_input_ids"
        ),
      "source_report_resource_filter_suppressed_reason_counts" =>
        source_report_family_merge_count_maps(source_reports, "suppressed_reason_counts"),
      "source_report_resource_filter_candidate_ids_by_suppressed_reason" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "candidate_ids_by_suppressed_reason"
        )
    }
  end
end
