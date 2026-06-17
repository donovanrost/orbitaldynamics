defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivityLifecycleState.Summary.Pressure do
  @moduledoc false

  def fields(lifecycle_fields, counts) do
    invalid_activity_input_reason_counts =
      Map.get(lifecycle_fields, "invalid_activity_input_reason_counts", %{})

    transition_decision_counts = Map.get(lifecycle_fields, "transition_decision_counts", %{})

    status_transition_decision_counts =
      Map.get(lifecycle_fields, "status_transition_decision_counts", %{})

    approval_transition_decision_counts =
      Map.get(lifecycle_fields, "approval_transition_decision_counts", %{})

    required_action_counts = Map.get(lifecycle_fields, "required_operator_action_counts", %{})
    planned_status_counts = Map.get(lifecycle_fields, "planned_status_category_counts", %{})
    realized_status_counts = Map.get(lifecycle_fields, "realized_status_category_counts", %{})
    planned_approval_counts = Map.get(lifecycle_fields, "planned_approval_category_counts", %{})

    realized_approval_counts =
      Map.get(lifecycle_fields, "realized_approval_category_counts", %{})

    status_transition_counts = Map.get(lifecycle_fields, "status_transition_category_counts", %{})

    approval_transition_counts =
      Map.get(lifecycle_fields, "approval_transition_category_counts", %{})

    transition_application_provenance_helper_counts =
      Map.get(lifecycle_fields, "transition_application_provenance_helper_counts", %{})

    transition_application_provenance_category_counts =
      Map.get(lifecycle_fields, "transition_application_provenance_category_counts", %{})

    transition_application_provenance_operator_action_reason_counts =
      Map.get(
        lifecycle_fields,
        "transition_application_provenance_operator_action_reason_counts",
        %{}
      )

    protection_decision_counts = Map.get(lifecycle_fields, "protection_decision_counts", %{})
    protection_category_counts = Map.get(lifecycle_fields, "protection_category_counts", %{})
    activity_id_counts = Map.get(lifecycle_fields, "activity_id_counts", %{})
    timeline_id_counts = Map.get(lifecycle_fields, "timeline_id_counts", %{})
    review_activity_id_counts = Map.get(lifecycle_fields, "review_activity_id_counts", %{})
    action_routing = Map.get(lifecycle_fields, "action_routing", %{})

    review_action_counts =
      required_action_counts
      |> Enum.filter(fn {action, _count} ->
        is_binary(action) and String.starts_with?(action, "review")
      end)
      |> Map.new()

    lifecycle_evidence_pressure =
      counts.row_count > 0 or counts.invalid_activity_input_count > 0 or
        map_size(invalid_activity_input_reason_counts) > 0 or
        map_size(transition_decision_counts) > 0 or
        map_size(status_transition_decision_counts) > 0 or
        map_size(approval_transition_decision_counts) > 0 or
        map_size(planned_status_counts) > 0 or map_size(realized_status_counts) > 0 or
        map_size(planned_approval_counts) > 0 or map_size(realized_approval_counts) > 0 or
        map_size(status_transition_counts) > 0 or map_size(approval_transition_counts) > 0 or
        counts.transition_application_provenance_count > 0 or
        map_size(transition_application_provenance_helper_counts) > 0 or
        map_size(transition_application_provenance_category_counts) > 0 or
        map_size(transition_application_provenance_operator_action_reason_counts) > 0 or
        map_size(protection_decision_counts) > 0 or map_size(protection_category_counts) > 0

    review_pressure =
      counts.review_required_count > 0 or map_size(review_action_counts) > 0 or
        map_size(review_activity_id_counts) > 0

    routing_pressure =
      map_size(activity_id_counts) > 0 or map_size(timeline_id_counts) > 0 or
        map_size(review_activity_id_counts) > 0 or map_size(action_routing) > 0

    %{
      "branch_local_timeline_activity_lifecycle_state_pressure" =>
        lifecycle_evidence_pressure or review_pressure or routing_pressure,
      "branch_local_activity_lifecycle_review_pressure" => review_pressure,
      "branch_local_activity_lifecycle_action_pressure" => map_size(action_routing) > 0,
      "branch_local_activity_lifecycle_routing_pressure" => routing_pressure
    }
  end
end
