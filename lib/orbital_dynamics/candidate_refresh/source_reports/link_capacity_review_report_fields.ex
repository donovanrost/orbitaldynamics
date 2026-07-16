defmodule OrbitalDynamics.CandidateRefresh.SourceReports.LinkCapacityReviewReportFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EmbeddedRowFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.LinkCapacityReviewReportCounts
  alias OrbitalDynamics.CandidateRefresh.SourceReports.LinkCapacityReviewRows

  def report(source, rows, artifact) do
    %{
      "schema_contract" => "link_capacity_report.v1",
      "model" => "preserved_link_capacity_rows",
      "source" => source,
      "rows" => rows,
      "row_count" => length(rows),
      "downlink_requirement_status_counts" =>
        LinkCapacityReviewReportCounts.count_rows(rows, "downlink_requirement_status"),
      "actual_downlink_requirement_status_counts" =>
        LinkCapacityReviewReportCounts.count_rows(rows, "actual_downlink_requirement_status")
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
    artifact = LinkCapacityReviewRows.stringify_keys(artifact)

    Map.get(artifact, "trust_boundary") ||
      get_in(artifact, ["provenance", "trust_boundary"]) ||
      get_in(artifact, ["metadata", "trust_boundary"]) ||
      get_in(artifact, ["assumptions", "trust_boundary"])
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
