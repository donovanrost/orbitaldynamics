defmodule OrbitalDynamics.CampaignPlanner.RecommendationResourcePressure do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.PlanBranch
  alias OrbitalDynamics.CampaignPlanner.ResourceProjectionRisk

  def rows(%PlanBranch{
        id: branch_id,
        resource_projection_report: %{} = report
      }) do
    rows = Map.get(report, "projected_resources", [])
    pressure = ResourceProjectionRisk.first_pressure(rows)
    pressure_kind = ResourceProjectionRisk.pressure_kind(pressure)
    pressure_row = pressure_parent_row(rows, pressure)

    cond do
      pressure_kind ->
        [
          %{
            "type" => "resource_pressure",
            "recommended_branch_id" => branch_id,
            "spacecraft_id" => pressure_row["spacecraft_id"] || pressure_row["scenario_id"],
            "activity_id" => pressure["activity_id"],
            "activity_type" => pressure["activity_type"],
            "pressure_kind" => pressure_kind,
            "starts_at_s" => pressure["starts_at_s"],
            "storage_overflow_mb" => pressure["storage_overflow_mb"],
            "downlink_shortfall_mb" => pressure["downlink_shortfall_mb"],
            "battery_overuse_wh" => pressure["battery_overuse_wh"],
            "payload_available" => pressure_row["payload_available"],
            "antenna_available" => pressure_row["antenna_available"],
            "degraded" => pressure_row["degraded"],
            "resource_pressure_status" => pressure_row["resource_pressure_status"],
            "resource_pressure_types" => pressure_row["resource_pressure_types"],
            "peak_storage_overflow_mb" => peak_flow_value(rows, "storage_overflow_mb"),
            "peak_downlink_shortfall_mb" => peak_flow_value(rows, "downlink_shortfall_mb"),
            "peak_battery_overuse_wh" => peak_flow_value(rows, "battery_overuse_wh"),
            "reason" =>
              "recommended branch resource projection shows #{pressure_kind} at #{pressure["activity_id"]}"
          }
          |> Map.merge(resource_pressure_context(pressure, pressure_kind))
          |> compact_map()
        ]

      unavailable = ResourceProjectionRisk.first_spacecraft_unavailable(rows) ->
        [
          %{
            "type" => "resource_pressure",
            "recommended_branch_id" => branch_id,
            "spacecraft_id" => unavailable["spacecraft_id"],
            "pressure_kind" => "spacecraft_unavailable",
            "resource_pressure_status" => unavailable["resource_pressure_status"],
            "resource_pressure_types" => unavailable["resource_pressure_types"],
            "payload_available" => unavailable["payload_available"],
            "antenna_available" => unavailable["antenna_available"],
            "degraded" => unavailable["degraded"],
            "reason" =>
              "recommended branch resource projection declares spacecraft unavailable for #{unavailable["spacecraft_id"]}"
          }
          |> compact_map()
        ]

      true ->
        []
    end
  end

  def rows(_branch), do: []

  defp resource_pressure_context(pressure, pressure_kind) do
    %{
      "direction" => pressure["direction"],
      "ground_station_id" => pressure["ground_station_id"],
      "station_calendar_entry_id" => pressure["station_calendar_entry_id"],
      "station_calendar_provider_id" => pressure["station_calendar_provider_id"],
      "station_calendar_provider_entry_id" => pressure["station_calendar_provider_entry_id"],
      "station_calendar_directions" => pressure["station_calendar_directions"],
      "first_resource_pressure_activity_id" => pressure["activity_id"],
      "first_resource_pressure_activity_type" => pressure["activity_type"],
      "first_resource_pressure_kind" => pressure_kind,
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
  end

  defp pressure_parent_row(rows, pressure) do
    pressure_activity_id = pressure["activity_id"]

    Enum.find(rows, %{}, fn row ->
      row
      |> ResourceProjectionRisk.flow_rows()
      |> Enum.any?(&(&1["activity_id"] == pressure_activity_id))
    end)
  end

  defp peak_flow_value(rows, field) do
    rows
    |> Enum.flat_map(&ResourceProjectionRisk.flow_rows/1)
    |> Enum.map(&Map.get(&1, field))
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      values -> Enum.max(values)
    end
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
