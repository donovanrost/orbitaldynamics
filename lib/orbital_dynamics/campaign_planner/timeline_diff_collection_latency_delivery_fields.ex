defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffCollectionLatencyDeliveryFields do
  @moduledoc false

  def status(row, callbacks) do
    [
      row["collection_latency_status"],
      row["latency_status"],
      row["delivery_status"],
      row["replacement_collection_latency_status"],
      row["replacement_latency_status"],
      row["replacement_delivery_status"],
      get_in(row, ["replacement_activity_context", "collection_latency_status"]),
      get_in(row, ["replacement_activity_context", "latency_status"]),
      get_in(row, ["replacement_activity_context", "delivery_status"]),
      row["source_collection_latency_status"],
      row["source_latency_status"],
      row["source_delivery_status"],
      get_in(row, ["source_activity_context", "collection_latency_status"]),
      get_in(row, ["source_activity_context", "latency_status"]),
      get_in(row, ["source_activity_context", "delivery_status"])
    ]
    |> Enum.map(fn value -> callback!(callbacks, :normalized_status_token).(value) end)
    |> Enum.find(&(is_binary(&1) and &1 != ""))
  end

  def window_start_s(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_number).(row, [
      "collection_end_s",
      "collection_ends_at_s",
      "observation_end_s",
      "observation_ends_at_s",
      "replacement_collection_end_s",
      "replacement_collection_ends_at_s",
      "replacement_observation_end_s",
      "replacement_observation_ends_at_s",
      ["replacement_activity_context", "collection_end_s"],
      ["replacement_activity_context", "collection_ends_at_s"],
      ["replacement_activity_context", "observation_end_s"],
      ["replacement_activity_context", "observation_ends_at_s"],
      "source_collection_end_s",
      "source_collection_ends_at_s",
      "source_observation_end_s",
      "source_observation_ends_at_s",
      ["source_activity_context", "collection_end_s"],
      ["source_activity_context", "collection_ends_at_s"],
      ["source_activity_context", "observation_end_s"],
      ["source_activity_context", "observation_ends_at_s"]
    ]) || callback!(callbacks, :timeline_diff_changed_window_end_s).(row)
  end

  def deadline_s(row, callbacks) do
    callback!(callbacks, :timeline_diff_first_number).(row, [
      "delivery_deadline_s",
      "deadline_s",
      "required_delivery_at_s",
      "target_delivery_at_s",
      "replacement_delivery_deadline_s",
      "replacement_deadline_s",
      "replacement_required_delivery_at_s",
      "replacement_target_delivery_at_s",
      ["replacement_activity_context", "delivery_deadline_s"],
      ["replacement_activity_context", "deadline_s"],
      ["replacement_activity_context", "required_delivery_at_s"],
      ["replacement_activity_context", "target_delivery_at_s"],
      "source_delivery_deadline_s",
      "source_deadline_s",
      "source_required_delivery_at_s",
      "source_target_delivery_at_s",
      ["source_activity_context", "delivery_deadline_s"],
      ["source_activity_context", "deadline_s"],
      ["source_activity_context", "required_delivery_at_s"],
      ["source_activity_context", "target_delivery_at_s"]
    ])
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
