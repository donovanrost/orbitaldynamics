defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactFilter.SourceFields.TrustBoundaries.RowValues do
  @moduledoc false

  def values(row) do
    [
      primary_value(row),
      row["source_trust_boundary"],
      get_in(row, ["source_contact_suppression", "trust_boundary"]),
      get_in(row, ["source_contact_suppression", "provenance", "trust_boundary"]),
      get_in(row, ["source_station_calendar_entry", "provenance", "trust_boundary"])
    ]
  end

  defp primary_value(row) do
    row["trust_boundary"] ||
      row["station_calendar_trust_boundary"] ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      get_in(row, ["source_station_calendar_entry", "provenance", "trust_boundary"])
  end
end
