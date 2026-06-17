defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffObservationPriorityFields do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineDiffObservationPriorityMetadataFields

  def target_priority(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_number).(row, [
      "target_priority",
      "priority",
      "replacement_target_priority",
      "replacement_priority",
      ["replacement_activity_context", "target_priority"],
      ["replacement_activity_context", "priority"],
      ["replacement_activity_context", "target", "target_priority"],
      ["replacement_activity_context", "target", "priority"],
      ["replacement_target", "target_priority"],
      ["replacement_target", "priority"],
      "source_target_priority",
      "source_priority",
      ["source_activity_context", "target_priority"],
      ["source_activity_context", "priority"],
      ["source_activity_context", "target", "target_priority"],
      ["source_activity_context", "target", "priority"],
      ["source_target", "target_priority"],
      ["source_target", "priority"]
    ])
  end

  def target_number(row, field, callbacks) do
    target_field = "target_#{field}"
    replacement_field = "replacement_#{target_field}"
    source_field = "source_#{target_field}"

    callback!(callbacks, :timeline_diff_first_number).(row, [
      target_field,
      field,
      replacement_field,
      "replacement_#{field}",
      ["replacement_activity_context", target_field],
      ["replacement_activity_context", field],
      ["replacement_activity_context", "target", target_field],
      ["replacement_activity_context", "target", field],
      ["replacement_target", target_field],
      ["replacement_target", field],
      source_field,
      "source_#{field}",
      ["source_activity_context", target_field],
      ["source_activity_context", field],
      ["source_activity_context", "target", target_field],
      ["source_activity_context", "target", field],
      ["source_target", target_field],
      ["source_target", field]
    ])
  end

  def target_priority_source(row, callbacks) do
    TimelineDiffObservationPriorityMetadataFields.target_priority_source(row, callbacks)
  end

  def target_priority_objective_ids(row, callbacks) do
    TimelineDiffObservationPriorityMetadataFields.target_priority_objective_ids(row, callbacks)
  end

  def target_priority_objective_type(row, callbacks) do
    TimelineDiffObservationPriorityMetadataFields.target_priority_objective_type(row, callbacks)
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
