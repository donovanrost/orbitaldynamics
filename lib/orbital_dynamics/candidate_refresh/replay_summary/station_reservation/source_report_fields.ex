defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.Summary

  alias __MODULE__.Direction
  alias __MODULE__.Evidence
  alias __MODULE__.IdentityStatus
  alias __MODULE__.Metadata
  alias __MODULE__.ProviderContention
  alias __MODULE__.Pressure
  alias __MODULE__.ReservationHold

  import __MODULE__.Aggregation

  def source_report_summary_fields(source_reports) do
    source_reports
    |> station_reservation_summary()
    |> Pressure.source_report_pressure_fields()
    |> then(&source_report_fields(source_reports, &1))
  end

  def source_report_fields(source_reports, pressure_fields) do
    source_reports
    |> source_report_fields()
    |> Map.merge(pressure_fields)
    |> compact_map()
  end

  def source_report_fields(source_reports) do
    source_reports
    |> Evidence.source_report_evidence_fields()
    |> Map.merge(Metadata.source_report_metadata_fields(source_reports))
    |> Map.merge(Direction.source_report_direction_fields(source_reports))
    |> Map.merge(IdentityStatus.source_report_identity_status_fields(source_reports))
    |> Map.merge(ProviderContention.source_report_provider_contention_fields(source_reports))
    |> Map.merge(ReservationHold.source_report_reservation_hold_fields(source_reports))
  end

  defp station_reservation_summary(source_reports) do
    source_reports
    |> Map.get("station_reservation_report", %{})
    |> Summary.summary(
      "candidate_refresh.source_report_provenance.station_reservation_report",
      "station_reservation_source_report_provenance_only"
    )
  end
end
