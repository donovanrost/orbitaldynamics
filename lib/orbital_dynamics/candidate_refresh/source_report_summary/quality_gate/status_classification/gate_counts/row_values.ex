defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.StatusClassification.GateCounts.RowValues do
  @moduledoc false

  alias __MODULE__.Counts
  alias __MODULE__.ReportCounts

  def gate_status_counts(report),
    do: Counts.row_or_fallback(report, "status", "gate_status_counts")

  def gate_classification_counts(report) do
    Counts.row_or_fallback(report, "classification", "gate_classification_counts")
  end

  def gate_count(report) do
    ReportCounts.gate_count(report)
  end

  def quality_gate_row_count(report) do
    ReportCounts.quality_gate_row_count(report)
  end

  def gate_status_count(report, status) do
    ReportCounts.gate_status_count(report, status)
  end

  def analysis_mode_counts(report) do
    Counts.non_empty_row_counts_or_fallback(report, "analysis_mode", "analysis_mode_counts")
  end
end
