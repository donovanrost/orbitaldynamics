defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionEmbeddedReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EmbeddedRowFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionEmbeddedReportFields
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionReviewRows

  def from_rows(path, source, rows, artifact) do
    EmbeddedRowFallbacks.from_rows(path, source, rows, artifact, &report_from_rows/4)
  end

  defp report_from_rows(path, source, rows, artifact) do
    row_groups = ResourceProjectionReviewRows.split_embedded_rows(rows)

    report =
      ResourceProjectionEmbeddedReportFields.report(source, rows, row_groups, artifact)

    {path, report}
  end
end
