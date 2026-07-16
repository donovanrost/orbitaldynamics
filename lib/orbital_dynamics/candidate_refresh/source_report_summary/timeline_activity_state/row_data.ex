defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.RowData do
  @moduledoc false

  alias __MODULE__.{Ids, InvalidInputs, Predicates, Rows}

  def ids(row, field), do: Ids.values(row, field)

  def invalid_activity_input_count(row), do: InvalidInputs.count(row)

  def invalid_activity_input_reasons(row), do: InvalidInputs.reasons(row)

  def rows_for_summary(state), do: Rows.for_summary(state)

  def review_required?(row), do: Predicates.review_required?(row)

  def present_action?(row_or_action), do: Predicates.present_action?(row_or_action)
end
