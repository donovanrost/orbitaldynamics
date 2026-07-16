defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationReviewImportRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationReviewImportEncoding

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationReviewImportRowCounts

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationReviewImportRowSources

  def review_or_import_path(
        rows,
        source_timeline_application_path,
        source_timeline_transition_application_path
      ) do
    TimelineTransitionApplicationReviewImportRowSources.review_or_import_path(
      rows,
      source_timeline_application_path,
      source_timeline_transition_application_path
    )
  end

  def source_application_from_review_or_import_row(%{} = row) do
    TimelineTransitionApplicationReviewImportRowSources.source_application_from_row(row)
  end

  def duplicate_identity_row?(row) do
    row["timeline_identity_collision"] == true or
      row["duplicate_timeline_identity_scope"] in [
        "source",
        "replacement",
        "source_and_replacement"
      ]
  end

  def duplicate_identity_scope?(row, scope) do
    case row["duplicate_timeline_identity_scope"] do
      ^scope -> true
      "source_and_replacement" when scope in ["source", "replacement"] -> true
      _scope -> false
    end
  end

  def count_rows(rows, field) do
    TimelineTransitionApplicationReviewImportRowCounts.count_rows(rows, field)
  end

  def stringify_keys(value),
    do: TimelineTransitionApplicationReviewImportEncoding.stringify_keys(value)
end
