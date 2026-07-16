defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.DirectionRouting.RouteMap do
  @moduledoc false

  alias __MODULE__.RouteEntries

  def build(direction_counts, activity_ids_by_direction, window_ids_by_direction) do
    RouteEntries.build(direction_counts, activity_ids_by_direction, window_ids_by_direction)
  end
end
