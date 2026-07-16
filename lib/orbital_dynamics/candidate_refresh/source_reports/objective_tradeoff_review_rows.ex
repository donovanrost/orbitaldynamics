defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveTradeoffReviewRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveTradeoffReviewRowValues

  def row_from_review_or_import_row(%{} = row) do
    ObjectiveTradeoffReviewRowValues.row_from_review_or_import_row(row)
  end

  def score_term_keys(rows), do: ObjectiveTradeoffReviewRowValues.score_term_keys(rows)

  def stringify_keys(value), do: ObjectiveTradeoffReviewRowValues.stringify_keys(value)
end
