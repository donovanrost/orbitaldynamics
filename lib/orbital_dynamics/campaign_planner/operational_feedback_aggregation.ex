defmodule OrbitalDynamics.CampaignPlanner.OperationalFeedbackAggregation do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    DirectOperationalFeedback,
    OperationalFeedbackNormalization,
    OperationalFeedbackSources
  }

  def source_rows(rows) do
    OperationalFeedbackSources.source_rows(rows)
  end

  def source_rows(rows, callbacks) do
    Enum.reduce(rows, callback!(callbacks, :normalize_operational_feedback).(%{}), fn row,
                                                                                      merged ->
      feedback = Map.get(row, "source_operational_feedback", %{})
      callback!(callbacks, :merge_operational_feedback).(merged, feedback)
    end)
  end

  def prior_plan(prior_plan) do
    source_feedback =
      OperationalFeedbackSources.prior_plan_timeline_feedback_operational_feedback(prior_plan)

    planned_activity_feedback =
      OperationalFeedbackSources.prior_plan_planned_activity_operational_feedback(prior_plan)

    proposed_contact_feedback =
      OperationalFeedbackSources.prior_plan_proposed_contact_operational_feedback(prior_plan)

    realized_activity_feedback =
      OperationalFeedbackSources.prior_plan_realized_activity_operational_feedback(prior_plan)

    operational_timeline_feedback =
      OperationalFeedbackSources.prior_plan_operational_timeline_operational_feedback(prior_plan)

    command_window_feedback =
      OperationalFeedbackSources.prior_plan_command_window_operational_feedback(prior_plan)

    maneuver_review_feedback =
      OperationalFeedbackSources.prior_plan_maneuver_review_operational_feedback(prior_plan)

    cadence_import_source_feedback =
      OperationalFeedbackSources.prior_plan_cadence_import_source_operational_feedback(prior_plan)

    cadence_import_feedback =
      OperationalFeedbackSources.prior_plan_cadence_import_operational_feedback(prior_plan)

    operator_review_source_feedback =
      OperationalFeedbackSources.prior_plan_operator_review_source_operational_feedback(
        prior_plan
      )

    operator_review_feedback =
      OperationalFeedbackSources.prior_plan_operator_review_operational_feedback(prior_plan)

    direct_feedback = DirectOperationalFeedback.prior_plan_feedback(prior_plan)

    direct_feedback
    |> OperationalFeedbackNormalization.normalize()
    |> then(&OperationalFeedbackNormalization.merge(operator_review_feedback, &1))
    |> then(&OperationalFeedbackNormalization.merge(operator_review_source_feedback, &1))
    |> then(&OperationalFeedbackNormalization.merge(cadence_import_feedback, &1))
    |> then(&OperationalFeedbackNormalization.merge(cadence_import_source_feedback, &1))
    |> then(&OperationalFeedbackNormalization.merge(maneuver_review_feedback, &1))
    |> then(&OperationalFeedbackNormalization.merge(command_window_feedback, &1))
    |> then(&OperationalFeedbackNormalization.merge(operational_timeline_feedback, &1))
    |> then(&OperationalFeedbackNormalization.merge(realized_activity_feedback, &1))
    |> then(&OperationalFeedbackNormalization.merge(proposed_contact_feedback, &1))
    |> then(&OperationalFeedbackNormalization.merge(planned_activity_feedback, &1))
    |> then(&OperationalFeedbackNormalization.merge(source_feedback, &1))
  end

  def prior_plan(prior_plan, callbacks) do
    source_feedback =
      callback!(callbacks, :prior_plan_timeline_feedback_operational_feedback).(prior_plan)

    planned_activity_feedback =
      callback!(callbacks, :prior_plan_planned_activity_operational_feedback).(prior_plan)

    proposed_contact_feedback =
      callback!(callbacks, :prior_plan_proposed_contact_operational_feedback).(prior_plan)

    realized_activity_feedback =
      callback!(callbacks, :prior_plan_realized_activity_operational_feedback).(prior_plan)

    operational_timeline_feedback =
      callback!(callbacks, :prior_plan_operational_timeline_operational_feedback).(prior_plan)

    command_window_feedback =
      callback!(callbacks, :prior_plan_command_window_operational_feedback).(prior_plan)

    maneuver_review_feedback =
      callback!(callbacks, :prior_plan_maneuver_review_operational_feedback).(prior_plan)

    cadence_import_source_feedback =
      callback!(callbacks, :prior_plan_cadence_import_source_operational_feedback).(prior_plan)

    cadence_import_feedback =
      callback!(callbacks, :prior_plan_cadence_import_operational_feedback).(prior_plan)

    operator_review_source_feedback =
      callback!(callbacks, :prior_plan_operator_review_source_operational_feedback).(prior_plan)

    operator_review_feedback =
      callback!(callbacks, :prior_plan_operator_review_operational_feedback).(prior_plan)

    direct_feedback =
      callback!(callbacks, :prior_plan_direct_operational_feedback).(prior_plan)

    direct_feedback
    |> callback!(callbacks, :normalize_operational_feedback).()
    |> then(&merge(callbacks, operator_review_feedback, &1))
    |> then(&merge(callbacks, operator_review_source_feedback, &1))
    |> then(&merge(callbacks, cadence_import_feedback, &1))
    |> then(&merge(callbacks, cadence_import_source_feedback, &1))
    |> then(&merge(callbacks, maneuver_review_feedback, &1))
    |> then(&merge(callbacks, command_window_feedback, &1))
    |> then(&merge(callbacks, operational_timeline_feedback, &1))
    |> then(&merge(callbacks, realized_activity_feedback, &1))
    |> then(&merge(callbacks, proposed_contact_feedback, &1))
    |> then(&merge(callbacks, planned_activity_feedback, &1))
    |> then(&merge(callbacks, source_feedback, &1))
  end

  def mission_state(mission_state, prior_plan, realized_activities_feedback, callbacks) do
    mission_report_feedback =
      mission_state
      |> callback!(callbacks, :mission_state_timeline_feedback_report).()
      |> Map.get("operational_feedback", %{})

    mission_planned_activity_feedback =
      callback!(callbacks, :mission_state_planned_activity_operational_feedback).(mission_state)

    mission_proposed_contact_feedback =
      callback!(callbacks, :mission_state_proposed_contact_operational_feedback).(mission_state)

    mission_realized_activity_feedback =
      callback!(callbacks, :mission_state_realized_activity_operational_feedback).(
        mission_state,
        prior_plan
      )

    mission_operational_timeline_feedback =
      callback!(callbacks, :mission_state_operational_timeline_operational_feedback).(
        mission_state
      )

    mission_command_window_feedback =
      callback!(callbacks, :mission_state_command_window_operational_feedback).(mission_state)

    mission_maneuver_review_feedback =
      callback!(callbacks, :mission_state_maneuver_review_operational_feedback).(mission_state)

    mission_cadence_import_source_feedback =
      callback!(callbacks, :mission_state_cadence_import_source_operational_feedback).(
        mission_state
      )

    mission_cadence_import_feedback =
      callback!(callbacks, :mission_state_cadence_import_operational_feedback).(mission_state)

    mission_operator_review_source_feedback =
      callback!(callbacks, :mission_state_operator_review_source_operational_feedback).(
        mission_state
      )

    mission_operator_review_feedback =
      callback!(callbacks, :mission_state_operator_review_operational_feedback).(mission_state)

    mission_direct_feedback =
      callback!(callbacks, :mission_state_direct_operational_feedback).(mission_state)

    realized_activities_feedback
    |> then(&merge(callbacks, &1, mission_realized_activity_feedback))
    |> then(&merge(callbacks, &1, mission_planned_activity_feedback))
    |> then(&merge(callbacks, &1, mission_proposed_contact_feedback))
    |> then(&merge(callbacks, &1, mission_operational_timeline_feedback))
    |> then(&merge(callbacks, &1, mission_command_window_feedback))
    |> then(&merge(callbacks, &1, mission_maneuver_review_feedback))
    |> then(&merge(callbacks, &1, mission_cadence_import_source_feedback))
    |> then(&merge(callbacks, &1, mission_cadence_import_feedback))
    |> then(&merge(callbacks, &1, mission_operator_review_source_feedback))
    |> then(&merge(callbacks, &1, mission_operator_review_feedback))
    |> then(&merge(callbacks, &1, mission_report_feedback))
    |> then(&merge(callbacks, &1, mission_direct_feedback))
  end

  def mission_state(mission_state, prior_plan, realized_activities_feedback) do
    mission_report_feedback =
      mission_state
      |> OperationalFeedbackSources.mission_state_timeline_feedback_report()
      |> Map.get("operational_feedback", %{})

    mission_planned_activity_feedback =
      OperationalFeedbackSources.mission_state_planned_activity_operational_feedback(
        mission_state
      )

    mission_proposed_contact_feedback =
      OperationalFeedbackSources.mission_state_proposed_contact_operational_feedback(
        mission_state
      )

    mission_realized_activity_feedback =
      OperationalFeedbackSources.mission_state_realized_activity_operational_feedback(
        mission_state,
        prior_plan
      )

    mission_operational_timeline_feedback =
      OperationalFeedbackSources.mission_state_operational_timeline_operational_feedback(
        mission_state
      )

    mission_command_window_feedback =
      OperationalFeedbackSources.mission_state_command_window_operational_feedback(mission_state)

    mission_maneuver_review_feedback =
      OperationalFeedbackSources.mission_state_maneuver_review_operational_feedback(mission_state)

    mission_cadence_import_source_feedback =
      OperationalFeedbackSources.mission_state_cadence_import_source_operational_feedback(
        mission_state
      )

    mission_cadence_import_feedback =
      OperationalFeedbackSources.mission_state_cadence_import_operational_feedback(mission_state)

    mission_operator_review_source_feedback =
      OperationalFeedbackSources.mission_state_operator_review_source_operational_feedback(
        mission_state
      )

    mission_operator_review_feedback =
      OperationalFeedbackSources.mission_state_operator_review_operational_feedback(mission_state)

    mission_direct_feedback = DirectOperationalFeedback.mission_state_feedback(mission_state)

    realized_activities_feedback
    |> then(&OperationalFeedbackNormalization.merge(&1, mission_realized_activity_feedback))
    |> then(&OperationalFeedbackNormalization.merge(&1, mission_planned_activity_feedback))
    |> then(&OperationalFeedbackNormalization.merge(&1, mission_proposed_contact_feedback))
    |> then(&OperationalFeedbackNormalization.merge(&1, mission_operational_timeline_feedback))
    |> then(&OperationalFeedbackNormalization.merge(&1, mission_command_window_feedback))
    |> then(&OperationalFeedbackNormalization.merge(&1, mission_maneuver_review_feedback))
    |> then(&OperationalFeedbackNormalization.merge(&1, mission_cadence_import_source_feedback))
    |> then(&OperationalFeedbackNormalization.merge(&1, mission_cadence_import_feedback))
    |> then(&OperationalFeedbackNormalization.merge(&1, mission_operator_review_source_feedback))
    |> then(&OperationalFeedbackNormalization.merge(&1, mission_operator_review_feedback))
    |> then(&OperationalFeedbackNormalization.merge(&1, mission_report_feedback))
    |> then(&OperationalFeedbackNormalization.merge(&1, mission_direct_feedback))
  end

  defp merge(callbacks, derived, explicit) do
    callback!(callbacks, :merge_operational_feedback).(derived, explicit)
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
