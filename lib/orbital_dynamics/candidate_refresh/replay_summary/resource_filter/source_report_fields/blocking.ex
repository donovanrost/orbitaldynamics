defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ResourceFilter.SourceReportFields.Blocking do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.ResourceFilter.SourceReportFields.Aggregation

  def fields(source_reports) do
    %{
      "source_report_resource_filter_spacecraft_counts" =>
        source_report_family_merge_count_maps(source_reports, "resource_filter_spacecraft_counts"),
      "source_report_resource_filter_candidate_ids_by_spacecraft" =>
        source_report_family_merge_string_list_maps(source_reports, "candidate_ids_by_spacecraft"),
      "source_report_resource_filter_resource_counts" =>
        source_report_family_merge_count_maps(source_reports, "resource_filter_resource_counts"),
      "source_report_resource_filter_candidate_ids_by_resource" =>
        source_report_family_merge_string_list_maps(source_reports, "candidate_ids_by_resource"),
      "source_report_resource_filter_blocking_dimension_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "resource_filter_blocking_dimension_counts"
        ),
      "source_report_resource_filter_candidate_ids_by_blocking_dimension" =>
        source_report_family_merge_string_list_maps(
          source_reports,
          "candidate_ids_by_blocking_dimension"
        )
    }
  end
end
