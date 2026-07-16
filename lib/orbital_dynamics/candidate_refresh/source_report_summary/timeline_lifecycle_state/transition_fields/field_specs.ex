defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineLifecycleState.TransitionFields.FieldSpecs do
  @moduledoc false

  @transition_count_fields [
    "transition_decision_counts",
    "required_operator_action_counts",
    "import_action_counts",
    "planned_status_category_counts",
    "realized_status_category_counts",
    "planned_approval_category_counts",
    "realized_approval_category_counts",
    "status_transition_category_counts",
    "approval_transition_category_counts"
  ]

  def transition_count_fields, do: @transition_count_fields
end
