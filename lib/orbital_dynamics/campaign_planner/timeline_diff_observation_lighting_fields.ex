defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffObservationLightingFields do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineDiffObservationLightingAssessment
  alias OrbitalDynamics.CampaignPlanner.TimelineDiffObservationLightingConditionFields
  alias OrbitalDynamics.CampaignPlanner.TimelineDiffObservationLightingEclipseFields

  def observation_lighting_factor(row, callbacks) do
    TimelineDiffObservationLightingAssessment.observation_lighting_factor(row, callbacks)
  end

  def observation_lighting_evidence?(row, callbacks) do
    TimelineDiffObservationLightingAssessment.observation_lighting_evidence?(row, callbacks)
  end

  def observation_lighting_reasons(row, callbacks) do
    TimelineDiffObservationLightingAssessment.observation_lighting_reasons(row, callbacks)
  end

  def lighting_condition_match_status(row, callbacks) do
    TimelineDiffObservationLightingConditionFields.lighting_condition_match_status(row, callbacks)
  end

  def planned_lighting_condition(row, callbacks) do
    TimelineDiffObservationLightingConditionFields.planned_lighting_condition(row, callbacks)
  end

  def realized_lighting_condition(row, callbacks) do
    TimelineDiffObservationLightingConditionFields.realized_lighting_condition(row, callbacks)
  end

  def lighting_condition_detail(row, callbacks) do
    TimelineDiffObservationLightingConditionFields.lighting_condition_detail(row, callbacks)
  end

  def lighting_condition_model(row, callbacks) do
    TimelineDiffObservationLightingConditionFields.lighting_condition_model(row, callbacks)
  end

  def lighting_detail_model(row, callbacks) do
    TimelineDiffObservationLightingConditionFields.lighting_detail_model(row, callbacks)
  end

  def lighting_confidence(row, callbacks) do
    TimelineDiffObservationLightingConditionFields.lighting_confidence(row, callbacks)
  end

  def eclipse_overlap_fraction(row, callbacks) do
    TimelineDiffObservationLightingEclipseFields.eclipse_overlap_fraction(row, callbacks)
  end

  def eclipse_overlap_s(row, callbacks) do
    TimelineDiffObservationLightingEclipseFields.eclipse_overlap_s(row, callbacks)
  end
end
