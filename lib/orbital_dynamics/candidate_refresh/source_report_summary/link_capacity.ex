defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.InputSummary
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity.SourceFields

  def report_input_summary([]), do: nil

  def report_input_summary(sources), do: InputSummary.report_input_summary(sources)

  def source_link_capacity_report_trust_boundaries(report),
    do: SourceFields.trust_boundaries(report)
end
