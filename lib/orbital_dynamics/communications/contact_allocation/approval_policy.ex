defmodule OrbitalDynamics.Communications.ContactAllocation.ApprovalPolicy do
  @moduledoc false

  alias OrbitalDynamics.Policy
  alias OrbitalDynamics.Communications.ContactAllocation.ProviderCounteroffer

  def apply(rows, nil, _command_directions), do: rows

  def apply(rows, approval_policy, command_directions) do
    Enum.map(rows, fn row ->
      if allocation_policy_boundary?(row) do
        apply_approval_policy(row, approval_policy, command_directions)
      else
        row
      end
    end)
  end

  defp allocation_policy_boundary?(%{"allocation_status" => status}) when status != "allocated",
    do: true

  defp allocation_policy_boundary?(%{"review_status" => "operator_review_required"}), do: true

  defp allocation_policy_boundary?(%{"station_availability" => availability})
       when availability in ["reserved", "unavailable", "maintenance", "reduced_capacity"],
       do: true

  defp allocation_policy_boundary?(%{"station_contention_status" => status})
       when is_binary(status) and status != "",
       do: true

  defp allocation_policy_boundary?(%{"station_calendar_trust_boundary_status" => status})
       when status in ["declared", "missing"],
       do: true

  defp allocation_policy_boundary?(row) do
    Enum.any?(
      [
        "contact_success",
        "contact_result",
        "contact_success_factor",
        "command_success",
        "command_result",
        "command_success_factor"
      ],
      &Map.has_key?(row, &1)
    )
  end

  defp apply_approval_policy(row, approval_policy, command_directions) do
    requirement = allocation_approval_requirement(row, command_directions)

    {status, requirements, rule_matches, decision} =
      Policy.decide(
        [requirement],
        [],
        %{"id" => "contact_allocation", "events" => []},
        %{},
        approval_policy
      )

    row
    |> Map.put("approval_status", status)
    |> Map.put("approval_requirements", requirements)
    |> Map.put("approval_rule_matches", rule_matches)
    |> Map.put("policy_decision", decision)
  end

  defp allocation_approval_requirement(row, command_directions) do
    %{
      "schema_contract" => "approval_requirement.v1",
      "id" => "approval:#{row["id"]}",
      "activity_id" => row["contact_id"],
      "activity_type" => row["type"] || "planned_contact",
      "action" => "review_contact_allocation",
      "requirement_type" => allocation_requirement_type(row, command_directions),
      "reason" => allocation_requirement_reason(row, command_directions),
      "activity_context" => allocation_policy_context(row)
    }
  end

  defp allocation_requirement_type(row, command_directions) do
    cond do
      health_check_contact_allocation?(row) -> "health_check_review"
      command_contact_allocation?(row, command_directions) -> "command_review"
      true -> "contact_schedule_change"
    end
  end

  defp allocation_requirement_reason(row, command_directions) do
    cond do
      health_check_contact_allocation?(row) ->
        "health-check contact allocation #{row["allocation_status"]}: #{row["allocation_reason"]}"

      command_contact_allocation?(row, command_directions) ->
        "command contact allocation #{row["allocation_status"]}: #{row["allocation_reason"]}"

      true ->
        "contact allocation #{row["allocation_status"]}: #{row["allocation_reason"]}"
    end
  end

  defp health_check_contact_allocation?(row) do
    row["direction"] == "health_check" or row["type"] == "health_check"
  end

  defp command_contact_allocation?(row, command_directions) do
    row["direction"] in command_directions or row["type"] == "command"
  end

  defp allocation_policy_context(row) do
    row
    |> Map.take([
      "contact_id",
      "type",
      "direction",
      "allocation_status",
      "effective_allocation_status",
      "allocation_reason",
      "suppressed_reason",
      "contention_group_id",
      "selected_contact_id",
      "deferred_contact_ids",
      "selected_priority",
      "selected_priority_source",
      "deferred_contact_priorities",
      "requested_priority_fields",
      "priority_field_evidence_counts",
      "priority_fields_without_numeric_evidence_count",
      "priority_fields_without_numeric_evidence",
      "resolution_priority_override_count",
      "resolution_priority_override_contact_ids",
      "starts_at_s",
      "ends_at_s",
      "source_window_id",
      "source_window_revision",
      "source_window_type",
      "source_window",
      "downlink_link_budget_id",
      "actual_throughput_mb",
      "actual_data_rate_throughput_derivation",
      "completed_fraction",
      "required_downlink_mb",
      "candidate_downlink_mb",
      "downlink_completion_ratio",
      "selected_downlink_shortfall_mb",
      "downlink_requirement_status",
      "downlink_completion_source",
      "downlink_completion_sources",
      "required_capacity_fraction",
      "contact_success",
      "contact_result",
      "contact_success_factor",
      "contact_success_factor_source",
      "command_success",
      "command_result",
      "command_success_factor",
      "command_success_factor_source",
      "ground_station_id",
      "station_availability",
      "capacity_fraction",
      "station_contention_status",
      "station_calendar_entry_id",
      "station_calendar_provider_id",
      "station_calendar_provider_entry_id",
      "station_calendar_directions",
      "station_calendar_status",
      "station_calendar_overlap_count",
      "station_calendar_overlap_entry_ids",
      "station_calendar_overlap_availabilities",
      "station_calendar_entry_ambiguous",
      "station_calendar_ambiguous_entry_count",
      "station_calendar_ambiguous_entry_ids",
      "station_calendar_reservation_overlap_count",
      "station_calendar_reservation_ids",
      "station_calendar_reservation_expires_at_s",
      "station_calendar_reserved_by",
      "station_calendar_reservation_statuses",
      "station_calendar_trust_boundary_status",
      "trust_boundary",
      "provenance",
      "source_station_calendar_entry",
      "source_station_calendar_overlaps",
      "station_reservation_id",
      "station_reservation_expires_at_s",
      "station_reserved_by",
      "station_reservation_status",
      "station_reservation_match_status",
      "resource_blocking_dimension",
      "resource_source_quality",
      "resource_trust_boundary",
      "resource_trust_boundary_status",
      "resource_provenance",
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
      "suppressed_activity_types",
      "source_resource_summary"
    ])
    |> Map.merge(ProviderCounteroffer.context(row))
    |> compact_map()
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
