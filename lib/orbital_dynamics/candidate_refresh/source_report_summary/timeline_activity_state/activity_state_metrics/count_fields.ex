defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.ActivityStateMetrics.CountFields do
  @moduledoc false

  alias __MODULE__.ActivityIdentities
  alias __MODULE__.ValueCounts

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.ActivityStateMetrics.ActionRouting

  def fields(states) do
    %{
      "state_status_counts" => ValueCounts.field(states, "state_status"),
      "transition_decision_counts" => ValueCounts.field(states, "transition_decision"),
      "planned_status_category_counts" => ValueCounts.field(states, "planned_status_category"),
      "realized_status_category_counts" => ValueCounts.field(states, "realized_status_category"),
      "planned_approval_category_counts" =>
        ValueCounts.field(states, "planned_approval_category"),
      "realized_approval_category_counts" =>
        ValueCounts.field(states, "realized_approval_category"),
      "status_transition_category_counts" =>
        ValueCounts.nested(states, ["status_transition", "transition_category"]),
      "approval_transition_category_counts" =>
        ValueCounts.nested(states, ["approval_transition", "transition_category"]),
      "required_operator_action_counts" => ValueCounts.field(states, "required_operator_action"),
      "import_action_counts" => ValueCounts.field(states, "import_action"),
      "action_routing" => ActionRouting.fields(states)
    }
    |> Map.merge(ActivityIdentities.fields(states))
  end
end
