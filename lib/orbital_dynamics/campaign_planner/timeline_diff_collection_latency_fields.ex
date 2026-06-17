defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffCollectionLatencyFields do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TimelineDiffCollectionLatencyTimingFields

  def gap?(row, callbacks) do
    TimelineDiffCollectionLatencyTimingFields.gap?(row, callbacks)
  end

  def routed?(row, callbacks) do
    evidence = evidence(row, callbacks)

    [
      source_activity_id(row, callbacks),
      callback!(callbacks, :timeline_diff_changed_target_id).(row),
      callback!(callbacks, :score_term_primary_target_id).(evidence),
      callback!(callbacks, :timeline_diff_changed_ground_station_id).(row),
      callback!(callbacks, :score_term_station_id).(evidence),
      callback!(callbacks, :score_term_collection_id).(evidence),
      callback!(callbacks, :score_term_product_id).(evidence),
      callback!(callbacks, :score_term_payload_id).(evidence),
      callback!(callbacks, :score_term_instrument_id).(evidence)
    ]
    |> Enum.any?(fn value -> callback!(callbacks, :stable_id_string?).(value) end)
  end

  def evidence(row, callbacks) do
    [
      row["source_activity_context"],
      row["source_observation"],
      row,
      row["replacement_activity_context"],
      row["replacement_observation"]
    ]
    |> Enum.reduce(%{}, fn evidence, merged ->
      Map.merge(merged, callback!(callbacks, :stringify_keys).(evidence || %{}))
    end)
  end

  def max_s(row, callbacks) do
    TimelineDiffCollectionLatencyTimingFields.max_s(row, callbacks)
  end

  def planned_s(row, callbacks) do
    TimelineDiffCollectionLatencyTimingFields.planned_s(row, callbacks)
  end

  def gap_s(row, callbacks) do
    TimelineDiffCollectionLatencyTimingFields.gap_s(row, callbacks)
  end

  def status(row, callbacks) do
    TimelineDiffCollectionLatencyTimingFields.status(row, callbacks)
  end

  def window_start_s(row, callbacks) do
    TimelineDiffCollectionLatencyTimingFields.window_start_s(row, callbacks)
  end

  def deadline_s(row, callbacks) do
    TimelineDiffCollectionLatencyTimingFields.deadline_s(row, callbacks)
  end

  def objective_id(row, callbacks) do
    [
      row["objective_id"],
      row["collection_latency_objective_id"],
      row["replacement_objective_id"],
      row["replacement_collection_latency_objective_id"],
      get_in(row, ["replacement_activity_context", "objective_id"]),
      get_in(row, ["replacement_activity_context", "collection_latency_objective_id"]),
      row["source_objective_id"],
      row["source_collection_latency_objective_id"],
      get_in(row, ["source_activity_context", "objective_id"]),
      get_in(row, ["source_activity_context", "collection_latency_objective_id"])
    ]
    |> Enum.map(fn value -> callback!(callbacks, :encode_value).(value) end)
    |> Enum.find(fn value -> callback!(callbacks, :stable_id_string?).(value) end)
  end

  def source_activity_id(row, callbacks) do
    [
      row["source_observation_activity_id"],
      row["observation_activity_id"],
      row["source_activity_id"],
      get_in(row, ["source_activity_context", "activity_id"]),
      get_in(row, ["source_activity_context", "id"]),
      get_in(row, ["replacement_activity_context", "observation_activity_id"])
    ]
    |> Enum.map(fn value -> callback!(callbacks, :encode_value).(value) end)
    |> Enum.find(fn value -> callback!(callbacks, :stable_id_string?).(value) end)
  end

  def downlink_activity_id(row, callbacks) do
    row
    |> downlink_activity_ids(callbacks)
    |> List.wrap()
    |> List.first()
  end

  def downlink_activity_ids(row, callbacks) do
    [
      row["missed_downlink_activity_ids"],
      row["missed_downlink_activity_id"],
      row["downlink_activity_ids"],
      row["downlink_activity_id"],
      row["replacement_activity_id"],
      get_in(row, ["replacement_activity_context", "downlink_activity_id"]),
      get_in(row, ["replacement_activity_context", "activity_id"])
    ]
    |> List.flatten()
    |> Enum.map(fn value -> callback!(callbacks, :encode_value).(value) end)
    |> Enum.filter(fn value -> callback!(callbacks, :stable_id_string?).(value) end)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      ids -> ids
    end
  end

  def reasons(row, callbacks) do
    TimelineDiffCollectionLatencyTimingFields.reasons(row, callbacks)
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
