defmodule OrbitalDynamics.CampaignPlanner.StrategyPressureRisk do
  @moduledoc false

  alias __MODULE__.{
    CandidateSource,
    Communications,
    ContactAllocation,
    DiffReports,
    ExecutionFeedback,
    Governance,
    Resources,
    SourceReports,
    Station,
    Timeline,
    ValidationRefresh
  }

  def contact_allocation_pressure_risk_count(risk_indicators) do
    ContactAllocation.contact_allocation_pressure_risk_count(risk_indicators)
  end

  def contact_allocation_pressure_risk?(risk),
    do: ContactAllocation.contact_allocation_pressure_risk?(risk)

  def provider_reservation_request_pressure_risk_count(risk_indicators) do
    ContactAllocation.provider_reservation_request_pressure_risk_count(risk_indicators)
  end

  def station_reservation_conflict_pressure_risk_count(risk_indicators) do
    ContactAllocation.station_reservation_conflict_pressure_risk_count(risk_indicators)
  end

  def candidate_diff_pressure_risk_count(risk_indicators) do
    DiffReports.candidate_diff_pressure_risk_count(risk_indicators)
  end

  def candidate_diff_event_pressure_risk?(risk),
    do: DiffReports.candidate_diff_event_pressure_risk?(risk)

  def timeline_diff_pressure_risk_count(risk_indicators) do
    DiffReports.timeline_diff_pressure_risk_count(risk_indicators)
  end

  def timeline_diff_event_pressure_risk?(risk),
    do: DiffReports.timeline_diff_event_pressure_risk?(risk)

  def link_capacity_pressure_risk_count(risk_indicators) do
    Communications.link_capacity_pressure_risk_count(risk_indicators)
  end

  def link_capacity_pressure_risk?(risk), do: Communications.link_capacity_pressure_risk?(risk)

  def contact_intent_pressure_risk_count(risk_indicators) do
    Communications.contact_intent_pressure_risk_count(risk_indicators)
  end

  def contact_contention_pressure_risk_count(risk_indicators) do
    Communications.contact_contention_pressure_risk_count(risk_indicators)
  end

  def contact_filter_pressure_risk_count(risk_indicators) do
    Communications.contact_filter_pressure_risk_count(risk_indicators)
  end

  def contact_filter_pressure_risk?(risk), do: Communications.contact_filter_pressure_risk?(risk)

  def command_window_pressure_risk_count(risk_indicators) do
    SourceReports.command_window_pressure_risk_count(risk_indicators)
  end

  def objective_gap_pressure_risk_count(risk_indicators) do
    SourceReports.objective_gap_pressure_risk_count(risk_indicators)
  end

  def objective_gap_event_pressure_risk?(risk),
    do: SourceReports.objective_gap_event_pressure_risk?(risk)

  def timeline_feedback_pressure_risk_count(risk_indicators) do
    SourceReports.timeline_feedback_pressure_risk_count(risk_indicators)
  end

  def timeline_feedback_event_pressure_risk?(risk),
    do: SourceReports.timeline_feedback_event_pressure_risk?(risk)

  def operational_timeline_pressure_risk_count(risk_indicators) do
    SourceReports.operational_timeline_pressure_risk_count(risk_indicators)
  end

  def operational_timeline_event_pressure_risk?(risk),
    do: SourceReports.operational_timeline_event_pressure_risk?(risk)

  def maneuver_review_pressure_risk_count(risk_indicators) do
    SourceReports.maneuver_review_pressure_risk_count(risk_indicators)
  end

  def operational_readiness_pressure_risk_count(risk_indicators) do
    Governance.operational_readiness_pressure_risk_count(risk_indicators)
  end

  def operational_readiness_pressure_event_risk?(risk),
    do: Governance.operational_readiness_pressure_event_risk?(risk)

  def quality_gate_pressure_risk_count(risk_indicators) do
    Governance.quality_gate_pressure_risk_count(risk_indicators)
  end

  def quality_gate_pressure_event_risk?(risk),
    do: Governance.quality_gate_pressure_event_risk?(risk)

  def operator_training_pressure_risk_count(risk_indicators) do
    Governance.operator_training_pressure_risk_count(risk_indicators)
  end

  def import_readiness_pressure_risk_count(risk_indicators) do
    Governance.import_readiness_pressure_risk_count(risk_indicators)
  end

  def approval_boundary_pressure_risk_count(risk_indicators) do
    Governance.approval_boundary_pressure_risk_count(risk_indicators)
  end

  def timeline_integrity_pressure_risk_count(risk_indicators) do
    Timeline.timeline_integrity_pressure_risk_count(risk_indicators)
  end

  def timeline_integrity_pressure_risk?(risk),
    do: Timeline.timeline_integrity_pressure_risk?(risk)

  def timeline_dependency_impact_pressure_risk_count(risk_indicators) do
    Timeline.timeline_dependency_impact_pressure_risk_count(risk_indicators)
  end

  def timeline_dependency_impact_pressure_risk?(risk),
    do: Timeline.timeline_dependency_impact_pressure_risk?(risk)

  def timeline_publication_pressure_risk_count(risk_indicators) do
    Timeline.timeline_publication_pressure_risk_count(risk_indicators)
  end

  def timeline_publication_pressure_risk?(risk),
    do: Timeline.timeline_publication_pressure_risk?(risk)

  def timeline_transition_application_pressure_risk_count(risk_indicators) do
    Timeline.timeline_transition_application_pressure_risk_count(risk_indicators)
  end

  def timeline_transition_application_pressure_risk?(risk),
    do: Timeline.timeline_transition_application_pressure_risk?(risk)

  def timeline_activity_state_pressure_risk_count(risk_indicators) do
    Timeline.timeline_activity_state_pressure_risk_count(risk_indicators)
  end

  def timeline_lifecycle_pressure_risk_count(risk_indicators) do
    Timeline.timeline_lifecycle_pressure_risk_count(risk_indicators)
  end

  def timeline_lifecycle_state_review_risk?(risk),
    do: Timeline.timeline_lifecycle_state_review_risk?(risk)

  def timeline_activity_lifecycle_state_review_risk?(risk),
    do: Timeline.timeline_activity_lifecycle_state_review_risk?(risk)

  def timeline_precondition_pressure_risk_count(risk_indicators) do
    Timeline.timeline_precondition_pressure_risk_count(risk_indicators)
  end

  def timeline_precondition_pressure_risk?(risk),
    do: Timeline.timeline_precondition_pressure_risk?(risk)

  def timeline_preservation_pressure_risk_count(risk_indicators) do
    Timeline.timeline_preservation_pressure_risk_count(risk_indicators)
  end

  def timeline_pressure_risk_count(risk_indicators) do
    Timeline.timeline_pressure_risk_count(risk_indicators)
  end

  def storage_downlink_pressure_risk_count(risk_indicators) do
    Resources.storage_downlink_pressure_risk_count(risk_indicators)
  end

  def resource_projection_pressure_risk_count(risk_indicators) do
    Resources.resource_projection_pressure_risk_count(risk_indicators)
  end

  def resource_filter_pressure_risk_count(risk_indicators) do
    Resources.resource_filter_pressure_risk_count(risk_indicators)
  end

  def resource_availability_pressure_risk_count(risk_indicators) do
    Governance.resource_availability_pressure_risk_count(risk_indicators)
  end

  def resource_margin_pressure_risk_count(risk_indicators) do
    Resources.resource_margin_pressure_risk_count(risk_indicators)
  end

  def battery_depletion_pressure_risk_count(risk_indicators) do
    Resources.battery_depletion_pressure_risk_count(risk_indicators)
  end

  def station_calendar_pressure_risk_count(risk_indicators) do
    Station.station_calendar_pressure_risk_count(risk_indicators)
  end

  def station_calendar_pressure_risk?(risk), do: Station.station_calendar_pressure_risk?(risk)

  def station_reservation_expiration_pressure_risk_count(risk_indicators) do
    Station.station_reservation_expiration_pressure_risk_count(risk_indicators)
  end

  def station_reservation_expiration_pressure_risk?(risk) do
    Station.station_reservation_expiration_pressure_risk?(risk)
  end

  def candidate_rejection_pressure_risk_count(risk_indicators) do
    CandidateSource.candidate_rejection_pressure_risk_count(risk_indicators)
  end

  def candidate_rejection_pressure_risk?(risk),
    do: CandidateSource.candidate_rejection_pressure_risk?(risk)

  def provider_counteroffer_pressure_risk_count(risk_indicators) do
    CandidateSource.provider_counteroffer_pressure_risk_count(risk_indicators)
  end

  def provider_counteroffer_pressure_risk?(risk),
    do: CandidateSource.provider_counteroffer_pressure_risk?(risk)

  def model_acceptance_pressure_risk_count(risk_indicators) do
    ValidationRefresh.model_acceptance_pressure_risk_count(risk_indicators)
  end

  def model_acceptance_pressure_risk?(risk),
    do: ValidationRefresh.model_acceptance_pressure_risk?(risk)

  def schema_validation_pressure_risk?(risk),
    do: ValidationRefresh.schema_validation_pressure_risk?(risk)

  def schema_validation_pressure_risk_count(risk_indicators) do
    ValidationRefresh.schema_validation_pressure_risk_count(risk_indicators)
  end

  def refresh_freshness_pressure_risk?(risk),
    do: ValidationRefresh.refresh_freshness_pressure_risk?(risk)

  def refresh_freshness_pressure_risk_count(risk_indicators) do
    ValidationRefresh.refresh_freshness_pressure_risk_count(risk_indicators)
  end

  def refresh_budget_pressure_risk?(risk),
    do: ValidationRefresh.refresh_budget_pressure_risk?(risk)

  def refresh_budget_pressure_risk_count(risk_indicators) do
    ValidationRefresh.refresh_budget_pressure_risk_count(risk_indicators)
  end

  def validation_safety_case_pressure_risk?(risk),
    do: ValidationRefresh.validation_safety_case_pressure_risk?(risk)

  def validation_safety_case_pressure_risk_count(risk_indicators) do
    ValidationRefresh.validation_safety_case_pressure_risk_count(risk_indicators)
  end

  def validation_refresh_pressure_risk_count(risk_indicators) do
    ValidationRefresh.validation_refresh_pressure_risk_count(risk_indicators)
  end

  def relay_data_path_pressure_risk_count(risk_indicators) do
    Resources.relay_data_path_pressure_risk_count(risk_indicators)
  end

  def execution_feedback_pressure_risk_count(risk_indicators) do
    ExecutionFeedback.execution_feedback_pressure_risk_count(risk_indicators)
  end
end
