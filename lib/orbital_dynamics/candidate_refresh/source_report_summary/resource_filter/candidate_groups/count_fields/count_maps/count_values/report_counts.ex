defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.CandidateGroups.CountFields.CountMaps.CountValues.ReportCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.CandidateGroups.RowValues

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.CandidateGroups.CountFields.CountMaps.CountValues.RowCounts

  def suppressed_reason_counts(report) do
    case RowCounts.by_field(report, "suppressed_reason") do
      nil -> %{}
      counts -> counts
    end
  end

  def spacecraft_counts(report) do
    RowCounts.by(report, &RowValues.spacecraft_id/1)
  end

  def resource_counts(report) do
    RowCounts.by(report, &RowValues.resource_id/1)
  end

  def blocking_dimension_counts(report) do
    RowCounts.by_field(report, "resource_blocking_dimension")
  end
end
