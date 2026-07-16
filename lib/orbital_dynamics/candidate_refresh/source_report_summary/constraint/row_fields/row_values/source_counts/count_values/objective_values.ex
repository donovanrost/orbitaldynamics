defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Constraint.RowFields.RowValues.SourceCounts.CountValues.ObjectiveValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Constraint.RowFields.RowValues.SourceCounts.Rows

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [count_source_report_values: 1]

  def source_objective_counts(rows, extractor) do
    rows
    |> Enum.map(&extractor.(&1))
    |> count_source_report_values()
  end

  def source_activity_id_counts(rows) do
    rows
    |> Enum.flat_map(&Rows.source_activity_ids/1)
    |> count_source_report_values()
  end
end
