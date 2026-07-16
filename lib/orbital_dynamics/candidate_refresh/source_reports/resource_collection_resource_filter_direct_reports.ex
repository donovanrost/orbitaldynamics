defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ResourceCollectionResourceFilterDirectReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceFilter

  def reports(refresh) do
    [
      {"accepted_planning_state.source_resource_filter_report",
       get_in(refresh, ["accepted_planning_state", "source_resource_filter_report"])},
      {"accepted_planning_state.resource_filter_report",
       get_in(refresh, ["accepted_planning_state", "resource_filter_report"])},
      {"accepted_planning_state.source_resource_filter_summary",
       get_in(refresh, ["accepted_planning_state", "source_resource_filter_summary"])},
      {"accepted_planning_state.resource_filter_summary",
       get_in(refresh, ["accepted_planning_state", "resource_filter_summary"])},
      {"mission_state.source_resource_filter_report",
       get_in(refresh, ["mission_state", "source_resource_filter_report"])},
      {"mission_state.resource_filter_report",
       get_in(refresh, ["mission_state", "resource_filter_report"])},
      {"mission_state.source_resource_filter_summary",
       get_in(refresh, ["mission_state", "source_resource_filter_summary"])},
      {"mission_state.resource_filter_summary",
       get_in(refresh, ["mission_state", "resource_filter_summary"])},
      {"source_resource_filter_report", Map.get(refresh, "source_resource_filter_report")},
      {"resource_filter_report", Map.get(refresh, "resource_filter_report")},
      {"source_resource_filter_summary", Map.get(refresh, "source_resource_filter_summary")},
      {"resource_filter_summary", Map.get(refresh, "resource_filter_summary")}
    ]
    |> Enum.flat_map(fn {path, report_or_summary} ->
      ResourceFilter.entries(path, report_or_summary)
    end)
  end
end
