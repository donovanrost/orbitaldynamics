defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.ChangeCounts.RowCounts.ObjectiveCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.ChangeCounts.RowCounts.Rows

  alias OrbitalDynamics.CandidateRefresh.SourceObjectives.TimelineDiff,
    as: TimelineDiffSourceObjectives

  def removed_observation_count(report) do
    Rows.count(report, &TimelineDiffSourceObjectives.removed_observation_objective_row?/1)
  end

  def changed_observation_count(report) do
    Rows.count(report, &TimelineDiffSourceObjectives.changed_observation_objective_row?/1)
  end
end
