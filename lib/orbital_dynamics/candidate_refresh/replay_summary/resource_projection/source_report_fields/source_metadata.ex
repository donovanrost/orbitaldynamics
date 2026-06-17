defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ResourceProjection.SourceReportFields.SourceMetadata do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.ResourceProjection.SourceReportFields.Aggregation

  def fields(source_reports) do
    %{
      "source_report_resource_projection_projected_resource_count" =>
        source_report_family_count(source_reports, "projected_resource_count"),
      "source_report_resource_projection_source_artifact_type_counts" =>
        source_report_family_merge_count_maps(source_reports, "source_artifact_type_counts"),
      "source_report_resource_projection_source_flow_summary_model_counts" =>
        source_report_family_merge_count_maps(
          source_reports,
          "source_flow_summary_model_counts"
        )
    }
  end
end
