defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffResourceMarginFields do
  @moduledoc false

  def evidence(row, callbacks) do
    [
      side_resource_margin_evidence(row, "source", callbacks),
      row,
      side_resource_margin_evidence(row, "replacement", callbacks)
    ]
    |> Enum.reduce(%{}, fn evidence, merged ->
      evidence =
        evidence
        |> callback!(callbacks, :stringify_keys).()
        |> callback!(callbacks, :normalize_resource_margin_aliases).()
        |> callback!(callbacks, :compact_map).()

      Map.merge(merged, evidence)
    end)
  end

  def threshold(evidence, policy, field, callbacks) do
    field
    |> threshold_keys()
    |> Enum.map(
      &(callback!(callbacks, :numeric_or_nil).(evidence[&1]) ||
          callback!(callbacks, :numeric_or_nil).(policy[&1]))
    )
    |> Enum.find(&is_number/1)
  end

  def spacecraft_id(row, evidence) do
    evidence["spacecraft_id"] ||
      row["spacecraft_id"] ||
      row["scenario_id"] ||
      get_in(row, ["replacement_activity_context", "spacecraft_id"]) ||
      get_in(row, ["replacement_activity_context", "scenario_id"]) ||
      get_in(row, ["source_activity_context", "spacecraft_id"]) ||
      get_in(row, ["source_activity_context", "scenario_id"])
  end

  defp side_resource_margin_evidence(row, side, callbacks) do
    context = callback!(callbacks, :stringify_keys).(row["#{side}_activity_context"] || %{})

    context
    |> callback!(callbacks, :put_default_if_present).(
      "spacecraft_id",
      row["#{side}_spacecraft_id"]
    )
    |> callback!(callbacks, :put_default_if_present).("fuel_margin", row["#{side}_fuel_margin"])
    |> callback!(callbacks, :put_default_if_present).(
      "fuel_margin_threshold",
      row["#{side}_fuel_margin_threshold"]
    )
    |> callback!(callbacks, :put_default_if_present).("power_margin", row["#{side}_power_margin"])
    |> callback!(callbacks, :put_default_if_present).(
      "battery_state_of_charge",
      row["#{side}_battery_state_of_charge"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "power_margin_threshold",
      row["#{side}_power_margin_threshold"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "storage_margin",
      row["#{side}_storage_margin"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "storage_margin_threshold",
      row["#{side}_storage_margin_threshold"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "downlink_margin",
      row["#{side}_downlink_margin"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "downlink_capacity_margin",
      row["#{side}_downlink_capacity_margin"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "downlink_margin_threshold",
      row["#{side}_downlink_margin_threshold"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "downlink_capacity_margin_threshold",
      row["#{side}_downlink_capacity_margin_threshold"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "thermal_margin_c",
      row["#{side}_thermal_margin_c"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "thermal_margin_c_threshold",
      row["#{side}_thermal_margin_c_threshold"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "thermal_margin_threshold",
      row["#{side}_thermal_margin_threshold"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "temperature_c",
      row["#{side}_temperature_c"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "actual_temperature_c",
      row["#{side}_actual_temperature_c"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "measured_temperature_c",
      row["#{side}_measured_temperature_c"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "planned_temperature_c",
      row["#{side}_planned_temperature_c"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "min_operating_temperature_c",
      row["#{side}_min_operating_temperature_c"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "max_operating_temperature_c",
      row["#{side}_max_operating_temperature_c"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "minimum_operating_temperature_c",
      row["#{side}_minimum_operating_temperature_c"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "maximum_operating_temperature_c",
      row["#{side}_maximum_operating_temperature_c"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "min_temperature_c",
      row["#{side}_min_temperature_c"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "max_temperature_c",
      row["#{side}_max_temperature_c"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "thermal_status",
      row["#{side}_thermal_status"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "thermal_model",
      row["#{side}_thermal_model"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "thermal_source",
      row["#{side}_thermal_source"]
    )
    |> callback!(callbacks, :put_default_if_present).(
      "thermal_confidence",
      row["#{side}_thermal_confidence"]
    )
  end

  defp threshold_keys("thermal_margin_c"),
    do: ["thermal_margin_c_threshold", "thermal_margin_threshold"]

  defp threshold_keys(field), do: ["#{field}_threshold"]

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
