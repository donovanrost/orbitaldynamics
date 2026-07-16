defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.DirectionRouting.Inputs.RowPairs do
  @moduledoc false

  alias __MODULE__.Values

  def direction_counts(report), do: Values.direction_counts(report)

  def activity_ids_by_direction(report), do: Values.activity_ids_by_direction(report)

  def window_ids_by_direction(report), do: Values.window_ids_by_direction(report)
end
