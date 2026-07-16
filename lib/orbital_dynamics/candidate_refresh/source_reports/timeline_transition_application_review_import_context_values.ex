defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationReviewImportContextValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationReviewImportContextRows

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationReviewImportRows

  def context(
        review_rows,
        source_timeline_application_path,
        source_timeline_transition_application_path,
        source_path_timeline_application,
        source_path_timeline_transition_application
      ) do
    applications =
      TimelineTransitionApplicationReviewImportContextRows.applications_from_rows(review_rows)

    application_path =
      TimelineTransitionApplicationReviewImportRows.review_or_import_path(
        review_rows,
        source_timeline_application_path,
        source_timeline_transition_application_path
      )

    source =
      TimelineTransitionApplicationReviewImportRows.review_or_import_path(
        review_rows,
        source_path_timeline_application,
        source_path_timeline_transition_application
      )

    {application_path, source, applications}
  end
end
