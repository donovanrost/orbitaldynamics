defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineLifecycleState.Summary.Pressure do
  @moduledoc false

  def fields(lifecycle_fields, counts) do
    transition_decision_counts = Map.get(lifecycle_fields, "transition_decision_counts", %{})
    required_action_counts = Map.get(lifecycle_fields, "required_operator_action_counts", %{})
    planned_status_counts = Map.get(lifecycle_fields, "planned_status_category_counts", %{})
    realized_status_counts = Map.get(lifecycle_fields, "realized_status_category_counts", %{})
    planned_approval_counts = Map.get(lifecycle_fields, "planned_approval_category_counts", %{})

    realized_approval_counts =
      Map.get(lifecycle_fields, "realized_approval_category_counts", %{})

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

    recordable_timeline_ids = Map.get(lifecycle_fields, "recordable_timeline_ids", [])
    preserved_timeline_ids = Map.get(lifecycle_fields, "preserved_timeline_ids", [])
    review_timeline_ids = Map.get(lifecycle_fields, "review_timeline_ids", [])
    review_activity_ids = Map.get(lifecycle_fields, "review_activity_ids", [])
    invalid_activity_input_ids = Map.get(lifecycle_fields, "invalid_activity_input_ids", [])

    review_timeline_ids_by_action =
      Map.get(lifecycle_fields, "review_timeline_ids_by_required_operator_action", %{})

    review_timeline_ids_by_status_transition =
      Map.get(lifecycle_fields, "review_timeline_ids_by_status_transition_category", %{})

    review_timeline_ids_by_approval_transition =
      Map.get(lifecycle_fields, "review_timeline_ids_by_approval_transition_category", %{})

    review_routing = Map.get(lifecycle_fields, "review_routing", %{})

    lifecycle_evidence_pressure =
      counts.row_count + counts.planned_activity_count + counts.realized_activity_count > 0 or
        map_size(transition_decision_counts) > 0 or map_size(planned_status_counts) > 0 or
        map_size(realized_status_counts) > 0 or map_size(planned_approval_counts) > 0 or
        map_size(realized_approval_counts) > 0 or
        counts.transition_application_provenance_count > 0 or
        map_size(transition_application_provenance_helper_counts) > 0 or
        map_size(transition_application_provenance_category_counts) > 0 or
        map_size(transition_application_provenance_operator_action_reason_counts) > 0

    review_pressure =
      counts.review_required_count + counts.duplicate_timeline_identity_count +
        counts.invalid_activity_input_count > 0 or
        required_action_counts |> Map.delete("none") |> map_size() > 0 or
        review_timeline_ids != [] or review_activity_ids != [] or invalid_activity_input_ids != [] or
        map_size(review_timeline_ids_by_action) > 0 or
        map_size(review_timeline_ids_by_status_transition) > 0 or
        map_size(review_timeline_ids_by_approval_transition) > 0 or
        map_size(review_routing) > 0

    recordable_pressure =
      counts.recordable_count > 0 or nonempty_pressure_value?(recordable_timeline_ids) or
        summary_integer(transition_decision_counts, "record") > 0

    preservation_pressure =
      counts.preserved_count > 0 or nonempty_pressure_value?(preserved_timeline_ids) or
        summary_integer(transition_decision_counts, "none") > 0

    %{
      "branch_local_timeline_lifecycle_state_pressure" =>
        lifecycle_evidence_pressure or review_pressure or recordable_pressure or
          preservation_pressure,
      "branch_local_lifecycle_review_pressure" => review_pressure,
      "branch_local_lifecycle_recordable_pressure" => recordable_pressure,
      "branch_local_lifecycle_preservation_pressure" => preservation_pressure
    }
  end

  defp summary_integer(%{} = summary, field) do
    case Map.get(summary, field) do
      value when is_integer(value) ->
        value

      value when is_float(value) ->
        trunc(value)

      value when is_binary(value) ->
        case Integer.parse(String.trim(value)) do
          {integer, ""} -> integer
          _parse -> 0
        end

      _value ->
        0
    end
  end

  defp summary_integer(_summary, _field), do: 0

  defp nonempty_pressure_value?(value) when value in [nil, [], %{}], do: false
  defp nonempty_pressure_value?(_value), do: true
end
