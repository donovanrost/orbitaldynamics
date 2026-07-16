defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.CapacityPack.Report.Rows.RowValues do
  @moduledoc false

  alias __MODULE__.ContactMaps
  alias __MODULE__.Normalization

  def contact_status_row_counts(report) do
    report
    |> rows_for_summary()
    |> Enum.flat_map(fn row ->
      contact_id = summary_contact_id(row)
      status = normalized_token(row["capacity_pack_status"])

      if contact_id in [nil, ""] or status in [nil, ""] do
        []
      else
        [{status, contact_id}]
      end
    end)
    |> grouped_contact_counts()
  end

  def reduced_groups(report) do
    report
    |> Map.get("reduced_capacity_pack_groups", [])
    |> List.wrap()
    |> Enum.filter(&is_map/1)
    |> Enum.map(&stringify_keys/1)
  end

  def pack_group_id(group) do
    stable_id_or_nil(group["contention_group_id"]) ||
      stable_id_or_nil(group["capacity_pack_group_id"]) ||
      stable_id_or_nil(group["pack_group_id"])
  end

  def group_ids_by_status_from_groups(groups) do
    groups
    |> Enum.map(fn group ->
      {capacity_pack_group_key(group, "pack_status"), pack_group_id(group)}
    end)
    |> grouped_contact_ids()
  end

  def capacity_pack_group_key(row, "pack_status"), do: normalized_token(row["pack_status"])
  def capacity_pack_group_key(row, "direction"), do: summary_direction(row)

  def capacity_pack_group_key(row, field) do
    stable_id_or_nil(row[field]) || normalized_token(row[field])
  end

  def packed_row?(row),
    do:
      normalized_token(row["capacity_pack_status"]) == "selected_by_reduced_station_capacity_pack"

  def deferred_row?(row),
    do:
      normalized_token(row["capacity_pack_status"]) == "deferred_by_reduced_station_capacity_pack"

  def selected_capacity_pack_row?(row) do
    normalized_token(row["capacity_pack_status"]) in [
      "selected_by_contention_resolution",
      "selected_by_reduced_station_capacity_pack"
    ]
  end

  def rows_for_summary(report) do
    report
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
  end

  def capacity_pack_rows(report) do
    report
    |> rows_for_summary()
    |> Enum.filter(fn row ->
      normalized_token(row["capacity_pack_status"]) not in [nil, ""] and
        is_number(numeric_value(row["required_capacity_fraction"]))
    end)
  end

  def summary_contact_id(row) do
    stable_id_or_nil(row["contact_id"]) ||
      stable_id_or_nil(row["id"]) ||
      stable_id_or_nil(get_in(row, ["activity_context", "activity_id"]))
  end

  defdelegate id_map_counts(contact_ids_by_key), to: ContactMaps
  defdelegate grouped_contact_counts(pairs), to: ContactMaps
  defdelegate grouped_contact_ids(pairs), to: ContactMaps
  defdelegate map_value_lists(value), to: ContactMaps
  defdelegate fallback_contact_count(report), to: ContactMaps
  defdelegate sorted_non_empty_values(values), to: ContactMaps

  def explicit_count_map(report, field) do
    case Map.get(report, field) do
      counts when is_map(counts) -> counts
      _counts -> nil
    end
  end

  def numeric_map(%{} = numeric_map) do
    numeric_map
    |> Enum.reduce(%{}, fn {key, value}, totals ->
      case numeric_value(value) do
        value when is_number(value) -> Map.put(totals, to_string(key), value)
        _value -> totals
      end
    end)
    |> non_empty_map()
  end

  def numeric_map(_value), do: nil

  def numeric_value(value), do: Normalization.numeric_value(value)

  def non_empty_map(map), do: Normalization.non_empty_map(map)

  defp summary_direction(row) do
    [
      row["direction"],
      get_in(row, ["activity_context", "direction"]),
      get_in(row, ["source_contact_candidate", "direction"]),
      get_in(row, ["source_contact_candidate", "activity_context", "direction"]),
      get_in(row, ["source_contention_recommendation", "direction"]),
      row["type"],
      get_in(row, ["source_contact_candidate", "type"])
    ]
    |> Enum.map(&normalize_direction/1)
    |> Enum.find(&(&1 not in [nil, ""]))
  end

  defp normalized_token(value), do: Normalization.normalized_token(value)
  defp normalize_direction(direction), do: Normalization.normalize_direction(direction)
  defp stable_id_or_nil(value), do: Normalization.stable_id_or_nil(value)
  defp stringify_keys(value), do: Normalization.stringify_keys(value)
end
