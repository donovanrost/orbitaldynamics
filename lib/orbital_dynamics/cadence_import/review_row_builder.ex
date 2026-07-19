defmodule OrbitalDynamics.CadenceImport.ReviewRowBuilder do
  @moduledoc false

  alias OrbitalDynamics.CadenceImport.{
    ApprovalContextPolicy,
    BranchEvidenceFields,
    CandidateDiffFields,
    GenericReviewActionPolicy,
    ImportReadinessPolicy,
    JsonNormalization,
    ManifestMapNormalization,
    OperationalReadinessContext,
    ProviderResultNormalization,
    ReviewRowDispatch,
    ReviewRowMetadata,
    StationCalendarContextFields
  }

  defp source_review_action(row), do: ReviewRowMetadata.action(row)

  def build(row, rank) do
    ReviewRowDispatch.dispatch(row, rank, %{
      approval_requirement: &approval_requirement_manifest_row/2,
      candidate_diff: &candidate_diff_manifest_row/2,
      command_window: &command_window_manifest_row/2,
      constraint: &constraint_manifest_row/2,
      contact_allocation: &contact_allocation_manifest_row/2,
      contact_contention: &contact_contention_manifest_row/2,
      contact_intent: &contact_intent_manifest_row/2,
      contact_suppression: &suppression_manifest_row(&1, &2, "contact"),
      execution: &execution_manifest_row/2,
      freshness: &freshness_manifest_row/2,
      generic: &generic_review_manifest_row/2,
      link_capacity: &link_capacity_manifest_row/2,
      maneuver_review: &maneuver_review_manifest_row/2,
      objective_satisfaction: &objective_satisfaction_manifest_row/2,
      objective_tradeoff: &objective_tradeoff_manifest_row/2,
      operational_readiness: &operational_readiness_manifest_row/2,
      operational_timeline: &operational_timeline_manifest_row/2,
      pareto_frontier: &pareto_frontier_manifest_row/2,
      plan_delta: &manifest_row/2,
      policy_escalation: &policy_escalation_manifest_row/2,
      quality_gate: &quality_gate_manifest_row/2,
      ranking_comparison: &ranking_comparison_manifest_row/2,
      realized_feedback: &realized_feedback_manifest_row/2,
      refresh_budget: &refresh_budget_manifest_row/2,
      resource_projection: &resource_projection_manifest_row/2,
      resource_suppression: &suppression_manifest_row(&1, &2, "resource"),
      risk: &risk_manifest_row/2,
      schema_validation: &schema_validation_manifest_row/2,
      score_term: &score_term_manifest_row/2,
      station_calendar: &station_calendar_manifest_row/2,
      station_reservation: &station_reservation_manifest_row/2,
      strategy_recommendation: &strategy_recommendation_manifest_row/2,
      strategy_tradeoff: &strategy_tradeoff_manifest_row/2,
      timeline_diff: &timeline_diff_manifest_row/2,
      timeline_protection: &timeline_protection_manifest_row/2,
      warning: &warning_manifest_row/2
    })
  end

  defp realized_feedback_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.RealizedFeedbackManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      normalize_provider_result_artifact_fields: &normalize_provider_result_artifact_fields/1,
      provider_result_artifact_value: &provider_result_artifact_value/1,
      adapter_import_status: &adapter_import_status/2,
      compact_map: &compact_map/1
    )
  end

  defp contact_contention_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.ContactContentionManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      provider_result_artifact_value: &provider_result_artifact_value/1,
      station_calendar_context_fields: &station_calendar_context_fields/0,
      compact_map: &compact_map/1
    )
  end

  defp contact_allocation_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.ContactAllocationManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      provider_result_artifact_value: &provider_result_artifact_value/1,
      compact_map: &compact_map/1
    )
  end

  defp contact_intent_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.ContactIntentManifestRow.build(
      row,
      rank,
      cadence_import_present?: &cadence_import_present?/2,
      first_approval_requirement: &first_approval_requirement/1,
      first_approval_rule_match: &first_approval_rule_match/1,
      stringify_keys: &stringify_keys/1,
      preferred_approval_escalation: &preferred_approval_escalation/3,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      provider_result_artifact_value: &provider_result_artifact_value/1,
      generic_review_activity_context: &generic_review_activity_context/1,
      normalize_provider_result_artifact_fields: &normalize_provider_result_artifact_fields/1,
      non_empty_map: &non_empty_map/1,
      compact_map: &compact_map/1
    )
  end

  defp candidate_diff_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.CandidateDiffManifestRow.build(
      row,
      rank,
      candidate_diff_changed_fields: &candidate_diff_changed_fields/1,
      candidate_diff_changed_field_count: &candidate_diff_changed_field_count/1,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      compact_map: &compact_map/1
    )
  end

  defp suppression_manifest_row(row, rank, suppression_type) do
    OrbitalDynamics.CadenceImport.SuppressionManifestRow.build(
      row,
      rank,
      suppression_type,
      first_approval_requirement: &first_approval_requirement/1,
      first_approval_rule_match: &first_approval_rule_match/1,
      stringify_keys: &stringify_keys/1,
      preferred_approval_escalation: &preferred_approval_escalation/3,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      provider_result_artifact_value: &provider_result_artifact_value/1,
      non_empty_map: &non_empty_map/1,
      compact_map: &compact_map/1
    )
  end

  defp first_approval_requirement(row),
    do: ApprovalContextPolicy.first_requirement(row)

  defp first_approval_rule_match(row),
    do: ApprovalContextPolicy.first_rule_match(row)

  defp preferred_approval_escalation(escalations, row, source_requirement),
    do: ApprovalContextPolicy.preferred_escalation(escalations, row, source_requirement)

  defp freshness_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.FreshnessManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      compact_map: &compact_map/1
    )
  end

  defp refresh_budget_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.RefreshBudgetManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      compact_map: &compact_map/1
    )
  end

  defp operational_readiness_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.OperationalReadinessManifestRow.build(
      row,
      rank,
      generic_review_import_action: &generic_review_import_action/1,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      operational_readiness_resource_context: &operational_readiness_resource_context/1,
      operational_readiness_adapter_boundary_context:
        &operational_readiness_adapter_boundary_context/1,
      operational_readiness_operator_training_context:
        &operational_readiness_operator_training_context/1,
      operational_readiness_cadence_import_context:
        &operational_readiness_cadence_import_context/1,
      compact_map: &compact_map/1
    )
  end

  defp quality_gate_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.QualityGateManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      operational_readiness_cadence_import_context:
        &operational_readiness_cadence_import_context/1,
      operational_readiness_resource_context: &operational_readiness_resource_context/1,
      compact_map: &compact_map/1
    )
  end

  defp operational_readiness_adapter_boundary_context(row),
    do: OperationalReadinessContext.adapter_boundary(row)

  defp operational_readiness_resource_context(row),
    do: OperationalReadinessContext.resource(row)

  defp operational_readiness_operator_training_context(row),
    do: OperationalReadinessContext.operator_training(row)

  defp operational_readiness_cadence_import_context(row),
    do: OperationalReadinessContext.cadence_import(row)

  defp approval_requirement_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.ApprovalRequirementManifestRow.build(
      row,
      rank,
      stringify_keys: &stringify_keys/1,
      first_approval_rule_match: &first_approval_rule_match/1,
      preferred_approval_escalation: &preferred_approval_escalation/3,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      generic_review_activity_context: &generic_review_activity_context/1,
      normalize_provider_result_artifact_fields: &normalize_provider_result_artifact_fields/1,
      non_empty_map: &non_empty_map/1,
      candidate_diff_changed_fields: &candidate_diff_changed_fields/1,
      candidate_diff_changed_field_count: &candidate_diff_changed_field_count/1,
      compact_map: &compact_map/1
    )
  end

  defp candidate_diff_changed_fields(row),
    do: CandidateDiffFields.derive(row)

  defp candidate_diff_changed_field_count(fields),
    do: CandidateDiffFields.count(fields)

  defp maneuver_review_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.ManeuverReviewManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      compact_map: &compact_map/1
    )
  end

  defp timeline_diff_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.TimelineDiffManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      generic_review_activity_context: &generic_review_activity_context/1,
      normalize_provider_result_artifact_fields: &normalize_provider_result_artifact_fields/1,
      compact_map: &compact_map/1
    )
  end

  defp timeline_protection_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.TimelineProtectionManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      compact_map: &compact_map/1
    )
  end

  defp command_window_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.CommandWindowManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      provider_result_artifact_value: &provider_result_artifact_value/1,
      normalize_provider_result_artifact_fields: &normalize_provider_result_artifact_fields/1,
      compact_map: &compact_map/1
    )
  end

  defp station_calendar_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.StationCalendarManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      provider_result_artifact_value: &provider_result_artifact_value/1,
      compact_map: &compact_map/1
    )
  end

  defp station_reservation_manifest_row(row, rank) do
    row
    |> station_calendar_manifest_row(rank)
    |> Map.merge(%{
      "id" => "cadence_import:station_reservation:#{row["id"] || rank}",
      "import_action" => "review_station_reservation",
      "source_station_reservation" => row["source_station_reservation"]
    })
    |> compact_map()
  end

  defp policy_escalation_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.PolicyEscalationManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      compact_map: &compact_map/1
    )
  end

  defp resource_projection_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.ResourceProjectionManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      compact_map: &compact_map/1
    )
  end

  defp warning_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.WarningManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      compact_map: &compact_map/1
    )
  end

  defp risk_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.RiskManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      compact_map: &compact_map/1
    )
  end

  defp strategy_recommendation_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.StrategyRecommendationManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      branch_timeline_evidence_fields: &branch_timeline_evidence_fields/0,
      branch_readiness_quality_gate_fields: &branch_readiness_quality_gate_fields/0,
      branch_contact_allocation_fields: &branch_contact_allocation_fields/0,
      compact_map: &compact_map/1
    )
  end

  defp branch_contact_allocation_fields,
    do: BranchEvidenceFields.contact_allocation()

  defp branch_readiness_quality_gate_fields,
    do: BranchEvidenceFields.readiness_quality_gate()

  defp branch_timeline_evidence_fields,
    do: BranchEvidenceFields.timeline()

  defp strategy_tradeoff_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.StrategyTradeoffManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      branch_timeline_evidence_fields: &branch_timeline_evidence_fields/0,
      branch_readiness_quality_gate_fields: &branch_readiness_quality_gate_fields/0,
      branch_contact_allocation_fields: &branch_contact_allocation_fields/0,
      compact_map: &compact_map/1
    )
  end

  defp ranking_comparison_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.RankingComparisonManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      compact_map: &compact_map/1
    )
  end

  defp score_term_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.ScoreTermManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      compact_map: &compact_map/1
    )
  end

  defp objective_tradeoff_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.ObjectiveTradeoffManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      compact_map: &compact_map/1
    )
  end

  defp pareto_frontier_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.ParetoFrontierManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      compact_map: &compact_map/1
    )
  end

  defp schema_validation_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.SchemaValidationManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      compact_map: &compact_map/1
    )
  end

  defp execution_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.ExecutionManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      compact_map: &compact_map/1
    )
  end

  defp constraint_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.ConstraintManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      compact_map: &compact_map/1
    )
  end

  defp objective_satisfaction_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.ObjectiveSatisfactionManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      compact_map: &compact_map/1
    )
  end

  defp link_capacity_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.LinkCapacityManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      provider_result_artifact_value: &provider_result_artifact_value/1,
      compact_map: &compact_map/1
    )
  end

  defp operational_timeline_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.OperationalTimelineManifestRow.build(
      row,
      rank,
      cadence_import_present?: &cadence_import_present?/2,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      provider_result_artifact_value: &provider_result_artifact_value/1,
      normalize_provider_result_artifact_fields: &normalize_provider_result_artifact_fields/1,
      compact_map: &compact_map/1
    )
  end

  defp generic_review_manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.GenericReviewManifestRow.build(
      row,
      rank,
      cadence_import_present?: &cadence_import_present?/2,
      generic_review_import_action: &generic_review_import_action/1,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      generic_review_activity_context: &generic_review_activity_context/1,
      normalize_provider_result_artifact_fields: &normalize_provider_result_artifact_fields/1,
      compact_map: &compact_map/1
    )
  end

  defp cadence_import_present?(row, status),
    do: ImportReadinessPolicy.cadence_import_present?(row, status)

  defp generic_review_activity_context(row),
    do: ReviewRowMetadata.activity_context(row)

  defp manifest_row(row, rank) do
    OrbitalDynamics.CadenceImport.PlanDeltaManifestRow.build(
      row,
      rank,
      source_review_action: &source_review_action/1,
      adapter_import_status: &adapter_import_status/2,
      normalize_provider_result_artifact_fields: &normalize_provider_result_artifact_fields/1,
      compact_map: &compact_map/1
    )
  end

  defp adapter_import_status(status, approval_status),
    do: ImportReadinessPolicy.adapter_import_status(status, approval_status)

  defp generic_review_import_action(review_type),
    do: GenericReviewActionPolicy.resolve(review_type)

  defp stringify_keys(value), do: JsonNormalization.stringify_keys(value)

  defp normalize_provider_result_artifact_fields(value),
    do: ProviderResultNormalization.normalize_artifact_fields(value)

  defp provider_result_artifact_value(value),
    do: ProviderResultNormalization.artifact_value(value)

  defp station_calendar_context_fields,
    do: StationCalendarContextFields.all()

  defp compact_map(map), do: ManifestMapNormalization.compact(map)

  defp non_empty_map(map), do: ManifestMapNormalization.non_empty(map)
end
