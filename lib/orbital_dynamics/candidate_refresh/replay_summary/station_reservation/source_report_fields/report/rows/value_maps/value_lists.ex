defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.Rows.ValueMaps.ValueLists do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.Rows.ValueMaps.Normalization

  def map_value_lists(%{} = value_map) do
    value_map
    |> Enum.map(fn {key, values} ->
      values =
        values
        |> List.wrap()
        |> sorted_string_values()

      {encode_value(key), values}
    end)
    |> Map.new()
    |> non_empty_map()
  end

  def map_value_lists(_value), do: nil

  def sorted_string_values(values) when is_list(values) do
    values
    |> Enum.map(&encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  def sorted_string_values(_values), do: []

  defp encode_value(value), do: Normalization.encode_value(value)

  defp non_empty_map(map), do: Normalization.non_empty_map(map)
end
