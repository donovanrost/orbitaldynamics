defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationReservation.DirectionRouting.RouteMap.Inputs.ValueListMaps do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def from(%{} = value_map) do
    value_map
    |> Enum.map(&entry/1)
    |> Map.new()
    |> non_empty_map()
  end

  def from(_value), do: nil

  defp entry({key, values}) do
    {EncodedValue.value(key), value_list(values)}
  end

  defp value_list(values) do
    values
    |> List.wrap()
    |> Enum.map(&EncodedValue.value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
