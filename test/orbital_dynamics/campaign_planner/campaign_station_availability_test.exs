defmodule OrbitalDynamics.CampaignPlanner.CampaignStationAvailabilityTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CampaignPlanner, Epoch, ResultSet, Schema}

  test "campaign resource summaries filter unavailable resource candidates before ranking" do
    result_set =
      ResultSet.new!(%{
        study_id: :campaign,
        trajectory_results: [],
        event_results: [
          target_visibility_result(:leo_1, :target_a, 0.0, 120.0, 2.0),
          access_result(:leo_1, :equator_prime, 0.0, 100.0)
        ],
        errors: [],
        assumptions: %{},
        metadata: %{}
      })

    artifact =
      CampaignPlanner.build(result_set,
        generated_at: ~U[2026-05-14 00:00:00Z],
        campaign: %{
          "targets" => [%{"id" => "target_a", "priority" => 2.0}],
          "constraints" => %{},
          "scoring_policy" => %{"contact_value_weight" => 1.0},
          "approval_policy" => %{"policy_bundle_id" => "degraded_payload_guard_v1"},
          "resource_summaries" => [
            %{
              "schema_contract" => "resource_summary.v1",
              "spacecraft_id" => "leo_1",
              "payload_available" => false,
              "antenna_available" => true,
              "downlink_margin" => 0.8,
              "assumptions" => %{"model" => "operator_supplied_summary"}
            }
          ]
        }
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_downlink_equator_prime_1"
           ]

    assert %{
             "schema_contract" => "resource_filter_report.v1",
             "model" => "resource_summary_availability_and_margin_filter",
             "input_candidate_count" => 2,
             "kept_candidate_count" => 1,
             "suppressed_candidate_count" => 1,
             "suppressed_candidates" => [
               %{
                 "id" => "leo_1_observe_target_a_1",
                 "type" => "observe",
                 "scenario_id" => "leo_1",
                 "suppressed_reason" => "payload_unavailable",
                 "approval_status" => "blocked_by_policy",
                 "policy_decision" => %{
                   "policy_bundle_id" => "degraded_payload_guard_v1"
                 },
                 "approval_rule_matches" => [
                   %{"rule_id" => "payload_unavailable_observation_block"}
                 ]
               }
             ]
           } = artifact["resource_filter_report"]

    assert "resource summary filters suppressed campaign candidates" in artifact["warnings"]

    refute Enum.any?(artifact["ranked_timelines"], fn timeline ->
             timeline["score_terms"]["selected_observation_count"] > 0
           end)

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} = Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "resource_filter_report.v1"}} =
             Schema.validate_artifact(artifact["resource_filter_report"])
  end

  test "campaign filters unavailable station contacts before ranking" do
    result_set =
      ResultSet.new!(%{
        study_id: :campaign,
        trajectory_results: [],
        event_results: [
          access_result(:leo_1, :equator_prime, 100.0, 200.0),
          access_result(:leo_2, :deep_space_net, 300.0, 400.0)
        ],
        errors: [],
        assumptions: %{},
        metadata: %{}
      })

    artifact =
      CampaignPlanner.build(result_set,
        generated_at: ~U[2026-05-14 00:00:00Z],
        campaign: %{
          "ground_network" => [
            %{
              "id" => "equator_maintenance",
              "ground_station_id" => "equator_prime",
              "status" => "maintenance",
              "starts_at_s" => 90.0,
              "ends_at_s" => 150.0
            },
            %{
              "id" => "dsn_reduced_capacity",
              "ground_station_id" => "deep_space_net",
              "status" => "available",
              "starts_at_s" => 250.0,
              "ends_at_s" => 450.0,
              "capacity_fraction" => "0.5"
            }
          ],
          "constraints" => %{},
          "scoring_policy" => %{"contact_value_weight" => 1.0},
          "approval_policy" => %{"policy_bundle_id" => "ground_network_allocation_v1"}
        }
      )

    assert {:ok, %{"status" => "pass"}} = Schema.validate_artifact(artifact)

    assert %{
             "schema_contract" => "station_calendar_report.v1",
             "model" => "campaign_ground_network_interval_overlay",
             "input_contact_count" => 2,
             "calendar_entry_count" => 2,
             "affected_contact_count" => 2,
             "affected_contacts" => affected_contacts
           } = artifact["station_calendar_report"]

    assert Enum.map(affected_contacts, & &1["station_calendar_entry_id"]) ==
             ["equator_maintenance", "dsn_reduced_capacity"]

    assert %{
             "approval_status" => "blocked_by_policy",
             "required_operator_action" => "review_station_availability",
             "policy_decision" => %{"policy_bundle_id" => "ground_network_allocation_v1"}
           } =
             maintenance_contact =
             Enum.find(
               affected_contacts,
               &(&1["station_calendar_entry_id"] == "equator_maintenance")
             )

    assert Enum.any?(
             maintenance_contact["approval_rule_matches"],
             &(&1["rule_id"] == "unavailable_station_contact_block")
           )

    assert Enum.any?(
             maintenance_contact["approval_rule_matches"],
             &(&1["rule_id"] == "missing_station_calendar_trust_review" and
                 &1["station_calendar_trust_boundary_status"] == "missing")
           )

    assert %{
             "approval_status" => "operator_review_required",
             "required_operator_action" => "review_reduced_station_capacity"
           } =
             reduced_contact =
             Enum.find(
               affected_contacts,
               &(&1["station_calendar_entry_id"] == "dsn_reduced_capacity")
             )

    assert Enum.any?(
             reduced_contact["approval_rule_matches"],
             &(&1["rule_id"] == "severe_capacity_reduction_review" and
                 &1["capacity_fraction"] == 0.5)
           )

    assert Enum.any?(
             reduced_contact["approval_rule_matches"],
             &(&1["rule_id"] == "missing_station_calendar_trust_review" and
                 &1["station_calendar_trust_boundary_status"] == "missing")
           )

    refute Enum.any?(
             artifact["candidate_activities"],
             &(&1["ground_station_id"] == "equator_prime")
           )

    reduced =
      Enum.find(artifact["candidate_activities"], &(&1["ground_station_id"] == "deep_space_net"))

    assert reduced["station_availability"] == "reduced_capacity"
    assert reduced["station_capacity_fraction"] == 0.5
    assert get_in(reduced, ["throughput_model", "station_capacity_fraction"]) == 0.5

    link_report = artifact["link_capacity_report"]
    reduced_row = Enum.find(link_report["rows"], &(&1["ground_station_id"] == "deep_space_net"))

    assert_in_delta reduced_row["capacity_adjusted_throughput_mb"],
                    reduced_row["estimated_throughput_mb"] * 0.5,
                    1.0e-9

    assert %{
             "approval_status" => "operator_review_required",
             "policy_decision" => %{"policy_bundle_id" => "ground_network_allocation_v1"}
           } = reduced_row

    assert Enum.any?(
             reduced_row["approval_rule_matches"],
             &(&1["rule_id"] == "severe_capacity_reduction_review" and
                 &1["capacity_fraction"] == 0.5)
           )

    assert %{
             "link_capacity_review_count" => 1
           } = artifact["operator_review_package"]

    assert %{
             "input_candidate_count" => 2,
             "kept_candidate_count" => 1,
             "suppressed_candidate_count" => 1,
             "suppressed_candidates" => [
               %{
                 "id" => "leo_1_downlink_equator_prime_1",
                 "ground_station_id" => "equator_prime",
                 "suppressed_reason" => "ground_station_unavailable",
                 "station_calendar_entry_id" => "equator_maintenance",
                 "approval_status" => "blocked_by_policy"
               }
             ]
           } = artifact["contact_filter_report"]

    assert "contact filters suppressed campaign contacts" in artifact["warnings"]

    assert %{
             "review_type" => "link_capacity_review",
             "source" => "campaign_plan.link_capacity_report.rows",
             "ground_station_id" => "deep_space_net",
             "capacity_adjusted_throughput_mb" => capacity_adjusted_throughput_mb,
             "selected_capacity_adjusted_throughput_mb" =>
               selected_capacity_adjusted_throughput_mb,
             "capacity_fraction_min" => 0.5,
             "capacity_fraction_max" => 0.5,
             "approval_status" => "operator_review_required",
             "required_operator_action" => "review_link_capacity_summary",
             "approval_rule_matches" => [
               %{"rule_id" => "severe_capacity_reduction_review", "capacity_fraction" => 0.5}
             ],
             "source_policy_decision" => %{
               "policy_bundle_id" => "ground_network_allocation_v1"
             },
             "source_link_capacity" => %{"ground_station_id" => "deep_space_net"}
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "link_capacity_review" and
                   &1["ground_station_id"] == "deep_space_net")
             )

    assert capacity_adjusted_throughput_mb == reduced_row["capacity_adjusted_throughput_mb"]

    assert selected_capacity_adjusted_throughput_mb ==
             reduced_row["selected_capacity_adjusted_throughput_mb"]

    assert %{
             "import_action" => "review_link_capacity",
             "source_review_type" => "link_capacity_review",
             "ground_station_id" => "deep_space_net",
             "capacity_adjusted_throughput_mb" => ^capacity_adjusted_throughput_mb,
             "selected_capacity_adjusted_throughput_mb" =>
               ^selected_capacity_adjusted_throughput_mb,
             "capacity_fraction_min" => 0.5,
             "capacity_fraction_max" => 0.5,
             "source_link_capacity" => %{"ground_station_id" => "deep_space_net"},
             "source_policy_decision" => %{
               "policy_bundle_id" => "ground_network_allocation_v1"
             }
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["source_review_type"] == "link_capacity_review" and
                   &1["ground_station_id"] == "deep_space_net")
             )

    adjusted_row_total =
      link_report["rows"]
      |> Enum.map(& &1["capacity_adjusted_throughput_mb"])
      |> Enum.sum()

    assert_in_delta link_report["capacity_adjusted_throughput_mb"], adjusted_row_total, 1.0e-9

    assert length(artifact["candidate_activities"]) == 1
  end

  test "campaign does not apply uplink-only station outage to downlink contacts" do
    result_set =
      ResultSet.new!(%{
        study_id: :campaign,
        trajectory_results: [],
        event_results: [
          access_result(:leo_1, :equator_prime, 100.0, 200.0),
          access_result(:leo_2, :deep_space_net, 100.0, 200.0)
        ],
        errors: [],
        assumptions: %{},
        metadata: %{}
      })

    artifact =
      CampaignPlanner.build(result_set,
        generated_at: ~U[2026-05-14 00:00:00Z],
        campaign: %{
          "ground_network" => [
            %{
              "id" => "equator_uplink_outage",
              "ground_station_id" => "equator_prime",
              "status" => "maintenance",
              "directions" => ["uplink"],
              "starts_at_s" => 90.0,
              "ends_at_s" => 210.0,
              "provenance" => %{"trust_boundary" => "ops_station_calendar"}
            },
            %{
              "id" => "dsn_downlink_outage",
              "ground_station_id" => "deep_space_net",
              "status" => "maintenance",
              "directions" => ["downlink"],
              "starts_at_s" => 90.0,
              "ends_at_s" => 210.0,
              "provenance" => %{"trust_boundary" => "ops_station_calendar"}
            }
          ],
          "constraints" => %{},
          "scoring_policy" => %{"contact_value_weight" => 1.0},
          "approval_policy" => %{"policy_bundle_id" => "ground_network_allocation_v1"}
        }
      )

    assert {:ok, %{"status" => "pass"}} = Schema.validate_artifact(artifact)

    assert %{
             "schema_contract" => "station_calendar_report.v1",
             "input_contact_count" => 2,
             "calendar_entry_count" => 2,
             "affected_contact_count" => 1,
             "affected_contacts" => [
               %{
                 "contact_id" => "leo_2_downlink_deep_space_net_1",
                 "ground_station_id" => "deep_space_net",
                 "direction" => "downlink",
                 "station_calendar_entry_id" => "dsn_downlink_outage",
                 "station_calendar_directions" => ["downlink"],
                 "station_availability" => "unavailable"
               }
             ]
           } = artifact["station_calendar_report"]

    assert [
             %{
               "id" => "leo_1_downlink_equator_prime_1",
               "type" => "downlink",
               "direction" => "downlink",
               "ground_station_id" => "equator_prime"
             } = unaffected_candidate
           ] = Enum.sort_by(artifact["candidate_activities"], & &1["ground_station_id"])

    refute Map.has_key?(unaffected_candidate, "station_calendar_entry_id")
    assert unaffected_candidate["station_availability"] == "available"

    assert %{
             "kept_candidate_count" => 1,
             "suppressed_candidate_count" => 1,
             "suppressed_candidates" => [
               %{
                 "id" => "leo_2_downlink_deep_space_net_1",
                 "suppressed_reason" => "ground_station_unavailable",
                 "station_calendar_entry_id" => "dsn_downlink_outage",
                 "station_calendar_directions" => ["downlink"]
               }
             ]
           } = artifact["contact_filter_report"]

    assert %{
             "contact_id" => "leo_1_downlink_equator_prime_1",
             "allocation_status" => "allocated",
             "allocation_reason" => "available"
           } =
             Enum.find(
               artifact["contact_allocation_report"]["rows"],
               &(&1["contact_id"] == "leo_1_downlink_equator_prime_1")
             )

    refute Enum.any?(
             artifact["contact_allocation_report"]["rows"],
             &(&1["contact_id"] == "leo_2_downlink_deep_space_net_1")
           )

    assert [
             %{
               "review_type" => "station_calendar_review",
               "contact_id" => "leo_2_downlink_deep_space_net_1",
               "station_calendar_entry_id" => "dsn_downlink_outage"
             }
           ] =
             Enum.filter(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "station_calendar_review")
             )

    assert [
             %{
               "import_action" => "review_station_calendar",
               "contact_id" => "leo_2_downlink_deep_space_net_1",
               "station_calendar_entry_id" => "dsn_downlink_outage"
             }
           ] =
             Enum.filter(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["import_action"] == "review_station_calendar")
             )
  end

  test "campaign marks ambiguous same-priority station calendar entries without choosing capacity" do
    result_set =
      ResultSet.new!(%{
        study_id: :campaign,
        trajectory_results: [],
        event_results: [
          access_result(:leo_1, :equator_prime, 100.0, 200.0)
        ],
        errors: [],
        assumptions: %{},
        metadata: %{}
      })

    artifact =
      CampaignPlanner.build(result_set,
        generated_at: ~U[2026-05-14 00:00:00Z],
        campaign: %{
          "ground_network" => [
            %{
              "id" => "equator_capacity_low",
              "ground_station_id" => "equator_prime",
              "status" => "available",
              "starts_at_s" => 90.0,
              "ends_at_s" => 210.0,
              "capacity_fraction" => 0.25
            },
            %{
              "id" => "equator_capacity_high",
              "ground_station_id" => "equator_prime",
              "status" => "available",
              "starts_at_s" => 90.0,
              "ends_at_s" => 210.0,
              "capacity_fraction" => 0.75
            }
          ],
          "constraints" => %{},
          "scoring_policy" => %{"contact_value_weight" => 1.0}
        }
      )

    assert {:ok, %{"status" => "pass"}} = Schema.validate_artifact(artifact)

    assert [
             %{
               "station_calendar_entry_id" =>
                 "ambiguous_station_calendar:equator_capacity_high:equator_capacity_low",
               "station_availability" => "reduced_capacity",
               "station_calendar_entry_ambiguous" => true,
               "station_calendar_ambiguous_entry_count" => 2,
               "station_calendar_ambiguous_entry_ids" => [
                 "equator_capacity_high",
                 "equator_capacity_low"
               ],
               "required_operator_action" => "review_reduced_station_capacity"
             } = affected
           ] = artifact["station_calendar_report"]["affected_contacts"]

    refute Map.has_key?(affected, "capacity_fraction")

    assert [candidate] = artifact["candidate_activities"]
    assert candidate["station_availability"] == "reduced_capacity"

    assert candidate["station_calendar_entry_id"] ==
             "ambiguous_station_calendar:equator_capacity_high:equator_capacity_low"

    assert candidate["station_calendar_entry_ambiguous"]
    refute Map.has_key?(candidate, "station_capacity_fraction")
    refute Map.has_key?(candidate["throughput_model"], "station_capacity_fraction")

    assert [link_row] = artifact["link_capacity_report"]["rows"]
    assert link_row["capacity_fraction_min"] == 1.0
    assert link_row["capacity_fraction_max"] == 1.0
  end

  test "campaign marks ambiguous reserved station entries without choosing reservation metadata" do
    result_set =
      ResultSet.new!(%{
        study_id: :campaign,
        trajectory_results: [],
        event_results: [
          access_result(:leo_1, :equator_prime, 100.0, 200.0)
        ],
        errors: [],
        assumptions: %{},
        metadata: %{}
      })

    artifact =
      CampaignPlanner.build(result_set,
        generated_at: ~U[2026-05-14 00:00:00Z],
        campaign: %{
          "ground_network" => [
            %{
              "id" => "equator_reserved_a",
              "ground_station_id" => "equator_prime",
              "availability" => "reserved",
              "starts_at_s" => 90.0,
              "ends_at_s" => 210.0,
              "reservation_id" => "reservation_a",
              "reserved_by" => "ops_team_a",
              "reservation_status" => "tentative"
            },
            %{
              "id" => "equator_reserved_b",
              "ground_station_id" => "equator_prime",
              "availability" => "reserved",
              "starts_at_s" => 90.0,
              "ends_at_s" => 210.0,
              "reservation_id" => "reservation_b",
              "reserved_by" => "ops_team_b",
              "reservation_status" => "confirmed"
            }
          ],
          "constraints" => %{},
          "scoring_policy" => %{"contact_value_weight" => 1.0}
        }
      )

    assert {:ok, %{"status" => "pass"}} = Schema.validate_artifact(artifact)

    assert [
             %{
               "station_calendar_entry_id" =>
                 "ambiguous_station_calendar:equator_reserved_a:equator_reserved_b",
               "station_availability" => "reserved",
               "station_calendar_entry_ambiguous" => true,
               "station_calendar_ambiguous_entry_ids" => [
                 "equator_reserved_a",
                 "equator_reserved_b"
               ],
               "station_contention_status" => "reserved_overlap",
               "required_operator_action" => "review_station_reservation_overlap"
             } = affected
           ] = artifact["station_calendar_report"]["affected_contacts"]

    refute Map.has_key?(affected, "station_reservation_id")
    refute Map.has_key?(affected, "station_reserved_by")
    refute Map.has_key?(affected, "station_reservation_status")

    assert [] = artifact["candidate_activities"]

    assert %{
             "input_candidate_count" => 1,
             "kept_candidate_count" => 0,
             "suppressed_candidate_count" => 1,
             "suppressed_candidates" => [
               %{
                 "id" => "leo_1_downlink_equator_prime_1",
                 "station_availability" => "reserved",
                 "station_contention_status" => "reserved_overlap",
                 "suppressed_reason" => "ground_station_reserved",
                 "station_calendar_entry_id" =>
                   "ambiguous_station_calendar:equator_reserved_a:equator_reserved_b"
               } = suppressed
             ]
           } = artifact["contact_filter_report"]

    refute Map.has_key?(suppressed, "station_reservation_id")
    refute Map.has_key?(suppressed, "station_reserved_by")
    refute Map.has_key?(suppressed, "station_reservation_status")
  end

  test "campaign overlays reserved station calendar entries with reservation metadata" do
    result_set =
      ResultSet.new!(%{
        study_id: :campaign_reserved,
        trajectory_results: [],
        event_results: [
          access_result(:leo_1, :equator_prime, 100.0, 200.0)
        ],
        errors: [],
        assumptions: %{},
        metadata: %{}
      })

    artifact =
      CampaignPlanner.build(result_set,
        generated_at: ~U[2026-05-14 00:00:00Z],
        campaign: %{
          "ground_network" => [
            %{
              "id" => "equator_reduced_capacity",
              "ground_station_id" => "equator_prime",
              "status" => "available",
              "starts_at_s" => 90.0,
              "ends_at_s" => 170.0,
              "capacity_fraction" => 0.5
            },
            %{
              "id" => "equator_reserved",
              "ground_station_id" => "equator_prime",
              "availability" => "reserved",
              "starts_at_s" => 120.0,
              "ends_at_s" => 150.0,
              "reservation_id" => "reservation_42",
              "reserved_by" => "ops_team_b"
            }
          ],
          "approval_policy" => %{"policy_bundle_id" => "ground_network_allocation_v1"},
          "constraints" => %{},
          "scoring_policy" => %{"contact_value_weight" => 1.0}
        }
      )

    assert {:ok, %{"status" => "pass"}} = Schema.validate_artifact(artifact)

    assert %{
             "affected_contact_count" => 1,
             "affected_contacts" => [
               %{
                 "station_calendar_entry_id" => "equator_reserved",
                 "station_availability" => "reserved",
                 "station_contention_status" => "reserved_overlap",
                 "station_reservation_id" => "reservation_42",
                 "station_reserved_by" => "ops_team_b",
                 "station_reservation_status" => "reserved"
               }
             ]
           } = artifact["station_calendar_report"]

    assert %{"station_calendar_review_count" => 1} = artifact["operator_review_package"]

    assert %{
             "review_type" => "station_calendar_review",
             "source" => "campaign_plan.station_calendar_report.affected_contacts",
             "contact_id" => "leo_1_downlink_equator_prime_1",
             "ground_station_id" => "equator_prime",
             "station_calendar_entry_id" => "equator_reserved",
             "station_availability" => "reserved",
             "station_contention_status" => "reserved_overlap",
             "station_reservation_id" => "reservation_42",
             "station_reserved_by" => "ops_team_b",
             "station_reservation_status" => "reserved",
             "required_operator_action" => "review_station_reservation_overlap",
             "source_policy_decision" => %{
               "policy_bundle_id" => "ground_network_allocation_v1"
             },
             "source_station_calendar_review" => %{
               "contact_id" => "leo_1_downlink_equator_prime_1"
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "station_calendar_review")
             )

    assert %{
             "import_action" => "review_station_calendar",
             "source_review_type" => "station_calendar_review",
             "contact_id" => "leo_1_downlink_equator_prime_1",
             "ground_station_id" => "equator_prime",
             "station_calendar_entry_id" => "equator_reserved",
             "station_availability" => "reserved",
             "station_contention_status" => "reserved_overlap",
             "station_reservation_id" => "reservation_42",
             "source_station_calendar_review" => %{
               "contact_id" => "leo_1_downlink_equator_prime_1"
             }
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["import_action"] == "review_station_calendar")
             )

    assert %{
             "input_candidate_count" => 1,
             "kept_candidate_count" => 0,
             "suppressed_candidate_count" => 1,
             "suppressed_candidates" => [
               %{
                 "id" => "leo_1_downlink_equator_prime_1",
                 "station_availability" => "reserved",
                 "station_calendar_entry_id" => "equator_reserved",
                 "station_contention_status" => "reserved_overlap",
                 "station_reservation_id" => "reservation_42",
                 "station_reserved_by" => "ops_team_b",
                 "station_reservation_status" => "reserved",
                 "suppressed_reason" => "ground_station_reserved",
                 "approval_status" => "operator_review_required",
                 "policy_decision" => %{
                   "schema_contract" => "policy_decision.v1",
                   "policy_bundle_id" => "ground_network_allocation_v1",
                   "classification" => "operator_review_required"
                 },
                 "approval_rule_matches" => rule_matches
               }
             ]
           } = artifact["contact_filter_report"]

    assert [] = artifact["candidate_activities"]
    assert [] = artifact["contact_allocation_report"]["rows"]

    assert Enum.any?(
             rule_matches,
             &(&1["rule_id"] == "reserved_station_contact_review" and
                 &1["station_reservation_status"] == "reserved")
           )

    assert Enum.any?(
             artifact["operator_review_package"]["rows"],
             &(&1["review_type"] == "contact_suppression" and
                 &1["activity_id"] == "leo_1_downlink_equator_prime_1" and
                 get_in(&1, ["source_contact_suppression", "station_reservation_id"]) ==
                   "reservation_42" and
                 get_in(&1, ["source_policy_decision", "policy_bundle_id"]) ==
                   "ground_network_allocation_v1")
           )

    refute Enum.any?(
             artifact["operator_review_package"]["rows"],
             &(&1["review_type"] == "contact_allocation_review" and
                 &1["contact_id"] == "leo_1_downlink_equator_prime_1")
           )
  end

  defp target_visibility_result(scenario_id, target_id, starts_at_s, ends_at_s, priority) do
    %{
      scenario_id: scenario_id,
      event_type: :target_visibility,
      events: [
        %{
          type: :target_visibility,
          starts_at: Epoch.new!(starts_at_s, :tdb),
          ends_at: Epoch.new!(ends_at_s, :tdb),
          metadata: %{
            target_id: target_id,
            target_priority: priority,
            max_elevation_deg: 60.0,
            minimum_elevation_deg: 10.0
          }
        }
      ],
      source: %{target_id: target_id}
    }
  end

  defp access_result(scenario_id, ground_station_id, starts_at_s, ends_at_s) do
    %{
      scenario_id: scenario_id,
      event_type: :ground_station_access,
      events: [
        %{
          type: :ground_station_access,
          starts_at: Epoch.new!(starts_at_s, :tdb),
          ends_at: Epoch.new!(ends_at_s, :tdb),
          metadata: %{
            max_elevation_deg: 45.0,
            minimum_elevation_deg: 5.0
          }
        }
      ],
      source: %{ground_station_id: ground_station_id}
    }
  end
end
