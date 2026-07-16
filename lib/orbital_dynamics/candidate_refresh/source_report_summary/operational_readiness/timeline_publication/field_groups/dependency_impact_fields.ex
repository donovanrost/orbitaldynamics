defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.TimelinePublication.FieldGroups.DependencyImpactFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.Evidence

  def values(reports) do
    %{
      "dependency_impact_row_count" => Evidence.count_sum(reports, "dependency_impact_row_count"),
      "impacted_dependency_activity_ids" =>
        Evidence.string_values(reports, "impacted_dependency_activity_ids"),
      "impacted_dependency_timeline_ids" =>
        Evidence.string_values(reports, "impacted_dependency_timeline_ids"),
      "impacted_exclusive_with_activity_ids" =>
        Evidence.string_values(reports, "impacted_exclusive_with_activity_ids"),
      "impacted_exclusive_with_timeline_ids" =>
        Evidence.string_values(reports, "impacted_exclusive_with_timeline_ids")
    }
  end
end
