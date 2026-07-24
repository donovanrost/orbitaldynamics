defmodule OrbitalDynamics.CampaignPlanner.PressureRiskFields do
  @moduledoc false

  alias __MODULE__.{Communications, Governance, OperationalFeedback, SourceReports, Timeline}

  def fields(:relay_data_path), do: relay_data_path()
  def fields(:resource_margin), do: resource_margin()
  def fields(:validation_refresh), do: validation_refresh()
  def fields(:candidate_rejection), do: candidate_rejection()
  def fields(:command_window), do: command_window()
  def fields(:objective_gap), do: objective_gap()
  def fields(:timeline_feedback), do: timeline_feedback()
  def fields(:operational_timeline), do: operational_timeline()
  def fields(:maneuver_review), do: maneuver_review()
  def fields(:candidate_diff), do: candidate_diff()
  def fields(:timeline_diff), do: timeline_diff()
  def fields(:timeline_dependency_impact), do: timeline_dependency_impact()
  def fields(:timeline_publication), do: timeline_publication()
  def fields(:timeline_lifecycle_state), do: timeline_lifecycle_state()
  def fields(:timeline_activity_precondition), do: timeline_activity_precondition()
  def fields(:timeline_activity_lifecycle_state), do: timeline_activity_lifecycle_state()
  def fields(:timeline_preservation), do: timeline_preservation()
  def fields(:operational_readiness), do: operational_readiness()
  def fields(:quality_gate), do: quality_gate()
  def fields(:provider_counteroffer), do: provider_counteroffer()
  def fields(:approval_boundary), do: approval_boundary()
  def fields(:provider_reservation_request), do: provider_reservation_request()
  def fields(:capacity_pack), do: capacity_pack()
  def fields(:station_reservation_conflict), do: station_reservation_conflict()

  def fields(:station_reservation_hold_import_readiness),
    do: station_reservation_hold_import_readiness()

  def fields(:operational_feedback), do: operational_feedback()

  def relay_data_path do
    [
      "ground_station_id",
      "route_id",
      "route_ids",
      "source_spacecraft_id",
      "source_spacecraft_ids",
      "relay_spacecraft_ids",
      "relay_chain_spacecraft_ids",
      "relay_hop_count",
      "ground_downlink_contact_id",
      "ground_downlink_contact_ids",
      "custody_status",
      "latency_s",
      "latency_limit_s",
      "latency_status",
      "risk_status",
      "risk_reasons",
      "product_ids",
      "collection_ids",
      "route_count",
      "relay_route_count",
      "direct_downlink_route_count",
      "custody_status_counts",
      "latency_status_counts",
      "risk_status_counts",
      "route_ids_by_custody_status",
      "route_ids_by_latency_status",
      "route_ids_by_risk_status",
      "route_ids_by_ground_station_id",
      "feedback_source",
      "feedback_scope",
      "feedback_key",
      "trust_boundary",
      "derivation_reasons",
      "assumptions"
    ]
  end

  def resource_margin do
    [
      "type",
      "spacecraft_id",
      "scenario_id",
      "timeline_id",
      "source_activity_id",
      "replacement_activity_id",
      "source_activity_ids",
      "resource_margin_risk_type",
      "resource_field",
      "resource_margin_value",
      "resource_margin_threshold",
      "resource_margin_field_value",
      "suppressed_reason",
      "source_quality",
      "resource_trust_boundary_status",
      "operator_training_requirement_count",
      "required_operator_roles",
      "starts_at_s",
      "ends_at_s",
      "diff_status",
      "changed_fields",
      "required_operator_action",
      "requires_operator_review",
      "feedback_source",
      "feedback_scope",
      "feedback_key",
      "trust_boundary",
      "derivation_reasons"
    ]
  end

  def validation_refresh, do: Governance.validation_refresh()

  def candidate_rejection, do: SourceReports.candidate_rejection()

  def command_window, do: SourceReports.command_window()

  def objective_gap, do: SourceReports.objective_gap()

  def timeline_feedback, do: Timeline.timeline_feedback()

  def operational_timeline, do: Timeline.operational_timeline()

  def maneuver_review, do: SourceReports.maneuver_review()

  def candidate_diff, do: SourceReports.candidate_diff()

  def timeline_diff, do: Timeline.timeline_diff()

  def timeline_dependency_impact, do: Timeline.timeline_dependency_impact()

  def timeline_publication, do: Timeline.timeline_publication()

  def timeline_lifecycle_state, do: Timeline.timeline_lifecycle_state()

  def timeline_activity_precondition, do: Timeline.timeline_activity_precondition()

  def timeline_activity_lifecycle_state, do: Timeline.timeline_activity_lifecycle_state()

  def timeline_preservation, do: Timeline.timeline_preservation()

  def operational_readiness, do: Governance.operational_readiness()

  def quality_gate, do: Governance.quality_gate()

  def provider_counteroffer, do: Governance.provider_counteroffer()

  def approval_boundary, do: Governance.approval_boundary()

  def provider_reservation_request, do: Communications.provider_reservation_request()

  def capacity_pack, do: Communications.capacity_pack()

  def station_reservation_conflict, do: Communications.station_reservation_conflict()

  def station_reservation_hold_import_readiness,
    do: Communications.station_reservation_hold_import_readiness()

  def operational_feedback, do: OperationalFeedback.operational_feedback()
end
