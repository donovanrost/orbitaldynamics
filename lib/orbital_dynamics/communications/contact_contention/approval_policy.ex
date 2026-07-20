defmodule OrbitalDynamics.Communications.ContactContention.ApprovalPolicy do
  @moduledoc false

  alias OrbitalDynamics.Communications.ContactContention.{
    FeedbackContext,
    StationCalendarContext
  }

  alias OrbitalDynamics.Policy

  @command_contact_directions ~w(command uplink)
  @health_check_contact_directions ~w(health_check)

  def apply_group(group, nil), do: group

  def apply_group(group, approval_policy) do
    requirement = group_requirement(group)

    {status, requirements, matches, decision} =
      Policy.decide(
        [requirement],
        [],
        %{"id" => "contact_contention", "events" => []},
        %{},
        approval_policy
      )

    group
    |> Map.put("approval_status", status)
    |> Map.put("approval_requirements", requirements)
    |> Map.put("approval_rule_matches", matches)
    |> Map.put("policy_decision", decision)
  end

  def apply_invalid_input(row, nil), do: row

  def apply_invalid_input(row, approval_policy) do
    requirement = invalid_input_requirement(row)

    {status, requirements, matches, decision} =
      Policy.decide(
        [requirement],
        [],
        %{"id" => "contact_contention_invalid_input", "events" => []},
        %{},
        approval_policy
      )

    row
    |> Map.put("approval_status", status)
    |> Map.put("approval_requirements", requirements)
    |> Map.put("approval_rule_matches", matches)
    |> Map.put("policy_decision", decision)
  end

  def apply_recommendation(recommendation, nil), do: recommendation

  def apply_recommendation(recommendation, approval_policy) do
    requirement = recommendation_requirement(recommendation)

    {status, requirements, matches, decision} =
      Policy.decide(
        [requirement],
        [],
        %{"id" => "contact_contention_resolution", "events" => []},
        %{},
        approval_policy
      )

    recommendation
    |> Map.put("review_status", status)
    |> Map.put("approval_requirements", requirements)
    |> Map.put("approval_rule_matches", matches)
    |> Map.put("policy_decision", decision)
  end

  defp group_requirement(group) do
    %{
      "activity_id" => group["id"],
      "activity_type" => "contact_contention",
      "action" => group["required_operator_action"],
      "requirement_type" => requirement_type(group),
      "reason" => requirement_reason(group),
      "activity_context" =>
        %{
          "resource_scope" => group["resource_scope"],
          "ground_station_id" => group["ground_station_id"],
          "ground_station_ids" => group["ground_station_ids"],
          "spacecraft_id" => group["spacecraft_id"],
          "spacecraft_ids" => group["spacecraft_ids"],
          "direction" => group["direction"],
          "directions" => group["directions"],
          "required_operator_action" => group["required_operator_action"],
          "operator_action_reason" => group["operator_action_reason"],
          "contact_count" => group["contact_count"],
          "contact_ids" => group["contact_ids"],
          "duplicate_contact_ids" => group["duplicate_contact_ids"],
          "duplicate_contact_id_count" => group["duplicate_contact_id_count"],
          "duplicate_contact_candidate_count" => group["duplicate_contact_candidate_count"],
          "source_window_ids" => group["source_window_ids"],
          "scenario_ids" => group["scenario_ids"]
        }
        |> Map.merge(Map.take(group, FeedbackContext.fields()))
        |> Map.merge(Map.take(group, StationCalendarContext.fields()))
        |> compact_map()
    }
    |> compact_map()
  end

  defp invalid_input_requirement(row) do
    %{
      "activity_id" => row["id"],
      "activity_type" => "contact_contention",
      "action" => row["required_operator_action"],
      "requirement_type" => "contact_schedule_change",
      "reason" => row["operator_action_reason"],
      "activity_context" =>
        %{
          "resource_scope" => "ground_station",
          "ground_station_id" => row["ground_station_id"],
          "ground_station_ids" => row["ground_station_ids"],
          "spacecraft_id" => row["spacecraft_id"],
          "spacecraft_ids" => row["spacecraft_ids"],
          "direction" => row["direction"],
          "directions" => row["directions"],
          "required_operator_action" => row["required_operator_action"],
          "operator_action_reason" => row["operator_action_reason"],
          "contact_id" => row["contact_id"],
          "contact_ids" => row["contact_ids"],
          "contact_count" => row["contact_count"],
          "invalid_contact_input" => row["invalid_contact_input"],
          "invalid_contact_input_reason" => row["invalid_contact_input_reason"]
        }
        |> compact_map()
    }
    |> compact_map()
  end

  defp recommendation_requirement(recommendation) do
    %{
      "activity_id" => recommendation["group_id"],
      "activity_type" => "contact_contention_resolution",
      "action" => recommendation["action"],
      "requirement_type" => requirement_type(recommendation),
      "reason" => resolution_requirement_reason(recommendation),
      "activity_context" =>
        %{
          "resource_scope" => recommendation["resource_scope"],
          "ground_station_id" => recommendation["ground_station_id"],
          "ground_station_ids" => recommendation["ground_station_ids"],
          "spacecraft_id" => recommendation["spacecraft_id"],
          "spacecraft_ids" => recommendation["spacecraft_ids"],
          "direction" => recommendation["direction"],
          "directions" => recommendation["directions"],
          "required_operator_action" => recommendation["action"],
          "selected_contact_id" => recommendation["selected_contact_id"],
          "selected_priority" => recommendation["selected_priority"],
          "selected_priority_source" => recommendation["selected_priority_source"],
          "deferred_contact_ids" => recommendation["deferred_contact_ids"],
          "deferred_contact_priorities" => recommendation["deferred_contact_priorities"],
          "candidate_count" => recommendation["candidate_count"],
          "resolution_status" => recommendation["resolution_status"],
          "resolution_issue" => recommendation["resolution_issue"],
          "duplicate_contact_ids" => recommendation["duplicate_contact_ids"],
          "duplicate_contact_id_count" => recommendation["duplicate_contact_id_count"],
          "duplicate_contact_candidate_count" =>
            recommendation["duplicate_contact_candidate_count"],
          "selection_reason" => recommendation["selection_reason"],
          "resolution_selection_rule" => recommendation["resolution_selection_rule"],
          "resolution_priority_fields" => recommendation["resolution_priority_fields"],
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
          "resolution_tie_breakers" => recommendation["resolution_tie_breakers"],
          "requested_selection_rule" => recommendation["requested_selection_rule"],
          "ignored_tie_breakers" => recommendation["ignored_tie_breakers"],
          "ignored_policy_input" => recommendation["ignored_policy_input"],
          "policy_warnings" => recommendation["policy_warnings"]
        }
        |> Map.merge(Map.take(recommendation, FeedbackContext.fields()))
        |> Map.merge(Map.take(recommendation, StationCalendarContext.fields()))
        |> compact_map()
    }
    |> compact_map()
  end

  defp requirement_type(row) do
    cond do
      command_contact_contention?(row) -> "command_review"
      health_check_contact_contention?(row) -> "health_check_review"
      true -> "contact_schedule_change"
    end
  end

  defp requirement_reason(row) do
    cond do
      command_contact_contention?(row) ->
        "command contact contention requires operator review"

      health_check_contact_contention?(row) ->
        "health-check contact contention requires operator review"

      true ->
        row["operator_action_reason"]
    end
  end

  defp resolution_requirement_reason(recommendation) do
    if recommendation["resource_scope"] == "spacecraft" do
      spacecraft = Map.get(recommendation, "spacecraft_id", "spacecraft")
      "resolve #{spacecraft} spacecraft contact contention"
    else
      station = Map.get(recommendation, "ground_station_id", "station")

      cond do
        command_contact_contention?(recommendation) ->
          "resolve #{station} command contact contention"

        health_check_contact_contention?(recommendation) ->
          "resolve #{station} health-check contact contention"

        true ->
          "resolve #{station} contact contention"
      end
    end
  end

  defp command_contact_contention?(row) do
    row["direction"] in @command_contact_directions or
      row
      |> Map.get("directions", [])
      |> List.wrap()
      |> Enum.any?(&(&1 in @command_contact_directions))
  end

  defp health_check_contact_contention?(row) do
    row["direction"] in @health_check_contact_directions or row["type"] == "health_check" or
      row
      |> Map.get("directions", [])
      |> List.wrap()
      |> Enum.any?(&(&1 in @health_check_contact_directions))
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
