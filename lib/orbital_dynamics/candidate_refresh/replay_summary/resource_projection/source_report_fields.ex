defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ResourceProjection.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ResourceProjection
  alias __MODULE__.Identity
  alias __MODULE__.InvalidInput
  alias __MODULE__.Pressure
  alias __MODULE__.PressureEvidence
  alias __MODULE__.PressureRouting
  alias __MODULE__.SourceMetadata

  def source_report_fields(source_reports) do
    summary =
      source_reports
      |> Map.get("resource_projection_report", %{})
      |> ResourceProjection.summary(
        "candidate_refresh.source_report_provenance.resource_projection_report",
        "resource_projection_source_report_provenance_only"
      )

    Pressure.source_report_fields(summary)
  end

  def source_report_summary_fields(source_reports) do
    source_reports
    |> source_report_fields()
    |> Map.merge(Identity.fields(source_reports))
    |> Map.merge(SourceMetadata.fields(source_reports))
    |> Map.merge(InvalidInput.fields(source_reports))
    |> Map.merge(PressureRouting.fields(source_reports))
    |> Map.merge(PressureEvidence.fields(source_reports))
  end
end
