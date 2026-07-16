defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ScoreTermCollectionDirectReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ScoreTerm

  def reports(refresh) do
    [
      {"accepted_planning_state.source_score_term_report",
       get_in(refresh, ["accepted_planning_state", "source_score_term_report"])},
      {"accepted_planning_state.score_term_report",
       get_in(refresh, ["accepted_planning_state", "score_term_report"])},
      {"mission_state.source_score_term_report",
       get_in(refresh, ["mission_state", "source_score_term_report"])},
      {"mission_state.score_term_report",
       get_in(refresh, ["mission_state", "score_term_report"])},
      {"source_score_term_report", Map.get(refresh, "source_score_term_report")},
      {"score_term_report", Map.get(refresh, "score_term_report")}
    ]
    |> Enum.flat_map(fn {path, report_or_reports} ->
      ScoreTerm.entries(path, report_or_reports)
    end)
  end
end
