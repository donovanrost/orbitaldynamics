defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.Summary.ResolutionFields do
  @moduledoc false

  def fields(resolution_summary) do
    selection_reason_counts =
      count_map_or_empty(Map.get(resolution_summary, "selection_reason_counts"))

    resource_scope_counts =
      count_map_or_empty(Map.get(resolution_summary, "resource_scope_counts"))

    required_operator_action_counts =
      count_map_or_empty(
        Map.get(resolution_summary, "required_operator_action_counts") ||
          Map.get(resolution_summary, "action_counts")
      )

    recommendation_group_ids =
      list_or_empty(Map.get(resolution_summary, "recommendation_group_ids"))

    review_group_ids =
      lineage_group_ids(resolution_summary, "review_group_ids", recommendation_group_ids)

    ambiguous_group_ids =
      lineage_group_ids(resolution_summary, "ambiguous_group_ids", recommendation_group_ids)

    %{
      "resolution_status_counts" => Map.get(resolution_summary, "resolution_status_counts", %{}),
      "selection_reason_counts" => selection_reason_counts,
      "recommendation_group_ids" => recommendation_group_ids,
      "review_group_ids" => review_group_ids,
      "ambiguous_group_ids" => ambiguous_group_ids,
      "ambiguous_duplicate_contact_ids" =>
        Map.get(resolution_summary, "ambiguous_duplicate_contact_ids", []),
      "ambiguous_duplicate_contact_ids_by_group_id" =>
        take_group_keys(
          resolution_summary,
          "ambiguous_duplicate_contact_ids_by_group_id",
          ambiguous_group_ids
        ),
      "selected_contact_ids" => Map.get(resolution_summary, "selected_contact_ids", []),
      "deferred_contact_ids" => Map.get(resolution_summary, "deferred_contact_ids", []),
      "review_contact_ids" => Map.get(resolution_summary, "review_contact_ids", []),
      "selected_contact_ids_by_group_id" =>
        take_group_keys(
          resolution_summary,
          "selected_contact_ids_by_group_id",
          recommendation_group_ids
        ),
      "deferred_contact_ids_by_group_id" =>
        take_group_keys(
          resolution_summary,
          "deferred_contact_ids_by_group_id",
          recommendation_group_ids
        ),
      "review_contact_ids_by_group_id" =>
        take_group_keys(resolution_summary, "review_contact_ids_by_group_id", review_group_ids),
      "selected_contact_ids_by_selection_reason" =>
        take_positive_count_keys(
          resolution_summary,
          "selected_contact_ids_by_selection_reason",
          selection_reason_counts
        ),
      "selected_contact_ids_by_ground_station" =>
        Map.get(resolution_summary, "selected_contact_ids_by_ground_station", %{}),
      "deferred_contact_ids_by_ground_station" =>
        Map.get(resolution_summary, "deferred_contact_ids_by_ground_station", %{}),
      "resource_scope_counts" => resource_scope_counts,
      "selected_contact_ids_by_resource_scope" =>
        take_positive_count_keys(
          resolution_summary,
          "selected_contact_ids_by_resource_scope",
          resource_scope_counts
        ),
      "deferred_contact_ids_by_resource_scope" =>
        take_positive_count_keys(
          resolution_summary,
          "deferred_contact_ids_by_resource_scope",
          resource_scope_counts
        ),
      "review_contact_ids_by_resource_scope" =>
        take_positive_count_keys(
          resolution_summary,
          "review_contact_ids_by_resource_scope",
          resource_scope_counts
        ),
      "direction_counts" => Map.get(resolution_summary, "direction_counts", %{}),
      "contact_ids_by_direction" => Map.get(resolution_summary, "contact_ids_by_direction", %{}),
      "direction_routing" => Map.get(resolution_summary, "direction_routing", %{}),
      "required_operator_action_counts" => required_operator_action_counts,
      "review_contact_ids_by_action" =>
        take_positive_count_keys(
          resolution_summary,
          "review_contact_ids_by_action",
          required_operator_action_counts
        )
    }
  end

  def output_fields(fields) do
    %{
      "recommendation_group_ids" =>
        non_empty_list(Map.fetch!(fields, "recommendation_group_ids")),
      "review_group_ids" => non_empty_list(Map.fetch!(fields, "review_group_ids")),
      "ambiguous_group_ids" => non_empty_list(Map.fetch!(fields, "ambiguous_group_ids")),
      "ambiguous_duplicate_contact_ids" =>
        non_empty_list(Map.fetch!(fields, "ambiguous_duplicate_contact_ids")),
      "ambiguous_duplicate_contact_ids_by_group_id" =>
        non_empty_map(Map.fetch!(fields, "ambiguous_duplicate_contact_ids_by_group_id")),
      "resolution_status_counts" => Map.fetch!(fields, "resolution_status_counts"),
      "selection_reason_counts" => Map.fetch!(fields, "selection_reason_counts"),
      "selected_contact_ids" => Map.fetch!(fields, "selected_contact_ids"),
      "deferred_contact_ids" => Map.fetch!(fields, "deferred_contact_ids"),
      "review_contact_ids" => non_empty_list(Map.fetch!(fields, "review_contact_ids")),
      "selected_contact_ids_by_group_id" =>
        non_empty_map(Map.fetch!(fields, "selected_contact_ids_by_group_id")),
      "deferred_contact_ids_by_group_id" =>
        non_empty_map(Map.fetch!(fields, "deferred_contact_ids_by_group_id")),
      "review_contact_ids_by_group_id" =>
        non_empty_map(Map.fetch!(fields, "review_contact_ids_by_group_id")),
      "selected_contact_ids_by_selection_reason" =>
        non_empty_map(Map.fetch!(fields, "selected_contact_ids_by_selection_reason")),
      "selected_contact_ids_by_ground_station" =>
        Map.fetch!(fields, "selected_contact_ids_by_ground_station"),
      "deferred_contact_ids_by_ground_station" =>
        Map.fetch!(fields, "deferred_contact_ids_by_ground_station"),
      "resource_scope_counts" => non_empty_map(Map.fetch!(fields, "resource_scope_counts")),
      "selected_contact_ids_by_resource_scope" =>
        non_empty_map(Map.fetch!(fields, "selected_contact_ids_by_resource_scope")),
      "deferred_contact_ids_by_resource_scope" =>
        non_empty_map(Map.fetch!(fields, "deferred_contact_ids_by_resource_scope")),
      "review_contact_ids_by_resource_scope" =>
        non_empty_map(Map.fetch!(fields, "review_contact_ids_by_resource_scope")),
      "direction_counts" => Map.fetch!(fields, "direction_counts"),
      "contact_ids_by_direction" => Map.fetch!(fields, "contact_ids_by_direction"),
      "direction_routing" => Map.fetch!(fields, "direction_routing"),
      "required_operator_action_counts" => Map.fetch!(fields, "required_operator_action_counts"),
      "review_contact_ids_by_action" =>
        non_empty_map(Map.fetch!(fields, "review_contact_ids_by_action"))
    }
  end

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map

  defp non_empty_list([]), do: nil
  defp non_empty_list(list), do: list

  defp take_group_keys(summary, field, group_ids) when is_list(group_ids) do
    case Map.get(summary, field) do
      %{} = values -> Map.take(values, group_ids)
      _values -> %{}
    end
  end

  defp take_positive_count_keys(summary, field, counts) when is_map(counts) do
    case Map.get(summary, field) do
      %{} = values ->
        positive_count_keys =
          for {key, count} <- counts, is_integer(count) and count > 0, do: key

        Map.take(values, positive_count_keys)

      _values ->
        %{}
    end
  end

  defp lineage_group_ids(summary, field, allowed_group_ids) when is_list(allowed_group_ids) do
    summary
    |> Map.get(field, [])
    |> List.wrap()
    |> Enum.filter(&(&1 in allowed_group_ids))
  end

  defp list_or_empty(values) when is_list(values), do: values
  defp list_or_empty(_values), do: []

  defp count_map_or_empty(values) when is_map(values), do: values
  defp count_map_or_empty(_values), do: %{}
end
