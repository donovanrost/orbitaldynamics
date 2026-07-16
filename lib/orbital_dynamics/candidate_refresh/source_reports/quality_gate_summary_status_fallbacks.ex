defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSummaryStatusFallbacks do
  @moduledoc false

  def ids_by_classification(%{} = fallback), do: fallback
  def ids_by_classification(_fallback), do: %{}

  def status_count(summary, "passed"), do: summary["passed_gate_count"]
  def status_count(summary, "review_required"), do: summary["review_gate_count"]
  def status_count(summary, "analysis_only"), do: summary["analysis_gate_count"]
  def status_count(summary, "blocked"), do: summary["blocked_gate_count"]

  def status_counts(fallback_counts), do: fallback_counts
  def classification_counts(fallback_counts), do: fallback_counts

  def status(summary), do: summary["status"]
  def import_classification(summary), do: summary["import_classification"]
  def readiness_level(summary), do: summary["readiness_level"]
end
