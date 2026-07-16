defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.Outcome.ReportValues.ApplicationFallbacks.ApplicationPredicates do
  @moduledoc false

  def review_required?(row) do
    row["requires_operator_review"] == true or
      withheld_review?(row) or
      review_action?(row["required_operator_action"])
  end

  def preserved_source?(row) do
    row["application_status"] == "source_preserved_pending_review" or
      row["transition_decision"] == "preserve_source"
  end

  def recorded_replacement?(row) do
    row["application_status"] == "replacement_recorded"
  end

  def withheld_review?(row) do
    row["application_status"] in ["operator_review_required", "withheld_review"]
  end

  defp review_action?(action), do: action not in [nil, "", "none"]
end
