defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.DirectionRouting.CandidateDirections.ReportValues.GroupedDirectionCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NumericValue

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.DirectionRouting.CandidateDirections.DirectionValues

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.ValueMaps,
    as: ResourceValueMaps

  def from_map(%{} = counts) do
    counts
    |> Enum.reduce(%{}, fn {direction, count}, acc ->
      case {DirectionValues.normalize(direction), NumericValue.value(count)} do
        {nil, _count} -> acc
        {_direction, nil} -> acc
        {direction, count} -> Map.update(acc, direction, trunc(count), &(&1 + trunc(count)))
      end
    end)
    |> ResourceValueMaps.non_empty_map()
  end

  def from_map(_counts), do: nil
end
