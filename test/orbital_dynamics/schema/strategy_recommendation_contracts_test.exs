defmodule OrbitalDynamics.Schema.StrategyRecommendationContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  test "exports nested strategy recommendation schemas" do
    assert {:ok, schema} = Schema.json_schema("strategy_recommendation.v1")

    recommendation = read_json!("study_results/strategy_recommendation_v1.json")

    assert {:ok, %{"schema_contract" => "strategy_recommendation.v1"}} =
             Schema.validate_artifact(recommendation)

    assert %{
             "branch_transition_types" => ["approval_state_changed"],
             "branch_transition_categories" => ["urgent_retarget_review"],
             "branch_requires_operator_review" => true,
             "branch_requires_operator_review_count" => 1
           } =
             Enum.find(
               recommendation["explanation"],
               &(&1["type"] == "branch_event_summary")
             )

    invalid_status = Map.put(recommendation, "status", 42)
    assert {:error, status_report} = Schema.validate_artifact(invalid_status)
    assert Enum.any?(status_report["errors"], &(&1["path"] == "$.status"))

    assert get_in(schema, ["properties", "status", "type"]) == "string"

    assert get_in(schema, ["properties", "ranked_branch_ids", "items", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    tradeoff_schema = get_in(schema, ["properties", "tradeoffs", "items"])

    assert tradeoff_schema["required"] == ["dimension", "baseline", "recommended", "delta"]
    assert get_in(tradeoff_schema, ["properties", "delta", "type"]) == "number"

    explanation_schema = get_in(schema, ["properties", "explanation", "items"])

    assert explanation_schema["required"] == ["type"]

    assert get_in(explanation_schema, ["properties", "recommended_branch_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(explanation_schema, ["properties", "classification", "enum"]) == [
             "auto_approvable",
             "operator_review_required",
             "blocked_by_policy"
           ]

    assert get_in(explanation_schema, ["properties", "branch_transition_types", "items", "type"]) ==
             "string"

    assert get_in(explanation_schema, [
             "properties",
             "branch_transition_categories",
             "items",
             "type"
           ]) ==
             "string"

    assert get_in(explanation_schema, ["properties", "branch_requires_operator_review", "type"]) ==
             "boolean"

    assert get_in(explanation_schema, [
             "properties",
             "branch_requires_operator_review_count",
             "minimum"
           ]) == 0

    invalid_explanation =
      put_in(
        recommendation,
        ["explanation"],
        [
          %{
            "type" => "branch_event_summary",
            "branch_transition_types" => "approval_state_changed"
          }
        ]
      )

    assert {:error, explanation_report} = Schema.validate_artifact(invalid_explanation)

    assert Enum.any?(
             explanation_report["errors"],
             &(&1["path"] == "$.explanation[0].branch_transition_types")
           )

    risk_schema = get_in(schema, ["properties", "risks_remaining", "items"])

    assert risk_schema["required"] == ["type", "severity", "reason"]
    assert get_in(risk_schema, ["properties", "value", "type"]) == "number"

    assert get_in(risk_schema, ["properties", "collection_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    for field <- ["collection_ids", "product_ids", "payload_ids", "instrument_ids"] do
      assert get_in(risk_schema, ["properties", field, "items", "pattern"]) ==
               Schema.identity_policy()["stable_id_pattern"]
    end

    assert get_in(risk_schema, ["properties", "source_activity_ids", "items", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    invalid_risk =
      put_in(
        recommendation,
        ["risks_remaining"],
        [
          %{
            "type" => "downlink_completion_gap",
            "severity" => "warning",
            "reason" => "broad collection selector preserved for review",
            "collection_ids" => ["collection_alpha", "bad collection"],
            "product_ids" => ["product_a"],
            "payload_ids" => ["payload_a"],
            "instrument_ids" => ["instrument_a"]
          }
        ]
      )

    assert {:error, risk_report} = Schema.validate_artifact(invalid_risk)

    assert Enum.any?(
             risk_report["errors"],
             &(&1["path"] == "$.risks_remaining[0].collection_ids[1]")
           )

    requirement_schema = get_in(schema, ["properties", "requires_approval", "items"])

    assert requirement_schema["required"] == ["activity_id", "activity_type", "action", "reason"]

    assert get_in(requirement_schema, ["properties", "schema_contract", "const"]) ==
             "approval_requirement.v1"

    assert get_in(requirement_schema, [
             "properties",
             "approval_rule_matches",
             "items",
             "properties",
             "rule_id",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
