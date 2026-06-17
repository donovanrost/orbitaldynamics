defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineTransitionApplication.Summary.TransitionFields do
  @moduledoc false

  def fields(transition_summary) do
    %{
      "selected_timeline_integrity_issue_type_counts" =>
        Map.get(transition_summary, "selected_timeline_integrity_issue_type_counts", %{}),
      "selected_activity_id_counts" =>
        Map.get(transition_summary, "selected_activity_id_counts", %{}),
      "review_activity_id_counts" =>
        Map.get(transition_summary, "review_activity_id_counts", %{}),
      "application_status_counts" =>
        Map.get(transition_summary, "application_status_counts", %{}),
      "transition_decision_counts" =>
        Map.get(transition_summary, "transition_decision_counts", %{}),
      "required_operator_action_counts" =>
        Map.get(transition_summary, "required_operator_action_counts", %{}),
      "duplicate_timeline_identity_scope_counts" =>
        Map.get(transition_summary, "duplicate_timeline_identity_scope_counts", %{})
    }
  end
end
