defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffReviewImportReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EmbeddedRowFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffReviewImportReportValues

  def report_from_embedded_rows(path, source, rows, artifact) do
    EmbeddedRowFallbacks.report_from_embedded_rows(
      path,
      source,
      rows,
      artifact,
      &report_from_rows/4
    )
  end

  defp report_from_rows(path, source, rows, artifact) do
    {path, TimelineDiffReviewImportReportValues.build(source, rows, artifact)}
  end
end
