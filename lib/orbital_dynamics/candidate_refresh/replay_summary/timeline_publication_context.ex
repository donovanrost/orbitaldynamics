defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelinePublicationContext do
  @moduledoc false

  alias __MODULE__.Fields
  alias __MODULE__.SourceReportFields

  def source_report_fields(source_reports, family, prefix) do
    SourceReportFields.source_report_fields(source_reports, family, prefix)
  end

  def fields(summary, allow_source_artifact_type_fallback?) do
    Fields.fields(summary, allow_source_artifact_type_fallback?)
  end
end
