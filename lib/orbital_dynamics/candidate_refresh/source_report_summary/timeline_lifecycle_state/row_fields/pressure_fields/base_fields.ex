defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineLifecycleState.RowFields.PressureFields.BaseFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineLifecycleState.RowFields.PressureFields.RowCounts

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineLifecycleState.RowFields.PressureFields.RowValues

  def fields(rows) do
    %{
      "row_count" => length(rows),
      "recordable_count" => RowCounts.decision_count(rows, "record"),
      "preserved_count" => RowCounts.decision_count(rows, "none"),
      "duplicate_timeline_identity_count" =>
        Enum.count(rows, &(&1["timeline_identity_collision"] == true)),
      "transition_decision_counts" => RowCounts.field_counts(rows, "transition_decision"),
      "required_operator_action_counts" =>
        RowCounts.field_counts(rows, "required_operator_action"),
      "import_action_counts" => RowCounts.field_counts(rows, "import_action"),
      "planned_status_category_counts" => RowCounts.field_counts(rows, "planned_status_category"),
      "realized_status_category_counts" =>
        RowCounts.field_counts(rows, "realized_status_category"),
      "planned_approval_category_counts" =>
        RowCounts.field_counts(rows, "planned_approval_category"),
      "realized_approval_category_counts" =>
        RowCounts.field_counts(rows, "realized_approval_category"),
      "status_transition_category_counts" =>
        RowCounts.nested_counts(rows, ["status_transition", "transition_category"]),
      "approval_transition_category_counts" =>
        RowCounts.nested_counts(rows, ["approval_transition", "transition_category"]),
      "recordable_timeline_ids" => timeline_ids(rows, &(&1["transition_decision"] == "record")),
      "preserved_timeline_ids" => timeline_ids(rows, &(&1["transition_decision"] == "none"))
    }
  end

  defp timeline_ids(rows, predicate), do: RowValues.timeline_ids(rows, predicate)
end
