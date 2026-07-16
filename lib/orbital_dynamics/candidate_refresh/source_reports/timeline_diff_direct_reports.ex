defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffDirectReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiff

  def reports(refresh) do
    [
      {"accepted_planning_state.source_timeline_diff_report",
       get_in(refresh, ["accepted_planning_state", "source_timeline_diff_report"])},
      {"accepted_planning_state.timeline_diff_report",
       get_in(refresh, ["accepted_planning_state", "timeline_diff_report"])},
      {"accepted_planning_state.source_timeline_diff_summary",
       get_in(refresh, ["accepted_planning_state", "source_timeline_diff_summary"])},
      {"accepted_planning_state.timeline_diff_summary",
       get_in(refresh, ["accepted_planning_state", "timeline_diff_summary"])},
      {"mission_state.source_timeline_diff_report",
       get_in(refresh, ["mission_state", "source_timeline_diff_report"])},
      {"mission_state.timeline_diff_report",
       get_in(refresh, ["mission_state", "timeline_diff_report"])},
      {"mission_state.source_timeline_diff_summary",
       get_in(refresh, ["mission_state", "source_timeline_diff_summary"])},
      {"mission_state.timeline_diff_summary",
       get_in(refresh, ["mission_state", "timeline_diff_summary"])},
      {"source_timeline_diff_report", Map.get(refresh, "source_timeline_diff_report")},
      {"timeline_diff_report", Map.get(refresh, "timeline_diff_report")},
      {"source_timeline_diff_summary", Map.get(refresh, "source_timeline_diff_summary")},
      {"timeline_diff_summary", Map.get(refresh, "timeline_diff_summary")}
    ]
    |> Enum.flat_map(fn {path, report_or_summary} ->
      TimelineDiff.entries(path, report_or_summary)
    end)
  end
end
