defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Assembly.TimelineFields.FieldMaps do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Assembly.TimelineFields.{
    FieldMaps.ActivityFields,
    FieldMaps.DiffIntegrityFields,
    FieldMaps.InitialFields,
    PublicationFields,
    SingleState
  }

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.{
    TimelinePreservation
  }

  def source_report_fields(
        refresh_or_artifact,
        source_reports
      ) do
    InitialFields.fields(refresh_or_artifact, source_reports)
    |> Map.merge(ActivityFields.source_report_fields(source_reports))
    |> Map.merge(TimelinePreservation.source_report_flags(refresh_or_artifact))
    |> Map.merge(DiffIntegrityFields.source_report_fields(source_reports))
    |> Map.merge(PublicationFields.source_report_fields(source_reports))
    |> Map.merge(
      SingleState.source_report_fields(
        refresh_or_artifact,
        source_reports
      )
    )
  end
end
