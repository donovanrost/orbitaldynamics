defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ObjectiveGap do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary
  alias __MODULE__.Summary

  def replay(refresh_or_artifact) do
    source_reports =
      refresh_or_artifact
      |> SourceReportSummary.build()
      |> Map.get("source_reports", %{})

    summary_from_source_reports(source_reports)
  end

  def summary(satisfaction_summary, tradeoff_summary, score_term_summary) do
    Summary.summary(satisfaction_summary, tradeoff_summary, score_term_summary)
  end

  defp summary_from_source_reports(source_reports) do
    summary(
      Map.get(source_reports, "objective_satisfaction_report", %{}),
      Map.get(source_reports, "objective_tradeoff_report", %{}),
      Map.get(source_reports, "score_term_report", %{})
    )
  end
end
