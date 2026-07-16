defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDependencyImpactReviewSummaryFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDependencyImpactReviewSummaryValues

  def summary(source, rows, artifact) do
    %{
      "model" => "artifact_only_timeline_dependency_impact_summary",
      "source" => source,
      "source_artifact_type" => Map.get(artifact, "source_artifact_type"),
      "source_artifact_id" => Map.get(artifact, "source_artifact_id"),
      "dependency_impact_rows" => rows,
      "dependent_activity_count" => length(rows)
    }
    |> Map.merge(TimelineDependencyImpactReviewSummaryValues.derived_fields(rows, artifact))
    |> maybe_put("provenance", Map.get(artifact, "provenance"))
    |> compact_map()
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
