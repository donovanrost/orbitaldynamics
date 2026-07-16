defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ModelAcceptance.CountFields.CompactCounts.ModelIdMaps.MapCounts do
  @moduledoc false

  def count(model_id_map) do
    model_id_map
    |> Enum.flat_map(fn {_key, values} -> list_value(values) end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> length()
  end

  def group_count(model_id_map, group) do
    model_id_map
    |> Map.get(group, [])
    |> list_value()
    |> length()
  end

  def group_count_map(model_id_map) do
    model_id_map
    |> Enum.map(fn {key, values} ->
      {to_string(key), values |> list_value() |> length()}
    end)
    |> Enum.reject(fn {_key, count} -> count == 0 end)
    |> Map.new()
  end

  defp list_value(values) when is_list(values), do: values
  defp list_value(_values), do: []
end
