defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.BaseFields
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.InputSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.PreservedSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.TrustBoundaries

  def report_input_summary([]), do: nil

  defdelegate report_input_summary(sources), to: InputSummary

  defdelegate report_from_summary(summary), to: PreservedSummary

  def invalid_resource_summary_input_count(report) do
    BaseFields.invalid_resource_summary_input_count(report)
  end

  def source_resource_filter_report_trust_boundaries(report_or_reports),
    do: TrustBoundaries.values(report_or_reports)
end
