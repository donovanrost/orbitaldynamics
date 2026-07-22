defmodule OrbitalDynamics.Schema.OperatorReviewPackageContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.ContactAllocationHandoffContracts

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_one_of: 5,
      expect_optional_non_negative_integer: 4,
      expect_optional_type: 5,
      expect_type: 5,
      validate_non_negative_integer_count_map: 3,
      validate_optional_exact_model_limits: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_optional_stable_id_list: 4, validate_stable_ids: 4]

  @required_scalar_count_fields [
    "review_count",
    "approval_requirement_count",
    "contention_recommendation_count",
    "realized_feedback_count",
    "warning_count",
    "risk_count",
    "recommendation_count"
  ]

  @optional_scalar_count_fields [
    "plan_delta_count",
    "timeline_protection_count",
    "policy_escalation_count",
    "contact_suppression_count",
    "resource_projection_review_count",
    "command_window_count",
    "station_calendar_review_count",
    "station_reservation_review_count",
    "link_capacity_review_count",
    "contention_review_count",
    "resource_suppression_count",
    "contact_allocation_review_count",
    "contact_allocation_capacity_pack_review_count",
    "contact_intent_review_count",
    "candidate_rejection_review_count",
    "provider_counteroffer_review_count",
    "candidate_diff_review_count",
    "freshness_review_count",
    "refresh_budget_review_count",
    "model_acceptance_review_count",
    "validation_safety_case_review_count",
    "timeline_diff_count",
    "maneuver_review_count",
    "score_term_review_count",
    "objective_tradeoff_review_count",
    "constraint_review_count",
    "objective_satisfaction_review_count",
    "schema_validation_review_count",
    "execution_review_count",
    "operational_timeline_count",
    "pareto_frontier_count",
    "tradeoff_count",
    "ranking_comparison_count",
    "operational_readiness_review_count",
    "quality_gate_review_count"
  ]

  @optional_count_maps [
    "review_type_counts",
    "review_queue_counts",
    "approval_status_counts",
    "required_operator_action_counts",
    "cadence_import_status_counts",
    "source_cadence_import_status_counts",
    "replacement_cadence_import_status_counts",
    "calendar_entry_trust_boundary_status_counts",
    "station_reservation_match_status_counts"
  ]

  def scalar_count_fields, do: @required_scalar_count_fields ++ @optional_scalar_count_fields

  def validate(
        issues,
        path,
        package,
        source_artifact_types,
        model_limits,
        callbacks
      )
      when is_list(source_artifact_types) and is_list(model_limits) and is_list(callbacks) do
    issues
    |> expect_equal(path, package, "schema_contract", "operator_review_package.v1")
    |> expect_equal(path, package, "model", "artifact_only_operator_review_package")
    |> expect_one_of(
      path,
      package,
      "source_artifact_type",
      source_artifact_types
    )
    |> validate_stable_ids(path, package, ["source_artifact_id"])
    |> validate_scalar_counts(path, package)
    |> validate_optional_count_map_types(path, package)
    |> expect_optional_type(path, package, "station_reservation_ids", :list)
    |> validate_optional_stable_id_list(path, package, "station_reservation_ids")
    |> expect_optional_type(path, package, "station_pressure_contact_ids", :list)
    |> validate_optional_stable_id_list(path, package, "station_pressure_contact_ids")
    |> ContactAllocationHandoffContracts.validate_station_pressure_identity_summary(path, package)
    |> expect_optional_type(path, package, "station_reserved_bys", :list)
    |> validate_string_list_items(path, package, "station_reserved_bys")
    |> expect_optional_type(path, package, "station_reservation_statuses", :list)
    |> validate_string_list_items(path, package, "station_reservation_statuses")
    |> validate_contact_allocation_expiration_handoff_summary(path, package, callbacks)
    |> validate_quality_gate_handoff_summary(path, package, callbacks)
    |> expect_optional_type(path, package, "model_limits", :list)
    |> validate_string_list_items(path, package, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      package,
      model_limits,
      "must match operator review package model limits"
    )
    |> validate_assumptions(path, package)
    |> expect_type(path, package, "rows", :list)
    |> expect_type(path, package, "provenance", :map)
    |> expect_type(path, package, "assumptions", :map)
    |> validate_rows(
      path <> ".rows",
      Map.get(package, "rows", []),
      require_callback(callbacks, :validate_operator_review_row)
    )
    |> validate_suppression_duplicate_handoff_groups(
      path,
      Map.get(package, "rows", []),
      callbacks
    )
    |> validate_counts(path, package, callbacks)
  end

  defp validate_scalar_counts(issues, path, package) do
    issues =
      @required_scalar_count_fields
      |> Enum.reduce(issues, fn field, acc ->
        expect_non_negative_integer(acc, path, package, field)
      end)

    @optional_scalar_count_fields
    |> Enum.reduce(issues, fn field, acc ->
      expect_optional_non_negative_integer(acc, path, package, field)
    end)
  end

  defp validate_optional_count_map_types(issues, path, package) do
    Enum.reduce(@optional_count_maps, issues, fn field, acc ->
      expect_optional_type(acc, path, package, field, :map)
    end)
  end

  defp validate_assumptions(issues, path, package) do
    case Map.get(package, "assumptions") do
      %{} = assumptions ->
        if Map.has_key?(assumptions, "boundary") and
             Map.get(assumptions, "boundary") != "artifact_only_no_api_or_database_writes" do
          [
            error(
              path <> ".assumptions.boundary",
              "must equal \"artifact_only_no_api_or_database_writes\""
            )
            | issues
          ]
        else
          issues
        end

      _assumptions ->
        issues
    end
  end

  defp validate_counts(issues, path, package, callbacks) do
    rows =
      package
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    issues
    |> expect_field_equals(path, package, "review_count", length(rows))
    |> validate_count_maps(path, package)
    |> validate_contact_allocation_expiration_handoff_summary(path, package, callbacks)
    |> expect_field_equals(
      path,
      package,
      "review_type_counts",
      frequency_map(rows, "review_type"),
      "must equal row-derived review_type_counts"
    )
    |> expect_field_equals(
      path,
      package,
      "review_queue_counts",
      frequency_map(rows, "review_queue_key"),
      "must equal row-derived review_queue_counts"
    )
    |> expect_field_equals(
      path,
      package,
      "approval_status_counts",
      frequency_map(rows, "approval_status"),
      "must equal row-derived approval_status_counts"
    )
    |> expect_field_equals(
      path,
      package,
      "required_operator_action_counts",
      frequency_map(rows, "required_operator_action"),
      "must equal row-derived required_operator_action_counts"
    )
    |> expect_field_equals(
      path,
      package,
      "cadence_import_status_counts",
      frequency_map(rows, "cadence_import_status"),
      "must equal row-derived cadence_import_status_counts"
    )
    |> expect_field_equals(
      path,
      package,
      "source_cadence_import_status_counts",
      frequency_map(rows, "source_cadence_import_status"),
      "must equal row-derived source_cadence_import_status_counts"
    )
    |> expect_field_equals(
      path,
      package,
      "replacement_cadence_import_status_counts",
      frequency_map(rows, "replacement_cadence_import_status"),
      "must equal row-derived replacement_cadence_import_status_counts"
    )
    |> expect_field_equals(
      path,
      package,
      "contention_recommendation_count",
      Enum.count(rows, &(Map.get(&1, "review_type") == "contact_contention_recommendation"))
    )
  end

  defp validate_count_maps(issues, path, package) do
    Enum.reduce(@optional_count_maps, issues, fn field, acc ->
      validate_non_negative_integer_count_map(
        acc,
        path <> ".#{field}",
        Map.get(package, field)
      )
    end)
  end

  defp frequency_map(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp expect_field_equals(issues, path, map, field, expected),
    do: expect_field_equals(issues, path, map, field, expected, "must equal #{expected}")

  defp validate_contact_allocation_expiration_handoff_summary(issues, path, package, callbacks),
    do:
      apply(
        require_callback(callbacks, :validate_contact_allocation_expiration_handoff_summary),
        [
          issues,
          path,
          package
        ]
      )

  defp validate_quality_gate_handoff_summary(issues, path, package, callbacks),
    do:
      apply(require_callback(callbacks, :validate_quality_gate_handoff_summary), [
        issues,
        path,
        package
      ])

  defp validate_suppression_duplicate_handoff_groups(issues, path, rows, callbacks),
    do:
      apply(require_callback(callbacks, :validate_suppression_duplicate_handoff_groups), [
        issues,
        path,
        rows
      ])

  defp require_callback(callbacks, name) do
    Keyword.fetch!(callbacks, name)
  end
end
