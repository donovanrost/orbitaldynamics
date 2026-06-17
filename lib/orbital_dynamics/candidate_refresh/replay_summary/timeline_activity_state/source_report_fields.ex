defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivityState.SourceReportFields do
  @moduledoc false

  alias __MODULE__.Flattened

  def source_report_fields(source_reports, summary) do
    source_reports
    |> Flattened.source_report_fields()
    |> Map.merge(%{
      "source_report_timeline_activity_state_branch_local_timeline_activity_state_pressure" =>
        Map.get(summary, "branch_local_timeline_activity_state_pressure"),
      "source_report_timeline_activity_state_branch_local_review_pressure" =>
        Map.get(summary, "branch_local_activity_state_review_pressure"),
      "source_report_timeline_activity_state_branch_local_action_pressure" =>
        Map.get(summary, "branch_local_activity_state_action_pressure"),
      "source_report_timeline_activity_state_branch_local_routing_pressure" =>
        Map.get(summary, "branch_local_activity_state_routing_pressure")
    })
    |> compact_map()
  end

  defp compact_map(map) when is_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
