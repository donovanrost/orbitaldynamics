defmodule OrbitalDynamics.Validation.ActivityArtifactFixtureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.Validation.ActivityArtifactFixtures,
    only: [
      planned_activity_fixture_observations: 0,
      planned_activity_fixture: 0,
      activity_template_fixture_observations: 0,
      activity_template_fixture: 0,
      subsystem_model_capability_fixture_observations: 0,
      subsystem_model_capability_fixture: 0,
      subsystem_model_capability_storage_fixture_observations: 0,
      subsystem_model_capability_storage_fixture: 0,
      realized_activity_fixture_observations: 0,
      realized_activity_fixture: 0,
      plan_delta_fixture_observations: 0,
      plan_delta_fixture: 0,
      candidate_activity_fixture_observations: 0,
      candidate_activity_fixture: 0
    ]

  alias OrbitalDynamics.{Schema, Validation}

  test "verifies curated planned activity reference fixtures" do
    fixture_id = "fixture.artifact.planned_activity.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.planned_activity.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = planned_activity_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               planned_activity_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      planned_activity_fixture_observations()
      |> Map.put("timeline_identity_field_count", 5)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "timeline_identity_field_count" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "planned_activity.v1")

    stale_timeline_identity =
      put_in(report, ["timeline_identity", "activity_id"], "cmd_other")

    assert {:error, stale_timeline_identity_report} =
             Schema.validate_artifact(stale_timeline_identity,
               schema_contract: "planned_activity.v1"
             )

    assert Enum.any?(
             stale_timeline_identity_report["errors"],
             &(&1["path"] == "$.timeline_identity.activity_id")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "planned_activity.v1",
             report
           ) == Validation.artifact_observations("planned_activity.v1", report)
  end

  test "verifies curated activity template reference fixtures" do
    fixture_id = "fixture.artifact.activity_template.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.activity_template.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    template = activity_template_fixture()
    observations = activity_template_fixture_observations()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(fixture_id, observations)

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    assert observations["activity_type"] == "observe"
    assert observations["required_field_keys"] == "id|type|target_id|starts_at_s|ends_at_s"
    assert observations["optional_field_count"] == 7
    assert observations["setup_duration_s"] == 120
    assert observations["cooldown_duration_s"] == 60
    assert observations["telemetry_confirmation_required"] == true
    assert observations["required_state_keys"] == "spacecraft:standby|payload:ready"
    assert observations["produced_state_keys"] == "payload:observation_collected"
    assert observations["precondition_type_keys"] == "payload_unavailable"
    assert observations["boundary"] == "template_only_no_schedule_mutation"

    stale_hint_observations =
      observations
      |> Map.put("setup_duration_s", 30)

    assert {:ok, stale_hint_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_hint_observations)

    assert stale_hint_verification["status"] == "fail"

    assert Enum.any?(
             stale_hint_verification["checks"],
             &(&1["field"] == "setup_duration_s" and &1["status"] == "fail")
           )

    stale_state_observations =
      observations
      |> Map.put("required_state_keys", "payload:ready")

    assert {:ok, stale_state_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_state_observations)

    assert stale_state_verification["status"] == "fail"

    assert Enum.any?(
             stale_state_verification["checks"],
             &(&1["field"] == "required_state_keys" and &1["status"] == "fail")
           )

    stale_limit_observations =
      observations
      |> Map.put("no_resource_reservation", false)

    assert {:ok, stale_limit_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_limit_observations)

    assert stale_limit_verification["status"] == "fail"

    assert Enum.any?(
             stale_limit_verification["checks"],
             &(&1["field"] == "no_resource_reservation" and &1["status"] == "fail")
           )

    assert {:ok, _valid_template} =
             Schema.validate_artifact(template, schema_contract: "activity_template.v1")

    assert OrbitalDynamics.validation_artifact_observations(
             "activity_template.v1",
             template
           ) == Validation.artifact_observations("activity_template.v1", template)
  end

  test "verifies curated subsystem model capability reference fixtures" do
    battery_fixture_id = "fixture.artifact.subsystem_model_capability.battery"
    storage_fixture_id = "fixture.artifact.subsystem_model_capability.storage"

    assert {:ok, battery_fixture} = Validation.reference_fixture(battery_fixture_id)
    assert {:ok, storage_fixture} = Validation.reference_fixture(storage_fixture_id)

    assert battery_fixture["model_id"] == "artifact.subsystem_model_capability.v1"
    assert storage_fixture["model_id"] == "artifact.subsystem_model_capability.v1"

    battery_capability = subsystem_model_capability_fixture()
    storage_capability = subsystem_model_capability_storage_fixture()
    battery_observations = subsystem_model_capability_fixture_observations()
    storage_observations = subsystem_model_capability_storage_fixture_observations()

    assert {:ok, battery_verification} =
             Validation.verify_reference_fixture(battery_fixture_id, battery_observations)

    assert {:ok, storage_verification} =
             Validation.verify_reference_fixture(storage_fixture_id, storage_observations)

    assert battery_verification["status"] == "pass"
    assert storage_verification["status"] == "pass"
    assert Enum.all?(battery_verification["checks"], &(&1["status"] == "pass"))
    assert Enum.all?(storage_verification["checks"], &(&1["status"] == "pass"))

    assert battery_observations["id"] ==
             "subsystem.power.battery.energy_storage.planning_grade"

    assert battery_observations["resource_dimensions"] == "battery"
    assert battery_observations["activity_effect_types"] == "consumption|generation"

    assert battery_observations["known_limit_keys"] ==
             "selected_activity_sequence_only|declared_energy_hints_only|no_continuous_power_bus_or_thermal_coupling|no_battery_degradation_or_charge_dynamics"

    assert storage_observations["id"] ==
             "subsystem.data_recorder.storage_buffer.planning_grade"

    assert storage_observations["resource_dimensions"] == "storage|downlink"
    assert storage_observations["activity_effect_types"] == "downlink|production"

    assert storage_observations["known_limit_keys"] ==
             "selected_activity_sequence_only|declared_data_volume_hints_only|storage_limited_downlink_arithmetic_only|no_partition_priority_deletion_or_latency_model"

    stale_battery_observations =
      battery_observations
      |> Map.put("resource_dimensions", "power")

    assert {:ok, stale_battery_verification} =
             Validation.verify_reference_fixture(battery_fixture_id, stale_battery_observations)

    assert stale_battery_verification["status"] == "fail"

    assert Enum.any?(
             stale_battery_verification["checks"],
             &(&1["field"] == "resource_dimensions" and &1["status"] == "fail")
           )

    stale_storage_observations =
      storage_observations
      |> Map.put("storage_limited_downlink_arithmetic_only", false)

    assert {:ok, stale_storage_verification} =
             Validation.verify_reference_fixture(storage_fixture_id, stale_storage_observations)

    assert stale_storage_verification["status"] == "fail"

    assert Enum.any?(
             stale_storage_verification["checks"],
             &(&1["field"] == "storage_limited_downlink_arithmetic_only" and
                 &1["status"] == "fail")
           )

    assert {:ok, _valid_battery_capability} =
             Schema.validate_artifact(battery_capability,
               schema_contract: "subsystem_model_capability.v1"
             )

    assert {:ok, _valid_storage_capability} =
             Schema.validate_artifact(storage_capability,
               schema_contract: "subsystem_model_capability.v1"
             )

    assert OrbitalDynamics.validation_artifact_observations(
             "subsystem_model_capability.v1",
             battery_capability
           ) ==
             Validation.artifact_observations("subsystem_model_capability.v1", battery_capability)

    assert OrbitalDynamics.validation_artifact_observations(
             "subsystem_model_capability.v1",
             storage_capability
           ) ==
             Validation.artifact_observations("subsystem_model_capability.v1", storage_capability)
  end

  test "verifies curated realized activity reference fixtures" do
    fixture_id = "fixture.artifact.realized_activity.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.realized_activity.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = realized_activity_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               realized_activity_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      realized_activity_fixture_observations()
      |> Map.put("status", "completed")

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "status" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "realized_activity.v1")

    stale_metadata =
      put_in(report, ["metadata", "planned_activity_id"], "other_activity")

    assert {:error, stale_metadata_report} =
             Schema.validate_artifact(stale_metadata, schema_contract: "realized_activity.v1")

    assert Enum.any?(
             stale_metadata_report["errors"],
             &(&1["path"] == "$.metadata.planned_activity_id")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "realized_activity.v1",
             report
           ) == Validation.artifact_observations("realized_activity.v1", report)
  end

  test "verifies curated plan delta reference fixtures" do
    fixture_id = "fixture.artifact.plan_delta.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.plan_delta.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = plan_delta_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               plan_delta_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      plan_delta_fixture_observations()
      |> Map.put("requires_approval", false)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "requires_approval" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "plan_delta.v1")

    stale_source_identity =
      put_in(report, ["source_activity_context", "timeline_identity", "activity_id"], "other")

    assert {:error, stale_source_identity_report} =
             Schema.validate_artifact(stale_source_identity, schema_contract: "plan_delta.v1")

    assert Enum.any?(
             stale_source_identity_report["errors"],
             &(&1["path"] == "$.source_activity_context.timeline_identity.activity_id")
           )

    planned_identity_report =
      put_in(
        report,
        ["planned", "timeline_identity"],
        get_in(report, ["source_activity_context", "timeline_identity"])
      )

    assert {:ok, _valid_planned_identity_report} =
             Schema.validate_artifact(planned_identity_report,
               schema_contract: "plan_delta.v1"
             )

    invalid_planned_identities = [
      {"$.planned.id", put_in(planned_identity_report, ["planned", "id"], "other")},
      {"$.planned.type", put_in(planned_identity_report, ["planned", "type"], "other_type")},
      {"$.planned.timeline_identity.activity_id",
       put_in(
         planned_identity_report,
         ["planned", "timeline_identity", "activity_id"],
         "other"
       )},
      {"$.planned.timeline_identity.activity_type",
       put_in(
         planned_identity_report,
         ["planned", "timeline_identity", "activity_type"],
         "other_type"
       )},
      {"$.planned.timeline_identity.timeline_id",
       put_in(
         planned_identity_report,
         ["planned", "timeline_identity", "timeline_id"],
         "timeline:planned:drift"
       )}
    ]

    for {expected_path, invalid} <- invalid_planned_identities do
      assert {:error, invalid_report} =
               Schema.validate_artifact(invalid, schema_contract: "plan_delta.v1")

      assert Enum.any?(invalid_report["errors"], &(&1["path"] == expected_path))
    end

    replacement_report =
      report
      |> Map.put("replacement_activity_id", "leo_1_observe_target_a_2")
      |> Map.put(
        "replacement_timeline_id",
        "timeline:leo_1:observe:target_a:replacement:2"
      )
      |> Map.put("replacement_activity_context", %{
        "timeline_identity" => %{
          "activity_id" => "leo_1_observe_target_a_2",
          "activity_type" => "observe",
          "scenario_id" => "leo_1",
          "subject_id" => "target_a",
          "timeline_id" => "timeline:leo_1:observe:target_a:replacement:2"
        }
      })
      |> Map.put("timeline_link", %{
        "source_activity_id" => report["activity_id"],
        "replacement_activity_id" => "leo_1_observe_target_a_2",
        "source_timeline_id" => report["source_timeline_id"],
        "replacement_timeline_id" => "timeline:leo_1:observe:target_a:replacement:2"
      })

    assert {:ok, _valid_replacement_report} =
             Schema.validate_artifact(replacement_report, schema_contract: "plan_delta.v1")

    invalid_replacement_identities = [
      {"$.replacement_activity_id",
       Map.put(replacement_report, "replacement_activity_id", "other_activity")},
      {"$.replacement_timeline_id",
       Map.put(replacement_report, "replacement_timeline_id", "timeline:replacement:drift")}
    ]

    for {expected_path, invalid} <- invalid_replacement_identities do
      assert {:error, invalid_report} =
               Schema.validate_artifact(invalid, schema_contract: "plan_delta.v1")

      assert Enum.any?(invalid_report["errors"], &(&1["path"] == expected_path))
    end

    invalid_timeline_link_identities = [
      {"source_activity_id", "other_source_activity"},
      {"replacement_activity_id", "other_replacement_activity"},
      {"source_timeline_id", "timeline:source:link-drift"},
      {"replacement_timeline_id", "timeline:replacement:link-drift"}
    ]

    for {field, drift} <- invalid_timeline_link_identities do
      invalid = put_in(replacement_report, ["timeline_link", field], drift)

      assert {:error, invalid_report} =
               Schema.validate_artifact(invalid, schema_contract: "plan_delta.v1")

      assert Enum.any?(
               invalid_report["errors"],
               &(&1["path"] == "$.timeline_link.#{field}")
             )
    end

    assert OrbitalDynamics.validation_artifact_observations(
             "plan_delta.v1",
             report
           ) == Validation.artifact_observations("plan_delta.v1", report)
  end

  test "verifies curated candidate activity reference fixtures" do
    fixture_id = "fixture.artifact.candidate_activity.v1"

    assert {:ok, fixture} = Validation.reference_fixture(fixture_id)

    assert fixture["model_id"] == "artifact.candidate_activity.v1"
    assert fixture["fixture_type"] == "curated_internal_artifact_regression"

    report = candidate_activity_fixture()

    assert {:ok, verification} =
             Validation.verify_reference_fixture(
               fixture_id,
               candidate_activity_fixture_observations()
             )

    assert verification["status"] == "pass"
    assert Enum.all?(verification["checks"], &(&1["status"] == "pass"))

    stale_observations =
      candidate_activity_fixture_observations()
      |> Map.put("score_term_count", 3)

    assert {:ok, stale_verification} =
             Validation.verify_reference_fixture(fixture_id, stale_observations)

    assert stale_verification["status"] == "fail"

    assert Enum.any?(
             stale_verification["checks"],
             &(&1["field"] == "score_term_count" and &1["status"] == "fail")
           )

    assert {:ok, _valid_report} =
             Schema.validate_artifact(report, schema_contract: "candidate_activity.v1")

    stale_score = Map.put(report, "score", 1.0)

    assert {:error, stale_score_report} =
             Schema.validate_artifact(stale_score, schema_contract: "candidate_activity.v1")

    assert Enum.any?(
             stale_score_report["errors"],
             &(&1["path"] == "$.score")
           )

    assert OrbitalDynamics.validation_artifact_observations(
             "candidate_activity.v1",
             report
           ) == Validation.artifact_observations("candidate_activity.v1", report)
  end
end
