defmodule OrbitalDynamics.Validation.QualityGateFixtureTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema, Validation}

  import OrbitalDynamics.Validation.QualityGateFixtures,
    only: [
      operational_quality_gate_import_readiness_summary_fixture: 0,
      operational_quality_gate_import_readiness_summary_fixture_observations: 0,
      operational_quality_gate_operator_training_summary_fixture: 0,
      operational_quality_gate_operator_training_summary_fixture_observations: 0,
      operational_quality_gate_schema_validation_summary_fixture: 0,
      operational_quality_gate_schema_validation_summary_fixture_observations: 0,
      operational_quality_gate_summary_fixture: 0,
      operational_quality_gate_summary_fixture_observations: 0,
      operational_quality_gate_unavailable_resource_summary_checked_in_fixture: 0,
      operational_quality_gate_unavailable_resource_summary_checked_in_observations: 0,
      operational_quality_gate_unavailable_resource_summary_fixture: 0,
      operational_quality_gate_unavailable_resource_summary_fixture_observations: 0,
      quality_gate_report_fixture: 0,
      quality_gate_report_fixture_observations: 0
    ]

  test "verifies curated quality gate report reference fixtures" do
    fixture_id = "fixture.artifact.quality_gate_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.quality_gate_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = quality_gate_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               quality_gate_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    observations = quality_gate_report_fixture_observations()

    assert observations["row_derived_ready_for_import_count"] == 1
    assert observations["row_derived_import_status_counts"] == %{"ready_for_import" => 1}
    assert observations["row_derived_cadence_import_status_counts"] == %{"present" => 1}

    assert OrbitalDynamics.validation_artifact_observations("quality_gate_report.v1", report) ==
             Validation.artifact_observations("quality_gate_report.v1", report)

    stale_row_derived_observations =
      quality_gate_report_fixture_observations()
      |> put_in(["row_derived_gate_ids_by_status", "passed"], ["source_contract"])

    assert {:ok, stale_row_derived_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_observations)

    assert stale_row_derived_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_verification["checks"],
             &(&1["field"] == "row_derived_gate_ids_by_status" and &1["status"] == "fail")
           )

    stale_import_status_observations =
      observations
      |> put_in(["row_derived_cadence_import_status_counts", "present"], 0)

    assert {:ok, stale_import_status_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_import_status_observations)

    assert stale_import_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_import_status_verification["checks"],
             &(&1["field"] == "row_derived_cadence_import_status_counts" and
                 &1["status"] == "fail")
           )

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report,
               schema_contract: "quality_gate_report.v1"
             )

    stale_import_classification = Map.put(report, "import_classification", "review_only")

    assert {:error, stale_import_classification_report} =
             Schema.validate_artifact(stale_import_classification,
               schema_contract: "quality_gate_report.v1"
             )

    assert Enum.any?(
             stale_import_classification_report["errors"],
             &(&1["path"] == "$.import_classification")
           )

    stale_gate_count = Map.put(report, "gate_count", 4)

    assert {:error, stale_gate_count_report} =
             Schema.validate_artifact(stale_gate_count,
               schema_contract: "quality_gate_report.v1"
             )

    assert Enum.any?(
             stale_gate_count_report["errors"],
             &(&1["path"] == "$.gate_count")
           )

    stale_gate_status_counts = Map.put(report, "gate_status_counts", %{"passed" => 4})

    assert {:error, stale_gate_status_counts_report} =
             Schema.validate_artifact(stale_gate_status_counts,
               schema_contract: "quality_gate_report.v1"
             )

    assert Enum.any?(
             stale_gate_status_counts_report["errors"],
             &(&1["path"] == "$.gate_status_counts")
           )

    stale_gate_ids_by_status =
      put_in(report, ["gate_ids_by_status", "passed"], ["source_contract"])

    assert {:error, stale_gate_ids_by_status_report} =
             Schema.validate_artifact(stale_gate_ids_by_status,
               schema_contract: "quality_gate_report.v1"
             )

    assert Enum.any?(
             stale_gate_ids_by_status_report["errors"],
             &(&1["path"] == "$.gate_ids_by_status")
           )

    stale_model_limits =
      Map.put(report, "model_limits", Enum.drop(Map.fetch!(report, "model_limits"), 1))

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits,
               schema_contract: "quality_gate_report.v1"
             )

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits")
           )

    stale_execution_boundary =
      put_in(report, ["assumptions", "execution_boundary"], "cadence_write_ready")

    assert {:error, stale_execution_boundary_report} =
             Schema.validate_artifact(stale_execution_boundary,
               schema_contract: "quality_gate_report.v1"
             )

    assert Enum.any?(
             stale_execution_boundary_report["errors"],
             &(&1["path"] == "$.assumptions.execution_boundary")
           )
  end

  test "verifies curated operational quality gate summary reference fixtures" do
    fixture_id = "fixture.artifact.operational_quality_gate_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.operational_quality_gate_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = operational_quality_gate_summary_fixture()
    observations = operational_quality_gate_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["review_gate_count"] == 3
    assert observations["row_derived_review_gate_count"] == 3
    assert observations["non_passed_gate_count"] == 3

    assert observations["row_derived_non_passed_gate_keys"] ==
             "cadence_import|operator_review|resource_availability"

    assert observations["row_derived_non_passed_quality_gate_row_keys"] ==
             "quality_gate:resource_projection_report.v1:resource_summaries:cadence_import:6|quality_gate:resource_projection_report.v1:resource_summaries:operator_review:5|quality_gate:resource_projection_report.v1:resource_summaries:resource_availability:4"

    assert OrbitalDynamics.validation_artifact_observations(
             "operational_quality_gate_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "operational_quality_gate_summary.v1",
               report
             )

    stale_review_count_observations = Map.put(observations, "row_derived_review_gate_count", 0)

    assert {:ok, stale_review_count_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_review_count_observations)

    assert stale_review_count_verification["status"] == "fail"

    assert Enum.any?(
             stale_review_count_verification["checks"],
             &(&1["field"] == "row_derived_review_gate_count" and &1["status"] == "fail")
           )

    stale_non_passed_routing_observations =
      Map.put(observations, "row_derived_non_passed_gate_keys", "cadence_import")

    assert {:ok, stale_non_passed_routing_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_non_passed_routing_observations
             )

    assert stale_non_passed_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_non_passed_routing_verification["checks"],
             &(&1["field"] == "row_derived_non_passed_gate_keys" and &1["status"] == "fail")
           )

    stale_non_passed_row_routing_observations =
      Map.put(
        observations,
        "row_derived_non_passed_quality_gate_row_keys",
        "quality_gate:resource_projection_report.v1:resource_summaries:cadence_import:6"
      )

    assert {:ok, stale_non_passed_row_routing_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_non_passed_row_routing_observations
             )

    assert stale_non_passed_row_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_non_passed_row_routing_verification["checks"],
             &(&1["field"] == "row_derived_non_passed_quality_gate_row_keys" and
                 &1["status"] == "fail")
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
               schema_contract: "operational_quality_gate_summary.v1"
             )
  end

  test "verifies curated operational quality gate import readiness summary reference fixtures" do
    fixture_id = "fixture.artifact.operational_quality_gate_import_readiness_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.operational_quality_gate_import_readiness_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = operational_quality_gate_import_readiness_summary_fixture()
    observations = operational_quality_gate_import_readiness_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["ready_for_import_count"] == 1
    assert observations["row_derived_ready_for_import_count"] == 1
    assert observations["stale_freshness_count"] == 1
    assert observations["row_derived_stale_freshness_count"] == 1
    assert observations["cadence_import_status_counts"] == %{"present" => 1}
    assert observations["freshness_review_required"] == true
    assert observations["import_blocked"] == false

    assert OrbitalDynamics.validation_artifact_observations(
             "operational_quality_gate_import_readiness_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "operational_quality_gate_import_readiness_summary.v1",
               report
             )

    stale_ready_observations = Map.put(observations, "ready_for_import_count", 0)

    assert {:ok, stale_ready_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_ready_observations)

    assert stale_ready_verification["status"] == "fail"

    assert Enum.any?(
             stale_ready_verification["checks"],
             &(&1["field"] == "ready_for_import_count" and &1["status"] == "fail")
           )

    stale_row_derived_freshness_observations =
      Map.put(observations, "row_derived_stale_freshness_count", 0)

    assert {:ok, stale_row_derived_freshness_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_row_derived_freshness_observations
             )

    assert stale_row_derived_freshness_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_freshness_verification["checks"],
             &(&1["field"] == "row_derived_stale_freshness_count" and
                 &1["status"] == "fail")
           )

    stale_cadence_status_observations =
      Map.put(observations, "row_derived_cadence_import_present_count", 0)

    assert {:ok, stale_cadence_status_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_cadence_status_observations)

    assert stale_cadence_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_cadence_status_verification["checks"],
             &(&1["field"] == "row_derived_cadence_import_present_count" and
                 &1["status"] == "fail")
           )

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report,
               schema_contract: "operational_quality_gate_import_readiness_summary.v1"
             )
  end

  test "verifies curated operational quality gate unavailable-resource summary reference fixtures" do
    fixture_id = "fixture.artifact.operational_quality_gate_unavailable_resource_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] ==
             "artifact.operational_quality_gate_unavailable_resource_summary.v1"

    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = operational_quality_gate_unavailable_resource_summary_fixture()
    observations = operational_quality_gate_unavailable_resource_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_reason_count_observations =
      observations
      |> put_in(["unavailable_resource_reason_counts", "antenna_unavailable"], 0)

    assert {:ok, stale_reason_count_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_reason_count_observations)

    assert stale_reason_count_verification["status"] == "fail"

    assert Enum.any?(
             stale_reason_count_verification["checks"],
             &(&1["field"] == "unavailable_resource_reason_counts" and
                 &1["status"] == "fail")
           )

    stale_contact_routing_observations =
      observations
      |> put_in(["blocked_contact_ids_by_blocking_dimension", "antenna"], [])

    assert {:ok, stale_contact_routing_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_contact_routing_observations)

    assert stale_contact_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_contact_routing_verification["checks"],
             &(&1["field"] == "blocked_contact_ids_by_blocking_dimension" and
                 &1["status"] == "fail")
           )

    stale_row_status_observations =
      observations
      |> Map.put("row_derived_review_required_quality_gate_row_count", 0)

    assert {:ok, stale_row_status_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_status_observations)

    assert stale_row_status_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_status_verification["checks"],
             &(&1["field"] == "row_derived_review_required_quality_gate_row_count" and
                 &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "operational_quality_gate_unavailable_resource_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "operational_quality_gate_unavailable_resource_summary.v1",
               report
             )

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report,
               schema_contract: "operational_quality_gate_unavailable_resource_summary.v1"
             )
  end

  test "verifies checked-in operational quality gate unavailable-resource summary reference fixture" do
    fixture_id =
      "fixture.artifact.operational_quality_gate_unavailable_resource_summary.resource_projection_v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] ==
             "artifact.operational_quality_gate_unavailable_resource_summary.v1"

    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    assert fixture["inputs"]["artifact_path"] ==
             "study_results/operational_quality_gate_unavailable_resource_summary_v1.json"

    report = operational_quality_gate_unavailable_resource_summary_checked_in_fixture()
    observations = operational_quality_gate_unavailable_resource_summary_checked_in_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["source_artifact_type"] == "resource_projection_report.v1"
    assert observations["unavailable_resource_pressure_count"] == 2
    assert observations["row_derived_unavailable_resource_pressure_count"] == 2

    assert observations["unavailable_resource_reason_counts"] == %{
             "antenna_unavailable" => 1,
             "payload_unavailable" => 1
           }

    assert observations["unavailable_resource_reason_keys"] ==
             "antenna_unavailable|payload_unavailable"

    assert observations["blocked_contact_ids_by_blocking_dimension"] == %{}

    assert observations["quality_gate_row_ids_by_status"] == %{
             "review_required" => [
               "quality_gate:resource_projection_report.v1:resource_summaries:resource_availability:4"
             ]
           }

    assert observations["execution_boundary"] == "artifact_only_no_cadence_write"
    assert observations["operator_authority"] == "not_granted_by_unavailable_resource_summary"

    stale_pressure_observations =
      observations
      |> Map.put("row_derived_unavailable_resource_pressure_count", 1)

    assert {:ok, stale_pressure_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_pressure_observations)

    assert stale_pressure_verification["status"] == "fail"

    assert Enum.any?(
             stale_pressure_verification["checks"],
             &(&1["field"] == "row_derived_unavailable_resource_pressure_count" and
                 &1["status"] == "fail")
           )

    stale_reason_observations =
      observations
      |> put_in(["unavailable_resource_reason_counts", "payload_unavailable"], 0)

    assert {:ok, stale_reason_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_reason_observations)

    assert stale_reason_verification["status"] == "fail"

    assert Enum.any?(
             stale_reason_verification["checks"],
             &(&1["field"] == "unavailable_resource_reason_counts" and
                 &1["status"] == "fail")
           )

    stale_quality_gate_routing_observations =
      observations
      |> put_in(["quality_gate_row_ids_by_status", "review_required"], [])

    assert {:ok, stale_quality_gate_routing_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_quality_gate_routing_observations
             )

    assert stale_quality_gate_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_quality_gate_routing_verification["checks"],
             &(&1["field"] == "quality_gate_row_ids_by_status" and &1["status"] == "fail")
           )

    stale_boundary_observations =
      observations
      |> Map.put("execution_boundary", "cadence_write_ready")

    assert {:ok, stale_boundary_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_boundary_observations)

    assert stale_boundary_verification["status"] == "fail"

    assert Enum.any?(
             stale_boundary_verification["checks"],
             &(&1["field"] == "execution_boundary" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "operational_quality_gate_unavailable_resource_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "operational_quality_gate_unavailable_resource_summary.v1",
               report
             )

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report,
               schema_contract: "operational_quality_gate_unavailable_resource_summary.v1"
             )
  end

  test "verifies curated operational quality gate schema validation summary reference fixtures" do
    fixture_id = "fixture.artifact.operational_quality_gate_schema_validation_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.operational_quality_gate_schema_validation_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = operational_quality_gate_schema_validation_summary_fixture()
    observations = operational_quality_gate_schema_validation_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["schema_validation_fail_count"] == 1
    assert observations["row_derived_schema_validation_fail_count"] == 1
    assert observations["schema_validation_error_count"] == 1
    assert observations["schema_validation_remediation_count"] == 1
    assert observations["schema_validation_import_blocked"] == true
    assert observations["row_derived_blocked_quality_gate_row_count"] == 1
    assert observations["row_derived_failed_schema_validation_quality_gate_row_count"] == 1

    assert OrbitalDynamics.validation_artifact_observations(
             "operational_quality_gate_schema_validation_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "operational_quality_gate_schema_validation_summary.v1",
               report
             )

    stale_fail_count_observations = Map.put(observations, "schema_validation_fail_count", 0)

    assert {:ok, stale_fail_count_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_fail_count_observations)

    assert stale_fail_count_verification["status"] == "fail"

    assert Enum.any?(
             stale_fail_count_verification["checks"],
             &(&1["field"] == "schema_validation_fail_count" and &1["status"] == "fail")
           )

    stale_row_derived_fail_observations =
      Map.put(observations, "row_derived_schema_validation_fail_count", 0)

    assert {:ok, stale_row_derived_fail_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_row_derived_fail_observations)

    assert stale_row_derived_fail_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_fail_verification["checks"],
             &(&1["field"] == "row_derived_schema_validation_fail_count" and
                 &1["status"] == "fail")
           )

    stale_blocked_row_observations =
      Map.put(observations, "row_derived_blocked_quality_gate_row_count", 0)

    assert {:ok, stale_blocked_row_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_blocked_row_observations)

    assert stale_blocked_row_verification["status"] == "fail"

    assert Enum.any?(
             stale_blocked_row_verification["checks"],
             &(&1["field"] == "row_derived_blocked_quality_gate_row_count" and
                 &1["status"] == "fail")
           )

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report,
               schema_contract: "operational_quality_gate_schema_validation_summary.v1"
             )
  end

  test "verifies curated operational quality gate operator training summary reference fixtures" do
    fixture_id = "fixture.artifact.operational_quality_gate_operator_training_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.operational_quality_gate_operator_training_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = operational_quality_gate_operator_training_summary_fixture()
    observations = operational_quality_gate_operator_training_summary_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["operator_training_requirement_count"] == 5
    assert observations["row_derived_operator_training_requirement_count"] == 5

    assert observations["operator_training_requirement_counts"] == %{
             "certification" => 1,
             "operator_role" => 2,
             "qualification" => 1,
             "training" => 1
           }

    assert observations["required_operator_role_keys"] == "contact_operator|mission_director"
    assert observations["required_training_keys"] == "contact_replan_drill"
    assert observations["required_certification_keys"] == "cadence_import_cert"
    assert observations["required_qualification_keys"] == "sat_ops_current"
    assert observations["operator_training_review_required"] == true
    assert observations["row_derived_review_required_quality_gate_row_count"] == 1
    assert observations["row_derived_review_only_quality_gate_row_count"] == 1

    assert OrbitalDynamics.validation_artifact_observations(
             "operational_quality_gate_operator_training_summary.v1",
             report
           ) ==
             Validation.artifact_observations(
               "operational_quality_gate_operator_training_summary.v1",
               report
             )

    stale_requirement_count_observations =
      Map.put(observations, "operator_training_requirement_count", 4)

    assert {:ok, stale_requirement_count_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_requirement_count_observations)

    assert stale_requirement_count_verification["status"] == "fail"

    assert Enum.any?(
             stale_requirement_count_verification["checks"],
             &(&1["field"] == "operator_training_requirement_count" and
                 &1["status"] == "fail")
           )

    stale_row_derived_requirement_observations =
      Map.put(observations, "row_derived_operator_training_requirement_count", 4)

    assert {:ok, stale_row_derived_requirement_verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_row_derived_requirement_observations
             )

    assert stale_row_derived_requirement_verification["status"] == "fail"

    assert Enum.any?(
             stale_row_derived_requirement_verification["checks"],
             &(&1["field"] == "row_derived_operator_training_requirement_count" and
                 &1["status"] == "fail")
           )

    stale_role_routing_observations =
      Map.put(observations, "required_operator_role_keys", "contact_operator")

    assert {:ok, stale_role_routing_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_role_routing_observations)

    assert stale_role_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_role_routing_verification["checks"],
             &(&1["field"] == "required_operator_role_keys" and &1["status"] == "fail")
           )

    stale_training_routing_observations =
      Map.put(observations, "required_training_keys", "")

    assert {:ok, stale_training_routing_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_training_routing_observations)

    assert stale_training_routing_verification["status"] == "fail"

    assert Enum.any?(
             stale_training_routing_verification["checks"],
             &(&1["field"] == "required_training_keys" and &1["status"] == "fail")
           )

    stale_review_row_observations =
      Map.put(observations, "row_derived_review_required_quality_gate_row_count", 0)

    assert {:ok, stale_review_row_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_review_row_observations)

    assert stale_review_row_verification["status"] == "fail"

    assert Enum.any?(
             stale_review_row_verification["checks"],
             &(&1["field"] == "row_derived_review_required_quality_gate_row_count" and
                 &1["status"] == "fail")
           )

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report,
               schema_contract: "operational_quality_gate_operator_training_summary.v1"
             )
  end

  test "rejects stale copied readiness and quality source reports from challenge fixtures" do
    readiness_review = read_json!("study_results/operator_review_resource_pressure_v1.json")
    readiness_import = read_json!("study_results/cadence_import_resource_pressure_v1.json")
    quality_gate = read_json!("study_results/quality_gate_resource_pressure_v1.json")
    quality_review = OperatorReview.from_quality_gate_report(quality_gate)
    quality_import = CadenceImport.from_quality_gate_report(quality_gate)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(readiness_review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(readiness_import)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(quality_review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(quality_import)

    stale_readiness_review =
      put_in(
        readiness_review,
        ["rows", Access.at(0), "source_operational_readiness_report", "status"],
        "passed"
      )

    assert {:error, stale_readiness_review_report} =
             Schema.validate_artifact(stale_readiness_review)

    assert Enum.any?(
             stale_readiness_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_operational_readiness_report.status" and
                 &1["message"] == "must match operational_readiness_status on handoff row")
           )

    stale_readiness_import =
      put_in(
        readiness_import,
        ["rows", Access.at(0), "source_operational_readiness_report", "readiness_level"],
        "blocked"
      )

    assert {:error, stale_readiness_import_report} =
             Schema.validate_artifact(stale_readiness_import)

    assert Enum.any?(
             stale_readiness_import_report["errors"],
             &(&1["path"] == "$.rows[0].source_operational_readiness_report.readiness_level" and
                 &1["message"] == "must match readiness_level on handoff row")
           )

    stale_quality_review =
      put_in(
        quality_review,
        ["rows", Access.at(0), "source_quality_gate_report", "readiness_level"],
        "blocked"
      )

    assert {:error, stale_quality_review_report} =
             Schema.validate_artifact(stale_quality_review)

    assert Enum.any?(
             stale_quality_review_report["errors"],
             &(&1["path"] == "$.rows[0].source_quality_gate_report.readiness_level" and
                 &1["message"] == "must match readiness_level on handoff row")
           )

    stale_quality_import =
      put_in(
        quality_import,
        ["rows", Access.at(0), "source_quality_gate_report", "report_id"],
        "quality_gate:wrong_report"
      )

    assert {:error, stale_quality_import_report} =
             Schema.validate_artifact(stale_quality_import)

    assert Enum.any?(
             stale_quality_import_report["errors"],
             &(&1["path"] == "$.rows[0].source_quality_gate_report.report_id" and
                 &1["message"] == "must match quality_gate_report_id on handoff row")
           )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
