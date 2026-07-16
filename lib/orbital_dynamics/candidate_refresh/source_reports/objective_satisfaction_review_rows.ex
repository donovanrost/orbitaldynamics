defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveSatisfactionReviewRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveSatisfactionReviewRowFields
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveSatisfactionStatusValues
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveSatisfactionValueEncoding

  def row_from_review_or_import_row(%{} = row) do
    ObjectiveSatisfactionReviewRowFields.row_from_review_or_import_row(row)
  end

  def row_from_review_or_import_row(_row), do: nil

  def status_value(status), do: ObjectiveSatisfactionStatusValues.status_value(status)

  def stringify_keys(value), do: ObjectiveSatisfactionValueEncoding.stringify_keys(value)
end
