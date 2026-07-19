defmodule OrbitalDynamics.ResourceProjection.PressureClassification do
  @moduledoc false

  @activity_availability_risk_types ~w(
    payload_unavailable
    spacecraft_degraded_payload_unavailable
    activity_type_suppressed_by_resource_summary
    activity_type_incompatible_with_resource_summary
    antenna_unavailable
  )

  @resource_availability_pressure_types [
    "spacecraft_unavailable" | @activity_availability_risk_types
  ]

  def activity_availability_risk_types, do: @activity_availability_risk_types

  def types(projected_resources) when is_list(projected_resources) do
    projection_pressure_types =
      Enum.flat_map(projected_resources, &Map.get(&1, "resource_pressure_types", []))

    flow_pressure_types =
      projected_resources
      |> Enum.flat_map(&Map.get(&1, "activity_resource_flow", []))
      |> Enum.map(&first_kind/1)
      |> Enum.reject(&is_nil/1)

    (projection_pressure_types ++ flow_pressure_types)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def types(
        storage_overflow_mb,
        downlink_shortfall_mb,
        battery_overuse_wh,
        thermal_margin_c,
        activity_resource_flow,
        spacecraft_available
      ) do
    []
    |> maybe_add_type("storage_overflow", storage_overflow_mb)
    |> maybe_add_type("downlink_shortfall", downlink_shortfall_mb)
    |> maybe_add_type("battery_depletion", battery_overuse_wh)
    |> maybe_add_thermal_margin_type(thermal_margin_c)
    |> add_activity_types(activity_resource_flow)
    |> maybe_add_spacecraft_unavailable_type(spacecraft_available)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def status([]), do: "nominal"
  def status(["downlink_shortfall"]), do: "downlink_shortfall"
  def status(["spacecraft_unavailable"]), do: "spacecraft_unavailable"
  def status(["payload_unavailable"]), do: "payload_unavailable"
  def status(["antenna_unavailable"]), do: "antenna_unavailable"

  def status(["spacecraft_degraded_payload_unavailable"]),
    do: "spacecraft_degraded_payload_unavailable"

  def status(types) when is_list(types) do
    if Enum.all?(types, &(&1 in @resource_availability_pressure_types)) do
      "resource_availability_pressure"
    else
      fallback_status(types)
    end
  end

  def first_event(rows) when is_list(rows) do
    rows
    |> Enum.find(fn row ->
      positive_number?(row["storage_overflow_mb"]) or
        positive_number?(row["downlink_shortfall_mb"]) or
        positive_number?(row["battery_overuse_wh"]) or
        Map.get(row, "resource_effect_reason") in @resource_availability_pressure_types
    end)
    |> case do
      nil ->
        %{}

      row ->
        %{
          "first_resource_pressure_activity_id" => row["activity_id"],
          "first_resource_pressure_activity_type" => row["activity_type"],
          "first_resource_pressure_kind" => first_kind(row),
          "first_resource_pressure_starts_at_s" => row["starts_at_s"],
          "first_resource_pressure_direction" => row["direction"],
          "first_resource_pressure_ground_station_id" => row["ground_station_id"],
          "first_resource_pressure_station_calendar_entry_id" => row["station_calendar_entry_id"],
          "first_resource_pressure_station_calendar_provider_id" =>
            row["station_calendar_provider_id"],
          "first_resource_pressure_station_calendar_provider_entry_id" =>
            row["station_calendar_provider_entry_id"],
          "first_resource_pressure_station_calendar_directions" =>
            row["station_calendar_directions"],
          "first_resource_pressure_capacity_fraction" => row["capacity_fraction"],
          "first_resource_pressure_source_window_id" => row["source_window_id"],
          "first_resource_pressure_source_window_type" => row["source_window_type"],
          "first_resource_pressure_source_window" => row["source_window"],
          "source_window_id" => row["source_window_id"],
          "source_window_type" => row["source_window_type"],
          "source_window" => row["source_window"]
        }
        |> compact_map()
    end
  end

  def kinds(row) do
    []
    |> maybe_add_kind(row, "storage_overflow", "storage_overflow_mb")
    |> maybe_add_kind(row, "downlink_shortfall", "downlink_shortfall_mb")
    |> maybe_add_kind(row, "battery_depletion", "battery_overuse_wh")
    |> maybe_add_availability_kind(row)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp maybe_add_type(types, type, value) when is_number(value) and value > 0.0,
    do: [type | types]

  defp maybe_add_type(types, _type, _value), do: types

  defp maybe_add_thermal_margin_type(types, value) when is_number(value) and value < 0.0,
    do: ["thermal_margin_below_limit" | types]

  defp maybe_add_thermal_margin_type(types, _value), do: types

  defp add_activity_types(types, rows) when is_list(rows) do
    Enum.reduce(rows, types, fn row, acc ->
      reason = Map.get(row, "resource_effect_reason")

      if reason in @resource_availability_pressure_types do
        [reason | acc]
      else
        acc
      end
    end)
  end

  defp add_activity_types(types, _rows), do: types

  defp maybe_add_spacecraft_unavailable_type(types, false),
    do: ["spacecraft_unavailable" | types]

  defp maybe_add_spacecraft_unavailable_type(types, _spacecraft_available), do: types

  defp fallback_status(["storage_overflow"]), do: "storage_overflow"

  defp fallback_status(["downlink_shortfall", "storage_overflow"]),
    do: "storage_and_downlink_pressure"

  defp fallback_status(_types), do: "resource_pressure"

  defp first_kind(%{"storage_overflow_mb" => value})
       when is_number(value) and value > 0.0,
       do: "storage_overflow"

  defp first_kind(%{"downlink_shortfall_mb" => value})
       when is_number(value) and value > 0.0,
       do: "downlink_shortfall"

  defp first_kind(%{"battery_overuse_wh" => value})
       when is_number(value) and value > 0.0,
       do: "battery_depletion"

  defp first_kind(%{"resource_effect_reason" => reason})
       when reason in @resource_availability_pressure_types,
       do: reason

  defp first_kind(_row), do: nil

  defp maybe_add_kind(types, row, type, field) do
    case Map.get(row, field) do
      value when is_number(value) and value > 0.0 -> [type | types]
      _value -> types
    end
  end

  defp maybe_add_availability_kind(types, %{"resource_effect_reason" => reason})
       when reason in @resource_availability_pressure_types,
       do: [reason | types]

  defp maybe_add_availability_kind(types, _row), do: types

  defp positive_number?(value), do: is_number(value) and value > 0.0

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
