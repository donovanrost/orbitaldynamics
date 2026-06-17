defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactContentionResolution.Summary.ResolutionFields do
  @moduledoc false

  def fields(resolution_summary) do
    %{
      "resolution_status_counts" => Map.get(resolution_summary, "resolution_status_counts", %{}),
      "selection_reason_counts" => Map.get(resolution_summary, "selection_reason_counts", %{}),
      "recommendation_group_ids" => Map.get(resolution_summary, "recommendation_group_ids", []),
      "review_group_ids" => Map.get(resolution_summary, "review_group_ids", []),
      "ambiguous_group_ids" => Map.get(resolution_summary, "ambiguous_group_ids", []),
      "ambiguous_duplicate_contact_ids" =>
        Map.get(resolution_summary, "ambiguous_duplicate_contact_ids", []),
      "ambiguous_duplicate_contact_ids_by_group_id" =>
        Map.get(resolution_summary, "ambiguous_duplicate_contact_ids_by_group_id", %{}),
      "selected_contact_ids" => Map.get(resolution_summary, "selected_contact_ids", []),
      "deferred_contact_ids" => Map.get(resolution_summary, "deferred_contact_ids", []),
      "review_contact_ids" => Map.get(resolution_summary, "review_contact_ids", []),
      "selected_contact_ids_by_group_id" =>
        Map.get(resolution_summary, "selected_contact_ids_by_group_id", %{}),
      "deferred_contact_ids_by_group_id" =>
        Map.get(resolution_summary, "deferred_contact_ids_by_group_id", %{}),
      "review_contact_ids_by_group_id" =>
        Map.get(resolution_summary, "review_contact_ids_by_group_id", %{}),
      "selected_contact_ids_by_selection_reason" =>
        Map.get(resolution_summary, "selected_contact_ids_by_selection_reason", %{}),
      "selected_contact_ids_by_ground_station" =>
        Map.get(resolution_summary, "selected_contact_ids_by_ground_station", %{}),
      "deferred_contact_ids_by_ground_station" =>
        Map.get(resolution_summary, "deferred_contact_ids_by_ground_station", %{}),
      "resource_scope_counts" => Map.get(resolution_summary, "resource_scope_counts", %{}),
      "selected_contact_ids_by_resource_scope" =>
        Map.get(resolution_summary, "selected_contact_ids_by_resource_scope", %{}),
      "deferred_contact_ids_by_resource_scope" =>
        Map.get(resolution_summary, "deferred_contact_ids_by_resource_scope", %{}),
      "review_contact_ids_by_resource_scope" =>
        Map.get(resolution_summary, "review_contact_ids_by_resource_scope", %{}),
      "direction_counts" => Map.get(resolution_summary, "direction_counts", %{}),
      "contact_ids_by_direction" => Map.get(resolution_summary, "contact_ids_by_direction", %{}),
      "direction_routing" => Map.get(resolution_summary, "direction_routing", %{}),
      "required_operator_action_counts" =>
        Map.get(resolution_summary, "required_operator_action_counts", %{}),
      "review_contact_ids_by_action" =>
        Map.get(resolution_summary, "review_contact_ids_by_action", %{})
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
end
