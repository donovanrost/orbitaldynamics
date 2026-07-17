defmodule OrbitalDynamics.Validation.ReferenceFixtures.ContactAllocationArtifacts do
  @moduledoc false

  @fixtures %{
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
    }
  }

  def all, do: @fixtures
end
