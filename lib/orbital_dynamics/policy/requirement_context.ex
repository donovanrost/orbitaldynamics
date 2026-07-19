defmodule OrbitalDynamics.Policy.RequirementContext do
  @moduledoc false

  @provider_result_map_value_keys ~w(result results outcome outcomes status state disposition provider_result provider_results provider_outcome provider_outcomes provider_status provider_state provider_code code reason reasons message messages error errors details metadata provider diagnostics)
  @direction_aliases %{
    "cmd" => "command",
    "commanding" => "command",
    "down_link" => "downlink",
    "health" => "health_check",
    "health_check_window" => "health_check",
    "healthcheck" => "health_check",
    "track" => "tracking",
    "track_ing" => "tracking",
    "up_link" => "uplink"
  }
  def direction_aliases, do: @direction_aliases
  def provider_result_map_value_keys, do: @provider_result_map_value_keys

  def value(requirement, field) do
    requirement
    |> requirement_context_maps()
    |> Enum.reduce_while(nil, fn context, _acc ->
      case context_value(context, field) do
        nil -> {:cont, nil}
        value -> {:halt, normalize_value(field, value)}
      end
    end)
  end

  def values(requirement, "direction") do
    requirement
    |> requirement_context_maps()
    |> Enum.flat_map(fn context ->
      canonical_direction_values(context_value(context, "direction")) ++
        canonical_direction_values(context_value(context, "directions"))
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  def values(requirement, "ground_station_id") do
    requirement
    |> requirement_context_maps()
    |> Enum.flat_map(fn context ->
      direction_values(context_value(context, "ground_station_id")) ++
        direction_values(context_value(context, "ground_station_ids")) ++
        direction_values(context_value(context, "station_ids"))
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  def values(requirement, "spacecraft_id") do
    requirement
    |> requirement_context_maps()
    |> Enum.flat_map(fn context ->
      direction_values(context_value(context, "spacecraft_id")) ++
        direction_values(context_value(context, "spacecraft_ids")) ++
        direction_values(context_value(context, "scenario_ids"))
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  def values(requirement, "target_id") do
    requirement
    |> requirement_context_maps()
    |> Enum.flat_map(fn context ->
      direction_values(context_value(context, "target_id")) ++
        direction_values(context_value(context, "target_ids"))
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  def values(requirement, field)
      when field in [
             "status",
             "approval_status",
             "policy_classification",
             "review_queue",
             "review_queue_key",
             "cadence_import_status"
           ] do
    plural_field =
      case field do
        "status" -> "statuses"
        "policy_classification" -> "policy_classifications"
        "review_queue" -> "review_queues"
        "review_queue_key" -> "review_queue_keys"
        value -> value <> "es"
      end

    requirement
    |> requirement_context_maps()
    |> Enum.flat_map(fn context ->
      direction_values(context_value(context, field)) ++
        direction_values(context_value(context, plural_field))
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  def values(requirement, field)
      when field in ["station_availability", "station_contention_status"] do
    plural_field =
      case field do
        "station_availability" -> "station_availabilities"
        value -> value <> "es"
      end

    requirement
    |> requirement_context_maps()
    |> Enum.flat_map(fn context ->
      direction_values(context_value(context, field)) ++
        direction_values(context_value(context, plural_field))
    end)
    |> Enum.map(&normalize_station_status/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  def values(requirement, "resource_pressure_types") do
    requirement
    |> requirement_context_maps()
    |> Enum.flat_map(fn context ->
      direction_values(context_value(context, "resource_pressure_type")) ++
        direction_values(context_value(context, "resource_pressure_types"))
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  def values(requirement, field)
      when field in [
             "resource_pressure_status",
             "resource_source_quality",
             "resource_trust_boundary",
             "resource_trust_boundary_status",
             "first_resource_pressure_kind",
             "feedback_source",
             "feedback_scope",
             "trust_boundary",
             "source_event_type"
           ] do
    plural_field =
      case field do
        "resource_pressure_status" -> "resource_pressure_statuses"
        "resource_source_quality" -> "resource_source_qualities"
        "resource_trust_boundary" -> "resource_trust_boundaries"
        "resource_trust_boundary_status" -> "resource_trust_boundary_statuses"
        "first_resource_pressure_kind" -> "first_resource_pressure_kinds"
        "trust_boundary" -> "trust_boundaries"
        value -> value <> "s"
      end

    requirement
    |> requirement_context_maps()
    |> Enum.flat_map(fn context ->
      direction_values(context_value(context, field)) ++
        direction_values(context_value(context, plural_field))
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  def values(requirement, field)
      when field in [
             "resource_scope",
             "selection_reason",
             "selected_priority_source",
             "resolution_status",
             "resolution_issue",
             "required_operator_action",
             "operator_action_reason",
             "allocation_status",
             "effective_allocation_status",
             "allocation_reason",
             "suppressed_reason",
             "resource_blocking_dimension",
             "transition_decision",
             "application_status",
             "planned_protection_decision",
             "planned_protection_category",
             "timeline_integrity_status",
             "source_timeline_integrity_status",
             "replacement_timeline_integrity_status",
             "source_protection_decision",
             "source_protection_category",
             "replacement_protection_decision",
             "replacement_protection_category"
           ] do
    plural_field =
      case field do
        "selected_priority_source" -> "selected_priority_sources"
        "resolution_status" -> "resolution_statuses"
        "allocation_status" -> "allocation_statuses"
        "effective_allocation_status" -> "effective_allocation_statuses"
        "suppressed_reason" -> "suppressed_reasons"
        "transition_decision" -> "transition_decisions"
        "application_status" -> "application_statuses"
        "planned_protection_decision" -> "planned_protection_decisions"
        "planned_protection_category" -> "planned_protection_categories"
        "timeline_integrity_status" -> "timeline_integrity_statuses"
        "source_timeline_integrity_status" -> "source_timeline_integrity_statuses"
        "replacement_timeline_integrity_status" -> "replacement_timeline_integrity_statuses"
        "source_protection_decision" -> "source_protection_decisions"
        "source_protection_category" -> "source_protection_categories"
        "replacement_protection_decision" -> "replacement_protection_decisions"
        "replacement_protection_category" -> "replacement_protection_categories"
        value -> value <> "s"
      end

    requirement
    |> requirement_context_maps()
    |> Enum.flat_map(fn context ->
      direction_values(context_value(context, field)) ++
        direction_values(context_value(context, plural_field))
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  def values(requirement, "priority_fields_without_numeric_evidence") do
    requirement
    |> requirement_context_maps()
    |> Enum.flat_map(fn context ->
      direction_values(context_value(context, "priority_field_without_numeric_evidence")) ++
        direction_values(context_value(context, "priority_fields_without_numeric_evidence"))
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  def values(requirement, "timeline_integrity_issue_types") do
    requirement
    |> requirement_context_maps()
    |> Enum.flat_map(fn context ->
      direction_values(context_value(context, "timeline_integrity_issue_type")) ++
        direction_values(context_value(context, "timeline_integrity_issue_types"))
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  def values(requirement, "source_timeline_integrity_issue_types") do
    requirement
    |> requirement_context_maps()
    |> Enum.flat_map(fn context ->
      direction_values(context_value(context, "source_timeline_integrity_issue_type")) ++
        direction_values(context_value(context, "source_timeline_integrity_issue_types"))
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  def values(requirement, "replacement_timeline_integrity_issue_types") do
    requirement
    |> requirement_context_maps()
    |> Enum.flat_map(fn context ->
      direction_values(context_value(context, "replacement_timeline_integrity_issue_type")) ++
        direction_values(context_value(context, "replacement_timeline_integrity_issue_types"))
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  def values(requirement, field)
      when field in [
             "contact_result",
             "command_result",
             "observation_result",
             "maneuver_result"
           ] do
    requirement
    |> requirement_context_maps()
    |> Enum.flat_map(fn context ->
      provider_result_values(context_value(context, field)) ++
        provider_result_values(context_value(context, field <> "s"))
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  def values(requirement, "station_calendar_trust_boundary_status") do
    requirement
    |> requirement_context_maps()
    |> Enum.flat_map(fn context ->
      direction_values(context_value(context, "station_calendar_trust_boundary_status")) ++
        direction_values(context_value(context, "station_calendar_trust_boundary_statuses"))
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  def values(requirement, "station_calendar_status") do
    requirement
    |> requirement_context_maps()
    |> Enum.flat_map(fn context ->
      direction_values(context_value(context, "station_calendar_status")) ++
        direction_values(context_value(context, "station_calendar_statuses"))
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  def values(requirement, "station_calendar_direction") do
    requirement
    |> requirement_context_maps()
    |> Enum.flat_map(fn context ->
      canonical_direction_values(context_value(context, "station_calendar_direction")) ++
        canonical_direction_values(context_value(context, "station_calendar_directions"))
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  def values(requirement, "station_calendar_provider_id") do
    requirement
    |> requirement_context_maps()
    |> Enum.flat_map(fn context ->
      direction_values(context_value(context, "station_calendar_provider_id")) ++
        direction_values(context_value(context, "station_calendar_provider_ids"))
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  def values(requirement, "station_calendar_provider_entry_id") do
    requirement
    |> requirement_context_maps()
    |> Enum.flat_map(fn context ->
      direction_values(context_value(context, "station_calendar_provider_entry_id")) ++
        direction_values(context_value(context, "station_calendar_provider_entry_ids"))
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  def values(requirement, "station_calendar_entry_id") do
    requirement
    |> requirement_context_maps()
    |> Enum.flat_map(fn context ->
      direction_values(context_value(context, "station_calendar_entry_id")) ++
        direction_values(context_value(context, "station_calendar_entry_ids"))
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  def values(requirement, "station_calendar_reservation_id") do
    requirement
    |> requirement_context_maps()
    |> Enum.flat_map(fn context ->
      direction_values(context_value(context, "station_calendar_reservation_id")) ++
        direction_values(context_value(context, "station_calendar_reservation_ids"))
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  def values(requirement, "station_reservation_id") do
    requirement
    |> requirement_context_maps()
    |> Enum.flat_map(fn context ->
      direction_values(context_value(context, "station_reservation_id")) ++
        direction_values(context_value(context, "station_reservation_ids"))
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  def values(requirement, "station_reserved_by") do
    requirement
    |> requirement_context_maps()
    |> Enum.flat_map(fn context ->
      direction_values(context_value(context, "station_reserved_by")) ++
        direction_values(context_value(context, "reserved_by")) ++
        direction_values(context_value(context, "station_reserved_bys"))
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  def values(requirement, "station_reservation_status") do
    requirement
    |> requirement_context_maps()
    |> Enum.flat_map(fn context ->
      direction_values(context_value(context, "station_reservation_status")) ++
        direction_values(context_value(context, "reservation_status")) ++
        direction_values(context_value(context, "station_reservation_statuses"))
    end)
    |> Enum.map(&normalize_station_status/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  def values(requirement, "station_reservation_match_status") do
    requirement
    |> requirement_context_maps()
    |> Enum.flat_map(fn context ->
      direction_values(context_value(context, "station_reservation_match_status")) ++
        direction_values(context_value(context, "reservation_match_status")) ++
        direction_values(context_value(context, "station_reservation_match_statuses"))
    end)
    |> Enum.map(&normalize_station_status/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  def values(requirement, "station_calendar_reserved_by") do
    requirement
    |> requirement_context_maps()
    |> Enum.flat_map(fn context ->
      direction_values(context_value(context, "station_calendar_reserved_by")) ++
        direction_values(context_value(context, "station_calendar_reserved_bys"))
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  def values(requirement, "station_calendar_reservation_status") do
    requirement
    |> requirement_context_maps()
    |> Enum.flat_map(fn context ->
      direction_values(context_value(context, "station_calendar_reservation_status")) ++
        direction_values(context_value(context, "station_calendar_reservation_statuses"))
    end)
    |> Enum.map(&normalize_station_status/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  def values(requirement, "station_calendar_ambiguous_entry_id") do
    requirement
    |> requirement_context_maps()
    |> Enum.flat_map(fn context ->
      direction_values(context_value(context, "station_calendar_ambiguous_entry_id")) ++
        direction_values(context_value(context, "station_calendar_ambiguous_entry_ids"))
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  def values(requirement, field) do
    case value(requirement, field) do
      nil -> []
      value when is_list(value) -> value
      value -> [value]
    end
  end

  defp normalize_value(field, value)
       when field in [
              "station_availability",
              "station_contention_status",
              "station_reservation_status",
              "station_reservation_match_status",
              "station_calendar_reservation_status"
            ] do
    normalize_station_status(value)
  end

  defp normalize_value(_field, value), do: value

  def normalize_station_status(values) when is_list(values) do
    values
    |> Enum.map(&normalize_station_status/1)
    |> Enum.reject(&(&1 in [nil, ""]))
  end

  def normalize_station_status(nil), do: nil

  def normalize_station_status(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
  end

  def normalize_station_status(value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> normalize_station_status()
  end

  def normalize_station_status(value), do: value

  def normalize_direction_field(map, field) do
    case Map.fetch(map, field) do
      {:ok, value} -> Map.put(map, field, normalize_direction(value))
      :error -> map
    end
  end

  def normalize_direction(values) when is_list(values) do
    values
    |> Enum.map(&normalize_direction/1)
    |> Enum.reject(&(&1 in [nil, ""]))
  end

  def normalize_direction(nil), do: nil

  def normalize_direction(value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> normalize_direction()
  end

  def normalize_direction(value) when is_binary(value) do
    normalized =
      value
      |> String.trim()
      |> String.downcase()
      |> String.replace(~r/[\s-]+/, "_")

    Map.get(@direction_aliases, normalized, normalized)
  end

  def normalize_direction(value), do: value

  def direction_values(nil), do: []
  def direction_values(values) when is_list(values), do: values
  def direction_values(value), do: [value]

  def canonical_direction_values(value) do
    value
    |> direction_values()
    |> Enum.map(&normalize_direction/1)
  end

  def provider_result_context_value(requirement, field) do
    case value(requirement, field) do
      nil ->
        nil

      value when is_binary(value) ->
        value

      value ->
        case provider_result_values(value) do
          [] -> nil
          values -> Enum.join(values, ",")
        end
    end
  end

  defp provider_result_values(nil), do: []

  defp provider_result_values(values) when is_list(values) do
    Enum.flat_map(values, &provider_result_values/1)
  end

  defp provider_result_values(%{} = result) do
    @provider_result_map_value_keys
    |> Enum.flat_map(fn key -> provider_result_values(Map.get(result, key)) end)
    |> Enum.reject(&(&1 in [nil, ""]))
  end

  defp provider_result_values(value) do
    value
    |> to_string()
    |> String.split(",", trim: true)
    |> Enum.map(&normalize_provider_result_token/1)
    |> Enum.reject(&(&1 in [nil, ""]))
  end

  def normalize_provider_result_token(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
  end

  def normalize_provider_result_token(value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> normalize_provider_result_token()
  end

  def normalize_provider_result_token(value) when is_number(value),
    do: normalize_provider_result_token(to_string(value))

  def normalize_provider_result_token(_value), do: nil

  defp context_value(context, "ground_station_id") do
    Map.get(context, "ground_station_id") || Map.get(context, "station_id")
  end

  defp context_value(context, "spacecraft_id") do
    Map.get(context, "spacecraft_id") || Map.get(context, "scenario_id")
  end

  defp context_value(context, "source_protection_decision") do
    protection_context_value(context, "source_protection_decision", "protection_decision")
  end

  defp context_value(context, "source_protection_category") do
    protection_context_value(context, "source_protection_decision", "protection_category") ||
      Map.get(context, "source_protection_category")
  end

  defp context_value(context, "replacement_protection_decision") do
    protection_context_value(context, "replacement_protection_decision", "protection_decision")
  end

  defp context_value(context, "replacement_protection_category") do
    protection_context_value(context, "replacement_protection_decision", "protection_category") ||
      Map.get(context, "replacement_protection_category")
  end

  defp context_value(context, field), do: Map.get(context, field)

  defp protection_context_value(context, protection_field, nested_field) do
    case Map.get(context, protection_field) do
      %{} = protection -> Map.get(protection, nested_field)
      value when nested_field == "protection_decision" -> value
      _value -> nil
    end
  end

  defp requirement_context_maps(requirement) do
    [
      requirement,
      Map.get(requirement, "source_activity_context", %{}),
      Map.get(requirement, "activity_context", %{}),
      Map.get(requirement, "metadata", %{})
    ]
  end
end
