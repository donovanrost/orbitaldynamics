defmodule OrbitalDynamics.Schema.TimelineHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [expect_field_equals: 6, expect_optional_type: 5]

  @timeline_transition_application_source_field_pairs [
    {"subject_id", "timeline_id"},
    {"timeline_id", "timeline_id"},
    {"diff_status", "diff_status"},
    {"source_activity_id", "source_activity_id"},
    {"replacement_activity_id", "replacement_activity_id"},
    {"source_activity_type", "source_activity_type"},
    {"replacement_activity_type", "replacement_activity_type"},
    {"transition_decision", "transition_decision"},
    {"transition_decision_reason", "transition_decision_reason"},
    {"requires_operator_review", "requires_operator_review"},
    {"required_operator_action", "required_operator_action"},
    {"reason", "reason"},
    {"changed_fields", "changed_fields"},
    {"status_transition", "status_transition"},
    {"approval_transition", "approval_transition"},
    {"application_status", "application_status"},
    {"selected_activity_source", "selected_activity_source"},
    {"selected_activity", "selected_activity"},
    {"selected_timeline_integrity_status", "selected_timeline_integrity_status"},
    {"selected_timeline_integrity_issue_count", "selected_timeline_integrity_issue_count"},
    {"selected_timeline_integrity_issue_types", "selected_timeline_integrity_issue_types"},
    {"selected_timeline_integrity_issues", "selected_timeline_integrity_issues"},
    {"selected_missing_dependency_activity_ids", "selected_missing_dependency_activity_ids"},
    {"selected_missing_dependency_timeline_ids", "selected_missing_dependency_timeline_ids"},
    {"selected_self_dependency_activity_ids", "selected_self_dependency_activity_ids"},
    {"selected_self_dependency_timeline_ids", "selected_self_dependency_timeline_ids"},
    {"selected_duplicate_dependency_activity_ids", "selected_duplicate_dependency_activity_ids"},
    {"selected_duplicate_dependency_timeline_ids", "selected_duplicate_dependency_timeline_ids"},
    {"selected_duplicate_exclusivity_activity_ids",
     "selected_duplicate_exclusivity_activity_ids"},
    {"selected_duplicate_exclusivity_timeline_ids",
     "selected_duplicate_exclusivity_timeline_ids"},
    {"selected_dependency_cycle_activity_ids", "selected_dependency_cycle_activity_ids"},
    {"selected_dependency_cycle_timeline_ids", "selected_dependency_cycle_timeline_ids"},
    {"selected_dependency_order_violation_activity_ids",
     "selected_dependency_order_violation_activity_ids"},
    {"selected_dependency_order_violation_timeline_ids",
     "selected_dependency_order_violation_timeline_ids"},
    {"selected_exclusivity_violation_activity_ids",
     "selected_exclusivity_violation_activity_ids"},
    {"selected_exclusivity_violation_timeline_ids",
     "selected_exclusivity_violation_timeline_ids"},
    {"selected_exclusivity_violation_group", "selected_exclusivity_violation_group"}
  ]
  @timeline_transition_application_source_review_fields Enum.map(
                                                          [
                                                            "subject_id",
                                                            "timeline_id",
                                                            "diff_status",
                                                            "source_activity_id",
                                                            "replacement_activity_id",
                                                            "source_activity_type",
                                                            "replacement_activity_type",
                                                            "transition_decision",
                                                            "transition_decision_reason",
                                                            "requires_operator_review",
                                                            "required_operator_action",
                                                            "reason",
                                                            "changed_fields",
                                                            "status_transition",
                                                            "approval_transition",
                                                            "application_status",
                                                            "selected_activity_source",
                                                            "selected_activity",
                                                            "selected_timeline_integrity_status",
                                                            "selected_timeline_integrity_issue_count",
                                                            "selected_timeline_integrity_issue_types",
                                                            "selected_timeline_integrity_issues",
                                                            "selected_missing_dependency_activity_ids",
                                                            "selected_missing_dependency_timeline_ids",
                                                            "selected_self_dependency_activity_ids",
                                                            "selected_self_dependency_timeline_ids",
                                                            "selected_duplicate_dependency_activity_ids",
                                                            "selected_duplicate_dependency_timeline_ids",
                                                            "selected_duplicate_exclusivity_activity_ids",
                                                            "selected_duplicate_exclusivity_timeline_ids",
                                                            "selected_dependency_cycle_activity_ids",
                                                            "selected_dependency_cycle_timeline_ids",
                                                            "selected_dependency_order_violation_activity_ids",
                                                            "selected_dependency_order_violation_timeline_ids",
                                                            "selected_exclusivity_violation_activity_ids",
                                                            "selected_exclusivity_violation_timeline_ids",
                                                            "selected_exclusivity_violation_group",
                                                            "source_timeline_application"
                                                          ],
                                                          &{&1, &1}
                                                        )
  @timeline_diff_source_field_pairs [
    {"subject_id", "timeline_id"},
    {"timeline_id", "timeline_id"},
    {"diff_status", "diff_status"},
    {"source_activity_id", "source_activity_id"},
    {"replacement_activity_id", "replacement_activity_id"},
    {"source_activity_type", "source_activity_type"},
    {"replacement_activity_type", "replacement_activity_type"},
    {"scenario_id", "scenario_id"},
    {"source_starts_at_s", "source_starts_at_s"},
    {"source_ends_at_s", "source_ends_at_s"},
    {"replacement_starts_at_s", "replacement_starts_at_s"},
    {"replacement_ends_at_s", "replacement_ends_at_s"},
    {"start_delta_s", "start_delta_s"},
    {"end_delta_s", "end_delta_s"},
    {"source_status", "source_status"},
    {"replacement_status", "replacement_status"},
    {"source_approval_status", "source_approval_status"},
    {"replacement_approval_status", "replacement_approval_status"},
    {"source_locked", "source_locked"},
    {"replacement_locked", "replacement_locked"},
    {"source_protection_decision", "source_protection_decision"},
    {"source_protection_category", "source_protection_category"},
    {"source_protection_reason", "source_protection_reason"},
    {"replacement_protection_decision", "replacement_protection_decision"},
    {"replacement_protection_category", "replacement_protection_category"},
    {"replacement_protection_reason", "replacement_protection_reason"},
    {"source_timeline_integrity_status", "source_timeline_integrity_status"},
    {"source_timeline_integrity_issue_count", "source_timeline_integrity_issue_count"},
    {"source_timeline_integrity_issue_types", "source_timeline_integrity_issue_types"},
    {"source_timeline_integrity_issues", "source_timeline_integrity_issues"},
    {"source_missing_dependency_activity_ids", "source_missing_dependency_activity_ids"},
    {"source_missing_dependency_timeline_ids", "source_missing_dependency_timeline_ids"},
    {"source_self_dependency_activity_ids", "source_self_dependency_activity_ids"},
    {"source_self_dependency_timeline_ids", "source_self_dependency_timeline_ids"},
    {"source_dependency_cycle_activity_ids", "source_dependency_cycle_activity_ids"},
    {"source_dependency_cycle_timeline_ids", "source_dependency_cycle_timeline_ids"},
    {"replacement_timeline_integrity_status", "replacement_timeline_integrity_status"},
    {"replacement_timeline_integrity_issue_count", "replacement_timeline_integrity_issue_count"},
    {"replacement_timeline_integrity_issue_types", "replacement_timeline_integrity_issue_types"},
    {"replacement_timeline_integrity_issues", "replacement_timeline_integrity_issues"},
    {"replacement_missing_dependency_activity_ids",
     "replacement_missing_dependency_activity_ids"},
    {"replacement_missing_dependency_timeline_ids",
     "replacement_missing_dependency_timeline_ids"},
    {"replacement_self_dependency_activity_ids", "replacement_self_dependency_activity_ids"},
    {"replacement_self_dependency_timeline_ids", "replacement_self_dependency_timeline_ids"},
    {"replacement_dependency_cycle_activity_ids", "replacement_dependency_cycle_activity_ids"},
    {"replacement_dependency_cycle_timeline_ids", "replacement_dependency_cycle_timeline_ids"},
    {"status_transition", "status_transition"},
    {"approval_transition", "approval_transition"},
    {"changed_fields", "changed_fields"},
    {"timeline_identity_collision", "timeline_identity_collision"},
    {"duplicate_timeline_identity_scope", "duplicate_timeline_identity_scope"},
    {"source_duplicate_activity_count", "source_duplicate_activity_count"},
    {"replacement_duplicate_activity_count", "replacement_duplicate_activity_count"},
    {"source_duplicate_activity_ids", "source_duplicate_activity_ids"},
    {"replacement_duplicate_activity_ids", "replacement_duplicate_activity_ids"},
    {"source_invalid_activity_input", "source_invalid_activity_input"},
    {"source_invalid_activity_input_reason", "source_invalid_activity_input_reason"},
    {"replacement_invalid_activity_input", "replacement_invalid_activity_input"},
    {"replacement_invalid_activity_input_reason", "replacement_invalid_activity_input_reason"},
    {"transition_decision", "transition_decision"},
    {"transition_decision_reason", "transition_decision_reason"},
    {"requires_operator_review", "requires_operator_review"},
    {"required_operator_action", "required_operator_action"},
    {"reason", "reason"},
    {"application_status", "application_status"},
    {"selected_activity_source", "selected_activity_source"},
    {"selected_activity", "selected_activity"},
    {"selected_timeline_integrity_status", "selected_timeline_integrity_status"},
    {"selected_timeline_integrity_issue_count", "selected_timeline_integrity_issue_count"},
    {"selected_timeline_integrity_issue_types", "selected_timeline_integrity_issue_types"},
    {"selected_timeline_integrity_issues", "selected_timeline_integrity_issues"},
    {"selected_missing_dependency_activity_ids", "selected_missing_dependency_activity_ids"},
    {"selected_missing_dependency_timeline_ids", "selected_missing_dependency_timeline_ids"},
    {"selected_self_dependency_activity_ids", "selected_self_dependency_activity_ids"},
    {"selected_self_dependency_timeline_ids", "selected_self_dependency_timeline_ids"},
    {"selected_duplicate_dependency_activity_ids", "selected_duplicate_dependency_activity_ids"},
    {"selected_duplicate_dependency_timeline_ids", "selected_duplicate_dependency_timeline_ids"},
    {"selected_duplicate_exclusivity_activity_ids",
     "selected_duplicate_exclusivity_activity_ids"},
    {"selected_duplicate_exclusivity_timeline_ids",
     "selected_duplicate_exclusivity_timeline_ids"},
    {"selected_dependency_cycle_activity_ids", "selected_dependency_cycle_activity_ids"},
    {"selected_dependency_cycle_timeline_ids", "selected_dependency_cycle_timeline_ids"},
    {"selected_dependency_order_violation_activity_ids",
     "selected_dependency_order_violation_activity_ids"},
    {"selected_dependency_order_violation_timeline_ids",
     "selected_dependency_order_violation_timeline_ids"},
    {"selected_exclusivity_violation_activity_ids",
     "selected_exclusivity_violation_activity_ids"},
    {"selected_exclusivity_violation_timeline_ids",
     "selected_exclusivity_violation_timeline_ids"},
    {"selected_exclusivity_violation_group", "selected_exclusivity_violation_group"},
    {"source_timeline_identity", "source_timeline_identity"},
    {"replacement_timeline_identity", "replacement_timeline_identity"},
    {"source_activity_context", "source_activity_context"},
    {"replacement_activity_context", "replacement_activity_context"}
  ]
  @timeline_diff_source_review_fields [
    {"id", "source_review_row_id"},
    {"review_type", "source_review_type"},
    {"action", "source_review_action"},
    {"source", "source"},
    {"source_timeline_diff", "source_timeline_diff"}
    | @timeline_diff_source_field_pairs
  ]
  @operational_timeline_source_field_pairs [
    {"activity_id", "activity_id"},
    {"timeline_id", "timeline_id"},
    {"scenario_id", "scenario_id"},
    {"activity_type", "activity_type"},
    {"operational_kind", "operational_kind"},
    {"direction", "direction"},
    {"spacecraft_id", "spacecraft_id"},
    {"ground_station_id", "ground_station_id"},
    {"target_id", "target_id"},
    {"resource_id", "resource_id"},
    {"collection_id", "collection_id"},
    {"product_id", "product_id"},
    {"product_ids", "product_ids"},
    {"payload_id", "payload_id"},
    {"instrument_id", "instrument_id"},
    {"starts_at_s", "starts_at_s"},
    {"ends_at_s", "ends_at_s"},
    {"status", "status"},
    {"source_approval_status", "approval_status"},
    {"locked", "locked"},
    {"command_authority_status", "command_authority_status"},
    {"required_authority", "required_authority"},
    {"command_safety_status", "command_safety_status"},
    {"command_authorized", "command_authorized"},
    {"command_safety_checked", "command_safety_checked"},
    {"precondition_status", "precondition_status"},
    {"blocked_precondition_count", "blocked_precondition_count"},
    {"review_precondition_count", "review_precondition_count"},
    {"blocked_precondition_types", "blocked_precondition_types"},
    {"review_precondition_types", "review_precondition_types"},
    {"preconditions", "preconditions"},
    {"action", "required_operator_action"},
    {"required_operator_action", "required_operator_action"},
    {"operator_action_reason", "operator_action_reason"},
    {"execution_boundary", "execution_boundary"},
    {"cadence_import_type", "cadence_import_type"},
    {"cadence_import_id", "cadence_import_id"},
    {"cadence_import_contract", "cadence_import_contract"},
    {"source_window_id", "source_window_id"},
    {"source_window_type", "source_window_type"},
    {"schedule_conflict_status", "schedule_conflict_status"},
    {"exclusivity_group", "exclusivity_group"},
    {"dependency_activity_ids", "dependency_activity_ids"},
    {"dependency_timeline_ids", "dependency_timeline_ids"},
    {"exclusive_with_activity_ids", "exclusive_with_activity_ids"},
    {"exclusive_with_timeline_ids", "exclusive_with_timeline_ids"},
    {"has_source_window", "has_source_window"},
    {"timeline_identity", "timeline_identity"}
  ]
  @operational_timeline_source_review_fields Enum.map(
                                               [
                                                 "subject_id",
                                                 "activity_id",
                                                 "timeline_id",
                                                 "scenario_id",
                                                 "activity_type",
                                                 "operational_kind",
                                                 "direction",
                                                 "spacecraft_id",
                                                 "ground_station_id",
                                                 "target_id",
                                                 "resource_id",
                                                 "collection_id",
                                                 "product_id",
                                                 "product_ids",
                                                 "payload_id",
                                                 "instrument_id",
                                                 "starts_at_s",
                                                 "ends_at_s",
                                                 "status",
                                                 "approval_status",
                                                 "source_approval_status",
                                                 "locked",
                                                 "command_authority_status",
                                                 "required_authority",
                                                 "command_safety_status",
                                                 "command_authorized",
                                                 "command_safety_checked",
                                                 "precondition_status",
                                                 "blocked_precondition_count",
                                                 "review_precondition_count",
                                                 "blocked_precondition_types",
                                                 "review_precondition_types",
                                                 "preconditions",
                                                 "action",
                                                 "required_operator_action",
                                                 "reason",
                                                 "operator_action_reason",
                                                 "execution_boundary",
                                                 "cadence_import_type",
                                                 "cadence_import_id",
                                                 "cadence_import_contract",
                                                 "source_window_id",
                                                 "source_window_type",
                                                 "schedule_conflict_status",
                                                 "exclusivity_group",
                                                 "dependency_activity_ids",
                                                 "dependency_timeline_ids",
                                                 "exclusive_with_activity_ids",
                                                 "exclusive_with_timeline_ids",
                                                 "has_source_window",
                                                 "timeline_identity",
                                                 "source_operational_timeline"
                                               ],
                                               &{&1, &1}
                                             )
  @timeline_publication_source_review_fields [
    {"source_timeline_publication_summary", "source_timeline_publication_summary"}
  ]
  @timeline_publication_handoff_fields [
    "publication_id",
    "publication_sequence",
    "publication_status",
    "downstream_invalidation_status",
    "publication_authority",
    "source_artifact_id",
    "source_artifact_type",
    "supersedes_artifact_ids",
    "downstream_product_ids",
    "invalidated_downstream_product_ids",
    "downstream_invalidation_reason_counts",
    "invalidated_downstream_product_ids_by_reason",
    "dependency_impact_status",
    "dependency_impact_row_count",
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
    "timeline_diff_row_count",
    "timeline_diff_changed_count",
    "timeline_diff_review_required_count",
    "changed_field_counts",
    "changed_timeline_ids",
    "review_timeline_ids",
    "timeline_ids_by_changed_field"
  ]
  @timeline_publication_unique_handoff_fields [
    "publication_id",
    "publication_sequence",
    "publication_status",
    "downstream_invalidation_status",
    "publication_authority",
    "supersedes_artifact_ids",
    "downstream_product_ids",
    "invalidated_downstream_product_ids",
    "downstream_invalidation_reason_counts",
    "invalidated_downstream_product_ids_by_reason",
    "timeline_diff_row_count",
    "timeline_diff_changed_count",
    "timeline_diff_review_required_count",
    "changed_field_counts",
    "changed_timeline_ids",
    "timeline_ids_by_changed_field"
  ]
  @timeline_dependency_impact_source_review_fields [
    {"source_timeline_dependency_impact", "source_timeline_dependency_impact"}
  ]
  @timeline_activity_precondition_source_review_fields [
    {"source_timeline_activity_precondition_summary",
     "source_timeline_activity_precondition_summary"}
  ]
  @timeline_lifecycle_state_source_review_fields [
    {"source_timeline_lifecycle_state", "source_timeline_lifecycle_state"}
  ]
  @timeline_preservation_source_review_fields [
    {"source_timeline_preservation", "source_timeline_preservation"}
  ]

  def validate_timeline_diff_matches_source(
        issues,
        path,
        %{"source_timeline_diff" => %{} = source_row} = row
      ) do
    if timeline_diff_handoff_row?(row) do
      validate_source_pairs(
        issues,
        path,
        row,
        source_row,
        @timeline_diff_source_field_pairs,
        "source_timeline_diff"
      )
    else
      issues
    end
  end

  def validate_timeline_diff_matches_source(issues, _path, _row), do: issues

  def validate_cadence_source_review_timeline_diff_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if timeline_diff_handoff_row?(row) do
      validate_cadence_source_review_pairs(
        issues,
        path,
        row,
        source_review_row,
        @timeline_diff_source_review_fields
      )
    else
      issues
    end
  end

  def validate_cadence_source_review_timeline_diff_matches(issues, _path, _row), do: issues

  def validate_timeline_transition_application_matches_source(
        issues,
        path,
        %{"source_timeline_application" => %{} = source_row} = row
      ) do
    if timeline_transition_application_handoff_row?(row) do
      validate_source_pairs(
        issues,
        path,
        row,
        source_row,
        @timeline_transition_application_source_field_pairs,
        "source_timeline_application"
      )
    else
      issues
    end
  end

  def validate_timeline_transition_application_matches_source(issues, _path, _row), do: issues

  def validate_cadence_source_review_timeline_transition_application_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if timeline_transition_application_handoff_row?(row) do
      validate_cadence_source_review_pairs(
        issues,
        path,
        row,
        source_review_row,
        @timeline_transition_application_source_review_fields
      )
    else
      issues
    end
  end

  def validate_cadence_source_review_timeline_transition_application_matches(
        issues,
        _path,
        _row
      ),
      do: issues

  def validate_operational_timeline_matches_source(
        issues,
        path,
        %{"source_operational_timeline" => %{} = source_row} = row
      ) do
    if operational_timeline_handoff_row?(row) do
      validate_source_pairs(
        issues,
        path,
        row,
        source_row,
        @operational_timeline_source_field_pairs,
        "source_operational_timeline"
      )
    else
      issues
    end
  end

  def validate_operational_timeline_matches_source(issues, _path, _row), do: issues

  def validate_cadence_source_review_operational_timeline_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if operational_timeline_handoff_row?(row) do
      validate_cadence_source_review_pairs(
        issues,
        path,
        row,
        source_review_row,
        @operational_timeline_source_review_fields
      )
    else
      issues
    end
  end

  def validate_cadence_source_review_operational_timeline_matches(issues, _path, _row),
    do: issues

  def validate_cadence_source_review_timeline_publication_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if timeline_publication_handoff_row?(row) do
      validate_cadence_source_review_pairs(
        issues,
        path,
        row,
        source_review_row,
        @timeline_publication_source_review_fields
      )
    else
      issues
    end
  end

  def validate_cadence_source_review_timeline_publication_matches(issues, _path, _row),
    do: issues

  def validate_optional_timeline_publication_summary_source(issues, _path, nil, _callbacks),
    do: issues

  def validate_optional_timeline_publication_summary_source(
        issues,
        path,
        %{} = summary,
        callbacks
      ) do
    OrbitalDynamics.Schema.TimelinePublicationSummaryContracts.validate(
      issues,
      path,
      summary,
      callbacks
    )
  end

  def validate_optional_timeline_publication_summary_source(issues, path, _summary, _callbacks),
    do: [error(path, "must be an object") | issues]

  def validate_timeline_publication_matches_source_summary(
        issues,
        path,
        row,
        publication_summary_validator
      )
      when is_function(publication_summary_validator, 3) do
    source_summary = Map.get(row, "source_timeline_publication_summary")

    issues
    |> expect_optional_type(path, row, "source_timeline_publication_summary", :map)
    |> publication_summary_validator.(
      path <> ".source_timeline_publication_summary",
      source_summary
    )
    |> validate_timeline_publication_handoff_matches_source_summary(
      path,
      row,
      source_summary
    )
  end

  def validate_cadence_source_review_timeline_dependency_impact_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if timeline_dependency_impact_handoff_row?(row) do
      validate_cadence_source_review_pairs(
        issues,
        path,
        row,
        source_review_row,
        @timeline_dependency_impact_source_review_fields
      )
    else
      issues
    end
  end

  def validate_cadence_source_review_timeline_dependency_impact_matches(issues, _path, _row),
    do: issues

  def validate_cadence_source_review_timeline_activity_precondition_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if timeline_activity_precondition_handoff_row?(row) do
      validate_cadence_source_review_pairs(
        issues,
        path,
        row,
        source_review_row,
        @timeline_activity_precondition_source_review_fields
      )
    else
      issues
    end
  end

  def validate_cadence_source_review_timeline_activity_precondition_matches(issues, _path, _row),
    do: issues

  def validate_cadence_source_review_timeline_lifecycle_state_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if timeline_lifecycle_state_handoff_row?(row) do
      validate_cadence_source_review_pairs(
        issues,
        path,
        row,
        source_review_row,
        @timeline_lifecycle_state_source_review_fields
      )
    else
      issues
    end
  end

  def validate_cadence_source_review_timeline_lifecycle_state_matches(issues, _path, _row),
    do: issues

  def validate_cadence_source_review_timeline_preservation_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if timeline_preservation_handoff_row?(row) do
      validate_cadence_source_review_pairs(
        issues,
        path,
        row,
        source_review_row,
        @timeline_preservation_source_review_fields
      )
    else
      issues
    end
  end

  def validate_cadence_source_review_timeline_preservation_matches(issues, _path, _row),
    do: issues

  def timeline_diff_handoff_row?(row) do
    Map.get(row, "review_type") == "timeline_diff_review" or
      Map.get(row, "source_review_type") == "timeline_diff_review" or
      Map.get(row, "import_action") == "review_timeline_diff"
  end

  def timeline_transition_application_handoff_row?(row) do
    timeline_diff_handoff_row?(row) and Map.has_key?(row, "source_timeline_application")
  end

  def operational_timeline_handoff_row?(row) do
    Map.get(row, "review_type") == "operational_timeline_review" or
      Map.get(row, "source_review_type") == "operational_timeline_review" or
      Map.get(row, "import_action") == "review_operational_timeline"
  end

  def timeline_publication_handoff_row?(row) do
    Map.get(row, "review_type") == "timeline_publication_review" or
      Map.get(row, "source_review_type") == "timeline_publication_review" or
      Map.get(row, "import_action") == "review_timeline_publication"
  end

  def timeline_dependency_impact_handoff_row?(row) do
    Map.get(row, "review_type") == "timeline_dependency_impact_review" or
      Map.get(row, "source_review_type") == "timeline_dependency_impact_review" or
      Map.get(row, "import_action") == "review_timeline_dependency_impact"
  end

  def timeline_activity_precondition_handoff_row?(row) do
    Map.get(row, "review_type") == "timeline_activity_precondition_review" or
      Map.get(row, "source_review_type") == "timeline_activity_precondition_review" or
      Map.get(row, "import_action") == "review_timeline_precondition"
  end

  def timeline_lifecycle_state_handoff_row?(row) do
    Map.get(row, "review_type") == "timeline_lifecycle_state_review" or
      Map.get(row, "source_review_type") == "timeline_lifecycle_state_review" or
      Map.get(row, "import_action") == "review_timeline_lifecycle_state"
  end

  def timeline_preservation_handoff_row?(row) do
    Map.get(row, "review_type") == "timeline_preservation_review" or
      Map.get(row, "source_review_type") == "timeline_preservation_review" or
      Map.get(row, "import_action") == "review_timeline_preservation"
  end

  defp validate_source_pairs(issues, path, row, source_row, field_pairs, source_key) do
    Enum.reduce(field_pairs, issues, fn {row_field, source_field}, acc ->
      row_value = Map.get(row, row_field)
      source_value = Map.get(source_row, source_field)

      if not is_nil(row_value) and not is_nil(source_value) and row_value != source_value do
        [error("#{path}.#{row_field}", "must match #{source_key}.#{source_field}") | acc]
      else
        acc
      end
    end)
  end

  defp validate_cadence_source_review_pairs(
         issues,
         path,
         row,
         source_review_row,
         field_pairs
       ) do
    Enum.reduce(field_pairs, issues, fn {source_field, row_field}, acc ->
      source_value = Map.get(source_review_row, source_field)
      row_value = Map.get(row, row_field)

      if not is_nil(source_value) and not is_nil(row_value) and source_value != row_value do
        [
          error(
            "#{path}.source_review_row.#{source_field}",
            "must match #{row_field} on Cadence import row"
          )
          | acc
        ]
      else
        acc
      end
    end)
  end

  defp validate_timeline_publication_handoff_matches_source_summary(
         issues,
         path,
         row,
         %{} = source_summary
       ) do
    Enum.reduce(@timeline_publication_handoff_fields, issues, fn field, acc ->
      acc
      |> require_timeline_publication_handoff_field(path, row, source_summary, field)
      |> expect_field_equals(
        path,
        row,
        field,
        Map.get(source_summary, field),
        "must equal source_timeline_publication_summary.#{field}"
      )
    end)
  end

  defp validate_timeline_publication_handoff_matches_source_summary(
         issues,
         path,
         row,
         _source
       ) do
    if Enum.any?(@timeline_publication_unique_handoff_fields, &Map.has_key?(row, &1)) do
      [
        error(
          path <> ".source_timeline_publication_summary",
          "must be present when timeline publication handoff fields are present"
        )
        | issues
      ]
    else
      issues
    end
  end

  defp require_timeline_publication_handoff_field(issues, path, row, source_summary, field) do
    if Map.has_key?(source_summary, field) and not Map.has_key?(row, field) do
      [
        error(
          "#{path}.#{field}",
          "must be present when source_timeline_publication_summary.#{field} is present"
        )
        | issues
      ]
    else
      issues
    end
  end

  defp error(path, message) do
    %{"severity" => "error", "path" => path, "message" => message}
  end
end
