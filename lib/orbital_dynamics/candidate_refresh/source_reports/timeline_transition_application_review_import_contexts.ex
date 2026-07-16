defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationReviewImportContexts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationReviewImportContextValues

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationReviewImportContextRows

  def operator_review_context(path, %{} = package) do
    review_rows =
      TimelineTransitionApplicationReviewImportContextRows.operator_review_rows(package)

    TimelineTransitionApplicationReviewImportContextValues.context(
      review_rows,
      "#{path}.rows.source_timeline_application",
      "#{path}.rows.source_timeline_transition_application",
      "operator_review_package.rows.source_timeline_application",
      "operator_review_package.rows.source_timeline_transition_application"
    )
  end

  def cadence_import_context(path, %{} = manifest) do
    review_rows =
      TimelineTransitionApplicationReviewImportContextRows.cadence_import_rows(manifest)

    TimelineTransitionApplicationReviewImportContextValues.context(
      review_rows,
      "#{path}.rows.source_review_row.source_timeline_application",
      "#{path}.rows.source_review_row.source_timeline_transition_application",
      "cadence_import_manifest.rows.source_review_row.source_timeline_application",
      "cadence_import_manifest.rows.source_review_row.source_timeline_transition_application"
    )
  end
end
