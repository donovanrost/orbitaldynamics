defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineFeedbackCollectionDirectReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineFeedbackCollectionEncoding

  def reports(refresh) do
    [
      {"accepted_planning_state.source_timeline_feedback_report",
       get_in(refresh, ["accepted_planning_state", "source_timeline_feedback_report"])},
      {"accepted_planning_state.timeline_feedback_report",
       get_in(refresh, ["accepted_planning_state", "timeline_feedback_report"])},
      {"mission_state.source_timeline_feedback_report",
       get_in(refresh, ["mission_state", "source_timeline_feedback_report"])},
      {"mission_state.timeline_feedback_report",
       get_in(refresh, ["mission_state", "timeline_feedback_report"])},
      {"source_timeline_feedback_report", Map.get(refresh, "source_timeline_feedback_report")},
      {"timeline_feedback_report", Map.get(refresh, "timeline_feedback_report")}
    ]
    |> reject_root_shadowed_mission_state_reports()
  end

  defp reject_root_shadowed_mission_state_reports(entries) do
    root_reports =
      entries
      |> Enum.reject(fn {path, _report} -> String.starts_with?(path, "mission_state.") end)
      |> Map.new(fn {path, report} ->
        {path, TimelineFeedbackCollectionEncoding.stringify_keys(report)}
      end)

    Enum.reject(entries, fn
      {"mission_state." <> root_path, %{} = report} ->
        Map.get(root_reports, root_path) ==
          TimelineFeedbackCollectionEncoding.stringify_keys(report)

      {_path, _report} ->
        false
    end)
  end
end
