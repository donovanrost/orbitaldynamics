defmodule OrbitalDynamics.CandidateRefresh.SourceReports.CommandWindowReviewRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.CommandWindowReviewRowValues

  def row_from_review_or_import_row(%{} = row) do
    CommandWindowReviewRowValues.row_from_review_or_import_row(row)
  end

  def stringify_keys(value), do: CommandWindowReviewRowValues.stringify_keys(value)
end
