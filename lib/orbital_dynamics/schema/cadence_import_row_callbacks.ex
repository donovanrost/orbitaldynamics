defmodule OrbitalDynamics.Schema.CadenceImportRowCallbacks do
  @moduledoc false

  def build(local) when is_list(local) do
    [
      validate_station_calendar_handoff_count_lists:
        &OrbitalDynamics.Schema.StationCalendarHandoffContracts.validate_count_lists/3,
      validate_contact_allocation_capacity_pack_group:
        fetch!(local, :validate_contact_allocation_capacity_pack_group),
      validate_contact_allocation_capacity_pack_handoff_matches_source:
        &OrbitalDynamics.Schema.ContactAllocationHandoffContracts.validate_capacity_pack_matches_source/3,
      validate_station_capacity_fraction_fields:
        &OrbitalDynamics.Schema.HandoffFieldContracts.validate_station_capacity_fraction_fields/3,
      validate_suppression_duplicate_handoff_row_fields:
        &OrbitalDynamics.Schema.SuppressionHandoffContracts.validate_duplicate_row_fields/3,
      validate_scoped_downlink_context_fields:
        &OrbitalDynamics.Schema.ScopedDownlinkContextContracts.validate/3,
      validate_observation_quality_handoff_fields:
        &OrbitalDynamics.Schema.HandoffFieldContracts.validate_observation_quality_handoff_fields/3,
      validate_feedback_maneuver_handoff_fields:
        &OrbitalDynamics.Schema.HandoffFieldContracts.validate_feedback_maneuver_handoff_fields/3,
      validate_link_handoff_fields:
        &OrbitalDynamics.Schema.HandoffFieldContracts.validate_link_handoff_fields/3,
      validate_resource_availability_variance_fields:
        &OrbitalDynamics.Schema.HandoffFieldContracts.validate_resource_availability_variance_fields/3,
      validate_eclipse_lighting_handoff_fields:
        &OrbitalDynamics.Schema.HandoffFieldContracts.validate_eclipse_lighting_handoff_fields/3,
      validate_thermal_handoff_fields:
        &OrbitalDynamics.Schema.HandoffFieldContracts.validate_thermal_handoff_fields/3,
      validate_branch_event_summary_fields:
        &OrbitalDynamics.Schema.BranchEventContracts.validate_summary_fields/3,
      validate_semantic_change_details:
        &OrbitalDynamics.Schema.CandidateDiffContracts.validate_semantic_change_details/3,
      validate_candidate_diff_changed_fields:
        &OrbitalDynamics.Schema.CandidateDiffContracts.validate_changed_fields/3,
      validate_optional_policy_decision_evidence:
        fetch!(local, :validate_optional_policy_decision_evidence),
      validate_optional_policy_escalation: fetch!(local, :validate_optional_policy_escalation),
      validate_optional_candidate_rejection_source_row:
        fetch!(local, :validate_optional_candidate_rejection_source_row),
      validate_optional_branch_comparison_source_row:
        fetch!(local, :validate_optional_branch_comparison_source_row),
      validate_source_evidence_fields: fetch!(local, :validate_source_evidence_fields),
      validate_source_operational_readiness_report_handoff_matches:
        &OrbitalDynamics.Schema.OperationalReadinessHandoffContracts.validate_report_matches_source/3,
      validate_source_quality_gate_report_handoff_matches:
        &OrbitalDynamics.Schema.QualityGateHandoffContracts.validate_report_matches_source/3,
      validate_freshness_source_status_matches:
        fetch!(local, :validate_freshness_source_status_matches),
      validate_refresh_budget_handoff_matches_source:
        &OrbitalDynamics.Schema.SourceReviewHandoffContracts.validate_refresh_budget_matches_source/3,
      validate_schema_validation_source_status_matches:
        fetch!(local, :validate_schema_validation_source_status_matches),
      validate_execution_source_status_matches:
        fetch!(local, :validate_execution_source_status_matches),
      validate_optional_source_window:
        &OrbitalDynamics.Schema.CandidateDiffContracts.validate_optional_source_window/4,
      validate_nested_id_match: fetch!(local, :validate_nested_id_match),
      validate_optional_source_window_lineage:
        &OrbitalDynamics.Schema.CandidateDiffContracts.validate_optional_source_window_lineage/4,
      validate_optional_activity_context: fetch!(local, :validate_optional_activity_context),
      validate_optional_timeline_link: fetch!(local, :validate_optional_timeline_link),
      validate_optional_timeline_identity: fetch!(local, :validate_optional_timeline_identity),
      validate_cadence_source_review_row: fetch!(local, :validate_cadence_source_review_row),
      validate_operational_readiness_resource_context:
        fetch!(local, :validate_operational_readiness_resource_context),
      validate_operational_readiness_cadence_import_context:
        fetch!(local, :validate_operational_readiness_cadence_import_context)
    ]
  end

  defp fetch!(local, name), do: Keyword.fetch!(local, name)
end
