defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffCollectionTransitionApplicationDirectReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiff

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
    |> Enum.flat_map(fn {path, report_or_reports} ->
      TimelineTransitionApplication.timeline_diff_entries(
        path,
        report_or_reports,
        &TimelineDiff.row_from_review_or_import_row/1
      )
    end)
  end
end
