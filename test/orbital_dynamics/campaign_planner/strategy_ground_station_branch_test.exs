Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyGroundStationBranchTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy compares baseline against ground-station outage branch" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_500.0},
        "assumptions" => %{
          "constraints" => %{"max_timeline_activities" => 0, "min_activity_duration_s" => 90.0},
          "scoring_policy" => %{}
        },
        "activities" => [downlink("dl_1", 100.0, 160.0)],
        "candidate_activities" => [
          downlink("dl_1", 100.0, 160.0),
          downlink("dl_2", 700.0, 760.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([%{"type" => "downlink_completion", "required_contacts" => 1}]),
        branches: [
          %{id: "baseline", label: "Nominal"},
          %{
            id: "station_outage",
            label: "Station outage",
            events: [
              %{
                type: "ground_station_outage",
                station_id: :equator_prime,
                start_s: "90.0",
                end_s: "200.0"
              }
            ]
          },
          %{id: "noop", probability: 0.0}
        ],
        current_epoch_s: 0.0
      )

    outage = branch(artifact, "station_outage")

    assert [
             %{
               "type" => "ground_station_outage",
               "ground_station_id" => "equator_prime",
               "starts_at_s" => 90.0,
               "ends_at_s" => 200.0
             }
           ] = outage["events"]

    refute Map.has_key?(List.first(outage["events"]), "station_id")
    refute Map.has_key?(List.first(outage["events"]), "start_s")
    refute Map.has_key?(List.first(outage["events"]), "end_s")

    assert artifact["recommendation"]["recommended_branch_id"] == "baseline"
    assert Enum.any?(outage["risk_indicators"], &(&1["type"] == "ground_station_outage"))

    assert [
             %{
               "activity_id" => "dl_1",
               "repair_action" => "moved",
               "replacement_activity_id" => "dl_2"
             }
           ] = outage["repair_result"]["deltas"]

    outage_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "station_outage"))

    assert outage_row["repair_score_term_keys"] == [
             "activity_score",
             "schedule_churn_penalty",
             "schedule_move_penalty"
           ]

    assert outage_row["repair_score_term_count"] == 3
    assert outage_row["repair_score"] == outage["repair_result"]["score"]
    assert outage_row["repair_activity_score"] == 10.0
    assert outage_row["repair_schedule_churn_penalty"] == -100.0
    assert outage_row["repair_schedule_move_penalty"] < 0.0
    assert outage_row["repair_link_contact_count"] == 1
    assert outage_row["repair_link_selected_contact_count"] == 1
    assert outage_row["repair_link_selected_estimated_throughput_mb"] == 0.0
    assert outage_row["repair_constraint_count"] == 2
    assert outage_row["repair_constraint_row_count"] == 2
    assert outage_row["repair_constraint_status"] == "fail"
    assert outage_row["repair_constraint_fail_count"] == 2

    assert outage_row["repair_constraint_failed_ids"] == [
             "campaign:max_timeline_activities",
             "campaign:min_activity_duration_s"
           ]

    assert {:ok, %{"schema_contract" => "branch_comparison_report.v1"}} =
             Schema.validate_artifact(artifact["branch_comparison_report"])
  end

  test "strategy reports repair constraint warning severity in branch comparison rows" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_500.0},
        "assumptions" => %{
          "constraints" => %{
            "max_timeline_activities" => %{"threshold" => 0, "severity" => "warning"},
            "min_activity_duration_s" => %{threshold: 90.0, violation_severity: :warning}
          },
          "scoring_policy" => %{}
        },
        "activities" => [downlink("dl_1", 100.0, 160.0)],
        "candidate_activities" => [
          downlink("dl_1", 100.0, 160.0),
          downlink("dl_2", 700.0, 760.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state([%{"type" => "downlink_completion", "required_contacts" => 1}]),
        branches: [
          %{id: "baseline", label: "Nominal"},
          %{
            id: "station_outage",
            label: "Station outage",
            events: [
              %{
                type: "ground_station_outage",
                ground_station_id: "equator_prime",
                starts_at_s: 90.0,
                ends_at_s: 200.0
              }
            ]
          },
          %{id: "noop", probability: 0.0}
        ],
        current_epoch_s: 0.0
      )

    outage = branch(artifact, "station_outage")

    outage_row =
      Enum.find(
        artifact["branch_comparison_report"]["rows"],
        &(&1["branch_id"] == "station_outage")
      )

    assert outage["repair_result"]["constraint_report"]["status"] == "warning"
    assert outage_row["repair_constraint_status"] == "warning"
    assert outage_row["repair_constraint_count"] == 2
    assert outage_row["repair_constraint_row_count"] == 2
    assert outage_row["repair_constraint_warning_count"] == 2
    assert outage_row["repair_constraint_fail_count"] == 0
    assert outage_row["repair_constraint_failed_ids"] == []

    assert outage_row["repair_constraint_warning_ids"] == [
             "campaign:max_timeline_activities",
             "campaign:min_activity_duration_s"
           ]

    assert Enum.all?(
             outage["repair_result"]["constraint_report"]["rows"],
             &(&1["status"] == "warning" and &1["violation_severity"] == "warning")
           )

    assert %{
             "review_type" => "constraint_review",
             "source" => "campaign_strategy.branches.repair_result.constraint_report.rows",
             "branch_id" => "station_outage",
             "constraint_id" => "campaign:max_timeline_activities",
             "constraint_status" => "warning",
             "required_operator_action" => "review_constraint"
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "constraint_review" and
                   &1["branch_id"] == "station_outage" and
                   &1["constraint_id"] == "campaign:max_timeline_activities")
             )

    assert %{
             "import_action" => "review_constraint",
             "source_review_type" => "constraint_review",
             "source" => "campaign_strategy.branches.repair_result.constraint_report.rows",
             "branch_id" => "station_outage",
             "constraint_id" => "campaign:max_timeline_activities",
             "constraint_status" => "warning"
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["source_review_type"] == "constraint_review" and
                   &1["branch_id"] == "station_outage" and
                   &1["constraint_id"] == "campaign:max_timeline_activities")
             )

    assert {:ok, %{"schema_contract" => "branch_comparison_report.v1"}} =
             Schema.validate_artifact(artifact["branch_comparison_report"])
  end

  test "strategy applies ground-station outage branch events to planned-contact downlinks" do
    missed_planned_contact =
      "planned_dl_1"
      |> downlink(100.0, 160.0)
      |> Map.put("type", "planned_contact")
      |> Map.put("direction", "downlink")

    replacement_planned_contact =
      "planned_dl_2"
      |> refreshed_downlink(700.0, 760.0)
      |> Map.put("type", "planned_contact")

    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_500.0},
        "activities" => [missed_planned_contact],
        "candidate_activities" => [missed_planned_contact, replacement_planned_contact]
      })

    artifact =
      strategy(prior_plan,
        branches: [
          %{id: "baseline"},
          %{
            id: "station_outage",
            events: [
              %{
                type: "ground_station_outage",
                ground_station_id: "equator_prime",
                starts_at_s: 90.0,
                ends_at_s: 200.0
              }
            ]
          },
          %{id: "noop", probability: 0.0}
        ],
        current_epoch_s: 0.0
      )

    outage = branch(artifact, "station_outage")

    assert [
             %{
               "activity_id" => "planned_dl_1",
               "activity_type" => "planned_contact",
               "repair_action" => "moved",
               "replacement_activity_id" => "planned_dl_2"
             }
           ] = outage["repair_result"]["deltas"]

    refute Enum.any?(
             outage["repair_result"]["source_candidate_activities"],
             &(&1["id"] == "planned_dl_1")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives ground-network branches from station-id mission-state entries" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:ground_network, [
        %{
          station_id: "equator_prime",
          status: "unavailable",
          starts_at_s: 0.0,
          ends_at_s: 2_000.0
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}, %{id: "manual_review", events: [%{type: "operator_note"}]}],
        current_epoch_s: 0.0
      )

    outage = branch(artifact, "derived_station_outage_equator_prime")

    assert outage["derived_source"] == "mission_state.ground_network"

    assert %{"suppressed_candidate_count" => suppressed_count} =
             outage["repair_result"]["source_contact_filter_report"]

    assert suppressed_count > 0

    refute Enum.any?(
             outage["repair_result"]["source_candidate_activities"],
             &(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy preserves station-calendar source path for derived mission-state branches" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:station_calendar, [
        %{
          id: "equator_station_calendar_outage",
          station_id: "equator_prime",
          availability: "maintenance",
          starts_at_s: "0.0",
          ends_at_s: "2000.0",
          provenance: %{trust_boundary: "operator_station_calendar"}
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    outage = branch(artifact, "derived_station_outage_equator_prime")

    assert outage["derived_source"] == "mission_state.station_calendar"

    assert [
             %{
               "type" => "ground_station_outage",
               "ground_station_id" => "equator_prime",
               "station_calendar_entry_id" => "equator_station_calendar_outage",
               "station_calendar_status" => "maintenance",
               "trust_boundary" => "operator_station_calendar"
             }
           ] = outage["events"]

    assert %{"suppressed_candidate_count" => suppressed_count} =
             outage["repair_result"]["source_contact_filter_report"]

    assert suppressed_count > 0

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy keeps independent ground-network outages for the same station" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:ground_network, [
        %{
          id: "equator_outage_morning",
          station_id: "equator_prime",
          status: "unavailable",
          starts_at_s: 0.0,
          ends_at_s: 600.0
        },
        %{
          id: "equator_outage_afternoon",
          station_id: "equator_prime",
          status: "unavailable",
          starts_at_s: 1_200.0,
          ends_at_s: 1_800.0
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    base_id = "derived_station_outage_equator_prime"
    refute branch(artifact, base_id)

    outage_branches =
      Enum.filter(artifact["branches"], &String.starts_with?(&1["branch_id"], "#{base_id}_"))

    assert length(outage_branches) == 2

    assert MapSet.new(Enum.map(outage_branches, & &1["derived_source"])) ==
             MapSet.new(["mission_state.ground_network"])

    assert outage_branches
           |> Enum.flat_map(& &1["events"])
           |> Enum.map(& &1["station_calendar_entry_id"])
           |> Enum.sort() == ["equator_outage_afternoon", "equator_outage_morning"]

    assert outage_branches
           |> Enum.flat_map(& &1["events"])
           |> Enum.map(&{&1["starts_at_s"], &1["ends_at_s"]})
           |> Enum.sort() == [{0.0, 600.0}, {1_200.0, 1_800.0}]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy accepts mission-state station calendar provider artifacts for branch refresh" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:station_calendar, [
        %{
          id: "equator_declared_capacity",
          ground_station_id: "equator_prime",
          capacity_fraction: 0.75,
          starts_at_s: 0.0,
          ends_at_s: 2_000.0
        }
      ])
      |> Map.put(:station_calendar_provider, %{
        schema_contract: "station_calendar_provider.v1",
        id: "ops_calendar",
        trust_boundary: "declared_station_calendar_provider",
        entries: [
          %{
            id: "equator_provider_maintenance",
            station_id: "equator_prime",
            availability: "maintenance",
            directions: [:downlink],
            start_s: 0.0,
            end_s: 2_000.0
          }
        ]
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    outage = branch(artifact, "derived_station_outage_equator_prime")

    assert outage["derived_source"] == "mission_state.station_calendar_provider"

    assert [
             %{
               "type" => "ground_station_outage",
               "ground_station_id" => "equator_prime",
               "station_calendar_entry_id" => "equator_provider_maintenance",
               "station_calendar_provider_id" => "ops_calendar",
               "station_calendar_provider_entry_id" => "equator_provider_maintenance",
               "station_calendar_directions" => ["downlink"],
               "station_calendar_status" => "maintenance",
               "trust_boundary" => "declared_station_calendar_provider",
               "provenance" => %{
                 "source" => "station_calendar_provider",
                 "provider_id" => "ops_calendar",
                 "trust_boundary" => "declared_station_calendar_provider"
               }
             }
           ] = outage["events"]

    assert %{
             "schema_contract" => "contact_filter_report.v1",
             "suppressed_candidate_count" => suppressed_count,
             "suppressed_candidates" => suppressed
           } = outage["repair_result"]["source_contact_filter_report"]

    assert suppressed_count > 0

    assert Enum.any?(suppressed, fn row ->
             source_overlaps =
               row["source_station_calendar_overlaps"] ||
                 get_in(row, ["activity_context", "source_station_calendar_overlaps"]) ||
                 []

             overlap_entry_ids =
               row["station_calendar_overlap_entry_ids"] ||
                 get_in(row, ["activity_context", "station_calendar_overlap_entry_ids"]) ||
                 Enum.map(source_overlaps, & &1["id"])

             row["suppressed_reason"] == "ground_station_unavailable" and
               row["station_calendar_entry_id"] == "equator_provider_maintenance" and
               row["station_calendar_provider_id"] == "ops_calendar" and
               row["station_calendar_provider_entry_id"] == "equator_provider_maintenance" and
               row["station_calendar_directions"] == ["downlink"] and
               row["station_calendar_status"] == "unavailable" and
               Enum.sort(overlap_entry_ids) == [
                 "equator_declared_capacity",
                 "equator_provider_maintenance"
               ] and
               get_in(row, ["source_station_calendar_entry", "id"]) ==
                 "equator_provider_maintenance" and
               get_in(row, [
                 "source_station_calendar_entry",
                 "provenance",
                 "source_event_provenance",
                 "trust_boundary"
               ]) == "declared_station_calendar_provider"
           end)

    assert %{
             "branch_station_calendar_entry_ids" => ["equator_provider_maintenance"],
             "branch_station_calendar_provider_ids" => ["ops_calendar"],
             "branch_station_calendar_provider_entry_ids" => ["equator_provider_maintenance"],
             "branch_station_calendar_directions" => ["downlink"],
             "branch_station_calendar_statuses" => ["maintenance"]
           } =
             Enum.find(
               artifact["branch_comparison_report"]["rows"],
               &(&1["branch_id"] == "derived_station_outage_equator_prime")
             )

    refute Enum.any?(
             outage["repair_result"]["source_candidate_activities"],
             &(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy accepts mission-state station calendar provider lists for branch refresh" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:station_calendar_provider, [
        %{
          schema_contract: "station_calendar_provider.v1",
          provider_id: "ops_calendar_aux",
          trust_boundary: "declared_station_calendar_provider",
          entries: [
            %{
              id: "aux_station_available",
              station_id: "polar_aux",
              availability: "available",
              starts_at_s: 0.0,
              ends_at_s: 2_000.0
            }
          ]
        },
        %{
          schema_contract: "station_calendar_provider.v1",
          provider_id: "ops_calendar_primary",
          trust_boundary: "declared_station_calendar_provider",
          entries: [
            %{
              id: "equator_provider_reserved",
              station_id: "equator_prime",
              availability: "reserved",
              directions: [:downlink],
              start_s: "0.0",
              end_s: "2000.0",
              reservation_id: "provider_branch_reservation",
              reserved_by: "ops_calendar_primary",
              reservation_status: "confirmed"
            }
          ]
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    reserved = branch(artifact, "derived_station_reserved_equator_prime")

    assert reserved["derived_source"] == "mission_state.station_calendar_provider"

    assert [
             %{
               "type" => "ground_station_reserved",
               "ground_station_id" => "equator_prime",
               "station_calendar_entry_id" => "equator_provider_reserved",
               "station_calendar_provider_id" => "ops_calendar_primary",
               "station_calendar_provider_entry_id" => "equator_provider_reserved",
               "station_calendar_directions" => ["downlink"],
               "reservation_id" => "provider_branch_reservation",
               "reserved_by" => "ops_calendar_primary",
               "reservation_status" => "confirmed",
               "trust_boundary" => "declared_station_calendar_provider"
             }
           ] = reserved["events"]

    assert %{
             "suppressed_candidate_count" => suppressed_count,
             "suppressed_candidates" => suppressed
           } = reserved["repair_result"]["source_contact_filter_report"]

    assert suppressed_count > 0

    assert Enum.any?(suppressed, fn row ->
             row["station_calendar_provider_id"] == "ops_calendar_primary" and
               row["station_calendar_provider_entry_id"] == "equator_provider_reserved" and
               row["station_calendar_reservation_ids"] == ["provider_branch_reservation"]
           end)

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy rejects invalid mission-state station calendar provider artifacts" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:station_calendar, %{
        schema_contract: "station_calendar_provider.v1",
        id: "ops_calendar",
        entries: %{}
      })

    assert_raise ArgumentError, ~r/entries must be a list/, fn ->
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )
    end
  end

  test "strategy derives station reservations from availability-only mission-state entries" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:ground_network, [
        %{
          station_id: "equator_prime",
          availability: "Reserved",
          starts_at_s: 0.0,
          ends_at_s: 600.0,
          reservation_id: "reservation_equator_prime_1",
          reserved_by: "ops_team_b",
          reservation_status: "reserved"
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}, %{id: "manual_review", events: [%{type: "operator_note"}]}],
        current_epoch_s: 0.0
      )

    reserved = branch(artifact, "derived_station_reserved_equator_prime")
    assert reserved["derived_source"] == "mission_state.ground_network"

    assert [
             %{
               "type" => "ground_station_reserved",
               "ground_station_id" => "equator_prime",
               "reservation_id" => "reservation_equator_prime_1",
               "reserved_by" => "ops_team_b",
               "reservation_status" => "reserved"
             }
           ] = reserved["events"]

    repair = reserved["repair_result"]

    assert %{
             "schema_contract" => "contact_filter_report.v1",
             "suppressed_candidate_count" => suppressed_count,
             "suppressed_candidates" => [
               %{
                 "suppressed_reason" => "ground_station_reserved",
                 "station_availability" => "reserved",
                 "station_contention_status" => "reserved_overlap",
                 "station_reservation_id" => "reservation_equator_prime_1",
                 "station_reserved_by" => "ops_team_b",
                 "station_reservation_status" => "reserved"
               }
               | _
             ]
           } = repair["source_contact_filter_report"]

    assert suppressed_count > 0

    refute Enum.any?(
             repair["source_candidate_activities"],
             &(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives station maintenance outages from availability-only mission-state entries" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:ground_network, [
        %{
          station_id: "equator_prime",
          availability: "maintenance",
          starts_at_s: 0.0,
          ends_at_s: 600.0
        }
      ])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}, %{id: "manual_review", events: [%{type: "operator_note"}]}],
        current_epoch_s: 0.0
      )

    outage = branch(artifact, "derived_station_outage_equator_prime")

    assert [
             %{
               "type" => "ground_station_outage",
               "ground_station_id" => "equator_prime",
               "starts_at_s" => starts_at_s,
               "ends_at_s" => ends_at_s
             }
           ] = outage["events"]

    assert starts_at_s == 0.0
    assert ends_at_s == 600.0

    repair = outage["repair_result"]

    assert %{
             "schema_contract" => "contact_filter_report.v1",
             "suppressed_candidate_count" => suppressed_count,
             "suppressed_candidates" => [
               %{
                 "suppressed_reason" => "ground_station_unavailable",
                 "station_availability" => "unavailable"
               }
               | _
             ]
           } = repair["source_contact_filter_report"]

    assert suppressed_count > 0

    refute Enum.any?(
             repair["source_candidate_activities"],
             &(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
