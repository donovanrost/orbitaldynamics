defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Report.Rows.ValueMaps.ByValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Report.Rows.ValueMaps.Normalization

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Report.Rows.ValueMaps.RowValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sorted_string_values: 1]

  @contact_id_fields ["contact_id", "source_contact_id", "candidate_id"]

  def contact_ids_by_values(rows, grouping_fields) do
    ids_by_values(rows, group_values_fun(grouping_fields), fn row ->
      row
      |> row_values(@contact_id_fields)
      |> sorted_string_values()
    end)
  end

  def entry_ids_by_values(rows, grouping_fields) do
    ids_by_values(rows, group_values_fun(grouping_fields), &RowValues.row_entry_ids/1)
  end

  def reservation_ids_by_values(rows, grouping_fields) do
    ids_by_values(rows, group_values_fun(grouping_fields), &RowValues.row_reservation_ids/1)
  end

  def ids_by_reserved_by(rows, id_fun) do
    ids_by_values(rows, &RowValues.row_reserved_by_values/1, id_fun)
  end

  defp ids_by_values(rows, value_fun, id_fun) do
    rows
    |> Enum.reduce(%{}, fn row, acc ->
      row = stringify_keys(row)
      ids = id_fun.(row)
      values = value_fun.(row)

      if ids == [] or values == [] do
        acc
      else
        merge_ids_by_values(acc, values, ids)
      end
    end)
    |> non_empty_map()
  end

  defp group_values_fun(grouping_fields) do
    fn row -> group_values(row, grouping_fields) end
  end

  defp group_values(row, grouping_fields) do
    row
    |> row_values(grouping_fields)
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp merge_ids_by_values(acc, group_values, ids) do
    Enum.reduce(group_values, acc, fn group_value, acc ->
      Map.update(acc, group_value, ids, fn current ->
        (current ++ ids)
        |> Enum.uniq()
        |> Enum.sort()
      end)
    end)
  end

  defp row_values(row, fields) do
    fields
    |> Enum.flat_map(fn field ->
      row
      |> Map.get(field)
      |> List.wrap()
    end)
    |> Enum.map(&encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
  end

  defp stable_id_or_nil(value), do: Normalization.stable_id_or_nil(value)

  defp stringify_keys(value), do: Normalization.stringify_keys(value)

  defp encode_value(value), do: Normalization.encode_value(value)

  defp non_empty_map(value), do: Normalization.non_empty_map(value)
end
