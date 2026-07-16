defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.ActivityIds.Paths do
  @moduledoc false

  def source do
    [
      "source_activity_id",
      "activity_id",
      "removed_activity_id",
      "changed_activity_id",
      ["source_timeline_identity", "activity_id"],
      ["timeline_identity", "activity_id"],
      ["source_activity_context", "activity_id"],
      ["source_activity_context", "id"],
      ["source_activity", "activity_id"],
      ["source_activity", "id"]
    ]
  end

  def replacement do
    [
      "replacement_activity_id",
      "selected_activity_id",
      "candidate_activity_id",
      ["replacement_timeline_identity", "activity_id"],
      ["replacement_activity_context", "activity_id"],
      ["replacement_activity_context", "id"],
      ["replacement_activity", "activity_id"],
      ["replacement_activity", "id"]
    ]
  end
end
