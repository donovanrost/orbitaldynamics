defmodule OrbitalDynamics.ResourceProjection.PressureRisks do
  @moduledoc false

  alias OrbitalDynamics.ResourceProjection.PressureClassification

  def build(row) do
    []
    |> maybe_add_resource_pressure_risk(row, "storage_overflow", "projected_storage_overflow_mb")
    |> maybe_add_resource_pressure_risk(
      row,
      "downlink_shortfall",
      "projected_downlink_shortfall_mb"
    )
    |> maybe_add_resource_pressure_risk(
      row,
      "battery_depletion",
      "projected_battery_overuse_wh"
    )
    |> maybe_add_thermal_margin_risk(row)
    |> maybe_add_spacecraft_unavailable_risk(row)
    |> maybe_add_activity_availability_risks(row)
  end

  defp maybe_add_resource_pressure_risk(risks, row, type, field) do
    case Map.get(row, field) do
      value when is_number(value) and value > 0.0 ->
        [
          %{
            "type" => type,
            "severity" => "high",
            "reason" =>
              "#{type} #{value} #{resource_pressure_unit(field)} for #{row["spacecraft_id"]}",
            "value" => value
          }
          | risks
        ]

      _value ->
        risks
    end
  end

  defp resource_pressure_unit("projected_battery_overuse_wh"), do: "Wh"
  defp resource_pressure_unit(_field), do: "MB"

  defp maybe_add_thermal_margin_risk(risks, %{"thermal_margin_c" => value} = row)
       when is_number(value) and value < 0.0 do
    [
      %{
        "type" => "thermal_margin_below_limit",
        "severity" => "high",
        "reason" => "thermal margin below zero for #{row["spacecraft_id"]}",
        "value" => value
      }
      | risks
    ]
  end

  defp maybe_add_thermal_margin_risk(risks, _row), do: risks

  defp maybe_add_spacecraft_unavailable_risk(risks, %{"spacecraft_available" => false} = row) do
    [
      %{
        "type" => "spacecraft_unavailable",
        "severity" => "high",
        "reason" => "spacecraft unavailable for #{row["spacecraft_id"]}",
        "value" => false
      }
      | risks
    ]
  end

  defp maybe_add_spacecraft_unavailable_risk(risks, _row), do: risks

  defp maybe_add_activity_availability_risks(risks, row) do
    row
    |> Map.get("resource_pressure_types", [])
    |> Enum.filter(&(&1 in PressureClassification.activity_availability_risk_types()))
    |> Enum.reduce(risks, fn type, acc ->
      [
        %{
          "type" => type,
          "severity" => "high",
          "reason" => "#{type} for #{row["spacecraft_id"]}",
          "value" => true
        }
        | acc
      ]
    end)
  end
end
