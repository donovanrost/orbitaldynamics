defmodule OrbitalDynamics.Validation.ReferenceFixtures do
  @moduledoc false

  @candidate_refresh_source_report_input_order Enum.join(
                                                 [
                                                   "station_calendar_report",
                                                   "station_calendar_precedence_summary",
                                                   "contact_intent_summary",
                                                   "resource_projection_report",
                                                   "resource_projection_flow_summary",
                                                   "resource_filter_report",
                                                   "resource_filter_summary",
                                                   "contact_filter_report",
                                                   "link_capacity_summary",
                                                   "relay_data_path_summary",
                                                   "timeline_feedback_report",
                                                   "operational_timeline_report",
                                                   "timeline_integrity_report",
                                                   "timeline_activity_precondition_summary",
                                                   "timeline_preservation_report",
                                                   "timeline_diff_report",
                                                   "timeline_diff_summary",
                                                   "timeline_lifecycle_state_summary",
                                                   "timeline_dependency_impact_summary",
                                                   "timeline_publication_summary",
                                                   "timeline_transition_application_report",
                                                   "timeline_transition_application_summary",
                                                   "objective_satisfaction_report",
                                                   "objective_tradeoff_report",
                                                   "score_term_report",
                                                   "constraint_report",
                                                   "candidate_diff_report",
                                                   "candidate_rejection_report",
                                                   "freshness_report",
                                                   "refresh_budget_report",
                                                   "schema_validation_report",
                                                   "schema_validation_batch_report",
                                                   "operational_readiness_report",
                                                   "operational_import_eligibility_summary",
                                                   "operational_readiness_gate_summary",
                                                   "operational_execution_boundary_summary",
                                                   "command_window_report",
                                                   "maneuver_review_report",
                                                   "provider_counteroffer_report",
                                                   "provider_counteroffer_review_summary",
                                                   "provider_counteroffer_import_readiness_summary",
                                                   "provider_counteroffer_plan_impact_summary",
                                                   "contact_allocation_report",
                                                   "contact_allocation_summary",
                                                   "contact_allocation_station_pressure_summary",
                                                   "contact_allocation_reservation_conflict_summary",
                                                   "contact_allocation_capacity_pack_summary",
                                                   "contact_allocation_provider_reservation_request_summary",
                                                   "station_reservation_report",
                                                   "station_reservation_review_summary",
                                                   "station_reservation_hold_summary",
                                                   "station_reservation_hold_import_readiness_summary",
                                                   "contact_contention_report",
                                                   "contact_contention_resolution_report",
                                                   "contact_contention_resolution_summary",
                                                   "link_capacity_report",
                                                   "quality_gate_report",
                                                   "operational_quality_gate_summary",
                                                   "operational_quality_gate_unavailable_resource_summary",
                                                   "operational_quality_gate_operator_training_summary",
                                                   "operational_quality_gate_schema_validation_summary",
                                                   "operational_quality_gate_import_readiness_summary",
                                                   "model_acceptance_report",
                                                   "validation_safety_case_summary"
                                                 ],
                                                 "|"
                                               )

  @fixtures %{
    "fixture.event.access.equator_overhead_120s" => %{
      "id" => "fixture.event.access.equator_overhead_120s",
      "model_id" => "event.access_windows",
      "reference_case" => "manual three-sample equatorial overhead access window",
      "validation_level" => "analysis",
      "fixture_type" => "curated_internal_regression",
      "inputs" => %{
        "central_body" => "earth",
        "ground_station" => %{
          "id" => "equator",
          "latitude_deg" => 0.0,
          "longitude_deg" => 0.0,
          "minimum_elevation_deg" => 0.0
        },
        "sample_epochs_s" => [0.0, 60.0, 120.0],
        "sample_positions" => [
          "overhead_station_500km",
          "overhead_station_500km",
          "opposite_earth_500km"
        ]
      },
      "expected" => %{
        "window_count" => 1,
        "first_window_starts_at_s" => 0.0,
        "first_window_ends_at_s" => 89.45807391804992,
        "first_window_duration_s" => 89.45807391804992,
        "first_window_sample_count" => 2,
        "first_window_max_elevation_deg" => 90.0
      },
      "tolerances" => %{
        "window_count" => 0,
        "first_window_starts_at_s" => 1.0e-12,
        "first_window_ends_at_s" => 1.0e-9,
        "first_window_duration_s" => 1.0e-9,
        "first_window_sample_count" => 0,
        "first_window_max_elevation_deg" => 1.0e-9
      },
      "evidence" => [
        "generated by OrbitalDynamics.EventDetectors.AccessWindows",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2"
      ],
      "known_limits" => [
        "internal regression fixture, not an external truth model",
        "covers simple spherical Earth access geometry only"
      ]
    },
    "fixture.event.eclipse.cylindrical_shadow_120s" => %{
      "id" => "fixture.event.eclipse.cylindrical_shadow_120s",
      "model_id" => "event.eclipses",
      "reference_case" => "manual three-sample cylindrical Earth-shadow interval",
      "validation_level" => "analysis",
      "fixture_type" => "curated_internal_regression",
      "inputs" => %{
        "central_body" => "earth",
        "sun_direction" => [1.0, 0.0, 0.0],
        "sample_epochs_s" => [0.0, 60.0, 120.0],
        "sample_positions" => [
          "anti_sunward_inside_shadow_500km",
          "anti_sunward_inside_shadow_500km",
          "sunward_500km"
        ]
      },
      "expected" => %{
        "interval_count" => 1,
        "first_interval_starts_at_s" => 0.0,
        "first_interval_ends_at_s" => 88.8684602035115,
        "first_interval_duration_s" => 88.8684602035115,
        "first_interval_sample_count" => 2,
        "first_interval_minimum_shadow_axis_distance_km" => 0.0,
        "first_interval_maximum_shadow_margin_km" => 6378.1363
      },
      "tolerances" => %{
        "interval_count" => 0,
        "first_interval_starts_at_s" => 1.0e-12,
        "first_interval_ends_at_s" => 1.0e-9,
        "first_interval_duration_s" => 1.0e-9,
        "first_interval_sample_count" => 0,
        "first_interval_minimum_shadow_axis_distance_km" => 1.0e-12,
        "first_interval_maximum_shadow_margin_km" => 1.0e-9
      },
      "evidence" => [
        "generated by OrbitalDynamics.EventDetectors.Eclipses",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2"
      ],
      "known_limits" => [
        "internal regression fixture, not an external truth model",
        "covers cylindrical shadow geometry with fixed Sun direction only"
      ]
    },
    "fixture.event.target_visibility.equator_overhead_120s" => %{
      "id" => "fixture.event.target_visibility.equator_overhead_120s",
      "model_id" => "event.target_visibility",
      "reference_case" => "manual three-sample equatorial target visibility window",
      "validation_level" => "analysis",
      "fixture_type" => "curated_internal_regression",
      "inputs" => %{
        "central_body" => "earth",
        "target" => %{
          "id" => "target_a",
          "latitude_deg" => 0.0,
          "longitude_deg" => 0.0,
          "minimum_elevation_deg" => 0.0,
          "priority" => 4.0
        },
        "sample_epochs_s" => [0.0, 60.0, 120.0],
        "sample_positions" => [
          "overhead_target_500km",
          "overhead_target_500km",
          "opposite_earth_500km"
        ]
      },
      "expected" => %{
        "window_count" => 1,
        "first_window_starts_at_s" => 0.0,
        "first_window_ends_at_s" => 89.45807391804992,
        "first_window_duration_s" => 89.45807391804992,
        "first_window_sample_count" => 2,
        "first_window_max_elevation_deg" => 90.0,
        "target_priority" => 4.0
      },
      "tolerances" => %{
        "window_count" => 0,
        "first_window_starts_at_s" => 1.0e-12,
        "first_window_ends_at_s" => 1.0e-9,
        "first_window_duration_s" => 1.0e-9,
        "first_window_sample_count" => 0,
        "first_window_max_elevation_deg" => 1.0e-9,
        "target_priority" => 0
      },
      "evidence" => [
        "generated by OrbitalDynamics.EventDetectors.TargetVisibility",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2"
      ],
      "known_limits" => [
        "internal regression fixture, not an external truth model",
        "covers simple spherical Earth target geometry only"
      ]
    },
    "fixture.event.ground_track.latitude_equator_60s" => %{
      "id" => "fixture.event.ground_track.latitude_equator_60s",
      "model_id" => "event.ground_track_crossings",
      "reference_case" => "manual two-sample geocentric equator crossing",
      "validation_level" => "analysis",
      "fixture_type" => "curated_internal_regression",
      "inputs" => %{
        "crossing" => "latitude",
        "latitude_deg" => 0.0,
        "sample_epochs_s" => [0.0, 60.0],
        "sample_positions" => [
          "unit_radius_latitude_minus_45_deg",
          "unit_radius_latitude_plus_45_deg"
        ]
      },
      "expected" => %{
        "crossing_count" => 1,
        "first_crossing_epoch_s" => 30.0,
        "first_crossing_target_deg" => 0.0,
        "first_crossing_direction" => "northbound"
      },
      "tolerances" => %{
        "crossing_count" => 0,
        "first_crossing_epoch_s" => 1.0e-12,
        "first_crossing_target_deg" => 0,
        "first_crossing_direction" => 0
      },
      "evidence" => [
        "generated by OrbitalDynamics.EventDetectors.GroundTrackCrossings",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2"
      ],
      "known_limits" => [
        "internal regression fixture, not an external truth model",
        "geocentric inertial crossing only"
      ]
    },
    "fixture.j2.circular_leo_600s" => %{
      "id" => "fixture.j2.circular_leo_600s",
      "model_id" => "propagator.j2",
      "reference_case" => "7000 km circular equatorial LEO propagated for 600 s with J2",
      "validation_level" => "educational",
      "fixture_type" => "curated_internal_regression",
      "inputs" => %{
        "central_body" => "earth",
        "initial_position_km" => [7000.0, 0.0, 0.0],
        "initial_velocity_km_s" => [0.0, 7.546053290107542, 0.0],
        "duration_s" => 600.0,
        "output_step_s" => 120.0,
        "propagator_opts" => %{"max_step_s" => 10.0}
      },
      "expected" => %{
        "sample_count" => 6,
        "final_epoch_s" => 600.0,
        "final_position_km" => [5584.070997735894, 4217.992693724331, 0.0],
        "final_velocity_km_s" => [-4.554400191561496, 6.019254825378945, 0.0]
      },
      "tolerances" => %{
        "sample_count" => 0,
        "final_epoch_s" => 1.0e-12,
        "final_position_km" => 1.0e-5,
        "final_velocity_km_s" => 1.0e-8
      },
      "evidence" => [
        "generated by OrbitalDynamics.Propagators.J2 fixed-step RK4",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2"
      ],
      "known_limits" => [
        "internal regression fixture, not an external truth model",
        "J2 is the only perturbation",
        "covers one near-circular equatorial LEO case only"
      ]
    },
    "fixture.two_body.circular_leo_600s" => %{
      "id" => "fixture.two_body.circular_leo_600s",
      "model_id" => "propagator.two_body",
      "reference_case" => "7000 km circular equatorial LEO propagated for 600 s",
      "validation_level" => "educational",
      "fixture_type" => "curated_internal_regression",
      "inputs" => %{
        "central_body" => "earth",
        "initial_position_km" => [7000.0, 0.0, 0.0],
        "initial_velocity_km_s" => [0.0, 7.546053290107542, 0.0],
        "duration_s" => 600.0,
        "output_step_s" => 120.0,
        "propagator_opts" => %{"max_step_s" => 10.0}
      },
      "expected" => %{
        "sample_count" => 6,
        "final_epoch_s" => 600.0,
        "final_position_km" => [5586.094941787218, 4218.4764189319985, 0.0],
        "final_velocity_km_s" => [-4.54754969549011, 6.021852873409085, 0.0]
      },
      "tolerances" => %{
        "sample_count" => 0,
        "final_epoch_s" => 1.0e-12,
        "final_position_km" => 1.0e-6,
        "final_velocity_km_s" => 1.0e-9
      },
      "evidence" => [
        "generated by OrbitalDynamics.Propagators.TwoBody fixed-step RK4",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2"
      ],
      "known_limits" => [
        "internal regression fixture, not an external truth model",
        "covers one near-circular LEO case only"
      ]
    },
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
    },
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
        "payload_metrics_artifact_body_bytes" => 323_398,
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
    },
    "fixture.artifact.campaign_repair.leo_constellation_v2" => %{
      "id" => "fixture.artifact.campaign_repair.leo_constellation_v2",
      "model_id" => "artifact.campaign_repair.v2",
      "reference_case" => "checked-in LEO constellation campaign repair artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/leo_constellation_campaign_repair_v2.json",
        "contract" => "campaign_repair.v2"
      },
      "expected" => %{
        "schema_version" => 2,
        "planner" => "OrbitalDynamics.CampaignPlanner.V2",
        "activity_count" => 0,
        "delta_count" => 1,
        "approval_requirement_count" => 1,
        "source_candidate_count" => 0,
        "source_candidate_rejection_report_count" => 1,
        "source_candidate_rejection_row_count" => 1,
        "source_candidate_rejection_rejected_count" => 1,
        "source_candidate_rejection_reviewable_count" => 1,
        "source_contact_intent_count" => 0,
        "source_resource_summary_count" => 1,
        "operator_review_candidate_rejection_review_count" => 1,
        "cadence_import_candidate_rejection_row_count" => 1,
        "warning_count" => 3,
        "policy_decision_contract" => "policy_decision.v1"
      },
      "tolerances" => %{
        "schema_version" => 0,
        "activity_count" => 0,
        "delta_count" => 0,
        "approval_requirement_count" => 0,
        "source_candidate_count" => 0,
        "source_candidate_rejection_report_count" => 0,
        "source_candidate_rejection_row_count" => 0,
        "source_candidate_rejection_rejected_count" => 0,
        "source_candidate_rejection_reviewable_count" => 0,
        "source_contact_intent_count" => 0,
        "source_resource_summary_count" => 0,
        "operator_review_candidate_rejection_review_count" => 0,
        "cadence_import_candidate_rejection_row_count" => 0,
        "warning_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external mission validation",
        "checks contract shape and stable product counts only"
      ]
    },
    "fixture.artifact.campaign_request_lint.v1" => %{
      "id" => "fixture.artifact.campaign_request_lint.v1",
      "model_id" => "artifact.campaign_request_lint.v1",
      "reference_case" => "checked-in campaign request lint report artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/campaign_request_lint_v1.json",
        "contract" => "campaign_request_lint.v1"
      },
      "expected" => %{
        "schema_contract" => "campaign_request_lint.v1",
        "status" => "pass",
        "validation_mode" => "campaign_request_lint",
        "request_type" => "repair",
        "lint_task" => "mix orbital_dynamics.campaign.lint --type repair --request PATH",
        "semantic_validator" => "OrbitalDynamics.CampaignPlanner.request_validation_report/3",
        "error_count" => 0,
        "error_row_count" => 0,
        "source_plan_status" => "pass",
        "source_plan_contract" => "campaign_plan.v1"
      },
      "tolerances" => %{
        "error_count" => 0,
        "error_row_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not full campaign request validation",
        "checks request lint status/counts and source-plan routing only"
      ]
    },
    "fixture.artifact.campaign_strategy.leo_constellation_v3" => %{
      "id" => "fixture.artifact.campaign_strategy.leo_constellation_v3",
      "model_id" => "artifact.campaign_strategy.v3",
      "reference_case" => "checked-in LEO constellation campaign strategy artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/leo_constellation_campaign_strategy_v3.json",
        "contract" => "campaign_strategy.v3"
      },
      "expected" => %{
        "schema_version" => 3,
        "planner" => "OrbitalDynamics.CampaignPlanner.V3",
        "branch_count" => 27,
        "recommended_branch_id" => "derived_urgent_target_target_hot",
        "ranked_branch_count" => 7,
        "approval_status" => "operator_review_required",
        "warning_count" => 0,
        "score_term_report_model" => "strategy_branch_score_terms",
        "score_term_report_source" => "campaign_strategy.branches.score_terms",
        "score_term_report_row_count" => 1674,
        "score_term_report_derived_row_count" => 1674,
        "score_term_report_selected_row_count" => 62,
        "score_term_report_key_count" => 62,
        "score_term_report_key_counts" => %{
          "approval_boundary_pressure_penalty" => 1,
          "approval_load_penalty" => 1,
          "asset_balance_score" => 1,
          "battery_depletion_pressure_penalty" => 1,
          "branch_probability" => 1,
          "candidate_diff_pressure_penalty" => 1,
          "candidate_rejection_pressure_penalty" => 1,
          "command_window_pressure_penalty" => 1,
          "contact_allocation_pressure_penalty" => 1,
          "contact_contention_pressure_penalty" => 1,
          "contact_filter_pressure_penalty" => 1,
          "contact_intent_pressure_penalty" => 1,
          "coverage_score" => 1,
          "downlink_completion_score" => 1,
          "execution_feedback_pressure_penalty" => 1,
          "expected_score" => 1,
          "feedback_adjustment_score" => 1,
          "fuel_preservation_score" => 1,
          "import_readiness_pressure_penalty" => 1,
          "latency_penalty" => 1,
          "link_capacity_pressure_penalty" => 1,
          "maneuver_review_pressure_penalty" => 1,
          "mission_value_score" => 1,
          "model_acceptance_pressure_penalty" => 1,
          "objective_gap_pressure_penalty" => 1,
          "operational_readiness_pressure_penalty" => 1,
          "operational_timeline_pressure_penalty" => 1,
          "operator_training_pressure_penalty" => 1,
          "priority_commitment_score" => 1,
          "provider_counteroffer_pressure_penalty" => 1,
          "provider_reservation_request_pressure_penalty" => 1,
          "quality_gate_pressure_penalty" => 1,
          "raw_score" => 1,
          "relay_data_path_pressure_penalty" => 1,
          "refresh_budget_pressure_penalty" => 1,
          "refresh_freshness_pressure_penalty" => 1,
          "resource_availability_pressure_penalty" => 1,
          "resource_filter_pressure_penalty" => 1,
          "resource_margin_pressure_penalty" => 1,
          "resource_projection_pressure_penalty" => 1,
          "resource_score" => 1,
          "revisit_score" => 1,
          "risk_penalty" => 1,
          "schedule_stability_penalty" => 1,
          "schema_validation_pressure_penalty" => 1,
          "station_calendar_pressure_penalty" => 1,
          "station_reservation_conflict_pressure_penalty" => 1,
          "station_reservation_expiration_pressure_penalty" => 1,
          "storage_downlink_pressure_penalty" => 1,
          "timeline_activity_state_pressure_penalty" => 1,
          "timeline_dependency_impact_pressure_penalty" => 1,
          "timeline_diff_pressure_penalty" => 1,
          "timeline_feedback_pressure_penalty" => 1,
          "timeline_integrity_pressure_penalty" => 1,
          "timeline_lifecycle_pressure_penalty" => 1,
          "timeline_precondition_pressure_penalty" => 1,
          "timeline_preservation_pressure_penalty" => 1,
          "timeline_pressure_penalty" => 1,
          "timeline_publication_pressure_penalty" => 1,
          "timeline_transition_application_pressure_penalty" => 1,
          "validation_refresh_pressure_penalty" => 1,
          "validation_safety_case_pressure_penalty" => 1
        },
        "score_term_report_row_derived_key_counts" => %{
          "approval_boundary_pressure_penalty" => 27,
          "approval_load_penalty" => 27,
          "asset_balance_score" => 27,
          "battery_depletion_pressure_penalty" => 27,
          "branch_probability" => 27,
          "candidate_diff_pressure_penalty" => 27,
          "candidate_rejection_pressure_penalty" => 27,
          "command_window_pressure_penalty" => 27,
          "contact_allocation_pressure_penalty" => 27,
          "contact_contention_pressure_penalty" => 27,
          "contact_filter_pressure_penalty" => 27,
          "contact_intent_pressure_penalty" => 27,
          "coverage_score" => 27,
          "downlink_completion_score" => 27,
          "execution_feedback_pressure_penalty" => 27,
          "expected_score" => 27,
          "feedback_adjustment_score" => 27,
          "fuel_preservation_score" => 27,
          "import_readiness_pressure_penalty" => 27,
          "latency_penalty" => 27,
          "link_capacity_pressure_penalty" => 27,
          "maneuver_review_pressure_penalty" => 27,
          "mission_value_score" => 27,
          "model_acceptance_pressure_penalty" => 27,
          "objective_gap_pressure_penalty" => 27,
          "operational_readiness_pressure_penalty" => 27,
          "operational_timeline_pressure_penalty" => 27,
          "operator_training_pressure_penalty" => 27,
          "priority_commitment_score" => 27,
          "provider_counteroffer_pressure_penalty" => 27,
          "provider_reservation_request_pressure_penalty" => 27,
          "quality_gate_pressure_penalty" => 27,
          "raw_score" => 27,
          "relay_data_path_pressure_penalty" => 27,
          "refresh_budget_pressure_penalty" => 27,
          "refresh_freshness_pressure_penalty" => 27,
          "resource_availability_pressure_penalty" => 27,
          "resource_filter_pressure_penalty" => 27,
          "resource_margin_pressure_penalty" => 27,
          "resource_projection_pressure_penalty" => 27,
          "resource_score" => 27,
          "revisit_score" => 27,
          "risk_penalty" => 27,
          "schedule_stability_penalty" => 27,
          "schema_validation_pressure_penalty" => 27,
          "station_calendar_pressure_penalty" => 27,
          "station_reservation_conflict_pressure_penalty" => 27,
          "station_reservation_expiration_pressure_penalty" => 27,
          "storage_downlink_pressure_penalty" => 27,
          "timeline_activity_state_pressure_penalty" => 27,
          "timeline_dependency_impact_pressure_penalty" => 27,
          "timeline_diff_pressure_penalty" => 27,
          "timeline_feedback_pressure_penalty" => 27,
          "timeline_integrity_pressure_penalty" => 27,
          "timeline_lifecycle_pressure_penalty" => 27,
          "timeline_precondition_pressure_penalty" => 27,
          "timeline_preservation_pressure_penalty" => 27,
          "timeline_pressure_penalty" => 27,
          "timeline_publication_pressure_penalty" => 27,
          "timeline_transition_application_pressure_penalty" => 27,
          "validation_refresh_pressure_penalty" => 27,
          "validation_safety_case_pressure_penalty" => 27
        },
        "score_term_report_validation_refresh_pressure_row_count" => 27,
        "score_term_report_score_term_source" => "campaign_strategy.branches.score_terms",
        "score_term_report_model_limit_count" => 4
      },
      "tolerances" => %{
        "schema_version" => 0,
        "branch_count" => 0,
        "ranked_branch_count" => 0,
        "warning_count" => 0,
        "score_term_report_row_count" => 0,
        "score_term_report_derived_row_count" => 0,
        "score_term_report_selected_row_count" => 0,
        "score_term_report_key_count" => 0,
        "score_term_report_validation_refresh_pressure_row_count" => 0,
        "score_term_report_model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external mission validation",
        "checks contract shape and stable product counts only"
      ]
    },
    "fixture.artifact.capability_catalog.v1" => %{
      "id" => "fixture.artifact.capability_catalog.v1",
      "model_id" => "artifact.capability_catalog.v1",
      "reference_case" => "checked-in public capability catalog artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/capability_catalog_v1.json",
        "contract" => "capability_catalog.v1"
      },
      "expected" => %{
        "schema_contract" => "capability_catalog.v1",
        "schema_version" => 1,
        "model" => "public_capability_catalog",
        "top_level_family_count" => 7,
        "planning_capability_count" => 6,
        "operations_capability_count" => 17,
        "validation_family_count" => 2,
        "artifact_contract_count" => 121,
        "artifact_contract_list_count" => 121,
        "compatibility_policy_version" => 1,
        "identity_policy_version" => 1,
        "public_validation_facade_count" => 13,
        "optimizer_model" => "per_spacecraft_greedy_non_overlapping",
        "optimizer_contract" => "optimizer_contract.v1",
        "cadence_import_contract" => "cadence_import_manifest.v1",
        "operational_readiness_contract" => "operational_readiness_report.v1",
        "station_calendar_reservation_contract" => "station_reservation_report.v1",
        "candidate_refresh_input_count" => 81,
        "candidate_refresh_source_report_input_count" => 64,
        "candidate_refresh_source_report_input_order" =>
          @candidate_refresh_source_report_input_order,
        "candidate_refresh_source_report_helper_count" => 40
      },
      "tolerances" => %{
        "schema_version" => 0,
        "top_level_family_count" => 0,
        "planning_capability_count" => 0,
        "operations_capability_count" => 0,
        "validation_family_count" => 0,
        "artifact_contract_count" => 0,
        "artifact_contract_list_count" => 0,
        "compatibility_policy_version" => 0,
        "identity_policy_version" => 0,
        "public_validation_facade_count" => 0,
        "candidate_refresh_input_count" => 0,
        "candidate_refresh_source_report_input_count" => 0,
        "candidate_refresh_source_report_helper_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not full capability certification",
        "checks public catalog counts and key contract routing only"
      ]
    },
    "fixture.artifact.candidate_refresh.v1" => %{
      "id" => "fixture.artifact.candidate_refresh.v1",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" => "checked-in candidate refresh artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/candidate_refresh_v1.json",
        "contract" => "candidate_refresh.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_refresh.v1",
        "schema_version" => 1,
        "planner" => "OrbitalDynamics.CandidateRefresh.V1",
        "candidate_count" => 2,
        "contact_intent_count" => 1,
        "access_window_count" => 1,
        "target_visibility_window_count" => 1,
        "eclipse_interval_count" => 0,
        "warning_count" => 0,
        "source_report_family_count" => 0,
        "source_report_row_count" => 0
      },
      "tolerances" => %{
        "schema_version" => 0,
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "warning_count" => 0,
        "source_report_family_count" => 0,
        "source_report_row_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external mission validation",
        "checks candidate-refresh product counts and source-report provenance counts only"
      ]
    },
    "fixture.artifact.candidate_refresh.candidate_rejection_replay" => %{
      "id" => "fixture.artifact.candidate_refresh.candidate_rejection_replay",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" =>
        "generated candidate refresh replay of candidate-rejection source-report provenance",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_candidate_refresh_candidate_rejection_fixture",
        "contract" => "candidate_refresh.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_refresh.v1",
        "schema_version" => 1,
        "planner" => "OrbitalDynamics.CandidateRefresh.V1",
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 1,
        "source_report_row_count" => 2,
        "source_candidate_rejection_report_count" => 1,
        "source_candidate_rejection_row_count" => 2,
        "source_candidate_rejection_rejected_count" => 2,
        "source_candidate_rejection_reviewable_count" => 1,
        "source_candidate_rejection_invalid_candidate_input_count" => 1,
        "source_candidate_rejection_rejection_reason_counts" => %{
          "invalid_candidate_input" => 1,
          "station_reserved" => 1
        },
        "source_candidate_rejection_required_operator_action_counts" => %{
          "none" => 1,
          "review_candidate_rejection" => 1
        },
        "source_candidate_rejection_candidate_id_counts" => %{
          "bad_candidate" => 1,
          "dl_reserved" => 1
        },
        "source_candidate_rejection_ground_station_counts" => %{
          "dss_43" => 1,
          "equator_prime" => 1
        },
        "source_candidate_rejection_trust_boundary_status" => "declared",
        "source_candidate_rejection_branch_local_rejection_pressure" => true,
        "source_candidate_rejection_branch_local_review_pressure" => true,
        "source_candidate_rejection_branch_local_invalid_input_pressure" => true
      },
      "tolerances" => %{
        "schema_version" => 0,
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 0,
        "source_report_row_count" => 0,
        "source_candidate_rejection_report_count" => 0,
        "source_candidate_rejection_row_count" => 0,
        "source_candidate_rejection_rejected_count" => 0,
        "source_candidate_rejection_reviewable_count" => 0,
        "source_candidate_rejection_invalid_candidate_input_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not candidate selection validation",
        "checks candidate-refresh replay of candidate-rejection provenance without candidate selection, import approval, or Cadence writes"
      ]
    },
    "fixture.artifact.candidate_refresh.freshness_replay" => %{
      "id" => "fixture.artifact.candidate_refresh.freshness_replay",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" =>
        "generated candidate refresh replay of freshness source-report provenance",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_candidate_refresh_freshness_fixture",
        "contract" => "candidate_refresh.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_refresh.v1",
        "schema_version" => 1,
        "planner" => "OrbitalDynamics.CandidateRefresh.V1",
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 1,
        "source_report_row_count" => 2,
        "source_freshness_report_count" => 2,
        "source_freshness_row_count" => 2,
        "source_freshness_path_keys" => "source_freshness_report[0]|source_freshness_report[1]",
        "source_freshness_status_counts" => %{
          "stale" => 1,
          "unknown" => 1
        },
        "source_freshness_stale_reason_count" => 2,
        "source_freshness_stale_reason_keys" =>
          "accepted_snapshot_older_than_policy|horizon_start_before_now",
        "source_freshness_stale_reason_counts" => %{
          "accepted_snapshot_older_than_policy" => 1,
          "horizon_start_before_now" => 1
        },
        "source_freshness_unknown_reason_count" => 1,
        "source_freshness_unknown_reason_keys" => "missing_generated_at",
        "source_freshness_unknown_reason_counts" => %{"missing_generated_at" => 1},
        "source_freshness_trust_boundary_status" => "declared",
        "source_freshness_branch_local_stale_pressure" => true,
        "source_freshness_branch_local_unknown_pressure" => true,
        "source_freshness_branch_local_freshness_pressure" => true
      },
      "tolerances" => %{
        "schema_version" => 0,
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 0,
        "source_report_row_count" => 0,
        "source_freshness_report_count" => 0,
        "source_freshness_row_count" => 0,
        "source_freshness_stale_reason_count" => 0,
        "source_freshness_unknown_reason_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not freshness policy validation",
        "checks candidate-refresh replay of freshness provenance without refresh mutation, import approval, or Cadence writes"
      ]
    },
    "fixture.artifact.candidate_refresh.refresh_budget_replay" => %{
      "id" => "fixture.artifact.candidate_refresh.refresh_budget_replay",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" =>
        "generated candidate refresh replay of refresh-budget source-report provenance",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_candidate_refresh_refresh_budget_fixture",
        "contract" => "candidate_refresh.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_refresh.v1",
        "schema_version" => 1,
        "planner" => "OrbitalDynamics.CandidateRefresh.V1",
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 1,
        "source_report_row_count" => 2,
        "source_refresh_budget_report_count" => 2,
        "source_refresh_budget_row_count" => 2,
        "source_refresh_budget_path_keys" =>
          "source_refresh_budget_report[0]|source_refresh_budget_report[1]",
        "source_refresh_budget_input_candidate_count" => 5,
        "source_refresh_budget_kept_candidate_count" => 3,
        "source_refresh_budget_dropped_candidate_count" => 2,
        "source_refresh_budget_invalid_candidate_limit_policy_count" => 1,
        "source_refresh_budget_invalid_candidate_limit_policy_reason_counts" => %{
          "max_candidate_activities_must_be_integer" => 1
        },
        "source_refresh_budget_kept_candidate_id_keys" => "candidate_a|candidate_b|candidate_e",
        "source_refresh_budget_dropped_candidate_id_keys" => "candidate_c|candidate_d",
        "source_refresh_budget_trust_boundary_status" => "declared",
        "source_refresh_budget_branch_local_budget_pressure" => true,
        "source_refresh_budget_branch_local_dropped_candidate_pressure" => true,
        "source_refresh_budget_branch_local_invalid_limit_pressure" => true,
        "source_refresh_budget_branch_local_candidate_limit_applied" => true
      },
      "tolerances" => %{
        "schema_version" => 0,
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 0,
        "source_report_row_count" => 0,
        "source_refresh_budget_report_count" => 0,
        "source_refresh_budget_row_count" => 0,
        "source_refresh_budget_input_candidate_count" => 0,
        "source_refresh_budget_kept_candidate_count" => 0,
        "source_refresh_budget_dropped_candidate_count" => 0,
        "source_refresh_budget_invalid_candidate_limit_policy_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not refresh-budget policy validation",
        "checks candidate-refresh replay of refresh-budget provenance without refresh mutation, import approval, or Cadence writes"
      ]
    },
    "fixture.artifact.candidate_refresh.station_calendar_replay" => %{
      "id" => "fixture.artifact.candidate_refresh.station_calendar_replay",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" =>
        "generated candidate refresh replay of station-calendar provider-contention provenance",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_candidate_refresh_station_calendar_fixture",
        "contract" => "candidate_refresh.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_refresh.v1",
        "schema_version" => 1,
        "planner" => "OrbitalDynamics.CandidateRefresh.V1",
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 1,
        "source_report_row_count" => 4,
        "source_station_calendar_report_count" => 1,
        "source_station_calendar_row_count" => 4,
        "source_station_calendar_path_keys" => "source_station_calendar_report",
        "source_station_calendar_affected_contact_count" => 3,
        "source_station_calendar_provider_calendar_contention_group_count" => 1,
        "source_station_calendar_provider_calendar_contention_group_id_keys" =>
          "station_calendar_provider_contention:equator_prime:1",
        "source_station_calendar_provider_calendar_contention_source_entry_id_keys" =>
          "provider_a|provider_b",
        "source_station_calendar_provider_calendar_contention_provider_entry_id_keys" =>
          "provider_entry_ops|provider_entry_partner",
        "source_station_calendar_provider_calendar_contention_provider_counts" => %{
          "ops_calendar" => 1,
          "partner_calendar" => 1
        },
        "source_station_calendar_provider_calendar_contention_ground_station_counts" => %{
          "dss_43" => 1,
          "equator_prime" => 1
        },
        "source_station_calendar_provider_calendar_contention_direction_counts" => %{
          "downlink" => 1,
          "tracking" => 1
        },
        "source_station_calendar_provider_calendar_contention_minimum_capacity_fraction" => 0.25,
        "source_station_calendar_affected_contact_ground_station_counts" => %{
          "dss_43" => 1,
          "equator_prime" => 2
        },
        "source_station_calendar_affected_contact_availability_counts" => %{
          "reduced_capacity" => 1,
          "reserved" => 1,
          "unavailable" => 1
        },
        "source_station_calendar_direction_counts" => %{
          "downlink" => 2,
          "uplink" => 1
        },
        "source_station_calendar_status_counts" => %{
          "reduced_capacity" => 1,
          "reserved" => 1,
          "unavailable" => 1
        },
        "source_station_calendar_trust_boundary_status" => "declared",
        "source_station_calendar_branch_local_station_calendar_pressure" => true,
        "source_station_calendar_branch_local_affected_contact_pressure" => true,
        "source_station_calendar_branch_local_provider_contention_pressure" => true,
        "source_station_calendar_branch_local_station_availability_pressure" => true
      },
      "tolerances" => %{
        "schema_version" => 0,
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 0,
        "source_report_row_count" => 0,
        "source_station_calendar_report_count" => 0,
        "source_station_calendar_row_count" => 0,
        "source_station_calendar_affected_contact_count" => 0,
        "source_station_calendar_provider_calendar_contention_group_count" => 0,
        "source_station_calendar_provider_calendar_contention_minimum_capacity_fraction" => 0.0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not station-calendar policy validation",
        "checks candidate-refresh replay of station-calendar provenance without schedule mutation, candidate selection, import approval, or Cadence writes"
      ]
    },
    "fixture.artifact.candidate_refresh.contact_allocation_contradiction_replay" => %{
      "id" => "fixture.artifact.candidate_refresh.contact_allocation_contradiction_replay",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" =>
        "generated candidate refresh replay of contradictory provider-calendar, reservation, and contact-allocation evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_candidate_refresh_contact_allocation_contradiction_fixture",
        "contract" => "candidate_refresh.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_refresh.v1",
        "schema_version" => 1,
        "planner" => "OrbitalDynamics.CandidateRefresh.V1",
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 2,
        "source_report_row_count" => 9,
        "source_station_calendar_report_count" => 1,
        "source_station_calendar_row_count" => 3,
        "source_station_calendar_affected_contact_count" => 2,
        "source_station_calendar_provider_calendar_contention_group_count" => 1,
        "source_station_calendar_provider_calendar_contention_group_id_keys" =>
          "station_calendar_provider_contention:equator_prime:1",
        "source_station_calendar_provider_calendar_contention_source_entry_id_keys" =>
          "equator_capacity|equator_reserved",
        "source_station_calendar_provider_calendar_contention_provider_entry_id_keys" =>
          "equator_capacity|equator_reserved",
        "source_station_calendar_provider_calendar_contention_provider_counts" => %{
          "ops_calendar" => 1
        },
        "source_station_calendar_provider_calendar_contention_ground_station_counts" => %{
          "equator_prime" => 1
        },
        "source_station_calendar_provider_calendar_contention_minimum_capacity_fraction" => 0.5,
        "source_station_calendar_status_counts" => %{"available" => 1, "reserved" => 1},
        "source_station_calendar_branch_local_station_calendar_pressure" => true,
        "source_station_calendar_branch_local_provider_contention_pressure" => true,
        "source_contact_allocation_report_count" => 2,
        "source_contact_allocation_row_count" => 6,
        "source_contact_allocation_path_keys" =>
          "source_contact_allocation_reservation_conflict_summary|source_contact_allocation_provider_reservation_request_summary",
        "source_contact_allocation_source_summary_schema_contract_counts" => %{
          "contact_allocation_provider_reservation_request_summary.v1" => 1,
          "contact_allocation_reservation_conflict_summary.v1" => 1
        },
        "source_contact_allocation_reservation_conflict_contact_count" => 3,
        "source_contact_allocation_reservation_conflict_match_status_counts" => %{
          "overlap" => 3
        },
        "source_contact_allocation_reservation_conflict_contact_ids_by_direction_and_ground_station" =>
          %{
            "command" => %{"equator_prime" => ["dl_review_overlap"]},
            "downlink" => %{"equator_prime" => ["dl_reserved_intruder"]},
            "tracking" => %{"equator_prime" => ["dl_reserved_intruder"]}
          },
        "source_contact_allocation_station_reservation_expiration_status_counts" => %{
          "declared" => 2,
          "expired" => 2,
          "missing" => 1
        },
        "source_contact_allocation_provider_reservation_request_contact_count" => 2,
        "source_contact_allocation_provider_reservation_review_contact_count" => 1,
        "source_contact_allocation_provider_reservation_no_request_contact_count" => 3,
        "source_contact_allocation_provider_reservation_request_status_counts" => %{
          "request_ready" => 1,
          "review_required" => 1
        },
        "source_contact_allocation_provider_reservation_request_contact_ids_by_direction_and_ground_station" =>
          %{
            "downlink" => %{"equator_prime" => ["dl_reserved_owner"]}
          },
        "source_contact_allocation_provider_reservation_review_contact_ids_by_direction_and_ground_station" =>
          %{
            "command" => %{"equator_prime" => ["dl_review_overlap"]}
          },
        "source_contact_allocation_branch_local_reservation_conflict_pressure" => true,
        "source_contact_allocation_branch_local_provider_reservation_request_pressure" => true
      },
      "tolerances" => %{
        "schema_version" => 0,
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 0,
        "source_report_row_count" => 0,
        "source_station_calendar_report_count" => 0,
        "source_station_calendar_row_count" => 0,
        "source_station_calendar_provider_calendar_contention_group_count" => 0,
        "source_station_calendar_provider_calendar_contention_minimum_capacity_fraction" => 0.0,
        "source_contact_allocation_report_count" => 0,
        "source_contact_allocation_row_count" => 0,
        "source_contact_allocation_reservation_conflict_contact_count" => 0,
        "source_contact_allocation_provider_reservation_request_contact_count" => 0,
        "source_contact_allocation_provider_reservation_review_contact_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not provider-reservation execution validation",
        "checks branch-local replay of contradictory provider-calendar, reservation, and contact-allocation evidence without schedule mutation, candidate selection, import approval, provider reservation, or Cadence writes"
      ]
    },
    "fixture.artifact.candidate_refresh.contact_contention_cross_station_replay" => %{
      "id" => "fixture.artifact.candidate_refresh.contact_contention_cross_station_replay",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" =>
        "generated candidate refresh replay of cross-station same-spacecraft contention challenge",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_candidate_refresh_contact_contention_challenge_fixture",
        "contract" => "candidate_refresh.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_refresh.v1",
        "schema_version" => 1,
        "planner" => "OrbitalDynamics.CandidateRefresh.V1",
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "warning_count" => 2,
        "source_report_family_count" => 1,
        "source_report_row_count" => 1,
        "source_contact_contention_report_count" => 1,
        "source_contact_contention_row_count" => 1,
        "source_contact_contention_conflict_group_count" => 1,
        "source_contact_contention_invalid_contact_input_count" => 0,
        "source_contact_contention_resource_scope_counts" => %{"spacecraft" => 1},
        "source_contact_contention_direction_counts" => %{"downlink" => 2},
        "source_contact_contention_contact_ids_by_direction" => %{
          "downlink" => ["dl_dsn", "dl_equator"]
        },
        "source_contact_contention_required_operator_action_counts" => %{
          "review_contact_contention" => 1
        },
        "source_contact_contention_trust_boundary_status" => "declared"
      },
      "tolerances" => %{
        "schema_version" => 0,
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "warning_count" => 0,
        "source_report_family_count" => 0,
        "source_report_row_count" => 0,
        "source_contact_contention_report_count" => 0,
        "source_contact_contention_row_count" => 0,
        "source_contact_contention_conflict_group_count" => 0,
        "source_contact_contention_invalid_contact_input_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not provider schedule validation",
        "checks candidate-refresh replay of contact-contention provenance without contact allocation, candidate selection, import approval, or Cadence writes"
      ]
    },
    "fixture.artifact.candidate_refresh.contact_intent_direction_replay" => %{
      "id" => "fixture.artifact.candidate_refresh.contact_intent_direction_replay",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" =>
        "generated candidate refresh replay of direction-scoped contact-intent capacity demand",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_candidate_refresh_contact_intent_direction_fixture",
        "contract" => "candidate_refresh.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_refresh.v1",
        "schema_version" => 1,
        "planner" => "OrbitalDynamics.CandidateRefresh.V1",
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 1,
        "source_report_row_count" => 3,
        "source_contact_intent_report_count" => 3,
        "source_contact_intent_row_count" => 3,
        "source_contact_intent_station_feedback_count" => 2,
        "source_contact_intent_capacity_pack_required_contact_count" => 2,
        "source_contact_intent_capacity_pack_required_capacity_fraction" => 0.65,
        "source_contact_intent_capacity_pack_required_capacity_fraction_by_direction" => %{
          "downlink" => 0.25,
          "tracking" => 0.4
        },
        "source_contact_intent_capacity_pack_required_capacity_fraction_by_direction_and_ground_station" =>
          %{
            "downlink" => %{"equator_prime" => 0.25},
            "tracking" => %{"dss_43" => 0.4}
          },
        "source_contact_intent_capacity_pack_contact_ids_by_direction" => %{
          "downlink" => ["intent_direct_capacity"],
          "tracking" => ["intent_nested_capacity"]
        },
        "source_contact_intent_capacity_pack_contact_ids_by_direction_and_ground_station" => %{
          "downlink" => %{"equator_prime" => ["intent_direct_capacity"]},
          "tracking" => %{"dss_43" => ["intent_nested_capacity"]}
        },
        "source_contact_intent_direction_keys" => "command|downlink|tracking",
        "source_contact_intent_direction_counts" => %{
          "command" => 1,
          "downlink" => 1,
          "tracking" => 1
        },
        "source_contact_intent_contact_ids_by_direction" => %{
          "command" => ["intent_station_only"],
          "downlink" => ["intent_direct_capacity"],
          "tracking" => ["intent_nested_capacity"]
        },
        "source_contact_intent_contact_ids_by_direction_and_ground_station" => %{
          "command" => %{"dss_43" => ["intent_station_only"]},
          "downlink" => %{"equator_prime" => ["intent_direct_capacity"]},
          "tracking" => %{"dss_43" => ["intent_nested_capacity"]}
        },
        "source_contact_intent_direction_routing" => %{
          "command" => %{
            "contact_count" => 1,
            "contact_ids" => ["intent_station_only"],
            "capacity_pack_contact_ids" => [],
            "ground_station_ids" => ["dss_43"],
            "contact_ids_by_ground_station" => %{"dss_43" => ["intent_station_only"]}
          },
          "downlink" => %{
            "contact_count" => 1,
            "contact_ids" => ["intent_direct_capacity"],
            "capacity_pack_required_capacity_fraction" => 0.25,
            "capacity_pack_contact_ids" => ["intent_direct_capacity"],
            "ground_station_ids" => ["equator_prime"],
            "contact_ids_by_ground_station" => %{
              "equator_prime" => ["intent_direct_capacity"]
            },
            "capacity_pack_required_capacity_fraction_by_ground_station" => %{
              "equator_prime" => 0.25
            },
            "capacity_pack_contact_ids_by_ground_station" => %{
              "equator_prime" => ["intent_direct_capacity"]
            }
          },
          "tracking" => %{
            "contact_count" => 1,
            "contact_ids" => ["intent_nested_capacity"],
            "capacity_pack_required_capacity_fraction" => 0.4,
            "capacity_pack_contact_ids" => ["intent_nested_capacity"],
            "ground_station_ids" => ["dss_43"],
            "contact_ids_by_ground_station" => %{"dss_43" => ["intent_nested_capacity"]},
            "capacity_pack_required_capacity_fraction_by_ground_station" => %{
              "dss_43" => 0.4
            },
            "capacity_pack_contact_ids_by_ground_station" => %{
              "dss_43" => ["intent_nested_capacity"]
            }
          }
        },
        "source_contact_intent_trust_boundary_status" => "declared"
      },
      "tolerances" => %{
        "schema_version" => 0,
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 0,
        "source_report_row_count" => 0,
        "source_contact_intent_report_count" => 0,
        "source_contact_intent_row_count" => 0,
        "source_contact_intent_station_feedback_count" => 0,
        "source_contact_intent_capacity_pack_required_contact_count" => 0,
        "source_contact_intent_capacity_pack_required_capacity_fraction" => 0.0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not provider schedule validation",
        "checks candidate-refresh replay of contact-intent direction and capacity-pack provenance without contact generation, contact allocation, candidate selection, import approval, or Cadence writes"
      ]
    },
    "fixture.artifact.candidate_refresh.resource_projection_replay" => %{
      "id" => "fixture.artifact.candidate_refresh.resource_projection_replay",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" =>
        "generated candidate refresh replay of resource-projection pressure evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_candidate_refresh_resource_projection_fixture",
        "contract" => "candidate_refresh.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_refresh.v1",
        "schema_version" => 1,
        "planner" => "OrbitalDynamics.CandidateRefresh.V1",
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 1,
        "source_report_row_count" => 4,
        "source_resource_projection_report_count" => 1,
        "source_resource_projection_row_count" => 4,
        "source_resource_projection_projected_resource_count" => 2,
        "source_resource_projection_invalid_activity_input_count" => 1,
        "source_resource_projection_invalid_resource_summary_input_count" => 1,
        "source_resource_projection_resource_pressure_status_counts" => %{
          "downlink_shortfall" => 1,
          "storage_shortfall" => 1
        },
        "source_resource_projection_resource_pressure_type_counts" => %{
          "downlink_shortfall" => 1,
          "storage_pressure" => 1,
          "storage_shortfall" => 1
        },
        "source_resource_projection_resource_pressure_direction_counts" => %{
          "downlink" => 1,
          "tracking" => 1
        },
        "source_resource_projection_resource_pressure_activity_ids_by_status" => %{
          "downlink_shortfall" => ["dl_pressure_1"],
          "storage_shortfall" => ["imaging_1", "imaging_2"]
        },
        "source_resource_projection_resource_pressure_activity_ids_by_type" => %{
          "downlink_shortfall" => ["dl_pressure_1"],
          "storage_pressure" => ["dl_pressure_1"],
          "storage_shortfall" => ["imaging_1", "imaging_2"]
        },
        "source_resource_projection_resource_pressure_activity_ids_by_direction" => %{
          "downlink" => ["dl_pressure_1"],
          "tracking" => ["imaging_1", "imaging_2"]
        },
        "source_resource_projection_trust_boundary_status" => "declared"
      },
      "tolerances" => %{
        "schema_version" => 0,
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 0,
        "source_report_row_count" => 0,
        "source_resource_projection_report_count" => 0,
        "source_resource_projection_row_count" => 0,
        "source_resource_projection_projected_resource_count" => 0,
        "source_resource_projection_invalid_activity_input_count" => 0,
        "source_resource_projection_invalid_resource_summary_input_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not resource execution validation",
        "checks candidate-refresh replay of resource-projection pressure provenance without resource mutation, candidate selection, import approval, or Cadence writes"
      ]
    },
    "fixture.artifact.candidate_refresh.quality_gate_replay" => %{
      "id" => "fixture.artifact.candidate_refresh.quality_gate_replay",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" =>
        "generated candidate refresh replay of quality-gate resource pressure evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_candidate_refresh_quality_gate_fixture",
        "contract" => "candidate_refresh.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_refresh.v1",
        "schema_version" => 1,
        "planner" => "OrbitalDynamics.CandidateRefresh.V1",
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 1,
        "source_report_row_count" => 6,
        "source_quality_gate_report_count" => 1,
        "source_quality_gate_row_count" => 6,
        "source_quality_gate_gate_count" => 6,
        "source_quality_gate_passed_gate_count" => 3,
        "source_quality_gate_review_gate_count" => 3,
        "source_quality_gate_analysis_gate_count" => 0,
        "source_quality_gate_blocked_gate_count" => 0,
        "source_quality_gate_readiness_level_counts" => %{"operator_review" => 1},
        "source_quality_gate_import_classification_counts" => %{"review_only" => 1},
        "source_quality_gate_status_counts" => %{"review_required" => 1},
        "source_quality_gate_gate_status_counts" => %{"passed" => 3, "review_required" => 3},
        "source_quality_gate_gate_classification_counts" => %{
          "importable" => 3,
          "review_only" => 3
        },
        "source_quality_gate_ready_for_import_count" => 0,
        "source_quality_gate_trust_boundary_status" => "declared",
        "source_quality_gate_resource_availability_pressure_count" => 2,
        "source_quality_gate_resource_availability_reason_counts" => %{
          "antenna_unavailable" => 1,
          "payload_unavailable" => 1
        },
        "source_quality_gate_resource_availability_reason_ids" =>
          "antenna_unavailable|payload_unavailable",
        "source_quality_gate_branch_local_review_pressure" => true,
        "source_quality_gate_branch_local_import_pressure" => false,
        "source_quality_gate_branch_local_resource_pressure" => true
      },
      "tolerances" => %{
        "schema_version" => 0,
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 0,
        "source_report_row_count" => 0,
        "source_quality_gate_report_count" => 0,
        "source_quality_gate_row_count" => 0,
        "source_quality_gate_gate_count" => 0,
        "source_quality_gate_passed_gate_count" => 0,
        "source_quality_gate_review_gate_count" => 0,
        "source_quality_gate_analysis_gate_count" => 0,
        "source_quality_gate_blocked_gate_count" => 0,
        "source_quality_gate_ready_for_import_count" => 0,
        "source_quality_gate_resource_availability_pressure_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not external readiness validation",
        "checks candidate-refresh replay of quality-gate resource-pressure provenance without granting operator authority, candidate selection, import approval, or Cadence writes"
      ]
    },
    "fixture.artifact.candidate_refresh.operational_readiness_replay" => %{
      "id" => "fixture.artifact.candidate_refresh.operational_readiness_replay",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" =>
        "generated candidate refresh replay of operational-readiness resource pressure evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_candidate_refresh_operational_readiness_fixture",
        "contract" => "candidate_refresh.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_refresh.v1",
        "schema_version" => 1,
        "planner" => "OrbitalDynamics.CandidateRefresh.V1",
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 1,
        "source_report_row_count" => 1,
        "source_operational_readiness_report_count" => 1,
        "source_operational_readiness_row_count" => 1,
        "source_operational_readiness_gate_count" => 6,
        "source_operational_readiness_passed_gate_count" => 3,
        "source_operational_readiness_review_gate_count" => 3,
        "source_operational_readiness_analysis_gate_count" => 0,
        "source_operational_readiness_blocked_gate_count" => 0,
        "source_operational_readiness_readiness_level_counts" => %{"operator_review" => 1},
        "source_operational_readiness_import_classification_counts" => %{
          "review_only" => 1
        },
        "source_operational_readiness_status_counts" => %{"review_required" => 1},
        "source_operational_readiness_trust_boundary_status" => "declared",
        "source_operational_readiness_resource_availability_pressure_count" => 2,
        "source_operational_readiness_resource_availability_reason_counts" => %{
          "antenna_unavailable" => 1,
          "payload_unavailable" => 1
        },
        "source_operational_readiness_resource_availability_reason_ids" =>
          "antenna_unavailable|payload_unavailable",
        "source_operational_readiness_branch_local_review_pressure" => true,
        "source_operational_readiness_branch_local_import_pressure" => true,
        "source_operational_readiness_branch_local_resource_pressure" => true
      },
      "tolerances" => %{
        "schema_version" => 0,
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 0,
        "source_report_row_count" => 0,
        "source_operational_readiness_report_count" => 0,
        "source_operational_readiness_row_count" => 0,
        "source_operational_readiness_gate_count" => 0,
        "source_operational_readiness_passed_gate_count" => 0,
        "source_operational_readiness_review_gate_count" => 0,
        "source_operational_readiness_analysis_gate_count" => 0,
        "source_operational_readiness_blocked_gate_count" => 0,
        "source_operational_readiness_resource_availability_pressure_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not external operations validation",
        "checks candidate-refresh replay of operational-readiness provenance without granting execution, operator authority, candidate selection, import approval, or Cadence writes"
      ]
    },
    "fixture.artifact.candidate_refresh.timeline_activity_precondition_replay" => %{
      "id" => "fixture.artifact.candidate_refresh.timeline_activity_precondition_replay",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" =>
        "generated candidate refresh replay of timeline-activity precondition evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_candidate_refresh_timeline_activity_precondition_fixture",
        "contract" => "candidate_refresh.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_refresh.v1",
        "schema_version" => 1,
        "planner" => "OrbitalDynamics.CandidateRefresh.V1",
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 1,
        "source_report_row_count" => 3,
        "source_timeline_activity_precondition_report_count" => 2,
        "source_timeline_activity_precondition_row_count" => 3,
        "source_timeline_activity_precondition_status_counts" => %{
          "blocked" => 1,
          "review_required" => 1
        },
        "source_timeline_activity_precondition_blocked_precondition_count" => 2,
        "source_timeline_activity_precondition_review_precondition_count" => 1,
        "source_timeline_activity_precondition_blocked_precondition_type_counts" => %{
          "payload_unavailable" => 1,
          "resource_block_declared" => 1
        },
        "source_timeline_activity_precondition_review_precondition_type_counts" => %{
          "degraded_mode" => 1
        },
        "source_timeline_activity_precondition_invalid_activity_input_count" => 1,
        "source_timeline_activity_precondition_invalid_activity_input_reason_counts" => %{
          "missing_activity_type" => 1
        },
        "source_timeline_activity_precondition_dependency_activity_id_counts" => %{
          "health_check_1" => 1,
          "obs_1" => 1
        },
        "source_timeline_activity_precondition_dependency_timeline_id_counts" => %{
          "timeline:health_check_1" => 1
        },
        "source_timeline_activity_precondition_exclusive_with_activity_id_counts" => %{
          "dl_conflict" => 1
        },
        "source_timeline_activity_precondition_exclusive_with_timeline_id_counts" => %{
          "timeline:dl_conflict" => 1
        },
        "source_timeline_activity_precondition_duplicate_dependency_activity_id_counts" => %{
          "obs_1" => 1
        },
        "source_timeline_activity_precondition_duplicate_dependency_timeline_id_counts" => %{
          "timeline:health_check_1" => 1
        },
        "source_timeline_activity_precondition_duplicate_exclusivity_activity_id_counts" => %{
          "dl_conflict" => 1
        },
        "source_timeline_activity_precondition_duplicate_exclusivity_timeline_id_counts" => %{
          "timeline:dl_conflict" => 1
        },
        "source_timeline_activity_precondition_allow_overlap_counts" => %{"true" => 1},
        "source_timeline_activity_precondition_trust_boundary_status" => "declared"
      },
      "tolerances" => %{
        "schema_version" => 0,
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 0,
        "source_report_row_count" => 0,
        "source_timeline_activity_precondition_report_count" => 0,
        "source_timeline_activity_precondition_row_count" => 0,
        "source_timeline_activity_precondition_blocked_precondition_count" => 0,
        "source_timeline_activity_precondition_review_precondition_count" => 0,
        "source_timeline_activity_precondition_invalid_activity_input_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not external timeline validation",
        "checks candidate-refresh replay of timeline-activity precondition provenance without mutating schedules, granting operator authority, selecting candidates, approving imports, or writing to Cadence"
      ]
    },
    "fixture.artifact.candidate_refresh.timeline_lifecycle_state_replay" => %{
      "id" => "fixture.artifact.candidate_refresh.timeline_lifecycle_state_replay",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" =>
        "generated candidate refresh replay of timeline lifecycle state evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_candidate_refresh_timeline_lifecycle_state_fixture",
        "contract" => "candidate_refresh.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_refresh.v1",
        "schema_version" => 1,
        "planner" => "OrbitalDynamics.CandidateRefresh.V1",
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 1,
        "source_report_row_count" => 4,
        "source_timeline_lifecycle_state_report_count" => 1,
        "source_timeline_lifecycle_state_row_count" => 4,
        "source_timeline_lifecycle_state_planned_activity_count" => 5,
        "source_timeline_lifecycle_state_realized_activity_count" => 3,
        "source_timeline_lifecycle_state_recordable_count" => 1,
        "source_timeline_lifecycle_state_preserved_count" => 1,
        "source_timeline_lifecycle_state_review_required_count" => 2,
        "source_timeline_lifecycle_state_duplicate_timeline_identity_count" => 1,
        "source_timeline_lifecycle_state_invalid_activity_input_count" => 0,
        "source_timeline_lifecycle_state_transition_decision_counts" => %{
          "none" => 1,
          "record" => 1,
          "review" => 2
        },
        "source_timeline_lifecycle_state_required_operator_action_counts" => %{
          "none" => 1,
          "record_timeline_change" => 1,
          "review_activity_approval" => 1,
          "review_duplicate_timeline_identity" => 1
        },
        "source_timeline_lifecycle_state_import_action_counts" => %{
          "import_replacement_activity" => 1,
          "record_preserved_activity" => 1,
          "review_timeline_diff" => 2
        },
        "source_timeline_lifecycle_state_preserved_timeline_keys" => "timeline:done_keep",
        "source_timeline_lifecycle_state_review_timeline_keys" =>
          "timeline:cmd_provider|timeline:dup",
        "source_timeline_lifecycle_state_review_activity_keys" => "cmd_provider|dup_a|dup_b",
        "source_timeline_lifecycle_state_review_timeline_ids_by_required_operator_action" => %{
          "review_activity_approval" => ["timeline:cmd_provider"],
          "review_duplicate_timeline_identity" => ["timeline:dup"]
        },
        "source_timeline_lifecycle_state_trust_boundary_status" => "declared"
      },
      "tolerances" => %{
        "schema_version" => 0,
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 0,
        "source_report_row_count" => 0,
        "source_timeline_lifecycle_state_report_count" => 0,
        "source_timeline_lifecycle_state_row_count" => 0,
        "source_timeline_lifecycle_state_planned_activity_count" => 0,
        "source_timeline_lifecycle_state_realized_activity_count" => 0,
        "source_timeline_lifecycle_state_recordable_count" => 0,
        "source_timeline_lifecycle_state_preserved_count" => 0,
        "source_timeline_lifecycle_state_review_required_count" => 0,
        "source_timeline_lifecycle_state_duplicate_timeline_identity_count" => 0,
        "source_timeline_lifecycle_state_invalid_activity_input_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not external timeline validation",
        "checks candidate-refresh replay of timeline lifecycle-state provenance without mutating schedules, granting operator authority, selecting candidates, approving imports, or writing to Cadence"
      ]
    },
    "fixture.artifact.candidate_refresh.timeline_activity_lifecycle_replay" => %{
      "id" => "fixture.artifact.candidate_refresh.timeline_activity_lifecycle_replay",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" =>
        "generated candidate refresh replay of timeline activity lifecycle evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_candidate_refresh_timeline_activity_lifecycle_fixture",
        "contract" => "candidate_refresh.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_refresh.v1",
        "schema_version" => 1,
        "planner" => "OrbitalDynamics.CandidateRefresh.V1",
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 1,
        "source_report_row_count" => 1,
        "source_timeline_activity_lifecycle_report_count" => 1,
        "source_timeline_activity_lifecycle_row_count" => 1,
        "source_timeline_activity_lifecycle_review_required_count" => 1,
        "source_timeline_activity_lifecycle_invalid_activity_input_count" => 0,
        "source_timeline_activity_lifecycle_transition_decision_counts" => %{"review" => 1},
        "source_timeline_activity_lifecycle_status_transition_decision_counts" => %{
          "record" => 1
        },
        "source_timeline_activity_lifecycle_approval_transition_decision_counts" => %{
          "review" => 1
        },
        "source_timeline_activity_lifecycle_required_operator_action_counts" => %{
          "record_timeline_change" => 1,
          "review_activity_approval" => 1
        },
        "source_timeline_activity_lifecycle_import_action_counts" => %{
          "review_timeline_diff" => 1
        },
        "source_timeline_activity_lifecycle_planned_status_category_counts" => %{
          "planned" => 1
        },
        "source_timeline_activity_lifecycle_realized_status_category_counts" => %{
          "executed" => 1
        },
        "source_timeline_activity_lifecycle_planned_approval_category_counts" => %{
          "review_required" => 1
        },
        "source_timeline_activity_lifecycle_realized_approval_category_counts" => %{
          "protected" => 1
        },
        "source_timeline_activity_lifecycle_status_transition_category_counts" => %{
          "execution_recorded" => 1
        },
        "source_timeline_activity_lifecycle_approval_transition_category_counts" => %{
          "approval_granted" => 1
        },
        "source_timeline_activity_lifecycle_protection_decision_counts" => %{
          "mutable" => 1,
          "preserve" => 1
        },
        "source_timeline_activity_lifecycle_protection_category_counts" => %{
          "executed" => 1,
          "none" => 1
        },
        "source_timeline_activity_lifecycle_action_routing" => %{
          "record_timeline_change" => %{
            "activity_ids" => ["cmd_provider"],
            "approval_transition_categories" => ["approval_granted"],
            "protection_categories" => ["executed", "none"],
            "review_count" => 1,
            "status_transition_categories" => ["execution_recorded"],
            "timeline_ids" => ["timeline:cmd_provider"]
          },
          "review_activity_approval" => %{
            "activity_ids" => ["cmd_provider"],
            "approval_transition_categories" => ["approval_granted"],
            "protection_categories" => ["executed", "none"],
            "review_count" => 1,
            "status_transition_categories" => ["execution_recorded"],
            "timeline_ids" => ["timeline:cmd_provider"]
          }
        },
        "source_timeline_activity_lifecycle_trust_boundary_status" => "declared"
      },
      "tolerances" => %{
        "schema_version" => 0,
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 0,
        "source_report_row_count" => 0,
        "source_timeline_activity_lifecycle_report_count" => 0,
        "source_timeline_activity_lifecycle_row_count" => 0,
        "source_timeline_activity_lifecycle_review_required_count" => 0,
        "source_timeline_activity_lifecycle_invalid_activity_input_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not external timeline validation",
        "checks candidate-refresh replay of timeline activity lifecycle provenance without mutating schedules, granting operator authority, selecting candidates, approving imports, or writing to Cadence"
      ]
    },
    "fixture.artifact.candidate_refresh.timeline_transition_application_replay" => %{
      "id" => "fixture.artifact.candidate_refresh.timeline_transition_application_replay",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" =>
        "generated candidate refresh replay of timeline-transition selected-integrity evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_candidate_refresh_timeline_transition_application_fixture",
        "contract" => "candidate_refresh.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_refresh.v1",
        "schema_version" => 1,
        "planner" => "OrbitalDynamics.CandidateRefresh.V1",
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 1,
        "source_report_row_count" => 1,
        "source_timeline_transition_application_report_count" => 1,
        "source_timeline_transition_application_row_count" => 1,
        "source_timeline_transition_application_application_count" => 1,
        "source_timeline_transition_application_selected_activity_count" => 1,
        "source_timeline_transition_application_selected_integrity_review_count" => 1,
        "source_timeline_transition_application_selected_integrity_issue_count" => 1,
        "source_timeline_transition_application_selected_integrity_issue_type_counts" => %{
          "missing_dependency_activity" => 1
        },
        "source_timeline_transition_application_review_required_count" => 1,
        "source_timeline_transition_application_status_counts" => %{
          "selected_timeline_integrity_review_required" => 1
        },
        "source_timeline_transition_application_required_operator_action_counts" => %{
          "review_timeline_integrity" => 1
        },
        "source_timeline_transition_application_trust_boundary_status" => "declared"
      },
      "tolerances" => %{
        "schema_version" => 0,
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 0,
        "source_report_row_count" => 0,
        "source_timeline_transition_application_report_count" => 0,
        "source_timeline_transition_application_row_count" => 0,
        "source_timeline_transition_application_application_count" => 0,
        "source_timeline_transition_application_selected_activity_count" => 0,
        "source_timeline_transition_application_selected_integrity_review_count" => 0,
        "source_timeline_transition_application_selected_integrity_issue_count" => 0,
        "source_timeline_transition_application_review_required_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not transition execution validation",
        "checks candidate-refresh replay of timeline-transition selected-integrity provenance without schedule mutation, candidate selection, import approval, or Cadence writes"
      ]
    },
    "fixture.artifact.candidate_refresh.objective_gap_replay" => %{
      "id" => "fixture.artifact.candidate_refresh.objective_gap_replay",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" =>
        "generated candidate refresh replay of objective-gap source-report provenance",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_candidate_refresh_objective_gap_fixture",
        "contract" => "candidate_refresh.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_refresh.v1",
        "schema_version" => 1,
        "planner" => "OrbitalDynamics.CandidateRefresh.V1",
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 3,
        "source_report_row_count" => 9,
        "source_objective_satisfaction_report_count" => 1,
        "source_objective_satisfaction_gap_row_count" => 3,
        "source_objective_satisfaction_downlink_gap_row_count" => 1,
        "source_objective_satisfaction_target_gap_row_count" => 1,
        "source_objective_satisfaction_collection_latency_gap_row_count" => 1,
        "source_objective_satisfaction_status_counts" => %{
          "partial" => 2,
          "unmet" => 1
        },
        "source_objective_satisfaction_objective_type_counts" => %{
          "collection_latency" => 1,
          "downlink_completion" => 1,
          "target_coverage" => 1
        },
        "source_objective_satisfaction_ground_station_counts" => %{
          "equator_prime" => 1
        },
        "source_objective_satisfaction_target_counts" => %{"target_a" => 1},
        "source_objective_satisfaction_collection_counts" => %{
          "collection_alpha" => 1
        },
        "source_objective_satisfaction_source_activity_id_counts" => %{
          "collection_latency_activity" => 1,
          "dl_gap_activity" => 1,
          "target_gap_activity" => 1
        },
        "source_objective_satisfaction_trust_boundary_status" => "declared",
        "source_objective_gap_branch_local_objective_gap_pressure" => true,
        "source_objective_gap_branch_local_downlink_gap_pressure" => true,
        "source_objective_gap_branch_local_target_gap_pressure" => true,
        "source_objective_gap_branch_local_collection_latency_gap_pressure" => true,
        "source_objective_gap_branch_local_objective_status_pressure" => true,
        "source_objective_gap_branch_local_score_term_pressure" => true,
        "source_objective_gap_branch_local_routing_pressure" => true,
        "source_objective_tradeoff_report_count" => 1,
        "source_objective_tradeoff_row_count" => 3,
        "source_objective_tradeoff_downlink_gap_row_count" => 1,
        "source_objective_tradeoff_target_gap_row_count" => 1,
        "source_objective_tradeoff_collection_latency_gap_row_count" => 2,
        "source_objective_tradeoff_ground_station_counts" => %{
          "equator_prime" => 1
        },
        "source_objective_tradeoff_target_counts" => %{"target_a" => 1},
        "source_objective_tradeoff_collection_counts" => %{
          "collection_alpha" => 1
        },
        "source_objective_tradeoff_source_activity_id_counts" => %{
          "tradeoff_downlink_activity" => 1,
          "tradeoff_latency_activity" => 1,
          "tradeoff_target_activity" => 1
        },
        "source_objective_tradeoff_trust_boundary_status" => "declared",
        "source_score_term_report_count" => 1,
        "source_score_term_row_count" => 3,
        "source_score_term_downlink_gap_row_count" => 1,
        "source_score_term_target_gap_row_count" => 1,
        "source_score_term_collection_latency_gap_row_count" => 1,
        "source_score_term_term_key_counts" => %{
          "collection_latency_gap_s" => 1,
          "downlink_shortfall_mb" => 1,
          "target_gap_count" => 1
        },
        "source_score_term_ground_station_counts" => %{"equator_prime" => 1},
        "source_score_term_target_counts" => %{"target_a" => 1},
        "source_score_term_collection_counts" => %{"collection_alpha" => 1},
        "source_score_term_source_activity_id_counts" => %{
          "score_collection_activity" => 1,
          "score_downlink_activity" => 1,
          "score_target_activity" => 1
        },
        "source_score_term_trust_boundary_status" => "declared",
        "source_score_term_branch_local_score_term_pressure" => true,
        "source_score_term_branch_local_downlink_gap_pressure" => true,
        "source_score_term_branch_local_target_gap_pressure" => true,
        "source_score_term_branch_local_collection_latency_gap_pressure" => true,
        "source_score_term_branch_local_routing_pressure" => true
      },
      "tolerances" => %{
        "schema_version" => 0,
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 0,
        "source_report_row_count" => 0,
        "source_objective_satisfaction_report_count" => 0,
        "source_objective_satisfaction_gap_row_count" => 0,
        "source_objective_satisfaction_downlink_gap_row_count" => 0,
        "source_objective_satisfaction_target_gap_row_count" => 0,
        "source_objective_satisfaction_collection_latency_gap_row_count" => 0,
        "source_objective_tradeoff_report_count" => 0,
        "source_objective_tradeoff_row_count" => 0,
        "source_objective_tradeoff_downlink_gap_row_count" => 0,
        "source_objective_tradeoff_target_gap_row_count" => 0,
        "source_objective_tradeoff_collection_latency_gap_row_count" => 0,
        "source_score_term_report_count" => 0,
        "source_score_term_row_count" => 0,
        "source_score_term_downlink_gap_row_count" => 0,
        "source_score_term_target_gap_row_count" => 0,
        "source_score_term_collection_latency_gap_row_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not objective or scoring validation",
        "checks candidate-refresh replay of objective-gap provenance without objective generation, score recalculation, candidate selection, import approval, or Cadence writes"
      ]
    },
    "fixture.artifact.candidate_refresh.constraint_replay" => %{
      "id" => "fixture.artifact.candidate_refresh.constraint_replay",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" =>
        "generated candidate refresh replay of constraint source-report provenance",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_candidate_refresh_constraint_fixture",
        "contract" => "candidate_refresh.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_refresh.v1",
        "schema_version" => 1,
        "planner" => "OrbitalDynamics.CandidateRefresh.V1",
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 1,
        "source_report_row_count" => 3,
        "source_constraint_report_count" => 1,
        "source_constraint_row_count" => 3,
        "source_constraint_downlink_gap_row_count" => 1,
        "source_constraint_resource_margin_row_count" => 2,
        "source_constraint_status_counts" => %{"fail" => 1, "warning" => 2},
        "source_constraint_ground_station_counts" => %{"equator_prime" => 1},
        "source_constraint_metric_counts" => %{
          "battery_margin" => 1,
          "selected_downlink_shortfall_mb" => 1,
          "storage_margin" => 1
        },
        "source_constraint_id_counts" => %{
          "battery_margin" => 1,
          "downlink_shortfall" => 1,
          "storage_margin" => 1
        },
        "source_constraint_source_activity_id_counts" => %{
          "constraint_battery_activity" => 1,
          "constraint_downlink_activity" => 1,
          "constraint_storage_activity" => 1
        },
        "source_constraint_resource_counts" => %{"battery_1" => 1, "storage_1" => 1},
        "source_constraint_spacecraft_counts" => %{"sat_1" => 2},
        "source_constraint_trust_boundary_status" => "declared",
        "source_constraint_branch_local_constraint_pressure" => true,
        "source_constraint_branch_local_downlink_gap_pressure" => true,
        "source_constraint_branch_local_resource_margin_pressure" => true,
        "source_constraint_branch_local_constraint_routing_pressure" => true
      },
      "tolerances" => %{
        "schema_version" => 0,
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 0,
        "source_report_row_count" => 0,
        "source_constraint_report_count" => 0,
        "source_constraint_row_count" => 0,
        "source_constraint_downlink_gap_row_count" => 0,
        "source_constraint_resource_margin_row_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not constraint or resource validation",
        "checks candidate-refresh replay of constraint provenance without objective generation, resource mutation, candidate selection, import approval, or Cadence writes"
      ]
    },
    "fixture.artifact.candidate_refresh.contact_filter_replay" => %{
      "id" => "fixture.artifact.candidate_refresh.contact_filter_replay",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" =>
        "generated candidate refresh replay of contact-filter source-report provenance",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_candidate_refresh_contact_filter_fixture",
        "contract" => "candidate_refresh.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_refresh.v1",
        "schema_version" => 1,
        "planner" => "OrbitalDynamics.CandidateRefresh.V1",
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 1,
        "source_report_row_count" => 4,
        "source_contact_filter_report_count" => 1,
        "source_contact_filter_row_count" => 4,
        "source_contact_filter_suppressed_candidate_count" => 4,
        "source_contact_filter_invalid_contact_input_count" => 1,
        "source_contact_filter_suppressed_reason_counts" => %{
          "ground_station_capacity_zero" => 1,
          "ground_station_reserved" => 1,
          "ground_station_unavailable" => 1,
          "invalid_contact_input" => 1
        },
        "source_contact_filter_contact_ids_by_suppressed_reason" => %{
          "ground_station_capacity_zero" => ["dl_station_capacity_zero"],
          "ground_station_reserved" => ["dl_station_reserved"],
          "ground_station_unavailable" => ["dl_station_unavailable"],
          "invalid_contact_input" => ["invalid_contact"]
        },
        "source_contact_filter_direction_counts" => %{
          "command" => 1,
          "downlink" => 1,
          "health_check" => 1,
          "tracking" => 1
        },
        "source_contact_filter_station_suppression_count" => 3,
        "source_contact_filter_station_suppression_ground_station_counts" => %{
          "dss_43" => 2,
          "equator_prime" => 1
        },
        "source_contact_filter_station_suppression_availability_counts" => %{
          "reduced_capacity" => 1,
          "reserved" => 1,
          "unavailable" => 1
        },
        "source_contact_filter_station_suppression_status_counts" => %{
          "reserved" => 1,
          "unavailable" => 1
        },
        "source_contact_filter_trust_boundary_status" => "declared",
        "source_contact_filter_branch_local_contact_filter_pressure" => true,
        "source_contact_filter_branch_local_candidate_suppression_pressure" => true,
        "source_contact_filter_branch_local_invalid_contact_input_pressure" => true,
        "source_contact_filter_branch_local_station_suppression_pressure" => true
      },
      "tolerances" => %{
        "schema_version" => 0,
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 0,
        "source_report_row_count" => 0,
        "source_contact_filter_report_count" => 0,
        "source_contact_filter_row_count" => 0,
        "source_contact_filter_suppressed_candidate_count" => 0,
        "source_contact_filter_invalid_contact_input_count" => 0,
        "source_contact_filter_station_suppression_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not contact filtering validation",
        "checks candidate-refresh replay of contact-filter provenance without contact allocation, candidate selection, import approval, or Cadence writes"
      ]
    },
    "fixture.artifact.candidate_refresh.link_capacity_replay" => %{
      "id" => "fixture.artifact.candidate_refresh.link_capacity_replay",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" =>
        "generated candidate refresh replay of link-capacity source-report provenance",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_candidate_refresh_link_capacity_fixture",
        "contract" => "candidate_refresh.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_refresh.v1",
        "schema_version" => 1,
        "planner" => "OrbitalDynamics.CandidateRefresh.V1",
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 1,
        "source_report_row_count" => 2,
        "source_link_capacity_report_count" => 1,
        "source_link_capacity_row_count" => 2,
        "source_link_capacity_selected_shortfall_row_count" => 1,
        "source_link_capacity_actual_shortfall_row_count" => 1,
        "source_link_capacity_actual_throughput_row_count" => 2,
        "source_link_capacity_capacity_adjusted_throughput_row_count" => 2,
        "source_link_capacity_capacity_adjusted_throughput_mb_total" => 85.0,
        "source_link_capacity_selected_capacity_adjusted_throughput_mb_total" => 40.0,
        "source_link_capacity_unused_capacity_adjusted_throughput_mb_total" => 45.0,
        "source_link_capacity_ground_station_counts" => %{
          "dss_43" => 1,
          "equator_prime" => 1
        },
        "source_link_capacity_spacecraft_counts" => %{"leo_1" => 1, "leo_2" => 1},
        "source_link_capacity_direction_counts" => %{
          "command" => 1,
          "downlink" => 1,
          "tracking" => 1
        },
        "source_link_capacity_downlink_requirement_status_counts" => %{
          "actual_met" => 1,
          "actual_shortfall" => 1,
          "selected_met" => 1,
          "selected_shortfall" => 1
        },
        "source_link_capacity_contact_ids_by_requirement_status" => %{
          "actual_met" => ["contact_alpha"],
          "actual_shortfall" => ["contact_gamma"],
          "selected_met" => ["contact_gamma"],
          "selected_shortfall" => ["contact_alpha", "contact_beta"]
        },
        "source_link_capacity_trust_boundary_status" => "declared",
        "source_link_capacity_branch_local_link_capacity_pressure" => true,
        "source_link_capacity_branch_local_capacity_adjusted_throughput_pressure" => true,
        "source_link_capacity_branch_local_downlink_shortfall_pressure" => true,
        "source_link_capacity_branch_local_actual_throughput_pressure" => true
      },
      "tolerances" => %{
        "schema_version" => 0,
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 0,
        "source_report_row_count" => 0,
        "source_link_capacity_report_count" => 0,
        "source_link_capacity_row_count" => 0,
        "source_link_capacity_selected_shortfall_row_count" => 0,
        "source_link_capacity_actual_shortfall_row_count" => 0,
        "source_link_capacity_actual_throughput_row_count" => 0,
        "source_link_capacity_capacity_adjusted_throughput_row_count" => 0,
        "source_link_capacity_capacity_adjusted_throughput_mb_total" => 0.0,
        "source_link_capacity_selected_capacity_adjusted_throughput_mb_total" => 0.0,
        "source_link_capacity_unused_capacity_adjusted_throughput_mb_total" => 0.0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not link-budget or provider-capacity validation",
        "checks candidate-refresh replay of link-capacity provenance without contact allocation, candidate selection, import approval, or Cadence writes"
      ]
    },
    "fixture.artifact.candidate_refresh.resource_filter_replay" => %{
      "id" => "fixture.artifact.candidate_refresh.resource_filter_replay",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" =>
        "generated candidate refresh replay of resource-filter source-report provenance",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_candidate_refresh_resource_filter_fixture",
        "contract" => "candidate_refresh.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_refresh.v1",
        "schema_version" => 1,
        "planner" => "OrbitalDynamics.CandidateRefresh.V1",
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 1,
        "source_report_row_count" => 4,
        "source_resource_filter_report_count" => 1,
        "source_resource_filter_row_count" => 4,
        "source_resource_filter_suppressed_candidate_count" => 3,
        "source_resource_filter_invalid_resource_summary_input_count" => 1,
        "source_resource_filter_suppressed_reason_counts" => %{
          "downlink_margin_low" => 1,
          "payload_unavailable" => 1,
          "power_margin_low" => 1
        },
        "source_resource_filter_candidate_ids_by_suppressed_reason" => %{
          "downlink_margin_low" => ["downlink_margin_block"],
          "payload_unavailable" => ["obs_payload_block"],
          "power_margin_low" => ["power_block"]
        },
        "source_resource_filter_spacecraft_counts" => %{"leo_1" => 2, "leo_2" => 1},
        "source_resource_filter_candidate_ids_by_spacecraft" => %{
          "leo_1" => ["downlink_margin_block", "obs_payload_block"],
          "leo_2" => ["power_block"]
        },
        "source_resource_filter_resource_counts" => %{
          "battery_main" => 1,
          "downlink_budget" => 1,
          "payload_1" => 1
        },
        "source_resource_filter_blocking_dimension_counts" => %{
          "communications" => 1,
          "payload" => 1,
          "power" => 1
        },
        "source_resource_filter_direction_counts" => %{
          "command" => 1,
          "downlink" => 1
        },
        "source_resource_filter_direction_routing" => %{
          "command" => %{
            "candidate_count" => 1,
            "candidate_ids" => ["power_block"]
          },
          "downlink" => %{
            "candidate_count" => 1,
            "candidate_ids" => ["downlink_margin_block"]
          }
        },
        "source_resource_filter_trust_boundary_status" => "declared",
        "source_resource_filter_branch_local_resource_filter_pressure" => true,
        "source_resource_filter_branch_local_candidate_suppression_pressure" => true,
        "source_resource_filter_branch_local_invalid_resource_summary_pressure" => true,
        "source_resource_filter_branch_local_resource_blocking_pressure" => true
      },
      "tolerances" => %{
        "schema_version" => 0,
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "source_report_family_count" => 0,
        "source_report_row_count" => 0,
        "source_resource_filter_report_count" => 0,
        "source_resource_filter_row_count" => 0,
        "source_resource_filter_suppressed_candidate_count" => 0,
        "source_resource_filter_invalid_resource_summary_input_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not resource filtering validation",
        "checks candidate-refresh replay of resource-filter provenance without resource filtering, candidate selection, import approval, or Cadence writes"
      ]
    },
    "fixture.artifact.candidate_refresh.resource_provenance_v1" => %{
      "id" => "fixture.artifact.candidate_refresh.resource_provenance_v1",
      "model_id" => "artifact.candidate_refresh.v1",
      "reference_case" => "checked-in candidate refresh resource provenance artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/candidate_refresh_resource_provenance_v1.json",
        "contract" => "candidate_refresh.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_refresh.v1",
        "schema_version" => 1,
        "planner" => "OrbitalDynamics.CandidateRefresh.V1",
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 1,
        "target_visibility_window_count" => 1,
        "eclipse_interval_count" => 0,
        "warning_count" => 3,
        "source_report_family_count" => 2,
        "source_report_row_count" => 7
      },
      "tolerances" => %{
        "schema_version" => 0,
        "candidate_count" => 0,
        "contact_intent_count" => 0,
        "access_window_count" => 0,
        "target_visibility_window_count" => 0,
        "eclipse_interval_count" => 0,
        "warning_count" => 0,
        "source_report_family_count" => 0,
        "source_report_row_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external mission validation",
        "checks branch-local source-report provenance counts, not full refresh viability"
      ]
    },
    "fixture.artifact.candidate_rejection_report.v1" => %{
      "id" => "fixture.artifact.candidate_rejection_report.v1",
      "model_id" => "artifact.candidate_rejection_report.v1",
      "reference_case" => "checked-in candidate rejection explanation report artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/candidate_rejection_report_v1.json",
        "contract" => "candidate_rejection_report.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_rejection_report.v1",
        "model" => "artifact_only_candidate_rejection_explanation",
        "source" => "candidate_refresh",
        "candidate_count" => 4,
        "row_count" => 4,
        "rejected_count" => 3,
        "not_rejected_count" => 1,
        "invalid_candidate_input_count" => 1,
        "reviewable_count" => 3,
        "rejection_reason_family_count" => 8,
        "required_operator_review_count" => 3,
        "rejected_candidate_id_order" => "dl_reserved|missing_activity_id:4|obs_clouded",
        "reviewable_candidate_id_order" => "dl_reserved|missing_activity_id:4|obs_clouded",
        "invalid_candidate_input_id_order" => "missing_activity_id:4",
        "station_reserved_candidate_ids" => "dl_reserved",
        "declared_rejection_candidate_ids" => "obs_clouded",
        "no_target_visibility_candidate_ids" => "obs_clouded",
        "contact_too_short_count" => 1,
        "station_reserved_count" => 1,
        "quality_gate_failed_count" => 1,
        "invalid_candidate_input_reason_count" => 1,
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "candidate_count" => 0,
        "row_count" => 0,
        "rejected_count" => 0,
        "not_rejected_count" => 0,
        "invalid_candidate_input_count" => 0,
        "reviewable_count" => 0,
        "rejection_reason_family_count" => 0,
        "required_operator_review_count" => 0,
        "contact_too_short_count" => 0,
        "station_reserved_count" => 0,
        "quality_gate_failed_count" => 0,
        "invalid_candidate_input_reason_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external mission validation",
        "checks candidate-rejection counts, reason routing, review action counts, and no-execution model limits only"
      ]
    },
    "fixture.artifact.candidate_diff_row.v1" => %{
      "id" => "fixture.artifact.candidate_diff_row.v1",
      "model_id" => "artifact.candidate_diff_row.v1",
      "reference_case" => "checked-in semantic candidate diff row artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/candidate_diff_row_v1.json",
        "contract" => "candidate_diff_row.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_diff_row.v1",
        "id" => "leo_1_observe_target_a_1",
        "type" => "observe",
        "scenario_id" => "leo_1",
        "diff_reason" => "semantically_similar_prior_candidate_changed",
        "matched_prior_candidate_id" => "old_candidate",
        "source_window_id" => "window:leo_1:target_visibility:target_a:1",
        "changed_field_count" => 3,
        "changed_field_order" => "ends_at_s|source_window_id|starts_at_s",
        "candidate_diff_changed_field_count" => 3,
        "candidate_diff_changed_field_order" => "ends_at_s|source_window_id|starts_at_s",
        "semantic_change_reason_count" => 3,
        "semantic_change_reason_order" =>
          "starts_at_s_changed|ends_at_s_changed|source_window_id_changed",
        "semantic_change_detail_count" => 3,
        "target_id" => "target_a",
        "source_target_id" => "target_a",
        "target_priority" => 12,
        "target_priority_source" => "candidate_refresh.objectives.observation_priority",
        "target_priority_objective_type" => "urgent_target",
        "target_priority_objective_count" => 1
      },
      "tolerances" => %{
        "changed_field_count" => 0,
        "candidate_diff_changed_field_count" => 0,
        "semantic_change_reason_count" => 0,
        "semantic_change_detail_count" => 0,
        "target_priority" => 0,
        "target_priority_objective_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external candidate scoring validation",
        "checks one semantic candidate-diff row and target-priority metadata only"
      ]
    },
    "fixture.artifact.environment_model_capability.fixed_sun" => %{
      "id" => "fixture.artifact.environment_model_capability.fixed_sun",
      "model_id" => "artifact.environment_model_capability.v1",
      "reference_case" => "runtime fixed inertial Sun direction environment model capability",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_runtime_capability_regression",
      "inputs" => %{
        "source_facade" => "OrbitalDynamics.Environment.model_capabilities/0",
        "capability_id" => "environment.solar.fixed_inertial_direction",
        "contract" => "environment_model_capability.v1"
      },
      "expected" => %{
        "schema_contract" => "environment_model_capability.v1",
        "id" => "environment.solar.fixed_inertial_direction",
        "category" => "solar_direction",
        "model" => "fixed_inertial_solar_direction",
        "source" => "study_runner_option",
        "validation_level" => "assumption_declared",
        "coordinate_frame" => "eci_j2000_inertial",
        "interpolation" => "constant",
        "time_span" => "study_horizon",
        "supported_body_count" => 1,
        "network_access" => false,
        "parameter_count" => 1,
        "sun_direction_dimension" => 3,
        "sun_direction_order" => "1.0|0.0|0.0",
        "known_limit_count" => 3
      },
      "tolerances" => %{
        "supported_body_count" => 0,
        "parameter_count" => 0,
        "sun_direction_dimension" => 0,
        "known_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-validated from OrbitalDynamics.Environment.model_capabilities/0"
      ],
      "known_limits" => [
        "runtime capability regression, not external environment-model validation",
        "checks public model capability identity and declared assumption boundaries only"
      ]
    },
    "fixture.artifact.environment_model_capability.constant_earth_rotation" => %{
      "id" => "fixture.artifact.environment_model_capability.constant_earth_rotation",
      "model_id" => "artifact.environment_model_capability.v1",
      "reference_case" => "runtime constant Earth rotation environment model capability",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_runtime_capability_regression",
      "inputs" => %{
        "source_facade" => "OrbitalDynamics.Environment.model_capabilities/0",
        "capability_id" => "environment.earth_rotation.constant_rate",
        "contract" => "environment_model_capability.v1"
      },
      "expected" => %{
        "schema_contract" => "environment_model_capability.v1",
        "id" => "environment.earth_rotation.constant_rate",
        "category" => "body_rotation",
        "model" => "constant_earth_rotation",
        "source" => "internal_simplified_geometry",
        "validation_level" => "assumption_declared",
        "coordinate_frame" => "earth_body_fixed_to_eci_j2000_approximation",
        "interpolation" => "analytic_constant_rate",
        "time_span" => "study_horizon",
        "supported_body_count" => 1,
        "network_access" => false,
        "parameter_count" => 2,
        "earth_rotation_rate_rad_s" => 7.292115e-5,
        "geometry_model" => "simplified_spherical_earth_rotation",
        "known_limit_count" => 3
      },
      "tolerances" => %{
        "supported_body_count" => 0,
        "parameter_count" => 0,
        "earth_rotation_rate_rad_s" => 0.0,
        "known_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-validated from OrbitalDynamics.Environment.model_capabilities/0"
      ],
      "known_limits" => [
        "runtime capability regression, not external environment-model validation",
        "checks public model capability identity and declared assumption boundaries only"
      ]
    },
    "fixture.artifact.environment_provider_capability.fixed_sun" => %{
      "id" => "fixture.artifact.environment_provider_capability.fixed_sun",
      "model_id" => "artifact.environment_provider_capability.v1",
      "reference_case" => "runtime fixed inertial Sun direction environment provider capability",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_runtime_capability_regression",
      "inputs" => %{
        "source_facade" => "OrbitalDynamics.Environment.provider_capabilities/0",
        "capability_id" => "environment.provider.solar.fixed_inertial_direction",
        "contract" => "environment_provider_capability.v1"
      },
      "expected" => %{
        "schema_contract" => "environment_provider_capability.v1",
        "id" => "environment.provider.solar.fixed_inertial_direction",
        "category" => "solar_direction",
        "model" => "fixed_inertial_solar_direction",
        "source" => "internal_fixed_sun_assumption",
        "validation_level" => "assumption_declared",
        "interpolation" => "constant",
        "coverage_policy" => "all_times",
        "coverage_time_scale" => "seconds_since_j2000",
        "output_count" => 1,
        "supported_body_count" => 1,
        "network_access" => false,
        "parameter_count" => 0,
        "known_limit_count" => 3
      },
      "tolerances" => %{
        "output_count" => 0,
        "supported_body_count" => 0,
        "parameter_count" => 0,
        "known_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-validated from OrbitalDynamics.Environment.provider_capabilities/0"
      ],
      "known_limits" => [
        "runtime capability regression, not external environment-provider validation",
        "checks public provider capability identity and declared network boundary only"
      ]
    },
    "fixture.artifact.environment_provider_capability.constant_earth_rotation" => %{
      "id" => "fixture.artifact.environment_provider_capability.constant_earth_rotation",
      "model_id" => "artifact.environment_provider_capability.v1",
      "reference_case" => "runtime constant Earth rotation environment provider capability",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_runtime_capability_regression",
      "inputs" => %{
        "source_facade" => "OrbitalDynamics.Environment.provider_capabilities/0",
        "capability_id" => "environment.provider.earth_rotation.constant_rate",
        "contract" => "environment_provider_capability.v1"
      },
      "expected" => %{
        "schema_contract" => "environment_provider_capability.v1",
        "id" => "environment.provider.earth_rotation.constant_rate",
        "category" => "body_rotation",
        "model" => "constant_earth_rotation",
        "source" => "internal_simplified_geometry",
        "validation_level" => "assumption_declared",
        "interpolation" => "analytic_constant_rate",
        "coverage_policy" => "all_times",
        "coverage_time_scale" => "seconds_since_j2000",
        "output_count" => 3,
        "supported_body_count" => 1,
        "network_access" => false,
        "parameter_count" => 2,
        "known_limit_count" => 3
      },
      "tolerances" => %{
        "output_count" => 0,
        "supported_body_count" => 0,
        "parameter_count" => 0,
        "known_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-validated from OrbitalDynamics.Environment.provider_capabilities/0"
      ],
      "known_limits" => [
        "runtime capability regression, not external environment-provider validation",
        "checks public provider capability identity and declared network boundary only"
      ]
    },
    "fixture.artifact.environment_provider_capability.tabular_earth_orientation" => %{
      "id" => "fixture.artifact.environment_provider_capability.tabular_earth_orientation",
      "model_id" => "artifact.environment_provider_capability.v1",
      "reference_case" =>
        "runtime declared table Earth orientation environment provider capability",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_runtime_capability_regression",
      "inputs" => %{
        "source_facade" => "OrbitalDynamics.Environment.provider_capabilities/0",
        "capability_id" => "environment.provider.earth_orientation.tabular_rotation",
        "contract" => "environment_provider_capability.v1"
      },
      "expected" => %{
        "schema_contract" => "environment_provider_capability.v1",
        "id" => "environment.provider.earth_orientation.tabular_rotation",
        "category" => "body_rotation",
        "model" => "tabular_earth_orientation_rotation",
        "source" => "declared_earth_orientation_table",
        "validation_level" => "assumption_declared",
        "interpolation" => "linear_declared_rotation_sample",
        "coverage_policy" => "declared_samples",
        "coverage_time_scale" => "seconds_since_j2000",
        "output_count" => 3,
        "supported_body_count" => 1,
        "network_access" => false,
        "parameter_count" => 0,
        "known_limit_count" => 4
      },
      "tolerances" => %{
        "output_count" => 0,
        "supported_body_count" => 0,
        "parameter_count" => 0,
        "known_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-validated from OrbitalDynamics.Environment.provider_capabilities/0"
      ],
      "known_limits" => [
        "runtime capability regression, not external environment-provider validation",
        "checks public provider capability identity and declared network boundary only"
      ]
    },
    "fixture.artifact.environment_provider_capability.exponential_atmosphere" => %{
      "id" => "fixture.artifact.environment_provider_capability.exponential_atmosphere",
      "model_id" => "artifact.environment_provider_capability.v1",
      "reference_case" => "runtime exponential atmosphere environment provider capability",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_runtime_capability_regression",
      "inputs" => %{
        "source_facade" => "OrbitalDynamics.Environment.provider_capabilities/0",
        "capability_id" => "environment.provider.atmosphere.exponential_reference",
        "contract" => "environment_provider_capability.v1"
      },
      "expected" => %{
        "schema_contract" => "environment_provider_capability.v1",
        "id" => "environment.provider.atmosphere.exponential_reference",
        "category" => "atmosphere_density",
        "model" => "single_scale_height_exponential_atmosphere",
        "source" => "internal_reference_model",
        "validation_level" => "assumption_declared",
        "interpolation" => "analytic_single_scale_height",
        "coverage_policy" => "all_times",
        "coverage_time_scale" => "seconds_since_j2000",
        "output_count" => 2,
        "supported_body_count" => 1,
        "network_access" => false,
        "parameter_count" => 3,
        "known_limit_count" => 3
      },
      "tolerances" => %{
        "output_count" => 0,
        "supported_body_count" => 0,
        "parameter_count" => 0,
        "known_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-validated from OrbitalDynamics.Environment.provider_capabilities/0"
      ],
      "known_limits" => [
        "runtime capability regression, not external environment-provider validation",
        "checks public provider capability identity and declared network boundary only"
      ]
    },
    "fixture.artifact.branch_comparison_report.v1" => %{
      "id" => "fixture.artifact.branch_comparison_report.v1",
      "model_id" => "artifact.branch_comparison_report.v1",
      "reference_case" => "checked-in branch comparison artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/branch_comparison_report_v1.json",
        "contract" => "branch_comparison_report.v1"
      },
      "expected" => %{
        "schema_contract" => "branch_comparison_report.v1",
        "model" => "deterministic_strategy_branch_score_comparison",
        "source" => "campaign_strategy.branches",
        "branch_count" => 13,
        "row_count" => 13,
        "recommended_branch_id" => "derived_urgent_target_target_hot",
        "selected_count" => 1,
        "selected_branch_score" => 2835.3981832107565,
        "max_rank" => 13,
        "risk_count_total" => 106,
        "approval_requirement_count_total" => 6,
        "candidate_activity_count_total" => 6,
        "approval_status_counts" => %{"blocked_by_policy" => 9, "operator_review_required" => 4},
        "selected_branch_ids_by_status" => %{
          "false" => [
            "baseline",
            "derived_combined_mission_state",
            "derived_contact_success_feedback",
            "derived_degraded_leo_2",
            "derived_downlink_constrained",
            "derived_fuel_preservation",
            "derived_observation_success_feedback",
            "derived_station_capacity_equator_prime",
            "derived_station_throughput_feedback",
            "derived_target_revisit_target_hot",
            "operator_placeholder_urgent",
            "operator_station_outage"
          ],
          "true" => ["derived_urgent_target_target_hot"]
        },
        "branch_ids_by_approval_status" => %{
          "blocked_by_policy" => [
            "baseline",
            "derived_contact_success_feedback",
            "derived_degraded_leo_2",
            "derived_downlink_constrained",
            "derived_fuel_preservation",
            "derived_observation_success_feedback",
            "derived_station_capacity_equator_prime",
            "derived_station_throughput_feedback",
            "operator_station_outage"
          ],
          "operator_review_required" => [
            "derived_combined_mission_state",
            "derived_target_revisit_target_hot",
            "derived_urgent_target_target_hot",
            "operator_placeholder_urgent"
          ]
        },
        "row_derived_branch_count" => 13,
        "row_derived_selected_count" => 1,
        "row_derived_risk_count_total" => 106,
        "row_derived_approval_requirement_count_total" => 6,
        "row_derived_candidate_activity_count_total" => 6,
        "row_derived_approval_status_counts" => %{
          "blocked_by_policy" => 9,
          "operator_review_required" => 4
        },
        "row_derived_branch_ids_by_approval_status" => %{
          "blocked_by_policy" => [
            "baseline",
            "derived_contact_success_feedback",
            "derived_degraded_leo_2",
            "derived_downlink_constrained",
            "derived_fuel_preservation",
            "derived_observation_success_feedback",
            "derived_station_capacity_equator_prime",
            "derived_station_throughput_feedback",
            "operator_station_outage"
          ],
          "operator_review_required" => [
            "derived_combined_mission_state",
            "derived_target_revisit_target_hot",
            "derived_urgent_target_target_hot",
            "operator_placeholder_urgent"
          ]
        },
        "resource_risk_type_counts" => %{
          "downlink_capacity_low" => 13,
          "fuel_margin_low" => 13,
          "payload_availability_low" => 13,
          "spacecraft_availability_low" => 13,
          "storage_margin_low" => 13
        },
        "row_derived_resource_risk_type_counts" => %{
          "downlink_capacity_low" => 13,
          "fuel_margin_low" => 13,
          "payload_availability_low" => 13,
          "spacecraft_availability_low" => 13,
          "storage_margin_low" => 13
        },
        "branch_order" => "score_descending_then_branch_id",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "branch_count" => 0,
        "row_count" => 0,
        "selected_count" => 0,
        "selected_branch_score" => 0.0,
        "max_rank" => 0,
        "risk_count_total" => 0,
        "approval_requirement_count_total" => 0,
        "candidate_activity_count_total" => 0,
        "row_derived_branch_count" => 0,
        "row_derived_selected_count" => 0,
        "row_derived_risk_count_total" => 0,
        "row_derived_approval_requirement_count_total" => 0,
        "row_derived_candidate_activity_count_total" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external optimizer validation",
        "checks branch comparison counts, ranking maps, and no-execution model boundary only"
      ]
    },
    "fixture.artifact.optimizer_contract.v1" => %{
      "id" => "fixture.artifact.optimizer_contract.v1",
      "model_id" => "artifact.optimizer_contract.v1",
      "reference_case" => "checked-in optimizer contract artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/optimizer_contract_v1.json",
        "contract" => "optimizer_contract.v1"
      },
      "expected" => %{
        "schema_contract" => "optimizer_contract.v1",
        "id" =>
          "optimizer_contract:campaign_plan:leo_constellation_campaign:2026-05-14T00:00:00Z",
        "optimizer" => "per_spacecraft_greedy_non_overlapping",
        "objective" => "maximize weighted observation value and contact value",
        "selection_policy" => "highest_scored_non_overlapping_timeline",
        "selected_activity_count" => 1,
        "candidate_count" => 2,
        "candidate_activity_id_count" => 2,
        "ranked_scenario_count" => 1,
        "ranked_timeline_count" => 1,
        "constraint_count" => 3,
        "score_term_key_count" => 7,
        "deterministic_ordering_count" => 5,
        "known_limit_count" => 6,
        "preserved_lineage_field_count" => 5,
        "external_solver" => false,
        "optimizer_family" => "deterministic_greedy_selector",
        "selection_scope" => "per_scenario_then_ranked_plan",
        "selected_activity_id_order" => "leo_1_observe_target_a_1",
        "candidate_activity_id_order" => "leo_1_downlink_equator_prime_1|leo_1_observe_target_a_1"
      },
      "tolerances" => %{
        "selected_activity_count" => 0,
        "candidate_count" => 0,
        "candidate_activity_id_count" => 0,
        "ranked_scenario_count" => 0,
        "ranked_timeline_count" => 0,
        "constraint_count" => 0,
        "score_term_key_count" => 0,
        "deterministic_ordering_count" => 0,
        "known_limit_count" => 0,
        "preserved_lineage_field_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external optimizer validation",
        "checks deterministic greedy optimizer contract shape and routing only"
      ]
    },
    "fixture.artifact.invalidated_candidate.v1" => %{
      "id" => "fixture.artifact.invalidated_candidate.v1",
      "model_id" => "artifact.invalidated_candidate.v1",
      "reference_case" => "checked-in invalidated candidate artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/invalidated_candidate_v1.json",
        "contract" => "invalidated_candidate.v1"
      },
      "expected" => %{
        "schema_contract" => "invalidated_candidate.v1",
        "id" => "old_candidate",
        "scenario_id" => "leo_1",
        "type" => "observe",
        "invalidated_reason" => "replaced_by_semantically_similar_candidate",
        "replacement_candidate_id" => "leo_1_observe_target_a_1",
        "source_window_id" => "window:leo_1:target_visibility:target_a:old",
        "target_id" => "target_a",
        "target_priority" => 12,
        "target_priority_objective_type" => "urgent_target",
        "changed_field_count" => 3,
        "candidate_diff_changed_field_count" => 3,
        "semantic_change_reason_count" => 3,
        "semantic_change_detail_count" => 3,
        "changed_field_order" => "ends_at_s|source_window_id|starts_at_s",
        "semantic_change_reason_order" =>
          "starts_at_s_changed|ends_at_s_changed|source_window_id_changed",
        "target_priority_objective_count" => 1,
        "duration_s" => 60
      },
      "tolerances" => %{
        "target_priority" => 0,
        "changed_field_count" => 0,
        "candidate_diff_changed_field_count" => 0,
        "semantic_change_reason_count" => 0,
        "semantic_change_detail_count" => 0,
        "target_priority_objective_count" => 0,
        "duration_s" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not candidate refresh validation",
        "checks invalidation reason, replacement routing, target metadata, and semantic-change details only"
      ]
    },
    "fixture.artifact.candidate_diff_report.v1" => %{
      "id" => "fixture.artifact.candidate_diff_report.v1",
      "model_id" => "artifact.candidate_diff_report.v1",
      "reference_case" => "checked-in candidate diff artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/candidate_diff_report_v1.json",
        "contract" => "candidate_diff_report.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_diff_report.v1",
        "model" => "candidate_id_set_diff_with_semantic_change_reasons",
        "prior_candidate_count" => 1,
        "refreshed_candidate_count" => 2,
        "retained_candidate_count" => 0,
        "retained_candidate_row_count" => 0,
        "new_candidate_count" => 2,
        "new_candidate_row_count" => 2,
        "invalidated_candidate_count" => 1,
        "invalidated_candidate_row_count" => 1,
        "source_window_lineage_count" => 1,
        "new_reason_counts" => %{
          "not_present_in_prior_candidate_set" => 1,
          "semantically_similar_prior_candidate_changed" => 1
        },
        "invalidated_reason_counts" => %{"replaced_by_semantically_similar_candidate" => 1},
        "semantic_change_reason_counts" => %{
          "ends_at_s_changed" => 2,
          "source_window_id_changed" => 2,
          "starts_at_s_changed" => 2
        },
        "changed_field_counts" => %{
          "ends_at_s" => 1,
          "source_window_id" => 1,
          "starts_at_s" => 1
        },
        "new_candidate_ids_by_reason" => %{
          "not_present_in_prior_candidate_set" => ["leo_1_downlink_equator_prime_1"],
          "semantically_similar_prior_candidate_changed" => ["leo_1_observe_target_a_1"]
        },
        "invalidated_candidate_ids_by_reason" => %{
          "replaced_by_semantically_similar_candidate" => ["old_candidate"]
        },
        "replacement_candidate_ids_by_invalidated_reason" => %{
          "replaced_by_semantically_similar_candidate" => ["leo_1_observe_target_a_1"]
        },
        "model_limit_count" => 6
      },
      "tolerances" => %{
        "prior_candidate_count" => 0,
        "refreshed_candidate_count" => 0,
        "retained_candidate_count" => 0,
        "retained_candidate_row_count" => 0,
        "new_candidate_count" => 0,
        "new_candidate_row_count" => 0,
        "invalidated_candidate_count" => 0,
        "invalidated_candidate_row_count" => 0,
        "source_window_lineage_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external candidate-refresh validation",
        "checks candidate diff counts, semantic change reasons, replacement routing, and model-limit boundary only"
      ]
    },
    "fixture.artifact.refresh_budget_report.v1" => %{
      "id" => "fixture.artifact.refresh_budget_report.v1",
      "model_id" => "artifact.refresh_budget_report.v1",
      "reference_case" => "checked-in refresh budget artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/refresh_budget_report_v1.json",
        "contract" => "refresh_budget_report.v1"
      },
      "expected" => %{
        "schema_contract" => "refresh_budget_report.v1",
        "model" => "deterministic_candidate_limit_after_filters",
        "input_candidate_count" => 2,
        "kept_candidate_count" => 1,
        "dropped_candidate_count" => 1,
        "max_candidate_activities" => 1,
        "kept_candidate_id_count" => 1,
        "dropped_candidate_id_count" => 1,
        "first_kept_candidate_id" => "leo_1_observe_target_a_1",
        "first_dropped_candidate_id" => "leo_1_downlink_equator_prime_1",
        "budget_stage" => "after_contact_resource_and_allocation_filters",
        "optimizer_search_performed" => false,
        "selection_policy" => "highest_score_candidates_are_kept_then_artifact_order_is_restored",
        "model_limit_count" => 6
      },
      "tolerances" => %{
        "input_candidate_count" => 0,
        "kept_candidate_count" => 0,
        "dropped_candidate_count" => 0,
        "max_candidate_activities" => 0,
        "kept_candidate_id_count" => 0,
        "dropped_candidate_id_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external optimizer validation",
        "checks deterministic refresh budget counts, keep/drop IDs, and model-limit boundary only"
      ]
    },
    "fixture.artifact.execution_report.v1" => %{
      "id" => "fixture.artifact.execution_report.v1",
      "model_id" => "artifact.execution_report.v1",
      "reference_case" => "checked-in distributed execution report artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/execution_report_v1.json",
        "contract" => "execution_report.v1"
      },
      "expected" => %{
        "schema_contract" => "execution_report.v1",
        "status" => "completed_with_errors",
        "study_id" => "large_monte_carlo",
        "run_id" => "large_monte_carlo-2026-05-14T00:00:00Z",
        "backend" => "Elixir.OrbitalDynamics.Propagators.TwoBody",
        "execution_mode" => "distributed_task_supervisors",
        "scenario_count" => 2000,
        "completed_scenario_count" => 1999,
        "failed_scenario_count" => 1,
        "event_result_count" => 5997,
        "task_chunk_size" => 50,
        "effective_task_concurrency" => 16,
        "timeout" => 30_000,
        "failed_scenario_row_count" => 1,
        "first_failed_scenario_id" => "trial_1842",
        "first_failed_scenario_stage" => "propagation",
        "first_failed_scenario_resumability" => "manual_rerun_only",
        "first_failed_scenario_retry_recommendation" =>
          "rerun_failed_scenario_from_source_manifest",
        "node_distribution_counts" => %{
          "mission_ops@node_a" => 1000,
          "mission_ops@node_b" => 1000
        },
        "node_distribution_total" => 2000,
        "task_supervisor_node_count" => 2,
        "execution_plan_distribution_mode" => "distributed_task_supervisors",
        "execution_plan_task_batch_count" => 40,
        "execution_plan_wave_count" => 2,
        "execution_plan_supervisor_count" => 2,
        "execution_plan_batch_propagation" => false,
        "adaptive_chunking_policy" => "explicit",
        "adaptive_chunking_reason" => "operator_supplied_task_chunk_size",
        "backend_acceptance_tier" => "reference_default",
        "reference_backend" => true,
        "requires_benchmark_artifact" => false,
        "requires_reference_match" => true,
        "failure_isolation" =>
          "failed scenario is reported without dropping completed scenario counts",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "scenario_count" => 0,
        "completed_scenario_count" => 0,
        "failed_scenario_count" => 0,
        "event_result_count" => 0,
        "task_chunk_size" => 0,
        "effective_task_concurrency" => 0,
        "timeout" => 0,
        "failed_scenario_row_count" => 0,
        "node_distribution_total" => 0,
        "task_supervisor_node_count" => 0,
        "execution_plan_task_batch_count" => 0,
        "execution_plan_wave_count" => 0,
        "execution_plan_supervisor_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external execution validation",
        "checks distributed execution counts, failed-scenario isolation, backend acceptance evidence, and model-limit boundary only"
      ]
    },
    "fixture.artifact.freshness_report.v1" => %{
      "id" => "fixture.artifact.freshness_report.v1",
      "model_id" => "artifact.freshness_report.v1",
      "reference_case" => "checked-in accepted-state freshness artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/freshness_report_v1.json",
        "contract" => "freshness_report.v1"
      },
      "expected" => %{
        "schema_contract" => "freshness_report.v1",
        "model" => "accepted_snapshot_horizon_and_quality_freshness",
        "status" => "current",
        "state_quality_status" => "accepted",
        "accepted_state_quality_level" => "accepted",
        "allowed_state_quality_level_count" => 2,
        "first_allowed_state_quality_level" => "accepted",
        "last_allowed_state_quality_level" => "planning_accepted",
        "stale_reason_count" => 0,
        "unknown_reason_count" => 0,
        "freshness_reason_total" => 0,
        "accepted_snapshot_age_s" => 0,
        "horizon_start_offset_s" => 0,
        "current_epoch_s" => 0,
        "horizon_starts_at_s" => 0,
        "max_horizon_start_offset_s" => 1,
        "max_snapshot_age_s" => 86_400,
        "artifact_only_no_schedule_mutation" => true,
        "model_limit_count" => 6
      },
      "tolerances" => %{
        "allowed_state_quality_level_count" => 0,
        "stale_reason_count" => 0,
        "unknown_reason_count" => 0,
        "freshness_reason_total" => 0,
        "accepted_snapshot_age_s" => 0,
        "horizon_start_offset_s" => 0,
        "current_epoch_s" => 0,
        "horizon_starts_at_s" => 0,
        "max_horizon_start_offset_s" => 0,
        "max_snapshot_age_s" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external freshness validation",
        "checks accepted snapshot freshness counts, horizon offsets, state-quality routing, and no-schedule-mutation boundary only"
      ]
    },
    "fixture.artifact.manifest_field_reference.v1" => %{
      "id" => "fixture.artifact.manifest_field_reference.v1",
      "model_id" => "artifact.manifest_field_reference.v1",
      "reference_case" => "checked-in study manifest field reference artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/manifest_field_reference.json",
        "contract" => "manifest_field_reference.v1"
      },
      "expected" => %{
        "schema_contract" => "study_manifest.v1",
        "schema_version" => 1,
        "reference_mode" => "study_manifest_schema_field_reference",
        "compatibility_policy_version" => 1,
        "identity_policy_version" => 1,
        "field_count" => 3720,
        "field_row_count" => 3720,
        "required_field_count" => 162,
        "array_item_count" => 302,
        "section_count" => 19,
        "top_level_required_count" => 3,
        "activation_section_count" => 6,
        "supported_output_count" => 5,
        "supported_propagator_count" => 6,
        "supported_lint_error_code_count" => 15,
        "supported_search_objective_count" => 15,
        "generated_id_scope_count" => 2,
        "semantic_invariant_count" => 3,
        "first_field_path" => "$.campaign",
        "last_field_path" => "$.sun_direction.[]",
        "stable_id_pattern" => "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"
      },
      "tolerances" => %{
        "schema_version" => 0,
        "compatibility_policy_version" => 0,
        "identity_policy_version" => 0,
        "field_count" => 0,
        "field_row_count" => 0,
        "required_field_count" => 0,
        "array_item_count" => 0,
        "section_count" => 0,
        "top_level_required_count" => 0,
        "activation_section_count" => 0,
        "supported_output_count" => 0,
        "supported_propagator_count" => 0,
        "supported_lint_error_code_count" => 0,
        "supported_search_objective_count" => 0,
        "generated_id_scope_count" => 0,
        "semantic_invariant_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external manifest validation",
        "checks manifest field catalog counts, supported vocabularies, policy versions, and identity-policy bounds only"
      ]
    },
    "fixture.artifact.study_manifest_lint.v1" => %{
      "id" => "fixture.artifact.study_manifest_lint.v1",
      "model_id" => "artifact.study_manifest_lint.v1",
      "reference_case" => "checked-in study manifest lint artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/study_manifest_lint_v1.json",
        "contract" => "study_manifest_lint.v1"
      },
      "expected" => %{
        "schema_contract" => "study_manifest_lint.v1",
        "schema_version" => 1,
        "manifest_schema_contract" => "study_manifest.v1",
        "status" => "pass",
        "study_id" => "leo_constellation_campaign",
        "validation_mode" => "study_manifest_lint",
        "error_count" => 0,
        "warning_count" => 0,
        "scenario_count" => 2,
        "output_count" => 4,
        "first_output" => "trajectories",
        "last_output" => "target_visibility",
        "supported_output_count" => 5,
        "supported_propagator_count" => 6,
        "supported_lint_error_code_count" => 15,
        "supported_search_objective_count" => 15,
        "manifest_path" => "studies/leo_constellation_campaign.json",
        "lint_task" => "mix orbital_dynamics.manifest.lint --manifest PATH",
        "semantic_validator" =>
          "OrbitalDynamics.Study.Manifest.from_map/1 + OrbitalDynamics.StudyRunner.validate_run_inputs/2"
      },
      "tolerances" => %{
        "schema_version" => 0,
        "error_count" => 0,
        "warning_count" => 0,
        "scenario_count" => 0,
        "output_count" => 0,
        "supported_output_count" => 0,
        "supported_propagator_count" => 0,
        "supported_lint_error_code_count" => 0,
        "supported_search_objective_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external study-manifest certification",
        "checks manifest lint counts, supported vocabularies, output bounds, and semantic-validator identity only"
      ]
    },
    "fixture.artifact.approval_requirement.v1" => %{
      "id" => "fixture.artifact.approval_requirement.v1",
      "model_id" => "artifact.approval_requirement.v1",
      "reference_case" => "checked-in approval requirement artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/approval_requirement_v1.json",
        "contract" => "approval_requirement.v1"
      },
      "expected" => %{
        "schema_contract" => "approval_requirement.v1",
        "activity_id" => "cmd_repoint",
        "activity_type" => "command",
        "action" => "review_command_contact",
        "policy_classification" => "operator_review_required",
        "policy_bundle_id" => "contact_command_review_v1",
        "required_authority" => "contact_schedule_authority",
        "requirement_type" => "command_review",
        "rule_id" => "command_contact_review",
        "approval_rule_match_count" => 1,
        "policy_decision_classification" => "operator_review_required",
        "policy_decision_escalation_count" => 1,
        "timeline_identity_field_count" => 5,
        "timeline_identity_activity_id" => "cmd_repoint",
        "ground_station_id" => "equator_prime",
        "direction" => "command"
      },
      "tolerances" => %{
        "approval_rule_match_count" => 0,
        "policy_decision_escalation_count" => 0,
        "timeline_identity_field_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external policy validation",
        "checks approval requirement classification, authority routing, policy-decision echo, and timeline identity only"
      ]
    },
    "fixture.artifact.policy_decision.v1" => %{
      "id" => "fixture.artifact.policy_decision.v1",
      "model_id" => "artifact.policy_decision.v1",
      "reference_case" => "checked-in policy decision artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/policy_decision_v1.json",
        "contract" => "policy_decision.v1"
      },
      "expected" => %{
        "schema_contract" => "policy_decision.v1",
        "classification" => "operator_review_required",
        "policy_bundle_id" => "mission_ops_escalation_v1",
        "approval_requirement_count" => 1,
        "risk_count" => 0,
        "rule_match_count" => 1,
        "escalation_count" => 1,
        "first_rule_id" => "contact_execution_coordination",
        "first_required_authority" => "contact_schedule_authority",
        "first_escalation_queue" => "ground_network",
        "first_escalation_role" => "contact_scheduler",
        "first_escalation_sla_s" => 1800,
        "boundary" => "artifact_only_no_authority_lookup",
        "workflow_execution" => "none",
        "no_command_execution" => true,
        "no_schedule_mutation" => true,
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "approval_requirement_count" => 0,
        "risk_count" => 0,
        "rule_match_count" => 0,
        "escalation_count" => 0,
        "first_escalation_sla_s" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external policy validation",
        "checks policy decision classification, escalation routing, authority boundary, and model-limit evidence only"
      ]
    },
    "fixture.artifact.proposed_contact.v1" => %{
      "id" => "fixture.artifact.proposed_contact.v1",
      "model_id" => "artifact.proposed_contact.v1",
      "reference_case" => "checked-in proposed contact artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/proposed_contact_v1.json",
        "contract" => "proposed_contact.v1"
      },
      "expected" => %{
        "id" => "leo_1_downlink_equator_prime_1",
        "scenario_id" => "leo_1",
        "type" => "downlink",
        "direction" => "downlink",
        "ground_station_id" => "equator_prime",
        "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1",
        "source_window_type" => "ground_station_access",
        "event_detector" => "access_windows",
        "event_timing_policy" => "sampled_state_linear_boundary",
        "event_time_tolerance_s" => 60,
        "station_availability" => "available",
        "schedule_conflict_status" => "not_evaluated",
        "timeline_identity_activity_type" => "downlink",
        "cadence_import_contract" => "proposed_contact.v1",
        "model_limit_count" => 3,
        "duration_s" => 345.1793094813298,
        "estimated_throughput_mb" => 690.3586189626596
      },
      "tolerances" => %{
        "event_time_tolerance_s" => 0,
        "model_limit_count" => 0,
        "duration_s" => 1.0e-9,
        "estimated_throughput_mb" => 1.0e-9
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not station-provider validation",
        "checks proposed contact identity, timing, source-window, and artifact-only boundary only"
      ]
    },
    "fixture.artifact.policy_bundle.v1" => %{
      "id" => "fixture.artifact.policy_bundle.v1",
      "model_id" => "artifact.policy_bundle.v1",
      "reference_case" => "checked-in mission operations policy bundle artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/policy_bundle_v1.json",
        "contract" => "policy_bundle.v1"
      },
      "expected" => %{
        "schema_contract" => "policy_bundle.v1",
        "id" => "mission_ops_escalation_v1",
        "action_rule_count" => 6,
        "blocked_risk_type_count" => 2,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 2,
        "classification_counts" => %{
          "blocked_by_policy" => 1,
          "operator_review_required" => 5
        },
        "required_authority_counts" => %{
          "command_authority" => 1,
          "contact_schedule_authority" => 3,
          "flight_director" => 1,
          "mission_planning_authority" => 1
        },
        "boundary" => "artifact_only_no_authority_lookup",
        "workflow_execution" => "none",
        "provenance_source" => "OrbitalDynamics.Policy.bundle!",
        "no_command_execution" => true,
        "no_schedule_mutation" => true,
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "action_rule_count" => 0,
        "blocked_risk_type_count" => 0,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external policy validation",
        "checks representative policy bundle rule counts, authority routing maps, artifact-only boundary, and model-limit evidence only"
      ]
    },
    "fixture.artifact.policy_bundle.ground_network_allocation" => %{
      "id" => "fixture.artifact.policy_bundle.ground_network_allocation",
      "model_id" => "artifact.policy_bundle.v1",
      "reference_case" => "checked-in ground-network allocation policy bundle artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/policy_bundle_ground_network_allocation_v1.json",
        "contract" => "policy_bundle.v1"
      },
      "expected" => %{
        "schema_contract" => "policy_bundle.v1",
        "id" => "ground_network_allocation_v1",
        "action_rule_count" => 14,
        "blocked_risk_type_count" => 2,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 2,
        "classification_counts" => %{
          "blocked_by_policy" => 3,
          "operator_review_required" => 11
        },
        "required_authority_counts" => %{"contact_schedule_authority" => 14},
        "escalation_queue_counts" => %{
          "ground_network" => 13,
          "ground_network_priority" => 1
        },
        "station_availability_rule_count" => 3,
        "reduced_capacity_rule_count" => 2,
        "unavailable_or_maintenance_rule_count" => 1,
        "contention_rule_count" => 5,
        "contact_allocation_rule_count" => 1,
        "required_operator_action_rule_count" => 2,
        "command_direction_rule_count" => 1,
        "missing_trust_rule_count" => 1,
        "rule_ids_by_classification" => %{
          "blocked_by_policy" => [
            "duplicate_contact_identity_block",
            "reduced_station_capacity_insufficient_block",
            "unavailable_station_contact_block"
          ],
          "operator_review_required" => [
            "command_station_calendar_direction_review",
            "declared_provider_calendar_contention_review",
            "high_overlap_contact_contention_review",
            "invalid_contact_contention_input_review",
            "invalid_link_capacity_input_review",
            "low_actual_downlink_completion_review",
            "missing_priority_field_evidence_review",
            "missing_station_calendar_trust_review",
            "reserved_station_contact_review",
            "same_station_contact_contention_review",
            "severe_capacity_reduction_review"
          ]
        },
        "boundary" => "artifact_only_no_authority_lookup",
        "workflow_execution" => "none",
        "provenance_source" => "OrbitalDynamics.Policy.bundle!",
        "no_command_execution" => true,
        "no_schedule_mutation" => true,
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "action_rule_count" => 0,
        "blocked_risk_type_count" => 0,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 0,
        "station_availability_rule_count" => 0,
        "reduced_capacity_rule_count" => 0,
        "unavailable_or_maintenance_rule_count" => 0,
        "contention_rule_count" => 0,
        "contact_allocation_rule_count" => 0,
        "required_operator_action_rule_count" => 0,
        "command_direction_rule_count" => 0,
        "missing_trust_rule_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external policy validation",
        "checks ground-network allocation policy rule counts, authority routing, calendar-review triggers, and artifact-only boundary only"
      ]
    },
    "fixture.artifact.policy_bundle.operator_review_queue_authority" => %{
      "id" => "fixture.artifact.policy_bundle.operator_review_queue_authority",
      "model_id" => "artifact.policy_bundle.v1",
      "reference_case" => "checked-in operator-review queue authority policy bundle artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/policy_bundle_operator_review_queue_authority_v1.json",
        "contract" => "policy_bundle.v1"
      },
      "expected" => %{
        "schema_contract" => "policy_bundle.v1",
        "id" => "operator_review_queue_authority_v1",
        "action_rule_count" => 5,
        "blocked_risk_type_count" => 2,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 2,
        "classification_counts" => %{"operator_review_required" => 5},
        "required_authority_counts" => %{
          "contact_schedule_authority" => 1,
          "maneuver_authority" => 1,
          "mission_operations_authority" => 1,
          "resource_model_authority" => 1,
          "timeline_protection_authority" => 1
        },
        "escalation_queue_counts" => %{
          "flight_dynamics" => 1,
          "ground_network" => 1,
          "mission_operations" => 1,
          "mission_planning" => 2
        },
        "rule_ids_by_classification" => %{
          "operator_review_required" => [
            "ground_network_review_queue_authority",
            "maneuver_review_queue_authority",
            "policy_escalation_review_queue_authority",
            "resource_review_queue_authority",
            "timeline_review_queue_authority"
          ]
        },
        "required_operator_action_rule_count" => 0,
        "boundary" => "artifact_only_no_authority_lookup",
        "workflow_execution" => "none",
        "provenance_source" => "OrbitalDynamics.Policy.bundle!",
        "no_command_execution" => true,
        "no_schedule_mutation" => true,
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "action_rule_count" => 0,
        "blocked_risk_type_count" => 0,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 0,
        "required_operator_action_rule_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external policy validation",
        "checks operator-review queue authority routing, queue counts, rule IDs, and artifact-only boundary only"
      ]
    },
    "fixture.artifact.policy_bundle.command_contact_authority" => %{
      "id" => "fixture.artifact.policy_bundle.command_contact_authority",
      "model_id" => "artifact.policy_bundle.v1",
      "reference_case" => "checked-in command/contact authority policy bundle artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/policy_bundle_command_contact_authority_v1.json",
        "contract" => "policy_bundle.v1"
      },
      "expected" => %{
        "schema_contract" => "policy_bundle.v1",
        "id" => "command_contact_authority_v1",
        "action_rule_count" => 14,
        "blocked_risk_type_count" => 2,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 2,
        "classification_counts" => %{
          "blocked_by_policy" => 1,
          "operator_review_required" => 13
        },
        "required_authority_counts" => %{
          "cadence_import_boundary_authority" => 1,
          "command_authority" => 5,
          "contact_schedule_authority" => 6,
          "mission_planning_authority" => 1,
          "tracking_coordination_authority" => 1
        },
        "escalation_queue_counts" => %{
          "ground_network" => 6,
          "mission_operations" => 5,
          "mission_planning" => 2,
          "tracking_operations" => 1
        },
        "station_availability_rule_count" => 2,
        "required_operator_action_rule_count" => 2,
        "rule_ids_by_classification" => %{
          "blocked_by_policy" => ["command_window_station_calendar_block"],
          "operator_review_required" => [
            "command_result_failure_review",
            "command_uplink_authority_review",
            "command_window_station_calendar_review",
            "contact_result_failure_review",
            "downlink_schedule_authority_review",
            "failed_command_success_review",
            "failed_contact_success_review",
            "health_command_authority_review",
            "invalid_command_window_input_review",
            "low_command_success_confidence_review",
            "low_contact_success_confidence_review",
            "missing_cadence_import_review",
            "tracking_coordination_review"
          ]
        },
        "boundary" => "artifact_only_no_authority_lookup",
        "workflow_execution" => "none",
        "provenance_source" => "OrbitalDynamics.Policy.bundle!",
        "no_command_execution" => true,
        "no_schedule_mutation" => true,
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "action_rule_count" => 0,
        "blocked_risk_type_count" => 0,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 0,
        "station_availability_rule_count" => 0,
        "required_operator_action_rule_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external policy validation",
        "checks command/contact authority routing, queue counts, rule IDs, and artifact-only boundary only"
      ]
    },
    "fixture.artifact.policy_bundle.conservative_ops" => %{
      "id" => "fixture.artifact.policy_bundle.conservative_ops",
      "model_id" => "artifact.policy_bundle.v1",
      "reference_case" => "checked-in conservative operations policy bundle artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/policy_bundle_conservative_ops_v1.json",
        "contract" => "policy_bundle.v1"
      },
      "expected" => %{
        "schema_contract" => "policy_bundle.v1",
        "id" => "conservative_ops_v1",
        "action_rule_count" => 2,
        "blocked_risk_type_count" => 8,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 0,
        "classification_counts" => %{"blocked_by_policy" => 1, "operator_review_required" => 1},
        "required_authority_counts" => %{"unknown" => 2},
        "escalation_queue_counts" => %{"unknown" => 2},
        "rule_ids_by_classification" => %{
          "blocked_by_policy" => ["resource_pressure_block"],
          "operator_review_required" => ["all_requirements_review"]
        },
        "boundary" => "artifact_only_no_authority_lookup",
        "workflow_execution" => "none",
        "provenance_source" => "OrbitalDynamics.Policy.bundle!",
        "no_command_execution" => true,
        "no_schedule_mutation" => true,
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "action_rule_count" => 0,
        "blocked_risk_type_count" => 0,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external policy validation",
        "checks conservative policy blocking/review rules, risk limits, and artifact-only boundary only"
      ]
    },
    "fixture.artifact.policy_bundle.contact_command_review" => %{
      "id" => "fixture.artifact.policy_bundle.contact_command_review",
      "model_id" => "artifact.policy_bundle.v1",
      "reference_case" => "checked-in contact/command review policy bundle artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/policy_bundle_contact_command_review_v1.json",
        "contract" => "policy_bundle.v1"
      },
      "expected" => %{
        "schema_contract" => "policy_bundle.v1",
        "id" => "contact_command_review_v1",
        "action_rule_count" => 3,
        "blocked_risk_type_count" => 2,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 2,
        "classification_counts" => %{"operator_review_required" => 3},
        "required_authority_counts" => %{"unknown" => 3},
        "escalation_queue_counts" => %{"unknown" => 3},
        "rule_ids_by_classification" => %{
          "operator_review_required" => [
            "command_health_review",
            "contact_schedule_review",
            "invalid_contact_intent_input_review"
          ]
        },
        "boundary" => "artifact_only_no_authority_lookup",
        "workflow_execution" => "none",
        "provenance_source" => "OrbitalDynamics.Policy.bundle!",
        "no_command_execution" => true,
        "no_schedule_mutation" => true,
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "action_rule_count" => 0,
        "blocked_risk_type_count" => 0,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external policy validation",
        "checks contact/command review rule IDs, review-only classification, and artifact-only boundary only"
      ]
    },
    "fixture.artifact.policy_bundle.degraded_payload_guard" => %{
      "id" => "fixture.artifact.policy_bundle.degraded_payload_guard",
      "model_id" => "artifact.policy_bundle.v1",
      "reference_case" => "checked-in degraded payload guard policy bundle artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/policy_bundle_degraded_payload_guard_v1.json",
        "contract" => "policy_bundle.v1"
      },
      "expected" => %{
        "schema_contract" => "policy_bundle.v1",
        "id" => "degraded_payload_guard_v1",
        "action_rule_count" => 6,
        "blocked_risk_type_count" => 2,
        "auto_approvable_approval_count_limit" => 2,
        "auto_approvable_risk_limit" => 1,
        "operator_review_risk_limit" => 3,
        "classification_counts" => %{
          "auto_approvable" => 1,
          "blocked_by_policy" => 3,
          "operator_review_required" => 2
        },
        "required_authority_counts" => %{"resource_model_authority" => 2, "unknown" => 4},
        "escalation_queue_counts" => %{"resource_planning" => 2, "unknown" => 4},
        "rule_ids_by_classification" => %{
          "auto_approvable" => ["degraded_command_health_exemption"],
          "blocked_by_policy" => [
            "antenna_unavailable_contact_block",
            "degraded_payload_observation_block",
            "payload_unavailable_observation_block"
          ],
          "operator_review_required" => [
            "invalid_resource_filter_candidate_input_review",
            "invalid_resource_filter_summary_input_review"
          ]
        },
        "boundary" => "artifact_only_no_authority_lookup",
        "workflow_execution" => "none",
        "provenance_source" => "OrbitalDynamics.Policy.bundle!",
        "no_command_execution" => true,
        "no_schedule_mutation" => true,
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "action_rule_count" => 0,
        "blocked_risk_type_count" => 0,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external policy validation",
        "checks degraded payload guard block/review/exemption routing and artifact-only boundary only"
      ]
    },
    "fixture.artifact.policy_bundle.default" => %{
      "id" => "fixture.artifact.policy_bundle.default",
      "model_id" => "artifact.policy_bundle.v1",
      "reference_case" => "checked-in default fallback policy bundle artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/policy_bundle_default_v1.json",
        "contract" => "policy_bundle.v1"
      },
      "expected" => %{
        "schema_contract" => "policy_bundle.v1",
        "id" => "default_v1",
        "action_rule_count" => 0,
        "blocked_risk_type_count" => 2,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 3,
        "classification_counts" => %{},
        "required_authority_counts" => %{},
        "escalation_queue_counts" => %{},
        "rule_ids_by_classification" => %{},
        "boundary" => "artifact_only_no_authority_lookup",
        "workflow_execution" => "none",
        "provenance_source" => "OrbitalDynamics.Policy.bundle!",
        "no_command_execution" => true,
        "no_schedule_mutation" => true,
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "action_rule_count" => 0,
        "blocked_risk_type_count" => 0,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external policy validation",
        "checks default fallback limits and artifact-only boundary only"
      ]
    },
    "fixture.artifact.policy_bundle.maneuver_authority" => %{
      "id" => "fixture.artifact.policy_bundle.maneuver_authority",
      "model_id" => "artifact.policy_bundle.v1",
      "reference_case" => "checked-in maneuver authority policy bundle artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/policy_bundle_maneuver_authority_v1.json",
        "contract" => "policy_bundle.v1"
      },
      "expected" => %{
        "schema_contract" => "policy_bundle.v1",
        "id" => "maneuver_authority_v1",
        "action_rule_count" => 4,
        "blocked_risk_type_count" => 2,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 2,
        "classification_counts" => %{"operator_review_required" => 4},
        "required_authority_counts" => %{"maneuver_authority" => 4},
        "escalation_queue_counts" => %{"flight_dynamics" => 4},
        "required_operator_action_rule_count" => 0,
        "rule_ids_by_classification" => %{
          "operator_review_required" => [
            "impulsive_burn_authority_review",
            "invalid_maneuver_recommendation_review",
            "maneuver_result_failure_review",
            "maneuver_timing_authority_review"
          ]
        },
        "boundary" => "artifact_only_no_authority_lookup",
        "workflow_execution" => "none",
        "provenance_source" => "OrbitalDynamics.Policy.bundle!",
        "no_command_execution" => true,
        "no_schedule_mutation" => true,
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "action_rule_count" => 0,
        "blocked_risk_type_count" => 0,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 0,
        "required_operator_action_rule_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external policy validation",
        "checks maneuver authority routing, queue counts, rule IDs, and artifact-only boundary only"
      ]
    },
    "fixture.artifact.policy_bundle.resource_projection_authority" => %{
      "id" => "fixture.artifact.policy_bundle.resource_projection_authority",
      "model_id" => "artifact.policy_bundle.v1",
      "reference_case" => "checked-in resource projection authority policy bundle artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/policy_bundle_resource_projection_authority_v1.json",
        "contract" => "policy_bundle.v1"
      },
      "expected" => %{
        "schema_contract" => "policy_bundle.v1",
        "id" => "resource_projection_authority_v1",
        "action_rule_count" => 7,
        "blocked_risk_type_count" => 2,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 2,
        "classification_counts" => %{
          "blocked_by_policy" => 1,
          "operator_review_required" => 6
        },
        "required_authority_counts" => %{
          "flight_director" => 1,
          "resource_model_authority" => 6
        },
        "escalation_queue_counts" => %{
          "mission_operations" => 1,
          "mission_planning" => 4,
          "resource_planning" => 2
        },
        "required_operator_action_rule_count" => 0,
        "rule_ids_by_classification" => %{
          "blocked_by_policy" => ["combined_resource_pressure_director_block"],
          "operator_review_required" => [
            "first_storage_pressure_review",
            "invalid_resource_projection_activity_input_review",
            "invalid_resource_projection_summary_input_review",
            "missing_resource_trust_boundary_review",
            "resource_pressure_review",
            "unknown_resource_source_quality_review"
          ]
        },
        "boundary" => "artifact_only_no_authority_lookup",
        "workflow_execution" => "none",
        "provenance_source" => "OrbitalDynamics.Policy.bundle!",
        "no_command_execution" => true,
        "no_schedule_mutation" => true,
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "action_rule_count" => 0,
        "blocked_risk_type_count" => 0,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 0,
        "required_operator_action_rule_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external policy validation",
        "checks resource-projection authority routing, queue counts, rule IDs, and artifact-only boundary only"
      ]
    },
    "fixture.artifact.policy_bundle.timeline_protection" => %{
      "id" => "fixture.artifact.policy_bundle.timeline_protection",
      "model_id" => "artifact.policy_bundle.v1",
      "reference_case" => "checked-in timeline protection policy bundle artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/policy_bundle_timeline_protection_v1.json",
        "contract" => "policy_bundle.v1"
      },
      "expected" => %{
        "schema_contract" => "policy_bundle.v1",
        "id" => "timeline_protection_v1",
        "action_rule_count" => 9,
        "blocked_risk_type_count" => 2,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 2,
        "classification_counts" => %{
          "blocked_by_policy" => 1,
          "operator_review_required" => 8
        },
        "required_authority_counts" => %{
          "flight_director" => 1,
          "timeline_protection_authority" => 8
        },
        "escalation_queue_counts" => %{
          "mission_operations" => 1,
          "mission_planning" => 8
        },
        "required_operator_action_rule_count" => 0,
        "rule_ids_by_classification" => %{
          "blocked_by_policy" => ["executed_timeline_item_block"],
          "operator_review_required" => [
            "approved_timeline_item_review",
            "locked_timeline_item_review",
            "planned_protection_decision_review",
            "replacement_timeline_integrity_issue_review",
            "source_preserved_transition_review",
            "source_protection_decision_review",
            "source_timeline_integrity_issue_review",
            "timeline_integrity_issue_review"
          ]
        },
        "boundary" => "artifact_only_no_authority_lookup",
        "workflow_execution" => "none",
        "provenance_source" => "OrbitalDynamics.Policy.bundle!",
        "no_command_execution" => true,
        "no_schedule_mutation" => true,
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "action_rule_count" => 0,
        "blocked_risk_type_count" => 0,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 0,
        "required_operator_action_rule_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external policy validation",
        "checks timeline-protection authority routing, queue counts, rule IDs, and artifact-only boundary only"
      ]
    },
    "fixture.artifact.policy_bundle.organization_adapter" => %{
      "id" => "fixture.artifact.policy_bundle.organization_adapter",
      "model_id" => "artifact.policy_bundle.v1",
      "reference_case" => "checked-in organization adapter policy bundle artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/policy_bundle_organization_adapter_v1.json",
        "contract" => "policy_bundle.v1"
      },
      "expected" => %{
        "schema_contract" => "policy_bundle.v1",
        "id" => "org:mission_ops:authority:v1",
        "action_rule_count" => 1,
        "blocked_risk_type_count" => 0,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 1,
        "classification_counts" => %{"operator_review_required" => 1},
        "required_authority_counts" => %{"org_command_authority" => 1},
        "escalation_queue_counts" => %{"org_mission_ops" => 1},
        "rule_ids_by_classification" => %{
          "operator_review_required" => ["org_command_station_review"]
        },
        "boundary" => "artifact_only_no_authority_lookup",
        "workflow_execution" => "none",
        "provenance_source" => "organization_policy_adapter",
        "no_command_execution" => true,
        "no_schedule_mutation" => true,
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "action_rule_count" => 0,
        "blocked_risk_type_count" => 0,
        "auto_approvable_approval_count_limit" => 0,
        "auto_approvable_risk_limit" => 0,
        "operator_review_risk_limit" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external policy validation",
        "checks organization adapter authority routing, provenance source, and no-external-authority boundary only"
      ]
    },
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
    },
    "fixture.artifact.subsystem_model_capability.battery" => %{
      "id" => "fixture.artifact.subsystem_model_capability.battery",
      "model_id" => "artifact.subsystem_model_capability.v1",
      "reference_case" => "checked-in battery energy storage subsystem capability artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/subsystem_model_capability_v1.json",
        "contract" => "subsystem_model_capability.v1"
      },
      "expected" => %{
        "schema_contract" => "subsystem_model_capability.v1",
        "id" => "subsystem.power.battery.energy_storage.planning_grade",
        "subsystem" => "power",
        "model" => "battery_energy_storage_planning_grade",
        "source" => "resource_projection_activity_energy_hints",
        "validation_level" => "assumption_declared",
        "fidelity_tier" => "planning_grade",
        "resource_dimension_count" => 1,
        "resource_dimensions" => "battery",
        "activity_effect_field_count" => 4,
        "activity_effect_fields" =>
          "energy_consumed_wh|energy_generated_wh|battery_energy_used_wh|battery_energy_generated_wh",
        "activity_effect_type_count" => 2,
        "activity_effect_types" => "consumption|generation",
        "time_span" => "selected_activity_sequence",
        "state_variable_count" => 3,
        "state_variables" => "capacity_wh|energy_remaining_wh|state_of_charge_fraction",
        "parameter_count" => 4,
        "parameter_keys" =>
          "capacity_wh|max_state_of_charge_fraction|min_state_of_charge_fraction|round_trip_efficiency",
        "capacity_wh" => 1000,
        "min_state_of_charge_fraction" => 0.2,
        "max_state_of_charge_fraction" => 1,
        "round_trip_efficiency" => 1,
        "known_limit_count" => 4,
        "known_limit_keys" =>
          "selected_activity_sequence_only|declared_energy_hints_only|no_continuous_power_bus_or_thermal_coupling|no_battery_degradation_or_charge_dynamics",
        "selected_activity_sequence_only" => true,
        "declared_energy_hints_only" => true,
        "no_continuous_power_bus_or_thermal_coupling" => true,
        "no_battery_degradation_or_charge_dynamics" => true
      },
      "tolerances" => %{
        "resource_dimension_count" => 0,
        "activity_effect_field_count" => 0,
        "activity_effect_type_count" => 0,
        "state_variable_count" => 0,
        "parameter_count" => 0,
        "capacity_wh" => 0,
        "min_state_of_charge_fraction" => 0.0,
        "max_state_of_charge_fraction" => 0.0,
        "round_trip_efficiency" => 0.0,
        "known_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external subsystem validation",
        "checks declared battery planning-grade resource model boundaries and known limits only"
      ]
    },
    "fixture.artifact.subsystem_model_capability.storage" => %{
      "id" => "fixture.artifact.subsystem_model_capability.storage",
      "model_id" => "artifact.subsystem_model_capability.v1",
      "reference_case" => "checked-in data recorder storage subsystem capability artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/subsystem_model_capability_storage_v1.json",
        "contract" => "subsystem_model_capability.v1"
      },
      "expected" => %{
        "schema_contract" => "subsystem_model_capability.v1",
        "id" => "subsystem.data_recorder.storage_buffer.planning_grade",
        "subsystem" => "data_recorder",
        "model" => "data_storage_buffer_planning_grade",
        "source" => "resource_projection_activity_data_volume_hints",
        "validation_level" => "assumption_declared",
        "fidelity_tier" => "planning_grade",
        "resource_dimension_count" => 2,
        "resource_dimensions" => "storage|downlink",
        "activity_effect_field_count" => 6,
        "activity_effect_fields" =>
          "planned_data_volume_mb|data_volume_mb|estimated_data_volume_mb|estimated_storage_mb|required_downlink_mb|selected_downlink_mb",
        "activity_effect_type_count" => 2,
        "activity_effect_types" => "downlink|production",
        "time_span" => "selected_activity_sequence",
        "state_variable_count" => 4,
        "state_variables" =>
          "storage_capacity_mb|storage_used_mb|storage_remaining_mb|storage_margin",
        "parameter_count" => 3,
        "parameter_keys" => "downlink_completion_policy|min_storage_margin|storage_capacity_mb",
        "storage_capacity_mb" => 1000,
        "min_storage_margin" => 0,
        "downlink_completion_policy" => "selected_activity_order",
        "known_limit_count" => 4,
        "known_limit_keys" =>
          "selected_activity_sequence_only|declared_data_volume_hints_only|storage_limited_downlink_arithmetic_only|no_partition_priority_deletion_or_latency_model",
        "selected_activity_sequence_only" => true,
        "declared_data_volume_hints_only" => true,
        "storage_limited_downlink_arithmetic_only" => true,
        "no_partition_priority_deletion_or_latency_model" => true
      },
      "tolerances" => %{
        "resource_dimension_count" => 0,
        "activity_effect_field_count" => 0,
        "activity_effect_type_count" => 0,
        "state_variable_count" => 0,
        "parameter_count" => 0,
        "storage_capacity_mb" => 0,
        "min_storage_margin" => 0,
        "known_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external subsystem validation",
        "checks declared storage planning-grade resource model boundaries and known limits only"
      ]
    },
    "fixture.artifact.realized_activity.v1" => %{
      "id" => "fixture.artifact.realized_activity.v1",
      "model_id" => "artifact.realized_activity.v1",
      "reference_case" => "checked-in realized activity artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/realized_activity_v1.json",
        "contract" => "realized_activity.v1"
      },
      "expected" => %{
        "schema_contract" => "realized_activity.v1",
        "id" => "downlink_equator",
        "type" => "downlink",
        "status" => "partial",
        "planned_activity_id" => "downlink_equator",
        "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1",
        "timeline_id" => "timeline:downlink:equator_prime:access:leo_1:equator_prime:1",
        "ground_station_id" => "equator_prime",
        "direction" => "downlink",
        "planned_data_volume_mb" => 80,
        "actual_data_volume_mb" => 60,
        "data_volume_shortfall_mb" => 20,
        "completed_fraction" => 0.6,
        "contact_result" => "dropped",
        "contact_success" => false,
        "execution_uncertainty_status" => "declared",
        "resource_trust_boundary_status" => "declared",
        "adapter" => "cadence_feedback_adapter",
        "adapter_version" => "2026.05",
        "trust_boundary" => "operator_supplied",
        "provenance_trust_boundary" => "operator_supplied",
        "product_count" => 2
      },
      "tolerances" => %{
        "planned_data_volume_mb" => 0,
        "actual_data_volume_mb" => 0,
        "data_volume_shortfall_mb" => 0,
        "completed_fraction" => 0.0,
        "product_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external execution validation",
        "checks realized activity status, planned-vs-actual data volume, contact feedback, provenance, and adapter identity only"
      ]
    },
    "fixture.artifact.plan_delta.v1" => %{
      "id" => "fixture.artifact.plan_delta.v1",
      "model_id" => "artifact.plan_delta.v1",
      "reference_case" => "checked-in plan delta artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/plan_delta_v1.json",
        "contract" => "plan_delta.v1"
      },
      "expected" => %{
        "schema_contract" => "plan_delta.v1",
        "activity_id" => "leo_1_observe_target_a_1",
        "activity_type" => "observe",
        "status" => "failed",
        "reason" => "failed_observation_no_viable_replacement_window",
        "repair_action" => "canceled",
        "requires_approval" => true,
        "planned_type" => "observe",
        "planned_scenario_id" => "leo_1",
        "planned_source_window_id" => "window:leo_1:target_visibility:target_a:1",
        "planned_starts_at_s" => 0,
        "planned_ends_at_s" => 283.4546366421513,
        "realized_status" => "failed",
        "realized_reason" => "payload timeout",
        "source_timeline_id" =>
          "timeline:leo_1:observe:target_a:window:leo_1:target_visibility:target_a:1",
        "source_context_window_id" => "window:leo_1:target_visibility:target_a:1",
        "timeline_identity_field_count" => 6,
        "timeline_identity_activity_id" => "leo_1_observe_target_a_1"
      },
      "tolerances" => %{
        "planned_starts_at_s" => 0,
        "planned_ends_at_s" => 1.0e-12,
        "timeline_identity_field_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external repair validation",
        "checks plan-delta identity, failed realized status, repair action, approval requirement, and source timeline identity only"
      ]
    },
    "fixture.artifact.candidate_activity.v1" => %{
      "id" => "fixture.artifact.candidate_activity.v1",
      "model_id" => "artifact.candidate_activity.v1",
      "reference_case" => "checked-in candidate activity artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/candidate_activity_v1.json",
        "contract" => "candidate_activity.v1"
      },
      "expected" => %{
        "schema_contract" => "candidate_activity.v1",
        "id" => "leo_1_observe_target_a_1",
        "type" => "observe",
        "scenario_id" => "leo_1",
        "spacecraft_id" => "sat_1",
        "target_id" => "target_a",
        "source_window_id" => "window:leo_1:target_visibility:target_a:1",
        "source_window_type" => "target_visibility",
        "starts_at_s" => 0,
        "ends_at_s" => 282.8895569509249,
        "duration_s" => 282.8895569509249,
        "score" => 3469.6746834110986,
        "score_term_count" => 4,
        "target_priority" => 12,
        "required_downlink_mb" => 180,
        "required_observations" => 1,
        "product_count" => 2,
        "observation_objective_count" => 1,
        "collection_latency_objective_count" => 1,
        "target_priority_objective_count" => 1,
        "lighting_condition" => "sunlit",
        "lighting_condition_model" => "sampled_eclipse_overlap_tag",
        "eclipse_overlap_s" => 0,
        "event_timing_policy" => "sampled_state_linear_boundary",
        "event_time_tolerance_s" => 60,
        "max_sample_step_s" => 60
      },
      "tolerances" => %{
        "starts_at_s" => 0,
        "ends_at_s" => 1.0e-12,
        "duration_s" => 1.0e-12,
        "score" => 1.0e-9,
        "score_term_count" => 0,
        "target_priority" => 0,
        "required_downlink_mb" => 0,
        "required_observations" => 0,
        "product_count" => 0,
        "observation_objective_count" => 0,
        "collection_latency_objective_count" => 0,
        "target_priority_objective_count" => 0,
        "eclipse_overlap_s" => 0,
        "event_time_tolerance_s" => 0,
        "max_sample_step_s" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external opportunity validation",
        "checks candidate activity identity, score/objective counts, sampled-window provenance, and lighting tags only"
      ]
    },
    "fixture.artifact.contact_intent.v1" => %{
      "id" => "fixture.artifact.contact_intent.v1",
      "model_id" => "artifact.contact_intent.v1",
      "reference_case" => "checked-in contact intent artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/contact_intent_v1.json",
        "contract" => "contact_intent.v1"
      },
      "expected" => %{
        "schema_contract" => "contact_intent.v1",
        "id" => "refresh_downlink",
        "activity_type" => "downlink",
        "scenario_id" => "leo_1",
        "ground_station_id" => "equator_prime",
        "direction" => "downlink",
        "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1",
        "starts_at_s" => 100,
        "ends_at_s" => 160,
        "duration_s" => 60,
        "estimated_throughput_mb" => 120,
        "station_availability" => "available",
        "schedule_conflict_status" => "not_evaluated",
        "approval_status" => "operator_review_required",
        "approval_requirement_count" => 1,
        "approval_rule_match_count" => 1,
        "policy_decision_classification" => "operator_review_required",
        "policy_bundle_id" => "command_contact_authority_v1",
        "cadence_import_external_id" => "refresh_downlink",
        "cadence_import_activity_type" => "contact",
        "no_provider_reservation" => true,
        "no_schedule_mutation" => true,
        "no_command_execution" => true,
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "starts_at_s" => 0,
        "ends_at_s" => 0,
        "duration_s" => 0,
        "estimated_throughput_mb" => 0,
        "approval_requirement_count" => 0,
        "approval_rule_match_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external contact validation",
        "checks contact intent timing, approval routing, Cadence import metadata, and no-reservation/no-mutation boundaries only"
      ]
    },
    "fixture.artifact.contact_intent_summary.v1" => %{
      "id" => "fixture.artifact.contact_intent_summary.v1",
      "model_id" => "artifact.contact_intent_summary.v1",
      "reference_case" => "checked-in contact intent summary artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/contact_intent_summary_v1.json",
        "contract" => "contact_intent_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "contact_intent_summary.v1",
        "model" => "artifact_only_contact_intent_summary",
        "source_artifact_type" => "contact_intent.v1",
        "contact_intent_count" => 3,
        "capacity_pack_required_contact_count" => 3,
        "capacity_pack_required_capacity_fraction" => 0.95,
        "capacity_pack_required_capacity_fraction_by_ground_station_id" => %{
          "dss_43" => 0.5,
          "equator_prime" => 0.45
        },
        "capacity_pack_required_capacity_fraction_by_direction" => %{
          "command" => 0.5,
          "downlink" => 0.25,
          "tracking" => 0.2
        },
        "direction_counts" => %{"command" => 1, "downlink" => 1, "tracking" => 1},
        "direction_keys" => "command|downlink|tracking",
        "ground_station_keys" => "dss_43|equator_prime",
        "contact_ids_by_ground_station_id" => %{
          "dss_43" => ["throughput_capacity_contact"],
          "equator_prime" => ["capacity_model_contact", "direct_capacity_contact"]
        },
        "contact_ids_by_direction" => %{
          "command" => ["throughput_capacity_contact"],
          "downlink" => ["direct_capacity_contact"],
          "tracking" => ["capacity_model_contact"]
        },
        "capacity_pack_contact_ids_by_direction" => %{
          "command" => ["throughput_capacity_contact"],
          "downlink" => ["direct_capacity_contact"],
          "tracking" => ["capacity_model_contact"]
        },
        "required_capacity_fraction_source_counts" => %{
          "capacity_model" => 1,
          "contact_required_capacity_fraction" => 1,
          "throughput_model" => 1
        },
        "required_capacity_fraction_source_keys" =>
          "capacity_model|contact_required_capacity_fraction|throughput_model",
        "direction_routing_count" => 3,
        "model_limit_count" => 5,
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
        "assumption_source_artifact_type" => "contact_intent.v1",
        "no_provider_reservation" => true,
        "no_schedule_mutation" => true,
        "no_command_execution" => true
      },
      "tolerances" => %{
        "contact_intent_count" => 0,
        "capacity_pack_required_contact_count" => 0,
        "capacity_pack_required_capacity_fraction" => 0.0,
        "direction_routing_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by contact_intent_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external ground-network validation",
        "checks compact contact direction, station, capacity-source routing, and no-provider-reservation/no-mutation boundaries only"
      ]
    },
    "fixture.artifact.link_capacity_summary.v1" => %{
      "id" => "fixture.artifact.link_capacity_summary.v1",
      "model_id" => "artifact.link_capacity_summary.v1",
      "reference_case" => "checked-in link capacity summary artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/link_capacity_summary_v1.json",
        "contract" => "link_capacity_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "link_capacity_summary.v1",
        "model" => "artifact_only_link_capacity_summary",
        "source_artifact_type" => "link_capacity_report.v1",
        "station_count" => 1,
        "contact_count" => 1,
        "effective_contact_count" => 1,
        "ignored_contact_count" => 0,
        "selected_contact_count" => 1,
        "ignored_selected_contact_count" => 0,
        "required_downlink_contact_count" => 0,
        "actual_throughput_contact_count" => 1,
        "actual_completion_contact_count" => 0,
        "invalid_contact_input_count" => 0,
        "invalid_selected_contact_input_count" => 0,
        "invalid_policy_required_downlink_station_count" => 0,
        "downlink_requirement_status" => "satisfied",
        "actual_downlink_requirement_status" => "shortfall",
        "selection_utilization_status" => "fully_selected",
        "selected_downlink_shortfall_mb" => 0,
        "actual_downlink_shortfall_mb" => 10,
        "capacity_adjusted_throughput_mb" => 120,
        "selected_capacity_adjusted_throughput_mb" => 120,
        "unused_capacity_adjusted_throughput_mb" => 0,
        "contact_ids" => "science_downlink",
        "selected_contact_ids" => "science_downlink",
        "actual_throughput_contact_ids" => "science_downlink",
        "actual_completion_contact_ids" => "",
        "ground_station_ids" => "equator_prime",
        "selected_contact_ids_by_ground_station_id" => %{
          "equator_prime" => ["science_downlink"]
        },
        "actual_throughput_contact_ids_by_ground_station_id" => %{
          "equator_prime" => ["science_downlink"]
        },
        "actual_completion_contact_ids_by_ground_station_id" => %{},
        "capacity_adjusted_throughput_mb_by_ground_station_id" => %{
          "equator_prime" => 120
        },
        "selected_capacity_adjusted_throughput_mb_by_ground_station_id" => %{
          "equator_prime" => 120
        },
        "unused_capacity_adjusted_throughput_mb_by_ground_station_id" => %{
          "equator_prime" => 0
        },
        "model_limit_count" => 9,
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
        "assumption_source" => "link_capacity_report.v1",
        "operator_authority" => "not_granted_by_summary",
        "no_provider_reservation" => true,
        "no_schedule_mutation" => true,
        "no_link_budget_model" => true
      },
      "tolerances" => %{
        "station_count" => 0,
        "contact_count" => 0,
        "effective_contact_count" => 0,
        "ignored_contact_count" => 0,
        "selected_contact_count" => 0,
        "ignored_selected_contact_count" => 0,
        "required_downlink_contact_count" => 0,
        "actual_throughput_contact_count" => 0,
        "actual_completion_contact_count" => 0,
        "invalid_contact_input_count" => 0,
        "invalid_selected_contact_input_count" => 0,
        "invalid_policy_required_downlink_station_count" => 0,
        "selected_downlink_shortfall_mb" => 0,
        "actual_downlink_shortfall_mb" => 0,
        "capacity_adjusted_throughput_mb" => 0,
        "selected_capacity_adjusted_throughput_mb" => 0,
        "unused_capacity_adjusted_throughput_mb" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by link_capacity_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external link-budget validation",
        "checks compact contact, station, throughput routing, and no-provider-reservation/no-mutation boundaries only"
      ]
    },
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
    },
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
    },
    "fixture.artifact.backend_acceptance_policy.v1" => %{
      "id" => "fixture.artifact.backend_acceptance_policy.v1",
      "model_id" => "artifact.backend_acceptance_policy.v1",
      "reference_case" => "checked-in backend acceptance policy artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/backend_acceptance_policy_v1.json",
        "contract" => "backend_acceptance_policy.v1"
      },
      "expected" => %{
        "schema_contract" => "backend_acceptance_policy.v1",
        "tier_count" => 3,
        "implementation_count" => 6,
        "benchmark_case_count" => 2,
        "reference_backend_count" => 2,
        "known_limit_count" => 4,
        "numeric_tolerance_policy" => "validation_tolerance_policy.v1",
        "reference_backend_tier" => "reference_default",
        "two_body_tier" => "reference_default",
        "two_body_nx_tier" => "experimental_accelerator",
        "external_service_requires_provider_policy" => true
      },
      "tolerances" => %{
        "tier_count" => 0,
        "implementation_count" => 0,
        "benchmark_case_count" => 0,
        "reference_backend_count" => 0,
        "known_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external backend validation",
        "checks backend tier counts, implementation routing, reference backend mapping, and tolerance-policy link only"
      ]
    },
    "fixture.artifact.validation_tolerance_policy.v1" => %{
      "id" => "fixture.artifact.validation_tolerance_policy.v1",
      "model_id" => "artifact.validation_tolerance_policy.v1",
      "reference_case" => "checked-in validation tolerance policy artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/validation_tolerance_policy_v1.json",
        "contract" => "validation_tolerance_policy.v1"
      },
      "expected" => %{
        "schema_contract" => "validation_tolerance_policy.v1",
        "validation_level_count" => 5,
        "comparison_model_count" => 3,
        "event_timing_key_count" => 4,
        "artifact_regression_limit" => "not an external physics or operations truth model",
        "artifact_regression_scope" =>
          "schema and public-surface stability checks for checked-in artifacts",
        "current_event_timing_policy" => "sampled_state_linear_boundary",
        "validated_level_description" =>
          "reserved for future external reference-tool or operational validation evidence"
      },
      "tolerances" => %{
        "validation_level_count" => 0,
        "comparison_model_count" => 0,
        "event_timing_key_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external validation policy certification",
        "checks tolerance policy level counts, comparison model vocabulary, event-timing policy, and artifact-regression boundary only"
      ]
    },
    "fixture.artifact.validation_record.v1" => %{
      "id" => "fixture.artifact.validation_record.v1",
      "model_id" => "artifact.validation_record.v1",
      "reference_case" => "checked-in validation record artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/validation_record_v1.json",
        "contract" => "validation_record.v1"
      },
      "expected" => %{
        "schema_contract" => "validation_record.v1",
        "id" => "propagator.two_body",
        "model" => "point_mass_two_body",
        "implementation" => "OrbitalDynamics.Propagators.TwoBody",
        "validation_level" => "educational",
        "evidence_count" => 3,
        "known_limit_count" => 3,
        "tolerance_count" => 3,
        "position_tolerance_km" => 1.0e-6,
        "velocity_tolerance_km_s" => 1.0e-9,
        "energy_relative_tolerance" => 1.0e-9
      },
      "tolerances" => %{
        "evidence_count" => 0,
        "known_limit_count" => 0,
        "tolerance_count" => 0,
        "position_tolerance_km" => 0.0,
        "velocity_tolerance_km_s" => 0.0,
        "energy_relative_tolerance" => 0.0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external model validation",
        "checks validation record identity, implementation, validation level, evidence/limit counts, and tolerance values only"
      ]
    },
    "fixture.artifact.validation_reference_report.v1" => %{
      "id" => "fixture.artifact.validation_reference_report.v1",
      "model_id" => "artifact.validation_reference_report.v1",
      "reference_case" => "checked-in standalone validation reference report artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/validation_reference_report_v1.json",
        "contract" => "validation_reference_report.v1"
      },
      "expected" => %{
        "schema_contract" => "validation_reference_report.v1",
        "fixture_id" => "fixture.artifact.campaign_plan.leo_constellation_v1",
        "model_id" => "artifact.campaign_plan.v1",
        "validation_level" => "artifact_contract",
        "status" => "pass",
        "status_counts" => %{"pass" => 3},
        "check_count" => 3,
        "pass_check_count" => 3,
        "fail_check_count" => 0,
        "check_field_order" => "activity_count|candidate_activity_count|planner"
      },
      "tolerances" => %{
        "check_count" => 0,
        "pass_check_count" => 0,
        "fail_check_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external validation evidence",
        "checks standalone reference report status and check routing only"
      ]
    },
    "fixture.artifact.validation_check.v1" => %{
      "id" => "fixture.artifact.validation_check.v1",
      "model_id" => "artifact.validation_check.v1",
      "reference_case" => "checked-in validation check artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/validation_check_v1.json",
        "contract" => "validation_check.v1"
      },
      "expected" => %{
        "schema_contract" => "validation_check.v1",
        "field" => "activity_count",
        "status" => "pass",
        "expected" => 1,
        "observed" => 1,
        "tolerance" => 0,
        "error" => 0
      },
      "tolerances" => %{
        "expected" => 0,
        "observed" => 0,
        "tolerance" => 0,
        "error" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external validation evidence",
        "checks validation check scalar equality fields only"
      ]
    },
    "fixture.artifact.timeline_diff_report.v1" => %{
      "id" => "fixture.artifact.timeline_diff_report.v1",
      "model_id" => "artifact.timeline_diff_report.v1",
      "reference_case" => "checked-in timeline diff artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/timeline_diff_report_v1.json",
        "contract" => "timeline_diff_report.v1"
      },
      "expected" => %{
        "schema_contract" => "timeline_diff_report.v1",
        "model" => "timeline_identity_activity_diff",
        "source" => "repair.activities",
        "source_activity_count" => 3,
        "replacement_activity_count" => 3,
        "row_count" => 4,
        "added_count" => 1,
        "changed_count" => 2,
        "removed_count" => 1,
        "unchanged_count" => 0,
        "review_required_count" => 4,
        "duplicate_timeline_identity_count" => 0,
        "duplicate_source_timeline_identity_count" => 0,
        "duplicate_replacement_timeline_identity_count" => 0,
        "diff_status_counts" => %{"added" => 1, "changed" => 2, "removed" => 1},
        "row_derived_diff_status_counts" => %{
          "added" => 1,
          "changed" => 2,
          "removed" => 1
        },
        "approval_transition_counts" => %{"added" => 1, "changed" => 1, "removed" => 1},
        "row_derived_approval_transition_counts" => %{
          "added" => 1,
          "changed" => 1,
          "removed" => 1
        },
        "status_transition_counts" => %{"added" => 1, "changed" => 1, "removed" => 1},
        "row_derived_status_transition_counts" => %{
          "added" => 1,
          "changed" => 1,
          "removed" => 1
        },
        "required_operator_action_counts" => %{
          "review_added_activity" => 1,
          "review_changed_protected_activity" => 1,
          "review_removed_activity" => 1,
          "review_timeline_change" => 1
        },
        "row_derived_required_operator_action_counts" => %{
          "review_added_activity" => 1,
          "review_changed_protected_activity" => 1,
          "review_removed_activity" => 1,
          "review_timeline_change" => 1
        },
        "changed_field_counts" => %{
          "activity_id" => 1,
          "approval_status" => 1,
          "ends_at_s" => 1,
          "execution_uncertainty" => 1,
          "starts_at_s" => 1,
          "status" => 1,
          "timeline_presence" => 2
        },
        "row_derived_changed_field_counts" => %{
          "activity_id" => 1,
          "approval_status" => 1,
          "ends_at_s" => 1,
          "execution_uncertainty" => 1,
          "starts_at_s" => 1,
          "status" => 1,
          "timeline_presence" => 2
        },
        "row_ids_by_diff_status" => %{
          "added" => ["timeline_diff:timeline:cmd_added"],
          "changed" => [
            "timeline_diff:timeline:obs_1",
            "timeline_diff:timeline:raise_apogee"
          ],
          "removed" => ["timeline_diff:timeline:dl_removed"]
        },
        "row_ids_by_required_operator_action" => %{
          "review_added_activity" => ["timeline_diff:timeline:cmd_added"],
          "review_changed_protected_activity" => ["timeline_diff:timeline:obs_1"],
          "review_removed_activity" => ["timeline_diff:timeline:dl_removed"],
          "review_timeline_change" => ["timeline_diff:timeline:raise_apogee"]
        },
        "row_derived_row_ids_by_diff_status" => %{
          "added" => ["timeline_diff:timeline:cmd_added"],
          "changed" => [
            "timeline_diff:timeline:obs_1",
            "timeline_diff:timeline:raise_apogee"
          ],
          "removed" => ["timeline_diff:timeline:dl_removed"]
        },
        "row_derived_row_ids_by_required_operator_action" => %{
          "review_added_activity" => ["timeline_diff:timeline:cmd_added"],
          "review_changed_protected_activity" => ["timeline_diff:timeline:obs_1"],
          "review_removed_activity" => ["timeline_diff:timeline:dl_removed"],
          "review_timeline_change" => ["timeline_diff:timeline:raise_apogee"]
        },
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "source_activity_count" => 0,
        "replacement_activity_count" => 0,
        "row_count" => 0,
        "added_count" => 0,
        "changed_count" => 0,
        "removed_count" => 0,
        "unchanged_count" => 0,
        "review_required_count" => 0,
        "duplicate_timeline_identity_count" => 0,
        "duplicate_source_timeline_identity_count" => 0,
        "duplicate_replacement_timeline_identity_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external timeline validation",
        "checks timeline diff counts, transition maps, operator-action routing, and no-schedule-mutation boundary only"
      ]
    },
    "fixture.artifact.cadence_import_manifest.v1" => %{
      "id" => "fixture.artifact.cadence_import_manifest.v1",
      "model_id" => "artifact.cadence_import_manifest.v1",
      "reference_case" => "checked-in Cadence import manifest artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/cadence_import_manifest_v1.json",
        "contract" => "cadence_import_manifest.v1"
      },
      "expected" => %{
        "schema_contract" => "cadence_import_manifest.v1",
        "schema_version" => 1,
        "model" => "artifact_only_cadence_import_manifest",
        "manifest_id" => "cadence_import_manifest:repair:fixture",
        "source_artifact_type" => "campaign_repair.v2",
        "source_artifact_id" => "repair:fixture",
        "row_count" => 2,
        "ready_count" => 1,
        "row_derived_ready_count" => 1,
        "blocked_count" => 1,
        "row_derived_blocked_count" => 1,
        "review_required_count" => 0,
        "missing_import_count" => 1,
        "row_derived_missing_import_count" => 1,
        "source_review_count" => 2,
        "import_status_counts" => %{
          "blocked_missing_cadence_import" => 1,
          "ready_for_import" => 1
        },
        "row_derived_import_status_counts" => %{
          "blocked_missing_cadence_import" => 1,
          "ready_for_import" => 1
        },
        "import_action_counts" => %{"import_replacement_activity" => 2},
        "row_derived_import_action_counts" => %{"import_replacement_activity" => 2},
        "cadence_import_status_counts" => %{"missing" => 1, "present" => 1},
        "row_derived_cadence_import_status_counts" => %{"missing" => 1, "present" => 1},
        "required_operator_action_counts" => %{"review_moved_timeline_item" => 2},
        "row_derived_required_operator_action_counts" => %{
          "review_moved_timeline_item" => 2
        },
        "source_review_type_counts" => %{"plan_delta_review" => 2},
        "row_derived_source_review_type_counts" => %{"plan_delta_review" => 2},
        "import_side_counts" => %{"replacement" => 2},
        "row_derived_import_side_counts" => %{"replacement" => 2},
        "source_review_queue_counts" => %{
          "plan_delta_review|review_moved_timeline_item|not_required" => 2
        },
        "row_derived_source_review_queue_counts" => %{
          "plan_delta_review|review_moved_timeline_item|not_required" => 2
        },
        "manifest_row_ids_by_import_status" => %{
          "blocked_missing_cadence_import" => ["cadence_import:plan_delta:dl_3:moved:2"],
          "ready_for_import" => ["cadence_import:plan_delta:dl_1:moved:1"]
        },
        "row_derived_manifest_row_ids_by_import_status" => %{
          "blocked_missing_cadence_import" => ["cadence_import:plan_delta:dl_3:moved:2"],
          "ready_for_import" => ["cadence_import:plan_delta:dl_1:moved:1"]
        },
        "execution_boundary" => "artifact_only_no_cadence_api_writes",
        "authorization_boundary" => "operator_review_or_cadence_adapter_must_authorize_import",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "schema_version" => 0,
        "row_count" => 0,
        "ready_count" => 0,
        "row_derived_ready_count" => 0,
        "blocked_count" => 0,
        "row_derived_blocked_count" => 0,
        "review_required_count" => 0,
        "missing_import_count" => 0,
        "row_derived_missing_import_count" => 0,
        "source_review_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external Cadence API validation",
        "checks import manifest counts, handoff routing, and no-write authorization boundary only"
      ]
    },
    "fixture.artifact.cadence_import_manifest.resource_projection_battery_handoff_v1" => %{
      "id" => "fixture.artifact.cadence_import_manifest.resource_projection_battery_handoff_v1",
      "model_id" => "artifact.cadence_import_manifest.v1",
      "reference_case" =>
        "checked-in Cadence import resource-projection battery handoff artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" =>
          "study_results/cadence_import_resource_projection_battery_handoff_v1.json",
        "contract" => "cadence_import_manifest.v1",
        "source_contract" => "resource_projection_report.v1"
      },
      "expected" => %{
        "schema_contract" => "cadence_import_manifest.v1",
        "model" => "artifact_only_cadence_import_manifest",
        "source_artifact_type" => "resource_projection_report.v1",
        "row_count" => 1,
        "review_required_count" => 1,
        "source_review_type_counts" => %{"resource_projection_review" => 1},
        "import_action_counts" => %{"review_resource_projection" => 1},
        "resource_projection_battery_handoff_count" => 1,
        "source_review_battery_handoff_count" => 1,
        "total_resource_projection_battery_energy_consumed_wh" => 23.0,
        "total_resource_projection_battery_energy_generated_wh" => 8.0,
        "net_resource_projection_battery_energy_delta_wh" => 15.0,
        "peak_resource_projection_battery_overuse_wh" => 4.0,
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "row_count" => 0,
        "review_required_count" => 0,
        "resource_projection_battery_handoff_count" => 0,
        "source_review_battery_handoff_count" => 0,
        "total_resource_projection_battery_energy_consumed_wh" => 0.0,
        "total_resource_projection_battery_energy_generated_wh" => 0.0,
        "net_resource_projection_battery_energy_delta_wh" => 0.0,
        "peak_resource_projection_battery_overuse_wh" => 0.0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external Cadence API validation",
        "checks resource-projection battery handoff routing and no-write boundary only"
      ]
    },
    "fixture.artifact.command_window_report.v1" => %{
      "id" => "fixture.artifact.command_window_report.v1",
      "model_id" => "artifact.command_window_report.v1",
      "reference_case" => "checked-in command window artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/command_window_report_v1.json",
        "contract" => "command_window_report.v1"
      },
      "expected" => %{
        "schema_contract" => "command_window_report.v1",
        "model" => "artifact_only_command_window_report",
        "source" => "fixture.command_window.activities",
        "window_count" => 4,
        "row_count" => 4,
        "command_count" => 1,
        "health_check_count" => 1,
        "tracking_count" => 1,
        "uplink_count" => 1,
        "review_required_count" => 2,
        "source_window_lineage_count" => 1,
        "locked_window_count" => 1,
        "window_type_counts" => %{
          "command_window" => 1,
          "health_check_window" => 1,
          "tracking_window" => 1,
          "uplink_window" => 1
        },
        "row_derived_window_type_counts" => %{
          "command_window" => 1,
          "health_check_window" => 1,
          "tracking_window" => 1,
          "uplink_window" => 1
        },
        "required_operator_action_counts" => %{
          "monitor_activity" => 2,
          "prepare_cadence_import" => 1,
          "review_command_contact" => 1
        },
        "row_derived_required_operator_action_counts" => %{
          "monitor_activity" => 2,
          "prepare_cadence_import" => 1,
          "review_command_contact" => 1
        },
        "approval_status_counts" => %{
          "approved" => 1,
          "not_required" => 1,
          "operator_review_required" => 2
        },
        "row_derived_approval_status_counts" => %{
          "approved" => 1,
          "not_required" => 1,
          "operator_review_required" => 2
        },
        "cadence_import_status_counts" => %{
          "missing" => 2,
          "not_applicable" => 1,
          "present" => 1
        },
        "row_derived_cadence_import_status_counts" => %{
          "missing" => 2,
          "not_applicable" => 1,
          "present" => 1
        },
        "window_ids_by_required_operator_action" => %{
          "monitor_activity" => [
            "command_window:health_poll",
            "command_window:tracking_pass"
          ],
          "prepare_cadence_import" => ["command_window:uplink_contact"],
          "review_command_contact" => ["command_window:cmd_window"]
        },
        "row_derived_window_ids_by_required_operator_action" => %{
          "monitor_activity" => [
            "command_window:health_poll",
            "command_window:tracking_pass"
          ],
          "prepare_cadence_import" => ["command_window:uplink_contact"],
          "review_command_contact" => ["command_window:cmd_window"]
        },
        "execution_boundary" => "artifact_only_no_schedule_mutation_or_command_execution",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "window_count" => 0,
        "row_count" => 0,
        "command_count" => 0,
        "health_check_count" => 0,
        "tracking_count" => 0,
        "uplink_count" => 0,
        "review_required_count" => 0,
        "source_window_lineage_count" => 0,
        "locked_window_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external command execution validation",
        "checks command-window counts, operator action routing, and artifact-only boundary only"
      ]
    },
    "fixture.artifact.constraint_report.v1" => %{
      "id" => "fixture.artifact.constraint_report.v1",
      "model_id" => "artifact.constraint_report.v1",
      "reference_case" => "checked-in constraint report artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/constraint_report_v1.json",
        "contract" => "constraint_report.v1"
      },
      "expected" => %{
        "schema_contract" => "constraint_report.v1",
        "model" => "artifact_metric_threshold",
        "status" => "fail",
        "constraint_count" => 2,
        "row_count" => 3,
        "constraint_row_count" => 3,
        "status_counts" => %{"fail" => 1, "pass" => 1, "warning" => 1},
        "row_derived_status_counts" => %{"fail" => 1, "pass" => 1, "warning" => 1},
        "metric_counts" => %{"estimated_throughput_mb" => 1, "min_altitude_km" => 2},
        "row_derived_metric_counts" => %{
          "estimated_throughput_mb" => 1,
          "min_altitude_km" => 2
        },
        "operator_counts" => %{">=" => 3},
        "row_derived_operator_counts" => %{">=" => 3},
        "constraint_ids_by_status" => %{
          "fail" => ["minimum_operational_altitude"],
          "pass" => ["minimum_operational_altitude"],
          "warning" => ["downlink_margin"]
        },
        "row_derived_constraint_ids_by_status" => %{
          "fail" => ["minimum_operational_altitude"],
          "pass" => ["minimum_operational_altitude"],
          "warning" => ["downlink_margin"]
        },
        "constraint_model" => "artifact_level_metric_thresholds",
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "constraint_count" => 0,
        "row_count" => 0,
        "constraint_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external constraint validation",
        "checks threshold status distribution, metric rows, and artifact-level boundary only"
      ]
    },
    "fixture.artifact.timeline_activity_lifecycle_state.v1" => %{
      "id" => "fixture.artifact.timeline_activity_lifecycle_state.v1",
      "model_id" => "artifact.timeline_activity_lifecycle_state.v1",
      "reference_case" => "checked-in single-activity lifecycle-state artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/timeline_activity_lifecycle_state_v1.json",
        "contract" => "timeline_activity_lifecycle_state.v1"
      },
      "expected" => %{
        "schema_contract" => "timeline_activity_lifecycle_state.v1",
        "model" => "artifact_only_timeline_activity_lifecycle_state",
        "validation_level" => "artifact_contract",
        "activity_id" => "cmd_provider",
        "planned_activity_id" => "cmd_provider",
        "realized_activity_id" => "cmd_provider",
        "timeline_id" => "timeline:cmd_provider",
        "planned_timeline_id" => "timeline:cmd_provider",
        "realized_timeline_id" => "timeline:cmd_provider",
        "planned_status" => "executing",
        "realized_status" => "completed",
        "planned_status_category" => "planned",
        "realized_status_category" => "executed",
        "planned_approval_status" => "operator_review_required",
        "realized_approval_status" => "approved",
        "planned_approval_category" => "review_required",
        "realized_approval_category" => "protected",
        "planned_locked" => false,
        "realized_locked" => false,
        "planned_executed" => false,
        "realized_executed" => true,
        "status_transition_decision" => "record",
        "approval_transition_decision" => "review",
        "transition_decision" => "review",
        "review_required" => true,
        "required_operator_action" => "review_activity_approval",
        "required_operator_action_count" => 2,
        "required_operator_action_keys" => "record_timeline_change|review_activity_approval",
        "operator_action_reason_count" => 2,
        "operator_action_reason_keys" =>
          "activity_execution_recorded|approval_grant_requires_operator_authority",
        "import_action" => "review_timeline_diff",
        "status_transition_category" => "execution_recorded",
        "status_transition_operator_action_reason" => "activity_execution_recorded",
        "approval_transition_category" => "approval_granted",
        "approval_transition_operator_action_reason" =>
          "approval_grant_requires_operator_authority",
        "planned_protection_decision" => "mutable",
        "planned_protection_category" => "none",
        "planned_protection_reason" => "no_timeline_protection",
        "realized_protection_decision" => "preserve",
        "realized_protection_category" => "executed",
        "realized_protection_reason" => "activity_already_completed",
        "artifact_only" => true,
        "no_schedule_mutation" => true,
        "no_operator_authority_grant" => true,
        "no_cadence_import" => true,
        "no_command_execution" => true
      },
      "tolerances" => %{
        "required_operator_action_count" => 0,
        "operator_action_reason_count" => 0
      },
      "evidence" => [
        "generated by OrbitalDynamics.Timeline.activity_lifecycle_state/2",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks single-activity lifecycle status, approval, protection, and no-authority boundary only"
      ]
    },
    "fixture.artifact.timeline_activity_status_state.v1" => %{
      "id" => "fixture.artifact.timeline_activity_status_state.v1",
      "model_id" => "artifact.timeline_activity_status_state.v1",
      "reference_case" => "checked-in single-activity status-state artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/timeline_activity_status_state_v1.json",
        "contract" => "timeline_activity_status_state.v1"
      },
      "expected" => %{
        "schema_contract" => "timeline_activity_status_state.v1",
        "model" => "artifact_only_timeline_activity_status_state",
        "validation_level" => "artifact_contract",
        "activity_id" => "obs_provider",
        "planned_activity_id" => "obs_provider",
        "realized_activity_id" => "obs_provider",
        "timeline_id" => "timeline:obs_provider",
        "planned_timeline_id" => "timeline:obs_provider",
        "realized_timeline_id" => "timeline:obs_provider",
        "planned_status" => "executing",
        "realized_status" => "completed",
        "planned_status_category" => "planned",
        "realized_status_category" => "executed",
        "transition_decision" => "record",
        "review_required" => false,
        "required_operator_action" => "record_timeline_change",
        "operator_action_reason" => "activity_execution_recorded",
        "import_action" => "import_replacement_activity",
        "status_transition_field" => "status",
        "status_transition_type" => "changed",
        "status_transition_from" => "executing",
        "status_transition_to" => "completed",
        "status_transition_from_category" => "planned",
        "status_transition_to_category" => "executed",
        "status_transition_category" => "execution_recorded",
        "status_transition_requires_operator_review" => false,
        "status_transition_operator_action_reason" => "activity_execution_recorded",
        "planned_context_status" => "executing",
        "planned_context_source_window_id" => "visibility:obs_provider",
        "realized_context_status" => "completed",
        "artifact_only" => true,
        "no_schedule_mutation" => true,
        "no_operator_authority_grant" => true,
        "no_command_execution" => true
      },
      "tolerances" => %{},
      "evidence" => [
        "generated by OrbitalDynamics.Timeline.activity_status_state/2",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks single-activity status transition, import routing, and no-authority boundary only"
      ]
    },
    "fixture.artifact.timeline_activity_approval_state.v1" => %{
      "id" => "fixture.artifact.timeline_activity_approval_state.v1",
      "model_id" => "artifact.timeline_activity_approval_state.v1",
      "reference_case" => "checked-in single-activity approval-state artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/timeline_activity_approval_state_v1.json",
        "contract" => "timeline_activity_approval_state.v1"
      },
      "expected" => %{
        "schema_contract" => "timeline_activity_approval_state.v1",
        "model" => "artifact_only_timeline_activity_approval_state",
        "validation_level" => "artifact_contract",
        "activity_id" => "cmd_provider",
        "planned_activity_id" => "cmd_provider",
        "realized_activity_id" => "cmd_provider",
        "timeline_id" => "timeline:cmd_provider",
        "planned_timeline_id" => "timeline:cmd_provider",
        "realized_timeline_id" => "timeline:cmd_provider",
        "planned_approval_status" => "operator_review_required",
        "realized_approval_status" => "approved",
        "planned_approval_category" => "review_required",
        "realized_approval_category" => "protected",
        "transition_decision" => "review",
        "review_required" => true,
        "required_operator_action" => "review_activity_approval",
        "operator_action_reason" => "approval_grant_requires_operator_authority",
        "import_action" => "review_timeline_diff",
        "approval_transition_field" => "approval_status",
        "approval_transition_type" => "changed",
        "approval_transition_from" => "operator_review_required",
        "approval_transition_to" => "approved",
        "approval_transition_from_category" => "review_required",
        "approval_transition_to_category" => "protected",
        "approval_transition_category" => "approval_granted",
        "approval_transition_requires_operator_review" => true,
        "approval_transition_operator_action_reason" =>
          "approval_grant_requires_operator_authority",
        "planned_context_approval_status" => "operator_review_required",
        "planned_context_source_window_id" => "command:cmd_provider",
        "realized_context_approval_status" => "approved",
        "artifact_only" => true,
        "no_schedule_mutation" => true,
        "no_operator_authority_grant" => true,
        "no_command_execution" => true
      },
      "tolerances" => %{},
      "evidence" => [
        "generated by OrbitalDynamics.Timeline.activity_approval_state/2",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks single-activity approval transition, operator-review routing, and no-authority boundary only"
      ]
    },
    "fixture.artifact.timeline_lifecycle_state_summary.v1" => %{
      "id" => "fixture.artifact.timeline_lifecycle_state_summary.v1",
      "model_id" => "artifact.timeline_lifecycle_state_summary.v1",
      "reference_case" => "checked-in aggregate lifecycle-state summary artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/timeline_lifecycle_state_summary_v1.json",
        "contract" => "timeline_lifecycle_state_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "timeline_lifecycle_state_summary.v1",
        "model" => "artifact_only_timeline_lifecycle_state_summary",
        "source" => "validation.timeline_lifecycle_state_summary",
        "validation_level" => "artifact_contract",
        "planned_activity_count" => 5,
        "realized_activity_count" => 3,
        "row_count" => 4,
        "row_derived_row_count" => 4,
        "review_row_count" => 2,
        "row_derived_review_row_count" => 2,
        "recordable_count" => 1,
        "row_derived_recordable_count" => 1,
        "preserved_count" => 1,
        "row_derived_preserved_count" => 1,
        "review_required_count" => 2,
        "row_derived_review_required_count" => 2,
        "duplicate_timeline_identity_count" => 1,
        "row_derived_duplicate_timeline_identity_count" => 1,
        "invalid_activity_input_count" => 0,
        "row_derived_invalid_activity_input_count" => 0,
        "transition_decision_counts" => %{"none" => 1, "record" => 1, "review" => 2},
        "row_derived_transition_decision_counts" => %{
          "none" => 1,
          "record" => 1,
          "review" => 2
        },
        "required_operator_action_counts" => %{
          "none" => 1,
          "record_timeline_change" => 1,
          "review_activity_approval" => 1,
          "review_duplicate_timeline_identity" => 1
        },
        "row_derived_required_operator_action_counts" => %{
          "none" => 1,
          "record_timeline_change" => 1,
          "review_activity_approval" => 1,
          "review_duplicate_timeline_identity" => 1
        },
        "operator_action_reason_counts" => %{
          "activity_execution_recorded" => 2,
          "approval_grant_requires_operator_authority" => 1,
          "duplicate_timeline_identity" => 1
        },
        "row_derived_operator_action_reason_counts" => %{
          "activity_execution_recorded" => 2,
          "approval_grant_requires_operator_authority" => 1,
          "duplicate_timeline_identity" => 1
        },
        "import_action_counts" => %{
          "import_replacement_activity" => 1,
          "record_preserved_activity" => 1,
          "review_timeline_diff" => 2
        },
        "row_derived_import_action_counts" => %{
          "import_replacement_activity" => 1,
          "record_preserved_activity" => 1,
          "review_timeline_diff" => 2
        },
        "planned_status_category_counts" => %{"executed" => 1, "planned" => 2},
        "row_derived_planned_status_category_counts" => %{"executed" => 1, "planned" => 2},
        "realized_status_category_counts" => %{"executed" => 3},
        "row_derived_realized_status_category_counts" => %{"executed" => 3},
        "planned_approval_category_counts" => %{
          "other" => 1,
          "protected" => 1,
          "review_required" => 1
        },
        "row_derived_planned_approval_category_counts" => %{
          "other" => 1,
          "protected" => 1,
          "review_required" => 1
        },
        "realized_approval_category_counts" => %{"other" => 1, "protected" => 2},
        "row_derived_realized_approval_category_counts" => %{"other" => 1, "protected" => 2},
        "status_transition_category_counts" => %{"execution_recorded" => 2},
        "row_derived_status_transition_category_counts" => %{"execution_recorded" => 2},
        "approval_transition_category_counts" => %{"approval_granted" => 1},
        "row_derived_approval_transition_category_counts" => %{"approval_granted" => 1},
        "recordable_timeline_keys" => "timeline:obs_record",
        "row_derived_recordable_timeline_keys" => "timeline:obs_record",
        "preserved_timeline_keys" => "timeline:done_keep",
        "row_derived_preserved_timeline_keys" => "timeline:done_keep",
        "review_timeline_keys" => "timeline:cmd_provider|timeline:dup",
        "row_derived_review_timeline_keys" => "timeline:cmd_provider|timeline:dup",
        "review_activity_keys" => "cmd_provider|dup_a|dup_b",
        "row_derived_review_activity_keys" => "cmd_provider|dup_a|dup_b",
        "invalid_activity_input_keys" => "",
        "review_timeline_ids_by_required_operator_action" => %{
          "review_activity_approval" => ["timeline:cmd_provider"],
          "review_duplicate_timeline_identity" => ["timeline:dup"]
        },
        "row_derived_review_timeline_ids_by_required_operator_action" => %{
          "review_activity_approval" => ["timeline:cmd_provider"],
          "review_duplicate_timeline_identity" => ["timeline:dup"]
        },
        "review_timeline_ids_by_operator_action_reason" => %{
          "activity_execution_recorded" => ["timeline:cmd_provider"],
          "approval_grant_requires_operator_authority" => ["timeline:cmd_provider"],
          "duplicate_timeline_identity" => ["timeline:dup"]
        },
        "row_derived_review_timeline_ids_by_operator_action_reason" => %{
          "activity_execution_recorded" => ["timeline:cmd_provider"],
          "approval_grant_requires_operator_authority" => ["timeline:cmd_provider"],
          "duplicate_timeline_identity" => ["timeline:dup"]
        },
        "review_timeline_ids_by_approval_transition_category" => %{
          "approval_granted" => ["timeline:cmd_provider"]
        },
        "row_derived_review_timeline_ids_by_approval_transition_category" => %{
          "approval_granted" => ["timeline:cmd_provider"]
        },
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "operator_authority" => "not_granted_by_summary",
        "cadence_import" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary",
        "identity_match" => "planned and realized rows are paired by timeline identity"
      },
      "tolerances" => %{
        "row_count" => 0,
        "row_derived_row_count" => 0,
        "review_required_count" => 0,
        "row_derived_review_required_count" => 0,
        "duplicate_timeline_identity_count" => 0,
        "row_derived_duplicate_timeline_identity_count" => 0
      },
      "evidence" => [
        "generated by OrbitalDynamics.Timeline.lifecycle_state_summary/3",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks aggregate lifecycle row routing, review identity maps, and no-authority boundary only"
      ]
    },
    "fixture.artifact.timeline_preservation_report.v1" => %{
      "id" => "fixture.artifact.timeline_preservation_report.v1",
      "model_id" => "artifact.timeline_preservation_report.v1",
      "reference_case" => "checked-in aggregate timeline preservation report artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/timeline_preservation_report_v1.json",
        "contract" => "timeline_preservation_report.v1"
      },
      "expected" => %{
        "schema_contract" => "timeline_preservation_report.v1",
        "model" => "artifact_only_lifecycle_preservation_summary",
        "source" => "validation.timeline_preservation_report",
        "activity_count" => 4,
        "row_count" => 3,
        "row_derived_row_count" => 3,
        "mutable_activity_count" => 1,
        "preserve_activity_count" => 2,
        "row_derived_preserve_activity_count" => 2,
        "review_change_activity_count" => 1,
        "row_derived_review_change_activity_count" => 1,
        "preservation_sensitive_activity_count" => 3,
        "row_derived_preservation_sensitive_activity_count" => 3,
        "row_derived_invalid_activity_input_count" => 1,
        "timeline_preservation_status" => "review_required",
        "protection_decision_counts" => %{
          "mutable" => 1,
          "preserve" => 2,
          "review_change" => 1
        },
        "row_derived_protection_decision_counts" => %{
          "preserve" => 2,
          "review_change" => 1
        },
        "protection_category_counts" => %{
          "executed" => 1,
          "invalid_activity_input" => 1,
          "locked_or_approved" => 1,
          "none" => 1
        },
        "row_derived_protection_category_counts" => %{
          "executed" => 1,
          "invalid_activity_input" => 1,
          "locked_or_approved" => 1
        },
        "protection_reason_counts" => %{
          "activity_already_completed" => 1,
          "activity_locked_or_approved" => 1,
          "missing_activity_type" => 1,
          "no_timeline_protection" => 1
        },
        "row_derived_protection_reason_counts" => %{
          "activity_already_completed" => 1,
          "activity_locked_or_approved" => 1,
          "missing_activity_type" => 1
        },
        "preserve_activity_keys" => "contact_locked|obs_done",
        "row_derived_preserve_activity_keys" => "contact_locked|obs_done",
        "review_change_activity_keys" => "bad_missing_type",
        "row_derived_review_change_activity_keys" => "bad_missing_type",
        "mutable_activity_keys" => "cmd_mutable",
        "preservation_sensitive_activity_keys" => "bad_missing_type|contact_locked|obs_done",
        "row_derived_preservation_sensitive_activity_keys" =>
          "bad_missing_type|contact_locked|obs_done",
        "preservation_sensitive_timeline_keys" =>
          "timeline:invalid_activity_input:bad_missing_type|timeline:observe|timeline:planned_contact",
        "row_derived_preservation_sensitive_timeline_keys" =>
          "timeline:invalid_activity_input:bad_missing_type|timeline:observe|timeline:planned_contact",
        "invalid_activity_input_keys" => "bad_missing_type",
        "activity_id_sets_by_protection_decision" => %{
          "mutable" => ["cmd_mutable"],
          "preserve" => ["contact_locked", "obs_done"],
          "review_change" => ["bad_missing_type"]
        },
        "row_derived_activity_id_sets_by_protection_decision" => %{
          "preserve" => ["contact_locked", "obs_done"],
          "review_change" => ["bad_missing_type"]
        },
        "timeline_id_sets_by_protection_decision" => %{
          "mutable" => ["timeline:command"],
          "preserve" => ["timeline:observe", "timeline:planned_contact"],
          "review_change" => ["timeline:invalid_activity_input:bad_missing_type"]
        },
        "row_derived_timeline_id_sets_by_protection_decision" => %{
          "preserve" => ["timeline:observe", "timeline:planned_contact"],
          "review_change" => ["timeline:invalid_activity_input:bad_missing_type"]
        },
        "activity_id_sets_by_protection_category" => %{
          "executed" => ["obs_done"],
          "invalid_activity_input" => ["bad_missing_type"],
          "locked_or_approved" => ["contact_locked"],
          "none" => ["cmd_mutable"]
        },
        "row_derived_activity_id_sets_by_protection_category" => %{
          "executed" => ["obs_done"],
          "invalid_activity_input" => ["bad_missing_type"],
          "locked_or_approved" => ["contact_locked"]
        },
        "timeline_id_sets_by_protection_reason" => %{
          "activity_already_completed" => ["timeline:observe"],
          "activity_locked_or_approved" => ["timeline:planned_contact"],
          "missing_activity_type" => ["timeline:invalid_activity_input:bad_missing_type"],
          "no_timeline_protection" => ["timeline:command"]
        },
        "row_derived_timeline_id_sets_by_protection_reason" => %{
          "activity_already_completed" => ["timeline:observe"],
          "activity_locked_or_approved" => ["timeline:planned_contact"],
          "missing_activity_type" => ["timeline:invalid_activity_input:bad_missing_type"]
        },
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "scope" => "lifecycle_lock_approval_and_executed_preservation_review",
        "assumption_source" => "validation.timeline_preservation_report",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "row_count" => 0,
        "row_derived_row_count" => 0,
        "preservation_sensitive_activity_count" => 0,
        "row_derived_preservation_sensitive_activity_count" => 0,
        "review_change_activity_count" => 0,
        "row_derived_review_change_activity_count" => 0
      },
      "evidence" => [
        "generated by OrbitalDynamics.Timeline.preservation_report/2",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks preservation/report row routing, invalid input review evidence, and no-mutation boundary only"
      ]
    },
    "fixture.artifact.timeline_preservation_status.v1" => %{
      "id" => "fixture.artifact.timeline_preservation_status.v1",
      "model_id" => "artifact.timeline_preservation_status.v1",
      "reference_case" => "checked-in single-activity timeline preservation status artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/timeline_preservation_status_v1.json",
        "contract" => "timeline_preservation_status.v1"
      },
      "expected" => %{
        "schema_contract" => "timeline_preservation_status.v1",
        "model" => "artifact_only_lifecycle_preservation_status",
        "activity_id" => "dl_locked",
        "activity_type" => "downlink",
        "timeline_id" => "timeline:dl_locked",
        "timeline_identity_activity_id" => "dl_locked",
        "timeline_identity_activity_type" => "downlink",
        "timeline_identity_timeline_id" => "timeline:dl_locked",
        "status" => "planned",
        "approval_status" => "pending",
        "locked" => true,
        "approved" => false,
        "protection_decision" => "preserve",
        "protection_category" => "locked_or_approved",
        "protection_reason" => "activity_locked_or_approved",
        "timeline_preservation_status" => "preservation_required",
        "requires_preservation" => true,
        "requires_operator_review" => false,
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "scope" => "single_activity_lifecycle_preservation_preflight",
        "model_limit_count" => 4,
        "no_schedule_mutation" => true,
        "no_command_execution" => true,
        "derived_identity_when_no_persistent_timeline_id" => true
      },
      "tolerances" => %{"model_limit_count" => 0},
      "evidence" => [
        "generated by OrbitalDynamics.timeline_preservation_status/1",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks single-activity lock preservation and artifact-only no-mutation boundary only"
      ]
    },
    "fixture.artifact.timeline_activity_state.v1" => %{
      "id" => "fixture.artifact.timeline_activity_state.v1",
      "model_id" => "artifact.timeline_activity_state.v1",
      "reference_case" => "checked-in timeline activity state artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/timeline_activity_state_v1.json",
        "contract" => "timeline_activity_state.v1"
      },
      "expected" => %{
        "schema_contract" => "timeline_activity_state.v1",
        "model" => "artifact_only_timeline_activity_state",
        "validation_level" => "artifact_contract",
        "state_status" => "review_required",
        "row_count" => 2,
        "row_derived_row_count" => 2,
        "review_required" => true,
        "activity_id" => "cmd_lock",
        "timeline_id" => "timeline:cmd_lock",
        "planned_timeline_id" => "timeline:cmd_lock",
        "feedback_kind" => "command",
        "match_strategy" => "unmatched_planned",
        "planned_status" => "approved",
        "planned_protection_decision" => "preserve",
        "planned_protection_category" => "locked_or_approved",
        "planned_protection_reason" => "activity_locked_or_approved",
        "status_transition_category" => "status_removed",
        "activity_keys" => "cmd_lock|cmd_new",
        "review_activity_keys" => "cmd_lock|cmd_new",
        "status_counts" => %{"planned_only" => 1, "realized_only" => 1},
        "row_derived_status_counts" => %{"planned_only" => 1, "realized_only" => 1},
        "feedback_kind_counts" => %{"command" => 2},
        "row_derived_feedback_kind_counts" => %{"command" => 2},
        "match_strategy_counts" => %{
          "unmatched_planned" => 1,
          "unmatched_realized" => 1
        },
        "row_derived_match_strategy_counts" => %{
          "unmatched_planned" => 1,
          "unmatched_realized" => 1
        },
        "cadence_import_status_counts" => %{"missing" => 1},
        "row_derived_cadence_import_status_counts" => %{"missing" => 1, "unknown" => 1},
        "planned_protection_decision_counts" => %{"preserve" => 1},
        "row_derived_planned_protection_decision_counts" => %{
          "preserve" => 1,
          "unknown" => 1
        },
        "row_derived_status_transition_category_counts" => %{
          "status_added" => 1,
          "status_removed" => 1
        },
        "activity_ids_by_status" => %{
          "planned_only" => ["cmd_lock"],
          "realized_only" => ["cmd_new"]
        },
        "row_derived_activity_ids_by_status" => %{
          "planned_only" => ["cmd_lock"],
          "realized_only" => ["cmd_new"]
        },
        "row_derived_activity_ids_by_match_strategy" => %{
          "unmatched_planned" => ["cmd_lock"],
          "unmatched_realized" => ["cmd_new"]
        },
        "artifact_only" => true,
        "no_schedule_mutation" => true,
        "no_command_execution" => true,
        "source" => "timeline_feedback.reconcile",
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "row_count" => 0,
        "row_derived_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "generated by OrbitalDynamics.TimelineFeedback.activity_state/3",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external execution validation",
        "checks activity-state row routing, review identity, preservation evidence, and no-command/no-mutation boundary only"
      ]
    },
    "fixture.artifact.timeline_activity_precondition_summary.v1" => %{
      "id" => "fixture.artifact.timeline_activity_precondition_summary.v1",
      "model_id" => "artifact.timeline_activity_precondition_summary.v1",
      "reference_case" => "checked-in timeline activity precondition summary artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/timeline_activity_precondition_summary_v1.json",
        "contract" => "timeline_activity_precondition_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "timeline_activity_precondition_summary.v1",
        "model" => "artifact_only_timeline_activity_precondition_summary",
        "validation_level" => "artifact_contract",
        "activity_id" => "cmd_source",
        "timeline_id" => "timeline:cmd_source",
        "activity_type" => "command",
        "precondition_status" => "blocked",
        "blocked_precondition_count" => 2,
        "review_precondition_count" => 1,
        "blocked_precondition_type_keys" => "payload_unavailable|resource_block_declared",
        "review_precondition_type_keys" => "degraded_mode",
        "precondition_count" => 3,
        "row_derived_precondition_status_counts" => %{
          "blocked" => 2,
          "review_required" => 1
        },
        "row_derived_precondition_type_counts" => %{
          "degraded_mode" => 1,
          "payload_unavailable" => 1,
          "resource_block_declared" => 1
        },
        "timeline_identity_activity_id" => "cmd_source",
        "timeline_identity_timeline_id" => "timeline:cmd_source",
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "operator_authority" => "not_granted_by_precondition_summary",
        "resource_authority" => "not_reserved_by_precondition_summary"
      },
      "tolerances" => %{},
      "evidence" => [
        "generated by OrbitalDynamics.Timeline.activity_precondition_summary/1",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external validation evidence",
        "checks artifact-only precondition status/count routing and no-authority assumptions"
      ]
    },
    "fixture.artifact.timeline_integrity_report.v1" => %{
      "id" => "fixture.artifact.timeline_integrity_report.v1",
      "model_id" => "artifact.timeline_integrity_report.v1",
      "reference_case" => "checked-in timeline integrity report artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/timeline_integrity_report_v1.json",
        "contract" => "timeline_integrity_report.v1"
      },
      "expected" => %{
        "schema_contract" => "timeline_integrity_report.v1",
        "model" => "artifact_only_timeline_integrity_summary",
        "validation_level" => "artifact_contract",
        "source" => "timeline.activities",
        "activity_count" => 3,
        "valid_activity_count" => 3,
        "invalid_activity_input_count" => 0,
        "timeline_integrity_status" => "review_required",
        "timeline_integrity_review_count" => 1,
        "row_derived_timeline_integrity_review_count" => 1,
        "timeline_integrity_issue_count" => 3,
        "row_derived_timeline_integrity_issue_count" => 3,
        "timeline_integrity_issue_type_keys" =>
          "dependency_order_violation|exclusivity_overlap|missing_dependency_activity",
        "timeline_integrity_issue_type_counts" => %{
          "dependency_order_violation" => 1,
          "exclusivity_overlap" => 1,
          "missing_dependency_activity" => 1
        },
        "row_derived_timeline_integrity_issue_type_counts" => %{
          "dependency_order_violation" => 1,
          "exclusivity_overlap" => 1,
          "missing_dependency_activity" => 1
        },
        "required_operator_action_counts" => %{"review_timeline_integrity" => 1},
        "row_derived_required_operator_action_counts" => %{"review_timeline_integrity" => 1},
        "operator_action_reason_counts" => %{"timeline_integrity_issue" => 1},
        "row_derived_operator_action_reason_counts" => %{"timeline_integrity_issue" => 1},
        "dependency_issue_count" => 2,
        "exclusivity_issue_count" => 1,
        "review_activity_keys" => "cmd_main",
        "review_timeline_keys" => "timeline:command:dss_14:10.0",
        "dependency_review_activity_keys" => "cmd_main",
        "exclusivity_review_activity_keys" => "cmd_main",
        "missing_dependency_activity_keys" => "missing_gate",
        "dependency_order_violation_activity_keys" => "health_gate",
        "exclusivity_violation_activity_keys" => "dl_conflict",
        "exclusivity_violation_timeline_keys" => "timeline:downlink:dss_14:12.0",
        "review_activity_ids_by_issue_type" => %{
          "dependency_order_violation" => ["cmd_main"],
          "exclusivity_overlap" => ["cmd_main"],
          "missing_dependency_activity" => ["cmd_main"]
        },
        "row_derived_activity_ids_by_issue_type" => %{
          "dependency_order_violation" => ["cmd_main"],
          "exclusivity_overlap" => ["cmd_main"],
          "missing_dependency_activity" => ["cmd_main"]
        },
        "review_timeline_ids_by_required_operator_action" => %{
          "review_timeline_integrity" => ["timeline:command:dss_14:10.0"]
        },
        "row_derived_timeline_ids_by_required_operator_action" => %{
          "review_timeline_integrity" => ["timeline:command:dss_14:10.0"]
        },
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "missing_dependency_validation" => "enabled",
        "scope" => "dependency_and_exclusivity_integrity_validation",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "activity_count" => 0,
        "valid_activity_count" => 0,
        "invalid_activity_input_count" => 0,
        "timeline_integrity_review_count" => 0,
        "row_derived_timeline_integrity_review_count" => 0,
        "timeline_integrity_issue_count" => 0,
        "row_derived_timeline_integrity_issue_count" => 0,
        "dependency_issue_count" => 0,
        "exclusivity_issue_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "generated by OrbitalDynamics.Timeline.integrity_report/2",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external dependency validation evidence",
        "checks integrity review rows, dependency/exclusivity evidence, row-derived issue maps, and no-schedule-mutation boundary only"
      ]
    },
    "fixture.artifact.timeline_dependency_impact_summary.v1" => %{
      "id" => "fixture.artifact.timeline_dependency_impact_summary.v1",
      "model_id" => "artifact.timeline_dependency_impact_summary.v1",
      "reference_case" => "checked-in timeline dependency impact summary artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/timeline_dependency_impact_summary_v1.json",
        "contract" => "timeline_dependency_impact_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "timeline_dependency_impact_summary.v1",
        "model" => "artifact_only_timeline_dependency_impact_summary",
        "validation_level" => "artifact_contract",
        "source" => "timeline_diff_report.v1",
        "source_activity_count" => 4,
        "replacement_activity_count" => 3,
        "changed_source_activity_count" => 2,
        "changed_source_timeline_count" => 2,
        "dependency_impact_status" => "review_required",
        "dependent_activity_count" => 4,
        "source_dependent_activity_count" => 2,
        "replacement_dependent_activity_count" => 2,
        "impacted_source_activity_keys" => "dl_followup|health_gate",
        "dependent_activity_keys" => "cmd_main|obs_parallel",
        "impacted_dependency_activity_keys" => "health_gate",
        "impacted_exclusive_with_activity_keys" => "dl_followup",
        "dependency_impact_row_count" => 4,
        "row_derived_scope_counts" => %{"replacement" => 2, "source" => 2},
        "row_derived_dependency_impact_status_counts" => %{"review_required" => 4},
        "row_derived_required_operator_action_counts" => %{
          "review_timeline_integrity" => 4
        },
        "row_derived_operator_action_reason_counts" => %{
          "dependency_changed_or_removed_source_activity" => 2,
          "exclusivity_changed_or_removed_source_activity" => 2
        },
        "row_derived_activity_type_counts" => %{"command" => 2, "observe" => 2},
        "row_ids_by_required_operator_action" => %{
          "review_timeline_integrity" => [
            "dependency_impact:replacement:timeline:command:20.0",
            "dependency_impact:replacement:timeline:observe:60.0",
            "dependency_impact:source:timeline:command:20.0",
            "dependency_impact:source:timeline:observe:60.0"
          ]
        },
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "operator_authority" => "not_granted_by_summary",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "source_activity_count" => 0,
        "replacement_activity_count" => 0,
        "changed_source_activity_count" => 0,
        "changed_source_timeline_count" => 0,
        "dependent_activity_count" => 0,
        "source_dependent_activity_count" => 0,
        "replacement_dependent_activity_count" => 0,
        "dependency_impact_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "generated by OrbitalDynamics.Timeline.dependency_impact_summary/2",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external dependency validation evidence",
        "checks dependency-impact counts, row routing, and no-authority assumptions"
      ]
    },
    "fixture.artifact.timeline_diff_summary.v1" => %{
      "id" => "fixture.artifact.timeline_diff_summary.v1",
      "model_id" => "artifact.timeline_diff_summary.v1",
      "reference_case" => "checked-in timeline diff summary artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/timeline_diff_summary_v1.json",
        "contract" => "timeline_diff_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "timeline_diff_summary.v1",
        "model" => "artifact_only_timeline_diff_summary",
        "validation_level" => "artifact_contract",
        "source_artifact_type" => "timeline_diff_report.v1",
        "source" => "repair.activities",
        "source_activity_count" => 2,
        "replacement_activity_count" => 2,
        "row_count" => 3,
        "added_count" => 1,
        "removed_count" => 1,
        "changed_count" => 1,
        "unchanged_count" => 0,
        "review_required_count" => 3,
        "review_row_count" => 3,
        "diff_status_counts" => %{"added" => 1, "changed" => 1, "removed" => 1},
        "row_derived_diff_status_counts" => %{"added" => 1, "changed" => 1, "removed" => 1},
        "transition_decision_counts" => %{"preserve_source" => 1, "review" => 2},
        "row_derived_transition_decision_counts" => %{
          "preserve_source" => 1,
          "review" => 2
        },
        "required_operator_action_counts" => %{
          "review_added_activity" => 1,
          "review_changed_protected_activity" => 1,
          "review_removed_activity" => 1
        },
        "row_derived_required_operator_action_counts" => %{
          "review_added_activity" => 1,
          "review_changed_protected_activity" => 1,
          "review_removed_activity" => 1
        },
        "changed_field_counts" => %{
          "activity_id" => 1,
          "approval_status" => 1,
          "ends_at_s" => 1,
          "starts_at_s" => 1,
          "status" => 1,
          "timeline_presence" => 2
        },
        "row_derived_changed_field_counts" => %{
          "activity_id" => 1,
          "approval_status" => 1,
          "ends_at_s" => 1,
          "starts_at_s" => 1,
          "status" => 1,
          "timeline_presence" => 2
        },
        "status_transition_category_counts" => %{
          "status_added" => 1,
          "status_changed" => 1,
          "status_removed" => 1
        },
        "row_derived_status_transition_category_counts" => %{
          "status_added" => 1,
          "status_changed" => 1,
          "status_removed" => 1
        },
        "approval_transition_category_counts" => %{
          "approval_regressed" => 1,
          "approval_removed" => 1,
          "approval_review_required" => 1
        },
        "row_derived_approval_transition_category_counts" => %{
          "approval_regressed" => 1,
          "approval_removed" => 1,
          "approval_review_required" => 1
        },
        "review_timeline_ids_by_required_operator_action" => %{
          "review_added_activity" => ["timeline:cmd_added"],
          "review_changed_protected_activity" => ["timeline:obs_1"],
          "review_removed_activity" => ["timeline:dl_removed"]
        },
        "row_derived_review_timeline_ids_by_required_operator_action" => %{
          "review_added_activity" => ["timeline:cmd_added"],
          "review_changed_protected_activity" => ["timeline:obs_1"],
          "review_removed_activity" => ["timeline:dl_removed"]
        },
        "review_timeline_keys" => "timeline:cmd_added|timeline:dl_removed|timeline:obs_1",
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "operator_authority" => "not_granted_by_summary",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "source_activity_count" => 0,
        "replacement_activity_count" => 0,
        "row_count" => 0,
        "added_count" => 0,
        "removed_count" => 0,
        "changed_count" => 0,
        "unchanged_count" => 0,
        "review_required_count" => 0,
        "review_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "generated by OrbitalDynamics.Timeline.diff_summary/3",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external timeline validation evidence",
        "checks diff-summary counts, review-row routing, and no-authority assumptions"
      ]
    },
    "fixture.artifact.timeline_publication_summary.v1" => %{
      "id" => "fixture.artifact.timeline_publication_summary.v1",
      "model_id" => "artifact.timeline_publication_summary.v1",
      "reference_case" => "checked-in timeline publication summary artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/timeline_publication_summary_v1.json",
        "contract" => "timeline_publication_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "timeline_publication_summary.v1",
        "model" => "artifact_only_timeline_publication_summary",
        "validation_level" => "artifact_contract",
        "source" => "operational_timeline_report.v1",
        "source_artifact_type" => "operational_timeline_report.v1",
        "source_artifact_id" => "timeline:published_plan:v2",
        "publication_id" =>
          "timeline_publication:7:timeline:published_plan:v2:timeline:published_plan:v1",
        "publication_sequence" => 7,
        "publication_status" => "published_with_downstream_invalidations",
        "downstream_invalidation_status" => "invalidated",
        "publication_authority" => "mission_operations",
        "supersedes_artifact_ids" => "timeline:published_plan:v1",
        "downstream_product_ids" => "cadence_import:plan:v1|operator_review:plan:v1",
        "invalidated_downstream_product_ids" => "cadence_import:plan:v1|operator_review:plan:v1",
        "downstream_invalidation_reason_counts" => %{
          "dependency_impact_review_required" => 2
        },
        "invalidated_downstream_product_ids_by_reason" => %{
          "dependency_impact_review_required" => [
            "cadence_import:plan:v1",
            "operator_review:plan:v1"
          ]
        },
        "dependency_impact_status" => "review_required",
        "dependency_impact_row_count" => 2,
        "impacted_source_activity_ids" => "health_gate",
        "impacted_source_timeline_ids" => "timeline:health_check:0.0",
        "dependent_activity_ids" => "cmd_main",
        "dependent_timeline_ids" => "timeline:command:20.0",
        "source_dependent_activity_ids" => "cmd_main",
        "source_dependent_timeline_ids" => "timeline:command:20.0",
        "replacement_dependent_activity_ids" => "cmd_main",
        "replacement_dependent_timeline_ids" => "timeline:command:20.0",
        "impacted_dependency_activity_ids" => "health_gate",
        "impacted_dependency_timeline_ids" => "",
        "impacted_exclusive_with_activity_ids" => "",
        "impacted_exclusive_with_timeline_ids" => "",
        "timeline_diff_row_count" => 3,
        "timeline_diff_changed_count" => 0,
        "timeline_diff_review_required_count" => 2,
        "changed_field_counts" => %{"timeline_presence" => 2},
        "changed_timeline_ids" => "",
        "review_timeline_ids" => "timeline:health_check:0.0|timeline:health_check:5.0",
        "timeline_ids_by_changed_field" => %{
          "timeline_presence" => ["timeline:health_check:0.0", "timeline:health_check:5.0"]
        },
        "source_timeline_diff_row_count" => 3,
        "source_timeline_diff_review_required_count" => 2,
        "source_timeline_diff_changed_count" => 0,
        "source_timeline_diff_changed_field_counts" => %{"timeline_presence" => 2},
        "source_timeline_diff_review_timeline_ids" =>
          "timeline:health_check:0.0|timeline:health_check:5.0",
        "source_timeline_diff_review_timeline_ids_by_required_operator_action" => %{
          "review_added_activity" => ["timeline:health_check:5.0"],
          "review_removed_activity" => ["timeline:health_check:0.0"]
        },
        "model_limit_count" => 4,
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "notification_delivery" => "host_system_owned",
        "assumption_publication_authority" => "mission_operations",
        "operator_authority" => "not_granted_by_summary",
        "no_schedule_mutation" => true,
        "no_command_execution" => true,
        "derived_identity_when_no_persistent_timeline_id" => true
      },
      "tolerances" => %{
        "publication_sequence" => 0,
        "dependency_impact_row_count" => 0,
        "timeline_diff_row_count" => 0,
        "timeline_diff_changed_count" => 0,
        "timeline_diff_review_required_count" => 0,
        "source_timeline_diff_row_count" => 0,
        "source_timeline_diff_review_required_count" => 0,
        "source_timeline_diff_changed_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "generated by OrbitalDynamics.Timeline.publication_summary/2",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external timeline publication evidence",
        "checks publication status, downstream invalidations, diff review routing, and no-authority assumptions"
      ]
    },
    "fixture.artifact.timeline_transition_application_summary.v1" => %{
      "id" => "fixture.artifact.timeline_transition_application_summary.v1",
      "model_id" => "artifact.timeline_transition_application_summary.v1",
      "reference_case" => "checked-in timeline transition application summary artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/timeline_transition_application_summary_v1.json",
        "contract" => "timeline_transition_application_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "timeline_transition_application_summary.v1",
        "model" => "artifact_only_timeline_transition_application_summary",
        "validation_level" => "artifact_contract",
        "source_artifact_type" => "timeline_transition_application_report.v1",
        "source" => "timeline.activities",
        "source_activity_count" => 2,
        "replacement_activity_count" => 3,
        "application_count" => 3,
        "selected_activity_count" => 2,
        "review_required_count" => 2,
        "preserved_source_count" => 1,
        "recorded_replacement_count" => 0,
        "withheld_review_count" => 1,
        "review_application_count" => 2,
        "application_status_counts" => %{
          "operator_review_required" => 1,
          "source_preserved_pending_review" => 1,
          "source_unchanged" => 1
        },
        "transition_decision_counts" => %{
          "none" => 1,
          "preserve_source" => 1,
          "review" => 1
        },
        "required_operator_action_counts" => %{
          "none" => 1,
          "review_added_activity" => 1,
          "review_changed_protected_activity" => 1
        },
        "status_transition_category_counts" => %{"status_added" => 1},
        "approval_transition_category_counts" => %{"approval_review_required" => 1},
        "row_derived_application_status_counts" => %{
          "operator_review_required" => 1,
          "source_preserved_pending_review" => 1
        },
        "row_derived_transition_decision_counts" => %{
          "preserve_source" => 1,
          "review" => 1
        },
        "row_derived_required_operator_action_counts" => %{
          "review_added_activity" => 1,
          "review_changed_protected_activity" => 1
        },
        "row_derived_status_transition_category_counts" => %{"status_added" => 1},
        "row_derived_approval_transition_category_counts" => %{
          "approval_review_required" => 1
        },
        "review_timeline_ids_by_required_operator_action" => %{
          "review_added_activity" => ["timeline:new_cmd"],
          "review_changed_protected_activity" => ["timeline:cmd_lock"]
        },
        "row_derived_review_timeline_ids_by_required_operator_action" => %{
          "review_added_activity" => ["timeline:new_cmd"],
          "review_changed_protected_activity" => ["timeline:cmd_lock"]
        },
        "selected_activity_keys" => "cmd_lock|obs_keep",
        "selected_timeline_keys" => "timeline:cmd_lock|timeline:obs_keep",
        "review_activity_keys" => "cmd_lock|new_cmd",
        "review_timeline_keys" => "timeline:cmd_lock|timeline:new_cmd",
        "withheld_review_timeline_keys" => "timeline:new_cmd",
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "operator_authority" => "not_granted_by_summary",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "source_activity_count" => 0,
        "replacement_activity_count" => 0,
        "application_count" => 0,
        "selected_activity_count" => 0,
        "review_required_count" => 0,
        "preserved_source_count" => 0,
        "recorded_replacement_count" => 0,
        "withheld_review_count" => 0,
        "review_application_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "generated by OrbitalDynamics.Timeline.transition_application_summary/3",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external transition validation evidence",
        "checks transition-application summary counts, review routing, and no-authority assumptions"
      ]
    },
    "fixture.artifact.timeline_transition_application_selected_integrity_summary.v1" => %{
      "id" => "fixture.artifact.timeline_transition_application_selected_integrity_summary.v1",
      "model_id" => "artifact.timeline_transition_application_summary.v1",
      "reference_case" => "checked-in transition application selected-integrity summary artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" =>
          "study_results/timeline_transition_application_selected_integrity_summary_v1.json",
        "contract" => "timeline_transition_application_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "timeline_transition_application_summary.v1",
        "model" => "artifact_only_timeline_transition_application_summary",
        "validation_level" => "artifact_contract",
        "source_artifact_type" => "timeline_transition_application_report.v1",
        "source" => "fixture.timeline.transition_application.selected_integrity",
        "source_activity_count" => 2,
        "replacement_activity_count" => 1,
        "application_count" => 2,
        "selected_activity_count" => 1,
        "review_required_count" => 2,
        "preserved_source_count" => 1,
        "recorded_replacement_count" => 0,
        "withheld_review_count" => 1,
        "review_application_count" => 2,
        "selected_timeline_integrity_issue_count" => 1,
        "selected_timeline_integrity_review_count" => 1,
        "selected_timeline_integrity_issue_type_counts" => %{
          "missing_dependency_activity" => 1
        },
        "row_derived_selected_timeline_integrity_issue_type_counts" => %{
          "missing_dependency_activity" => 1
        },
        "row_derived_selected_required_operator_action_counts" => %{
          "review_changed_protected_activity" => 1
        },
        "row_derived_selected_review_timeline_ids_by_required_operator_action" => %{
          "review_changed_protected_activity" => ["timeline:cmd_lock"]
        },
        "row_derived_selected_missing_dependency_activity_keys" => "cmd_prereq",
        "application_status_counts" => %{
          "operator_review_required" => 1,
          "source_preserved_pending_review" => 1
        },
        "transition_decision_counts" => %{"preserve_source" => 1, "review" => 1},
        "required_operator_action_counts" => %{
          "review_changed_protected_activity" => 1,
          "review_removed_activity" => 1
        },
        "status_transition_category_counts" => %{"status_removed" => 1},
        "approval_transition_category_counts" => %{"approval_removed" => 1},
        "row_derived_application_status_counts" => %{
          "operator_review_required" => 1,
          "source_preserved_pending_review" => 1
        },
        "row_derived_transition_decision_counts" => %{
          "preserve_source" => 1,
          "review" => 1
        },
        "row_derived_required_operator_action_counts" => %{
          "review_changed_protected_activity" => 1,
          "review_removed_activity" => 1
        },
        "row_derived_status_transition_category_counts" => %{"status_removed" => 1},
        "row_derived_approval_transition_category_counts" => %{"approval_removed" => 1},
        "review_timeline_ids_by_required_operator_action" => %{
          "review_changed_protected_activity" => ["timeline:cmd_lock"],
          "review_removed_activity" => ["timeline:cmd_prereq"]
        },
        "row_derived_review_timeline_ids_by_required_operator_action" => %{
          "review_changed_protected_activity" => ["timeline:cmd_lock"],
          "review_removed_activity" => ["timeline:cmd_prereq"]
        },
        "selected_activity_keys" => "cmd_lock",
        "selected_timeline_keys" => "timeline:cmd_lock",
        "review_activity_keys" => "cmd_lock|cmd_prereq",
        "review_timeline_keys" => "timeline:cmd_lock|timeline:cmd_prereq",
        "withheld_review_timeline_keys" => "timeline:cmd_prereq",
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "operator_authority" => "not_granted_by_summary",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "source_activity_count" => 0,
        "replacement_activity_count" => 0,
        "application_count" => 0,
        "selected_activity_count" => 0,
        "review_required_count" => 0,
        "preserved_source_count" => 0,
        "recorded_replacement_count" => 0,
        "withheld_review_count" => 0,
        "review_application_count" => 0,
        "selected_timeline_integrity_issue_count" => 0,
        "selected_timeline_integrity_review_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "generated by OrbitalDynamics.timeline_transition_application_summary/3",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external transition validation evidence",
        "checks compact selected-integrity summary routing and no-authority assumptions"
      ]
    },
    "fixture.artifact.operational_timeline_report.v1" => %{
      "id" => "fixture.artifact.operational_timeline_report.v1",
      "model_id" => "artifact.operational_timeline_report.v1",
      "reference_case" => "checked-in operational timeline artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/operational_timeline_report_v1.json",
        "contract" => "operational_timeline_report.v1"
      },
      "expected" => %{
        "schema_contract" => "operational_timeline_report.v1",
        "model" => "selected_activity_operational_context_summary",
        "source" => "mission_plan.activities",
        "activity_count" => 3,
        "row_count" => 3,
        "contact_count" => 2,
        "command_count" => 2,
        "approved_count" => 2,
        "executed_count" => 0,
        "locked_count" => 0,
        "terminal_exception_count" => 0,
        "dependency_count" => 1,
        "dependency_issue_count" => 2,
        "exclusivity_count" => 1,
        "exclusivity_issue_count" => 3,
        "timeline_integrity_issue_count" => 5,
        "timeline_integrity_review_count" => 2,
        "duplicate_timeline_identity_count" => 0,
        "duplicate_timeline_identity_activity_count" => 0,
        "source_window_lineage_count" => 2,
        "operational_kind_counts" => %{"command" => 1, "contact" => 1, "health_check" => 1},
        "row_derived_operational_kind_counts" => %{
          "command" => 1,
          "contact" => 1,
          "health_check" => 1
        },
        "activity_status_counts" => %{"planned" => 3},
        "row_derived_activity_status_counts" => %{"planned" => 3},
        "approval_status_counts" => %{"approved" => 2, "pending" => 1},
        "row_derived_approval_status_counts" => %{"approved" => 2, "pending" => 1},
        "cadence_import_status_counts" => %{
          "missing" => 1,
          "not_applicable" => 1,
          "present" => 1
        },
        "row_derived_cadence_import_status_counts" => %{
          "missing" => 1,
          "not_applicable" => 1,
          "present" => 1
        },
        "required_operator_action_counts" => %{
          "monitor_activity" => 1,
          "review_timeline_integrity" => 2
        },
        "row_derived_required_operator_action_counts" => %{
          "monitor_activity" => 1,
          "review_timeline_integrity" => 2
        },
        "timeline_integrity_issue_type_counts" => %{
          "dependency_order_violation" => 1,
          "exclusivity_group_overlap" => 2,
          "exclusivity_overlap" => 1,
          "missing_dependency_activity" => 1
        },
        "row_derived_timeline_integrity_issue_type_counts" => %{
          "dependency_order_violation" => 1,
          "exclusivity_group_overlap" => 2,
          "exclusivity_overlap" => 1,
          "missing_dependency_activity" => 1
        },
        "timeline_row_ids_by_required_operator_action" => %{
          "monitor_activity" => ["timeline_row:1:health_1"],
          "review_timeline_integrity" => ["timeline_row:2:cmd_1", "timeline_row:3:dl_1"]
        },
        "row_derived_timeline_row_ids_by_required_operator_action" => %{
          "monitor_activity" => ["timeline_row:1:health_1"],
          "review_timeline_integrity" => ["timeline_row:2:cmd_1", "timeline_row:3:dl_1"]
        },
        "timeline_row_ids_by_integrity_status" => %{
          "none" => ["timeline_row:1:health_1"],
          "review_required" => ["timeline_row:2:cmd_1", "timeline_row:3:dl_1"]
        },
        "row_derived_timeline_row_ids_by_integrity_status" => %{
          "none" => ["timeline_row:1:health_1"],
          "review_required" => ["timeline_row:2:cmd_1", "timeline_row:3:dl_1"]
        },
        "execution_boundary" => "planned_not_commanded",
        "missing_dependency_validation" => "enabled",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "activity_count" => 0,
        "row_count" => 0,
        "contact_count" => 0,
        "command_count" => 0,
        "approved_count" => 0,
        "executed_count" => 0,
        "locked_count" => 0,
        "terminal_exception_count" => 0,
        "dependency_count" => 0,
        "dependency_issue_count" => 0,
        "exclusivity_count" => 0,
        "exclusivity_issue_count" => 0,
        "timeline_integrity_issue_count" => 0,
        "timeline_integrity_review_count" => 0,
        "duplicate_timeline_identity_count" => 0,
        "duplicate_timeline_identity_activity_count" => 0,
        "source_window_lineage_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks operational timeline counts, integrity review routing, and no-command boundary only"
      ]
    },
    "fixture.artifact.timeline_transition_application_report.v1" => %{
      "id" => "fixture.artifact.timeline_transition_application_report.v1",
      "model_id" => "artifact.timeline_transition_application_report.v1",
      "reference_case" => "checked-in timeline transition application artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/timeline_transition_application_report_v1.json",
        "contract" => "timeline_transition_application_report.v1"
      },
      "expected" => %{
        "schema_contract" => "timeline_transition_application_report.v1",
        "model" => "artifact_only_timeline_transition_application",
        "source" => "fixture.timeline.transition_application",
        "source_activity_count" => 3,
        "replacement_activity_count" => 3,
        "application_count" => 4,
        "selected_activity_count" => 2,
        "preserved_source_count" => 1,
        "recorded_replacement_count" => 0,
        "review_required_count" => 3,
        "withheld_review_count" => 2,
        "selected_timeline_integrity_issue_count" => 0,
        "selected_timeline_integrity_review_count" => 0,
        "application_status_counts" => %{
          "operator_review_required" => 2,
          "source_preserved_pending_review" => 1,
          "source_unchanged" => 1
        },
        "row_derived_application_status_counts" => %{
          "operator_review_required" => 2,
          "source_preserved_pending_review" => 1,
          "source_unchanged" => 1
        },
        "transition_decision_counts" => %{"none" => 1, "preserve_source" => 1, "review" => 2},
        "row_derived_transition_decision_counts" => %{
          "none" => 1,
          "preserve_source" => 1,
          "review" => 2
        },
        "status_transition_counts" => %{"added" => 1, "removed" => 1},
        "row_derived_status_transition_counts" => %{"added" => 1, "removed" => 1},
        "status_transition_category_counts" => %{"status_added" => 1, "status_removed" => 1},
        "row_derived_status_transition_category_counts" => %{
          "status_added" => 1,
          "status_removed" => 1
        },
        "approval_transition_counts" => %{"added" => 1, "removed" => 1},
        "row_derived_approval_transition_counts" => %{"added" => 1, "removed" => 1},
        "approval_transition_category_counts" => %{
          "approval_removed" => 1,
          "approval_review_required" => 1
        },
        "row_derived_approval_transition_category_counts" => %{
          "approval_removed" => 1,
          "approval_review_required" => 1
        },
        "required_operator_action_counts" => %{
          "none" => 1,
          "review_added_activity" => 1,
          "review_changed_protected_activity" => 1,
          "review_removed_activity" => 1
        },
        "row_derived_required_operator_action_counts" => %{
          "none" => 1,
          "review_added_activity" => 1,
          "review_changed_protected_activity" => 1,
          "review_removed_activity" => 1
        },
        "application_ids_by_status" => %{
          "operator_review_required" => [
            "timeline_diff:timeline:new_cmd",
            "timeline_diff:timeline:old_contact"
          ],
          "source_preserved_pending_review" => ["timeline_diff:timeline:cmd_lock"],
          "source_unchanged" => ["timeline_diff:timeline:obs_keep"]
        },
        "row_derived_application_ids_by_status" => %{
          "operator_review_required" => [
            "timeline_diff:timeline:new_cmd",
            "timeline_diff:timeline:old_contact"
          ],
          "source_preserved_pending_review" => ["timeline_diff:timeline:cmd_lock"],
          "source_unchanged" => ["timeline_diff:timeline:obs_keep"]
        },
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "review_gate" =>
          "review-required transitions withhold replacement selection until an operator decision",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "source_activity_count" => 0,
        "replacement_activity_count" => 0,
        "application_count" => 0,
        "selected_activity_count" => 0,
        "preserved_source_count" => 0,
        "recorded_replacement_count" => 0,
        "review_required_count" => 0,
        "withheld_review_count" => 0,
        "selected_timeline_integrity_issue_count" => 0,
        "selected_timeline_integrity_review_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external timeline mutation validation",
        "checks transition application counts, review-gate routing, selected-activity counts, and no-schedule-mutation boundary only"
      ]
    },
    "fixture.artifact.timeline_transition_application_selected_integrity.v1" => %{
      "id" => "fixture.artifact.timeline_transition_application_selected_integrity.v1",
      "model_id" => "artifact.timeline_transition_application_report.v1",
      "reference_case" => "checked-in transition application selected-integrity review artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" =>
          "study_results/timeline_transition_application_selected_integrity_v1.json",
        "contract" => "timeline_transition_application_report.v1"
      },
      "expected" => %{
        "schema_contract" => "timeline_transition_application_report.v1",
        "model" => "artifact_only_timeline_transition_application",
        "source" => "fixture.timeline.transition_application.selected_integrity",
        "source_activity_count" => 2,
        "replacement_activity_count" => 1,
        "application_count" => 2,
        "selected_activity_count" => 1,
        "preserved_source_count" => 1,
        "recorded_replacement_count" => 0,
        "review_required_count" => 2,
        "withheld_review_count" => 1,
        "selected_timeline_integrity_issue_count" => 1,
        "selected_timeline_integrity_review_count" => 1,
        "selected_timeline_integrity_issue_type_counts" => %{
          "missing_dependency_activity" => 1
        },
        "row_derived_selected_timeline_integrity_issue_type_counts" => %{
          "missing_dependency_activity" => 1
        },
        "row_derived_selected_required_operator_action_counts" => %{
          "review_changed_protected_activity" => 1
        },
        "row_derived_selected_application_ids_by_required_operator_action" => %{
          "review_changed_protected_activity" => ["timeline_diff:timeline:cmd_lock"]
        },
        "row_derived_selected_missing_dependency_activity_keys" => "cmd_prereq",
        "application_status_counts" => %{
          "operator_review_required" => 1,
          "source_preserved_pending_review" => 1
        },
        "row_derived_application_status_counts" => %{
          "operator_review_required" => 1,
          "source_preserved_pending_review" => 1
        },
        "required_operator_action_counts" => %{
          "review_changed_protected_activity" => 1,
          "review_removed_activity" => 1
        },
        "row_derived_required_operator_action_counts" => %{
          "review_changed_protected_activity" => 1,
          "review_removed_activity" => 1
        },
        "application_ids_by_status" => %{
          "operator_review_required" => ["timeline_diff:timeline:cmd_prereq"],
          "source_preserved_pending_review" => ["timeline_diff:timeline:cmd_lock"]
        },
        "row_derived_application_ids_by_status" => %{
          "operator_review_required" => ["timeline_diff:timeline:cmd_prereq"],
          "source_preserved_pending_review" => ["timeline_diff:timeline:cmd_lock"]
        },
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "review_gate" =>
          "review-required transitions withhold replacement selection until an operator decision",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "source_activity_count" => 0,
        "replacement_activity_count" => 0,
        "application_count" => 0,
        "selected_activity_count" => 0,
        "preserved_source_count" => 0,
        "recorded_replacement_count" => 0,
        "review_required_count" => 0,
        "withheld_review_count" => 0,
        "selected_timeline_integrity_issue_count" => 0,
        "selected_timeline_integrity_review_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "generated by OrbitalDynamics.timeline_transition_application_report/3",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external timeline mutation validation",
        "checks selected-activity integrity review routing and no-schedule-mutation boundary only"
      ]
    },
    "fixture.artifact.timeline_feedback_report.v1" => %{
      "id" => "fixture.artifact.timeline_feedback_report.v1",
      "model_id" => "artifact.timeline_feedback_report.v1",
      "reference_case" => "checked-in timeline feedback artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/timeline_feedback_report_v1.json",
        "contract" => "timeline_feedback_report.v1"
      },
      "expected" => %{
        "schema_contract" => "timeline_feedback_report.v1",
        "model" => "planned_vs_realized_activity_reconciliation",
        "planned_count" => 4,
        "realized_count" => 4,
        "row_count" => 4,
        "operational_feedback_count" => 16,
        "operational_feedback_excluded_count" => 1,
        "duplicate_realized_feedback_count" => 0,
        "ambiguous_timeline_feedback_count" => 0,
        "ambiguous_timeline_match_count" => 0,
        "duplicate_realized_match_count" => 0,
        "execution_uncertainty_declared_count" => 0,
        "execution_uncertainty_missing_count" => 1,
        "operator_review_count" => 4,
        "cadence_import_manifest_row_count" => 4,
        "status_counts" => %{"matched" => 4},
        "row_derived_status_counts" => %{"matched" => 4},
        "feedback_kind_counts" => %{
          "command" => 1,
          "contact" => 1,
          "maneuver" => 1,
          "observation" => 1
        },
        "row_derived_feedback_kind_counts" => %{
          "command" => 1,
          "contact" => 1,
          "maneuver" => 1,
          "observation" => 1
        },
        "match_strategy_counts" => %{"planned_activity_id" => 4},
        "row_derived_match_strategy_counts" => %{"planned_activity_id" => 4},
        "planned_protection_decision_counts" => %{"preserve" => 4},
        "row_derived_planned_protection_decision_counts" => %{"preserve" => 4},
        "cadence_import_status_counts" => %{
          "missing" => 1,
          "not_applicable" => 2,
          "present" => 1
        },
        "row_derived_cadence_import_status_counts" => %{
          "missing" => 1,
          "not_applicable" => 2,
          "present" => 1
        },
        "realized_status_counts" => %{"completed" => 3, "partial" => 1},
        "row_derived_realized_status_counts" => %{"completed" => 3, "partial" => 1},
        "status_transition_category_counts" => %{"execution_recorded" => 4},
        "row_derived_status_transition_category_counts" => %{"execution_recorded" => 4},
        "activity_ids_by_feedback_kind" => %{
          "command" => ["cmd_repoint"],
          "contact" => ["downlink_equator"],
          "maneuver" => ["burn_cleanup"],
          "observation" => ["obs_feedback"]
        },
        "activity_ids_by_status" => %{
          "matched" => ["burn_cleanup", "cmd_repoint", "downlink_equator", "obs_feedback"]
        },
        "row_derived_activity_ids_by_feedback_kind" => %{
          "command" => ["cmd_repoint"],
          "contact" => ["downlink_equator"],
          "maneuver" => ["burn_cleanup"],
          "observation" => ["obs_feedback"]
        },
        "row_derived_activity_ids_by_status" => %{
          "matched" => ["burn_cleanup", "cmd_repoint", "downlink_equator", "obs_feedback"]
        },
        "boundary" => "report_only_no_schedule_mutation",
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "planned_count" => 0,
        "realized_count" => 0,
        "row_count" => 0,
        "operational_feedback_count" => 0,
        "operational_feedback_excluded_count" => 0,
        "duplicate_realized_feedback_count" => 0,
        "ambiguous_timeline_feedback_count" => 0,
        "ambiguous_timeline_match_count" => 0,
        "duplicate_realized_match_count" => 0,
        "execution_uncertainty_declared_count" => 0,
        "execution_uncertainty_missing_count" => 0,
        "operator_review_count" => 0,
        "cadence_import_manifest_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks timeline feedback reconciliation counts, nested handoff counts, feedback routing, and no-schedule-mutation boundary only"
      ]
    },
    "fixture.artifact.contact_allocation_report.v1" => %{
      "id" => "fixture.artifact.contact_allocation_report.v1",
      "model_id" => "artifact.contact_allocation_report.v1",
      "reference_case" => "checked-in contact allocation artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/contact_allocation_report_v1.json",
        "contract" => "contact_allocation_report.v1"
      },
      "expected" => %{
        "schema_contract" => "contact_allocation_report.v1",
        "model" => "deterministic_station_contact_allocation",
        "input_contact_count" => 5,
        "row_derived_input_contact_count" => 5,
        "row_count" => 5,
        "allocated_contact_count" => 1,
        "row_derived_allocated_contact_count" => 1,
        "returned_allocated_contact_count" => 1,
        "row_derived_returned_allocated_contact_count" => 1,
        "deferred_contact_count" => 1,
        "row_derived_deferred_contact_count" => 1,
        "blocked_contact_count" => 3,
        "row_derived_blocked_contact_count" => 3,
        "policy_blocked_allocated_contact_count" => 0,
        "row_derived_policy_blocked_allocated_contact_count" => 0,
        "invalid_contact_input_count" => 0,
        "row_derived_invalid_contact_input_count" => 0,
        "status_blocked_contact_count" => 0,
        "row_derived_status_blocked_contact_count" => 0,
        "resource_blocked_contact_count" => 1,
        "row_derived_resource_blocked_contact_count" => 1,
        "resource_blocking_dimension_counts" => %{"antenna" => 1},
        "row_derived_resource_blocking_dimension_counts" => %{"antenna" => 1},
        "resource_blocked_contact_ids_by_blocking_dimension" => %{
          "antenna" => ["dl_resource_blocked"]
        },
        "row_derived_resource_blocked_contact_ids_by_blocking_dimension" => %{
          "antenna" => ["dl_resource_blocked"]
        },
        "resource_blocked_contact_ids_by_spacecraft_id" => %{
          "sat_low_resource" => ["dl_resource_blocked"]
        },
        "row_derived_resource_blocked_contact_ids_by_spacecraft_id" => %{
          "sat_low_resource" => ["dl_resource_blocked"]
        },
        "review_row_count" => 5,
        "allocation_status_counts" => %{"allocated" => 1, "blocked" => 3, "deferred" => 1},
        "row_derived_allocation_status_counts" => %{
          "allocated" => 1,
          "blocked" => 3,
          "deferred" => 1
        },
        "effective_allocation_status_counts" => %{
          "allocated" => 1,
          "blocked" => 3,
          "deferred" => 1
        },
        "row_derived_effective_allocation_status_counts" => %{
          "allocated" => 1,
          "blocked" => 3,
          "deferred" => 1
        },
        "allocation_reason_counts" => %{
          "antenna_unavailable" => 1,
          "ground_station_reserved" => 1,
          "ground_station_unavailable" => 1,
          "same_station_contention" => 1,
          "selected_by_contention_resolution" => 1
        },
        "row_derived_allocation_reason_counts" => %{
          "antenna_unavailable" => 1,
          "ground_station_reserved" => 1,
          "ground_station_unavailable" => 1,
          "same_station_contention" => 1,
          "selected_by_contention_resolution" => 1
        },
        "contact_ids_by_effective_allocation_status" => %{
          "allocated" => ["dl_1"],
          "blocked" => ["cmd_unavailable", "dl_3", "dl_resource_blocked"],
          "deferred" => ["dl_2"]
        },
        "row_derived_station_reservation_id_counts" => %{"reservation_1" => 1},
        "row_derived_station_reserved_by_counts" => %{"network_partner" => 1},
        "row_derived_station_reservation_status_counts" => %{"reserved" => 1},
        "contact_ids_by_station_reservation_match_status" => %{
          "overlap" => ["dl_3"],
          "unknown" => ["cmd_unavailable", "dl_1", "dl_2", "dl_resource_blocked"]
        },
        "reported_station_pressure_contact_ids_by_ground_station_id" => %{
          "equator_prime" => ["cmd_unavailable", "dl_3"]
        },
        "reported_station_pressure_contact_ids_by_availability" => %{
          "reserved" => ["dl_3"],
          "unavailable" => ["cmd_unavailable"]
        },
        "reported_station_pressure_contact_ids_by_precedence_availability" => %{
          "reserved" => ["dl_3"],
          "unavailable" => ["cmd_unavailable"]
        },
        "reported_station_pressure_contact_ids_by_precedence_rank" => %{
          "0" => ["cmd_unavailable"],
          "1" => ["dl_3"]
        },
        "station_reservation_match_status_counts" => %{"overlap" => 1},
        "station_calendar_trust_boundary_status_counts" => %{"missing" => 2},
        "calendar_entry_trust_boundary_status_counts" => %{"missing" => 2},
        "model_limit_count" => 8
      },
      "tolerances" => %{
        "input_contact_count" => 0,
        "row_derived_input_contact_count" => 0,
        "row_count" => 0,
        "allocated_contact_count" => 0,
        "row_derived_allocated_contact_count" => 0,
        "returned_allocated_contact_count" => 0,
        "row_derived_returned_allocated_contact_count" => 0,
        "deferred_contact_count" => 0,
        "row_derived_deferred_contact_count" => 0,
        "blocked_contact_count" => 0,
        "row_derived_blocked_contact_count" => 0,
        "policy_blocked_allocated_contact_count" => 0,
        "row_derived_policy_blocked_allocated_contact_count" => 0,
        "invalid_contact_input_count" => 0,
        "row_derived_invalid_contact_input_count" => 0,
        "status_blocked_contact_count" => 0,
        "row_derived_status_blocked_contact_count" => 0,
        "resource_blocked_contact_count" => 0,
        "row_derived_resource_blocked_contact_count" => 0,
        "review_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external allocation validation",
        "checks contact allocation counts, routing maps, and model-limit boundary only"
      ]
    },
    "fixture.artifact.contact_allocation_reservation_conflict_summary.v1" => %{
      "id" => "fixture.artifact.contact_allocation_reservation_conflict_summary.v1",
      "model_id" => "artifact.contact_allocation_reservation_conflict_summary.v1",
      "reference_case" => "checked-in contact allocation reservation conflict summary",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" =>
          "study_results/contact_allocation_reservation_conflict_summary_v1.json",
        "contract" => "contact_allocation_reservation_conflict_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "contact_allocation_reservation_conflict_summary.v1",
        "model" => "artifact_only_contact_allocation_reservation_conflict_summary",
        "source_artifact_type" => "contact_allocation_report.v1",
        "source" => "validation.contact_allocation_reservation_conflict_summary",
        "input_contact_count" => 2,
        "row_derived_input_contact_count" => 2,
        "station_reservation_contact_count" => 2,
        "row_derived_station_reservation_contact_count" => 2,
        "reservation_conflict_contact_count" => 1,
        "row_derived_reservation_conflict_contact_count" => 1,
        "reservation_review_contact_count" => 1,
        "row_derived_reservation_review_contact_count" => 1,
        "station_reservation_match_status_counts" => %{"matched" => 1, "overlap" => 1},
        "row_derived_station_reservation_match_status_counts" => %{
          "matched" => 1,
          "overlap" => 1
        },
        "reservation_conflict_match_status_counts" => %{"overlap" => 1},
        "row_derived_reservation_conflict_match_status_counts" => %{"overlap" => 1},
        "station_reservation_status_counts" => %{"confirmed" => 2},
        "row_derived_station_reservation_status_counts" => %{"confirmed" => 2},
        "station_reserved_by_counts" => %{"ops_team_b" => 2},
        "row_derived_station_reserved_by_counts" => %{"ops_team_b" => 2},
        "station_reservation_keys" => "reservation_1",
        "row_derived_station_reservation_keys" => "reservation_1",
        "reservation_conflict_contact_keys" => "dl_reserved_intruder",
        "row_derived_reservation_conflict_contact_keys" => "dl_reserved_intruder",
        "reservation_review_contact_keys" => "dl_reserved_intruder",
        "row_derived_reservation_review_contact_keys" => "dl_reserved_intruder",
        "station_reservation_contact_ids_by_match_status" => %{
          "matched" => ["dl_reserved_owner"],
          "overlap" => ["dl_reserved_intruder"]
        },
        "row_derived_station_reservation_contact_ids_by_match_status" => %{
          "matched" => ["dl_reserved_owner"],
          "overlap" => ["dl_reserved_intruder"]
        },
        "reservation_conflict_contact_ids_by_match_status" => %{
          "overlap" => ["dl_reserved_intruder"]
        },
        "row_derived_reservation_conflict_contact_ids_by_match_status" => %{
          "overlap" => ["dl_reserved_intruder"]
        },
        "reservation_conflict_contact_ids_by_direction_and_ground_station_id" => %{
          "downlink" => %{"equator_prime" => ["dl_reserved_intruder"]}
        },
        "row_derived_reservation_conflict_contact_ids_by_direction_and_ground_station_id" => %{
          "downlink" => %{"equator_prime" => ["dl_reserved_intruder"]}
        },
        "station_reservation_ids_by_expiration_status" => %{
          "expired" => ["reservation_1"]
        },
        "model_limit_count" => 8
      },
      "tolerances" => %{
        "input_contact_count" => 0,
        "row_derived_input_contact_count" => 0,
        "station_reservation_contact_count" => 0,
        "row_derived_station_reservation_contact_count" => 0,
        "reservation_conflict_contact_count" => 0,
        "row_derived_reservation_conflict_contact_count" => 0,
        "reservation_review_contact_count" => 0,
        "row_derived_reservation_review_contact_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external reservation validation",
        "checks reservation conflict counts, routing maps, and model-limit boundary only"
      ]
    },
    "fixture.artifact.contact_allocation_station_pressure_summary.v1" => %{
      "id" => "fixture.artifact.contact_allocation_station_pressure_summary.v1",
      "model_id" => "artifact.contact_allocation_station_pressure_summary.v1",
      "reference_case" => "checked-in contact allocation station pressure summary",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/contact_allocation_station_pressure_summary_v1.json",
        "contract" => "contact_allocation_station_pressure_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "contact_allocation_station_pressure_summary.v1",
        "model" => "artifact_only_contact_allocation_station_pressure_summary",
        "source_artifact_type" => "contact_allocation_report.v1",
        "source" => "validation.contact_allocation_station_pressure_summary",
        "input_contact_count" => 3,
        "row_derived_input_contact_count" => 3,
        "station_pressure_contact_count" => 1,
        "row_derived_station_pressure_contact_count" => 1,
        "station_pressure_review_contact_count" => 1,
        "row_derived_station_pressure_review_contact_count" => 1,
        "station_pressure_contact_keys" => "dl_3",
        "row_derived_station_pressure_contact_keys" => "dl_3",
        "station_pressure_review_contact_keys" => "dl_3",
        "row_derived_station_pressure_review_contact_keys" => "dl_3",
        "station_pressure_contact_ids_by_ground_station_id" => %{
          "equator_prime" => ["dl_3"]
        },
        "row_derived_station_pressure_contact_ids_by_ground_station_id" => %{
          "equator_prime" => ["dl_3"]
        },
        "station_pressure_contact_ids_by_availability" => %{"reserved" => ["dl_3"]},
        "row_derived_station_pressure_contact_ids_by_availability" => %{
          "reserved" => ["dl_3"]
        },
        "station_pressure_contact_ids_by_status" => %{"reserved" => ["dl_3"]},
        "row_derived_station_pressure_contact_ids_by_status" => %{
          "reserved" => ["dl_3"]
        },
        "station_pressure_contact_counts_by_status" => %{"reserved" => 1},
        "row_derived_station_pressure_contact_counts_by_status" => %{"reserved" => 1},
        "station_pressure_contact_ids_by_precedence_availability" => %{
          "reserved" => ["dl_3"]
        },
        "row_derived_station_pressure_contact_ids_by_precedence_availability" => %{
          "reserved" => ["dl_3"]
        },
        "station_pressure_contact_ids_by_precedence_rank" => %{"1" => ["dl_3"]},
        "row_derived_station_pressure_contact_ids_by_precedence_rank" => %{
          "1" => ["dl_3"]
        },
        "station_pressure_contact_ids_by_direction_and_ground_station_id" => %{
          "downlink" => %{"equator_prime" => ["dl_3"]}
        },
        "row_derived_station_pressure_contact_ids_by_direction_and_ground_station_id" => %{
          "downlink" => %{"equator_prime" => ["dl_3"]}
        },
        "model_limit_count" => 8
      },
      "tolerances" => %{
        "input_contact_count" => 0,
        "row_derived_input_contact_count" => 0,
        "station_pressure_contact_count" => 0,
        "row_derived_station_pressure_contact_count" => 0,
        "station_pressure_review_contact_count" => 0,
        "row_derived_station_pressure_review_contact_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external station validation",
        "checks station pressure counts, routing maps, and model-limit boundary only"
      ]
    },
    "fixture.artifact.contact_allocation_capacity_pack_summary.v1" => %{
      "id" => "fixture.artifact.contact_allocation_capacity_pack_summary.v1",
      "model_id" => "artifact.contact_allocation_capacity_pack_summary.v1",
      "reference_case" => "checked-in contact allocation capacity pack summary",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/contact_allocation_capacity_pack_summary_v1.json",
        "contract" => "contact_allocation_capacity_pack_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "contact_allocation_capacity_pack_summary.v1",
        "model" => "artifact_only_contact_allocation_capacity_pack_summary",
        "source_artifact_type" => "contact_allocation_report.v1",
        "source" => "validation.contact_allocation_capacity_pack_summary",
        "input_contact_count" => 3,
        "row_derived_input_contact_count" => 3,
        "capacity_pack_contact_count" => 3,
        "row_derived_capacity_pack_contact_count" => 3,
        "reduced_capacity_pack_group_count" => 1,
        "row_derived_reduced_capacity_pack_group_count" => 1,
        "capacity_pack_status_counts" => %{
          "deferred_by_reduced_station_capacity_pack" => 1,
          "selected_by_contention_resolution" => 1,
          "selected_by_reduced_station_capacity_pack" => 1
        },
        "row_derived_capacity_pack_status_counts" => %{
          "deferred_by_reduced_station_capacity_pack" => 1,
          "selected_by_contention_resolution" => 1,
          "selected_by_reduced_station_capacity_pack" => 1
        },
        "reduced_capacity_pack_status_counts" => %{"capacity_limited" => 1},
        "row_derived_reduced_capacity_pack_status_counts" => %{"capacity_limited" => 1},
        "capacity_pack_contact_ids_by_status" => %{
          "deferred_by_reduced_station_capacity_pack" => ["dl_capacity_overflow"],
          "selected_by_contention_resolution" => ["dl_capacity_primary"],
          "selected_by_reduced_station_capacity_pack" => ["dl_capacity_secondary"]
        },
        "row_derived_capacity_pack_contact_ids_by_status" => %{
          "deferred_by_reduced_station_capacity_pack" => ["dl_capacity_overflow"],
          "selected_by_contention_resolution" => ["dl_capacity_primary"],
          "selected_by_reduced_station_capacity_pack" => ["dl_capacity_secondary"]
        },
        "reduced_capacity_packed_contact_keys" => "dl_capacity_secondary",
        "row_derived_reduced_capacity_packed_contact_keys" => "dl_capacity_secondary",
        "reduced_capacity_deferred_contact_keys" => "dl_capacity_overflow",
        "row_derived_reduced_capacity_deferred_contact_keys" => "dl_capacity_overflow",
        "row_derived_reduced_capacity_pack_group_ids_by_status" => %{
          "capacity_limited" => ["capacity_pack:equator_prime:downlink:100_160"]
        },
        "row_derived_capacity_pack_contact_ids_by_direction_and_ground_station_id" => %{
          "downlink" => %{
            "equator_prime" => [
              "dl_capacity_overflow",
              "dl_capacity_primary",
              "dl_capacity_secondary"
            ]
          }
        },
        "model_limit_count" => 8
      },
      "tolerances" => %{
        "input_contact_count" => 0,
        "row_derived_input_contact_count" => 0,
        "capacity_pack_contact_count" => 0,
        "row_derived_capacity_pack_contact_count" => 0,
        "reduced_capacity_pack_group_count" => 0,
        "row_derived_reduced_capacity_pack_group_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external capacity validation",
        "checks capacity-pack counts, routing maps, and model-limit boundary only"
      ]
    },
    "fixture.artifact.contact_allocation_summary.v1" => %{
      "id" => "fixture.artifact.contact_allocation_summary.v1",
      "model_id" => "artifact.contact_allocation_summary.v1",
      "reference_case" => "checked-in contact allocation summary",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/contact_allocation_summary_v1.json",
        "contract" => "contact_allocation_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "contact_allocation_summary.v1",
        "model" => "artifact_only_contact_allocation_summary",
        "source_artifact_type" => "contact_allocation_report.v1",
        "source" => "validation.contact_allocation_summary",
        "input_contact_count" => 3,
        "row_derived_input_contact_count" => 3,
        "allocated_contact_count" => 1,
        "row_derived_allocated_contact_count" => 1,
        "deferred_contact_count" => 1,
        "row_derived_deferred_contact_count" => 1,
        "blocked_contact_count" => 1,
        "row_derived_blocked_contact_count" => 1,
        "review_row_count" => 3,
        "row_derived_review_row_count" => 3,
        "allocation_status_counts" => %{"allocated" => 1, "blocked" => 1, "deferred" => 1},
        "row_derived_allocation_status_counts" => %{
          "allocated" => 1,
          "blocked" => 1,
          "deferred" => 1
        },
        "effective_allocation_status_counts" => %{
          "allocated" => 1,
          "blocked" => 1,
          "deferred" => 1
        },
        "row_derived_effective_allocation_status_counts" => %{
          "allocated" => 1,
          "blocked" => 1,
          "deferred" => 1
        },
        "allocation_reason_counts" => %{
          "ground_station_reserved" => 1,
          "same_station_contention" => 1,
          "selected_by_contention_resolution" => 1
        },
        "row_derived_allocation_reason_counts" => %{
          "ground_station_reserved" => 1,
          "same_station_contention" => 1,
          "selected_by_contention_resolution" => 1
        },
        "row_derived_contact_ids_by_effective_allocation_status" => %{
          "allocated" => ["dl_1"],
          "blocked" => ["dl_3"],
          "deferred" => ["dl_2"]
        },
        "station_pressure_contact_ids_by_ground_station_id" => %{
          "equator_prime" => ["dl_3"]
        },
        "row_derived_station_pressure_contact_ids_by_ground_station_id" => %{
          "equator_prime" => ["dl_3"]
        },
        "station_pressure_contact_ids_by_availability" => %{"reserved" => ["dl_3"]},
        "row_derived_station_pressure_contact_ids_by_availability" => %{
          "reserved" => ["dl_3"]
        },
        "station_pressure_contact_ids_by_status" => %{"reserved" => ["dl_3"]},
        "row_derived_station_pressure_contact_ids_by_status" => %{
          "reserved" => ["dl_3"]
        },
        "station_pressure_contact_counts_by_status" => %{"reserved" => 1},
        "row_derived_station_pressure_contact_counts_by_status" => %{"reserved" => 1},
        "model_limit_count" => 8
      },
      "tolerances" => %{
        "input_contact_count" => 0,
        "row_derived_input_contact_count" => 0,
        "allocated_contact_count" => 0,
        "row_derived_allocated_contact_count" => 0,
        "deferred_contact_count" => 0,
        "row_derived_deferred_contact_count" => 0,
        "blocked_contact_count" => 0,
        "row_derived_blocked_contact_count" => 0,
        "review_row_count" => 0,
        "row_derived_review_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external allocation validation",
        "checks compact allocation counts, routing maps, and model-limit boundary only"
      ]
    },
    "fixture.artifact.contact_allocation_provider_reservation_request_summary.v1" => %{
      "id" => "fixture.artifact.contact_allocation_provider_reservation_request_summary.v1",
      "model_id" => "artifact.contact_allocation_provider_reservation_request_summary.v1",
      "reference_case" => "checked-in provider reservation request summary fixture",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" =>
          "study_results/contact_allocation_provider_reservation_request_summary_v1.json",
        "contract" => "contact_allocation_provider_reservation_request_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "contact_allocation_provider_reservation_request_summary.v1",
        "model" => "artifact_only_contact_allocation_provider_reservation_request_summary",
        "source_artifact_type" => "contact_allocation_report.v1",
        "source" => "validation.provider_reservation_request_summary",
        "input_contact_count" => 4,
        "row_derived_input_contact_count" => 4,
        "provider_reservation_candidate_contact_count" => 2,
        "row_derived_provider_reservation_candidate_contact_count" => 2,
        "provider_reservation_request_contact_count" => 1,
        "row_derived_provider_reservation_request_contact_count" => 1,
        "provider_reservation_review_contact_count" => 1,
        "row_derived_provider_reservation_review_contact_count" => 1,
        "provider_reservation_no_request_contact_count" => 2,
        "row_derived_provider_reservation_no_request_contact_count" => 2,
        "provider_reservation_request_status" => "review_required",
        "provider_reservation_request_contact_keys" => "dl_reserved_owner",
        "provider_reservation_review_contact_keys" => "dl_review_overlap",
        "provider_reservation_no_request_contact_keys" => "dl_reserved_intruder|dl_unreserved",
        "provider_reservation_no_request_contact_ids_by_direction" => %{
          "tracking" => ["dl_reserved_intruder"],
          "uplink" => ["dl_unreserved"]
        },
        "row_derived_provider_reservation_no_request_contact_ids_by_direction" => %{
          "tracking" => ["dl_reserved_intruder"],
          "uplink" => ["dl_unreserved"]
        },
        "row_derived_provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id" =>
          %{
            "tracking" => %{"equator_prime" => ["dl_reserved_intruder"]},
            "uplink" => %{"equator_prime" => ["dl_unreserved"]}
          },
        "provider_reservation_request_contact_ids_by_direction" => %{
          "downlink" => ["dl_reserved_owner"]
        },
        "row_derived_provider_reservation_request_contact_ids_by_direction" => %{
          "downlink" => ["dl_reserved_owner"]
        },
        "row_derived_provider_reservation_request_contact_ids_by_direction_and_ground_station_id" =>
          %{
            "downlink" => %{"equator_prime" => ["dl_reserved_owner"]}
          },
        "provider_reservation_review_contact_ids_by_direction" => %{
          "command" => ["dl_review_overlap"]
        },
        "row_derived_provider_reservation_review_contact_ids_by_direction" => %{
          "command" => ["dl_review_overlap"]
        },
        "row_derived_provider_reservation_review_contact_ids_by_direction_and_ground_station_id" =>
          %{
            "command" => %{"equator_prime" => ["dl_review_overlap"]}
          },
        "provider_reservation_request_contact_ids_by_ground_station_id" => %{
          "equator_prime" => ["dl_reserved_owner"]
        },
        "provider_reservation_review_contact_ids_by_ground_station_id" => %{
          "equator_prime" => ["dl_review_overlap"]
        },
        "provider_reservation_request_contact_ids_by_match_status" => %{
          "matched" => ["dl_reserved_owner"]
        },
        "provider_reservation_review_contact_ids_by_match_status" => %{
          "overlap" => ["dl_review_overlap"]
        },
        "provider_reservation_request_ids_by_match_status" => %{
          "matched" => ["reservation_1"]
        },
        "provider_reservation_review_ids_by_match_status" => %{
          "overlap" => ["reservation_review"]
        },
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
        "provider_reservation_execution" => "not_performed_by_summary",
        "operator_authority" => "not_granted_by_provider_reservation_request_summary"
      },
      "tolerances" => %{
        "input_contact_count" => 0,
        "row_derived_input_contact_count" => 0,
        "provider_reservation_candidate_contact_count" => 0,
        "row_derived_provider_reservation_candidate_contact_count" => 0,
        "provider_reservation_request_contact_count" => 0,
        "row_derived_provider_reservation_request_contact_count" => 0,
        "provider_reservation_review_contact_count" => 0,
        "row_derived_provider_reservation_review_contact_count" => 0,
        "provider_reservation_no_request_contact_count" => 0,
        "row_derived_provider_reservation_no_request_contact_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not external provider reservation validation",
        "checks provider-reservation request, review, no-request routing maps and no-provider-write boundary only"
      ]
    },
    "fixture.artifact.contact_allocation_report.reduced_capacity_pack" => %{
      "id" => "fixture.artifact.contact_allocation_report.reduced_capacity_pack",
      "model_id" => "artifact.contact_allocation_report.v1",
      "reference_case" => "checked-in reduced-capacity contact allocation pack artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/contact_allocation_capacity_pack_report_v1.json",
        "contract" => "contact_allocation_report.v1"
      },
      "expected" => %{
        "schema_contract" => "contact_allocation_report.v1",
        "model" => "deterministic_station_contact_allocation",
        "input_contact_count" => 3,
        "row_count" => 3,
        "allocated_contact_count" => 2,
        "returned_allocated_contact_count" => 2,
        "deferred_contact_count" => 1,
        "blocked_contact_count" => 0,
        "reduced_capacity_pack_group_count" => 1,
        "reduced_capacity_pack_capacity_fraction_total" => 0.5,
        "reduced_capacity_pack_used_fraction_total" => 0.5,
        "reduced_capacity_pack_unused_fraction_total" => 0.0,
        "reduced_capacity_pack_selected_contact_count" => 1,
        "reduced_capacity_pack_capacity_packed_contact_count" => 1,
        "reduced_capacity_pack_deferred_contact_count" => 1,
        "required_capacity_fraction_total" => 0.75,
        "selected_contact_count" => 2,
        "allocation_reason_counts" => %{
          "same_station_contention" => 1,
          "selected_by_contention_resolution" => 1,
          "selected_by_reduced_station_capacity_pack" => 1
        },
        "capacity_pack_status_counts" => %{
          "deferred_by_reduced_station_capacity_pack" => 1,
          "selected_by_contention_resolution" => 1,
          "selected_by_reduced_station_capacity_pack" => 1
        },
        "reported_reduced_capacity_pack_status_counts" => %{
          "capacity_limited" => 1
        },
        "reported_capacity_pack_status_counts" => %{
          "deferred_by_reduced_station_capacity_pack" => 1,
          "selected_by_contention_resolution" => 1,
          "selected_by_reduced_station_capacity_pack" => 1
        },
        "contact_ids_by_capacity_pack_status" => %{
          "deferred_by_reduced_station_capacity_pack" => ["dl_capacity_overflow"],
          "selected_by_contention_resolution" => ["dl_capacity_primary"],
          "selected_by_reduced_station_capacity_pack" => ["dl_capacity_secondary"]
        },
        "reported_capacity_pack_contact_ids_by_status" => %{
          "deferred_by_reduced_station_capacity_pack" => ["dl_capacity_overflow"],
          "selected_by_contention_resolution" => ["dl_capacity_primary"],
          "selected_by_reduced_station_capacity_pack" => ["dl_capacity_secondary"]
        },
        "reported_station_pressure_contact_ids_by_ground_station_id" => %{
          "equator_prime" => [
            "dl_capacity_overflow",
            "dl_capacity_primary",
            "dl_capacity_secondary"
          ]
        },
        "reported_station_pressure_contact_ids_by_availability" => %{
          "available" => [
            "dl_capacity_overflow",
            "dl_capacity_primary",
            "dl_capacity_secondary"
          ],
          "reduced_capacity" => [
            "dl_capacity_overflow",
            "dl_capacity_primary",
            "dl_capacity_secondary"
          ]
        },
        "reported_station_pressure_contact_ids_by_precedence_availability" => %{
          "reduced_capacity" => [
            "dl_capacity_overflow",
            "dl_capacity_primary",
            "dl_capacity_secondary"
          ]
        },
        "reported_station_pressure_contact_ids_by_precedence_rank" => %{
          "2" => [
            "dl_capacity_overflow",
            "dl_capacity_primary",
            "dl_capacity_secondary"
          ]
        },
        "contact_ids_by_effective_allocation_status" => %{
          "allocated" => ["dl_capacity_primary", "dl_capacity_secondary"],
          "deferred" => ["dl_capacity_overflow"]
        },
        "station_calendar_trust_boundary_status_counts" => %{"declared" => 3},
        "calendar_entry_trust_boundary_status_counts" => %{"declared" => 1},
        "model_limit_count" => 8
      },
      "tolerances" => %{
        "input_contact_count" => 0,
        "row_count" => 0,
        "allocated_contact_count" => 0,
        "returned_allocated_contact_count" => 0,
        "deferred_contact_count" => 0,
        "blocked_contact_count" => 0,
        "reduced_capacity_pack_group_count" => 0,
        "reduced_capacity_pack_capacity_fraction_total" => 0.0,
        "reduced_capacity_pack_used_fraction_total" => 0.0,
        "reduced_capacity_pack_unused_fraction_total" => 0.0,
        "reduced_capacity_pack_selected_contact_count" => 0,
        "reduced_capacity_pack_capacity_packed_contact_count" => 0,
        "reduced_capacity_pack_deferred_contact_count" => 0,
        "required_capacity_fraction_total" => 0.0,
        "selected_contact_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external allocation validation",
        "checks reduced-capacity station pack counts, contact routing, capacity fractions, and model-limit boundary only"
      ]
    },
    "fixture.artifact.contact_filter_report.v1" => %{
      "id" => "fixture.artifact.contact_filter_report.v1",
      "model_id" => "artifact.contact_filter_report.v1",
      "reference_case" => "checked-in contact filter artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/contact_filter_report_v1.json",
        "contract" => "contact_filter_report.v1"
      },
      "expected" => %{
        "schema_contract" => "contact_filter_report.v1",
        "model" => "thin_ground_network_availability_filter",
        "input_candidate_count" => 3,
        "kept_candidate_count" => 0,
        "suppressed_candidate_count" => 3,
        "row_derived_suppressed_candidate_count" => 3,
        "suppressed_candidate_row_count" => 3,
        "duplicate_suppressed_candidate_id_count" => 0,
        "duplicate_suppressed_candidate_row_count" => 0,
        "station_reservation_match_status_counts" => %{"overlap" => 1},
        "suppressed_reason_counts" => %{
          "ground_station_reserved" => 1,
          "ground_station_unavailable" => 2
        },
        "suppressed_station_availability_counts" => %{
          "reserved" => 1,
          "unavailable" => 2
        },
        "suppressed_candidate_ids_by_reason" => %{
          "ground_station_reserved" => ["leo_2_downlink_polar_north_1"],
          "ground_station_unavailable" => [
            "leo_1_downlink_equator_prime_1",
            "leo_1_tracking_equator_prime_1"
          ]
        },
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "input_candidate_count" => 0,
        "kept_candidate_count" => 0,
        "suppressed_candidate_count" => 0,
        "row_derived_suppressed_candidate_count" => 0,
        "suppressed_candidate_row_count" => 0,
        "duplicate_suppressed_candidate_id_count" => 0,
        "duplicate_suppressed_candidate_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not provider availability validation",
        "checks contact filter counts, suppression routing maps, and model-limit boundary only"
      ]
    },
    "fixture.artifact.contact_contention_report.v1" => %{
      "id" => "fixture.artifact.contact_contention_report.v1",
      "model_id" => "artifact.contact_contention_report.v1",
      "reference_case" => "checked-in contact contention artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/contact_contention_report_v1.json",
        "contract" => "contact_contention_report.v1"
      },
      "expected" => %{
        "schema_contract" => "contact_contention_report.v1",
        "model" => "single_station_interval_overlap",
        "input_contact_count" => 4,
        "conflict_group_count" => 2,
        "row_derived_conflict_group_count" => 2,
        "conflict_group_row_count" => 2,
        "conflicted_contact_count" => 4,
        "row_derived_conflicted_contact_count" => 4,
        "group_contact_count_total" => 4,
        "row_derived_group_contact_count_total" => 4,
        "duplicate_contact_candidate_count" => 0,
        "duplicate_contact_id_count" => 0,
        "review_required_group_count" => 2,
        "row_derived_review_required_group_count" => 2,
        "resource_scope_counts" => %{"ground_station" => 1, "spacecraft" => 1},
        "required_operator_action_counts" => %{"review_contact_contention" => 2},
        "conflict_group_ids_by_resource_scope" => %{
          "ground_station" => ["station:equator_prime:contention:1"],
          "spacecraft" => ["spacecraft:sat_1:contention:1"]
        },
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "input_contact_count" => 0,
        "conflict_group_count" => 0,
        "row_derived_conflict_group_count" => 0,
        "conflict_group_row_count" => 0,
        "conflicted_contact_count" => 0,
        "row_derived_conflicted_contact_count" => 0,
        "group_contact_count_total" => 0,
        "row_derived_group_contact_count_total" => 0,
        "duplicate_contact_candidate_count" => 0,
        "duplicate_contact_id_count" => 0,
        "review_required_group_count" => 0,
        "row_derived_review_required_group_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not provider schedule validation",
        "checks contact contention counts, operator-action routing, resource-scope maps, and model-limit boundary only"
      ]
    },
    "fixture.artifact.contact_contention_report.cross_station_spacecraft" => %{
      "id" => "fixture.artifact.contact_contention_report.cross_station_spacecraft",
      "model_id" => "artifact.contact_contention_report.v1",
      "reference_case" => "generated cross-station same-spacecraft contact contention challenge",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_cross_station_spacecraft_contention_fixture",
        "contract" => "contact_contention_report.v1"
      },
      "expected" => %{
        "schema_contract" => "contact_contention_report.v1",
        "model" => "single_station_interval_overlap",
        "input_contact_count" => 3,
        "conflict_group_count" => 1,
        "row_derived_conflict_group_count" => 1,
        "conflict_group_row_count" => 1,
        "conflicted_contact_count" => 2,
        "row_derived_conflicted_contact_count" => 2,
        "group_contact_count_total" => 2,
        "row_derived_group_contact_count_total" => 2,
        "duplicate_contact_candidate_count" => 0,
        "duplicate_contact_id_count" => 0,
        "review_required_group_count" => 1,
        "row_derived_review_required_group_count" => 1,
        "resource_scope_counts" => %{"spacecraft" => 1},
        "required_operator_action_counts" => %{"review_contact_contention" => 1},
        "conflict_group_ids_by_resource_scope" => %{
          "spacecraft" => ["spacecraft:sat_1:contention:1"]
        },
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "input_contact_count" => 0,
        "conflict_group_count" => 0,
        "row_derived_conflict_group_count" => 0,
        "conflict_group_row_count" => 0,
        "conflicted_contact_count" => 0,
        "row_derived_conflicted_contact_count" => 0,
        "group_contact_count_total" => 0,
        "row_derived_group_contact_count_total" => 0,
        "duplicate_contact_candidate_count" => 0,
        "duplicate_contact_id_count" => 0,
        "review_required_group_count" => 0,
        "row_derived_review_required_group_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not provider schedule validation",
        "checks same-spacecraft cross-station contention routing without provider reservation or schedule mutation"
      ]
    },
    "fixture.artifact.contact_contention_resolution_report.v1" => %{
      "id" => "fixture.artifact.contact_contention_resolution_report.v1",
      "model_id" => "artifact.contact_contention_resolution_report.v1",
      "reference_case" => "checked-in contact contention resolution artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/contact_contention_resolution_report_v1.json",
        "contract" => "contact_contention_resolution_report.v1"
      },
      "expected" => %{
        "schema_contract" => "contact_contention_resolution_report.v1",
        "model" => "deterministic_contact_contention_recommendation",
        "conflict_group_count" => 2,
        "row_derived_conflict_group_count" => 2,
        "recommendation_count" => 2,
        "row_derived_recommendation_count" => 2,
        "recommendation_row_count" => 2,
        "candidate_count_total" => 4,
        "selected_contact_count" => 2,
        "row_derived_selected_contact_count" => 2,
        "deferred_contact_count" => 2,
        "row_derived_deferred_contact_count" => 2,
        "review_required_recommendation_count" => 2,
        "row_derived_review_required_recommendation_count" => 2,
        "resource_scope_counts" => %{"ground_station" => 1, "spacecraft" => 1},
        "action_counts" => %{"recommend_preferred_contact_for_operator_review" => 2},
        "selection_reason_counts" => %{"highest_score_earliest_start" => 2},
        "selected_contact_ids_by_resource_scope" => %{
          "ground_station" => ["dl_1"],
          "spacecraft" => ["dl_3"]
        },
        "resolution_boundary" => "recommendation_only_no_station_reservation",
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "conflict_group_count" => 0,
        "row_derived_conflict_group_count" => 0,
        "recommendation_count" => 0,
        "row_derived_recommendation_count" => 0,
        "recommendation_row_count" => 0,
        "candidate_count_total" => 0,
        "selected_contact_count" => 0,
        "row_derived_selected_contact_count" => 0,
        "deferred_contact_count" => 0,
        "row_derived_deferred_contact_count" => 0,
        "review_required_recommendation_count" => 0,
        "row_derived_review_required_recommendation_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not provider reservation or schedule validation",
        "checks contention-resolution recommendation counts, routing maps, no-reservation boundary, and model-limit boundary only"
      ]
    },
    "fixture.artifact.contact_contention_resolution_summary.v1" => %{
      "id" => "fixture.artifact.contact_contention_resolution_summary.v1",
      "model_id" => "artifact.contact_contention_resolution_summary.v1",
      "reference_case" => "checked-in contact contention resolution summary artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/contact_contention_resolution_summary_v1.json",
        "contract" => "contact_contention_resolution_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "contact_contention_resolution_summary.v1",
        "model" => "artifact_only_contact_contention_resolution_summary",
        "source_artifact_type" => "contact_contention_resolution_report.v1",
        "conflict_group_count" => 2,
        "recommendation_count" => 2,
        "recommendation_group_ids" =>
          "spacecraft:sat_1:contention:1|station:equator_prime:contention:1",
        "review_group_ids" => "spacecraft:sat_1:contention:1|station:equator_prime:contention:1",
        "selected_contact_ids" => "dl_1|dl_3",
        "selected_contact_ids_by_group_id" => %{
          "spacecraft:sat_1:contention:1" => ["dl_3"],
          "station:equator_prime:contention:1" => ["dl_1"]
        },
        "deferred_contact_ids" => "dl_2|dl_4",
        "deferred_contact_ids_by_group_id" => %{
          "spacecraft:sat_1:contention:1" => ["dl_4"],
          "station:equator_prime:contention:1" => ["dl_2"]
        },
        "review_contact_ids" => "dl_1|dl_2|dl_3|dl_4",
        "review_contact_ids_by_group_id" => %{
          "spacecraft:sat_1:contention:1" => ["dl_3", "dl_4"],
          "station:equator_prime:contention:1" => ["dl_1", "dl_2"]
        },
        "review_recommendation_count" => 2,
        "resource_scope_counts" => %{"ground_station" => 1, "spacecraft" => 1},
        "selected_contact_ids_by_resource_scope" => %{
          "ground_station" => ["dl_1"],
          "spacecraft" => ["dl_3"]
        },
        "deferred_contact_ids_by_resource_scope" => %{
          "ground_station" => ["dl_2"],
          "spacecraft" => ["dl_4"]
        },
        "review_contact_ids_by_resource_scope" => %{
          "ground_station" => ["dl_1", "dl_2"],
          "spacecraft" => ["dl_3", "dl_4"]
        },
        "selection_reason_counts" => %{"highest_score_earliest_start" => 2},
        "selected_contact_ids_by_selection_reason" => %{
          "highest_score_earliest_start" => ["dl_1", "dl_3"]
        },
        "action_counts" => %{"recommend_preferred_contact_for_operator_review" => 2},
        "review_contact_ids_by_action" => %{
          "recommend_preferred_contact_for_operator_review" => [
            "dl_1",
            "dl_2",
            "dl_3",
            "dl_4"
          ]
        },
        "ambiguous_group_ids" => "",
        "ambiguous_duplicate_contact_ids" => "",
        "ambiguous_duplicate_contact_ids_by_group_id" => %{},
        "model_limit_count" => 5,
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
        "assumption_source" => "contact_contention_resolution_report.v1",
        "candidate_mutation" => "none",
        "operator_authority" => "not_granted_by_summary",
        "no_provider_reservation" => true,
        "no_candidate_suppression" => true,
        "no_schedule_mutation" => true,
        "no_link_budget_model" => true
      },
      "tolerances" => %{
        "conflict_group_count" => 0,
        "recommendation_count" => 0,
        "review_recommendation_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by contact_contention_resolution_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not provider reservation or schedule validation",
        "checks compact contention-resolution routing, review handoff IDs, model limits, and no-mutation boundaries only"
      ]
    },
    "fixture.artifact.link_capacity_report.v1" => %{
      "id" => "fixture.artifact.link_capacity_report.v1",
      "model_id" => "artifact.link_capacity_report.v1",
      "reference_case" => "checked-in link capacity artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/link_capacity_report_v1.json",
        "contract" => "link_capacity_report.v1"
      },
      "expected" => %{
        "schema_contract" => "link_capacity_report.v1",
        "model" => "fixed_rate_downlink_capacity_summary",
        "contact_count" => 1,
        "row_derived_contact_count" => 1,
        "effective_contact_count" => 1,
        "row_derived_effective_contact_count" => 1,
        "row_count" => 1,
        "selected_contact_count" => 0,
        "row_derived_selected_contact_count" => 0,
        "ignored_contact_count" => 0,
        "row_derived_ignored_contact_count" => 0,
        "ignored_selected_contact_count" => 0,
        "row_derived_ignored_selected_contact_count" => 0,
        "row_derived_required_downlink_contact_count" => 0,
        "row_derived_actual_throughput_contact_count" => 0,
        "row_derived_actual_completion_contact_count" => 0,
        "unmatched_selected_contact_count" => 0,
        "ambiguous_selected_contact_id_count" => 0,
        "duplicate_contact_candidate_count" => 0,
        "duplicate_contact_id_count" => 0,
        "capacity_adjusted_throughput_mb" => 172.71212086982393,
        "estimated_throughput_mb" => 345.42424173964787,
        "selected_capacity_adjusted_throughput_mb" => 0.0,
        "selected_estimated_throughput_mb" => 0.0,
        "unused_capacity_adjusted_throughput_mb" => 172.71212086982393,
        "selection_utilization_status" => "unselected_capacity",
        "station_count" => 1,
        "stations_by_selection_utilization_status" => %{
          "unselected_capacity" => ["equator_prime"]
        },
        "model_limit_count" => 9
      },
      "tolerances" => %{
        "contact_count" => 0,
        "row_derived_contact_count" => 0,
        "effective_contact_count" => 0,
        "row_derived_effective_contact_count" => 0,
        "row_count" => 0,
        "selected_contact_count" => 0,
        "row_derived_selected_contact_count" => 0,
        "ignored_contact_count" => 0,
        "row_derived_ignored_contact_count" => 0,
        "ignored_selected_contact_count" => 0,
        "row_derived_ignored_selected_contact_count" => 0,
        "row_derived_required_downlink_contact_count" => 0,
        "row_derived_actual_throughput_contact_count" => 0,
        "row_derived_actual_completion_contact_count" => 0,
        "unmatched_selected_contact_count" => 0,
        "ambiguous_selected_contact_id_count" => 0,
        "duplicate_contact_candidate_count" => 0,
        "duplicate_contact_id_count" => 0,
        "capacity_adjusted_throughput_mb" => 0.0,
        "estimated_throughput_mb" => 0.0,
        "selected_capacity_adjusted_throughput_mb" => 0.0,
        "selected_estimated_throughput_mb" => 0.0,
        "unused_capacity_adjusted_throughput_mb" => 0.0,
        "station_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external link-budget validation",
        "checks fixed-rate link-capacity counts, throughput totals, station routing, and model-limit boundary only"
      ]
    },
    "fixture.artifact.relay_data_path_summary.v1" => %{
      "id" => "fixture.artifact.relay_data_path_summary.v1",
      "model_id" => "artifact.relay_data_path_summary.v1",
      "reference_case" => "checked-in relay data-path summary artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/relay_data_path_summary_v1.json",
        "contract" => "relay_data_path_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "relay_data_path_summary.v1",
        "model" => "artifact_only_relay_data_path_summary",
        "source" => "relay_ops",
        "route_count" => 2,
        "row_derived_route_count" => 2,
        "relay_route_count" => 1,
        "row_derived_relay_route_count" => 1,
        "direct_downlink_route_count" => 1,
        "row_derived_direct_downlink_route_count" => 1,
        "custody_status_counts" => %{"confirmed" => 1, "missing_ack" => 1},
        "row_derived_custody_status_counts" => %{"confirmed" => 1, "missing_ack" => 1},
        "latency_status_counts" => %{"exceeds_limit" => 1, "within_limit" => 1},
        "row_derived_latency_status_counts" => %{"exceeds_limit" => 1, "within_limit" => 1},
        "risk_status_counts" => %{"high" => 1, "nominal" => 1},
        "row_derived_risk_status_counts" => %{"high" => 1, "nominal" => 1},
        "route_ids" => "relay_data_path:sat_a:downlink_1:54b7e7ff594c|route_direct",
        "row_derived_route_ids" => "relay_data_path:sat_a:downlink_1:54b7e7ff594c|route_direct",
        "source_spacecraft_ids" => "sat_a|sat_b",
        "row_derived_source_spacecraft_ids" => "sat_a|sat_b",
        "relay_spacecraft_ids" => "relay_1|relay_2",
        "row_derived_relay_spacecraft_ids" => "relay_1|relay_2",
        "ground_station_ids" => "dss_14|dss_35",
        "row_derived_ground_station_ids" => "dss_14|dss_35",
        "ground_downlink_contact_ids" => "downlink_1|downlink_2",
        "row_derived_ground_downlink_contact_ids" => "downlink_1|downlink_2",
        "route_ids_by_custody_status" => %{
          "confirmed" => ["relay_data_path:sat_a:downlink_1:54b7e7ff594c"],
          "missing_ack" => ["route_direct"]
        },
        "row_derived_route_ids_by_custody_status" => %{
          "confirmed" => ["relay_data_path:sat_a:downlink_1:54b7e7ff594c"],
          "missing_ack" => ["route_direct"]
        },
        "route_ids_by_latency_status" => %{
          "exceeds_limit" => ["route_direct"],
          "within_limit" => ["relay_data_path:sat_a:downlink_1:54b7e7ff594c"]
        },
        "row_derived_route_ids_by_latency_status" => %{
          "exceeds_limit" => ["route_direct"],
          "within_limit" => ["relay_data_path:sat_a:downlink_1:54b7e7ff594c"]
        },
        "route_ids_by_risk_status" => %{
          "high" => ["route_direct"],
          "nominal" => ["relay_data_path:sat_a:downlink_1:54b7e7ff594c"]
        },
        "row_derived_route_ids_by_risk_status" => %{
          "high" => ["route_direct"],
          "nominal" => ["relay_data_path:sat_a:downlink_1:54b7e7ff594c"]
        },
        "route_ids_by_ground_station_id" => %{
          "dss_14" => ["relay_data_path:sat_a:downlink_1:54b7e7ff594c"],
          "dss_35" => ["route_direct"]
        },
        "row_derived_route_ids_by_ground_station_id" => %{
          "dss_14" => ["relay_data_path:sat_a:downlink_1:54b7e7ff594c"],
          "dss_35" => ["route_direct"]
        },
        "maximum_latency_s" => 500.0,
        "row_derived_maximum_latency_s" => 500.0,
        "maximum_latency_limit_s" => 300.0,
        "row_derived_maximum_latency_limit_s" => 300.0,
        "execution_boundary" => "artifact_only_no_relay_scheduling_or_schedule_mutation",
        "custody_acknowledgement_delivery" => "not_performed",
        "model_limit_count" => 6
      },
      "tolerances" => %{
        "route_count" => 0,
        "row_derived_route_count" => 0,
        "relay_route_count" => 0,
        "row_derived_relay_route_count" => 0,
        "direct_downlink_route_count" => 0,
        "row_derived_direct_downlink_route_count" => 0,
        "maximum_latency_s" => 0,
        "row_derived_maximum_latency_s" => 0,
        "maximum_latency_limit_s" => 0,
        "row_derived_maximum_latency_limit_s" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not relay scheduling validation",
        "checks relay/direct route counts, custody/latency/risk routing maps, route IDs, and model-limit boundary only"
      ]
    },
    "fixture.artifact.maneuver_review_report.v1" => %{
      "id" => "fixture.artifact.maneuver_review_report.v1",
      "model_id" => "artifact.maneuver_review_report.v1",
      "reference_case" => "checked-in maneuver review artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/maneuver_review_report_v1.json",
        "contract" => "maneuver_review_report.v1"
      },
      "expected" => %{
        "schema_contract" => "maneuver_review_report.v1",
        "model" => "artifact_only_maneuver_review_report",
        "source" => "study_results/mission_plan_checkout.json.maneuver_recommendations",
        "source_artifact_id" => "mission_plan_checkout",
        "maneuver_count" => 1,
        "row_count" => 1,
        "review_required_count" => 1,
        "invalid_maneuver_recommendation_count" => 0,
        "invalid_maneuver_recommendation_id_count" => 0,
        "execution_uncertainty_declared_count" => 0,
        "execution_uncertainty_missing_count" => 1,
        "total_delta_v_km_s" => 0.01,
        "approval_status_counts" => %{"operator_review_required" => 1},
        "required_operator_action_counts" => %{"review_maneuver_recommendation" => 1},
        "execution_uncertainty_status_counts" => %{"missing" => 1},
        "maneuver_review_ids_by_required_operator_action" => %{
          "review_maneuver_recommendation" => ["maneuver_review:ops_checkout:trim_burn"]
        },
        "execution_boundary" => "recommendation_only_no_command_execution",
        "review_boundary" => "review_only_no_command_execution",
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "maneuver_count" => 0,
        "row_count" => 0,
        "review_required_count" => 0,
        "invalid_maneuver_recommendation_count" => 0,
        "invalid_maneuver_recommendation_id_count" => 0,
        "execution_uncertainty_declared_count" => 0,
        "execution_uncertainty_missing_count" => 0,
        "total_delta_v_km_s" => 0.0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not maneuver execution validation",
        "checks maneuver review counts, operator-action routing, and no-command boundary only"
      ]
    },
    "fixture.artifact.monte_carlo_reproducibility_report.v1" => %{
      "id" => "fixture.artifact.monte_carlo_reproducibility_report.v1",
      "model_id" => "artifact.monte_carlo_reproducibility_report.v1",
      "reference_case" => "checked-in Monte Carlo reproducibility artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/monte_carlo_reproducibility_report_v1.json",
        "contract" => "monte_carlo_reproducibility_report.v1"
      },
      "expected" => %{
        "schema_contract" => "monte_carlo_reproducibility_report.v1",
        "model" => "seeded_independent_normal_cartesian_dispersion",
        "source" => "study_metadata.monte_carlo",
        "generator" => "state_vector_dispersion",
        "requested_count" => 20,
        "generated_scenario_count" => 20,
        "generated_scenario_id_count" => 20,
        "first_generated_scenario_id" => "dispersion_1",
        "last_generated_scenario_id" => "dispersion_20",
        "deterministic_seed" => true,
        "seed" => 12345,
        "rng" => "rand_exsss",
        "sampling_method" => "box_muller_transform",
        "id_prefix" => "dispersion",
        "position_sigma_km" => [0.1, 0.1, 0.05],
        "velocity_sigma_km_s" => [0.0001, 0.0001, 0.00005],
        "distribution" => "independent normal per Cartesian component",
        "covariance_model" => "none",
        "model_limit_count" => 4,
        "known_limit_count" => 4
      },
      "tolerances" => %{
        "requested_count" => 0,
        "generated_scenario_count" => 0,
        "generated_scenario_id_count" => 0,
        "seed" => 0,
        "position_sigma_km" => 0.0,
        "velocity_sigma_km_s" => 0.0,
        "model_limit_count" => 0,
        "known_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not statistical validation",
        "checks seeded reproducibility counts, RNG metadata, dispersion sigmas, and model-limit boundary only"
      ]
    },
    "fixture.artifact.pareto_frontier_report.v1" => %{
      "id" => "fixture.artifact.pareto_frontier_report.v1",
      "model_id" => "artifact.pareto_frontier_report.v1",
      "reference_case" => "checked-in Pareto frontier artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/pareto_frontier_report_v1.json",
        "contract" => "pareto_frontier_report.v1"
      },
      "expected" => %{
        "schema_contract" => "pareto_frontier_report.v1",
        "model" => "objective_vector_pareto_frontier",
        "source" => "strategy.branch_objectives",
        "alternative_count" => 4,
        "row_count" => 4,
        "frontier_count" => 3,
        "dominated_count" => 1,
        "objective_count" => 2,
        "objective_directions" => %{"coverage" => "maximize", "risk" => "minimize"},
        "frontier_status_counts" => %{"false" => 1, "true" => 3},
        "objective_key_count_counts" => %{"0" => 1, "2" => 3},
        "alternative_ids_by_frontier_status" => %{
          "false" => ["dominated"],
          "true" => ["balanced", "coverage_leader", "ignored_no_numeric"]
        },
        "missing_objective_policy" => "alternative_with_missing_objective_cannot_dominate",
        "search_performed" => false,
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "alternative_count" => 0,
        "row_count" => 0,
        "frontier_count" => 0,
        "dominated_count" => 0,
        "objective_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external optimizer validation",
        "checks deterministic frontier counts, dominance routing, and no-solver boundary only"
      ]
    },
    "fixture.artifact.resource_projection_report.v1" => %{
      "id" => "fixture.artifact.resource_projection_report.v1",
      "model_id" => "artifact.resource_projection_report.v1",
      "reference_case" => "checked-in selected-activity resource projection artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/resource_projection_report_v1.json",
        "contract" => "resource_projection_report.v1"
      },
      "expected" => %{
        "schema_contract" => "resource_projection_report.v1",
        "model" => "thin_campaign_selected_activity_resource_projection",
        "activity_count" => 1,
        "input_resource_summary_count" => 1,
        "valid_activity_count" => 1,
        "invalid_activity_input_count" => 0,
        "projected_resource_count" => 1,
        "activity_resource_flow_count" => 1,
        "resource_pressure_row_count" => 0,
        "storage_overflow_row_count" => 0,
        "downlink_shortfall_row_count" => 0,
        "projected_storage_overflow_mb_total" => 0.0,
        "projected_downlink_shortfall_mb_total" => 0.0,
        "warning_count" => 0,
        "model_limit_count" => 9,
        "resource_source_quality_counts" => %{"operator_supplied" => 1},
        "resource_trust_boundary_status_counts" => %{"missing" => 1}
      },
      "tolerances" => %{
        "activity_count" => 0,
        "input_resource_summary_count" => 0,
        "valid_activity_count" => 0,
        "invalid_activity_input_count" => 0,
        "projected_resource_count" => 0,
        "activity_resource_flow_count" => 0,
        "resource_pressure_row_count" => 0,
        "storage_overflow_row_count" => 0,
        "downlink_shortfall_row_count" => 0,
        "projected_storage_overflow_mb_total" => 0.0,
        "projected_downlink_shortfall_mb_total" => 0.0,
        "warning_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external resource-model validation",
        "checks resource projection counts, pressure routing counts, and summary maps only"
      ]
    },
    "fixture.artifact.resource_projection_flow_summary.v1" => %{
      "id" => "fixture.artifact.resource_projection_flow_summary.v1",
      "model_id" => "artifact.resource_projection_flow_summary.v1",
      "reference_case" => "checked-in compact selected-activity resource-flow summary artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/resource_projection_flow_summary_v1.json",
        "contract" => "resource_projection_flow_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "resource_projection_flow_summary.v1",
        "model" => "artifact_only_selected_activity_resource_flow_summary",
        "source" => "campaign.resource_summaries",
        "activity_count" => 1,
        "valid_activity_count" => 1,
        "invalid_activity_input_count" => 0,
        "input_resource_summary_count" => 1,
        "valid_resource_summary_count" => 1,
        "invalid_resource_summary_input_count" => 0,
        "projected_resource_count" => 1,
        "flow_row_count" => 1,
        "resource_flow_status" => "clear",
        "resource_pressure_status" => "clear",
        "resource_pressure_count" => 0,
        "total_storage_produced_mb" => 0.0,
        "total_storage_limited_downlinked_mb" => 0.0,
        "total_downlink_shortfall_mb" => 0.0,
        "total_unused_downlink_capacity_mb" => 0.0,
        "total_battery_energy_consumed_wh" => 120.0,
        "total_battery_energy_generated_wh" => 0.0,
        "net_battery_energy_delta_wh" => 120.0,
        "peak_battery_overuse_wh" => 0.0,
        "total_projected_storage_remaining_mb" => 750.0,
        "minimum_projected_storage_remaining_mb" => 750.0,
        "total_projected_downlink_remaining_mb" => 600.0,
        "minimum_projected_downlink_remaining_mb" => 600.0,
        "ignored_activity_count" => 0,
        "ignored_activity_reason_counts" => %{},
        "resource_pressure_types" => [],
        "model_limit_count" => 9,
        "execution_boundary" => "artifact_only_no_schedule_mutation"
      },
      "tolerances" => %{
        "activity_count" => 0,
        "valid_activity_count" => 0,
        "invalid_activity_input_count" => 0,
        "input_resource_summary_count" => 0,
        "valid_resource_summary_count" => 0,
        "invalid_resource_summary_input_count" => 0,
        "projected_resource_count" => 0,
        "flow_row_count" => 0,
        "resource_pressure_count" => 0,
        "total_storage_produced_mb" => 0.0,
        "total_storage_limited_downlinked_mb" => 0.0,
        "total_downlink_shortfall_mb" => 0.0,
        "total_unused_downlink_capacity_mb" => 0.0,
        "total_battery_energy_consumed_wh" => 0.0,
        "total_battery_energy_generated_wh" => 0.0,
        "net_battery_energy_delta_wh" => 0.0,
        "peak_battery_overuse_wh" => 0.0,
        "total_projected_storage_remaining_mb" => 0.0,
        "minimum_projected_storage_remaining_mb" => 0.0,
        "total_projected_downlink_remaining_mb" => 0.0,
        "minimum_projected_downlink_remaining_mb" => 0.0,
        "ignored_activity_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external resource-model validation",
        "checks compact resource-flow row-derived storage, downlink, battery, and pressure evidence only"
      ]
    },
    "fixture.artifact.resource_projection_report.battery_handoff_v1" => %{
      "id" => "fixture.artifact.resource_projection_report.battery_handoff_v1",
      "model_id" => "artifact.resource_projection_report.v1",
      "reference_case" => "checked-in resource projection battery handoff source artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/resource_projection_battery_handoff_v1.json",
        "contract" => "resource_projection_report.v1"
      },
      "expected" => %{
        "schema_contract" => "resource_projection_report.v1",
        "model" => "thin_battery_handoff_resource_projection_fixture",
        "activity_count" => 2,
        "projected_resource_count" => 1,
        "activity_resource_flow_count" => 2,
        "storage_overflow_row_count" => 1,
        "downlink_shortfall_row_count" => 1,
        "total_battery_energy_consumed_wh" => 23.0,
        "total_battery_energy_generated_wh" => 8.0,
        "net_battery_energy_delta_wh" => 15.0,
        "peak_battery_overuse_wh" => 4.0,
        "model_limit_count" => 9
      },
      "tolerances" => %{
        "activity_count" => 0,
        "projected_resource_count" => 0,
        "activity_resource_flow_count" => 0,
        "storage_overflow_row_count" => 0,
        "downlink_shortfall_row_count" => 0,
        "total_battery_energy_consumed_wh" => 0.0,
        "total_battery_energy_generated_wh" => 0.0,
        "net_battery_energy_delta_wh" => 0.0,
        "peak_battery_overuse_wh" => 0.0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external resource-model validation",
        "checks battery flow aggregation source values for review/import handoff fixtures only"
      ]
    },
    "fixture.artifact.resource_projection_report.stale_resource_summary_margins" => %{
      "id" => "fixture.artifact.resource_projection_report.stale_resource_summary_margins",
      "model_id" => "artifact.resource_projection_report.v1",
      "reference_case" => "generated stale derived-margin resource projection challenge",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_resource_projection_stale_derived_margin_fixture",
        "contract" => "resource_projection_report.v1"
      },
      "expected" => %{
        "schema_contract" => "resource_projection_report.v1",
        "model" => "thin_stale_derived_margin_resource_projection_fixture",
        "activity_count" => 1,
        "input_resource_summary_count" => 3,
        "valid_resource_summary_count" => 1,
        "invalid_activity_input_count" => 0,
        "invalid_resource_summary_input_count" => 2,
        "invalid_resource_summary_input_ids" => "leo_2|leo_3",
        "invalid_resource_summary_input_reasons" =>
          "stale_battery_state_of_charge|stale_storage_margin",
        "stale_battery_state_of_charge_count" => 1,
        "stale_storage_margin_count" => 1,
        "projected_resource_count" => 1,
        "activity_resource_flow_count" => 1,
        "model_limit_count" => 9
      },
      "tolerances" => %{
        "activity_count" => 0,
        "input_resource_summary_count" => 0,
        "valid_resource_summary_count" => 0,
        "invalid_activity_input_count" => 0,
        "invalid_resource_summary_input_count" => 0,
        "stale_battery_state_of_charge_count" => 0,
        "stale_storage_margin_count" => 0,
        "projected_resource_count" => 0,
        "activity_resource_flow_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not external resource-model validation",
        "checks stale explicit battery and storage derived-margin evidence is preserved for review"
      ]
    },
    "fixture.artifact.resource_summary.v1" => %{
      "id" => "fixture.artifact.resource_summary.v1",
      "model_id" => "artifact.resource_summary.v1",
      "reference_case" => "checked-in planning resource summary artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/resource_summary_v1.json",
        "contract" => "resource_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "resource_summary.v1",
        "spacecraft_id" => "leo_1",
        "mode" => "degraded",
        "fuel_margin" => 0.82,
        "power_margin" => 0.74,
        "battery_capacity_wh" => 1200.0,
        "battery_energy_used_wh" => 312.0,
        "battery_state_of_charge" => 0.74,
        "thermal_margin_c" => -2.5,
        "storage_capacity_mb" => 1000.0,
        "storage_used_mb" => 250.0,
        "storage_margin" => 0.75,
        "downlink_capacity_mb" => 600.0,
        "downlink_margin" => 0.65,
        "spacecraft_available" => false,
        "payload_available" => false,
        "antenna_available" => true,
        "degraded" => true,
        "source_quality" => "operator_supplied",
        "trust_boundary" => "operator_declared_resource_summary",
        "suppressed_activity_type_count" => 2,
        "suppressed_activity_type_order" => "observe|command",
        "incompatible_activity_type_count" => 2,
        "incompatible_activity_type_order" => "command|health_check",
        "assumption_source" => "campaign_manifest_demo",
        "provenance_source" => "ops"
      },
      "tolerances" => %{
        "fuel_margin" => 0.0,
        "power_margin" => 0.0,
        "battery_capacity_wh" => 0.0,
        "battery_energy_used_wh" => 0.0,
        "battery_state_of_charge" => 0.0,
        "thermal_margin_c" => 0.0,
        "storage_capacity_mb" => 0.0,
        "storage_used_mb" => 0.0,
        "storage_margin" => 0.0,
        "downlink_capacity_mb" => 0.0,
        "downlink_margin" => 0.0,
        "suppressed_activity_type_count" => 0,
        "incompatible_activity_type_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external resource-model validation",
        "checks resource-summary normalization, derived margins, availability flags, and provenance boundaries only"
      ]
    },
    "fixture.artifact.station_calendar_precedence_summary.v1" => %{
      "id" => "fixture.artifact.station_calendar_precedence_summary.v1",
      "model_id" => "artifact.station_calendar_precedence_summary.v1",
      "reference_case" => "checked-in station calendar precedence summary artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/station_calendar_precedence_summary_v1.json",
        "contract" => "station_calendar_precedence_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "station_calendar_precedence_summary.v1",
        "model" => "artifact_only_station_calendar_precedence_summary",
        "source_artifact_type" => "station_calendar_report.v1",
        "source" => "ops_calendar",
        "affected_contact_count" => 1,
        "precedence_review_status" => "review_required",
        "applied_availability_counts" => %{"unavailable" => 1},
        "applied_status_counts" => %{"unavailable" => 1},
        "overlap_availability_counts" => %{
          "reduced_capacity" => 1,
          "reserved" => 1,
          "unavailable" => 1
        },
        "affected_contact_ids_by_applied_availability" => %{"unavailable" => ["dl_1"]},
        "affected_contact_ids_by_applied_status" => %{"unavailable" => ["dl_1"]},
        "affected_contact_ids_by_overlap_availability" => %{
          "reduced_capacity" => ["dl_1"],
          "reserved" => ["dl_1"],
          "unavailable" => ["dl_1"]
        },
        "reserved_under_higher_precedence_contact_count" => 1,
        "reserved_under_higher_precedence_contact_ids" => "dl_1",
        "reserved_under_higher_precedence_contact_ids_by_applied_availability" => %{
          "unavailable" => ["dl_1"]
        },
        "reserved_under_higher_precedence_contact_ids_by_applied_status" => %{
          "unavailable" => ["dl_1"]
        },
        "unavailable_contact_ids" => "dl_1",
        "reserved_overlap_contact_ids" => "dl_1",
        "reduced_capacity_contact_ids" => "dl_1",
        "model_limit_count" => 5,
        "execution_boundary" => "artifact_only_no_provider_reservation",
        "scope" => "station_calendar_availability_precedence_review",
        "operator_authority" => "not_granted_by_summary",
        "no_network_calls" => true,
        "no_provider_reservation" => true,
        "no_schedule_mutation" => true,
        "no_conflict_resolution" => true
      },
      "tolerances" => %{
        "affected_contact_count" => 0,
        "reserved_under_higher_precedence_contact_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by station_calendar_precedence_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external provider validation",
        "checks compact precedence routing, higher-precedence reservation visibility, and no-provider/no-mutation boundaries only"
      ]
    },
    "fixture.artifact.station_calendar_provider.v1" => %{
      "id" => "fixture.artifact.station_calendar_provider.v1",
      "model_id" => "artifact.station_calendar_provider.v1",
      "reference_case" => "checked-in declared station calendar provider artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/station_calendar_provider_v1.json",
        "contract" => "station_calendar_provider.v1"
      },
      "expected" => %{
        "schema_contract" => "station_calendar_provider.v1",
        "id" => "declared_ground_network_demo",
        "provider_id" => "declared_ground_network_demo",
        "entry_count" => 2,
        "entry_id_order" => "equator_prime_maintenance_1|equator_prime_reservation_1",
        "ground_station_id_order" => "equator_prime|equator_prime",
        "maintenance_entry_count" => 1,
        "reserved_entry_count" => 1,
        "zero_capacity_entry_count" => 1,
        "reservation_entry_count" => 1,
        "reservation_id_order" => "reservation_equator_prime_1",
        "reserved_by_order" => "ops_team_b",
        "provenance_source" => "declared_provider_fixture",
        "trust_boundary" => "operator_declared_station_calendar",
        "assumption_boundary" => "artifact_only_no_provider_reservation",
        "network_access" => "none"
      },
      "tolerances" => %{
        "entry_count" => 0,
        "maintenance_entry_count" => 0,
        "reserved_entry_count" => 0,
        "zero_capacity_entry_count" => 0,
        "reservation_entry_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external provider validation",
        "checks declared station-calendar entries, reservation metadata, and no-provider-write boundary only"
      ]
    },
    "fixture.artifact.resource_filter_report.v1" => %{
      "id" => "fixture.artifact.resource_filter_report.v1",
      "model_id" => "artifact.resource_filter_report.v1",
      "reference_case" => "checked-in resource filter artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/resource_filter_report_v1.json",
        "contract" => "resource_filter_report.v1"
      },
      "expected" => %{
        "schema_contract" => "resource_filter_report.v1",
        "model" => "resource_summary_availability_and_margin_filter",
        "input_candidate_count" => 3,
        "kept_candidate_count" => 1,
        "suppressed_candidate_count" => 2,
        "suppressed_candidate_row_count" => 2,
        "invalid_candidate_input_count" => 0,
        "duplicate_suppressed_candidate_id_count" => 0,
        "duplicate_suppressed_candidate_row_count" => 0,
        "resource_source_quality_counts" => %{"operator_supplied" => 1},
        "resource_trust_boundary_status_counts" => %{"missing" => 1},
        "suppressed_resource_source_quality_counts" => %{"operator_supplied" => 2},
        "suppressed_resource_trust_boundary_status_counts" => %{"missing" => 2},
        "suppressed_reason_counts" => %{
          "downlink_margin_below_policy" => 1,
          "storage_margin_below_observe_policy" => 1
        },
        "suppressed_blocking_dimension_counts" => %{"downlink" => 1, "storage" => 1},
        "suppressed_candidate_ids_by_blocking_dimension" => %{
          "downlink" => ["leo_1_downlink_equator_prime_1"],
          "storage" => ["leo_1_observe_target_a_1"]
        },
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "input_candidate_count" => 0,
        "kept_candidate_count" => 0,
        "suppressed_candidate_count" => 0,
        "suppressed_candidate_row_count" => 0,
        "invalid_candidate_input_count" => 0,
        "duplicate_suppressed_candidate_id_count" => 0,
        "duplicate_suppressed_candidate_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not subsystem simulation validation",
        "checks resource filter counts, suppression routing maps, trust-boundary maps, and model-limit boundary only"
      ]
    },
    "fixture.artifact.resource_filter_summary.v1" => %{
      "id" => "fixture.artifact.resource_filter_summary.v1",
      "model_id" => "artifact.resource_filter_summary.v1",
      "reference_case" => "checked-in resource filter summary artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/resource_filter_summary_v1.json",
        "contract" => "resource_filter_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "resource_filter_summary.v1",
        "model" => "artifact_only_resource_filter_summary",
        "source_artifact_type" => "resource_filter_report.v1",
        "input_candidate_count" => 3,
        "kept_candidate_count" => 1,
        "suppressed_candidate_count" => 2,
        "suppression_review_status" => "review_required",
        "suppressed_candidate_ids" => "leo_1_downlink_equator_prime_1|leo_1_observe_target_a_1",
        "suppressed_reason_counts" => %{
          "downlink_margin_below_policy" => 1,
          "storage_margin_below_observe_policy" => 1
        },
        "suppressed_candidate_ids_by_reason" => %{
          "downlink_margin_below_policy" => ["leo_1_downlink_equator_prime_1"],
          "storage_margin_below_observe_policy" => ["leo_1_observe_target_a_1"]
        },
        "resource_blocking_dimension_counts" => %{"downlink" => 1, "storage" => 1},
        "suppressed_candidate_ids_by_resource_blocking_dimension" => %{
          "downlink" => ["leo_1_downlink_equator_prime_1"],
          "storage" => ["leo_1_observe_target_a_1"]
        },
        "suppressed_candidate_ids_by_scenario_id" => %{
          "leo_1" => ["leo_1_downlink_equator_prime_1", "leo_1_observe_target_a_1"]
        },
        "suppressed_resource_source_quality_counts" => %{"operator_supplied" => 2},
        "suppressed_candidate_ids_by_resource_source_quality" => %{
          "operator_supplied" => [
            "leo_1_downlink_equator_prime_1",
            "leo_1_observe_target_a_1"
          ]
        },
        "suppressed_resource_trust_boundary_status_counts" => %{"missing" => 2},
        "suppressed_candidate_ids_by_resource_trust_boundary_status" => %{
          "missing" => ["leo_1_downlink_equator_prime_1", "leo_1_observe_target_a_1"]
        },
        "invalid_candidate_input_count" => 0,
        "invalid_candidate_input_ids" => "",
        "invalid_resource_summary_input_count" => 0,
        "invalid_resource_summary_input_ids" => "",
        "duplicate_suppressed_candidate_id_count" => 0,
        "duplicate_suppressed_candidate_row_count" => 0,
        "review_row_count" => 2,
        "review_row_ids" => "leo_1_observe_target_a_1|leo_1_downlink_equator_prime_1",
        "model_limit_count" => 5,
        "execution_boundary" => "artifact_only_no_schedule_mutation",
        "assumption_source" => "resource_filter_report.v1",
        "operator_authority" => "not_granted_by_resource_filter_summary",
        "resource_state_propagation" => "not_performed",
        "no_schedule_mutation" => true,
        "no_resource_time_propagation" => true,
        "no_subsystem_simulation" => true
      },
      "tolerances" => %{
        "input_candidate_count" => 0,
        "kept_candidate_count" => 0,
        "suppressed_candidate_count" => 0,
        "invalid_candidate_input_count" => 0,
        "invalid_resource_summary_input_count" => 0,
        "duplicate_suppressed_candidate_id_count" => 0,
        "duplicate_suppressed_candidate_row_count" => 0,
        "review_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by resource_filter_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not subsystem simulation validation",
        "checks compact suppression counts, routing maps, review rows, and no-mutation/no-propagation boundaries only"
      ]
    },
    "fixture.artifact.resource_filter_report.stale_resource_summary_margins" => %{
      "id" => "fixture.artifact.resource_filter_report.stale_resource_summary_margins",
      "model_id" => "artifact.resource_filter_report.v1",
      "reference_case" => "generated stale derived-margin resource filter challenge",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_resource_filter_stale_derived_margin_fixture",
        "contract" => "resource_filter_report.v1"
      },
      "expected" => %{
        "schema_contract" => "resource_filter_report.v1",
        "model" => "resource_summary_availability_and_margin_filter",
        "input_candidate_count" => 1,
        "kept_candidate_count" => 1,
        "suppressed_candidate_count" => 0,
        "suppressed_candidate_row_count" => 0,
        "input_resource_summary_count" => 2,
        "valid_resource_summary_count" => 0,
        "invalid_resource_summary_input_count" => 2,
        "invalid_resource_summary_input_ids" => "sat_1|sat_2",
        "invalid_resource_summary_input_reasons" =>
          "stale_battery_state_of_charge|stale_storage_margin",
        "stale_battery_state_of_charge_count" => 1,
        "stale_storage_margin_count" => 1,
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "input_candidate_count" => 0,
        "kept_candidate_count" => 0,
        "suppressed_candidate_count" => 0,
        "suppressed_candidate_row_count" => 0,
        "input_resource_summary_count" => 0,
        "valid_resource_summary_count" => 0,
        "invalid_resource_summary_input_count" => 0,
        "stale_battery_state_of_charge_count" => 0,
        "stale_storage_margin_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not subsystem simulation validation",
        "checks stale explicit battery and storage derived-margin evidence does not suppress candidates"
      ]
    },
    "fixture.artifact.objective_satisfaction_report.v1" => %{
      "id" => "fixture.artifact.objective_satisfaction_report.v1",
      "model_id" => "artifact.objective_satisfaction_report.v1",
      "reference_case" => "checked-in objective satisfaction artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/objective_satisfaction_report_v1.json",
        "contract" => "objective_satisfaction_report.v1"
      },
      "expected" => %{
        "schema_contract" => "objective_satisfaction_report.v1",
        "model" => "campaign_v1_selected_activity_objective_summary",
        "source" => "campaign_plan.activities",
        "objective_count" => 4,
        "row_count" => 4,
        "selected_count_total" => 2,
        "satisfied_count_total" => 2,
        "required_count_total" => 4,
        "status_counts" => %{
          "no_candidate_window" => 1,
          "partial" => 1,
          "selected" => 1,
          "unmet" => 1
        },
        "objective_type_counts" => %{
          "downlink_completion" => 1,
          "target_commitment" => 2,
          "target_coverage" => 1
        },
        "objective_ids_by_status" => %{
          "no_candidate_window" => ["objective:target_commitment:target_b"],
          "partial" => ["objective:target_coverage"],
          "selected" => ["objective:target_commitment:target_a"],
          "unmet" => ["objective:downlink_completion"]
        },
        "execution_status" => "planned_not_executed",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "objective_count" => 0,
        "row_count" => 0,
        "selected_count_total" => 0,
        "satisfied_count_total" => 0,
        "required_count_total" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not objective-achievement validation",
        "checks objective satisfaction counts, status routing maps, planned-not-executed boundary, and model-limit boundary only"
      ]
    },
    "fixture.artifact.objective_tradeoff_report.v1" => %{
      "id" => "fixture.artifact.objective_tradeoff_report.v1",
      "model_id" => "artifact.objective_tradeoff_report.v1",
      "reference_case" => "checked-in objective tradeoff artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/objective_tradeoff_report_v1.json",
        "contract" => "objective_tradeoff_report.v1"
      },
      "expected" => %{
        "schema_contract" => "objective_tradeoff_report.v1",
        "model" => "ranked_timeline_score_term_tradeoffs",
        "objective" => "maximize weighted observation value and contact value",
        "ranking_count" => 1,
        "tradeoff_row_count" => 1,
        "score_term_key_count" => 7,
        "activity_count_total" => 1,
        "selected_observation_count_total" => 1,
        "selected_contact_count_total" => 0,
        "score_total" => 1417.2731832107565,
        "score_delta_from_selected_total" => 0.0,
        "scenario_ids_by_rank" => %{"1" => ["leo_1"]},
        "score_term_key_counts" => %{
          "activity_count_penalty" => 1,
          "activity_score" => 1,
          "contact_value" => 1,
          "eclipse_penalty" => 1,
          "selected_contact_count" => 1,
          "selected_observation_count" => 1,
          "target_value" => 1
        },
        "selection_assumption" => "best_ranked_timeline_is_selected",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "ranking_count" => 0,
        "tradeoff_row_count" => 0,
        "score_term_key_count" => 0,
        "activity_count_total" => 0,
        "selected_observation_count_total" => 0,
        "selected_contact_count_total" => 0,
        "score_total" => 0.0,
        "score_delta_from_selected_total" => 0.0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not optimizer validation",
        "checks objective tradeoff counts, score-term shape, selected-ranking assumptions, and model-limit boundary only"
      ]
    },
    "fixture.artifact.score_term_report.v1" => %{
      "id" => "fixture.artifact.score_term_report.v1",
      "model_id" => "artifact.score_term_report.v1",
      "reference_case" => "checked-in score term artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/score_term_report_v1.json",
        "contract" => "score_term_report.v1"
      },
      "expected" => %{
        "schema_contract" => "score_term_report.v1",
        "model" => "ranked_timeline_score_terms",
        "source" => "campaign_plan.ranked_timelines",
        "row_count" => 7,
        "derived_row_count" => 7,
        "selected_row_count" => 7,
        "score_term_key_count" => 7,
        "score_term_key_counts" => %{
          "activity_count_penalty" => 1,
          "activity_score" => 1,
          "contact_value" => 1,
          "eclipse_penalty" => 1,
          "selected_contact_count" => 1,
          "selected_observation_count" => 1,
          "target_value" => 1
        },
        "row_derived_score_term_key_counts" => %{
          "activity_count_penalty" => 1,
          "activity_score" => 1,
          "contact_value" => 1,
          "eclipse_penalty" => 1,
          "selected_contact_count" => 1,
          "selected_observation_count" => 1,
          "target_value" => 1
        },
        "term_value_total" => 2835.546366421513,
        "timeline_score_total" => 9920.912282475295,
        "score_term_source" => "ranked_timeline.score_terms",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "row_count" => 0,
        "derived_row_count" => 0,
        "selected_row_count" => 0,
        "score_term_key_count" => 0,
        "term_value_total" => 0.0,
        "timeline_score_total" => 0.0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not score-policy validation",
        "checks score-term row counts, key shape, selected-row counts, score totals, and model-limit boundary only"
      ]
    },
    "fixture.artifact.ranking_comparison_report.v1" => %{
      "id" => "fixture.artifact.ranking_comparison_report.v1",
      "model_id" => "artifact.ranking_comparison_report.v1",
      "reference_case" => "checked-in ranking comparison artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/ranking_comparison_report_v1.json",
        "contract" => "ranking_comparison_report.v1"
      },
      "expected" => %{
        "schema_contract" => "ranking_comparison_report.v1",
        "model" => "scenario_ranking_pairwise_delta",
        "source" => "study_benchmark.rankings",
        "objective" => "final_radius_km",
        "objective_direction" => "maximize",
        "left_count" => 2,
        "right_count" => 2,
        "matched_count" => 1,
        "left_only_count" => 1,
        "right_only_count" => 1,
        "row_count" => 3,
        "derived_row_count" => 3,
        "status_counts" => %{"left_only" => 1, "matched" => 1, "right_only" => 1},
        "scenario_ids_by_status" => %{
          "left_only" => ["burn_a"],
          "matched" => ["burn_b"],
          "right_only" => ["burn_c"]
        },
        "rank_delta_total" => 1,
        "value_delta_total" => 15,
        "winner_changed" => true,
        "external_solver" => false,
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "left_count" => 0,
        "right_count" => 0,
        "matched_count" => 0,
        "left_only_count" => 0,
        "right_only_count" => 0,
        "row_count" => 0,
        "derived_row_count" => 0,
        "rank_delta_total" => 0,
        "value_delta_total" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not optimizer validation",
        "checks ranking comparison counts, status routing, winner-change evidence, and model-limit boundary only"
      ]
    },
    "fixture.artifact.strategy_branch.v1" => %{
      "id" => "fixture.artifact.strategy_branch.v1",
      "model_id" => "artifact.strategy_branch.v1",
      "reference_case" => "checked-in standalone V3 strategy branch artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/strategy_branch_v1.json",
        "contract" => "strategy_branch.v1"
      },
      "expected" => %{
        "schema_contract" => "strategy_branch.v1",
        "branch_id" => "derived_urgent_target_target_hot",
        "label" => "Derived urgent target target_hot",
        "probability" => 1.0,
        "event_count" => 2,
        "event_type_counts" => %{"downlink_completion_gap" => 1, "urgent_target" => 1},
        "candidate_activity_count" => 0,
        "strategic_addition_count" => 0,
        "capacity_adjustment_count" => 0,
        "repair_delta_count" => 0,
        "approval_requirement_count" => 0,
        "policy_classification" => "operator_review_required",
        "policy_risk_count" => 1,
        "score" => 2835.3981832107565,
        "score_term_count" => 4,
        "warning_count" => 1,
        "risk_count" => 1,
        "approval_status" => "operator_review_required",
        "derived_source" => "mission_state.objectives",
        "tradeoff_count" => 1,
        "downlink_capacity_margin" => 0.62
      },
      "tolerances" => %{
        "probability" => 0.0,
        "event_count" => 0,
        "candidate_activity_count" => 0,
        "strategic_addition_count" => 0,
        "capacity_adjustment_count" => 0,
        "repair_delta_count" => 0,
        "approval_requirement_count" => 0,
        "policy_risk_count" => 0,
        "score" => 0.0,
        "score_term_count" => 0,
        "warning_count" => 0,
        "risk_count" => 0,
        "tradeoff_count" => 0,
        "downlink_capacity_margin" => 0.0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external strategy validation",
        "checks standalone branch event/risk/score routing only"
      ]
    },
    "fixture.artifact.strategy_recommendation.v1" => %{
      "id" => "fixture.artifact.strategy_recommendation.v1",
      "model_id" => "artifact.strategy_recommendation.v1",
      "reference_case" => "checked-in standalone V3 strategy recommendation artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/strategy_recommendation_v1.json",
        "contract" => "strategy_recommendation.v1"
      },
      "expected" => %{
        "schema_contract" => "strategy_recommendation.v1",
        "status" => "pass",
        "recommended_branch_id" => "derived_urgent_target_target_hot",
        "approval_status" => "operator_review_required",
        "reason" => "best_expected_score_requiring_operator_review",
        "ranked_branch_count" => 4,
        "ranked_branch_id_order" =>
          "derived_urgent_target_target_hot|derived_target_revisit_target_hot|derived_combined_mission_state|operator_placeholder_urgent",
        "tradeoff_count" => 3,
        "explanation_count" => 4,
        "risk_count" => 2,
        "approval_requirement_count" => 1,
        "requires_operator_review_count" => 1,
        "branch_event_summary_count" => 1,
        "branch_event_type_counts" => %{"urgent_target" => 1},
        "branch_requires_operator_review" => true
      },
      "tolerances" => %{
        "ranked_branch_count" => 0,
        "tradeoff_count" => 0,
        "explanation_count" => 0,
        "risk_count" => 0,
        "approval_requirement_count" => 0,
        "requires_operator_review_count" => 0,
        "branch_event_summary_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external strategy validation",
        "checks standalone recommendation ranking/review routing only"
      ]
    },
    "fixture.artifact.study_benchmark.v1" => %{
      "id" => "fixture.artifact.study_benchmark.v1",
      "model_id" => "artifact.study_benchmark.v1",
      "reference_case" => "checked-in persisted study benchmark artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/study_benchmark.json",
        "contract" => "study_benchmark.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "benchmark_mode_count" => 1,
        "repetition_count" => 2,
        "result_count" => 2,
        "local_result_count" => 2,
        "matches_baseline_count" => 2,
        "failure_count_total" => 0,
        "scenario_count_total" => 8,
        "trajectory_count_total" => 8,
        "manifest_path" => "studies/raise_apogee_search.json",
        "manifest_sha256_length" => 64,
        "max_duration_ms" => 3
      },
      "tolerances" => %{
        "schema_version" => 0,
        "benchmark_mode_count" => 0,
        "repetition_count" => 0,
        "result_count" => 0,
        "local_result_count" => 0,
        "matches_baseline_count" => 0,
        "failure_count_total" => 0,
        "scenario_count_total" => 0,
        "trajectory_count_total" => 0,
        "manifest_sha256_length" => 0,
        "max_duration_ms" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not performance certification",
        "checks persisted benchmark shape, counts, and baseline-match metadata only"
      ]
    },
    "fixture.artifact.study_benchmark.distributed_concurrency_sweep" => %{
      "id" => "fixture.artifact.study_benchmark.distributed_concurrency_sweep",
      "model_id" => "artifact.study_benchmark.v1",
      "reference_case" => "checked-in distributed concurrency sweep benchmark artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/distributed_concurrency_sweep.json",
        "contract" => "study_benchmark.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "benchmark_mode_count" => 2,
        "repetition_count" => 3,
        "result_count" => 108,
        "local_result_count" => 54,
        "distributed_result_count" => 54,
        "matches_baseline_count" => 108,
        "failure_count_total" => 0,
        "scenario_count_total" => 1_188_000,
        "trajectory_count_total" => 1_188_000,
        "manifest_path" => "studies/leo_dispersion_monte_carlo.json",
        "manifest_sha256_length" => 64,
        "max_duration_ms" => 3_352,
        "backend_count" => 0,
        "propagator_option_count" => 0,
        "monte_carlo_count_option_count" => 2,
        "max_concurrency_option_count" => 3,
        "task_chunk_size_option_count" => 3
      },
      "tolerances" => %{
        "schema_version" => 0,
        "benchmark_mode_count" => 0,
        "repetition_count" => 0,
        "result_count" => 0,
        "local_result_count" => 0,
        "distributed_result_count" => 0,
        "matches_baseline_count" => 0,
        "failure_count_total" => 0,
        "scenario_count_total" => 0,
        "trajectory_count_total" => 0,
        "manifest_sha256_length" => 0,
        "max_duration_ms" => 0,
        "backend_count" => 0,
        "propagator_option_count" => 0,
        "monte_carlo_count_option_count" => 0,
        "max_concurrency_option_count" => 0,
        "task_chunk_size_option_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not performance certification",
        "checks distributed/local benchmark rows, option sweep shape, and baseline-match metadata only"
      ]
    },
    "fixture.artifact.study_benchmark.distributed_chunk_sweep" => %{
      "id" => "fixture.artifact.study_benchmark.distributed_chunk_sweep",
      "model_id" => "artifact.study_benchmark.v1",
      "reference_case" => "checked-in distributed chunk sweep benchmark artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/distributed_chunk_sweep.json",
        "contract" => "study_benchmark.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "benchmark_mode_count" => 2,
        "repetition_count" => 3,
        "result_count" => 72,
        "local_result_count" => 36,
        "distributed_result_count" => 36,
        "matches_baseline_count" => 72,
        "failure_count_total" => 0,
        "scenario_count_total" => 792_000,
        "manifest_path" => "studies/leo_dispersion_monte_carlo.json",
        "manifest_sha256_length" => 64,
        "max_duration_ms" => 4_000,
        "monte_carlo_count_option_count" => 2,
        "task_chunk_size_option_count" => 6
      },
      "tolerances" => %{
        "schema_version" => 0,
        "benchmark_mode_count" => 0,
        "repetition_count" => 0,
        "result_count" => 0,
        "local_result_count" => 0,
        "distributed_result_count" => 0,
        "matches_baseline_count" => 0,
        "failure_count_total" => 0,
        "scenario_count_total" => 0,
        "manifest_sha256_length" => 0,
        "max_duration_ms" => 0,
        "monte_carlo_count_option_count" => 0,
        "task_chunk_size_option_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not performance certification",
        "checks distributed chunk sweep rows, option shape, and baseline-match metadata only"
      ]
    },
    "fixture.artifact.study_benchmark.distributed_monte_carlo_scaling" => %{
      "id" => "fixture.artifact.study_benchmark.distributed_monte_carlo_scaling",
      "model_id" => "artifact.study_benchmark.v1",
      "reference_case" => "checked-in distributed Monte Carlo scaling benchmark artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/distributed_monte_carlo_scaling.json",
        "contract" => "study_benchmark.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "benchmark_mode_count" => 2,
        "repetition_count" => 3,
        "result_count" => 18,
        "local_result_count" => 9,
        "distributed_result_count" => 9,
        "matches_baseline_count" => 18,
        "failure_count_total" => 0,
        "scenario_count_total" => 133_200,
        "trajectory_count_total" => 133_200,
        "manifest_path" => "studies/leo_dispersion_monte_carlo.json",
        "manifest_sha256_length" => 64,
        "max_duration_ms" => 3_289,
        "backend_count" => 0,
        "propagator_option_count" => 0,
        "monte_carlo_count_option_count" => 3,
        "max_concurrency_option_count" => 0,
        "task_chunk_size_option_count" => 0
      },
      "tolerances" => %{
        "schema_version" => 0,
        "benchmark_mode_count" => 0,
        "repetition_count" => 0,
        "result_count" => 0,
        "local_result_count" => 0,
        "distributed_result_count" => 0,
        "matches_baseline_count" => 0,
        "failure_count_total" => 0,
        "scenario_count_total" => 0,
        "trajectory_count_total" => 0,
        "manifest_sha256_length" => 0,
        "max_duration_ms" => 0,
        "backend_count" => 0,
        "propagator_option_count" => 0,
        "monte_carlo_count_option_count" => 0,
        "max_concurrency_option_count" => 0,
        "task_chunk_size_option_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not performance certification",
        "checks distributed/local Monte Carlo benchmark rows, option sweep shape, and baseline-match metadata only"
      ]
    },
    "fixture.artifact.study_benchmark.distributed_diagnostic_sweep" => %{
      "id" => "fixture.artifact.study_benchmark.distributed_diagnostic_sweep",
      "model_id" => "artifact.study_benchmark.v1",
      "reference_case" => "checked-in distributed diagnostic sweep benchmark artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/distributed_diagnostic_sweep.json",
        "contract" => "study_benchmark.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "benchmark_mode_count" => 2,
        "repetition_count" => 3,
        "result_count" => 36,
        "local_result_count" => 12,
        "distributed_result_count" => 24,
        "matches_baseline_count" => 36,
        "failure_count_total" => 0,
        "scenario_count_total" => 396_000,
        "manifest_path" => "studies/leo_dispersion_monte_carlo.json",
        "manifest_sha256_length" => 64,
        "max_duration_ms" => 2_074,
        "monte_carlo_count_option_count" => 2,
        "max_concurrency_option_count" => 2,
        "task_chunk_size_option_count" => 2
      },
      "tolerances" => %{
        "schema_version" => 0,
        "benchmark_mode_count" => 0,
        "repetition_count" => 0,
        "result_count" => 0,
        "local_result_count" => 0,
        "distributed_result_count" => 0,
        "matches_baseline_count" => 0,
        "failure_count_total" => 0,
        "scenario_count_total" => 0,
        "manifest_sha256_length" => 0,
        "max_duration_ms" => 0,
        "monte_carlo_count_option_count" => 0,
        "max_concurrency_option_count" => 0,
        "task_chunk_size_option_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not performance certification",
        "checks distributed diagnostic sweep rows, option shape, and baseline-match metadata only"
      ]
    },
    "fixture.artifact.study_benchmark.distributed_monte_carlo_chunked" => %{
      "id" => "fixture.artifact.study_benchmark.distributed_monte_carlo_chunked",
      "model_id" => "artifact.study_benchmark.v1",
      "reference_case" => "checked-in distributed Monte Carlo chunked benchmark artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/distributed_monte_carlo_chunked.json",
        "contract" => "study_benchmark.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "benchmark_mode_count" => 2,
        "repetition_count" => 3,
        "result_count" => 18,
        "local_result_count" => 9,
        "distributed_result_count" => 9,
        "matches_baseline_count" => 18,
        "failure_count_total" => 0,
        "scenario_count_total" => 133_200,
        "manifest_path" => "studies/leo_dispersion_monte_carlo.json",
        "manifest_sha256_length" => 64,
        "max_duration_ms" => 2_241,
        "monte_carlo_count_option_count" => 3
      },
      "tolerances" => %{
        "schema_version" => 0,
        "benchmark_mode_count" => 0,
        "repetition_count" => 0,
        "result_count" => 0,
        "local_result_count" => 0,
        "distributed_result_count" => 0,
        "matches_baseline_count" => 0,
        "failure_count_total" => 0,
        "scenario_count_total" => 0,
        "manifest_sha256_length" => 0,
        "max_duration_ms" => 0,
        "monte_carlo_count_option_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not performance certification",
        "checks distributed Monte Carlo chunked rows, option shape, and baseline-match metadata only"
      ]
    },
    "fixture.artifact.study_benchmark.monte_carlo_scaling" => %{
      "id" => "fixture.artifact.study_benchmark.monte_carlo_scaling",
      "model_id" => "artifact.study_benchmark.v1",
      "reference_case" => "checked-in local Monte Carlo scaling benchmark artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/monte_carlo_scaling.json",
        "contract" => "study_benchmark.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "benchmark_mode_count" => 1,
        "repetition_count" => 1,
        "result_count" => 2,
        "local_result_count" => 2,
        "distributed_result_count" => 0,
        "matches_baseline_count" => 2,
        "failure_count_total" => 0,
        "scenario_count_total" => 220,
        "manifest_path" => "studies/leo_dispersion_monte_carlo.json",
        "manifest_sha256_length" => 64,
        "max_duration_ms" => 16,
        "monte_carlo_count_option_count" => 2
      },
      "tolerances" => %{
        "schema_version" => 0,
        "benchmark_mode_count" => 0,
        "repetition_count" => 0,
        "result_count" => 0,
        "local_result_count" => 0,
        "distributed_result_count" => 0,
        "matches_baseline_count" => 0,
        "failure_count_total" => 0,
        "scenario_count_total" => 0,
        "manifest_sha256_length" => 0,
        "max_duration_ms" => 0,
        "monte_carlo_count_option_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not performance certification",
        "checks local Monte Carlo scaling rows, option shape, and baseline-match metadata only"
      ]
    },
    "fixture.artifact.study_benchmark.nx_study_benchmark" => %{
      "id" => "fixture.artifact.study_benchmark.nx_study_benchmark",
      "model_id" => "artifact.study_benchmark.v1",
      "reference_case" => "checked-in Nx study benchmark artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/nx_study_benchmark.json",
        "contract" => "study_benchmark.v1"
      },
      "expected" => %{
        "schema_version" => 1,
        "benchmark_mode_count" => 1,
        "repetition_count" => 2,
        "result_count" => 12,
        "local_result_count" => 12,
        "distributed_result_count" => 0,
        "matches_baseline_count" => 12,
        "failure_count_total" => 0,
        "scenario_count_total" => 13_200,
        "trajectory_count_total" => 13_200,
        "manifest_path" => "studies/leo_dispersion_monte_carlo.json",
        "manifest_sha256_length" => 64,
        "max_duration_ms" => 67_760,
        "backend_count" => 3,
        "propagator_option_count" => 3,
        "monte_carlo_count_option_count" => 2,
        "max_concurrency_option_count" => 0,
        "task_chunk_size_option_count" => 0
      },
      "tolerances" => %{
        "schema_version" => 0,
        "benchmark_mode_count" => 0,
        "repetition_count" => 0,
        "result_count" => 0,
        "local_result_count" => 0,
        "distributed_result_count" => 0,
        "matches_baseline_count" => 0,
        "failure_count_total" => 0,
        "scenario_count_total" => 0,
        "trajectory_count_total" => 0,
        "manifest_sha256_length" => 0,
        "max_duration_ms" => 0,
        "backend_count" => 0,
        "propagator_option_count" => 0,
        "monte_carlo_count_option_count" => 0,
        "max_concurrency_option_count" => 0,
        "task_chunk_size_option_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not performance certification",
        "checks Nx benchmark backend coverage, option shape, and baseline-match metadata only"
      ]
    },
    "fixture.artifact.schema_validation_report.v1" => %{
      "id" => "fixture.artifact.schema_validation_report.v1",
      "model_id" => "artifact.schema_validation_report.v1",
      "reference_case" => "checked-in schema validation report artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/schema_validation_report_v1.json",
        "contract" => "schema_validation_report.v1",
        "validated_contract" => "campaign_plan.v1"
      },
      "expected" => %{
        "schema_contract" => "schema_validation_report.v1",
        "model" => "executable_artifact_contract_validation",
        "validation_mode" => "artifact_file",
        "artifact_path" => "study_results/leo_constellation_campaign.json",
        "validated_contract" => "campaign_plan.v1",
        "validated_artifact_family" => "campaign_plan",
        "validated_schema_version" => 1,
        "status" => "pass",
        "error_count" => 0,
        "warning_count" => 0,
        "remediation_count" => 0,
        "error_row_count" => 0,
        "warning_row_count" => 0,
        "remediation_row_count" => 0,
        "model_limit_count" => 3
      },
      "tolerances" => %{
        "validated_schema_version" => 0,
        "error_count" => 0,
        "warning_count" => 0,
        "remediation_count" => 0,
        "error_row_count" => 0,
        "warning_row_count" => 0,
        "remediation_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external schema validator certification",
        "checks executable schema-validation report counts and model-limit boundary only"
      ]
    },
    "fixture.artifact.schema_validation_batch_report.v1" => %{
      "id" => "fixture.artifact.schema_validation_batch_report.v1",
      "model_id" => "artifact.schema_validation_batch_report.v1",
      "reference_case" => "checked-in schema validation batch report artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/schema_validation_batch_report_v1.json",
        "contract" => "schema_validation_batch_report.v1",
        "input_dir" => "study_results"
      },
      "expected" => %{
        "schema_contract" => "schema_validation_batch_report.v1",
        "model" => "executable_artifact_contract_batch_validation",
        "validation_mode" => "artifact_directory",
        "input_dir" => "study_results",
        "status" => "pass",
        "status_counts" => %{"pass" => 155},
        "file_count" => 155,
        "artifact_count" => 155,
        "skipped_count" => 0,
        "error_count" => 0,
        "warning_count" => 0,
        "remediation_count" => 0,
        "report_count" => 155,
        "pass_report_count" => 155,
        "fail_report_count" => 0,
        "skipped_artifact_count" => 0,
        "model_limit_count" => 3
      },
      "tolerances" => %{
        "file_count" => 0,
        "artifact_count" => 0,
        "skipped_count" => 0,
        "error_count" => 0,
        "warning_count" => 0,
        "remediation_count" => 0,
        "report_count" => 0,
        "pass_report_count" => 0,
        "fail_report_count" => 0,
        "skipped_artifact_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not an external compatibility suite",
        "checks batch validation counts, status count maps, and model-limit boundary only"
      ]
    },
    "fixture.artifact.schema_migration_report.deprecated_campaign_plan" => %{
      "id" => "fixture.artifact.schema_migration_report.deprecated_campaign_plan",
      "model_id" => "artifact.schema_migration_report.v1",
      "reference_case" =>
        "checked-in schema migration report with campaign-plan deprecation hint",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/schema_migration_report_v1.json",
        "contract" => "schema_migration_report.v1"
      },
      "expected" => %{
        "schema_contract" => "schema_migration_report.v1",
        "schema_version" => 1,
        "model" => "executable_schema_migration_and_deprecation_report",
        "source" => "orbital_dynamics.schema_registry",
        "status" => "review_required",
        "compatibility_policy_version" => 1,
        "compatible_change_rule_count" => 3,
        "breaking_change_rule_count" => 5,
        "contract_count" => 121,
        "current_contract_count" => 120,
        "deprecated_contract_count" => 1,
        "future_contract_count" => 0,
        "migration_row_count" => 121,
        "deprecation_warning_count" => 1,
        "row_derived_contract_count" => 121,
        "status_counts" => %{"current" => 120, "deprecated" => 1},
        "row_derived_status_counts" => %{"current" => 120, "deprecated" => 1},
        "migration_action_counts" => %{
          "continue_current_contract" => 120,
          "plan_replacement" => 1
        },
        "row_derived_migration_action_counts" => %{
          "continue_current_contract" => 120,
          "plan_replacement" => 1
        },
        "deprecated_contracts" => "campaign_plan.v1",
        "replacement_contracts" => "campaign_strategy.v3",
        "execution_boundary" => "artifact_only_no_schema_rewrite",
        "migration_authority" => "not_granted_by_report",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "schema_version" => 0,
        "compatibility_policy_version" => 0,
        "compatible_change_rule_count" => 0,
        "breaking_change_rule_count" => 0,
        "contract_count" => 0,
        "current_contract_count" => 0,
        "deprecated_contract_count" => 0,
        "future_contract_count" => 0,
        "migration_row_count" => 0,
        "deprecation_warning_count" => 0,
        "row_derived_contract_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not automatic schema migration",
        "checks schema registry/deprecation rollups and report-only migration boundary"
      ]
    },
    "fixture.artifact.schema_migration_report.future_campaign_plan" => %{
      "id" => "fixture.artifact.schema_migration_report.future_campaign_plan",
      "model_id" => "artifact.schema_migration_report.v1",
      "reference_case" => "generated schema migration report with campaign-plan future hint",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source" => "generated_schema_migration_future_contract_fixture",
        "contract" => "schema_migration_report.v1"
      },
      "expected" => %{
        "schema_contract" => "schema_migration_report.v1",
        "schema_version" => 1,
        "model" => "executable_schema_migration_and_deprecation_report",
        "source" => "orbital_dynamics.schema_registry",
        "status" => "review_required",
        "compatibility_policy_version" => 1,
        "compatible_change_rule_count" => 3,
        "breaking_change_rule_count" => 5,
        "contract_count" => 122,
        "current_contract_count" => 121,
        "deprecated_contract_count" => 0,
        "future_contract_count" => 1,
        "migration_row_count" => 122,
        "deprecation_warning_count" => 0,
        "row_derived_contract_count" => 122,
        "status_counts" => %{"current" => 121, "future" => 1},
        "row_derived_status_counts" => %{"current" => 121, "future" => 1},
        "migration_action_counts" => %{
          "continue_current_contract" => 121,
          "prepare_future_contract" => 1
        },
        "row_derived_migration_action_counts" => %{
          "continue_current_contract" => 121,
          "prepare_future_contract" => 1
        },
        "deprecated_contracts" => "",
        "replacement_contracts" => "",
        "execution_boundary" => "artifact_only_no_schema_rewrite",
        "migration_authority" => "not_granted_by_report",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "schema_version" => 0,
        "compatibility_policy_version" => 0,
        "compatible_change_rule_count" => 0,
        "breaking_change_rule_count" => 0,
        "contract_count" => 0,
        "current_contract_count" => 0,
        "deprecated_contract_count" => 0,
        "future_contract_count" => 0,
        "migration_row_count" => 0,
        "deprecation_warning_count" => 0,
        "row_derived_contract_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal generated artifact regression, not automatic schema migration",
        "checks future-contract rollups and report-only migration boundary"
      ]
    },
    "fixture.artifact.cadence_import_manifest.resource_pressure_v1" => %{
      "id" => "fixture.artifact.cadence_import_manifest.resource_pressure_v1",
      "model_id" => "artifact.cadence_import_manifest.v1",
      "reference_case" => "checked-in resource-pressure Cadence import manifest artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/cadence_import_resource_pressure_v1.json",
        "contract" => "cadence_import_manifest.v1"
      },
      "expected" => %{
        "schema_contract" => "cadence_import_manifest.v1",
        "model" => "artifact_only_cadence_import_manifest",
        "manifest_id" =>
          "cadence_import_manifest:operational_readiness:resource_projection_report.v1:resource_summaries",
        "source_artifact_type" => "operational_readiness_report.v1",
        "source_artifact_id" =>
          "operational_readiness:resource_projection_report.v1:resource_summaries",
        "row_count" => 4,
        "ready_count" => 0,
        "row_derived_ready_count" => 0,
        "blocked_count" => 0,
        "row_derived_blocked_count" => 0,
        "review_required_count" => 4,
        "missing_import_count" => 0,
        "row_derived_missing_import_count" => 0,
        "source_review_count" => 4,
        "import_status_counts" => %{"review_required_before_import" => 4},
        "row_derived_import_status_counts" => %{"review_required_before_import" => 4},
        "import_action_counts" => %{"review_operational_readiness" => 4},
        "row_derived_import_action_counts" => %{"review_operational_readiness" => 4},
        "cadence_import_status_counts" => %{"present" => 4},
        "row_derived_cadence_import_status_counts" => %{"present" => 4},
        "required_operator_action_counts" => %{"review_operational_readiness" => 4},
        "row_derived_required_operator_action_counts" => %{
          "review_operational_readiness" => 4
        },
        "source_review_type_counts" => %{"operational_readiness_review" => 4},
        "row_derived_source_review_type_counts" => %{
          "operational_readiness_review" => 4
        },
        "import_side_counts" => %{"source" => 4},
        "row_derived_import_side_counts" => %{"source" => 4},
        "source_review_queue_counts" => %{
          "operational_readiness_review|review_operational_readiness|operator_review_required" =>
            4
        },
        "row_derived_source_review_queue_counts" => %{
          "operational_readiness_review|review_operational_readiness|operator_review_required" =>
            4
        },
        "resource_availability_import_row_count" => 2,
        "row_derived_resource_availability_pressure_count" => 4,
        "row_derived_resource_availability_reason_counts" => %{
          "antenna_unavailable" => 2,
          "payload_unavailable" => 2
        },
        "row_derived_resource_availability_reason_keys" =>
          "antenna_unavailable|payload_unavailable",
        "row_derived_unavailable_resource_reason_keys" =>
          "antenna_unavailable|payload_unavailable",
        "execution_boundary" => "artifact_only_no_cadence_api_writes",
        "authorization_boundary" => "operator_review_or_cadence_adapter_must_authorize_import",
        "model_limit_count" => 4
      },
      "tolerances" => %{
        "row_count" => 0,
        "ready_count" => 0,
        "row_derived_ready_count" => 0,
        "blocked_count" => 0,
        "row_derived_blocked_count" => 0,
        "review_required_count" => 0,
        "missing_import_count" => 0,
        "row_derived_missing_import_count" => 0,
        "source_review_count" => 0,
        "resource_availability_import_row_count" => 0,
        "row_derived_resource_availability_pressure_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external Cadence API validation",
        "checks resource-pressure import routing and no-write authorization boundary only"
      ]
    },
    "fixture.artifact.operational_readiness_report.resource_pressure_v1" => %{
      "id" => "fixture.artifact.operational_readiness_report.resource_pressure_v1",
      "model_id" => "artifact.operational_readiness_report.v1",
      "reference_case" => "checked-in resource-pressure operational readiness artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/operational_readiness_resource_pressure_v1.json",
        "contract" => "operational_readiness_report.v1"
      },
      "expected" => %{
        "schema_contract" => "operational_readiness_report.v1",
        "model" => "artifact_only_operational_readiness_classifier",
        "report_id" => "operational_readiness:resource_projection_report.v1:resource_summaries",
        "source_artifact_type" => "resource_projection_report.v1",
        "source_artifact_id" => "resource_summaries",
        "readiness_level" => "operator_review",
        "import_classification" => "review_only",
        "status" => "review_required",
        "gate_count" => 6,
        "row_derived_gate_count" => 6,
        "passed_gate_count" => 3,
        "row_derived_passed_gate_count" => 3,
        "review_gate_count" => 3,
        "row_derived_review_gate_count" => 3,
        "analysis_gate_count" => 0,
        "row_derived_analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "row_derived_blocked_gate_count" => 0,
        "row_derived_gate_status_counts" => %{
          "passed" => 3,
          "review_required" => 3
        },
        "row_derived_gate_classification_counts" => %{
          "importable" => 3,
          "review_only" => 3
        },
        "review_row_count" => 1,
        "import_row_count" => 1,
        "ready_for_import_count" => 0,
        "row_derived_ready_for_import_count" => 0,
        "manifest_review_required_count" => 1,
        "row_derived_manifest_review_required_count" => 0,
        "blocked_import_count" => 0,
        "row_derived_blocked_import_count" => 0,
        "missing_import_count" => 0,
        "row_derived_missing_import_count" => 0,
        "invalid_cadence_import_count" => 0,
        "row_derived_invalid_cadence_import_count" => 0,
        "import_status_counts" => %{"review_required_before_import" => 1},
        "row_derived_import_status_counts" => %{},
        "cadence_import_status_counts" => %{"present" => 1},
        "row_derived_cadence_import_status_counts" => %{},
        "resource_availability_pressure_count" => 2,
        "row_derived_resource_availability_pressure_count" => 2,
        "resource_availability_reason_counts" => %{
          "antenna_unavailable" => 1,
          "payload_unavailable" => 1
        },
        "row_derived_resource_availability_reason_counts" => %{
          "antenna_unavailable" => 1,
          "payload_unavailable" => 1
        },
        "resource_availability_reason_keys" => "antenna_unavailable|payload_unavailable",
        "row_derived_resource_availability_reason_keys" =>
          "antenna_unavailable|payload_unavailable",
        "unavailable_resource_reason_keys" => "antenna_unavailable|payload_unavailable",
        "row_derived_unavailable_resource_reason_keys" =>
          "antenna_unavailable|payload_unavailable",
        "source_model_count" => 1,
        "source_model_limit_count" => 9,
        "adapter_context_count" => 0,
        "adapter_trust_boundary_missing_count" => 0
      },
      "tolerances" => %{
        "gate_count" => 0,
        "row_derived_gate_count" => 0,
        "passed_gate_count" => 0,
        "row_derived_passed_gate_count" => 0,
        "review_gate_count" => 0,
        "row_derived_review_gate_count" => 0,
        "resource_availability_pressure_count" => 0,
        "row_derived_resource_availability_pressure_count" => 0,
        "source_model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks resource-pressure readiness classification and no-execution boundary only"
      ]
    },
    "fixture.artifact.operator_review_package.resource_pressure_v1" => %{
      "id" => "fixture.artifact.operator_review_package.resource_pressure_v1",
      "model_id" => "artifact.operator_review_package.v1",
      "reference_case" => "checked-in resource-pressure operator review artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/operator_review_resource_pressure_v1.json",
        "contract" => "operator_review_package.v1"
      },
      "expected" => %{
        "schema_contract" => "operator_review_package.v1",
        "model" => "artifact_only_operator_review_package",
        "review_count" => 4,
        "row_derived_review_count" => 4,
        "approval_requirement_count" => 0,
        "policy_escalation_count" => 0,
        "realized_feedback_count" => 0,
        "resource_projection_review_count" => 0,
        "resource_suppression_count" => 0,
        "contact_suppression_count" => 0,
        "link_capacity_review_count" => 0,
        "timeline_diff_count" => 0,
        "row_derived_review_type_counts" => %{"operational_readiness_review" => 4},
        "row_derived_required_operator_action_counts" => %{
          "review_operational_readiness" => 4
        },
        "row_derived_review_queue_counts" => %{
          "operational_readiness_review|review_operational_readiness|operator_review_required" =>
            4
        },
        "resource_availability_review_row_count" => 2,
        "row_derived_resource_availability_pressure_count" => 4,
        "row_derived_resource_availability_reason_counts" => %{
          "antenna_unavailable" => 2,
          "payload_unavailable" => 2
        },
        "row_derived_resource_availability_reason_keys" =>
          "antenna_unavailable|payload_unavailable",
        "row_derived_unavailable_resource_reason_keys" =>
          "antenna_unavailable|payload_unavailable"
      },
      "tolerances" => %{
        "review_count" => 0,
        "row_derived_review_count" => 0,
        "resource_availability_review_row_count" => 0,
        "row_derived_resource_availability_pressure_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operator workflow validation",
        "checks resource-pressure review routing and artifact-only review boundary only"
      ]
    },
    "fixture.artifact.quality_gate_report.resource_pressure_v1" => %{
      "id" => "fixture.artifact.quality_gate_report.resource_pressure_v1",
      "model_id" => "artifact.quality_gate_report.v1",
      "reference_case" => "checked-in resource-pressure quality gate artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/quality_gate_resource_pressure_v1.json",
        "contract" => "quality_gate_report.v1"
      },
      "expected" => %{
        "schema_contract" => "quality_gate_report.v1",
        "model" => "artifact_only_operational_quality_gate_report",
        "report_id" => "quality_gate:resource_projection_report.v1:resource_summaries",
        "source_artifact_type" => "resource_projection_report.v1",
        "source_artifact_id" => "resource_summaries",
        "source_readiness_report_id" =>
          "operational_readiness:resource_projection_report.v1:resource_summaries",
        "readiness_level" => "operator_review",
        "import_classification" => "review_only",
        "status" => "review_required",
        "gate_count" => 6,
        "row_derived_gate_count" => 6,
        "passed_gate_count" => 3,
        "row_derived_passed_gate_count" => 3,
        "review_gate_count" => 3,
        "row_derived_review_gate_count" => 3,
        "analysis_gate_count" => 0,
        "row_derived_analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "row_derived_blocked_gate_count" => 0,
        "row_count" => 6,
        "gate_status_counts" => %{"passed" => 3, "review_required" => 3},
        "row_derived_gate_status_counts" => %{"passed" => 3, "review_required" => 3},
        "gate_classification_counts" => %{"importable" => 3, "review_only" => 3},
        "row_derived_gate_classification_counts" => %{
          "importable" => 3,
          "review_only" => 3
        },
        "resource_availability_gate_count" => 1,
        "row_derived_resource_availability_pressure_count" => 2,
        "row_derived_resource_availability_reason_counts" => %{
          "antenna_unavailable" => 1,
          "payload_unavailable" => 1
        },
        "row_derived_resource_availability_reason_keys" =>
          "antenna_unavailable|payload_unavailable",
        "row_derived_unavailable_resource_reason_keys" =>
          "antenna_unavailable|payload_unavailable",
        "row_derived_ready_for_import_count" => 0,
        "row_derived_manifest_review_required_count" => 0,
        "row_derived_blocked_import_count" => 0,
        "row_derived_missing_import_count" => 0,
        "row_derived_invalid_cadence_import_count" => 0,
        "row_derived_import_status_counts" => %{},
        "row_derived_cadence_import_status_counts" => %{},
        "model_limit_count" => 2,
        "execution_boundary" => "artifact_only_no_cadence_write",
        "operator_authority" => "not_granted_by_quality_gate_report"
      },
      "tolerances" => %{
        "gate_count" => 0,
        "row_derived_gate_count" => 0,
        "passed_gate_count" => 0,
        "row_derived_passed_gate_count" => 0,
        "review_gate_count" => 0,
        "row_derived_review_gate_count" => 0,
        "resource_availability_gate_count" => 0,
        "row_derived_resource_availability_pressure_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks resource-pressure gate routing and no-authority boundary only"
      ]
    },
    "fixture.artifact.operator_review_package.v1" => %{
      "id" => "fixture.artifact.operator_review_package.v1",
      "model_id" => "artifact.operator_review_package.v1",
      "reference_case" => "checked-in standalone operator review package artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/operator_review_package_v1.json",
        "contract" => "operator_review_package.v1"
      },
      "expected" => %{
        "schema_contract" => "operator_review_package.v1",
        "model" => "artifact_only_operator_review_package",
        "review_count" => 8,
        "row_derived_review_count" => 8,
        "approval_requirement_count" => 1,
        "policy_escalation_count" => 1,
        "realized_feedback_count" => 1,
        "resource_projection_review_count" => 1,
        "resource_suppression_count" => 1,
        "contact_suppression_count" => 1,
        "link_capacity_review_count" => 1,
        "timeline_diff_count" => 1,
        "row_derived_review_type_counts" => %{
          "approval_requirement" => 1,
          "contact_suppression" => 1,
          "link_capacity_review" => 1,
          "policy_escalation" => 1,
          "realized_feedback" => 1,
          "resource_projection_review" => 1,
          "resource_suppression" => 1,
          "timeline_diff_review" => 1
        },
        "row_derived_required_operator_action_counts" => %{
          "approve_manual_contact" => 1,
          "review_contact_variance" => 1,
          "review_link_capacity_summary" => 1,
          "review_policy_escalation" => 1,
          "review_resource_projection" => 1,
          "review_suppressed_contact" => 1,
          "review_suppressed_observation" => 1,
          "review_timeline_change" => 1
        },
        "row_derived_review_queue_counts" => %{
          "approval_requirement|approve_manual_contact|operator_review_required" => 1,
          "contact_suppression|review_suppressed_contact|operator_review_required" => 1,
          "link_capacity_review|review_link_capacity_summary|operator_review_required" => 1,
          "policy_escalation|review_policy_escalation|operator_review_required" => 1,
          "realized_feedback|review_contact_variance|operator_review_required" => 1,
          "resource_projection_review|review_resource_projection|operator_review_required" => 1,
          "resource_suppression|review_suppressed_observation|operator_review_required" => 1,
          "timeline_diff_review|review_timeline_change|operator_review_required" => 1
        },
        "row_derived_review_row_ids_by_type" => %{
          "approval_requirement" => ["approval:operator_review_package:manual_contact:1"],
          "contact_suppression" => ["contact_suppression:leo_1_downlink_equator_prime_1:1"],
          "link_capacity_review" => ["link_capacity:equator_prime:1"],
          "policy_escalation" => ["policy_escalation:contact_execution_coordination:1"],
          "realized_feedback" => ["realized_feedback:downlink_equator:1"],
          "resource_projection_review" => ["resource_projection:leo_1:1"],
          "resource_suppression" => ["resource_suppression:leo_1_observe_target_a_1:1"],
          "timeline_diff_review" => ["timeline_diff:timeline:downlink_equator:1"]
        }
      },
      "tolerances" => %{
        "review_count" => 0,
        "row_derived_review_count" => 0,
        "approval_requirement_count" => 0,
        "policy_escalation_count" => 0,
        "realized_feedback_count" => 0,
        "resource_projection_review_count" => 0,
        "resource_suppression_count" => 0,
        "contact_suppression_count" => 0,
        "link_capacity_review_count" => 0,
        "timeline_diff_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks operator-review import surface counts only"
      ]
    },
    "fixture.artifact.operator_review_package.resource_projection_battery_handoff_v1" => %{
      "id" => "fixture.artifact.operator_review_package.resource_projection_battery_handoff_v1",
      "model_id" => "artifact.operator_review_package.v1",
      "reference_case" =>
        "checked-in operator-review resource-projection battery handoff artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" =>
          "study_results/operator_review_resource_projection_battery_handoff_v1.json",
        "contract" => "operator_review_package.v1",
        "source_contract" => "resource_projection_report.v1"
      },
      "expected" => %{
        "schema_contract" => "operator_review_package.v1",
        "model" => "artifact_only_operator_review_package",
        "review_count" => 1,
        "resource_projection_review_count" => 1,
        "resource_projection_battery_handoff_count" => 1,
        "total_resource_projection_battery_energy_consumed_wh" => 23.0,
        "total_resource_projection_battery_energy_generated_wh" => 8.0,
        "net_resource_projection_battery_energy_delta_wh" => 15.0,
        "peak_resource_projection_battery_overuse_wh" => 4.0
      },
      "tolerances" => %{
        "review_count" => 0,
        "resource_projection_review_count" => 0,
        "resource_projection_battery_handoff_count" => 0,
        "total_resource_projection_battery_energy_consumed_wh" => 0.0,
        "total_resource_projection_battery_energy_generated_wh" => 0.0,
        "net_resource_projection_battery_energy_delta_wh" => 0.0,
        "peak_resource_projection_battery_overuse_wh" => 0.0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks resource-projection battery handoff row aggregation only"
      ]
    },
    "fixture.artifact.operational_execution_boundary_summary.v1" => %{
      "id" => "fixture.artifact.operational_execution_boundary_summary.v1",
      "model_id" => "artifact.operational_execution_boundary_summary.v1",
      "reference_case" =>
        "checked-in operational execution boundary summary from ready readiness evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/operational_execution_boundary_summary_v1.json",
        "source_contract" => "operational_readiness_report.v1",
        "contract" => "operational_execution_boundary_summary.v1",
        "source_artifact_type" => "planned_activity.v1"
      },
      "expected" => %{
        "schema_contract" => "operational_execution_boundary_summary.v1",
        "model" => "artifact_only_operational_execution_boundary_summary",
        "source" => "operational_readiness_report.v1",
        "source_artifact_type" => "planned_activity.v1",
        "source_artifact_id" => "activity_1",
        "readiness_level" => "import_eligible",
        "import_classification" => "importable",
        "status" => "passed",
        "import_eligible" => true,
        "handoff_only" => true,
        "execution_allowed" => false,
        "cadence_write_allowed" => false,
        "operator_authority_granted" => false,
        "execution_boundary" => "adapter_handoff_only",
        "operational_mode_gate_id" => "operational_mode",
        "operational_mode_gate_status" => "passed",
        "operational_mode_gate_classification" => "importable",
        "gate_count" => 5,
        "passed_gate_count" => 5,
        "review_gate_count" => 0,
        "analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "non_passed_gate_count" => 0,
        "non_passed_gate_keys" => "",
        "model_limit_count" => 2,
        "assumption_execution_boundary" => "artifact_only_no_cadence_write_no_command_execution",
        "operator_authority" => "not_granted_by_execution_boundary_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary",
        "assumption_source" => "operational_readiness_report.v1"
      },
      "tolerances" => %{
        "gate_count" => 0,
        "passed_gate_count" => 0,
        "review_gate_count" => 0,
        "analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "non_passed_gate_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by operational_execution_boundary_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks execution/write/authority denial, gate counts, and handoff boundary only"
      ]
    },
    "fixture.artifact.operational_import_eligibility_summary.v1" => %{
      "id" => "fixture.artifact.operational_import_eligibility_summary.v1",
      "model_id" => "artifact.operational_import_eligibility_summary.v1",
      "reference_case" =>
        "checked-in operational import eligibility summary from ready readiness evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/operational_import_eligibility_summary_v1.json",
        "source_contract" => "operational_readiness_report.v1",
        "contract" => "operational_import_eligibility_summary.v1",
        "source_artifact_type" => "planned_activity.v1"
      },
      "expected" => %{
        "schema_contract" => "operational_import_eligibility_summary.v1",
        "model" => "artifact_only_import_eligibility_summary",
        "source" => "operational_readiness_report.v1",
        "source_artifact_type" => "planned_activity.v1",
        "source_artifact_id" => "activity_1",
        "readiness_level" => "import_eligible",
        "import_classification" => "importable",
        "status" => "passed",
        "import_eligible" => true,
        "gate_count" => 5,
        "passed_gate_count" => 5,
        "review_gate_count" => 0,
        "analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "non_passed_gate_count" => 0,
        "row_derived_non_passed_gate_count" => 0,
        "non_passed_gate_keys" => "",
        "model_limit_count" => 2,
        "execution_boundary" => "artifact_only_no_cadence_write",
        "operator_authority" => "not_granted_by_summary",
        "assumption_source" => "operational_readiness_report.v1"
      },
      "tolerances" => %{
        "gate_count" => 0,
        "passed_gate_count" => 0,
        "review_gate_count" => 0,
        "analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "non_passed_gate_count" => 0,
        "row_derived_non_passed_gate_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by operational_import_eligibility_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks import eligibility, gate counts, and no-authority boundary only"
      ]
    },
    "fixture.artifact.operational_readiness_report.v1" => %{
      "id" => "fixture.artifact.operational_readiness_report.v1",
      "model_id" => "artifact.operational_readiness_report.v1",
      "reference_case" =>
        "curated operational readiness report from ready Cadence import evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/operational_readiness_report_v1.json",
        "source_contract" => "cadence_import_manifest.v1",
        "contract" => "operational_readiness_report.v1",
        "source_artifact_type" => "planned_activity.v1"
      },
      "expected" => %{
        "schema_contract" => "operational_readiness_report.v1",
        "model" => "artifact_only_operational_readiness_classifier",
        "report_id" => "operational_readiness:planned_activity.v1:activity_1",
        "source_artifact_type" => "planned_activity.v1",
        "source_artifact_id" => "activity_1",
        "readiness_level" => "import_eligible",
        "import_classification" => "importable",
        "status" => "passed",
        "gate_count" => 5,
        "row_derived_gate_count" => 5,
        "passed_gate_count" => 5,
        "row_derived_passed_gate_count" => 5,
        "review_gate_count" => 0,
        "row_derived_review_gate_count" => 0,
        "analysis_gate_count" => 0,
        "row_derived_analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "row_derived_blocked_gate_count" => 0,
        "row_derived_gate_status_counts" => %{"passed" => 5},
        "row_derived_gate_classification_counts" => %{"importable" => 5},
        "row_derived_gate_ids_by_status" => %{
          "passed" => [
            "adapter_boundary",
            "cadence_import",
            "operational_mode",
            "operator_review",
            "source_contract"
          ]
        },
        "row_derived_gate_ids_by_classification" => %{
          "importable" => [
            "adapter_boundary",
            "cadence_import",
            "operational_mode",
            "operator_review",
            "source_contract"
          ]
        },
        "review_row_count" => 0,
        "import_row_count" => 1,
        "ready_for_import_count" => 1,
        "row_derived_ready_for_import_count" => 1,
        "manifest_review_required_count" => 0,
        "row_derived_manifest_review_required_count" => 0,
        "blocked_import_count" => 0,
        "row_derived_blocked_import_count" => 0,
        "missing_import_count" => 0,
        "row_derived_missing_import_count" => 0,
        "invalid_cadence_import_count" => 0,
        "row_derived_invalid_cadence_import_count" => 0,
        "current_freshness_count" => 0,
        "row_derived_current_freshness_count" => 0,
        "stale_freshness_count" => 0,
        "row_derived_stale_freshness_count" => 0,
        "unknown_freshness_count" => 0,
        "row_derived_unknown_freshness_count" => 0,
        "freshness_status_counts" => %{},
        "row_derived_freshness_status_counts" => %{},
        "schema_validation_pass_count" => 0,
        "row_derived_schema_validation_pass_count" => 0,
        "schema_validation_fail_count" => 0,
        "row_derived_schema_validation_fail_count" => 0,
        "schema_validation_error_count" => 0,
        "row_derived_schema_validation_error_count" => 0,
        "schema_validation_warning_count" => 0,
        "row_derived_schema_validation_warning_count" => 0,
        "schema_validation_remediation_count" => 0,
        "row_derived_schema_validation_remediation_count" => 0,
        "schema_validation_status_counts" => %{},
        "row_derived_schema_validation_status_counts" => %{},
        "import_status_counts" => %{"ready_for_import" => 1},
        "row_derived_import_status_counts" => %{"ready_for_import" => 1},
        "cadence_import_status_counts" => %{"present" => 1},
        "row_derived_cadence_import_status_counts" => %{"present" => 1},
        "source_model_count" => 1,
        "source_model_limit_count" => 1,
        "adapter_context_count" => 0,
        "adapter_trust_boundary_missing_count" => 0
      },
      "tolerances" => %{
        "gate_count" => 0,
        "row_derived_gate_count" => 0,
        "passed_gate_count" => 0,
        "row_derived_passed_gate_count" => 0,
        "review_gate_count" => 0,
        "row_derived_review_gate_count" => 0,
        "analysis_gate_count" => 0,
        "row_derived_analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "row_derived_blocked_gate_count" => 0,
        "review_row_count" => 0,
        "import_row_count" => 0,
        "ready_for_import_count" => 0,
        "row_derived_ready_for_import_count" => 0,
        "manifest_review_required_count" => 0,
        "row_derived_manifest_review_required_count" => 0,
        "blocked_import_count" => 0,
        "row_derived_blocked_import_count" => 0,
        "missing_import_count" => 0,
        "row_derived_missing_import_count" => 0,
        "invalid_cadence_import_count" => 0,
        "row_derived_invalid_cadence_import_count" => 0,
        "current_freshness_count" => 0,
        "row_derived_current_freshness_count" => 0,
        "stale_freshness_count" => 0,
        "row_derived_stale_freshness_count" => 0,
        "unknown_freshness_count" => 0,
        "row_derived_unknown_freshness_count" => 0,
        "schema_validation_pass_count" => 0,
        "row_derived_schema_validation_pass_count" => 0,
        "schema_validation_fail_count" => 0,
        "row_derived_schema_validation_fail_count" => 0,
        "schema_validation_error_count" => 0,
        "row_derived_schema_validation_error_count" => 0,
        "schema_validation_warning_count" => 0,
        "row_derived_schema_validation_warning_count" => 0,
        "schema_validation_remediation_count" => 0,
        "row_derived_schema_validation_remediation_count" => 0,
        "source_model_count" => 0,
        "source_model_limit_count" => 0,
        "adapter_context_count" => 0,
        "adapter_trust_boundary_missing_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by operational_readiness_report.v1 validation tests"
      ],
      "known_limits" => [
        "internal artifact regression, not external operations validation",
        "checks readiness classification and evidence counts only"
      ]
    },
    "fixture.artifact.operational_readiness_gate_summary.v1" => %{
      "id" => "fixture.artifact.operational_readiness_gate_summary.v1",
      "model_id" => "artifact.operational_readiness_gate_summary.v1",
      "reference_case" =>
        "checked-in operational readiness gate summary from ready readiness evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/operational_readiness_gate_summary_v1.json",
        "source_contract" => "operational_readiness_report.v1",
        "contract" => "operational_readiness_gate_summary.v1",
        "source_artifact_type" => "planned_activity.v1"
      },
      "expected" => %{
        "schema_contract" => "operational_readiness_gate_summary.v1",
        "model" => "artifact_only_operational_readiness_gate_summary",
        "source" => "operational_readiness_report.v1",
        "source_artifact_type" => "planned_activity.v1",
        "source_artifact_id" => "activity_1",
        "readiness_level" => "import_eligible",
        "import_classification" => "importable",
        "status" => "passed",
        "gate_count" => 5,
        "row_derived_gate_count" => 5,
        "passed_gate_count" => 5,
        "row_derived_passed_gate_count" => 5,
        "review_gate_count" => 0,
        "row_derived_review_gate_count" => 0,
        "analysis_gate_count" => 0,
        "row_derived_analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "row_derived_blocked_gate_count" => 0,
        "non_passed_gate_count" => 0,
        "row_derived_non_passed_gate_count" => 0,
        "gate_status_counts" => %{"passed" => 5},
        "row_derived_gate_status_counts" => %{"passed" => 5},
        "gate_classification_counts" => %{"importable" => 5},
        "row_derived_gate_classification_counts" => %{"importable" => 5},
        "gate_ids_by_status" => %{
          "passed" => [
            "adapter_boundary",
            "cadence_import",
            "operational_mode",
            "operator_review",
            "source_contract"
          ]
        },
        "row_derived_gate_ids_by_status" => %{
          "passed" => [
            "adapter_boundary",
            "cadence_import",
            "operational_mode",
            "operator_review",
            "source_contract"
          ]
        },
        "gate_ids_by_classification" => %{
          "importable" => [
            "adapter_boundary",
            "cadence_import",
            "operational_mode",
            "operator_review",
            "source_contract"
          ]
        },
        "row_derived_gate_ids_by_classification" => %{
          "importable" => [
            "adapter_boundary",
            "cadence_import",
            "operational_mode",
            "operator_review",
            "source_contract"
          ]
        },
        "passed_gate_keys" =>
          "source_contract|operational_mode|adapter_boundary|operator_review|cadence_import",
        "non_passed_gate_keys" => "",
        "model_limit_count" => 2,
        "execution_boundary" => "artifact_only_no_cadence_write",
        "operator_authority" => "not_granted_by_summary",
        "assumption_source" => "operational_readiness_report.v1"
      },
      "tolerances" => %{
        "gate_count" => 0,
        "row_derived_gate_count" => 0,
        "passed_gate_count" => 0,
        "row_derived_passed_gate_count" => 0,
        "review_gate_count" => 0,
        "row_derived_review_gate_count" => 0,
        "analysis_gate_count" => 0,
        "row_derived_analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "row_derived_blocked_gate_count" => 0,
        "non_passed_gate_count" => 0,
        "row_derived_non_passed_gate_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by operational_readiness_gate_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks gate routing maps, gate counts, and no-authority boundary only"
      ]
    },
    "fixture.artifact.quality_gate_report.v1" => %{
      "id" => "fixture.artifact.quality_gate_report.v1",
      "model_id" => "artifact.quality_gate_report.v1",
      "reference_case" => "curated quality gate report from ready operational readiness evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source_contract" => "operational_readiness_report.v1",
        "contract" => "quality_gate_report.v1",
        "source_artifact_type" => "planned_activity.v1"
      },
      "expected" => %{
        "schema_contract" => "quality_gate_report.v1",
        "model" => "artifact_only_operational_quality_gate_report",
        "report_id" => "quality_gate:planned_activity.v1:activity_1",
        "source_artifact_type" => "planned_activity.v1",
        "source_artifact_id" => "activity_1",
        "source_readiness_report_id" => "operational_readiness:planned_activity.v1:activity_1",
        "readiness_level" => "import_eligible",
        "import_classification" => "importable",
        "status" => "passed",
        "gate_count" => 5,
        "row_derived_gate_count" => 5,
        "passed_gate_count" => 5,
        "row_derived_passed_gate_count" => 5,
        "review_gate_count" => 0,
        "row_derived_review_gate_count" => 0,
        "analysis_gate_count" => 0,
        "row_derived_analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "row_derived_blocked_gate_count" => 0,
        "row_count" => 5,
        "gate_status_counts" => %{"passed" => 5},
        "row_derived_gate_status_counts" => %{"passed" => 5},
        "gate_classification_counts" => %{"importable" => 5},
        "row_derived_gate_classification_counts" => %{"importable" => 5},
        "gate_ids_by_status" => %{
          "passed" => [
            "adapter_boundary",
            "cadence_import",
            "operational_mode",
            "operator_review",
            "source_contract"
          ]
        },
        "row_derived_gate_ids_by_status" => %{
          "passed" => [
            "adapter_boundary",
            "cadence_import",
            "operational_mode",
            "operator_review",
            "source_contract"
          ]
        },
        "gate_ids_by_classification" => %{
          "importable" => [
            "adapter_boundary",
            "cadence_import",
            "operational_mode",
            "operator_review",
            "source_contract"
          ]
        },
        "row_derived_gate_ids_by_classification" => %{
          "importable" => [
            "adapter_boundary",
            "cadence_import",
            "operational_mode",
            "operator_review",
            "source_contract"
          ]
        },
        "row_derived_ready_for_import_count" => 1,
        "row_derived_manifest_review_required_count" => 0,
        "row_derived_blocked_import_count" => 0,
        "row_derived_missing_import_count" => 0,
        "row_derived_invalid_cadence_import_count" => 0,
        "row_derived_current_freshness_count" => 0,
        "row_derived_stale_freshness_count" => 0,
        "row_derived_unknown_freshness_count" => 0,
        "row_derived_freshness_status_counts" => %{},
        "row_derived_schema_validation_pass_count" => 0,
        "row_derived_schema_validation_fail_count" => 0,
        "row_derived_schema_validation_error_count" => 0,
        "row_derived_schema_validation_warning_count" => 0,
        "row_derived_schema_validation_remediation_count" => 0,
        "row_derived_schema_validation_status_counts" => %{},
        "row_derived_import_status_counts" => %{"ready_for_import" => 1},
        "row_derived_cadence_import_status_counts" => %{"present" => 1},
        "model_limit_count" => 2,
        "execution_boundary" => "artifact_only_no_cadence_write",
        "operator_authority" => "not_granted_by_quality_gate_report"
      },
      "tolerances" => %{
        "gate_count" => 0,
        "row_derived_gate_count" => 0,
        "passed_gate_count" => 0,
        "row_derived_passed_gate_count" => 0,
        "review_gate_count" => 0,
        "row_derived_review_gate_count" => 0,
        "analysis_gate_count" => 0,
        "row_derived_analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "row_derived_blocked_gate_count" => 0,
        "row_count" => 0,
        "row_derived_ready_for_import_count" => 0,
        "row_derived_manifest_review_required_count" => 0,
        "row_derived_blocked_import_count" => 0,
        "row_derived_missing_import_count" => 0,
        "row_derived_invalid_cadence_import_count" => 0,
        "row_derived_current_freshness_count" => 0,
        "row_derived_stale_freshness_count" => 0,
        "row_derived_unknown_freshness_count" => 0,
        "row_derived_schema_validation_pass_count" => 0,
        "row_derived_schema_validation_fail_count" => 0,
        "row_derived_schema_validation_error_count" => 0,
        "row_derived_schema_validation_warning_count" => 0,
        "row_derived_schema_validation_remediation_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by quality_gate_report.v1 validation tests"
      ],
      "known_limits" => [
        "internal artifact regression, not external operations validation",
        "checks gate projection counts and authority boundary only"
      ]
    },
    "fixture.artifact.operational_quality_gate_summary.v1" => %{
      "id" => "fixture.artifact.operational_quality_gate_summary.v1",
      "model_id" => "artifact.operational_quality_gate_summary.v1",
      "reference_case" =>
        "checked-in quality gate summary from resource-pressure review evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/operational_quality_gate_summary_v1.json",
        "source_contract" => "quality_gate_report.v1",
        "contract" => "operational_quality_gate_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "operational_quality_gate_summary.v1",
        "model" => "artifact_only_quality_gate_summary",
        "source" => "quality_gate_report.v1",
        "source_artifact_type" => "resource_projection_report.v1",
        "source_artifact_id" => "resource_summaries",
        "source_quality_gate_report_id" =>
          "quality_gate:resource_projection_report.v1:resource_summaries",
        "source_readiness_report_id" =>
          "operational_readiness:resource_projection_report.v1:resource_summaries",
        "readiness_level" => "operator_review",
        "import_classification" => "review_only",
        "status" => "review_required",
        "execution_allowed" => false,
        "cadence_write_allowed" => false,
        "operator_authority_granted" => false,
        "gate_count" => 6,
        "row_derived_gate_count" => 6,
        "passed_gate_count" => 3,
        "row_derived_passed_gate_count" => 3,
        "review_gate_count" => 3,
        "row_derived_review_gate_count" => 3,
        "analysis_gate_count" => 0,
        "row_derived_analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "row_derived_blocked_gate_count" => 0,
        "non_passed_gate_count" => 3,
        "row_derived_non_passed_gate_count" => 3,
        "gate_status_counts" => %{"passed" => 3, "review_required" => 3},
        "row_derived_gate_status_counts" => %{"passed" => 3, "review_required" => 3},
        "gate_classification_counts" => %{"importable" => 3, "review_only" => 3},
        "row_derived_gate_classification_counts" => %{
          "importable" => 3,
          "review_only" => 3
        },
        "gate_ids_by_status" => %{
          "passed" => ["adapter_boundary", "operational_mode", "source_contract"],
          "review_required" => ["cadence_import", "operator_review", "resource_availability"]
        },
        "row_derived_gate_ids_by_status" => %{
          "passed" => ["adapter_boundary", "operational_mode", "source_contract"],
          "review_required" => ["cadence_import", "operator_review", "resource_availability"]
        },
        "gate_ids_by_classification" => %{
          "importable" => ["adapter_boundary", "operational_mode", "source_contract"],
          "review_only" => ["cadence_import", "operator_review", "resource_availability"]
        },
        "row_derived_gate_ids_by_classification" => %{
          "importable" => ["adapter_boundary", "operational_mode", "source_contract"],
          "review_only" => ["cadence_import", "operator_review", "resource_availability"]
        },
        "non_passed_gate_keys" => "cadence_import|operator_review|resource_availability",
        "row_derived_non_passed_gate_keys" =>
          "cadence_import|operator_review|resource_availability",
        "non_passed_quality_gate_row_keys" =>
          "quality_gate:resource_projection_report.v1:resource_summaries:cadence_import:6|quality_gate:resource_projection_report.v1:resource_summaries:operator_review:5|quality_gate:resource_projection_report.v1:resource_summaries:resource_availability:4",
        "row_derived_non_passed_quality_gate_row_keys" =>
          "quality_gate:resource_projection_report.v1:resource_summaries:cadence_import:6|quality_gate:resource_projection_report.v1:resource_summaries:operator_review:5|quality_gate:resource_projection_report.v1:resource_summaries:resource_availability:4",
        "row_derived_non_passed_quality_gate_row_count" => 3,
        "model_limit_count" => 2,
        "execution_boundary" => "artifact_only_no_cadence_write",
        "operator_authority" => "not_granted_by_quality_gate_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary"
      },
      "tolerances" => %{
        "gate_count" => 0,
        "row_derived_gate_count" => 0,
        "passed_gate_count" => 0,
        "row_derived_passed_gate_count" => 0,
        "review_gate_count" => 0,
        "row_derived_review_gate_count" => 0,
        "analysis_gate_count" => 0,
        "row_derived_analysis_gate_count" => 0,
        "blocked_gate_count" => 0,
        "row_derived_blocked_gate_count" => 0,
        "non_passed_gate_count" => 0,
        "row_derived_non_passed_gate_count" => 0,
        "row_derived_non_passed_quality_gate_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by operational_quality_gate_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks base quality-gate summary routing, review pressure, and no-authority boundary only"
      ]
    },
    "fixture.artifact.operational_quality_gate_import_readiness_summary.v1" => %{
      "id" => "fixture.artifact.operational_quality_gate_import_readiness_summary.v1",
      "model_id" => "artifact.operational_quality_gate_import_readiness_summary.v1",
      "reference_case" =>
        "checked-in quality gate import-readiness summary from stale freshness evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" =>
          "study_results/operational_quality_gate_import_readiness_summary_v1.json",
        "source_contract" => "quality_gate_report.v1",
        "contract" => "operational_quality_gate_import_readiness_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "operational_quality_gate_import_readiness_summary.v1",
        "model" => "artifact_only_quality_gate_import_readiness_summary",
        "source" => "quality_gate_report.v1",
        "source_artifact_type" => "planned_activity.v1",
        "source_artifact_id" => "activity_1",
        "source_quality_gate_report_id" => "quality_gate:planned_activity.v1:activity_1",
        "source_readiness_report_id" => "operational_readiness:planned_activity.v1:activity_1",
        "import_readiness_row_count" => 1,
        "ready_for_import_count" => 1,
        "row_derived_ready_for_import_count" => 1,
        "manifest_review_required_count" => 0,
        "blocked_import_count" => 0,
        "missing_import_count" => 0,
        "invalid_cadence_import_count" => 0,
        "current_freshness_count" => 0,
        "stale_freshness_count" => 1,
        "row_derived_stale_freshness_count" => 1,
        "unknown_freshness_count" => 0,
        "freshness_status_counts" => %{"stale" => 1},
        "freshness_status_keys" => "stale",
        "import_status_counts" => %{"ready_for_import" => 1},
        "import_status_keys" => "ready_for_import",
        "cadence_import_status_counts" => %{"present" => 1},
        "cadence_import_status_keys" => "present",
        "row_derived_cadence_import_present_count" => 1,
        "freshness_review_required" => true,
        "import_preparation_required" => false,
        "import_blocked" => false,
        "quality_gate_row_ids_by_status" => %{
          "review_required" => ["quality_gate:planned_activity.v1:activity_1:cadence_import:5"]
        },
        "quality_gate_ids_by_status" => %{"review_required" => ["cadence_import"]},
        "review_required_quality_gate_row_keys" =>
          "quality_gate:planned_activity.v1:activity_1:cadence_import:5",
        "blocked_quality_gate_row_keys" => "",
        "ready_quality_gate_row_keys" => "",
        "analysis_only_quality_gate_row_keys" => "",
        "stale_or_unknown_freshness_quality_gate_row_keys" =>
          "quality_gate:planned_activity.v1:activity_1:cadence_import:5",
        "import_preparation_quality_gate_row_keys" => "",
        "blocked_import_quality_gate_row_keys" => "",
        "import_readiness_gate_keys" => "cadence_import",
        "row_derived_review_required_quality_gate_row_count" => 1,
        "row_derived_stale_or_unknown_freshness_quality_gate_row_count" => 1,
        "execution_boundary" => "artifact_only_no_cadence_write",
        "operator_authority" => "not_granted_by_import_readiness_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary",
        "model_limit_count" => 2
      },
      "tolerances" => %{
        "import_readiness_row_count" => 0,
        "ready_for_import_count" => 0,
        "row_derived_ready_for_import_count" => 0,
        "manifest_review_required_count" => 0,
        "blocked_import_count" => 0,
        "missing_import_count" => 0,
        "invalid_cadence_import_count" => 0,
        "current_freshness_count" => 0,
        "stale_freshness_count" => 0,
        "row_derived_stale_freshness_count" => 0,
        "unknown_freshness_count" => 0,
        "row_derived_cadence_import_present_count" => 0,
        "row_derived_review_required_quality_gate_row_count" => 0,
        "row_derived_stale_or_unknown_freshness_quality_gate_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by operational_quality_gate_import_readiness_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks import-readiness status maps, freshness review routing, and no-authority boundary only"
      ]
    },
    "fixture.artifact.operational_quality_gate_unavailable_resource_summary.v1" => %{
      "id" => "fixture.artifact.operational_quality_gate_unavailable_resource_summary.v1",
      "model_id" => "artifact.operational_quality_gate_unavailable_resource_summary.v1",
      "reference_case" =>
        "generated quality gate unavailable-resource summary from contact allocation resource pressure",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source_contract" => "quality_gate_report.v1",
        "contract" => "operational_quality_gate_unavailable_resource_summary.v1",
        "source_artifact_type" => "contact_allocation_report.v1"
      },
      "expected" => %{
        "schema_contract" => "operational_quality_gate_unavailable_resource_summary.v1",
        "model" => "artifact_only_quality_gate_unavailable_resource_summary",
        "source" => "quality_gate_report.v1",
        "source_artifact_type" => "contact_allocation_report.v1",
        "source_artifact_id" => "validation_unavailable_resource_fixture",
        "source_quality_gate_report_id" =>
          "quality_gate:contact_allocation_report.v1:validation_unavailable_resource_fixture",
        "source_readiness_report_id" =>
          "operational_readiness:contact_allocation_report.v1:validation_unavailable_resource_fixture",
        "resource_availability_row_count" => 1,
        "row_derived_resource_availability_row_count" => 1,
        "unavailable_resource_row_count" => 1,
        "unavailable_resource_pressure_count" => 1,
        "row_derived_unavailable_resource_pressure_count" => 1,
        "unavailable_resource_reason_counts" => %{"antenna_unavailable" => 1},
        "unavailable_resource_reason_keys" => "antenna_unavailable",
        "station_availability_reason_counts" => %{},
        "station_availability_reason_keys" => "",
        "resource_blocking_dimension_counts" => %{"antenna" => 1},
        "blocked_contact_ids_by_blocking_dimension" => %{"antenna" => ["dl_resource_blocked"]},
        "blocked_contact_ids_by_spacecraft_id" => %{"leo_1" => ["dl_resource_blocked"]},
        "blocked_contact_ids_by_status" => %{"review_required" => ["dl_resource_blocked"]},
        "quality_gate_row_ids_by_status" => %{
          "review_required" => [
            "quality_gate:contact_allocation_report.v1:validation_unavailable_resource_fixture:resource_availability:4"
          ]
        },
        "quality_gate_ids_by_status" => %{"review_required" => ["resource_availability"]},
        "review_required_quality_gate_row_keys" =>
          "quality_gate:contact_allocation_report.v1:validation_unavailable_resource_fixture:resource_availability:4",
        "blocked_quality_gate_row_keys" => "",
        "resource_availability_gate_keys" => "resource_availability",
        "row_derived_review_required_quality_gate_row_count" => 1,
        "row_derived_blocked_quality_gate_row_count" => 0,
        "execution_boundary" => "artifact_only_no_cadence_write",
        "operator_authority" => "not_granted_by_unavailable_resource_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary",
        "model_limit_count" => 2
      },
      "tolerances" => %{
        "resource_availability_row_count" => 0,
        "row_derived_resource_availability_row_count" => 0,
        "unavailable_resource_row_count" => 0,
        "unavailable_resource_pressure_count" => 0,
        "row_derived_unavailable_resource_pressure_count" => 0,
        "row_derived_review_required_quality_gate_row_count" => 0,
        "row_derived_blocked_quality_gate_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by operational_quality_gate_unavailable_resource_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal generated artifact regression, not external operations validation",
        "checks unavailable-resource reason maps, row-status routing, contact ID maps, and no-authority boundary only"
      ]
    },
    "fixture.artifact.operational_quality_gate_unavailable_resource_summary.resource_projection_v1" =>
      %{
        "id" =>
          "fixture.artifact.operational_quality_gate_unavailable_resource_summary.resource_projection_v1",
        "model_id" => "artifact.operational_quality_gate_unavailable_resource_summary.v1",
        "reference_case" =>
          "checked-in quality gate unavailable-resource summary from resource projection pressure",
        "validation_level" => "artifact_contract",
        "fixture_type" => "curated_internal_artifact_regression",
        "inputs" => %{
          "artifact_path" =>
            "study_results/operational_quality_gate_unavailable_resource_summary_v1.json",
          "contract" => "operational_quality_gate_unavailable_resource_summary.v1",
          "source_artifact_type" => "resource_projection_report.v1"
        },
        "expected" => %{
          "schema_contract" => "operational_quality_gate_unavailable_resource_summary.v1",
          "model" => "artifact_only_quality_gate_unavailable_resource_summary",
          "source" => "quality_gate_report.v1",
          "source_artifact_type" => "resource_projection_report.v1",
          "source_artifact_id" => "resource_summaries",
          "source_quality_gate_report_id" =>
            "quality_gate:resource_projection_report.v1:resource_summaries",
          "source_readiness_report_id" =>
            "operational_readiness:resource_projection_report.v1:resource_summaries",
          "resource_availability_row_count" => 1,
          "row_derived_resource_availability_row_count" => 1,
          "unavailable_resource_row_count" => 1,
          "unavailable_resource_pressure_count" => 2,
          "row_derived_unavailable_resource_pressure_count" => 2,
          "unavailable_resource_reason_counts" => %{
            "antenna_unavailable" => 1,
            "payload_unavailable" => 1
          },
          "unavailable_resource_reason_keys" => "antenna_unavailable|payload_unavailable",
          "station_availability_reason_counts" => %{},
          "station_availability_reason_keys" => "",
          "resource_blocking_dimension_counts" => %{},
          "blocked_contact_ids_by_blocking_dimension" => %{},
          "blocked_contact_ids_by_spacecraft_id" => %{},
          "blocked_contact_ids_by_status" => %{},
          "quality_gate_row_ids_by_status" => %{
            "review_required" => [
              "quality_gate:resource_projection_report.v1:resource_summaries:resource_availability:4"
            ]
          },
          "quality_gate_ids_by_status" => %{"review_required" => ["resource_availability"]},
          "review_required_quality_gate_row_keys" =>
            "quality_gate:resource_projection_report.v1:resource_summaries:resource_availability:4",
          "blocked_quality_gate_row_keys" => "",
          "resource_availability_gate_keys" => "resource_availability",
          "row_derived_review_required_quality_gate_row_count" => 1,
          "row_derived_blocked_quality_gate_row_count" => 0,
          "execution_boundary" => "artifact_only_no_cadence_write",
          "operator_authority" => "not_granted_by_unavailable_resource_summary",
          "cadence_write" => "not_performed_by_summary",
          "command_execution" => "not_performed_by_summary",
          "model_limit_count" => 2
        },
        "tolerances" => %{
          "resource_availability_row_count" => 0,
          "row_derived_resource_availability_row_count" => 0,
          "unavailable_resource_row_count" => 0,
          "unavailable_resource_pressure_count" => 0,
          "row_derived_unavailable_resource_pressure_count" => 0,
          "row_derived_review_required_quality_gate_row_count" => 0,
          "row_derived_blocked_quality_gate_row_count" => 0,
          "model_limit_count" => 0
        },
        "evidence" => [
          "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
          "schema-linted by mix orbital_dynamics.schema.lint"
        ],
        "known_limits" => [
          "internal checked-in artifact regression, not external operations validation",
          "checks resource-projection unavailable-resource reason maps, review routing, and no-authority boundary only"
        ]
      },
    "fixture.artifact.operational_quality_gate_operator_training_summary.v1" => %{
      "id" => "fixture.artifact.operational_quality_gate_operator_training_summary.v1",
      "model_id" => "artifact.operational_quality_gate_operator_training_summary.v1",
      "reference_case" =>
        "checked-in quality gate operator-training summary from review-required training evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" =>
          "study_results/operational_quality_gate_operator_training_summary_v1.json",
        "source_contract" => "quality_gate_report.v1",
        "contract" => "operational_quality_gate_operator_training_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "operational_quality_gate_operator_training_summary.v1",
        "model" => "artifact_only_quality_gate_operator_training_summary",
        "source" => "quality_gate_report.v1",
        "source_artifact_type" => "planned_activity.v1",
        "source_artifact_id" => "activity_1",
        "source_quality_gate_report_id" => "quality_gate:planned_activity.v1:activity_1",
        "source_readiness_report_id" => "operational_readiness:planned_activity.v1:activity_1",
        "operator_training_row_count" => 1,
        "operator_training_requirement_count" => 5,
        "row_derived_operator_training_requirement_count" => 5,
        "operator_training_requirement_counts" => %{
          "certification" => 1,
          "operator_role" => 2,
          "qualification" => 1,
          "training" => 1
        },
        "operator_training_requirement_keys" =>
          "certification|operator_role|qualification|training",
        "required_operator_role_keys" => "contact_operator|mission_director",
        "required_training_keys" => "contact_replan_drill",
        "required_certification_keys" => "cadence_import_cert",
        "required_qualification_keys" => "sat_ops_current",
        "quality_gate_row_ids_by_status" => %{
          "review_required" => [
            "quality_gate:planned_activity.v1:activity_1:operator_training:4"
          ]
        },
        "quality_gate_row_ids_by_classification" => %{
          "review_only" => [
            "quality_gate:planned_activity.v1:activity_1:operator_training:4"
          ]
        },
        "quality_gate_ids_by_status" => %{"review_required" => ["operator_training"]},
        "quality_gate_ids_by_classification" => %{"review_only" => ["operator_training"]},
        "review_required_quality_gate_row_keys" =>
          "quality_gate:planned_activity.v1:activity_1:operator_training:4",
        "blocked_quality_gate_row_keys" => "",
        "review_only_quality_gate_row_keys" =>
          "quality_gate:planned_activity.v1:activity_1:operator_training:4",
        "operator_training_gate_keys" => "operator_training",
        "operator_training_review_required" => true,
        "row_derived_review_required_quality_gate_row_count" => 1,
        "row_derived_review_only_quality_gate_row_count" => 1,
        "execution_boundary" => "artifact_only_no_cadence_write",
        "operator_authority" => "not_granted_by_operator_training_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary",
        "model_limit_count" => 2
      },
      "tolerances" => %{
        "operator_training_row_count" => 0,
        "operator_training_requirement_count" => 0,
        "row_derived_operator_training_requirement_count" => 0,
        "row_derived_review_required_quality_gate_row_count" => 0,
        "row_derived_review_only_quality_gate_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by operational_quality_gate_operator_training_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks operator-training requirement routing and no-authority boundary only"
      ]
    },
    "fixture.artifact.operational_quality_gate_schema_validation_summary.v1" => %{
      "id" => "fixture.artifact.operational_quality_gate_schema_validation_summary.v1",
      "model_id" => "artifact.operational_quality_gate_schema_validation_summary.v1",
      "reference_case" =>
        "checked-in quality gate schema-validation summary from failed schema evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" =>
          "study_results/operational_quality_gate_schema_validation_summary_v1.json",
        "source_contract" => "quality_gate_report.v1",
        "contract" => "operational_quality_gate_schema_validation_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "operational_quality_gate_schema_validation_summary.v1",
        "model" => "artifact_only_quality_gate_schema_validation_summary",
        "source" => "quality_gate_report.v1",
        "source_artifact_type" => "planned_activity.v1",
        "source_artifact_id" => "activity_1",
        "source_quality_gate_report_id" => "quality_gate:planned_activity.v1:activity_1",
        "source_readiness_report_id" => "operational_readiness:planned_activity.v1:activity_1",
        "schema_validation_row_count" => 1,
        "schema_validation_pass_count" => 0,
        "row_derived_schema_validation_pass_count" => 0,
        "schema_validation_fail_count" => 1,
        "row_derived_schema_validation_fail_count" => 1,
        "schema_validation_error_count" => 1,
        "schema_validation_warning_count" => 0,
        "schema_validation_remediation_count" => 1,
        "schema_validation_status_counts" => %{"fail" => 1},
        "schema_validation_status_keys" => "fail",
        "schema_validation_import_blocked" => true,
        "quality_gate_row_ids_by_status" => %{
          "blocked" => ["quality_gate:planned_activity.v1:activity_1:cadence_import:5"]
        },
        "quality_gate_ids_by_status" => %{"blocked" => ["cadence_import"]},
        "blocked_quality_gate_row_keys" =>
          "quality_gate:planned_activity.v1:activity_1:cadence_import:5",
        "review_required_quality_gate_row_keys" => "",
        "failed_schema_validation_quality_gate_row_keys" =>
          "quality_gate:planned_activity.v1:activity_1:cadence_import:5",
        "schema_validation_gate_keys" => "cadence_import",
        "row_derived_blocked_quality_gate_row_count" => 1,
        "row_derived_failed_schema_validation_quality_gate_row_count" => 1,
        "execution_boundary" => "artifact_only_no_cadence_write",
        "operator_authority" => "not_granted_by_schema_validation_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary",
        "model_limit_count" => 2
      },
      "tolerances" => %{
        "schema_validation_row_count" => 0,
        "schema_validation_pass_count" => 0,
        "row_derived_schema_validation_pass_count" => 0,
        "schema_validation_fail_count" => 0,
        "row_derived_schema_validation_fail_count" => 0,
        "schema_validation_error_count" => 0,
        "schema_validation_warning_count" => 0,
        "schema_validation_remediation_count" => 0,
        "row_derived_blocked_quality_gate_row_count" => 0,
        "row_derived_failed_schema_validation_quality_gate_row_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by operational_quality_gate_schema_validation_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external operations validation",
        "checks schema-validation status maps, blocked row routing, and no-authority boundary only"
      ]
    },
    "fixture.artifact.station_calendar_report.stale_provider_reservation_hold" => %{
      "id" => "fixture.artifact.station_calendar_report.stale_provider_reservation_hold",
      "model_id" => "artifact.station_calendar_report.v1",
      "reference_case" =>
        "curated station calendar report from stale but plausible provider reservation hold",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "provider_contract" => "station_calendar_provider.v1",
        "contract" => "station_calendar_report.v1",
        "provider_entry_status" => "reservation_hold"
      },
      "expected" => %{
        "schema_contract" => "station_calendar_report.v1",
        "model" => "campaign_ground_network_interval_overlay",
        "input_contact_count" => 1,
        "calendar_entry_count" => 1,
        "affected_contact_count" => 1,
        "affected_duration_s" => 40.0,
        "provider_calendar_contention_group_count" => 0,
        "duplicate_affected_contact_id_count" => 0,
        "duplicate_affected_contact_row_count" => 0,
        "affected_contact_ground_station_counts" => %{"equator_prime" => 1},
        "row_derived_affected_contact_ground_station_counts" => %{"equator_prime" => 1},
        "affected_contact_availability_counts" => %{"reserved" => 1},
        "row_derived_affected_contact_availability_counts" => %{"reserved" => 1},
        "direction_counts" => %{"downlink" => 1},
        "row_derived_direction_counts" => %{"downlink" => 1},
        "station_calendar_status_counts" => %{"reserved" => 1},
        "row_derived_station_calendar_status_counts" => %{"reserved" => 1},
        "station_reservation_match_status_counts" => %{"overlap" => 1},
        "row_derived_station_reservation_match_status_counts" => %{"overlap" => 1},
        "stale_reservation_hold_count" => 1,
        "row_derived_stale_reservation_hold_count" => 1,
        "reservation_hold_status_count" => 1,
        "row_derived_reservation_hold_status_count" => 1,
        "row_derived_affected_contact_count" => 1,
        "row_derived_affected_duration_s" => 40.0,
        "row_derived_contact_ids_by_station_reservation_match_status" => %{
          "overlap" => ["dl_hold"]
        },
        "provider_reservation_execution_boundary" => "artifact_only_no_provider_reservation"
      },
      "tolerances" => %{
        "input_contact_count" => 0,
        "calendar_entry_count" => 0,
        "affected_contact_count" => 0,
        "affected_duration_s" => 0,
        "provider_calendar_contention_group_count" => 0,
        "duplicate_affected_contact_id_count" => 0,
        "duplicate_affected_contact_row_count" => 0,
        "stale_reservation_hold_count" => 0,
        "reservation_hold_status_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by station_calendar_report.v1 validation tests"
      ],
      "known_limits" => [
        "internal artifact regression, not external provider validation",
        "checks declared provider-calendar evidence only",
        "does not call provider APIs, reserve station time, or mutate schedules"
      ]
    },
    "fixture.artifact.station_reservation_report.stale_provider_reservation_hold" => %{
      "id" => "fixture.artifact.station_reservation_report.stale_provider_reservation_hold",
      "model_id" => "artifact.station_reservation_report.v1",
      "reference_case" =>
        "curated station reservation summary from stale but plausible provider reservation hold",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "source_contract" => "station_calendar_report.v1",
        "contract" => "station_reservation_report.v1",
        "provider_entry_status" => "reservation_hold"
      },
      "expected" => %{
        "schema_contract" => "station_reservation_report.v1",
        "model" => "artifact_only_station_reservation_summary",
        "affected_contact_reservation_count" => 1,
        "provider_calendar_contention_group_count" => 0,
        "reservation_review_count" => 1,
        "reservation_review_status" => "review_required",
        "station_reservation_match_status_counts" => %{"overlap" => 1},
        "row_derived_station_reservation_match_status_counts" => %{"overlap" => 1},
        "reservation_status_counts" => %{"tentative_hold" => 2},
        "row_derived_reservation_status_counts" => %{"tentative_hold" => 2},
        "reservation_id_order" => "provider_hold_1",
        "row_derived_reservation_id_order" => "provider_hold_1",
        "row_derived_reservation_ids_by_match_status" => %{"overlap" => ["provider_hold_1"]},
        "provider_reservation_execution_boundary" => "artifact_only_no_provider_reservation"
      },
      "tolerances" => %{
        "affected_contact_reservation_count" => 0,
        "provider_calendar_contention_group_count" => 0,
        "reservation_review_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by station_reservation_report.v1 validation tests"
      ],
      "known_limits" => [
        "internal artifact regression, not external provider validation",
        "checks reservation summary routing and no-provider-write boundary only",
        "does not call provider APIs, reserve station time, or mutate schedules"
      ]
    },
    "fixture.artifact.station_reservation_review_summary.v1" => %{
      "id" => "fixture.artifact.station_reservation_review_summary.v1",
      "model_id" => "artifact.station_reservation_review_summary.v1",
      "reference_case" => "checked-in station reservation review summary",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/station_reservation_review_summary_v1.json",
        "source_contract" => "station_reservation_report.v1",
        "contract" => "station_reservation_review_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "station_reservation_review_summary.v1",
        "model" => "artifact_only_station_reservation_review_summary",
        "source_artifact_type" => "station_reservation_report.v1",
        "source" => "station_calendar_report.reservation_evidence",
        "reservation_count" => 3,
        "affected_contact_reservation_count" => 1,
        "provider_calendar_contention_group_count" => 2,
        "reservation_review_status" => "review_required",
        "reservation_expiration_count" => 2,
        "earliest_reservation_expires_at_s" => 240.0,
        "expired_reservation_count" => 1,
        "active_reservation_count" => 1,
        "missing_reservation_expiration_count" => 1,
        "reservation_expiration_status_counts" => %{"active" => 1, "expired" => 1, "missing" => 1},
        "row_derived_reservation_expiration_status_counts" => %{
          "active" => 1,
          "expired" => 1,
          "missing" => 1
        },
        "review_reservation_id_keys" =>
          "reservation_active|reservation_expired|reservation_missing",
        "row_derived_review_reservation_id_keys" =>
          "reservation_active|reservation_expired|reservation_missing",
        "reservation_ids_by_expiration_status" => %{
          "active" => ["reservation_active"],
          "expired" => ["reservation_expired"],
          "missing" => ["reservation_missing"]
        },
        "row_derived_reservation_ids_by_expiration_status" => %{
          "active" => ["reservation_active"],
          "expired" => ["reservation_expired"],
          "missing" => ["reservation_missing"]
        },
        "row_derived_reservation_ids_by_row_type" => %{
          "affected_contact" => ["reservation_expired"],
          "provider_calendar_contention_group" => ["reservation_active", "reservation_missing"]
        },
        "row_derived_required_operator_action_counts" => %{
          "review_station_provider_contention" => 2,
          "review_station_reservation_overlap" => 1
        },
        "row_derived_review_contact_ids_by_expiration_status" => %{
          "expired" => ["dl_source_reserved"]
        },
        "execution_boundary" => "artifact_only_no_provider_reservation",
        "operator_authority" => "not_granted_by_summary",
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "reservation_count" => 0,
        "affected_contact_reservation_count" => 0,
        "provider_calendar_contention_group_count" => 0,
        "reservation_expiration_count" => 0,
        "earliest_reservation_expires_at_s" => 0,
        "expired_reservation_count" => 0,
        "active_reservation_count" => 0,
        "missing_reservation_expiration_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by station_reservation_review_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external provider validation",
        "checks review summary routing and no-provider-write boundary only",
        "does not call provider APIs, accept reservations, or mutate schedules"
      ]
    },
    "fixture.artifact.station_reservation_hold_summary.v1" => %{
      "id" => "fixture.artifact.station_reservation_hold_summary.v1",
      "model_id" => "artifact.station_reservation_hold_summary.v1",
      "reference_case" => "checked-in station reservation hold summary",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/station_reservation_hold_summary_v1.json",
        "source_contract" => "station_reservation_report.v1",
        "contract" => "station_reservation_hold_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "station_reservation_hold_summary.v1",
        "model" => "artifact_only_station_reservation_hold_summary",
        "source_artifact_type" => "station_reservation_report.v1",
        "source" => "station_calendar_report.reservation_evidence",
        "reservation_hold_count" => 2,
        "affected_contact_reservation_hold_count" => 1,
        "provider_calendar_contention_hold_count" => 1,
        "reservation_hold_review_status" => "review_required",
        "reservation_hold_status_counts" => %{"held" => 2},
        "row_derived_reservation_hold_status_counts" => %{"held" => 2},
        "reservation_hold_expiration_status_counts" => %{"expired" => 1, "missing" => 1},
        "row_derived_reservation_hold_expiration_status_counts" => %{
          "expired" => 1,
          "missing" => 1
        },
        "reservation_hold_id_keys" => "reservation_expired|reservation_missing",
        "row_derived_reservation_hold_id_keys" => "reservation_expired|reservation_missing",
        "reservation_hold_ids_by_reserved_by" => %{
          "ops_calendar" => ["reservation_expired"],
          "partner_calendar" => ["reservation_missing"]
        },
        "row_derived_reservation_hold_ids_by_reserved_by" => %{
          "ops_calendar" => ["reservation_expired"],
          "partner_calendar" => ["reservation_missing"]
        },
        "reservation_hold_ids_by_row_type" => %{
          "affected_contact" => ["reservation_expired"],
          "provider_calendar_contention_group" => ["reservation_missing"]
        },
        "row_derived_reservation_hold_ids_by_row_type" => %{
          "affected_contact" => ["reservation_expired"],
          "provider_calendar_contention_group" => ["reservation_missing"]
        },
        "reservation_hold_contact_ids_by_expiration_status" => %{
          "expired" => ["dl_source_reserved"]
        },
        "row_derived_reservation_hold_contact_ids_by_expiration_status" => %{
          "expired" => ["dl_source_reserved"]
        },
        "earliest_reservation_hold_expires_at_s" => 240.0,
        "execution_boundary" => "artifact_only_no_provider_reservation",
        "operator_authority" => "not_granted_by_summary",
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "reservation_hold_count" => 0,
        "affected_contact_reservation_hold_count" => 0,
        "provider_calendar_contention_hold_count" => 0,
        "earliest_reservation_hold_expires_at_s" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by station_reservation_hold_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external provider validation",
        "checks hold summary routing and no-provider-write boundary only",
        "does not call provider APIs, accept reservations, or mutate schedules"
      ]
    },
    "fixture.artifact.station_reservation_hold_import_readiness_summary.v1" => %{
      "id" => "fixture.artifact.station_reservation_hold_import_readiness_summary.v1",
      "model_id" => "artifact.station_reservation_hold_import_readiness_summary.v1",
      "reference_case" => "checked-in station reservation hold import-readiness summary",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" =>
          "study_results/station_reservation_hold_import_readiness_summary_v1.json",
        "source_contract" => "station_reservation_report.v1",
        "contract" => "station_reservation_hold_import_readiness_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "station_reservation_hold_import_readiness_summary.v1",
        "model" => "artifact_only_station_reservation_hold_import_readiness_summary",
        "source_artifact_type" => "station_reservation_report.v1",
        "source" => "station_calendar_report.reservation_evidence",
        "reservation_hold_count" => 2,
        "import_readiness_status" => "review_required",
        "import_classification" => "review_only",
        "ready_for_import_count" => 0,
        "review_required_before_import_count" => 2,
        "no_import_required_count" => 0,
        "reservation_hold_import_status_counts" => %{"review_required_before_import" => 2},
        "row_derived_reservation_hold_import_status_counts" => %{
          "review_required_before_import" => 2
        },
        "required_import_action_counts" => %{
          "review_station_provider_contention" => 1,
          "review_station_reservation_overlap" => 1
        },
        "row_derived_required_import_action_counts" => %{
          "review_station_provider_contention" => 1,
          "review_station_reservation_overlap" => 1
        },
        "reservation_hold_ids_by_import_status" => %{
          "review_required_before_import" => ["reservation_expired", "reservation_missing"]
        },
        "row_derived_reservation_hold_ids_by_import_status" => %{
          "review_required_before_import" => ["reservation_expired", "reservation_missing"]
        },
        "reservation_hold_ids_by_required_import_action" => %{
          "review_station_provider_contention" => ["reservation_missing"],
          "review_station_reservation_overlap" => ["reservation_expired"]
        },
        "row_derived_reservation_hold_ids_by_required_import_action" => %{
          "review_station_provider_contention" => ["reservation_missing"],
          "review_station_reservation_overlap" => ["reservation_expired"]
        },
        "reservation_hold_contact_ids_by_import_status" => %{
          "review_required_before_import" => ["dl_source_reserved"]
        },
        "row_derived_reservation_hold_contact_ids_by_import_status" => %{
          "review_required_before_import" => ["dl_source_reserved"]
        },
        "execution_boundary" => "artifact_only_no_provider_or_cadence_writes",
        "provider_write" => "not_performed_by_summary",
        "cadence_write" => "not_performed_by_summary",
        "reservation_acceptance" => "not_performed_by_summary",
        "operator_authority" => "not_granted_by_import_readiness_summary",
        "model_limit_count" => 5
      },
      "tolerances" => %{
        "reservation_hold_count" => 0,
        "ready_for_import_count" => 0,
        "review_required_before_import_count" => 0,
        "no_import_required_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by station_reservation_hold_import_readiness_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external provider validation",
        "checks hold import-readiness routing and no-provider/no-Cadence-write boundary only",
        "does not call provider APIs, accept reservations, or write Cadence imports"
      ]
    },
    "fixture.artifact.station_calendar_report.v1" => %{
      "id" => "fixture.artifact.station_calendar_report.v1",
      "model_id" => "artifact.station_calendar_report.v1",
      "reference_case" => "checked-in station calendar report artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/station_calendar_report_v1.json",
        "contract" => "station_calendar_report.v1"
      },
      "expected" => %{
        "schema_contract" => "station_calendar_report.v1",
        "model" => "campaign_ground_network_interval_overlay",
        "input_contact_count" => 2,
        "calendar_entry_count" => 2,
        "affected_contact_count" => 2,
        "affected_duration_s" => 80.0,
        "provider_calendar_contention_group_count" => 1,
        "duplicate_affected_contact_id_count" => 0,
        "duplicate_affected_contact_row_count" => 0,
        "affected_contact_ground_station_counts" => %{"equator_prime" => 2},
        "row_derived_affected_contact_ground_station_counts" => %{"equator_prime" => 2},
        "affected_contact_availability_counts" => %{
          "reduced_capacity" => 1,
          "reserved" => 1
        },
        "row_derived_affected_contact_availability_counts" => %{
          "reduced_capacity" => 1,
          "reserved" => 1
        },
        "direction_counts" => %{"command" => 1, "downlink" => 1},
        "row_derived_direction_counts" => %{"command" => 1, "downlink" => 1},
        "station_calendar_status_counts" => %{"available" => 1, "reserved" => 1},
        "row_derived_station_calendar_status_counts" => %{
          "available" => 1,
          "reserved" => 1
        },
        "station_reservation_match_status_counts" => %{"overlap" => 1},
        "row_derived_station_reservation_match_status_counts" => %{"overlap" => 1},
        "stale_reservation_hold_count" => 0,
        "row_derived_stale_reservation_hold_count" => 0,
        "reservation_hold_status_count" => 0,
        "row_derived_reservation_hold_status_count" => 0,
        "row_derived_affected_contact_count" => 2,
        "row_derived_affected_duration_s" => 80.0,
        "row_derived_contact_ids_by_station_reservation_match_status" => %{
          "overlap" => ["cmd_1"]
        },
        "provider_reservation_execution_boundary" => "artifact_only_no_provider_reservation"
      },
      "tolerances" => %{
        "input_contact_count" => 0,
        "calendar_entry_count" => 0,
        "affected_contact_count" => 0,
        "affected_duration_s" => 0,
        "provider_calendar_contention_group_count" => 0,
        "duplicate_affected_contact_id_count" => 0,
        "duplicate_affected_contact_row_count" => 0,
        "stale_reservation_hold_count" => 0,
        "reservation_hold_status_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external provider validation",
        "checks station-calendar overlay counts and artifact-only execution boundary only"
      ]
    },
    "fixture.artifact.provider_counteroffer_report.v1" => %{
      "id" => "fixture.artifact.provider_counteroffer_report.v1",
      "model_id" => "artifact.provider_counteroffer_report.v1",
      "reference_case" =>
        "curated provider counteroffer report preserving timing and cost impact evidence",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "provider_contract" => "station_calendar_provider.v1",
        "contract" => "provider_counteroffer_report.v1",
        "provider_counteroffer_status" => "proposed"
      },
      "expected" => %{
        "schema_contract" => "provider_counteroffer_report.v1",
        "model" => "artifact_only_provider_counteroffer_review",
        "source_artifact_type" => "station_calendar_report.v1",
        "counteroffer_count" => 1,
        "row_derived_counteroffer_count" => 1,
        "reviewable_count" => 1,
        "row_derived_reviewable_count" => 1,
        "counteroffer_cost_delta_count" => 1,
        "row_derived_counteroffer_cost_delta_count" => 1,
        "counteroffer_cost_delta_total" => 125.5,
        "row_derived_counteroffer_cost_delta_total" => 125.5,
        "counteroffer_lock_deadline_count" => 1,
        "row_derived_counteroffer_lock_deadline_count" => 1,
        "earliest_counteroffer_lock_deadline_s" => 150.0,
        "row_derived_earliest_counteroffer_lock_deadline_s" => 150.0,
        "timing_shift_counteroffer_count" => 1,
        "row_derived_timing_shift_counteroffer_count" => 1,
        "provider_counteroffer_start_delta_s" => 30.0,
        "provider_counteroffer_end_delta_s" => 30.0,
        "required_operator_action_count" => 1,
        "row_derived_required_operator_action_count" => 1,
        "provider_write_boundary" => "artifact_only_no_provider_writes"
      },
      "tolerances" => %{
        "counteroffer_count" => 0,
        "row_derived_counteroffer_count" => 0,
        "reviewable_count" => 0,
        "row_derived_reviewable_count" => 0,
        "counteroffer_cost_delta_count" => 0,
        "row_derived_counteroffer_cost_delta_count" => 0,
        "counteroffer_cost_delta_total" => 0,
        "row_derived_counteroffer_cost_delta_total" => 0,
        "counteroffer_lock_deadline_count" => 0,
        "row_derived_counteroffer_lock_deadline_count" => 0,
        "earliest_counteroffer_lock_deadline_s" => 0,
        "row_derived_earliest_counteroffer_lock_deadline_s" => 0,
        "timing_shift_counteroffer_count" => 0,
        "row_derived_timing_shift_counteroffer_count" => 0,
        "provider_counteroffer_start_delta_s" => 0,
        "provider_counteroffer_end_delta_s" => 0,
        "required_operator_action_count" => 0,
        "row_derived_required_operator_action_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by provider_counteroffer_report.v1 validation tests"
      ],
      "known_limits" => [
        "internal artifact regression, not external provider validation",
        "checks declared provider counteroffer timing and cost evidence only",
        "does not call provider APIs, accept counteroffers, reserve station time, or mutate schedules"
      ]
    },
    "fixture.artifact.provider_counteroffer_import_readiness_summary.v1" => %{
      "id" => "fixture.artifact.provider_counteroffer_import_readiness_summary.v1",
      "model_id" => "artifact.provider_counteroffer_import_readiness_summary.v1",
      "reference_case" => "checked-in provider counteroffer import-readiness summary artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/provider_counteroffer_import_readiness_summary_v1.json",
        "contract" => "provider_counteroffer_import_readiness_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "provider_counteroffer_import_readiness_summary.v1",
        "model" => "artifact_only_provider_counteroffer_import_readiness_summary",
        "source" => "station_calendar_report.affected_contacts",
        "source_artifact_id" => "station_calendar_report",
        "source_artifact_type" => "provider_counteroffer_report.v1",
        "source_counteroffer_artifact_type" => "station_calendar_report.v1",
        "counteroffer_count" => 1,
        "reviewable_count" => 1,
        "row_derived_reviewable_count" => 1,
        "import_readiness_status" => "review_required",
        "import_classification" => "review_only",
        "ready_for_import_count" => 0,
        "review_required_before_import_count" => 1,
        "no_import_required_count" => 0,
        "provider_counteroffer_import_status_counts" => %{
          "review_required_before_import" => 1
        },
        "row_derived_provider_counteroffer_import_status_counts" => %{
          "review_required_before_import" => 1
        },
        "required_import_action_counts" => %{"review_provider_counteroffer" => 1},
        "row_derived_required_import_action_counts" => %{
          "review_provider_counteroffer" => 1
        },
        "counteroffer_lock_deadline_status_counts" => %{"expired" => 1},
        "row_derived_counteroffer_lock_deadline_status_counts" => %{"expired" => 1},
        "counteroffer_status_counts" => %{"proposed" => 1},
        "counteroffer_negotiation_state_counts" => %{"proposed" => 1},
        "counteroffer_ids_by_import_status" => %{
          "review_required_before_import" => ["provider_offer_1"]
        },
        "counteroffer_ids_by_required_import_action" => %{
          "review_provider_counteroffer" => ["provider_offer_1"]
        },
        "counteroffer_ids_by_lock_deadline_status" => %{
          "expired" => ["provider_offer_1"]
        },
        "row_derived_counteroffer_ids_by_import_status" => %{
          "review_required_before_import" => ["provider_offer_1"]
        },
        "row_derived_counteroffer_ids_by_required_import_action" => %{
          "review_provider_counteroffer" => ["provider_offer_1"]
        },
        "row_derived_counteroffer_ids_by_lock_deadline_status" => %{
          "expired" => ["provider_offer_1"]
        },
        "review_counteroffer_ids" => "provider_offer_1",
        "no_import_required_counteroffer_ids" => "",
        "import_readiness_row_count" => 1,
        "execution_boundary" => "artifact_only_no_provider_or_cadence_writes",
        "operator_authority" => "not_granted_by_import_readiness_summary",
        "provider_write" => "not_performed_by_summary",
        "cadence_write" => "not_performed_by_summary",
        "offer_acceptance" => "not_performed_by_summary",
        "deadline_evaluation" => "relative_to_now_s",
        "now_s" => 160.0,
        "assumption_source" => "provider_counteroffer_report.v1"
      },
      "tolerances" => %{
        "counteroffer_count" => 0,
        "reviewable_count" => 0,
        "row_derived_reviewable_count" => 0,
        "ready_for_import_count" => 0,
        "review_required_before_import_count" => 0,
        "no_import_required_count" => 0,
        "import_readiness_row_count" => 0,
        "now_s" => 0
      },
      "evidence" => [
        "generated by OrbitalDynamics.Communications.StationCalendar.provider_counteroffer_import_readiness_summary/2",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external provider validation",
        "checks import-readiness routing and no provider/Cadence write assumptions only"
      ]
    },
    "fixture.artifact.provider_counteroffer_plan_impact_summary.v1" => %{
      "id" => "fixture.artifact.provider_counteroffer_plan_impact_summary.v1",
      "model_id" => "artifact.provider_counteroffer_plan_impact_summary.v1",
      "reference_case" => "checked-in provider counteroffer plan-impact summary artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/provider_counteroffer_plan_impact_summary_v1.json",
        "contract" => "provider_counteroffer_plan_impact_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "provider_counteroffer_plan_impact_summary.v1",
        "model" => "artifact_only_provider_counteroffer_plan_impact_summary",
        "source" => "station_calendar_report.affected_contacts",
        "source_artifact_id" => "station_calendar_report",
        "source_artifact_type" => "provider_counteroffer_report.v1",
        "source_counteroffer_artifact_type" => "station_calendar_report.v1",
        "counteroffer_count" => 1,
        "reviewable_count" => 1,
        "row_derived_reviewable_count" => 1,
        "plan_impact_status" => "review_required",
        "timing_shift_counteroffer_count" => 1,
        "row_derived_timing_shift_counteroffer_count" => 1,
        "counteroffer_cost_delta_count" => 1,
        "row_derived_counteroffer_cost_delta_count" => 1,
        "counteroffer_cost_delta_total" => 125.5,
        "row_derived_counteroffer_cost_delta_total" => 125.5,
        "counteroffer_lock_deadline_status_counts" => %{"active" => 1},
        "row_derived_counteroffer_lock_deadline_status_counts" => %{"active" => 1},
        "affected_station_calendar_entry_ids" => "provider_counteroffer_window",
        "affected_provider_entry_ids" => "provider_counteroffer_window",
        "impact_counteroffer_ids" => "provider_offer_1",
        "timing_shift_counteroffer_ids" => "provider_offer_1",
        "cost_delta_counteroffer_ids" => "provider_offer_1",
        "counteroffer_ids_by_lock_deadline_status" => %{"active" => ["provider_offer_1"]},
        "row_derived_counteroffer_ids_by_lock_deadline_status" => %{
          "active" => ["provider_offer_1"]
        },
        "impact_row_count" => 1,
        "provider_counteroffer_start_delta_s" => 30.0,
        "provider_counteroffer_end_delta_s" => 30.0,
        "provider_counteroffer_duration_delta_s" => 0.0,
        "execution_boundary" => "artifact_only_no_provider_writes",
        "operator_authority" => "not_granted_by_summary",
        "deadline_evaluation" => "relative_to_now_s",
        "now_s" => 120.0,
        "assumption_source" => "provider_counteroffer_report.v1"
      },
      "tolerances" => %{
        "counteroffer_count" => 0,
        "reviewable_count" => 0,
        "row_derived_reviewable_count" => 0,
        "timing_shift_counteroffer_count" => 0,
        "row_derived_timing_shift_counteroffer_count" => 0,
        "counteroffer_cost_delta_count" => 0,
        "row_derived_counteroffer_cost_delta_count" => 0,
        "counteroffer_cost_delta_total" => 0,
        "row_derived_counteroffer_cost_delta_total" => 0,
        "impact_row_count" => 0,
        "provider_counteroffer_start_delta_s" => 0,
        "provider_counteroffer_end_delta_s" => 0,
        "provider_counteroffer_duration_delta_s" => 0,
        "now_s" => 0
      },
      "evidence" => [
        "generated by OrbitalDynamics.Communications.StationCalendar.provider_counteroffer_plan_impact_summary/2",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external provider validation",
        "checks timing/cost impact identity and no provider-write assumptions only"
      ]
    },
    "fixture.artifact.provider_counteroffer_review_summary.v1" => %{
      "id" => "fixture.artifact.provider_counteroffer_review_summary.v1",
      "model_id" => "artifact.provider_counteroffer_review_summary.v1",
      "reference_case" => "checked-in provider counteroffer review summary artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/provider_counteroffer_review_summary_v1.json",
        "contract" => "provider_counteroffer_review_summary.v1"
      },
      "expected" => %{
        "schema_contract" => "provider_counteroffer_review_summary.v1",
        "model" => "artifact_only_provider_counteroffer_review_summary",
        "source" => "station_calendar_report.affected_contacts",
        "source_artifact_id" => "station_calendar_report",
        "source_artifact_type" => "provider_counteroffer_report.v1",
        "source_counteroffer_artifact_type" => "station_calendar_report.v1",
        "counteroffer_count" => 1,
        "reviewable_count" => 1,
        "row_derived_reviewable_count" => 1,
        "counteroffer_review_status" => "review_required",
        "counteroffer_status_counts" => %{"proposed" => 1},
        "counteroffer_negotiation_state_counts" => %{"proposed" => 1},
        "counteroffer_lock_deadline_count" => 1,
        "earliest_counteroffer_lock_deadline_s" => 150.0,
        "counteroffer_lock_deadline_status_counts" => %{"expired" => 1},
        "row_derived_counteroffer_lock_deadline_status_counts" => %{"expired" => 1},
        "counteroffer_ids_by_lock_deadline_status" => %{
          "expired" => ["provider_offer_1"]
        },
        "row_derived_counteroffer_ids_by_lock_deadline_status" => %{
          "expired" => ["provider_offer_1"]
        },
        "expired_counteroffer_lock_deadline_count" => 1,
        "active_counteroffer_lock_deadline_count" => 0,
        "missing_counteroffer_lock_deadline_count" => 0,
        "review_counteroffer_ids" => "provider_offer_1",
        "row_derived_review_counteroffer_ids" => "provider_offer_1",
        "row_count" => 1,
        "review_row_count" => 1,
        "execution_boundary" => "artifact_only_no_provider_writes",
        "operator_authority" => "not_granted_by_summary",
        "deadline_evaluation" => "relative_to_now_s",
        "now_s" => 160.0,
        "assumption_source" => "provider_counteroffer_report.v1"
      },
      "tolerances" => %{
        "counteroffer_count" => 0,
        "reviewable_count" => 0,
        "row_derived_reviewable_count" => 0,
        "counteroffer_lock_deadline_count" => 0,
        "earliest_counteroffer_lock_deadline_s" => 0,
        "expired_counteroffer_lock_deadline_count" => 0,
        "active_counteroffer_lock_deadline_count" => 0,
        "missing_counteroffer_lock_deadline_count" => 0,
        "row_count" => 0,
        "review_row_count" => 0,
        "now_s" => 0
      },
      "evidence" => [
        "generated by OrbitalDynamics.Communications.StationCalendar.provider_counteroffer_review_summary/2",
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external provider validation",
        "checks review status, deadline routing, and no provider-write assumptions only"
      ]
    },
    "fixture.artifact.model_acceptance_report.operational_import" => %{
      "id" => "fixture.artifact.model_acceptance_report.operational_import",
      "model_id" => "artifact.model_acceptance_report.v1",
      "reference_case" =>
        "curated model acceptance report for operational import evidence boundaries",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "contract" => "model_acceptance_report.v1",
        "intended_use" => "operational_import",
        "model_ids" => [
          "orbit_data.simple_json",
          "event.access_windows",
          "propagator.two_body",
          "missing.model"
        ]
      },
      "expected" => %{
        "schema_contract" => "model_acceptance_report.v1",
        "model" => "registry_model_acceptance_classifier",
        "intended_use" => "operational_import",
        "status" => "blocked",
        "model_count" => 4,
        "record_count" => 3,
        "row_count" => 4,
        "accepted_count" => 1,
        "review_required_count" => 1,
        "blocked_count" => 2,
        "unknown_model_count" => 1,
        "status_counts" => %{
          "accepted" => 1,
          "blocked" => 2,
          "review_required" => 1
        },
        "validation_level_counts" => %{
          "analysis" => 1,
          "artifact_contract" => 1,
          "educational" => 1,
          "unknown" => 1
        },
        "model_ids_by_status" => %{
          "accepted" => ["orbit_data.simple_json"],
          "blocked" => ["propagator.two_body", "missing.model"],
          "review_required" => ["event.access_windows"]
        },
        "model_ids_by_validation_level" => %{
          "analysis" => ["event.access_windows"],
          "artifact_contract" => ["orbit_data.simple_json"],
          "educational" => ["propagator.two_body"],
          "unknown" => ["missing.model"]
        },
        "model_ids_by_intended_use" => %{
          "operational_import" => [
            "orbit_data.simple_json",
            "event.access_windows",
            "propagator.two_body",
            "missing.model"
          ]
        }
      },
      "tolerances" => %{
        "model_count" => 0,
        "record_count" => 0,
        "row_count" => 0,
        "accepted_count" => 0,
        "review_required_count" => 0,
        "blocked_count" => 0,
        "unknown_model_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by model_acceptance_report.v1 validation tests"
      ],
      "known_limits" => [
        "internal artifact regression, not external model certification",
        "checks intended-use acceptance counts and unknown-model blocking only"
      ]
    },
    "fixture.artifact.validation_safety_case_summary.v1" => %{
      "id" => "fixture.artifact.validation_safety_case_summary.v1",
      "model_id" => "artifact.validation_safety_case_summary.v1",
      "reference_case" =>
        "curated validation safety-case summary for artifact-only handoff boundaries",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "contract" => "validation_safety_case_summary.v1",
        "artifact_path" => "study_results/validation_safety_case_summary_v1.json",
        "case_id" => "case:compatibility-example"
      },
      "expected" => %{
        "schema_contract" => "validation_safety_case_summary.v1",
        "model" => "artifact_only_validation_safety_case_summary",
        "source" => "validation.safety_case_evidence",
        "summary_id" => "validation_safety_case:case:compatibility-example",
        "case_id" => "case:compatibility-example",
        "status" => "blocked",
        "evidence_count" => 4,
        "accepted_evidence_count" => 1,
        "review_required_evidence_count" => 1,
        "blocked_evidence_count" => 2,
        "model_accepted_count" => 1,
        "model_review_required_count" => 1,
        "model_blocked_count" => 0,
        "unknown_model_count" => 0,
        "readiness_review_required_count" => 0,
        "readiness_blocked_count" => 0,
        "ready_for_import_count" => 0,
        "quality_gate_review_count" => 0,
        "quality_gate_blocked_count" => 0,
        "schema_error_count" => 2,
        "schema_warning_count" => 0,
        "schema_validation_report_count" => 0,
        "schema_validation_failed_report_count" => 0,
        "fixture_passed_count" => 0,
        "fixture_failed_count" => 0,
        "input_contract_count" => 2,
        "evidence_status_counts" => %{
          "accepted_for_use" => 1,
          "blocked" => 2,
          "review_required" => 1
        },
        "model_acceptance_evidence_status_counts" => %{
          "accepted" => 1,
          "review_required" => 1
        },
        "model_acceptance_evidence_model_ids_by_status" => %{
          "accepted" => ["orbit_data.simple_json"],
          "review_required" => ["event.access_windows"]
        },
        "model_acceptance_evidence_model_ids_by_validation_level" => %{
          "analysis" => ["event.access_windows"],
          "artifact_contract" => ["orbit_data.simple_json"]
        },
        "model_acceptance_evidence_model_ids_by_intended_use" => %{
          "operational_import" => ["orbit_data.simple_json", "event.access_windows"]
        },
        "evidence_refs_by_status" => %{
          "accepted_for_use" => ["schema_validation_report.v1:candidate_refresh.v1"],
          "blocked" => [
            "schema_validation_report.v1:candidate_refresh.v1",
            "schema_validation_report.v1:candidate_refresh.v1"
          ],
          "review_required" => [
            "model_acceptance_report.v1:model_acceptance:operational_import:orbit_data.simple_json__event.access_windows"
          ]
        },
        "evidence_refs_by_contract" => %{
          "model_acceptance_report.v1" => [
            "model_acceptance_report.v1:model_acceptance:operational_import:orbit_data.simple_json__event.access_windows"
          ],
          "schema_validation_report.v1" => [
            "schema_validation_report.v1:candidate_refresh.v1",
            "schema_validation_report.v1:candidate_refresh.v1",
            "schema_validation_report.v1:candidate_refresh.v1"
          ]
        },
        "model_limit_count" => 3,
        "execution_boundary" => "artifact_only_no_cadence_write",
        "certification_authority" => "not_granted_by_summary",
        "operator_authority" => "not_granted_by_summary"
      },
      "tolerances" => %{
        "evidence_count" => 0,
        "accepted_evidence_count" => 0,
        "review_required_evidence_count" => 0,
        "blocked_evidence_count" => 0,
        "model_accepted_count" => 0,
        "model_review_required_count" => 0,
        "model_blocked_count" => 0,
        "unknown_model_count" => 0,
        "readiness_review_required_count" => 0,
        "readiness_blocked_count" => 0,
        "ready_for_import_count" => 0,
        "quality_gate_review_count" => 0,
        "quality_gate_blocked_count" => 0,
        "schema_error_count" => 0,
        "schema_warning_count" => 0,
        "schema_validation_report_count" => 0,
        "schema_validation_failed_report_count" => 0,
        "fixture_passed_count" => 0,
        "fixture_failed_count" => 0,
        "input_contract_count" => 0,
        "model_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by validation_safety_case_summary.v1 validation tests"
      ],
      "known_limits" => [
        "internal artifact regression, not external safety-case certification",
        "checks evidence counts, routing maps, and authority boundaries only",
        "does not approve imports, certify models, or write to Cadence"
      ]
    }
  }

  def all, do: @fixtures

  def fetch(id) when is_binary(id), do: Map.fetch(@fixtures, id)
end
