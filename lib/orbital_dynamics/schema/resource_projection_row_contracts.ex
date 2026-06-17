defmodule OrbitalDynamics.Schema.ResourceProjectionRowContracts do
  @moduledoc false

  def validate(issues, path, row, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, row, [
      "spacecraft_id",
      "activity_count",
      "observation_count",
      "downlink_count",
      "estimated_storage_produced_mb",
      "estimated_downlink_mb"
    ])
    |> validate_stable_ids(callbacks, path, row, ["spacecraft_id"])
    |> expect_non_negative_integer(callbacks, path, row, "activity_count")
    |> expect_optional_non_negative_integer(callbacks, path, row, "effective_activity_count")
    |> expect_non_negative_integer(callbacks, path, row, "observation_count")
    |> expect_non_negative_integer(callbacks, path, row, "downlink_count")
    |> expect_number(callbacks, path, row, "estimated_storage_produced_mb")
    |> expect_number(callbacks, path, row, "estimated_downlink_mb")
    |> expect_optional_number(callbacks, path, row, "starting_storage_used_mb")
    |> expect_optional_number(callbacks, path, row, "projected_storage_used_mb")
    |> expect_optional_number(callbacks, path, row, "storage_capacity_mb")
    |> expect_optional_number(callbacks, path, row, "starting_storage_margin")
    |> expect_optional_number(callbacks, path, row, "projected_storage_margin")
    |> expect_optional_number(callbacks, path, row, "projected_storage_remaining_mb")
    |> expect_optional_non_negative_number(callbacks, path, row, "projected_storage_overflow_mb")
    |> expect_optional_number(callbacks, path, row, "downlink_capacity_mb")
    |> expect_optional_number(callbacks, path, row, "starting_downlink_margin")
    |> expect_optional_number(callbacks, path, row, "projected_downlink_margin")
    |> expect_optional_number(callbacks, path, row, "projected_downlink_remaining_mb")
    |> expect_optional_non_negative_number(
      callbacks,
      path,
      row,
      "projected_downlink_shortfall_mb"
    )
    |> expect_optional_non_negative_number(callbacks, path, row, "storage_limited_downlinked_mb")
    |> expect_optional_non_negative_number(callbacks, path, row, "unused_downlink_capacity_mb")
    |> expect_optional_type(callbacks, path, row, "resource_source_quality", :binary)
    |> expect_optional_type(callbacks, path, row, "resource_trust_boundary_status", :binary)
    |> expect_optional_type(callbacks, path, row, "resource_pressure_status", :binary)
    |> expect_optional_type(callbacks, path, row, "resource_pressure_types", :list)
    |> validate_string_list_items(callbacks, path, row, "resource_pressure_types")
    |> expect_optional_type(callbacks, path, row, "resource_provenance", :map)
    |> expect_optional_type(callbacks, path, row, "payload_available", :boolean)
    |> expect_optional_type(callbacks, path, row, "antenna_available", :boolean)
    |> expect_optional_type(callbacks, path, row, "mode", :binary)
    |> expect_optional_type(callbacks, path, row, "incompatible_activity_types", :list)
    |> validate_string_list_items(callbacks, path, row, "incompatible_activity_types")
    |> expect_optional_type(callbacks, path, row, "suppressed_activity_types", :list)
    |> validate_string_list_items(callbacks, path, row, "suppressed_activity_types")
    |> expect_optional_number(callbacks, path, row, "fuel_margin")
    |> expect_optional_number(callbacks, path, row, "power_margin")
    |> expect_optional_probability(callbacks, path, row, "projected_power_margin")
    |> expect_optional_non_negative_number(callbacks, path, row, "battery_capacity_wh")
    |> expect_optional_non_negative_number(callbacks, path, row, "battery_energy_used_wh")
    |> expect_optional_non_negative_number(
      callbacks,
      path,
      row,
      "starting_battery_energy_used_wh"
    )
    |> expect_optional_non_negative_number(
      callbacks,
      path,
      row,
      "projected_battery_energy_used_wh"
    )
    |> expect_optional_non_negative_number(callbacks, path, row, "projected_battery_overuse_wh")
    |> expect_optional_probability(callbacks, path, row, "battery_state_of_charge")
    |> expect_optional_probability(callbacks, path, row, "projected_battery_state_of_charge")
    |> expect_optional_number(callbacks, path, row, "thermal_margin_c")
    |> expect_optional_type(callbacks, path, row, "warnings", :list)
    |> expect_optional_type(callbacks, path, row, "approval_requirements", :list)
    |> validate_optional_rows(
      callbacks,
      path <> ".approval_requirements",
      Map.get(row, "approval_requirements"),
      fn acc, row_path, requirement ->
        validate_approval_requirement(callbacks, acc, row_path, requirement)
      end
    )
    |> expect_optional_type(callbacks, path, row, "approval_rule_matches", :list)
    |> validate_optional_rows(
      callbacks,
      path <> ".approval_rule_matches",
      Map.get(row, "approval_rule_matches"),
      fn acc, row_path, match ->
        validate_policy_rule_match(callbacks, acc, row_path, match)
      end
    )
    |> expect_optional_non_negative_integer(callbacks, path, row, "ignored_activity_count")
    |> expect_optional_type(callbacks, path, row, "ignored_activity_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "ignored_activity_ids")
    |> validate_stable_ids(callbacks, path, row, [
      "first_resource_pressure_activity_id",
      "first_resource_pressure_ground_station_id",
      "first_resource_pressure_station_calendar_entry_id",
      "first_resource_pressure_station_calendar_provider_id",
      "first_resource_pressure_station_calendar_provider_entry_id",
      "first_resource_pressure_source_window_id",
      "source_window_id"
    ])
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "first_resource_pressure_source_window_type",
      :binary
    )
    |> validate_optional_source_window(
      callbacks,
      path,
      row,
      "first_resource_pressure_source_window"
    )
    |> expect_optional_type(callbacks, path, row, "source_window_type", :binary)
    |> validate_optional_source_window(callbacks, path, row, "source_window")
    |> validate_nested_id_match(
      callbacks,
      path,
      row,
      "first_resource_pressure_source_window",
      "id",
      "first_resource_pressure_source_window_id",
      "must match first_resource_pressure_source_window_id"
    )
    |> validate_nested_id_match(
      callbacks,
      path,
      row,
      "source_window",
      "id",
      "source_window_id",
      "must match source_window_id"
    )
    |> expect_optional_type(
      callbacks,
      path,
      row,
      "first_resource_pressure_station_calendar_directions",
      :list
    )
    |> validate_string_list_items(
      callbacks,
      path,
      row,
      "first_resource_pressure_station_calendar_directions"
    )
    |> expect_optional_probability(
      callbacks,
      path,
      row,
      "first_resource_pressure_capacity_fraction"
    )
    |> expect_optional_type(callbacks, path, row, "activity_resource_flow", :list)
    |> validate_rows(
      callbacks,
      path <> ".activity_resource_flow",
      Map.get(row, "activity_resource_flow", []),
      fn acc, row_path, flow_row ->
        validate_resource_projection_flow_row(callbacks, acc, row_path, flow_row)
      end
    )
    |> validate_counts(callbacks, path, row)
  end

  defp validate_counts(issues, callbacks, path, row) do
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
      callbacks,
      path,
      row,
      "activity_count",
      if(is_list(flow_rows), do: length(flow_rows), else: nil),
      "must equal activity_resource_flow row count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      row,
      "effective_activity_count",
      if(is_list(projected_flow_rows), do: length(projected_flow_rows), else: nil),
      "must equal projected activity_resource_flow row count"
    )
    |> expect_field_equals(
      callbacks,
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
      callbacks,
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
      callbacks,
      path,
      row,
      "ignored_activity_count",
      if(is_list(flow_ignored_ids), do: length(flow_ignored_ids), else: nil)
    )
    |> expect_field_equals(
      callbacks,
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

  defp require_callback(callbacks, name), do: Keyword.fetch!(callbacks, name)

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :require_fields), [issues, path, map, fields])

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp expect_non_negative_integer(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_non_negative_integer), [
        issues,
        path,
        map,
        field
      ])

  defp expect_optional_non_negative_integer(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_optional_non_negative_integer), [
        issues,
        path,
        map,
        field
      ])

  defp expect_number(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_number), [issues, path, map, field])

  defp expect_optional_number(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_optional_number), [issues, path, map, field])

  defp expect_optional_non_negative_number(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_optional_non_negative_number), [
        issues,
        path,
        map,
        field
      ])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp expect_optional_probability(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_optional_probability), [issues, path, map, field])

  defp validate_optional_rows(issues, callbacks, path, rows, validator),
    do:
      apply(require_callback(callbacks, :validate_optional_rows), [issues, path, rows, validator])

  defp validate_approval_requirement(callbacks, issues, path, requirement),
    do:
      apply(require_callback(callbacks, :validate_approval_requirement), [
        issues,
        path,
        requirement
      ])

  defp validate_policy_rule_match(callbacks, issues, path, match),
    do: apply(require_callback(callbacks, :validate_policy_rule_match), [issues, path, match])

  defp validate_optional_stable_id_list(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_optional_stable_id_list), [
        issues,
        path,
        map,
        field
      ])

  defp validate_optional_source_window(issues, callbacks, path, row, field),
    do:
      apply(require_callback(callbacks, :validate_optional_source_window), [
        issues,
        path,
        row,
        field
      ])

  defp validate_nested_id_match(
         issues,
         callbacks,
         path,
         row,
         nested_field,
         nested_id_field,
         expected_field,
         message
       ) do
    apply(require_callback(callbacks, :validate_nested_id_match), [
      issues,
      path,
      row,
      nested_field,
      nested_id_field,
      expected_field,
      message
    ])
  end

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(require_callback(callbacks, :validate_rows), [issues, path, rows, validator])

  defp validate_resource_projection_flow_row(callbacks, issues, path, row),
    do:
      apply(require_callback(callbacks, :validate_resource_projection_flow_row), [
        issues,
        path,
        row
      ])

  defp expect_field_equals(issues, callbacks, path, map, field, expected),
    do:
      apply(require_callback(callbacks, :expect_field_equals), [
        issues,
        path,
        map,
        field,
        expected
      ])

  defp expect_field_equals(issues, callbacks, path, map, field, expected, message),
    do:
      apply(require_callback(callbacks, :expect_field_equals_with_message), [
        issues,
        path,
        map,
        field,
        expected,
        message
      ])
end
