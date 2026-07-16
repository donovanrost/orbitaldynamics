defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Constraint.RowFields.RowValues.SourceCounts.CountValues do
  @moduledoc false

  alias __MODULE__.ObjectiveValues

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Constraint.RowFields.RowValues.SourceCounts.Rows

  def token_counts(rows, field) do
    rows
    |> Enum.map(&Rows.token_value(&1, field))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
    |> case do
      counts when counts == %{} -> nil
      counts -> counts
    end
  end

  def source_objective_counts(rows, extractor) do
    ObjectiveValues.source_objective_counts(rows, extractor)
  end

  def source_activity_id_counts(rows) do
    ObjectiveValues.source_activity_id_counts(rows)
  end
end
