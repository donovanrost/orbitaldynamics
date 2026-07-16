defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ScoreTermReviewReportFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EmbeddedRowFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ScoreTermReviewRows

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
    report =
      %{
        "schema_contract" => "score_term_report.v1",
        "model" => "preserved_score_term_rows",
        "source" => %{"artifact_source" => source},
        "rows" => rows,
        "row_count" => length(rows),
        "score_term_keys" => score_term_keys(rows),
        "assumptions" => %{
          "candidate_refresh_replay" =>
            "only explicitly routed gap-like score terms become refresh objectives"
        }
      }
      |> maybe_put("provenance", Map.get(artifact, "provenance"))
      |> maybe_put("trust_boundary", result_artifact_trust_boundary(artifact))
      |> compact_map()

    {path, report}
  end

  defp score_term_keys(rows) do
    rows
    |> Enum.map(&ScoreTermReviewRows.score_term_key/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp result_artifact_trust_boundary(artifact) do
    artifact = ScoreTermReviewRows.stringify_keys(artifact)

    Map.get(artifact, "trust_boundary") ||
      get_in(artifact, ["provenance", "trust_boundary"]) ||
      get_in(artifact, ["metadata", "trust_boundary"]) ||
      get_in(artifact, ["assumptions", "trust_boundary"])
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
