defmodule OrbitalDynamics.CandidateRefresh.SourceReports.OperationalReadinessReviewRowReports do
  @moduledoc false

  alias OrbitalDynamics.OperationalReadiness, as: OperationalReadinessReport

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalReadinessReviewRowEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalReadinessReviewRowSources

  def report_from_review_or_import_rows(_path, [], _artifact), do: nil

  def report_from_review_or_import_rows(path, rows, artifact) do
    report =
      case rows
           |> Enum.map(&OperationalReadinessReviewRowSources.embedded_report/1)
           |> Enum.reject(&is_nil/1) do
        [embedded_report | _reports] ->
          stringify_keys(embedded_report)

        [] ->
          artifact
          |> stringify_keys()
          |> Map.put("rows", rows)
          |> OperationalReadinessReport.report()
      end

    artifact = stringify_keys(artifact)

    report =
      report
      |> Map.put("source", "preserved_operational_readiness_review_rows")
      |> maybe_put("provenance", Map.get(artifact, "provenance"))
      |> maybe_put(
        "trust_boundary",
        OperationalReadinessReviewRowSources.trust_boundary(artifact)
      )
      |> compact_map()

    {path, report}
  end

  def stringify_keys(value), do: OperationalReadinessReviewRowEncoding.stringify_keys(value)

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
