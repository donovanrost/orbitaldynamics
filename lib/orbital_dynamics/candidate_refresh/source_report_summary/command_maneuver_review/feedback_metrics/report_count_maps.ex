defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.FeedbackMetrics.ReportCountMaps do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.FeedbackMetrics.CountMaps

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.CommandManeuverReview.FeedbackMetrics.RowValues

  def maneuver_id_counts(reports) do
    CountMaps.from_reports(reports, &RowValues.maneuver_id_counts/1)
  end

  def required_operator_action_counts(reports) do
    CountMaps.from_reports(reports, &RowValues.required_operator_action_counts/1)
  end
end
