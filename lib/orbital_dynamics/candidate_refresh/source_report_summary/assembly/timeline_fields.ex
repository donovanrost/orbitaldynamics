defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Assembly.TimelineFields do
  @moduledoc false

  alias __MODULE__.FieldMaps

  def source_report_fields(
        refresh_or_artifact,
        source_reports
      ) do
    FieldMaps.source_report_fields(refresh_or_artifact, source_reports)
  end
end
