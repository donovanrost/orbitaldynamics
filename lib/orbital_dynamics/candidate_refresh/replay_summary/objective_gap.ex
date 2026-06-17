defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ObjectiveGap do
  @moduledoc false

  alias __MODULE__.SourceReportFields
  alias __MODULE__.Summary

  def replay(refresh_or_artifact, callbacks) do
    source_report_summary = Keyword.fetch!(callbacks, :source_report_summary)

    source_reports =
      refresh_or_artifact
      |> source_report_summary.()
      |> Map.get("source_reports", %{})

    summary_from_source_reports(source_reports)
  end

  def summary(satisfaction_summary, tradeoff_summary, score_term_summary) do
    Summary.summary(satisfaction_summary, tradeoff_summary, score_term_summary)
  end

  def source_report_fields(source_reports) do
    SourceReportFields.source_report_fields(source_reports)
  end

  defp summary_from_source_reports(source_reports) do
    summary(
      Map.get(source_reports, "objective_satisfaction_report", %{}),
      Map.get(source_reports, "objective_tradeoff_report", %{}),
      Map.get(source_reports, "score_term_report", %{})
    )
  end
end
