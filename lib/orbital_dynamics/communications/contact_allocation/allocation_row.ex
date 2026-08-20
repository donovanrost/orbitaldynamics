defmodule OrbitalDynamics.Communications.ContactAllocation.AllocationRow do
  @moduledoc false

  alias OrbitalDynamics.Communications.ContactAllocation.{
    ContactIdentity,
    ContactValidation,
    ProviderCounteroffer,
    StationCapacityEvidence,
    ThroughputEvidence
  }

  alias OrbitalDynamics.Communications.DownlinkLinkBudget

  def build(contact, deferred_by_contact_id, selected_by_contact_id, config) do
    contact_id = ContactIdentity.contact_id(contact)

    cond do
      recommendation = Map.get(deferred_by_contact_id, contact_id) ->
        contact
        |> base(config)
        |> Map.merge(%{
          "allocation_status" => "deferred",
          "allocation_reason" => contention_allocation_reason(recommendation),
          "selected" => false,
          "contention_group_id" => recommendation["group_id"],
          "selected_contact_id" => recommendation["selected_contact_id"],
          "selected_priority" => recommendation["selected_priority"],
          "selected_priority_source" => recommendation["selected_priority_source"],
          "deferred_contact_priorities" => recommendation["deferred_contact_priorities"],
          "requested_priority_fields" => recommendation["requested_priority_fields"],
          "priority_field_evidence_counts" => recommendation["priority_field_evidence_counts"],
          "priority_fields_without_numeric_evidence_count" =>
            recommendation["priority_fields_without_numeric_evidence_count"],
          "priority_fields_without_numeric_evidence" =>
            recommendation["priority_fields_without_numeric_evidence"],
          "resolution_priority_override_count" =>
            recommendation["resolution_priority_override_count"],
          "resolution_priority_override_contact_ids" =>
            recommendation["resolution_priority_override_contact_ids"],
          "review_status" => "operator_review_required",
          "source_contention_recommendation" => recommendation
        })
        |> compact_map()

      recommendation = Map.get(selected_by_contact_id, contact_id) ->
        contact
        |> base(config)
        |> Map.merge(%{
          "allocation_status" => "allocated",
          "allocation_reason" => "selected_by_contention_resolution",
          "selected" => true,
          "contention_group_id" => recommendation["group_id"],
          "deferred_contact_ids" => recommendation["deferred_contact_ids"],
          "selected_priority" => recommendation["selected_priority"],
          "selected_priority_source" => recommendation["selected_priority_source"],
          "deferred_contact_priorities" => recommendation["deferred_contact_priorities"],
          "requested_priority_fields" => recommendation["requested_priority_fields"],
          "priority_field_evidence_counts" => recommendation["priority_field_evidence_counts"],
          "priority_fields_without_numeric_evidence_count" =>
            recommendation["priority_fields_without_numeric_evidence_count"],
          "priority_fields_without_numeric_evidence" =>
            recommendation["priority_fields_without_numeric_evidence"],
          "resolution_priority_override_count" =>
            recommendation["resolution_priority_override_count"],
          "resolution_priority_override_contact_ids" =>
            recommendation["resolution_priority_override_contact_ids"],
          "review_status" => "operator_review_required",
          "source_contention_recommendation" => recommendation
        })
        |> compact_map()

      true ->
        contact
        |> base(config)
        |> Map.merge(%{
          "allocation_status" => "allocated",
          "allocation_reason" => "available",
          "selected" => true,
          "review_status" => "accepted_for_planning"
        })
        |> compact_map()
    end
  end

  def base(contact, config) do
    id = ContactIdentity.contact_id(contact)
    station_capacity_policy = Map.fetch!(config, :station_capacity_policy)

    %{
      "id" => "contact_allocation:#{id}",
      "contact_id" => id,
      "type" => contact["type"] || contact_type_from_direction(contact, config),
      "scenario_id" => ContactIdentity.stable_id_or_nil(contact["scenario_id"]),
      "spacecraft_id" => ContactIdentity.contact_spacecraft_id(contact),
      "ground_station_id" => ContactIdentity.stable_id_or_nil(contact["ground_station_id"]),
      "direction" => contact_direction(contact),
      "contact_status" => ContactValidation.contact_status(contact),
      "source_approval_status" => ContactValidation.contact_approval_status(contact),
      "starts_at_s" => contact["starts_at_s"],
      "ends_at_s" => contact["ends_at_s"],
      "source_window_id" => ContactIdentity.stable_id_or_nil(contact["source_window_id"]),
      "source_window_type" => contact["source_window_type"],
      "source_window" => contact["source_window"],
      "downlink_link_budget" => DownlinkLinkBudget.evidence_for_contact(contact),
      "actual_throughput_mb" => ThroughputEvidence.actual_throughput(contact),
      "actual_data_rate_throughput_derivation" =>
        ThroughputEvidence.actual_data_rate_derivation(contact),
      "completed_fraction" => ContactValidation.completed_fraction_value(contact),
      "required_capacity_fraction" =>
        StationCapacityEvidence.required_capacity_fraction_value(
          contact,
          station_capacity_policy
        ),
      "required_capacity_fraction_source" =>
        StationCapacityEvidence.required_capacity_fraction_source(contact),
      "contact_success" => contact_boolean_value(contact, "contact_success"),
      "contact_result" =>
        provider_result_artifact_value(
          contact_value(contact, "contact_result"),
          Map.fetch!(config, :provider_result_map_value_keys)
        ),
      "contact_success_factor" =>
        ContactValidation.feedback_factor(contact, "contact_success_factor"),
      "contact_success_factor_source" => contact_value(contact, "contact_success_factor_source"),
      "command_success" => contact_boolean_value(contact, "command_success"),
      "command_result" =>
        provider_result_artifact_value(
          contact_value(contact, "command_result"),
          Map.fetch!(config, :provider_result_map_value_keys)
        ),
      "command_success_factor" =>
        ContactValidation.feedback_factor(contact, "command_success_factor"),
      "command_success_factor_source" => contact_value(contact, "command_success_factor_source"),
      "station_calendar_entry_id" => ContactIdentity.contact_station_calendar_entry_id(contact),
      "station_calendar_provider_id" =>
        ContactIdentity.contact_station_calendar_provider_id(contact),
      "station_calendar_provider_entry_id" =>
        ContactIdentity.contact_station_calendar_provider_entry_id(contact),
      "station_calendar_directions" => contact["station_calendar_directions"],
      "station_calendar_status" => contact["station_calendar_status"],
      "station_calendar_precedence_rank" => contact["station_calendar_precedence_rank"],
      "station_calendar_precedence_availability" =>
        contact["station_calendar_precedence_availability"],
      "station_calendar_overlap_count" => contact["station_calendar_overlap_count"],
      "station_calendar_overlap_entry_ids" => contact["station_calendar_overlap_entry_ids"],
      "station_calendar_overlap_availabilities" =>
        contact["station_calendar_overlap_availabilities"],
      "station_calendar_entry_ambiguous" => contact["station_calendar_entry_ambiguous"],
      "station_calendar_ambiguous_entry_count" =>
        contact["station_calendar_ambiguous_entry_count"],
      "station_calendar_ambiguous_entry_ids" => contact["station_calendar_ambiguous_entry_ids"],
      "station_calendar_reservation_overlap_count" =>
        contact["station_calendar_reservation_overlap_count"],
      "station_calendar_reservation_ids" => contact["station_calendar_reservation_ids"],
      "station_calendar_reservation_expires_at_s" =>
        contact["station_calendar_reservation_expires_at_s"],
      "station_calendar_reserved_by" => contact["station_calendar_reserved_by"],
      "station_calendar_reservation_statuses" => contact["station_calendar_reservation_statuses"],
      "station_calendar_trust_boundary_status" =>
        contact["station_calendar_trust_boundary_status"],
      "trust_boundary" => contact["trust_boundary"],
      "provenance" => contact["provenance"],
      "source_station_calendar_entry" => contact["source_station_calendar_entry"],
      "source_station_calendar_overlaps" => contact["source_station_calendar_overlaps"],
      "station_availability" =>
        StationCapacityEvidence.station_availability(contact, station_capacity_policy),
      "station_contention_status" => contact["station_contention_status"],
      "capacity_fraction" =>
        StationCapacityEvidence.station_capacity_fraction(contact, station_capacity_policy),
      "station_reservation_id" =>
        ContactIdentity.stable_id_or_nil(contact["station_reservation_id"]) ||
          ContactIdentity.stable_id_or_nil(contact["reservation_id"]),
      "station_reserved_by" => contact["station_reserved_by"] || contact["reserved_by"],
      "station_reservation_status" =>
        contact["station_reservation_status"] || contact["reservation_status"],
      "station_reservation_expires_at_s" =>
        StationCapacityEvidence.numeric_or_nil(contact["station_reservation_expires_at_s"]) ||
          ContactIdentity.reservation_expires_at_s(
            contact,
            &StationCapacityEvidence.numeric_or_nil/1
          ),
      "station_reservation_match_status" =>
        contact["station_reservation_match_status"] || contact["reservation_match_status"]
    }
    |> Map.merge(ProviderCounteroffer.context(contact))
    |> Map.merge(ThroughputEvidence.downlink_completion_context(contact))
    |> Map.merge(resource_suppression_context(contact))
    |> ContactIdentity.normalize_station_calendar_id_lists()
    |> ContactIdentity.normalize_station_calendar_number_lists(
      &StationCapacityEvidence.numeric_or_nil/1
    )
    |> ContactIdentity.derive_station_calendar_counts()
    |> compact_map()
  end

  def resource_suppression_context(row) do
    Map.take(row, [
      "resource_blocking_dimension",
      "resource_source_quality",
      "resource_trust_boundary",
      "resource_trust_boundary_status",
      "resource_provenance",
      "source_resource_summary",
      "fuel_margin",
      "power_margin",
      "storage_margin",
      "downlink_margin",
      "thermal_margin_c",
      "battery_capacity_wh",
      "battery_energy_used_wh",
      "battery_state_of_charge",
      "spacecraft_available",
      "payload_available",
      "antenna_available",
      "degraded",
      "mode",
      "incompatible_activity_types",
      "suppressed_activity_types"
    ])
  end

  defp contention_allocation_reason(%{"resource_scope" => "spacecraft"}),
    do: "same_spacecraft_contention"

  defp contention_allocation_reason(_recommendation), do: "same_station_contention"

  defp contact_direction(%{"direction" => direction})
       when is_binary(direction) and direction != "",
       do: direction

  defp contact_direction(%{"type" => "command"}), do: "command"
  defp contact_direction(%{"type" => "tracking"}), do: "tracking"
  defp contact_direction(%{"type" => "health_check"}), do: "health_check"
  defp contact_direction(_contact), do: "downlink"

  defp contact_type_from_direction(%{"direction" => "downlink"}, _config), do: "downlink"

  defp contact_type_from_direction(%{"direction" => direction}, config) do
    if direction in Map.fetch!(config, :contact_directions), do: "planned_contact"
  end

  defp contact_type_from_direction(contact, _config) do
    if ContactValidation.provider_downlink_contact_input?(contact), do: "downlink"
  end

  defp contact_boolean_value(contact, key) do
    contact
    |> contact_value(key)
    |> boolean_value()
  end

  defp boolean_value(value) when is_boolean(value), do: value
  defp boolean_value(value) when value == 1, do: true
  defp boolean_value(value) when value == 0, do: false

  defp boolean_value(value) when is_binary(value) do
    case String.downcase(String.trim(value)) do
      "true" -> true
      "1" -> true
      "false" -> false
      "0" -> false
      _value -> nil
    end
  end

  defp boolean_value(_value), do: nil

  defp contact_value(contact, key) do
    case Map.fetch(contact, key) do
      {:ok, nil} -> get_in(contact, ["metadata", key])
      {:ok, value} -> value
      :error -> get_in(contact, ["metadata", key])
    end
  end

  defp provider_result_values(values, keys) when is_list(values) do
    values
    |> Enum.flat_map(&provider_result_values(&1, keys))
    |> Enum.reject(&(&1 == ""))
  end

  defp provider_result_values(%{} = result, keys) do
    keys
    |> Enum.flat_map(fn key -> provider_result_values(Map.get(result, key), keys) end)
    |> Enum.reject(&(&1 == ""))
  end

  defp provider_result_values(value, _keys) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> []
      value -> [value]
    end
  end

  defp provider_result_values(nil, _keys), do: []

  defp provider_result_values(value, keys) when is_atom(value),
    do: provider_result_values(Atom.to_string(value), keys)

  defp provider_result_values(value, keys),
    do: provider_result_values(to_string(value), keys)

  defp provider_result_artifact_value(value, keys) do
    case provider_result_values(value, keys) do
      [] -> nil
      values -> Enum.join(values, ",")
    end
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
