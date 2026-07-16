defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Assembly.TimelineFields.FieldMaps.ActivityFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivityLifecycleState.SourceReportFields,
    as: TimelineActivityLifecycleStateFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivityPrecondition.SourceReportFields,
    as: TimelineActivityPreconditionFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineLifecycleState.SourceReportFields,
    as: TimelineLifecycleStateFields

  def source_report_fields(source_reports) do
    TimelineActivityLifecycleStateFields.source_report_fields(source_reports)
    |> Map.merge(TimelineLifecycleStateFields.source_report_fields(source_reports))
    |> Map.merge(TimelineActivityPreconditionFields.source_report_fields(source_reports))
  end
end
