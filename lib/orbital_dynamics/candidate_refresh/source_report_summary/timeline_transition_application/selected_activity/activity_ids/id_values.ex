defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.SelectedActivity.ActivityIds.IdValues do
  @moduledoc false

  alias __MODULE__.NormalizedIds

  def selected(row) do
    [
      row["selected_activity_id"],
      row["selected_activity_ids"],
      NormalizedIds.activity_id_value(row["selected_activity"]),
      get_in(row, ["selected_activity", "activity_id"]),
      get_in(row, ["selected_activity", "id"]),
      get_in(row, ["selected_activity", "timeline_identity", "activity_id"]),
      get_in(row, ["selected_activity", "timeline_identity", "id"])
    ]
    |> NormalizedIds.values_or_nil()
  end

  def review(row) do
    [
      row["activity_id"],
      row["review_activity_ids"],
      row["source_activity_id"],
      row["replacement_activity_id"],
      row["source_activity_ids"],
      row["replacement_activity_ids"],
      NormalizedIds.activity_id_value(row["source_activity"]),
      NormalizedIds.activity_id_value(row["replacement_activity"]),
      get_in(row, ["source_timeline_diff", "source_activity_id"]),
      get_in(row, ["source_timeline_diff", "replacement_activity_id"])
    ]
    |> NormalizedIds.values()
  end
end
