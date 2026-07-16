defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.Rows.ValueMaps.ByValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.Rows.RowValues

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.Rows.ValueMaps.Normalization

  @contact_id_fields ["contact_id", "source_contact_id", "candidate_id"]

  @reservation_id_fields [
    "station_reservation_id",
    "station_calendar_reservation_ids",
    "reservation_id",
    "reservation_ids"
  ]

  def contact_ids_by_values(rows, grouping_fields) do
    rows
    |> Enum.reduce(%{}, fn row, acc ->
      row = RowValues.stringify_keys(row)

      contact_ids =
        row
        |> RowValues.row_values(@contact_id_fields)
        |> sorted_string_values()

      group_values = group_values(row, grouping_fields)

      if contact_ids == [] or group_values == [] do
        acc
      else
        merge_ids_by_values(acc, group_values, contact_ids)
      end
    end)
    |> non_empty_map()
  end

  def ids_by_values(rows, grouping_fields) do
    rows
    |> Enum.reduce(%{}, fn row, acc ->
      row = RowValues.stringify_keys(row)

      reservation_ids =
        row
        |> RowValues.row_values(@reservation_id_fields)
        |> Enum.map(&RowValues.stable_id_or_nil/1)
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq()
        |> Enum.sort()

      group_values = group_values(row, grouping_fields)

      if reservation_ids == [] or group_values == [] do
        acc
      else
        merge_ids_by_values(acc, group_values, reservation_ids)
      end
    end)
    |> non_empty_map()
  end

  defp group_values(row, grouping_fields) do
    row
    |> RowValues.row_values(grouping_fields)
    |> Enum.map(&RowValues.stable_id_or_nil/1)
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

  defp sorted_string_values(values) when is_list(values) do
    values
    |> Enum.map(&Normalization.encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp sorted_string_values(_values), do: []

  defp non_empty_map(map), do: Normalization.non_empty_map(map)
end
