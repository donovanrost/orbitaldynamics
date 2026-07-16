defmodule OrbitalDynamics.CampaignPlanner.PriorityCommitmentSatisfaction do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TargetObjectiveSchedule
  alias OrbitalDynamics.CampaignPlanner.TargetObjectiveSelectors
  alias OrbitalDynamics.CampaignPlanner.UrgentTargetAdditionFields

  def summary(mission_state, activities, callbacks) do
    mission_state
    |> objectives()
    |> rows(activities, callbacks)
    |> summary_from_rows()
  end

  def summary_from_rows(rows) do
    required_target_ids = target_ids(rows)

    satisfied_target_ids =
      rows
      |> Enum.filter(&(&1["status"] == "satisfied"))
      |> target_ids()

    missed_target_ids =
      rows
      |> Enum.reject(&(&1["status"] == "satisfied"))
      |> target_ids()

    required_observation_count = sum_number_field(rows, "required_observations")
    planned_observation_count = sum_number_field(rows, "planned_observations")
    missing_observation_count = sum_number_field(rows, "missing_observations")

    %{
      "required_target_ids" => required_target_ids,
      "satisfied_target_ids" => satisfied_target_ids,
      "missed_target_ids" => missed_target_ids,
      "required_observation_count" => required_observation_count,
      "planned_observation_count" => planned_observation_count,
      "missing_observation_count" => missing_observation_count,
      "ratio" =>
        if(required_observation_count > 0,
          do: min(planned_observation_count / required_observation_count, 1.0),
          else: 1.0
        ),
      "rows" => rows
    }
  end

  def rows(objectives, activities), do: rows(objectives, activities, [])

  def rows(objectives, activities, callbacks) do
    objectives
    |> Enum.map(fn objective ->
      target_id = Map.get(objective, "target_id") || Map.get(objective, "id")
      required_observations = UrgentTargetAdditionFields.required_observations(objective)
      planned_observations = scoped_observation_count(activities, objective, callbacks)
      missing_observations = max(required_observations - planned_observations, 0)

      %{
        "objective_id" => Map.get(objective, "objective_id") || Map.get(objective, "id"),
        "commitment_id" => Map.get(objective, "commitment_id"),
        "target_id" => target_id,
        "required_observations" => required_observations,
        "planned_observations" => planned_observations,
        "missing_observations" => missing_observations,
        "status" => if(missing_observations == 0, do: "satisfied", else: "unmet")
      }
      |> compact_map()
    end)
    |> Enum.sort_by(&{&1["target_id"], &1["objective_id"] || "", &1["commitment_id"] || ""})
  end

  def objectives(mission_state) do
    mission_state
    |> Map.get("objectives", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&(Map.get(&1, "type") == "priority_commitment"))
    |> Enum.flat_map(&TargetObjectiveSelectors.expand/1)
    |> Enum.map(fn objective ->
      objective
      |> TargetObjectiveSelectors.put_objective_id()
      |> TargetObjectiveSelectors.put_commitment_id()
    end)
  end

  def objectives(mission_state, _callbacks), do: objectives(mission_state)

  defp target_ids(rows) do
    rows
    |> Enum.map(& &1["target_id"])
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp sum_number_field(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field, 0))
    |> Enum.filter(&is_number/1)
    |> Enum.sum()
  end

  defp scoped_observation_count(activities, objective, []) do
    TargetObjectiveSchedule.scoped_observation_count(activities, objective)
  end

  defp scoped_observation_count(activities, objective, callbacks) do
    TargetObjectiveSchedule.scoped_observation_count(
      activities,
      objective,
      schedule_callbacks(callbacks)
    )
  end

  defp schedule_callbacks(callbacks) do
    Keyword.get(callbacks, :target_objective_schedule_callbacks, callbacks)
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
