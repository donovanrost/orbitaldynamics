defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.Constraint.SourceReportFields do
  @moduledoc false

  alias __MODULE__.Flattened

  def source_report_fields(source_reports, summary) do
    %{
      "source_report_constraint_branch_local_constraint_pressure" =>
        Map.get(summary, "branch_local_constraint_pressure"),
      "source_report_constraint_branch_local_downlink_gap_pressure" =>
        Map.get(summary, "branch_local_downlink_gap_pressure"),
      "source_report_constraint_branch_local_resource_margin_pressure" =>
        Map.get(summary, "branch_local_resource_margin_pressure"),
      "source_report_constraint_branch_local_constraint_routing_pressure" =>
        Map.get(summary, "branch_local_constraint_routing_pressure")
    }
    |> Map.merge(Flattened.fields(source_reports))
  end
end
