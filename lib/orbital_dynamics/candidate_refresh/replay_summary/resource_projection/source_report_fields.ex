defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ResourceProjection.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ResourceProjection
  alias __MODULE__.Identity
  alias __MODULE__.InvalidInput
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

    %{
      "source_report_resource_projection_branch_local_resource_projection_pressure" =>
        Map.get(summary, "branch_local_resource_projection_pressure"),
      "source_report_resource_projection_branch_local_projected_resource_pressure" =>
        Map.get(summary, "branch_local_projected_resource_pressure"),
      "source_report_resource_projection_branch_local_invalid_resource_projection_pressure" =>
        Map.get(summary, "branch_local_invalid_resource_projection_pressure"),
      "source_report_resource_projection_branch_local_activity_pressure" =>
        Map.get(summary, "branch_local_activity_pressure")
    }
  end

  def source_report_summary_fields(source_reports) do
    source_reports
    |> source_report_fields()
    |> Map.merge(source_report_identity_fields(source_reports))
    |> Map.merge(source_report_source_metadata_fields(source_reports))
    |> Map.merge(source_report_invalid_input_fields(source_reports))
    |> Map.merge(source_report_pressure_routing_fields(source_reports))
    |> Map.merge(source_report_pressure_evidence_fields(source_reports))
  end

  def source_report_identity_fields(source_reports) do
    Identity.fields(source_reports)
  end

  def source_report_source_metadata_fields(source_reports) do
    SourceMetadata.fields(source_reports)
  end

  def source_report_invalid_input_fields(source_reports) do
    InvalidInput.fields(source_reports)
  end

  def source_report_pressure_routing_fields(source_reports) do
    PressureRouting.fields(source_reports)
  end

  def source_report_pressure_evidence_fields(source_reports) do
    PressureEvidence.fields(source_reports)
  end
end
