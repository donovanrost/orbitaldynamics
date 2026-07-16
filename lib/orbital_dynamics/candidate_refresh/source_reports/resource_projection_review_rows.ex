defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionReviewRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionReviewEmbeddedRows
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionReviewRowValues

  def row_from_review_or_import_row(%{} = row) do
    ResourceProjectionReviewEmbeddedRows.row_from_review_or_import_row(row)
  end

  def row_from_review_or_import_row(_row), do: nil

  def split_embedded_rows(rows) do
    ResourceProjectionReviewRowValues.split_embedded_rows(rows)
  end

  def count_resource_projection_rows(rows, field) do
    ResourceProjectionReviewRowValues.count_resource_projection_rows(rows, field)
  end

  def stringify_keys(value), do: ResourceProjectionReviewRowValues.stringify_keys(value)
end
