defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineLifecycleState.ReviewFields.RouteMap.Inputs.ActionInputs do
  @moduledoc false

  alias __MODULE__.Values

  def action_counts(summaries), do: Values.action_counts(summaries)

  def timeline_ids_by_action(summaries), do: Values.timeline_ids_by_action(summaries)

  def rows_by_action(summaries), do: Values.rows_by_action(summaries)
end
