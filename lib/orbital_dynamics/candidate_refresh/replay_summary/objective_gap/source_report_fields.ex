defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ObjectiveGap.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ObjectiveGap.Summary
  alias __MODULE__.Flattened

  def source_report_fields(source_reports) do
    summary = summary_from_source_reports(source_reports)

    %{
      "source_report_objective_gap_branch_local_objective_gap_pressure" =>
        Map.get(summary, "branch_local_objective_gap_pressure"),
      "source_report_objective_gap_branch_local_downlink_gap_pressure" =>
        Map.get(summary, "branch_local_downlink_gap_pressure"),
      "source_report_objective_gap_branch_local_target_gap_pressure" =>
        Map.get(summary, "branch_local_target_gap_pressure"),
      "source_report_objective_gap_branch_local_collection_latency_gap_pressure" =>
        Map.get(summary, "branch_local_collection_latency_gap_pressure"),
      "source_report_objective_gap_branch_local_objective_status_pressure" =>
        Map.get(summary, "branch_local_objective_status_pressure"),
      "source_report_objective_gap_branch_local_score_term_pressure" =>
        Map.get(summary, "branch_local_score_term_pressure"),
      "source_report_objective_gap_branch_local_routing_pressure" =>
        Map.get(summary, "branch_local_routing_pressure")
    }
    |> Map.merge(Flattened.fields(source_reports))
  end

  defp summary_from_source_reports(source_reports) do
    Summary.summary(
      Map.get(source_reports, "objective_satisfaction_report", %{}),
      Map.get(source_reports, "objective_tradeoff_report", %{}),
      Map.get(source_reports, "score_term_report", %{})
    )
  end
end
