defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.ReservationConflictFields.ValueMaps do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_nested_string_list_maps: 1,
      sorted_string_values: 1
    ]

  def string_list_map(summary, field) do
    summary
    |> Map.get(field)
    |> value_lists()
  end

  def nested_string_list_map_fields(summary, fields) do
    fields
    |> Enum.map(&Map.get(summary, &1))
    |> merge_nested_string_list_maps()
  end

  defp value_lists(%{} = value_map) do
    value_map
    |> Enum.reduce(%{}, fn {key, values}, acc ->
      case sorted_string_values(List.wrap(values)) do
        [] -> acc
        values -> Map.put(acc, to_string(key), values)
      end
    end)
    |> non_empty_map()
  end

  defp value_lists(_value), do: nil

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
