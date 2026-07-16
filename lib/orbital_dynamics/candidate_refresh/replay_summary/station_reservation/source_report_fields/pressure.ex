defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Pressure do
  @moduledoc false

  def source_report_pressure_fields(summary) do
    %{
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
    }
  end
end
