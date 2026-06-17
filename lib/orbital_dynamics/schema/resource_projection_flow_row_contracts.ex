defmodule OrbitalDynamics.Schema.ResourceProjectionFlowRowContracts do
  @moduledoc false

  @stable_id_fields [
    "activity_id",
    "source_window_id",
    "ground_station_id",
    "station_calendar_entry_id",
    "station_calendar_provider_id",
    "station_calendar_provider_entry_id"
  ]

  @string_list_fields [
    "station_calendar_directions",
    "incompatible_activity_types",
    "suppressed_activity_types"
  ]

  @probability_fields [
    "capacity_fraction",
    "completed_fraction",
    "battery_state_of_charge_after"
  ]

  @non_negative_number_fields [
    "planned_data_volume_mb",
    "actual_data_volume_mb",
    "data_volume_completion_fraction",
    "max_latency_s",
    "planned_latency_s",
    "actual_latency_s",
    "storage_used_before_mb",
    "storage_produced_mb",
    "storage_available_before_downlink_mb",
    "planned_downlink_mb",
    "downlinked_mb",
    "unused_downlink_capacity_mb",
    "storage_used_after_mb",
    "storage_overflow_mb",
    "downlink_used_before_mb",
    "downlink_used_after_mb",
    "downlink_shortfall_mb",
    "battery_energy_used_before_wh",
    "battery_energy_consumed_wh",
    "battery_energy_generated_wh",
    "battery_energy_used_after_wh",
    "battery_overuse_wh"
  ]

  @number_fields [
    "data_volume_delta_mb",
    "starts_at_s",
    "ends_at_s",
    "collection_ends_at_s",
    "planned_delivery_at_s",
    "actual_delivery_at_s",
    "latency_margin_s",
    "storage_delta_mb",
    "storage_margin_after",
    "downlink_margin_after",
    "battery_energy_delta_wh"
  ]

  def validate(issues, path, row, callbacks) when is_list(callbacks) do
    issues
    |> validate_stable_ids(callbacks, path, row, @stable_id_fields)
    |> expect_optional_type(callbacks, path, row, "source_window_type", :binary)
    |> validate_optional_source_window(callbacks, path, row, "source_window")
    |> validate_nested_id_match(
      callbacks,
      path,
      row,
      "source_window",
      "id",
      "source_window_id",
      "must match source_window_id"
    )
    |> validate_string_lists(callbacks, path, row)
    |> validate_probabilities(callbacks, path, row)
    |> validate_non_negative_numbers(callbacks, path, row)
    |> validate_numbers(callbacks, path, row)
    |> expect_optional_one_of(callbacks, path, row, "latency_basis", ["planned", "actual"])
    |> expect_optional_one_of(callbacks, path, row, "latency_status", ["within_limit", "late"])
    |> expect_optional_one_of(
      callbacks,
      path,
      row,
      "resource_effect_status",
      resource_effect_statuses()
    )
    |> expect_optional_type(callbacks, path, row, "resource_effect_reason", :binary)
  end

  defp validate_string_lists(issues, callbacks, path, row) do
    Enum.reduce(@string_list_fields, issues, fn field, acc ->
      acc
      |> expect_optional_type(callbacks, path, row, field, :list)
      |> validate_string_list_items(callbacks, path, row, field)
    end)
  end

  defp validate_probabilities(issues, callbacks, path, row) do
    Enum.reduce(@probability_fields, issues, fn field, acc ->
      expect_optional_probability(acc, callbacks, path, row, field)
    end)
  end

  defp validate_non_negative_numbers(issues, callbacks, path, row) do
    Enum.reduce(@non_negative_number_fields, issues, fn field, acc ->
      expect_optional_non_negative_number(acc, callbacks, path, row, field)
    end)
  end

  defp validate_numbers(issues, callbacks, path, row) do
    Enum.reduce(@number_fields, issues, fn field, acc ->
      expect_optional_number(acc, callbacks, path, row, field)
    end)
  end

  defp resource_effect_statuses do
    OrbitalDynamics.ResourceSummary.capabilities().roll_forward_resource_effect_statuses
  end

  defp require_callback(callbacks, name), do: Keyword.fetch!(callbacks, name)

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp validate_optional_source_window(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_optional_source_window), [
        issues,
        path,
        map,
        field
      ])

  defp validate_nested_id_match(
         issues,
         callbacks,
         path,
         map,
         nested_field,
         nested_id_field,
         expected_field,
         message
       ) do
    apply(require_callback(callbacks, :validate_nested_id_match), [
      issues,
      path,
      map,
      nested_field,
      nested_id_field,
      expected_field,
      message
    ])
  end

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp expect_optional_probability(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_optional_probability), [issues, path, map, field])

  defp expect_optional_non_negative_number(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_optional_non_negative_number), [
        issues,
        path,
        map,
        field
      ])

  defp expect_optional_number(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_optional_number), [issues, path, map, field])

  defp expect_optional_one_of(issues, callbacks, path, map, field, allowed),
    do:
      apply(require_callback(callbacks, :expect_optional_one_of), [
        issues,
        path,
        map,
        field,
        allowed
      ])
end
