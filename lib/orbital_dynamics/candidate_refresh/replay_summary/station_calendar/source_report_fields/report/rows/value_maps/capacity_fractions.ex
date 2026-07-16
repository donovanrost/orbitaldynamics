defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Report.Rows.ValueMaps.CapacityFractions do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Report.Rows.ValueMaps.Normalization

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationCalendar.SourceReportFields.Report.Rows.ValueMaps.RowValues

  def capacity_fractions_by_values(rows, grouping_fields) do
    rows
    |> Enum.reduce(%{}, fn row, acc ->
      row = stringify_keys(row)
      capacity_fractions = RowValues.row_capacity_fractions(row)
      group_values = group_values(row, grouping_fields)

      if capacity_fractions == [] or group_values == [] do
        acc
      else
        merge_capacity_fractions_by_values(acc, group_values, capacity_fractions)
      end
    end)
    |> non_empty_map()
  end

  defp group_values(row, grouping_fields) do
    row
    |> row_values(grouping_fields)
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp merge_capacity_fractions_by_values(acc, group_values, capacity_fractions) do
    Enum.reduce(group_values, acc, fn group_value, acc ->
      Map.update(acc, group_value, capacity_fractions, fn current ->
        (current ++ capacity_fractions)
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
