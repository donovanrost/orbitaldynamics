defmodule OrbitalDynamics.CampaignPlanner.CandidateSourceDiffReplayRisk do
  @moduledoc false

  def candidate_diff(%{"branch_local_diff_pressure" => true} = replay_summary) do
    [
      %{
        "type" => "candidate_diff_pressure",
        "severity" => "medium",
        "reason" =>
          "candidate source candidate-diff replay reports new, invalidated, semantic-change, candidate-routing, or station-routing pressure",
        "contract" => Map.get(replay_summary, "contract"),
        "source_report_count" => Map.get(replay_summary, "source_report_count"),
        "source_report_row_count" => Map.get(replay_summary, "source_report_row_count"),
        "source_report_paths" => Map.get(replay_summary, "source_report_paths"),
        "retained_candidate_count" => Map.get(replay_summary, "retained_candidate_count"),
        "new_candidate_count" => Map.get(replay_summary, "new_candidate_count"),
        "invalidated_candidate_count" => Map.get(replay_summary, "invalidated_candidate_count"),
        "diff_reason_counts" => Map.get(replay_summary, "diff_reason_counts"),
        "invalidated_reason_counts" => Map.get(replay_summary, "invalidated_reason_counts"),
        "semantic_change_reason_counts" =>
          Map.get(replay_summary, "semantic_change_reason_counts"),
        "candidate_diff_changed_field_counts" =>
          Map.get(replay_summary, "candidate_diff_changed_field_counts"),
        "candidate_diff_candidate_id_counts" =>
          Map.get(replay_summary, "candidate_diff_candidate_id_counts"),
        "candidate_diff_ground_station_counts" =>
          Map.get(replay_summary, "candidate_diff_ground_station_counts"),
        "trust_boundary_status" => Map.get(replay_summary, "trust_boundary_status"),
        "trust_boundaries" => Map.get(replay_summary, "trust_boundaries"),
        "branch_local_new_candidate_pressure" =>
          Map.get(replay_summary, "branch_local_new_candidate_pressure"),
        "branch_local_invalidated_candidate_pressure" =>
          Map.get(replay_summary, "branch_local_invalidated_candidate_pressure"),
        "branch_local_semantic_change_pressure" =>
          Map.get(replay_summary, "branch_local_semantic_change_pressure"),
        "feedback_source" => "candidate_source.candidate_diff_replay_summary",
        "feedback_scope" => "candidate_diff",
        "assumptions" => Map.get(replay_summary, "assumptions")
      }
      |> compact_map()
    ]
  end

  def candidate_diff(_replay_summary), do: []

  def timeline_diff(%{"branch_local_timeline_diff_pressure" => true} = replay_summary) do
    [
      %{
        "type" => "timeline_diff_pressure",
        "severity" => "high",
        "reason" =>
          "candidate source timeline-diff replay reports duplicate-identity, removed/changed activity, operator-review, or activity-routing pressure",
        "contract" => Map.get(replay_summary, "contract"),
        "source_report_count" => Map.get(replay_summary, "source_report_count"),
        "source_report_row_count" => Map.get(replay_summary, "source_report_row_count"),
        "source_report_paths" => Map.get(replay_summary, "source_report_paths"),
        "duplicate_timeline_identity_count" =>
          Map.get(replay_summary, "duplicate_timeline_identity_count"),
        "duplicate_source_timeline_identity_count" =>
          Map.get(replay_summary, "duplicate_source_timeline_identity_count"),
        "duplicate_replacement_timeline_identity_count" =>
          Map.get(replay_summary, "duplicate_replacement_timeline_identity_count"),
        "removed_downlink_count" => Map.get(replay_summary, "removed_downlink_count"),
        "removed_observation_count" => Map.get(replay_summary, "removed_observation_count"),
        "changed_downlink_shortfall_count" =>
          Map.get(replay_summary, "changed_downlink_shortfall_count"),
        "changed_contact_feedback_count" =>
          Map.get(replay_summary, "changed_contact_feedback_count"),
        "changed_observation_count" => Map.get(replay_summary, "changed_observation_count"),
        "changed_observation_quality_feedback_count" =>
          Map.get(replay_summary, "changed_observation_quality_feedback_count"),
        "changed_command_feedback_count" =>
          Map.get(replay_summary, "changed_command_feedback_count"),
        "changed_maneuver_feedback_count" =>
          Map.get(replay_summary, "changed_maneuver_feedback_count"),
        "diff_status_counts" => Map.get(replay_summary, "diff_status_counts"),
        "required_operator_action_counts" =>
          Map.get(replay_summary, "required_operator_action_counts"),
        "duplicate_timeline_identity_scope_counts" =>
          Map.get(replay_summary, "duplicate_timeline_identity_scope_counts"),
        "source_activity_id_counts" => Map.get(replay_summary, "source_activity_id_counts"),
        "replacement_activity_id_counts" =>
          Map.get(replay_summary, "replacement_activity_id_counts"),
        "trust_boundary_status" => Map.get(replay_summary, "trust_boundary_status"),
        "trust_boundaries" => Map.get(replay_summary, "trust_boundaries"),
        "branch_local_duplicate_identity_pressure" =>
          Map.get(replay_summary, "branch_local_duplicate_identity_pressure"),
        "branch_local_removed_activity_pressure" =>
          Map.get(replay_summary, "branch_local_removed_activity_pressure"),
        "branch_local_changed_activity_pressure" =>
          Map.get(replay_summary, "branch_local_changed_activity_pressure"),
        "branch_local_activity_routing_pressure" =>
          Map.get(replay_summary, "branch_local_activity_routing_pressure"),
        "branch_local_operator_review_pressure" =>
          Map.get(replay_summary, "branch_local_operator_review_pressure"),
        "feedback_source" => "candidate_source.timeline_diff_replay_summary",
        "feedback_scope" => "timeline_diff",
        "assumptions" => Map.get(replay_summary, "assumptions")
      }
      |> compact_map()
    ]
  end

  def timeline_diff(_replay_summary), do: []

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
