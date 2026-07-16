defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveTradeoffReviewReportFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EmbeddedRowFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveTradeoffReviewRows

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
        "schema_contract" => "objective_tradeoff_report.v1",
        "model" => "preserved_objective_tradeoff_rows",
        "objective" => "preserved branch objective tradeoff replay",
        "source" => %{"artifact_source" => source},
        "tradeoffs" => rows,
        "ranking_count" => length(rows),
        "score_term_keys" => ObjectiveTradeoffReviewRows.score_term_keys(rows),
        "assumptions" => %{
          "candidate_refresh_replay" =>
            "only explicitly routed gap-like tradeoff rows become refresh objectives"
        }
      }
      |> maybe_put("provenance", Map.get(artifact, "provenance"))
      |> maybe_put("trust_boundary", result_artifact_trust_boundary(artifact))
      |> compact_map()

    {path, report}
  end

  defp result_artifact_trust_boundary(artifact) do
    artifact = ObjectiveTradeoffReviewRows.stringify_keys(artifact)

    Map.get(artifact, "trust_boundary") ||
      get_in(artifact, ["provenance", "trust_boundary"]) ||
      get_in(artifact, ["metadata", "trust_boundary"]) ||
      get_in(artifact, ["assumptions", "trust_boundary"])
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
