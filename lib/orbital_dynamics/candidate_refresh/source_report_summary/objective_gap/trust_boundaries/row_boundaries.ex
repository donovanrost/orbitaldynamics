defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.TrustBoundaries.RowBoundaries do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [source_report_trust_boundaries: 1]

  def values(rows, report, trust_boundary_fun) do
    rows
    |> Enum.map(&put_source_report_trust_boundary(&1, report))
    |> Enum.map(trust_boundary_fun)
    |> with_source_report_boundaries(report)
  end

  def source_report_values(report) do
    source_report_trust_boundaries([report])
  end

  defp with_source_report_boundaries(row_trust_boundaries, report) do
    row_trust_boundaries ++ source_report_values(report)
  end

  defp put_source_report_trust_boundary(row, report) do
    row
    |> EncodedValue.stringify_keys()
    |> Map.put_new("_source_report_trust_boundary", result_artifact_trust_boundary(report))
  end

  defp result_artifact_trust_boundary(artifact) do
    artifact = EncodedValue.stringify_keys(artifact)

    Map.get(artifact, "trust_boundary") ||
      get_in(artifact, ["provenance", "trust_boundary"]) ||
      get_in(artifact, ["metadata", "trust_boundary"]) ||
      get_in(artifact, ["assumptions", "trust_boundary"])
  end
end
