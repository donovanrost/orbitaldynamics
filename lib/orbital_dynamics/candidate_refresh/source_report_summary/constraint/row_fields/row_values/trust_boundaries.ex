defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Constraint.RowFields.RowValues.TrustBoundaries do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceObjectives.Constraint,
    as: ConstraintSourceObjectives

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def row_trust_boundaries(rows, report) do
    report_trust_boundary = result_artifact_trust_boundary(report)

    rows
    |> Enum.map(&EncodedValue.stringify_keys/1)
    |> Enum.map(&Map.put_new(&1, "_source_report_trust_boundary", report_trust_boundary))
    |> Enum.map(&ConstraintSourceObjectives.trust_boundary/1)
  end

  defp result_artifact_trust_boundary(artifact) do
    artifact = EncodedValue.stringify_keys(artifact)

    Map.get(artifact, "trust_boundary") ||
      get_in(artifact, ["provenance", "trust_boundary"]) ||
      get_in(artifact, ["metadata", "trust_boundary"]) ||
      get_in(artifact, ["assumptions", "trust_boundary"])
  end
end
