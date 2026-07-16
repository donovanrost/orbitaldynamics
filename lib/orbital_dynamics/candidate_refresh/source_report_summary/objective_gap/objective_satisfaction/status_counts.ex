defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ObjectiveSatisfaction.StatusCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Counts
  alias __MODULE__.StatusCategory

  def counts(rows) do
    Counts.normalized_rows(rows, "status", &StatusCategory.value/1)
  end
end
