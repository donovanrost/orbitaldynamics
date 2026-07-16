defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ManeuverReviewReportRowValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ManeuverReviewReportRowArtifactValues
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ManeuverReviewReportRowCounts

  def from_rows(path, source, rows, artifact) do
    report =
      %{
        "schema_contract" => "maneuver_review_report.v1",
        "model" => "preserved_maneuver_review_rows",
        "source" => source,
        "rows" => rows,
        "maneuver_count" => length(rows),
        "execution_uncertainty_declared_count" =>
          ManeuverReviewReportRowCounts.count_rows(
            rows,
            "execution_uncertainty_status",
            "declared"
          ),
        "execution_uncertainty_missing_count" =>
          ManeuverReviewReportRowCounts.count_rows(
            rows,
            "execution_uncertainty_status",
            "missing"
          ),
        "required_operator_action_counts" =>
          ManeuverReviewReportRowCounts.count_rows(rows, "required_operator_action")
      }
      |> maybe_put("provenance", Map.get(artifact, "provenance"))
      |> maybe_put(
        "trust_boundary",
        ManeuverReviewReportRowArtifactValues.trust_boundary(artifact)
      )
      |> compact_map()

    {path, report}
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
