defmodule OrbitalDynamics.Schema.SourceReviewHandoffContracts do
  @moduledoc false

  @policy_escalation_fields [
    {"id", "source_review_row_id"},
    {"review_type", "source_review_type"},
    {"action", "source_review_action"},
    {"subject_id", "subject_id"},
    {"approval_status", "approval_status"},
    {"required_operator_action", "required_operator_action"},
    {"reason", "reason"},
    {"policy_bundle_id", "policy_bundle_id"},
    {"policy_bundle_provenance", "policy_bundle_provenance"},
    {"policy_bundle_provenance_source", "policy_bundle_provenance_source"},
    {"policy_bundle_adapter", "policy_bundle_adapter"},
    {"policy_bundle_organization_id", "policy_bundle_organization_id"},
    {"policy_bundle_policy_source", "policy_bundle_policy_source"},
    {"rule_id", "rule_id"},
    {"escalation_level", "escalation_level"},
    {"escalation_queue", "escalation_queue"},
    {"escalation_role", "escalation_role"},
    {"required_authority", "required_authority"},
    {"sla_s", "sla_s"},
    {"source_policy_escalation", "source_policy_escalation"},
    {"source_policy_decision", "source_policy_decision"}
  ]
  @freshness_fields [
    {"id", "source_review_row_id"},
    {"review_type", "source_review_type"},
    {"action", "source_review_action"},
    {"source", "source"},
    {"subject_id", "subject_id"},
    {"branch_id", "branch_id"},
    {"reason", "reason"},
    {"approval_status", "approval_status"},
    {"required_operator_action", "required_operator_action"},
    {"freshness_status", "freshness_status"},
    {"freshness_status", "refresh_gate_status"},
    {"generated_at", "generated_at"},
    {"accepted_at", "accepted_at"},
    {"accepted_state_quality_level", "accepted_state_quality_level"},
    {"allowed_state_quality_levels", "allowed_state_quality_levels"},
    {"state_quality_status", "state_quality_status"},
    {"current_epoch_s", "current_epoch_s"},
    {"horizon_starts_at_s", "horizon_starts_at_s"},
    {"accepted_snapshot_age_s", "accepted_snapshot_age_s"},
    {"horizon_start_offset_s", "horizon_start_offset_s"},
    {"max_snapshot_age_s", "max_snapshot_age_s"},
    {"max_horizon_start_offset_s", "max_horizon_start_offset_s"},
    {"stale_reasons", "stale_reasons"},
    {"unknown_reasons", "unknown_reasons"},
    {"source_freshness_report", "source_freshness_report"}
  ]
  @warning_fields [
    {"id", "source_review_row_id"},
    {"review_type", "source_review_type"},
    {"action", "source_review_action"},
    {"source", "source"},
    {"subject_id", "subject_id"},
    {"branch_id", "branch_id"},
    {"scenario_id", "scenario_id"},
    {"activity_id", "activity_id"},
    {"activity_type", "activity_type"},
    {"ground_station_id", "ground_station_id"},
    {"spacecraft_id", "spacecraft_id"},
    {"target_id", "target_id"},
    {"direction", "direction"},
    {"station_calendar_entry_id", "station_calendar_entry_id"},
    {"station_calendar_provider_id", "station_calendar_provider_id"},
    {"station_calendar_provider_entry_id", "station_calendar_provider_entry_id"},
    {"station_calendar_directions", "station_calendar_directions"},
    {"first_resource_pressure_activity_id", "first_resource_pressure_activity_id"},
    {"first_resource_pressure_activity_type", "first_resource_pressure_activity_type"},
    {"first_resource_pressure_kind", "first_resource_pressure_kind"},
    {"first_resource_pressure_starts_at_s", "first_resource_pressure_starts_at_s"},
    {"first_resource_pressure_direction", "first_resource_pressure_direction"},
    {"first_resource_pressure_ground_station_id", "first_resource_pressure_ground_station_id"},
    {"first_resource_pressure_station_calendar_entry_id",
     "first_resource_pressure_station_calendar_entry_id"},
    {"first_resource_pressure_station_calendar_provider_id",
     "first_resource_pressure_station_calendar_provider_id"},
    {"first_resource_pressure_station_calendar_provider_entry_id",
     "first_resource_pressure_station_calendar_provider_entry_id"},
    {"first_resource_pressure_station_calendar_directions",
     "first_resource_pressure_station_calendar_directions"},
    {"approval_status", "approval_status"},
    {"required_operator_action", "required_operator_action"},
    {"reason", "reason"},
    {"severity", "severity"},
    {"operational_feedback_trust_boundary_status", "operational_feedback_trust_boundary_status"},
    {"operational_feedback_trust_boundary", "operational_feedback_trust_boundary"},
    {"operational_feedback_trust_boundaries", "operational_feedback_trust_boundaries"},
    {"operational_feedback_field_trust_boundaries",
     "operational_feedback_field_trust_boundaries"},
    {"operational_feedback_input_keys", "operational_feedback_input_keys"},
    {"source_operational_feedback", "source_operational_feedback"},
    {"source_operational_feedback_provenance", "source_operational_feedback_provenance"}
  ]
  @timeline_protection_fields [
    {"id", "source_review_row_id"},
    {"review_type", "source_review_type"},
    {"action", "source_review_action"},
    {"source", "source"},
    {"subject_id", "subject_id"},
    {"activity_id", "activity_id"},
    {"approval_status", "approval_status"},
    {"required_operator_action", "required_operator_action"},
    {"reason", "reason"},
    {"protection_category", "protection_category"},
    {"protection_decision", "protection_decision"},
    {"source_timeline_protection", "source_timeline_protection"}
  ]
  @refresh_budget_source_field_pairs Enum.map(
                                       [
                                         "model",
                                         "input_candidate_count",
                                         "kept_candidate_count",
                                         "dropped_candidate_count",
                                         "max_candidate_activities",
                                         "invalid_candidate_limit_policy",
                                         "invalid_candidate_limit_policy_reason",
                                         "source_candidate_limit_policy",
                                         "selection_order",
                                         "kept_candidate_ids",
                                         "dropped_candidate_ids"
                                       ],
                                       &{&1, &1}
                                     )
  @refresh_budget_fields [
    {"id", "source_review_row_id"},
    {"review_type", "source_review_type"},
    {"action", "source_review_action"},
    {"source", "source"},
    {"subject_id", "subject_id"},
    {"branch_id", "branch_id"},
    {"reason", "reason"},
    {"approval_status", "approval_status"},
    {"required_operator_action", "required_operator_action"},
    {"model", "model"},
    {"input_candidate_count", "input_candidate_count"},
    {"kept_candidate_count", "kept_candidate_count"},
    {"dropped_candidate_count", "dropped_candidate_count"},
    {"max_candidate_activities", "max_candidate_activities"},
    {"invalid_candidate_limit_policy", "invalid_candidate_limit_policy"},
    {"invalid_candidate_limit_policy_reason", "invalid_candidate_limit_policy_reason"},
    {"source_candidate_limit_policy", "source_candidate_limit_policy"},
    {"selection_order", "selection_order"},
    {"kept_candidate_ids", "kept_candidate_ids"},
    {"dropped_candidate_ids", "dropped_candidate_ids"},
    {"source_refresh_budget_report", "source_refresh_budget_report"}
  ]
  @schema_validation_fields [
    {"id", "source_review_row_id"},
    {"review_type", "source_review_type"},
    {"action", "source_review_action"},
    {"source", "source"},
    {"subject_id", "subject_id"},
    {"approval_status", "approval_status"},
    {"required_operator_action", "required_operator_action"},
    {"reason", "reason"},
    {"validation_status", "validation_status"},
    {"validation_status", "schema_validation_gate_status"},
    {"validation_mode", "validation_mode"},
    {"validated_contract", "validated_contract"},
    {"validated_artifact_family", "validated_artifact_family"},
    {"artifact_path", "artifact_path"},
    {"issue_severity", "issue_severity"},
    {"issue_path", "issue_path"},
    {"issue_message", "issue_message"},
    {"error_count", "error_count"},
    {"warning_count", "warning_count"},
    {"remediation_count", "remediation_count"},
    {"remediation_category", "remediation_category"},
    {"remediation_action", "remediation_action"},
    {"source_validation_issue", "source_validation_issue"},
    {"source_validation_remediation", "source_validation_remediation"},
    {"source_schema_validation_report", "source_schema_validation_report"}
  ]
  @execution_fields [
    {"id", "source_review_row_id"},
    {"review_type", "source_review_type"},
    {"action", "source_review_action"},
    {"source", "source"},
    {"subject_id", "subject_id"},
    {"scenario_id", "scenario_id"},
    {"scenario_index", "scenario_index"},
    {"approval_status", "approval_status"},
    {"required_operator_action", "required_operator_action"},
    {"reason", "reason"},
    {"execution_status", "execution_status"},
    {"execution_mode", "execution_mode"},
    {"execution_stage", "execution_stage"},
    {"execution_error", "execution_error"},
    {"resumability", "resumability"},
    {"retry_recommendation", "retry_recommendation"},
    {"study_id", "study_id"},
    {"run_id", "run_id"},
    {"failed_scenario_count", "failed_scenario_count"},
    {"completed_scenario_count", "completed_scenario_count"},
    {"scenario_count", "scenario_count"},
    {"source_execution_failure", "source_execution_failure"},
    {"source_execution_report", "source_execution_report"}
  ]
  @quality_gate_fields [
    {"id", "source_review_row_id"},
    {"review_type", "source_review_type"},
    {"action", "source_review_action"},
    {"source", "source"},
    {"subject_id", "subject_id"},
    {"reason", "reason"},
    {"approval_status", "approval_status"},
    {"required_operator_action", "required_operator_action"},
    {"source_artifact_type", "source_artifact_type"},
    {"source_artifact_id", "source_artifact_id"},
    {"readiness_level", "readiness_level"},
    {"import_classification", "import_classification"},
    {"quality_gate_report_id", "quality_gate_report_id"},
    {"quality_gate_id", "quality_gate_id"},
    {"quality_gate_status", "quality_gate_status"},
    {"quality_gate_classification", "quality_gate_classification"},
    {"quality_gate_reason", "quality_gate_reason"},
    {"readiness_gate_id", "readiness_gate_id"},
    {"readiness_gate_status", "readiness_gate_status"},
    {"readiness_gate_classification", "readiness_gate_classification"},
    {"readiness_gate_reason", "readiness_gate_reason"},
    {"analysis_mode", "analysis_mode"},
    {"analysis_mode_source", "analysis_mode_source"},
    {"resource_availability_pressure_count", "resource_availability_pressure_count"},
    {"resource_availability_reason_counts", "resource_availability_reason_counts"},
    {"resource_availability_reason_ids", "resource_availability_reason_ids"},
    {"station_availability_reason_ids", "station_availability_reason_ids"},
    {"station_availability_reason_counts", "station_availability_reason_counts"},
    {"unavailable_resource_reason_ids", "unavailable_resource_reason_ids"},
    {"source_quality_gate_row", "source_quality_gate_row"},
    {"source_quality_gate_report", "source_quality_gate_report"}
  ]
  @operational_readiness_fields [
    {"id", "source_review_row_id"},
    {"review_type", "source_review_type"},
    {"action", "source_review_action"},
    {"source", "source"},
    {"subject_id", "subject_id"},
    {"reason", "reason"},
    {"approval_status", "approval_status"},
    {"required_operator_action", "required_operator_action"},
    {"source_artifact_type", "source_artifact_type"},
    {"source_artifact_id", "source_artifact_id"},
    {"readiness_level", "readiness_level"},
    {"import_classification", "import_classification"},
    {"operational_readiness_status", "operational_readiness_status"},
    {"readiness_gate_id", "readiness_gate_id"},
    {"readiness_gate_status", "readiness_gate_status"},
    {"readiness_gate_classification", "readiness_gate_classification"},
    {"readiness_gate_reason", "readiness_gate_reason"},
    {"analysis_mode", "analysis_mode"},
    {"analysis_mode_source", "analysis_mode_source"},
    {"gate_count", "gate_count"},
    {"passed_gate_count", "passed_gate_count"},
    {"review_gate_count", "review_gate_count"},
    {"analysis_gate_count", "analysis_gate_count"},
    {"blocked_gate_count", "blocked_gate_count"},
    {"adapter_context_count", "adapter_context_count"},
    {"adapter_trust_boundary_declared_count", "adapter_trust_boundary_declared_count"},
    {"adapter_trust_boundary_missing_count", "adapter_trust_boundary_missing_count"},
    {"adapter_trust_boundary_untrusted_count", "adapter_trust_boundary_untrusted_count"},
    {"adapter_boundary_status_counts", "adapter_boundary_status_counts"},
    {"resource_availability_pressure_count", "resource_availability_pressure_count"},
    {"resource_availability_reason_counts", "resource_availability_reason_counts"},
    {"resource_availability_reason_ids", "resource_availability_reason_ids"},
    {"station_availability_reason_ids", "station_availability_reason_ids"},
    {"station_availability_reason_counts", "station_availability_reason_counts"},
    {"unavailable_resource_reason_ids", "unavailable_resource_reason_ids"},
    {"resource_blocking_dimension_counts", "resource_blocking_dimension_counts"},
    {"resource_source_quality_counts", "resource_source_quality_counts"},
    {"resource_trust_boundary_status_counts", "resource_trust_boundary_status_counts"},
    {"operator_training_requirement_count", "operator_training_requirement_count"},
    {"operator_training_requirement_counts", "operator_training_requirement_counts"},
    {"required_operator_roles", "required_operator_roles"},
    {"required_training_ids", "required_training_ids"},
    {"required_certification_ids", "required_certification_ids"},
    {"required_qualification_ids", "required_qualification_ids"},
    {"ready_for_import_count", "ready_for_import_count"},
    {"manifest_review_required_count", "manifest_review_required_count"},
    {"blocked_import_count", "blocked_import_count"},
    {"missing_import_count", "missing_import_count"},
    {"invalid_cadence_import_count", "invalid_cadence_import_count"},
    {"current_freshness_count", "current_freshness_count"},
    {"stale_freshness_count", "stale_freshness_count"},
    {"unknown_freshness_count", "unknown_freshness_count"},
    {"freshness_status_counts", "freshness_status_counts"},
    {"schema_validation_pass_count", "schema_validation_pass_count"},
    {"schema_validation_fail_count", "schema_validation_fail_count"},
    {"schema_validation_error_count", "schema_validation_error_count"},
    {"schema_validation_warning_count", "schema_validation_warning_count"},
    {"schema_validation_remediation_count", "schema_validation_remediation_count"},
    {"schema_validation_status_counts", "schema_validation_status_counts"},
    {"import_status_counts", "import_status_counts"},
    {"cadence_import_status_counts", "cadence_import_status_counts"},
    {"gates", "gates"},
    {"evidence", "evidence"},
    {"source_operational_readiness_gate", "source_operational_readiness_gate"},
    {"source_operational_readiness_report", "source_operational_readiness_report"}
  ]

  def validate_policy_escalation_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if policy_escalation_handoff_row?(row) do
      validate_cadence_source_review_pairs(
        issues,
        path,
        row,
        source_review_row,
        @policy_escalation_fields
      )
    else
      issues
    end
  end

  def validate_policy_escalation_matches(issues, _path, _row), do: issues

  def validate_freshness_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if freshness_handoff_row?(row) do
      validate_cadence_source_review_pairs(
        issues,
        path,
        row,
        source_review_row,
        @freshness_fields
      )
    else
      issues
    end
  end

  def validate_freshness_matches(issues, _path, _row), do: issues

  def validate_warning_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if warning_handoff_row?(row) do
      validate_cadence_source_review_pairs(issues, path, row, source_review_row, @warning_fields)
    else
      issues
    end
  end

  def validate_warning_matches(issues, _path, _row), do: issues

  def validate_timeline_protection_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if timeline_protection_handoff_row?(row) do
      validate_cadence_source_review_pairs(
        issues,
        path,
        row,
        source_review_row,
        @timeline_protection_fields
      )
    else
      issues
    end
  end

  def validate_timeline_protection_matches(issues, _path, _row), do: issues

  def validate_refresh_budget_matches_source(
        issues,
        path,
        %{"source_refresh_budget_report" => %{} = source_report} = row
      ) do
    if refresh_budget_handoff_row?(row) do
      validate_source_pairs(
        issues,
        path,
        row,
        source_report,
        @refresh_budget_source_field_pairs,
        "source_refresh_budget_report"
      )
    else
      issues
    end
  end

  def validate_refresh_budget_matches_source(issues, _path, _row), do: issues

  def validate_refresh_budget_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if refresh_budget_handoff_row?(row) do
      validate_cadence_source_review_pairs(
        issues,
        path,
        row,
        source_review_row,
        @refresh_budget_fields
      )
    else
      issues
    end
  end

  def validate_refresh_budget_matches(issues, _path, _row), do: issues

  def validate_schema_validation_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if schema_validation_handoff_row?(row) do
      validate_cadence_source_review_pairs(
        issues,
        path,
        row,
        source_review_row,
        @schema_validation_fields
      )
    else
      issues
    end
  end

  def validate_schema_validation_matches(issues, _path, _row), do: issues

  def validate_execution_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if execution_handoff_row?(row) do
      validate_cadence_source_review_pairs(
        issues,
        path,
        row,
        source_review_row,
        @execution_fields
      )
    else
      issues
    end
  end

  def validate_execution_matches(issues, _path, _row), do: issues

  def validate_quality_gate_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if quality_gate_handoff_row?(row) do
      validate_cadence_source_review_pairs(
        issues,
        path,
        row,
        source_review_row,
        @quality_gate_fields
      )
    else
      issues
    end
  end

  def validate_quality_gate_matches(issues, _path, _row), do: issues

  def validate_operational_readiness_matches(
        issues,
        path,
        %{"source_review_row" => %{} = source_review_row} = row
      ) do
    if operational_readiness_handoff_row?(row) do
      validate_cadence_source_review_pairs(
        issues,
        path,
        row,
        source_review_row,
        @operational_readiness_fields
      )
    else
      issues
    end
  end

  def validate_operational_readiness_matches(issues, _path, _row), do: issues

  def policy_escalation_handoff_row?(row) do
    Map.get(row, "review_type") == "policy_escalation" or
      Map.get(row, "source_review_type") == "policy_escalation" or
      Map.get(row, "import_action") == "review_policy_escalation"
  end

  def freshness_handoff_row?(row) do
    Map.get(row, "review_type") == "freshness_review" or
      Map.get(row, "source_review_type") == "freshness_review" or
      Map.get(row, "import_action") == "review_refresh_freshness"
  end

  def warning_handoff_row?(row) do
    Map.get(row, "review_type") == "warning" or
      Map.get(row, "source_review_type") == "warning" or
      Map.get(row, "import_action") == "review_warning"
  end

  def timeline_protection_handoff_row?(row) do
    Map.get(row, "review_type") == "timeline_protection" or
      Map.get(row, "source_review_type") == "timeline_protection" or
      Map.get(row, "import_action") == "review_timeline_protection"
  end

  def refresh_budget_handoff_row?(row) do
    Map.get(row, "review_type") == "refresh_budget_review" or
      Map.get(row, "source_review_type") == "refresh_budget_review" or
      Map.get(row, "import_action") == "review_refresh_budget"
  end

  def schema_validation_handoff_row?(row) do
    Map.get(row, "review_type") == "schema_validation_review" or
      Map.get(row, "source_review_type") == "schema_validation_review" or
      Map.get(row, "import_action") == "review_schema_validation"
  end

  def execution_handoff_row?(row) do
    Map.get(row, "review_type") == "execution_review" or
      Map.get(row, "source_review_type") == "execution_review" or
      Map.get(row, "import_action") == "review_execution"
  end

  def quality_gate_handoff_row?(row) do
    Map.get(row, "review_type") == "quality_gate_review" or
      Map.get(row, "source_review_type") == "quality_gate_review" or
      Map.get(row, "import_action") == "review_quality_gate"
  end

  def operational_readiness_handoff_row?(row) do
    Map.get(row, "review_type") == "operational_readiness_review" or
      Map.get(row, "source_review_type") == "operational_readiness_review" or
      Map.get(row, "import_action") == "review_operational_readiness"
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

  defp error(path, message) do
    %{"severity" => "error", "path" => path, "message" => message}
  end
end
