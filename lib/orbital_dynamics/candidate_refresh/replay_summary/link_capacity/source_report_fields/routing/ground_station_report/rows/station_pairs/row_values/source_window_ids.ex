defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.GroundStationReport.Rows.StationPairs.RowValues.SourceWindowIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.GroundStationReport.Rows.StationPairs.Normalization

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.GroundStationReport.Rows.StationPairs.RowValues.SourceContacts.SourceWindowIds,
    as: SourceContactWindowIds

  def source_window_ids(row) do
    [
      row_source_window_ids(row),
      SourceContactWindowIds.source_contact_window_ids(row)
    ]
    |> List.flatten()
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      source_window_ids -> source_window_ids
    end
  end

  defp row_source_window_ids(row) do
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
