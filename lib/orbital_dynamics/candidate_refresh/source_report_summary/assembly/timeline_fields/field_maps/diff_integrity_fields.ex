defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Assembly.TimelineFields.FieldMaps.DiffIntegrityFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineDependencyImpact.SourceReportFields,
    as: TimelineDependencyImpactFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineDiff.SourceReportFields,
    as: TimelineDiffFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineIntegrity.SourceReportFields,
    as: TimelineIntegrityFields

  def source_report_fields(source_reports) do
    TimelineDependencyImpactFields.source_report_fields(source_reports)
    |> Map.merge(TimelineDiffFields.source_report_fields(source_reports))
    |> Map.merge(TimelineIntegrityFields.source_report_fields(source_reports))
  end
end
