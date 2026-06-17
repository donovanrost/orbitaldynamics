defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivitySingleState.Summary.Pressure do
  @moduledoc false

  def fields(family, state_fields, counts) do
    invalid_activity_input_reason_counts =
      Map.get(state_fields, "invalid_activity_input_reason_counts", %{})

    transition_decision_counts = Map.get(state_fields, "transition_decision_counts", %{})
    import_action_counts = Map.get(state_fields, "import_action_counts", %{})
    planned_status_counts = Map.get(state_fields, "planned_status_category_counts", %{})
    realized_status_counts = Map.get(state_fields, "realized_status_category_counts", %{})
    planned_approval_counts = Map.get(state_fields, "planned_approval_category_counts", %{})

    realized_approval_counts =
      Map.get(state_fields, "realized_approval_category_counts", %{})

    status_transition_counts = Map.get(state_fields, "status_transition_category_counts", %{})

    approval_transition_counts =
      Map.get(state_fields, "approval_transition_category_counts", %{})

    required_action_counts = Map.get(state_fields, "required_operator_action_counts", %{})
    activity_id_counts = Map.get(state_fields, "activity_id_counts", %{})
    timeline_id_counts = Map.get(state_fields, "timeline_id_counts", %{})
    review_activity_id_counts = Map.get(state_fields, "review_activity_id_counts", %{})
    action_routing = Map.get(state_fields, "action_routing", %{})

    review_action_counts =
      required_action_counts
      |> Enum.filter(fn {action, _count} ->
        is_binary(action) and String.starts_with?(action, "review")
      end)
      |> Map.new()

    state_evidence_pressure =
      counts.row_count > 0 or counts.invalid_activity_input_count > 0 or
        map_size(invalid_activity_input_reason_counts) > 0 or
        map_size(transition_decision_counts) > 0 or
        map_size(import_action_counts) > 0 or map_size(planned_status_counts) > 0 or
        map_size(realized_status_counts) > 0 or map_size(planned_approval_counts) > 0 or
        map_size(realized_approval_counts) > 0 or map_size(status_transition_counts) > 0 or
        map_size(approval_transition_counts) > 0

    review_pressure =
      counts.review_required_count > 0 or map_size(review_action_counts) > 0 or
        map_size(review_activity_id_counts) > 0

    routing_pressure =
      map_size(activity_id_counts) > 0 or map_size(timeline_id_counts) > 0 or
        map_size(review_activity_id_counts) > 0 or map_size(action_routing) > 0

    %{
      "branch_local_#{family}_pressure" =>
        state_evidence_pressure or review_pressure or routing_pressure,
      "branch_local_#{family}_review_pressure" => review_pressure,
      "branch_local_#{family}_action_pressure" => map_size(action_routing) > 0,
      "branch_local_#{family}_routing_pressure" => routing_pressure
    }
  end
end
