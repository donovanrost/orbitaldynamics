defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Constraint.RowFields.RowValues.SourceCounts.Rows.SourceObjectiveValues.GapPredicates do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Constraint.RowFields.RowValues.SourceCounts.Rows.SourceObjectiveValues.EncodedRows

  alias OrbitalDynamics.CandidateRefresh.SourceObjectives.Constraint,
    as: ConstraintSourceObjectives

  def downlink_gap?(row) do
    row
    |> EncodedRows.stringify()
    |> ConstraintSourceObjectives.downlink_gap?()
  end

  def resource_margin_gap?(row) do
    row
    |> EncodedRows.stringify()
    |> ConstraintSourceObjectives.resource_margin_gap?()
  end
end
