defmodule OrbitalDynamics.Schema.ActivityContracts do
  @moduledoc false

  def validate(issues, path, activity, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, activity, [
      "id",
      "type",
      "scenario_id",
      "starts_at_s",
      "ends_at_s"
    ])
    |> validate_stable_ids(callbacks, path, activity, [
      "id",
      "scenario_id",
      "target_id",
      "ground_station_id",
      "source_window_id"
    ])
    |> expect_number(callbacks, path, activity, "starts_at_s")
    |> expect_number(callbacks, path, activity, "ends_at_s")
    |> validate_interval(callbacks, path, activity)
    |> validate_activity_type(callbacks, path, activity)
  end

  def validate_contact_fields(issues, path, activity, callbacks) when is_list(callbacks) do
    issues
    |> expect_one_of(callbacks, path, activity, "direction", [
      "downlink",
      "uplink",
      "command",
      "tracking",
      "health_check"
    ])
    |> expect_type(callbacks, path, activity, "source_window", :map)
    |> expect_type(callbacks, path, activity, "cadence_import", :map)
    |> require_nested(
      callbacks,
      path <> ".cadence_import",
      Map.get(activity, "cadence_import", %{}),
      [
        "external_id",
        "activity_type"
      ]
    )
    |> validate_stable_ids(callbacks, path, activity, ["station_reservation_id"])
    |> expect_optional_type(callbacks, path, activity, "station_contention_status", :binary)
    |> expect_optional_type(callbacks, path, activity, "station_reserved_by", :binary)
    |> expect_optional_type(callbacks, path, activity, "station_reservation_status", :binary)
    |> validate_stable_ids(
      callbacks,
      path <> ".cadence_import",
      Map.get(activity, "cadence_import", %{}),
      [
        "external_id"
      ]
    )
  end

  defp validate_activity_type(issues, callbacks, path, %{"type" => "observe"} = activity) do
    require_fields(issues, callbacks, path, activity, ["target_id"])
  end

  defp validate_activity_type(issues, callbacks, path, %{"type" => "downlink"} = activity) do
    issues
    |> require_fields(callbacks, path, activity, ["ground_station_id"])
    |> validate_contact_fields(path, activity, callbacks)
  end

  defp validate_activity_type(issues, _callbacks, _path, _activity), do: issues

  defp require_callback(callbacks, name), do: Keyword.fetch!(callbacks, name)

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :require_fields), [issues, path, map, fields])

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp expect_number(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_number), [issues, path, map, field])

  defp validate_interval(issues, callbacks, path, activity),
    do: apply(require_callback(callbacks, :validate_interval), [issues, path, activity])

  defp expect_one_of(issues, callbacks, path, map, field, allowed),
    do: apply(require_callback(callbacks, :expect_one_of), [issues, path, map, field, allowed])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(require_callback(callbacks, :expect_type), [issues, path, map, field, type])

  defp require_nested(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :require_nested), [issues, path, map, fields])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [issues, path, map, field, type])
end
