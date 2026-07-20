defmodule OrbitalDynamics.RecommendationRiskContext do
  @moduledoc false

  alias OrbitalDynamics.RecommendationRiskContext.{
    ContactAllocation,
    ContactIntent,
    ExecutionSuccessFeedback,
    ManeuverExecutionUncertainty,
    ObjectiveSatisfaction,
    ObjectiveTradeoff,
    OperationalFeedback,
    RelayDataPath,
    ResourceProjection,
    ScoreTerm,
    StationCalendar,
    StationReservationHoldImportReadiness,
    TimelineActivityPrecondition,
    TimelineActivityLifecycleState,
    TimelineLifecycleState,
    TimelinePublication,
    ValidationRefresh
  }

  @approval_boundary_context_keys [
    "approval_boundary_ids",
    "approval_boundary_statuses",
    "approval_boundary_reasons",
    "automation_boundaries",
    "execution_boundaries",
    "approval_boundary_import_classifications",
    "approval_boundary_required_operator_actions",
    "approval_boundary_required_authorities",
    "approval_boundary_policy_bundle_ids",
    "approval_boundary_rule_ids",
    "approval_boundary_feedback_sources",
    "approval_boundary_feedback_scopes",
    "approval_boundary_feedback_keys",
    "approval_boundary_trust_boundaries"
  ]

  @provider_reservation_request_context_keys [
    "provider_reservation_request_contact_ids",
    "provider_reservation_request_source_activity_ids",
    "provider_reservation_request_ground_station_ids",
    "provider_reservation_request_directions",
    "provider_reservation_request_station_reservation_ids",
    "provider_reservation_request_station_reserved_by",
    "provider_reservation_request_station_reservation_statuses",
    "provider_reservation_request_station_reservation_match_statuses",
    "provider_reservation_request_statuses",
    "provider_reservation_request_row_scopes",
    "provider_reservation_request_required_operator_actions",
    "provider_reservation_request_assumption_maps",
    "provider_reservation_request_feedback_sources",
    "provider_reservation_request_feedback_scopes",
    "provider_reservation_request_trust_boundaries"
  ]

  @capacity_pack_context_keys [
    "capacity_pack_risk_contact_ids",
    "capacity_pack_risk_source_activity_ids",
    "capacity_pack_risk_ground_station_ids",
    "capacity_pack_risk_group_ids",
    "capacity_pack_risk_statuses",
    "capacity_pack_risk_capacity_fraction_values",
    "capacity_pack_risk_used_fraction_values",
    "capacity_pack_risk_unused_fraction_values",
    "capacity_pack_risk_required_capacity_fraction_values",
    "capacity_pack_risk_required_capacity_fraction_sources",
    "capacity_pack_risk_derivation_reasons",
    "capacity_pack_risk_feedback_sources",
    "capacity_pack_risk_feedback_scopes",
    "capacity_pack_risk_trust_boundaries"
  ]

  @contact_contention_resolution_context_keys [
    "contact_contention_resolution_pressure_risk_types",
    "contact_contention_resolution_pressure_contact_ids",
    "contact_contention_resolution_pressure_selected_contact_ids",
    "contact_contention_resolution_pressure_scenario_ids",
    "contact_contention_resolution_pressure_spacecraft_ids",
    "contact_contention_resolution_pressure_ground_station_ids",
    "contact_contention_resolution_pressure_source_activity_ids",
    "contact_contention_resolution_pressure_source_window_ids",
    "contact_contention_resolution_pressure_required_contact_values",
    "contact_contention_resolution_pressure_planned_contact_values",
    "contact_contention_resolution_pressure_required_downlink_values_mb",
    "contact_contention_resolution_pressure_planned_downlink_values_mb",
    "contact_contention_resolution_pressure_start_values_s",
    "contact_contention_resolution_pressure_end_values_s",
    "contact_contention_resolution_pressure_selected_priority_sources",
    "contact_contention_resolution_pressure_selection_reasons",
    "contact_contention_resolution_pressure_resolution_selection_rules",
    "contact_contention_resolution_pressure_priority_override_count_values",
    "contact_contention_resolution_pressure_priority_override_contact_ids",
    "contact_contention_resolution_pressure_review_statuses",
    "contact_contention_resolution_pressure_downlink_demand_sources",
    "contact_contention_resolution_pressure_downlink_completion_sources",
    "contact_contention_resolution_pressure_feedback_sources",
    "contact_contention_resolution_pressure_feedback_scopes",
    "contact_contention_resolution_pressure_trust_boundaries",
    "contact_contention_resolution_pressure_derivation_reasons"
  ]

  @contact_contention_context_keys [
    "contact_contention_pressure_risk_types",
    "contact_contention_pressure_contact_ids",
    "contact_contention_pressure_scenario_ids",
    "contact_contention_pressure_spacecraft_ids",
    "contact_contention_pressure_ground_station_ids",
    "contact_contention_pressure_source_activity_ids",
    "contact_contention_pressure_source_window_ids",
    "contact_contention_pressure_required_contact_values",
    "contact_contention_pressure_planned_contact_values",
    "contact_contention_pressure_required_downlink_values_mb",
    "contact_contention_pressure_planned_downlink_values_mb",
    "contact_contention_pressure_start_values_s",
    "contact_contention_pressure_end_values_s",
    "contact_contention_pressure_group_ids",
    "contact_contention_pressure_resource_scopes",
    "contact_contention_pressure_contention_contact_ids",
    "contact_contention_pressure_required_operator_actions",
    "contact_contention_pressure_approval_statuses",
    "contact_contention_pressure_operator_action_reasons",
    "contact_contention_pressure_downlink_demand_sources",
    "contact_contention_pressure_downlink_completion_sources",
    "contact_contention_pressure_feedback_sources",
    "contact_contention_pressure_feedback_scopes",
    "contact_contention_pressure_trust_boundaries",
    "contact_contention_pressure_derivation_reasons"
  ]

  @station_reservation_conflict_context_keys [
    "station_reservation_conflict_contact_ids",
    "station_reservation_conflict_source_activity_ids",
    "station_reservation_conflict_ground_station_ids",
    "station_reservation_conflict_reservation_ids",
    "station_reservation_conflict_reserved_by",
    "station_reservation_conflict_statuses",
    "station_reservation_conflict_match_statuses",
    "station_reservation_conflict_expires_at_values_s",
    "station_reservation_conflict_derivation_reasons",
    "station_reservation_conflict_feedback_sources",
    "station_reservation_conflict_feedback_scopes",
    "station_reservation_conflict_trust_boundaries"
  ]

  @timeline_preservation_context_keys [
    "timeline_preservation_activity_ids",
    "timeline_preservation_timeline_ids",
    "timeline_preservation_statuses",
    "timeline_preservation_requires_preservation_values",
    "timeline_preservation_requires_operator_review_values",
    "timeline_preservation_protection_decisions",
    "timeline_preservation_protection_categories",
    "timeline_preservation_protection_reasons",
    "timeline_preservation_preserve_activity_count_values",
    "timeline_preservation_review_change_activity_count_values",
    "timeline_preservation_sensitive_activity_count_values",
    "timeline_preservation_preserve_activity_ids",
    "timeline_preservation_preserve_timeline_ids",
    "timeline_preservation_review_change_activity_ids",
    "timeline_preservation_review_change_timeline_ids",
    "timeline_preservation_sensitive_activity_ids",
    "timeline_preservation_sensitive_timeline_ids",
    "timeline_preservation_invalid_activity_input_values",
    "timeline_preservation_invalid_activity_input_reasons",
    "timeline_preservation_required_operator_actions",
    "timeline_preservation_feedback_sources",
    "timeline_preservation_feedback_scopes",
    "timeline_preservation_feedback_keys",
    "timeline_preservation_trust_boundaries",
    "timeline_preservation_derivation_reasons",
    "timeline_preservation_assumption_maps"
  ]

  @timeline_publication_context_keys [
    "timeline_publication_ids",
    "timeline_publication_sequences",
    "timeline_publication_statuses",
    "timeline_publication_downstream_invalidation_statuses",
    "timeline_publication_dependency_impact_statuses",
    "timeline_publication_source_artifact_ids",
    "timeline_publication_source_artifact_types",
    "timeline_publication_authorities",
    "timeline_publication_supersedes_artifact_ids",
    "timeline_publication_downstream_product_ids",
    "timeline_publication_invalidated_downstream_product_ids",
    "timeline_publication_downstream_invalidation_reason_count_maps",
    "timeline_publication_downstream_invalidation_reasons",
    "timeline_publication_invalidated_downstream_product_ids_by_reason",
    "timeline_publication_dependency_impact_row_count_values",
    "timeline_publication_timeline_diff_row_count_values",
    "timeline_publication_timeline_diff_changed_count_values",
    "timeline_publication_timeline_diff_review_required_count_values",
    "timeline_publication_changed_field_count_maps",
    "timeline_publication_changed_fields",
    "timeline_publication_changed_timeline_ids",
    "timeline_publication_review_timeline_ids",
    "timeline_publication_timeline_ids_by_changed_field",
    "timeline_publication_feedback_sources",
    "timeline_publication_feedback_scopes",
    "timeline_publication_feedback_keys",
    "timeline_publication_trust_boundaries",
    "timeline_publication_derivation_reasons",
    "timeline_publication_assumption_maps"
  ]

  @timeline_lifecycle_state_context_keys [
    "timeline_lifecycle_state_statuses",
    "timeline_lifecycle_state_planned_activity_count_values",
    "timeline_lifecycle_state_realized_activity_count_values",
    "timeline_lifecycle_state_row_count_values",
    "timeline_lifecycle_state_recordable_count_values",
    "timeline_lifecycle_state_preserved_count_values",
    "timeline_lifecycle_state_review_required_count_values",
    "timeline_lifecycle_state_duplicate_identity_count_values",
    "timeline_lifecycle_state_invalid_activity_input_count_values",
    "timeline_lifecycle_state_transition_decision_count_maps",
    "timeline_lifecycle_state_required_operator_action_count_maps",
    "timeline_lifecycle_state_operator_action_reason_count_maps",
    "timeline_lifecycle_state_import_action_count_maps",
    "timeline_lifecycle_state_planned_status_category_count_maps",
    "timeline_lifecycle_state_realized_status_category_count_maps",
    "timeline_lifecycle_state_status_transition_category_count_maps",
    "timeline_lifecycle_state_approval_transition_category_count_maps",
    "timeline_lifecycle_state_recordable_timeline_ids",
    "timeline_lifecycle_state_preserved_timeline_ids",
    "timeline_lifecycle_state_review_timeline_ids",
    "timeline_lifecycle_state_review_activity_ids",
    "timeline_lifecycle_state_invalid_activity_input_ids",
    "timeline_lifecycle_state_review_timeline_ids_by_required_operator_action",
    "timeline_lifecycle_state_review_timeline_ids_by_operator_action_reason",
    "timeline_lifecycle_state_review_timeline_ids_by_status_transition_category",
    "timeline_lifecycle_state_review_timeline_ids_by_approval_transition_category",
    "timeline_lifecycle_state_required_operator_actions",
    "timeline_lifecycle_state_requires_operator_review_values",
    "timeline_lifecycle_state_feedback_sources",
    "timeline_lifecycle_state_feedback_scopes",
    "timeline_lifecycle_state_feedback_keys",
    "timeline_lifecycle_state_trust_boundaries",
    "timeline_lifecycle_state_derivation_reasons",
    "timeline_lifecycle_state_assumption_maps"
  ]

  @timeline_dependency_impact_context_keys [
    "timeline_dependency_impact_activity_ids",
    "timeline_dependency_impact_timeline_ids",
    "timeline_dependency_impact_scopes",
    "timeline_dependency_impact_statuses",
    "timeline_dependency_impact_required_operator_actions",
    "timeline_dependency_impact_operator_action_reasons",
    "timeline_dependency_impact_dependency_activity_ids",
    "timeline_dependency_impact_dependency_timeline_ids",
    "timeline_dependency_impact_exclusive_with_activity_ids",
    "timeline_dependency_impact_exclusive_with_timeline_ids",
    "timeline_dependency_impact_impacted_dependency_activity_ids",
    "timeline_dependency_impact_impacted_dependency_timeline_ids",
    "timeline_dependency_impact_impacted_exclusive_with_activity_ids",
    "timeline_dependency_impact_impacted_exclusive_with_timeline_ids",
    "timeline_dependency_impact_feedback_sources",
    "timeline_dependency_impact_feedback_scopes",
    "timeline_dependency_impact_feedback_keys",
    "timeline_dependency_impact_trust_boundaries",
    "timeline_dependency_impact_derivation_reasons"
  ]

  @link_capacity_context_keys [
    "link_capacity_pressure_risk_types",
    "link_capacity_pressure_ground_station_ids",
    "link_capacity_pressure_required_contact_values",
    "link_capacity_pressure_planned_contact_values",
    "link_capacity_pressure_required_downlink_values_mb",
    "link_capacity_pressure_planned_downlink_values_mb",
    "link_capacity_pressure_start_values_s",
    "link_capacity_pressure_end_values_s",
    "link_capacity_pressure_source_activity_ids",
    "link_capacity_pressure_source_window_ids",
    "link_capacity_pressure_selected_capacity_adjusted_throughput_values_mb",
    "link_capacity_pressure_selected_downlink_shortfall_values_mb",
    "link_capacity_pressure_actual_throughput_values_mb",
    "link_capacity_pressure_actual_downlink_completion_ratio_values",
    "link_capacity_pressure_actual_downlink_shortfall_values_mb",
    "link_capacity_pressure_downlink_requirement_statuses",
    "link_capacity_pressure_actual_downlink_requirement_statuses",
    "link_capacity_pressure_downlink_demand_sources",
    "link_capacity_pressure_downlink_completion_sources",
    "link_capacity_pressure_feedback_sources",
    "link_capacity_pressure_feedback_scopes",
    "link_capacity_pressure_trust_boundaries",
    "link_capacity_pressure_derivation_reasons"
  ]

  @contact_filter_context_keys [
    "contact_filter_pressure_risk_types",
    "contact_filter_pressure_contact_ids",
    "contact_filter_pressure_scenario_ids",
    "contact_filter_pressure_spacecraft_ids",
    "contact_filter_pressure_ground_station_ids",
    "contact_filter_pressure_source_activity_ids",
    "contact_filter_pressure_source_window_ids",
    "contact_filter_pressure_required_contact_values",
    "contact_filter_pressure_planned_contact_values",
    "contact_filter_pressure_required_downlink_values_mb",
    "contact_filter_pressure_planned_downlink_values_mb",
    "contact_filter_pressure_start_values_s",
    "contact_filter_pressure_end_values_s",
    "contact_filter_pressure_suppressed_reasons",
    "contact_filter_pressure_review_statuses",
    "contact_filter_pressure_station_reservation_ids",
    "contact_filter_pressure_station_reserved_by",
    "contact_filter_pressure_station_reservation_statuses",
    "contact_filter_pressure_station_reservation_match_statuses",
    "contact_filter_pressure_station_calendar_entry_ids",
    "contact_filter_pressure_station_calendar_entry_statuses",
    "contact_filter_pressure_downlink_demand_sources",
    "contact_filter_pressure_downlink_completion_sources",
    "contact_filter_pressure_feedback_sources",
    "contact_filter_pressure_feedback_scopes",
    "contact_filter_pressure_trust_boundaries",
    "contact_filter_pressure_derivation_reasons"
  ]

  @resource_filter_context_keys [
    "resource_filter_pressure_risk_types",
    "resource_filter_pressure_scenario_ids",
    "resource_filter_pressure_spacecraft_ids",
    "resource_filter_pressure_resource_fields",
    "resource_filter_pressure_available_values",
    "resource_filter_pressure_source_activity_ids",
    "resource_filter_pressure_start_values_s",
    "resource_filter_pressure_end_values_s",
    "resource_filter_pressure_suppressed_reasons",
    "resource_filter_pressure_source_quality_values",
    "resource_filter_pressure_resource_trust_boundary_statuses",
    "resource_filter_pressure_fuel_margin_values",
    "resource_filter_pressure_fuel_margin_threshold_values",
    "resource_filter_pressure_power_margin_values",
    "resource_filter_pressure_power_margin_threshold_values",
    "resource_filter_pressure_storage_margin_values",
    "resource_filter_pressure_storage_margin_threshold_values",
    "resource_filter_pressure_downlink_margin_values",
    "resource_filter_pressure_downlink_margin_threshold_values",
    "resource_filter_pressure_thermal_margin_values_c",
    "resource_filter_pressure_thermal_margin_threshold_values_c",
    "resource_filter_pressure_operator_training_requirement_count_values",
    "resource_filter_pressure_required_operator_roles",
    "resource_filter_pressure_feedback_sources",
    "resource_filter_pressure_feedback_scopes",
    "resource_filter_pressure_trust_boundaries",
    "resource_filter_pressure_derivation_reasons"
  ]

  @resource_margin_context_keys [
    "resource_margin_risk_types",
    "resource_margin_spacecraft_ids",
    "resource_margin_scenario_ids",
    "resource_margin_timeline_ids",
    "resource_margin_source_activity_ids",
    "resource_margin_replacement_activity_ids",
    "resource_margin_fields",
    "resource_margin_values",
    "resource_margin_threshold_values",
    "resource_margin_field_value_maps",
    "resource_margin_source_quality_values",
    "resource_margin_start_values_s",
    "resource_margin_end_values_s",
    "resource_margin_diff_statuses",
    "resource_margin_changed_fields",
    "resource_margin_required_operator_actions",
    "resource_margin_requires_operator_review_values",
    "resource_margin_feedback_sources",
    "resource_margin_feedback_scopes",
    "resource_margin_feedback_keys",
    "resource_margin_trust_boundaries",
    "resource_margin_derivation_reasons"
  ]

  @timeline_integrity_context_keys [
    "timeline_integrity_risk_types",
    "timeline_integrity_activity_ids",
    "timeline_integrity_timeline_ids",
    "timeline_integrity_statuses",
    "timeline_integrity_issue_count_values",
    "timeline_integrity_issue_types",
    "timeline_integrity_issue_maps",
    "timeline_integrity_missing_dependency_activity_ids",
    "timeline_integrity_missing_dependency_timeline_ids",
    "timeline_integrity_dependency_cycle_activity_ids",
    "timeline_integrity_dependency_cycle_timeline_ids",
    "timeline_integrity_dependency_order_violation_activity_ids",
    "timeline_integrity_dependency_order_violation_timeline_ids",
    "timeline_integrity_exclusivity_violation_activity_ids",
    "timeline_integrity_exclusivity_violation_timeline_ids",
    "timeline_integrity_exclusivity_violation_groups",
    "timeline_integrity_required_operator_actions",
    "timeline_integrity_feedback_sources",
    "timeline_integrity_feedback_scopes",
    "timeline_integrity_feedback_keys",
    "timeline_integrity_trust_boundaries",
    "timeline_integrity_derivation_reasons"
  ]

  def validation_refresh_context_keys, do: ValidationRefresh.context_keys()

  def approval_boundary_context_keys, do: @approval_boundary_context_keys

  def provider_reservation_request_context_keys, do: @provider_reservation_request_context_keys

  def capacity_pack_context_keys, do: @capacity_pack_context_keys

  def contact_contention_resolution_context_keys,
    do: @contact_contention_resolution_context_keys

  def contact_contention_context_keys, do: @contact_contention_context_keys

  def station_reservation_conflict_context_keys, do: @station_reservation_conflict_context_keys

  def station_reservation_hold_import_readiness_context_keys,
    do: StationReservationHoldImportReadiness.context_keys()

  def timeline_activity_precondition_context_keys,
    do: TimelineActivityPrecondition.context_keys()

  def timeline_preservation_context_keys, do: @timeline_preservation_context_keys

  def timeline_publication_context_keys, do: @timeline_publication_context_keys

  def timeline_lifecycle_state_context_keys, do: @timeline_lifecycle_state_context_keys

  def timeline_activity_lifecycle_state_context_keys,
    do: TimelineActivityLifecycleState.context_keys()

  def timeline_dependency_impact_context_keys, do: @timeline_dependency_impact_context_keys

  def relay_data_path_context_keys, do: RelayDataPath.context_keys()

  def link_capacity_context_keys, do: @link_capacity_context_keys

  def contact_intent_context_keys, do: ContactIntent.context_keys()

  def contact_allocation_context_keys, do: ContactAllocation.context_keys()

  def contact_filter_context_keys, do: @contact_filter_context_keys

  def resource_filter_context_keys, do: @resource_filter_context_keys

  def resource_projection_context_keys, do: ResourceProjection.context_keys()

  def station_calendar_context_keys, do: StationCalendar.context_keys()

  def score_term_context_keys, do: ScoreTerm.context_keys()

  def objective_satisfaction_context_keys, do: ObjectiveSatisfaction.context_keys()

  def objective_tradeoff_context_keys, do: ObjectiveTradeoff.context_keys()

  def resource_margin_context_keys, do: @resource_margin_context_keys

  def maneuver_execution_uncertainty_context_keys,
    do: ManeuverExecutionUncertainty.context_keys()

  def timeline_integrity_context_keys, do: @timeline_integrity_context_keys

  def execution_success_feedback_context_keys,
    do: ExecutionSuccessFeedback.context_keys()

  def operational_feedback_context_keys,
    do: OperationalFeedback.context_keys()

  def validation_refresh_context(risks), do: ValidationRefresh.context(risks)

  def approval_boundary_context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    approval_boundary_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "feedback_scope") == "approval_boundary" or
            Map.get(&1, "type") == "approval_boundary_pressure")
      )

    %{
      "approval_boundary_ids" =>
        risk_context_values(approval_boundary_risks, "approval_boundary"),
      "approval_boundary_statuses" =>
        risk_context_values(approval_boundary_risks, "approval_boundary_status"),
      "approval_boundary_reasons" =>
        risk_context_values(approval_boundary_risks, "approval_boundary_reason"),
      "automation_boundaries" =>
        risk_context_values(approval_boundary_risks, "automation_boundary"),
      "execution_boundaries" =>
        risk_context_values(approval_boundary_risks, "execution_boundary"),
      "approval_boundary_import_classifications" =>
        risk_context_values(approval_boundary_risks, "import_classification"),
      "approval_boundary_required_operator_actions" =>
        risk_context_values(approval_boundary_risks, "required_operator_action"),
      "approval_boundary_required_authorities" =>
        risk_context_values(approval_boundary_risks, "required_authority"),
      "approval_boundary_policy_bundle_ids" =>
        risk_context_values(approval_boundary_risks, "policy_bundle_id"),
      "approval_boundary_rule_ids" => risk_context_values(approval_boundary_risks, "rule_id"),
      "approval_boundary_feedback_sources" =>
        risk_context_values(approval_boundary_risks, "feedback_source"),
      "approval_boundary_feedback_scopes" =>
        risk_context_values(approval_boundary_risks, "feedback_scope"),
      "approval_boundary_feedback_keys" =>
        risk_context_values(approval_boundary_risks, "feedback_key"),
      "approval_boundary_trust_boundaries" =>
        risk_context_values(approval_boundary_risks, "trust_boundary")
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def approval_boundary_context(_risks), do: %{}

  def provider_reservation_request_context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    provider_reservation_request_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "feedback_scope") == "contact_allocation_provider_reservation_request" or
            Map.get(&1, "type") == "provider_reservation_request_review")
      )

    %{
      "provider_reservation_request_contact_ids" =>
        risk_context_values(provider_reservation_request_risks, "contact_id"),
      "provider_reservation_request_source_activity_ids" =>
        risk_context_values(provider_reservation_request_risks, [
          "source_activity_id",
          "source_activity_ids"
        ]),
      "provider_reservation_request_ground_station_ids" =>
        risk_context_values(provider_reservation_request_risks, "ground_station_id"),
      "provider_reservation_request_directions" =>
        risk_context_values(provider_reservation_request_risks, "direction"),
      "provider_reservation_request_station_reservation_ids" =>
        risk_context_values(provider_reservation_request_risks, "station_reservation_id"),
      "provider_reservation_request_station_reserved_by" =>
        risk_context_values(provider_reservation_request_risks, "station_reserved_by"),
      "provider_reservation_request_station_reservation_statuses" =>
        risk_context_values(provider_reservation_request_risks, "station_reservation_status"),
      "provider_reservation_request_station_reservation_match_statuses" =>
        risk_context_values(
          provider_reservation_request_risks,
          "station_reservation_match_status"
        ),
      "provider_reservation_request_statuses" =>
        risk_context_values(
          provider_reservation_request_risks,
          "provider_reservation_request_status"
        ),
      "provider_reservation_request_row_scopes" =>
        risk_context_values(provider_reservation_request_risks, "provider_reservation_row_scope"),
      "provider_reservation_request_required_operator_actions" =>
        risk_context_values(provider_reservation_request_risks, "required_operator_action"),
      "provider_reservation_request_assumption_maps" =>
        risk_context_values(provider_reservation_request_risks, "assumptions"),
      "provider_reservation_request_feedback_sources" =>
        risk_context_values(provider_reservation_request_risks, "feedback_source"),
      "provider_reservation_request_feedback_scopes" =>
        risk_context_values(provider_reservation_request_risks, "feedback_scope"),
      "provider_reservation_request_trust_boundaries" =>
        risk_context_values(provider_reservation_request_risks, "trust_boundary")
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def provider_reservation_request_context(_risks), do: %{}

  def capacity_pack_context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    capacity_pack_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "feedback_scope") == "contact_contention_resolution" or
            Map.has_key?(&1, "capacity_pack_group_id"))
      )

    %{
      "capacity_pack_risk_contact_ids" => risk_context_values(capacity_pack_risks, "contact_id"),
      "capacity_pack_risk_source_activity_ids" =>
        risk_context_values(capacity_pack_risks, ["source_activity_id", "source_activity_ids"]),
      "capacity_pack_risk_ground_station_ids" =>
        risk_context_values(capacity_pack_risks, "ground_station_id"),
      "capacity_pack_risk_group_ids" =>
        risk_context_values(capacity_pack_risks, "capacity_pack_group_id"),
      "capacity_pack_risk_statuses" =>
        risk_context_values(capacity_pack_risks, "capacity_pack_status"),
      "capacity_pack_risk_capacity_fraction_values" =>
        risk_context_values(capacity_pack_risks, "capacity_pack_capacity_fraction"),
      "capacity_pack_risk_used_fraction_values" =>
        risk_context_values(capacity_pack_risks, "capacity_pack_used_fraction"),
      "capacity_pack_risk_unused_fraction_values" =>
        risk_context_values(capacity_pack_risks, "capacity_pack_unused_fraction"),
      "capacity_pack_risk_required_capacity_fraction_values" =>
        risk_context_values(capacity_pack_risks, "required_capacity_fraction"),
      "capacity_pack_risk_required_capacity_fraction_sources" =>
        risk_context_values(capacity_pack_risks, "required_capacity_fraction_source"),
      "capacity_pack_risk_derivation_reasons" =>
        risk_context_values(capacity_pack_risks, ["derivation_reasons"]),
      "capacity_pack_risk_feedback_sources" =>
        risk_context_values(capacity_pack_risks, "feedback_source"),
      "capacity_pack_risk_feedback_scopes" =>
        risk_context_values(capacity_pack_risks, "feedback_scope"),
      "capacity_pack_risk_trust_boundaries" =>
        risk_context_values(capacity_pack_risks, "trust_boundary")
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def capacity_pack_context(_risks), do: %{}

  def contact_contention_resolution_context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    contact_contention_resolution_risks =
      Enum.filter(risks, &contact_contention_resolution_risk?/1)

    %{
      "contact_contention_resolution_pressure_risk_types" =>
        risk_context_values(contact_contention_resolution_risks, ["type", "risk_type"]),
      "contact_contention_resolution_pressure_contact_ids" =>
        risk_context_values(contact_contention_resolution_risks, "contact_id"),
      "contact_contention_resolution_pressure_selected_contact_ids" =>
        risk_context_values(contact_contention_resolution_risks, "selected_contact_id"),
      "contact_contention_resolution_pressure_scenario_ids" =>
        risk_context_values(contact_contention_resolution_risks, "scenario_id"),
      "contact_contention_resolution_pressure_spacecraft_ids" =>
        risk_context_values(contact_contention_resolution_risks, "spacecraft_id"),
      "contact_contention_resolution_pressure_ground_station_ids" =>
        risk_context_values(contact_contention_resolution_risks, "ground_station_id"),
      "contact_contention_resolution_pressure_source_activity_ids" =>
        risk_context_values(contact_contention_resolution_risks, [
          "source_activity_id",
          "source_activity_ids"
        ]),
      "contact_contention_resolution_pressure_source_window_ids" =>
        risk_context_values(contact_contention_resolution_risks, "source_window_id"),
      "contact_contention_resolution_pressure_required_contact_values" =>
        risk_context_values(contact_contention_resolution_risks, "required_contacts"),
      "contact_contention_resolution_pressure_planned_contact_values" =>
        risk_context_values(contact_contention_resolution_risks, "planned_contacts"),
      "contact_contention_resolution_pressure_required_downlink_values_mb" =>
        risk_context_values(contact_contention_resolution_risks, "required_downlink_mb"),
      "contact_contention_resolution_pressure_planned_downlink_values_mb" =>
        risk_context_values(contact_contention_resolution_risks, "planned_downlink_mb"),
      "contact_contention_resolution_pressure_start_values_s" =>
        risk_context_values(contact_contention_resolution_risks, "starts_at_s"),
      "contact_contention_resolution_pressure_end_values_s" =>
        risk_context_values(contact_contention_resolution_risks, "ends_at_s"),
      "contact_contention_resolution_pressure_selected_priority_sources" =>
        risk_context_values(contact_contention_resolution_risks, "selected_priority_source"),
      "contact_contention_resolution_pressure_selection_reasons" =>
        risk_context_values(contact_contention_resolution_risks, "selection_reason"),
      "contact_contention_resolution_pressure_resolution_selection_rules" =>
        risk_context_values(contact_contention_resolution_risks, "resolution_selection_rule"),
      "contact_contention_resolution_pressure_priority_override_count_values" =>
        risk_context_values(
          contact_contention_resolution_risks,
          "resolution_priority_override_count"
        ),
      "contact_contention_resolution_pressure_priority_override_contact_ids" =>
        risk_context_values(
          contact_contention_resolution_risks,
          ["resolution_priority_override_contact_ids"]
        ),
      "contact_contention_resolution_pressure_review_statuses" =>
        risk_context_values(contact_contention_resolution_risks, "review_status"),
      "contact_contention_resolution_pressure_downlink_demand_sources" =>
        risk_context_values(contact_contention_resolution_risks, ["downlink_demand_sources"]),
      "contact_contention_resolution_pressure_downlink_completion_sources" =>
        risk_context_values(
          contact_contention_resolution_risks,
          ["downlink_completion_sources"]
        ),
      "contact_contention_resolution_pressure_feedback_sources" =>
        risk_context_values(contact_contention_resolution_risks, "feedback_source"),
      "contact_contention_resolution_pressure_feedback_scopes" =>
        risk_context_values(contact_contention_resolution_risks, "feedback_scope"),
      "contact_contention_resolution_pressure_trust_boundaries" =>
        risk_context_values(contact_contention_resolution_risks, "trust_boundary"),
      "contact_contention_resolution_pressure_derivation_reasons" =>
        risk_context_values(contact_contention_resolution_risks, ["derivation_reasons"])
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def contact_contention_resolution_context(_risks), do: %{}

  def contact_contention_context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    contact_contention_risks =
      Enum.filter(risks, &contact_contention_risk?/1)

    %{
      "contact_contention_pressure_risk_types" =>
        risk_context_values(contact_contention_risks, ["type", "risk_type"]),
      "contact_contention_pressure_contact_ids" =>
        risk_context_values(contact_contention_risks, "contact_id"),
      "contact_contention_pressure_scenario_ids" =>
        risk_context_values(contact_contention_risks, "scenario_id"),
      "contact_contention_pressure_spacecraft_ids" =>
        risk_context_values(contact_contention_risks, "spacecraft_id"),
      "contact_contention_pressure_ground_station_ids" =>
        risk_context_values(contact_contention_risks, "ground_station_id"),
      "contact_contention_pressure_source_activity_ids" =>
        risk_context_values(contact_contention_risks, [
          "source_activity_id",
          "source_activity_ids"
        ]),
      "contact_contention_pressure_source_window_ids" =>
        risk_context_values(contact_contention_risks, [
          "source_window_id",
          "source_window_ids"
        ]),
      "contact_contention_pressure_required_contact_values" =>
        risk_context_values(contact_contention_risks, "required_contacts"),
      "contact_contention_pressure_planned_contact_values" =>
        risk_context_values(contact_contention_risks, "planned_contacts"),
      "contact_contention_pressure_required_downlink_values_mb" =>
        risk_context_values(contact_contention_risks, "required_downlink_mb"),
      "contact_contention_pressure_planned_downlink_values_mb" =>
        risk_context_values(contact_contention_risks, "planned_downlink_mb"),
      "contact_contention_pressure_start_values_s" =>
        risk_context_values(contact_contention_risks, "starts_at_s"),
      "contact_contention_pressure_end_values_s" =>
        risk_context_values(contact_contention_risks, "ends_at_s"),
      "contact_contention_pressure_group_ids" =>
        risk_context_values(contact_contention_risks, "contention_group_id"),
      "contact_contention_pressure_resource_scopes" =>
        risk_context_values(contact_contention_risks, "contention_resource_scope"),
      "contact_contention_pressure_contention_contact_ids" =>
        risk_context_values(contact_contention_risks, ["contention_contact_ids"]),
      "contact_contention_pressure_required_operator_actions" =>
        risk_context_values(contact_contention_risks, "required_operator_action"),
      "contact_contention_pressure_approval_statuses" =>
        risk_context_values(contact_contention_risks, "approval_status"),
      "contact_contention_pressure_operator_action_reasons" =>
        risk_context_values(contact_contention_risks, "operator_action_reason"),
      "contact_contention_pressure_downlink_demand_sources" =>
        risk_context_values(contact_contention_risks, ["downlink_demand_sources"]),
      "contact_contention_pressure_downlink_completion_sources" =>
        risk_context_values(contact_contention_risks, ["downlink_completion_sources"]),
      "contact_contention_pressure_feedback_sources" =>
        risk_context_values(contact_contention_risks, "feedback_source"),
      "contact_contention_pressure_feedback_scopes" =>
        risk_context_values(contact_contention_risks, "feedback_scope"),
      "contact_contention_pressure_trust_boundaries" =>
        risk_context_values(contact_contention_risks, "trust_boundary"),
      "contact_contention_pressure_derivation_reasons" =>
        risk_context_values(contact_contention_risks, ["derivation_reasons"])
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def contact_contention_context(_risks), do: %{}

  def station_reservation_conflict_context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    station_reservation_conflict_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "feedback_scope") == "contact_allocation" and
            Map.has_key?(&1, "station_reservation_match_status"))
      )

    %{
      "station_reservation_conflict_contact_ids" =>
        risk_context_values(station_reservation_conflict_risks, "contact_id"),
      "station_reservation_conflict_source_activity_ids" =>
        risk_context_values(station_reservation_conflict_risks, [
          "source_activity_id",
          "source_activity_ids"
        ]),
      "station_reservation_conflict_ground_station_ids" =>
        risk_context_values(station_reservation_conflict_risks, "ground_station_id"),
      "station_reservation_conflict_reservation_ids" =>
        risk_context_values(station_reservation_conflict_risks, "station_reservation_id"),
      "station_reservation_conflict_reserved_by" =>
        risk_context_values(station_reservation_conflict_risks, "station_reserved_by"),
      "station_reservation_conflict_statuses" =>
        risk_context_values(station_reservation_conflict_risks, "station_reservation_status"),
      "station_reservation_conflict_match_statuses" =>
        risk_context_values(
          station_reservation_conflict_risks,
          "station_reservation_match_status"
        ),
      "station_reservation_conflict_expires_at_values_s" =>
        risk_context_values(
          station_reservation_conflict_risks,
          "station_reservation_expires_at_s"
        ),
      "station_reservation_conflict_derivation_reasons" =>
        risk_context_values(station_reservation_conflict_risks, ["derivation_reasons"]),
      "station_reservation_conflict_feedback_sources" =>
        risk_context_values(station_reservation_conflict_risks, "feedback_source"),
      "station_reservation_conflict_feedback_scopes" =>
        risk_context_values(station_reservation_conflict_risks, "feedback_scope"),
      "station_reservation_conflict_trust_boundaries" =>
        risk_context_values(station_reservation_conflict_risks, "trust_boundary")
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def station_reservation_conflict_context(_risks), do: %{}

  def station_reservation_hold_import_readiness_context(risks) when is_list(risks),
    do: StationReservationHoldImportReadiness.context(risks)

  def station_reservation_hold_import_readiness_context(risks),
    do: StationReservationHoldImportReadiness.context(risks)

  def timeline_activity_precondition_context(risks),
    do: TimelineActivityPrecondition.context(risks)

  def timeline_preservation_context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    timeline_preservation_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "type") == "timeline_preservation_review" or
            Map.get(&1, "feedback_scope") == "timeline_preservation")
      )

    %{
      "timeline_preservation_activity_ids" =>
        risk_context_values(timeline_preservation_risks, "activity_id"),
      "timeline_preservation_timeline_ids" =>
        risk_context_values(timeline_preservation_risks, "timeline_id"),
      "timeline_preservation_statuses" =>
        risk_context_values(timeline_preservation_risks, "timeline_preservation_status"),
      "timeline_preservation_requires_preservation_values" =>
        risk_context_values(timeline_preservation_risks, "requires_preservation"),
      "timeline_preservation_requires_operator_review_values" =>
        risk_context_values(timeline_preservation_risks, "requires_operator_review"),
      "timeline_preservation_protection_decisions" =>
        risk_context_values(timeline_preservation_risks, "protection_decision"),
      "timeline_preservation_protection_categories" =>
        risk_context_values(timeline_preservation_risks, "protection_category"),
      "timeline_preservation_protection_reasons" =>
        risk_context_values(timeline_preservation_risks, "protection_reason"),
      "timeline_preservation_preserve_activity_count_values" =>
        risk_context_values(timeline_preservation_risks, "preserve_activity_count"),
      "timeline_preservation_review_change_activity_count_values" =>
        risk_context_values(timeline_preservation_risks, "review_change_activity_count"),
      "timeline_preservation_sensitive_activity_count_values" =>
        risk_context_values(timeline_preservation_risks, "preservation_sensitive_activity_count"),
      "timeline_preservation_preserve_activity_ids" =>
        risk_context_values(timeline_preservation_risks, ["preserve_activity_ids"]),
      "timeline_preservation_preserve_timeline_ids" =>
        risk_context_values(timeline_preservation_risks, ["preserve_timeline_ids"]),
      "timeline_preservation_review_change_activity_ids" =>
        risk_context_values(timeline_preservation_risks, ["review_change_activity_ids"]),
      "timeline_preservation_review_change_timeline_ids" =>
        risk_context_values(timeline_preservation_risks, ["review_change_timeline_ids"]),
      "timeline_preservation_sensitive_activity_ids" =>
        risk_context_values(timeline_preservation_risks, [
          "preservation_sensitive_activity_ids"
        ]),
      "timeline_preservation_sensitive_timeline_ids" =>
        risk_context_values(timeline_preservation_risks, [
          "preservation_sensitive_timeline_ids"
        ]),
      "timeline_preservation_invalid_activity_input_values" =>
        risk_context_values(timeline_preservation_risks, "invalid_activity_input"),
      "timeline_preservation_invalid_activity_input_reasons" =>
        risk_context_values(timeline_preservation_risks, "invalid_activity_input_reason"),
      "timeline_preservation_required_operator_actions" =>
        risk_context_values(timeline_preservation_risks, "required_operator_action"),
      "timeline_preservation_feedback_sources" =>
        risk_context_values(timeline_preservation_risks, "feedback_source"),
      "timeline_preservation_feedback_scopes" =>
        risk_context_values(timeline_preservation_risks, "feedback_scope"),
      "timeline_preservation_feedback_keys" =>
        risk_context_values(timeline_preservation_risks, "feedback_key"),
      "timeline_preservation_trust_boundaries" =>
        risk_context_values(timeline_preservation_risks, "trust_boundary"),
      "timeline_preservation_derivation_reasons" =>
        risk_context_values(timeline_preservation_risks, ["derivation_reasons"]),
      "timeline_preservation_assumption_maps" =>
        risk_context_values(timeline_preservation_risks, "assumptions")
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def timeline_preservation_context(_risks), do: %{}

  def timeline_publication_context(risks), do: TimelinePublication.context(risks)

  def timeline_lifecycle_state_context(risks), do: TimelineLifecycleState.context(risks)

  def timeline_activity_lifecycle_state_context(risks),
    do: TimelineActivityLifecycleState.context(risks)

  def timeline_dependency_impact_context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    timeline_dependency_impact_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "type") == "timeline_dependency_impact" or
            Map.get(&1, "feedback_scope") == "timeline_dependency_impact")
      )

    %{
      "timeline_dependency_impact_activity_ids" =>
        risk_context_values(timeline_dependency_impact_risks, "activity_id"),
      "timeline_dependency_impact_timeline_ids" =>
        risk_context_values(timeline_dependency_impact_risks, "timeline_id"),
      "timeline_dependency_impact_scopes" =>
        risk_context_values(timeline_dependency_impact_risks, "dependency_impact_scope"),
      "timeline_dependency_impact_statuses" =>
        risk_context_values(timeline_dependency_impact_risks, "dependency_impact_status"),
      "timeline_dependency_impact_required_operator_actions" =>
        risk_context_values(timeline_dependency_impact_risks, "required_operator_action"),
      "timeline_dependency_impact_operator_action_reasons" =>
        risk_context_values(timeline_dependency_impact_risks, "operator_action_reason"),
      "timeline_dependency_impact_dependency_activity_ids" =>
        risk_context_values(timeline_dependency_impact_risks, ["dependency_activity_ids"]),
      "timeline_dependency_impact_dependency_timeline_ids" =>
        risk_context_values(timeline_dependency_impact_risks, ["dependency_timeline_ids"]),
      "timeline_dependency_impact_exclusive_with_activity_ids" =>
        risk_context_values(timeline_dependency_impact_risks, [
          "exclusive_with_activity_ids"
        ]),
      "timeline_dependency_impact_exclusive_with_timeline_ids" =>
        risk_context_values(timeline_dependency_impact_risks, [
          "exclusive_with_timeline_ids"
        ]),
      "timeline_dependency_impact_impacted_dependency_activity_ids" =>
        risk_context_values(timeline_dependency_impact_risks, [
          "impacted_dependency_activity_ids"
        ]),
      "timeline_dependency_impact_impacted_dependency_timeline_ids" =>
        risk_context_values(timeline_dependency_impact_risks, [
          "impacted_dependency_timeline_ids"
        ]),
      "timeline_dependency_impact_impacted_exclusive_with_activity_ids" =>
        risk_context_values(timeline_dependency_impact_risks, [
          "impacted_exclusive_with_activity_ids"
        ]),
      "timeline_dependency_impact_impacted_exclusive_with_timeline_ids" =>
        risk_context_values(timeline_dependency_impact_risks, [
          "impacted_exclusive_with_timeline_ids"
        ]),
      "timeline_dependency_impact_feedback_sources" =>
        risk_context_values(timeline_dependency_impact_risks, "feedback_source"),
      "timeline_dependency_impact_feedback_scopes" =>
        risk_context_values(timeline_dependency_impact_risks, "feedback_scope"),
      "timeline_dependency_impact_feedback_keys" =>
        risk_context_values(timeline_dependency_impact_risks, "feedback_key"),
      "timeline_dependency_impact_trust_boundaries" =>
        risk_context_values(timeline_dependency_impact_risks, "trust_boundary"),
      "timeline_dependency_impact_derivation_reasons" =>
        risk_context_values(timeline_dependency_impact_risks, ["derivation_reasons"])
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def timeline_dependency_impact_context(_risks), do: %{}

  def relay_data_path_context(risks), do: RelayDataPath.context(risks)

  def link_capacity_context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    link_capacity_risks =
      Enum.filter(risks, &link_capacity_risk?/1)

    %{
      "link_capacity_pressure_risk_types" =>
        risk_context_values(link_capacity_risks, ["type", "risk_type"]),
      "link_capacity_pressure_ground_station_ids" =>
        risk_context_values(link_capacity_risks, "ground_station_id"),
      "link_capacity_pressure_required_contact_values" =>
        risk_context_values(link_capacity_risks, "required_contacts"),
      "link_capacity_pressure_planned_contact_values" =>
        risk_context_values(link_capacity_risks, "planned_contacts"),
      "link_capacity_pressure_required_downlink_values_mb" =>
        risk_context_values(link_capacity_risks, "required_downlink_mb"),
      "link_capacity_pressure_planned_downlink_values_mb" =>
        risk_context_values(link_capacity_risks, "planned_downlink_mb"),
      "link_capacity_pressure_start_values_s" =>
        risk_context_values(link_capacity_risks, "starts_at_s"),
      "link_capacity_pressure_end_values_s" =>
        risk_context_values(link_capacity_risks, "ends_at_s"),
      "link_capacity_pressure_source_activity_ids" =>
        risk_context_values(link_capacity_risks, ["source_activity_ids"]),
      "link_capacity_pressure_source_window_ids" =>
        risk_context_values(link_capacity_risks, ["source_window_id", "source_window_ids"]),
      "link_capacity_pressure_selected_capacity_adjusted_throughput_values_mb" =>
        risk_context_values(link_capacity_risks, "selected_capacity_adjusted_throughput_mb"),
      "link_capacity_pressure_selected_downlink_shortfall_values_mb" =>
        risk_context_values(link_capacity_risks, "selected_downlink_shortfall_mb"),
      "link_capacity_pressure_actual_throughput_values_mb" =>
        risk_context_values(link_capacity_risks, "actual_throughput_mb"),
      "link_capacity_pressure_actual_downlink_completion_ratio_values" =>
        risk_context_values(link_capacity_risks, "actual_downlink_completion_ratio"),
      "link_capacity_pressure_actual_downlink_shortfall_values_mb" =>
        risk_context_values(link_capacity_risks, "actual_downlink_shortfall_mb"),
      "link_capacity_pressure_downlink_requirement_statuses" =>
        risk_context_values(link_capacity_risks, "downlink_requirement_status"),
      "link_capacity_pressure_actual_downlink_requirement_statuses" =>
        risk_context_values(link_capacity_risks, "actual_downlink_requirement_status"),
      "link_capacity_pressure_downlink_demand_sources" =>
        risk_context_values(link_capacity_risks, ["downlink_demand_sources"]),
      "link_capacity_pressure_downlink_completion_sources" =>
        risk_context_values(link_capacity_risks, ["downlink_completion_sources"]),
      "link_capacity_pressure_feedback_sources" =>
        risk_context_values(link_capacity_risks, "feedback_source"),
      "link_capacity_pressure_feedback_scopes" =>
        risk_context_values(link_capacity_risks, "feedback_scope"),
      "link_capacity_pressure_trust_boundaries" =>
        risk_context_values(link_capacity_risks, "trust_boundary"),
      "link_capacity_pressure_derivation_reasons" =>
        risk_context_values(link_capacity_risks, ["derivation_reasons"])
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def link_capacity_context(_risks), do: %{}

  def contact_intent_context(risks), do: ContactIntent.context(risks)

  def contact_allocation_context(risks), do: ContactAllocation.context(risks)

  def contact_filter_context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    contact_filter_risks =
      Enum.filter(risks, &contact_filter_risk?/1)

    %{
      "contact_filter_pressure_risk_types" =>
        risk_context_values(contact_filter_risks, ["type", "risk_type"]),
      "contact_filter_pressure_contact_ids" =>
        risk_context_values(contact_filter_risks, "contact_id"),
      "contact_filter_pressure_scenario_ids" =>
        risk_context_values(contact_filter_risks, "scenario_id"),
      "contact_filter_pressure_spacecraft_ids" =>
        risk_context_values(contact_filter_risks, "spacecraft_id"),
      "contact_filter_pressure_ground_station_ids" =>
        risk_context_values(contact_filter_risks, "ground_station_id"),
      "contact_filter_pressure_source_activity_ids" =>
        risk_context_values(contact_filter_risks, ["source_activity_id", "source_activity_ids"]),
      "contact_filter_pressure_source_window_ids" =>
        risk_context_values(contact_filter_risks, "source_window_id"),
      "contact_filter_pressure_required_contact_values" =>
        risk_context_values(contact_filter_risks, "required_contacts"),
      "contact_filter_pressure_planned_contact_values" =>
        risk_context_values(contact_filter_risks, "planned_contacts"),
      "contact_filter_pressure_required_downlink_values_mb" =>
        risk_context_values(contact_filter_risks, "required_downlink_mb"),
      "contact_filter_pressure_planned_downlink_values_mb" =>
        risk_context_values(contact_filter_risks, "planned_downlink_mb"),
      "contact_filter_pressure_start_values_s" =>
        risk_context_values(contact_filter_risks, "starts_at_s"),
      "contact_filter_pressure_end_values_s" =>
        risk_context_values(contact_filter_risks, "ends_at_s"),
      "contact_filter_pressure_suppressed_reasons" =>
        risk_context_values(contact_filter_risks, "suppressed_reason"),
      "contact_filter_pressure_review_statuses" =>
        risk_context_values(contact_filter_risks, "review_status"),
      "contact_filter_pressure_station_reservation_ids" =>
        risk_context_values(contact_filter_risks, "station_reservation_id"),
      "contact_filter_pressure_station_reserved_by" =>
        risk_context_values(contact_filter_risks, "station_reserved_by"),
      "contact_filter_pressure_station_reservation_statuses" =>
        risk_context_values(contact_filter_risks, "station_reservation_status"),
      "contact_filter_pressure_station_reservation_match_statuses" =>
        risk_context_values(contact_filter_risks, "station_reservation_match_status"),
      "contact_filter_pressure_station_calendar_entry_ids" =>
        risk_context_values(contact_filter_risks, "station_calendar_entry_id"),
      "contact_filter_pressure_station_calendar_entry_statuses" =>
        risk_context_values(contact_filter_risks, "station_calendar_entry_status"),
      "contact_filter_pressure_downlink_demand_sources" =>
        risk_context_values(contact_filter_risks, ["downlink_demand_sources"]),
      "contact_filter_pressure_downlink_completion_sources" =>
        risk_context_values(contact_filter_risks, ["downlink_completion_sources"]),
      "contact_filter_pressure_feedback_sources" =>
        risk_context_values(contact_filter_risks, "feedback_source"),
      "contact_filter_pressure_feedback_scopes" =>
        risk_context_values(contact_filter_risks, "feedback_scope"),
      "contact_filter_pressure_trust_boundaries" =>
        risk_context_values(contact_filter_risks, "trust_boundary"),
      "contact_filter_pressure_derivation_reasons" =>
        risk_context_values(contact_filter_risks, ["derivation_reasons"])
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def contact_filter_context(_risks), do: %{}

  def resource_filter_context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    resource_filter_risks =
      Enum.filter(risks, &resource_filter_risk?/1)

    %{
      "resource_filter_pressure_risk_types" =>
        risk_context_values(resource_filter_risks, ["type", "risk_type"]),
      "resource_filter_pressure_scenario_ids" =>
        risk_context_values(resource_filter_risks, "scenario_id"),
      "resource_filter_pressure_spacecraft_ids" =>
        risk_context_values(resource_filter_risks, "spacecraft_id"),
      "resource_filter_pressure_resource_fields" =>
        risk_context_values(resource_filter_risks, "resource_field"),
      "resource_filter_pressure_available_values" =>
        risk_context_values(resource_filter_risks, "available"),
      "resource_filter_pressure_source_activity_ids" =>
        risk_context_values(resource_filter_risks, ["source_activity_id", "source_activity_ids"]),
      "resource_filter_pressure_start_values_s" =>
        risk_context_values(resource_filter_risks, "starts_at_s"),
      "resource_filter_pressure_end_values_s" =>
        risk_context_values(resource_filter_risks, "ends_at_s"),
      "resource_filter_pressure_suppressed_reasons" =>
        risk_context_values(resource_filter_risks, "suppressed_reason"),
      "resource_filter_pressure_source_quality_values" =>
        risk_context_values(resource_filter_risks, "source_quality"),
      "resource_filter_pressure_resource_trust_boundary_statuses" =>
        risk_context_values(resource_filter_risks, "resource_trust_boundary_status"),
      "resource_filter_pressure_fuel_margin_values" =>
        risk_context_values(resource_filter_risks, "fuel_margin"),
      "resource_filter_pressure_fuel_margin_threshold_values" =>
        risk_context_values(resource_filter_risks, "fuel_margin_threshold"),
      "resource_filter_pressure_power_margin_values" =>
        risk_context_values(resource_filter_risks, "power_margin"),
      "resource_filter_pressure_power_margin_threshold_values" =>
        risk_context_values(resource_filter_risks, "power_margin_threshold"),
      "resource_filter_pressure_storage_margin_values" =>
        risk_context_values(resource_filter_risks, "storage_margin"),
      "resource_filter_pressure_storage_margin_threshold_values" =>
        risk_context_values(resource_filter_risks, "storage_margin_threshold"),
      "resource_filter_pressure_downlink_margin_values" =>
        risk_context_values(resource_filter_risks, "downlink_margin"),
      "resource_filter_pressure_downlink_margin_threshold_values" =>
        risk_context_values(resource_filter_risks, "downlink_margin_threshold"),
      "resource_filter_pressure_thermal_margin_values_c" =>
        risk_context_values(resource_filter_risks, "thermal_margin_c"),
      "resource_filter_pressure_thermal_margin_threshold_values_c" =>
        risk_context_values(resource_filter_risks, "thermal_margin_c_threshold"),
      "resource_filter_pressure_operator_training_requirement_count_values" =>
        risk_context_values(resource_filter_risks, "operator_training_requirement_count"),
      "resource_filter_pressure_required_operator_roles" =>
        risk_context_values(resource_filter_risks, ["required_operator_roles"]),
      "resource_filter_pressure_feedback_sources" =>
        risk_context_values(resource_filter_risks, "feedback_source"),
      "resource_filter_pressure_feedback_scopes" =>
        risk_context_values(resource_filter_risks, "feedback_scope"),
      "resource_filter_pressure_trust_boundaries" =>
        risk_context_values(resource_filter_risks, "trust_boundary"),
      "resource_filter_pressure_derivation_reasons" =>
        risk_context_values(resource_filter_risks, ["derivation_reasons"])
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def resource_filter_context(_risks), do: %{}

  def resource_projection_context(risks), do: ResourceProjection.context(risks)

  def station_calendar_context(risks), do: StationCalendar.context(risks)

  def score_term_context(risks), do: ScoreTerm.context(risks)

  def objective_satisfaction_context(risks), do: ObjectiveSatisfaction.context(risks)

  def objective_tradeoff_context(risks), do: ObjectiveTradeoff.context(risks)

  def resource_margin_context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    resource_margin_risks =
      Enum.filter(risks, &resource_margin_risk?/1)

    %{
      "resource_margin_risk_types" =>
        risk_context_values(resource_margin_risks, "resource_margin_risk_type"),
      "resource_margin_spacecraft_ids" =>
        risk_context_values(resource_margin_risks, "spacecraft_id"),
      "resource_margin_scenario_ids" => risk_context_values(resource_margin_risks, "scenario_id"),
      "resource_margin_timeline_ids" => risk_context_values(resource_margin_risks, "timeline_id"),
      "resource_margin_source_activity_ids" =>
        risk_context_values(resource_margin_risks, [
          "source_activity_id",
          "source_activity_ids"
        ]),
      "resource_margin_replacement_activity_ids" =>
        risk_context_values(resource_margin_risks, "replacement_activity_id"),
      "resource_margin_fields" => risk_context_values(resource_margin_risks, "resource_field"),
      "resource_margin_values" =>
        risk_context_values(resource_margin_risks, "resource_margin_value"),
      "resource_margin_threshold_values" =>
        risk_context_values(resource_margin_risks, "resource_margin_threshold"),
      "resource_margin_field_value_maps" =>
        risk_context_values(resource_margin_risks, "resource_margin_field_value"),
      "resource_margin_source_quality_values" =>
        risk_context_values(resource_margin_risks, "source_quality"),
      "resource_margin_start_values_s" =>
        risk_context_values(resource_margin_risks, "starts_at_s"),
      "resource_margin_end_values_s" => risk_context_values(resource_margin_risks, "ends_at_s"),
      "resource_margin_diff_statuses" =>
        risk_context_values(resource_margin_risks, "diff_status"),
      "resource_margin_changed_fields" =>
        risk_context_values(resource_margin_risks, ["changed_fields"]),
      "resource_margin_required_operator_actions" =>
        risk_context_values(resource_margin_risks, "required_operator_action"),
      "resource_margin_requires_operator_review_values" =>
        risk_context_values(resource_margin_risks, "requires_operator_review"),
      "resource_margin_feedback_sources" =>
        risk_context_values(resource_margin_risks, "feedback_source"),
      "resource_margin_feedback_scopes" =>
        risk_context_values(resource_margin_risks, "feedback_scope"),
      "resource_margin_feedback_keys" =>
        risk_context_values(resource_margin_risks, "feedback_key"),
      "resource_margin_trust_boundaries" =>
        risk_context_values(resource_margin_risks, "trust_boundary"),
      "resource_margin_derivation_reasons" =>
        risk_context_values(resource_margin_risks, ["derivation_reasons"])
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def resource_margin_context(_risks), do: %{}

  def maneuver_execution_uncertainty_context(risks),
    do: ManeuverExecutionUncertainty.context(risks)

  def timeline_integrity_context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    timeline_integrity_risks =
      Enum.filter(risks, &timeline_integrity_risk?/1)

    %{
      "timeline_integrity_risk_types" =>
        risk_context_values(timeline_integrity_risks, ["type", "risk_type"]),
      "timeline_integrity_activity_ids" =>
        risk_context_values(timeline_integrity_risks, "activity_id"),
      "timeline_integrity_timeline_ids" =>
        risk_context_values(timeline_integrity_risks, "timeline_id"),
      "timeline_integrity_statuses" =>
        risk_context_values(timeline_integrity_risks, "timeline_integrity_status"),
      "timeline_integrity_issue_count_values" =>
        risk_context_values(timeline_integrity_risks, "timeline_integrity_issue_count"),
      "timeline_integrity_issue_types" =>
        risk_context_values(timeline_integrity_risks, ["timeline_integrity_issue_types"]),
      "timeline_integrity_issue_maps" =>
        risk_context_values(timeline_integrity_risks, "timeline_integrity_issues"),
      "timeline_integrity_missing_dependency_activity_ids" =>
        risk_context_values(timeline_integrity_risks, ["missing_dependency_activity_ids"]),
      "timeline_integrity_missing_dependency_timeline_ids" =>
        risk_context_values(timeline_integrity_risks, ["missing_dependency_timeline_ids"]),
      "timeline_integrity_dependency_cycle_activity_ids" =>
        risk_context_values(timeline_integrity_risks, ["dependency_cycle_activity_ids"]),
      "timeline_integrity_dependency_cycle_timeline_ids" =>
        risk_context_values(timeline_integrity_risks, ["dependency_cycle_timeline_ids"]),
      "timeline_integrity_dependency_order_violation_activity_ids" =>
        risk_context_values(timeline_integrity_risks, [
          "dependency_order_violation_activity_ids"
        ]),
      "timeline_integrity_dependency_order_violation_timeline_ids" =>
        risk_context_values(timeline_integrity_risks, [
          "dependency_order_violation_timeline_ids"
        ]),
      "timeline_integrity_exclusivity_violation_activity_ids" =>
        risk_context_values(timeline_integrity_risks, ["exclusivity_violation_activity_ids"]),
      "timeline_integrity_exclusivity_violation_timeline_ids" =>
        risk_context_values(timeline_integrity_risks, ["exclusivity_violation_timeline_ids"]),
      "timeline_integrity_exclusivity_violation_groups" =>
        risk_context_values(timeline_integrity_risks, "exclusivity_violation_group"),
      "timeline_integrity_required_operator_actions" =>
        risk_context_values(timeline_integrity_risks, "required_operator_action"),
      "timeline_integrity_feedback_sources" =>
        risk_context_values(timeline_integrity_risks, "feedback_source"),
      "timeline_integrity_feedback_scopes" =>
        risk_context_values(timeline_integrity_risks, "feedback_scope"),
      "timeline_integrity_feedback_keys" =>
        risk_context_values(timeline_integrity_risks, "feedback_key"),
      "timeline_integrity_trust_boundaries" =>
        risk_context_values(timeline_integrity_risks, "trust_boundary"),
      "timeline_integrity_derivation_reasons" =>
        risk_context_values(timeline_integrity_risks, ["derivation_reasons"])
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def timeline_integrity_context(_risks), do: %{}

  def execution_success_feedback_context(risks), do: ExecutionSuccessFeedback.context(risks)

  def operational_feedback_context(risks), do: OperationalFeedback.context(risks)

  defp resource_margin_risk?(%{"resource_field" => field}) when is_binary(field) do
    field in [
      "fuel_margin",
      "power_margin",
      "storage_margin",
      "downlink_margin",
      "thermal_margin_c"
    ]
  end

  defp resource_margin_risk?(%{"type" => type}) when is_binary(type) do
    type in [
      "fuel_margin_low",
      "power_margin_low",
      "storage_margin_low",
      "downlink_margin_low",
      "thermal_margin_c_low"
    ]
  end

  defp resource_margin_risk?(_risk), do: false

  defp timeline_integrity_risk?(%{"type" => "timeline_integrity_issue"}), do: true

  defp timeline_integrity_risk?(%{"risk_type" => "timeline_integrity_issue"}), do: true

  defp timeline_integrity_risk?(%{"feedback_scope" => "timeline_integrity"}), do: true

  defp timeline_integrity_risk?(_risk), do: false

  defp link_capacity_risk?(%{"type" => "downlink_completion_gap", "feedback_scope" => scope})
       when scope == "link_capacity",
       do: true

  defp link_capacity_risk?(%{
         "risk_type" => "downlink_completion_gap",
         "feedback_scope" => scope
       })
       when scope == "link_capacity",
       do: true

  defp link_capacity_risk?(_risk), do: false

  defp contact_contention_resolution_risk?(%{
         "feedback_scope" => "contact_contention_resolution"
       }),
       do: true

  defp contact_contention_resolution_risk?(_risk), do: false

  defp contact_contention_risk?(%{"feedback_scope" => "contact_contention"}), do: true

  defp contact_contention_risk?(_risk), do: false

  defp contact_filter_risk?(%{"feedback_scope" => "contact_filter"}), do: true

  defp contact_filter_risk?(_risk), do: false

  defp resource_filter_risk?(%{"feedback_scope" => "resource_filter"}), do: true

  defp resource_filter_risk?(_risk), do: false

  defp risk_context_values(risks, keys) when is_list(keys) do
    risks
    |> Enum.flat_map(fn risk ->
      Enum.flat_map(keys, fn key ->
        risk
        |> Map.get(key)
        |> List.wrap()
      end)
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp risk_context_values(risks, key) do
    risks
    |> Enum.map(&Map.get(&1, key))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), value}
      {key, value} -> {key, value}
    end)
  end

  defp stringify_keys(value), do: value
end
