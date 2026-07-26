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

  test "rejects Repair approval decision drift", context do
    invalid_cases = [
      {"$.approval_status", Map.put(context.repair, "approval_status", "blocked_by_policy")},
      {"$.approval_rule_matches", Map.put(context.repair, "approval_rule_matches", [])},
      {"$.policy_decision.approval_requirement_count",
       put_in(
         context.readiness_repair,
         ["policy_decision", "approval_requirement_count"],
         2
       )}
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
end
