defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ResourceFilter.SourceReportFields.Identity do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.ResourceFilter.SourceReportFields.Aggregation

  def fields(source_reports) do
    %{
      "source_report_resource_filter_contract" =>
        source_report_family_field(source_reports, "contract"),
      "source_report_resource_filter_count" =>
        source_report_family_identity_count(source_reports, "count"),
      "source_report_resource_filter_row_count" =>
        source_report_family_identity_count(source_reports, "row_count"),
      "source_report_resource_filter_paths" =>
        source_report_family_identity_field(source_reports, "paths")
    }
  end
end
