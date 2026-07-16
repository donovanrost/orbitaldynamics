defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.IntegrityFields.IssueFields.IssueTypes.Classification do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NormalizedToken

  @dependency_issue_types MapSet.new([
                            "missing_dependency_activity",
                            "missing_dependency_timeline",
                            "self_dependency_activity",
                            "self_dependency_timeline",
                            "duplicate_dependency_activity",
                            "duplicate_dependency_timeline",
                            "dependency_cycle",
                            "dependency_order_violation"
                          ])

  @exclusivity_issue_types MapSet.new([
                             "duplicate_exclusivity_activity",
                             "duplicate_exclusivity_timeline",
                             "exclusivity_overlap",
                             "exclusivity_group_overlap"
                           ])

  def dependency?(issue_type) do
    MapSet.member?(@dependency_issue_types, NormalizedToken.value(issue_type))
  end

  def exclusivity?(issue_type) do
    MapSet.member?(@exclusivity_issue_types, NormalizedToken.value(issue_type))
  end
end
