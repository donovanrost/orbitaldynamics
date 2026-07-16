defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Assembly.TimelineFields.SingleState do
  @moduledoc false

  alias __MODULE__.Definitions

  def pressure_fields(refresh_or_artifact, source_reports) do
    Definitions.pressure_fields(refresh_or_artifact, source_reports)
  end

  def source_report_fields(refresh_or_artifact, source_reports) do
    Definitions.source_report_fields(refresh_or_artifact, source_reports)
  end
end
