defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.CandidateGroups.GroupedIds.RouteSpecs.PairValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.CandidateGroups.RowValues

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.CandidatePairs,
    as: SharedCandidatePairs

  def suppressed_reason_pairs(report) do
    pairs(report, &RowValues.suppressed_reason/1)
  end

  def spacecraft_pairs(report) do
    pairs(report, &RowValues.spacecraft_id/1)
  end

  def resource_pairs(report) do
    pairs(report, &RowValues.resource_id/1)
  end

  def blocking_dimension_pairs(report) do
    pairs(report, &RowValues.blocking_dimension/1)
  end

  defp pairs(report, value_fun) do
    report
    |> RowValues.rows()
    |> SharedCandidatePairs.pairs(value_fun)
  end
end
