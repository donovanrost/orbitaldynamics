defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.DirectionRouting.RouteMap.RouteEntries.RouteFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  def fields(direction, inputs) do
    %{
      "activity_count" => Map.get(inputs.direction_counts, direction),
      "activity_ids" => Map.get(inputs.activity_ids_by_direction, direction, []),
      "window_ids" => Map.get(inputs.window_ids_by_direction, direction, [])
    }
    |> compact_map()
  end
end
