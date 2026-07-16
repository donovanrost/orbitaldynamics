defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ConstraintReviewReportCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceObjectives.Constraint,
    as: ConstraintSourceObjectives

  def count_rows(rows, field) do
    rows
    |> Enum.map(&ConstraintSourceObjectives.status_value(Map.get(&1, field)))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
    |> case do
      counts when counts == %{} -> nil
      counts -> counts
    end
  end
end
