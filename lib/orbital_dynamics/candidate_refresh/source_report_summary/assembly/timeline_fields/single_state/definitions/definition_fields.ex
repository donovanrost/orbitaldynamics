defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Assembly.TimelineFields.SingleState.Definitions.DefinitionFields do
  @moduledoc false

  alias __MODULE__.DefinitionSpecs
  alias __MODULE__.SourceFields

  def pressure_fields(refresh_or_artifact, source_reports) do
    Enum.reduce(DefinitionSpecs.all(), %{}, fn definition, fields ->
      Map.merge(
        fields,
        SourceFields.pressure_fields(refresh_or_artifact, source_reports, definition)
      )
    end)
  end

  def source_report_fields(refresh_or_artifact, source_reports) do
    Enum.reduce(DefinitionSpecs.all(), %{}, fn definition, fields ->
      Map.merge(
        fields,
        SourceFields.source_report_fields(refresh_or_artifact, source_reports, definition)
      )
    end)
  end
end
