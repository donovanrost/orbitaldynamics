defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Assembly.TimelineFields.SingleState.Definitions.DefinitionFields.SourceFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivitySingleState.SourceReportFields

  def pressure_fields(
        refresh_or_artifact,
        source_reports,
        {family, contract, model, application_boundary, authority_boundary}
      ) do
    SourceReportFields.source_report_pressure_fields(
      refresh_or_artifact,
      source_reports,
      family,
      contract,
      model,
      application_boundary,
      authority_boundary
    )
  end

  def source_report_fields(
        refresh_or_artifact,
        source_reports,
        {family, contract, model, _, _}
      ) do
    SourceReportFields.source_report_fields(
      refresh_or_artifact,
      source_reports,
      family,
      contract,
      model
    )
  end
end
