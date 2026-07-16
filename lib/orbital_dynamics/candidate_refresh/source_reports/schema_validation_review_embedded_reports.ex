defmodule OrbitalDynamics.CandidateRefresh.SourceReports.SchemaValidationReviewEmbeddedReports do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.SchemaValidationReportValues
  alias OrbitalDynamics.CandidateRefresh.SourceReports.SchemaValidationReviewRowReports

  def from_rows(_path, [], _artifact), do: nil

  def from_rows(path, rows, artifact) do
    report =
      case rows
           |> Enum.map(&SchemaValidationReviewRowReports.embedded_report/1)
           |> Enum.reject(&is_nil/1) do
        [embedded_report | _reports] ->
          SchemaValidationReportValues.stringify_keys(embedded_report)

        [] ->
          SchemaValidationReviewRowReports.from_rows(rows)
      end

    artifact = SchemaValidationReportValues.stringify_keys(artifact)

    report =
      report
      |> Map.put("source", "preserved_schema_validation_review_rows")
      |> maybe_put("provenance", Map.get(artifact, "provenance"))
      |> maybe_put("trust_boundary", result_artifact_trust_boundary(artifact))
      |> compact_map()

    {path, report}
  end

  defp result_artifact_trust_boundary(artifact) do
    Map.get(artifact, "trust_boundary") ||
      get_in(artifact, ["provenance", "trust_boundary"]) ||
      get_in(artifact, ["metadata", "trust_boundary"]) ||
      get_in(artifact, ["assumptions", "trust_boundary"])
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
