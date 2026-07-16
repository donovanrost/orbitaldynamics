defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Assembly.TimelineFields.SingleState.Definitions do
  @moduledoc false

  alias __MODULE__.DefinitionFields

  def pressure_fields(refresh_or_artifact, source_reports) do
    DefinitionFields.pressure_fields(refresh_or_artifact, source_reports)
  end

  def source_report_fields(refresh_or_artifact, source_reports) do
    DefinitionFields.source_report_fields(refresh_or_artifact, source_reports)
  end
end
