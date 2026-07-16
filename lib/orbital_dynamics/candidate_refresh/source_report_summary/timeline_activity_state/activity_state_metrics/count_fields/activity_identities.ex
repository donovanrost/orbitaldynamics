defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityState.ActivityStateMetrics.CountFields.ActivityIdentities do
  @moduledoc false

  alias __MODULE__.IdentityValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_source_report_values: 1,
      merge_count_maps: 1
    ]

  def fields(states) do
    %{
      "activity_id_counts" => activity_id_count_map(states, "activity_id"),
      "timeline_id_counts" => activity_id_count_map(states, "timeline_id"),
      "review_activity_id_counts" => count_map(states, &IdentityValues.review_activity_ids/1)
    }
  end

  defp activity_id_count_map(states, field) do
    count_map(states, &IdentityValues.ids(&1, field))
  end

  defp count_map(states, row_values) do
    states
    |> Enum.map(fn state ->
      state
      |> row_values.()
      |> count_source_report_values()
    end)
    |> merge_count_maps()
  end
end
