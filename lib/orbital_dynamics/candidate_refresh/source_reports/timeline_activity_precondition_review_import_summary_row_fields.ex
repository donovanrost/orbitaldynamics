defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionReviewImportSummaryRowFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionReviewImportEncoding

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionReviewImportSummaryRowValues

  def fields(rows, artifact) do
    %{
      "activity_id" => row_value(rows, "activity_id"),
      "timeline_id" => row_value(rows, "timeline_id"),
      "dependency_activity_ids" => row_values(rows, "dependency_activity_ids"),
      "dependency_timeline_ids" => row_values(rows, "dependency_timeline_ids"),
      "exclusive_with_activity_ids" => row_values(rows, "exclusive_with_activity_ids"),
      "exclusive_with_timeline_ids" => row_values(rows, "exclusive_with_timeline_ids"),
      "duplicate_dependency_activity_ids" =>
        row_values(rows, "duplicate_dependency_activity_ids"),
      "duplicate_dependency_timeline_ids" =>
        row_values(rows, "duplicate_dependency_timeline_ids"),
      "duplicate_exclusivity_activity_ids" =>
        row_values(rows, "duplicate_exclusivity_activity_ids"),
      "duplicate_exclusivity_timeline_ids" =>
        row_values(rows, "duplicate_exclusivity_timeline_ids"),
      "allow_overlap" => if(Enum.any?(rows, &(&1["allow_overlap"] == true)), do: true),
      "invalid_activity_input" => Enum.any?(rows, &(&1["invalid_activity_input"] == true)),
      "invalid_activity_input_count" => Enum.count(rows, &(&1["invalid_activity_input"] == true)),
      "invalid_activity_input_reasons" => invalid_activity_input_reasons(rows),
      "provenance" => Map.get(artifact, "provenance"),
      "trust_boundary" => result_artifact_trust_boundary(artifact)
    }
  end

  defp row_value(rows, field),
    do: TimelineActivityPreconditionReviewImportSummaryRowValues.unique_row_value(rows, field)

  defp row_values(rows, field),
    do: TimelineActivityPreconditionReviewImportSummaryRowValues.sorted_row_values(rows, field)

  defp invalid_activity_input_reasons(rows),
    do:
      TimelineActivityPreconditionReviewImportSummaryRowValues.invalid_activity_input_reasons(
        rows
      )

  defp result_artifact_trust_boundary(artifact) do
    artifact = TimelineActivityPreconditionReviewImportEncoding.stringify_keys(artifact)

    Map.get(artifact, "trust_boundary") ||
      get_in(artifact, ["provenance", "trust_boundary"]) ||
      get_in(artifact, ["metadata", "trust_boundary"]) ||
      get_in(artifact, ["assumptions", "trust_boundary"])
  end
end
