defmodule OrbitalDynamics.Validation.PolicyBundleFixtureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.Validation.PolicyBundleFixtures,
    only: [
      policy_bundle_fixture_observations: 0,
      policy_bundle_fixture: 0,
      ground_network_policy_bundle_fixture_observations: 0,
      ground_network_policy_bundle_fixture: 0,
      operator_review_queue_policy_bundle_fixture_observations: 0,
      operator_review_queue_policy_bundle_fixture: 0,
      command_contact_policy_bundle_fixture_observations: 0,
      command_contact_policy_bundle_fixture: 0,
      conservative_policy_bundle_fixture_observations: 0,
      conservative_policy_bundle_fixture: 0,
      contact_command_review_policy_bundle_fixture_observations: 0,
      contact_command_review_policy_bundle_fixture: 0,
      default_policy_bundle_fixture_observations: 0,
      default_policy_bundle_fixture: 0,
      degraded_payload_guard_policy_bundle_fixture_observations: 0,
      degraded_payload_guard_policy_bundle_fixture: 0,
      maneuver_authority_policy_bundle_fixture_observations: 0,
      maneuver_authority_policy_bundle_fixture: 0,
      resource_projection_authority_policy_bundle_fixture_observations: 0,
      resource_projection_authority_policy_bundle_fixture: 0,
      timeline_protection_policy_bundle_fixture_observations: 0,
      timeline_protection_policy_bundle_fixture: 0,
      organization_adapter_policy_bundle_fixture_observations: 0,
      organization_adapter_policy_bundle_fixture: 0
    ]

  alias OrbitalDynamics.{Schema, Validation}

  test "verifies curated policy bundle reference fixtures" do
    fixture_id = "fixture.artifact.policy_bundle.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.policy_bundle.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = policy_bundle_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               policy_bundle_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      policy_bundle_fixture_observations()
      |> Map.put("action_rule_count", 5)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "action_rule_count" and &1["status"] == "fail")
           )

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report, schema_contract: "policy_bundle.v1")

    first_rule_id = get_in(report, ["approval_policy", "action_rules", Access.at(0), "id"])

    stale_duplicate_rule_id =
      put_in(report, ["approval_policy", "action_rules", Access.at(1), "id"], first_rule_id)

    assert {:error, stale_duplicate_rule_id_report} =
             Schema.validate_artifact(stale_duplicate_rule_id,
               schema_contract: "policy_bundle.v1"
             )

    assert Enum.any?(
             stale_duplicate_rule_id_report["errors"],
             &(&1["path"] == "$.approval_policy.action_rules[1].id")
           )

    stale_provenance_bundle_id =
      put_in(report, ["provenance", "bundle_id"], "other_policy_bundle")

    assert {:error, stale_provenance_bundle_id_report} =
             Schema.validate_artifact(stale_provenance_bundle_id,
               schema_contract: "policy_bundle.v1"
             )

    assert Enum.any?(
             stale_provenance_bundle_id_report["errors"],
             &(&1["path"] == "$.provenance.bundle_id")
           )

    stale_authority_route =
      update_in(
        report,
        ["approval_policy", "action_rules", Access.at(0)],
        &Map.delete(&1, "required_authority")
      )

    assert {:error, stale_authority_route_report} =
             Schema.validate_artifact(stale_authority_route,
               schema_contract: "policy_bundle.v1"
             )

    assert Enum.any?(
             stale_authority_route_report["errors"],
             &(&1["path"] == "$.approval_policy.action_rules[0].required_authority")
           )

    stale_assumption_boundary =
      put_in(report, ["assumptions", "boundary"], "external_authority_lookup")

    assert {:error, stale_assumption_boundary_report} =
             Schema.validate_artifact(stale_assumption_boundary,
               schema_contract: "policy_bundle.v1"
             )

    assert Enum.any?(
             stale_assumption_boundary_report["errors"],
             &(&1["path"] == "$.assumptions.boundary")
           )

    stale_model_limits =
      Map.put(report, "model_limits", Enum.drop(Map.fetch!(report, "model_limits"), 1))

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits,
               schema_contract: "policy_bundle.v1"
             )

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "policy_bundle.v1",
             report
           ) == Validation.artifact_observations("policy_bundle.v1", report)
  end

  test "verifies curated ground-network policy bundle reference fixtures" do
    fixture_id = "fixture.artifact.policy_bundle.ground_network_allocation"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.policy_bundle.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = ground_network_policy_bundle_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               ground_network_policy_bundle_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      ground_network_policy_bundle_fixture_observations()
      |> Map.put("reduced_capacity_rule_count", 1)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "reduced_capacity_rule_count" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "policy_bundle.v1",
             report
           ) == Validation.artifact_observations("policy_bundle.v1", report)

    assert {:ok, _validated_report} =
             Schema.validate_artifact(report, schema_contract: "policy_bundle.v1")

    missing_classification =
      update_in(
        report,
        ["approval_policy", "action_rules", Access.at(0)],
        &Map.delete(&1, "classification")
      )

    assert {:error, missing_classification_report} =
             Schema.validate_artifact(missing_classification,
               schema_contract: "policy_bundle.v1"
             )

    assert Enum.any?(
             missing_classification_report["errors"],
             &(&1["path"] == "$.approval_policy.action_rules[0].classification")
           )

    missing_reason =
      update_in(
        report,
        ["approval_policy", "action_rules", Access.at(0)],
        &Map.delete(&1, "reason")
      )

    assert {:error, missing_reason_report} =
             Schema.validate_artifact(missing_reason,
               schema_contract: "policy_bundle.v1"
             )

    assert Enum.any?(
             missing_reason_report["errors"],
             &(&1["path"] == "$.approval_policy.action_rules[0].reason")
           )
  end

  test "verifies curated operator-review queue policy bundle reference fixtures" do
    fixture_id = "fixture.artifact.policy_bundle.operator_review_queue_authority"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.policy_bundle.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = operator_review_queue_policy_bundle_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               operator_review_queue_policy_bundle_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      operator_review_queue_policy_bundle_fixture_observations()
      |> Map.put("required_authority_counts", %{"mission_operations_authority" => 5})

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "required_authority_counts" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "policy_bundle.v1",
             report
           ) == Validation.artifact_observations("policy_bundle.v1", report)
  end

  test "verifies curated command/contact policy bundle reference fixtures" do
    fixture_id = "fixture.artifact.policy_bundle.command_contact_authority"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.policy_bundle.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = command_contact_policy_bundle_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               command_contact_policy_bundle_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      command_contact_policy_bundle_fixture_observations()
      |> Map.put("station_availability_rule_count", 1)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "station_availability_rule_count" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "policy_bundle.v1",
             report
           ) == Validation.artifact_observations("policy_bundle.v1", report)
  end

  test "verifies curated domain authority policy bundle reference fixtures" do
    fixtures = [
      {
        "fixture.artifact.policy_bundle.maneuver_authority",
        maneuver_authority_policy_bundle_fixture(),
        maneuver_authority_policy_bundle_fixture_observations(),
        "escalation_queue_counts",
        %{"mission_planning" => 4}
      },
      {
        "fixture.artifact.policy_bundle.resource_projection_authority",
        resource_projection_authority_policy_bundle_fixture(),
        resource_projection_authority_policy_bundle_fixture_observations(),
        "required_authority_counts",
        %{"resource_model_authority" => 7}
      },
      {
        "fixture.artifact.policy_bundle.timeline_protection",
        timeline_protection_policy_bundle_fixture(),
        timeline_protection_policy_bundle_fixture_observations(),
        "action_rule_count",
        8
      }
    ]

    for {fixture_id, report, observations, stale_field, stale_value} <- fixtures do
      assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

      assert fixture["model_id"] == "artifact.policy_bundle.v1"
      assert fixture["fixture_type"] == "curated_internal_artifact_regression"

      assert {:ok, verification} =
               Validation.verify_reference_fixture(fixture_id, observations)

      assert verification["status"] == "pass"
      assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

      stale_observations = Map.put(observations, stale_field, stale_value)

      assert {:ok, stale_verification} =
               Validation.verify_reference_fixture(fixture_id, stale_observations)

      assert stale_verification["status"] == "fail"

      assert Enum.any?(
               stale_verification["checks"],
               &(&1["field"] == stale_field and &1["status"] == "fail")
             )

      assert OrbitalDynamics.validation_artifact_observations(
               "policy_bundle.v1",
               report
             ) == Validation.artifact_observations("policy_bundle.v1", report)

      assert {:ok, _validated_report} =
               Schema.validate_artifact(report, schema_contract: "policy_bundle.v1")
    end
  end

  test "verifies curated remaining policy bundle variant reference fixtures" do
    fixtures = [
      {
        "fixture.artifact.policy_bundle.conservative_ops",
        conservative_policy_bundle_fixture(),
        conservative_policy_bundle_fixture_observations(),
        "blocked_risk_type_count",
        7
      },
      {
        "fixture.artifact.policy_bundle.contact_command_review",
        contact_command_review_policy_bundle_fixture(),
        contact_command_review_policy_bundle_fixture_observations(),
        "action_rule_count",
        2
      },
      {
        "fixture.artifact.policy_bundle.degraded_payload_guard",
        degraded_payload_guard_policy_bundle_fixture(),
        degraded_payload_guard_policy_bundle_fixture_observations(),
        "auto_approvable_approval_count_limit",
        1
      },
      {
        "fixture.artifact.policy_bundle.default",
        default_policy_bundle_fixture(),
        default_policy_bundle_fixture_observations(),
        "operator_review_risk_limit",
        2
      },
      {
        "fixture.artifact.policy_bundle.organization_adapter",
        organization_adapter_policy_bundle_fixture(),
        organization_adapter_policy_bundle_fixture_observations(),
        "workflow_execution",
        "external_workflow"
      }
    ]

    for {fixture_id, report, observations, stale_field, stale_value} <- fixtures do
      assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

      assert fixture["model_id"] == "artifact.policy_bundle.v1"
      assert fixture["fixture_type"] == "curated_internal_artifact_regression"

      assert {:ok, verification} =
               Validation.verify_reference_fixture(fixture_id, observations)

      assert verification["status"] == "pass"
      assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

      stale_observations = Map.put(observations, stale_field, stale_value)

      assert {:ok, stale_verification} =
               Validation.verify_reference_fixture(fixture_id, stale_observations)

      assert stale_verification["status"] == "fail"

      assert Enum.any?(
               stale_verification["checks"],
               &(&1["field"] == stale_field and &1["status"] == "fail")
             )

      assert OrbitalDynamics.validation_artifact_observations(
               "policy_bundle.v1",
               report
             ) == Validation.artifact_observations("policy_bundle.v1", report)
    end
  end
end
