defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.DirectionReport.Rows.DirectionPairs.RowDirection do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.DirectionReport.Rows.DirectionPairs.Normalization

  def row_direction(row) do
    [
      row["direction"],
      get_in(row, ["activity_context", "direction"]),
      row["type"],
      row["activity_type"],
      get_in(row, ["activity_context", "type"]),
      get_in(row, ["activity_context", "activity_type"])
    ]
    |> Enum.map(&normalize_direction/1)
    |> Enum.find(&(&1 not in [nil, ""]))
  end

  defp normalize_direction(direction), do: Normalization.normalize_direction(direction)
end
