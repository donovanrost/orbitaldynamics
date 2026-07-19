defmodule OrbitalDynamics.Policy.RiskMatcher do
  @moduledoc false

  alias OrbitalDynamics.Policy.RequirementContext

  def match?(rule, risk) do
    risk_type_match? =
      cond do
        not is_nil(rule["risk_type"]) ->
          rule["risk_type"] == risk["type"]

        not is_nil(rule["risk_types"]) ->
          risk["type"] in List.wrap(rule["risk_types"])

        true ->
          false
      end

    risk_type_match? and risk_direction_match?(rule, risk) and
      risk_ground_station_match?(rule, risk) and risk_spacecraft_match?(rule, risk) and
      risk_target_match?(rule, risk) and
      risk_context_match?(
        rule,
        risk,
        "station_availability",
        "station_availabilities",
        "station_availability"
      ) and
      risk_context_match?(
        rule,
        risk,
        "station_contention_status",
        "station_contention_statuses",
        "station_contention_status"
      ) and
      risk_context_match?(
        rule,
        risk,
        "station_reservation_id",
        "station_reservation_ids",
        "station_reservation_id"
      ) and
      risk_context_match?(
        rule,
        risk,
        "station_reserved_by",
        "station_reserved_bys",
        "station_reserved_by"
      ) and
      risk_context_match?(
        rule,
        risk,
        "station_reservation_status",
        "station_reservation_statuses",
        "station_reservation_status"
      ) and
      risk_context_match?(
        rule,
        risk,
        "station_reservation_match_status",
        "station_reservation_match_statuses",
        "station_reservation_match_status"
      ) and
      risk_context_match?(
        rule,
        risk,
        "station_calendar_entry_id",
        "station_calendar_entry_ids",
        "station_calendar_entry_id"
      ) and
      risk_context_match?(
        rule,
        risk,
        "station_calendar_provider_id",
        "station_calendar_provider_ids",
        "station_calendar_provider_id"
      ) and
      risk_context_match?(
        rule,
        risk,
        "station_calendar_provider_entry_id",
        "station_calendar_provider_entry_ids",
        "station_calendar_provider_entry_id"
      ) and
      risk_context_match?(
        rule,
        risk,
        "station_calendar_direction",
        "station_calendar_directions",
        "station_calendar_direction"
      ) and
      risk_context_match?(
        rule,
        risk,
        "station_calendar_status",
        "station_calendar_statuses",
        "station_calendar_status"
      ) and
      risk_context_match?(
        rule,
        risk,
        "station_calendar_trust_boundary_status",
        "station_calendar_trust_boundary_statuses",
        "station_calendar_trust_boundary_status"
      ) and
      risk_context_match?(
        rule,
        risk,
        "station_calendar_reservation_id",
        "station_calendar_reservation_ids",
        "station_calendar_reservation_id"
      ) and
      risk_context_match?(
        rule,
        risk,
        "station_calendar_reserved_by",
        "station_calendar_reserved_bys",
        "station_calendar_reserved_by"
      ) and
      risk_context_match?(
        rule,
        risk,
        "station_calendar_reservation_status",
        "station_calendar_reservation_statuses",
        "station_calendar_reservation_status"
      )
  end

  defp risk_direction_match?(rule, risk) do
    direction_match?(rule, directions(risk))
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

  def direction(_risk), do: nil

  def directions(risk) do
    (RequirementContext.canonical_direction_values(Map.get(risk, "direction")) ++
       RequirementContext.canonical_direction_values(Map.get(risk, "directions")))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  defp risk_ground_station_match?(rule, risk) do
    risk_station_id = ground_station_id(risk)

    cond do
      not is_nil(rule["ground_station_id"]) ->
        rule["ground_station_id"] == risk_station_id

      not is_nil(rule["ground_station_ids"]) ->
        risk_station_id in List.wrap(rule["ground_station_ids"])

      true ->
        true
    end
  end

  def ground_station_id(risk) do
    Map.get(risk, "ground_station_id") || Map.get(risk, "station_id")
  end

  defp risk_spacecraft_match?(rule, risk) do
    risk_spacecraft_id = spacecraft_id(risk)

    cond do
      not is_nil(rule["spacecraft_id"]) ->
        rule["spacecraft_id"] == risk_spacecraft_id

      not is_nil(rule["spacecraft_ids"]) ->
        risk_spacecraft_id in List.wrap(rule["spacecraft_ids"])

      true ->
        true
    end
  end

  def spacecraft_id(risk) do
    Map.get(risk, "spacecraft_id") || Map.get(risk, "scenario_id")
  end

  defp risk_context_match?(rule, risk, singular_rule_field, plural_rule_field, field) do
    values = context_values(risk, field)

    cond do
      not is_nil(rule[singular_rule_field]) ->
        rule[singular_rule_field] in values

      not is_nil(rule[plural_rule_field]) ->
        Enum.any?(values, &(&1 in List.wrap(rule[plural_rule_field])))

      true ->
        true
    end
  end

  def context_value(risk, field) do
    risk
    |> context_values(field)
    |> List.first()
  end

  def context_values(risk, "station_reservation_id") do
    RequirementContext.direction_values(Map.get(risk, "station_reservation_id")) ++
      RequirementContext.direction_values(Map.get(risk, "reservation_id")) ++
      RequirementContext.direction_values(Map.get(risk, "station_reservation_ids"))
  end

  def context_values(risk, "station_reserved_by") do
    RequirementContext.direction_values(Map.get(risk, "station_reserved_by")) ++
      RequirementContext.direction_values(Map.get(risk, "reserved_by")) ++
      RequirementContext.direction_values(Map.get(risk, "station_reserved_bys"))
  end

  def context_values(risk, "station_reservation_status") do
    RequirementContext.direction_values(Map.get(risk, "station_reservation_status")) ++
      RequirementContext.direction_values(Map.get(risk, "reservation_status")) ++
      RequirementContext.direction_values(Map.get(risk, "station_reservation_statuses"))
  end

  def context_values(risk, "station_reservation_match_status") do
    RequirementContext.direction_values(Map.get(risk, "station_reservation_match_status")) ++
      RequirementContext.direction_values(Map.get(risk, "reservation_match_status")) ++
      RequirementContext.direction_values(Map.get(risk, "station_reservation_match_statuses"))
  end

  def context_values(risk, "station_calendar_provider_id") do
    RequirementContext.direction_values(Map.get(risk, "station_calendar_provider_id")) ++
      RequirementContext.direction_values(Map.get(risk, "station_calendar_provider_ids"))
  end

  def context_values(risk, "station_calendar_provider_entry_id") do
    RequirementContext.direction_values(Map.get(risk, "station_calendar_provider_entry_id")) ++
      RequirementContext.direction_values(Map.get(risk, "station_calendar_provider_entry_ids"))
  end

  def context_values(risk, "station_calendar_entry_id") do
    RequirementContext.direction_values(Map.get(risk, "station_calendar_entry_id")) ++
      RequirementContext.direction_values(Map.get(risk, "station_calendar_entry_ids"))
  end

  def context_values(risk, "station_calendar_direction") do
    RequirementContext.canonical_direction_values(Map.get(risk, "station_calendar_direction")) ++
      RequirementContext.canonical_direction_values(Map.get(risk, "station_calendar_directions"))
  end

  def context_values(risk, "station_calendar_status") do
    RequirementContext.direction_values(Map.get(risk, "station_calendar_status")) ++
      RequirementContext.direction_values(Map.get(risk, "station_calendar_statuses"))
  end

  def context_values(risk, "station_calendar_trust_boundary_status") do
    RequirementContext.direction_values(Map.get(risk, "station_calendar_trust_boundary_status")) ++
      RequirementContext.direction_values(
        Map.get(risk, "station_calendar_trust_boundary_statuses")
      )
  end

  def context_values(risk, "station_calendar_reservation_id") do
    RequirementContext.direction_values(Map.get(risk, "station_calendar_reservation_id")) ++
      RequirementContext.direction_values(Map.get(risk, "station_calendar_reservation_ids")) ++
      RequirementContext.direction_values(Map.get(risk, "station_reservation_id")) ++
      RequirementContext.direction_values(Map.get(risk, "reservation_id")) ++
      RequirementContext.direction_values(Map.get(risk, "station_reservation_ids"))
  end

  def context_values(risk, "station_calendar_reserved_by") do
    RequirementContext.direction_values(Map.get(risk, "station_calendar_reserved_by")) ++
      RequirementContext.direction_values(Map.get(risk, "station_calendar_reserved_bys")) ++
      RequirementContext.direction_values(Map.get(risk, "station_reserved_by")) ++
      RequirementContext.direction_values(Map.get(risk, "reserved_by")) ++
      RequirementContext.direction_values(Map.get(risk, "station_reserved_bys"))
  end

  def context_values(risk, "station_calendar_reservation_status") do
    RequirementContext.direction_values(Map.get(risk, "station_calendar_reservation_status")) ++
      RequirementContext.direction_values(Map.get(risk, "station_calendar_reservation_statuses")) ++
      RequirementContext.direction_values(Map.get(risk, "station_reservation_status")) ++
      RequirementContext.direction_values(Map.get(risk, "reservation_status")) ++
      RequirementContext.direction_values(Map.get(risk, "station_reservation_statuses"))
  end

  def context_values(risk, field) do
    risk
    |> Map.get(field)
    |> RequirementContext.direction_values()
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  defp risk_target_match?(rule, risk) do
    cond do
      not is_nil(rule["target_id"]) ->
        rule["target_id"] == risk["target_id"]

      not is_nil(rule["target_ids"]) ->
        risk["target_id"] in List.wrap(rule["target_ids"])

      true ->
        true
    end
  end

  def direction_match?(rule, values) do
    cond do
      not is_nil(rule["direction"]) ->
        rule["direction"] in values

      not is_nil(rule["directions"]) ->
        Enum.any?(values, &(&1 in List.wrap(rule["directions"])))

      true ->
        true
    end
  end
end
