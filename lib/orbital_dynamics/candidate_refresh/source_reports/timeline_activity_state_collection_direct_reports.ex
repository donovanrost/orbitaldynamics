defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityStateCollectionDirectReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityStateCollectionArtifactReports

  def reports(refresh) do
    [
      {"accepted_planning_state.source_timeline_activity_state",
       get_in(refresh, ["accepted_planning_state", "source_timeline_activity_state"])},
      {"accepted_planning_state.timeline_activity_state",
       get_in(refresh, ["accepted_planning_state", "timeline_activity_state"])},
      {"accepted_planning_state.source_timeline_activity_status_state",
       get_in(refresh, ["accepted_planning_state", "source_timeline_activity_status_state"])},
      {"accepted_planning_state.timeline_activity_status_state",
       get_in(refresh, ["accepted_planning_state", "timeline_activity_status_state"])},
      {"accepted_planning_state.source_timeline_activity_approval_state",
       get_in(refresh, ["accepted_planning_state", "source_timeline_activity_approval_state"])},
      {"accepted_planning_state.timeline_activity_approval_state",
       get_in(refresh, ["accepted_planning_state", "timeline_activity_approval_state"])},
      {"mission_state.source_timeline_activity_state",
       get_in(refresh, ["mission_state", "source_timeline_activity_state"])},
      {"mission_state.timeline_activity_state",
       get_in(refresh, ["mission_state", "timeline_activity_state"])},
      {"mission_state.source_timeline_activity_status_state",
       get_in(refresh, ["mission_state", "source_timeline_activity_status_state"])},
      {"mission_state.timeline_activity_status_state",
       get_in(refresh, ["mission_state", "timeline_activity_status_state"])},
      {"mission_state.source_timeline_activity_approval_state",
       get_in(refresh, ["mission_state", "source_timeline_activity_approval_state"])},
      {"mission_state.timeline_activity_approval_state",
       get_in(refresh, ["mission_state", "timeline_activity_approval_state"])},
      {"source_timeline_activity_state", Map.get(refresh, "source_timeline_activity_state")},
      {"timeline_activity_state", Map.get(refresh, "timeline_activity_state")},
      {"source_timeline_activity_status_state",
       Map.get(refresh, "source_timeline_activity_status_state")},
      {"timeline_activity_status_state", Map.get(refresh, "timeline_activity_status_state")},
      {"source_timeline_activity_approval_state",
       Map.get(refresh, "source_timeline_activity_approval_state")},
      {"timeline_activity_approval_state", Map.get(refresh, "timeline_activity_approval_state")}
    ]
    |> Enum.flat_map(fn {path, state_or_states} ->
      TimelineActivityStateCollectionArtifactReports.entries(path, state_or_states)
    end)
  end
end
