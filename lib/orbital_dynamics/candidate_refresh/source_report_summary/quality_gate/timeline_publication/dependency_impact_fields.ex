defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.TimelinePublication.DependencyImpactFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.TimelinePublication.FieldGroups

  def fields(reports) do
    %{
      "dependency_impact_status_counts" =>
        FieldGroups.count_map(reports, "dependency_impact_status_counts"),
      "dependency_impact_row_count" =>
        FieldGroups.row_count(reports, "dependency_impact_row_count"),
      "impacted_dependency_activity_ids" =>
        FieldGroups.string_values(reports, "impacted_dependency_activity_ids"),
      "impacted_dependency_timeline_ids" =>
        FieldGroups.string_values(reports, "impacted_dependency_timeline_ids"),
      "impacted_exclusive_with_activity_ids" =>
        FieldGroups.string_values(reports, "impacted_exclusive_with_activity_ids"),
      "impacted_exclusive_with_timeline_ids" =>
        FieldGroups.string_values(reports, "impacted_exclusive_with_timeline_ids")
    }
  end
end
