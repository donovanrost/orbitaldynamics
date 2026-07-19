defmodule OrbitalDynamics.Timeline.LifecycleStateSummaryPolicy do
  @moduledoc false

  def build(
        rows,
        planned_rows,
        realized_rows,
        source,
        schema_contract,
        model_limits,
        sorted_uniq
      ) do
    review_rows = Enum.filter(rows, &(&1["review_required"] == true))

    %{
      "schema_contract" => schema_contract,
      "model" => "artifact_only_timeline_lifecycle_state_summary",
      "source" => source,
      "validation_level" => "artifact_contract",
      "model_limits" => model_limits,
      "planned_activity_count" => length(planned_rows),
      "realized_activity_count" => length(realized_rows),
      "row_count" => length(rows),
      "recordable_count" => Enum.count(rows, &(&1["transition_decision"] == "record")),
      "preserved_count" => Enum.count(rows, &(&1["transition_decision"] == "none")),
      "review_required_count" => length(review_rows),
      "duplicate_timeline_identity_count" =>
        Enum.count(rows, &(&1["timeline_identity_collision"] == true)),
      "invalid_activity_input_count" => Enum.count(rows, &(&1["invalid_activity_input"] == true)),
      "transition_decision_counts" => count_by(rows, "transition_decision"),
      "required_operator_action_counts" => count_by(rows, "required_operator_action"),
      "operator_action_reason_counts" => lifecycle_state_operator_action_reason_counts(rows),
      "import_action_counts" => count_by(rows, "import_action"),
      "planned_status_category_counts" => count_by(rows, "planned_status_category"),
      "realized_status_category_counts" => count_by(rows, "realized_status_category"),
      "planned_approval_category_counts" => count_by(rows, "planned_approval_category"),
      "realized_approval_category_counts" => count_by(rows, "realized_approval_category"),
      "status_transition_category_counts" =>
        transition_category_counts(rows, "status_transition"),
      "approval_transition_category_counts" =>
        transition_category_counts(rows, "approval_transition"),
      "recordable_timeline_ids" =>
        lifecycle_state_timeline_ids(
          rows,
          &(&1["transition_decision"] == "record"),
          sorted_uniq
        ),
      "preserved_timeline_ids" =>
        lifecycle_state_timeline_ids(
          rows,
          &(&1["transition_decision"] == "none"),
          sorted_uniq
        ),
      "review_timeline_ids" =>
        lifecycle_state_timeline_ids(review_rows, fn _row -> true end, sorted_uniq),
      "review_activity_ids" => lifecycle_state_activity_ids(review_rows, sorted_uniq),
      "invalid_activity_input_ids" =>
        lifecycle_state_activity_ids(
          Enum.filter(rows, &(&1["invalid_activity_input"] == true)),
          sorted_uniq
        ),
      "review_timeline_ids_by_required_operator_action" =>
        timeline_ids_by(
          review_rows,
          & &1["required_operator_action"],
          &(&1["review_required"] == true),
          sorted_uniq
        ),
      "review_timeline_ids_by_operator_action_reason" =>
        timeline_ids_by_each(
          review_rows,
          &list_value(&1, "operator_action_reasons"),
          &(&1["review_required"] == true),
          sorted_uniq
        ),
      "review_timeline_ids_by_status_transition_category" =>
        timeline_ids_by(
          review_rows,
          &get_in(&1, ["status_transition", "transition_category"]),
          &(&1["review_required"] == true),
          sorted_uniq
        ),
      "review_timeline_ids_by_approval_transition_category" =>
        timeline_ids_by(
          review_rows,
          &get_in(&1, ["approval_transition", "transition_category"]),
          &(&1["review_required"] == true),
          sorted_uniq
        ),
      "rows" => rows,
      "review_rows" => review_rows,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "operator_authority" => "not_granted_by_summary",
        "cadence_import" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary",
        "identity_match" => "planned and realized rows are paired by timeline identity"
      }
    }
    |> compact_map()
  end

  defp count_by(rows, field) do
    OrbitalDynamics.Timeline.CountSummaryPolicy.count_by(rows, field)
  end

  defp transition_category_counts(rows, field) do
    OrbitalDynamics.Timeline.CountSummaryPolicy.transition_category_counts(rows, field)
  end

  defp lifecycle_state_operator_action_reason_counts(rows) do
    OrbitalDynamics.Timeline.LifecycleStateSummaryMetricsPolicy.lifecycle_state_operator_action_reason_counts(
      rows,
      &OrbitalDynamics.Timeline.CollectionValuePolicy.list_value/2,
      &OrbitalDynamics.Timeline.CountSummaryPolicy.sort_count_map/1
    )
  end

  defp lifecycle_state_timeline_ids(rows, predicate, sorted_uniq) do
    OrbitalDynamics.Timeline.LifecycleStateSummaryMetricsPolicy.lifecycle_state_timeline_ids(
      rows,
      predicate,
      sorted_uniq
    )
  end

  defp lifecycle_state_activity_ids(rows, sorted_uniq) do
    OrbitalDynamics.Timeline.LifecycleStateSummaryMetricsPolicy.lifecycle_state_activity_ids(
      rows,
      &OrbitalDynamics.Timeline.CollectionValuePolicy.list_value/2,
      sorted_uniq
    )
  end

  defp timeline_ids_by(rows, key_fun, predicate, sorted_uniq) do
    OrbitalDynamics.Timeline.IdentityGroupingPolicy.timeline_ids_by(
      rows,
      key_fun,
      predicate,
      sorted_uniq
    )
  end

  defp timeline_ids_by_each(rows, values_fun, predicate, sorted_uniq) do
    OrbitalDynamics.Timeline.IdentityGroupingPolicy.timeline_ids_by_each(
      rows,
      values_fun,
      predicate,
      sorted_uniq
    )
  end

  defp list_value(value, key) do
    OrbitalDynamics.Timeline.CollectionValuePolicy.list_value(value, key)
  end

  defp compact_map(map) do
    OrbitalDynamics.Timeline.ArtifactValueEncodingPolicy.compact(map)
  end
end
