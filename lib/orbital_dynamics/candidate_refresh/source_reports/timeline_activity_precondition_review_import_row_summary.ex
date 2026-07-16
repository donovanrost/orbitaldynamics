defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionReviewImportRowSummary do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1
    ]

  def from_row(row, embedded) do
    row
    |> Map.drop(["source_review_row", "source_timeline_activity_precondition_summary"])
    |> Map.merge(embedded)
    |> Map.put_new("schema_contract", "timeline_activity_precondition_summary.v1")
    |> Map.put_new("model", "artifact_only_timeline_activity_precondition_summary")
    |> Map.put_new("activity_id", row["activity_id"])
    |> Map.put_new("timeline_id", row["timeline_id"])
    |> Map.put_new("activity_type", row["activity_type"])
    |> Map.put_new("precondition_status", row["precondition_status"])
    |> Map.put_new("blocked_precondition_count", row["blocked_precondition_count"])
    |> Map.put_new("review_precondition_count", row["review_precondition_count"])
    |> Map.put_new("blocked_precondition_types", row["blocked_precondition_types"])
    |> Map.put_new("review_precondition_types", row["review_precondition_types"])
    |> Map.put_new("dependency_activity_ids", row["dependency_activity_ids"])
    |> Map.put_new("dependency_timeline_ids", row["dependency_timeline_ids"])
    |> Map.put_new("exclusive_with_activity_ids", row["exclusive_with_activity_ids"])
    |> Map.put_new("exclusive_with_timeline_ids", row["exclusive_with_timeline_ids"])
    |> Map.put_new("duplicate_dependency_activity_ids", row["duplicate_dependency_activity_ids"])
    |> Map.put_new("duplicate_dependency_timeline_ids", row["duplicate_dependency_timeline_ids"])
    |> Map.put_new(
      "duplicate_exclusivity_activity_ids",
      row["duplicate_exclusivity_activity_ids"]
    )
    |> Map.put_new(
      "duplicate_exclusivity_timeline_ids",
      row["duplicate_exclusivity_timeline_ids"]
    )
    |> Map.put_new("allow_overlap", row["allow_overlap"])
    |> Map.put_new("invalid_activity_input", row["invalid_activity_input"])
    |> Map.put_new("invalid_activity_input_reason", row["invalid_activity_input_reason"])
    |> Map.put_new("invalid_activity_input_reasons", row["invalid_activity_input_reasons"])
    |> Map.put_new("preconditions", Map.get(embedded, "preconditions", []))
    |> compact_map()
  end
end
