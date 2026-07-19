defmodule OrbitalDynamics.Policy.ActivityMatcher do
  @moduledoc false

  alias OrbitalDynamics.Policy.{RequirementContext, RiskMatcher}

  def match?(rule, activity) do
    not is_nil(rule["feasibility_status"]) and
      rule["feasibility_status"] == get_in(activity, ["feasibility", "status"]) and
      activity_direction_match?(rule, activity) and
      activity_ground_station_match?(rule, activity) and
      activity_spacecraft_match?(rule, activity) and
      activity_target_match?(rule, activity) and
      activity_provenance_match?(rule, activity)
  end

  defp activity_provenance_match?(rule, activity) do
    activity_context_match?(
      rule,
      activity,
      "feedback_source",
      "feedback_sources",
      "feedback_source"
    ) and
      activity_context_match?(
        rule,
        activity,
        "feedback_scope",
        "feedback_scopes",
        "feedback_scope"
      ) and
      activity_context_match?(
        rule,
        activity,
        "trust_boundary",
        "trust_boundaries",
        "trust_boundary"
      ) and
      activity_context_match?(
        rule,
        activity,
        "source_event_type",
        "source_event_types",
        "source_event_type"
      )
  end

  defp activity_context_match?(rule, activity, singular_rule_field, plural_rule_field, field) do
    values = activity_context_values(activity, field)

    cond do
      not is_nil(rule[singular_rule_field]) ->
        rule[singular_rule_field] in values

      not is_nil(rule[plural_rule_field]) ->
        Enum.any?(values, &(&1 in List.wrap(rule[plural_rule_field])))

      true ->
        true
    end
  end

  def provenance_value(activity, field) do
    activity_context_values(activity, field)
    |> List.first()
  end

  defp activity_context_values(activity, field) do
    (RequirementContext.direction_values(Map.get(activity, field)) ++
       RequirementContext.direction_values(get_in(activity, ["feasibility", field])))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  defp activity_direction_match?(rule, activity) do
    RiskMatcher.direction_match?(rule, directions(activity))
  end

  def direction(%{"direction" => direction}) when is_binary(direction),
    do: RequirementContext.normalize_direction(direction)

  def direction(%{"direction" => direction}) when is_atom(direction),
    do: RequirementContext.normalize_direction(direction)

  def direction(%{"directions" => directions}) when is_list(directions) do
    directions
    |> RequirementContext.canonical_direction_values()
    |> Enum.find(&(is_binary(&1) and &1 != ""))
  end

  def direction(%{"feasibility" => %{} = feasibility}),
    do: direction(feasibility)

  def direction(_activity), do: nil

  def directions(activity) do
    (RequirementContext.canonical_direction_values(Map.get(activity, "direction")) ++
       RequirementContext.canonical_direction_values(Map.get(activity, "directions")) ++
       RequirementContext.canonical_direction_values(
         get_in(activity, ["feasibility", "direction"])
       ) ++
       RequirementContext.canonical_direction_values(
         get_in(activity, ["feasibility", "directions"])
       ))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  defp activity_ground_station_match?(rule, activity) do
    activity_station_id = ground_station_id(activity)

    cond do
      not is_nil(rule["ground_station_id"]) ->
        rule["ground_station_id"] == activity_station_id

      not is_nil(rule["ground_station_ids"]) ->
        activity_station_id in List.wrap(rule["ground_station_ids"])

      true ->
        true
    end
  end

  def ground_station_id(activity) do
    Map.get(activity, "ground_station_id") || Map.get(activity, "station_id") ||
      get_in(activity, ["feasibility", "ground_station_id"]) ||
      get_in(activity, ["feasibility", "station_id"])
  end

  defp activity_spacecraft_match?(rule, activity) do
    activity_spacecraft_id = spacecraft_id(activity)

    cond do
      not is_nil(rule["spacecraft_id"]) ->
        rule["spacecraft_id"] == activity_spacecraft_id

      not is_nil(rule["spacecraft_ids"]) ->
        activity_spacecraft_id in List.wrap(rule["spacecraft_ids"])

      true ->
        true
    end
  end

  def spacecraft_id(activity) do
    Map.get(activity, "spacecraft_id") || Map.get(activity, "scenario_id") ||
      get_in(activity, ["feasibility", "spacecraft_id"]) ||
      get_in(activity, ["feasibility", "scenario_id"])
  end

  defp activity_target_match?(rule, activity) do
    activity_target_id = target_id(activity)

    cond do
      not is_nil(rule["target_id"]) ->
        rule["target_id"] == activity_target_id

      not is_nil(rule["target_ids"]) ->
        activity_target_id in List.wrap(rule["target_ids"])

      true ->
        true
    end
  end

  def target_id(activity) do
    Map.get(activity, "target_id") || get_in(activity, ["feasibility", "target_id"])
  end
end
