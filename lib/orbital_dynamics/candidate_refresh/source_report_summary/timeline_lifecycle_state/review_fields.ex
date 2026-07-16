defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineLifecycleState.ReviewFields do
  @moduledoc false

  alias __MODULE__.RouteMap

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_string_list_maps: 1,
      sorted_string_values: 1
    ]

  def fields(summaries) do
    %{
      "recordable_timeline_ids" => list_values(summaries, "recordable_timeline_ids"),
      "preserved_timeline_ids" => list_values(summaries, "preserved_timeline_ids"),
      "review_timeline_ids" => list_values(summaries, "review_timeline_ids"),
      "review_activity_ids" => list_values(summaries, "review_activity_ids"),
      "review_timeline_ids_by_required_operator_action" =>
        list_values_by(summaries, "review_timeline_ids_by_required_operator_action"),
      "review_timeline_ids_by_status_transition_category" =>
        list_values_by(summaries, "review_timeline_ids_by_status_transition_category"),
      "review_timeline_ids_by_approval_transition_category" =>
        list_values_by(summaries, "review_timeline_ids_by_approval_transition_category"),
      "review_routing" => RouteMap.build(summaries)
    }
  end

  defp list_values(summaries, field) do
    summaries
    |> Enum.flat_map(&Map.get(&1, field, []))
    |> sorted_string_values()
  end

  defp list_values_by(summaries, field) do
    summaries
    |> Enum.map(&Map.get(&1, field, %{}))
    |> merge_string_list_maps()
  end
end
