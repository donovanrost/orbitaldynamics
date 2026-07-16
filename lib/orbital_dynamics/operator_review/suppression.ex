defmodule OrbitalDynamics.OperatorReview.Suppression do
  @moduledoc false

  def contact_rows(candidates, source) do
    candidates
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {candidate, index} ->
      requirement =
        candidate["approval_requirements"]
        |> first_map()
        |> stringify_keys()

      rule_match =
        candidate["approval_rule_matches"]
        |> first_map()
        |> stringify_keys()

      policy_decision = stringify_keys(candidate["policy_decision"] || %{})
      policy_escalation = candidate |> matched_policy_escalation() |> stringify_keys()

      %{
        "id" => review_id(["contact_suppression", candidate["id"], index]),
        "review_type" => "contact_suppression",
        "source" => source,
        "subject_id" => candidate["id"],
        "activity_id" => candidate["id"],
        "base_candidate_id" => candidate["base_candidate_id"],
        "activity_type" => candidate["type"],
        "action" => contact_suppression_action(candidate),
        "required_operator_action" => contact_suppression_action(candidate),
        "approval_status" => candidate["approval_status"] || "operator_review_required",
        "reason" => contact_suppression_reason(candidate),
        "ground_station_id" => candidate["ground_station_id"],
        "direction" => candidate["direction"],
        "starts_at_s" => candidate["starts_at_s"],
        "ends_at_s" => candidate["ends_at_s"],
        "source_window_id" => candidate["source_window_id"],
        "contact_success" => candidate["contact_success"],
        "contact_success_factor" => candidate["contact_success_factor"],
        "contact_success_factor_source" => candidate["contact_success_factor_source"],
        "command_success" => candidate["command_success"],
        "contact_result" => provider_result_artifact_value(candidate["contact_result"]),
        "command_result" => provider_result_artifact_value(candidate["command_result"]),
        "command_success_factor" => candidate["command_success_factor"],
        "command_success_factor_source" => candidate["command_success_factor_source"],
        "station_availability" => candidate["station_availability"],
        "station_calendar_entry_id" => candidate["station_calendar_entry_id"],
        "station_calendar_directions" => candidate["station_calendar_directions"],
        "station_calendar_status" => candidate["station_calendar_status"],
        "station_calendar_overlap_count" => candidate["station_calendar_overlap_count"],
        "station_calendar_overlap_entry_ids" => candidate["station_calendar_overlap_entry_ids"],
        "station_calendar_overlap_availabilities" =>
          candidate["station_calendar_overlap_availabilities"],
        "station_calendar_entry_ambiguous" => candidate["station_calendar_entry_ambiguous"],
        "station_calendar_ambiguous_entry_count" =>
          candidate["station_calendar_ambiguous_entry_count"],
        "station_calendar_ambiguous_entry_ids" =>
          candidate["station_calendar_ambiguous_entry_ids"],
        "station_calendar_reservation_overlap_count" =>
          candidate["station_calendar_reservation_overlap_count"],
        "station_calendar_reservation_ids" => candidate["station_calendar_reservation_ids"],
        "station_calendar_reserved_by" => candidate["station_calendar_reserved_by"],
        "station_calendar_reservation_statuses" =>
          candidate["station_calendar_reservation_statuses"],
        "station_calendar_reservation_expires_at_s" =>
          candidate["station_calendar_reservation_expires_at_s"],
        "source_station_calendar_entry" => candidate["source_station_calendar_entry"],
        "source_station_calendar_overlaps" => candidate["source_station_calendar_overlaps"],
        "provider_counteroffer_id" => candidate["provider_counteroffer_id"],
        "provider_counteroffer_status" => candidate["provider_counteroffer_status"],
        "provider_counteroffer_negotiation_state" =>
          candidate["provider_counteroffer_negotiation_state"],
        "provider_counteroffer_reason_code" => candidate["provider_counteroffer_reason_code"],
        "provider_counteroffer_cost_delta" => candidate["provider_counteroffer_cost_delta"],
        "provider_counteroffer_lock_deadline_s" =>
          candidate["provider_counteroffer_lock_deadline_s"],
        "provider_counteroffer_starts_at_s" => candidate["provider_counteroffer_starts_at_s"],
        "provider_counteroffer_ends_at_s" => candidate["provider_counteroffer_ends_at_s"],
        "provider_counteroffer_start_delta_s" => candidate["provider_counteroffer_start_delta_s"],
        "provider_counteroffer_end_delta_s" => candidate["provider_counteroffer_end_delta_s"],
        "provider_counteroffer_duration_delta_s" =>
          candidate["provider_counteroffer_duration_delta_s"],
        "station_contention_status" => candidate["station_contention_status"],
        "station_reservation_id" => candidate["station_reservation_id"],
        "station_reservation_expires_at_s" => candidate["station_reservation_expires_at_s"],
        "station_reserved_by" => candidate["station_reserved_by"],
        "station_reservation_status" => candidate["station_reservation_status"],
        "station_reservation_match_status" => candidate["station_reservation_match_status"],
        "duplicate_suppressed_candidate_id_collision" =>
          candidate["duplicate_suppressed_candidate_id_collision"],
        "duplicate_suppressed_candidate_index" =>
          candidate["duplicate_suppressed_candidate_index"],
        "duplicate_suppressed_candidate_count" =>
          candidate["duplicate_suppressed_candidate_count"],
        "invalid_contact_input" => candidate["invalid_contact_input"],
        "invalid_contact_input_reason" => candidate["invalid_contact_input_reason"],
        "review_status" => candidate["review_status"],
        "source_contact_candidate" => candidate["source_contact_candidate"],
        "requirement_type" => requirement["requirement_type"],
        "required_authority" =>
          requirement["required_authority"] || policy_escalation["required_authority"],
        "policy_bundle_id" =>
          requirement["policy_bundle_id"] || policy_decision["policy_bundle_id"],
        "rule_id" =>
          requirement["rule_id"] || rule_match["rule_id"] || policy_escalation["rule_id"],
        "escalation_level" =>
          rule_match["escalation_level"] || policy_escalation["escalation_level"],
        "escalation_queue" =>
          rule_match["escalation_queue"] || policy_escalation["escalation_queue"],
        "escalation_role" =>
          rule_match["escalation_role"] || policy_escalation["escalation_role"],
        "sla_s" => rule_match["sla_s"] || policy_escalation["sla_s"],
        "approval_requirements" => candidate["approval_requirements"],
        "approval_rule_matches" => candidate["approval_rule_matches"],
        "source_policy_decision" => candidate["policy_decision"],
        "source_policy_escalation" => non_empty_map(policy_escalation),
        "source_contact_suppression" => candidate
      }
      |> compact_map()
    end)
  end

  defp contact_suppression_action(%{"required_operator_action" => action}) when is_binary(action),
    do: action

  defp contact_suppression_action(candidate) do
    if downlink_candidate?(candidate),
      do: "review_suppressed_contact",
      else: "review_suppressed_candidate"
  end

  defp contact_suppression_reason(%{
         "suppressed_reason" => "invalid_contact_input",
         "invalid_contact_input_reason" => reason
       })
       when is_binary(reason),
       do: "contact filter invalid input: #{reason}"

  defp contact_suppression_reason(%{"suppressed_reason" => reason}) when is_binary(reason),
    do: "contact filter suppressed candidate: #{reason}"

  defp contact_suppression_reason(_candidate), do: "contact filter suppressed candidate"

  def resource_rows(candidates),
    do:
      resource_rows(
        candidates,
        "campaign_plan.resource_filter_report.suppressed_candidates"
      )

  def resource_rows(candidates, source) do
    candidates
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {candidate, index} ->
      requirement =
        candidate["approval_requirements"]
        |> first_map()
        |> stringify_keys()

      rule_match =
        candidate["approval_rule_matches"]
        |> first_map()
        |> stringify_keys()

      policy_decision = stringify_keys(candidate["policy_decision"] || %{})
      policy_escalation = candidate |> matched_policy_escalation() |> stringify_keys()

      %{
        "id" => review_id(["resource_suppression", candidate["id"], index]),
        "review_type" => "resource_suppression",
        "source" => source,
        "subject_id" => candidate["id"],
        "activity_id" => candidate["id"],
        "base_candidate_id" => candidate["base_candidate_id"],
        "activity_type" => candidate["type"],
        "action" => resource_suppression_action(candidate),
        "required_operator_action" => resource_suppression_action(candidate),
        "approval_status" => candidate["approval_status"] || "operator_review_required",
        "suppressed_reason" => candidate["suppressed_reason"],
        "reason" => resource_suppression_reason(candidate),
        "scenario_id" => candidate["scenario_id"],
        "spacecraft_id" => candidate["spacecraft_id"],
        "target_id" => candidate["target_id"],
        "ground_station_id" => candidate["ground_station_id"],
        "direction" => candidate["direction"],
        "starts_at_s" => candidate["starts_at_s"],
        "ends_at_s" => candidate["ends_at_s"],
        "source_window_id" => candidate["source_window_id"],
        "contact_success" => candidate["contact_success"],
        "contact_success_factor" => candidate["contact_success_factor"],
        "contact_success_factor_source" => candidate["contact_success_factor_source"],
        "command_success" => candidate["command_success"],
        "contact_result" => provider_result_artifact_value(candidate["contact_result"]),
        "command_result" => provider_result_artifact_value(candidate["command_result"]),
        "command_success_factor" => candidate["command_success_factor"],
        "command_success_factor_source" => candidate["command_success_factor_source"],
        "station_availability" => candidate["station_availability"],
        "station_calendar_entry_id" => candidate["station_calendar_entry_id"],
        "station_calendar_directions" => candidate["station_calendar_directions"],
        "station_calendar_status" => candidate["station_calendar_status"],
        "station_calendar_overlap_count" => candidate["station_calendar_overlap_count"],
        "station_calendar_overlap_entry_ids" => candidate["station_calendar_overlap_entry_ids"],
        "station_calendar_overlap_availabilities" =>
          candidate["station_calendar_overlap_availabilities"],
        "station_calendar_entry_ambiguous" => candidate["station_calendar_entry_ambiguous"],
        "station_calendar_ambiguous_entry_count" =>
          candidate["station_calendar_ambiguous_entry_count"],
        "station_calendar_ambiguous_entry_ids" =>
          candidate["station_calendar_ambiguous_entry_ids"],
        "station_calendar_reservation_overlap_count" =>
          candidate["station_calendar_reservation_overlap_count"],
        "station_calendar_reservation_ids" => candidate["station_calendar_reservation_ids"],
        "station_calendar_reserved_by" => candidate["station_calendar_reserved_by"],
        "station_calendar_reservation_statuses" =>
          candidate["station_calendar_reservation_statuses"],
        "station_calendar_reservation_expires_at_s" =>
          candidate["station_calendar_reservation_expires_at_s"],
        "source_station_calendar_entry" => candidate["source_station_calendar_entry"],
        "source_station_calendar_overlaps" => candidate["source_station_calendar_overlaps"],
        "station_contention_status" => candidate["station_contention_status"],
        "station_reservation_id" => candidate["station_reservation_id"],
        "station_reservation_expires_at_s" => candidate["station_reservation_expires_at_s"],
        "station_reserved_by" => candidate["station_reserved_by"],
        "station_reservation_status" => candidate["station_reservation_status"],
        "station_reservation_match_status" => candidate["station_reservation_match_status"],
        "resource_source_quality" => candidate["resource_source_quality"],
        "resource_trust_boundary" => candidate["resource_trust_boundary"],
        "resource_trust_boundary_status" => candidate["resource_trust_boundary_status"],
        "resource_provenance" => candidate["resource_provenance"],
        "resource_blocking_dimension" => candidate["resource_blocking_dimension"],
        "fuel_margin" => candidate["fuel_margin"],
        "thermal_margin_c" => candidate["thermal_margin_c"],
        "power_margin" => candidate["power_margin"],
        "storage_margin" => candidate["storage_margin"],
        "downlink_margin" => candidate["downlink_margin"],
        "battery_capacity_wh" => candidate["battery_capacity_wh"],
        "battery_energy_used_wh" => candidate["battery_energy_used_wh"],
        "battery_energy_generated_wh" => candidate["battery_energy_generated_wh"],
        "battery_state_of_charge" => candidate["battery_state_of_charge"],
        "spacecraft_available" => candidate["spacecraft_available"],
        "payload_available" => candidate["payload_available"],
        "antenna_available" => candidate["antenna_available"],
        "degraded" => candidate["degraded"],
        "mode" => candidate["mode"],
        "incompatible_activity_types" => candidate["incompatible_activity_types"],
        "suppressed_activity_types" => candidate["suppressed_activity_types"],
        "duplicate_suppressed_candidate_id_collision" =>
          candidate["duplicate_suppressed_candidate_id_collision"],
        "duplicate_suppressed_candidate_index" =>
          candidate["duplicate_suppressed_candidate_index"],
        "duplicate_suppressed_candidate_count" =>
          candidate["duplicate_suppressed_candidate_count"],
        "invalid_candidate_input" => candidate["invalid_candidate_input"],
        "invalid_candidate_input_reason" => candidate["invalid_candidate_input_reason"],
        "invalid_resource_summary_input" => candidate["invalid_resource_summary_input"],
        "invalid_resource_summary_input_reason" =>
          candidate["invalid_resource_summary_input_reason"],
        "source_candidate" => candidate["source_candidate"],
        "source_resource_summary" => candidate["source_resource_summary"],
        "requirement_type" => requirement["requirement_type"],
        "required_authority" =>
          requirement["required_authority"] || policy_escalation["required_authority"],
        "policy_bundle_id" =>
          requirement["policy_bundle_id"] || policy_decision["policy_bundle_id"],
        "rule_id" =>
          requirement["rule_id"] || rule_match["rule_id"] || policy_escalation["rule_id"],
        "escalation_level" =>
          rule_match["escalation_level"] || policy_escalation["escalation_level"],
        "escalation_queue" =>
          rule_match["escalation_queue"] || policy_escalation["escalation_queue"],
        "escalation_role" =>
          rule_match["escalation_role"] || policy_escalation["escalation_role"],
        "sla_s" => rule_match["sla_s"] || policy_escalation["sla_s"],
        "approval_requirements" => candidate["approval_requirements"],
        "approval_rule_matches" => candidate["approval_rule_matches"],
        "source_policy_decision" => candidate["policy_decision"],
        "source_policy_escalation" => non_empty_map(policy_escalation),
        "source_resource_suppression" => candidate
      }
      |> compact_map()
    end)
  end

  def invalid_resource_summary_rows(
        rows,
        source \\ "resource_filter_report.invalid_resource_summary_inputs"
      ) do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      resource_summary_id = row["resource_summary_id"] || "invalid_resource_summary:#{index}"
      requirement = row["approval_requirements"] |> first_map() |> stringify_keys()
      rule_match = row["approval_rule_matches"] |> first_map() |> stringify_keys()
      policy_decision = stringify_keys(row["policy_decision"] || %{})
      policy_escalation = row |> matched_policy_escalation() |> stringify_keys()

      %{
        "id" =>
          review_id(["resource_suppression", "invalid_resource_summary", resource_summary_id]),
        "review_type" => "resource_suppression",
        "source" => source,
        "subject_id" => resource_summary_id,
        "spacecraft_id" => row["spacecraft_id"],
        "action" => "review_invalid_resource_filter_summary",
        "required_operator_action" => "review_invalid_resource_filter_summary",
        "approval_status" => row["approval_status"] || "operator_review_required",
        "review_status" => row["review_status"] || "operator_review_required",
        "suppressed_reason" => "invalid_resource_summary_input",
        "reason" =>
          "review invalid resource filter summary #{resource_summary_id}: #{row["invalid_resource_summary_input_reason"]}",
        "resource_blocking_dimension" => "spacecraft_health",
        "invalid_resource_summary_input" => true,
        "invalid_resource_summary_input_reason" => row["invalid_resource_summary_input_reason"],
        "requirement_type" => requirement["requirement_type"],
        "required_authority" =>
          requirement["required_authority"] || policy_escalation["required_authority"],
        "policy_bundle_id" =>
          requirement["policy_bundle_id"] || policy_decision["policy_bundle_id"],
        "rule_id" =>
          requirement["rule_id"] || rule_match["rule_id"] || policy_escalation["rule_id"],
        "escalation_level" =>
          rule_match["escalation_level"] || policy_escalation["escalation_level"],
        "escalation_queue" =>
          rule_match["escalation_queue"] || policy_escalation["escalation_queue"],
        "escalation_role" =>
          rule_match["escalation_role"] || policy_escalation["escalation_role"],
        "sla_s" => rule_match["sla_s"] || policy_escalation["sla_s"],
        "approval_requirements" => row["approval_requirements"],
        "approval_rule_matches" => row["approval_rule_matches"],
        "source_policy_decision" => row["policy_decision"],
        "source_policy_escalation" => non_empty_map(policy_escalation),
        "source_resource_summary" => row["source_resource_summary"],
        "source_resource_suppression" => row
      }
      |> compact_map()
    end)
  end

  defp resource_suppression_action(candidate) do
    cond do
      resource_contact_candidate?(candidate) -> "review_suppressed_contact"
      candidate["type"] == "observe" -> "review_suppressed_observation"
      true -> "review_suppressed_candidate"
    end
  end

  defp resource_contact_candidate?(%{"type" => type})
       when type in ["downlink", "tracking", "uplink", "command", "health_check"],
       do: true

  defp resource_contact_candidate?(%{"type" => "planned_contact", "direction" => direction})
       when direction in ["downlink", "tracking", "uplink", "command", "health_check"],
       do: true

  defp resource_contact_candidate?(%{"direction" => direction, "ground_station_id" => station_id})
       when direction in ["downlink", "tracking", "uplink", "command", "health_check"] and
              not is_nil(station_id),
       do: true

  defp resource_contact_candidate?(candidate), do: downlink_candidate?(candidate)

  defp downlink_candidate?(%{"type" => "downlink"}), do: true
  defp downlink_candidate?(%{"type" => "planned_contact", "direction" => "downlink"}), do: true
  defp downlink_candidate?(%{"type" => "tracking"}), do: true
  defp downlink_candidate?(%{"type" => "planned_contact", "direction" => "tracking"}), do: true

  defp downlink_candidate?(%{"direction" => "downlink", "ground_station_id" => station_id})
       when not is_nil(station_id),
       do: true

  defp downlink_candidate?(%{"direction" => "tracking", "ground_station_id" => station_id})
       when not is_nil(station_id),
       do: true

  defp downlink_candidate?(_candidate), do: false

  defp resource_suppression_reason(%{"suppressed_reason" => reason}) when is_binary(reason),
    do: "resource filter suppressed candidate: #{reason}"

  defp resource_suppression_reason(_candidate), do: "resource filter suppressed candidate"

  defp matched_policy_escalation(row) do
    preferred_rule_id =
      row
      |> preferred_approval_rule_match()
      |> Map.get("rule_id")

    rule_ids =
      row
      |> Map.get("approval_rule_matches", [])
      |> List.wrap()
      |> Enum.map(&Map.get(&1, "rule_id"))
      |> Enum.reject(&is_nil/1)

    escalations =
      row
      |> get_in(["policy_decision", "escalations"])
      |> List.wrap()
      |> Enum.filter(&is_map/1)

    escalation =
      Enum.find(escalations, &(Map.get(&1, "rule_id") == preferred_rule_id)) ||
        Enum.find(escalations, &(Map.get(&1, "rule_id") in rule_ids)) ||
        List.first(escalations) ||
        row
        |> Map.get("approval_rule_matches", [])
        |> List.wrap()
        |> Enum.find(&policy_escalation_context?/1)

    escalation || %{}
  end

  defp preferred_approval_rule_match(%{} = row) do
    preferred_classification =
      row["approval_status"] || get_in(row, ["policy_decision", "classification"])

    preferred_approval_rule_match(row["approval_rule_matches"], preferred_classification)
  end

  defp preferred_approval_rule_match(rule_matches, preferred_classification)
       when is_list(rule_matches) do
    rule_matches =
      rule_matches
      |> Enum.filter(&is_map/1)
      |> Enum.map(&stringify_keys/1)

    Enum.find(rule_matches, &(&1["classification"] == preferred_classification)) ||
      List.first(rule_matches) ||
      %{}
  end

  defp preferred_approval_rule_match(_rule_matches, _preferred_classification), do: %{}

  defp policy_escalation_context?(%{} = row) do
    Enum.any?(
      ["escalation_level", "escalation_queue", "escalation_role", "required_authority", "sla_s"],
      &Map.has_key?(row, &1)
    )
  end

  defp policy_escalation_context?(_row), do: false

  defp provider_result_values(result) when is_binary(result) do
    result
    |> String.trim()
    |> case do
      "" -> []
      value -> [value]
    end
  end

  defp provider_result_values(values) when is_list(values) do
    values
    |> Enum.flat_map(&provider_result_values/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  defp provider_result_values(%{} = result) do
    Enum.flat_map(provider_result_map_value_keys(), fn key ->
      result
      |> Map.get(key)
      |> provider_result_values()
    end)
  end

  defp provider_result_values(nil), do: []

  defp provider_result_values(result) when is_atom(result) do
    result
    |> Atom.to_string()
    |> provider_result_values()
  end

  defp provider_result_values(result)
       when is_integer(result) or is_float(result) or is_boolean(result),
       do: [encode_value(result)]

  defp provider_result_values(_result), do: []

  defp provider_result_artifact_value(nil), do: nil

  defp provider_result_artifact_value(result) when is_binary(result) do
    case String.trim(result) do
      "" -> nil
      _value -> result
    end
  end

  defp provider_result_artifact_value(results) when is_list(results) do
    case provider_result_values(results) do
      [] -> nil
      values -> Enum.join(values, ",")
    end
  end

  defp provider_result_artifact_value(%{} = result) do
    case provider_result_values(result) do
      [] -> nil
      values -> Enum.join(values, ",")
    end
  end

  defp provider_result_artifact_value(result) when is_integer(result),
    do: Integer.to_string(result)

  defp provider_result_artifact_value(result) when is_float(result), do: Float.to_string(result)
  defp provider_result_artifact_value(result) when is_boolean(result), do: Atom.to_string(result)

  defp provider_result_artifact_value(result) when is_atom(result) do
    result
    |> Atom.to_string()
    |> provider_result_artifact_value()
  end

  defp provider_result_artifact_value(_result), do: nil

  defp provider_result_map_value_keys do
    ~w(result results outcome outcomes status state disposition provider_result provider_results provider_outcome provider_outcomes provider_status provider_state provider_code code reason reasons message messages error errors details metadata provider diagnostics)
  end

  defp first_map(values) when is_list(values), do: Enum.find(values, %{}, &is_map/1)
  defp first_map(_values), do: %{}

  defp non_empty_map(%{} = map) when map_size(map) > 0, do: map
  defp non_empty_map(_map), do: nil

  defp review_id(parts) do
    parts
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&encode_value/1)
    |> Enum.join(":")
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(nil), do: nil
  defp encode_value(:null), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
