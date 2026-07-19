defmodule OrbitalDynamics.Policy.EventMatcher do
  @moduledoc false

  alias OrbitalDynamics.Policy.{RequirementContext, RiskMatcher}

  def match?(rule, event) do
    event_type_match? =
      cond do
        not is_nil(rule["event_type"]) ->
          rule["event_type"] == event["type"]

        not is_nil(rule["event_types"]) ->
          event["type"] in List.wrap(rule["event_types"])

        true ->
          false
      end

    event_type_match? and event_direction_match?(rule, event) and
      event_ground_station_match?(rule, event) and event_spacecraft_match?(rule, event) and
      event_target_match?(rule, event) and event_status_match?(rule, event) and
      event_allocation_match?(rule, event) and event_station_calendar_match?(rule, event) and
      event_provenance_match?(rule, event)
  end

  defp event_status_match?(rule, event) do
    event_context_match?(rule, event, "status", "statuses", "status") and
      event_context_match?(rule, event, "approval_status", "approval_statuses", "approval_status") and
      event_context_match?(
        rule,
        event,
        "policy_classification",
        "policy_classifications",
        "policy_classification"
      )
  end

  defp event_allocation_match?(rule, event) do
    event_context_match?(
      rule,
      event,
      "allocation_status",
      "allocation_statuses",
      "allocation_status"
    ) and
      event_context_match?(
        rule,
        event,
        "effective_allocation_status",
        "effective_allocation_statuses",
        "effective_allocation_status"
      ) and
      event_context_match?(
        rule,
        event,
        "allocation_reason",
        "allocation_reasons",
        "allocation_reason"
      )
  end

  defp event_station_calendar_match?(rule, event) do
    event_context_match?(
      rule,
      event,
      "station_calendar_entry_id",
      "station_calendar_entry_ids",
      "station_calendar_entry_id"
    ) and
      event_context_match?(
        rule,
        event,
        "station_calendar_provider_id",
        "station_calendar_provider_ids",
        "station_calendar_provider_id"
      ) and
      event_context_match?(
        rule,
        event,
        "station_calendar_provider_entry_id",
        "station_calendar_provider_entry_ids",
        "station_calendar_provider_entry_id"
      ) and
      event_context_match?(
        rule,
        event,
        "station_calendar_direction",
        "station_calendar_directions",
        "station_calendar_direction"
      ) and
      event_context_match?(
        rule,
        event,
        "station_calendar_status",
        "station_calendar_statuses",
        "station_calendar_status"
      ) and
      event_context_match?(
        rule,
        event,
        "station_calendar_trust_boundary_status",
        "station_calendar_trust_boundary_statuses",
        "station_calendar_trust_boundary_status"
      ) and
      event_context_match?(
        rule,
        event,
        "station_calendar_reservation_id",
        "station_calendar_reservation_ids",
        "station_calendar_reservation_id"
      ) and
      event_context_match?(
        rule,
        event,
        "station_calendar_reserved_by",
        "station_calendar_reserved_bys",
        "station_calendar_reserved_by"
      ) and
      event_context_match?(
        rule,
        event,
        "station_calendar_reservation_status",
        "station_calendar_reservation_statuses",
        "station_calendar_reservation_status"
      )
  end

  defp event_provenance_match?(rule, event) do
    event_context_match?(rule, event, "feedback_source", "feedback_sources", "feedback_source") and
      event_context_match?(rule, event, "feedback_scope", "feedback_scopes", "feedback_scope") and
      event_context_match?(rule, event, "trust_boundary", "trust_boundaries", "trust_boundary") and
      event_context_match?(rule, event, "source_event_type", "source_event_types", "type")
  end

  defp event_context_match?(rule, event, singular_rule_field, plural_rule_field, field) do
    values = context_values(event, field)

    cond do
      not is_nil(rule[singular_rule_field]) ->
        rule[singular_rule_field] in values

      not is_nil(rule[plural_rule_field]) ->
        Enum.any?(values, &(&1 in List.wrap(rule[plural_rule_field])))

      true ->
        true
    end
  end

  def context_values(event, "station_calendar_provider_id") do
    RequirementContext.direction_values(Map.get(event, "station_calendar_provider_id")) ++
      RequirementContext.direction_values(Map.get(event, "station_calendar_provider_ids"))
  end

  def context_values(event, "station_calendar_provider_entry_id") do
    RequirementContext.direction_values(Map.get(event, "station_calendar_provider_entry_id")) ++
      RequirementContext.direction_values(Map.get(event, "station_calendar_provider_entry_ids"))
  end

  def context_values(event, "station_calendar_entry_id") do
    RequirementContext.direction_values(Map.get(event, "station_calendar_entry_id")) ++
      RequirementContext.direction_values(Map.get(event, "station_calendar_entry_ids"))
  end

  def context_values(event, "station_calendar_direction") do
    RequirementContext.canonical_direction_values(Map.get(event, "station_calendar_direction")) ++
      RequirementContext.canonical_direction_values(Map.get(event, "station_calendar_directions"))
  end

  def context_values(event, "station_calendar_status") do
    RequirementContext.direction_values(Map.get(event, "station_calendar_status")) ++
      RequirementContext.direction_values(Map.get(event, "station_calendar_statuses"))
  end

  def context_values(event, "station_calendar_trust_boundary_status") do
    RequirementContext.direction_values(Map.get(event, "station_calendar_trust_boundary_status")) ++
      RequirementContext.direction_values(
        Map.get(event, "station_calendar_trust_boundary_statuses")
      )
  end

  def context_values(event, "station_calendar_reservation_id") do
    RequirementContext.direction_values(Map.get(event, "station_calendar_reservation_id")) ++
      RequirementContext.direction_values(Map.get(event, "station_calendar_reservation_ids")) ++
      RequirementContext.direction_values(Map.get(event, "station_reservation_id")) ++
      RequirementContext.direction_values(Map.get(event, "reservation_id")) ++
      RequirementContext.direction_values(Map.get(event, "station_reservation_ids"))
  end

  def context_values(event, "station_calendar_reserved_by") do
    RequirementContext.direction_values(Map.get(event, "station_calendar_reserved_by")) ++
      RequirementContext.direction_values(Map.get(event, "station_calendar_reserved_bys")) ++
      RequirementContext.direction_values(Map.get(event, "station_reserved_by")) ++
      RequirementContext.direction_values(Map.get(event, "reserved_by")) ++
      RequirementContext.direction_values(Map.get(event, "station_reserved_bys"))
  end

  def context_values(event, "station_calendar_reservation_status") do
    RequirementContext.direction_values(Map.get(event, "station_calendar_reservation_status")) ++
      RequirementContext.direction_values(Map.get(event, "station_calendar_reservation_statuses")) ++
      RequirementContext.direction_values(Map.get(event, "station_reservation_status")) ++
      RequirementContext.direction_values(Map.get(event, "reservation_status")) ++
      RequirementContext.direction_values(Map.get(event, "station_reservation_statuses"))
  end

  def context_values(event, field) do
    event
    |> Map.get(field)
    |> RequirementContext.direction_values()
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  defp event_direction_match?(rule, event) do
    RiskMatcher.direction_match?(rule, directions(event))
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

  def direction(_event), do: nil

  def directions(event) do
    (RequirementContext.canonical_direction_values(Map.get(event, "direction")) ++
       RequirementContext.canonical_direction_values(Map.get(event, "directions")))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  defp event_ground_station_match?(rule, event) do
    event_station_id = ground_station_id(event)

    cond do
      not is_nil(rule["ground_station_id"]) ->
        rule["ground_station_id"] == event_station_id

      not is_nil(rule["ground_station_ids"]) ->
        event_station_id in List.wrap(rule["ground_station_ids"])

      true ->
        true
    end
  end

  def ground_station_id(event) do
    Map.get(event, "ground_station_id") || Map.get(event, "station_id")
  end

  defp event_spacecraft_match?(rule, event) do
    event_spacecraft_id = spacecraft_id(event)

    cond do
      not is_nil(rule["spacecraft_id"]) ->
        rule["spacecraft_id"] == event_spacecraft_id

      not is_nil(rule["spacecraft_ids"]) ->
        event_spacecraft_id in List.wrap(rule["spacecraft_ids"])

      true ->
        true
    end
  end

  def spacecraft_id(event) do
    Map.get(event, "spacecraft_id") || Map.get(event, "scenario_id")
  end

  defp event_target_match?(rule, event) do
    cond do
      not is_nil(rule["target_id"]) ->
        rule["target_id"] == event["target_id"]

      not is_nil(rule["target_ids"]) ->
        event["target_id"] in List.wrap(rule["target_ids"])

      true ->
        true
    end
  end
end
