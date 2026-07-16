defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Constraint.RowFields.RowValues.SourceCounts.Rows.SourceObjectiveValues.EncodedRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def stringify(row), do: EncodedValue.stringify_keys(row)
end
