defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Assembly.ContactNetworkFields.FieldGroups do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContention.SourceReportFields,
    as: ContactContentionFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.SourceReportFields,
    as: ContactContentionResolutionFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields,
    as: StationCalendarFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields,
    as: StationReservationFields

  def contention_fields(refresh_or_artifact, source_reports) do
    ContactContentionFields.source_report_summary_fields(
      refresh_or_artifact,
      source_reports
    )
    |> Map.merge(
      ContactContentionResolutionFields.source_report_summary_fields(
        refresh_or_artifact,
        source_reports
      )
    )
  end

  def station_fields(refresh_or_artifact, source_reports) do
    StationCalendarFields.source_report_summary_fields(
      refresh_or_artifact,
      source_reports
    )
    |> Map.merge(StationReservationFields.source_report_summary_fields(source_reports))
  end
end
