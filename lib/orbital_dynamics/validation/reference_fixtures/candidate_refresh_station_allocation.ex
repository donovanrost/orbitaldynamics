defmodule OrbitalDynamics.Validation.ReferenceFixtures.CandidateRefreshStationAllocation do
  @moduledoc false

  @fixtures %{
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
    }
  }

  def all, do: @fixtures
end
