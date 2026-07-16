defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.StatusClassification.GateCounts.RowValues.ReportCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.StatusClassification.GateCounts.RowValues.Counts

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      numeric_report_count: 2
    ]

  def gate_count(report) do
    case Counts.rows(report) do
      [] -> numeric_report_count(report, "gate_count")
      rows -> length(rows)
    end
  end

  def quality_gate_row_count(report) do
    case Counts.rows(report) do
      [] -> fallback_quality_gate_row_count(report)
      rows -> length(rows)
    end
  end

  def gate_status_count(report, status) do
    case Counts.rows(report) do
      [] -> numeric_report_count(report, Counts.gate_status_count_field(status))
      rows -> Counts.value_count(rows, "status", status)
    end
  end

  defp fallback_quality_gate_row_count(report) do
    case numeric_report_count(report, "import_readiness_row_count") do
      0 -> numeric_report_count(report, "gate_count")
      count -> count
    end
  end
end
