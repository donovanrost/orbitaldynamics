defmodule OrbitalDynamics.Communications.StationCalendar.ApprovalPolicy do
  @moduledoc false

  alias OrbitalDynamics.Policy

  alias OrbitalDynamics.Communications.StationCalendar.{
    ProviderCounterofferHandoffSummary,
    ProviderResult
  }

  @command_contact_directions ~w(command uplink)

  def apply_to_row(row, nil), do: row

  def apply_to_row(row, approval_policy) do
    requirement = station_calendar_approval_requirement(row)

    {status, requirements, matches, decision} =
      Policy.decide(
        [requirement],
        [],
        %{"id" => "station_calendar", "events" => []},
        %{},
        approval_policy
      )

    row
    |> Map.put("approval_status", status)
    |> Map.put("approval_requirements", requirements)
    |> Map.put("approval_rule_matches", matches)
    |> Map.put("policy_decision", decision)
  end

  def apply_to_provider_contention(group, nil), do: group

  def apply_to_provider_contention(group, approval_policy) do
    requirement = provider_contention_approval_requirement(group)

    {status, requirements, matches, decision} =
      Policy.decide(
        [requirement],
        [],
        %{"id" => "station_calendar_provider_contention", "events" => []},
        %{},
        approval_policy
      )

    group
    |> Map.put("approval_status", status)
    |> Map.put("approval_requirements", requirements)
    |> Map.put("approval_rule_matches", matches)
    |> Map.put("policy_decision", decision)
  end

  defp provider_contention_approval_requirement(group) do
    %{
      "activity_id" => group["id"],
      "activity_type" => "contact_contention_resolution",
      "action" => group["required_operator_action"],
      "requirement_type" => "contact_schedule_change",
      "reason" => station_provider_contention_requirement_reason(group),
      "activity_context" =>
        %{
          "ground_station_id" => group["ground_station_id"],
          "required_operator_action" => group["required_operator_action"],
          "operator_action_reason" => group["operator_action_reason"],
          "provider_calendar_contention_status" => group["provider_calendar_contention_status"],
          "station_contention_status" => group["provider_calendar_contention_status"],
          "station_calendar_provider_ids" => group["provider_ids"],
          "station_calendar_provider_entry_ids" => group["provider_entry_ids"],
          "station_calendar_entry_ids" => group["entry_ids"],
          "station_calendar_reservation_ids" => group["reservation_ids"],
          "station_calendar_reserved_by" => group["reserved_by"],
          "station_calendar_reservation_statuses" => group["reservation_statuses"],
          "station_calendar_reservation_expires_at_s" => group["reservation_expires_at_s"],
          "station_calendar_trust_boundary_statuses" => group["trust_boundary_statuses"],
          "station_calendar_directions" => group["directions"],
          "station_calendar_availabilities" => group["availabilities"],
          "overlap_duration_s" => group["overlap_duration_s"],
          "overlap_contact_pair_count" => length(Map.get(group, "overlap_pairs", []))
        }
        |> compact_map()
    }
    |> compact_map()
  end

  defp station_provider_contention_requirement_reason(%{
         "ground_station_id" => station_id,
         "entry_count" => entry_count
       }) do
    "review #{entry_count} overlapping provider calendar entries at #{station_id}"
  end

  defp station_provider_contention_requirement_reason(_group) do
    "review overlapping provider calendar entries"
  end

  defp station_calendar_approval_requirement(row) do
    %{
      "activity_id" => row["contact_id"],
      "activity_type" => row["contact_type"] || "planned_contact",
      "action" => row["required_operator_action"],
      "requirement_type" => station_calendar_requirement_type(row),
      "reason" => station_calendar_requirement_reason(row),
      "activity_context" =>
        %{
          "direction" => row["direction"],
          "ground_station_id" => row["ground_station_id"],
          "required_operator_action" => row["required_operator_action"],
          "operator_action_reason" => row["operator_action_reason"],
          "station_availability" => row["station_availability"],
          "capacity_fraction" => row["capacity_fraction"],
          "station_contention_status" => row["station_contention_status"],
          "station_reservation_status" => row["station_reservation_status"],
          "station_reservation_id" => row["station_reservation_id"],
          "station_reserved_by" => row["station_reserved_by"],
          "station_reservation_match_status" => row["station_reservation_match_status"],
          "station_calendar_entry_id" => row["station_calendar_entry_id"],
          "station_calendar_provider_id" => row["station_calendar_provider_id"],
          "station_calendar_provider_entry_id" => row["station_calendar_provider_entry_id"],
          "station_calendar_overlap_count" => row["station_calendar_overlap_count"],
          "station_calendar_overlap_entry_ids" => row["station_calendar_overlap_entry_ids"],
          "station_calendar_overlap_availabilities" =>
            row["station_calendar_overlap_availabilities"],
          "station_calendar_entry_ambiguous" => row["station_calendar_entry_ambiguous"],
          "station_calendar_ambiguous_entry_count" =>
            row["station_calendar_ambiguous_entry_count"],
          "station_calendar_ambiguous_entry_ids" => row["station_calendar_ambiguous_entry_ids"],
          "station_calendar_reservation_overlap_count" =>
            row["station_calendar_reservation_overlap_count"],
          "station_calendar_reservation_ids" => row["station_calendar_reservation_ids"],
          "station_calendar_reserved_by" => row["station_calendar_reserved_by"],
          "station_calendar_reservation_statuses" => row["station_calendar_reservation_statuses"],
          "station_calendar_trust_boundary_status" =>
            row["station_calendar_trust_boundary_status"],
          "provider_counteroffer_id" => row["provider_counteroffer_id"],
          "provider_counteroffer_status" => row["provider_counteroffer_status"],
          "provider_counteroffer_negotiation_state" =>
            row["provider_counteroffer_negotiation_state"],
          "provider_counteroffer_reason_code" => row["provider_counteroffer_reason_code"],
          "provider_counteroffer_cost_delta" => row["provider_counteroffer_cost_delta"],
          "provider_counteroffer_lock_deadline_s" => row["provider_counteroffer_lock_deadline_s"],
          "provider_counteroffer_starts_at_s" => row["provider_counteroffer_starts_at_s"],
          "provider_counteroffer_ends_at_s" => row["provider_counteroffer_ends_at_s"],
          "provider_counteroffer_start_delta_s" =>
            row["provider_counteroffer_start_delta_s"] ||
              ProviderCounterofferHandoffSummary.numeric_delta(
                row["provider_counteroffer_starts_at_s"],
                row["starts_at_s"]
              ),
          "provider_counteroffer_end_delta_s" =>
            row["provider_counteroffer_end_delta_s"] ||
              ProviderCounterofferHandoffSummary.numeric_delta(
                row["provider_counteroffer_ends_at_s"],
                row["ends_at_s"]
              ),
          "provider_counteroffer_duration_delta_s" =>
            row["provider_counteroffer_duration_delta_s"] ||
              ProviderCounterofferHandoffSummary.duration_delta(row),
          "invalid_feedback_confidence" => row["invalid_feedback_confidence"],
          "invalid_feedback_confidence_reason" => row["invalid_feedback_confidence_reason"],
          "source_contact_candidate" => row["source_contact_candidate"],
          "contact_success" => row["contact_success"],
          "contact_result" => ProviderResult.artifact_value(row["contact_result"]),
          "contact_success_factor" => row["contact_success_factor"],
          "contact_success_factor_source" => row["contact_success_factor_source"],
          "command_success" => row["command_success"],
          "command_result" => ProviderResult.artifact_value(row["command_result"]),
          "command_success_factor" => row["command_success_factor"],
          "command_success_factor_source" => row["command_success_factor_source"],
          "trust_boundary" => row["trust_boundary"],
          "provenance" => row["provenance"]
        }
        |> compact_map()
    }
    |> compact_map()
  end

  defp station_calendar_requirement_type(row) do
    cond do
      health_check_contact_row?(row) -> "health_check_review"
      command_contact_row?(row) -> "command_review"
      true -> "contact_schedule_change"
    end
  end

  defp station_calendar_requirement_reason(row) do
    cond do
      health_check_contact_row?(row) ->
        "health-check contact station calendar review: #{row["operator_action_reason"]}"

      command_contact_row?(row) ->
        "command contact station calendar review: #{row["operator_action_reason"]}"

      true ->
        row["operator_action_reason"]
    end
  end

  defp health_check_contact_row?(row) do
    row["direction"] == "health_check" or row["contact_type"] == "health_check"
  end

  defp command_contact_row?(row) do
    row["direction"] in @command_contact_directions or row["contact_type"] == "command"
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
