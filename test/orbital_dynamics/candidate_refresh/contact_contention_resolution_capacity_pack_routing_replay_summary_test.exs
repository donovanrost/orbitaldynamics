defmodule OrbitalDynamics.CandidateRefresh.ContactContentionResolutionCapacityPackRoutingReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CandidateRefresh

  test "source report summary aggregates contact contention capacity-pack demand" do
    refresh = %{
      "source_contact_contention_resolution_report" => %{
        "schema_contract" => "contact_contention_resolution_report.v1",
        "recommendations" => [
          %{
            "group_id" => "equator_prime:contention:1",
            "ground_station_id" => "equator_prime",
            "direction" => "mixed",
            "directions" => ["Down Link", "s-band command"],
            "selected_contact_id" => "selected_contact",
            "deferred_contact_ids" => ["deferred_contact"],
            "resolution_status" => "deferred",
            "selection_reason" => "highest_score",
            "required_operator_actions" => ["review_contact_contention_resolution"],
            "source_contact_candidates" => [
              %{
                "id" => "selected_contact",
                "direction" => "Down Link",
                "ground_station_id" => "equator_prime",
                "required_capacity_percent" => "20"
              },
              %{
                "id" => "deferred_contact",
                "direction" => "s-band command",
                "ground_station_id" => "equator_prime",
                "required_capacity_fraction" => 0.35
              }
            ]
          }
        ],
        "capacity_pack_required_capacity_fraction" => 99.0,
        "capacity_pack_selected_required_capacity_fraction" => 99.0,
        "capacity_pack_deferred_required_capacity_fraction" => 99.0,
        "capacity_pack_required_capacity_fraction_by_ground_station_id" => %{
          "stale_station" => 99.0
        },
        "direction_counts" => %{"stale_direction" => 99},
        "contact_ids_by_direction" => %{"stale_direction" => ["stale_contact"]},
        "required_operator_action_counts" => %{"stale_action" => 99},
        "provenance" => %{"trust_boundary" => "ops_contention_resolution"}
      }
    }

    expected_direction_routing = %{
      "command" => %{
        "contact_count" => 1,
        "contact_ids" => ["deferred_contact"]
      },
      "downlink" => %{
        "contact_count" => 1,
        "contact_ids" => ["selected_contact"]
      }
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_contact_contention_resolution_contract" =>
               "contact_contention_resolution_report.v1",
             "source_report_contact_contention_resolution_count" => 1,
             "source_report_contact_contention_resolution_row_count" => 1,
             "source_report_contact_contention_resolution_paths" => [
               "source_contact_contention_resolution_report"
             ],
             "source_report_contact_contention_resolution_recommendation_count" => 1,
             "source_report_contact_contention_resolution_deferred_contact_count" => 1,
             "source_report_contact_contention_resolution_status_counts" => %{"deferred" => 1},
             "source_report_contact_contention_resolution_selection_reason_counts" => %{
               "highest_score" => 1
             },
             "source_report_contact_contention_capacity_pack_required_capacity_fraction" => 0.55,
             "source_report_contact_contention_capacity_pack_selected_required_capacity_fraction" =>
               0.2,
             "source_report_contact_contention_capacity_pack_deferred_required_capacity_fraction" =>
               0.35,
             "source_report_contact_contention_capacity_pack_required_capacity_fraction_by_ground_station" =>
               %{"equator_prime" => 0.55},
             "source_report_contact_contention_capacity_pack_selected_required_capacity_fraction_by_ground_station" =>
               %{"equator_prime" => 0.2},
             "source_report_contact_contention_capacity_pack_deferred_required_capacity_fraction_by_ground_station" =>
               %{"equator_prime" => 0.35},
             "source_report_contact_contention_resolution_selected_contact_ids" => [
               "selected_contact"
             ],
             "source_report_contact_contention_resolution_deferred_contact_ids" => [
               "deferred_contact"
             ],
             "source_report_contact_contention_resolution_selected_contact_ids_by_ground_station" =>
               %{"equator_prime" => ["selected_contact"]},
             "source_report_contact_contention_resolution_deferred_contact_ids_by_ground_station" =>
               %{"equator_prime" => ["deferred_contact"]},
             "source_report_contact_contention_resolution_direction_counts" => %{
               "command" => 1,
               "downlink" => 1
             },
             "source_report_contact_contention_resolution_contact_ids_by_direction" => %{
               "command" => ["deferred_contact"],
               "downlink" => ["selected_contact"]
             },
             "source_report_contact_contention_resolution_direction_routing" =>
               ^expected_direction_routing,
             "source_report_contact_contention_resolution_required_operator_action_counts" => %{
               "review_contact_contention_resolution" => 1
             },
             "source_report_contact_contention_resolution_branch_local_contact_contention_resolution_pressure" =>
               true,
             "source_report_contact_contention_resolution_branch_local_deferred_contact_pressure" =>
               true,
             "source_report_contact_contention_resolution_branch_local_capacity_pack_pressure" =>
               true,
             "source_report_contact_contention_resolution_branch_local_action_pressure" => true,
             "source_reports" => %{
               "contact_contention_resolution_report" => %{
                 "recommendation_count" => 1,
                 "deferred_contact_count" => 1,
                 "resolution_status_counts" => %{"deferred" => 1},
                 "selection_reason_counts" => %{"highest_score" => 1},
                 "capacity_pack_required_capacity_fraction" => 0.55,
                 "capacity_pack_selected_required_capacity_fraction" => 0.2,
                 "capacity_pack_deferred_required_capacity_fraction" => 0.35,
                 "selected_contact_ids" => ["selected_contact"],
                 "deferred_contact_ids" => ["deferred_contact"],
                 "selected_contact_ids_by_ground_station" => %{
                   "equator_prime" => ["selected_contact"]
                 },
                 "deferred_contact_ids_by_ground_station" => %{
                   "equator_prime" => ["deferred_contact"]
                 },
                 "direction_counts" => %{
                   "command" => 1,
                   "downlink" => 1
                 },
                 "contact_ids_by_direction" => %{
                   "command" => ["deferred_contact"],
                   "downlink" => ["selected_contact"]
                 },
                 "direction_routing" => ^expected_direction_routing,
                 "required_operator_action_counts" => %{
                   "review_contact_contention_resolution" => 1
                 }
               }
             }
           } = summary = CandidateRefresh.source_report_summary(refresh)

    replay_summary = %{
      "model" => "artifact_only_candidate_refresh_contact_contention_resolution_replay_summary",
      "source" =>
        "candidate_refresh.source_report_provenance.contact_contention_resolution_report",
      "contract" => "contact_contention_resolution_report.v1",
      "source_report_count" => 1,
      "source_report_row_count" => 1,
      "source_report_paths" => ["source_contact_contention_resolution_report"],
      "recommendation_count" => 1,
      "deferred_contact_count" => 1,
      "resolution_status_counts" => %{"deferred" => 1},
      "selection_reason_counts" => %{"highest_score" => 1},
      "capacity_pack_required_capacity_fraction" => 0.55,
      "capacity_pack_selected_required_capacity_fraction" => 0.2,
      "capacity_pack_deferred_required_capacity_fraction" => 0.35,
      "capacity_pack_required_capacity_fraction_by_ground_station" => %{
        "equator_prime" => 0.55
      },
      "capacity_pack_selected_required_capacity_fraction_by_ground_station" => %{
        "equator_prime" => 0.2
      },
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station" => %{
        "equator_prime" => 0.35
      },
      "selected_contact_ids" => ["selected_contact"],
      "deferred_contact_ids" => ["deferred_contact"],
      "selected_contact_ids_by_ground_station" => %{
        "equator_prime" => ["selected_contact"]
      },
      "deferred_contact_ids_by_ground_station" => %{
        "equator_prime" => ["deferred_contact"]
      },
      "direction_counts" => %{
        "command" => 1,
        "downlink" => 1
      },
      "contact_ids_by_direction" => %{
        "command" => ["deferred_contact"],
        "downlink" => ["selected_contact"]
      },
      "direction_routing" => expected_direction_routing,
      "required_operator_action_counts" => %{
        "review_contact_contention_resolution" => 1
      },
      "trust_boundary_status" => "declared",
      "trust_boundaries" => ["ops_contention_resolution"],
      "branch_local_contact_contention_resolution_pressure" => true,
      "branch_local_deferred_contact_pressure" => true,
      "branch_local_capacity_pack_pressure" => true,
      "branch_local_contact_contention_resolution_action_pressure" => true,
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_refresh_replay_mutation",
        "replay_scope" => "contact_contention_resolution_source_report_provenance_only",
        "operator_authority" => "not_granted_by_contact_contention_resolution_replay_summary",
        "contact_allocation" => "not_performed_by_summary",
        "candidate_selection" => "not_performed_by_summary",
        "import_approval" => "not_granted_by_contact_contention_resolution_replay_summary",
        "cadence_write" => "not_performed_by_summary",
        "candidate_generation" => "not_performed_by_summary"
      }
    }

    assert CandidateRefresh.contact_contention_resolution_replay_summary(refresh) ==
             replay_summary

    assert OrbitalDynamics.candidate_refresh_contact_contention_resolution_replay_summary(refresh) ==
             replay_summary

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => summary["source_reports"]}
    }

    assert %{
             "source_report_contact_contention_resolution_contract" =>
               "contact_contention_resolution_report.v1",
             "source_report_contact_contention_resolution_count" => 1,
             "source_report_contact_contention_resolution_row_count" => 1,
             "source_report_contact_contention_resolution_paths" => [
               "source_contact_contention_resolution_report"
             ],
             "source_report_contact_contention_resolution_recommendation_count" => 1,
             "source_report_contact_contention_resolution_deferred_contact_count" => 1,
             "source_report_contact_contention_resolution_status_counts" => %{"deferred" => 1},
             "source_report_contact_contention_resolution_selection_reason_counts" => %{
               "highest_score" => 1
             },
             "source_report_contact_contention_capacity_pack_required_capacity_fraction" => 0.55,
             "source_report_contact_contention_capacity_pack_deferred_required_capacity_fraction" =>
               0.35,
             "source_report_contact_contention_resolution_selected_contact_ids_by_ground_station" =>
               %{"equator_prime" => ["selected_contact"]},
             "source_report_contact_contention_resolution_deferred_contact_ids_by_ground_station" =>
               %{"equator_prime" => ["deferred_contact"]},
             "source_report_contact_contention_resolution_direction_counts" => %{
               "command" => 1,
               "downlink" => 1
             },
             "source_report_contact_contention_resolution_contact_ids_by_direction" => %{
               "command" => ["deferred_contact"],
               "downlink" => ["selected_contact"]
             },
             "source_report_contact_contention_resolution_direction_routing" =>
               ^expected_direction_routing,
             "source_report_contact_contention_resolution_required_operator_action_counts" => %{
               "review_contact_contention_resolution" => 1
             },
             "source_report_contact_contention_resolution_branch_local_contact_contention_resolution_pressure" =>
               true,
             "source_report_contact_contention_resolution_branch_local_deferred_contact_pressure" =>
               true,
             "source_report_contact_contention_resolution_branch_local_capacity_pack_pressure" =>
               true,
             "source_report_contact_contention_resolution_branch_local_action_pressure" => true
           } = CandidateRefresh.source_report_summary(artifact)

    assert CandidateRefresh.contact_contention_resolution_replay_summary(artifact) ==
             replay_summary

    assert OrbitalDynamics.candidate_refresh_contact_contention_resolution_replay_summary(
             artifact
           ) ==
             replay_summary
  end
end
