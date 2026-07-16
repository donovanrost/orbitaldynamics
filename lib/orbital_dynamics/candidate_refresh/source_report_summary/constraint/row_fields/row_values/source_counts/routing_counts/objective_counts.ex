defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Constraint.RowFields.RowValues.SourceCounts.RoutingCounts.ObjectiveCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Constraint.RowFields.RowValues.SourceCounts.{
    CountValues,
    Rows
  }

  def counts(report, extractor) do
    report
    |> Rows.rows()
    |> CountValues.source_objective_counts(extractor)
  end
end
