defmodule OrbitalDynamics.Validation.ReferenceFixtures.ContactContentionArtifacts do
  @moduledoc false

  @fixtures %{
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
    }
  }

  def all, do: @fixtures
end
