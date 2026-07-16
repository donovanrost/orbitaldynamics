defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDependencyImpactReviewSummaryValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sorted_string_values: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDependencyImpactRows

  def derived_fields(rows, artifact) do
    %{
      "source_dependent_activity_count" =>
        Enum.count(rows, &(TimelineDependencyImpactRows.row_scope(&1) == "source")),
      "replacement_dependent_activity_count" =>
        Enum.count(rows, &(TimelineDependencyImpactRows.row_scope(&1) == "replacement")),
      "dependency_impact_status" => dependency_impact_status(rows),
      "impacted_source_activity_ids" => summary_values(rows, "impacted_source_activity_ids"),
      "impacted_source_timeline_ids" => summary_values(rows, "impacted_source_timeline_ids"),
      "impacted_dependency_activity_ids" =>
        summary_values(rows, "impacted_dependency_activity_ids"),
      "impacted_dependency_timeline_ids" =>
        summary_values(rows, "impacted_dependency_timeline_ids"),
      "impacted_exclusive_with_activity_ids" =>
        summary_values(rows, "impacted_exclusive_with_activity_ids"),
      "impacted_exclusive_with_timeline_ids" =>
        summary_values(rows, "impacted_exclusive_with_timeline_ids"),
      "trust_boundary" => result_artifact_trust_boundary(artifact)
    }
  end

  defp dependency_impact_status(rows) do
    if Enum.any?(rows, &(&1["dependency_impact_status"] == "review_required")) do
      "review_required"
    else
      "clear"
    end
  end

  defp summary_values(rows, field) do
    rows
    |> Enum.flat_map(&TimelineDependencyImpactRows.summary_values(&1, field))
    |> sorted_string_values()
  end

  defp result_artifact_trust_boundary(artifact) do
    artifact = TimelineDependencyImpactRows.stringify_keys(artifact)

    Map.get(artifact, "trust_boundary") ||
      get_in(artifact, ["provenance", "trust_boundary"]) ||
      get_in(artifact, ["metadata", "trust_boundary"]) ||
      get_in(artifact, ["assumptions", "trust_boundary"])
  end
end
