defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Constraint.RowFields.RowValues.SourceCounts.Rows.SourceObjectiveValues do
  @moduledoc false

  alias __MODULE__.EncodedRows
  alias __MODULE__.GapPredicates

  alias OrbitalDynamics.CandidateRefresh.SourceObjectives.Constraint,
    as: ConstraintSourceObjectives

  def downlink_gap?(row), do: GapPredicates.downlink_gap?(row)

  def resource_margin_gap?(row), do: GapPredicates.resource_margin_gap?(row)

  def station_id(row), do: source_objective_value(row, &ConstraintSourceObjectives.station_id/1)

  def metric(row), do: source_objective_value(row, &ConstraintSourceObjectives.metric/1)

  def constraint_id(row), do: source_objective_value(row, &ConstraintSourceObjectives.id/1)

  def resource_id(row), do: source_objective_value(row, &ConstraintSourceObjectives.resource_id/1)

  def spacecraft_id(row),
    do: source_objective_value(row, &ConstraintSourceObjectives.spacecraft_id/1)

  def source_activity_ids(row) do
    row
    |> EncodedRows.stringify()
    |> ConstraintSourceObjectives.source_activity_ids()
    |> Kernel.||([])
  end

  defp source_objective_value(row, extractor) do
    row
    |> EncodedRows.stringify()
    |> extractor.()
  end
end
