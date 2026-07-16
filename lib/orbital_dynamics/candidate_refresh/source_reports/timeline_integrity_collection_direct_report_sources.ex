defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineIntegrityCollectionDirectReportSources do
  @moduledoc false

  def sources(refresh) do
    [
      {"accepted_planning_state.source_timeline_integrity_report",
       get_in(refresh, ["accepted_planning_state", "source_timeline_integrity_report"])},
      {"accepted_planning_state.timeline_integrity_report",
       get_in(refresh, ["accepted_planning_state", "timeline_integrity_report"])},
      {"mission_state.source_timeline_integrity_report",
       get_in(refresh, ["mission_state", "source_timeline_integrity_report"])},
      {"mission_state.timeline_integrity_report",
       get_in(refresh, ["mission_state", "timeline_integrity_report"])},
      {"source_timeline_integrity_report", Map.get(refresh, "source_timeline_integrity_report")},
      {"timeline_integrity_report", Map.get(refresh, "timeline_integrity_report")}
    ]
  end
end
