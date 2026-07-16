defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.RequirementStatusReport.Rows.StatusPairs.LineagePairs.SourceWindowPairs.SourceWindowIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.RequirementStatusReport.Rows.StatusPairs.Normalization

  def row_source_window_ids(row) do
    [
      row["source_window_id"],
      row["source_window_ids"],
      get_in(row, ["source_window", "id"]),
      get_in(row, ["activity_context", "source_window_id"])
    ]
    |> List.flatten()
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp stable_id_or_nil(value), do: Normalization.stable_id_or_nil(value)
end
