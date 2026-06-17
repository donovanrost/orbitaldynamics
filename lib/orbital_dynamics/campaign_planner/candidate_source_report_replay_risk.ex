defmodule OrbitalDynamics.CampaignPlanner.CandidateSourceReportReplayRisk do
  @moduledoc false

  def command_window(%{"branch_local_command_window_pressure" => true} = replay_summary) do
    [
      %{
        "type" => "command_window_pressure",
        "severity" => "medium",
        "reason" =>
          "candidate source command-window replay reports command feedback, routing, or operator-action pressure",
        "source_report_count" => Map.get(replay_summary, "source_report_count"),
        "source_report_row_count" => Map.get(replay_summary, "source_report_row_count"),
        "source_report_paths" => Map.get(replay_summary, "source_report_paths"),
        "command_feedback_count" => Map.get(replay_summary, "command_feedback_count"),
        "input_keys" => Map.get(replay_summary, "input_keys"),
        "direction_counts" => Map.get(replay_summary, "direction_counts"),
        "activity_ids_by_direction" => Map.get(replay_summary, "activity_ids_by_direction"),
        "window_ids_by_direction" => Map.get(replay_summary, "window_ids_by_direction"),
        "direction_routing" => Map.get(replay_summary, "direction_routing"),
        "required_operator_action_counts" =>
          Map.get(replay_summary, "required_operator_action_counts"),
        "trust_boundary_status" => Map.get(replay_summary, "trust_boundary_status"),
        "trust_boundaries" => Map.get(replay_summary, "trust_boundaries"),
        "branch_local_command_feedback_pressure" =>
          Map.get(replay_summary, "branch_local_command_feedback_pressure"),
        "branch_local_command_window_action_pressure" =>
          Map.get(replay_summary, "branch_local_command_window_action_pressure"),
        "feedback_source" => "candidate_source.command_window_replay_summary",
        "feedback_scope" => "command_window",
        "assumptions" => Map.get(replay_summary, "assumptions")
      }
      |> compact_map()
    ]
  end

  def command_window(_replay_summary), do: []

  def objective_gap(%{"branch_local_objective_gap_pressure" => true} = replay_summary) do
    [
      %{
        "type" => "objective_gap_pressure",
        "severity" => "medium",
        "reason" =>
          "candidate source objective-gap replay reports downlink, target, collection-latency, status, score-term, or routing pressure",
        "contracts" => Map.get(replay_summary, "contracts"),
        "source_report_count" => Map.get(replay_summary, "source_report_count"),
        "source_report_row_count" => Map.get(replay_summary, "source_report_row_count"),
        "source_report_paths" => Map.get(replay_summary, "source_report_paths"),
        "routed_gap_signal_count" => Map.get(replay_summary, "routed_gap_signal_count"),
        "downlink_gap_row_count" => Map.get(replay_summary, "downlink_gap_row_count"),
        "target_gap_row_count" => Map.get(replay_summary, "target_gap_row_count"),
        "collection_latency_gap_row_count" =>
          Map.get(replay_summary, "collection_latency_gap_row_count"),
        "objective_satisfaction_gap_row_count" =>
          Map.get(replay_summary, "objective_satisfaction_gap_row_count"),
        "objective_satisfaction_status_counts" =>
          Map.get(replay_summary, "objective_satisfaction_status_counts"),
        "objective_satisfaction_objective_type_counts" =>
          Map.get(replay_summary, "objective_satisfaction_objective_type_counts"),
        "objective_tradeoff_downlink_gap_row_count" =>
          Map.get(replay_summary, "objective_tradeoff_downlink_gap_row_count"),
        "objective_tradeoff_target_gap_row_count" =>
          Map.get(replay_summary, "objective_tradeoff_target_gap_row_count"),
        "objective_tradeoff_collection_latency_gap_row_count" =>
          Map.get(replay_summary, "objective_tradeoff_collection_latency_gap_row_count"),
        "score_term_downlink_gap_row_count" =>
          Map.get(replay_summary, "score_term_downlink_gap_row_count"),
        "score_term_target_gap_row_count" =>
          Map.get(replay_summary, "score_term_target_gap_row_count"),
        "score_term_collection_latency_gap_row_count" =>
          Map.get(replay_summary, "score_term_collection_latency_gap_row_count"),
        "score_term_key_counts" => Map.get(replay_summary, "score_term_key_counts"),
        "ground_station_counts" => Map.get(replay_summary, "ground_station_counts"),
        "target_counts" => Map.get(replay_summary, "target_counts"),
        "collection_counts" => Map.get(replay_summary, "collection_counts"),
        "source_activity_id_counts" => Map.get(replay_summary, "source_activity_id_counts"),
        "trust_boundary_status_counts" => Map.get(replay_summary, "trust_boundary_status_counts"),
        "trust_boundaries" => Map.get(replay_summary, "trust_boundaries"),
        "branch_local_downlink_gap_pressure" =>
          Map.get(replay_summary, "branch_local_downlink_gap_pressure"),
        "branch_local_target_gap_pressure" =>
          Map.get(replay_summary, "branch_local_target_gap_pressure"),
        "branch_local_collection_latency_gap_pressure" =>
          Map.get(replay_summary, "branch_local_collection_latency_gap_pressure"),
        "branch_local_objective_status_pressure" =>
          Map.get(replay_summary, "branch_local_objective_status_pressure"),
        "branch_local_score_term_pressure" =>
          Map.get(replay_summary, "branch_local_score_term_pressure"),
        "branch_local_routing_pressure" =>
          Map.get(replay_summary, "branch_local_routing_pressure"),
        "feedback_source" => "candidate_source.objective_gap_replay_summary",
        "feedback_scope" => "objective_gap",
        "assumptions" => Map.get(replay_summary, "assumptions")
      }
      |> compact_map()
    ]
  end

  def objective_gap(_replay_summary), do: []

  def timeline_feedback(%{"branch_local_timeline_feedback_pressure" => true} = replay_summary) do
    [
      %{
        "type" => "timeline_feedback_pressure",
        "severity" => "medium",
        "reason" =>
          "candidate source timeline-feedback replay reports feedback input, status, match, import, activity-routing, or station-reservation pressure",
        "contract" => Map.get(replay_summary, "contract"),
        "source_report_count" => Map.get(replay_summary, "source_report_count"),
        "source_report_row_count" => Map.get(replay_summary, "source_report_row_count"),
        "source_report_paths" => Map.get(replay_summary, "source_report_paths"),
        "input_keys" => Map.get(replay_summary, "input_keys"),
        "status_counts" => Map.get(replay_summary, "status_counts"),
        "feedback_kind_counts" => Map.get(replay_summary, "feedback_kind_counts"),
        "match_strategy_counts" => Map.get(replay_summary, "match_strategy_counts"),
        "activity_id_counts" => Map.get(replay_summary, "activity_id_counts"),
        "cadence_import_status_counts" => Map.get(replay_summary, "cadence_import_status_counts"),
        "station_reservation_evidence_row_count" =>
          Map.get(replay_summary, "station_reservation_evidence_row_count"),
        "station_reservation_expiration_evidence_row_count" =>
          Map.get(replay_summary, "station_reservation_expiration_evidence_row_count"),
        "trust_boundary_status" => Map.get(replay_summary, "trust_boundary_status"),
        "trust_boundaries" => Map.get(replay_summary, "trust_boundaries"),
        "branch_local_feedback_input_pressure" =>
          Map.get(replay_summary, "branch_local_feedback_input_pressure"),
        "branch_local_activity_routing_pressure" =>
          Map.get(replay_summary, "branch_local_activity_routing_pressure"),
        "branch_local_match_review_pressure" =>
          Map.get(replay_summary, "branch_local_match_review_pressure"),
        "branch_local_import_review_pressure" =>
          Map.get(replay_summary, "branch_local_import_review_pressure"),
        "branch_local_station_reservation_pressure" =>
          Map.get(replay_summary, "branch_local_station_reservation_pressure"),
        "feedback_source" => "candidate_source.timeline_feedback_replay_summary",
        "feedback_scope" => "timeline_feedback",
        "assumptions" => Map.get(replay_summary, "assumptions")
      }
      |> compact_map()
    ]
  end

  def timeline_feedback(_replay_summary), do: []

  def operational_timeline(
        %{"branch_local_operational_timeline_pressure" => true} = replay_summary
      ) do
    [
      %{
        "type" => "operational_timeline_pressure",
        "severity" => "medium",
        "reason" =>
          "candidate source operational-timeline replay reports operational feedback, activity-routing, status, approval, import, integrity, or station-reservation pressure",
        "contract" => Map.get(replay_summary, "contract"),
        "source_report_count" => Map.get(replay_summary, "source_report_count"),
        "source_report_row_count" => Map.get(replay_summary, "source_report_row_count"),
        "source_report_paths" => Map.get(replay_summary, "source_report_paths"),
        "contact_feedback_count" => Map.get(replay_summary, "contact_feedback_count"),
        "command_feedback_count" => Map.get(replay_summary, "command_feedback_count"),
        "maneuver_feedback_count" => Map.get(replay_summary, "maneuver_feedback_count"),
        "observation_feedback_count" => Map.get(replay_summary, "observation_feedback_count"),
        "station_throughput_feedback_count" =>
          Map.get(replay_summary, "station_throughput_feedback_count"),
        "input_keys" => Map.get(replay_summary, "input_keys"),
        "operational_kind_counts" => Map.get(replay_summary, "operational_kind_counts"),
        "activity_id_counts" => Map.get(replay_summary, "activity_id_counts"),
        "activity_status_counts" => Map.get(replay_summary, "activity_status_counts"),
        "approval_status_counts" => Map.get(replay_summary, "approval_status_counts"),
        "required_operator_action_counts" =>
          Map.get(replay_summary, "required_operator_action_counts"),
        "cadence_import_status_counts" => Map.get(replay_summary, "cadence_import_status_counts"),
        "timeline_integrity_issue_count" =>
          Map.get(replay_summary, "timeline_integrity_issue_count"),
        "dependency_integrity_issue_count" =>
          Map.get(replay_summary, "dependency_integrity_issue_count"),
        "exclusivity_integrity_issue_count" =>
          Map.get(replay_summary, "exclusivity_integrity_issue_count"),
        "timeline_integrity_issue_type_counts" =>
          Map.get(replay_summary, "timeline_integrity_issue_type_counts"),
        "station_reservation_evidence_row_count" =>
          Map.get(replay_summary, "station_reservation_evidence_row_count"),
        "station_reservation_expiration_evidence_row_count" =>
          Map.get(replay_summary, "station_reservation_expiration_evidence_row_count"),
        "trust_boundary_status" => Map.get(replay_summary, "trust_boundary_status"),
        "trust_boundaries" => Map.get(replay_summary, "trust_boundaries"),
        "branch_local_feedback_pressure" =>
          Map.get(replay_summary, "branch_local_feedback_pressure"),
        "branch_local_activity_routing_pressure" =>
          Map.get(replay_summary, "branch_local_activity_routing_pressure"),
        "branch_local_integrity_pressure" =>
          Map.get(replay_summary, "branch_local_integrity_pressure"),
        "branch_local_station_reservation_pressure" =>
          Map.get(replay_summary, "branch_local_station_reservation_pressure"),
        "feedback_source" => "candidate_source.operational_timeline_replay_summary",
        "feedback_scope" => "operational_timeline",
        "assumptions" => Map.get(replay_summary, "assumptions")
      }
      |> compact_map()
    ]
  end

  def operational_timeline(_replay_summary), do: []

  def maneuver_review(%{"branch_local_maneuver_review_pressure" => true} = replay_summary) do
    [
      %{
        "type" => "maneuver_review_pressure",
        "severity" => "medium",
        "reason" =>
          "candidate source maneuver-review replay reports maneuver feedback, execution-uncertainty, routing, or operator-action pressure",
        "source_report_count" => Map.get(replay_summary, "source_report_count"),
        "source_report_row_count" => Map.get(replay_summary, "source_report_row_count"),
        "source_report_paths" => Map.get(replay_summary, "source_report_paths"),
        "maneuver_success_feedback_count" =>
          Map.get(replay_summary, "maneuver_success_feedback_count"),
        "execution_uncertainty_declared_count" =>
          Map.get(replay_summary, "execution_uncertainty_declared_count"),
        "execution_uncertainty_missing_count" =>
          Map.get(replay_summary, "execution_uncertainty_missing_count"),
        "input_keys" => Map.get(replay_summary, "input_keys"),
        "maneuver_id_counts" => Map.get(replay_summary, "maneuver_id_counts"),
        "required_operator_action_counts" =>
          Map.get(replay_summary, "required_operator_action_counts"),
        "trust_boundary_status" => Map.get(replay_summary, "trust_boundary_status"),
        "trust_boundaries" => Map.get(replay_summary, "trust_boundaries"),
        "branch_local_maneuver_feedback_pressure" =>
          Map.get(replay_summary, "branch_local_maneuver_feedback_pressure"),
        "branch_local_maneuver_routing_pressure" =>
          Map.get(replay_summary, "branch_local_maneuver_routing_pressure"),
        "branch_local_maneuver_action_pressure" =>
          Map.get(replay_summary, "branch_local_maneuver_action_pressure"),
        "branch_local_execution_uncertainty_pressure" =>
          Map.get(replay_summary, "branch_local_execution_uncertainty_pressure"),
        "feedback_source" => "candidate_source.maneuver_review_replay_summary",
        "feedback_scope" => "maneuver_review",
        "assumptions" => Map.get(replay_summary, "assumptions")
      }
      |> compact_map()
    ]
  end

  def maneuver_review(_replay_summary), do: []

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
