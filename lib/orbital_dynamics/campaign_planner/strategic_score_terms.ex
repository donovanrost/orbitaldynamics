defmodule OrbitalDynamics.CampaignPlanner.StrategicScoreTerms do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    BranchApprovalRequirements,
    ScalarValues,
    StrategyMetrics,
    StrategyPressureRisk
  }

  def build(
        candidate_plan,
        repair_result,
        risk_indicators,
        branch,
        request,
        resource_impacts,
        feedback_adjustments,
        callbacks \\ default_callbacks()
      ) do
    branch_approval_requirements = Keyword.fetch!(callbacks, :branch_approval_requirements)
    candidate_score = Keyword.fetch!(callbacks, :candidate_score)
    target_count = Keyword.fetch!(callbacks, :target_count)
    revisit_count = Keyword.fetch!(callbacks, :revisit_count)
    collection_latency_s = Keyword.fetch!(callbacks, :collection_latency_s)
    downlink_completion_ratio = Keyword.fetch!(callbacks, :downlink_completion_ratio)
    fuel_preservation_score = Keyword.fetch!(callbacks, :fuel_preservation_score)
    schedule_stability_penalty = Keyword.fetch!(callbacks, :schedule_stability_penalty)
    asset_balance_score = Keyword.fetch!(callbacks, :asset_balance_score)
    priority_commitment_score = Keyword.fetch!(callbacks, :priority_commitment_score)
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    policy = request.strategy_policy
    activities = candidate_plan["activities"]
    repair_score_terms = Map.get(repair_result, "score_terms", %{})
    approval_count = length(branch_approval_requirements.(repair_result, candidate_plan))
    risk_count = length(risk_indicators)

    contact_allocation_pressure_count =
      StrategyPressureRisk.contact_allocation_pressure_risk_count(risk_indicators)

    provider_reservation_request_pressure_count =
      StrategyPressureRisk.provider_reservation_request_pressure_risk_count(risk_indicators)

    station_reservation_conflict_pressure_count =
      StrategyPressureRisk.station_reservation_conflict_pressure_risk_count(risk_indicators)

    candidate_diff_pressure_count =
      StrategyPressureRisk.candidate_diff_pressure_risk_count(risk_indicators)

    timeline_diff_pressure_count =
      StrategyPressureRisk.timeline_diff_pressure_risk_count(risk_indicators)

    link_capacity_pressure_count =
      StrategyPressureRisk.link_capacity_pressure_risk_count(risk_indicators)

    contact_intent_pressure_count =
      StrategyPressureRisk.contact_intent_pressure_risk_count(risk_indicators)

    contact_contention_pressure_count =
      StrategyPressureRisk.contact_contention_pressure_risk_count(risk_indicators)

    contact_filter_pressure_count =
      StrategyPressureRisk.contact_filter_pressure_risk_count(risk_indicators)

    command_window_pressure_count =
      StrategyPressureRisk.command_window_pressure_risk_count(risk_indicators)

    objective_gap_pressure_count =
      StrategyPressureRisk.objective_gap_pressure_risk_count(risk_indicators)

    timeline_feedback_pressure_count =
      StrategyPressureRisk.timeline_feedback_pressure_risk_count(risk_indicators)

    operational_timeline_pressure_count =
      StrategyPressureRisk.operational_timeline_pressure_risk_count(risk_indicators)

    maneuver_review_pressure_count =
      StrategyPressureRisk.maneuver_review_pressure_risk_count(risk_indicators)

    operational_readiness_pressure_count =
      StrategyPressureRisk.operational_readiness_pressure_risk_count(risk_indicators)

    operator_training_pressure_count =
      StrategyPressureRisk.operator_training_pressure_risk_count(risk_indicators)

    import_readiness_pressure_count =
      StrategyPressureRisk.import_readiness_pressure_risk_count(risk_indicators)

    quality_gate_pressure_count =
      StrategyPressureRisk.quality_gate_pressure_risk_count(risk_indicators)

    approval_boundary_pressure_count =
      StrategyPressureRisk.approval_boundary_pressure_risk_count(risk_indicators)

    timeline_integrity_pressure_count =
      StrategyPressureRisk.timeline_integrity_pressure_risk_count(risk_indicators)

    timeline_dependency_impact_pressure_count =
      StrategyPressureRisk.timeline_dependency_impact_pressure_risk_count(risk_indicators)

    timeline_publication_pressure_count =
      StrategyPressureRisk.timeline_publication_pressure_risk_count(risk_indicators)

    timeline_transition_application_pressure_count =
      StrategyPressureRisk.timeline_transition_application_pressure_risk_count(risk_indicators)

    timeline_activity_state_pressure_count =
      StrategyPressureRisk.timeline_activity_state_pressure_risk_count(risk_indicators)

    timeline_lifecycle_pressure_count =
      StrategyPressureRisk.timeline_lifecycle_pressure_risk_count(risk_indicators)

    timeline_precondition_pressure_count =
      StrategyPressureRisk.timeline_precondition_pressure_risk_count(risk_indicators)

    timeline_preservation_pressure_count =
      StrategyPressureRisk.timeline_preservation_pressure_risk_count(risk_indicators)

    timeline_pressure_count = StrategyPressureRisk.timeline_pressure_risk_count(risk_indicators)

    storage_downlink_pressure_count =
      StrategyPressureRisk.storage_downlink_pressure_risk_count(risk_indicators)

    resource_projection_pressure_count =
      StrategyPressureRisk.resource_projection_pressure_risk_count(risk_indicators)

    resource_filter_pressure_count =
      StrategyPressureRisk.resource_filter_pressure_risk_count(risk_indicators)

    resource_availability_pressure_count =
      StrategyPressureRisk.resource_availability_pressure_risk_count(risk_indicators)

    resource_margin_pressure_count =
      StrategyPressureRisk.resource_margin_pressure_risk_count(risk_indicators)

    battery_depletion_pressure_count =
      StrategyPressureRisk.battery_depletion_pressure_risk_count(risk_indicators)

    station_calendar_pressure_count =
      StrategyPressureRisk.station_calendar_pressure_risk_count(risk_indicators)

    station_reservation_expiration_pressure_count =
      StrategyPressureRisk.station_reservation_expiration_pressure_risk_count(risk_indicators)

    candidate_rejection_pressure_count =
      StrategyPressureRisk.candidate_rejection_pressure_risk_count(risk_indicators)

    provider_counteroffer_pressure_count =
      StrategyPressureRisk.provider_counteroffer_pressure_risk_count(risk_indicators)

    model_acceptance_pressure_count =
      StrategyPressureRisk.model_acceptance_pressure_risk_count(risk_indicators)

    validation_safety_case_pressure_count =
      StrategyPressureRisk.validation_safety_case_pressure_risk_count(risk_indicators)

    schema_validation_pressure_count =
      StrategyPressureRisk.schema_validation_pressure_risk_count(risk_indicators)

    refresh_budget_pressure_count =
      StrategyPressureRisk.refresh_budget_pressure_risk_count(risk_indicators)

    refresh_freshness_pressure_count =
      StrategyPressureRisk.refresh_freshness_pressure_risk_count(risk_indicators)

    validation_refresh_pressure_count =
      StrategyPressureRisk.validation_refresh_pressure_risk_count(risk_indicators)

    relay_data_path_pressure_count =
      StrategyPressureRisk.relay_data_path_pressure_risk_count(risk_indicators)

    execution_feedback_pressure_count =
      StrategyPressureRisk.execution_feedback_pressure_risk_count(risk_indicators)

    generic_risk_count =
      max(
        risk_count - contact_allocation_pressure_count -
          provider_reservation_request_pressure_count - approval_boundary_pressure_count -
          station_reservation_conflict_pressure_count -
          candidate_diff_pressure_count -
          timeline_diff_pressure_count -
          link_capacity_pressure_count - contact_intent_pressure_count -
          contact_contention_pressure_count -
          contact_filter_pressure_count - command_window_pressure_count -
          objective_gap_pressure_count - timeline_feedback_pressure_count -
          operational_timeline_pressure_count -
          maneuver_review_pressure_count -
          operational_readiness_pressure_count - operator_training_pressure_count -
          import_readiness_pressure_count - quality_gate_pressure_count -
          timeline_integrity_pressure_count - timeline_dependency_impact_pressure_count -
          timeline_publication_pressure_count -
          timeline_transition_application_pressure_count -
          timeline_activity_state_pressure_count - timeline_lifecycle_pressure_count -
          timeline_precondition_pressure_count - timeline_preservation_pressure_count -
          timeline_pressure_count - storage_downlink_pressure_count -
          resource_projection_pressure_count -
          resource_filter_pressure_count -
          resource_availability_pressure_count - resource_margin_pressure_count -
          battery_depletion_pressure_count - station_calendar_pressure_count -
          station_reservation_expiration_pressure_count - candidate_rejection_pressure_count -
          provider_counteroffer_pressure_count -
          model_acceptance_pressure_count -
          validation_safety_case_pressure_count -
          schema_validation_pressure_count -
          refresh_budget_pressure_count -
          refresh_freshness_pressure_count -
          validation_refresh_pressure_count -
          relay_data_path_pressure_count - execution_feedback_pressure_count,
        0
      )

    mission_value_score =
      activities
      |> Enum.map(candidate_score)
      |> Enum.sum()
      |> Kernel.*(policy.mission_value_weight)

    coverage_score = target_count.(activities) * policy.coverage_weight
    revisit_score = revisit_count.(activities) * policy.revisit_weight
    latency_penalty = -collection_latency_s.(activities) * policy.latency_weight

    downlink_completion_score =
      downlink_completion_ratio.(activities, request) * policy.downlink_completion_weight

    fuel_preservation_score =
      fuel_preservation_score.(branch, request) * policy.fuel_preservation_weight

    schedule_stability_penalty =
      schedule_stability_penalty.(repair_score_terms) * policy.schedule_stability_weight

    asset_balance_score = asset_balance_score.(activities) * policy.asset_balance_weight

    priority_commitment_score =
      priority_commitment_score.(activities, request) * policy.priority_commitment_weight

    resource_score =
      numeric_or_nil.(Map.get(resource_impacts, "score_adjustment")) || 0.0

    feedback_adjustment_score =
      numeric_or_nil.(Map.get(feedback_adjustments, "score_adjustment")) || 0.0

    contact_allocation_pressure_penalty =
      -contact_allocation_pressure_count * policy.risk_weight

    provider_reservation_request_pressure_penalty =
      -provider_reservation_request_pressure_count * policy.risk_weight

    station_reservation_conflict_pressure_penalty =
      -station_reservation_conflict_pressure_count * policy.risk_weight

    candidate_diff_pressure_penalty =
      -candidate_diff_pressure_count * policy.risk_weight

    timeline_diff_pressure_penalty =
      -timeline_diff_pressure_count * policy.risk_weight

    link_capacity_pressure_penalty =
      -link_capacity_pressure_count * policy.risk_weight

    contact_intent_pressure_penalty =
      -contact_intent_pressure_count * policy.risk_weight

    contact_contention_pressure_penalty =
      -contact_contention_pressure_count * policy.risk_weight

    contact_filter_pressure_penalty =
      -contact_filter_pressure_count * policy.risk_weight

    command_window_pressure_penalty =
      -command_window_pressure_count * policy.risk_weight

    objective_gap_pressure_penalty =
      -objective_gap_pressure_count * policy.risk_weight

    timeline_feedback_pressure_penalty =
      -timeline_feedback_pressure_count * policy.risk_weight

    operational_timeline_pressure_penalty =
      -operational_timeline_pressure_count * policy.risk_weight

    maneuver_review_pressure_penalty =
      -maneuver_review_pressure_count * policy.risk_weight

    operational_readiness_pressure_penalty =
      -operational_readiness_pressure_count * policy.risk_weight

    operator_training_pressure_penalty =
      -operator_training_pressure_count * policy.risk_weight

    import_readiness_pressure_penalty =
      -import_readiness_pressure_count * policy.risk_weight

    quality_gate_pressure_penalty =
      -quality_gate_pressure_count * policy.risk_weight

    approval_boundary_pressure_penalty =
      -approval_boundary_pressure_count * policy.risk_weight

    timeline_integrity_pressure_penalty =
      -timeline_integrity_pressure_count * policy.risk_weight

    timeline_dependency_impact_pressure_penalty =
      -timeline_dependency_impact_pressure_count * policy.risk_weight

    timeline_publication_pressure_penalty =
      -timeline_publication_pressure_count * policy.risk_weight

    timeline_transition_application_pressure_penalty =
      -timeline_transition_application_pressure_count * policy.risk_weight

    timeline_activity_state_pressure_penalty =
      -timeline_activity_state_pressure_count * policy.risk_weight

    timeline_lifecycle_pressure_penalty =
      -timeline_lifecycle_pressure_count * policy.risk_weight

    timeline_precondition_pressure_penalty =
      -timeline_precondition_pressure_count * policy.risk_weight

    timeline_preservation_pressure_penalty =
      -timeline_preservation_pressure_count * policy.risk_weight

    timeline_pressure_penalty =
      -timeline_pressure_count * policy.risk_weight

    storage_downlink_pressure_penalty =
      -storage_downlink_pressure_count * policy.risk_weight

    resource_projection_pressure_penalty =
      -resource_projection_pressure_count * policy.risk_weight

    resource_filter_pressure_penalty =
      -resource_filter_pressure_count * policy.risk_weight

    resource_availability_pressure_penalty =
      -resource_availability_pressure_count * policy.risk_weight

    resource_margin_pressure_penalty =
      -resource_margin_pressure_count * policy.risk_weight

    battery_depletion_pressure_penalty =
      -battery_depletion_pressure_count * policy.risk_weight

    station_calendar_pressure_penalty =
      -station_calendar_pressure_count * policy.risk_weight

    station_reservation_expiration_pressure_penalty =
      -station_reservation_expiration_pressure_count * policy.risk_weight

    candidate_rejection_pressure_penalty =
      -candidate_rejection_pressure_count * policy.risk_weight

    provider_counteroffer_pressure_penalty =
      -provider_counteroffer_pressure_count * policy.risk_weight

    model_acceptance_pressure_penalty =
      -model_acceptance_pressure_count * policy.risk_weight

    validation_safety_case_pressure_penalty =
      -validation_safety_case_pressure_count * policy.risk_weight

    schema_validation_pressure_penalty =
      -schema_validation_pressure_count * policy.risk_weight

    refresh_budget_pressure_penalty =
      -refresh_budget_pressure_count * policy.risk_weight

    refresh_freshness_pressure_penalty =
      -refresh_freshness_pressure_count * policy.risk_weight

    validation_refresh_pressure_penalty =
      -validation_refresh_pressure_count * policy.risk_weight

    relay_data_path_pressure_penalty =
      -relay_data_path_pressure_count * policy.risk_weight

    execution_feedback_pressure_penalty =
      -execution_feedback_pressure_count * policy.risk_weight

    risk_penalty = -generic_risk_count * policy.risk_weight
    approval_load_penalty = -approval_count * policy.approval_load_weight

    raw_score =
      mission_value_score + coverage_score + revisit_score + latency_penalty +
        downlink_completion_score + fuel_preservation_score + schedule_stability_penalty +
        asset_balance_score + priority_commitment_score + resource_score +
        feedback_adjustment_score + contact_allocation_pressure_penalty +
        provider_reservation_request_pressure_penalty +
        station_reservation_conflict_pressure_penalty +
        candidate_diff_pressure_penalty +
        timeline_diff_pressure_penalty +
        link_capacity_pressure_penalty + contact_intent_pressure_penalty +
        contact_contention_pressure_penalty + operational_readiness_pressure_penalty +
        contact_filter_pressure_penalty + command_window_pressure_penalty +
        objective_gap_pressure_penalty +
        timeline_feedback_pressure_penalty +
        operational_timeline_pressure_penalty +
        maneuver_review_pressure_penalty +
        operator_training_pressure_penalty + import_readiness_pressure_penalty +
        quality_gate_pressure_penalty +
        approval_boundary_pressure_penalty +
        timeline_integrity_pressure_penalty + timeline_dependency_impact_pressure_penalty +
        timeline_publication_pressure_penalty +
        timeline_transition_application_pressure_penalty +
        timeline_activity_state_pressure_penalty + timeline_lifecycle_pressure_penalty +
        timeline_precondition_pressure_penalty + timeline_preservation_pressure_penalty +
        timeline_pressure_penalty + storage_downlink_pressure_penalty +
        resource_projection_pressure_penalty +
        resource_filter_pressure_penalty +
        resource_availability_pressure_penalty + resource_margin_pressure_penalty +
        battery_depletion_pressure_penalty + station_calendar_pressure_penalty +
        station_reservation_expiration_pressure_penalty +
        candidate_rejection_pressure_penalty + provider_counteroffer_pressure_penalty +
        model_acceptance_pressure_penalty + validation_safety_case_pressure_penalty +
        schema_validation_pressure_penalty +
        refresh_budget_pressure_penalty +
        refresh_freshness_pressure_penalty +
        validation_refresh_pressure_penalty +
        relay_data_path_pressure_penalty + execution_feedback_pressure_penalty +
        risk_penalty + approval_load_penalty

    probability = Map.get(branch, "probability", 1.0)
    expected_score = raw_score * probability * policy.probability_weight

    %{
      "mission_value_score" => mission_value_score,
      "coverage_score" => coverage_score,
      "revisit_score" => revisit_score,
      "latency_penalty" => latency_penalty,
      "downlink_completion_score" => downlink_completion_score,
      "fuel_preservation_score" => fuel_preservation_score,
      "schedule_stability_penalty" => schedule_stability_penalty,
      "asset_balance_score" => asset_balance_score,
      "priority_commitment_score" => priority_commitment_score,
      "resource_score" => resource_score,
      "feedback_adjustment_score" => feedback_adjustment_score,
      "contact_allocation_pressure_penalty" => contact_allocation_pressure_penalty,
      "provider_reservation_request_pressure_penalty" =>
        provider_reservation_request_pressure_penalty,
      "station_reservation_conflict_pressure_penalty" =>
        station_reservation_conflict_pressure_penalty,
      "candidate_diff_pressure_penalty" => candidate_diff_pressure_penalty,
      "timeline_diff_pressure_penalty" => timeline_diff_pressure_penalty,
      "link_capacity_pressure_penalty" => link_capacity_pressure_penalty,
      "contact_intent_pressure_penalty" => contact_intent_pressure_penalty,
      "contact_contention_pressure_penalty" => contact_contention_pressure_penalty,
      "contact_filter_pressure_penalty" => contact_filter_pressure_penalty,
      "command_window_pressure_penalty" => command_window_pressure_penalty,
      "objective_gap_pressure_penalty" => objective_gap_pressure_penalty,
      "timeline_feedback_pressure_penalty" => timeline_feedback_pressure_penalty,
      "operational_timeline_pressure_penalty" => operational_timeline_pressure_penalty,
      "maneuver_review_pressure_penalty" => maneuver_review_pressure_penalty,
      "operational_readiness_pressure_penalty" => operational_readiness_pressure_penalty,
      "operator_training_pressure_penalty" => operator_training_pressure_penalty,
      "import_readiness_pressure_penalty" => import_readiness_pressure_penalty,
      "quality_gate_pressure_penalty" => quality_gate_pressure_penalty,
      "approval_boundary_pressure_penalty" => approval_boundary_pressure_penalty,
      "timeline_integrity_pressure_penalty" => timeline_integrity_pressure_penalty,
      "timeline_dependency_impact_pressure_penalty" =>
        timeline_dependency_impact_pressure_penalty,
      "timeline_publication_pressure_penalty" => timeline_publication_pressure_penalty,
      "timeline_transition_application_pressure_penalty" =>
        timeline_transition_application_pressure_penalty,
      "timeline_activity_state_pressure_penalty" => timeline_activity_state_pressure_penalty,
      "timeline_lifecycle_pressure_penalty" => timeline_lifecycle_pressure_penalty,
      "timeline_precondition_pressure_penalty" => timeline_precondition_pressure_penalty,
      "timeline_preservation_pressure_penalty" => timeline_preservation_pressure_penalty,
      "timeline_pressure_penalty" => timeline_pressure_penalty,
      "storage_downlink_pressure_penalty" => storage_downlink_pressure_penalty,
      "resource_projection_pressure_penalty" => resource_projection_pressure_penalty,
      "resource_filter_pressure_penalty" => resource_filter_pressure_penalty,
      "resource_availability_pressure_penalty" => resource_availability_pressure_penalty,
      "resource_margin_pressure_penalty" => resource_margin_pressure_penalty,
      "battery_depletion_pressure_penalty" => battery_depletion_pressure_penalty,
      "station_calendar_pressure_penalty" => station_calendar_pressure_penalty,
      "station_reservation_expiration_pressure_penalty" =>
        station_reservation_expiration_pressure_penalty,
      "candidate_rejection_pressure_penalty" => candidate_rejection_pressure_penalty,
      "provider_counteroffer_pressure_penalty" => provider_counteroffer_pressure_penalty,
      "model_acceptance_pressure_penalty" => model_acceptance_pressure_penalty,
      "validation_safety_case_pressure_penalty" => validation_safety_case_pressure_penalty,
      "schema_validation_pressure_penalty" => schema_validation_pressure_penalty,
      "refresh_budget_pressure_penalty" => refresh_budget_pressure_penalty,
      "refresh_freshness_pressure_penalty" => refresh_freshness_pressure_penalty,
      "validation_refresh_pressure_penalty" => validation_refresh_pressure_penalty,
      "relay_data_path_pressure_penalty" => relay_data_path_pressure_penalty,
      "execution_feedback_pressure_penalty" => execution_feedback_pressure_penalty,
      "risk_penalty" => risk_penalty,
      "approval_load_penalty" => approval_load_penalty,
      "raw_score" => raw_score,
      "branch_probability" => probability,
      "expected_score" => expected_score
    }
  end

  defp default_callbacks,
    do: [
      branch_approval_requirements: &BranchApprovalRequirements.build/2,
      candidate_score: &candidate_score/1,
      target_count: &StrategyMetrics.target_count/1,
      revisit_count: &StrategyMetrics.revisit_count/1,
      collection_latency_s: &StrategyMetrics.collection_latency_s/1,
      downlink_completion_ratio: &StrategyMetrics.downlink_completion_ratio/2,
      fuel_preservation_score: &fuel_preservation_score/2,
      schedule_stability_penalty: &StrategyMetrics.schedule_stability_penalty/1,
      asset_balance_score: &StrategyMetrics.asset_balance_score/1,
      priority_commitment_score: &StrategyMetrics.priority_commitment_score/2,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1
    ]

  defp candidate_score(candidate),
    do: ScalarValues.numeric_or_nil(Map.get(candidate, "score")) || 0.0

  defp fuel_preservation_score(branch, request) do
    fuel_mode? = Enum.any?(branch["events"], &(&1["type"] == "fuel_preservation_mode"))

    fuel_margin =
      request.mission_state
      |> get_in(["resources", "fuel_margin"])
      |> case do
        nil -> 1.0
        value -> value
      end

    if fuel_mode?, do: fuel_margin, else: fuel_margin * 0.25
  end
end
