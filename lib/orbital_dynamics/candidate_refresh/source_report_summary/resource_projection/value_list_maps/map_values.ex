defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.ValueListMaps.MapValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sorted_string_values: 1]

  def from_value_map(value_map) do
    Enum.reduce(value_map, %{}, fn {key, values}, acc ->
      case sorted_string_values(List.wrap(values)) do
        [] -> acc
        values -> Map.put(acc, to_string(key), values)
      end
    end)
  end
end
