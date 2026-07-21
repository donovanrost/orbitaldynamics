defmodule OrbitalDynamics.Policy.BlockedRiskMatcher do
  @moduledoc false

  def blocked?(risk, blocked_risk_types) do
    Enum.any?(blocked_risk_types, &risk_matches_blocked_type?(risk, &1))
  end

  defp risk_matches_blocked_type?(%{"type" => type}, blocked_type) when type == blocked_type,
    do: true

  defp risk_matches_blocked_type?(
         %{"type" => "operational_readiness_pressure"} = risk,
         "operational_readiness_blocked"
       ) do
    blocked_value?(risk["operational_readiness_status"]) or
      blocked_value?(risk["readiness_gate_status"]) or
      blocked_value?(risk["import_classification"]) or
      blocked_value?(risk["readiness_gate_classification"]) or
      positive_count?(risk["blocked_gate_count"]) or
      risk["required_operator_action"] == "review_blocked_operational_readiness"
  end

  defp risk_matches_blocked_type?(
         %{"type" => "quality_gate_pressure"} = risk,
         "quality_gate_blocked"
       ) do
    blocked_value?(risk["quality_gate_status"]) or
      blocked_value?(risk["gate_status"]) or
      blocked_value?(risk["import_classification"]) or
      blocked_value?(risk["gate_classification"]) or
      positive_count?(risk["blocked_gate_count"]) or
      risk["required_operator_action"] == "review_blocked_operational_readiness"
  end

  defp risk_matches_blocked_type?(
         %{"type" => "operational_readiness_pressure"} = risk,
         "import_readiness_blocked"
       ) do
    blocked_import_readiness_pressure?(risk)
  end

  defp risk_matches_blocked_type?(
         %{"type" => "quality_gate_pressure"} = risk,
         "import_readiness_blocked"
       ) do
    blocked_import_readiness_pressure?(risk)
  end

  defp risk_matches_blocked_type?(
         %{"type" => "downlink_completion_gap", "feedback_scope" => "contact_intent"} = risk,
         "contact_intent_blocked"
       ) do
    blocked_value?(risk["contact_intent_gate_status"]) or
      blocked_value?(risk["policy_classification"]) or
      blocked_value?(risk["approval_status"])
  end

  defp risk_matches_blocked_type?(
         %{"type" => "downlink_completion_gap", "feedback_scope" => "link_capacity"} = risk,
         "link_capacity_blocked"
       ) do
    blocked_value?(risk["link_capacity_status"]) or
      blocked_value?(risk["downlink_requirement_status"]) or
      blocked_value?(risk["actual_downlink_requirement_status"]) or
      blocked_value?(risk["policy_classification"]) or
      blocked_value?(risk["approval_status"])
  end

  defp risk_matches_blocked_type?(
         %{"type" => "downlink_completion_gap", "feedback_scope" => "resource_projection"} =
           risk,
         "resource_projection_blocked"
       ) do
    blocked_value?(risk["resource_projection_status"]) or
      blocked_value?(risk["projected_resource_status"]) or
      blocked_value?(risk["policy_classification"]) or
      blocked_value?(risk["approval_status"])
  end

  defp risk_matches_blocked_type?(
         %{"type" => "downlink_completion_gap", "feedback_scope" => "contact_filter"} = risk,
         "contact_filter_blocked"
       ) do
    blocked_value?(risk["contact_filter_status"]) or
      blocked_value?(risk["suppression_status"]) or
      blocked_value?(risk["policy_classification"]) or
      blocked_value?(risk["approval_status"])
  end

  defp risk_matches_blocked_type?(
         %{"type" => "downlink_completion_gap", "feedback_scope" => scope} = risk,
         "contact_contention_blocked"
       )
       when scope in ["contact_contention", "contact_contention_resolution"] do
    blocked_value?(risk["policy_classification"]) or
      blocked_value?(risk["approval_status"])
  end

  defp risk_matches_blocked_type?(
         %{"feedback_scope" => "resource_filter"} = risk,
         "resource_filter_availability_blocked"
       ) do
    resource_availability_blocked?(risk) and
      (blocked_value?(risk["resource_filter_status"]) or
         blocked_value?(risk["suppression_status"]) or
         blocked_value?(risk["policy_classification"]) or
         blocked_value?(risk["approval_status"]) or
         risk["resource_availability_value"] == false)
  end

  defp risk_matches_blocked_type?(
         %{"type" => "model_acceptance_pressure"} = risk,
         "model_acceptance_blocked"
       ) do
    blocked_model_acceptance_pressure?(risk)
  end

  defp risk_matches_blocked_type?(
         %{"feedback_scope" => "model_acceptance"} = risk,
         "model_acceptance_blocked"
       ) do
    blocked_model_acceptance_pressure?(risk)
  end

  defp risk_matches_blocked_type?(
         %{"type" => "validation_safety_case_pressure"} = risk,
         "validation_safety_case_blocked"
       ) do
    blocked_validation_safety_case_pressure?(risk)
  end

  defp risk_matches_blocked_type?(
         %{"feedback_scope" => "validation_safety_case"} = risk,
         "validation_safety_case_blocked"
       ) do
    blocked_validation_safety_case_pressure?(risk)
  end

  defp risk_matches_blocked_type?(
         %{"type" => "schema_validation_pressure"} = risk,
         "schema_validation_blocked"
       ) do
    blocked_schema_validation_pressure?(risk)
  end

  defp risk_matches_blocked_type?(
         %{"feedback_scope" => "schema_validation"} = risk,
         "schema_validation_blocked"
       ) do
    blocked_schema_validation_pressure?(risk)
  end

  defp risk_matches_blocked_type?(
         %{"type" => "refresh_budget_pressure"} = risk,
         "refresh_budget_blocked"
       ) do
    blocked_refresh_budget_pressure?(risk)
  end

  defp risk_matches_blocked_type?(
         %{"feedback_scope" => "refresh_budget"} = risk,
         "refresh_budget_blocked"
       ) do
    blocked_refresh_budget_pressure?(risk)
  end

  defp risk_matches_blocked_type?(
         %{"type" => "refresh_freshness_pressure"} = risk,
         "refresh_freshness_blocked"
       ) do
    blocked_refresh_freshness_pressure?(risk)
  end

  defp risk_matches_blocked_type?(
         %{"feedback_scope" => "refresh_freshness"} = risk,
         "refresh_freshness_blocked"
       ) do
    blocked_refresh_freshness_pressure?(risk)
  end

  defp risk_matches_blocked_type?(
         %{"type" => "timeline_activity_precondition_review"} = risk,
         "timeline_activity_precondition_blocked"
       ) do
    blocked_timeline_activity_precondition_pressure?(risk)
  end

  defp risk_matches_blocked_type?(
         %{"feedback_scope" => "timeline_activity_precondition"} = risk,
         "timeline_activity_precondition_blocked"
       ) do
    blocked_timeline_activity_precondition_pressure?(risk)
  end

  defp risk_matches_blocked_type?(
         %{"type" => "downlink_completion_gap", "feedback_scope" => "contact_allocation"} =
           risk,
         "station_reservation_conflict_blocked"
       ) do
    blocked_station_reservation_conflict_pressure?(risk)
  end

  defp risk_matches_blocked_type?(risk, "station_reservation_expiration_blocked") do
    blocked_station_reservation_expiration_pressure?(risk)
  end

  defp risk_matches_blocked_type?(
         %{"type" => "provider_counteroffer_pressure"} = risk,
         "provider_counteroffer_blocked"
       ) do
    blocked_provider_counteroffer_pressure?(risk)
  end

  defp risk_matches_blocked_type?(
         %{"type" => "provider_counteroffer_review"} = risk,
         "provider_counteroffer_blocked"
       ) do
    blocked_provider_counteroffer_pressure?(risk)
  end

  defp risk_matches_blocked_type?(
         %{"feedback_scope" => "provider_counteroffer"} = risk,
         "provider_counteroffer_blocked"
       ) do
    blocked_provider_counteroffer_pressure?(risk)
  end

  defp risk_matches_blocked_type?(
         %{"type" => "provider_reservation_request_review"} = risk,
         "provider_reservation_request_blocked"
       ) do
    blocked_provider_reservation_request_pressure?(risk)
  end

  defp risk_matches_blocked_type?(
         %{"feedback_scope" => "contact_allocation_provider_reservation_request"} = risk,
         "provider_reservation_request_blocked"
       ) do
    blocked_provider_reservation_request_pressure?(risk)
  end

  defp risk_matches_blocked_type?(_risk, _blocked_type), do: false

  defp blocked_model_acceptance_pressure?(risk) do
    blocked_value?(risk["model_acceptance_status"]) or
      blocked_value?(risk["model_status"]) or
      positive_count?(risk["blocked_count"]) or
      risk["branch_local_blocking_pressure"] == true or
      risk["required_operator_action"] == "review_blocked_model_acceptance"
  end

  defp blocked_validation_safety_case_pressure?(risk) do
    blocked_value?(risk["validation_safety_case_status"]) or
      blocked_value?(risk["evidence_status"]) or
      positive_count?(risk["blocked_evidence_count"]) or
      positive_count?(risk["schema_error_count"]) or
      positive_count?(risk["model_blocked_count"]) or
      positive_count?(risk["quality_gate_blocked_count"]) or
      risk["branch_local_blocking_pressure"] == true or
      risk["required_operator_action"] == "review_blocked_validation_safety_case"
  end

  defp blocked_schema_validation_pressure?(risk) do
    blocked_value?(risk["validation_status"]) or
      risk["validation_status"] == "fail" or
      risk["issue_severity"] == "error" or
      positive_count?(risk["error_count"]) or
      risk["branch_local_schema_error_pressure"] == true
  end

  defp blocked_import_readiness_pressure?(risk) do
    risk["import_blocked"] == true or
      positive_count?(risk["blocked_import_count"]) or
      nonempty_list?(risk["blocked_import_quality_gate_row_ids"]) or
      positive_count_for_key?(risk["import_status_counts"], "blocked") or
      positive_count_for_key?(risk["import_status_counts"], "blocked_missing_cadence_import")
  end

  defp blocked_refresh_budget_pressure?(risk) do
    blocked_value?(risk["refresh_budget_status"]) or
      risk["refresh_budget_status"] == "invalid" or
      risk["candidate_limit_status"] == "invalid" or
      risk["invalid_candidate_limit_policy"] == true or
      positive_count?(risk["invalid_candidate_limit_policy_count"]) or
      risk["branch_local_invalid_limit_pressure"] == true
  end

  defp blocked_refresh_freshness_pressure?(risk) do
    blocked_value?(risk["freshness_status"]) or
      risk["freshness_status"] == "stale" or
      risk["state_quality_status"] == "stale" or
      "stale" in List.wrap(risk["freshness_statuses"]) or
      positive_count?(risk["stale_reason_count"]) or
      risk["branch_local_stale_pressure"] == true
  end

  defp blocked_timeline_activity_precondition_pressure?(risk) do
    blocked_value?(risk["precondition_status"]) or
      positive_count?(risk["blocked_precondition_count"]) or
      risk["required_operator_action"] == "review_blocked_activity_precondition"
  end

  defp blocked_station_reservation_conflict_pressure?(risk) do
    station_reservation_conflict_match_status?(risk["station_reservation_match_status"]) or
      "contact_allocation_reservation_conflict" in List.wrap(risk["derivation_reasons"]) or
      reservation_conflict_source?(risk["feedback_source"])
  end

  defp station_reservation_conflict_match_status?(status) when is_atom(status) do
    status
    |> Atom.to_string()
    |> station_reservation_conflict_match_status?()
  end

  defp station_reservation_conflict_match_status?(status) when is_binary(status) do
    status
    |> String.trim()
    |> String.downcase()
    |> then(&(&1 in ["overlap", "conflict", "unmatched", "unmatched_overlap", "owner_mismatch"]))
  end

  defp station_reservation_conflict_match_status?(_status), do: false

  defp reservation_conflict_source?(source) when is_binary(source) do
    String.contains?(source, "reservation_conflict_summary")
  end

  defp reservation_conflict_source?(_source), do: false

  defp blocked_station_reservation_expiration_pressure?(risk) do
    risk["station_reservation_expiration_status"] in ["expired", "missing"] or
      risk["station_reservation_hold_expiration_status"] in ["expired", "missing"] or
      "expired" in List.wrap(risk["station_reservation_expiration_statuses"]) or
      "missing" in List.wrap(risk["station_reservation_expiration_statuses"]) or
      "expired" in List.wrap(risk["station_reservation_hold_expiration_statuses"]) or
      "missing" in List.wrap(risk["station_reservation_hold_expiration_statuses"])
  end

  defp blocked_provider_counteroffer_pressure?(risk) do
    blocked_value?(risk["provider_counteroffer_import_status"]) or
      blocked_value?(risk["import_readiness_status"]) or
      blocked_value?(risk["import_classification"]) or
      risk["provider_counteroffer_lock_deadline_status"] in ["expired", "missing"] or
      "expired" in List.wrap(risk["provider_counteroffer_lock_deadline_statuses"]) or
      "missing" in List.wrap(risk["provider_counteroffer_lock_deadline_statuses"]) or
      positive_count_for_key?(risk["counteroffer_lock_deadline_status_counts"], "expired") or
      positive_count_for_key?(risk["counteroffer_lock_deadline_status_counts"], "missing") or
      positive_count_for_key?(risk["provider_counteroffer_import_status_counts"], "blocked") or
      positive_count_for_key?(risk["import_readiness_status_counts"], "blocked") or
      positive_count_for_key?(risk["import_classification_counts"], "blocked")
  end

  defp blocked_provider_reservation_request_pressure?(risk) do
    blocked_value?(risk["provider_reservation_request_status"]) or
      risk["provider_reservation_request_status"] == "review_required" or
      risk["provider_reservation_row_scope"] == "review" or
      risk["station_reservation_match_status"] in [
        "overlap",
        "conflict",
        "unmatched",
        "owner_mismatch"
      ] or
      Enum.any?(List.wrap(risk["station_reservation_match_statuses"]), fn status ->
        status in ["overlap", "conflict", "unmatched", "owner_mismatch"]
      end)
  end

  defp nonempty_list?(value), do: is_list(value) and value != []

  defp positive_count_for_key?(%{} = counts, key), do: positive_count?(Map.get(counts, key))
  defp positive_count_for_key?(_counts, _key), do: false

  defp resource_availability_blocked?(risk) do
    is_binary(risk["resource_field"]) and
      Map.has_key?(risk, "resource_availability_value")
  end

  defp blocked_value?(value) when is_binary(value),
    do: value in ["blocked", "blocked_by_policy"]

  defp blocked_value?(_value), do: false

  defp positive_count?(value) when is_integer(value), do: value > 0
  defp positive_count?(value) when is_float(value), do: value > 0.0
  defp positive_count?(_value), do: false
end
