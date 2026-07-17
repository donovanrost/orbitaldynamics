defmodule OrbitalDynamics.Validation.OperationalReadinessFixtureTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Schema, Validation}

  import OrbitalDynamics.Validation.OperationalReadinessFixtures,
    only: [
      operational_execution_boundary_summary_fixture: 0,
      operational_execution_boundary_summary_fixture_observations: 0,
      operational_import_eligibility_summary_fixture: 0,
      operational_import_eligibility_summary_fixture_observations: 0,
      operational_readiness_gate_summary_fixture: 0,
      operational_readiness_gate_summary_fixture_observations: 0,
      operational_readiness_report_fixture: 0,
      operational_readiness_report_fixture_observations: 0,
      operator_review_package_fixture: 0,
      operator_review_package_fixture_observations: 0
    ]

  test "verifies curated operator review package reference fixtures" do
    assert {:ok, fixture} =
             Validation.reference_fixture("fixture.artifact.operator_review_package.v1")

    assert fixture["model_id"] == "artifact.operator_review_package.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    assert {:ok, report} =
             Validation.verify_reference_fixture(
               "fixture.artifact.operator_review_package.v1",
               operator_review_package_fixture_observations()
             )

    assert report["status"] == "pass"
    assert Enum.all?(report["checks"], &(&1["status"] == "pass"))

    stale_row_derived_observations =
      operator_review_package_fixture_observations()
      |> put_in(["row_derived_review_type_counts", "timeline_diff_review"], 0)

    assert {:ok, stale_row_derived_report} =
             Validation.verify_reference_fixture(
               "fixture.artifact.operator_review_package.v1",
               stale_row_derived_observations
             )

    assert stale_row_derived_report["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_report["checks"],
             &(&1["field"] == "row_derived_review_type_counts" and &1["status"] == "fail")
           )

    package = operator_review_package_fixture()

    assert {:ok, _schema_report} =
             Schema.validate_artifact(package,
               schema_contract: "operator_review_package.v1"
             )

    stale_review_count = Map.put(package, "review_count", 7)

    assert {:error, stale_review_count_report} =
             Schema.validate_artifact(stale_review_count,
               schema_contract: "operator_review_package.v1"
             )

    assert Enum.any?(
             stale_review_count_report["errors"],
             &(&1["path"] == "$.review_count")
           )

    stale_review_type_counts =
      put_in(package, ["review_type_counts", "timeline_diff_review"], 0)

    assert {:error, stale_review_type_counts_report} =
             Schema.validate_artifact(stale_review_type_counts,
               schema_contract: "operator_review_package.v1"
             )

    assert Enum.any?(
             stale_review_type_counts_report["errors"],
             &(&1["path"] == "$.review_type_counts")
           )

    stale_review_queue_counts = Map.put(package, "review_queue_counts", %{})

    assert {:error, stale_review_queue_counts_report} =
             Schema.validate_artifact(stale_review_queue_counts,
               schema_contract: "operator_review_package.v1"
             )

    assert Enum.any?(
             stale_review_queue_counts_report["errors"],
             &(&1["path"] == "$.review_queue_counts")
           )

    stale_required_operator_action_counts =
      Map.put(package, "required_operator_action_counts", %{})

    assert {:error, stale_required_operator_action_counts_report} =
             Schema.validate_artifact(stale_required_operator_action_counts,
               schema_contract: "operator_review_package.v1"
             )

    assert Enum.any?(
             stale_required_operator_action_counts_report["errors"],
             &(&1["path"] == "$.required_operator_action_counts")
           )

    stale_model_limits =
      Map.put(package, "model_limits", Enum.drop(Map.fetch!(package, "model_limits"), 1))

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits,
               schema_contract: "operator_review_package.v1"
             )

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits")
           )

    stale_assumption_boundary =
      put_in(package, ["assumptions", "boundary"], "api_write_ready")

    assert {:error, stale_assumption_boundary_report} =
             Schema.validate_artifact(stale_assumption_boundary,
               schema_contract: "operator_review_package.v1"
             )

    assert Enum.any?(
             stale_assumption_boundary_report["errors"],
             &(&1["path"] == "$.assumptions.boundary")
           )
  end

  test "verifies curated operational readiness report reference fixtures" do
    assert {:ok, fixture} =
             Validation.reference_fixture("fixture.artifact.operational_readiness_report.v1")

    assert fixture["model_id"] == "artifact.operational_readiness_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = operational_readiness_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               "fixture.artifact.operational_readiness_report.v1",
               operational_readiness_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    observations = operational_readiness_report_fixture_observations()

    assert observations["row_derived_ready_for_import_count"] == 1
    assert observations["row_derived_import_status_counts"] == %{"ready_for_import" => 1}
    assert observations["row_derived_cadence_import_status_counts"] == %{"present" => 1}

    assert OrbitalDynamics.validation_artifact_observations(
             "operational_readiness_report.v1",
             report
           ) == Validation.artifact_observations("operational_readiness_report.v1", report)

    stale_row_derived_observations =
      operational_readiness_report_fixture_observations()
      |> put_in(["row_derived_gate_status_counts", "passed"], 4)

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(
               "fixture.artifact.operational_readiness_report.v1",
               stale_row_derived_observations
             )

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_gate_status_counts" and
                 &1["status"] == "fail")
           )

    stale_import_status_observations =
      observations
      |> put_in(["row_derived_import_status_counts", "ready_for_import"], 0)

    assert {:ok, stale_import_status_verification} =
             Validation.verify_reference_fixture(
               "fixture.artifact.operational_readiness_report.v1",
               stale_import_status_observations
             )

    assert stale_import_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_import_status_verification["checks"],
             &(&1["field"] == "row_derived_import_status_counts" and
                 &1["status"] == "fail")
           )

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report,
               schema_contract: "operational_readiness_report.v1"
             )

    stale_model = Map.put(report, "model", "stale_operational_readiness_model")

    assert {:error, stale_model_report} =
             Schema.validate_artifact(stale_model,
               schema_contract: "operational_readiness_report.v1"
             )

    assert Enum.any?(
             stale_model_report["errors"],
             &(&1["path"] == "$.model" and
                 &1["message"] ==
                   "must equal \"artifact_only_operational_readiness_classifier\"")
           )

    stale_import_classification = Map.put(report, "import_classification", "review_only")

    assert {:error, stale_import_classification_report} =
             Schema.validate_artifact(stale_import_classification,
               schema_contract: "operational_readiness_report.v1"
             )

    assert Enum.any?(
             stale_import_classification_report["errors"],
             &(&1["path"] == "$.import_classification")
           )

    stale_readiness_level = Map.put(report, "readiness_level", "operator_review")

    assert {:error, stale_readiness_level_report} =
             Schema.validate_artifact(stale_readiness_level,
               schema_contract: "operational_readiness_report.v1"
             )

    assert Enum.any?(
             stale_readiness_level_report["errors"],
             &(&1["path"] == "$.readiness_level")
           )

    stale_gate_count = Map.put(report, "gate_count", 4)

    assert {:error, stale_gate_count_report} =
             Schema.validate_artifact(stale_gate_count,
               schema_contract: "operational_readiness_report.v1"
             )

    assert Enum.any?(
             stale_gate_count_report["errors"],
             &(&1["path"] == "$.gate_count")
           )

    stale_passed_gate_count = Map.put(report, "passed_gate_count", 4)

    assert {:error, stale_passed_gate_count_report} =
             Schema.validate_artifact(stale_passed_gate_count,
               schema_contract: "operational_readiness_report.v1"
             )

    assert Enum.any?(
             stale_passed_gate_count_report["errors"],
             &(&1["path"] == "$.passed_gate_count")
           )

    stale_evidence_count = put_in(report, ["evidence", "ready_for_import_count"], 0)

    assert {:error, stale_evidence_count_report} =
             Schema.validate_artifact(stale_evidence_count,
               schema_contract: "operational_readiness_report.v1"
             )

    assert Enum.any?(
             stale_evidence_count_report["errors"],
             &(&1["path"] == "$.evidence.ready_for_import_count")
           )

    stale_evidence_map = put_in(report, ["evidence", "import_status_counts"], %{})

    assert {:error, stale_evidence_map_report} =
             Schema.validate_artifact(stale_evidence_map,
               schema_contract: "operational_readiness_report.v1"
             )

    assert Enum.any?(
             stale_evidence_map_report["errors"],
             &(&1["path"] == "$.evidence.import_status_counts")
           )

    stale_model_limits =
      Map.put(report, "model_limits", Enum.drop(Map.fetch!(report, "model_limits"), 1))

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits,
               schema_contract: "operational_readiness_report.v1"
             )

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits")
           )

    stale_assumptions =
      Map.put(
        report,
        "assumptions",
        List.replace_at(Map.fetch!(report, "assumptions"), 1, "external_import_write_ready")
      )

    assert {:error, stale_assumptions_report} =
             Schema.validate_artifact(stale_assumptions,
               schema_contract: "operational_readiness_report.v1"
             )

    assert Enum.any?(
             stale_assumptions_report["errors"],
             &(&1["path"] == "$.assumptions")
           )
  end

  test "verifies curated operational execution boundary summary reference fixtures" do
    fixture_id = "fixture.artifact.operational_execution_boundary_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.operational_execution_boundary_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = operational_execution_boundary_summary_fixture()
    observations = operational_execution_boundary_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["import_eligible"] == true
    assert observations["handoff_only"] == true
    assert observations["execution_allowed"] == false
    assert observations["cadence_write_allowed"] == false
    assert observations["operator_authority_granted"] == false
    assert observations["execution_boundary"] == "adapter_handoff_only"

    assert observations["assumption_execution_boundary"] ==
             "artifact_only_no_cadence_write_no_command_execution"

    assert observations["operator_authority"] == "not_granted_by_execution_boundary_summary"
    assert observations["cadence_write"] == "not_performed_by_summary"
    assert observations["command_execution"] == "not_performed_by_summary"
    assert observations["operational_mode_gate_id"] == "operational_mode"
    assert observations["operational_mode_gate_status"] == "passed"
    assert observations["gate_count"] == 5

    assert OrbitalDynamics.validation_artifact_observations(
             "operational_execution_boundary_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "operational_execution_boundary_summary.v1",
               report
             )

    stale_execution_observations = Map.put(observations, "execution_allowed", true)

    assert {:ok, stale_execution_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_execution_observations)

    assert stale_execution_verification["status"] == "fail"

    assert Enum.any?(
             stale_execution_verification["checks"],
             &(&1["field"] == "execution_allowed" and &1["status"] == "fail")
           )

    stale_boundary_observations =
      Map.put(observations, "execution_boundary", "ready_for_command_execution")

    assert {:ok, stale_boundary_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_boundary_observations)

    assert stale_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_boundary_verification["checks"],
             &(&1["field"] == "execution_boundary" and &1["status"] == "fail")
           )

    stale_assumption_observations =
      Map.put(observations, "command_execution", "performed_by_summary")

    assert {:ok, stale_assumption_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_assumption_observations)

    assert stale_assumption_verification["status"] == "fail"

    assert Enum.any?(
             stale_assumption_verification["checks"],
             &(&1["field"] == "command_execution" and &1["status"] == "fail")
           )

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report,
               schema_contract: "operational_execution_boundary_summary.v1"
             )
  end

  test "verifies curated operational import eligibility summary reference fixtures" do
    fixture_id = "fixture.artifact.operational_import_eligibility_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.operational_import_eligibility_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = operational_import_eligibility_summary_fixture()
    observations = operational_import_eligibility_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["import_eligible"] == true
    assert observations["import_classification"] == "importable"
    assert observations["readiness_level"] == "import_eligible"
    assert observations["status"] == "passed"
    assert observations["gate_count"] == 5
    assert observations["passed_gate_count"] == 5
    assert observations["row_derived_non_passed_gate_count"] == 0
    assert observations["execution_boundary"] == "artifact_only_no_cadence_write"
    assert observations["operator_authority"] == "not_granted_by_summary"

    assert OrbitalDynamics.validation_artifact_observations(
             "operational_import_eligibility_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "operational_import_eligibility_summary.v1",
               report
             )

    stale_eligible_observations = Map.put(observations, "import_eligible", false)

    assert {:ok, stale_eligible_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_eligible_observations)

    assert stale_eligible_verification["status"] == "fail"

    assert Enum.any?(
             stale_eligible_verification["checks"],
             &(&1["field"] == "import_eligible" and &1["status"] == "fail")
           )

    stale_count_observations = Map.put(observations, "gate_count", 4)

    assert {:ok, stale_count_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_count_observations)

    assert stale_count_verification["status"] == "fail"

    assert Enum.any?(
             stale_count_verification["checks"],
             &(&1["field"] == "gate_count" and &1["status"] == "fail")
           )

    stale_boundary_observations =
      Map.put(observations, "execution_boundary", "cadence_write_ready")

    assert {:ok, stale_boundary_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_boundary_observations)

    assert stale_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_boundary_verification["checks"],
             &(&1["field"] == "execution_boundary" and &1["status"] == "fail")
           )

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report,
               schema_contract: "operational_import_eligibility_summary.v1"
             )
  end

  test "verifies curated operational readiness gate summary reference fixtures" do
    fixture_id = "fixture.artifact.operational_readiness_gate_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.operational_readiness_gate_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = operational_readiness_gate_summary_fixture()
    observations = operational_readiness_gate_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["gate_count"] == 5
    assert observations["row_derived_gate_count"] == 5
    assert observations["gate_status_counts"] == %{"passed" => 5}
    assert observations["row_derived_gate_status_counts"] == %{"passed" => 5}
    assert observations["gate_classification_counts"] == %{"importable" => 5}

    assert observations["row_derived_gate_ids_by_status"] == %{
             "passed" => [
               "adapter_boundary",
               "cadence_import",
               "operational_mode",
               "operator_review",
               "source_contract"
             ]
           }

    assert observations["passed_gate_keys"] ==
             "source_contract|operational_mode|adapter_boundary|operator_review|cadence_import"

    assert observations["non_passed_gate_keys"] == ""
    assert observations["execution_boundary"] == "artifact_only_no_cadence_write"
    assert observations["operator_authority"] == "not_granted_by_summary"

    assert OrbitalDynamics.validation_artifact_observations(
             "operational_readiness_gate_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "operational_readiness_gate_summary.v1",
               report
             )

    stale_status_observations =
      Map.put(observations, "row_derived_gate_status_counts", %{"passed" => 4})

    assert {:ok, stale_status_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_status_observations)

    assert stale_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_status_verification["checks"],
             &(&1["field"] == "row_derived_gate_status_counts" and
                 &1["status"] == "fail")
           )

    stale_routing_observations =
      put_in(observations, ["row_derived_gate_ids_by_status", "passed"], ["source_contract"])

    assert {:ok, stale_routing_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_routing_observations)

    assert stale_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_routing_verification["checks"],
             &(&1["field"] == "row_derived_gate_ids_by_status" and &1["status"] == "fail")
           )

    stale_boundary_observations = Map.put(observations, "operator_authority", "granted")

    assert {:ok, stale_boundary_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_boundary_observations)

    assert stale_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_boundary_verification["checks"],
             &(&1["field"] == "operator_authority" and &1["status"] == "fail")
           )

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report,
               schema_contract: "operational_readiness_gate_summary.v1"
             )
  end
end
