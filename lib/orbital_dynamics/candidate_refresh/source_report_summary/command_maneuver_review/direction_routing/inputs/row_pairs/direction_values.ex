defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.DirectionRouting.Inputs.RowPairs.DirectionValues do
  @moduledoc false

  alias __MODULE__.DirectionAliases

  def from_row(row) do
    [
      row["direction"],
      type_direction(row["window_type"]),
      row["activity_type"],
      row["type"],
      get_in(row, ["activity_context", "direction"]),
      get_in(row, ["source_activity", "direction"]),
      get_in(row, ["source_activity", "activity_context", "direction"])
    ]
    |> Enum.map(&normalize/1)
    |> Enum.find(&(&1 not in [nil, "", "contact"]))
  end

  def normalize(direction), do: DirectionAliases.normalize(direction)

  defp type_direction("command_window"), do: "command"
  defp type_direction("uplink_window"), do: "uplink"
  defp type_direction("tracking_window"), do: "tracking"
  defp type_direction("health_check_window"), do: "health_check"
  defp type_direction(_window_type), do: nil
end
