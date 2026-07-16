defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CandidateDiffRejection.CandidateDiffFields.Rows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def from_reports(reports) do
    Enum.flat_map(reports, &from_report/1)
  end

  def from_report(report) do
    Map.get(report, "retained_candidates", []) ++
      Map.get(report, "new_candidates", []) ++
      Map.get(report, "invalidated_candidates", [])
  end

  def trust_boundaries(reports) do
    reports
    |> from_reports()
    |> Enum.flat_map(&trust_boundary_values/1)
  end

  defp trust_boundary_values(row) do
    row = EncodedValue.stringify_keys(row)

    [
      row["trust_boundary"],
      row["source_trust_boundary"],
      get_in(row, ["provenance", "trust_boundary"]),
      get_in(row, ["source_window", "provenance", "trust_boundary"])
    ]
  end
end
