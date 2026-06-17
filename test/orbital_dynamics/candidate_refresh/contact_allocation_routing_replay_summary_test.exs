defmodule OrbitalDynamics.CandidateRefresh.ContactAllocationRoutingReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "source report summary aggregates contact allocation blocked-input routing" do
    refresh = %{
      "source_contact_allocation_report" => %{
        "schema_contract" => "contact_allocation_report.v1",
        "rows" => [
          %{
            "contact_id" => "invalid_contact",
            "allocation_status" => "blocked",
            "invalid_contact_input" => true,
            "ground_station_id" => "equator_prime"
          },
          %{
            "contact_id" => "status_blocked_contact",
            "allocation_status" => "blocked",
            "allocation_reason" => "activity_status_completed",
            "ground_station_id" => "polar_prime"
          },
          %{
            "contact_id" => "resource_blocked_contact",
            "allocation_status" => "blocked",
            "allocation_reason" => "resource_unavailable",
            "resource_blocking_dimension" => "antenna",
            "spacecraft_id" => "leo_1",
            "ground_station_id" => "dss_43",
            "source_resource_suppression" => %{
              "spacecraft_id" => "leo_1",
              "resource_blocking_dimension" => "antenna"
            }
          }
        ],
        "invalid_contact_input_count" => 99,
        "invalid_contact_input_ids" => ["stale_invalid_contact"],
        "status_blocked_contact_count" => 99,
        "status_blocked_contact_ids" => ["stale_status_contact"],
        "resource_blocked_contact_count" => 99,
        "resource_blocked_contact_ids" => ["stale_resource_contact"],
        "resource_blocking_dimension_counts" => %{"stale_dimension" => 99},
        "resource_blocked_contact_ids_by_blocking_dimension" => %{
          "stale_dimension" => ["stale_resource_contact"]
        },
        "resource_blocked_contact_ids_by_spacecraft_id" => %{
          "stale_spacecraft" => ["stale_resource_contact"]
        },
        "contact_ids_by_allocation_reason" => %{
          "stale_reason" => ["stale_reason_contact"]
        },
        "provenance" => %{"trust_boundary" => "ops_contact_allocation"}
      }
    }

    assert %{
             "source_report_contact_allocation_invalid_contact_input_count" => 1,
             "source_report_contact_allocation_invalid_contact_input_ids" => [
               "invalid_contact"
             ],
             "source_report_contact_allocation_status_blocked_contact_count" => 1,
             "source_report_contact_allocation_status_blocked_contact_ids" => [
               "status_blocked_contact"
             ],
             "source_report_contact_allocation_resource_blocked_contact_count" => 1,
             "source_report_contact_allocation_resource_blocked_contact_ids" => [
               "resource_blocked_contact"
             ],
             "source_report_contact_allocation_resource_blocking_dimension_counts" => %{
               "antenna" => 1
             },
             "source_report_contact_allocation_resource_blocked_contact_ids_by_blocking_dimension" =>
               %{
                 "antenna" => ["resource_blocked_contact"]
               },
             "source_report_contact_allocation_resource_blocked_contact_ids_by_spacecraft" => %{
               "leo_1" => ["resource_blocked_contact"]
             },
             "source_report_contact_allocation_allocation_reason_counts" => %{
               "activity_status_completed" => 1,
               "resource_unavailable" => 1
             },
             "source_report_contact_allocation_contact_ids_by_allocation_reason" => %{
               "activity_status_completed" => ["status_blocked_contact"],
               "resource_unavailable" => ["resource_blocked_contact"]
             },
             "source_reports" => %{
               "contact_allocation_report" => %{
                 "invalid_contact_input_count" => 1,
                 "invalid_contact_input_ids" => ["invalid_contact"],
                 "status_blocked_contact_count" => 1,
                 "status_blocked_contact_ids" => ["status_blocked_contact"],
                 "resource_blocked_contact_count" => 1,
                 "resource_blocked_contact_ids" => ["resource_blocked_contact"],
                 "resource_blocking_dimension_counts" => %{"antenna" => 1},
                 "resource_blocked_contact_ids_by_blocking_dimension" => %{
                   "antenna" => ["resource_blocked_contact"]
                 },
                 "resource_blocked_contact_ids_by_spacecraft" => %{
                   "leo_1" => ["resource_blocked_contact"]
                 },
                 "allocation_reason_counts" => %{
                   "activity_status_completed" => 1,
                   "resource_unavailable" => 1
                 },
                 "contact_ids_by_allocation_reason" => %{
                   "activity_status_completed" => ["status_blocked_contact"],
                   "resource_unavailable" => ["resource_blocked_contact"]
                 }
               }
             }
           } = summary = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "invalid_contact_input_count" => 1,
             "invalid_contact_input_ids" => ["invalid_contact"],
             "status_blocked_contact_count" => 1,
             "status_blocked_contact_ids" => ["status_blocked_contact"],
             "resource_blocked_contact_count" => 1,
             "resource_blocked_contact_ids" => ["resource_blocked_contact"],
             "resource_blocking_dimension_counts" => %{"antenna" => 1},
             "resource_blocked_contact_ids_by_blocking_dimension" => %{
               "antenna" => ["resource_blocked_contact"]
             },
             "resource_blocked_contact_ids_by_spacecraft" => %{
               "leo_1" => ["resource_blocked_contact"]
             },
             "contact_ids_by_allocation_reason" => %{
               "activity_status_completed" => ["status_blocked_contact"],
               "resource_unavailable" => ["resource_blocked_contact"]
             },
             "branch_local_contact_allocation_pressure" => true
           } = replay_summary = CandidateRefresh.contact_allocation_replay_summary(refresh)

    assert OrbitalDynamics.candidate_refresh_contact_allocation_replay_summary(refresh) ==
             replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => summary["source_reports"]}
    }

    assert %{
             "source_report_contact_allocation_invalid_contact_input_count" => 1,
             "source_report_contact_allocation_invalid_contact_input_ids" => [
               "invalid_contact"
             ],
             "source_report_contact_allocation_status_blocked_contact_count" => 1,
             "source_report_contact_allocation_resource_blocked_contact_count" => 1,
             "source_report_contact_allocation_resource_blocked_contact_ids_by_spacecraft" => %{
               "leo_1" => ["resource_blocked_contact"]
             },
             "source_report_contact_allocation_allocation_reason_counts" => %{
               "activity_status_completed" => 1,
               "resource_unavailable" => 1
             },
             "source_report_contact_allocation_contact_ids_by_allocation_reason" => %{
               "activity_status_completed" => ["status_blocked_contact"],
               "resource_unavailable" => ["resource_blocked_contact"]
             }
           } = CandidateRefresh.source_report_summary(artifact)

    assert %{
             "invalid_contact_input_count" => 1,
             "status_blocked_contact_ids" => ["status_blocked_contact"],
             "status_blocked_contact_count" => 1,
             "resource_blocked_contact_count" => 1,
             "resource_blocked_contact_ids_by_blocking_dimension" => %{
               "antenna" => ["resource_blocked_contact"]
             },
             "contact_ids_by_allocation_reason" => %{
               "activity_status_completed" => ["status_blocked_contact"],
               "resource_unavailable" => ["resource_blocked_contact"]
             }
           } = CandidateRefresh.contact_allocation_replay_summary(artifact)
  end

  test "source report summary aggregates contact allocation duplicate contact-id routing" do
    refresh = %{
      "source_contact_allocation_report" => %{
        "schema_contract" => "contact_allocation_report.v1",
        "rows" => [
          %{
            "contact_id" => "duplicate_contact",
            "allocation_status" => "blocked",
            "allocation_reason" => "duplicate_contact_id",
            "duplicate_contact_id_collision" => true,
            "duplicate_contact_index" => 0,
            "ground_station_id" => "equator_prime"
          },
          %{
            "contact_id" => "duplicate_contact",
            "allocation_status" => "blocked",
            "allocation_reason" => "duplicate_contact_id",
            "duplicate_contact_id_collision" => true,
            "duplicate_contact_index" => 1,
            "ground_station_id" => "equator_prime"
          }
        ],
        "duplicate_contact_id_count" => 99,
        "provenance" => %{"trust_boundary" => "ops_contact_allocation"}
      }
    }

    assert %{
             "source_report_contact_allocation_duplicate_contact_id_count" => 1,
             "source_reports" => %{
               "contact_allocation_report" => %{
                 "duplicate_contact_id_count" => 1
               }
             }
           } = summary = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "duplicate_contact_id_count" => 1,
             "branch_local_contact_allocation_pressure" => true
           } = replay_summary = CandidateRefresh.contact_allocation_replay_summary(refresh)

    assert OrbitalDynamics.candidate_refresh_contact_allocation_replay_summary(refresh) ==
             replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => summary["source_reports"]}
    }

    assert %{
             "source_report_contact_allocation_duplicate_contact_id_count" => 1
           } = CandidateRefresh.source_report_summary(artifact)

    assert %{
             "duplicate_contact_id_count" => 1,
             "branch_local_contact_allocation_pressure" => true
           } = CandidateRefresh.contact_allocation_replay_summary(artifact)
  end
end
