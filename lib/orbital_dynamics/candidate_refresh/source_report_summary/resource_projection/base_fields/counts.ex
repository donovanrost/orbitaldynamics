defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.BaseFields.Counts do
  @moduledoc false

  alias __MODULE__.ProjectedRows
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.InvalidInputs

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [numeric_report_count: 2]

  def row_count(report) do
    projected_resource_count(report) +
      InvalidInputs.invalid_activity_input_count(report) +
      InvalidInputs.invalid_resource_summary_input_count(report)
  end

  def projected_resource_count(report) do
    numeric_report_count(report, "projected_resource_count")
    |> case do
      0 -> report |> ProjectedRows.values() |> length()
      count -> count
    end
  end
end
