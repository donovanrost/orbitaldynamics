defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.IdentityStatusFields.MatchStatus do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.Rows,
    only: [
      contact_ids_by_values: 2,
      count_rows: 2,
      ids_by_values: 2
    ]

  @match_status_fields ["station_reservation_match_status"]

  def match_status_counts(report) do
    report
    |> Map.get("affected_contacts", [])
    |> count_rows("station_reservation_match_status")
  end

  def ids_by_match_status(report) do
    report
    |> Map.get("affected_contacts", [])
    |> ids_by_values(@match_status_fields)
  end

  def contact_ids_by_match_status(report) do
    report
    |> Map.get("affected_contacts", [])
    |> contact_ids_by_values(@match_status_fields)
  end
end
