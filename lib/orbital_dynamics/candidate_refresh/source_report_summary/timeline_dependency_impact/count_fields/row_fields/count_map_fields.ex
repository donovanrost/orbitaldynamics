defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDependencyImpact.CountFields.RowFields.CountMapFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDependencyImpact.CountFields.RowCounts

  def fields(reports) do
    %{
      "dependency_impact_status_counts" =>
        RowCounts.count_map(
          reports,
          &RowCounts.row_counts(
            &1,
            "dependency_impact_status_counts",
            "dependency_impact_status"
          )
        ),
      "dependency_impact_scope_counts" =>
        RowCounts.count_map(
          reports,
          &RowCounts.row_counts(&1, "dependency_impact_scope_counts", "scope")
        ),
      "required_operator_action_counts" =>
        RowCounts.count_map(
          reports,
          &RowCounts.row_counts(
            &1,
            "required_operator_action_counts",
            "required_operator_action"
          )
        )
    }
  end
end
