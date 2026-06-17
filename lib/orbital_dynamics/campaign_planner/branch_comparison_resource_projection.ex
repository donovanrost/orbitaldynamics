defmodule OrbitalDynamics.CampaignPlanner.BranchComparisonResourceProjection do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ResourceProjectionRisk

  @stable_id_regex ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/

  def fields(nil), do: %{}

  def fields(report) do
    rows = Map.get(report, "projected_resources", [])
    unavailable_spacecraft_ids = resource_projection_unavailable_spacecraft_ids(rows)

    payload_unavailable_ids =
      resource_projection_availability_pressure_spacecraft_ids(rows, "payload_unavailable")

    degraded_payload_unavailable_ids =
      resource_projection_availability_pressure_spacecraft_ids(
        rows,
        "spacecraft_degraded_payload_unavailable"
      )

    antenna_unavailable_ids =
      resource_projection_availability_pressure_spacecraft_ids(rows, "antenna_unavailable")

    activity_type_suppressed_ids =
      resource_projection_availability_pressure_spacecraft_ids(
        rows,
        "activity_type_suppressed_by_resource_summary"
      )

    activity_type_incompatible_ids =
      resource_projection_availability_pressure_spacecraft_ids(
        rows,
        "activity_type_incompatible_with_resource_summary"
      )

    availability_pressure_types = ResourceProjectionRisk.availability_pressure_types(rows)
    first_pressure = ResourceProjectionRisk.first_pressure(rows)

    if rows == [] do
      %{}
    else
      %{
        "resource_projection_spacecraft_count" => length(rows),
        "resource_projection_unavailable_spacecraft_count" => length(unavailable_spacecraft_ids),
        "resource_projection_unavailable_spacecraft_ids" => unavailable_spacecraft_ids,
        "resource_projection_payload_unavailable_count" => length(payload_unavailable_ids),
        "resource_projection_payload_unavailable_spacecraft_ids" => payload_unavailable_ids,
        "resource_projection_degraded_payload_unavailable_count" =>
          length(degraded_payload_unavailable_ids),
        "resource_projection_degraded_payload_unavailable_spacecraft_ids" =>
          degraded_payload_unavailable_ids,
        "resource_projection_antenna_unavailable_count" => length(antenna_unavailable_ids),
        "resource_projection_antenna_unavailable_spacecraft_ids" => antenna_unavailable_ids,
        "resource_projection_activity_type_suppressed_count" =>
          length(activity_type_suppressed_ids),
        "resource_projection_activity_type_suppressed_spacecraft_ids" =>
          activity_type_suppressed_ids,
        "resource_projection_activity_type_incompatible_count" =>
          length(activity_type_incompatible_ids),
        "resource_projection_activity_type_incompatible_spacecraft_ids" =>
          activity_type_incompatible_ids,
        "resource_projection_availability_pressure_types" => availability_pressure_types,
        "projected_storage_margin" => minimum_present(rows, "projected_storage_margin"),
        "projected_storage_remaining_mb" =>
          minimum_projected_remaining(
            rows,
            "projected_storage_remaining_mb",
            "storage_capacity_mb",
            "projected_storage_used_mb"
          ),
        "projected_downlink_margin" => minimum_present(rows, "projected_downlink_margin"),
        "projected_downlink_remaining_mb" =>
          minimum_projected_remaining(
            rows,
            "projected_downlink_remaining_mb",
            "downlink_capacity_mb",
            "estimated_downlink_mb"
          ),
        "projected_power_margin" => minimum_present(rows, "projected_power_margin"),
        "projected_storage_overflow_mb" => maximum_present(rows, "projected_storage_overflow_mb"),
        "projected_downlink_shortfall_mb" =>
          maximum_present(rows, "projected_downlink_shortfall_mb"),
        "projected_battery_overuse_wh" => maximum_present(rows, "projected_battery_overuse_wh"),
        "storage_limited_downlinked_mb" => maximum_present(rows, "storage_limited_downlinked_mb"),
        "unused_downlink_capacity_mb" => maximum_present(rows, "unused_downlink_capacity_mb"),
        "resource_projection_flow_count" => resource_projection_flow_count(rows),
        "resource_projection_peak_storage_overflow_mb" =>
          peak_resource_projection_flow_value(rows, "storage_overflow_mb"),
        "resource_projection_peak_downlink_shortfall_mb" =>
          peak_resource_projection_flow_value(rows, "downlink_shortfall_mb"),
        "resource_projection_peak_battery_overuse_wh" =>
          peak_resource_projection_flow_value(rows, "battery_overuse_wh"),
        "resource_projection_peak_unused_downlink_capacity_mb" =>
          peak_resource_projection_flow_value(rows, "unused_downlink_capacity_mb"),
        "resource_source_quality_counts" => Map.get(report, "resource_source_quality_counts"),
        "resource_trust_boundary_status_counts" =>
          Map.get(report, "resource_trust_boundary_status_counts"),
        "first_resource_pressure_activity_id" => first_pressure["activity_id"],
        "first_resource_pressure_activity_type" => first_pressure["activity_type"],
        "first_resource_pressure_kind" => ResourceProjectionRisk.pressure_kind(first_pressure),
        "first_resource_pressure_starts_at_s" => first_pressure["starts_at_s"],
        "first_resource_pressure_direction" => first_pressure["direction"],
        "first_resource_pressure_ground_station_id" => first_pressure["ground_station_id"],
        "first_resource_pressure_station_calendar_entry_id" =>
          first_pressure["station_calendar_entry_id"],
        "first_resource_pressure_station_calendar_provider_id" =>
          first_pressure["station_calendar_provider_id"],
        "first_resource_pressure_station_calendar_provider_entry_id" =>
          first_pressure["station_calendar_provider_entry_id"],
        "first_resource_pressure_station_calendar_directions" =>
          first_pressure["station_calendar_directions"],
        "resource_projection_warning_count" => length(Map.get(report, "warnings", []))
      }
      |> compact_map()
    end
  end

  defp resource_projection_unavailable_spacecraft_ids(rows) do
    rows
    |> Enum.filter(&(&1["spacecraft_available"] == false))
    |> Enum.map(& &1["spacecraft_id"])
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp resource_projection_availability_pressure_spacecraft_ids(rows, pressure_type) do
    rows
    |> Enum.filter(fn row ->
      pressure_type in List.wrap(Map.get(row, "resource_pressure_types", []))
    end)
    |> Enum.map(&(Map.get(&1, "spacecraft_id") || Map.get(&1, "scenario_id")))
    |> Enum.filter(&stable_id_string?/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp resource_projection_flow_count(rows) do
    rows
    |> Enum.flat_map(&ResourceProjectionRisk.flow_rows/1)
    |> length()
  end

  defp peak_resource_projection_flow_value(rows, field) do
    rows
    |> Enum.flat_map(&ResourceProjectionRisk.flow_rows/1)
    |> Enum.map(&Map.get(&1, field))
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      values -> Enum.max(values)
    end
  end

  defp minimum_present(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      values -> Enum.min(values)
    end
  end

  defp minimum_projected_remaining(rows, remaining_field, capacity_field, used_or_demand_field) do
    rows
    |> Enum.flat_map(fn row ->
      cond do
        is_number(Map.get(row, remaining_field)) ->
          [Map.get(row, remaining_field)]

        is_number(Map.get(row, capacity_field)) and is_number(Map.get(row, used_or_demand_field)) ->
          [max(Map.get(row, capacity_field) - Map.get(row, used_or_demand_field), 0.0)]

        true ->
          []
      end
    end)
    |> case do
      [] -> nil
      values -> Enum.min(values)
    end
  end

  defp maximum_present(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      values -> Enum.max(values)
    end
  end

  defp stable_id_string?(value),
    do: is_binary(value) and value != "" and Regex.match?(@stable_id_regex, value)

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
