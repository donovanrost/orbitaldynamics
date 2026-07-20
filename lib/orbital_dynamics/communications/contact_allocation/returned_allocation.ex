defmodule OrbitalDynamics.Communications.ContactAllocation.ReturnedAllocation do
  @moduledoc false

  alias OrbitalDynamics.Communications.ContactAllocation.ContactIdentity
  alias OrbitalDynamics.Communications.ContactAllocation.ProviderCounteroffer

  def deferred_by_contact_id(resolution_report) do
    resolution_report
    |> Map.get("recommendations", [])
    |> Enum.flat_map(fn recommendation ->
      recommendation
      |> Map.get("deferred_contact_ids", [])
      |> Enum.map(&{&1, recommendation})
    end)
    |> Map.new()
  end

  def selected_by_contact_id(resolution_report) do
    resolution_report
    |> Map.get("recommendations", [])
    |> Enum.map(&{&1["selected_contact_id"], &1})
    |> Enum.reject(fn {contact_id, _recommendation} -> is_nil(contact_id) end)
    |> Map.new()
  end

  def allocation_sort_key(row) do
    {
      row["ground_station_id"] || "",
      row["starts_at_s"] || 0.0,
      row["contact_id"] || "",
      row["id"] || ""
    }
  end

  def allocated_contact_row?(%{"effective_allocation_status" => "allocated"}), do: true

  def allocated_contact_row?(_row), do: false

  def allocated_contact_from_row(row, contention_contacts) do
    contention_contacts
    |> Enum.find(&(ContactIdentity.contact_id(&1) == row["contact_id"]))
    |> Map.merge(returned_allocation_context(row))
    |> compact_map()
  end

  defp returned_allocation_context(row) do
    %{
      "allocation_status" => row["allocation_status"],
      "effective_allocation_status" => row["effective_allocation_status"],
      "allocation_reason" => row["allocation_reason"],
      "review_status" => row["review_status"],
      "selected" => row["selected"],
      "selected_contact_id" => row["selected_contact_id"],
      "deferred_contact_ids" => row["deferred_contact_ids"],
      "selected_priority" => row["selected_priority"],
      "selected_priority_source" => row["selected_priority_source"],
      "deferred_contact_priorities" => row["deferred_contact_priorities"],
      "requested_priority_fields" => row["requested_priority_fields"],
      "priority_field_evidence_counts" => row["priority_field_evidence_counts"],
      "priority_fields_without_numeric_evidence_count" =>
        row["priority_fields_without_numeric_evidence_count"],
      "priority_fields_without_numeric_evidence" =>
        row["priority_fields_without_numeric_evidence"],
      "resolution_priority_override_count" => row["resolution_priority_override_count"],
      "resolution_priority_override_contact_ids" =>
        row["resolution_priority_override_contact_ids"],
      "contention_group_id" => row["contention_group_id"],
      "station_calendar_entry_id" => row["station_calendar_entry_id"],
      "station_calendar_provider_id" => row["station_calendar_provider_id"],
      "station_calendar_provider_entry_id" => row["station_calendar_provider_entry_id"],
      "station_reservation_id" => row["station_reservation_id"],
      "station_reservation_expires_at_s" => row["station_reservation_expires_at_s"],
      "station_reserved_by" => row["station_reserved_by"],
      "station_reservation_status" => row["station_reservation_status"],
      "station_reservation_match_status" => row["station_reservation_match_status"],
      "source_window_id" => row["source_window_id"],
      "source_window_type" => row["source_window_type"],
      "source_window" => row["source_window"],
      "required_capacity_fraction" => row["required_capacity_fraction"],
      "required_capacity_fraction_source" => row["required_capacity_fraction_source"],
      "capacity_pack_group_id" => row["capacity_pack_group_id"],
      "capacity_pack_status" => row["capacity_pack_status"],
      "capacity_pack_capacity_fraction" => row["capacity_pack_capacity_fraction"],
      "capacity_pack_used_fraction" => row["capacity_pack_used_fraction"],
      "approval_status" => row["approval_status"],
      "approval_requirements" => row["approval_requirements"],
      "approval_rule_matches" => row["approval_rule_matches"],
      "policy_decision" => row["policy_decision"]
    }
    |> Map.merge(ProviderCounteroffer.context(row))
  end

  def put_effective_allocation_status(%{"allocation_status" => "allocated"} = row) do
    effective_status =
      if row["approval_status"] == "blocked_by_policy",
        do: "policy_blocked",
        else: "allocated"

    Map.put(row, "effective_allocation_status", effective_status)
  end

  def put_effective_allocation_status(%{"allocation_status" => status} = row),
    do: Map.put(row, "effective_allocation_status", status)

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
