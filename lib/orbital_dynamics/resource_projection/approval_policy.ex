defmodule OrbitalDynamics.ResourceProjection.ApprovalPolicy do
  @moduledoc false

  alias OrbitalDynamics.Policy
  alias OrbitalDynamics.ResourceProjection.PressureRisks

  def apply_to_rows(rows, nil), do: rows

  def apply_to_rows(rows, approval_policy) do
    Enum.map(rows, fn row ->
      risks = PressureRisks.build(row)

      if risks == [] do
        row
      else
        requirements = approval_requirements(row, risks)

        {status, requirements, rule_matches, decision} =
          Policy.decide(
            requirements,
            risks,
            %{"id" => "resource_projection", "events" => []},
            %{},
            approval_policy
          )

        row
        |> Map.put("approval_status", status)
        |> Map.put("approval_requirements", requirements)
        |> Map.put("approval_rule_matches", rule_matches)
        |> Map.put("policy_decision", decision)
      end
    end)
  end

  def apply_to_invalid_activity(row, nil), do: row

  def apply_to_invalid_activity(row, approval_policy) do
    requirement = invalid_activity_requirement(row)

    {status, requirements, rule_matches, decision} =
      Policy.decide(
        [requirement],
        [],
        %{"id" => "resource_projection_invalid_activity", "events" => []},
        %{},
        approval_policy
      )

    row
    |> Map.put("approval_status", status)
    |> Map.put("approval_requirements", requirements)
    |> Map.put("approval_rule_matches", rule_matches)
    |> Map.put("policy_decision", decision)
  end

  def apply_to_invalid_summary(row, nil), do: row

  def apply_to_invalid_summary(row, approval_policy) do
    requirement = invalid_summary_requirement(row)

    {status, requirements, rule_matches, decision} =
      Policy.decide(
        [requirement],
        [],
        %{"id" => "resource_projection_invalid_summary", "events" => []},
        %{},
        approval_policy
      )

    row
    |> Map.put("approval_status", status)
    |> Map.put("approval_requirements", requirements)
    |> Map.put("approval_rule_matches", rule_matches)
    |> Map.put("policy_decision", decision)
  end

  defp invalid_activity_requirement(row) do
    %{
      "activity_id" => row["activity_id"],
      "activity_type" => "resource_projection_invalid_activity",
      "action" => "review_invalid_resource_projection_input",
      "requirement_type" => "operator_review",
      "reason" =>
        "resource projection activity input requires review: #{row["invalid_activity_input_reason"]}",
      "activity_context" =>
        %{
          "activity_ids" => row["activity_ids"],
          "scenario_id" => row["scenario_id"],
          "spacecraft_id" => row["spacecraft_id"],
          "source_window_id" => row["source_window_id"],
          "source_window_type" => row["source_window_type"],
          "source_window" => row["source_window"],
          "ground_station_id" => row["ground_station_id"],
          "target_id" => row["target_id"],
          "starts_at_s" => row["starts_at_s"],
          "ends_at_s" => row["ends_at_s"],
          "required_operator_action" => row["required_operator_action"],
          "invalid_activity_input" => row["invalid_activity_input"],
          "invalid_activity_input_reason" => row["invalid_activity_input_reason"],
          "source_activity" => row["source_activity"]
        }
        |> compact_map()
    }
    |> compact_map()
  end

  defp invalid_summary_requirement(row) do
    %{
      "activity_id" => row["id"],
      "activity_type" => "resource_projection_invalid_summary",
      "action" => "review_invalid_resource_projection_summary",
      "requirement_type" => "operator_review",
      "reason" =>
        "resource projection summary input requires review: #{row["invalid_resource_summary_input_reason"]}",
      "activity_context" =>
        %{
          "resource_summary_id" => row["resource_summary_id"],
          "spacecraft_id" => row["spacecraft_id"],
          "required_operator_action" => row["required_operator_action"],
          "invalid_resource_summary_input" => row["invalid_resource_summary_input"],
          "invalid_resource_summary_input_reason" => row["invalid_resource_summary_input_reason"],
          "source_resource_summary" => row["source_resource_summary"]
        }
        |> compact_map()
    }
    |> compact_map()
  end

  defp approval_requirements(row, risks) do
    risks
    |> Enum.map(fn risk ->
      spacecraft_id = row["spacecraft_id"] || "unscoped_resource_summary"
      risk_type = risk["type"]

      %{
        "schema_contract" => "approval_requirement.v1",
        "id" => "approval:resource_projection:#{spacecraft_id}:#{risk_type}",
        "activity_id" => "resource_projection:#{spacecraft_id}",
        "activity_type" => "resource_projection",
        "action" => "review_resource_projection",
        "requirement_type" => "operator_review",
        "reason" => risk["reason"],
        "activity_context" =>
          %{
            "spacecraft_id" => spacecraft_id,
            "risk_type" => risk_type,
            "risk_reason" => risk["reason"],
            "severity" => risk["severity"],
            "value" => risk["value"],
            "projected_storage_overflow_mb" => row["projected_storage_overflow_mb"],
            "projected_downlink_shortfall_mb" => row["projected_downlink_shortfall_mb"],
            "projected_battery_overuse_wh" => row["projected_battery_overuse_wh"],
            "projected_battery_state_of_charge" => row["projected_battery_state_of_charge"],
            "projected_power_margin" => row["projected_power_margin"],
            "thermal_margin_c" => row["thermal_margin_c"],
            "resource_pressure_status" => row["resource_pressure_status"],
            "resource_pressure_types" => row["resource_pressure_types"],
            "projected_storage_margin" => row["projected_storage_margin"],
            "projected_downlink_margin" => row["projected_downlink_margin"],
            "spacecraft_available" => row["spacecraft_available"],
            "mode" => row["mode"],
            "incompatible_activity_types" => row["incompatible_activity_types"],
            "suppressed_activity_types" => row["suppressed_activity_types"],
            "resource_source_quality" => row["resource_source_quality"],
            "resource_trust_boundary" => row["resource_trust_boundary"],
            "resource_trust_boundary_status" => row["resource_trust_boundary_status"],
            "resource_provenance" => row["resource_provenance"],
            "first_resource_pressure_activity_id" => row["first_resource_pressure_activity_id"],
            "first_resource_pressure_activity_type" =>
              row["first_resource_pressure_activity_type"],
            "first_resource_pressure_kind" => row["first_resource_pressure_kind"],
            "first_resource_pressure_starts_at_s" => row["first_resource_pressure_starts_at_s"],
            "first_resource_pressure_direction" => row["first_resource_pressure_direction"],
            "direction" => row["first_resource_pressure_direction"],
            "first_resource_pressure_ground_station_id" =>
              row["first_resource_pressure_ground_station_id"],
            "ground_station_id" => row["first_resource_pressure_ground_station_id"],
            "first_resource_pressure_station_calendar_entry_id" =>
              row["first_resource_pressure_station_calendar_entry_id"],
            "station_calendar_entry_id" =>
              row["first_resource_pressure_station_calendar_entry_id"],
            "first_resource_pressure_station_calendar_provider_id" =>
              row["first_resource_pressure_station_calendar_provider_id"],
            "station_calendar_provider_id" =>
              row["first_resource_pressure_station_calendar_provider_id"],
            "first_resource_pressure_station_calendar_provider_entry_id" =>
              row["first_resource_pressure_station_calendar_provider_entry_id"],
            "station_calendar_provider_entry_id" =>
              row["first_resource_pressure_station_calendar_provider_entry_id"],
            "first_resource_pressure_station_calendar_directions" =>
              row["first_resource_pressure_station_calendar_directions"],
            "station_calendar_directions" =>
              row["first_resource_pressure_station_calendar_directions"],
            "first_resource_pressure_capacity_fraction" =>
              row["first_resource_pressure_capacity_fraction"],
            "capacity_fraction" => row["first_resource_pressure_capacity_fraction"],
            "first_resource_pressure_source_window_id" =>
              row["first_resource_pressure_source_window_id"],
            "source_window_id" => row["first_resource_pressure_source_window_id"],
            "first_resource_pressure_source_window_type" =>
              row["first_resource_pressure_source_window_type"],
            "source_window_type" => row["first_resource_pressure_source_window_type"],
            "first_resource_pressure_source_window" =>
              row["first_resource_pressure_source_window"],
            "source_window" => row["first_resource_pressure_source_window"]
          }
          |> compact_map()
      }
      |> compact_map()
    end)
    |> Enum.sort_by(&{&1["activity_id"], &1["id"]})
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
