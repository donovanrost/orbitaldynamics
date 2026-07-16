defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalTimeline.IntegrityFields.RowIssues.Predicates.FieldSpecs do
  @moduledoc false

  @dependency_issue_fields ~w(
    missing_dependency_activity_ids
    missing_dependency_timeline_ids
    dependency_cycle_activity_ids
    dependency_cycle_timeline_ids
    dependency_order_violation_activity_ids
    dependency_order_violation_timeline_ids
  )
  @exclusivity_issue_fields ~w(
    exclusivity_violation_activity_ids
    exclusivity_violation_timeline_ids
    exclusivity_violation_group
  )
  @issue_fields @dependency_issue_fields ++ @exclusivity_issue_fields

  def dependency_issue_fields, do: @dependency_issue_fields
  def exclusivity_issue_fields, do: @exclusivity_issue_fields
  def issue_fields, do: @issue_fields
end
