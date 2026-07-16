defmodule OrbitalDynamics.CampaignPlanner.ReviewRowSources do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    CandidateDiffPressureEvents,
    CommandWindowOperationalFeedback,
    ConstraintReviewRows,
    ContactAllocationReviewRows,
    ContactIntentReviewRows,
    LinkCapacityReviewRows,
    ManeuverReviewOperationalFeedback,
    ObjectiveReviewRows,
    OperatorReviewFeedbackRows,
    RealizedFeedbackPressureEvents,
    RefreshBudgetPressureEvents,
    RefreshFreshnessPressureEvents,
    ResourceProjectionReviewRows,
    ScoreTermReviewRows,
    StationCalendarReviewRows,
    SuppressionReviewRows
  }

  def operational_timeline(%{"source_operational_timeline" => %{} = source} = row)
      when map_size(source) > 0 do
    {OperatorReviewFeedbackRows.operational_timeline_row(row), "source_operational_timeline"}
  end

  def operational_timeline(row),
    do: {OperatorReviewFeedbackRows.operational_timeline_row(row), "operational_timeline_review"}

  def operational_timeline(row, _callbacks), do: operational_timeline(row)

  def candidate_diff(row), do: CandidateDiffPressureEvents.source(row)

  def candidate_diff(row, _callbacks), do: candidate_diff(row)

  def refresh_budget(row), do: RefreshBudgetPressureEvents.source(row)

  def refresh_budget(row, _callbacks), do: refresh_budget(row)

  def freshness(row), do: RefreshFreshnessPressureEvents.source(row)

  def freshness(row, _callbacks), do: freshness(row)

  def command_window(row), do: CommandWindowOperationalFeedback.source(row)

  def command_window(row, _callbacks), do: command_window(row)

  def maneuver_review(row), do: ManeuverReviewOperationalFeedback.source(row)

  def maneuver_review(row, _callbacks), do: maneuver_review(row)

  def realized_feedback(row), do: RealizedFeedbackPressureEvents.source(row)

  def realized_feedback(row, _callbacks), do: realized_feedback(row)

  def resource_projection(row), do: ResourceProjectionReviewRows.source(row)

  def link_capacity(row), do: LinkCapacityReviewRows.source(row)

  def contact_allocation(row), do: ContactAllocationReviewRows.source(row)

  def contact_allocation_capacity_pack(row),
    do: ContactAllocationReviewRows.capacity_pack_source(row)

  def contact_allocation_capacity_pack(row, _callbacks), do: contact_allocation_capacity_pack(row)

  def contact_intent(row), do: ContactIntentReviewRows.source(row)

  def contact_intent(row, _callbacks), do: contact_intent(row)

  def contact_intent_row(source, row), do: ContactIntentReviewRows.row(source, row)

  def contact_intent_row(source, row, _callbacks), do: contact_intent_row(source, row)

  def station_calendar_pressure_branches(row, trust_boundary, source_prefix, callbacks) do
    StationCalendarReviewRows.pressure_branches(
      row,
      trust_boundary,
      source_prefix,
      callbacks
    )
  end

  def contact_suppression(row), do: SuppressionReviewRows.contact_source(row)

  def resource_suppression(row), do: SuppressionReviewRows.resource_source(row)

  def objective_satisfaction(row), do: ObjectiveReviewRows.satisfaction_source(row)

  def objective_satisfaction(row, _callbacks), do: objective_satisfaction(row)

  def flattened_objective_satisfaction(row),
    do: ObjectiveReviewRows.flattened_satisfaction_row(row)

  def flattened_objective_satisfaction(row, _callbacks),
    do: flattened_objective_satisfaction(row)

  def objective_tradeoff(row), do: ObjectiveReviewRows.tradeoff_source(row)

  def constraint(row), do: ConstraintReviewRows.source(row)

  def constraint(row, _callbacks), do: constraint(row)

  def flattened_constraint(row), do: ConstraintReviewRows.flattened_row(row)

  def flattened_constraint(row, _callbacks), do: flattened_constraint(row)

  def score_term(row), do: ScoreTermReviewRows.source(row)
end
