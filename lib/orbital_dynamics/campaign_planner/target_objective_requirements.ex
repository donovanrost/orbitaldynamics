defmodule OrbitalDynamics.CampaignPlanner.TargetObjectiveRequirements do
  @moduledoc false

  def needs_branch?(objective, planned_count, policy) do
    objective_type = objective["type"]
    priority = objective_number(objective, "priority", 0.0)

    cond do
      objective_type in ["urgent_target", "priority_commitment"] ->
        planned_count < required_observation_count(objective)

      objective_type in ["target_revisit", "target_observation"] ->
        planned_count < required_observation_count(objective)

      objective_type == "target_coverage" ->
        planned_count < required_observation_count(objective)

      is_number(priority) and priority >= policy["urgent_priority_threshold"] ->
        planned_count < required_observation_count(objective)

      truthy?(Map.get(objective, "urgent")) ->
        planned_count < required_observation_count(objective)

      true ->
        false
    end
  end

  def required_observation_count(objective) do
    objective
    |> Map.take(["required_observations", "required_revisits", "required_count"])
    |> Map.values()
    |> Enum.find_value(&numeric_or_nil/1)
    |> case do
      nil -> 1
      count -> max(trunc(count), 1)
    end
  end

  def put_required_observations(event, objective) do
    required_count = required_observation_count(objective)

    if objective["type"] in ["target_revisit", "target_observation", "target_coverage"] or
         required_count > 1 do
      Map.put(event, "required_observations", required_count)
    else
      event
    end
  end

  defp objective_number(objective, field, default) do
    case numeric_or_nil(Map.get(objective, field)) do
      value when is_number(value) -> value
      _value -> default
    end
  end

  defp truthy?(value), do: json_boolean_value(value) == true

  defp json_boolean_value(value) when is_boolean(value), do: value

  defp json_boolean_value(value) when is_number(value) do
    cond do
      value == 1 -> true
      value == 0 -> false
      true -> nil
    end
  end

  defp json_boolean_value(value) when is_binary(value) do
    case String.downcase(String.trim(value)) do
      "true" -> true
      "1" -> true
      "false" -> false
      "0" -> false
      _value -> nil
    end
  end

  defp json_boolean_value(_value), do: nil

  defp numeric_or_nil(nil), do: nil
  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value

  defp numeric_or_nil(value) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> number
      _error -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil
end
