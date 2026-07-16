defmodule OrbitalDynamics.CampaignPlanner.TargetObjectiveRealizedObservations do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ActivityMatching
  alias OrbitalDynamics.CampaignPlanner.ScalarValues

  @realized_failure_statuses ~w(missed failed canceled cancelled rejected)

  def revisit_objectives(mission_state, prior_plan),
    do: revisit_objectives(mission_state, prior_plan, default_callbacks())

  def revisit_objectives(mission_state, prior_plan, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    mission_state
    |> events(prior_plan, callbacks)
    |> Enum.map(fn realized ->
      %{
        "type" => "target_revisit",
        "target_id" => realized["target_id"],
        "required_observations" => 1,
        "priority" => numeric_or_nil.(Map.get(realized, "priority")) || 1.0,
        "source_activity_id" => realized["id"],
        "realized_status" => realized["status"],
        "derivation_reason" => "realized_observation_#{realized["status"]}"
      }
    end)
    |> Enum.reject(&(&1["target_id"] in [nil, ""]))
    |> dedupe_revisit_objectives()
  end

  def events(mission_state, prior_plan),
    do: events(mission_state, prior_plan, default_callbacks())

  def events(mission_state, prior_plan, callbacks) do
    failure_statuses = Keyword.fetch!(callbacks, :failure_statuses)

    planned_by_id = ActivityMatching.planned_activities_grouped_by_id(prior_plan)

    mission_state
    |> Map.get("realized_activities", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&(Map.get(&1, "status") in failure_statuses))
    |> Enum.map(fn realized ->
      planned =
        ActivityMatching.unique_planned_activity_for_realized(realized, planned_by_id, "observe") ||
          %{}

      type = Map.get(realized, "type") || Map.get(realized, "activity_type") || planned["type"]

      if type == "observe" do
        realized
        |> Map.put_new("type", "observe")
        |> Map.put_new("target_id", planned["target_id"])
        |> Map.put_new("priority", Map.get(planned, "score"))
        |> Map.put_new("scenario_id", planned["scenario_id"])
        |> Map.put_new("starts_at_s", planned["starts_at_s"])
        |> Map.put_new("ends_at_s", planned["ends_at_s"])
      else
        nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp default_callbacks,
    do: [
      failure_statuses: @realized_failure_statuses,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1
    ]

  defp dedupe_revisit_objectives(objectives) do
    objectives
    |> Enum.reduce(%{}, fn objective, acc ->
      Map.update(acc, objective["target_id"], objective, fn existing ->
        source_activity_ids =
          [
            existing["source_activity_ids"] || existing["source_activity_id"],
            objective["source_activity_ids"] || objective["source_activity_id"]
          ]
          |> List.flatten()
          |> Enum.reject(&(&1 in [nil, ""]))
          |> Enum.uniq()
          |> Enum.sort()

        existing
        |> Map.update("priority", objective["priority"], &max(&1, objective["priority"]))
        |> Map.put("source_activity_id", List.first(source_activity_ids))
        |> Map.put("source_activity_ids", source_activity_ids)
      end)
    end)
    |> Map.values()
    |> Enum.sort_by(& &1["target_id"])
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
