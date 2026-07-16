defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.BaseFields.ReportValues.CountFields.CountValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      numeric_report_count: 2,
      sum_report_count: 2
    ]

  def boolean_sum(reports, field, expected) do
    sum_report_count(reports, &boolean_count(&1, field, expected))
  end

  def gate_count(report) do
    case numeric_report_count(report, "gate_count") do
      0 -> length(Map.get(report, "gates", []))
      count -> count
    end
  end

  def import_eligible_count(%{"import_eligible" => true}), do: 1
  def import_eligible_count(_report), do: 0

  def import_ineligible_count(%{"import_eligible" => false}), do: 1
  def import_ineligible_count(_report), do: 0

  defp boolean_count(report, field, expected) do
    if Map.get(report, field) == expected, do: 1, else: 0
  end
end
