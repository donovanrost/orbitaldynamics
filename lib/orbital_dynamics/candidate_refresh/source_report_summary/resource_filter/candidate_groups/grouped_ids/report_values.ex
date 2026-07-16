defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.CandidateGroups.GroupedIds.ReportValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.ValueMaps

  def by_pairs_or_fallback(report, pairs_fun, fallback_fields) do
    case pairs_fun.(report) do
      [] -> fallback_values(report, fallback_fields)
      pairs -> from_pairs(pairs)
    end
  end

  defp fallback_values(report, fields) do
    fields
    |> Enum.find_value(&Map.get(report, &1))
    |> ValueMaps.map_value_lists()
  end

  defp from_pairs(pairs) do
    pairs
    |> Enum.reject(fn {key, value} -> key in [nil, ""] or value in [nil, ""] end)
    |> Enum.group_by(fn {key, _value} -> to_string(key) end, fn {_key, value} -> value end)
    |> Map.new(fn {key, values} -> {key, ValueMaps.sorted_non_empty_strings(values)} end)
    |> ValueMaps.non_empty_map()
  end
end
