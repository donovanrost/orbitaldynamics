defmodule OrbitalDynamics.Validation.ReferenceFixtures.AcceptedPlanningState do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.accepted_planning_state.simple" => %{
      "id" => "fixture.artifact.accepted_planning_state.simple",
      "model_id" => "artifact.accepted_planning_state.v1",
      "reference_case" => "checked-in simple JSON accepted planning state artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/accepted_planning_state_simple.json",
        "contract" => "accepted_planning_state.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "artifact_type" => "accepted_planning_state",
        "snapshot_id" => "ops-state-simple-2026-05-14",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "quality_level" => "planning_accepted",
        "source_system" => "operator_json_drop",
        "provenance_adapter" => "simple_json_state_estimates.v1",
        "provenance_trust_boundary" => "operator_supplied",
        "provenance_network_access" => false,
        "provenance_state_estimate_count" => 1,
        "spacecraft_state_count" => 1,
        "maneuver_execution_delta_count" => 1,
        "spacecraft_id" => "sat_1",
        "scenario_id" => "leo_1",
        "state_quality_level" => "accepted",
        "position_dimension" => 3,
        "velocity_dimension" => 3,
        "position_sigma_dimension" => 3,
        "velocity_sigma_dimension" => 3,
        "maneuver_status" => "completed"
      },
      "tolerances" => %{
        "schema_version" => 0,
        "provenance_state_estimate_count" => 0,
        "spacecraft_state_count" => 0,
        "maneuver_execution_delta_count" => 0,
        "position_dimension" => 0,
        "velocity_dimension" => 0,
        "position_sigma_dimension" => 0,
        "velocity_sigma_dimension" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not orbit-data truth validation",
        "checks accepted state identity, provenance, vector dimensions, and quality metadata only"
      ]
    },
    "fixture.artifact.accepted_planning_state.opm" => %{
      "id" => "fixture.artifact.accepted_planning_state.opm",
      "model_id" => "artifact.accepted_planning_state.v1",
      "reference_case" => "checked-in CCSDS OPM accepted planning state artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/accepted_planning_state_opm.json",
        "contract" => "accepted_planning_state.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "artifact_type" => "accepted_planning_state",
        "snapshot_id" => "ccsds_opm:1998-067A:120.0",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "quality_level" => "accepted",
        "provenance_input_format" => "ccsds_opm_kvn",
        "provenance_trust_boundary" => "external_orbit_data_adapter",
        "provenance_network_access" => false,
        "spacecraft_state_count" => 1,
        "maneuver_execution_delta_count" => 0,
        "spacecraft_id" => "1998-067A",
        "scenario_id" => "1998-067A",
        "state_quality_level" => "accepted",
        "position_dimension" => 3,
        "velocity_dimension" => 3
      },
      "tolerances" => %{
        "schema_version" => 0,
        "spacecraft_state_count" => 0,
        "maneuver_execution_delta_count" => 0,
        "position_dimension" => 0,
        "velocity_dimension" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not CCSDS orbit validation",
        "checks OPM accepted state identity, provenance format, and vector dimensions only"
      ]
    },
    "fixture.artifact.accepted_planning_state.oem" => %{
      "id" => "fixture.artifact.accepted_planning_state.oem",
      "model_id" => "artifact.accepted_planning_state.v1",
      "reference_case" => "checked-in CCSDS OEM accepted planning state artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/accepted_planning_state_oem.json",
        "contract" => "accepted_planning_state.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "artifact_type" => "accepted_planning_state",
        "snapshot_id" => "ops-oem-1",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "quality_level" => "planning_accepted",
        "provenance_input_format" => "ccsds_oem_kvn",
        "provenance_trust_boundary" => "external_orbit_data_adapter",
        "provenance_network_access" => false,
        "spacecraft_state_count" => 1,
        "maneuver_execution_delta_count" => 0,
        "spacecraft_id" => "1998-067A",
        "scenario_id" => "1998-067A",
        "state_quality_level" => "accepted",
        "position_dimension" => 3,
        "velocity_dimension" => 3
      },
      "tolerances" => %{
        "schema_version" => 0,
        "spacecraft_state_count" => 0,
        "maneuver_execution_delta_count" => 0,
        "position_dimension" => 0,
        "velocity_dimension" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not CCSDS orbit validation",
        "checks OEM accepted state identity, provenance format, and vector dimensions only"
      ]
    }
  }

  def all, do: @fixtures
end
