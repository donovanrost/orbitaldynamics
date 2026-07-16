defmodule OrbitalDynamics.CandidateRefresh.ContactAllocationProviderReservationRequestAggregateReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "source report summary replays aggregate-only provider reservation request summaries" do
    refresh = %{
      "source_contact_allocation_provider_reservation_request_summary" => %{
        "schema_contract" => "contact_allocation_provider_reservation_request_summary.v1",
        "model" => "artifact_only_contact_allocation_provider_reservation_request_summary",
        "source_artifact_type" => "contact_allocation_report.v1",
        "source" => "unit_test.provider_reservation_aggregate_summary",
        "provider_reservation_candidate_contact_count" => 2,
        "provider_reservation_request_contact_count" => 1,
        "provider_reservation_review_contact_count" => 1,
        "provider_reservation_no_request_contact_count" => 3,
        "provider_reservation_request_status" => "review_required",
        "provider_reservation_request_contact_ids" => ["aggregate_request_contact"],
        "provider_reservation_review_contact_ids" => ["aggregate_review_contact"],
        "provider_reservation_no_request_contact_ids" => [
          "aggregate_no_request_contact"
        ],
        "provider_reservation_request_contact_ids_by_ground_station_id" => %{
          "equator_prime" => ["aggregate_request_contact"]
        },
        "provider_reservation_request_contact_ids_by_direction" => %{
          "downlink" => ["aggregate_request_contact"]
        },
        "provider_reservation_no_request_contact_ids_by_direction" => %{
          "tracking" => ["aggregate_no_request_contact"]
        },
        "provider_reservation_request_contact_ids_by_match_status" => %{
          "matched" => ["aggregate_request_contact"]
        },
        "provider_reservation_request_ids_by_match_status" => %{
          "matched" => ["aggregate_reservation"]
        }
      }
    }

    assert %{
             "source_report_count" => 1,
             "source_report_contact_allocation_provider_reservation_candidate_contact_count" => 2,
             "source_report_contact_allocation_provider_reservation_request_contact_count" => 1,
             "source_report_contact_allocation_provider_reservation_review_contact_count" => 1,
             "source_report_contact_allocation_provider_reservation_no_request_contact_count" =>
               3,
             "source_report_contact_allocation_provider_reservation_request_status_counts" => %{
               "review_required" => 1
             },
             "source_report_contact_allocation_provider_reservation_request_contact_ids" => [
               "aggregate_request_contact"
             ],
             "source_report_contact_allocation_provider_reservation_review_contact_ids" => [
               "aggregate_review_contact"
             ],
             "source_report_contact_allocation_provider_reservation_no_request_contact_ids" => [
               "aggregate_no_request_contact"
             ],
             "source_report_contact_allocation_provider_reservation_request_contact_ids_by_ground_station" =>
               %{"equator_prime" => ["aggregate_request_contact"]},
             "source_report_contact_allocation_provider_reservation_request_contact_ids_by_direction" =>
               %{"downlink" => ["aggregate_request_contact"]},
             "source_report_contact_allocation_provider_reservation_no_request_contact_ids_by_direction" =>
               %{"tracking" => ["aggregate_no_request_contact"]},
             "source_report_contact_allocation_provider_reservation_request_contact_ids_by_match_status" =>
               %{"matched" => ["aggregate_request_contact"]},
             "source_report_contact_allocation_provider_reservation_request_ids_by_match_status" =>
               %{"matched" => ["aggregate_reservation"]},
             "source_reports" => %{
               "contact_allocation_report" => %{
                 "paths" => ["source_contact_allocation_provider_reservation_request_summary"],
                 "provider_reservation_request_summary_schema_contract" =>
                   "contact_allocation_provider_reservation_request_summary.v1"
               }
             }
           } = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "provider_reservation_candidate_contact_count" => 2,
             "provider_reservation_request_contact_count" => 1,
             "provider_reservation_review_contact_count" => 1,
             "provider_reservation_no_request_contact_count" => 3,
             "provider_reservation_request_status_counts" => %{"review_required" => 1},
             "provider_reservation_request_contact_ids" => ["aggregate_request_contact"],
             "provider_reservation_review_contact_ids" => ["aggregate_review_contact"],
             "provider_reservation_no_request_contact_ids" => ["aggregate_no_request_contact"],
             "provider_reservation_request_contact_ids_by_match_status" => %{
               "matched" => ["aggregate_request_contact"]
             },
             "provider_reservation_request_ids_by_match_status" => %{
               "matched" => ["aggregate_reservation"]
             },
             "branch_local_provider_reservation_request_pressure" => true,
             "branch_local_contact_allocation_pressure" => true
           } = CandidateRefresh.contact_allocation_replay_summary(refresh)
  end

  test "source report summary replays provider reservation request summaries from result artifacts" do
    summary = %{
      "schema_contract" => "contact_allocation_provider_reservation_request_summary.v1",
      "model" => "artifact_only_contact_allocation_provider_reservation_request_summary",
      "source_artifact_type" => "contact_allocation_report.v1",
      "source" => "unit_test.provider_reservation_request_summary.wrapper",
      "provider_reservation_candidate_contact_count" => 2,
      "provider_reservation_request_contact_count" => 1,
      "provider_reservation_review_contact_count" => 1,
      "provider_reservation_no_request_contact_count" => 1,
      "provider_reservation_request_status" => "review_required",
      "provider_reservation_request_contact_ids" => ["wrapper_request_contact"],
      "provider_reservation_review_contact_ids" => ["wrapper_review_contact"],
      "provider_reservation_no_request_contact_ids" => ["wrapper_no_request_contact"],
      "provider_reservation_request_contact_ids_by_ground_station_id" => %{
        "equator_prime" => ["wrapper_request_contact"]
      },
      "provider_reservation_review_contact_ids_by_ground_station_id" => %{
        "polar_prime" => ["wrapper_review_contact"]
      },
      "provider_reservation_no_request_contact_ids_by_direction" => %{
        "tracking" => ["wrapper_no_request_contact"]
      },
      "provider_reservation_request_contact_ids_by_direction" => %{
        "downlink" => ["wrapper_request_contact"]
      },
      "provider_reservation_review_contact_ids_by_direction" => %{
        "uplink" => ["wrapper_review_contact"]
      },
      "provider_reservation_no_request_contact_ids_by_direction_and_ground_station" => %{
        "tracking" => %{"polar_prime" => ["wrapper_no_request_contact"]}
      },
      "provider_reservation_request_contact_ids_by_direction_and_ground_station" => %{
        "downlink" => %{"equator_prime" => ["wrapper_request_contact"]}
      },
      "provider_reservation_review_contact_ids_by_direction_and_ground_station" => %{
        "uplink" => %{"polar_prime" => ["wrapper_review_contact"]}
      },
      "provider_reservation_request_contact_ids_by_match_status" => %{
        "matched" => ["wrapper_request_contact"]
      },
      "provider_reservation_review_contact_ids_by_match_status" => %{
        "overlap" => ["wrapper_review_contact"]
      },
      "provider_reservation_request_ids_by_match_status" => %{
        "matched" => ["wrapper_reservation"]
      },
      "provider_reservation_review_ids_by_match_status" => %{
        "overlap" => ["wrapper_review_reservation"]
      },
      "provider_reservation_request_rows" => [
        %{
          "contact_id" => "wrapper_request_contact",
          "allocation_status" => "allocated",
          "ground_station_id" => "equator_prime",
          "direction" => "Down Link",
          "station_reservation_id" => "wrapper_reservation",
          "station_reservation_match_status" => "matched",
          "station_reservation_status" => "confirmed",
          "trust_boundary" => "wrapper_request_row"
        }
      ],
      "provider_reservation_review_rows" => [
        %{
          "contact_id" => "wrapper_review_contact",
          "allocation_status" => "allocated",
          "ground_station_id" => "polar_prime",
          "direction" => "uplink",
          "station_reservation_id" => "wrapper_review_reservation",
          "station_reservation_match_status" => "overlap",
          "station_reservation_status" => "confirmed",
          "trust_boundary" => "wrapper_review_row"
        }
      ],
      "provenance" => %{"trust_boundary" => "wrapper_provider_reservation_summary"},
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
        "provider_reservation_execution" => "not_performed_by_summary"
      }
    }

    refresh = %{
      "source_result_artifact" => %{
        "source_contact_allocation_provider_reservation_request_summary" => summary
      }
    }

    assert %{
             "source_report_contact_allocation_provider_reservation_candidate_contact_count" => 2,
             "source_report_contact_allocation_provider_reservation_request_contact_count" => 1,
             "source_report_contact_allocation_provider_reservation_review_contact_count" => 1,
             "source_report_contact_allocation_provider_reservation_no_request_contact_count" =>
               1,
             "source_report_contact_allocation_provider_reservation_request_status_counts" => %{
               "review_required" => 1
             },
             "source_report_contact_allocation_provider_reservation_request_contact_ids" => [
               "wrapper_request_contact"
             ],
             "source_report_contact_allocation_provider_reservation_review_contact_ids" => [
               "wrapper_review_contact"
             ],
             "source_report_contact_allocation_provider_reservation_no_request_contact_ids" => [
               "wrapper_no_request_contact"
             ],
             "source_report_contact_allocation_provider_reservation_request_contact_ids_by_direction" =>
               %{"downlink" => ["wrapper_request_contact"]},
             "source_report_contact_allocation_provider_reservation_review_contact_ids_by_direction" =>
               %{"uplink" => ["wrapper_review_contact"]},
             "source_report_contact_allocation_provider_reservation_no_request_contact_ids_by_direction_and_ground_station" =>
               %{"tracking" => %{"polar_prime" => ["wrapper_no_request_contact"]}},
             "source_report_contact_allocation_provider_reservation_request_contact_ids_by_direction_and_ground_station" =>
               %{"downlink" => %{"equator_prime" => ["wrapper_request_contact"]}},
             "source_report_contact_allocation_provider_reservation_review_contact_ids_by_direction_and_ground_station" =>
               %{"uplink" => %{"polar_prime" => ["wrapper_review_contact"]}},
             "source_report_contact_allocation_provider_reservation_request_ids_by_match_status" =>
               %{"matched" => ["wrapper_reservation"]},
             "source_report_contact_allocation_provider_reservation_review_ids_by_match_status" =>
               %{"overlap" => ["wrapper_review_reservation"]},
             "source_reports" => %{
               "contact_allocation_report" => %{
                 "paths" => [
                   "source_result_artifact.source_contact_allocation_provider_reservation_request_summary"
                 ],
                 "count" => 1,
                 "row_count" => 2,
                 "provider_reservation_no_request_contact_ids_by_direction_and_ground_station" =>
                   %{"tracking" => %{"polar_prime" => ["wrapper_no_request_contact"]}},
                 "provider_reservation_request_contact_ids_by_direction_and_ground_station" => %{
                   "downlink" => %{"equator_prime" => ["wrapper_request_contact"]}
                 },
                 "provider_reservation_review_contact_ids_by_direction_and_ground_station" => %{
                   "uplink" => %{"polar_prime" => ["wrapper_review_contact"]}
                 },
                 "provider_reservation_request_summary_schema_contract" =>
                   "contact_allocation_provider_reservation_request_summary.v1",
                 "trust_boundary_status" => "declared",
                 "trust_boundaries" => [
                   "wrapper_provider_reservation_summary",
                   "wrapper_request_row",
                   "wrapper_review_row"
                 ]
               }
             }
           } = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "source_report_count" => 1,
             "source_report_row_count" => 2,
             "source_report_paths" => [
               "source_result_artifact.source_contact_allocation_provider_reservation_request_summary"
             ],
             "provider_reservation_candidate_contact_count" => 2,
             "provider_reservation_request_contact_count" => 1,
             "provider_reservation_review_contact_count" => 1,
             "provider_reservation_no_request_contact_count" => 1,
             "provider_reservation_request_status_counts" => %{"review_required" => 1},
             "provider_reservation_request_summary_schema_contract" =>
               "contact_allocation_provider_reservation_request_summary.v1",
             "provider_reservation_request_contact_ids_by_direction" => %{
               "downlink" => ["wrapper_request_contact"]
             },
             "provider_reservation_review_contact_ids_by_direction" => %{
               "uplink" => ["wrapper_review_contact"]
             },
             "provider_reservation_no_request_contact_ids_by_direction_and_ground_station" => %{
               "tracking" => %{"polar_prime" => ["wrapper_no_request_contact"]}
             },
             "provider_reservation_request_contact_ids_by_direction_and_ground_station" => %{
               "downlink" => %{"equator_prime" => ["wrapper_request_contact"]}
             },
             "provider_reservation_review_contact_ids_by_direction_and_ground_station" => %{
               "uplink" => %{"polar_prime" => ["wrapper_review_contact"]}
             },
             "provider_reservation_request_ids_by_match_status" => %{
               "matched" => ["wrapper_reservation"]
             },
             "provider_reservation_review_ids_by_match_status" => %{
               "overlap" => ["wrapper_review_reservation"]
             },
             "trust_boundaries" => [
               "wrapper_provider_reservation_summary",
               "wrapper_request_row",
               "wrapper_review_row"
             ],
             "branch_local_provider_reservation_request_pressure" => true,
             "branch_local_contact_allocation_pressure" => true
           } = CandidateRefresh.contact_allocation_replay_summary(refresh)
  end
end
