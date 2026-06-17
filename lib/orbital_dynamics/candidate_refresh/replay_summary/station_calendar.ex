defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields
  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.Summary

  def replay(refresh_or_artifact, callbacks) do
    {station_summary, summary_source, replay_scope} =
      selected_summary(refresh_or_artifact, nil, callbacks)

    summary(station_summary, summary_source, replay_scope)
  end

  def source_report_fields(refresh_or_artifact, source_reports, callbacks) do
    {station_summary, summary_source, replay_scope} =
      selected_summary(refresh_or_artifact, source_reports, callbacks)

    station_summary
    |> summary(summary_source, replay_scope)
    |> SourceReportFields.source_report_fields()
  end

  def source_report_summary_fields(refresh_or_artifact, source_reports, callbacks) do
    pressure_fields = source_report_fields(refresh_or_artifact, source_reports, callbacks)

    SourceReportFields.source_report_summary_fields(source_reports, pressure_fields)
  end

  def source_report_identity_fields(source_reports),
    do: SourceReportFields.source_report_identity_fields(source_reports)

  def source_report_source_metadata_fields(source_reports),
    do: SourceReportFields.source_report_source_metadata_fields(source_reports)

  def source_report_provider_contention_fields(source_reports),
    do: SourceReportFields.source_report_provider_contention_fields(source_reports)

  def source_report_direction_fields(source_reports),
    do: SourceReportFields.source_report_direction_fields(source_reports)

  def source_report_reservation_capacity_status_fields(source_reports),
    do: SourceReportFields.source_report_reservation_capacity_status_fields(source_reports)

  def source_report_precedence_fields(source_reports),
    do: SourceReportFields.source_report_precedence_fields(source_reports)

  defp selected_summary(refresh_or_artifact, source_reports, callbacks) do
    source_report_summary_branch_family =
      Keyword.fetch!(callbacks, :source_report_summary_branch_family)

    branch_station_summary =
      source_report_summary_branch_family.(refresh_or_artifact, "station_calendar_report")

    station_summary =
      branch_station_summary ||
        source_report_station_summary(refresh_or_artifact, source_reports, callbacks)

    {summary_source, replay_scope} =
      if branch_station_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.station_calendar_report",
          "station_calendar_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.station_calendar_report",
          "station_calendar_source_report_provenance_only"
        }
      end

    {station_summary, summary_source, replay_scope}
  end

  defp source_report_station_summary(refresh_or_artifact, nil, callbacks) do
    source_report_summary = Keyword.fetch!(callbacks, :source_report_summary)

    refresh_or_artifact
    |> source_report_summary.()
    |> get_in(["source_reports", "station_calendar_report"])
    |> Kernel.||(%{})
  end

  defp source_report_station_summary(_refresh_or_artifact, source_reports, _callbacks),
    do: Map.get(source_reports, "station_calendar_report", %{})

  def summary(station_summary, summary_source, replay_scope),
    do: Summary.summary(station_summary, summary_source, replay_scope)
end
