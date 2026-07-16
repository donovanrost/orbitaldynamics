defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ObjectiveSatisfaction.RowValues.GapTypes do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceObjectives.ObjectiveSatisfaction,
    as: ObjectiveSatisfactionSourceObjectives

  alias __MODULE__.ObjectiveTypes

  def downlink_gap?(row), do: gap_objective_type?(row, ObjectiveTypes.downlink_gap())

  def target_gap?(row), do: gap_objective_type?(row, ObjectiveTypes.target_gap())

  def collection_latency_gap?(row),
    do: gap_objective_type?(row, ObjectiveTypes.collection_latency_gap())

  defp gap_objective_type?(row, objective_types) do
    ObjectiveSatisfactionSourceObjectives.gap_status?(row["status"]) and
      ObjectiveSatisfactionSourceObjectives.objective_type(row) in objective_types
  end
end
