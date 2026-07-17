defmodule OrbitalDynamics.Validation.ReferenceFixtures.StateManeuverArtifacts do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.spacecraft_state_estimate.v1" => %{
      "id" => "fixture.artifact.spacecraft_state_estimate.v1",
      "model_id" => "artifact.spacecraft_state_estimate.v1",
      "reference_case" => "checked-in spacecraft state estimate artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/spacecraft_state_estimate_v1.json",
        "contract" => "spacecraft_state_estimate.v1"
      },
      "expected" => %{
        "schema_contract" => "spacecraft_state_estimate.v1",
        "spacecraft_id" => "sat_1",
        "scenario_id" => "leo_1",
        "epoch_s" => 0,
        "time_scale" => "tdb",
        "frame" => "earth_inertial_j2000",
        "source_system" => "operator_json_drop",
        "source_id" => "sat_1_estimate_1",
        "trust_boundary" => "operator_supplied",
        "quality_level" => "accepted",
        "position_component_count" => 3,
        "velocity_component_count" => 3,
        "position_sigma_component_count" => 3,
        "velocity_sigma_component_count" => 3,
        "position_x_km" => 7000,
        "velocity_y_km_s" => 7.546053290107542
      },
      "tolerances" => %{
        "epoch_s" => 0,
        "position_component_count" => 0,
        "velocity_component_count" => 0,
        "position_sigma_component_count" => 0,
        "velocity_sigma_component_count" => 0,
        "position_x_km" => 0,
        "velocity_y_km_s" => 1.0e-12
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external orbit-data validation",
        "checks state estimate identity, source/provenance, quality metadata, and vector dimensions only"
      ]
    },
    "fixture.artifact.realized_state_snapshot.v1" => %{
      "id" => "fixture.artifact.realized_state_snapshot.v1",
      "model_id" => "artifact.realized_state_snapshot.v1",
      "reference_case" => "checked-in realized state snapshot artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/realized_state_snapshot_v1.json",
        "contract" => "realized_state_snapshot.v1"
      },
      "expected" => %{
        "schema_contract" => "realized_state_snapshot.v1",
        "activity_count" => 2,
        "spacecraft_state_count" => 1,
        "status_counts" => %{"completed" => 1, "partial" => 1},
        "type_counts" => %{"command" => 1, "downlink" => 1},
        "degraded_count" => 1,
        "contact_failure_count" => 1,
        "total_planned_data_volume_mb" => 80,
        "total_actual_data_volume_mb" => 60,
        "snapshot_id" => "realized-state-demo-2026-05-14T00:00:00Z",
        "feedback_boundary" => "artifact_only_no_schedule_mutation",
        "provider" => "cadence",
        "adapter" => "cadence_feedback_adapter",
        "adapter_version" => "2026.05",
        "trust_boundary" => "operator_supplied",
        "no_schedule_mutation" => true,
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "activity_count" => 0,
        "spacecraft_state_count" => 0,
        "degraded_count" => 0,
        "contact_failure_count" => 0,
        "total_planned_data_volume_mb" => 0,
        "total_actual_data_volume_mb" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external state reconstruction validation",
        "checks realized snapshot activity counts, feedback status maps, provider metadata, and no-schedule-mutation boundary only"
      ]
    },
    "fixture.artifact.remaining_horizon.v1" => %{
      "id" => "fixture.artifact.remaining_horizon.v1",
      "model_id" => "artifact.remaining_horizon.v1",
      "reference_case" => "checked-in remaining horizon artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/remaining_horizon_v1.json",
        "contract" => "remaining_horizon.v1"
      },
      "expected" => %{
        "schema_contract" => "remaining_horizon.v1",
        "starts_at_s" => 0,
        "ends_at_s" => 600,
        "duration_s" => 600,
        "output_step_s" => 60
      },
      "tolerances" => %{
        "starts_at_s" => 0,
        "ends_at_s" => 0,
        "duration_s" => 0,
        "output_step_s" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external horizon validation",
        "checks remaining horizon timing bounds only"
      ]
    },
    "fixture.artifact.maneuver_execution_delta.v1" => %{
      "id" => "fixture.artifact.maneuver_execution_delta.v1",
      "model_id" => "artifact.maneuver_execution_delta.v1",
      "reference_case" => "checked-in maneuver execution delta artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/maneuver_execution_delta_v1.json",
        "contract" => "maneuver_execution_delta.v1"
      },
      "expected" => %{
        "schema_contract" => "maneuver_execution_delta.v1",
        "activity_id" => "trim_burn_1",
        "status" => "completed",
        "epoch_s" => 180,
        "delta_v_component_count" => 3,
        "delta_v_y_km_s" => 0.01,
        "delta_v_magnitude_km_s" => 0.01,
        "quality_level" => "operator_reported",
        "source_system" => "ops_log",
        "source_id" => "maneuver-log-1",
        "trust_boundary" => "operator_supplied"
      },
      "tolerances" => %{
        "epoch_s" => 0,
        "delta_v_component_count" => 0,
        "delta_v_y_km_s" => 0.0,
        "delta_v_magnitude_km_s" => 0.0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external maneuver execution validation",
        "checks maneuver execution delta identity, status, vector shape, source/provenance, and quality metadata only"
      ]
    },
    "fixture.artifact.maneuver_recommendation.v1" => %{
      "id" => "fixture.artifact.maneuver_recommendation.v1",
      "model_id" => "artifact.maneuver_recommendation.v1",
      "reference_case" => "checked-in maneuver recommendation artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/maneuver_recommendation_v1.json",
        "contract" => "maneuver_recommendation.v1"
      },
      "expected" => %{
        "schema_contract" => "maneuver_recommendation.v1",
        "id" => "trim_burn",
        "type" => "impulsive_burn",
        "scenario_id" => "ops_checkout",
        "epoch_s" => 180,
        "epoch_scale" => "tdb",
        "frame" => "eci_j2000",
        "maneuver_model" => "impulsive_burns",
        "validation_level" => "artifact_contract",
        "delta_v_component_count" => 3,
        "delta_v_y_km_s" => 0.01,
        "delta_v_magnitude_km_s" => 0.01,
        "execution_boundary" => "recommendation_only_no_command_execution",
        "assumption_source" => "trajectory_assumptions",
        "recommendation_only_no_command_execution" => true,
        "requires_operator_review_before_execution" => true,
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "epoch_s" => 0,
        "delta_v_component_count" => 0,
        "delta_v_y_km_s" => 0.0,
        "delta_v_magnitude_km_s" => 0.0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external maneuver validation",
        "checks maneuver recommendation identity, vector shape, model limits, and no-command execution boundary only"
      ]
    }
  }

  def all, do: @fixtures
end
