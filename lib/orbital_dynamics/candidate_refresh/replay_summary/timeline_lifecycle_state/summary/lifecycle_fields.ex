defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineLifecycleState.Summary.LifecycleFields do
  @moduledoc false

  def fields(lifecycle_summary) do
    %{
      "source_summary_model_counts" =>
        lifecycle_summary
        |> Map.get("source_summary_model_counts", %{})
        |> non_empty_map(),
      "source_summary_schema_contract_counts" =>
        lifecycle_summary
        |> Map.get("source_summary_schema_contract_counts", %{})
        |> non_empty_map(),
      "invalid_activity_input_ids" =>
        Map.get(lifecycle_summary, "invalid_activity_input_ids", []),
      "transition_decision_counts" =>
        Map.get(lifecycle_summary, "transition_decision_counts", %{}),
      "required_operator_action_counts" =>
        Map.get(lifecycle_summary, "required_operator_action_counts", %{}),
      "import_action_counts" => Map.get(lifecycle_summary, "import_action_counts", %{}),
      "planned_status_category_counts" =>
        Map.get(lifecycle_summary, "planned_status_category_counts", %{}),
      "realized_status_category_counts" =>
        Map.get(lifecycle_summary, "realized_status_category_counts", %{}),
      "planned_approval_category_counts" =>
        Map.get(lifecycle_summary, "planned_approval_category_counts", %{}),
      "realized_approval_category_counts" =>
        Map.get(lifecycle_summary, "realized_approval_category_counts", %{}),
      "status_transition_category_counts" =>
        Map.get(lifecycle_summary, "status_transition_category_counts", %{}),
      "approval_transition_category_counts" =>
        Map.get(lifecycle_summary, "approval_transition_category_counts", %{}),
      "transition_application_provenance_helper_counts" =>
        Map.get(lifecycle_summary, "transition_application_provenance_helper_counts", %{}),
      "transition_application_provenance_category_counts" =>
        Map.get(lifecycle_summary, "transition_application_provenance_category_counts", %{}),
      "transition_application_provenance_operator_action_reason_counts" =>
        Map.get(
          lifecycle_summary,
          "transition_application_provenance_operator_action_reason_counts",
          %{}
        ),
      "recordable_timeline_ids" => Map.get(lifecycle_summary, "recordable_timeline_ids", []),
      "preserved_timeline_ids" => Map.get(lifecycle_summary, "preserved_timeline_ids", []),
      "review_timeline_ids" => Map.get(lifecycle_summary, "review_timeline_ids", []),
      "review_activity_ids" => Map.get(lifecycle_summary, "review_activity_ids", []),
      "review_timeline_ids_by_required_operator_action" =>
        Map.get(lifecycle_summary, "review_timeline_ids_by_required_operator_action", %{}),
      "review_timeline_ids_by_status_transition_category" =>
        Map.get(lifecycle_summary, "review_timeline_ids_by_status_transition_category", %{}),
      "review_timeline_ids_by_approval_transition_category" =>
        Map.get(lifecycle_summary, "review_timeline_ids_by_approval_transition_category", %{}),
      "review_routing" =>
        lifecycle_summary
        |> Map.get("review_routing", %{})
        |> empty_map_if_nil()
    }
  end

  defp empty_map_if_nil(%{} = map), do: map
  defp empty_map_if_nil(_map), do: %{}

  defp non_empty_map(map) when map_size(map) == 0, do: nil
  defp non_empty_map(map), do: map
end
