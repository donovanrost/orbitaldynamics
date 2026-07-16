defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDependencyImpact.CountFields.RowCounts do
  @moduledoc false

  alias __MODULE__.ReportValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_count_maps: 1]

  def count_map(reports, count_fun) do
    reports
    |> Enum.map(count_fun)
    |> merge_count_maps()
  end

  def row_count(report, top_level_field) do
    ReportValues.row_count(report, top_level_field)
  end

  def scope_count(report, top_level_field, scope) do
    ReportValues.scope_count(report, top_level_field, scope)
  end

  def row_counts(report, top_level_field, row_field) do
    ReportValues.row_counts(report, top_level_field, row_field)
  end
end
