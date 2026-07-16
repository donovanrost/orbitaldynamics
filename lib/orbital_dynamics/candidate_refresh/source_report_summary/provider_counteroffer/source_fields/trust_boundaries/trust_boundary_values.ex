defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer.SourceFields.TrustBoundaries.TrustBoundaryValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def from_row(row) do
    row = EncodedValue.stringify_keys(row)

    [
      row["trust_boundary"],
      get_in(row, ["provenance", "trust_boundary"]),
      get_in(row, ["source_station_calendar_entry", "trust_boundary"]),
      get_in(row, ["source_station_calendar_entry", "provenance", "trust_boundary"])
    ]
  end
end
