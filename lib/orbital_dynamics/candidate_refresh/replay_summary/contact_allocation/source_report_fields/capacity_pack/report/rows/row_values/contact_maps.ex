defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.CapacityPack.Report.Rows.RowValues.ContactMaps do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [numeric_report_count: 2]

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.CapacityPack.Report.Rows.RowValues.Normalization

  def id_map_counts(%{} = contact_ids_by_key) do
    contact_ids_by_key
    |> Enum.map(fn {key, contact_ids} ->
      {to_string(key), contact_ids |> List.wrap() |> sorted_non_empty_values()}
    end)
    |> Enum.reject(fn {key, contact_ids} -> key in [nil, ""] or contact_ids in [nil, []] end)
    |> Map.new(fn {key, contact_ids} -> {key, length(contact_ids)} end)
    |> non_empty_map()
  end

  def id_map_counts(_contact_ids_by_key), do: nil

  def grouped_contact_counts(pairs) do
    pairs
    |> Enum.reject(fn {key, contact_id} -> key in [nil, ""] or contact_id in [nil, ""] end)
    |> Enum.group_by(fn {key, _contact_id} -> key end, fn {_key, contact_id} -> contact_id end)
    |> Map.new(fn {key, contact_ids} ->
      {key, contact_ids |> sorted_non_empty_values() |> length()}
    end)
    |> non_empty_map()
  end

  def grouped_contact_ids(pairs) do
    pairs
    |> Enum.reject(fn {key, contact_id} -> key in [nil, ""] or contact_id in [nil, ""] end)
    |> Enum.group_by(fn {key, _contact_id} -> key end, fn {_key, contact_id} -> contact_id end)
    |> Map.new(fn {key, contact_ids} -> {key, sorted_non_empty_values(contact_ids)} end)
    |> non_empty_map()
  end

  def map_value_lists(%{} = value_map) do
    value_map
    |> Enum.map(fn {key, values} ->
      {to_string(key), values |> List.wrap() |> sorted_non_empty_values()}
    end)
    |> Enum.reject(fn {key, values} -> key in [nil, ""] or values in [nil, []] end)
    |> Map.new()
    |> non_empty_map()
  end

  def map_value_lists(_value), do: nil

  def fallback_contact_count(report) do
    contact_id_maps =
      [
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
      |> Enum.map(&Map.get(report, &1))
      |> Enum.filter(&is_map/1)

    case contact_id_maps do
      [] ->
        numeric_report_count(report, "capacity_pack_contact_count")

      maps ->
        maps
        |> Enum.flat_map(&map_contact_ids/1)
        |> Enum.reject(&(&1 in [nil, ""]))
        |> Enum.map(&to_string/1)
        |> Enum.uniq()
        |> length()
    end
  end

  def sorted_non_empty_values(values) do
    values
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      values -> values
    end
  end

  defp map_contact_ids(%{} = contact_ids_by_key) do
    contact_ids_by_key
    |> Map.values()
    |> Enum.flat_map(&List.wrap/1)
  end

  defp non_empty_map(map), do: Normalization.non_empty_map(map)
end
