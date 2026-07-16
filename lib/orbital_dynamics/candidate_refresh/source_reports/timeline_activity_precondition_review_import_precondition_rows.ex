defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionReviewImportPreconditionRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionReviewImportPreconditionRowValues

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionReviewImportRowFallbacks

  def from_preconditions(rows) do
    TimelineActivityPreconditionReviewImportPreconditionRowValues.from_preconditions(rows)
  end

  def status(_rows, precondition_rows) when precondition_rows != [] do
    TimelineActivityPreconditionReviewImportPreconditionRowValues.status(precondition_rows)
  end

  def status(rows, _precondition_rows) do
    TimelineActivityPreconditionReviewImportRowFallbacks.status(rows)
  end

  def count(_rows, precondition_rows, status) when precondition_rows != [] do
    TimelineActivityPreconditionReviewImportPreconditionRowValues.count(precondition_rows, status)
  end

  def count(rows, _precondition_rows, "blocked") do
    TimelineActivityPreconditionReviewImportRowFallbacks.count(rows, "blocked")
  end

  def count(rows, _precondition_rows, "review_required") do
    TimelineActivityPreconditionReviewImportRowFallbacks.count(rows, "review_required")
  end

  def types(_rows, precondition_rows, status) when precondition_rows != [] do
    TimelineActivityPreconditionReviewImportPreconditionRowValues.types(precondition_rows, status)
  end

  def types(rows, _precondition_rows, "blocked") do
    TimelineActivityPreconditionReviewImportRowFallbacks.types(rows, "blocked")
  end

  def types(rows, _precondition_rows, "review_required") do
    TimelineActivityPreconditionReviewImportRowFallbacks.types(rows, "review_required")
  end
end
