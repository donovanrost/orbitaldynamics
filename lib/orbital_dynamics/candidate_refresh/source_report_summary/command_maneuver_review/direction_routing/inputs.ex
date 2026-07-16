defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.DirectionRouting.Inputs do
  @moduledoc false

  alias __MODULE__.RowPairs

  def direction_counts(report), do: RowPairs.direction_counts(report)

  def activity_ids_by_direction(report), do: RowPairs.activity_ids_by_direction(report)

  def window_ids_by_direction(report), do: RowPairs.window_ids_by_direction(report)
end
