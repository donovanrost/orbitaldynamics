defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.AggregateMaps.ListMaps.StringLists do
  @moduledoc false

  def merge(lists) do
    lists
    |> Enum.flat_map(&List.wrap/1)
    |> sorted_non_empty_strings()
  end

  defp sorted_non_empty_strings(values) do
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
