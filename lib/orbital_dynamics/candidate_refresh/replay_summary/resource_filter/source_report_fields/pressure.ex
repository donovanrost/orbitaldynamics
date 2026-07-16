defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ResourceFilter.SourceReportFields.Pressure do
  @moduledoc false

  def source_report_fields(summary) do
    %{
      "source_report_resource_filter_branch_local_resource_filter_pressure" =>
        Map.get(summary, "branch_local_resource_filter_pressure"),
      "source_report_resource_filter_branch_local_candidate_suppression_pressure" =>
        Map.get(summary, "branch_local_candidate_suppression_pressure"),
      "source_report_resource_filter_branch_local_invalid_resource_summary_pressure" =>
        Map.get(summary, "branch_local_invalid_resource_summary_pressure"),
      "source_report_resource_filter_branch_local_resource_blocking_pressure" =>
        Map.get(summary, "branch_local_resource_blocking_pressure")
    }
  end
end
