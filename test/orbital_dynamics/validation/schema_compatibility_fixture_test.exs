defmodule OrbitalDynamics.Validation.SchemaCompatibilityFixtureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.Validation.SchemaCompatibilityFixtures,
    only: [
      schema_validation_report_fixture_observations: 0,
      schema_validation_report_fixture: 0,
      schema_validation_batch_report_fixture_observations: 0,
      schema_validation_batch_report_fixture: 0,
      schema_migration_report_fixture_observations: 0,
      schema_migration_report_fixture: 0,
      schema_migration_future_contract_fixture_observations: 0,
      schema_migration_future_contract_fixture: 0
    ]

  alias OrbitalDynamics.{Schema, Validation}

  test "verifies curated schema validation report reference fixtures" do
    fixture_id = "fixture.artifact.schema_validation_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.schema_validation_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = schema_validation_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               schema_validation_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert OrbitalDynamics.validation_artifact_observations("schema_validation_report.v1", report) ==
             Validation.artifact_observations("schema_validation_report.v1", report)

    assert {:ok, _validated_report} =
             Schema.validate_artifact(report,
               schema_contract: "schema_validation_report.v1"
             )

    stale_error_count = Map.put(report, "error_count", 1)

    assert {:error, stale_error_count_report} =
             Schema.validate_artifact(stale_error_count,
               schema_contract: "schema_validation_report.v1"
             )

    assert Enum.any?(
             stale_error_count_report["errors"],
             &(&1["path"] == "$.error_count")
           )

    stale_status = Map.put(report, "status", "fail")

    assert {:error, stale_status_report} =
             Schema.validate_artifact(stale_status,
               schema_contract: "schema_validation_report.v1"
             )

    assert Enum.any?(
             stale_status_report["errors"],
             &(&1["path"] == "$.status")
           )
  end

  test "verifies curated schema validation batch report reference fixtures" do
    fixture_id = "fixture.artifact.schema_validation_batch_report.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.schema_validation_batch_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = schema_validation_batch_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               schema_validation_batch_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert OrbitalDynamics.validation_artifact_observations(
             "schema_validation_batch_report.v1",
             report
           ) == Validation.artifact_observations("schema_validation_batch_report.v1", report)

    assert {:ok, %{"schema_contract" => "schema_validation_batch_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "schema_validation_batch_report.v1"
             )

    Enum.each(
      [
        {"file_count", 0},
        {"artifact_count", 0},
        {"skipped_count", 1},
        {"error_count", 1},
        {"warning_count", 1},
        {"remediation_count", 1}
      ],
      fn {field, stale_value} ->
        stale_report = Map.put(report, field, stale_value)

        assert {:error, validation_report} =
                 Schema.validate_artifact(stale_report,
                   schema_contract: "schema_validation_batch_report.v1"
                 )

        assert Enum.any?(validation_report["errors"], &(&1["path"] == "$.#{field}"))
      end
    )

    stale_status_counts = put_in(report, ["status_counts", "pass"], 0)

    assert {:error, stale_status_counts_report} =
             Schema.validate_artifact(stale_status_counts,
               schema_contract: "schema_validation_batch_report.v1"
             )

    assert Enum.any?(
             stale_status_counts_report["errors"],
             &(&1["path"] == "$.status_counts")
           )

    nested_failure =
      update_in(report, ["reports", Access.at(0), "report"], fn nested_report ->
        nested_report
        |> Map.put("status", "fail")
        |> Map.put("error_count", 1)
        |> Map.put("errors", [
          %{"severity" => "error", "path" => "$.status", "message" => "forced stale fixture"}
        ])
      end)

    assert {:error, stale_status_report} =
             Schema.validate_artifact(nested_failure,
               schema_contract: "schema_validation_batch_report.v1"
             )

    assert Enum.any?(stale_status_report["errors"], &(&1["path"] == "$.status"))

    stale_limits = Map.put(report, "model_limits", ["stale_schema_validation_boundary"])

    assert {:error, stale_limits_report} =
             Schema.validate_artifact(stale_limits,
               schema_contract: "schema_validation_batch_report.v1"
             )

    assert Enum.any?(stale_limits_report["errors"], &(&1["path"] == "$.model_limits"))
  end

  test "verifies curated schema migration report reference fixtures" do
    fixture_id = "fixture.artifact.schema_migration_report.deprecated_campaign_plan"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.schema_migration_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = schema_migration_report_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               schema_migration_report_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "status" => "review_required",
             "deprecated_contract_count" => 1,
             "deprecated_contracts" => "campaign_plan.v1",
             "replacement_contracts" => "campaign_strategy.v3",
             "status_counts" => %{"current" => 127, "deprecated" => 1},
             "row_derived_status_counts" => %{"current" => 127, "deprecated" => 1}
           } = schema_migration_report_fixture_observations()

    stale_status_counts =
      schema_migration_report_fixture_observations()
      |> Map.put("row_derived_status_counts", %{"current" => 126})

    assert {:ok, stale_status_counts_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_status_counts)

    assert stale_status_counts_verification["status"] == "fail"

    assert Enum.any?(
             stale_status_counts_verification["checks"],
             &(&1["field"] == "row_derived_status_counts" and &1["status"] == "fail")
           )

    assert OrbitalDynamics.validation_artifact_observations("schema_migration_report.v1", report) ==
             Validation.artifact_observations("schema_migration_report.v1", report)

    assert {:ok, %{"schema_contract" => "schema_migration_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "schema_migration_report.v1"
             )

    stale_model_limits = Map.put(report, "model_limits", ["artifact_only"])

    assert {:error, stale_model_limits_report} =
             Schema.validate_artifact(stale_model_limits,
               schema_contract: "schema_migration_report.v1"
             )

    assert Enum.any?(
             stale_model_limits_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match schema migration report model limits")
           )

    stale_contract_count = Map.put(report, "contract_count", 116)

    assert {:error, stale_contract_count_report} =
             Schema.validate_artifact(stale_contract_count,
               schema_contract: "schema_migration_report.v1"
             )

    assert Enum.any?(
             stale_contract_count_report["errors"],
             &(&1["path"] == "$.contract_count")
           )

    stale_status = Map.put(report, "status", "current")

    assert {:error, stale_status_report} =
             Schema.validate_artifact(stale_status,
               schema_contract: "schema_migration_report.v1"
             )

    assert Enum.any?(stale_status_report["errors"], &(&1["path"] == "$.status"))
  end

  test "verifies schema migration future-contract challenge fixtures" do
    fixture_id = "fixture.artifact.schema_migration_report.future_campaign_plan"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.schema_migration_report.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = schema_migration_future_contract_fixture()
    observations = schema_migration_future_contract_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert %{
             "status" => "review_required",
             "future_contract_count" => 1,
             "deprecated_contract_count" => 0,
             "status_counts" => %{"current" => 128, "future" => 1},
             "row_derived_status_counts" => %{"current" => 128, "future" => 1},
             "migration_action_counts" => %{
               "continue_current_contract" => 128,
               "prepare_future_contract" => 1
             },
             "row_derived_migration_action_counts" => %{
               "continue_current_contract" => 128,
               "prepare_future_contract" => 1
             }
           } = observations

    schema_migration_actions = Validation.capabilities().schema_migration_actions

    assert Map.keys(observations["migration_action_counts"]) -- schema_migration_actions == []

    assert Map.keys(observations["row_derived_migration_action_counts"]) --
             schema_migration_actions == []

    stale_action_counts =
      observations
      |> Map.put("row_derived_migration_action_counts", %{
        "continue_current_contract" => 127
      })

    assert {:ok, stale_action_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_action_counts)

    assert stale_action_verification["status"] == "fail"

    assert Enum.any?(
             stale_action_verification["checks"],
             &(&1["field"] == "row_derived_migration_action_counts" and &1["status"] == "fail")
           )

    assert {:ok, %{"schema_contract" => "schema_migration_report.v1"}} =
             Schema.validate_artifact(report,
               schema_contract: "schema_migration_report.v1"
             )

    stale_future_count = Map.put(report, "future_contract_count", 0)

    assert {:error, stale_future_count_report} =
             Schema.validate_artifact(stale_future_count,
               schema_contract: "schema_migration_report.v1"
             )

    assert Enum.any?(
             stale_future_count_report["errors"],
             &(&1["path"] == "$.future_contract_count")
           )
  end
end
