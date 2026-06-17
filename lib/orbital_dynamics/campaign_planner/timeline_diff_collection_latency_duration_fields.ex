defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffCollectionLatencyDurationFields do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineDiffCollectionLatencyGapFields

  def max_s(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_number).(row, [
      "max_latency_s",
      "required_latency_s",
      "target_latency_s",
      "target_delivery_latency_s",
      "latency_limit_s",
      "max_delivery_latency_s",
      "required_delivery_latency_s",
      "replacement_max_latency_s",
      "replacement_required_latency_s",
      "replacement_target_latency_s",
      "replacement_target_delivery_latency_s",
      "replacement_latency_limit_s",
      "replacement_max_delivery_latency_s",
      "replacement_required_delivery_latency_s",
      ["replacement_activity_context", "max_latency_s"],
      ["replacement_activity_context", "required_latency_s"],
      ["replacement_activity_context", "target_latency_s"],
      ["replacement_activity_context", "target_delivery_latency_s"],
      ["replacement_activity_context", "latency_limit_s"],
      ["replacement_activity_context", "max_delivery_latency_s"],
      ["replacement_activity_context", "required_delivery_latency_s"],
      "source_max_latency_s",
      "source_required_latency_s",
      "source_target_latency_s",
      "source_target_delivery_latency_s",
      "source_latency_limit_s",
      "source_max_delivery_latency_s",
      "source_required_delivery_latency_s",
      ["source_activity_context", "max_latency_s"],
      ["source_activity_context", "required_latency_s"],
      ["source_activity_context", "target_latency_s"],
      ["source_activity_context", "target_delivery_latency_s"],
      ["source_activity_context", "latency_limit_s"],
      ["source_activity_context", "max_delivery_latency_s"],
      ["source_activity_context", "required_delivery_latency_s"]
    ])
  end

  def planned_s(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_number).(row, [
      "planned_latency_s",
      "actual_latency_s",
      "delivery_latency_s",
      "planned_delivery_latency_s",
      "actual_delivery_latency_s",
      "replacement_planned_latency_s",
      "replacement_actual_latency_s",
      "replacement_delivery_latency_s",
      "replacement_planned_delivery_latency_s",
      "replacement_actual_delivery_latency_s",
      ["replacement_activity_context", "planned_latency_s"],
      ["replacement_activity_context", "actual_latency_s"],
      ["replacement_activity_context", "delivery_latency_s"],
      ["replacement_activity_context", "planned_delivery_latency_s"],
      ["replacement_activity_context", "actual_delivery_latency_s"],
      "source_planned_latency_s",
      "source_actual_latency_s",
      "source_delivery_latency_s",
      "source_planned_delivery_latency_s",
      "source_actual_delivery_latency_s",
      ["source_activity_context", "planned_latency_s"],
      ["source_activity_context", "actual_latency_s"],
      ["source_activity_context", "delivery_latency_s"],
      ["source_activity_context", "planned_delivery_latency_s"],
      ["source_activity_context", "actual_delivery_latency_s"]
    ])
  end

  def gap_s(row, callbacks) do
    explicit = TimelineDiffCollectionLatencyGapFields.explicit_s(row, callbacks)

    case {explicit, planned_s(row, callbacks), max_s(row, callbacks)} do
      {value, _planned, _max} when is_number(value) ->
        value

      {_missing, planned, max_latency_s} when is_number(planned) and is_number(max_latency_s) ->
        max(planned - max_latency_s, 0.0)

      _other ->
        nil
    end
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
