defmodule OrbitalDynamics.Validation.ReferenceFixtures.CampaignArtifacts do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.campaign_plan.leo_constellation_v1" => %{
      "id" => "fixture.artifact.campaign_plan.leo_constellation_v1",
      "model_id" => "artifact.campaign_plan.v1",
      "reference_case" => "checked-in LEO constellation campaign plan artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/leo_constellation_campaign.json",
        "artifact_key" => "campaign_plan",
        "contract" => "campaign_plan.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "planner" => "OrbitalDynamics.CampaignPlanner.V1",
        "activity_count" => 1,
        "proposed_contact_count" => 1,
        "contact_intent_count" => 1,
        "candidate_activity_count" => 2,
        "ranked_timeline_count" => 1,
        "warning_count" => 0
      },
      "tolerances" => %{
        "schema_version" => 0,
        "activity_count" => 0,
        "proposed_contact_count" => 0,
        "contact_intent_count" => 0,
        "candidate_activity_count" => 0,
        "ranked_timeline_count" => 0,
        "warning_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external mission validation",
        "checks contract shape, stable product counts, and embedded strategy score-term routing only"
      ]
    },
    "fixture.artifact.result_artifact.leo_constellation_campaign" => %{
      "id" => "fixture.artifact.result_artifact.leo_constellation_campaign",
      "model_id" => "artifact.result_artifact.v1",
      "reference_case" => "checked-in LEO constellation campaign result artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/leo_constellation_campaign.json",
        "contract" => "result_artifact.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "study_id" => "leo_constellation_campaign",
        "top_level_key_count" => 16,
        "trajectory_count" => 2,
        "access_window_count" => 1,
        "eclipse_interval_count" => 2,
        "target_visibility_window_count" => 1,
        "error_count" => 0,
        "has_campaign_plan" => true,
        "campaign_activity_count" => 1,
        "campaign_proposed_contact_count" => 1,
        "campaign_contact_intent_count" => 1,
        "campaign_candidate_activity_count" => 2,
        "campaign_ranked_timeline_count" => 1,
        "execution_report_status" => "completed",
        "execution_report_scenario_count" => 0,
        "payload_metrics_contract" => "result_payload_metrics.v1",
        "payload_metrics_top_level_key_count" => 15,
        "payload_metrics_section_count" => 15,
        "payload_metrics_artifact_body_bytes" => 324_247,
        "run_status" => "completed",
        "run_study_id" => "leo_constellation_campaign"
      },
      "tolerances" => %{
        "schema_version" => 0,
        "top_level_key_count" => 0,
        "trajectory_count" => 0,
        "access_window_count" => 0,
        "eclipse_interval_count" => 0,
        "target_visibility_window_count" => 0,
        "error_count" => 0,
        "campaign_activity_count" => 0,
        "campaign_proposed_contact_count" => 0,
        "campaign_contact_intent_count" => 0,
        "campaign_candidate_activity_count" => 0,
        "campaign_ranked_timeline_count" => 0,
        "execution_report_scenario_count" => 0,
        "payload_metrics_top_level_key_count" => 0,
        "payload_metrics_section_count" => 0,
        "payload_metrics_artifact_body_bytes" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external mission validation",
        "checks wrapper-level product counts, embedded campaign counts, execution status, and payload metrics only"
      ]
    },
    "fixture.artifact.result_artifact.leo_access_demo" => %{
      "id" => "fixture.artifact.result_artifact.leo_access_demo",
      "model_id" => "artifact.result_artifact.v1",
      "reference_case" => "checked-in LEO access result artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/leo_access_demo.json",
        "contract" => "result_artifact.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "study_id" => "leo_access_demo",
        "top_level_key_count" => 15,
        "trajectory_count" => 2,
        "access_window_count" => 3,
        "eclipse_interval_count" => 2,
        "target_visibility_window_count" => 0,
        "ground_track_crossing_count" => 0,
        "maneuver_recommendation_count" => 0,
        "error_count" => 0,
        "has_campaign_plan" => false,
        "execution_report_status" => "completed",
        "execution_report_declared_scenario_count" => 2,
        "execution_report_failed_scenario_count" => 0,
        "payload_metrics_contract" => "result_payload_metrics.v1",
        "payload_metrics_top_level_key_count" => 14,
        "payload_metrics_section_count" => 14,
        "payload_metrics_artifact_body_bytes" => 21_802,
        "run_status" => "completed",
        "run_study_id" => "leo_access_demo",
        "run_scenario_count" => 2,
        "run_trajectory_count" => 2,
        "run_event_result_count" => 6
      },
      "tolerances" => %{
        "schema_version" => 0,
        "top_level_key_count" => 0,
        "trajectory_count" => 0,
        "access_window_count" => 0,
        "eclipse_interval_count" => 0,
        "target_visibility_window_count" => 0,
        "ground_track_crossing_count" => 0,
        "maneuver_recommendation_count" => 0,
        "error_count" => 0,
        "execution_report_declared_scenario_count" => 0,
        "execution_report_failed_scenario_count" => 0,
        "payload_metrics_top_level_key_count" => 0,
        "payload_metrics_section_count" => 0,
        "payload_metrics_artifact_body_bytes" => 0,
        "run_scenario_count" => 0,
        "run_trajectory_count" => 0,
        "run_event_result_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external mission validation",
        "checks event-rich wrapper product counts, execution status, run metadata, and payload metrics only"
      ]
    },
    "fixture.artifact.result_artifact.leo_access_demo_manifest" => %{
      "id" => "fixture.artifact.result_artifact.leo_access_demo_manifest",
      "model_id" => "artifact.result_artifact.v1",
      "reference_case" => "checked-in manifest-driven LEO access result artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/leo_access_demo_manifest.json",
        "contract" => "result_artifact.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "study_id" => "leo_access_demo",
        "top_level_key_count" => 15,
        "trajectory_count" => 2,
        "access_window_count" => 3,
        "eclipse_interval_count" => 2,
        "target_visibility_window_count" => 0,
        "ground_track_crossing_count" => 0,
        "maneuver_recommendation_count" => 0,
        "error_count" => 0,
        "execution_report_status" => "completed",
        "execution_report_declared_scenario_count" => 2,
        "execution_report_failed_scenario_count" => 0,
        "payload_metrics_contract" => "result_payload_metrics.v1",
        "payload_metrics_top_level_key_count" => 14,
        "payload_metrics_section_count" => 14,
        "payload_metrics_artifact_body_bytes" => 21_969,
        "run_status" => "completed",
        "run_study_id" => "leo_access_demo",
        "run_scenario_count" => 2,
        "run_trajectory_count" => 2,
        "run_event_result_count" => 6
      },
      "tolerances" => %{
        "schema_version" => 0,
        "top_level_key_count" => 0,
        "trajectory_count" => 0,
        "access_window_count" => 0,
        "eclipse_interval_count" => 0,
        "target_visibility_window_count" => 0,
        "ground_track_crossing_count" => 0,
        "maneuver_recommendation_count" => 0,
        "error_count" => 0,
        "execution_report_declared_scenario_count" => 0,
        "execution_report_failed_scenario_count" => 0,
        "payload_metrics_top_level_key_count" => 0,
        "payload_metrics_section_count" => 0,
        "payload_metrics_artifact_body_bytes" => 0,
        "run_scenario_count" => 0,
        "run_trajectory_count" => 0,
        "run_event_result_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external mission validation",
        "checks manifest-driven access wrapper counts, execution status, run metadata, and payload metrics only"
      ]
    },
    "fixture.artifact.result_artifact.ground_track_crossings" => %{
      "id" => "fixture.artifact.result_artifact.ground_track_crossings",
      "model_id" => "artifact.result_artifact.v1",
      "reference_case" => "checked-in ground-track crossing result artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/ground_track_crossings.json",
        "contract" => "result_artifact.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "study_id" => "ground_track_crossings",
        "top_level_key_count" => 15,
        "trajectory_count" => 1,
        "access_window_count" => 0,
        "eclipse_interval_count" => 0,
        "target_visibility_window_count" => 0,
        "ground_track_crossing_count" => 12,
        "maneuver_recommendation_count" => 0,
        "error_count" => 0,
        "has_campaign_plan" => false,
        "execution_report_status" => "completed",
        "execution_report_declared_scenario_count" => 1,
        "execution_report_failed_scenario_count" => 0,
        "payload_metrics_contract" => "result_payload_metrics.v1",
        "payload_metrics_top_level_key_count" => 14,
        "payload_metrics_section_count" => 14,
        "payload_metrics_artifact_body_bytes" => 29_804,
        "run_status" => "completed",
        "run_study_id" => "ground_track_crossings",
        "run_scenario_count" => 1,
        "run_trajectory_count" => 1,
        "run_event_result_count" => 4
      },
      "tolerances" => %{
        "schema_version" => 0,
        "top_level_key_count" => 0,
        "trajectory_count" => 0,
        "access_window_count" => 0,
        "eclipse_interval_count" => 0,
        "target_visibility_window_count" => 0,
        "ground_track_crossing_count" => 0,
        "maneuver_recommendation_count" => 0,
        "error_count" => 0,
        "execution_report_declared_scenario_count" => 0,
        "execution_report_failed_scenario_count" => 0,
        "payload_metrics_top_level_key_count" => 0,
        "payload_metrics_section_count" => 0,
        "payload_metrics_artifact_body_bytes" => 0,
        "run_scenario_count" => 0,
        "run_trajectory_count" => 0,
        "run_event_result_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external mission validation",
        "checks ground-track wrapper counts, execution status, run metadata, and payload metrics only"
      ]
    },
    "fixture.artifact.result_artifact.raise_apogee_search" => %{
      "id" => "fixture.artifact.result_artifact.raise_apogee_search",
      "model_id" => "artifact.result_artifact.v1",
      "reference_case" => "checked-in raise-apogee maneuver search result artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/raise_apogee_search.json",
        "contract" => "result_artifact.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "study_id" => "raise_apogee_search",
        "top_level_key_count" => 19,
        "trajectory_count" => 4,
        "access_window_count" => 0,
        "eclipse_interval_count" => 0,
        "target_visibility_window_count" => 0,
        "ground_track_crossing_count" => 0,
        "maneuver_recommendation_count" => 4,
        "error_count" => 0,
        "has_campaign_plan" => false,
        "has_constraint_report" => true,
        "has_maneuver_review_report" => true,
        "execution_report_status" => "completed",
        "execution_report_declared_scenario_count" => 4,
        "execution_report_failed_scenario_count" => 0,
        "payload_metrics_contract" => "result_payload_metrics.v1",
        "payload_metrics_top_level_key_count" => 18,
        "payload_metrics_section_count" => 18,
        "payload_metrics_artifact_body_bytes" => 34_019,
        "run_status" => "completed",
        "run_study_id" => "raise_apogee_search",
        "run_scenario_count" => 4,
        "run_trajectory_count" => 4,
        "run_event_result_count" => 0
      },
      "tolerances" => %{
        "schema_version" => 0,
        "top_level_key_count" => 0,
        "trajectory_count" => 0,
        "access_window_count" => 0,
        "eclipse_interval_count" => 0,
        "target_visibility_window_count" => 0,
        "ground_track_crossing_count" => 0,
        "maneuver_recommendation_count" => 0,
        "error_count" => 0,
        "execution_report_declared_scenario_count" => 0,
        "execution_report_failed_scenario_count" => 0,
        "payload_metrics_top_level_key_count" => 0,
        "payload_metrics_section_count" => 0,
        "payload_metrics_artifact_body_bytes" => 0,
        "run_scenario_count" => 0,
        "run_trajectory_count" => 0,
        "run_event_result_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external mission validation",
        "checks maneuver-search wrapper counts, nested report presence, execution status, run metadata, and payload metrics only"
      ]
    },
    "fixture.artifact.result_artifact.candidate_refresh_v1" => %{
      "id" => "fixture.artifact.result_artifact.candidate_refresh_v1",
      "model_id" => "artifact.result_artifact.v1",
      "reference_case" => "checked-in candidate-refresh result artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/candidate_refresh_v1.json",
        "contract" => "result_artifact.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "study_id" => "candidate_refresh_v1",
        "top_level_key_count" => 16,
        "trajectory_count" => 1,
        "access_window_count" => 1,
        "target_visibility_window_count" => 1,
        "error_count" => 0,
        "has_candidate_refresh" => true,
        "candidate_refresh_candidate_activity_count" => 2,
        "candidate_refresh_contact_intent_count" => 1,
        "candidate_refresh_refreshed_window_count" => 3,
        "candidate_refresh_warning_count" => 0,
        "execution_report_status" => "completed",
        "execution_report_declared_scenario_count" => 1,
        "execution_report_failed_scenario_count" => 0,
        "payload_metrics_contract" => "result_payload_metrics.v1",
        "payload_metrics_top_level_key_count" => 15,
        "payload_metrics_section_count" => 15,
        "payload_metrics_artifact_body_bytes" => 92_050,
        "run_status" => "completed",
        "run_study_id" => "candidate_refresh_v1",
        "run_scenario_count" => 1,
        "run_trajectory_count" => 1,
        "run_event_result_count" => 3
      },
      "tolerances" => %{
        "schema_version" => 0,
        "top_level_key_count" => 0,
        "trajectory_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "error_count" => 0,
        "candidate_refresh_candidate_activity_count" => 0,
        "candidate_refresh_contact_intent_count" => 0,
        "candidate_refresh_refreshed_window_count" => 0,
        "candidate_refresh_warning_count" => 0,
        "execution_report_declared_scenario_count" => 0,
        "execution_report_failed_scenario_count" => 0,
        "payload_metrics_top_level_key_count" => 0,
        "payload_metrics_section_count" => 0,
        "payload_metrics_artifact_body_bytes" => 0,
        "run_scenario_count" => 0,
        "run_trajectory_count" => 0,
        "run_event_result_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external mission validation",
        "checks candidate-refresh wrapper counts, nested refresh counts, execution status, run metadata, and payload metrics only"
      ]
    },
    "fixture.artifact.result_artifact.candidate_refresh_orbit_data_v1" => %{
      "id" => "fixture.artifact.result_artifact.candidate_refresh_orbit_data_v1",
      "model_id" => "artifact.result_artifact.v1",
      "reference_case" => "checked-in orbit-data candidate-refresh result artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/candidate_refresh_orbit_data_v1.json",
        "contract" => "result_artifact.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "study_id" => "candidate_refresh_orbit_data_v1",
        "top_level_key_count" => 16,
        "trajectory_count" => 1,
        "access_window_count" => 1,
        "target_visibility_window_count" => 1,
        "error_count" => 0,
        "has_candidate_refresh" => true,
        "candidate_refresh_candidate_activity_count" => 2,
        "candidate_refresh_contact_intent_count" => 1,
        "candidate_refresh_refreshed_window_count" => 3,
        "candidate_refresh_warning_count" => 0,
        "execution_report_status" => "completed",
        "execution_report_declared_scenario_count" => 1,
        "execution_report_failed_scenario_count" => 0,
        "payload_metrics_contract" => "result_payload_metrics.v1",
        "payload_metrics_top_level_key_count" => 15,
        "payload_metrics_section_count" => 15,
        "payload_metrics_artifact_body_bytes" => 81_235,
        "run_status" => "completed",
        "run_study_id" => "candidate_refresh_orbit_data_v1",
        "run_scenario_count" => 1,
        "run_trajectory_count" => 1,
        "run_event_result_count" => 3
      },
      "tolerances" => %{
        "schema_version" => 0,
        "top_level_key_count" => 0,
        "trajectory_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "error_count" => 0,
        "candidate_refresh_candidate_activity_count" => 0,
        "candidate_refresh_contact_intent_count" => 0,
        "candidate_refresh_refreshed_window_count" => 0,
        "candidate_refresh_warning_count" => 0,
        "execution_report_declared_scenario_count" => 0,
        "execution_report_failed_scenario_count" => 0,
        "payload_metrics_top_level_key_count" => 0,
        "payload_metrics_section_count" => 0,
        "payload_metrics_artifact_body_bytes" => 0,
        "run_scenario_count" => 0,
        "run_trajectory_count" => 0,
        "run_event_result_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external mission validation",
        "checks orbit-data candidate-refresh wrapper counts, nested refresh counts, execution status, run metadata, and payload metrics only"
      ]
    },
    "fixture.artifact.result_artifact.leo_dispersion_monte_carlo" => %{
      "id" => "fixture.artifact.result_artifact.leo_dispersion_monte_carlo",
      "model_id" => "artifact.result_artifact.v1",
      "reference_case" => "checked-in LEO dispersion Monte Carlo result artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/leo_dispersion_monte_carlo.json",
        "contract" => "result_artifact.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "study_id" => "leo_dispersion_monte_carlo",
        "top_level_key_count" => 19,
        "trajectory_count" => 20,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "error_count" => 0,
        "has_constraint_report" => true,
        "has_monte_carlo_reproducibility_report" => true,
        "execution_report_status" => "completed",
        "execution_report_declared_scenario_count" => 20,
        "execution_report_failed_scenario_count" => 0,
        "payload_metrics_contract" => "result_payload_metrics.v1",
        "payload_metrics_top_level_key_count" => 18,
        "payload_metrics_section_count" => 18,
        "payload_metrics_artifact_body_bytes" => 55_921,
        "run_status" => "completed",
        "run_study_id" => "leo_dispersion_monte_carlo",
        "run_scenario_count" => 20,
        "run_trajectory_count" => 20,
        "run_event_result_count" => 0
      },
      "tolerances" => %{
        "schema_version" => 0,
        "top_level_key_count" => 0,
        "trajectory_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "error_count" => 0,
        "execution_report_declared_scenario_count" => 0,
        "execution_report_failed_scenario_count" => 0,
        "payload_metrics_top_level_key_count" => 0,
        "payload_metrics_section_count" => 0,
        "payload_metrics_artifact_body_bytes" => 0,
        "run_scenario_count" => 0,
        "run_trajectory_count" => 0,
        "run_event_result_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external mission validation",
        "checks Monte Carlo wrapper counts, nested report presence, execution status, run metadata, and payload metrics only"
      ]
    },
    "fixture.artifact.result_artifact.mission_plan_checkout" => %{
      "id" => "fixture.artifact.result_artifact.mission_plan_checkout",
      "model_id" => "artifact.result_artifact.v1",
      "reference_case" => "checked-in mission-plan checkout result artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/mission_plan_checkout.json",
        "contract" => "result_artifact.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "study_id" => "mission_plan_checkout",
        "top_level_key_count" => 16,
        "trajectory_count" => 1,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "maneuver_recommendation_count" => 1,
        "error_count" => 0,
        "has_maneuver_review_report" => true,
        "execution_report_status" => "completed",
        "execution_report_declared_scenario_count" => 1,
        "execution_report_failed_scenario_count" => 0,
        "payload_metrics_contract" => "result_payload_metrics.v1",
        "payload_metrics_top_level_key_count" => 15,
        "payload_metrics_section_count" => 15,
        "payload_metrics_artifact_body_bytes" => 49_676,
        "run_status" => "completed",
        "run_study_id" => "mission_plan_checkout",
        "run_scenario_count" => 1,
        "run_trajectory_count" => 1,
        "run_event_result_count" => 0
      },
      "tolerances" => %{
        "schema_version" => 0,
        "top_level_key_count" => 0,
        "trajectory_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "maneuver_recommendation_count" => 0,
        "error_count" => 0,
        "execution_report_declared_scenario_count" => 0,
        "execution_report_failed_scenario_count" => 0,
        "payload_metrics_top_level_key_count" => 0,
        "payload_metrics_section_count" => 0,
        "payload_metrics_artifact_body_bytes" => 0,
        "run_scenario_count" => 0,
        "run_trajectory_count" => 0,
        "run_event_result_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external mission validation",
        "checks mission-plan checkout wrapper counts, maneuver review presence, execution status, run metadata, and payload metrics only"
      ]
    }
  }

  def all, do: @fixtures
end
