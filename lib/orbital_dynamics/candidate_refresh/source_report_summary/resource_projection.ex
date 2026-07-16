defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.InputSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.InvalidInputs
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.TrustBoundaries

  def report_input_summary([]), do: nil

  def report_input_summary(sources), do: InputSummary.report_input_summary(sources)

  def resource_projection_report_invalid_activity_input_count(report),
    do: InvalidInputs.invalid_activity_input_count(report)

  def resource_projection_report_invalid_resource_summary_input_count(report),
    do: InvalidInputs.invalid_resource_summary_input_count(report)

  def resource_projection_spacecraft_id(row), do: RowIdentities.spacecraft_id(row)

  def source_resource_projection_report_trust_boundaries(reports),
    do: TrustBoundaries.values(reports)
end
