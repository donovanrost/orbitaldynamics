defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ResourceProjection.SourceReportFields.Identity do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.ResourceProjection.SourceReportFields.Aggregation

  def fields(source_reports) do
    %{
      "source_report_resource_projection_contract" =>
        source_report_family_field(source_reports, "contract"),
      "source_report_resource_projection_count" =>
        source_report_family_identity_count(source_reports, "count"),
      "source_report_resource_projection_row_count" =>
        source_report_family_identity_count(source_reports, "row_count"),
      "source_report_resource_projection_paths" =>
        source_report_family_identity_field(source_reports, "paths")
    }
  end
end
