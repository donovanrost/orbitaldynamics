defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessRowGroups do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferImportReadinessRowNormalization,
    as: RowNormalization

  def row_ids_by_field(rows, row_field) do
    rows
    |> Enum.flat_map(fn row ->
      status = RowNormalization.normalized_token(Map.get(row, row_field))

      counteroffer_id =
        RowNormalization.stable_id_or_nil(Map.get(row, "provider_counteroffer_id"))

      if status in [nil, ""] or counteroffer_id in [nil, ""] do
        []
      else
        [{status, counteroffer_id}]
      end
    end)
    |> grouped_ids()
  end

  def count_rows(rows, field) do
    rows
    |> Enum.map(&RowNormalization.normalized_token(Map.get(&1, field)))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
    |> RowNormalization.non_empty_map()
  end

  defp grouped_ids(pairs) do
    pairs
    |> Enum.reject(fn {key, value} -> key in [nil, ""] or value in [nil, ""] end)
    |> Enum.group_by(fn {key, _value} -> to_string(key) end, fn {_key, value} -> value end)
    |> Map.new(fn {key, values} -> {key, sorted_non_empty_values(values)} end)
    |> RowNormalization.non_empty_map()
  end

  defp sorted_non_empty_values(values) do
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
