Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyStationCalendarPressureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CandidateRefresh
  alias OrbitalDynamics.Schema

  test "strategy derives branch refresh from prior station calendar pressure" do
    review_provider_contention_group = %{
      "id" => "station_calendar_provider_contention:equator_prime:review",
      "provider_calendar_contention_status" => "provider_calendar_overlap",
      "ground_station_id" => "equator_prime",
      "starts_at_s" => 1_120.0,
      "ends_at_s" => 1_140.0,
      "entry_ids" => ["review_reserved_a", "review_reserved_b"],
      "provider_ids" => ["review_calendar"],
      "provider_entry_ids" => ["review_reserved_a", "review_reserved_b"],
      "reservation_ids" => ["review_reservation_a", "review_reservation_b"],
      "reserved_by" => ["network_review_a", "network_review_b"],
      "reservation_statuses" => ["confirmed", "planned"],
      "trust_boundary_statuses" => ["declared"],
      "source_station_calendar_entries" => [
        %{
          "id" => "review_reserved_a",
          "provider_id" => "review_calendar",
          "ground_station_id" => "equator_prime",
          "availability" => "reserved",
          "starts_at_s" => 1_100.0,
          "ends_at_s" => 1_140.0,
          "reservation_id" => "review_reservation_a",
          "reserved_by" => "network_review_a",
          "reservation_status" => "confirmed"
        },
        %{
          "id" => "review_reserved_b",
          "provider_id" => "review_calendar",
          "ground_station_id" => "equator_prime",
          "availability" => "reserved",
          "starts_at_s" => 1_120.0,
          "ends_at_s" => 1_160.0,
          "reservation_id" => "review_reservation_b",
          "reserved_by" => "network_review_b",
          "reservation_status" => "planned"
        }
      ]
    }

    import_provider_contention_group = %{
      "id" => "station_calendar_provider_contention:equator_prime:import",
      "provider_calendar_contention_status" => "provider_calendar_overlap",
      "ground_station_id" => "equator_prime",
      "starts_at_s" => 1_220.0,
      "ends_at_s" => 1_240.0,
      "entry_ids" => ["import_reserved_a", "import_reserved_b"],
      "provider_ids" => ["import_calendar"],
      "provider_entry_ids" => ["import_reserved_a", "import_reserved_b"],
      "reservation_ids" => ["import_reservation_a", "import_reservation_b"],
      "reserved_by" => ["network_import_a", "network_import_b"],
      "reservation_statuses" => ["confirmed", "planned"],
      "trust_boundary_statuses" => ["declared"],
      "source_station_calendar_entries" => [
        %{
          "id" => "import_reserved_a",
          "provider_id" => "import_calendar",
          "ground_station_id" => "equator_prime",
          "availability" => "reserved",
          "starts_at_s" => 1_200.0,
          "ends_at_s" => 1_240.0,
          "reservation_id" => "import_reservation_a",
          "reserved_by" => "network_import_a",
          "reservation_status" => "confirmed"
        },
        %{
          "id" => "import_reserved_b",
          "provider_id" => "import_calendar",
          "ground_station_id" => "equator_prime",
          "availability" => "reserved",
          "starts_at_s" => 1_220.0,
          "ends_at_s" => 1_260.0,
          "reservation_id" => "import_reservation_b",
          "reserved_by" => "network_import_b",
          "reservation_status" => "planned"
        }
      ]
    }

    prior_plan =
      base_plan(%{
        "activities" => [
          downlink("dl_reserved", 500.0, 560.0),
          downlink("dl_capacity", 700.0, 760.0),
          downlink("dl_review", 800.0, 860.0),
          downlink("dl_import", 900.0, 960.0)
        ],
        "source_station_calendar_report" => %{
          "schema_contract" => "station_calendar_report.v1",
          "model" => "campaign_ground_network_interval_overlay",
          "provenance" => %{"trust_boundary" => "ops_station_calendar"},
          "affected_contacts" => [
            %{
              "id" => "station_calendar:dl_reserved:reserved",
              "contact_id" => "dl_reserved",
              "scenario_id" => "leo_1",
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 500.0,
              "ends_at_s" => 560.0,
              "station_calendar_entry_id" => "equator_reserved",
              "station_calendar_status" => "Reserved",
              "station_availability" => "Reserved",
              "station_contention_status" => "reserved_overlap",
              "station_reservation_id" => "reservation_42",
              "station_reserved_by" => "ops_team_b",
              "station_reservation_status" => "confirmed",
              "station_calendar_trust_boundary_status" => "declared",
              "trust_boundary" => "ops_station_calendar"
            }
          ],
          "provider_calendar_contention_groups" => [
            %{
              "id" => "station_calendar_provider_contention:equator_prime:1",
              "provider_calendar_contention_status" => "provider_calendar_overlap",
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 1_020.0,
              "ends_at_s" => 1_040.0,
              "entry_count" => 2,
              "entry_ids" => ["equator_reserved_a", "equator_reserved_b"],
              "provider_ids" => ["ops_calendar"],
              "provider_entry_ids" => ["equator_reserved_a", "equator_reserved_b"],
              "availabilities" => ["reserved"],
              "directions" => ["downlink"],
              "reservation_ids" => ["reservation_a", "reservation_b"],
              "reserved_by" => ["network_a", "network_b"],
              "reservation_statuses" => ["confirmed", "planned"],
              "trust_boundary_statuses" => ["declared"],
              "overlap_pairs" => [
                %{
                  "left_entry_id" => "equator_reserved_a",
                  "right_entry_id" => "equator_reserved_b",
                  "overlap_starts_at_s" => 1_020.0,
                  "overlap_ends_at_s" => 1_040.0,
                  "overlap_duration_s" => 20.0
                }
              ],
              "source_station_calendar_entries" => [
                %{
                  "id" => "equator_reserved_a",
                  "provider_id" => "ops_calendar",
                  "provider_entry_id" => "equator_reserved_a",
                  "ground_station_id" => "equator_prime",
                  "availability" => "Reserved",
                  "directions" => ["downlink"],
                  "starts_at_s" => 1_000.0,
                  "ends_at_s" => 1_040.0,
                  "reservation_id" => "reservation_a",
                  "reserved_by" => "network_a",
                  "reservation_status" => "confirmed",
                  "provenance" => %{"trust_boundary" => "ops_station_calendar"}
                },
                %{
                  "id" => "equator_reserved_b",
                  "provider_id" => "ops_calendar",
                  "provider_entry_id" => "equator_reserved_b",
                  "ground_station_id" => "equator_prime",
                  "availability" => "Reserved",
                  "directions" => ["downlink"],
                  "starts_at_s" => 1_020.0,
                  "ends_at_s" => 1_060.0,
                  "reservation_id" => "reservation_b",
                  "reserved_by" => "network_b",
                  "reservation_status" => "planned",
                  "provenance" => %{"trust_boundary" => "ops_station_calendar"}
                }
              ]
            }
          ]
        },
        "station_calendar_report" => %{
          "schema_contract" => "station_calendar_report.v1",
          "model" => "campaign_ground_network_interval_overlay",
          "trust_boundary" => "canonical_station_calendar",
          "affected_contacts" => [
            %{
              "id" => "station_calendar:dl_capacity:capacity",
              "contact_id" => "dl_capacity",
              "scenario_id" => "leo_1",
              "ground_station_id" => "deep_space_net",
              "starts_at_s" => 700.0,
              "ends_at_s" => 760.0,
              "station_calendar_entry_id" => "dsn_capacity",
              "station_calendar_status" => "available",
              "station_availability" => "Reduced Capacity",
              "capacity_fraction" => 0.35,
              "station_calendar_trust_boundary_status" => "declared"
            }
          ]
        },
        "operator_review_package" => %{
          "schema_contract" => "operator_review_package.v1",
          "source_artifact_type" => "station_calendar_report.v1",
          "review_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_station_calendar_review"},
          "rows" => [
            %{
              "id" => "operator_review:station_calendar:dl_review",
              "review_type" => "station_calendar_review",
              "contact_id" => "dl_review",
              "scenario_id" => "leo_1",
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 800.0,
              "ends_at_s" => 860.0,
              "station_calendar_entry_id" => "equator_maintenance_review",
              "station_calendar_status" => "maintenance",
              "station_availability" => "unavailable",
              "station_calendar_trust_boundary_status" => "declared",
              "source_station_calendar_review" => %{"contact_id" => "dl_review"}
            },
            %{
              "id" => "operator_review:station_calendar:provider_contention_review",
              "review_type" => "station_calendar_review",
              "source" => "station_calendar_report.provider_calendar_contention_groups",
              "approval_status" => "operator_review_required",
              "source_station_calendar_provider_contention" => review_provider_contention_group
            }
          ]
        },
        "cadence_import_manifest" => %{
          "schema_contract" => "cadence_import_manifest.v1",
          "source_artifact_type" => "operator_review_package.v1",
          "row_count" => 1,
          "review_required_count" => 1,
          "provenance" => %{"trust_boundary" => "cadence_station_calendar_review"},
          "rows" => [
            %{
              "id" => "cadence_import:station_calendar:dl_import",
              "import_action" => "review_station_calendar",
              "source_review_type" => "station_calendar_review",
              "contact_id" => "dl_import",
              "scenario_id" => "leo_1",
              "ground_station_id" => "deep_space_net",
              "starts_at_s" => 900.0,
              "ends_at_s" => 960.0,
              "station_calendar_entry_id" => "dsn_capacity_import",
              "station_availability" => "Reduced Capacity",
              "capacity_fraction" => 0.45,
              "station_calendar_trust_boundary_status" => "declared",
              "source_station_calendar_review" => %{"contact_id" => "dl_import"}
            },
            %{
              "id" => "cadence_import:station_calendar:provider_contention_import",
              "import_action" => "review_station_calendar",
              "source_review_type" => "station_calendar_review",
              "approval_status" => "operator_review_required",
              "source_station_calendar_provider_contention" => import_provider_contention_group
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    reserved_branch = branch(artifact, "derived_station_calendar_pressure_reserved_dl_reserved")

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             reserved_branch["assumptions"]["candidate_source"]

    assert %{
             "type" => "ground_station_reserved",
             "ground_station_id" => "equator_prime",
             "starts_at_s" => 500.0,
             "ends_at_s" => 560.0,
             "station_calendar_entry_id" => "equator_reserved",
             "station_calendar_status" => "reserved",
             "station_availability" => "reserved",
             "station_contention_status" => "reserved_overlap",
             "station_reservation_id" => "reservation_42",
             "station_reserved_by" => "ops_team_b",
             "station_reservation_status" => "confirmed",
             "feedback_source" => "prior_plan.source_station_calendar_report",
             "feedback_scope" => "station_calendar",
             "trust_boundary" => "ops_station_calendar"
           } = List.first(reserved_branch["events"])

    assert get_in(reserved_branch, ["provenance", "branch_metadata", "derived_source"]) ==
             "prior_plan.source_station_calendar_report"

    reserved_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "derived_station_calendar_pressure_reserved_dl_reserved"))

    assert reserved_row["branch_station_availabilities"] == ["reserved"]
    assert reserved_row["branch_station_reservation_ids"] == ["reservation_42"]
    assert reserved_row["branch_station_reserved_by"] == ["ops_team_b"]
    assert reserved_row["branch_station_reservation_statuses"] == ["confirmed"]

    assert Enum.any?(
             reserved_branch["risk_indicators"],
             &(&1["type"] == "ground_station_reserved" and
                 &1["ground_station_id"] == "equator_prime")
           )

    assert_station_calendar_pressure_score_terms(reserved_branch, artifact)

    provider_contention_branch =
      branch(
        artifact,
        "derived_station_calendar_provider_contention_station_calendar_provider_contention:equator_prime:1"
      )

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             provider_contention_branch["assumptions"]["candidate_source"]

    assert [
             %{
               "type" => "ground_station_reserved",
               "ground_station_id" => "equator_prime",
               "starts_at_s" => 1_020.0,
               "ends_at_s" => 1_040.0,
               "station_calendar_entry_id" => "equator_reserved_a",
               "station_calendar_provider_id" => "ops_calendar",
               "station_calendar_provider_entry_id" => "equator_reserved_a",
               "station_reservation_id" => "reservation_a",
               "station_reserved_by" => "network_a",
               "station_reservation_status" => "confirmed",
               "provider_calendar_contention_group_id" =>
                 "station_calendar_provider_contention:equator_prime:1",
               "feedback_source" =>
                 "prior_plan.source_station_calendar_report.provider_calendar_contention_groups",
               "feedback_scope" => "station_calendar",
               "trust_boundary" => "ops_station_calendar"
             },
             %{
               "type" => "ground_station_reserved",
               "station_calendar_entry_id" => "equator_reserved_b",
               "station_reservation_id" => "reservation_b",
               "station_reserved_by" => "network_b",
               "station_reservation_status" => "planned"
             }
           ] = provider_contention_branch["events"]

    assert get_in(provider_contention_branch, ["provenance", "branch_metadata", "derived_source"]) ==
             "prior_plan.source_station_calendar_report.provider_calendar_contention_groups"

    review_provider_contention_branch =
      branch(
        artifact,
        "derived_station_calendar_provider_contention_station_calendar_provider_contention:equator_prime:review"
      )

    assert %{
             "type" => "ground_station_reserved",
             "ground_station_id" => "equator_prime",
             "starts_at_s" => 1_120.0,
             "ends_at_s" => 1_140.0,
             "station_calendar_entry_id" => "review_reserved_a",
             "station_calendar_provider_id" => "review_calendar",
             "station_reservation_id" => "review_reservation_a",
             "station_reserved_by" => "network_review_a",
             "feedback_source" =>
               "prior_plan.operator_review_package.rows.source_station_calendar_provider_contention",
             "trust_boundary" => "ops_station_calendar_review"
           } = List.first(review_provider_contention_branch["events"])

    import_provider_contention_branch =
      branch(
        artifact,
        "derived_station_calendar_provider_contention_station_calendar_provider_contention:equator_prime:import"
      )

    assert %{
             "type" => "ground_station_reserved",
             "ground_station_id" => "equator_prime",
             "starts_at_s" => 1_220.0,
             "ends_at_s" => 1_240.0,
             "station_calendar_entry_id" => "import_reserved_a",
             "station_calendar_provider_id" => "import_calendar",
             "station_reservation_id" => "import_reservation_a",
             "station_reserved_by" => "network_import_a",
             "feedback_source" =>
               "prior_plan.cadence_import_manifest.rows.source_station_calendar_provider_contention",
             "trust_boundary" => "cadence_station_calendar_review"
           } = List.first(import_provider_contention_branch["events"])

    capacity_branch =
      branch(artifact, "derived_station_calendar_pressure_reduced_capacity_dl_capacity")

    assert %{
             "type" => "reduced_downlink_capacity",
             "ground_station_id" => "deep_space_net",
             "capacity_fraction" => 0.35,
             "station_calendar_entry_id" => "dsn_capacity",
             "station_availability" => "reduced_capacity",
             "feedback_source" => "prior_plan.station_calendar_report",
             "trust_boundary" => "canonical_station_calendar"
           } = List.first(capacity_branch["events"])

    capacity_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(
        &(&1["branch_id"] == "derived_station_calendar_pressure_reduced_capacity_dl_capacity")
      )

    assert capacity_row["branch_station_availabilities"] == ["reduced_capacity"]
    assert capacity_row["branch_event_trust_boundary_status_counts"] == %{"declared" => 1}

    review_branch =
      branch(artifact, "derived_station_calendar_pressure_unavailable_dl_review")

    assert %{
             "type" => "ground_station_outage",
             "ground_station_id" => "equator_prime",
             "station_calendar_entry_id" => "equator_maintenance_review",
             "station_availability" => "unavailable",
             "feedback_source" =>
               "prior_plan.operator_review_package.rows.source_station_calendar_review",
             "trust_boundary" => "ops_station_calendar_review"
           } = List.first(review_branch["events"])

    import_branch =
      branch(artifact, "derived_station_calendar_pressure_reduced_capacity_dl_import")

    assert %{
             "type" => "reduced_downlink_capacity",
             "ground_station_id" => "deep_space_net",
             "capacity_fraction" => 0.45,
             "station_calendar_entry_id" => "dsn_capacity_import",
             "feedback_source" =>
               "prior_plan.cadence_import_manifest.rows.source_station_calendar_review",
             "trust_boundary" => "cadence_station_calendar_review"
           } = List.first(import_branch["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from mission-state station calendar reports" do
    station_calendar_report = %{
      "schema_contract" => "station_calendar_report.v1",
      "model" => "campaign_ground_network_interval_overlay",
      "provenance" => %{"trust_boundary" => "mission_station_calendar"},
      "affected_contacts" => [
        %{
          "id" => "station_calendar:dl_mission_reserved:reserved",
          "contact_id" => "dl_mission_reserved",
          "scenario_id" => "leo_1",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 500.0,
          "ends_at_s" => 560.0,
          "station_calendar_entry_id" => "mission_equator_reserved",
          "station_calendar_status" => "Reserved",
          "station_availability" => "Reserved",
          "station_contention_status" => "reserved_overlap",
          "station_reservation_id" => "mission_reservation_42",
          "station_reserved_by" => "ops_team_live",
          "station_reservation_status" => "confirmed",
          "station_calendar_trust_boundary_status" => "declared"
        }
      ],
      "provider_calendar_contention_groups" => [
        %{
          "id" => "station_calendar_provider_contention:equator_prime:mission",
          "provider_calendar_contention_status" => "provider_calendar_overlap",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 1_020.0,
          "ends_at_s" => 1_040.0,
          "entry_ids" => ["mission_reserved_a", "mission_reserved_b"],
          "provider_ids" => ["mission_calendar"],
          "provider_entry_ids" => ["mission_reserved_a", "mission_reserved_b"],
          "reservation_ids" => ["mission_reservation_a", "mission_reservation_b"],
          "reserved_by" => ["network_live_a", "network_live_b"],
          "reservation_statuses" => ["confirmed", "planned"],
          "trust_boundary_statuses" => ["declared"],
          "source_station_calendar_entries" => [
            %{
              "id" => "mission_reserved_a",
              "provider_id" => "mission_calendar",
              "provider_entry_id" => "mission_reserved_a",
              "ground_station_id" => "equator_prime",
              "availability" => "Reserved",
              "directions" => ["downlink"],
              "starts_at_s" => 1_000.0,
              "ends_at_s" => 1_040.0,
              "reservation_id" => "mission_reservation_a",
              "reserved_by" => "network_live_a",
              "reservation_status" => "confirmed"
            },
            %{
              "id" => "mission_reserved_b",
              "provider_id" => "mission_calendar",
              "provider_entry_id" => "mission_reserved_b",
              "ground_station_id" => "equator_prime",
              "availability" => "Reserved",
              "directions" => ["downlink"],
              "starts_at_s" => 1_020.0,
              "ends_at_s" => 1_060.0,
              "reservation_id" => "mission_reservation_b",
              "reserved_by" => "network_live_b",
              "reservation_status" => "planned"
            }
          ]
        }
      ]
    }

    artifact =
      strategy(base_plan(%{}),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:source_station_calendar_report, station_calendar_report),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    reserved_branch =
      branch(artifact, "derived_station_calendar_pressure_reserved_dl_mission_reserved")

    assert %{
             "type" => "candidate_refresh.v1",
             "scope" => "branch_generated",
             "source_report_input_paths" => ["mission_state.source_station_calendar_report"]
           } = reserved_branch["assumptions"]["candidate_source"]

    assert %{
             "type" => "ground_station_reserved",
             "ground_station_id" => "equator_prime",
             "starts_at_s" => 500.0,
             "ends_at_s" => 560.0,
             "station_calendar_entry_id" => "mission_equator_reserved",
             "station_calendar_status" => "reserved",
             "station_availability" => "reserved",
             "station_contention_status" => "reserved_overlap",
             "station_reservation_id" => "mission_reservation_42",
             "station_reserved_by" => "ops_team_live",
             "station_reservation_status" => "confirmed",
             "feedback_source" => "mission_state.source_station_calendar_report",
             "feedback_scope" => "station_calendar",
             "trust_boundary" => "mission_station_calendar"
           } = List.first(reserved_branch["events"])

    provider_contention_branch =
      branch(
        artifact,
        "derived_station_calendar_provider_contention_station_calendar_provider_contention:equator_prime:mission"
      )

    assert %{
             "type" => "candidate_refresh.v1",
             "scope" => "branch_generated",
             "source_report_input_paths" => ["mission_state.source_station_calendar_report"]
           } = provider_contention_branch["assumptions"]["candidate_source"]

    assert [
             %{
               "type" => "ground_station_reserved",
               "ground_station_id" => "equator_prime",
               "starts_at_s" => 1_020.0,
               "ends_at_s" => 1_040.0,
               "station_calendar_entry_id" => "mission_reserved_a",
               "station_calendar_provider_id" => "mission_calendar",
               "station_calendar_provider_entry_id" => "mission_reserved_a",
               "station_reservation_id" => "mission_reservation_a",
               "station_reserved_by" => "network_live_a",
               "station_reservation_status" => "confirmed",
               "provider_calendar_contention_group_id" =>
                 "station_calendar_provider_contention:equator_prime:mission",
               "feedback_source" =>
                 "mission_state.source_station_calendar_report.provider_calendar_contention_groups",
               "feedback_scope" => "station_calendar",
               "trust_boundary" => "mission_station_calendar"
             },
             %{
               "type" => "ground_station_reserved",
               "station_calendar_entry_id" => "mission_reserved_b",
               "station_reservation_id" => "mission_reservation_b",
               "station_reserved_by" => "network_live_b",
               "station_reservation_status" => "planned"
             }
           ] = provider_contention_branch["events"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy ignores stale station-calendar aggregates when deriving branch pressure" do
    station_calendar_report = %{
      "schema_contract" => "station_calendar_report.v1",
      "model" => "campaign_ground_network_interval_overlay",
      "source" => "campaign_planner_test.stale.station_calendar_report",
      "provenance" => %{"trust_boundary" => "stale_station_calendar_report_boundary"},
      "affected_contacts" => [
        %{
          "id" => "station_calendar:dl_stale_reserved:reserved",
          "contact_id" => "dl_stale_reserved",
          "scenario_id" => "leo_1",
          "ground_station_id" => "dss_43",
          "direction" => "Down Link",
          "starts_at_s" => 420.0,
          "ends_at_s" => 480.0,
          "station_calendar_entry_id" => "row_station_reserved",
          "station_calendar_status" => "reserved",
          "station_availability" => "reserved",
          "station_contention_status" => "reserved_overlap",
          "station_reservation_id" => "row_reservation_43",
          "station_reserved_by" => "ops_row_owner",
          "station_reservation_status" => "confirmed",
          "station_reservation_expires_at_s" => 1_800.0,
          "station_calendar_trust_boundary_status" => "declared",
          "trust_boundary" => "stale_station_calendar_row_boundary"
        }
      ],
      "station_calendar_status_counts" => %{"available" => 99},
      "affected_contact_ground_station_counts" => %{"stale_station" => 99},
      "affected_contact_availability_counts" => %{"available" => 99},
      "contact_ids_by_status" => %{"available" => ["stale_contact"]},
      "station_calendar_entry_ids_by_status" => %{"available" => ["stale_entry"]},
      "station_reservation_ids_by_status" => %{"available" => ["stale_reservation"]},
      "direction_counts" => %{"tracking" => 99},
      "contact_ids_by_direction" => %{"tracking" => ["stale_contact"]}
    }

    artifact =
      strategy(base_plan(%{}),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:source_station_calendar_report, station_calendar_report),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    reserved_branch =
      branch(artifact, "derived_station_calendar_pressure_reserved_dl_stale_reserved")

    candidate_source =
      assert_candidate_source_report_path(
        reserved_branch,
        "mission_state.source_station_calendar_report"
      )

    source_summary = candidate_source["candidate_refresh_request_source_report_summary"]

    assert source_summary["source_report_station_calendar_status_counts"] == %{"reserved" => 1}

    assert source_summary["source_report_station_calendar_affected_contact_ground_station_counts"] ==
             %{"dss_43" => 1}

    assert source_summary["source_report_station_calendar_affected_contact_availability_counts"] ==
             %{"reserved" => 1}

    assert source_summary["source_report_station_calendar_direction_counts"] == %{
             "downlink" => 1
           }

    assert source_summary["source_report_station_calendar_contact_ids_by_status"] == %{
             "reserved" => ["dl_stale_reserved"]
           }

    assert source_summary["source_report_station_calendar_entry_ids_by_status"] == %{
             "reserved" => ["row_station_reserved"]
           }

    assert source_summary["source_report_station_calendar_reservation_ids_by_status"] == %{
             "reserved" => ["row_reservation_43"]
           }

    assert source_summary["source_report_station_calendar_contact_ids_by_direction"] == %{
             "downlink" => ["dl_stale_reserved"]
           }

    assert source_summary["source_report_station_calendar_entry_ids_by_direction"] == %{
             "downlink" => ["row_station_reserved"]
           }

    assert source_summary["source_report_station_calendar_reservation_ids_by_direction"] == %{
             "downlink" => ["row_reservation_43"]
           }

    assert source_summary["source_report_station_calendar_direction_routing"] == %{
             "downlink" => %{
               "contact_count" => 1,
               "contact_ids" => ["dl_stale_reserved"],
               "station_calendar_entry_ids" => ["row_station_reserved"],
               "station_reservation_ids" => ["row_reservation_43"],
               "station_capacity_fractions" => [],
               "provider_contention_group_ids" => [],
               "provider_contention_source_entry_ids" => [],
               "provider_contention_provider_ids" => [],
               "provider_contention_provider_entry_ids" => [],
               "provider_contention_capacity_fractions" => []
             }
           }

    replay_summary = CandidateRefresh.station_calendar_replay_summary(candidate_source)

    assert replay_summary["source_report_count"] == 1
    assert replay_summary["source_report_row_count"] == 1

    assert replay_summary["source_report_paths"] == [
             "mission_state.source_station_calendar_report"
           ]

    assert replay_summary["affected_contact_count"] == 1
    assert replay_summary["affected_contact_ids"] == ["dl_stale_reserved"]
    assert replay_summary["affected_station_calendar_entry_ids"] == ["row_station_reserved"]
    assert replay_summary["affected_station_reservation_ids"] == ["row_reservation_43"]
    assert replay_summary["direction_counts"] == %{"downlink" => 1}
    assert replay_summary["contact_ids_by_direction"] == %{"downlink" => ["dl_stale_reserved"]}

    assert replay_summary["station_calendar_entry_ids_by_direction"] == %{
             "downlink" => ["row_station_reserved"]
           }

    assert replay_summary["station_reservation_ids_by_direction"] == %{
             "downlink" => ["row_reservation_43"]
           }

    assert replay_summary["direction_routing"] == %{
             "downlink" => %{
               "contact_count" => 1,
               "contact_ids" => ["dl_stale_reserved"],
               "station_calendar_entry_ids" => ["row_station_reserved"],
               "station_reservation_ids" => ["row_reservation_43"],
               "station_capacity_fractions" => [],
               "provider_contention_group_ids" => [],
               "provider_contention_source_entry_ids" => [],
               "provider_contention_provider_ids" => [],
               "provider_contention_provider_entry_ids" => [],
               "provider_contention_capacity_fractions" => []
             }
           }

    assert replay_summary["station_calendar_status_counts"] == %{"reserved" => 1}
    assert replay_summary["affected_contact_ground_station_counts"] == %{"dss_43" => 1}
    assert replay_summary["affected_contact_availability_counts"] == %{"reserved" => 1}
    assert replay_summary["contact_ids_by_status"] == %{"reserved" => ["dl_stale_reserved"]}

    assert replay_summary["station_calendar_entry_ids_by_status"] == %{
             "reserved" => ["row_station_reserved"]
           }

    assert replay_summary["station_reservation_ids_by_status"] == %{
             "reserved" => ["row_reservation_43"]
           }

    assert replay_summary["branch_local_station_calendar_pressure"] == true
    assert replay_summary["branch_local_affected_contact_pressure"] == true
    assert replay_summary["branch_local_station_availability_pressure"] == true

    assert [
             %{
               "type" => "ground_station_reserved",
               "ground_station_id" => "dss_43",
               "starts_at_s" => 420.0,
               "ends_at_s" => 480.0,
               "station_calendar_entry_id" => "row_station_reserved",
               "station_calendar_status" => "reserved",
               "station_availability" => "reserved",
               "station_contention_status" => "reserved_overlap",
               "station_reservation_id" => "row_reservation_43",
               "station_reserved_by" => "ops_row_owner",
               "station_reservation_status" => "confirmed",
               "feedback_source" => "mission_state.source_station_calendar_report",
               "feedback_scope" => "station_calendar",
               "trust_boundary" => "stale_station_calendar_row_boundary"
             }
           ] = reserved_branch["events"]

    reserved_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(
        &(&1["branch_id"] == "derived_station_calendar_pressure_reserved_dl_stale_reserved")
      )

    assert reserved_row["branch_station_availabilities"] == ["reserved"]
    assert reserved_row["branch_station_reservation_ids"] == ["row_reservation_43"]
    assert reserved_row["branch_station_reserved_by"] == ["ops_row_owner"]
    assert reserved_row["branch_station_reservation_statuses"] == ["confirmed"]

    assert_station_calendar_pressure_score_terms(reserved_branch, artifact)

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives station calendar pressure from result artifact reports" do
    prior_plan =
      base_plan(%{
        "activities" => [
          downlink("dl_result_calendar", 500.0, 560.0)
        ],
        "source_result_artifact" => %{
          "schema_contract" => "result_artifact.v1",
          "metadata" => %{"trust_boundary" => "ops_result_artifact_calendar"},
          "station_calendar_report" => %{
            "schema_contract" => "station_calendar_report.v1",
            "model" => "campaign_ground_network_interval_overlay",
            "affected_contacts" => [
              %{
                "id" => "station_calendar:result:dl_result_calendar",
                "contact_id" => "dl_result_calendar",
                "scenario_id" => "leo_1",
                "ground_station_id" => "equator_prime",
                "starts_at_s" => 500.0,
                "ends_at_s" => 560.0,
                "station_calendar_entry_id" => "result_calendar_reserved",
                "station_calendar_status" => "reserved",
                "station_availability" => "reserved",
                "station_contention_status" => "reserved_overlap",
                "station_reservation_id" => "result_reservation_42",
                "station_reserved_by" => "ops_team_result",
                "station_reservation_status" => "confirmed",
                "station_calendar_trust_boundary_status" => "declared"
              }
            ],
            "provider_calendar_contention_groups" => [
              %{
                "id" => "station_calendar_provider_contention:result_calendar:1",
                "provider_calendar_contention_status" => "provider_calendar_overlap",
                "ground_station_id" => "equator_prime",
                "starts_at_s" => 900.0,
                "ends_at_s" => 930.0,
                "entry_ids" => ["result_provider_outage", "result_provider_reserved"],
                "provider_ids" => ["result_partner_calendar"],
                "provider_entry_ids" => [
                  "result_provider_outage",
                  "result_provider_reserved"
                ],
                "reservation_ids" => ["result_provider_reservation"],
                "reserved_by" => ["partner_ops"],
                "reservation_statuses" => ["planned"],
                "trust_boundary_statuses" => ["declared"],
                "source_station_calendar_entries" => [
                  %{
                    "id" => "result_provider_outage",
                    "provider_id" => "result_partner_calendar",
                    "provider_entry_id" => "result_provider_outage",
                    "ground_station_id" => "equator_prime",
                    "availability" => "unavailable",
                    "starts_at_s" => 880.0,
                    "ends_at_s" => 930.0
                  },
                  %{
                    "id" => "result_provider_reserved",
                    "provider_id" => "result_partner_calendar",
                    "provider_entry_id" => "result_provider_reserved",
                    "ground_station_id" => "equator_prime",
                    "availability" => "reserved",
                    "starts_at_s" => 900.0,
                    "ends_at_s" => 950.0,
                    "reservation_id" => "result_provider_reservation",
                    "reserved_by" => "partner_ops",
                    "reservation_status" => "planned"
                  }
                ]
              }
            ]
          }
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    reserved_branch =
      branch(artifact, "derived_station_calendar_pressure_reserved_dl_result_calendar")

    assert %{
             "type" => "ground_station_reserved",
             "ground_station_id" => "equator_prime",
             "station_calendar_entry_id" => "result_calendar_reserved",
             "station_reservation_id" => "result_reservation_42",
             "station_reserved_by" => "ops_team_result",
             "feedback_source" => "prior_plan.source_result_artifact.station_calendar_report",
             "trust_boundary" => "ops_result_artifact_calendar"
           } = List.first(reserved_branch["events"])

    provider_contention_branch =
      branch(
        artifact,
        "derived_station_calendar_provider_contention_station_calendar_provider_contention:result_calendar:1"
      )

    assert [
             %{
               "type" => "ground_station_outage",
               "station_calendar_entry_id" => "result_provider_outage",
               "station_calendar_provider_id" => "result_partner_calendar",
               "feedback_source" =>
                 "prior_plan.source_result_artifact.station_calendar_report.provider_calendar_contention_groups",
               "trust_boundary" => "ops_result_artifact_calendar"
             },
             %{
               "type" => "ground_station_reserved",
               "station_calendar_entry_id" => "result_provider_reserved",
               "station_reservation_id" => "result_provider_reservation",
               "station_reserved_by" => "partner_ops"
             }
           ] = provider_contention_branch["events"]

    assert get_in(provider_contention_branch, ["provenance", "branch_metadata", "derived_source"]) ==
             "prior_plan.source_result_artifact.station_calendar_report.provider_calendar_contention_groups"

    result_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(
        &(&1["branch_id"] == "derived_station_calendar_pressure_reserved_dl_result_calendar")
      )

    assert result_row["branch_event_trust_boundary_status_counts"] == %{"declared" => 1}

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy keeps independent station-calendar pressures for the same contact identity" do
    prior_plan =
      base_plan(%{
        "activities" => [
          downlink("dl_station_shared", 500.0, 560.0)
        ],
        "source_station_calendar_report" => %{
          "schema_contract" => "station_calendar_report.v1",
          "model" => "campaign_ground_network_interval_overlay",
          "trust_boundary" => "source_station_calendar",
          "affected_contacts" => [
            %{
              "id" => "station_calendar:source:dl_station_shared",
              "contact_id" => "dl_station_shared",
              "scenario_id" => "leo_1",
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 500.0,
              "ends_at_s" => 560.0,
              "station_calendar_entry_id" => "equator_source_outage",
              "station_calendar_status" => "maintenance",
              "station_availability" => "unavailable",
              "station_calendar_trust_boundary_status" => "declared"
            }
          ]
        },
        "station_calendar_report" => %{
          "schema_contract" => "station_calendar_report.v1",
          "model" => "campaign_ground_network_interval_overlay",
          "trust_boundary" => "canonical_station_calendar",
          "affected_contacts" => [
            %{
              "id" => "station_calendar:canonical:dl_station_shared",
              "contact_id" => "dl_station_shared",
              "scenario_id" => "leo_1",
              "ground_station_id" => "polar_prime",
              "starts_at_s" => 520.0,
              "ends_at_s" => 580.0,
              "station_calendar_entry_id" => "polar_canonical_outage",
              "station_calendar_status" => "offline",
              "station_availability" => "unavailable",
              "station_calendar_trust_boundary_status" => "declared"
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    base_id = "derived_station_calendar_pressure_unavailable_dl_station_shared"
    refute branch(artifact, base_id)

    station_branches =
      Enum.filter(artifact["branches"], &String.starts_with?(&1["branch_id"], "#{base_id}_"))

    assert length(station_branches) == 2

    assert MapSet.new(Enum.map(station_branches, & &1["derived_source"])) ==
             MapSet.new([
               "prior_plan.source_station_calendar_report",
               "prior_plan.station_calendar_report"
             ])

    assert station_branches
           |> Enum.flat_map(& &1["events"])
           |> Enum.map(& &1["station_calendar_entry_id"])
           |> Enum.sort() == ["equator_source_outage", "polar_canonical_outage"]

    assert station_branches
           |> Enum.flat_map(& &1["events"])
           |> Enum.map(& &1["ground_station_id"])
           |> Enum.sort() == ["equator_prime", "polar_prime"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp assert_candidate_source_report_path(branch, expected_path) do
    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             candidate_source = branch["assumptions"]["candidate_source"]

    assert expected_path in candidate_source["source_report_input_paths"]
    candidate_source
  end

  defp assert_station_calendar_pressure_score_terms(branch, artifact) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    station_calendar_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &(&1["feedback_scope"] == "station_calendar" and
            &1["station_reservation_expiration_status"] not in ["expired", "missing"])
      )

    assert station_calendar_pressure_count > 0

    assert branch["score_terms"]["station_calendar_pressure_penalty"] ==
             -station_calendar_pressure_count * risk_weight

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) - station_calendar_pressure_count) * risk_weight

    assert "station_calendar_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "station_calendar_pressure_penalty" and
                 &1["value"] < 0.0)
           )
  end
end
