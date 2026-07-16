defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.Rows.ValueMaps.Normalization do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ValueEncoding

  def normalize_number_list(nil), do: nil

  def normalize_number_list(values) when is_list(values) do
    values
    |> List.flatten()
    |> Enum.map(&numeric_value/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      numbers -> numbers
    end
  end

  def normalize_number_list(value), do: normalize_number_list([value])

  def report_count(value) do
    case numeric_value(value) do
      value when is_number(value) and value > 0 -> ceil(value)
      _value -> 0
    end
  end

  def numeric_report_count(report, field), do: numeric_value(Map.get(report, field)) || 0

  def numeric_value(value), do: ValueEncoding.numeric_value(value)

  def encode_value(value), do: ValueEncoding.encode_value(value)

  def non_empty_map(map) when map_size(map) == 0, do: nil
  def non_empty_map(map), do: map
end
