defmodule OrbitalDynamics.Schema.ResourceProjectionFlowProjectedResourceContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_optional_non_negative_integer: 4,
      expect_optional_number: 4,
      expect_optional_type: 5,
      require_fields: 4,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_optional_stable_id_list: 4, validate_stable_ids: 4]

  def validate(issues, path, row) do
    issues
    |> require_fields(path, row, ["spacecraft_id"])
    |> validate_stable_ids(path, row, [
      "spacecraft_id",
      "first_resource_pressure_activity_id",
      "first_resource_pressure_source_window_id",
      "first_resource_pressure_station_calendar_entry_id",
      "first_resource_pressure_station_calendar_provider_id",
      "first_resource_pressure_station_calendar_provider_entry_id"
    ])
    |> expect_optional_non_negative_integer(path, row, "activity_count")
    |> expect_optional_non_negative_integer(path, row, "effective_activity_count")
    |> expect_optional_non_negative_integer(path, row, "ignored_activity_count")
    |> expect_optional_type(path, row, "ignored_activity_ids", :list)
    |> validate_optional_stable_id_list(path, row, "ignored_activity_ids")
    |> expect_optional_type(path, row, "resource_pressure_types", :list)
    |> validate_string_list_items(path, row, "resource_pressure_types")
    |> expect_optional_number(path, row, "projected_storage_remaining_mb")
    |> expect_optional_number(path, row, "projected_downlink_remaining_mb")
    |> expect_optional_type(path, row, "resource_pressure_status", :binary)
  end
end
