defmodule OrbitalDynamics.Schema.ActivityContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_number: 4,
      expect_one_of: 5,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4,
      require_nested: 4,
      validate_interval: 3
    ]

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_ids: 4]

  def validate(issues, path, activity) do
    issues
    |> require_fields(path, activity, [
      "id",
      "type",
      "scenario_id",
      "starts_at_s",
      "ends_at_s"
    ])
    |> validate_stable_ids(path, activity, [
      "id",
      "scenario_id",
      "target_id",
      "ground_station_id",
      "source_window_id"
    ])
    |> expect_number(path, activity, "starts_at_s")
    |> expect_number(path, activity, "ends_at_s")
    |> validate_interval(path, activity)
    |> validate_activity_type(path, activity)
  end

  def validate_contact_fields(issues, path, activity) do
    issues
    |> expect_one_of(path, activity, "direction", [
      "downlink",
      "uplink",
      "command",
      "tracking",
      "health_check"
    ])
    |> expect_type(path, activity, "source_window", :map)
    |> expect_type(path, activity, "cadence_import", :map)
    |> require_nested(
      path <> ".cadence_import",
      Map.get(activity, "cadence_import", %{}),
      [
        "external_id",
        "activity_type"
      ]
    )
    |> validate_stable_ids(path, activity, ["station_reservation_id"])
    |> expect_optional_type(path, activity, "station_contention_status", :binary)
    |> expect_optional_type(path, activity, "station_reserved_by", :binary)
    |> expect_optional_type(path, activity, "station_reservation_status", :binary)
    |> validate_stable_ids(
      path <> ".cadence_import",
      Map.get(activity, "cadence_import", %{}),
      [
        "external_id"
      ]
    )
  end

  defp validate_activity_type(issues, path, %{"type" => "observe"} = activity) do
    require_fields(issues, path, activity, ["target_id"])
  end

  defp validate_activity_type(issues, path, %{"type" => "downlink"} = activity) do
    issues
    |> require_fields(path, activity, ["ground_station_id"])
    |> validate_contact_fields(path, activity)
  end

  defp validate_activity_type(issues, _path, _activity), do: issues
end
