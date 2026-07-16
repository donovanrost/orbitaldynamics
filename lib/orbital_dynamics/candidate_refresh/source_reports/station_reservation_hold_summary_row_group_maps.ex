defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryRowGroupMaps do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryRowValues,
    only: [non_empty_map: 1, stringify_keys: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryRowGroupValues

  def contact_ids_by_values(rows, contact_id_fields, grouping_fields) do
    rows
    |> Enum.reduce(%{}, fn row, acc ->
      row = stringify_keys(row)

      contact_ids =
        StationReservationHoldSummaryRowGroupValues.contact_ids(row, contact_id_fields)

      group_values =
        StationReservationHoldSummaryRowGroupValues.group_values(row, grouping_fields)

      update_group_map(acc, group_values, contact_ids)
    end)
    |> non_empty_map()
  end

  def reservation_ids_by_values(rows, reservation_id_fields, grouping_fields) do
    rows
    |> Enum.reduce(%{}, fn row, acc ->
      row = stringify_keys(row)

      reservation_ids =
        StationReservationHoldSummaryRowGroupValues.reservation_ids(row, reservation_id_fields)

      group_values =
        StationReservationHoldSummaryRowGroupValues.group_values(row, grouping_fields)

      update_group_map(acc, group_values, reservation_ids)
    end)
    |> non_empty_map()
  end

  defp update_group_map(acc, _group_values, []), do: acc
  defp update_group_map(acc, [], _ids), do: acc

  defp update_group_map(acc, group_values, ids) do
    Enum.reduce(group_values, acc, fn group_value, acc ->
      Map.update(acc, group_value, ids, fn current ->
        (current ++ ids)
        |> Enum.uniq()
        |> Enum.sort()
      end)
    end)
  end
end
