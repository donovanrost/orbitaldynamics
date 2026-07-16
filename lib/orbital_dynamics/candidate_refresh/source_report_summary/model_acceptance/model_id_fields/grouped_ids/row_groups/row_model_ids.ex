defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ModelAcceptance.ModelIdFields.GroupedIds.RowGroups.RowModelIds do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def grouped_ids(rows, group_fun) do
    rows
    |> Enum.group_by(
      &to_string(group_fun.(&1)),
      &(Map.get(&1, "model_id") || Map.get(&1, "id"))
    )
    |> Map.new(fn {key, values} ->
      {key, normalized_ids(values)}
    end)
    |> compact_map()
    |> case do
      nil -> %{}
      model_id_map -> model_id_map
    end
  end

  defp normalized_ids(values) do
    values
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
  end
end
