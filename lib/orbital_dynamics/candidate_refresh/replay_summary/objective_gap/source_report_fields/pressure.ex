defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ObjectiveGap.SourceReportFields.Pressure do
  @moduledoc false

  def source_report_fields(summary) do
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
  end
end
