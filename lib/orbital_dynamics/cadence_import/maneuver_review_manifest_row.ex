defmodule OrbitalDynamics.CadenceImport.ManeuverReviewManifestRow do
  @moduledoc false

  def build(row, rank, callbacks) when is_list(callbacks) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")

    %{
      "id" => "cadence_import:maneuver_review:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_maneuver",
      "import_status" => adapter_import_status(callbacks, import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(callbacks, row),
      "subject_id" => row["subject_id"],
      "maneuver_id" => row["maneuver_id"],
      "scenario_id" => row["scenario_id"],
      "maneuver_type" => row["maneuver_type"],
      "epoch_s" => row["epoch_s"],
      "epoch_scale" => row["epoch_scale"],
      "frame" => row["frame"],
      "delta_v_km_s" => row["delta_v_km_s"],
      "delta_v_magnitude_km_s" => row["delta_v_magnitude_km_s"],
      "maneuver_model" => row["maneuver_model"],
      "maneuver_success_factor" => row["maneuver_success_factor"],
      "maneuver_success_factor_source" => row["maneuver_success_factor_source"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "reason" => row["reason"],
      "execution_boundary" => row["execution_boundary"],
      "requirement_type" => row["requirement_type"],
      "required_authority" => row["required_authority"],
      "policy_bundle_id" => row["policy_bundle_id"],
      "rule_id" => row["rule_id"],
      "escalation_level" => row["escalation_level"],
      "escalation_queue" => row["escalation_queue"],
      "escalation_role" => row["escalation_role"],
      "sla_s" => row["sla_s"],
      "approval_requirements" => row["approval_requirements"],
      "approval_rule_matches" => row["approval_rule_matches"],
      "cadence_import_status" => import_status,
      "has_cadence_import" => false,
      "source_policy_escalation" => row["source_policy_escalation"],
      "source_policy_decision" => row["source_policy_decision"],
      "source_recommendation" => row["source_recommendation"],
      "source_maneuver_review" => row["source_maneuver_review"],
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
