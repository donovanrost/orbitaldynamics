defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.RowData.Ids do
  @moduledoc false

  def values(row, "activity_id") do
    [
      row["activity_id"],
      row["planned_activity_id"],
      row["realized_activity_id"],
      get_in(row, ["timeline_identity", "activity_id"]),
      get_in(row, ["source_activity_context", "activity_id"]),
      get_in(row, ["source_activity_context", "id"]),
      get_in(row, ["realized_activity_context", "activity_id"]),
      get_in(row, ["realized_activity_context", "id"])
    ] ++ List.wrap(Map.get(row, "activity_ids")) ++ List.wrap(Map.get(row, "review_activity_ids"))
  end

  def values(row, "timeline_id") do
    [
      row["timeline_id"],
      row["planned_timeline_id"],
      row["realized_timeline_id"],
      get_in(row, ["timeline_identity", "timeline_id"])
    ]
  end
end
