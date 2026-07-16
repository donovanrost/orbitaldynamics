defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Assembly.PlanningReviewFields.FeedbackFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.CommandWindow.SourceReportFields,
    as: CommandWindowFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.Constraint.SourceReportFields,
    as: ConstraintFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ManeuverReview.SourceReportFields,
    as: ManeuverReviewFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ObjectiveGap.SourceReportFields,
    as: ObjectiveGapFields

  def fields(source_reports) do
    CommandWindowFields.source_report_fields(source_reports)
    |> Map.merge(ManeuverReviewFields.source_report_fields(source_reports))
    |> Map.merge(ConstraintFields.source_report_fields(source_reports))
    |> Map.merge(ObjectiveGapFields.source_report_fields(source_reports))
  end
end
