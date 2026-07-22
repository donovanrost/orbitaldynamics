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

  test "station and direction routing filters substituted contact identity" do
    first_summary = %{
      "schema_contract" => "contact_contention_resolution_summary.v1",
      "recommendation_count" => 1,
      "selected_contact_ids" => ["selected_a"],
      "deferred_contact_ids" => ["deferred_a"],
      "selected_contact_ids_by_ground_station" => %{
        "station_a" => ["selected_a", "substituted_contact"],
        "phantom_station" => ["substituted_contact"]
      },
      "deferred_contact_ids_by_ground_station" => %{
        "station_a" => ["deferred_a", "substituted_contact"]
      },
      "direction_counts" => %{"downlink" => 1, "zero_direction" => 0},
      "contact_ids_by_direction" => %{
        "downlink" => ["selected_a", "substituted_contact"],
        "borrowed_direction" => ["selected_a"],
        "zero_direction" => ["selected_a"]
      },
      "direction_routing" => %{
        "stale_direction" => %{
          "contact_count" => 99,
          "contact_ids" => ["substituted_contact"]
        }
      }
    }

    second_summary = %{
      "schema_contract" => "contact_contention_resolution_summary.v1",
      "recommendation_count" => 1,
      "selected_contact_ids" => ["selected_b"],
      "deferred_contact_ids" => ["deferred_b"],
      "selected_contact_ids_by_ground_station" => %{"station_b" => ["selected_b"]},
      "deferred_contact_ids_by_ground_station" => %{"station_b" => ["deferred_b"]},
      "direction_counts" => %{"borrowed_direction" => 1},
      "contact_ids_by_direction" => %{}
    }

    refresh = %{
      "schema_contract" => "candidate_refresh.v1",
      "source_contact_contention_resolution_summary" => first_summary,
      "mission_state" => %{
        "source_contact_contention_resolution_summary" => second_summary
      }
    }

    source_summary = CandidateRefresh.source_report_summary(refresh)

    assert source_summary["source_report_contact_contention_resolution_selected_contact_ids"] ==
             ["selected_a", "selected_b"]

    assert source_summary["source_report_contact_contention_resolution_deferred_contact_ids"] ==
             ["deferred_a", "deferred_b"]

    assert source_summary[
             "source_report_contact_contention_resolution_selected_contact_ids_by_ground_station"
           ] == %{"station_a" => ["selected_a"], "station_b" => ["selected_b"]}

    assert source_summary[
             "source_report_contact_contention_resolution_deferred_contact_ids_by_ground_station"
           ] == %{"station_a" => ["deferred_a"], "station_b" => ["deferred_b"]}

    assert source_summary["source_report_contact_contention_resolution_direction_counts"] == %{
             "borrowed_direction" => 1,
             "downlink" => 1,
             "zero_direction" => 0
           }

    assert source_summary[
             "source_report_contact_contention_resolution_contact_ids_by_direction"
           ] == %{"downlink" => ["selected_a"]}

    assert source_summary["source_report_contact_contention_resolution_direction_routing"] == %{
             "borrowed_direction" => %{"contact_count" => 1, "contact_ids" => []},
             "downlink" => %{"contact_count" => 1, "contact_ids" => ["selected_a"]}
           }

    replay_summary = CandidateRefresh.contact_contention_resolution_replay_summary(refresh)

    assert replay_summary["selected_contact_ids_by_ground_station"] == %{
             "station_a" => ["selected_a"],
             "station_b" => ["selected_b"]
           }

    assert replay_summary["deferred_contact_ids_by_ground_station"] == %{
             "station_a" => ["deferred_a"],
             "station_b" => ["deferred_b"]
           }

    assert replay_summary["contact_ids_by_direction"] == %{"downlink" => ["selected_a"]}

    assert replay_summary["direction_routing"] == %{
             "borrowed_direction" => %{"contact_count" => 1, "contact_ids" => []},
             "downlink" => %{"contact_count" => 1, "contact_ids" => ["selected_a"]}
           }

    preserved_artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_contention_resolution_report" =>
            Map.put(first_summary, "contract", "contact_contention_resolution_summary.v1")
        }
      }
    }

    preserved_replay =
      CandidateRefresh.contact_contention_resolution_replay_summary(preserved_artifact)

    assert preserved_replay["selected_contact_ids_by_ground_station"] == %{
             "station_a" => ["selected_a"]
           }

    assert preserved_replay["deferred_contact_ids_by_ground_station"] == %{
             "station_a" => ["deferred_a"]
           }

    assert preserved_replay["direction_counts"] == %{
             "downlink" => 1,
             "zero_direction" => 0
           }

    assert preserved_replay["contact_ids_by_direction"] == %{
             "downlink" => ["selected_a"]
           }

    assert preserved_replay["direction_routing"] == %{
             "downlink" => %{"contact_count" => 1, "contact_ids" => ["selected_a"]}
           }
  end

  test "capacity-source routing filters zero-count and substituted contact identity" do
    first_summary = %{
      "schema_contract" => "contact_contention_resolution_summary.v1",
      "selected_contact_ids" => ["selected_a"],
      "deferred_contact_ids" => ["deferred_a"],
      "required_capacity_fraction_source_counts" => %{
        "capacity_model" => 3,
        "zero_source" => 0
      },
      "required_capacity_fraction_contact_ids_by_source" => %{
        "capacity_model" => [
          "deferred_a",
          "selected_a",
          "selected_b",
          "substituted_contact"
        ],
        "zero_source" => ["selected_a"]
      }
    }

    second_summary = %{
      "schema_contract" => "contact_contention_resolution_summary.v1",
      "selected_contact_ids" => ["selected_b"],
      "deferred_contact_ids" => ["deferred_b"],
      "required_capacity_fraction_source_counts" => %{"capacity_model" => 2}
    }

    refresh = %{
      "schema_contract" => "candidate_refresh.v1",
      "source_contact_contention_resolution_summary" => first_summary,
      "mission_state" => %{
        "source_contact_contention_resolution_summary" => second_summary
      }
    }

    source_summary = CandidateRefresh.source_report_summary(refresh)

    assert source_summary[
             "source_report_contact_contention_capacity_pack_required_capacity_fraction_source_counts"
           ] == %{"capacity_model" => 5, "zero_source" => 0}

    assert source_summary[
             "source_report_contact_contention_capacity_pack_required_capacity_fraction_contact_ids_by_source"
           ] == %{"capacity_model" => ["deferred_a", "selected_a"]}

    replay_summary = CandidateRefresh.contact_contention_resolution_replay_summary(refresh)

    assert replay_summary["required_capacity_fraction_source_counts"] == %{
             "capacity_model" => 5,
             "zero_source" => 0
           }

    assert replay_summary["required_capacity_fraction_contact_ids_by_source"] == %{
             "capacity_model" => ["deferred_a", "selected_a"]
           }

    assert replay_summary["selected_contact_ids"] == ["selected_a", "selected_b"]
    assert replay_summary["deferred_contact_ids"] == ["deferred_a", "deferred_b"]
    assert replay_summary["branch_local_capacity_pack_pressure"]

    preserved_artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_contention_resolution_report" =>
            Map.put(first_summary, "contract", "contact_contention_resolution_summary.v1")
        }
      }
    }

    preserved_replay =
      CandidateRefresh.contact_contention_resolution_replay_summary(preserved_artifact)

    assert preserved_replay["required_capacity_fraction_source_counts"] == %{
             "capacity_model" => 3,
             "zero_source" => 0
           }

    assert preserved_replay["required_capacity_fraction_contact_ids_by_source"] == %{
             "capacity_model" => ["deferred_a", "selected_a"]
           }
  end

  test "capacity-pack replay rejects unsupported status and mismatched numeric maps" do
    resolution_summary = %{
      "schema_contract" => "contact_contention_resolution_summary.v1",
      "capacity_pack_required_capacity_fraction" => 0.5,
      "capacity_pack_selected_required_capacity_fraction" => 0.2,
      "capacity_pack_deferred_required_capacity_fraction" => 0.3,
      "capacity_pack_required_capacity_fraction_by_ground_station_id" => %{
        "stale_station" => 0.6
      },
      "capacity_pack_selected_required_capacity_fraction_by_ground_station_id" => %{
        "selected_station" => 0.2
      },
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" => %{
        "deferred_station" => 0.3
      },
      "capacity_pack_required_capacity_fraction_by_status" => %{
        "selected" => 0.2,
        "deferred" => 0.2,
        "phantom_status" => 0.1
      }
    }

    refresh = %{
      "schema_contract" => "candidate_refresh.v1",
      "source_contact_contention_resolution_summary" => resolution_summary
    }

    source_summary = CandidateRefresh.source_report_summary(refresh)

    assert source_summary[
             "source_report_contact_contention_capacity_pack_required_capacity_fraction"
           ] == 0.5

    assert source_summary[
             "source_report_contact_contention_capacity_pack_selected_required_capacity_fraction"
           ] == 0.2

    assert source_summary[
             "source_report_contact_contention_capacity_pack_deferred_required_capacity_fraction"
           ] == 0.3

    assert Map.get(
             source_summary,
             "source_report_contact_contention_capacity_pack_required_capacity_fraction_by_ground_station",
             %{}
           ) == %{}

    assert source_summary[
             "source_report_contact_contention_capacity_pack_selected_required_capacity_fraction_by_ground_station"
           ] == %{"selected_station" => 0.2}

    assert source_summary[
             "source_report_contact_contention_capacity_pack_deferred_required_capacity_fraction_by_ground_station"
           ] == %{"deferred_station" => 0.3}

    assert Map.get(
             source_summary,
             "source_report_contact_contention_capacity_pack_required_capacity_fraction_by_status",
             %{}
           ) == %{}

    replay_summary = CandidateRefresh.contact_contention_resolution_replay_summary(refresh)

    assert replay_summary["capacity_pack_required_capacity_fraction"] == 0.5
    assert replay_summary["capacity_pack_selected_required_capacity_fraction"] == 0.2
    assert replay_summary["capacity_pack_deferred_required_capacity_fraction"] == 0.3
    assert replay_summary["capacity_pack_required_capacity_fraction_by_ground_station"] == %{}

    assert replay_summary["capacity_pack_selected_required_capacity_fraction_by_ground_station"] ==
             %{"selected_station" => 0.2}

    assert replay_summary["capacity_pack_deferred_required_capacity_fraction_by_ground_station"] ==
             %{"deferred_station" => 0.3}

    refute Map.has_key?(
             replay_summary,
             "capacity_pack_required_capacity_fraction_by_status"
           )

    assert replay_summary["branch_local_capacity_pack_pressure"]

    preserved_artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{
        "source_reports" => %{
          "contact_contention_resolution_report" =>
            Map.put(resolution_summary, "contract", "contact_contention_resolution_summary.v1")
        }
      }
    }

    preserved_replay =
      CandidateRefresh.contact_contention_resolution_replay_summary(preserved_artifact)

    assert preserved_replay["capacity_pack_required_capacity_fraction"] == 0.5
    assert preserved_replay["capacity_pack_required_capacity_fraction_by_ground_station"] == %{}

    refute Map.has_key?(
             preserved_replay,
             "capacity_pack_required_capacity_fraction_by_status"
           )
  end
end
