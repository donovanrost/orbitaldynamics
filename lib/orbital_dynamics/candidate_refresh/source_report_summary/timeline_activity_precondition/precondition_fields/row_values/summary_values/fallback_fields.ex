defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityPrecondition.PreconditionFields.RowValues.SummaryValues.FallbackFields do
  @moduledoc false

  def type_status("blocked_precondition_types"), do: "blocked"
  def type_status("review_precondition_types"), do: "review_required"

  def count_field("blocked"), do: "blocked_precondition_count"
  def count_field("review_required"), do: "review_precondition_count"
end
