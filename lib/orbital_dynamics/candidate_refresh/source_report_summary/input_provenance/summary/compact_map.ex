defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.InputProvenance.Summary.CompactMap do
  @moduledoc false

  def compact(map) do
    map
    |> Enum.reject(fn {_key, value} -> value in [nil, %{}] end)
    |> Map.new()
    |> non_empty_map()
  end

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
