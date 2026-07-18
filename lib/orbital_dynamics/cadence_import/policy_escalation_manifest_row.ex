defmodule OrbitalDynamics.CadenceImport.PolicyEscalationManifestRow do
  @moduledoc false

  def build(row, rank, callbacks) when is_list(callbacks) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")

    %{
      "id" => "cadence_import:policy_escalation:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_policy_escalation",
      "import_status" => adapter_import_status(callbacks, "present", approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(callbacks, row),
      "source" => row["source"],
      "subject_id" => row["subject_id"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "reason" => row["reason"],
      "policy_bundle_id" => row["policy_bundle_id"],
      "policy_bundle_provenance" => row["policy_bundle_provenance"],
      "policy_bundle_provenance_source" => row["policy_bundle_provenance_source"],
      "policy_bundle_adapter" => row["policy_bundle_adapter"],
      "policy_bundle_organization_id" => row["policy_bundle_organization_id"],
      "policy_bundle_policy_source" => row["policy_bundle_policy_source"],
      "rule_id" => row["rule_id"],
      "escalation_level" => row["escalation_level"],
      "escalation_queue" => row["escalation_queue"],
      "escalation_role" => row["escalation_role"],
      "required_authority" => row["required_authority"],
      "sla_s" => row["sla_s"],
      "cadence_import_status" => "present",
      "has_cadence_import" => false,
      "source_policy_escalation" => row["source_policy_escalation"],
      "source_policy_decision" => row["source_policy_decision"],
      "source_review_row" => row
    }
    |> compact_map(callbacks)
  end

  defp source_review_action(callbacks, row),
    do: invoke(callbacks, :source_review_action, [row])

  defp adapter_import_status(callbacks, status, approval_status),
    do: invoke(callbacks, :adapter_import_status, [status, approval_status])

  defp compact_map(value, callbacks), do: invoke(callbacks, :compact_map, [value])

  defp invoke(callbacks, name, args), do: apply(Keyword.fetch!(callbacks, name), args)
end
