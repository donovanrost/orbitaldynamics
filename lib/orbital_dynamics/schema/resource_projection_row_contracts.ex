defmodule OrbitalDynamics.Schema.ResourceProjectionRowContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.PrimitiveValidation

  import OrbitalDynamics.Schema.CollectionValidation,
    only: [validate_optional_rows: 4, validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_number: 4,
      expect_optional_non_negative_integer: 4,
      expect_optional_non_negative_number: 4,
      expect_optional_number: 4,
      expect_optional_probability: 4,
      expect_optional_type: 5,
      require_fields: 4,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_optional_stable_id_list: 4, validate_stable_ids: 4]

  def validate(
        issues,
        path,
        row,
        approval_requirement_validator,
        policy_rule_match_validator,
        source_window_validator,
        nested_id_match_validator,
        flow_row_validator
      )
      when is_function(approval_requirement_validator, 3) and
             is_function(policy_rule_match_validator, 3) and
             is_function(source_window_validator, 4) and
             is_function(nested_id_match_validator, 7) and
             is_function(flow_row_validator, 3) do
    issues
    |> require_fields(path, row, [
      "spacecraft_id",
      "activity_count",
      "observation_count",
      "downlink_count",
      "estimated_storage_produced_mb",
      "estimated_downlink_mb"
    ])
    |> validate_stable_ids(path, row, ["spacecraft_id"])
    |> expect_non_negative_integer(path, row, "activity_count")
    |> expect_optional_non_negative_integer(path, row, "effective_activity_count")
    |> expect_non_negative_integer(path, row, "observation_count")
    |> expect_non_negative_integer(path, row, "downlink_count")
    |> expect_number(path, row, "estimated_storage_produced_mb")
    |> expect_number(path, row, "estimated_downlink_mb")
    |> expect_optional_number(path, row, "starting_storage_used_mb")
    |> expect_optional_number(path, row, "projected_storage_used_mb")
    |> expect_optional_number(path, row, "storage_capacity_mb")
    |> expect_optional_number(path, row, "starting_storage_margin")
    |> expect_optional_number(path, row, "projected_storage_margin")
    |> expect_optional_number(path, row, "projected_storage_remaining_mb")
    |> expect_optional_non_negative_number(path, row, "projected_storage_overflow_mb")
    |> expect_optional_number(path, row, "downlink_capacity_mb")
    |> expect_optional_number(path, row, "starting_downlink_margin")
    |> expect_optional_number(path, row, "projected_downlink_margin")
    |> expect_optional_number(path, row, "projected_downlink_remaining_mb")
    |> expect_optional_non_negative_number(
      path,
      row,
      "projected_downlink_shortfall_mb"
    )
    |> expect_optional_non_negative_number(path, row, "storage_limited_downlinked_mb")
    |> expect_optional_non_negative_number(path, row, "unused_downlink_capacity_mb")
    |> expect_optional_type(path, row, "resource_source_quality", :binary)
    |> expect_optional_type(path, row, "resource_trust_boundary_status", :binary)
    |> expect_optional_type(path, row, "resource_pressure_status", :binary)
    |> expect_optional_type(path, row, "resource_pressure_types", :list)
    |> validate_string_list_items(path, row, "resource_pressure_types")
    |> expect_optional_type(path, row, "resource_provenance", :map)
    |> expect_optional_type(path, row, "payload_available", :boolean)
    |> expect_optional_type(path, row, "antenna_available", :boolean)
    |> expect_optional_type(path, row, "mode", :binary)
    |> expect_optional_type(path, row, "incompatible_activity_types", :list)
    |> validate_string_list_items(path, row, "incompatible_activity_types")
    |> expect_optional_type(path, row, "suppressed_activity_types", :list)
    |> validate_string_list_items(path, row, "suppressed_activity_types")
    |> expect_optional_number(path, row, "fuel_margin")
    |> expect_optional_number(path, row, "power_margin")
    |> expect_optional_probability(path, row, "projected_power_margin")
    |> expect_optional_non_negative_number(path, row, "battery_capacity_wh")
    |> expect_optional_non_negative_number(path, row, "battery_energy_used_wh")
    |> expect_optional_non_negative_number(
      path,
      row,
      "starting_battery_energy_used_wh"
    )
    |> expect_optional_non_negative_number(
      path,
      row,
      "projected_battery_energy_used_wh"
    )
    |> expect_optional_non_negative_number(path, row, "projected_battery_overuse_wh")
    |> expect_optional_probability(path, row, "battery_state_of_charge")
    |> expect_optional_probability(path, row, "projected_battery_state_of_charge")
    |> expect_optional_number(path, row, "thermal_margin_c")
    |> expect_optional_type(path, row, "warnings", :list)
    |> expect_optional_type(path, row, "approval_requirements", :list)
    |> validate_optional_rows(
      path <> ".approval_requirements",
      Map.get(row, "approval_requirements"),
      fn acc, row_path, requirement ->
        approval_requirement_validator.(acc, row_path, requirement)
      end
    )
    |> expect_optional_type(path, row, "approval_rule_matches", :list)
    |> validate_optional_rows(
      path <> ".approval_rule_matches",
      Map.get(row, "approval_rule_matches"),
      fn acc, row_path, match ->
        policy_rule_match_validator.(acc, row_path, match)
      end
    )
    |> expect_optional_non_negative_integer(path, row, "ignored_activity_count")
    |> expect_optional_type(path, row, "ignored_activity_ids", :list)
    |> validate_optional_stable_id_list(path, row, "ignored_activity_ids")
    |> validate_stable_ids(path, row, [
      "first_resource_pressure_activity_id",
      "first_resource_pressure_ground_station_id",
      "first_resource_pressure_station_calendar_entry_id",
      "first_resource_pressure_station_calendar_provider_id",
      "first_resource_pressure_station_calendar_provider_entry_id",
      "first_resource_pressure_source_window_id",
      "source_window_id"
    ])
    |> expect_optional_type(
      path,
      row,
      "first_resource_pressure_source_window_type",
      :binary
    )
    |> source_window_validator.(
      path,
      row,
      "first_resource_pressure_source_window"
    )
    |> expect_optional_type(path, row, "source_window_type", :binary)
    |> source_window_validator.(path, row, "source_window")
    |> nested_id_match_validator.(
      path,
      row,
      "first_resource_pressure_source_window",
      "id",
      "first_resource_pressure_source_window_id",
      "must match first_resource_pressure_source_window_id"
    )
    |> nested_id_match_validator.(
      path,
      row,
      "source_window",
      "id",
      "source_window_id",
      "must match source_window_id"
    )
    |> expect_optional_type(
      path,
      row,
      "first_resource_pressure_station_calendar_directions",
      :list
    )
    |> validate_string_list_items(
      path,
      row,
      "first_resource_pressure_station_calendar_directions"
    )
    |> expect_optional_probability(
      path,
      row,
      "first_resource_pressure_capacity_fraction"
    )
    |> expect_optional_type(path, row, "activity_resource_flow", :list)
    |> validate_rows(
      path <> ".activity_resource_flow",
      Map.get(row, "activity_resource_flow", []),
      fn acc, row_path, flow_row ->
        flow_row_validator.(acc, row_path, flow_row)
      end
    )
    |> validate_flow_budget_spacecraft_binding(path, row)
    |> validate_counts(path, row)
  end

  defp validate_flow_budget_spacecraft_binding(issues, path, row) do
    flows =
      case Map.get(row, "activity_resource_flow") do
        values when is_list(values) -> values
        _value -> []
      end

    flows
    |> Enum.with_index()
    |> Enum.reduce(issues, fn
      {%{"downlink_link_budget" => %{} = budget}, index}, acc ->
        if get_in(budget, ["contact_binding", "spacecraft_id"]) == row["spacecraft_id"] do
          acc
        else
          [
            PrimitiveValidation.error(
              "#{path}.activity_resource_flow[#{index}].downlink_link_budget.contact_binding.spacecraft_id",
              "must match enclosing projected resource spacecraft_id"
            )
            | acc
          ]
        end

      {_flow, _index}, acc ->
        acc
    end)
  end

  defp validate_counts(issues, path, row) do
    flow_rows =
      case Map.fetch(row, "activity_resource_flow") do
        {:ok, flow} when is_list(flow) -> Enum.filter(flow, &is_map/1)
        _flow -> nil
      end

    flow_ignored_ids =
      if is_list(flow_rows) do
        flow_rows
        |> Enum.filter(&(Map.get(&1, "resource_effect_status") == "ignored"))
        |> Enum.map(&Map.get(&1, "activity_id"))
      end

    projected_flow_rows =
      if is_list(flow_rows) do
        Enum.reject(flow_rows, &(Map.get(&1, "resource_effect_status") == "ignored"))
      end

    issues
    |> expect_field_equals(
      path,
      row,
      "activity_count",
      if(is_list(flow_rows), do: length(flow_rows), else: nil),
      "must equal activity_resource_flow row count"
    )
    |> expect_field_equals(
      path,
      row,
      "effective_activity_count",
      if(is_list(projected_flow_rows), do: length(projected_flow_rows), else: nil),
      "must equal projected activity_resource_flow row count"
    )
    |> expect_field_equals(
      path,
      row,
      "observation_count",
      if(is_list(projected_flow_rows),
        do: Enum.count(projected_flow_rows, &(Map.get(&1, "activity_type") == "observe")),
        else: nil
      ),
      "must equal projected observe flow row count"
    )
    |> expect_field_equals(
      path,
      row,
      "downlink_count",
      if(is_list(projected_flow_rows),
        do: Enum.count(projected_flow_rows, &resource_projection_downlink_flow_row?/1),
        else: nil
      ),
      "must equal projected downlink flow row count"
    )
    |> expect_field_equals(
      path,
      row,
      "ignored_activity_count",
      if(is_list(flow_ignored_ids), do: length(flow_ignored_ids), else: nil)
    )
    |> expect_field_equals(
      path,
      row,
      "ignored_activity_ids",
      flow_ignored_ids,
      "must match ignored activity flow row IDs"
    )
  end

  defp resource_projection_downlink_flow_row?(%{"activity_type" => "downlink"}), do: true

  defp resource_projection_downlink_flow_row?(%{
         "activity_type" => "planned_contact",
         "direction" => "downlink"
       }),
       do: true

  defp resource_projection_downlink_flow_row?(%{
         "direction" => "downlink",
         "ground_station_id" => station_id
       })
       when not is_nil(station_id),
       do: true

  defp resource_projection_downlink_flow_row?(_row), do: false

  defp expect_field_equals(issues, path, map, field, expected) do
    PrimitiveValidation.expect_field_equals(
      issues,
      path,
      map,
      field,
      expected,
      "must equal #{expected}"
    )
  end
end
