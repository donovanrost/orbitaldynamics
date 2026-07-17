defmodule OrbitalDynamics.Validation.ReferenceFixtures.ProviderCapacityPackArtifacts do
  @moduledoc false

  @fixtures %{
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
    }
  }

  def all, do: @fixtures
end
