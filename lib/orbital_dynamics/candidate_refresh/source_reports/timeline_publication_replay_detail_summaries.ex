defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelinePublicationReplayDetailSummaries do
  @moduledoc false

  @replay_detail_keys [
    "invalidated_downstream_product_ids",
    "downstream_invalidation_reason_counts",
    "invalidated_downstream_product_ids_by_reason",
    "dependency_impact_row_count",
    "impacted_source_activity_ids",
    "impacted_source_timeline_ids",
    "dependent_activity_ids",
    "dependent_timeline_ids",
    "source_dependent_activity_ids",
    "source_dependent_timeline_ids",
    "replacement_dependent_activity_ids",
    "replacement_dependent_timeline_ids",
    "impacted_dependency_activity_ids",
    "impacted_dependency_timeline_ids",
    "impacted_exclusive_with_activity_ids",
    "impacted_exclusive_with_timeline_ids",
    "timeline_diff_row_count",
    "timeline_diff_changed_count",
    "timeline_diff_review_required_count",
    "changed_field_counts",
    "changed_timeline_ids",
    "review_timeline_ids",
    "timeline_ids_by_changed_field"
  ]

  def replay_detail_summary?(%{} = summary) do
    Enum.any?(@replay_detail_keys, fn key -> present_replay_detail?(summary[key]) end)
  end

  defp present_replay_detail?(nil), do: false
  defp present_replay_detail?(""), do: false
  defp present_replay_detail?([]), do: false
  defp present_replay_detail?(%{} = value), do: map_size(value) > 0
  defp present_replay_detail?(value) when is_number(value), do: value != 0
  defp present_replay_detail?(_value), do: true
end
