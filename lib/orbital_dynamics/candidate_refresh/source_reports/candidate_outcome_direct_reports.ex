defmodule OrbitalDynamics.CandidateRefresh.SourceReports.CandidateOutcomeDirectReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.CandidateDiff
  alias OrbitalDynamics.CandidateRefresh.SourceReports.CandidateRejection

  def candidate_diff_reports(refresh) do
    [
      {"accepted_planning_state.source_candidate_diff_report",
       get_in(refresh, ["accepted_planning_state", "source_candidate_diff_report"])},
      {"accepted_planning_state.candidate_diff_report",
       get_in(refresh, ["accepted_planning_state", "candidate_diff_report"])},
      {"mission_state.source_candidate_diff_report",
       get_in(refresh, ["mission_state", "source_candidate_diff_report"])},
      {"mission_state.candidate_diff_report",
       get_in(refresh, ["mission_state", "candidate_diff_report"])},
      {"source_candidate_diff_report", Map.get(refresh, "source_candidate_diff_report")},
      {"candidate_diff_report", Map.get(refresh, "candidate_diff_report")}
    ]
    |> Enum.flat_map(fn {path, report_or_reports} ->
      CandidateDiff.entries(path, report_or_reports)
    end)
  end

  def candidate_rejection_reports(refresh) do
    [
      {"accepted_planning_state.source_candidate_rejection_report",
       get_in(refresh, ["accepted_planning_state", "source_candidate_rejection_report"])},
      {"accepted_planning_state.candidate_rejection_report",
       get_in(refresh, ["accepted_planning_state", "candidate_rejection_report"])},
      {"mission_state.source_candidate_rejection_report",
       get_in(refresh, ["mission_state", "source_candidate_rejection_report"])},
      {"mission_state.candidate_rejection_report",
       get_in(refresh, ["mission_state", "candidate_rejection_report"])},
      {"source_candidate_rejection_report",
       Map.get(refresh, "source_candidate_rejection_report")},
      {"candidate_rejection_report", Map.get(refresh, "candidate_rejection_report")}
    ]
    |> Enum.flat_map(fn {path, report_or_reports} ->
      CandidateRejection.entries(path, report_or_reports)
    end)
  end
end
