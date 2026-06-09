defmodule OrbitalDynamics.RecommendationRiskContext do
  @moduledoc false

  @validation_refresh_context_keys [
    "model_acceptance_report_ids",
    "model_acceptance_intended_uses",
    "model_acceptance_statuses",
    "model_acceptance_model_ids",
    "model_acceptance_model_statuses",
    "model_acceptance_validation_levels",
    "model_acceptance_model_reasons",
    "model_acceptance_status_count_maps",
    "model_acceptance_validation_level_count_maps",
    "model_acceptance_model_ids_by_status",
    "model_acceptance_model_ids_by_validation_level",
    "model_acceptance_model_ids_by_intended_use",
    "model_acceptance_required_operator_actions",
    "model_acceptance_feedback_sources",
    "model_acceptance_feedback_scopes",
    "model_acceptance_feedback_keys",
    "model_acceptance_trust_boundaries",
    "schema_validation_statuses",
    "schema_validation_modes",
    "schema_validation_validated_contracts",
    "schema_validation_artifact_families",
    "schema_validation_artifact_paths",
    "schema_validation_issue_severities",
    "schema_validation_issue_paths",
    "schema_validation_error_count_values",
    "schema_validation_warning_count_values",
    "schema_validation_remediation_count_values",
    "schema_validation_remediation_categories",
    "schema_validation_remediation_actions",
    "schema_validation_required_operator_actions",
    "schema_validation_feedback_sources",
    "schema_validation_feedback_scopes",
    "schema_validation_feedback_keys",
    "schema_validation_trust_boundaries",
    "validation_safety_case_report_ids",
    "validation_safety_case_statuses",
    "validation_safety_case_evidence_statuses",
    "validation_safety_case_input_contracts",
    "validation_safety_case_evidence_refs",
    "validation_safety_case_evidence_count_values",
    "validation_safety_case_accepted_evidence_count_values",
    "validation_safety_case_review_required_evidence_count_values",
    "validation_safety_case_blocked_evidence_count_values",
    "validation_safety_case_model_blocked_count_values",
    "validation_safety_case_quality_gate_review_count_values",
    "validation_safety_case_quality_gate_blocked_count_values",
    "validation_safety_case_schema_error_count_values",
    "validation_safety_case_schema_warning_count_values",
    "validation_safety_case_evidence_status_count_maps",
    "validation_safety_case_evidence_refs_by_status",
    "validation_safety_case_evidence_refs_by_contract",
    "validation_safety_case_required_operator_actions",
    "validation_safety_case_feedback_sources",
    "validation_safety_case_feedback_scopes",
    "validation_safety_case_feedback_keys",
    "validation_safety_case_trust_boundaries",
    "refresh_budget_statuses",
    "refresh_budget_candidate_limit_statuses",
    "refresh_budget_input_candidate_count_values",
    "refresh_budget_kept_candidate_count_values",
    "refresh_budget_dropped_candidate_count_values",
    "refresh_budget_invalid_limit_count_values",
    "refresh_budget_current_max_candidate_activity_values",
    "refresh_budget_relaxed_max_candidate_activity_values",
    "refresh_budget_required_operator_actions",
    "refresh_budget_feedback_sources",
    "refresh_budget_feedback_scopes",
    "refresh_budget_feedback_keys",
    "refresh_budget_trust_boundaries",
    "refresh_freshness_statuses",
    "refresh_freshness_state_quality_statuses",
    "refresh_freshness_accepted_snapshot_age_values_s",
    "refresh_freshness_horizon_start_offset_values_s",
    "refresh_freshness_max_snapshot_age_values_s",
    "refresh_freshness_max_horizon_start_offset_values_s",
    "refresh_freshness_stale_reason_ids",
    "refresh_freshness_unknown_reason_ids",
    "refresh_freshness_required_operator_actions",
    "refresh_freshness_feedback_sources",
    "refresh_freshness_feedback_scopes",
    "refresh_freshness_feedback_keys",
    "refresh_freshness_trust_boundaries"
  ]

  def validation_refresh_context_keys, do: @validation_refresh_context_keys

  def validation_refresh_context(risks) when is_list(risks) do
    risks = Enum.map(risks, &stringify_keys/1)

    model_acceptance_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "feedback_scope") == "model_acceptance" or
            Map.get(&1, "type") == "model_acceptance_pressure")
      )

    schema_validation_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "feedback_scope") == "schema_validation" or
            Map.get(&1, "type") == "schema_validation_pressure")
      )

    validation_safety_case_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "feedback_scope") == "validation_safety_case" or
            Map.get(&1, "type") == "validation_safety_case_pressure")
      )

    refresh_budget_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "feedback_scope") == "refresh_budget" or
            Map.get(&1, "type") == "refresh_budget_pressure")
      )

    refresh_freshness_risks =
      Enum.filter(
        risks,
        &(Map.get(&1, "feedback_scope") == "refresh_freshness" or
            Map.get(&1, "type") == "refresh_freshness_pressure")
      )

    %{
      "model_acceptance_report_ids" => risk_context_values(model_acceptance_risks, "report_id"),
      "model_acceptance_intended_uses" =>
        risk_context_values(model_acceptance_risks, "intended_use"),
      "model_acceptance_statuses" =>
        risk_context_values(model_acceptance_risks, "model_acceptance_status"),
      "model_acceptance_model_ids" => risk_context_values(model_acceptance_risks, "model_id"),
      "model_acceptance_model_statuses" =>
        risk_context_values(model_acceptance_risks, "model_status"),
      "model_acceptance_validation_levels" =>
        risk_context_values(model_acceptance_risks, "validation_level"),
      "model_acceptance_model_reasons" =>
        risk_context_values(model_acceptance_risks, "model_reason"),
      "model_acceptance_status_count_maps" =>
        risk_context_values(model_acceptance_risks, "status_counts"),
      "model_acceptance_validation_level_count_maps" =>
        risk_context_values(model_acceptance_risks, "validation_level_counts"),
      "model_acceptance_model_ids_by_status" =>
        risk_context_values(model_acceptance_risks, "model_ids_by_status"),
      "model_acceptance_model_ids_by_validation_level" =>
        risk_context_values(model_acceptance_risks, "model_ids_by_validation_level"),
      "model_acceptance_model_ids_by_intended_use" =>
        risk_context_values(model_acceptance_risks, "model_ids_by_intended_use"),
      "model_acceptance_required_operator_actions" =>
        risk_context_values(model_acceptance_risks, "required_operator_action"),
      "model_acceptance_feedback_sources" =>
        risk_context_values(model_acceptance_risks, "feedback_source"),
      "model_acceptance_feedback_scopes" =>
        risk_context_values(model_acceptance_risks, "feedback_scope"),
      "model_acceptance_feedback_keys" =>
        risk_context_values(model_acceptance_risks, "feedback_key"),
      "model_acceptance_trust_boundaries" =>
        risk_context_values(model_acceptance_risks, "trust_boundary"),
      "schema_validation_statuses" =>
        risk_context_values(schema_validation_risks, "validation_status"),
      "schema_validation_modes" =>
        risk_context_values(schema_validation_risks, "validation_mode"),
      "schema_validation_validated_contracts" =>
        risk_context_values(schema_validation_risks, "validated_contract"),
      "schema_validation_artifact_families" =>
        risk_context_values(schema_validation_risks, "validated_artifact_family"),
      "schema_validation_artifact_paths" =>
        risk_context_values(schema_validation_risks, "artifact_path"),
      "schema_validation_issue_severities" =>
        risk_context_values(schema_validation_risks, "issue_severity"),
      "schema_validation_issue_paths" =>
        risk_context_values(schema_validation_risks, "issue_path"),
      "schema_validation_error_count_values" =>
        risk_context_values(schema_validation_risks, "error_count"),
      "schema_validation_warning_count_values" =>
        risk_context_values(schema_validation_risks, "warning_count"),
      "schema_validation_remediation_count_values" =>
        risk_context_values(schema_validation_risks, "remediation_count"),
      "schema_validation_remediation_categories" =>
        risk_context_values(schema_validation_risks, "remediation_category"),
      "schema_validation_remediation_actions" =>
        risk_context_values(schema_validation_risks, "remediation_action"),
      "schema_validation_required_operator_actions" =>
        risk_context_values(schema_validation_risks, "required_operator_action"),
      "schema_validation_feedback_sources" =>
        risk_context_values(schema_validation_risks, "feedback_source"),
      "schema_validation_feedback_scopes" =>
        risk_context_values(schema_validation_risks, "feedback_scope"),
      "schema_validation_feedback_keys" =>
        risk_context_values(schema_validation_risks, "feedback_key"),
      "schema_validation_trust_boundaries" =>
        risk_context_values(schema_validation_risks, "trust_boundary"),
      "validation_safety_case_report_ids" =>
        risk_context_values(validation_safety_case_risks, "report_id"),
      "validation_safety_case_statuses" =>
        risk_context_values(validation_safety_case_risks, "validation_safety_case_status"),
      "validation_safety_case_evidence_statuses" =>
        risk_context_values(validation_safety_case_risks, "evidence_status"),
      "validation_safety_case_input_contracts" =>
        risk_context_values(validation_safety_case_risks, ["input_contract", "input_contracts"]),
      "validation_safety_case_evidence_refs" =>
        risk_context_values(validation_safety_case_risks, "evidence_ref"),
      "validation_safety_case_evidence_count_values" =>
        risk_context_values(validation_safety_case_risks, "evidence_count"),
      "validation_safety_case_accepted_evidence_count_values" =>
        risk_context_values(validation_safety_case_risks, "accepted_evidence_count"),
      "validation_safety_case_review_required_evidence_count_values" =>
        risk_context_values(validation_safety_case_risks, "review_required_evidence_count"),
      "validation_safety_case_blocked_evidence_count_values" =>
        risk_context_values(validation_safety_case_risks, "blocked_evidence_count"),
      "validation_safety_case_model_blocked_count_values" =>
        risk_context_values(validation_safety_case_risks, "model_blocked_count"),
      "validation_safety_case_quality_gate_review_count_values" =>
        risk_context_values(validation_safety_case_risks, "quality_gate_review_count"),
      "validation_safety_case_quality_gate_blocked_count_values" =>
        risk_context_values(validation_safety_case_risks, "quality_gate_blocked_count"),
      "validation_safety_case_schema_error_count_values" =>
        risk_context_values(validation_safety_case_risks, "schema_error_count"),
      "validation_safety_case_schema_warning_count_values" =>
        risk_context_values(validation_safety_case_risks, "schema_warning_count"),
      "validation_safety_case_evidence_status_count_maps" =>
        risk_context_values(validation_safety_case_risks, "evidence_status_counts"),
      "validation_safety_case_evidence_refs_by_status" =>
        risk_context_values(validation_safety_case_risks, "evidence_refs_by_status"),
      "validation_safety_case_evidence_refs_by_contract" =>
        risk_context_values(validation_safety_case_risks, "evidence_refs_by_contract"),
      "validation_safety_case_required_operator_actions" =>
        risk_context_values(validation_safety_case_risks, "required_operator_action"),
      "validation_safety_case_feedback_sources" =>
        risk_context_values(validation_safety_case_risks, "feedback_source"),
      "validation_safety_case_feedback_scopes" =>
        risk_context_values(validation_safety_case_risks, "feedback_scope"),
      "validation_safety_case_feedback_keys" =>
        risk_context_values(validation_safety_case_risks, "feedback_key"),
      "validation_safety_case_trust_boundaries" =>
        risk_context_values(validation_safety_case_risks, "trust_boundary"),
      "refresh_budget_statuses" =>
        risk_context_values(refresh_budget_risks, "refresh_budget_status"),
      "refresh_budget_candidate_limit_statuses" =>
        risk_context_values(refresh_budget_risks, "candidate_limit_status"),
      "refresh_budget_input_candidate_count_values" =>
        risk_context_values(refresh_budget_risks, "input_candidate_count"),
      "refresh_budget_kept_candidate_count_values" =>
        risk_context_values(refresh_budget_risks, "kept_candidate_count"),
      "refresh_budget_dropped_candidate_count_values" =>
        risk_context_values(refresh_budget_risks, "dropped_candidate_count"),
      "refresh_budget_invalid_limit_count_values" =>
        risk_context_values(refresh_budget_risks, "invalid_limit_count"),
      "refresh_budget_current_max_candidate_activity_values" =>
        risk_context_values(refresh_budget_risks, "current_max_candidate_activities"),
      "refresh_budget_relaxed_max_candidate_activity_values" =>
        risk_context_values(refresh_budget_risks, "relaxed_max_candidate_activities"),
      "refresh_budget_required_operator_actions" =>
        risk_context_values(refresh_budget_risks, "required_operator_action"),
      "refresh_budget_feedback_sources" =>
        risk_context_values(refresh_budget_risks, "feedback_source"),
      "refresh_budget_feedback_scopes" =>
        risk_context_values(refresh_budget_risks, "feedback_scope"),
      "refresh_budget_feedback_keys" => risk_context_values(refresh_budget_risks, "feedback_key"),
      "refresh_budget_trust_boundaries" =>
        risk_context_values(refresh_budget_risks, "trust_boundary"),
      "refresh_freshness_statuses" =>
        risk_context_values(refresh_freshness_risks, "freshness_status"),
      "refresh_freshness_state_quality_statuses" =>
        risk_context_values(refresh_freshness_risks, "state_quality_status"),
      "refresh_freshness_accepted_snapshot_age_values_s" =>
        risk_context_values(refresh_freshness_risks, "accepted_snapshot_age_s"),
      "refresh_freshness_horizon_start_offset_values_s" =>
        risk_context_values(refresh_freshness_risks, "horizon_start_offset_s"),
      "refresh_freshness_max_snapshot_age_values_s" =>
        risk_context_values(refresh_freshness_risks, "max_snapshot_age_s"),
      "refresh_freshness_max_horizon_start_offset_values_s" =>
        risk_context_values(refresh_freshness_risks, "max_horizon_start_offset_s"),
      "refresh_freshness_stale_reason_ids" =>
        risk_context_values(refresh_freshness_risks, ["stale_reasons"]),
      "refresh_freshness_unknown_reason_ids" =>
        risk_context_values(refresh_freshness_risks, ["unknown_reasons"]),
      "refresh_freshness_required_operator_actions" =>
        risk_context_values(refresh_freshness_risks, "required_operator_action"),
      "refresh_freshness_feedback_sources" =>
        risk_context_values(refresh_freshness_risks, "feedback_source"),
      "refresh_freshness_feedback_scopes" =>
        risk_context_values(refresh_freshness_risks, "feedback_scope"),
      "refresh_freshness_feedback_keys" =>
        risk_context_values(refresh_freshness_risks, "feedback_key"),
      "refresh_freshness_trust_boundaries" =>
        risk_context_values(refresh_freshness_risks, "trust_boundary")
    }
    |> Enum.reject(fn {_key, values} -> values == [] end)
    |> Map.new()
  end

  def validation_refresh_context(_risks), do: %{}

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
