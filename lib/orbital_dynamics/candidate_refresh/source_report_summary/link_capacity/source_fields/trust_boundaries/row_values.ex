defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.SourceFields.TrustBoundaries.RowValues do
  @moduledoc false

  alias __MODULE__.TrustBoundaryValues
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def with_rows(report, rows) do
    row_trust_boundaries =
      rows
      |> Enum.map(&EncodedValue.stringify_keys/1)
      |> Enum.map(&TrustBoundaryValues.from_row/1)

    row_trust_boundaries
    |> Kernel.++(fallback_values(report))
    |> TrustBoundaryValues.normalize()
  end

  def without_rows(report) do
    report = EncodedValue.stringify_keys(report)

    [TrustBoundaryValues.from_row(report)]
    |> Kernel.++(fallback_values(report))
    |> TrustBoundaryValues.normalize()
  end

  defp fallback_values(report) do
    [
      Map.get(report, "trust_boundary"),
      get_in(report, ["provenance", "trust_boundary"])
    ]
  end
end
