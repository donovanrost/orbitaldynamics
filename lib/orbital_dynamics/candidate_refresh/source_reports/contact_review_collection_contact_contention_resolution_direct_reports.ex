defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactContentionResolutionDirectReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactContentionResolution

  def reports(refresh) do
    [
      {"accepted_planning_state.source_contact_contention_resolution_report",
       get_in(refresh, ["accepted_planning_state", "source_contact_contention_resolution_report"])},
      {"accepted_planning_state.contact_contention_resolution_report",
       get_in(refresh, ["accepted_planning_state", "contact_contention_resolution_report"])},
      {"accepted_planning_state.source_contact_contention_resolution_summary",
       get_in(refresh, [
         "accepted_planning_state",
         "source_contact_contention_resolution_summary"
       ])},
      {"accepted_planning_state.contact_contention_resolution_summary",
       get_in(refresh, ["accepted_planning_state", "contact_contention_resolution_summary"])},
      {"mission_state.source_contact_contention_resolution_report",
       get_in(refresh, ["mission_state", "source_contact_contention_resolution_report"])},
      {"mission_state.contact_contention_resolution_report",
       get_in(refresh, ["mission_state", "contact_contention_resolution_report"])},
      {"mission_state.source_contact_contention_resolution_summary",
       get_in(refresh, ["mission_state", "source_contact_contention_resolution_summary"])},
      {"mission_state.contact_contention_resolution_summary",
       get_in(refresh, ["mission_state", "contact_contention_resolution_summary"])},
      {"source_contact_contention_resolution_report",
       Map.get(refresh, "source_contact_contention_resolution_report")},
      {"contact_contention_resolution_report",
       Map.get(refresh, "contact_contention_resolution_report")},
      {"source_contact_contention_resolution_summary",
       Map.get(refresh, "source_contact_contention_resolution_summary")},
      {"contact_contention_resolution_summary",
       Map.get(refresh, "contact_contention_resolution_summary")}
    ]
    |> Enum.flat_map(fn {path, report_or_reports} ->
      ContactContentionResolution.entries(path, report_or_reports)
    end)
  end
end
