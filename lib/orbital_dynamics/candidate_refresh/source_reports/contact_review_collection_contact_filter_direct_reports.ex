defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactFilterDirectReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactFilter

  def reports(refresh) do
    refresh
    |> sources()
    |> Enum.flat_map(fn {path, report_or_reports} ->
      ContactFilter.entries(path, report_or_reports)
    end)
  end

  defp sources(refresh) do
    [
      {"accepted_planning_state.source_contact_filter_report",
       get_in(refresh, ["accepted_planning_state", "source_contact_filter_report"])},
      {"accepted_planning_state.contact_filter_report",
       get_in(refresh, ["accepted_planning_state", "contact_filter_report"])},
      {"mission_state.source_contact_filter_report",
       get_in(refresh, ["mission_state", "source_contact_filter_report"])},
      {"mission_state.contact_filter_report",
       get_in(refresh, ["mission_state", "contact_filter_report"])},
      {"source_contact_filter_report", Map.get(refresh, "source_contact_filter_report")},
      {"contact_filter_report", Map.get(refresh, "contact_filter_report")}
    ]
  end
end
