defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.TrustBoundaries.RowValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def values(%{} = report) do
    report
    |> candidate_rows()
    |> Enum.flat_map(&candidate_values/1)
  end

  defp candidate_rows(report) do
    report
    |> Map.get("suppressed_candidates", [])
    |> Kernel.++(Map.get(report, "invalid_resource_summary_inputs", []))
  end

  defp candidate_values(row) do
    row = EncodedValue.stringify_keys(row)

    [
      row["resource_trust_boundary"],
      row["trust_boundary"],
      get_in(row, ["source_resource_summary", "trust_boundary"]),
      get_in(row, ["source_resource_summary", "provenance", "trust_boundary"]),
      get_in(row, ["resource_provenance", "trust_boundary"]),
      get_in(row, ["provenance", "trust_boundary"])
    ]
  end
end
