defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryRowValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryRowCounts
  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationReservationHoldSummaryValueEncoding

  def row_values(row, fields) do
    fields
    |> Enum.flat_map(fn field ->
      row
      |> Map.get(field)
      |> List.wrap()
    end)
    |> Enum.map(&StationReservationHoldSummaryValueEncoding.encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
  end

  def count_source_report_rows(rows, field) do
    StationReservationHoldSummaryRowCounts.count_source_report_rows(rows, field)
  end

  def count_values(values) do
    StationReservationHoldSummaryRowCounts.count_values(values)
  end

  def normalize_number_list(nil), do: nil

  def normalize_number_list(values) when is_list(values) do
    values
    |> List.flatten()
    |> Enum.map(&StationReservationHoldSummaryValueEncoding.numeric_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      numbers -> numbers
    end
  end

  def normalize_number_list(value), do: normalize_number_list([value])

  def stable_id_or_nil(value),
    do: StationReservationHoldSummaryValueEncoding.stable_id_or_nil(value)

  def non_empty_map(map) when map_size(map) == 0, do: nil
  def non_empty_map(map), do: map

  def stringify_keys(value), do: StationReservationHoldSummaryValueEncoding.stringify_keys(value)
end
