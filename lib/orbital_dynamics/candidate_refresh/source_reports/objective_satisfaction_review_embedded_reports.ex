defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveSatisfactionReviewEmbeddedReports do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EmbeddedRowFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveSatisfactionReviewRows

  def from_rows(path, source, rows, artifact) do
    EmbeddedRowFallbacks.from_rows(path, source, rows, artifact, &report_from_rows/4)
  end

  defp report_from_rows(path, source, rows, artifact) do
    report =
      %{
        "schema_contract" => "objective_satisfaction_report.v1",
        "source" => source,
        "rows" => rows,
        "row_count" => length(rows),
        "status_counts" => count_rows(rows, "status")
      }
      |> maybe_put("provenance", Map.get(artifact, "provenance"))
      |> maybe_put("trust_boundary", result_artifact_trust_boundary(artifact))
      |> compact_map()

    {path, report}
  end

  defp count_rows(rows, field) do
    rows
    |> Enum.map(&(Map.get(&1, field) |> ObjectiveSatisfactionReviewRows.status_value()))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
    |> case do
      counts when counts == %{} -> nil
      counts -> counts
    end
  end

  defp result_artifact_trust_boundary(artifact) do
    artifact = ObjectiveSatisfactionReviewRows.stringify_keys(artifact)

    Map.get(artifact, "trust_boundary") ||
      get_in(artifact, ["provenance", "trust_boundary"]) ||
      get_in(artifact, ["metadata", "trust_boundary"]) ||
      get_in(artifact, ["assumptions", "trust_boundary"])
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
