defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ResourceProjection.SourceReportFields.InvalidInput do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.ResourceProjection.SourceReportFields.Aggregation

  def fields(source_reports) do
    %{
      "source_report_resource_projection_invalid_activity_input_count" =>
        source_report_family_count(source_reports, "invalid_activity_input_count"),
      "source_report_resource_projection_invalid_resource_summary_input_count" =>
        source_report_family_count(source_reports, "invalid_resource_summary_input_count"),
      "source_report_resource_projection_invalid_activity_input_ids" =>
        source_report_family_merge_string_lists(source_reports, "invalid_activity_input_ids"),
      "source_report_resource_projection_invalid_resource_summary_input_ids" =>
        source_report_family_merge_string_lists(
          source_reports,
          "invalid_resource_summary_input_ids"
        )
    }
  end
end
