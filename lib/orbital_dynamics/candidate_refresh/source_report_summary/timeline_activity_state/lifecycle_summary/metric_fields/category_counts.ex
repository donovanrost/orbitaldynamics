defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.LifecycleSummary.MetricFields.CategoryCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.LifecycleStateMetrics.ValueCounts

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_count_maps: 1]

  def fields(states) do
    %{
      "import_action_counts" => category_field_counts(states, "import_action"),
      "planned_status_category_counts" =>
        category_field_counts(states, "planned_status_category"),
      "realized_status_category_counts" =>
        category_field_counts(states, "realized_status_category"),
      "planned_approval_category_counts" =>
        category_field_counts(states, "planned_approval_category"),
      "realized_approval_category_counts" =>
        category_field_counts(states, "realized_approval_category")
    }
  end

  defp category_field_counts(states, field) do
    states
    |> Enum.map(&ValueCounts.field_counts(&1, field))
    |> merge_count_maps()
  end
end
