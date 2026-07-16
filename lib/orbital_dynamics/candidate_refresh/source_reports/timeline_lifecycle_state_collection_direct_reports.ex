defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineLifecycleStateCollectionDirectReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineLifecycleState

  def reports(refresh) do
    [
      {"accepted_planning_state.source_timeline_lifecycle_state_summary",
       get_in(refresh, ["accepted_planning_state", "source_timeline_lifecycle_state_summary"])},
      {"accepted_planning_state.timeline_lifecycle_state_summary",
       get_in(refresh, ["accepted_planning_state", "timeline_lifecycle_state_summary"])},
      {"mission_state.source_timeline_lifecycle_state_summary",
       get_in(refresh, ["mission_state", "source_timeline_lifecycle_state_summary"])},
      {"mission_state.timeline_lifecycle_state_summary",
       get_in(refresh, ["mission_state", "timeline_lifecycle_state_summary"])},
      {"source_timeline_lifecycle_state_summary",
       Map.get(refresh, "source_timeline_lifecycle_state_summary")},
      {"timeline_lifecycle_state_summary", Map.get(refresh, "timeline_lifecycle_state_summary")}
    ]
    |> Enum.flat_map(fn {path, summary_or_summaries} ->
      TimelineLifecycleState.entries(path, summary_or_summaries)
    end)
  end
end
