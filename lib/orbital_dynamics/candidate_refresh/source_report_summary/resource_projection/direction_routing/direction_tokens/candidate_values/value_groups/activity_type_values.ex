defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting.DirectionTokens.CandidateValues.ValueGroups.ActivityTypeValues do
  @moduledoc false

  def values(row) do
    [
      row["first_resource_pressure_activity_type"],
      row["activity_type"],
      get_in(row, ["first_resource_pressure", "activity_type"]),
      get_in(row, ["source_activity", "activity_type"]),
      row["type"],
      get_in(row, ["source_activity", "type"])
    ]
  end
end
