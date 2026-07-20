defmodule OrbitalDynamics.ResourceFilter.ApprovalPolicy do
  @moduledoc false

  alias OrbitalDynamics.Policy

  def apply_suppressed_candidate(row, nil), do: row

  def apply_suppressed_candidate(row, approval_policy) do
    requirement = suppression_requirement(row)

    {status, requirements, matches, decision} =
      Policy.decide(
        [requirement],
        suppression_risks(row),
        %{"id" => "resource_filter", "events" => []},
        %{},
        approval_policy
      )

    row
    |> Map.put("approval_status", status)
    |> Map.put("approval_requirements", requirements)
    |> Map.put("approval_rule_matches", matches)
    |> Map.put("policy_decision", decision)
  end

  def apply_invalid_summary(row, nil), do: row

  def apply_invalid_summary(row, approval_policy) do
    requirement = invalid_summary_requirement(row)

    {status, requirements, matches, decision} =
      Policy.decide(
        [requirement],
        invalid_summary_risks(row),
        %{"id" => "resource_filter", "events" => []},
        %{},
        approval_policy
      )

    row
    |> Map.put("approval_status", status)
    |> Map.put("approval_requirements", requirements)
    |> Map.put("approval_rule_matches", matches)
    |> Map.put("policy_decision", decision)
  end

  defp suppression_requirement(row) do
    %{
      "activity_id" => row["id"],
      "activity_type" => row["type"],
      "action" => approval_action(row),
      "requirement_type" => requirement_type(row),
      "reason" => row["suppressed_reason"] || "resource filter suppressed candidate",
      "activity_context" =>
        %{
          "spacecraft_id" => row["spacecraft_id"],
          "scenario_id" => row["scenario_id"],
          "direction" => direction(row),
          "ground_station_id" => row["ground_station_id"],
          "source_window_id" => row["source_window_id"],
          "starts_at_s" => row["starts_at_s"],
          "ends_at_s" => row["ends_at_s"],
          "station_availability" => row["station_availability"],
          "station_calendar_entry_id" => row["station_calendar_entry_id"],
          "station_calendar_directions" => row["station_calendar_directions"],
          "station_calendar_status" => row["station_calendar_status"],
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
          "source_station_calendar_entry" => row["source_station_calendar_entry"],
          "source_station_calendar_overlaps" => row["source_station_calendar_overlaps"],
          "station_contention_status" => row["station_contention_status"],
          "station_reservation_id" => row["station_reservation_id"],
          "station_reserved_by" => row["station_reserved_by"],
          "station_reservation_status" => row["station_reservation_status"],
          "station_reservation_match_status" => row["station_reservation_match_status"],
          "contact_success" => row["contact_success"],
          "contact_result" => row["contact_result"],
          "contact_success_factor" => row["contact_success_factor"],
          "contact_success_factor_source" => row["contact_success_factor_source"],
          "command_success" => row["command_success"],
          "command_result" => row["command_result"],
          "command_success_factor" => row["command_success_factor"],
          "command_success_factor_source" => row["command_success_factor_source"],
          "suppressed_reason" => row["suppressed_reason"],
          "resource_source_quality" => row["resource_source_quality"],
          "resource_trust_boundary" => row["resource_trust_boundary"],
          "resource_trust_boundary_status" => row["resource_trust_boundary_status"],
          "resource_provenance" => row["resource_provenance"],
          "resource_blocking_dimension" => row["resource_blocking_dimension"],
          "fuel_margin" => row["fuel_margin"],
          "thermal_margin_c" => row["thermal_margin_c"],
          "power_margin" => row["power_margin"],
          "storage_margin" => row["storage_margin"],
          "downlink_margin" => row["downlink_margin"],
          "battery_capacity_wh" => row["battery_capacity_wh"],
          "battery_energy_used_wh" => row["battery_energy_used_wh"],
          "battery_state_of_charge" => row["battery_state_of_charge"],
          "payload_available" => row["payload_available"],
          "antenna_available" => row["antenna_available"],
          "degraded" => row["degraded"],
          "mode" => row["mode"],
          "incompatible_activity_types" => row["incompatible_activity_types"],
          "suppressed_activity_types" => row["suppressed_activity_types"]
        }
        |> compact_map()
    }
    |> compact_map()
  end

  defp approval_action(%{"invalid_candidate_input" => true}),
    do: "review_invalid_resource_filter_input"

  defp approval_action(row), do: suppression_action(row)

  defp invalid_summary_requirement(row) do
    %{
      "activity_id" => row["id"],
      "activity_type" => "resource_filter_invalid_summary",
      "action" => "review_invalid_resource_filter_summary",
      "requirement_type" => "operator_review",
      "reason" =>
        row["invalid_resource_summary_input_reason"] || "invalid resource summary input",
      "activity_context" =>
        %{
          "spacecraft_id" => row["spacecraft_id"],
          "resource_summary_id" => row["resource_summary_id"],
          "invalid_resource_summary_input" => row["invalid_resource_summary_input"],
          "invalid_resource_summary_input_reason" => row["invalid_resource_summary_input_reason"],
          "source_resource_summary" => row["source_resource_summary"]
        }
        |> compact_map()
    }
    |> compact_map()
  end

  defp invalid_summary_risks(row) do
    [
      %{
        "type" => "invalid_resource_summary_input",
        "severity" => "medium",
        "reason" =>
          row["invalid_resource_summary_input_reason"] || "invalid resource summary input",
        "activity_id" => row["id"],
        "activity_type" => "resource_filter_invalid_summary",
        "spacecraft_id" => row["spacecraft_id"]
      }
      |> compact_map()
    ]
  end

  defp suppression_action(row) do
    cond do
      antenna_required_candidate?(row) -> "review_suppressed_contact"
      row["type"] == "observe" -> "review_suppressed_observation"
      true -> "review_suppressed_candidate"
    end
  end

  defp requirement_type(row) do
    cond do
      health_check_contact_candidate?(row) -> "health_check_review"
      command_contact_candidate?(row) -> "command_review"
      antenna_required_candidate?(row) -> "contact_schedule_change"
      row["type"] == "observe" -> "observation_reassignment"
      true -> "operator_review"
    end
  end

  defp command_contact_candidate?(row), do: direction(row) in ["command", "uplink"]
  defp health_check_contact_candidate?(row), do: direction(row) == "health_check"

  defp direction(%{"direction" => direction}) when is_binary(direction), do: direction
  defp direction(%{"type" => "downlink"}), do: "downlink"
  defp direction(%{"type" => "tracking"}), do: "tracking"
  defp direction(%{"type" => "uplink"}), do: "uplink"
  defp direction(%{"type" => "command"}), do: "command"
  defp direction(%{"type" => "health_check"}), do: "health_check"
  defp direction(_row), do: nil

  defp antenna_required_candidate?(%{"type" => type})
       when type in ["downlink", "tracking", "uplink", "command", "health_check"],
       do: true

  defp antenna_required_candidate?(%{"type" => "planned_contact", "direction" => direction})
       when direction in ["downlink", "tracking", "uplink", "command", "health_check"],
       do: true

  defp antenna_required_candidate?(%{
         "direction" => direction,
         "ground_station_id" => station_id
       })
       when direction in ["downlink", "tracking", "uplink", "command", "health_check"] and
              not is_nil(station_id),
       do: true

  defp antenna_required_candidate?(candidate), do: downlink_candidate?(candidate)

  defp downlink_candidate?(%{"type" => "downlink"}), do: true
  defp downlink_candidate?(%{"type" => "planned_contact", "direction" => "downlink"}), do: true

  defp downlink_candidate?(%{"direction" => "downlink", "ground_station_id" => station_id})
       when not is_nil(station_id),
       do: true

  defp downlink_candidate?(_candidate), do: false

  defp suppression_risks(%{"suppressed_reason" => reason} = row) do
    reason
    |> risk_type()
    |> case do
      nil ->
        []

      risk_type ->
        [
          %{
            "type" => risk_type,
            "severity" => "medium",
            "reason" => reason,
            "resource_blocking_dimension" => row["resource_blocking_dimension"],
            "activity_id" => row["id"],
            "activity_type" => row["type"],
            "spacecraft_id" => row["spacecraft_id"],
            "scenario_id" => row["scenario_id"],
            "ground_station_id" => row["ground_station_id"],
            "target_id" => row["target_id"],
            "direction" => row["direction"]
          }
          |> compact_map()
        ]
    end
  end

  defp suppression_risks(_row), do: []

  defp risk_type("fuel_margin_below_policy"), do: "fuel_margin_low"
  defp risk_type("thermal_margin_below_policy"), do: "thermal_margin_low"
  defp risk_type("spacecraft_unavailable"), do: "spacecraft_unavailable"
  defp risk_type("payload_unavailable"), do: "payload_unavailable"
  defp risk_type("spacecraft_degraded_payload_unavailable"), do: "spacecraft_degraded"
  defp risk_type("activity_type_suppressed_by_resource_summary"), do: "activity_type_suppressed"

  defp risk_type("activity_type_incompatible_with_resource_summary"),
    do: "activity_type_incompatible"

  defp risk_type("antenna_unavailable"), do: "antenna_unavailable"
  defp risk_type("storage_margin_below_observe_policy"), do: "storage_overflow"
  defp risk_type("downlink_margin_below_policy"), do: "downlink_shortfall"
  defp risk_type("power_margin_below_observe_policy"), do: "power_margin_low"
  defp risk_type("power_margin_below_downlink_policy"), do: "power_margin_low"
  defp risk_type("invalid_candidate_input"), do: "invalid_resource_candidate_input"
  defp risk_type(_reason), do: nil

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
