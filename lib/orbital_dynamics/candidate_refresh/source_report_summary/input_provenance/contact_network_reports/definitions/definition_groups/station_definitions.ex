defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.ContactNetworkReports.Definitions.DefinitionGroups.StationDefinitions do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary

  def definitions do
    [
      %{
        key: "provider_counteroffer_report",
        mode: :deduplicated,
        source: :source_provider_counteroffer_reports,
        summary: &SourceReportSummary.ProviderCounteroffer.report_input_summary/1
      },
      %{
        key: "station_calendar_report",
        mode: :deduplicated,
        source: :source_station_calendar_reports,
        summary: &SourceReportSummary.StationCalendar.report_input_summary/1
      },
      %{
        key: "station_reservation_report",
        source: :source_station_reservation_reports,
        summary: &SourceReportSummary.StationReservation.report_input_summary/1
      }
    ]
  end
end
