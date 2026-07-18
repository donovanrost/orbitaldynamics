defmodule OrbitalDynamics.CampaignPlanner.DerivedActivityPressureBranches do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivitySourceRows,
    ContactIntentPressureBranches,
    ContactIntentSourceReports,
    OperationalTimelinePressureEvents,
    RealizedFeedbackPressureEvents
  }

  def build(prior_plan, mission_state) do
    []
    |> Kernel.++(prior_planned_activity(prior_plan))
    |> Kernel.++(mission_planned_activity(mission_state))
    |> Kernel.++(prior_proposed_contact(prior_plan))
    |> Kernel.++(mission_proposed_contact(mission_state))
    |> Kernel.++(prior_contact_intent(prior_plan))
    |> Kernel.++(prior_contact_intent_summary(prior_plan))
    |> Kernel.++(mission_contact_intent(mission_state))
    |> Kernel.++(mission_contact_intent_summary(mission_state))
    |> Kernel.++(prior_realized_activity(prior_plan))
    |> Kernel.++(mission_realized_activity(mission_state, prior_plan))
  end

  defp prior_planned_activity(prior_plan) do
    prior_plan
    |> ActivitySourceRows.prior_plan_planned_activity_pressure_rows_with_source()
    |> pressure_branches(OperationalTimelinePressureEvents)
  end

  defp mission_planned_activity(mission_state) do
    mission_state
    |> ActivitySourceRows.mission_state_planned_activity_pressure_rows_with_source()
    |> pressure_branches(OperationalTimelinePressureEvents)
  end

  defp prior_proposed_contact(prior_plan) do
    prior_plan
    |> ActivitySourceRows.prior_plan_proposed_contact_pressure_rows_with_source()
    |> pressure_branches(OperationalTimelinePressureEvents)
  end

  defp mission_proposed_contact(mission_state) do
    mission_state
    |> ActivitySourceRows.mission_state_proposed_contact_pressure_rows_with_source()
    |> pressure_branches(OperationalTimelinePressureEvents)
  end

  defp prior_contact_intent(prior_plan) do
    prior_plan
    |> ContactIntentSourceReports.prior_plan_rows_with_source()
    |> ContactIntentPressureBranches.from_rows_with_source()
  end

  defp prior_contact_intent_summary(prior_plan) do
    direct_identities =
      prior_plan
      |> ContactIntentSourceReports.prior_plan_rows_with_source()
      |> ContactIntentPressureBranches.identity_set()

    prior_plan
    |> ContactIntentSourceReports.prior_plan_summaries_with_source()
    |> ContactIntentPressureBranches.summaries_from_sources(direct_identities)
  end

  defp mission_contact_intent(mission_state) do
    mission_state
    |> ContactIntentSourceReports.mission_state_rows_with_source()
    |> ContactIntentPressureBranches.from_rows_with_source()
  end

  defp mission_contact_intent_summary(mission_state) do
    direct_identities =
      mission_state
      |> ContactIntentSourceReports.mission_state_rows_with_source()
      |> ContactIntentPressureBranches.identity_set()

    mission_state
    |> ContactIntentSourceReports.mission_state_summaries_with_source()
    |> ContactIntentPressureBranches.summaries_from_sources(direct_identities)
  end

  defp prior_realized_activity(prior_plan) do
    prior_plan
    |> ActivitySourceRows.prior_plan_realized_activity_pressure_rows_with_source()
    |> pressure_branches(RealizedFeedbackPressureEvents)
  end

  defp mission_realized_activity(mission_state, prior_plan) do
    mission_state
    |> ActivitySourceRows.mission_state_realized_activity_pressure_rows_with_source(prior_plan)
    |> pressure_branches(RealizedFeedbackPressureEvents)
  end

  defp pressure_branches(rows, events) do
    Enum.flat_map(rows, fn {row, source_path, index} ->
      events.pressure_branch(row, source_path, index)
    end)
  end
end
