defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.OperationalReadiness.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.OperationalReadiness
  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelinePublicationContext
  alias __MODULE__.Flattened

  def source_report_fields(refresh_or_artifact, source_reports, callbacks) do
    source_report_summary_branch_family =
      Keyword.fetch!(callbacks, :source_report_summary_branch_family)

    branch_readiness_summary =
      source_report_summary_branch_family.(refresh_or_artifact, "operational_readiness_report")

    readiness_summary =
      branch_readiness_summary || Map.get(source_reports, "operational_readiness_report", %{})

    pressure_fields = OperationalReadiness.pressure_fields(readiness_summary)
    timeline_fields = TimelinePublicationContext.fields(readiness_summary, true)

    %{
      "source_report_operational_readiness_branch_local_review_pressure" =>
        Map.get(pressure_fields, "branch_local_review_pressure"),
      "source_report_operational_readiness_branch_local_import_pressure" =>
        Map.get(pressure_fields, "branch_local_import_pressure"),
      "source_report_operational_readiness_branch_local_execution_boundary_pressure" =>
        Map.get(pressure_fields, "branch_local_execution_boundary_pressure"),
      "source_report_operational_readiness_branch_local_resource_pressure" =>
        Map.get(pressure_fields, "branch_local_resource_pressure"),
      "source_report_operational_readiness_branch_local_timeline_publication_pressure" =>
        Map.get(timeline_fields, "branch_local_timeline_publication_pressure"),
      "source_report_operational_readiness_branch_local_timeline_publication_dependency_pressure" =>
        Map.get(timeline_fields, "branch_local_timeline_publication_dependency_pressure"),
      "source_report_operational_readiness_branch_local_timeline_publication_changed_field_pressure" =>
        Map.get(timeline_fields, "branch_local_timeline_publication_changed_field_pressure"),
      "source_report_operational_readiness_branch_local_timeline_publication_invalidation_pressure" =>
        Map.get(timeline_fields, "branch_local_timeline_publication_invalidation_pressure"),
      "source_report_operational_readiness_branch_local_timeline_publication_review_pressure" =>
        Map.get(timeline_fields, "branch_local_timeline_publication_review_pressure")
    }
    |> Map.merge(Flattened.source_report_fields(source_reports))
  end
end
