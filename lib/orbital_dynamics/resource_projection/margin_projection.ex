defmodule OrbitalDynamics.ResourceProjection.MarginProjection do
  @moduledoc false

  def starting_storage_used_mb(%{"storage_used_mb" => value}) when is_number(value),
    do: value * 1.0

  def starting_storage_used_mb(%{"storage_capacity_mb" => capacity, "storage_margin" => margin})
      when is_number(capacity) and is_number(margin),
      do: max(capacity * (1.0 - margin), 0.0)

  def starting_storage_used_mb(_summary), do: nil

  def starting_battery_energy_used_wh(%{"battery_energy_used_wh" => value})
      when is_number(value),
      do: value * 1.0

  def starting_battery_energy_used_wh(%{
        "battery_capacity_wh" => capacity,
        "battery_state_of_charge" => state_of_charge
      })
      when is_number(capacity) and is_number(state_of_charge),
      do: max(capacity * (1.0 - state_of_charge), 0.0)

  def starting_battery_energy_used_wh(_summary), do: nil

  def projected_storage_used_mb(nil, _storage_produced_mb, _downlinked_mb), do: nil

  def projected_storage_used_mb(starting_storage_used_mb, storage_produced_mb, downlinked_mb) do
    max(starting_storage_used_mb + storage_produced_mb - downlinked_mb, 0.0)
  end

  def projected_storage_margin(capacity, projected_storage_used_mb, _summary)
      when is_number(capacity) and capacity > 0 and is_number(projected_storage_used_mb) do
    max((capacity - projected_storage_used_mb) / capacity, 0.0)
  end

  def projected_storage_margin(_capacity, _projected_storage_used_mb, summary),
    do: Map.get(summary, "storage_margin")

  def projected_storage_overflow_mb(capacity, projected_storage_used_mb)
      when is_number(capacity) and is_number(projected_storage_used_mb) do
    max(projected_storage_used_mb - capacity, 0.0)
  end

  def projected_storage_overflow_mb(_capacity, _projected_storage_used_mb), do: nil

  def projected_downlink_margin(capacity, downlinked_mb, _summary)
      when is_number(capacity) and capacity > 0 do
    max((capacity - downlinked_mb) / capacity, 0.0)
  end

  def projected_downlink_margin(_capacity, _downlinked_mb, summary),
    do: Map.get(summary, "downlink_margin")

  def projected_downlink_shortfall_mb(capacity, downlinked_mb)
      when is_number(capacity) and is_number(downlinked_mb) do
    max(downlinked_mb - capacity, 0.0)
  end

  def projected_downlink_shortfall_mb(_capacity, _downlinked_mb), do: nil

  def projected_battery_energy_used_wh(nil, _activity_resource_flow), do: nil

  def projected_battery_energy_used_wh(
        starting_battery_energy_used_wh,
        activity_resource_flow
      )
      when is_number(starting_battery_energy_used_wh) and is_list(activity_resource_flow) do
    Enum.reduce(activity_resource_flow, starting_battery_energy_used_wh, fn row, acc ->
      roll_forward_battery_energy(acc, Map.get(row, "battery_energy_delta_wh", 0.0))
    end)
  end

  def projected_battery_state_of_charge(capacity, battery_energy_used_wh)
      when is_number(capacity) and capacity > 0 and is_number(battery_energy_used_wh) do
    ((capacity - battery_energy_used_wh) / capacity)
    |> max(0.0)
    |> min(1.0)
  end

  def projected_battery_state_of_charge(_capacity, _battery_energy_used_wh), do: nil

  def projected_battery_overuse_wh(capacity, battery_energy_used_wh)
      when is_number(capacity) and is_number(battery_energy_used_wh) do
    max(battery_energy_used_wh - capacity, 0.0)
  end

  def projected_battery_overuse_wh(_capacity, _battery_energy_used_wh), do: nil

  def roll_forward_battery_energy(nil, _battery_delta_wh), do: nil

  def roll_forward_battery_energy(battery_energy_used_wh, battery_delta_wh)
      when is_number(battery_energy_used_wh) and is_number(battery_delta_wh) do
    max(battery_energy_used_wh + battery_delta_wh, 0.0)
  end

  def warnings(
        summary,
        storage_capacity_mb,
        downlink_capacity_mb,
        projected_storage_overflow_mb,
        projected_downlink_shortfall_mb,
        projected_battery_overuse_wh,
        unused_downlink_capacity_mb,
        resource_pressure_types
      ) do
    []
    |> maybe_warning(
      "spacecraft_unavailable" in resource_pressure_types,
      "spacecraft unavailable; projected activity resource effects are ignored"
    )
    |> maybe_warning(
      "payload_unavailable" in resource_pressure_types,
      "payload unavailable; projected observation resource effects are ignored"
    )
    |> maybe_warning(
      "spacecraft_degraded_payload_unavailable" in resource_pressure_types,
      "spacecraft degraded; projected observation resource effects are ignored"
    )
    |> maybe_warning(
      "activity_type_suppressed_by_resource_summary" in resource_pressure_types,
      "resource summary suppresses one or more selected activity types; projected resource effects are ignored"
    )
    |> maybe_warning(
      "activity_type_incompatible_with_resource_summary" in resource_pressure_types,
      "resource summary marks one or more selected activity types incompatible; projected resource effects are ignored"
    )
    |> maybe_warning(
      "antenna_unavailable" in resource_pressure_types,
      "antenna unavailable; projected contact resource effects are ignored"
    )
    |> maybe_warning(
      "thermal_margin_below_limit" in resource_pressure_types,
      "externally supplied thermal margin is below zero; resource projection requires review"
    )
    |> maybe_warning(
      is_nil(storage_capacity_mb) and not is_nil(Map.get(summary, "storage_margin")),
      "storage capacity missing; projected storage margin preserves supplied summary margin"
    )
    |> maybe_warning(
      is_nil(downlink_capacity_mb) and not is_nil(Map.get(summary, "downlink_margin")),
      "downlink capacity missing; projected downlink margin preserves supplied summary margin"
    )
    |> maybe_warning(
      is_number(projected_storage_overflow_mb) and projected_storage_overflow_mb > 0.0,
      "projected storage exceeds declared capacity by #{projected_storage_overflow_mb} MB"
    )
    |> maybe_warning(
      is_number(projected_downlink_shortfall_mb) and projected_downlink_shortfall_mb > 0.0,
      "projected downlink demand exceeds declared capacity by #{projected_downlink_shortfall_mb} MB"
    )
    |> maybe_warning(
      is_nil(Map.get(summary, "battery_capacity_wh")) and
        not is_nil(Map.get(summary, "battery_state_of_charge")),
      "battery capacity missing; projected battery state preserves supplied summary margin"
    )
    |> maybe_warning(
      is_number(projected_battery_overuse_wh) and projected_battery_overuse_wh > 0.0,
      "projected battery energy use exceeds declared capacity by #{projected_battery_overuse_wh} Wh"
    )
    |> maybe_warning(
      is_number(unused_downlink_capacity_mb) and unused_downlink_capacity_mb > 0.0,
      "projected downlink capacity exceeds stored data by #{unused_downlink_capacity_mb} MB"
    )
    |> Enum.reverse()
  end

  defp maybe_warning(warnings, true, warning), do: [warning | warnings]
  defp maybe_warning(warnings, false, _warning), do: warnings
end
