defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.ContactNetworkReports.Definitions.DefinitionGroups.ContactDefinitions do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary
  alias __MODULE__.ReportDefinitions

  def definitions do
    [
      %{
        key: "contact_intent",
        source: :source_contact_intents,
        summary: &SourceReportSummary.ContactIntent.report_input_summary/1
      },
      %{
        key: "contact_filter_report",
        source: :source_contact_filter_reports,
        summary: &SourceReportSummary.ContactFilter.report_input_summary/1
      }
    ] ++ ReportDefinitions.definitions()
  end
end
