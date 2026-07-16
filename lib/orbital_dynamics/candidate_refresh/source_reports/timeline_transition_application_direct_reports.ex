defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationDirectReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplication

  def reports(refresh) do
    [
      {"accepted_planning_state.source_timeline_transition_application_report",
       get_in(refresh, [
         "accepted_planning_state",
         "source_timeline_transition_application_report"
       ])},
      {"accepted_planning_state.timeline_transition_application_report",
       get_in(refresh, ["accepted_planning_state", "timeline_transition_application_report"])},
      {"mission_state.source_timeline_transition_application_report",
       get_in(refresh, ["mission_state", "source_timeline_transition_application_report"])},
      {"mission_state.timeline_transition_application_report",
       get_in(refresh, ["mission_state", "timeline_transition_application_report"])},
      {"source_timeline_transition_application_report",
       Map.get(refresh, "source_timeline_transition_application_report")},
      {"timeline_transition_application_report",
       Map.get(refresh, "timeline_transition_application_report")}
    ]
    |> Kernel.++([
      {"accepted_planning_state.source_timeline_transition_application_summary",
       get_in(refresh, [
         "accepted_planning_state",
         "source_timeline_transition_application_summary"
       ])},
      {"accepted_planning_state.timeline_transition_application_summary",
       get_in(refresh, ["accepted_planning_state", "timeline_transition_application_summary"])},
      {"mission_state.source_timeline_transition_application_summary",
       get_in(refresh, ["mission_state", "source_timeline_transition_application_summary"])},
      {"mission_state.timeline_transition_application_summary",
       get_in(refresh, ["mission_state", "timeline_transition_application_summary"])},
      {"source_timeline_transition_application_summary",
       Map.get(refresh, "source_timeline_transition_application_summary")},
      {"timeline_transition_application_summary",
       Map.get(refresh, "timeline_transition_application_summary")}
    ])
    |> Enum.flat_map(fn {path, report_or_summary} ->
      TimelineTransitionApplication.entries(path, report_or_summary)
    end)
  end
end
