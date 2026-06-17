defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivitySingleState.Summary.StateFields do
  @moduledoc false

  def fields(state_summary, opts \\ []) do
    source_summary_empty = Keyword.get(opts, :source_summary_empty, nil)
    action_routing_nil = Keyword.get(opts, :action_routing_nil, :empty)

    %{
      "source_summary_model_counts" =>
        state_summary
        |> Map.get("source_summary_model_counts", %{})
        |> source_summary_counts(source_summary_empty),
      "source_summary_schema_contract_counts" =>
        state_summary
        |> Map.get("source_summary_schema_contract_counts", %{})
        |> source_summary_counts(source_summary_empty),
      "invalid_activity_input_reason_counts" =>
        Map.get(state_summary, "invalid_activity_input_reason_counts", %{}),
      "invalid_activity_input_reasons" =>
        Map.get(state_summary, "invalid_activity_input_reasons", []),
      "transition_decision_counts" => Map.get(state_summary, "transition_decision_counts", %{}),
      "required_operator_action_counts" =>
        Map.get(state_summary, "required_operator_action_counts", %{}),
      "import_action_counts" => Map.get(state_summary, "import_action_counts", %{}),
      "planned_status_category_counts" =>
        Map.get(state_summary, "planned_status_category_counts", %{}),
      "realized_status_category_counts" =>
        Map.get(state_summary, "realized_status_category_counts", %{}),
      "planned_approval_category_counts" =>
        Map.get(state_summary, "planned_approval_category_counts", %{}),
      "realized_approval_category_counts" =>
        Map.get(state_summary, "realized_approval_category_counts", %{}),
      "status_transition_category_counts" =>
        Map.get(state_summary, "status_transition_category_counts", %{}),
      "approval_transition_category_counts" =>
        Map.get(state_summary, "approval_transition_category_counts", %{}),
      "activity_id_counts" => Map.get(state_summary, "activity_id_counts", %{}),
      "timeline_id_counts" => Map.get(state_summary, "timeline_id_counts", %{}),
      "review_activity_id_counts" => Map.get(state_summary, "review_activity_id_counts", %{}),
      "action_routing" =>
        state_summary
        |> Map.get("action_routing", %{})
        |> action_routing(action_routing_nil)
    }
  end

  defp action_routing(%{} = map, _action_routing_nil), do: map
  defp action_routing(nil, :preserve), do: nil
  defp action_routing(_map, :empty), do: %{}

  defp source_summary_counts(map, :preserve), do: map
  defp source_summary_counts(map, nil) when map_size(map) == 0, do: nil
  defp source_summary_counts(map, nil), do: map
end
