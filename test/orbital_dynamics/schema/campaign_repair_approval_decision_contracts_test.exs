defmodule OrbitalDynamics.Schema.CampaignRepairApprovalDecisionContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  setup do
    %{
      repair: read_json!("study_results/leo_constellation_campaign_repair_v2.json"),
      readiness_repair:
        read_json!("study_results/campaign_repair_readiness_source_handoff_v2.json")
    }
  end

  test "validates checked Repair approval decision surfaces", context do
    for artifact <- [context.repair, context.readiness_repair] do
      assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
               Schema.validate_artifact(artifact)
    end
  end

  test "keeps the additive top-level rule-match copy optional", %{repair: repair} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             repair
             |> Map.delete("approval_rule_matches")
             |> Schema.validate_artifact()
  end

  test "keeps additive requirement enrichment copies optional", %{repair: repair} do
    older_requirement =
      repair
      |> get_in(["approval_requirements", Access.at(0)])
      |> Map.drop(["approval_rule_matches", "policy_classification"])

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             repair
             |> put_in(["approval_requirements", Access.at(0)], older_requirement)
             |> drop_approval_handoffs()
             |> Schema.validate_artifact()
  end

  test "replays action-only requirement enrichment", %{repair: repair} do
    action_match =
      repair
      |> get_in(["policy_decision", "rule_matches", Access.at(0)])
      |> Map.delete("activity_id")

    action_repair =
      repair
      |> Map.put("approval_rule_matches", [action_match])
      |> put_in(["policy_decision", "rule_matches"], [action_match])
      |> put_in(
        ["approval_requirements", Access.at(0), "approval_rule_matches"],
        [action_match]
      )
      |> drop_approval_handoffs()

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(action_repair)
  end

  test "does not action-match a rule that declares another activity identity", %{repair: repair} do
    identified_match =
      repair
      |> get_in(["policy_decision", "rule_matches", Access.at(0)])
      |> Map.put("activity_id", "different_activity")

    unmatched_requirement =
      repair
      |> get_in(["approval_requirements", Access.at(0)])
      |> Map.drop(["approval_rule_matches", "policy_classification"])

    unmatched_repair =
      repair
      |> Map.put("approval_rule_matches", [identified_match])
      |> put_in(["policy_decision", "rule_matches"], [identified_match])
      |> put_in(["approval_requirements", Access.at(0)], unmatched_requirement)
      |> drop_approval_handoffs()

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(unmatched_repair)
  end

  test "keeps additive fallback policy evidence optional", %{repair: repair} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             repair
             |> update_in(["policy_decision"], &Map.delete(&1, "fallback_policy"))
             |> Schema.validate_artifact()

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             repair
             |> update_in(
               ["policy_decision", "fallback_policy"],
               &Map.delete(&1, "operator_review_risk_limit")
             )
             |> Schema.validate_artifact()

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             repair
             |> update_in(["approval_policy"], &Map.delete(&1, "operator_review_risk_limit"))
             |> Schema.validate_artifact()
  end

  test "keeps additive action-rule provenance optional", %{repair: repair} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             repair
             |> update_in(["approval_policy"], &Map.delete(&1, "action_rules"))
             |> Schema.validate_artifact()

    without_match_id =
      repair
      |> update_rule_match_copies(&Map.delete(&1, "rule_id"))
      |> drop_approval_handoffs()

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(without_match_id)
  end

  test "rejects Repair decision rule provenance drift", %{repair: repair} do
    classification_drift =
      repair
      |> update_rule_match_copies(&Map.put(&1, "classification", "auto_approvable"))
      |> Map.put("approval_status", "auto_approvable")
      |> put_in(["policy_decision", "classification"], "auto_approvable")
      |> put_in(["policy_decision", "approval_requirement_count"], 0)
      |> put_in(
        ["approval_requirements", Access.at(0), "policy_classification"],
        "auto_approvable"
      )

    invalid_cases = [
      {"$.policy_decision.rule_matches[0].rule_id",
       update_rule_match_copies(repair, &Map.put(&1, "rule_id", "unknown_rule"))},
      {"$.policy_decision.rule_matches[0].classification", classification_drift},
      {"$.policy_decision.rule_matches[0].reason",
       update_rule_match_copies(repair, &Map.put(&1, "reason", "drifted rule reason"))}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects Repair approval decision drift", context do
    invalid_cases = [
      {"$.approval_status", Map.put(context.repair, "approval_status", "blocked_by_policy")},
      {"$.approval_rule_matches", Map.put(context.repair, "approval_rule_matches", [])},
      {"$.policy_decision.approval_requirement_count",
       put_in(
         context.readiness_repair,
         ["policy_decision", "approval_requirement_count"],
         2
       )},
      {"$.approval_requirements[0].approval_rule_matches",
       put_in(
         context.repair,
         ["approval_requirements", Access.at(0), "approval_rule_matches"],
         []
       )},
      {"$.approval_requirements[0].policy_classification",
       put_in(
         context.repair,
         ["approval_requirements", Access.at(0), "policy_classification"],
         "auto_approvable"
       )},
      {"$.policy_decision.fallback_policy.auto_approvable_approval_count_limit",
       put_in(
         context.repair,
         ["policy_decision", "fallback_policy", "auto_approvable_approval_count_limit"],
         1
       )},
      {"$.policy_decision.fallback_policy.auto_approvable_risk_limit",
       put_in(
         context.repair,
         ["policy_decision", "fallback_policy", "auto_approvable_risk_limit"],
         1
       )},
      {"$.policy_decision.fallback_policy.operator_review_risk_limit",
       put_in(
         context.repair,
         ["policy_decision", "fallback_policy", "operator_review_risk_limit"],
         4
       )},
      {"$.policy_decision.fallback_policy.blocked_risk_types",
       update_in(
         context.repair,
         ["policy_decision", "fallback_policy", "blocked_risk_types"],
         &Enum.reverse/1
       )},
      {"$.policy_decision.fallback_policy",
       put_in(context.repair, ["policy_decision", "fallback_policy"], [])}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end

  defp update_rule_match_copies(repair, update) do
    match =
      repair
      |> get_in(["policy_decision", "rule_matches", Access.at(0)])
      |> update.()

    repair
    |> Map.put("approval_rule_matches", [match])
    |> put_in(["policy_decision", "rule_matches"], [match])
    |> put_in(["approval_requirements", Access.at(0), "approval_rule_matches"], [match])
  end

  defp drop_approval_handoffs(repair) do
    Map.drop(repair, ["operator_review_package", "cadence_import_manifest"])
  end
end
