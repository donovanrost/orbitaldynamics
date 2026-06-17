defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StorageDownlinkPressure.Summary.CapacityPack.ContactCount do
  @moduledoc false

  @contact_count_fields [
    "capacity_pack_contact_ids_by_ground_station_id",
    "capacity_pack_contact_ids_by_ground_station",
    "capacity_pack_contact_ids_by_direction",
    "capacity_pack_contact_ids_by_status",
    "capacity_pack_selected_contact_ids_by_ground_station_id",
    "capacity_pack_selected_contact_ids_by_ground_station",
    "capacity_pack_selected_contact_ids_by_direction",
    "capacity_pack_deferred_contact_ids_by_ground_station_id",
    "capacity_pack_deferred_contact_ids_by_ground_station",
    "capacity_pack_deferred_contact_ids_by_direction",
    "required_capacity_fraction_contact_ids_by_source"
  ]

  def count(summary) do
    case capacity_pack_contact_count(summary) do
      0 -> nil
      count -> count
    end
  end

  defp capacity_pack_contact_count(summary) do
    string_list_maps_unique_contact_count(
      summary,
      @contact_count_fields,
      "capacity_pack_contact_count"
    )
  end

  defp string_list_maps_unique_contact_count(summary, fields, fallback_field) do
    contact_id_maps =
      fields
      |> Enum.map(&Map.get(summary, &1))
      |> Enum.filter(&is_map/1)

    case contact_id_maps do
      [] ->
        numeric_report_count(summary, fallback_field)

      maps ->
        maps
        |> Enum.flat_map(&string_list_map_contact_ids/1)
        |> count_unique_contact_ids()
    end
  end

  defp string_list_map_contact_ids(%{} = contact_ids_by_group) do
    contact_ids_by_group
    |> Enum.flat_map(fn {_group, contact_ids} -> list_value(contact_ids) end)
  end

  defp string_list_map_contact_ids(_contact_ids_by_group), do: []

  defp count_unique_contact_ids(contact_ids) do
    contact_ids
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> length()
  end

  defp list_value(values) when is_list(values), do: values
  defp list_value(_values), do: []

  defp numeric_report_count(report, field), do: numeric_value(Map.get(report, field)) || 0

  defp numeric_value(value) when is_number(value), do: value * 1.0

  defp numeric_value(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _parse -> nil
    end
  end

  defp numeric_value(_value), do: nil
end
