defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.StatusClassification.StatusIds.NonPassed.StatusIds.StatusLists do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.StatusClassification.StatusIds.StatusValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sorted_string_values: 1]

  @non_passed_statuses ["review_required", "analysis_only", "blocked"]

  def gate_ids(report) do
    @non_passed_statuses
    |> Enum.flat_map(&StatusValues.gate_ids(report, &1, "#{&1}_gate_ids"))
    |> sorted_string_values()
  end

  def row_ids(report) do
    @non_passed_statuses
    |> Enum.flat_map(&StatusValues.row_ids(report, &1, "#{&1}_quality_gate_row_ids"))
    |> sorted_string_values()
  end
end
