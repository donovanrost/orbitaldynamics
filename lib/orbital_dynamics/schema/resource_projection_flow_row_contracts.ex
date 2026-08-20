defmodule OrbitalDynamics.Schema.ResourceProjectionFlowRowContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_optional_non_negative_number: 4,
      expect_optional_number: 4,
      expect_optional_one_of: 5,
      expect_optional_probability: 4,
      expect_optional_type: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_ids: 4]

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

  def validate(issues, path, row, source_window_validator, nested_id_match_validator)
      when is_function(source_window_validator, 4) and
             is_function(nested_id_match_validator, 7) do
    issues
    |> validate_stable_ids(path, row, @stable_id_fields)
    |> expect_optional_type(path, row, "source_window_type", :binary)
    |> source_window_validator.(path, row, "source_window")
    |> nested_id_match_validator.(
      path,
      row,
      "source_window",
      "id",
      "source_window_id",
      "must match source_window_id"
    )
    |> validate_string_lists(path, row)
    |> validate_probabilities(path, row)
    |> validate_non_negative_numbers(path, row)
    |> validate_numbers(path, row)
    |> validate_optional_link_budget(path, row)
    |> expect_optional_one_of(path, row, "latency_basis", ["planned", "actual"])
    |> expect_optional_one_of(path, row, "latency_status", ["within_limit", "late"])
    |> expect_optional_one_of(
      path,
      row,
      "resource_effect_status",
      resource_effect_statuses()
    )
    |> expect_optional_type(path, row, "resource_effect_reason", :binary)
  end

  defp validate_string_lists(issues, path, row) do
    Enum.reduce(@string_list_fields, issues, fn field, acc ->
      acc
      |> expect_optional_type(path, row, field, :list)
      |> validate_string_list_items(path, row, field)
    end)
  end

  defp validate_probabilities(issues, path, row) do
    Enum.reduce(@probability_fields, issues, fn field, acc ->
      expect_optional_probability(acc, path, row, field)
    end)
  end

  defp validate_non_negative_numbers(issues, path, row) do
    Enum.reduce(@non_negative_number_fields, issues, fn field, acc ->
      expect_optional_non_negative_number(acc, path, row, field)
    end)
  end

  defp validate_numbers(issues, path, row) do
    Enum.reduce(@number_fields, issues, fn field, acc ->
      expect_optional_number(acc, path, row, field)
    end)
  end

  defp validate_optional_link_budget(issues, path, row) do
    case Map.get(row, "downlink_link_budget") do
      nil ->
        issues

      %{} = budget ->
        OrbitalDynamics.Schema.DownlinkLinkBudgetContracts.validate(
          issues,
          path <> ".downlink_link_budget",
          budget
        )

      _budget ->
        [error(path <> ".downlink_link_budget", "must be an object") | issues]
    end
  end

  defp resource_effect_statuses do
    OrbitalDynamics.ResourceSummary.capabilities().roll_forward_resource_effect_statuses
  end
end
