defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffObservationPointingFields do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineDiffObservationAttitudeLookupFields
  alias OrbitalDynamics.CampaignPlanner.TimelineDiffObservationPointingAssessment
  alias OrbitalDynamics.CampaignPlanner.TimelineDiffObservationPointingLookupFields

  def feedback_target_id(row, callbacks) do
    [
      planned_pointing_target_id(row, callbacks),
      planned_attitude_target_id(row, callbacks),
      row["planned_target_id"],
      row["source_target_id"],
      get_in(row, ["source_activity_context", "target_id"]),
      callback!(callbacks, :timeline_diff_changed_target_id).(row)
    ]
    |> Enum.find(fn value -> callback!(callbacks, :stable_id_string?).(value) end)
  end

  def factor(row, callbacks) do
    TimelineDiffObservationPointingAssessment.factor(row, callbacks)
  end

  def reasons(row, callbacks) do
    TimelineDiffObservationPointingAssessment.reasons(row, callbacks)
  end

  def match_status(row, field, callbacks) do
    TimelineDiffObservationPointingLookupFields.match_status(row, field, callbacks)
  end

  def planned_pointing_target_id(row, callbacks) do
    TimelineDiffObservationPointingLookupFields.planned_pointing_target_id(row, callbacks)
  end

  def realized_pointing_target_id(row, callbacks) do
    TimelineDiffObservationPointingLookupFields.realized_pointing_target_id(row, callbacks)
  end

  def planned_attitude_target_id(row, callbacks) do
    TimelineDiffObservationAttitudeLookupFields.planned_attitude_target_id(row, callbacks)
  end

  def realized_attitude_target_id(row, callbacks) do
    TimelineDiffObservationAttitudeLookupFields.realized_attitude_target_id(row, callbacks)
  end

  def planned_pointing_mode(row, callbacks) do
    TimelineDiffObservationPointingLookupFields.planned_pointing_mode(row, callbacks)
  end

  def realized_pointing_mode(row, callbacks) do
    TimelineDiffObservationPointingLookupFields.realized_pointing_mode(row, callbacks)
  end

  def planned_attitude_mode(row, callbacks) do
    TimelineDiffObservationAttitudeLookupFields.planned_attitude_mode(row, callbacks)
  end

  def realized_attitude_mode(row, callbacks) do
    TimelineDiffObservationAttitudeLookupFields.realized_attitude_mode(row, callbacks)
  end

  def pointing_status(row, callbacks) do
    TimelineDiffObservationPointingLookupFields.pointing_status(row, callbacks)
  end

  def attitude_status(row, callbacks) do
    TimelineDiffObservationAttitudeLookupFields.attitude_status(row, callbacks)
  end

  def pointing_error_deg(row, callbacks) do
    TimelineDiffObservationPointingLookupFields.pointing_error_deg(row, callbacks)
  end

  def attitude_error_deg(row, callbacks) do
    TimelineDiffObservationAttitudeLookupFields.attitude_error_deg(row, callbacks)
  end

  def pointing_model(row, callbacks) do
    TimelineDiffObservationPointingLookupFields.pointing_model(row, callbacks)
  end

  def pointing_source(row, callbacks) do
    TimelineDiffObservationPointingLookupFields.pointing_source(row, callbacks)
  end

  def attitude_model(row, callbacks) do
    TimelineDiffObservationAttitudeLookupFields.attitude_model(row, callbacks)
  end

  def attitude_source(row, callbacks) do
    TimelineDiffObservationAttitudeLookupFields.attitude_source(row, callbacks)
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
