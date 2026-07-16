defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffReviewImportContexts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffReviewImportContextRows
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffReviewImportEmbeddedPaths

  def operator_review_context(path, %{} = package) do
    rows = TimelineDiffReviewImportContextRows.operator_review_rows(package)

    {embedded_path, embedded_source} =
      TimelineDiffReviewImportEmbeddedPaths.operator_review(path, rows)

    {embedded_path, embedded_source, rows}
  end

  def cadence_import_context(path, %{} = manifest) do
    rows = TimelineDiffReviewImportContextRows.cadence_import_rows(manifest)

    {embedded_path, embedded_source} =
      TimelineDiffReviewImportEmbeddedPaths.cadence_import(path, rows)

    {embedded_path, embedded_source, rows}
  end
end
