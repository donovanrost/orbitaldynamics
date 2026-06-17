defmodule OrbitalDynamics.Schema.ResourceProjectionFlowProjectedResourceContracts do
  @moduledoc false

  def validate(issues, path, row, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, row, ["spacecraft_id"])
    |> validate_stable_ids(callbacks, path, row, [
      "spacecraft_id",
      "first_resource_pressure_activity_id",
      "first_resource_pressure_source_window_id",
      "first_resource_pressure_station_calendar_entry_id",
      "first_resource_pressure_station_calendar_provider_id",
      "first_resource_pressure_station_calendar_provider_entry_id"
    ])
    |> expect_optional_non_negative_integer(callbacks, path, row, "activity_count")
    |> expect_optional_non_negative_integer(callbacks, path, row, "effective_activity_count")
    |> expect_optional_non_negative_integer(callbacks, path, row, "ignored_activity_count")
    |> expect_optional_type(callbacks, path, row, "ignored_activity_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, row, "ignored_activity_ids")
    |> expect_optional_type(callbacks, path, row, "resource_pressure_types", :list)
    |> validate_string_list_items(callbacks, path, row, "resource_pressure_types")
    |> expect_optional_number(callbacks, path, row, "projected_storage_remaining_mb")
    |> expect_optional_number(callbacks, path, row, "projected_downlink_remaining_mb")
    |> expect_optional_type(callbacks, path, row, "resource_pressure_status", :binary)
  end

  defp require_callback(callbacks, name), do: Keyword.fetch!(callbacks, name)

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :require_fields), [issues, path, map, fields])

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp expect_optional_non_negative_integer(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_optional_non_negative_integer), [
        issues,
        path,
        map,
        field
      ])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp validate_optional_stable_id_list(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_optional_stable_id_list), [
        issues,
        path,
        map,
        field
      ])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp expect_optional_number(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_optional_number), [issues, path, map, field])
end
