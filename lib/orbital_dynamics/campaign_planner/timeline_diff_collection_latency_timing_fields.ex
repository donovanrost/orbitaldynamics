defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffCollectionLatencyTimingFields do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineDiffCollectionLatencyDeliveryFields
  alias OrbitalDynamics.CampaignPlanner.TimelineDiffCollectionLatencyDurationFields

  def gap?(row, callbacks) do
    latency_gap = gap_s(row, callbacks)
    max_latency_s = max_s(row, callbacks)
    planned_latency_s = planned_s(row, callbacks)
    status = status(row, callbacks)

    callback!(callbacks, :positive_number?).(latency_gap) or
      (is_number(max_latency_s) and is_number(planned_latency_s) and
         planned_latency_s > max_latency_s) or
      status in ["late", "missed", "failed", "unmet", "unsatisfied", "violated", "breached"]
  end

  def max_s(row, callbacks) do
    TimelineDiffCollectionLatencyDurationFields.max_s(row, callbacks)
  end

  def planned_s(row, callbacks) do
    TimelineDiffCollectionLatencyDurationFields.planned_s(row, callbacks)
  end

  def gap_s(row, callbacks) do
    TimelineDiffCollectionLatencyDurationFields.gap_s(row, callbacks)
  end

  def status(row, callbacks) do
    TimelineDiffCollectionLatencyDeliveryFields.status(row, callbacks)
  end

  def window_start_s(row, callbacks) do
    TimelineDiffCollectionLatencyDeliveryFields.window_start_s(row, callbacks)
  end

  def deadline_s(row, callbacks) do
    TimelineDiffCollectionLatencyDeliveryFields.deadline_s(row, callbacks)
  end

  def reasons(row, callbacks) do
    latency_gap_s = gap_s(row, callbacks)
    max_latency_s = max_s(row, callbacks)
    planned_latency_s = planned_s(row, callbacks)
    status = status(row, callbacks)

    []
    |> maybe_append_reason(true, "timeline_diff_changed_activity")
    |> maybe_append_reason(true, "timeline_diff_changed_collection_latency")
    |> maybe_append_reason(
      callback!(callbacks, :positive_number?).(latency_gap_s),
      "collection_latency_gap"
    )
    |> maybe_append_reason(
      is_number(max_latency_s) and is_number(planned_latency_s) and
        planned_latency_s > max_latency_s,
      "timeline_diff_collection_latency_limit_exceeded"
    )
    |> maybe_append_reason(status not in [nil, ""], "collection_latency_status_#{status}")
    |> Enum.reverse()
  end

  defp maybe_append_reason(reasons, true, reason), do: [reason | reasons]
  defp maybe_append_reason(reasons, _condition, _reason), do: reasons

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
