defmodule OrbitalDynamics.RecommendationRiskContext.ValidationRefresh do
  @moduledoc false

  @model_acceptance_fields [
    {"model_acceptance_report_ids", "report_id"},
    {"model_acceptance_intended_uses", "intended_use"},
    {"model_acceptance_statuses", "model_acceptance_status"},
    {"model_acceptance_model_ids", "model_id"},
    {"model_acceptance_model_statuses", "model_status"},
    {"model_acceptance_validation_levels", "validation_level"},
    {"model_acceptance_model_reasons", "model_reason"},
    {"model_acceptance_status_count_maps", "status_counts"},
    {"model_acceptance_validation_level_count_maps", "validation_level_counts"},
    {"model_acceptance_model_ids_by_status", "model_ids_by_status"},
    {"model_acceptance_model_ids_by_validation_level", "model_ids_by_validation_level"},
    {"model_acceptance_model_ids_by_intended_use", "model_ids_by_intended_use"},
    {"model_acceptance_required_operator_actions", "required_operator_action"},
    {"model_acceptance_feedback_sources", "feedback_source"},
    {"model_acceptance_feedback_scopes", "feedback_scope"},
    {"model_acceptance_feedback_keys", "feedback_key"},
    {"model_acceptance_trust_boundaries", "trust_boundary"}
  ]

  @schema_validation_fields [
    {"schema_validation_statuses", "validation_status"},
    {"schema_validation_modes", "validation_mode"},
    {"schema_validation_validated_contracts", "validated_contract"},
    {"schema_validation_artifact_families", "validated_artifact_family"},
    {"schema_validation_artifact_paths", "artifact_path"},
    {"schema_validation_issue_severities", "issue_severity"},
    {"schema_validation_issue_paths", "issue_path"},
    {"schema_validation_error_count_values", "error_count"},
    {"schema_validation_warning_count_values", "warning_count"},
    {"schema_validation_remediation_count_values", "remediation_count"},
    {"schema_validation_remediation_categories", "remediation_category"},
    {"schema_validation_remediation_actions", "remediation_action"},
    {"schema_validation_required_operator_actions", "required_operator_action"},
    {"schema_validation_feedback_sources", "feedback_source"},
    {"schema_validation_feedback_scopes", "feedback_scope"},
    {"schema_validation_feedback_keys", "feedback_key"},
    {"schema_validation_trust_boundaries", "trust_boundary"}
  ]

  @validation_safety_case_fields [
    {"validation_safety_case_report_ids", "report_id"},
    {"validation_safety_case_statuses", "validation_safety_case_status"},
    {"validation_safety_case_evidence_statuses", "evidence_status"},
    {"validation_safety_case_input_contracts", ["input_contract", "input_contracts"]},
    {"validation_safety_case_evidence_refs", "evidence_ref"},
    {"validation_safety_case_evidence_count_values", "evidence_count"},
    {"validation_safety_case_accepted_evidence_count_values", "accepted_evidence_count"},
    {"validation_safety_case_review_required_evidence_count_values",
     "review_required_evidence_count"},
    {"validation_safety_case_blocked_evidence_count_values", "blocked_evidence_count"},
    {"validation_safety_case_model_blocked_count_values", "model_blocked_count"},
    {"validation_safety_case_quality_gate_review_count_values", "quality_gate_review_count"},
    {"validation_safety_case_quality_gate_blocked_count_values", "quality_gate_blocked_count"},
    {"validation_safety_case_schema_error_count_values", "schema_error_count"},
    {"validation_safety_case_schema_warning_count_values", "schema_warning_count"},
    {"validation_safety_case_evidence_status_count_maps", "evidence_status_counts"},
    {"validation_safety_case_evidence_refs_by_status", "evidence_refs_by_status"},
    {"validation_safety_case_evidence_refs_by_contract", "evidence_refs_by_contract"},
    {"validation_safety_case_required_operator_actions", "required_operator_action"},
    {"validation_safety_case_feedback_sources", "feedback_source"},
    {"validation_safety_case_feedback_scopes", "feedback_scope"},
    {"validation_safety_case_feedback_keys", "feedback_key"},
    {"validation_safety_case_trust_boundaries", "trust_boundary"}
  ]

  @refresh_budget_fields [
    {"refresh_budget_statuses", "refresh_budget_status"},
    {"refresh_budget_candidate_limit_statuses", "candidate_limit_status"},
    {"refresh_budget_input_candidate_count_values", "input_candidate_count"},
    {"refresh_budget_kept_candidate_count_values", "kept_candidate_count"},
    {"refresh_budget_dropped_candidate_count_values", "dropped_candidate_count"},
    {"refresh_budget_invalid_limit_count_values", "invalid_limit_count"},
    {"refresh_budget_current_max_candidate_activity_values", "current_max_candidate_activities"},
    {"refresh_budget_relaxed_max_candidate_activity_values", "relaxed_max_candidate_activities"},
    {"refresh_budget_required_operator_actions", "required_operator_action"},
    {"refresh_budget_feedback_sources", "feedback_source"},
    {"refresh_budget_feedback_scopes", "feedback_scope"},
    {"refresh_budget_feedback_keys", "feedback_key"},
    {"refresh_budget_trust_boundaries", "trust_boundary"}
  ]

  @refresh_freshness_fields [
    {"refresh_freshness_statuses", "freshness_status"},
    {"refresh_freshness_state_quality_statuses", "state_quality_status"},
    {"refresh_freshness_accepted_snapshot_age_values_s", "accepted_snapshot_age_s"},
    {"refresh_freshness_horizon_start_offset_values_s", "horizon_start_offset_s"},
    {"refresh_freshness_max_snapshot_age_values_s", "max_snapshot_age_s"},
    {"refresh_freshness_max_horizon_start_offset_values_s", "max_horizon_start_offset_s"},
    {"refresh_freshness_stale_reason_ids", ["stale_reasons"]},
    {"refresh_freshness_unknown_reason_ids", ["unknown_reasons"]},
    {"refresh_freshness_required_operator_actions", "required_operator_action"},
    {"refresh_freshness_feedback_sources", "feedback_source"},
    {"refresh_freshness_feedback_scopes", "feedback_scope"},
    {"refresh_freshness_feedback_keys", "feedback_key"},
    {"refresh_freshness_trust_boundaries", "trust_boundary"}
  ]

  @field_groups [
    {"model_acceptance", "model_acceptance_pressure", @model_acceptance_fields},
    {"schema_validation", "schema_validation_pressure", @schema_validation_fields},
    {"validation_safety_case", "validation_safety_case_pressure", @validation_safety_case_fields},
    {"refresh_budget", "refresh_budget_pressure", @refresh_budget_fields},
    {"refresh_freshness", "refresh_freshness_pressure", @refresh_freshness_fields}
  ]
  @context_fields Enum.flat_map(@field_groups, fn {_feedback_scope, _type, fields} -> fields end)
  @field_specs Enum.flat_map(@field_groups, fn {feedback_scope, _type, fields} ->
                 Enum.map(fields, fn {context_key, risk_keys} ->
                   {context_key, risk_keys, feedback_scope}
                 end)
               end)

  def field_pairs, do: @context_fields
  def field_specs, do: @field_specs
  def context_keys, do: Enum.map(@context_fields, &elem(&1, 0))

  def context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    @field_groups
    |> Enum.flat_map(fn {feedback_scope, type, fields} ->
      matching = matching_risks(risks, feedback_scope, type)

      Enum.map(fields, fn {context_key, risk_keys} ->
        {context_key, risk_context_values(matching, risk_keys)}
      end)
    end)
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def context(_risks), do: %{}

  defp matching_risks(risks, feedback_scope, type) do
    Enum.filter(
      risks,
      &(Map.get(&1, "feedback_scope") == feedback_scope or Map.get(&1, "type") == type)
    )
  end

  defp risk_context_values(risks, keys) when is_list(keys) do
    risks
    |> Enum.flat_map(fn risk ->
      Enum.flat_map(keys, fn key ->
        risk
        |> Map.get(key)
        |> List.wrap()
      end)
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp risk_context_values(risks, key) do
    risks
    |> Enum.map(&Map.get(&1, key))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), value}
      {key, value} -> {key, value}
    end)
  end

  defp stringify_keys(value), do: value
end
