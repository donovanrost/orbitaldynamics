defmodule OrbitalDynamics.Schema.TimelineCapabilityContext do
  @moduledoc false

  def timeline_feedback_report_model_limits do
    timeline_feedback_capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  def timeline_feedback_capabilities, do: OrbitalDynamics.TimelineFeedback.capabilities()

  def timeline_report_model_limits do
    timeline_capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  def timeline_capabilities, do: OrbitalDynamics.Timeline.capabilities()

  def timeline_candidate_rejection_reasons,
    do: timeline_capabilities().candidate_rejection_reasons

  def timeline_candidate_rejection_actions,
    do: timeline_capabilities().candidate_rejection_actions

  def timeline_transition_decisions, do: timeline_capabilities().transition_decisions

  def timeline_integrity_issue_types,
    do: timeline_capabilities().timeline_integrity_issue_types

  def timeline_activity_precondition_statuses,
    do: timeline_capabilities().activity_precondition_statuses

  def timeline_required_operator_actions,
    do: timeline_capabilities().required_operator_actions
end
