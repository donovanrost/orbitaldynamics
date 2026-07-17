defmodule OrbitalDynamics.Validation.ReferenceFixtures.ContactWindowArtifacts do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.refreshed_window.v1" => %{
      "id" => "fixture.artifact.refreshed_window.v1",
      "model_id" => "artifact.refreshed_window.v1",
      "reference_case" => "checked-in refreshed window artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/refreshed_window_v1.json",
        "contract" => "refreshed_window.v1"
      },
      "expected" => %{
        "schema_contract" => "refreshed_window.v1",
        "id" => "window:leo_1:target_visibility:target_a:1",
        "type" => "target_visibility",
        "scenario_id" => "leo_1",
        "target_id" => "target_a",
        "starts_at_s" => 0,
        "ends_at_s" => 282.8895569509249,
        "duration_s" => 282.8895569509249,
        "sample_count" => 5,
        "target_priority" => 2,
        "minimum_elevation_deg" => 10,
        "max_elevation_deg" => 90,
        "confidence" => "bounded_by_sample_cadence",
        "event_detector" => "target_visibility",
        "event_time_tolerance_s" => 60,
        "event_timing_policy" => "sampled_state_linear_boundary",
        "geometry_model" => "simplified_spherical_earth_rotation",
        "interpolation" => "linear_sample_crossing",
        "max_sample_step_s" => 60,
        "refraction" => "none",
        "terrain_mask" => "none"
      },
      "tolerances" => %{
        "starts_at_s" => 0,
        "ends_at_s" => 1.0e-12,
        "duration_s" => 1.0e-12,
        "sample_count" => 0,
        "target_priority" => 0,
        "minimum_elevation_deg" => 0,
        "max_elevation_deg" => 0,
        "event_time_tolerance_s" => 0,
        "max_sample_step_s" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external event validation",
        "checks refreshed window identity, timing, elevation bounds, sample count, and event-timing assumptions only"
      ]
    },
    "fixture.artifact.source_window_lineage.v1" => %{
      "id" => "fixture.artifact.source_window_lineage.v1",
      "model_id" => "artifact.source_window_lineage.v1",
      "reference_case" => "checked-in source window lineage artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/source_window_lineage_v1.json",
        "contract" => "source_window_lineage.v1"
      },
      "expected" => %{
        "schema_contract" => "source_window_lineage.v1",
        "candidate_activity_id" => "leo_1_downlink_equator_prime_1",
        "scenario_id" => "leo_1",
        "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1",
        "source_window_type" => "ground_station_access"
      },
      "tolerances" => %{},
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external lineage validation",
        "checks source-window lineage identity only"
      ]
    }
  }

  def all, do: @fixtures
end
