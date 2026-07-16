defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffReviewImportReportValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffReviewImportReportCounts
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffReviewImportRows

  def build(source, rows, artifact) do
    %{
      "schema_contract" => "timeline_diff_report.v1",
      "source" => source,
      "rows" => rows,
      "row_count" => length(rows),
      "diff_status_counts" =>
        TimelineDiffReviewImportReportCounts.count_rows(rows, "diff_status"),
      "duplicate_timeline_identity_count" =>
        TimelineDiffReviewImportReportCounts.duplicate_identity_count(rows),
      "duplicate_timeline_identity_scope_counts" =>
        TimelineDiffReviewImportReportCounts.count_rows(
          rows,
          "duplicate_timeline_identity_scope"
        ),
      "required_operator_action_counts" =>
        TimelineDiffReviewImportReportCounts.count_rows(rows, "required_operator_action")
    }
    |> maybe_put("provenance", Map.get(artifact, "provenance"))
    |> maybe_put("trust_boundary", result_artifact_trust_boundary(artifact))
    |> compact_map()
  end

  defp result_artifact_trust_boundary(artifact) do
    artifact = TimelineDiffReviewImportRows.stringify_keys(artifact)

    Map.get(artifact, "trust_boundary") ||
      get_in(artifact, ["provenance", "trust_boundary"]) ||
      get_in(artifact, ["metadata", "trust_boundary"]) ||
      get_in(artifact, ["assumptions", "trust_boundary"])
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
