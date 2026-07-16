defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.ContactNetworkReports.Definitions.DefinitionGroups.ContactDefinitions.ReportDefinitions do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary

  def definitions do
    [
      %{
        key: "link_capacity_report",
        mode: :deduplicated,
        source: :source_link_capacity_reports,
        summary: &SourceReportSummary.LinkCapacity.report_input_summary/1
      },
      %{
        key: "contact_allocation_report",
        mode: :deduplicated,
        source: :source_contact_allocation_reports,
        summary: &SourceReportSummary.ContactAllocation.report_input_summary/1
      },
      %{
        key: "contact_contention_report",
        mode: :deduplicated,
        source: :source_contact_contention_reports,
        summary: &SourceReportSummary.ContactContention.report_input_summary/1
      },
      %{
        key: "contact_contention_resolution_report",
        mode: :deduplicated,
        source: :source_contact_contention_resolution_reports,
        summary: &SourceReportSummary.ContactContentionResolution.report_input_summary/1
      }
    ]
  end
end
