defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.ObjectiveResourceReports.Definitions.DefinitionGroups.ResourceDefinitions do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary

  def definitions do
    [
      %{
        key: "resource_projection_report",
        source: :source_resource_projection_reports,
        summary: &SourceReportSummary.ResourceProjection.report_input_summary/1
      },
      %{
        key: "resource_filter_report",
        source: :source_resource_filter_reports,
        summary: &SourceReportSummary.ResourceFilter.report_input_summary/1
      }
    ]
  end
end
