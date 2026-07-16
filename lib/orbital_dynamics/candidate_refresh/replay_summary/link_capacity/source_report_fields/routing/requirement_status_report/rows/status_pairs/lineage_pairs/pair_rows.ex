defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.RequirementStatusReport.Rows.StatusPairs.LineagePairs.PairRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.RequirementStatusReport.Rows.StatusPairs.Normalization

  def requirement_status_lineage_pairs(row, selected_id_fun, actual_throughput_id_fun) do
    row = stringify_keys(row)

    [
      {row["downlink_requirement_status"], selected_id_fun.(row)},
      {row["actual_downlink_requirement_status"], actual_throughput_id_fun.(row)}
    ]
    |> Enum.flat_map(fn {status, ids} ->
      status = normalized_token(status)

      ids
      |> List.wrap()
      |> Enum.map(&{status, &1})
    end)
    |> Enum.reject(fn {status, id} -> status in [nil, ""] or id in [nil, ""] end)
    |> Enum.uniq()
  end

  defp normalized_token(value), do: Normalization.normalized_token(value)
  defp stringify_keys(value), do: Normalization.stringify_keys(value)
end
