defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.ReadinessSupport.ReadinessFields.OperatorTraining.FieldValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.RowFallbackValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      sorted_string_values: 1,
      sum_report_count: 2
    ]

  def row_count(reports, field) do
    sum_report_count(reports, &RowFallbackValues.count(&1, field))
  end

  def count_map(reports, field) do
    reports
    |> Enum.map(&RowFallbackValues.count_map(&1, field))
    |> merge_count_maps()
  end

  def string_values(reports, field) do
    reports
    |> Enum.flat_map(&RowFallbackValues.string_list(&1, field))
    |> sorted_string_values()
  end
end
