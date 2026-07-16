defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ConstraintReviewReportFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ConstraintEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ConstraintReviewReportCounts
  alias OrbitalDynamics.CandidateRefresh.SourceReports.EmbeddedRowFallbacks

  def report(source, rows, artifact) do
    %{
      "schema_contract" => "constraint_report.v1",
      "model" => "preserved_constraint_rows",
      "source" => source,
      "rows" => rows,
      "row_count" => length(rows),
      "status_counts" => ConstraintReviewReportCounts.count_rows(rows, "status")
    }
    |> maybe_put("provenance", Map.get(artifact, "provenance"))
    |> maybe_put("trust_boundary", result_artifact_trust_boundary(artifact))
    |> compact_map()
  end

  def report_from_embedded_rows(path, source, rows, artifact) do
    EmbeddedRowFallbacks.report_from_embedded_rows(
      path,
      source,
      rows,
      artifact,
      &report_from_rows/4
    )
  end

  defp report_from_rows(path, source, rows, artifact) do
    {path, report(source, rows, artifact)}
  end

  defp result_artifact_trust_boundary(artifact) do
    artifact = ConstraintEncoding.stringify_keys(artifact)

    Map.get(artifact, "trust_boundary") ||
      get_in(artifact, ["provenance", "trust_boundary"]) ||
      get_in(artifact, ["metadata", "trust_boundary"]) ||
      get_in(artifact, ["assumptions", "trust_boundary"])
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
