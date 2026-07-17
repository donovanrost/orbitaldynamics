defmodule OrbitalDynamics.Validation.ReferenceFixtures.ActivityArtifacts do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.planned_activity.v1" => %{
      "id" => "fixture.artifact.planned_activity.v1",
      "model_id" => "artifact.planned_activity.v1",
      "reference_case" => "checked-in planned activity artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/planned_activity_v1.json",
        "contract" => "planned_activity.v1"
      },
      "expected" => %{
        "schema_contract" => "planned_activity.v1",
        "id" => "cmd_repoint",
        "type" => "command",
        "scenario_id" => "leo_1",
        "spacecraft_id" => "leo_1",
        "source_window_id" => "window:leo_1:command:equator_prime:1",
        "starts_at_s" => 180,
        "ends_at_s" => 200,
        "duration_s" => 20,
        "ground_station_id" => "equator_prime",
        "direction" => "command",
        "mode" => "payload_safe",
        "dependency_activity_count" => 1,
        "exclusive_timeline_count" => 1,
        "product_count" => 1,
        "suppressed_activity_type_count" => 1,
        "timeline_identity_field_count" => 6,
        "timeline_identity_id" =>
          "timeline:leo_1:command:equator_prime:window:leo_1:command:equator_prime:1",
        "cadence_import_external_id" => "cadence_cmd_repoint",
        "resource_trust_boundary" => "operator_supplied_resource_summary",
        "resource_trust_boundary_status" => "declared",
        "resource_blocking_dimension" => "power",
        "command_success_factor" => 0.92,
        "maneuver_success_factor" => 0.9,
        "timing_3sigma_s" => 1.5,
        "delta_v_3sigma_component_count" => 3,
        "degraded" => false,
        "payload_available" => true,
        "spacecraft_available" => true
      },
      "tolerances" => %{
        "starts_at_s" => 0,
        "ends_at_s" => 0,
        "duration_s" => 0,
        "dependency_activity_count" => 0,
        "exclusive_timeline_count" => 0,
        "product_count" => 0,
        "suppressed_activity_type_count" => 0,
        "timeline_identity_field_count" => 0,
        "command_success_factor" => 0.0,
        "maneuver_success_factor" => 0.0,
        "timing_3sigma_s" => 0.0,
        "delta_v_3sigma_component_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external timeline validation",
        "checks planned activity identity, timing, dependency/exclusivity counts, resource trust, and execution-uncertainty metadata only"
      ]
    },
    "fixture.artifact.activity_template.v1" => %{
      "id" => "fixture.artifact.activity_template.v1",
      "model_id" => "artifact.activity_template.v1",
      "reference_case" => "checked-in observe activity template artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/activity_template_v1.json",
        "contract" => "activity_template.v1"
      },
      "expected" => %{
        "schema_contract" => "activity_template.v1",
        "id" => "template:observe:basic",
        "activity_type" => "observe",
        "template_version" => 1,
        "validation_level" => "artifact_contract",
        "display_name" => "Basic observe activity",
        "field_count" => 12,
        "required_field_count" => 5,
        "optional_field_count" => 7,
        "required_field_keys" => "id|type|target_id|starts_at_s|ends_at_s",
        "optional_field_keys" =>
          "payload_id|instrument_id|allow_overlap|setup_duration_s|cooldown_duration_s|telemetry_confirmation_required|telemetry_confirmation_status",
        "default_type" => "observe",
        "default_allow_overlap" => false,
        "lifecycle_status" => "planned",
        "lifecycle_approval_status" => "not_evaluated",
        "lifecycle_locked" => false,
        "lifecycle_allow_overlap" => false,
        "setup_duration_s" => 120,
        "cooldown_duration_s" => 60,
        "telemetry_confirmation_required" => true,
        "telemetry_confirmation_status" => "required",
        "required_state_count" => 2,
        "required_state_keys" => "spacecraft:standby|payload:ready",
        "required_blocking_state_count" => 2,
        "produced_state_count" => 1,
        "produced_state_keys" => "payload:observation_collected",
        "precondition_count" => 1,
        "precondition_type_keys" => "payload_unavailable",
        "blocking_precondition_count" => 1,
        "precondition_status_counts" => %{"review_required" => 1},
        "requires_payload" => true,
        "uses_storage" => true,
        "estimated_data_volume_mb" => 48,
        "suppressed_activity_type_keys" => "downlink",
        "boundary" => "template_only_no_schedule_mutation",
        "known_limit_count" => 2,
        "known_limit_keys" => "template_only_no_schedule_mutation|no_resource_reservation",
        "template_only_no_schedule_mutation" => true,
        "no_resource_reservation" => true
      },
      "tolerances" => %{
        "template_version" => 0,
        "field_count" => 0,
        "required_field_count" => 0,
        "optional_field_count" => 0,
        "setup_duration_s" => 0,
        "cooldown_duration_s" => 0,
        "required_state_count" => 0,
        "required_blocking_state_count" => 0,
        "produced_state_count" => 0,
        "precondition_count" => 0,
        "blocking_precondition_count" => 0,
        "estimated_data_volume_mb" => 0,
        "known_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external activity validation",
        "checks typed template fields, advisory operational/subsystem hints, and no-mutation/no-reservation limits only"
      ]
    }
  }

  def all, do: @fixtures
end
