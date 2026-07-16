defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.QualityGate.SourceReportFields.Pressure do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.QualityGate.Summary
  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelinePublicationContext

  def source_report_fields(quality_gate_summary) do
    pressure_fields = Summary.pressure_fields(quality_gate_summary)
    timeline_fields = TimelinePublicationContext.fields(quality_gate_summary, false)

    %{
      "source_report_quality_gate_branch_local_review_pressure" =>
        Map.get(pressure_fields, "branch_local_review_pressure"),
      "source_report_quality_gate_branch_local_import_pressure" =>
        Map.get(pressure_fields, "branch_local_import_pressure"),
      "source_report_quality_gate_branch_local_resource_pressure" =>
        Map.get(pressure_fields, "branch_local_resource_pressure"),
      "source_report_quality_gate_branch_local_timeline_publication_pressure" =>
        Map.get(timeline_fields, "branch_local_timeline_publication_pressure"),
      "source_report_quality_gate_branch_local_timeline_publication_dependency_pressure" =>
        Map.get(timeline_fields, "branch_local_timeline_publication_dependency_pressure"),
      "source_report_quality_gate_branch_local_timeline_publication_changed_field_pressure" =>
        Map.get(timeline_fields, "branch_local_timeline_publication_changed_field_pressure"),
      "source_report_quality_gate_branch_local_timeline_publication_invalidation_pressure" =>
        Map.get(timeline_fields, "branch_local_timeline_publication_invalidation_pressure"),
      "source_report_quality_gate_branch_local_timeline_publication_review_pressure" =>
        Map.get(timeline_fields, "branch_local_timeline_publication_review_pressure")
    }
  end
end
