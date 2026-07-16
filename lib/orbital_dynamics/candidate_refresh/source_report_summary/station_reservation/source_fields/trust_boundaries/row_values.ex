defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationReservation.SourceFields.TrustBoundaries.RowValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def values(report) do
    report
    |> trust_boundary_rows()
    |> Enum.map(&EncodedValue.stringify_keys/1)
    |> Enum.map(&trust_boundary/1)
  end

  defp trust_boundary_rows(report) do
    Map.get(report, "affected_contacts", []) ++
      Map.get(report, "provider_calendar_contention_groups", [])
  end

  defp trust_boundary(row) do
    row["trust_boundary"] ||
      row["station_calendar_trust_boundary"] ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      get_in(row, ["source_station_calendar_entry", "provenance", "trust_boundary"])
  end
end
