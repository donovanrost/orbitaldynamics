defmodule OrbitalDynamics.CandidateRefresh.OperationalFeedback.ResourceRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback.RowValues

  def link_capacity_station_throughput_factor(row) when is_map(row) do
    row = RowValues.stringify_keys(row)

    case RowValues.first_number(row, [
           "station_throughput_factor",
           "throughput_completion_fraction",
           "actual_completion_fraction",
           "actual_downlink_completion_ratio"
         ]) do
      factor when is_number(factor) ->
        RowValues.unit_interval(factor)

      _factor ->
        actual =
          RowValues.first_number(row, [
            "actual_throughput_mb",
            "actual_downlink_mb",
            "delivered_data_mb",
            "received_data_mb"
          ])

        planned =
          RowValues.first_number(row, [
            "selected_capacity_adjusted_throughput_mb",
            "selected_estimated_throughput_mb",
            "capacity_adjusted_throughput_mb",
            "estimated_throughput_mb"
          ])

        if is_number(actual) and is_number(planned) and planned > 0.0 do
          RowValues.unit_interval(actual / planned)
        end
    end
  end

  def link_capacity_station_throughput_factor(_row), do: nil

  def link_capacity_feedback_rows(%{"rows" => rows}) when is_list(rows),
    do: Enum.map(rows, &RowValues.stringify_keys/1)

  def link_capacity_feedback_rows(%{} = report), do: [RowValues.stringify_keys(report)]
  def link_capacity_feedback_rows(_report), do: []

  def link_capacity_station_id(row) when is_map(row) do
    row = RowValues.stringify_keys(row)

    [
      row["ground_station_id"],
      row["station_id"],
      nested_station_id(row)
    ]
    |> Enum.find_value(&RowValues.stable_id_or_nil/1)
  end

  def link_capacity_station_id(_row), do: nil

  def link_capacity_row_feedback(row, station_id) when is_map(row) do
    factor = link_capacity_station_throughput_factor(row)

    cond do
      station_id in [nil, ""] ->
        %{}

      not is_number(factor) ->
        %{}

      true ->
        %{
          "station_throughput_factor" => %{station_id => factor}
        }
        |> RowValues.compact_nonempty()
    end
  end

  def link_capacity_row_feedback(_row, _station_id), do: %{}

  def resource_projection_row_feedback(row, spacecraft_id) when is_map(row) do
    row = RowValues.stringify_keys(row)

    margin_override = resource_projection_row_margin_feedback(row)
    availability_override = resource_projection_row_availability_feedback(row)

    resource_row_feedback(spacecraft_id, margin_override, availability_override)
  end

  def resource_projection_row_feedback(_row, _spacecraft_id), do: %{}

  def resource_filter_row_feedback(%{} = row) do
    row = RowValues.stringify_keys(row)
    spacecraft_id = RowValues.stable_id_or_nil(row["spacecraft_id"])

    margin_override = resource_filter_row_margin_feedback(row)
    availability_override = resource_filter_row_availability_feedback(row)

    resource_row_feedback(spacecraft_id, margin_override, availability_override)
  end

  def resource_filter_row_feedback(_row), do: %{}

  defp resource_row_feedback(spacecraft_id, margin_override, availability_override) do
    cond do
      spacecraft_id in [nil, ""] ->
        %{}

      margin_override == %{} and availability_override == %{} ->
        %{}

      true ->
        %{
          "resource_margin_overrides" =>
            if(margin_override == %{}, do: %{}, else: %{spacecraft_id => margin_override}),
          "resource_availability_overrides" =>
            if(availability_override == %{},
              do: %{},
              else: %{spacecraft_id => availability_override}
            )
        }
        |> RowValues.compact_nonempty()
    end
  end

  defp resource_projection_row_margin_feedback(row) do
    %{
      "storage_margin" =>
        first_resource_projection_margin(row, [
          "projected_storage_margin",
          "storage_margin",
          "starting_storage_margin"
        ]) ||
          negative_resource_projection_pressure(row, [
            "projected_storage_overflow_mb",
            "storage_overflow_mb"
          ]),
      "downlink_margin" =>
        first_resource_projection_margin(row, [
          "projected_downlink_margin",
          "downlink_margin",
          "starting_downlink_margin"
        ]) ||
          negative_resource_projection_pressure(row, [
            "projected_downlink_shortfall_mb",
            "downlink_shortfall_mb"
          ]),
      "power_margin" =>
        first_resource_projection_margin(row, [
          "projected_power_margin",
          "projected_battery_state_of_charge",
          "battery_state_of_charge",
          "power_margin"
        ]) ||
          negative_resource_projection_pressure(row, [
            "projected_battery_overuse_wh",
            "battery_overuse_wh"
          ]),
      "battery_capacity_wh" => first_resource_projection_number(row, ["battery_capacity_wh"]),
      "battery_energy_used_wh" =>
        first_resource_projection_number(row, [
          "projected_battery_energy_used_wh",
          "battery_energy_used_wh"
        ]),
      "battery_state_of_charge" =>
        first_resource_projection_number(row, [
          "projected_battery_state_of_charge",
          "battery_state_of_charge"
        ])
    }
    |> RowValues.compact_nil_values()
  end

  defp resource_projection_row_availability_feedback(row) do
    %{
      "payload_available" => resource_projection_boolean_feedback(row, "payload_available"),
      "antenna_available" => resource_projection_boolean_feedback(row, "antenna_available"),
      "spacecraft_available" => resource_projection_boolean_feedback(row, "spacecraft_available"),
      "degraded" => resource_projection_boolean_feedback(row, "degraded")
    }
    |> RowValues.compact_nil_values()
  end

  defp resource_filter_row_margin_feedback(row) do
    reason = RowValues.normalized_token(row["suppressed_reason"])

    %{
      "fuel_margin" =>
        resource_filter_unit_margin(row, "fuel_margin") ||
          if(reason == "fuel_margin_below_policy", do: 0.0),
      "power_margin" =>
        resource_filter_unit_margin(row, "power_margin") ||
          if(
            reason in ["power_margin_below_observe_policy", "power_margin_below_downlink_policy"],
            do: 0.0
          ),
      "storage_margin" =>
        resource_filter_unit_margin(row, "storage_margin") ||
          if(reason == "storage_margin_below_observe_policy", do: 0.0),
      "downlink_margin" =>
        resource_filter_unit_margin(row, "downlink_margin") ||
          if(reason == "downlink_margin_below_policy", do: 0.0),
      "thermal_margin_c" =>
        resource_filter_number(row, "thermal_margin_c") ||
          if(reason == "thermal_margin_below_policy", do: 0.0),
      "battery_capacity_wh" => resource_filter_number(row, "battery_capacity_wh"),
      "battery_energy_used_wh" => resource_filter_number(row, "battery_energy_used_wh"),
      "battery_state_of_charge" => resource_filter_unit_margin(row, "battery_state_of_charge")
    }
    |> RowValues.compact_nil_values()
  end

  defp resource_filter_row_availability_feedback(row) do
    reason = RowValues.normalized_token(row["suppressed_reason"])

    %{
      "payload_available" =>
        resource_filter_first_boolean(
          resource_filter_boolean_feedback(row, "payload_available"),
          if(reason in ["payload_unavailable", "spacecraft_degraded_payload_unavailable"],
            do: false
          )
        ),
      "antenna_available" =>
        resource_filter_first_boolean(
          resource_filter_boolean_feedback(row, "antenna_available"),
          if(reason == "antenna_unavailable", do: false)
        ),
      "spacecraft_available" =>
        resource_filter_first_boolean(
          resource_filter_boolean_feedback(row, "spacecraft_available"),
          if(reason == "spacecraft_unavailable", do: false)
        ),
      "degraded" =>
        resource_filter_first_boolean(
          resource_filter_boolean_feedback(row, "degraded"),
          if(reason == "spacecraft_degraded_payload_unavailable", do: true)
        ),
      "mode" => resource_filter_mode_feedback(row)
    }
    |> RowValues.compact_nil_values()
  end

  defp resource_filter_first_boolean(value, _fallback) when is_boolean(value), do: value
  defp resource_filter_first_boolean(_value, fallback) when is_boolean(fallback), do: fallback
  defp resource_filter_first_boolean(_value, _fallback), do: nil

  defp resource_filter_unit_margin(row, field) do
    case resource_filter_number(row, field) do
      value when is_number(value) and value < 0.0 -> 0.0
      value when is_number(value) and value > 1.0 -> 1.0
      value when is_number(value) -> value
      _value -> nil
    end
  end

  defp resource_filter_number(row, field) do
    case RowValues.numeric_value(Map.get(row, field)) do
      value when is_number(value) -> value
      _value -> nil
    end
  end

  defp resource_filter_boolean_feedback(row, field) do
    case strict_boolean_value(Map.get(row, field)) do
      bool when is_boolean(bool) -> bool
      nil -> nil
    end
  end

  defp resource_filter_mode_feedback(row) do
    case Map.get(row, "mode") do
      mode when is_binary(mode) and mode != "" -> mode
      _mode -> nil
    end
  end

  defp first_resource_projection_number(row, fields) do
    Enum.find_value(fields, fn field ->
      case RowValues.numeric_value(Map.get(row, field)) do
        value when is_number(value) -> value
        _value -> nil
      end
    end)
  end

  defp first_resource_projection_margin(row, fields) do
    case first_resource_projection_number(row, fields) do
      value when is_number(value) and value < 0.0 -> 0.0
      value when is_number(value) and value > 1.0 -> 1.0
      value when is_number(value) -> value
      _value -> nil
    end
  end

  defp negative_resource_projection_pressure(row, fields) do
    case first_resource_projection_number(row, fields) do
      value when is_number(value) and value > 0.0 -> 0.0
      _value -> nil
    end
  end

  defp resource_projection_boolean_feedback(row, field) do
    case strict_boolean_value(Map.get(row, field)) do
      bool when is_boolean(bool) -> bool
      nil -> nil
    end
  end

  defp strict_boolean_value(value) when is_boolean(value), do: value

  defp strict_boolean_value(value) when is_number(value) do
    cond do
      value == 1 -> true
      value == 0 -> false
      true -> nil
    end
  end

  defp strict_boolean_value(value) when is_binary(value) do
    case String.downcase(String.trim(value)) do
      value when value in ["true", "1"] -> true
      value when value in ["false", "0"] -> false
      _value -> nil
    end
  end

  defp strict_boolean_value(_value), do: nil

  defp nested_station_id(candidate) do
    Enum.find_value(["ground_station", "station"], fn station_key ->
      case Map.get(candidate, station_key) do
        %{} = station ->
          Enum.find_value(["ground_station_id", "station_id", "id"], fn identity_key ->
            Map.get(station, identity_key)
          end)

        _station ->
          nil
      end
    end)
  end
end
