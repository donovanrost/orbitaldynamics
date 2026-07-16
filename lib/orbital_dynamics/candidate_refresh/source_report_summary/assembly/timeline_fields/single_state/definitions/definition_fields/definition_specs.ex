defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Assembly.TimelineFields.SingleState.Definitions.DefinitionFields.DefinitionSpecs do
  @moduledoc false

  def all do
    [
      {"timeline_activity_status_state", "timeline_activity_status_state.v1",
       "artifact_only_timeline_activity_status_state", "activity_status_state_application",
       "not_granted_by_timeline_activity_status_state_replay_summary"},
      {"timeline_activity_approval_state", "timeline_activity_approval_state.v1",
       "artifact_only_timeline_activity_approval_state", "activity_approval_state_application",
       "not_granted_by_timeline_activity_approval_state_replay_summary"}
    ]
  end
end
