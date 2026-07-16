defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.SourceFields.TrustBoundaries.RowValues.TrustBoundaryValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def from_row(row) do
    Map.get(row, "trust_boundary") ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      get_in(row, ["source_link_capacity", "trust_boundary"]) ||
      get_in(row, ["source_link_capacity", "provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"]
  end

  def normalize(values) do
    values
    |> Enum.map(&EncodedValue.value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end
end
