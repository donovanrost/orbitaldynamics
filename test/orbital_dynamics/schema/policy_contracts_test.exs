defmodule OrbitalDynamics.Schema.PolicyContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Policy, Schema}

  test "validates checked-in operational policy examples" do
    policy_bundle = read_json!("study_results/policy_bundle_v1.json")
    policy_decision = read_json!("study_results/policy_decision_v1.json")

    assert {:ok, %{"schema_contract" => "policy_bundle.v1"}} =
             Schema.validate_artifact(policy_bundle)

    assert {:ok, policy_bundle_schema} = Schema.json_schema("policy_bundle.v1")

    assert get_in(policy_bundle_schema, ["properties", "model_limits", "items", "enum"]) ==
             policy_model_limits()

    stale_bundle_limits = Map.put(policy_bundle, "model_limits", ["stale_policy_boundary"])

    assert {:error, bundle_limits_report} = Schema.validate_artifact(stale_bundle_limits)
    assert Enum.any?(bundle_limits_report["errors"], &(&1["path"] == "$.model_limits"))

    assert %{
             "id" => "mission_ops_escalation_v1",
             "approval_policy" => %{
               "action_rules" => action_rules
             }
           } = policy_bundle

    assert Enum.map(action_rules, & &1["id"]) ==
             Policy.bundle!("mission_ops_escalation_v1")
             |> get_in(["approval_policy", "action_rules"])
             |> Enum.map(& &1["id"])

    assert Enum.any?(
             action_rules,
             &(&1["id"] == "reserved_station_contact_escalation" and
                 &1["station_contention_statuses"] == ["reserved_overlap"] and
                 &1["required_authority"] == "contact_schedule_authority")
           )

    assert Enum.any?(
             action_rules,
             &(&1["id"] == "strategic_priority_escalation" and
                 &1["required_authority"] == "mission_planning_authority")
           )

    assert Enum.any?(
             action_rules,
             &(&1["id"] == "downlink_loss_director_escalation" and
                 &1["classification"] == "blocked_by_policy" and
                 &1["escalation_level"] == "flight_director")
           )

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(policy_decision)

    assert {:ok, policy_decision_schema} = Schema.json_schema("policy_decision.v1")

    assert get_in(policy_decision_schema, ["properties", "assumptions", "type"]) == "object"

    assert get_in(policy_decision_schema, ["properties", "model_limits", "items", "enum"]) ==
             policy_model_limits()

    assert get_in(policy_decision_schema, [
             "properties",
             "approval_requirement_count"
           ]) == %{"type" => "integer", "minimum" => 0}

    assert get_in(policy_decision_schema, ["properties", "risk_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    stale_decision_limits = Map.put(policy_decision, "model_limits", ["stale_policy_boundary"])

    assert {:error, decision_limits_report} = Schema.validate_artifact(stale_decision_limits)
    assert Enum.any?(decision_limits_report["errors"], &(&1["path"] == "$.model_limits"))

    invalid_decision_counts =
      policy_decision
      |> Map.put("approval_requirement_count", 1.0)
      |> Map.put("risk_count", -1)

    assert {:error, decision_count_report} = Schema.validate_artifact(invalid_decision_counts)

    assert Enum.any?(
             decision_count_report["errors"],
             &(&1["path"] == "$.approval_requirement_count")
           )

    assert Enum.any?(decision_count_report["errors"], &(&1["path"] == "$.risk_count"))

    assert %{
             "classification" => "operator_review_required",
             "policy_bundle_id" => "mission_ops_escalation_v1",
             "rule_matches" => [
               %{
                 "rule_id" => "contact_execution_coordination",
                 "ground_station_id" => "equator_prime",
                 "required_authority" => "contact_schedule_authority"
               }
             ],
             "escalations" => [%{"sla_s" => 1800}]
           } = policy_decision
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end

  defp policy_model_limits do
    Policy.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end
end
