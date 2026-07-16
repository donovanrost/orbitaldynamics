defmodule OrbitalDynamics.Schema.CandidateRefreshTimelineLifecycleContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation,
    only: [validate_optional_string_list: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_optional_non_negative_integer: 4,
      expect_optional_type: 5,
      expect_type: 5,
      validate_non_negative_integer_count_map: 3
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [
      validate_optional_stable_id_list: 4,
      validate_stable_id_array_map: 3
    ]

  def validate_activity_lifecycle(issues, path, summary) do
    issues =
      validate_integer_fields(issues, path, summary, [
        "review_required_count",
        "transition_application_provenance_count"
      ])

    issues =
      validate_count_maps(issues, path, summary, [
        "source_summary_model_counts",
        "source_summary_schema_contract_counts",
        "transition_decision_counts",
        "status_transition_decision_counts",
        "approval_transition_decision_counts",
        "required_operator_action_counts",
        "import_action_counts",
        "planned_status_category_counts",
        "realized_status_category_counts",
        "planned_approval_category_counts",
        "realized_approval_category_counts",
        "status_transition_category_counts",
        "approval_transition_category_counts",
        "transition_application_provenance_helper_counts",
        "transition_application_provenance_category_counts",
        "transition_application_provenance_operator_action_reason_counts",
        "protection_decision_counts",
        "protection_category_counts",
        "activity_id_counts",
        "timeline_id_counts",
        "review_activity_id_counts"
      ])

    issues
    |> expect_optional_type(path, summary, "action_routing", :map)
    |> validate_action_routing(path, "action_routing", Map.get(summary, "action_routing"))
  end

  def validate_lifecycle_state(issues, path, summary) do
    issues =
      validate_integer_fields(issues, path, summary, [
        "planned_activity_count",
        "realized_activity_count",
        "recordable_count",
        "preserved_count",
        "review_required_count",
        "duplicate_timeline_identity_count",
        "invalid_activity_input_count",
        "transition_application_provenance_count"
      ])

    issues =
      validate_count_maps(issues, path, summary, [
        "source_summary_model_counts",
        "source_summary_schema_contract_counts",
        "transition_decision_counts",
        "required_operator_action_counts",
        "import_action_counts",
        "planned_status_category_counts",
        "realized_status_category_counts",
        "planned_approval_category_counts",
        "realized_approval_category_counts",
        "status_transition_category_counts",
        "approval_transition_category_counts",
        "transition_application_provenance_helper_counts",
        "transition_application_provenance_category_counts",
        "transition_application_provenance_operator_action_reason_counts"
      ])

    issues =
      Enum.reduce(
        [
          "recordable_timeline_ids",
          "preserved_timeline_ids",
          "review_timeline_ids",
          "review_activity_ids",
          "invalid_activity_input_ids"
        ],
        issues,
        fn field, acc ->
          acc
          |> expect_optional_type(path, summary, field, :list)
          |> validate_optional_stable_id_list(path, summary, field)
        end
      )

    issues =
      Enum.reduce(
        [
          "review_timeline_ids_by_required_operator_action",
          "review_timeline_ids_by_status_transition_category",
          "review_timeline_ids_by_approval_transition_category"
        ],
        issues,
        fn field, acc ->
          acc
          |> expect_optional_type(path, summary, field, :map)
          |> validate_stable_id_array_map(path <> ".#{field}", Map.get(summary, field))
        end
      )

    issues
    |> expect_optional_type(path, summary, "review_routing", :map)
    |> validate_action_routing(path, "review_routing", Map.get(summary, "review_routing"))
  end

  defp validate_integer_fields(issues, path, summary, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      expect_optional_non_negative_integer(acc, path, summary, field)
    end)
  end

  defp validate_count_maps(issues, path, summary, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      acc
      |> expect_optional_type(path, summary, field, :map)
      |> validate_non_negative_integer_count_map(path <> ".#{field}", Map.get(summary, field))
    end)
  end

  defp validate_action_routing(issues, _path, _field, value) when value in [nil, :null],
    do: issues

  defp validate_action_routing(issues, path, field, %{} = routes) do
    Enum.reduce(routes, issues, fn {action, route}, acc ->
      route_path = path <> ".#{field}.#{action}"

      acc
      |> expect_type(path <> ".#{field}", routes, action, :map)
      |> validate_action_route(route_path, route)
    end)
  end

  defp validate_action_routing(issues, _path, _field, _value), do: issues

  defp validate_action_route(issues, path, %{} = route) do
    issues
    |> expect_optional_non_negative_integer(path, route, "review_count")
    |> expect_optional_type(path, route, "activity_ids", :list)
    |> expect_optional_type(path, route, "timeline_ids", :list)
    |> expect_optional_type(path, route, "status_transition_categories", :list)
    |> expect_optional_type(path, route, "approval_transition_categories", :list)
    |> expect_optional_type(path, route, "protection_categories", :list)
    |> validate_optional_stable_id_list(path, route, "activity_ids")
    |> validate_optional_stable_id_list(path, route, "timeline_ids")
    |> validate_optional_string_list(path, route, "status_transition_categories")
    |> validate_optional_string_list(path, route, "approval_transition_categories")
    |> validate_optional_string_list(path, route, "protection_categories")
  end

  defp validate_action_route(issues, _path, _route), do: issues
end
