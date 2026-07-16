defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineLifecycleState.RowFields.ReviewRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineLifecycleState.RowFields.PressureFields
  alias __MODULE__.TimelineIdGroups

  def fields(review_rows) do
    %{
      "review_required_count" => length(review_rows),
      "review_activity_ids" =>
        review_rows
        |> Enum.flat_map(&PressureFields.activity_ids/1)
        |> PressureFields.sorted_values(),
      "review_timeline_ids" => PressureFields.timeline_ids(review_rows, fn _row -> true end),
      "review_timeline_ids_by_required_operator_action" =>
        TimelineIdGroups.by_required_operator_action(review_rows),
      "review_timeline_ids_by_status_transition_category" =>
        TimelineIdGroups.by_status_transition_category(review_rows),
      "review_timeline_ids_by_approval_transition_category" =>
        TimelineIdGroups.by_approval_transition_category(review_rows)
    }
  end
end
