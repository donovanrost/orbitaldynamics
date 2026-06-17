defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StorageDownlinkPressure.Summary.ResourceRouting do
  @moduledoc false

  @downlink_shortfall_pressure_fields [
    "downlink_pressure_status_counts",
    "downlink_pressure_type_counts",
    "resource_pressure_direction_counts",
    "resource_pressure_activity_ids_by_direction",
    "resource_pressure_ground_station_ids_by_type",
    "resource_pressure_source_window_ids_by_type",
    "resource_pressure_station_calendar_entry_ids_by_type",
    "resource_pressure_station_calendar_provider_ids_by_type",
    "resource_pressure_station_calendar_provider_entry_ids_by_type"
  ]

  @downlink_pressure_fields @downlink_shortfall_pressure_fields ++
                              [
                                "downlink_requirement_status_counts",
                                "direction_counts",
                                "contact_ids_by_direction",
                                "selected_contact_id_counts"
                              ]

  def fields(allocation_summary, link_summary, projection_summary) do
    resource_pressure_status_counts =
      Map.get(projection_summary, "resource_pressure_status_counts", %{})

    resource_pressure_type_counts =
      Map.get(projection_summary, "resource_pressure_type_counts", %{})

    %{
      "contact_allocation_status_counts" =>
        Map.get(allocation_summary, "allocation_status_counts", %{}),
      "contact_allocation_reason_counts" =>
        Map.get(allocation_summary, "allocation_reason_counts", %{}),
      "selected_shortfall_row_count" =>
        summary_integer(link_summary, "selected_shortfall_row_count"),
      "actual_shortfall_row_count" => summary_integer(link_summary, "actual_shortfall_row_count"),
      "downlink_requirement_status_counts" =>
        Map.get(link_summary, "downlink_requirement_status_counts", %{}),
      "direction_counts" => Map.get(link_summary, "direction_counts", %{}),
      "contact_ids_by_direction" => Map.get(link_summary, "contact_ids_by_direction", %{}),
      "selected_contact_id_counts" => Map.get(link_summary, "selected_contact_id_counts", %{}),
      "resource_projection_spacecraft_counts" =>
        Map.get(projection_summary, "resource_projection_spacecraft_counts", %{}),
      "ground_station_counts" =>
        merge_count_maps([
          Map.get(allocation_summary, "station_pressure_ground_station_counts", %{}),
          Map.get(link_summary, "ground_station_counts", %{}),
          Map.get(projection_summary, "ground_station_counts", %{})
        ]) || %{},
      "resource_pressure_activity_id_counts" =>
        Map.get(projection_summary, "resource_pressure_activity_id_counts", %{}),
      "resource_pressure_direction_counts" =>
        Map.get(projection_summary, "resource_pressure_direction_counts", %{}),
      "resource_pressure_activity_ids_by_direction" =>
        Map.get(projection_summary, "resource_pressure_activity_ids_by_direction", %{}),
      "resource_pressure_ground_station_ids_by_type" =>
        Map.get(projection_summary, "resource_pressure_ground_station_ids_by_type", %{}),
      "resource_pressure_source_window_ids_by_type" =>
        Map.get(projection_summary, "resource_pressure_source_window_ids_by_type", %{}),
      "resource_pressure_station_calendar_entry_ids_by_type" =>
        Map.get(projection_summary, "resource_pressure_station_calendar_entry_ids_by_type", %{}),
      "resource_pressure_station_calendar_provider_ids_by_type" =>
        Map.get(
          projection_summary,
          "resource_pressure_station_calendar_provider_ids_by_type",
          %{}
        ),
      "resource_pressure_station_calendar_provider_entry_ids_by_type" =>
        Map.get(
          projection_summary,
          "resource_pressure_station_calendar_provider_entry_ids_by_type",
          %{}
        ),
      "storage_pressure_status_counts" =>
        pressure_count_map_matching(resource_pressure_status_counts, "storage"),
      "storage_pressure_type_counts" =>
        pressure_count_map_matching(resource_pressure_type_counts, "storage"),
      "downlink_pressure_status_counts" =>
        pressure_count_map_matching(resource_pressure_status_counts, "downlink"),
      "downlink_pressure_type_counts" =>
        pressure_count_map_matching(resource_pressure_type_counts, "downlink")
    }
  end

  def storage_pressure?(replay) do
    present?(replay["storage_pressure_status_counts"]) or
      present?(replay["storage_pressure_type_counts"])
  end

  def resource_activity_pressure?(replay) do
    present?(replay["resource_pressure_activity_id_counts"]) or
      present?(replay["resource_pressure_activity_ids_by_direction"])
  end

  def downlink_pressure?(replay) do
    downlink_shortfall_pressure?(replay) or
      Enum.any?(@downlink_pressure_fields, &present?(replay[&1]))
  end

  def downlink_shortfall_pressure?(replay) do
    replay["selected_shortfall_row_count"] + replay["actual_shortfall_row_count"] > 0 or
      Enum.any?(@downlink_shortfall_pressure_fields, &present?(replay[&1]))
  end

  defp pressure_count_map_matching(counts, token) when is_map(counts) do
    counts
    |> Enum.filter(fn {key, _value} -> String.contains?(to_string(key), token) end)
    |> Map.new()
  end

  defp pressure_count_map_matching(_counts, _token), do: %{}

  defp merge_count_maps(count_maps) do
    count_maps
    |> Enum.reject(&(&1 in [nil, %{}]))
    |> Enum.reduce(%{}, fn count_map, acc ->
      Enum.reduce(count_map, acc, fn {key, value}, acc ->
        Map.update(acc, key, value, fn
          current when is_integer(current) and is_integer(value) -> current + value
          current -> current
        end)
      end)
    end)
    |> non_empty_map()
  end

  defp summary_integer(%{} = summary, field) do
    case Map.get(summary, field) do
      value when is_integer(value) ->
        value

      value when is_float(value) ->
        trunc(value)

      value when is_binary(value) ->
        case Integer.parse(String.trim(value)) do
          {integer, ""} -> integer
          _parse -> 0
        end

      _value ->
        0
    end
  end

  defp summary_integer(_summary, _field), do: 0

  defp present?(value) when is_map(value), do: map_size(value) > 0
  defp present?(value) when is_list(value), do: value != []
  defp present?(nil), do: false
  defp present?(_value), do: true

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
