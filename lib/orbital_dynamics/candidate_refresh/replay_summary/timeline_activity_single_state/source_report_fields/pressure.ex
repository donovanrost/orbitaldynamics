defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivitySingleState.SourceReportFields.Pressure do
  @moduledoc false

  def source_report_fields(family, summary) do
    %{
      "source_report_#{family}_branch_local_#{family}_pressure" =>
        Map.get(summary, "branch_local_#{family}_pressure"),
      "source_report_#{family}_branch_local_review_pressure" =>
        Map.get(summary, "branch_local_#{family}_review_pressure"),
      "source_report_#{family}_branch_local_action_pressure" =>
        Map.get(summary, "branch_local_#{family}_action_pressure"),
      "source_report_#{family}_branch_local_routing_pressure" =>
        Map.get(summary, "branch_local_#{family}_routing_pressure")
    }
  end
end
