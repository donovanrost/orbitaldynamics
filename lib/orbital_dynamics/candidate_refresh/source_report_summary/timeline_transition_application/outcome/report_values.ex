defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.Outcome.ReportValues do
  @moduledoc false

  alias __MODULE__.CountValues
  alias __MODULE__.SourceValues

  def review_required_count(report) do
    CountValues.review_required_count(report)
  end

  def preserved_source_count(report) do
    CountValues.preserved_source_count(report)
  end

  def recorded_replacement_count(report) do
    CountValues.recorded_replacement_count(report)
  end

  def withheld_review_count(report) do
    CountValues.withheld_review_count(report)
  end

  def application_status_counts(report) do
    SourceValues.map(report, "application_status_counts", "application_status")
  end

  def transition_decision_counts(report) do
    SourceValues.map(report, "transition_decision_counts", "transition_decision")
  end

  def required_operator_action_counts(report) do
    SourceValues.map(report, "required_operator_action_counts", "required_operator_action")
  end
end
