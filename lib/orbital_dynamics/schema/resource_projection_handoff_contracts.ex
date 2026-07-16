defmodule OrbitalDynamics.Schema.ResourceProjectionHandoffContracts do
  @moduledoc false

  @battery_handoff_number_fields [
    "total_battery_energy_consumed_wh",
    "total_battery_energy_generated_wh",
    "net_battery_energy_delta_wh",
    "peak_battery_overuse_wh"
  ]
  @count_handoff_fields [
    "activity_count",
    "effective_activity_count",
    "observation_count",
    "downlink_count",
    "ignored_activity_count",
    "ignored_activity_ids"
  ]
  @context_handoff_fields [
    "activity_id",
    "activity_ids",
    "activity_type",
    "spacecraft_id",
    "scenario_id",
    "starts_at_s",
    "ends_at_s",
    "invalid_activity_input",
    "invalid_activity_input_reason",
    "invalid_resource_summary_input",
    "invalid_resource_summary_input_reason",
    "duplicate_resource_summary_scope",
    "mixed_wildcard_resource_summary_scope",
    "resource_summary_key",
    "duplicate_resource_summary_index",
    "duplicate_resource_summary_count",
    "storage_limited_downlinked_mb",
    "unused_downlink_capacity_mb",
    "projected_storage_margin",
    "projected_storage_remaining_mb",
    "projected_downlink_margin",
    "projected_downlink_remaining_mb",
    "projected_storage_overflow_mb",
    "projected_downlink_shortfall_mb",
    "projected_power_margin",
    "projected_battery_energy_used_wh",
    "projected_battery_state_of_charge",
    "projected_battery_overuse_wh",
    "resource_pressure_status",
    "resource_pressure_types",
    "resource_flow_count",
    "peak_storage_overflow_mb",
    "peak_downlink_shortfall_mb",
    "peak_unused_downlink_capacity_mb",
    "first_resource_pressure_activity_id",
    "first_resource_pressure_activity_type",
    "first_resource_pressure_kind",
    "first_resource_pressure_starts_at_s",
    "first_resource_pressure_direction",
    "first_resource_pressure_ground_station_id",
    "first_resource_pressure_station_calendar_entry_id",
    "first_resource_pressure_station_calendar_provider_id",
    "first_resource_pressure_station_calendar_provider_entry_id",
    "first_resource_pressure_station_calendar_directions",
    "first_resource_pressure_capacity_fraction",
    "first_resource_pressure_source_window_id",
    "first_resource_pressure_source_window_type",
    "source_window_id",
    "source_window_type",
    "resource_source_quality",
    "resource_trust_boundary",
    "resource_trust_boundary_status",
    "resource_provenance",
    "fuel_margin",
    "power_margin",
    "thermal_margin_c",
    "spacecraft_available",
    "payload_available",
    "antenna_available",
    "degraded",
    "mode",
    "incompatible_activity_types",
    "suppressed_activity_types",
    "requirement_type",
    "required_authority",
    "policy_bundle_id",
    "rule_id",
    "escalation_level",
    "escalation_queue",
    "escalation_role",
    "sla_s",
    "approval_status",
    "required_operator_action",
    "source_resource_projection_flow_summary"
  ]

  def battery_handoff_number_fields, do: @battery_handoff_number_fields

  def validate_battery_handoff_fields(issues, path, row, callbacks) when is_list(callbacks) do
    Enum.reduce(@battery_handoff_number_fields, issues, fn field, acc ->
      expect_optional_number(acc, callbacks, path, row, field)
    end)
  end

  def validate_remaining_handoff_fields(issues, path, row, callbacks) when is_list(callbacks) do
    Enum.reduce(
      ["projected_storage_remaining_mb", "projected_downlink_remaining_mb"],
      issues,
      fn field, acc -> expect_optional_number(acc, callbacks, path, row, field) end
    )
  end

  def validate_battery_handoff_matches_source(
        issues,
        path,
        %{"source_resource_projection" => %{"activity_resource_flow" => flow_rows}} = row
      )
      when is_list(flow_rows) do
    expected = battery_handoff_flow_values(flow_rows)

    Enum.reduce(expected, issues, fn {field, expected_value}, acc ->
      row_value = Map.get(row, field)

      if is_number(row_value) and row_value != expected_value do
        [
          error(
            "#{path}.#{field}",
            "must equal source_resource_projection activity_resource_flow #{field}"
          )
          | acc
        ]
      else
        acc
      end
    end)
  end

  def validate_battery_handoff_matches_source(issues, _path, _row), do: issues

  def validate_count_handoff_matches_source(
        issues,
        path,
        %{"source_resource_projection" => %{"activity_resource_flow" => flow_rows}} = row,
        callbacks
      )
      when is_list(flow_rows) and is_list(callbacks) do
    expected = handoff_count_values(flow_rows, callbacks)

    Enum.reduce(expected, issues, fn {field, {expected_value, message}}, acc ->
      expect_field_equals(acc, callbacks, path, row, field, expected_value, message)
    end)
  end

  def validate_count_handoff_matches_source(issues, _path, _row, _callbacks), do: issues

  def validate_flow_summary_context_matches_source(
        issues,
        path,
        %{"source_resource_projection" => %{} = source} = row
      ) do
    row_summary = Map.get(row, "source_resource_projection_flow_summary")
    source_summary = Map.get(source, "source_resource_projection_flow_summary")

    cond do
      is_nil(row_summary) and is_nil(source_summary) ->
        issues

      row_summary == source_summary ->
        issues

      true ->
        [
          error(
            "#{path}.source_resource_projection_flow_summary",
            "must match source_resource_projection.source_resource_projection_flow_summary"
          )
          | issues
        ]
    end
  end

  def validate_flow_summary_context_matches_source(issues, _path, _row), do: issues

  def validate_battery_handoff_matches_own_flow(
        issues,
        path,
        %{"activity_resource_flow" => flow_rows} = row
      )
      when is_list(flow_rows) do
    expected = battery_handoff_flow_values(flow_rows)

    Enum.reduce(expected, issues, fn {field, expected_value}, acc ->
      row_value = Map.get(row, field)

      if is_number(row_value) and row_value != expected_value do
        [
          error("#{path}.#{field}", "must equal activity_resource_flow #{field}")
          | acc
        ]
      else
        acc
      end
    end)
  end

  def validate_battery_handoff_matches_own_flow(issues, _path, _row), do: issues

  def validate_cadence_source_review_battery_handoff_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    Enum.reduce(@battery_handoff_number_fields, issues, fn field, acc ->
      row_value = Map.get(row, field)
      source_value = Map.get(source_review_row, field)

      if is_number(row_value) and is_number(source_value) and row_value != source_value do
        [
          error(
            "#{path}.source_review_row.#{field}",
            "must match #{field} on Cadence import row"
          )
          | acc
        ]
      else
        acc
      end
    end)
  end

  def validate_cadence_source_review_battery_handoff_matches(issues, _path, _row), do: issues

  def validate_cadence_source_review_count_handoff_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if handoff_row?(row) do
      Enum.reduce(@count_handoff_fields, issues, fn field, acc ->
        row_value = Map.get(row, field)
        source_value = Map.get(source_review_row, field)

        if not is_nil(row_value) and not is_nil(source_value) and row_value != source_value do
          [
            error(
              "#{path}.source_review_row.#{field}",
              "must match #{field} on Cadence import row"
            )
            | acc
          ]
        else
          acc
        end
      end)
    else
      issues
    end
  end

  def validate_cadence_source_review_count_handoff_matches(issues, _path, _row), do: issues

  def validate_cadence_source_review_context_handoff_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if handoff_row?(row) do
      Enum.reduce(@context_handoff_fields, issues, fn field, acc ->
        row_value = Map.get(row, field)
        source_value = Map.get(source_review_row, field)

        if not is_nil(row_value) and not is_nil(source_value) and row_value != source_value do
          [
            error(
              "#{path}.source_review_row.#{field}",
              "must match #{field} on Cadence import row"
            )
            | acc
          ]
        else
          acc
        end
      end)
    else
      issues
    end
  end

  def validate_cadence_source_review_context_handoff_matches(issues, _path, _row), do: issues

  defp handoff_count_values(flow_rows, callbacks) do
    flow_rows = Enum.filter(flow_rows, &is_map/1)

    ignored_ids =
      flow_rows
      |> Enum.filter(&(Map.get(&1, "resource_effect_status") == "ignored"))
      |> Enum.map(&Map.get(&1, "activity_id"))

    projected_rows =
      Enum.reject(flow_rows, &(Map.get(&1, "resource_effect_status") == "ignored"))

    %{
      "activity_count" =>
        {length(flow_rows), "must equal source_resource_projection flow row count"},
      "effective_activity_count" =>
        {length(projected_rows), "must equal source_resource_projection projected flow row count"},
      "observation_count" =>
        {Enum.count(projected_rows, &(Map.get(&1, "activity_type") == "observe")),
         "must equal source_resource_projection projected observe flow row count"},
      "downlink_count" =>
        {Enum.count(projected_rows, &resource_projection_downlink_flow_row?(callbacks, &1)),
         "must equal source_resource_projection projected downlink flow row count"},
      "ignored_activity_count" =>
        {length(ignored_ids), "must equal source_resource_projection ignored flow row count"},
      "ignored_activity_ids" =>
        {ignored_ids, "must match source_resource_projection ignored activity flow row IDs"}
    }
  end

  defp battery_handoff_flow_values(flow_rows) do
    %{
      "total_battery_energy_consumed_wh" =>
        OrbitalDynamics.Schema.ResourceProjectionNumericContracts.sum_flow_number(
          flow_rows,
          "battery_energy_consumed_wh"
        ),
      "total_battery_energy_generated_wh" =>
        OrbitalDynamics.Schema.ResourceProjectionNumericContracts.sum_flow_number(
          flow_rows,
          "battery_energy_generated_wh"
        ),
      "net_battery_energy_delta_wh" =>
        OrbitalDynamics.Schema.ResourceProjectionNumericContracts.sum_flow_number(
          flow_rows,
          "battery_energy_delta_wh"
        ),
      "peak_battery_overuse_wh" =>
        OrbitalDynamics.Schema.ResourceProjectionNumericContracts.max_flow_number(
          flow_rows,
          "battery_overuse_wh"
        )
    }
  end

  defp handoff_row?(row) do
    Map.get(row, "review_type") == "resource_projection_review" or
      Map.get(row, "source_review_type") == "resource_projection_review" or
      Map.get(row, "import_action") == "review_resource_projection"
  end

  defp expect_optional_number(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_optional_number), [issues, path, map, field])

  defp expect_field_equals(issues, callbacks, path, row, field, expected_value, message) do
    apply(require_callback(callbacks, :expect_field_equals), [
      issues,
      path,
      row,
      field,
      expected_value,
      message
    ])
  end

  defp resource_projection_downlink_flow_row?(callbacks, row),
    do: apply(require_callback(callbacks, :resource_projection_downlink_flow_row?), [row])

  defp require_callback(callbacks, name), do: Keyword.fetch!(callbacks, name)

  defp error(path, message) do
    %{"severity" => "error", "path" => path, "message" => message}
  end
end
