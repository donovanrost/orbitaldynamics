defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ResourceProjection.SourceReportFields.Pressure do
  @moduledoc false

  def source_report_fields(summary) do
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
end
