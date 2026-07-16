defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SummarySelection do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance
  alias OrbitalDynamics.CandidateRefresh.ValueEncoding

  def selected_summary(refresh_or_artifact, source_reports) do
    branch_station_summary =
      source_report_summary_branch_family(refresh_or_artifact, "station_calendar_report")

    station_summary =
      branch_station_summary ||
        source_report_station_summary(refresh_or_artifact, source_reports)

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

  defp source_report_station_summary(refresh_or_artifact, nil) do
    refresh_or_artifact
    |> source_report_summary()
    |> Map.get("station_calendar_report")
    |> Kernel.||(%{})
  end

  defp source_report_station_summary(
         _refresh_or_artifact,
         source_reports
       ),
       do: Map.get(source_reports, "station_calendar_report", %{})

  defp source_report_summary_branch_family(refresh_or_artifact, family) do
    SourceReportSummary.branch_family(
      refresh_or_artifact,
      family,
      &InputProvenance.build/1
    )
  end

  defp source_report_summary(refresh_or_artifact) when is_map(refresh_or_artifact) do
    refresh_or_artifact
    |> ValueEncoding.stringify_keys()
    |> SourceReportSummary.source_reports(&InputProvenance.build/1)
  end

  defp source_report_summary(_refresh_or_artifact), do: source_report_summary(%{})
end
