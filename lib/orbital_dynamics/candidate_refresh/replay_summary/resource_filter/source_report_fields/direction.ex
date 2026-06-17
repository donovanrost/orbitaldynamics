defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ResourceFilter.SourceReportFields.Direction do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.ResourceFilter.SourceReportFields.Aggregation

  def fields(source_reports) do
    %{
      "source_report_resource_filter_direction_counts" =>
        source_report_family_merge_count_maps(source_reports, "direction_counts"),
      "source_report_resource_filter_directions" =>
        source_report_family_field(source_reports, "directions"),
      "source_report_resource_filter_candidate_ids_by_direction" =>
        source_report_family_merge_string_list_maps(source_reports, "candidate_ids_by_direction"),
      "source_report_resource_filter_direction_routing" =>
        source_report_family_field(source_reports, "direction_routing")
    }
  end
end
