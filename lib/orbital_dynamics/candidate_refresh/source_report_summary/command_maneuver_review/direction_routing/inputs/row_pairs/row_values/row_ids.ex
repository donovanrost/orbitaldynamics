defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.DirectionRouting.Inputs.RowPairs.RowValues.RowIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.StableIds

  def activity_id(row) do
    [
      row["activity_id"],
      row["source_activity_id"],
      get_in(row, ["activity_context", "activity_id"]),
      get_in(row, ["activity_context", "id"]),
      get_in(row, ["source_activity", "id"]),
      get_in(row, ["source_activity", "activity_id"])
    ]
    |> stable_id()
  end

  def window_id(row) do
    [
      row["command_window_id"],
      row["id"],
      get_in(row, ["activity_context", "command_window_id"]),
      get_in(row, ["source_activity_context", "command_window_id"]),
      get_in(row, ["source_activity", "command_window_id"]),
      get_in(row, ["source_activity", "activity_context", "command_window_id"])
    ]
    |> stable_id()
  end

  defp stable_id(values) do
    values
    |> Enum.map(&StableIds.stable_id_or_nil/1)
    |> Enum.find(&(&1 not in [nil, ""]))
  end
end
