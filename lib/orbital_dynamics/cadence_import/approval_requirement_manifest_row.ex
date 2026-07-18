defmodule OrbitalDynamics.CadenceImport.ApprovalRequirementManifestRow do
  @moduledoc false

  def build(row, rank, callbacks) when is_list(callbacks) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")
    source_requirement = stringify_keys(row["source_requirement"] || %{}, callbacks)
    rule_match = first_approval_rule_match(callbacks, row)
    source_rule_match = first_approval_rule_match(callbacks, source_requirement)
    policy_decision = stringify_keys(row["source_policy_decision"] || %{}, callbacks)

    policy_escalation =
      policy_decision["escalations"]
      |> preferred_approval_escalation(row, source_requirement, callbacks)
      |> stringify_keys(callbacks)

    %{
      "id" => "cadence_import:approval_requirement:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_approval_requirement",
      "import_status" => adapter_import_status(callbacks, import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(callbacks, row),
      "subject_id" => row["subject_id"],
      "branch_id" => row["branch_id"],
      "activity_id" => row["activity_id"],
      "activity_type" => row["activity_type"],
      "target_id" => row["target_id"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "requirement_type" => row["requirement_type"] || source_requirement["requirement_type"],
      "required_authority" =>
        row["required_authority"] || source_requirement["required_authority"] ||
          rule_match["required_authority"] || source_rule_match["required_authority"] ||
          policy_escalation["required_authority"],
      "policy_bundle_id" =>
        row["policy_bundle_id"] || source_requirement["policy_bundle_id"] ||
          policy_decision["policy_bundle_id"],
      "rule_id" =>
        row["rule_id"] || source_requirement["rule_id"] || rule_match["rule_id"] ||
          source_rule_match["rule_id"] || policy_escalation["rule_id"],
      "escalation_level" =>
        row["escalation_level"] || rule_match["escalation_level"] ||
          source_rule_match["escalation_level"] || policy_escalation["escalation_level"],
      "escalation_queue" =>
        row["escalation_queue"] || rule_match["escalation_queue"] ||
          source_rule_match["escalation_queue"] || policy_escalation["escalation_queue"],
      "escalation_role" =>
        row["escalation_role"] || rule_match["escalation_role"] ||
          source_rule_match["escalation_role"] || policy_escalation["escalation_role"],
      "sla_s" =>
        row["sla_s"] || rule_match["sla_s"] || source_rule_match["sla_s"] ||
          policy_escalation["sla_s"],
      "reason" => row["reason"],
      "approval_rule_matches" =>
        row["approval_rule_matches"] || source_requirement["approval_rule_matches"],
      "candidate_diff" => row["candidate_diff"],
      "cadence_import_status" => import_status,
      "has_cadence_import" => false,
      "import_activity_context" =>
        normalize_provider_result_artifact_fields(
          callbacks,
          generic_review_activity_context(callbacks, row)
        ),
      "source_requirement" => row["source_requirement"],
      "source_policy_decision" => row["source_policy_decision"],
      "source_policy_escalation" =>
        row["source_policy_escalation"] || non_empty_map(callbacks, policy_escalation),
      "source_review_row" => row
    }
    |> put_candidate_diff_fields(row["candidate_diff"], callbacks)
    |> compact_map(callbacks)
  end

  defp put_candidate_diff_fields(row, nil, _callbacks), do: row

  defp put_candidate_diff_fields(row, %{} = candidate_diff, callbacks) do
    row
    |> Map.put("invalidated_candidate_id", candidate_diff["invalidated_candidate_id"])
    |> Map.put("invalidated_candidate_ids", candidate_diff["invalidated_candidate_ids"])
    |> Map.put("replacement_candidate_id", candidate_diff["replacement_candidate_id"])
    |> Map.put("invalidated_reason", candidate_diff["invalidated_reason"])
    |> Map.put("semantic_change_reasons", candidate_diff["semantic_change_reasons"])
    |> Map.put("semantic_change_details", candidate_diff["semantic_change_details"])
    |> put_candidate_diff_changed_fields(candidate_diff, callbacks)
    |> Map.put("candidate_diff_match_status", candidate_diff["candidate_diff_match_status"])
    |> Map.put("candidate_diff_match_count", candidate_diff["candidate_diff_match_count"])
    |> Map.put("semantic_match_status", candidate_diff["semantic_match_status"])
    |> Map.put("semantic_match_candidate_count", candidate_diff["semantic_match_candidate_count"])
    |> Map.put("semantic_match_candidate_ids", candidate_diff["semantic_match_candidate_ids"])
    |> Map.put("candidate_budget_match_status", candidate_diff["candidate_budget_match_status"])
    |> Map.put("candidate_budget_match_count", candidate_diff["candidate_budget_match_count"])
    |> Map.put("budget_dropped_candidate_ids", candidate_diff["budget_dropped_candidate_ids"])
  end

  defp put_candidate_diff_changed_fields(row, candidate_diff, callbacks) do
    changed_fields = candidate_diff_changed_fields(callbacks, candidate_diff)

    row
    |> Map.put("changed_fields", changed_fields)
    |> Map.put("candidate_diff_changed_fields", changed_fields)
    |> Map.put(
      "candidate_diff_changed_field_count",
      candidate_diff_changed_field_count(callbacks, changed_fields)
    )
  end

  defp stringify_keys(value, callbacks), do: invoke(callbacks, :stringify_keys, [value])

  defp first_approval_rule_match(callbacks, row),
    do: invoke(callbacks, :first_approval_rule_match, [row])

  defp preferred_approval_escalation(escalations, row, source_requirement, callbacks),
    do: invoke(callbacks, :preferred_approval_escalation, [escalations, row, source_requirement])

  defp source_review_action(callbacks, row),
    do: invoke(callbacks, :source_review_action, [row])

  defp adapter_import_status(callbacks, status, approval_status),
    do: invoke(callbacks, :adapter_import_status, [status, approval_status])

  defp generic_review_activity_context(callbacks, row),
    do: invoke(callbacks, :generic_review_activity_context, [row])

  defp normalize_provider_result_artifact_fields(callbacks, value),
    do: invoke(callbacks, :normalize_provider_result_artifact_fields, [value])

  defp non_empty_map(callbacks, value), do: invoke(callbacks, :non_empty_map, [value])

  defp candidate_diff_changed_fields(callbacks, row),
    do: invoke(callbacks, :candidate_diff_changed_fields, [row])

  defp candidate_diff_changed_field_count(callbacks, fields),
    do: invoke(callbacks, :candidate_diff_changed_field_count, [fields])

  defp compact_map(value, callbacks), do: invoke(callbacks, :compact_map, [value])

  defp invoke(callbacks, name, args), do: apply(Keyword.fetch!(callbacks, name), args)
end
