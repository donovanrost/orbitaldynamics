defmodule OrbitalDynamics.RecommendationRiskContext do
  @moduledoc false

  alias OrbitalDynamics.RecommendationRiskContext.{
    ApprovalBoundary,
    CapacityPack,
    ContactAllocation,
    ContactContention,
    ContactContentionResolution,
    ContactFilter,
    ContactIntent,
    ExecutionSuccessFeedback,
    LinkCapacity,
    ManeuverExecutionUncertainty,
    ObjectiveSatisfaction,
    ObjectiveTradeoff,
    OperationalFeedback,
    ProviderReservationRequest,
    RelayDataPath,
    ResourceMargin,
    ResourceProjection,
    ScoreTerm,
    StationCalendar,
    StationReservationConflict,
    StationReservationHoldImportReadiness,
    TimelineActivityPrecondition,
    TimelineActivityLifecycleState,
    TimelineDependencyImpact,
    TimelineIntegrity,
    TimelineLifecycleState,
    TimelinePreservation,
    TimelinePublication,
    ValidationRefresh
  }

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

  def validation_refresh_context_keys, do: ValidationRefresh.context_keys()

  def approval_boundary_context_keys, do: ApprovalBoundary.context_keys()

  def provider_reservation_request_context_keys,
    do: ProviderReservationRequest.context_keys()

  def capacity_pack_context_keys, do: CapacityPack.context_keys()

  def contact_contention_resolution_context_keys,
    do: ContactContentionResolution.context_keys()

  def contact_contention_context_keys, do: ContactContention.context_keys()

  def station_reservation_conflict_context_keys,
    do: StationReservationConflict.context_keys()

  def station_reservation_hold_import_readiness_context_keys,
    do: StationReservationHoldImportReadiness.context_keys()

  def timeline_activity_precondition_context_keys,
    do: TimelineActivityPrecondition.context_keys()

  def timeline_preservation_context_keys, do: TimelinePreservation.context_keys()

  def timeline_publication_context_keys, do: @timeline_publication_context_keys

  def timeline_lifecycle_state_context_keys, do: @timeline_lifecycle_state_context_keys

  def timeline_activity_lifecycle_state_context_keys,
    do: TimelineActivityLifecycleState.context_keys()

  def timeline_dependency_impact_context_keys,
    do: TimelineDependencyImpact.context_keys()

  def relay_data_path_context_keys, do: RelayDataPath.context_keys()

  def link_capacity_context_keys, do: LinkCapacity.context_keys()

  def contact_intent_context_keys, do: ContactIntent.context_keys()

  def contact_allocation_context_keys, do: ContactAllocation.context_keys()

  def contact_filter_context_keys, do: ContactFilter.context_keys()

  def resource_filter_context_keys, do: @resource_filter_context_keys

  def resource_projection_context_keys, do: ResourceProjection.context_keys()

  def station_calendar_context_keys, do: StationCalendar.context_keys()

  def score_term_context_keys, do: ScoreTerm.context_keys()

  def objective_satisfaction_context_keys, do: ObjectiveSatisfaction.context_keys()

  def objective_tradeoff_context_keys, do: ObjectiveTradeoff.context_keys()

  def resource_margin_context_keys, do: ResourceMargin.context_keys()

  def maneuver_execution_uncertainty_context_keys,
    do: ManeuverExecutionUncertainty.context_keys()

  def timeline_integrity_context_keys, do: TimelineIntegrity.context_keys()

  def execution_success_feedback_context_keys,
    do: ExecutionSuccessFeedback.context_keys()

  def operational_feedback_context_keys,
    do: OperationalFeedback.context_keys()

  def validation_refresh_context(risks), do: ValidationRefresh.context(risks)

  def approval_boundary_context(risks), do: ApprovalBoundary.context(risks)

  def provider_reservation_request_context(risks),
    do: ProviderReservationRequest.context(risks)

  def capacity_pack_context(risks), do: CapacityPack.context(risks)

  def contact_contention_resolution_context(risks),
    do: ContactContentionResolution.context(risks)

  def contact_contention_context(risks), do: ContactContention.context(risks)

  def station_reservation_conflict_context(risks),
    do: StationReservationConflict.context(risks)

  def station_reservation_hold_import_readiness_context(risks) when is_list(risks),
    do: StationReservationHoldImportReadiness.context(risks)

  def station_reservation_hold_import_readiness_context(risks),
    do: StationReservationHoldImportReadiness.context(risks)

  def timeline_activity_precondition_context(risks),
    do: TimelineActivityPrecondition.context(risks)

  def timeline_preservation_context(risks), do: TimelinePreservation.context(risks)

  def timeline_publication_context(risks), do: TimelinePublication.context(risks)

  def timeline_lifecycle_state_context(risks), do: TimelineLifecycleState.context(risks)

  def timeline_activity_lifecycle_state_context(risks),
    do: TimelineActivityLifecycleState.context(risks)

  def timeline_dependency_impact_context(risks),
    do: TimelineDependencyImpact.context(risks)

  def relay_data_path_context(risks), do: RelayDataPath.context(risks)

  def link_capacity_context(risks), do: LinkCapacity.context(risks)

  def contact_intent_context(risks), do: ContactIntent.context(risks)

  def contact_allocation_context(risks), do: ContactAllocation.context(risks)

  def contact_filter_context(risks), do: ContactFilter.context(risks)

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

  def resource_margin_context(risks), do: ResourceMargin.context(risks)

  def maneuver_execution_uncertainty_context(risks),
    do: ManeuverExecutionUncertainty.context(risks)

  def timeline_integrity_context(risks), do: TimelineIntegrity.context(risks)

  def execution_success_feedback_context(risks), do: ExecutionSuccessFeedback.context(risks)

  def operational_feedback_context(risks), do: OperationalFeedback.context(risks)

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
