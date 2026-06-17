defmodule OrbitalDynamics.CampaignPlanner.ResourceProjectionRisk do
  @moduledoc false

  def risk_indicators(%{"projected_resources" => rows}) when is_list(rows) do
    rows
    |> Enum.flat_map(fn row ->
      [
        resource_projection_pressure_risk(
          row,
          "storage_overflow",
          "projected_storage_overflow_mb"
        ),
        resource_projection_pressure_risk(
          row,
          "downlink_shortfall",
          "projected_downlink_shortfall_mb"
        ),
        resource_projection_pressure_risk(
          row,
          "battery_depletion",
          "projected_battery_overuse_wh"
        ),
        resource_projection_thermal_margin_risk(row),
        resource_projection_spacecraft_unavailable_risk(row)
      ]
      |> Kernel.++(resource_projection_availability_pressure_risks(row))
      |> Enum.reject(&is_nil/1)
    end)
  end

  def risk_indicators(_report), do: []

  defp resource_projection_pressure_risk(row, type, field) do
    case Map.get(row, field) do
      value when is_number(value) and value > 0.0 ->
        pressure = first_pressure([row], type)

        %{
          "type" => type,
          "severity" => "high",
          "reason" => resource_projection_pressure_reason(row, type, value),
          "value" => value,
          "spacecraft_id" => row["spacecraft_id"],
          "direction" => pressure["direction"],
          "ground_station_id" => pressure["ground_station_id"],
          "station_calendar_entry_id" => pressure["station_calendar_entry_id"],
          "station_calendar_provider_id" => pressure["station_calendar_provider_id"],
          "station_calendar_provider_entry_id" => pressure["station_calendar_provider_entry_id"],
          "station_calendar_directions" => pressure["station_calendar_directions"],
          "first_resource_pressure_activity_id" => pressure["activity_id"],
          "first_resource_pressure_activity_type" => pressure["activity_type"],
          "first_resource_pressure_kind" => type,
          "first_resource_pressure_starts_at_s" => pressure["starts_at_s"],
          "first_resource_pressure_direction" => pressure["direction"],
          "first_resource_pressure_ground_station_id" => pressure["ground_station_id"],
          "first_resource_pressure_station_calendar_entry_id" =>
            pressure["station_calendar_entry_id"],
          "first_resource_pressure_station_calendar_provider_id" =>
            pressure["station_calendar_provider_id"],
          "first_resource_pressure_station_calendar_provider_entry_id" =>
            pressure["station_calendar_provider_entry_id"],
          "first_resource_pressure_station_calendar_directions" =>
            pressure["station_calendar_directions"]
        }
        |> compact_map()

      _value ->
        nil
    end
  end

  defp resource_projection_thermal_margin_risk(row) do
    pressure_types = row |> Map.get("resource_pressure_types", []) |> List.wrap()
    thermal_margin = numeric_or_nil(row["thermal_margin_c"])

    cond do
      is_number(thermal_margin) and thermal_margin < 0.0 ->
        %{
          "type" => "thermal_margin_below_limit",
          "severity" => "high",
          "reason" =>
            "resource projection for #{row["spacecraft_id"]} declares thermal margin #{thermal_margin} C below zero",
          "value" => thermal_margin,
          "spacecraft_id" => row["spacecraft_id"],
          "thermal_margin_c" => thermal_margin,
          "resource_pressure_status" => row["resource_pressure_status"],
          "resource_pressure_types" => row["resource_pressure_types"]
        }
        |> compact_map()

      "thermal_margin_below_limit" in pressure_types ->
        %{
          "type" => "thermal_margin_below_limit",
          "severity" => "high",
          "reason" =>
            "resource projection for #{row["spacecraft_id"]} declares thermal margin below zero",
          "spacecraft_id" => row["spacecraft_id"],
          "resource_pressure_status" => row["resource_pressure_status"],
          "resource_pressure_types" => row["resource_pressure_types"]
        }
        |> compact_map()

      true ->
        nil
    end
  end

  defp resource_projection_spacecraft_unavailable_risk(%{"spacecraft_available" => false} = row) do
    %{
      "type" => "spacecraft_unavailable",
      "severity" => "high",
      "reason" =>
        "resource projection for #{row["spacecraft_id"]} declares spacecraft unavailable",
      "value" => false,
      "spacecraft_id" => row["spacecraft_id"],
      "resource_pressure_status" => row["resource_pressure_status"],
      "resource_pressure_types" => row["resource_pressure_types"]
    }
    |> compact_map()
  end

  defp resource_projection_spacecraft_unavailable_risk(_row), do: nil

  defp resource_projection_availability_pressure_risks(row) do
    row
    |> Map.get("resource_pressure_types", [])
    |> List.wrap()
    |> Enum.filter(&(&1 in resource_projection_activity_availability_pressure_types()))
    |> Enum.map(fn type ->
      pressure = first_pressure([row], type)

      %{
        "type" => type,
        "severity" => "high",
        "reason" => resource_projection_availability_pressure_reason(row, type),
        "value" => false,
        "spacecraft_id" => row["spacecraft_id"],
        "payload_available" => row["payload_available"],
        "antenna_available" => row["antenna_available"],
        "degraded" => row["degraded"],
        "incompatible_activity_types" => activity_constraint_types(row, pressure),
        "suppressed_activity_types" => row["suppressed_activity_types"],
        "resource_pressure_status" => row["resource_pressure_status"],
        "resource_pressure_types" => row["resource_pressure_types"],
        "direction" => pressure["direction"],
        "ground_station_id" => pressure["ground_station_id"],
        "station_calendar_entry_id" => pressure["station_calendar_entry_id"],
        "station_calendar_provider_id" => pressure["station_calendar_provider_id"],
        "station_calendar_provider_entry_id" => pressure["station_calendar_provider_entry_id"],
        "station_calendar_directions" => pressure["station_calendar_directions"],
        "first_resource_pressure_activity_id" => pressure["activity_id"],
        "first_resource_pressure_activity_type" => pressure["activity_type"],
        "first_resource_pressure_kind" => type,
        "first_resource_pressure_starts_at_s" => pressure["starts_at_s"],
        "first_resource_pressure_direction" => pressure["direction"],
        "first_resource_pressure_ground_station_id" => pressure["ground_station_id"],
        "first_resource_pressure_station_calendar_entry_id" =>
          pressure["station_calendar_entry_id"],
        "first_resource_pressure_station_calendar_provider_id" =>
          pressure["station_calendar_provider_id"],
        "first_resource_pressure_station_calendar_provider_entry_id" =>
          pressure["station_calendar_provider_entry_id"],
        "first_resource_pressure_station_calendar_directions" =>
          pressure["station_calendar_directions"]
      }
      |> compact_map()
    end)
  end

  defp resource_projection_activity_availability_pressure_types do
    ~w(payload_unavailable spacecraft_degraded_payload_unavailable activity_type_suppressed_by_resource_summary activity_type_incompatible_with_resource_summary antenna_unavailable)
  end

  defp resource_projection_availability_pressure_reason(row, "payload_unavailable") do
    "resource projection for #{row["spacecraft_id"]} declares payload unavailable for selected observations"
  end

  defp resource_projection_availability_pressure_reason(
         row,
         "spacecraft_degraded_payload_unavailable"
       ) do
    "resource projection for #{row["spacecraft_id"]} declares degraded payload operations unavailable"
  end

  defp resource_projection_availability_pressure_reason(row, "antenna_unavailable") do
    "resource projection for #{row["spacecraft_id"]} declares antenna unavailable for selected contacts"
  end

  defp resource_projection_availability_pressure_reason(
         row,
         "activity_type_suppressed_by_resource_summary"
       ) do
    "resource projection for #{row["spacecraft_id"]} suppresses activity types from resource summary"
  end

  defp resource_projection_availability_pressure_reason(
         row,
         "activity_type_incompatible_with_resource_summary"
       ) do
    "resource projection for #{row["spacecraft_id"]} declares activity types incompatible with resource summary"
  end

  defp resource_projection_pressure_reason(row, "storage_overflow", value) do
    "resource projection for #{row["spacecraft_id"]} exceeds declared storage capacity by #{value} MB"
  end

  defp resource_projection_pressure_reason(row, "downlink_shortfall", value) do
    "resource projection for #{row["spacecraft_id"]} exceeds declared downlink capacity by #{value} MB"
  end

  defp resource_projection_pressure_reason(row, "battery_depletion", value) do
    "resource projection for #{row["spacecraft_id"]} exceeds declared battery capacity by #{value} Wh"
  end

  def activity_constraint_types(row, pressure) do
    [
      row["incompatible_activity_types"],
      row["suppressed_activity_types"],
      pressure["incompatible_activity_types"],
      pressure["suppressed_activity_types"],
      pressure["activity_type"]
    ]
    |> List.flatten()
    |> normalize_incompatible_activity_types()
    |> case do
      [] -> ["observe"]
      types -> types
    end
  end

  def first_pressure(rows) do
    rows
    |> Enum.flat_map(&flow_rows/1)
    |> Enum.find(%{}, fn row ->
      positive_number?(row["storage_overflow_mb"]) or
        positive_number?(row["downlink_shortfall_mb"]) or
        positive_number?(row["battery_overuse_wh"]) or
        Map.get(row, "resource_effect_reason") in availability_pressure_types()
    end)
  end

  def first_pressure(rows, "storage_overflow") do
    rows
    |> Enum.flat_map(&flow_rows/1)
    |> Enum.find(%{}, &positive_number?(&1["storage_overflow_mb"]))
  end

  def first_pressure(rows, "downlink_shortfall") do
    rows
    |> Enum.flat_map(&flow_rows/1)
    |> Enum.find(%{}, &positive_number?(&1["downlink_shortfall_mb"]))
  end

  def first_pressure(rows, "battery_depletion") do
    rows
    |> Enum.flat_map(&flow_rows/1)
    |> Enum.find(%{}, &positive_number?(&1["battery_overuse_wh"]))
  end

  def first_pressure(rows, type)
      when type in [
             "spacecraft_unavailable",
             "payload_unavailable",
             "spacecraft_degraded_payload_unavailable",
             "activity_type_suppressed_by_resource_summary",
             "activity_type_incompatible_with_resource_summary",
             "antenna_unavailable"
           ] do
    rows
    |> Enum.flat_map(&flow_rows/1)
    |> Enum.find(%{}, &(Map.get(&1, "resource_effect_reason") == type))
  end

  def first_pressure(rows, _type),
    do: first_pressure(rows)

  def first_spacecraft_unavailable(rows) do
    Enum.find(rows, &(&1["spacecraft_available"] == false))
  end

  def flow_rows(%{"activity_resource_flow" => rows}) when is_list(rows),
    do: rows

  def flow_rows(_row), do: []

  def pressure_kind(%{"storage_overflow_mb" => value})
      when is_number(value) and value > 0.0,
      do: "storage_overflow"

  def pressure_kind(%{"downlink_shortfall_mb" => value})
      when is_number(value) and value > 0.0,
      do: "downlink_shortfall"

  def pressure_kind(%{"battery_overuse_wh" => value})
      when is_number(value) and value > 0.0,
      do: "battery_depletion"

  def pressure_kind(%{"resource_effect_reason" => reason})
      when reason in [
             "spacecraft_unavailable",
             "payload_unavailable",
             "spacecraft_degraded_payload_unavailable",
             "activity_type_suppressed_by_resource_summary",
             "activity_type_incompatible_with_resource_summary",
             "antenna_unavailable"
           ],
      do: reason

  def pressure_kind(_row), do: nil

  def availability_pressure_types(rows) do
    rows
    |> Enum.flat_map(&(Map.get(&1, "resource_pressure_types", []) |> List.wrap()))
    |> Enum.filter(&(&1 in availability_pressure_types()))
    |> Enum.uniq()
    |> Enum.sort()
  end

  def availability_pressure_types do
    boolean_availability_pressure_types() ++
      activity_type_constraint_pressure_types()
  end

  def boolean_availability_pressure_types do
    ~w(spacecraft_unavailable payload_unavailable spacecraft_degraded_payload_unavailable antenna_unavailable)
  end

  def activity_type_constraint_pressure_types do
    ~w(activity_type_suppressed_by_resource_summary activity_type_incompatible_with_resource_summary)
  end

  defp positive_number?(value), do: is_number(value) and value > 0.0

  defp numeric_or_nil(nil), do: nil
  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value

  defp numeric_or_nil(value) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> number
      _error -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp normalize_incompatible_activity_types(values) when is_list(values) do
    values
    |> Enum.map(&encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp normalize_incompatible_activity_types(value) when is_binary(value) or is_atom(value) do
    case encode_value(value) do
      value when value in [nil, ""] -> ["observe"]
      value -> [value]
    end
  end

  defp normalize_incompatible_activity_types(_values), do: ["observe"]

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
