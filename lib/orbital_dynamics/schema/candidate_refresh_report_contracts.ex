defmodule OrbitalDynamics.Schema.CandidateRefreshReportContracts do
  @moduledoc false

  def validate_source_report_provenance(issues, %{"provenance" => %{} = provenance}, callbacks)
      when is_list(callbacks) do
    issues
    |> expect_optional_type(callbacks, "$.provenance", provenance, "source_reports", :map)
    |> validate_source_report_summaries(callbacks, Map.get(provenance, "source_reports"))
  end

  def validate_source_report_provenance(issues, _artifact, _callbacks), do: issues

  defp validate_source_report_summaries(issues, _callbacks, nil), do: issues

  defp validate_source_report_summaries(issues, callbacks, source_reports)
       when is_map(source_reports) do
    Enum.reduce(source_reports, issues, fn {family, summary}, issues ->
      path = "$.provenance.source_reports.#{family}"

      issues =
        expect_type(
          issues,
          callbacks,
          "$.provenance.source_reports",
          source_reports,
          family,
          :map
        )

      if is_map(summary) do
        issues
        |> expect_optional_type(callbacks, path, summary, "contract", :binary)
        |> expect_optional_type(callbacks, path, summary, "paths", :list)
        |> validate_string_list_items(callbacks, path, summary, "paths")
        |> expect_optional_non_negative_integer(callbacks, path, summary, "count")
        |> expect_optional_non_negative_integer(callbacks, path, summary, "row_count")
        |> validate_non_negative_integer_count_map(
          callbacks,
          path <> ".analysis_mode_counts",
          Map.get(summary, "analysis_mode_counts")
        )
        |> expect_optional_type(callbacks, path, summary, "trust_boundary_status", :binary)
        |> expect_optional_type(callbacks, path, summary, "trust_boundaries", :list)
        |> validate_string_list_items(callbacks, path, summary, "trust_boundaries")
        |> expect_optional_non_negative_integer(
          callbacks,
          path,
          summary,
          "station_reservation_evidence_row_count"
        )
        |> expect_optional_non_negative_integer(
          callbacks,
          path,
          summary,
          "station_reservation_expiration_evidence_row_count"
        )
        |> validate_operational_readiness_resource_context(callbacks, path, summary)
        |> validate_operational_readiness_adapter_boundary_context(callbacks, path, summary)
        |> validate_operational_readiness_cadence_import_context(callbacks, path, summary)
        |> validate_link_capacity_context(path, summary, callbacks)
        |> validate_constraint_context(path, summary, callbacks)
        |> validate_resource_projection_context(path, summary, callbacks)
        |> validate_resource_filter_context(path, summary, callbacks)
        |> validate_contact_allocation_context(path, summary, callbacks)
        |> validate_contact_contention_context(path, summary, callbacks)
        |> validate_candidate_rejection_context(path, summary, callbacks)
        |> validate_provider_counteroffer_context(path, summary, callbacks)
        |> validate_maneuver_review_context(path, summary, callbacks)
        |> validate_station_pressure_context(path, summary, callbacks)
        |> validate_contact_intent_context(path, summary, callbacks)
        |> validate_contact_filter_context(path, summary, callbacks)
        |> validate_station_calendar_context(path, summary, callbacks)
        |> validate_timeline_activity_context(path, summary, callbacks)
        |> validate_timeline_activity_lifecycle_context(path, summary, callbacks)
        |> validate_timeline_lifecycle_state_context(path, summary, callbacks)
        |> validate_timeline_activity_precondition_context(path, summary, callbacks)
        |> validate_timeline_integrity_context(path, summary, callbacks)
        |> validate_timeline_publication_context(path, summary, callbacks)
        |> validate_timeline_dependency_impact_context(path, summary, callbacks)
        |> validate_timeline_feedback_context(path, summary, callbacks)
        |> validate_timeline_diff_context(path, summary, callbacks)
        |> validate_timeline_transition_application_context(path, summary, callbacks)
        |> validate_operational_timeline_context(path, summary, callbacks)
        |> validate_quality_gate_context(path, summary, callbacks)
        |> validate_schema_validation_context(path, summary, callbacks)
        |> validate_model_acceptance_context(path, summary, callbacks)
        |> validate_freshness_context(path, summary, callbacks)
        |> validate_objective_gap_context(path, summary, callbacks)
        |> validate_refresh_budget_context(path, summary, callbacks)
        |> validate_validation_safety_case_context(path, summary, callbacks)
      else
        issues
      end
    end)
  end

  defp validate_source_report_summaries(issues, _callbacks, _source_reports), do: issues

  def validate_quality_gate_context(issues, path, summary, callbacks) when is_list(callbacks) do
    issues =
      Enum.reduce(
        [
          "gate_count",
          "passed_gate_count",
          "review_gate_count",
          "analysis_gate_count",
          "blocked_gate_count",
          "non_passed_gate_count",
          "source_readiness_report_count"
        ],
        issues,
        fn field, acc ->
          expect_optional_non_negative_integer(acc, callbacks, path, summary, field)
        end
      )

    issues =
      Enum.reduce(
        [
          "readiness_level_counts",
          "import_classification_counts",
          "status_counts",
          "gate_status_counts",
          "gate_classification_counts"
        ],
        issues,
        fn field, acc ->
          acc
          |> expect_optional_type(callbacks, path, summary, field, :map)
          |> validate_non_negative_integer_count_map(
            callbacks,
            path <> ".#{field}",
            Map.get(summary, field)
          )
        end
      )

    issues =
      Enum.reduce(
        [
          "quality_gate_row_ids_by_status",
          "quality_gate_ids_by_status",
          "quality_gate_row_ids_by_classification",
          "quality_gate_ids_by_classification"
        ],
        issues,
        fn field, acc ->
          validate_optional_stable_id_array_map(acc, callbacks, path, summary, field)
        end
      )

    Enum.reduce(
      [
        "review_required_quality_gate_row_ids",
        "blocked_quality_gate_row_ids",
        "ready_quality_gate_row_ids",
        "analysis_only_quality_gate_row_ids",
        "passed_gate_ids",
        "review_required_gate_ids",
        "analysis_only_gate_ids",
        "blocked_gate_ids",
        "non_passed_gate_ids",
        "non_passed_quality_gate_row_ids",
        "stale_or_unknown_freshness_quality_gate_row_ids",
        "import_preparation_quality_gate_row_ids",
        "blocked_import_quality_gate_row_ids",
        "import_readiness_gate_ids"
      ],
      issues,
      fn field, acc ->
        validate_stable_id_list(acc, callbacks, path <> ".#{field}", Map.get(summary, field))
      end
    )
    |> validate_string_list_items(callbacks, path, summary, "schema_validation_status_ids")
    |> validate_string_list_items(callbacks, path, summary, "freshness_status_ids")
    |> validate_string_list_items(callbacks, path, summary, "import_status_ids")
    |> validate_string_list_items(callbacks, path, summary, "cadence_import_status_ids")
  end

  def validate_schema_validation_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    issues =
      Enum.reduce(
        [
          "error_count",
          "warning_count",
          "remediation_count"
        ],
        issues,
        fn field, acc ->
          expect_optional_non_negative_integer(acc, callbacks, path, summary, field)
        end
      )

    Enum.reduce(
      [
        "status_counts",
        "validated_contract_counts",
        "validation_mode_counts",
        "remediation_action_counts",
        "remediation_category_counts",
        "remediation_path_counts"
      ],
      issues,
      fn field, acc ->
        acc
        |> expect_optional_type(callbacks, path, summary, field, :map)
        |> validate_non_negative_integer_count_map(
          callbacks,
          path <> ".#{field}",
          Map.get(summary, field)
        )
      end
    )
  end

  def validate_model_acceptance_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    issues
    |> expect_optional_non_negative_integer(callbacks, path, summary, "record_count")
    |> expect_optional_non_negative_integer(callbacks, path, summary, "model_count")
    |> expect_optional_non_negative_integer(callbacks, path, summary, "accepted_count")
    |> expect_optional_non_negative_integer(callbacks, path, summary, "review_required_count")
    |> expect_optional_non_negative_integer(callbacks, path, summary, "blocked_count")
    |> expect_optional_non_negative_integer(callbacks, path, summary, "unknown_model_count")
    |> validate_model_acceptance_count_maps(callbacks, path, summary)
    |> expect_optional_type(callbacks, path, summary, "model_ids_by_status", :map)
    |> validate_string_list_map(callbacks, path, summary, "model_ids_by_status")
    |> expect_optional_type(callbacks, path, summary, "model_ids_by_validation_level", :map)
    |> validate_string_list_map(callbacks, path, summary, "model_ids_by_validation_level")
    |> expect_optional_type(callbacks, path, summary, "model_ids_by_intended_use", :map)
    |> validate_string_list_map(callbacks, path, summary, "model_ids_by_intended_use")
  end

  def validate_freshness_context(issues, path, summary, callbacks) when is_list(callbacks) do
    issues
    |> expect_optional_non_negative_integer(callbacks, path, summary, "stale_reason_count")
    |> expect_optional_non_negative_integer(callbacks, path, summary, "unknown_reason_count")
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".status_counts",
      Map.get(summary, "status_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".stale_reason_counts",
      Map.get(summary, "stale_reason_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".unknown_reason_counts",
      Map.get(summary, "unknown_reason_counts")
    )
    |> validate_string_list_items(callbacks, path, summary, "stale_reasons")
    |> validate_string_list_items(callbacks, path, summary, "unknown_reasons")
  end

  def validate_objective_gap_context(issues, path, summary, callbacks) when is_list(callbacks) do
    issues =
      Enum.reduce(
        [
          "gap_row_count",
          "downlink_gap_row_count",
          "target_gap_row_count",
          "collection_latency_gap_row_count"
        ],
        issues,
        fn field, acc ->
          expect_optional_non_negative_integer(acc, callbacks, path, summary, field)
        end
      )

    Enum.reduce(
      [
        "status_counts",
        "objective_type_counts",
        "term_key_counts",
        "ground_station_counts",
        "target_counts",
        "collection_counts",
        "source_activity_id_counts"
      ],
      issues,
      fn field, acc ->
        validate_non_negative_integer_count_map(
          acc,
          callbacks,
          path <> ".#{field}",
          Map.get(summary, field)
        )
      end
    )
  end

  def validate_refresh_budget_context(issues, path, summary, callbacks) when is_list(callbacks) do
    issues =
      Enum.reduce(
        [
          "input_candidate_count",
          "kept_candidate_count",
          "dropped_candidate_count",
          "invalid_candidate_limit_policy_count"
        ],
        issues,
        fn field, acc ->
          expect_optional_non_negative_integer(acc, callbacks, path, summary, field)
        end
      )

    issues
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".invalid_candidate_limit_policy_reason_counts",
      Map.get(summary, "invalid_candidate_limit_policy_reason_counts")
    )
    |> validate_stable_id_list(
      callbacks,
      path <> ".kept_candidate_ids",
      Map.get(summary, "kept_candidate_ids")
    )
    |> validate_stable_id_list(
      callbacks,
      path <> ".dropped_candidate_ids",
      Map.get(summary, "dropped_candidate_ids")
    )
  end

  def validate_validation_safety_case_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    issues
    |> expect_optional_non_negative_integer(callbacks, path, summary, "accepted_evidence_count")
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      summary,
      "review_required_evidence_count"
    )
    |> expect_optional_non_negative_integer(callbacks, path, summary, "blocked_evidence_count")
    |> expect_optional_type(callbacks, path, summary, "status_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".status_counts",
      Map.get(summary, "status_counts")
    )
    |> expect_optional_type(callbacks, path, summary, "evidence_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".evidence_status_counts",
      Map.get(summary, "evidence_status_counts")
    )
    |> expect_optional_type(callbacks, path, summary, "input_contract_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".input_contract_counts",
      Map.get(summary, "input_contract_counts")
    )
    |> expect_optional_type(callbacks, path, summary, "evidence_refs_by_status", :map)
    |> validate_string_list_map(callbacks, path, summary, "evidence_refs_by_status")
    |> expect_optional_type(callbacks, path, summary, "evidence_refs_by_contract", :map)
    |> validate_string_list_map(callbacks, path, summary, "evidence_refs_by_contract")
    |> validate_validation_safety_case_counts(callbacks, path, summary)
  end

  def validate_timeline_activity_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    issues
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      summary,
      "invalid_activity_input_count"
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".invalid_activity_input_reason_counts",
      Map.get(summary, "invalid_activity_input_reason_counts")
    )
    |> validate_string_list_items(callbacks, path, summary, "invalid_activity_input_reasons")
  end

  def validate_timeline_activity_lifecycle_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    issues =
      Enum.reduce(
        [
          "review_required_count",
          "transition_application_provenance_count"
        ],
        issues,
        fn field, acc ->
          expect_optional_non_negative_integer(acc, callbacks, path, summary, field)
        end
      )

    issues =
      Enum.reduce(
        [
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
        ],
        issues,
        fn field, acc ->
          acc
          |> expect_optional_type(callbacks, path, summary, field, :map)
          |> validate_non_negative_integer_count_map(
            callbacks,
            path <> ".#{field}",
            Map.get(summary, field)
          )
        end
      )

    issues
    |> expect_optional_type(callbacks, path, summary, "action_routing", :map)
    |> validate_timeline_activity_state_action_routing(
      callbacks,
      path,
      "action_routing",
      Map.get(summary, "action_routing")
    )
  end

  def validate_timeline_lifecycle_state_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    issues =
      Enum.reduce(
        [
          "planned_activity_count",
          "realized_activity_count",
          "recordable_count",
          "preserved_count",
          "review_required_count",
          "duplicate_timeline_identity_count",
          "invalid_activity_input_count",
          "transition_application_provenance_count"
        ],
        issues,
        fn field, acc ->
          expect_optional_non_negative_integer(acc, callbacks, path, summary, field)
        end
      )

    issues =
      Enum.reduce(
        [
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
        ],
        issues,
        fn field, acc ->
          acc
          |> expect_optional_type(callbacks, path, summary, field, :map)
          |> validate_non_negative_integer_count_map(
            callbacks,
            path <> ".#{field}",
            Map.get(summary, field)
          )
        end
      )

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
          |> expect_optional_type(callbacks, path, summary, field, :list)
          |> validate_optional_stable_id_list(callbacks, path, summary, field)
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
          |> expect_optional_type(callbacks, path, summary, field, :map)
          |> validate_optional_stable_id_array_map(callbacks, path, summary, field)
        end
      )

    issues
    |> expect_optional_type(callbacks, path, summary, "review_routing", :map)
    |> validate_timeline_activity_state_action_routing(
      callbacks,
      path,
      "review_routing",
      Map.get(summary, "review_routing")
    )
  end

  def validate_timeline_activity_precondition_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    issues =
      Enum.reduce(
        [
          "blocked_precondition_count",
          "review_precondition_count",
          "invalid_activity_input_count"
        ],
        issues,
        fn field, acc ->
          expect_optional_non_negative_integer(acc, callbacks, path, summary, field)
        end
      )

    issues =
      Enum.reduce(
        [
          "source_summary_model_counts",
          "source_summary_schema_contract_counts",
          "precondition_status_counts",
          "blocked_precondition_type_counts",
          "review_precondition_type_counts",
          "invalid_activity_input_reason_counts",
          "activity_id_counts",
          "timeline_id_counts",
          "dependency_activity_id_counts",
          "dependency_timeline_id_counts",
          "exclusive_with_activity_id_counts",
          "exclusive_with_timeline_id_counts",
          "duplicate_dependency_activity_id_counts",
          "duplicate_dependency_timeline_id_counts",
          "duplicate_exclusivity_activity_id_counts",
          "duplicate_exclusivity_timeline_id_counts",
          "allow_overlap_counts"
        ],
        issues,
        fn field, acc ->
          acc
          |> expect_optional_type(callbacks, path, summary, field, :map)
          |> validate_non_negative_integer_count_map(
            callbacks,
            path <> ".#{field}",
            Map.get(summary, field)
          )
        end
      )

    validate_string_list_items(issues, callbacks, path, summary, "invalid_activity_input_reasons")
  end

  def validate_timeline_publication_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    issues =
      Enum.reduce(
        [
          "publication_status_counts",
          "downstream_invalidation_status_counts",
          "dependency_impact_status_counts",
          "publication_authority_counts",
          "source_artifact_type_counts",
          "timeline_publication_source_artifact_type_counts",
          "changed_field_counts"
        ],
        issues,
        fn field, acc ->
          validate_non_negative_integer_count_map(
            acc,
            callbacks,
            path <> ".#{field}",
            Map.get(summary, field)
          )
        end
      )

    issues =
      Enum.reduce(
        [
          "dependency_impact_row_count",
          "timeline_diff_row_count",
          "timeline_diff_changed_count",
          "timeline_diff_review_required_count"
        ],
        issues,
        fn field, acc ->
          expect_optional_non_negative_integer(acc, callbacks, path, summary, field)
        end
      )

    issues =
      Enum.reduce(
        [
          "publication_ids",
          "source_artifact_ids",
          "supersedes_artifact_ids",
          "downstream_product_ids",
          "invalidated_downstream_product_ids",
          "impacted_source_activity_ids",
          "impacted_source_timeline_ids",
          "dependent_activity_ids",
          "dependent_timeline_ids",
          "source_dependent_activity_ids",
          "source_dependent_timeline_ids",
          "replacement_dependent_activity_ids",
          "replacement_dependent_timeline_ids",
          "impacted_dependency_activity_ids",
          "impacted_dependency_timeline_ids",
          "impacted_exclusive_with_activity_ids",
          "impacted_exclusive_with_timeline_ids",
          "changed_timeline_ids",
          "review_timeline_ids"
        ],
        issues,
        fn field, acc ->
          validate_optional_stable_id_list(acc, callbacks, path, summary, field)
        end
      )

    [
      "timeline_ids_by_changed_field",
      "invalidated_downstream_product_ids_by_reason"
    ]
    |> Enum.reduce(issues, fn field, acc ->
      validate_stable_id_array_map(acc, callbacks, path <> ".#{field}", Map.get(summary, field))
    end)
  end

  def validate_timeline_integrity_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    issues =
      Enum.reduce(
        [
          "timeline_integrity_issue_count",
          "timeline_integrity_review_count",
          "dependency_issue_count",
          "exclusivity_issue_count"
        ],
        issues,
        fn field, acc ->
          expect_optional_non_negative_integer(acc, callbacks, path, summary, field)
        end
      )

    Enum.reduce(
      [
        "timeline_integrity_status_counts",
        "timeline_integrity_issue_type_counts",
        "required_operator_action_counts",
        "operator_action_reason_counts",
        "review_activity_id_counts",
        "review_timeline_id_counts",
        "missing_dependency_activity_id_counts",
        "missing_dependency_timeline_id_counts",
        "self_dependency_activity_id_counts",
        "self_dependency_timeline_id_counts",
        "dependency_cycle_activity_id_counts",
        "dependency_cycle_timeline_id_counts",
        "dependency_order_violation_activity_id_counts",
        "dependency_order_violation_timeline_id_counts",
        "exclusivity_violation_activity_id_counts",
        "exclusivity_violation_timeline_id_counts",
        "exclusivity_violation_group_counts"
      ],
      issues,
      fn field, acc ->
        acc
        |> expect_optional_type(callbacks, path, summary, field, :map)
        |> validate_non_negative_integer_count_map(
          callbacks,
          path <> ".#{field}",
          Map.get(summary, field)
        )
      end
    )
  end

  def validate_timeline_dependency_impact_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    issues =
      Enum.reduce(
        [
          "source_activity_count",
          "replacement_activity_count",
          "changed_source_activity_count",
          "changed_source_timeline_count",
          "dependent_activity_count",
          "source_dependent_activity_count",
          "replacement_dependent_activity_count"
        ],
        issues,
        fn field, acc ->
          expect_optional_non_negative_integer(acc, callbacks, path, summary, field)
        end
      )

    Enum.reduce(
      [
        "dependency_impact_status_counts",
        "dependency_impact_scope_counts",
        "required_operator_action_counts",
        "impacted_source_activity_id_counts",
        "impacted_source_timeline_id_counts",
        "impacted_dependency_activity_id_counts",
        "impacted_dependency_timeline_id_counts",
        "impacted_exclusive_activity_id_counts",
        "impacted_exclusive_timeline_id_counts",
        "dependent_activity_id_counts",
        "dependent_timeline_id_counts"
      ],
      issues,
      fn field, acc ->
        acc
        |> expect_optional_type(callbacks, path, summary, field, :map)
        |> validate_non_negative_integer_count_map(
          callbacks,
          path <> ".#{field}",
          Map.get(summary, field)
        )
      end
    )
  end

  def validate_provider_counteroffer_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    issues
    |> expect_optional_non_negative_integer(callbacks, path, summary, "reviewable_count")
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      summary,
      "counteroffer_cost_delta_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      summary,
      "counteroffer_timing_shift_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      summary,
      "counteroffer_start_delta_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      summary,
      "counteroffer_end_delta_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      summary,
      "counteroffer_duration_delta_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      summary,
      "counteroffer_lock_deadline_count"
    )
    |> expect_optional_number(callbacks, path, summary, "counteroffer_cost_delta_total")
    |> expect_optional_number(callbacks, path, summary, "earliest_counteroffer_lock_deadline_s")
    |> expect_optional_type(callbacks, path, summary, "counteroffer_status_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".counteroffer_status_counts",
      Map.get(summary, "counteroffer_status_counts")
    )
    |> expect_optional_type(callbacks, path, summary, "required_operator_action_counts", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".required_operator_action_counts",
      Map.get(summary, "required_operator_action_counts")
    )
    |> expect_optional_non_negative_integer(callbacks, path, summary, "plan_impact_summary_count")
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      summary,
      "import_readiness_summary_count"
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".plan_impact_status_counts",
      Map.get(summary, "plan_impact_status_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".import_readiness_status_counts",
      Map.get(summary, "import_readiness_status_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".import_classification_counts",
      Map.get(summary, "import_classification_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".provider_counteroffer_import_status_counts",
      Map.get(summary, "provider_counteroffer_import_status_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".counteroffer_lock_deadline_status_counts",
      Map.get(summary, "counteroffer_lock_deadline_status_counts")
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".counteroffer_ids_by_import_status",
      Map.get(summary, "counteroffer_ids_by_import_status")
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".counteroffer_ids_by_required_import_action",
      Map.get(summary, "counteroffer_ids_by_required_import_action")
    )
    |> validate_stable_id_array_map(
      callbacks,
      path <> ".counteroffer_ids_by_lock_deadline_status",
      Map.get(summary, "counteroffer_ids_by_lock_deadline_status")
    )
    |> validate_stable_id_list(
      callbacks,
      path <> ".review_counteroffer_ids",
      Map.get(summary, "review_counteroffer_ids")
    )
    |> validate_stable_id_list(
      callbacks,
      path <> ".no_import_required_counteroffer_ids",
      Map.get(summary, "no_import_required_counteroffer_ids")
    )
    |> validate_string_list_items(callbacks, path, summary, "affected_station_calendar_entry_ids")
    |> validate_string_list_items(callbacks, path, summary, "affected_provider_entry_ids")
    |> validate_string_list_items(callbacks, path, summary, "impact_counteroffer_ids")
    |> validate_string_list_items(callbacks, path, summary, "timing_shift_counteroffer_ids")
    |> validate_string_list_items(callbacks, path, summary, "cost_delta_counteroffer_ids")
  end

  def validate_timeline_feedback_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    issues
    |> expect_optional_type(callbacks, path, summary, "input_keys", :list)
    |> validate_string_list_items(callbacks, path, summary, "input_keys")
    |> validate_optional_count_maps(callbacks, path, summary, [
      "status_counts",
      "feedback_kind_counts",
      "match_strategy_counts",
      "activity_id_counts",
      "cadence_import_status_counts"
    ])
  end

  def validate_timeline_diff_context(issues, path, summary, callbacks) when is_list(callbacks) do
    issues =
      Enum.reduce(
        [
          "duplicate_timeline_identity_count",
          "duplicate_source_timeline_identity_count",
          "duplicate_replacement_timeline_identity_count",
          "removed_downlink_count",
          "removed_observation_count",
          "changed_downlink_shortfall_count",
          "changed_contact_feedback_count",
          "changed_observation_count",
          "changed_observation_quality_feedback_count",
          "changed_command_feedback_count",
          "changed_maneuver_feedback_count"
        ],
        issues,
        fn field, acc ->
          expect_optional_non_negative_integer(acc, callbacks, path, summary, field)
        end
      )

    validate_optional_count_maps(issues, callbacks, path, summary, [
      "diff_status_counts",
      "required_operator_action_counts",
      "duplicate_timeline_identity_scope_counts",
      "source_activity_id_counts",
      "replacement_activity_id_counts"
    ])
  end

  def validate_operational_timeline_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    issues
    |> expect_optional_type(callbacks, path, summary, "input_keys", :list)
    |> validate_string_list_items(callbacks, path, summary, "input_keys")
    |> expect_optional_non_negative_integer(callbacks, path, summary, "contact_feedback_count")
    |> expect_optional_non_negative_integer(callbacks, path, summary, "command_feedback_count")
    |> expect_optional_non_negative_integer(callbacks, path, summary, "maneuver_feedback_count")
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      summary,
      "observation_feedback_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      summary,
      "station_throughput_feedback_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      summary,
      "timeline_integrity_issue_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      summary,
      "dependency_integrity_issue_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      summary,
      "exclusivity_integrity_issue_count"
    )
    |> validate_operational_timeline_count_maps(callbacks, path, summary)
  end

  def validate_timeline_transition_application_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    issues =
      Enum.reduce(
        [
          "application_count",
          "selected_activity_count",
          "selected_timeline_integrity_review_count",
          "selected_timeline_integrity_issue_count",
          "review_required_count",
          "preserved_source_count",
          "recorded_replacement_count",
          "withheld_review_count",
          "duplicate_timeline_identity_count",
          "duplicate_source_timeline_identity_count",
          "duplicate_replacement_timeline_identity_count"
        ],
        issues,
        fn field, acc ->
          expect_optional_non_negative_integer(acc, callbacks, path, summary, field)
        end
      )

    validate_optional_count_maps(issues, callbacks, path, summary, [
      "selected_activity_id_counts",
      "review_activity_id_counts",
      "selected_timeline_integrity_issue_type_counts",
      "application_status_counts",
      "transition_decision_counts",
      "required_operator_action_counts",
      "duplicate_timeline_identity_scope_counts"
    ])
  end

  def validate_maneuver_review_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    issues
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      summary,
      "maneuver_success_feedback_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      summary,
      "execution_uncertainty_declared_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      summary,
      "execution_uncertainty_missing_count"
    )
    |> expect_optional_type(callbacks, path, summary, "input_keys", :list)
    |> validate_string_list_items(callbacks, path, summary, "input_keys")
    |> validate_optional_count_maps(callbacks, path, summary, [
      "maneuver_id_counts",
      "required_operator_action_counts"
    ])
  end

  def validate_link_capacity_context(issues, path, summary, callbacks) when is_list(callbacks) do
    validate_count_maps(issues, callbacks, path, summary, [
      "ground_station_counts",
      "target_counts",
      "collection_counts",
      "selected_contact_id_counts",
      "actual_throughput_contact_id_counts"
    ])
  end

  def validate_constraint_context(issues, path, summary, callbacks) when is_list(callbacks) do
    validate_count_maps(issues, callbacks, path, summary, [
      "constraint_metric_counts",
      "constraint_resource_counts",
      "constraint_spacecraft_counts"
    ])
  end

  def validate_resource_projection_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    validate_count_maps(issues, callbacks, path, summary, [
      "resource_projection_spacecraft_counts",
      "resource_pressure_type_counts",
      "resource_pressure_activity_id_counts"
    ])
  end

  def validate_resource_filter_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    issues
    |> validate_count_maps(callbacks, path, summary, [
      "resource_filter_spacecraft_counts",
      "resource_filter_resource_counts",
      "resource_filter_blocking_dimension_counts"
    ])
    |> validate_stable_id_list(
      callbacks,
      path <> ".invalid_resource_summary_input_ids",
      Map.get(summary, "invalid_resource_summary_input_ids")
    )
  end

  def validate_contact_contention_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    validate_count_maps(issues, callbacks, path, summary, [
      "contact_contention_ground_station_counts",
      "contact_contention_contact_id_counts"
    ])
  end

  def validate_contact_allocation_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    Enum.reduce(
      [
        "provider_reservation_no_request_contact_ids_by_direction_and_ground_station",
        "provider_reservation_request_contact_ids_by_direction_and_ground_station",
        "provider_reservation_review_contact_ids_by_direction_and_ground_station"
      ],
      issues,
      fn field, acc ->
        validate_nested_stable_id_array_map(
          acc,
          callbacks,
          path <> ".#{field}",
          Map.get(summary, field)
        )
      end
    )
  end

  def validate_candidate_rejection_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    validate_count_maps(issues, callbacks, path, summary, [
      "candidate_rejection_candidate_id_counts",
      "candidate_rejection_ground_station_counts"
    ])
  end

  def validate_station_pressure_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    issues
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      summary,
      "station_pressure_contact_count"
    )
    |> validate_count_maps(callbacks, path, summary, [
      "station_pressure_ground_station_counts",
      "station_pressure_availability_counts",
      "station_pressure_precedence_availability_counts",
      "station_pressure_precedence_rank_counts"
    ])
  end

  def validate_contact_intent_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    issues
    |> expect_optional_non_negative_integer(callbacks, path, summary, "station_feedback_count")
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      summary,
      "capacity_pack_required_contact_count"
    )
    |> expect_optional_number(
      callbacks,
      path,
      summary,
      "capacity_pack_required_capacity_fraction"
    )
    |> validate_count_maps(callbacks, path, summary, [
      "station_calendar_status_counts",
      "cadence_import_status_counts",
      "policy_classification_counts",
      "required_capacity_fraction_source_counts",
      "direction_counts"
    ])
    |> validate_non_negative_number_map(
      callbacks,
      path <> ".capacity_pack_required_capacity_fraction_by_ground_station",
      Map.get(summary, "capacity_pack_required_capacity_fraction_by_ground_station")
    )
    |> validate_non_negative_number_map(
      callbacks,
      path <> ".capacity_pack_required_capacity_fraction_by_direction",
      Map.get(summary, "capacity_pack_required_capacity_fraction_by_direction")
    )
    |> validate_nested_non_negative_number_map(
      callbacks,
      path <> ".capacity_pack_required_capacity_fraction_by_direction_and_ground_station",
      Map.get(summary, "capacity_pack_required_capacity_fraction_by_direction_and_ground_station")
    )
    |> validate_contact_intent_stable_id_maps(callbacks, path, summary)
    |> validate_string_list_items(callbacks, path, summary, "directions")
    |> validate_contact_intent_direction_routing_with_callbacks(
      callbacks,
      path,
      Map.get(summary, "direction_routing"),
      summary
    )
  end

  def validate_contact_filter_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    issues
    |> validate_stable_id_list(
      callbacks,
      path <> ".invalid_contact_input_ids",
      Map.get(summary, "invalid_contact_input_ids")
    )
    |> expect_optional_non_negative_integer(callbacks, path, summary, "station_suppression_count")
    |> validate_count_maps(callbacks, path, summary, [
      "station_suppression_ground_station_counts",
      "station_suppression_availability_counts",
      "station_suppression_status_counts"
    ])
  end

  def validate_station_calendar_context(issues, path, summary, callbacks)
      when is_list(callbacks) do
    issues
    |> expect_optional_non_negative_integer(callbacks, path, summary, "affected_contact_count")
    |> validate_station_calendar_stable_id_lists(callbacks, path, summary)
    |> validate_count_maps(callbacks, path, summary, [
      "affected_contact_ground_station_counts",
      "affected_contact_availability_counts",
      "direction_counts"
    ])
    |> validate_station_calendar_direction_maps(callbacks, path, summary)
    |> validate_station_calendar_direction_routing(
      callbacks,
      path,
      Map.get(summary, "direction_routing")
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      summary,
      "provider_calendar_contention_group_count"
    )
    |> validate_station_calendar_provider_contention(callbacks, path, summary)
  end

  def validate_contact_intent_direction_routing(issues, path, value, summary, callbacks)
      when is_list(callbacks) do
    validate_contact_intent_direction_routing_with_callbacks(
      issues,
      callbacks,
      path,
      value,
      summary
    )
  end

  defp validate_model_acceptance_count_maps(issues, callbacks, path, summary) do
    Enum.reduce(
      [
        "intended_use_counts",
        "status_counts",
        "validation_level_counts"
      ],
      issues,
      fn field, acc ->
        acc
        |> expect_optional_type(callbacks, path, summary, field, :map)
        |> validate_non_negative_integer_count_map(
          callbacks,
          path <> ".#{field}",
          Map.get(summary, field)
        )
      end
    )
  end

  defp validate_operational_timeline_count_maps(issues, callbacks, path, summary) do
    validate_optional_count_maps(issues, callbacks, path, summary, [
      "operational_kind_counts",
      "activity_id_counts",
      "activity_status_counts",
      "approval_status_counts",
      "required_operator_action_counts",
      "cadence_import_status_counts",
      "timeline_integrity_issue_type_counts"
    ])
  end

  defp validate_optional_count_maps(issues, callbacks, path, summary, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      acc
      |> expect_optional_type(callbacks, path, summary, field, :map)
      |> validate_non_negative_integer_count_map(
        callbacks,
        path <> ".#{field}",
        Map.get(summary, field)
      )
    end)
  end

  defp validate_count_maps(issues, callbacks, path, summary, fields) do
    Enum.reduce(fields, issues, fn field, acc ->
      validate_non_negative_integer_count_map(
        acc,
        callbacks,
        path <> ".#{field}",
        Map.get(summary, field)
      )
    end)
  end

  defp validate_contact_intent_stable_id_maps(issues, callbacks, path, summary) do
    issues =
      Enum.reduce(
        [
          "required_capacity_fraction_contact_ids_by_source",
          "capacity_pack_contact_ids_by_ground_station",
          "contact_ids_by_ground_station",
          "capacity_pack_contact_ids_by_direction",
          "contact_ids_by_direction"
        ],
        issues,
        fn field, acc ->
          validate_stable_id_array_map(
            acc,
            callbacks,
            path <> ".#{field}",
            Map.get(summary, field)
          )
        end
      )

    Enum.reduce(
      [
        "capacity_pack_contact_ids_by_direction_and_ground_station",
        "contact_ids_by_direction_and_ground_station"
      ],
      issues,
      fn field, acc ->
        validate_nested_stable_id_array_map(
          acc,
          callbacks,
          path <> ".#{field}",
          Map.get(summary, field)
        )
      end
    )
  end

  defp validate_contact_intent_direction_routing_with_callbacks(
         issues,
         _callbacks,
         _path,
         value,
         _summary
       )
       when value in [nil, :null],
       do: issues

  defp validate_contact_intent_direction_routing_with_callbacks(
         issues,
         callbacks,
         path,
         %{} = routing,
         summary
       ) do
    Enum.reduce(routing, issues, fn {direction, route}, acc ->
      route_path = "#{path}.direction_routing.#{direction}"

      case route do
        %{} = route ->
          acc
          |> expect_optional_non_negative_integer(callbacks, route_path, route, "contact_count")
          |> validate_stable_id_list(
            callbacks,
            route_path <> ".contact_ids",
            Map.get(route, "contact_ids")
          )
          |> expect_optional_number(
            callbacks,
            route_path,
            route,
            "capacity_pack_required_capacity_fraction"
          )
          |> validate_non_negative_number_map(
            callbacks,
            route_path,
            maybe_single_number_map(route, "capacity_pack_required_capacity_fraction")
          )
          |> validate_contact_intent_route_stable_ids(callbacks, route_path, route)
          |> validate_contact_intent_route_fraction_maps(callbacks, route_path, route)
          |> validate_contact_intent_direction_route_consistency(
            callbacks,
            route_path,
            route,
            direction,
            summary
          )

        _route ->
          [error(callbacks, route_path, "must be an object") | acc]
      end
    end)
  end

  defp validate_contact_intent_direction_routing_with_callbacks(
         issues,
         callbacks,
         path,
         _value,
         _summary
       ),
       do: [error(callbacks, path <> ".direction_routing", "must be an object") | issues]

  defp validate_contact_intent_route_stable_ids(issues, callbacks, route_path, route) do
    issues =
      Enum.reduce(
        [
          "capacity_pack_contact_ids",
          "ground_station_ids"
        ],
        issues,
        fn field, acc ->
          validate_stable_id_list(
            acc,
            callbacks,
            route_path <> ".#{field}",
            Map.get(route, field)
          )
        end
      )

    Enum.reduce(
      [
        "contact_ids_by_ground_station",
        "contact_ids_by_ground_station_id",
        "capacity_pack_contact_ids_by_ground_station",
        "capacity_pack_contact_ids_by_ground_station_id"
      ],
      issues,
      fn field, acc ->
        validate_stable_id_array_map(
          acc,
          callbacks,
          route_path <> ".#{field}",
          Map.get(route, field)
        )
      end
    )
  end

  defp validate_contact_intent_route_fraction_maps(issues, callbacks, route_path, route) do
    Enum.reduce(
      [
        "capacity_pack_required_capacity_fraction_by_ground_station",
        "capacity_pack_required_capacity_fraction_by_ground_station_id"
      ],
      issues,
      fn field, acc ->
        validate_non_negative_number_map(
          acc,
          callbacks,
          route_path <> ".#{field}",
          Map.get(route, field)
        )
      end
    )
  end

  defp validate_contact_intent_direction_route_consistency(
         issues,
         callbacks,
         path,
         route,
         direction,
         summary
       ) do
    contact_ids_by_station =
      direction_route_nested_map(summary, direction, [
        "contact_ids_by_direction_and_ground_station",
        "contact_ids_by_direction_and_ground_station_id"
      ])

    capacity_contact_ids_by_station =
      direction_route_nested_map(summary, direction, [
        "capacity_pack_contact_ids_by_direction_and_ground_station",
        "capacity_pack_contact_ids_by_direction_and_ground_station_id"
      ])

    required_by_station =
      direction_route_nested_map(summary, direction, [
        "capacity_pack_required_capacity_fraction_by_direction_and_ground_station",
        "capacity_pack_required_capacity_fraction_by_direction_and_ground_station_id"
      ])

    station_ids =
      case contact_ids_by_station do
        %{} -> contact_ids_by_station |> Map.keys() |> Enum.sort()
        _value -> nil
      end

    issues
    |> expect_optional_field_equals(
      callbacks,
      path,
      route,
      "ground_station_ids",
      station_ids,
      "must equal contact_ids_by_direction_and_ground_station keys"
    )
    |> expect_optional_field_equals(
      callbacks,
      path,
      route,
      "contact_ids_by_ground_station",
      contact_ids_by_station,
      "must equal contact_ids_by_direction_and_ground_station for this direction"
    )
    |> expect_optional_field_equals(
      callbacks,
      path,
      route,
      "contact_ids_by_ground_station_id",
      contact_ids_by_station,
      "must equal contact_ids_by_direction_and_ground_station_id for this direction"
    )
    |> expect_optional_field_equals(
      callbacks,
      path,
      route,
      "capacity_pack_contact_ids_by_ground_station",
      capacity_contact_ids_by_station,
      "must equal capacity_pack_contact_ids_by_direction_and_ground_station for this direction"
    )
    |> expect_optional_field_equals(
      callbacks,
      path,
      route,
      "capacity_pack_contact_ids_by_ground_station_id",
      capacity_contact_ids_by_station,
      "must equal capacity_pack_contact_ids_by_direction_and_ground_station_id for this direction"
    )
    |> expect_optional_field_equals(
      callbacks,
      path,
      route,
      "capacity_pack_required_capacity_fraction_by_ground_station",
      required_by_station,
      "must equal capacity_pack_required_capacity_fraction_by_direction_and_ground_station for this direction"
    )
    |> expect_optional_field_equals(
      callbacks,
      path,
      route,
      "capacity_pack_required_capacity_fraction_by_ground_station_id",
      required_by_station,
      "must equal capacity_pack_required_capacity_fraction_by_direction_and_ground_station_id for this direction"
    )
  end

  defp direction_route_nested_map(summary, direction, fields) do
    Enum.find_value(fields, fn field ->
      case get_in(summary, [field, direction]) do
        %{} = values -> values
        _value -> nil
      end
    end)
  end

  defp maybe_single_number_map(map, field) do
    case Map.fetch(map, field) do
      {:ok, value} -> %{field => value}
      :error -> nil
    end
  end

  defp validate_station_calendar_stable_id_lists(issues, callbacks, path, summary) do
    Enum.reduce(
      [
        "affected_contact_ids",
        "affected_station_calendar_entry_ids",
        "affected_station_reservation_ids"
      ],
      issues,
      fn field, acc ->
        validate_stable_id_list(acc, callbacks, path <> ".#{field}", Map.get(summary, field))
      end
    )
  end

  defp validate_station_calendar_direction_maps(issues, callbacks, path, summary) do
    issues =
      Enum.reduce(
        [
          "contact_ids_by_direction",
          "station_calendar_entry_ids_by_direction",
          "station_reservation_ids_by_direction"
        ],
        issues,
        fn field, acc ->
          validate_stable_id_array_map(
            acc,
            callbacks,
            path <> ".#{field}",
            Map.get(summary, field)
          )
        end
      )

    validate_number_array_map(
      issues,
      callbacks,
      path <> ".station_capacity_fractions_by_direction",
      Map.get(summary, "station_capacity_fractions_by_direction")
    )
  end

  defp validate_station_calendar_direction_routing(issues, _callbacks, _path, value)
       when value in [nil, :null],
       do: issues

  defp validate_station_calendar_direction_routing(issues, callbacks, path, %{} = routing) do
    Enum.reduce(routing, issues, fn {direction, route}, acc ->
      route_path = "#{path}.direction_routing.#{direction}"

      case route do
        %{} = route ->
          acc
          |> expect_optional_non_negative_integer(callbacks, route_path, route, "contact_count")
          |> validate_station_calendar_direction_route(callbacks, route_path, route)

        _route ->
          [error(callbacks, route_path, "must be an object") | acc]
      end
    end)
  end

  defp validate_station_calendar_direction_routing(issues, callbacks, path, _value),
    do: [error(callbacks, path <> ".direction_routing", "must be an object") | issues]

  defp validate_station_calendar_direction_route(issues, callbacks, route_path, route) do
    issues =
      Enum.reduce(
        [
          "contact_ids",
          "station_calendar_entry_ids",
          "station_reservation_ids",
          "provider_contention_group_ids",
          "provider_contention_source_entry_ids",
          "provider_contention_provider_entry_ids"
        ],
        issues,
        fn field, acc ->
          validate_stable_id_list(
            acc,
            callbacks,
            route_path <> ".#{field}",
            Map.get(route, field)
          )
        end
      )

    issues
    |> validate_non_negative_number_list(
      callbacks,
      route_path <> ".station_capacity_fractions",
      Map.get(route, "station_capacity_fractions")
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      route_path,
      route,
      "provider_contention_group_count"
    )
    |> validate_non_negative_number_list(
      callbacks,
      route_path <> ".provider_contention_capacity_fractions",
      Map.get(route, "provider_contention_capacity_fractions")
    )
  end

  defp validate_station_calendar_provider_contention(issues, callbacks, path, summary) do
    issues =
      Enum.reduce(
        [
          "provider_calendar_contention_group_ids",
          "provider_calendar_contention_source_entry_ids",
          "provider_calendar_contention_provider_entry_ids"
        ],
        issues,
        fn field, acc ->
          validate_stable_id_list(acc, callbacks, path <> ".#{field}", Map.get(summary, field))
        end
      )

    issues =
      issues
      |> validate_non_negative_number_list(
        callbacks,
        path <> ".provider_calendar_contention_capacity_fractions",
        Map.get(summary, "provider_calendar_contention_capacity_fractions")
      )
      |> expect_optional_number(
        callbacks,
        path,
        summary,
        "provider_calendar_contention_minimum_capacity_fraction"
      )
      |> validate_non_negative_number_map(
        callbacks,
        path,
        maybe_single_number_map(summary, "provider_calendar_contention_minimum_capacity_fraction")
      )
      |> validate_count_maps(callbacks, path, summary, [
        "provider_calendar_contention_provider_counts",
        "provider_calendar_contention_ground_station_counts",
        "provider_calendar_contention_direction_counts"
      ])

    issues =
      Enum.reduce(
        [
          "provider_calendar_contention_group_ids_by_direction",
          "provider_calendar_contention_source_entry_ids_by_direction",
          "provider_calendar_contention_provider_entry_ids_by_direction"
        ],
        issues,
        fn field, acc ->
          validate_stable_id_array_map(
            acc,
            callbacks,
            path <> ".#{field}",
            Map.get(summary, field)
          )
        end
      )

    validate_number_array_map(
      issues,
      callbacks,
      path <> ".provider_calendar_contention_capacity_fractions_by_direction",
      Map.get(summary, "provider_calendar_contention_capacity_fractions_by_direction")
    )
  end

  defp validate_validation_safety_case_counts(issues, callbacks, path, summary) do
    Enum.reduce(safety_case_count_fields(callbacks), issues, fn field, acc ->
      expect_optional_non_negative_integer(acc, callbacks, path, summary, field)
    end)
  end

  defp validate_timeline_activity_state_action_routing(issues, _callbacks, _path, _field, value)
       when value in [nil, :null],
       do: issues

  defp validate_timeline_activity_state_action_routing(
         issues,
         callbacks,
         path,
         field,
         %{} = routes
       ) do
    Enum.reduce(routes, issues, fn {action, route}, acc ->
      route_path = path <> ".#{field}.#{action}"

      acc
      |> expect_type(callbacks, path <> ".#{field}", routes, action, :map)
      |> validate_timeline_activity_state_action_route(callbacks, route_path, route)
    end)
  end

  defp validate_timeline_activity_state_action_routing(
         issues,
         _callbacks,
         _path,
         _field,
         _value
       ),
       do: issues

  defp validate_timeline_activity_state_action_route(issues, callbacks, path, %{} = route) do
    issues
    |> expect_optional_non_negative_integer(callbacks, path, route, "review_count")
    |> expect_optional_type(callbacks, path, route, "activity_ids", :list)
    |> expect_optional_type(callbacks, path, route, "timeline_ids", :list)
    |> expect_optional_type(callbacks, path, route, "status_transition_categories", :list)
    |> expect_optional_type(callbacks, path, route, "approval_transition_categories", :list)
    |> expect_optional_type(callbacks, path, route, "protection_categories", :list)
    |> validate_optional_stable_id_list(callbacks, path, route, "activity_ids")
    |> validate_optional_stable_id_list(callbacks, path, route, "timeline_ids")
    |> validate_optional_string_list(callbacks, path, route, "status_transition_categories")
    |> validate_optional_string_list(callbacks, path, route, "approval_transition_categories")
    |> validate_optional_string_list(callbacks, path, route, "protection_categories")
  end

  defp validate_timeline_activity_state_action_route(issues, _callbacks, _path, _route),
    do: issues

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_optional_non_negative_integer(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :expect_optional_non_negative_integer), [
      issues,
      path,
      map,
      field
    ])
  end

  defp expect_optional_number(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_number), [issues, path, map, field])

  defp validate_non_negative_integer_count_map(issues, callbacks, path, counts) do
    apply(Keyword.fetch!(callbacks, :validate_non_negative_integer_count_map), [
      issues,
      path,
      counts
    ])
  end

  defp validate_optional_stable_id_array_map(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :validate_optional_stable_id_array_map), [
      issues,
      path,
      map,
      field
    ])
  end

  defp validate_stable_id_list(issues, callbacks, path, values),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_id_list), [issues, path, values])

  defp validate_stable_id_array_map(issues, callbacks, path, values),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_id_array_map), [issues, path, values])

  defp validate_nested_stable_id_array_map(issues, callbacks, path, values) do
    apply(Keyword.fetch!(callbacks, :validate_nested_stable_id_array_map), [
      issues,
      path,
      values
    ])
  end

  defp validate_non_negative_number_map(issues, callbacks, path, values) do
    apply(Keyword.fetch!(callbacks, :validate_non_negative_number_map), [
      issues,
      path,
      values
    ])
  end

  defp validate_nested_non_negative_number_map(issues, callbacks, path, values) do
    apply(Keyword.fetch!(callbacks, :validate_nested_non_negative_number_map), [
      issues,
      path,
      values
    ])
  end

  defp validate_non_negative_number_list(issues, callbacks, path, values) do
    apply(Keyword.fetch!(callbacks, :validate_non_negative_number_list), [
      issues,
      path,
      values
    ])
  end

  defp validate_number_array_map(issues, callbacks, path, values) do
    apply(Keyword.fetch!(callbacks, :validate_number_array_map), [
      issues,
      path,
      values
    ])
  end

  defp expect_optional_field_equals(issues, callbacks, path, map, field, expected, message) do
    apply(Keyword.fetch!(callbacks, :expect_optional_field_equals), [
      issues,
      path,
      map,
      field,
      expected,
      message
    ])
  end

  defp validate_operational_readiness_resource_context(issues, callbacks, path, summary) do
    apply(Keyword.fetch!(callbacks, :validate_operational_readiness_resource_context), [
      issues,
      path,
      summary
    ])
  end

  defp validate_operational_readiness_adapter_boundary_context(
         issues,
         callbacks,
         path,
         summary
       ) do
    apply(Keyword.fetch!(callbacks, :validate_operational_readiness_adapter_boundary_context), [
      issues,
      path,
      summary
    ])
  end

  defp validate_operational_readiness_cadence_import_context(issues, callbacks, path, summary) do
    apply(Keyword.fetch!(callbacks, :validate_operational_readiness_cadence_import_context), [
      issues,
      path,
      summary
    ])
  end

  defp error(callbacks, path, message),
    do: apply(Keyword.fetch!(callbacks, :error), [path, message])

  defp validate_optional_stable_id_list(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :validate_optional_stable_id_list), [
      issues,
      path,
      map,
      field
    ])
  end

  defp validate_optional_string_list(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :validate_optional_string_list), [
      issues,
      path,
      map,
      field
    ])
  end

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_string_list_map(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_string_list_map), [issues, path, map, field])

  defp safety_case_count_fields(callbacks),
    do: apply(Keyword.fetch!(callbacks, :safety_case_count_fields), [])
end
