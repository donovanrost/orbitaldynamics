defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionCollectionDirectReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPrecondition

  def reports(refresh) do
    [
      {"accepted_planning_state.source_timeline_activity_precondition_summary",
       get_in(refresh, [
         "accepted_planning_state",
         "source_timeline_activity_precondition_summary"
       ])},
      {"accepted_planning_state.timeline_activity_precondition_summary",
       get_in(refresh, ["accepted_planning_state", "timeline_activity_precondition_summary"])},
      {"mission_state.source_timeline_activity_precondition_summary",
       get_in(refresh, ["mission_state", "source_timeline_activity_precondition_summary"])},
      {"mission_state.timeline_activity_precondition_summary",
       get_in(refresh, ["mission_state", "timeline_activity_precondition_summary"])},
      {"source_timeline_activity_precondition_summary",
       Map.get(refresh, "source_timeline_activity_precondition_summary")},
      {"timeline_activity_precondition_summary",
       Map.get(refresh, "timeline_activity_precondition_summary")}
    ]
    |> Enum.flat_map(fn {path, summary_or_summaries} ->
      TimelineActivityPrecondition.entries(path, summary_or_summaries)
    end)
  end
end
