defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffReviewImportRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffReviewImportRowEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffReviewImportRowExtraction

  def row_from_review_or_import_row(%{} = row) do
    TimelineDiffReviewImportRowExtraction.row_from_review_or_import_row(row)
  end

  def row_from_review_or_import_row(_row), do: nil

  def stringify_keys(value), do: TimelineDiffReviewImportRowEncoding.stringify_keys(value)
end
