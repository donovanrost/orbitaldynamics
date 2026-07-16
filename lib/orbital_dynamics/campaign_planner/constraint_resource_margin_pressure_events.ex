defmodule OrbitalDynamics.CampaignPlanner.ConstraintResourceMarginPressureEvents do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ConstraintPressureContext
  alias OrbitalDynamics.CampaignPlanner.ScalarValues
  alias OrbitalDynamics.CampaignPlanner.ValueEncoding

  def events(row, source_path), do: events(row, source_path, callbacks())

  def events(row, source_path, callbacks) do
    with field when is_binary(field) <- resource_margin_field(row["metric"]),
         value when is_number(value) <- resource_margin_value(row, field, callbacks) do
      [
        %{
          "type" => "resource_margin_pressure",
          "spacecraft_id" => row["spacecraft_id"] || scenario_id(row, callbacks),
          "scenario_id" => scenario_id(row, callbacks),
          "resource_field" => field,
          field => value,
          "#{field}_threshold" => numeric_or_nil(row["threshold"], callbacks),
          "activity_id" => row["activity_id"],
          "source_activity_ids" => source_activity_ids(row, callbacks),
          "constraint_id" => row["constraint_id"],
          "constraint_metric" => row["metric"],
          "constraint_status" => row["status"],
          "violation_severity" => row["violation_severity"],
          "derivation_reasons" => [
            "constraint_report_#{row["status"]}",
            "constraint_resource_margin_pressure"
          ],
          "feedback_source" => source_path,
          "feedback_scope" => "constraint_report",
          "trust_boundary" => trust_boundary(row, callbacks)
        }
        |> compact_map(callbacks)
      ]
    else
      _value -> []
    end
  end

  defp resource_margin_field("projected_storage_margin"), do: "storage_margin"
  defp resource_margin_field("min_projected_storage_margin"), do: "storage_margin"
  defp resource_margin_field("storage_margin"), do: "storage_margin"
  defp resource_margin_field("projected_fuel_margin"), do: "fuel_margin"
  defp resource_margin_field("min_projected_fuel_margin"), do: "fuel_margin"
  defp resource_margin_field("fuel_margin"), do: "fuel_margin"
  defp resource_margin_field("projected_downlink_margin"), do: "downlink_margin"
  defp resource_margin_field("min_projected_downlink_margin"), do: "downlink_margin"
  defp resource_margin_field("downlink_margin"), do: "downlink_margin"
  defp resource_margin_field("projected_power_margin"), do: "power_margin"
  defp resource_margin_field("min_projected_power_margin"), do: "power_margin"
  defp resource_margin_field("power_margin"), do: "power_margin"
  defp resource_margin_field("projected_thermal_margin_c"), do: "thermal_margin_c"
  defp resource_margin_field("min_projected_thermal_margin_c"), do: "thermal_margin_c"
  defp resource_margin_field("thermal_margin_c"), do: "thermal_margin_c"
  defp resource_margin_field(_metric), do: nil

  defp resource_margin_value(row, field, callbacks) do
    [
      row["value"],
      row[field],
      row["projected_#{field}"]
    ]
    |> Enum.map(&numeric_or_nil(&1, callbacks))
    |> Enum.find(&is_number/1)
  end

  defp callbacks do
    [
      compact_map: &ValueEncoding.compact_map/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      scenario_id: &ConstraintPressureContext.scenario_id/1,
      source_activity_ids: &ConstraintPressureContext.source_activity_ids/1,
      trust_boundary: &ConstraintPressureContext.trust_boundary/1
    ]
  end

  defp callback(callbacks, name, args) do
    callbacks
    |> Keyword.fetch!(name)
    |> then(&apply(&1, args))
  end

  defp compact_map(map, callbacks), do: callback(callbacks, :compact_map, [map])
  defp numeric_or_nil(value, callbacks), do: callback(callbacks, :numeric_or_nil, [value])
  defp scenario_id(row, callbacks), do: callback(callbacks, :scenario_id, [row])

  defp source_activity_ids(row, callbacks),
    do: callback(callbacks, :source_activity_ids, [row])

  defp trust_boundary(row, callbacks), do: callback(callbacks, :trust_boundary, [row])
end
