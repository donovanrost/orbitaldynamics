defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ResourceCollectionResourceProjectionDirectReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjection

  def reports(refresh) do
    [
      {"accepted_planning_state.source_resource_projection_report",
       get_in(refresh, ["accepted_planning_state", "source_resource_projection_report"])},
      {"accepted_planning_state.resource_projection_report",
       get_in(refresh, ["accepted_planning_state", "resource_projection_report"])},
      {"accepted_planning_state.source_resource_projection_flow_summary",
       get_in(refresh, ["accepted_planning_state", "source_resource_projection_flow_summary"])},
      {"accepted_planning_state.resource_projection_flow_summary",
       get_in(refresh, ["accepted_planning_state", "resource_projection_flow_summary"])},
      {"mission_state.source_resource_projection_report",
       get_in(refresh, ["mission_state", "source_resource_projection_report"])},
      {"mission_state.resource_projection_report",
       get_in(refresh, ["mission_state", "resource_projection_report"])},
      {"mission_state.source_resource_projection_flow_summary",
       get_in(refresh, ["mission_state", "source_resource_projection_flow_summary"])},
      {"mission_state.resource_projection_flow_summary",
       get_in(refresh, ["mission_state", "resource_projection_flow_summary"])},
      {"source_resource_projection_report",
       Map.get(refresh, "source_resource_projection_report")},
      {"resource_projection_report", Map.get(refresh, "resource_projection_report")},
      {"source_resource_projection_flow_summary",
       Map.get(refresh, "source_resource_projection_flow_summary")},
      {"resource_projection_flow_summary", Map.get(refresh, "resource_projection_flow_summary")}
    ]
    |> Enum.flat_map(fn {path, report_or_reports} ->
      ResourceProjection.entries(path, report_or_reports)
    end)
  end
end
