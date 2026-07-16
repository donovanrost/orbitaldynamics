defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting.DirectionTokens.CandidateValues.ValueGroups do
  @moduledoc false

  alias __MODULE__.ActivityTypeValues

  def values(row), do: direction_values(row) ++ ActivityTypeValues.values(row)

  defp direction_values(row) do
    [
      row["first_resource_pressure_direction"],
      row["direction"],
      get_in(row, ["first_resource_pressure", "direction"]),
      get_in(row, ["activity_context", "direction"]),
      get_in(row, ["source_activity", "direction"]),
      get_in(row, ["source_activity", "activity_context", "direction"])
    ]
  end
end
