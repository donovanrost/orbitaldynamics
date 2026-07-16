defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Assembly.TimelineFields.FieldMaps.InitialFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Assembly.TimelineFields.SingleState

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.OperationalTimeline.SourceReportFields,
    as: OperationalTimelineFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivityState.SourceReportFields,
    as: TimelineActivityStateFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineFeedback.SourceReportFields,
    as: TimelineFeedbackFields

  def fields(refresh_or_artifact, source_reports) do
    TimelineFeedbackFields.source_report_summary_fields(source_reports)
    |> Map.merge(OperationalTimelineFields.source_report_summary_fields(source_reports))
    |> Map.merge(TimelineActivityStateFields.source_report_summary_fields(source_reports))
    |> Map.merge(
      SingleState.pressure_fields(
        refresh_or_artifact,
        source_reports
      )
    )
  end
end
