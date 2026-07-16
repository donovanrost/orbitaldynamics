defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.StationReservationEvidence do
  @moduledoc false

  alias __MODULE__.FieldSets
  alias __MODULE__.RowContexts

  def evidence_count(report) do
    report
    |> Map.get("rows", [])
    |> Enum.count(&row_station_reservation_evidence?/1)
  end

  def expiration_evidence_count(report) do
    report
    |> Map.get("rows", [])
    |> Enum.count(&row_station_reservation_expiration_evidence?/1)
  end

  defp row_station_reservation_evidence?(row) do
    row
    |> RowContexts.has_any?(FieldSets.reservation_fields())
  end

  defp row_station_reservation_expiration_evidence?(row) do
    row
    |> RowContexts.has_any?(FieldSets.expiration_fields())
  end
end
