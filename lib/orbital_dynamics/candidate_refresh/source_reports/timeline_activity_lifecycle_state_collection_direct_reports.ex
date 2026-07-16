defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityLifecycleStateCollectionDirectReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityLifecycleStateReports

  def reports(refresh) do
    [
      {"accepted_planning_state.source_timeline_activity_lifecycle_state",
       get_in(refresh, ["accepted_planning_state", "source_timeline_activity_lifecycle_state"])},
      {"accepted_planning_state.timeline_activity_lifecycle_state",
       get_in(refresh, ["accepted_planning_state", "timeline_activity_lifecycle_state"])},
      {"mission_state.source_timeline_activity_lifecycle_state",
       get_in(refresh, ["mission_state", "source_timeline_activity_lifecycle_state"])},
      {"mission_state.timeline_activity_lifecycle_state",
       get_in(refresh, ["mission_state", "timeline_activity_lifecycle_state"])},
      {"source_timeline_activity_lifecycle_state",
       Map.get(refresh, "source_timeline_activity_lifecycle_state")},
      {"timeline_activity_lifecycle_state", Map.get(refresh, "timeline_activity_lifecycle_state")}
    ]
    |> Enum.flat_map(fn {path, state_or_states} ->
      TimelineActivityLifecycleStateReports.entries(path, state_or_states)
    end)
  end
end
