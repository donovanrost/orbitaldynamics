defmodule OrbitalDynamics.CandidateRefresh.SourceReports.CommandWindowReviewEmbeddedReports do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.CommandWindowReviewRows
  alias OrbitalDynamics.CandidateRefresh.SourceReports.EmbeddedRowFallbacks

  def from_rows(path, source, rows, artifact) do
    EmbeddedRowFallbacks.from_rows(path, source, rows, artifact, &report_from_rows/4)
  end

  defp report_from_rows(path, source, rows, artifact) do
    report =
      %{
        "schema_contract" => "command_window_report.v1",
        "source" => source,
        "rows" => rows,
        "window_count" => length(rows),
        "required_operator_action_counts" => count_rows(rows, "required_operator_action")
      }
      |> maybe_put("provenance", Map.get(artifact, "provenance"))
      |> maybe_put("trust_boundary", result_artifact_trust_boundary(artifact))
      |> compact_map()

    {path, report}
  end

  defp count_rows(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
    |> case do
      counts when counts == %{} -> nil
      counts -> counts
    end
  end

  defp result_artifact_trust_boundary(artifact) do
    artifact = CommandWindowReviewRows.stringify_keys(artifact)

    Map.get(artifact, "trust_boundary") ||
      get_in(artifact, ["provenance", "trust_boundary"]) ||
      get_in(artifact, ["metadata", "trust_boundary"]) ||
      get_in(artifact, ["assumptions", "trust_boundary"])
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
