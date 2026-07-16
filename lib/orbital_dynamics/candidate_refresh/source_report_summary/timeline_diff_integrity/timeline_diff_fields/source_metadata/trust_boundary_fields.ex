defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.SourceMetadata.TrustBoundaryFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback

  def status(reports_or_report) do
    reports_or_report
    |> values()
    |> status_from_values()
  end

  def values(reports_or_report) do
    OperationalFeedback.source_timeline_diff_trust_boundaries(reports_or_report)
  end

  def status_from_values([]), do: "missing"
  def status_from_values(_trust_boundaries), do: "declared"
end
