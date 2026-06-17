defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields
  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.Summary

  def replay(refresh_or_artifact, callbacks) do
    source_report_summary = Keyword.fetch!(callbacks, :source_report_summary)

    source_report_summary_branch_family =
      Keyword.fetch!(callbacks, :source_report_summary_branch_family)

    branch_reservation_summary =
      source_report_summary_branch_family.(refresh_or_artifact, "station_reservation_report")

    reservation_summary =
      branch_reservation_summary ||
        refresh_or_artifact
        |> source_report_summary.()
        |> get_in(["source_reports", "station_reservation_report"]) ||
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

  def source_report_fields(source_reports) do
    summary =
      source_reports
      |> Map.get("station_reservation_report", %{})
      |> summary(
        "candidate_refresh.source_report_provenance.station_reservation_report",
        "station_reservation_source_report_provenance_only"
      )

    SourceReportFields.source_report_fields(source_reports, %{
      "source_report_station_reservation_branch_local_station_reservation_pressure" =>
        Map.get(summary, "branch_local_station_reservation_pressure"),
      "source_report_station_reservation_branch_local_reservation_review_pressure" =>
        Map.get(summary, "branch_local_reservation_review_pressure"),
      "source_report_station_reservation_branch_local_reservation_owner_pressure" =>
        Map.get(summary, "branch_local_reservation_owner_pressure"),
      "source_report_station_reservation_branch_local_reservation_expiration_pressure" =>
        Map.get(summary, "branch_local_reservation_expiration_pressure"),
      "source_report_station_reservation_branch_local_reservation_hold_pressure" =>
        Map.get(summary, "branch_local_reservation_hold_pressure"),
      "source_report_station_reservation_branch_local_provider_contention_pressure" =>
        Map.get(summary, "branch_local_provider_contention_pressure"),
      "source_report_station_reservation_branch_local_reservation_hold_import_readiness_pressure" =>
        Map.get(summary, "branch_local_reservation_hold_import_readiness_pressure")
    })
  end

  def summary(reservation_summary, summary_source, replay_scope),
    do: Summary.summary(reservation_summary, summary_source, replay_scope)
end
