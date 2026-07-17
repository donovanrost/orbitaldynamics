defmodule OrbitalDynamics.Validation.ModelAcceptanceFixtureTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Schema, Validation}

  import OrbitalDynamics.Validation.ModelAcceptanceFixtures,
    only: [
      model_acceptance_report_fixture: 0,
      model_acceptance_report_fixture_observations: 0,
      validation_safety_case_summary_fixture: 0,
      validation_safety_case_summary_fixture_observations: 0
    ]

  test "verifies curated model acceptance report reference fixtures" do
    fixture_id = "fixture.artifact.model_acceptance_report.operational_import"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.model_acceptance_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = model_acceptance_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               model_acceptance_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert verification["status_counts"] == %{"pass" => 16}

    assert OrbitalDynamics.validation_artifact_observations(
             "model_acceptance_report.v1",
             report
           ) == Validation.artifact_observations("model_acceptance_report.v1", report)

    assert {:ok, _schema_report} =
             Schema.validate_artifact(report,
               schema_contract: "model_acceptance_report.v1"
             )

    assert report["status_counts"] == %{
             "accepted" => 1,
             "blocked" => 2,
             "review_required" => 1
           }

    observations = model_acceptance_report_fixture_observations()

    assert observations["model_ids_by_status"] == %{
             "accepted" => ["orbit_data.simple_json"],
             "blocked" => ["propagator.two_body", "missing.model"],
             "review_required" => ["event.access_windows"]
           }

    assert observations["model_ids_by_validation_level"] == %{
             "analysis" => ["event.access_windows"],
             "artifact_contract" => ["orbit_data.simple_json"],
             "educational" => ["propagator.two_body"],
             "unknown" => ["missing.model"]
           }

    assert observations["model_ids_by_intended_use"] == %{
             "operational_import" => [
               "orbit_data.simple_json",
               "event.access_windows",
               "propagator.two_body",
               "missing.model"
             ]
           }

    stale_observed_model_ids_by_status =
      put_in(observations, ["model_ids_by_status", "blocked"], ["missing.model"])

    assert {:ok, stale_observed_model_ids_by_status_report} =
             Validation.verify_reference_fixture(fixture_id, stale_observed_model_ids_by_status)

    assert stale_observed_model_ids_by_status_report["status"] == "fail"

    assert Enum.any?(
             stale_observed_model_ids_by_status_report["checks"],
             &(&1["field"] == "model_ids_by_status" and &1["status"] == "fail")
           )

    stale_status = Map.put(report, "status", "accepted_for_use")

    assert {:error, stale_status_report} =
             Schema.validate_artifact(stale_status,
               schema_contract: "model_acceptance_report.v1"
             )

    assert Enum.any?(
             stale_status_report["errors"],
             &(&1["path"] == "$.status")
           )

    stale_validation_level_counts =
      put_in(report, ["validation_level_counts", "unknown"], 0)

    assert {:error, stale_validation_level_counts_report} =
             Schema.validate_artifact(stale_validation_level_counts,
               schema_contract: "model_acceptance_report.v1"
             )

    assert Enum.any?(
             stale_validation_level_counts_report["errors"],
             &(&1["path"] == "$.validation_level_counts")
           )

    stale_status_counts = put_in(report, ["status_counts", "blocked"], 1)

    assert {:error, stale_status_counts_report} =
             Schema.validate_artifact(stale_status_counts,
               schema_contract: "model_acceptance_report.v1"
             )

    assert Enum.any?(
             stale_status_counts_report["errors"],
             &(&1["path"] == "$.status_counts" and
                 &1["message"] == "must match row-derived status_counts")
           )

    stale_model_ids_by_validation_level =
      put_in(report, ["model_ids_by_validation_level", "unknown"], [])

    assert {:error, stale_model_ids_by_validation_level_report} =
             Schema.validate_artifact(stale_model_ids_by_validation_level,
               schema_contract: "model_acceptance_report.v1"
             )

    assert Enum.any?(
             stale_model_ids_by_validation_level_report["errors"],
             &(&1["path"] == "$.model_ids_by_validation_level")
           )

    stale_records = Map.put(report, "records", Enum.drop(Map.fetch!(report, "records"), 1))

    assert {:error, stale_records_report} =
             Schema.validate_artifact(stale_records,
               schema_contract: "model_acceptance_report.v1"
             )

    assert Enum.any?(
             stale_records_report["errors"],
             &(&1["path"] == "$.records")
           )

    stale_assumption_model_ids =
      put_in(report, ["assumptions", "input_model_ids"], ["orbit_data.simple_json"])

    assert {:error, stale_assumption_model_ids_report} =
             Schema.validate_artifact(stale_assumption_model_ids,
               schema_contract: "model_acceptance_report.v1"
             )

    assert Enum.any?(
             stale_assumption_model_ids_report["errors"],
             &(&1["path"] == "$.assumptions.input_model_ids")
           )

    stale_model_limits =
      Map.put(report, "model_limits", Enum.drop(Map.fetch!(report, "model_limits"), 1))

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits,
               schema_contract: "model_acceptance_report.v1"
             )

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits")
           )
  end

  test "verifies curated validation safety-case summary reference fixtures" do
    fixture_id = "fixture.artifact.validation_safety_case_summary.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.validation_safety_case_summary.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = validation_safety_case_summary_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               validation_safety_case_summary_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert OrbitalDynamics.validation_artifact_observations(
             "validation_safety_case_summary.v1",
             report
           ) == Validation.artifact_observations("validation_safety_case_summary.v1", report)

    assert {:ok, %{"schema_contract" => "validation_safety_case_summary.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "validation_safety_case_summary.v1"
             )

    stale_model_limits = Map.put(report, "model_limits", ["artifact_only"])

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits,
               schema_contract: "validation_safety_case_summary.v1"
             )

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match validation safety case summary model limits")
           )

    observations = validation_safety_case_summary_fixture_observations()

    assert observations["model_acceptance_evidence_status_counts"] == %{
             "accepted" => 1,
             "review_required" => 1
           }

    assert observations["model_acceptance_evidence_model_ids_by_status"] == %{
             "accepted" => ["orbit_data.simple_json"],
             "review_required" => ["event.access_windows"]
           }

    assert observations["model_acceptance_evidence_model_ids_by_validation_level"] == %{
             "analysis" => ["event.access_windows"],
             "artifact_contract" => ["orbit_data.simple_json"]
           }

    assert observations["model_acceptance_evidence_model_ids_by_intended_use"] == %{
             "operational_import" => ["orbit_data.simple_json", "event.access_windows"]
           }

    assert observations["evidence_refs_by_status"] == %{
             "accepted_for_use" => ["schema_validation_report.v1:candidate_refresh.v1"],
             "blocked" => [
               "schema_validation_report.v1:candidate_refresh.v1",
               "schema_validation_report.v1:candidate_refresh.v1"
             ],
             "review_required" => [
               "model_acceptance_report.v1:model_acceptance:operational_import:orbit_data.simple_json__event.access_windows"
             ]
           }

    assert observations["evidence_refs_by_contract"] == %{
             "model_acceptance_report.v1" => [
               "model_acceptance_report.v1:model_acceptance:operational_import:orbit_data.simple_json__event.access_windows"
             ],
             "schema_validation_report.v1" => [
               "schema_validation_report.v1:candidate_refresh.v1",
               "schema_validation_report.v1:candidate_refresh.v1",
               "schema_validation_report.v1:candidate_refresh.v1"
             ]
           }

    stale_model_acceptance_evidence_status_counts =
      put_in(observations, ["model_acceptance_evidence_status_counts", "accepted"], 0)

    assert {:ok, stale_model_acceptance_evidence_status_counts_report} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_model_acceptance_evidence_status_counts
             )

    assert stale_model_acceptance_evidence_status_counts_report["status"] == "fail"

    assert Enum.any?(
             stale_model_acceptance_evidence_status_counts_report["checks"],
             &(&1["field"] == "model_acceptance_evidence_status_counts" and
                 &1["status"] == "fail")
           )

    stale_model_acceptance_validation_level_ids =
      put_in(
        observations,
        ["model_acceptance_evidence_model_ids_by_validation_level", "artifact_contract"],
        []
      )

    assert {:ok, stale_model_acceptance_validation_level_ids_report} =
             Validation.verify_reference_fixture(
               fixture_id,
               stale_model_acceptance_validation_level_ids
             )

    assert stale_model_acceptance_validation_level_ids_report["status"] == "fail"

    assert Enum.any?(
             stale_model_acceptance_validation_level_ids_report["checks"],
             &(&1["field"] == "model_acceptance_evidence_model_ids_by_validation_level" and
                 &1["status"] == "fail")
           )

    model_acceptance_evidence_index =
      Enum.find_index(
        report["evidence"],
        &(&1["schema_contract"] == "model_acceptance_report.v1")
      )

    assert is_integer(model_acceptance_evidence_index)

    stale_copied_model_acceptance_ids =
      put_in(
        report,
        [
          "evidence",
          Access.at(model_acceptance_evidence_index),
          "model_ids_by_status",
          "accepted"
        ],
        []
      )

    assert {:error, stale_copied_model_acceptance_ids_report} =
             Schema.validate_artifact(stale_copied_model_acceptance_ids,
               schema_contract: "validation_safety_case_summary.v1"
             )

    assert Enum.any?(
             stale_copied_model_acceptance_ids_report["errors"],
             &(&1["path"] ==
                 "$.evidence[#{model_acceptance_evidence_index}].model_ids_by_status" and
                 &1["message"] == "must match model acceptance evidence status counts")
           )

    stale_schema_validation_evidence_index =
      Enum.find_index(
        report["evidence"],
        &(&1["schema_contract"] == "schema_validation_report.v1" and
            &1["status"] == "blocked")
      )

    assert is_integer(stale_schema_validation_evidence_index)

    stale_schema_validation_evidence =
      report
      |> put_in(
        ["evidence", Access.at(stale_schema_validation_evidence_index), "schema_error_count"],
        0
      )
      |> Map.put("schema_error_count", Map.fetch!(report, "schema_error_count") - 1)

    assert {:error, stale_schema_validation_evidence_report} =
             Schema.validate_artifact(stale_schema_validation_evidence,
               schema_contract: "validation_safety_case_summary.v1"
             )

    assert Enum.any?(
             stale_schema_validation_evidence_report["errors"],
             &(&1["path"] == "$.evidence[#{stale_schema_validation_evidence_index}].status" and
                 &1["message"] == "must match schema-validation evidence counts")
           )

    stale_observed_refs_by_contract =
      put_in(observations, ["evidence_refs_by_contract", "schema_validation_report.v1"], [
        "schema_validation_report.v1:candidate_refresh.v1"
      ])

    assert {:ok, stale_observed_refs_by_contract_report} =
             Validation.verify_reference_fixture(fixture_id, stale_observed_refs_by_contract)

    assert stale_observed_refs_by_contract_report["status"] == "fail"

    assert Enum.any?(
             stale_observed_refs_by_contract_report["checks"],
             &(&1["field"] == "evidence_refs_by_contract" and &1["status"] == "fail")
           )

    stale_status_counts = put_in(report, ["evidence_status_counts", "blocked"], 1)

    assert {:error, stale_status_counts_report} =
             Schema.validate_artifact(stale_status_counts,
               schema_contract: "validation_safety_case_summary.v1"
             )

    assert Enum.any?(
             stale_status_counts_report["errors"],
             &(&1["path"] == "$.evidence_status_counts")
           )

    stale_refs_by_status =
      put_in(report, ["evidence_refs_by_status", "blocked"], [
        "schema_validation_report.v1:candidate_refresh.v1"
      ])

    assert {:error, stale_refs_by_status_report} =
             Schema.validate_artifact(stale_refs_by_status,
               schema_contract: "validation_safety_case_summary.v1"
             )

    assert Enum.any?(
             stale_refs_by_status_report["errors"],
             &(&1["path"] == "$.evidence_refs_by_status")
           )

    stale_refs_by_contract =
      put_in(report, ["evidence_refs_by_contract", "schema_validation_report.v1"], [
        "schema_validation_report.v1:candidate_refresh.v1"
      ])

    assert {:error, stale_refs_by_contract_report} =
             Schema.validate_artifact(stale_refs_by_contract,
               schema_contract: "validation_safety_case_summary.v1"
             )

    assert Enum.any?(
             stale_refs_by_contract_report["errors"],
             &(&1["path"] == "$.evidence_refs_by_contract")
           )

    stale_fixture_failed_count = Map.put(report, "fixture_failed_count", 1)

    assert {:error, stale_fixture_failed_count_report} =
             Schema.validate_artifact(stale_fixture_failed_count,
               schema_contract: "validation_safety_case_summary.v1"
             )

    assert Enum.any?(
             stale_fixture_failed_count_report["errors"],
             &(&1["path"] == "$.fixture_failed_count")
           )
  end
end
