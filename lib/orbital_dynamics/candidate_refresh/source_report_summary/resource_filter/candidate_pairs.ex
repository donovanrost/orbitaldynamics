defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.CandidatePairs do
  @moduledoc false

  alias __MODULE__.CandidateIds
  alias __MODULE__.SourceContacts

  def pairs(rows, value_fun) do
    rows
    |> Enum.flat_map(&row_pairs(&1, value_fun))
  end

  defp row_pairs(row, value_fun) do
    row_value = value_fun.(row)
    row_candidate_id = CandidateIds.from_row(row)

    row
    |> SourceContacts.from_row()
    |> Kernel.++([row])
    |> Enum.map(fn candidate ->
      {value_fun.(candidate) || row_value, CandidateIds.from_row(candidate) || row_candidate_id}
    end)
    |> valid_pairs()
  end

  defp valid_pairs(pairs) do
    pairs
    |> Enum.reject(fn {key, candidate_id} ->
      key in [nil, ""] or candidate_id in [nil, ""]
    end)
    |> Enum.uniq()
  end
end
