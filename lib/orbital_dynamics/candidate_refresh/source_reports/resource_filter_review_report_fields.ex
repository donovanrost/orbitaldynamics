defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ResourceFilterReviewReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.{
    EmbeddedRowFallbacks,
    ResourceFilterReviewReportValues,
    ResourceFilterReviewRows
  }

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
    {suppressed_candidates, invalid_resource_summary_inputs} =
      ResourceFilterReviewRows.split_embedded_rows(rows)

    {path,
     ResourceFilterReviewReportValues.build(
       source,
       suppressed_candidates,
       invalid_resource_summary_inputs,
       artifact
     )}
  end
end
