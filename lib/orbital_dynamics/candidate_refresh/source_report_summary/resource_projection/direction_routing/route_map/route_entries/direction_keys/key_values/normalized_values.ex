defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting.RouteMap.RouteEntries.DirectionKeys.KeyValues.NormalizedValues do
  @moduledoc false

  def non_empty_sorted(values) do
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
end
