defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffObservationPriorityMetadataFields do
  @moduledoc false

  def target_priority_source(row, callbacks) do
    [
      row["target_priority_source"],
      row["replacement_target_priority_source"],
      get_in(row, ["replacement_activity_context", "target_priority_source"]),
      get_in(row, ["replacement_activity_context", "target", "target_priority_source"]),
      get_in(row, ["replacement_target", "target_priority_source"]),
      row["source_target_priority_source"],
      get_in(row, ["source_activity_context", "target_priority_source"]),
      get_in(row, ["source_activity_context", "target", "target_priority_source"]),
      get_in(row, ["source_target", "target_priority_source"])
    ]
    |> Enum.map(fn value -> callback!(callbacks, :encode_value).(value) end)
    |> Enum.find(fn value -> callback!(callbacks, :stable_id_string?).(value) end)
  end

  def target_priority_objective_ids(row, callbacks) do
    [
      row["target_priority_objective_ids"],
      row["target_priority_objective_id"],
      row["replacement_target_priority_objective_ids"],
      row["replacement_target_priority_objective_id"],
      get_in(row, ["replacement_activity_context", "target_priority_objective_ids"]),
      get_in(row, ["replacement_activity_context", "target_priority_objective_id"]),
      get_in(row, ["replacement_activity_context", "target", "target_priority_objective_ids"]),
      get_in(row, ["replacement_activity_context", "target", "target_priority_objective_id"]),
      get_in(row, ["replacement_target", "target_priority_objective_ids"]),
      get_in(row, ["replacement_target", "target_priority_objective_id"]),
      row["source_target_priority_objective_ids"],
      row["source_target_priority_objective_id"],
      get_in(row, ["source_activity_context", "target_priority_objective_ids"]),
      get_in(row, ["source_activity_context", "target_priority_objective_id"]),
      get_in(row, ["source_activity_context", "target", "target_priority_objective_ids"]),
      get_in(row, ["source_activity_context", "target", "target_priority_objective_id"]),
      get_in(row, ["source_target", "target_priority_objective_ids"]),
      get_in(row, ["source_target", "target_priority_objective_id"])
    ]
    |> List.flatten()
    |> Enum.map(fn value -> callback!(callbacks, :encode_value).(value) end)
    |> Enum.filter(fn value -> callback!(callbacks, :stable_id_string?).(value) end)
    |> Enum.uniq()
    |> case do
      [] -> nil
      ids -> ids
    end
  end

  def target_priority_objective_type(row, callbacks) do
    [
      row["target_priority_objective_type"],
      row["replacement_target_priority_objective_type"],
      get_in(row, ["replacement_activity_context", "target_priority_objective_type"]),
      get_in(row, ["replacement_activity_context", "target", "target_priority_objective_type"]),
      get_in(row, ["replacement_target", "target_priority_objective_type"]),
      row["source_target_priority_objective_type"],
      get_in(row, ["source_activity_context", "target_priority_objective_type"]),
      get_in(row, ["source_activity_context", "target", "target_priority_objective_type"]),
      get_in(row, ["source_target", "target_priority_objective_type"])
    ]
    |> Enum.map(fn value -> callback!(callbacks, :encode_value).(value) end)
    |> Enum.find(fn value -> callback!(callbacks, :stable_id_string?).(value) end)
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
