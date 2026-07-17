defmodule OrbitalDynamics.Validation.ReferenceFixtures.StationReservationArtifacts do
  @moduledoc false

  @fixtures %{
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
    }
  }

  def all, do: @fixtures
end
