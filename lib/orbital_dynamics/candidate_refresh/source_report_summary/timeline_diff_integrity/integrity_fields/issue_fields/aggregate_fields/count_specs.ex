defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.IntegrityFields.IssueFields.AggregateFields.CountSpecs do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.IntegrityFields.IssueFields.IssueTypes.Classification

  def total_issue_field, do: "timeline_integrity_issue_count"

  def issue_type_counts_field, do: "timeline_integrity_issue_type_counts"

  def dependency_field, do: "dependency_issue_count"

  def dependency, do: {dependency_field(), &Classification.dependency?/1}

  def exclusivity_field, do: "exclusivity_issue_count"

  def exclusivity, do: {exclusivity_field(), &Classification.exclusivity?/1}
end
