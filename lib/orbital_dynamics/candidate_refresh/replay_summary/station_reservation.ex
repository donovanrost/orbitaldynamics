defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.Summary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance
  alias OrbitalDynamics.CandidateRefresh.ValueEncoding

  def replay(refresh_or_artifact) do
    branch_reservation_summary = source_report_summary_branch_family(refresh_or_artifact)

    reservation_summary =
      branch_reservation_summary ||
        refresh_or_artifact
        |> source_report_summary()
        |> Map.get("station_reservation_report") ||
        %{}

    {summary_source, replay_scope} =
      if branch_reservation_summary do
        {
          "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.station_reservation_report",
          "station_reservation_candidate_source_report_summary_only"
        }
      else
        {
          "candidate_refresh.source_report_provenance.station_reservation_report",
          "station_reservation_source_report_provenance_only"
        }
      end

    summary(reservation_summary, summary_source, replay_scope)
  end

  def summary(reservation_summary, summary_source, replay_scope),
    do: Summary.summary(reservation_summary, summary_source, replay_scope)

  defp source_report_summary_branch_family(refresh_or_artifact) do
    SourceReportSummary.branch_family(
      refresh_or_artifact,
      "station_reservation_report",
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
