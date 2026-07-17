defmodule OrbitalDynamics.Validation.PolicyDecisionFixtureTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Schema, Validation}

  import OrbitalDynamics.Validation.PolicyDecisionFixtures,
    only: [
      approval_requirement_fixture: 0,
      approval_requirement_fixture_observations: 0,
      policy_decision_fixture: 0,
      policy_decision_fixture_observations: 0
    ]

  test "verifies curated approval requirement reference fixtures" do
    fixture_id = "fixture.artifact.approval_requirement.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.approval_requirement.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = approval_requirement_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               approval_requirement_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      approval_requirement_fixture_observations()
      |> Map.put("required_authority", "mission_planning_authority")

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "required_authority" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "approval_requirement.v1",
             report
           ) == Validation.artifact_observations("approval_requirement.v1", report)

    assert {:ok, %{"schema_contract" => "approval_requirement.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "approval_requirement.v1"
             )

    stale_decision_classification =
      put_in(report, ["policy_decision", "classification"], "auto_approvable")

    assert {:error, stale_decision_classification_report} =
             Schema.validate_artifact(stale_decision_classification,
               schema_contract: "approval_requirement.v1"
             )

    assert Enum.any?(
             stale_decision_classification_report["errors"],
             &(&1["path"] == "$.policy_decision.classification")
           )

    stale_decision_policy_bundle =
      put_in(report, ["policy_decision", "policy_bundle_id"], "other_policy_bundle")

    assert {:error, stale_decision_policy_bundle_report} =
             Schema.validate_artifact(stale_decision_policy_bundle,
               schema_contract: "approval_requirement.v1"
             )

    assert Enum.any?(
             stale_decision_policy_bundle_report["errors"],
             &(&1["path"] == "$.policy_decision.policy_bundle_id")
           )

    stale_rule_matches = Map.put(report, "approval_rule_matches", [])

    assert {:error, stale_rule_matches_report} =
             Schema.validate_artifact(stale_rule_matches,
               schema_contract: "approval_requirement.v1"
             )

    assert Enum.any?(
             stale_rule_matches_report["errors"],
             &(&1["path"] == "$.approval_rule_matches")
           )

    stale_escalations = put_in(report, ["policy_decision", "escalations"], [])

    assert {:error, stale_escalations_report} =
             Schema.validate_artifact(stale_escalations,
               schema_contract: "approval_requirement.v1"
             )

    assert Enum.any?(
             stale_escalations_report["errors"],
             &(&1["path"] == "$.policy_decision.escalations")
           )
  end

  test "verifies curated policy decision reference fixtures" do
    fixture_id = "fixture.artifact.policy_decision.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.policy_decision.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = policy_decision_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               policy_decision_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      policy_decision_fixture_observations()
      |> Map.put("classification", "approved")

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "classification" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "policy_decision.v1",
             report
           ) == Validation.artifact_observations("policy_decision.v1", report)

    assert {:ok, %{"schema_contract" => "policy_decision.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "policy_decision.v1"
             )

    stale_classification = Map.put(report, "classification", "auto_approvable")

    assert {:error, stale_classification_report} =
             Schema.validate_artifact(stale_classification,
               schema_contract: "policy_decision.v1"
             )

    assert Enum.any?(
             stale_classification_report["errors"],
             &(&1["path"] == "$.classification")
           )

    stale_approval_requirement_count = Map.put(report, "approval_requirement_count", 0)

    assert {:error, stale_approval_requirement_count_report} =
             Schema.validate_artifact(stale_approval_requirement_count,
               schema_contract: "policy_decision.v1"
             )

    assert Enum.any?(
             stale_approval_requirement_count_report["errors"],
             &(&1["path"] == "$.approval_requirement_count")
           )

    stale_risk_count = Map.put(report, "risk_count", 1)

    assert {:error, stale_risk_count_report} =
             Schema.validate_artifact(stale_risk_count,
               schema_contract: "policy_decision.v1"
             )

    assert Enum.any?(
             stale_risk_count_report["errors"],
             &(&1["path"] == "$.risk_count")
           )

    stale_escalation_rule_id =
      put_in(report, ["escalations", Access.at(0), "rule_id"], "other_rule")

    assert {:error, stale_escalation_rule_id_report} =
             Schema.validate_artifact(stale_escalation_rule_id,
               schema_contract: "policy_decision.v1"
             )

    assert Enum.any?(
             stale_escalation_rule_id_report["errors"],
             &(&1["path"] == "$.escalations")
           )

    stale_model_limits =
      Map.put(report, "model_limits", Enum.drop(Map.fetch!(report, "model_limits"), 1))

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits,
               schema_contract: "policy_decision.v1"
             )

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits")
           )
  end
end
