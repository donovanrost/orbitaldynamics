Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyContactIntentSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CandidateRefresh
  alias OrbitalDynamics.Communications.ContactIntent
  alias OrbitalDynamics.Schema

  test "strategy carries mission-state contact intent summaries into branch refresh requests" do
    contact_intent_summary = fn prefix, contacts ->
      contacts
      |> ContactIntent.summary()
      |> Map.put("source", "campaign_planner_test.#{prefix}.contact_intent_summary")
      |> Map.put("provenance", %{"trust_boundary" => "#{prefix}_contact_intent_summary_boundary"})
    end

    direct_summary =
      contact_intent_summary.("direct", [
        %{
          "schema_contract" => "contact_intent.v1",
          "id" => "direct_summary_downlink_contact",
          "activity_id" => "direct_summary_downlink_contact",
          "ground_station_id" => "equator_prime",
          "direction" => "downlink",
          "required_capacity_fraction" => 0.25
        },
        %{
          "schema_contract" => "contact_intent.v1",
          "id" => "direct_summary_command_contact",
          "activity_id" => "direct_summary_command_contact",
          "ground_station_id" => "dss_43",
          "direction" => "command"
        }
      ])

    canonical_summary =
      contact_intent_summary.("canonical", [
        %{
          "schema_contract" => "contact_intent.v1",
          "id" => "canonical_summary_health_contact",
          "activity_id" => "canonical_summary_health_contact",
          "ground_station_id" => "canberra",
          "direction" => "health_check"
        }
      ])

    wrapped_summary =
      contact_intent_summary.("wrapped", [
        %{
          "schema_contract" => "contact_intent.v1",
          "id" => "wrapped_summary_tracking_contact",
          "activity_id" => "wrapped_summary_tracking_contact",
          "ground_station_id" => "dss_43",
          "direction" => "tracking",
          "capacity_model" => %{"station_capacity_requirement" => 0.4}
        }
      ])

    result_wrapped_summary =
      contact_intent_summary.("result_wrapped", [
        %{
          "schema_contract" => "contact_intent.v1",
          "id" => "result_summary_uplink_contact",
          "activity_id" => "result_summary_uplink_contact",
          "ground_station_id" => "canberra",
          "direction" => "uplink",
          "throughput_model" => %{"required_capacity_fraction" => 0.15}
        }
      ])

    assert {:ok, %{"schema_contract" => "contact_intent_summary.v1"}} =
             Schema.validate_artifact(direct_summary)

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_contact_intent_summary", direct_summary)
      |> Map.put("contact_intent_summary", canonical_summary)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "contact_intent_summary" => Map.delete(wrapped_summary, "provenance"),
        "provenance" => %{"trust_boundary" => "wrapped_contact_intent_summary_boundary"}
      })
      |> Map.put(:result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "contact_intent_summary" => Map.delete(result_wrapped_summary, "provenance"),
        "provenance" => %{
          "trust_boundary" => "result_wrapped_contact_intent_summary_boundary"
        }
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    urgent = branch(artifact, "urgent")

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             candidate_source = urgent["assumptions"]["candidate_source"]

    source_report_input_paths = candidate_source["source_report_input_paths"]

    for source_path <- [
          "mission_state.source_contact_intent_summary",
          "mission_state.contact_intent_summary",
          "mission_state.source_result_artifact.contact_intent_summary",
          "mission_state.result_artifact.contact_intent_summary"
        ] do
      assert source_path in source_report_input_paths

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 5,
             "source_report_contact_intent_capacity_pack_required_contact_count" => 3,
             "source_report_contact_intent_capacity_pack_required_capacity_fraction" => 0.8,
             "source_report_contact_intent_capacity_pack_required_capacity_fraction_by_direction" =>
               %{
                 "downlink" => 0.25,
                 "tracking" => 0.4,
                 "uplink" => 0.15
               },
             "source_report_contact_intent_direction_routing" => %{
               "command" => %{
                 "contact_count" => 1,
                 "contact_ids" => ["direct_summary_command_contact"],
                 "capacity_pack_contact_ids" => []
               },
               "downlink" => %{
                 "contact_count" => 1,
                 "contact_ids" => ["direct_summary_downlink_contact"],
                 "capacity_pack_required_capacity_fraction" => 0.25,
                 "capacity_pack_contact_ids" => ["direct_summary_downlink_contact"]
               },
               "health_check" => %{
                 "contact_count" => 1,
                 "contact_ids" => ["canonical_summary_health_contact"],
                 "capacity_pack_contact_ids" => []
               },
               "tracking" => %{
                 "contact_count" => 1,
                 "contact_ids" => ["wrapped_summary_tracking_contact"],
                 "capacity_pack_required_capacity_fraction" => 0.4,
                 "capacity_pack_contact_ids" => ["wrapped_summary_tracking_contact"]
               },
               "uplink" => %{
                 "contact_count" => 1,
                 "contact_ids" => ["result_summary_uplink_contact"],
                 "capacity_pack_required_capacity_fraction" => 0.15,
                 "capacity_pack_contact_ids" => ["result_summary_uplink_contact"]
               }
             },
             "source_reports" => %{
               "contact_intent" => %{
                 "source_summary_schema_contract_counts" => %{
                   "contact_intent_summary.v1" => 4
                 },
                 "source_summary_model_counts" => %{
                   "artifact_only_contact_intent_summary" => 4
                 },
                 "source_artifact_type_counts" => %{"contact_intent.v1" => 4}
               }
             }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "contract" => "contact_intent_summary.v1",
             "source_report_count" => 4,
             "source_report_row_count" => 5,
             "source_report_paths" => replay_source_paths,
             "capacity_pack_required_contact_count" => 3,
             "capacity_pack_required_capacity_fraction" => 0.8,
             "branch_local_contact_intent_pressure" => true,
             "branch_local_capacity_pack_pressure" => true,
             "assumptions" => %{
               "contact_generation" => "not_performed_by_summary",
               "contact_allocation" => "not_performed_by_summary"
             }
           } = CandidateRefresh.contact_intent_replay_summary(candidate_source)

    for source_path <- [
          "mission_state.source_contact_intent_summary",
          "mission_state.contact_intent_summary",
          "mission_state.source_result_artifact.contact_intent_summary",
          "mission_state.result_artifact.contact_intent_summary"
        ] do
      assert source_path in replay_source_paths
    end

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy scores row-bearing contact intent summaries from row evidence" do
    row = fn id, activity_id, overrides ->
      Map.merge(
        %{
          "schema_contract" => "contact_intent.v1",
          "id" => id,
          "activity_id" => activity_id,
          "activity_type" => "downlink",
          "scenario_id" => "leo_1",
          "spacecraft_id" => "leo_1",
          "ground_station_id" => "equator_prime",
          "direction" => "downlink",
          "starts_at_s" => 700.0,
          "ends_at_s" => 760.0,
          "estimated_throughput_mb" => 36.0,
          "approval_status" => "blocked_by_policy",
          "required_operator_action" => "review_contact_intent",
          "policy_decision" => %{
            "classification" => "blocked_by_policy",
            "policy_bundle_id" => "contact_command_review_v1"
          },
          "station_availability" => "reserved",
          "station_calendar_entry_id" => "#{id}_partner_reservation",
          "station_calendar_provider_id" => "partner_calendar",
          "station_calendar_provider_entry_id" => "#{id}_partner_entry",
          "station_calendar_status" => "reserved",
          "station_calendar_trust_boundary_status" => "declared",
          "station_reservation_id" => "reservation_#{id}",
          "station_reserved_by" => "partner_team",
          "station_reservation_status" => "confirmed",
          "station_reservation_match_status" => "unmatched_overlap",
          "source_window_id" => "window:leo_1:ground_station_access:equator_prime:#{id}"
        },
        overrides
      )
    end

    summary_with_stale_top_level = fn rows, source, trust_boundary ->
      rows
      |> ContactIntent.summary()
      |> Map.put("rows", rows)
      |> Map.put("source", source)
      |> Map.put("provenance", %{"trust_boundary" => trust_boundary})
      |> Map.merge(%{
        "contact_intent_count" => 99,
        "capacity_pack_required_contact_count" => 0,
        "directions" => ["uplink"],
        "direction_counts" => %{"uplink" => 99},
        "contact_ids_by_direction" => %{"uplink" => ["stale_contact"]},
        "direction_routing" => %{
          "uplink" => %{"contact_count" => 99, "contact_ids" => ["stale_contact"]}
        }
      })
    end

    mission_summary_row =
      row.("summary_intent_blocked", "dl_summary_intent_blocked", %{
        "station_calendar_provider_entry_id" => "partner_entry_45"
      })

    prior_summary_row =
      row.("prior_summary_intent_blocked", "dl_prior_summary_intent_blocked", %{
        "ground_station_id" => "deep_space_net",
        "starts_at_s" => 800.0,
        "ends_at_s" => 860.0,
        "estimated_throughput_mb" => 41.0
      })

    result_summary_row =
      row.("result_summary_intent_invalid", "dl_result_summary_intent_invalid", %{
        "approval_status" => "approved",
        "invalid_activity_input" => true,
        "invalid_activity_input_reason" => "missing_external_activity_id",
        "starts_at_s" => 870.0,
        "ends_at_s" => 890.0,
        "estimated_throughput_mb" => 5.0
      })

    mirrored_direct_row =
      row.("mirrored_intent_blocked", "dl_mirrored_intent_blocked", %{
        "starts_at_s" => 900.0,
        "ends_at_s" => 960.0,
        "estimated_throughput_mb" => 12.0,
        "trust_boundary" => "direct_mirrored_contact_intent_boundary"
      })

    mirrored_summary_row =
      Map.delete(mirrored_direct_row, "trust_boundary")

    mission_summary =
      summary_with_stale_top_level.(
        [mission_summary_row, mirrored_summary_row],
        "campaign_planner_test.stale_contact_intent_summary",
        "summary_contact_intent_boundary"
      )

    prior_summary =
      summary_with_stale_top_level.(
        [prior_summary_row, mirrored_summary_row],
        "campaign_planner_test.prior_contact_intent_summary",
        "prior_summary_contact_intent_boundary"
      )

    result_summary =
      summary_with_stale_top_level.(
        [result_summary_row],
        "campaign_planner_test.result_contact_intent_summary",
        "result_summary_contact_intent_boundary"
      )

    prior_plan =
      base_plan(%{
        "source_contact_intent" => mirrored_direct_row,
        "source_contact_intent_summary" => prior_summary,
        "source_result_artifact" => %{
          "schema_contract" => "result_artifact.v1",
          "artifact_type" => "campaign_strategy_result_artifact",
          "contact_intent_summary" => Map.delete(result_summary, "provenance"),
          "provenance" => %{
            "trust_boundary" => "result_artifact_contact_intent_summary_boundary"
          }
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put("source_contact_intent_summary", mission_summary),
        derive_branches?: true,
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    urgent = branch(artifact, "urgent")
    candidate_source = urgent["assumptions"]["candidate_source"]

    assert %{
             "source_report_contact_intent_directions" => ["downlink"],
             "source_report_contact_intent_direction_counts" => %{"downlink" => 2},
             "source_report_contact_intent_contact_ids_by_direction" => %{
               "downlink" => ["mirrored_intent_blocked", "summary_intent_blocked"]
             },
             "source_report_contact_intent_direction_routing" => %{
               "downlink" => %{
                 "contact_count" => 2,
                 "contact_ids" => ["mirrored_intent_blocked", "summary_intent_blocked"]
               }
             }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    refute Map.has_key?(
             candidate_source["candidate_refresh_request_source_report_summary"][
               "source_report_contact_intent_direction_counts"
             ],
             "uplink"
           )

    assert %{
             "directions" => ["downlink"],
             "direction_counts" => %{"downlink" => 2},
             "contact_ids_by_direction" => %{
               "downlink" => ["mirrored_intent_blocked", "summary_intent_blocked"]
             },
             "branch_local_contact_intent_pressure" => true
           } = CandidateRefresh.contact_intent_replay_summary(candidate_source)

    blocked_branch =
      branch(
        artifact,
        "derived_contact_intent_pressure_blocked_by_policy_dl_summary_intent_blocked"
      )

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "equator_prime",
             "source_activity_id" => "dl_summary_intent_blocked",
             "required_downlink_mb" => 36.0,
             "source_window_id" =>
               "window:leo_1:ground_station_access:equator_prime:summary_intent_blocked",
             "approval_status" => "blocked_by_policy",
             "required_operator_action" => "review_contact_intent",
             "contact_intent_gate_status" => "blocked_by_policy",
             "policy_classification" => "blocked_by_policy",
             "policy_bundle_id" => "contact_command_review_v1",
             "station_availability" => "reserved",
             "station_calendar_entry_id" => "summary_intent_blocked_partner_reservation",
             "station_calendar_provider_id" => "partner_calendar",
             "station_calendar_provider_entry_id" => "partner_entry_45",
             "station_calendar_status" => "reserved",
             "station_calendar_trust_boundary_status" => "declared",
             "station_reservation_id" => "reservation_summary_intent_blocked",
             "station_reserved_by" => "partner_team",
             "station_reservation_status" => "confirmed",
             "station_reservation_match_status" => "unmatched_overlap",
             "feedback_source" => "mission_state.source_contact_intent_summary",
             "feedback_scope" => "contact_intent",
             "trust_boundary" => "summary_contact_intent_boundary"
           } = List.first(blocked_branch["events"])

    prior_branch =
      branch(
        artifact,
        "derived_contact_intent_pressure_blocked_by_policy_dl_prior_summary_intent_blocked"
      )

    assert %{
             "ground_station_id" => "deep_space_net",
             "source_activity_id" => "dl_prior_summary_intent_blocked",
             "feedback_source" => "prior_plan.source_contact_intent_summary",
             "trust_boundary" => "prior_summary_contact_intent_boundary"
           } = List.first(prior_branch["events"])

    result_branch =
      branch(
        artifact,
        "derived_contact_intent_pressure_invalid_activity_input_dl_result_summary_intent_invalid"
      )

    assert %{
             "source_activity_id" => "dl_result_summary_intent_invalid",
             "invalid_activity_input" => true,
             "invalid_activity_input_reason" => "missing_external_activity_id",
             "contact_intent_gate_status" => "invalid_activity_input",
             "feedback_source" => "prior_plan.source_result_artifact.contact_intent_summary",
             "trust_boundary" => "result_artifact_contact_intent_summary_boundary"
           } = List.first(result_branch["events"])

    mirrored_branches =
      artifact["branches"]
      |> Enum.filter(
        &String.starts_with?(
          &1["branch_id"],
          "derived_contact_intent_pressure_blocked_by_policy_dl_mirrored_intent_blocked"
        )
      )

    assert [
             %{
               "branch_id" =>
                 "derived_contact_intent_pressure_blocked_by_policy_dl_mirrored_intent_blocked"
             } = mirrored_branch
           ] =
             mirrored_branches

    assert %{
             "feedback_source" => "prior_plan.source_contact_intent",
             "trust_boundary" => "direct_mirrored_contact_intent_boundary"
           } = List.first(mirrored_branch["events"])

    assert_contact_intent_pressure_score_terms(blocked_branch, artifact)
    assert_contact_intent_pressure_score_terms(prior_branch, artifact)
    assert_contact_intent_pressure_score_terms(result_branch, artifact)
    assert_contact_intent_pressure_score_terms(mirrored_branch, artifact)

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy carries mission-state contact intent rows into branch refresh requests" do
    contact_intent = fn prefix, direction, ground_station_id, capacity_fraction ->
      %{
        "schema_contract" => "contact_intent.v1",
        "id" => "#{prefix}_contact",
        "activity_id" => "#{prefix}_contact",
        "scenario_id" => "leo_1",
        "ground_station_id" => ground_station_id,
        "direction" => direction,
        "starts_at_s" => 10.0,
        "ends_at_s" => 70.0,
        "station_calendar_status" => "reserved",
        "cadence_import_status" => "ready_for_import",
        "policy_classification" => "review_only",
        "required_capacity_fraction" => capacity_fraction,
        "provenance" => %{"trust_boundary" => "#{prefix}_contact_intent_boundary"}
      }
    end

    direct_intent = contact_intent.("direct", "Down Link", "equator_prime", 0.25)
    source_plural_intent = contact_intent.("source_plural", "tracking_pass", "dss_43", 0.1)

    canonical_singular_intent =
      contact_intent.("canonical_singular", "s-band command", "goldstone", 0.1)

    canonical_direct_intent =
      contact_intent.("canonical_direct", "s-band command", "goldstone", 0.35)

    source_wrapped_intent = contact_intent.("source_wrapped", "tracking_pass", "dss_43", 0.4)

    source_wrapped_plural_intent =
      contact_intent.("source_wrapped_plural", "tracking_pass", "dss_43", 0.2)

    result_wrapped_intent = contact_intent.("result_wrapped", "s-band command", "canberra", 0.15)

    result_wrapped_plural_intent =
      contact_intent.("result_wrapped_plural", "s-band command", "canberra", 0.05)

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_contact_intent", direct_intent)
      |> Map.put("source_contact_intents", [source_plural_intent])
      |> Map.put("contact_intent", canonical_singular_intent)
      |> Map.put("contact_intents", [canonical_direct_intent])
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "contact_intent" => Map.delete(source_wrapped_intent, "provenance"),
        "source_contact_intents" => [
          Map.delete(source_wrapped_plural_intent, "provenance")
        ],
        "provenance" => %{"trust_boundary" => "source_wrapped_contact_intent_boundary"}
      })
      |> Map.put(:result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_contact_intent" => Map.delete(result_wrapped_intent, "provenance"),
        "contact_intents" => [
          Map.delete(result_wrapped_plural_intent, "provenance")
        ],
        "provenance" => %{"trust_boundary" => "result_wrapped_contact_intent_boundary"}
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    urgent = branch(artifact, "urgent")

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             candidate_source = urgent["assumptions"]["candidate_source"]

    for source_path <- [
          "mission_state.source_contact_intent",
          "mission_state.source_contact_intents",
          "mission_state.contact_intent",
          "mission_state.contact_intents",
          "mission_state.source_result_artifact.contact_intent",
          "mission_state.source_result_artifact.source_contact_intents",
          "mission_state.result_artifact.contact_intents",
          "mission_state.result_artifact.source_contact_intent"
        ] do
      assert source_path in candidate_source["source_report_input_paths"]

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    request_summary = candidate_source["candidate_refresh_request_source_report_summary"]

    assert request_summary["source_report_count"] == 8
    assert request_summary["source_report_row_count"] == 8

    assert request_summary[
             "source_report_contact_intent_capacity_pack_required_contact_count"
           ] == 8

    assert_in_delta request_summary[
                      "source_report_contact_intent_capacity_pack_required_capacity_fraction"
                    ],
                    1.6,
                    1.0e-12

    request_capacity_by_direction =
      request_summary[
        "source_report_contact_intent_capacity_pack_required_capacity_fraction_by_direction"
      ]

    assert_in_delta request_capacity_by_direction["command"], 0.65, 1.0e-12
    assert_in_delta request_capacity_by_direction["downlink"], 0.25, 1.0e-12
    assert_in_delta request_capacity_by_direction["tracking"], 0.7, 1.0e-12

    assert request_summary[
             "source_report_contact_intent_capacity_pack_contact_ids_by_direction"
           ] == %{
             "command" => [
               "canonical_direct_contact",
               "canonical_singular_contact",
               "result_wrapped_contact",
               "result_wrapped_plural_contact"
             ],
             "downlink" => ["direct_contact"],
             "tracking" => [
               "source_plural_contact",
               "source_wrapped_contact",
               "source_wrapped_plural_contact"
             ]
           }

    assert request_summary[
             "source_report_contact_intent_contact_ids_by_direction"
           ] == %{
             "command" => [
               "canonical_direct_contact",
               "canonical_singular_contact",
               "result_wrapped_contact",
               "result_wrapped_plural_contact"
             ],
             "downlink" => ["direct_contact"],
             "tracking" => [
               "source_plural_contact",
               "source_wrapped_contact",
               "source_wrapped_plural_contact"
             ]
           }

    request_direction_routing =
      candidate_source["candidate_refresh_request_source_report_summary"][
        "source_report_contact_intent_direction_routing"
      ]

    assert get_in(request_direction_routing, ["command", "contact_ids"]) == [
             "canonical_direct_contact",
             "canonical_singular_contact",
             "result_wrapped_contact",
             "result_wrapped_plural_contact"
           ]

    assert get_in(request_direction_routing, ["command", "capacity_pack_contact_ids"]) == [
             "canonical_direct_contact",
             "canonical_singular_contact",
             "result_wrapped_contact",
             "result_wrapped_plural_contact"
           ]

    assert_in_delta get_in(request_direction_routing, [
                      "command",
                      "capacity_pack_required_capacity_fraction"
                    ]),
                    0.65,
                    1.0e-12

    assert get_in(request_direction_routing, ["tracking", "contact_ids"]) == [
             "source_plural_contact",
             "source_wrapped_contact",
             "source_wrapped_plural_contact"
           ]

    assert get_in(request_direction_routing, ["tracking", "capacity_pack_contact_ids"]) == [
             "source_plural_contact",
             "source_wrapped_contact",
             "source_wrapped_plural_contact"
           ]

    assert_in_delta get_in(request_direction_routing, [
                      "tracking",
                      "capacity_pack_required_capacity_fraction"
                    ]),
                    0.7,
                    1.0e-12

    assert %{
             "contract" => "contact_intent.v1",
             "source_report_count" => 8,
             "source_report_row_count" => 8,
             "source_report_paths" => replay_source_paths,
             "capacity_pack_required_contact_count" => 8,
             "contact_ids_by_direction" => %{
               "command" => [
                 "canonical_direct_contact",
                 "canonical_singular_contact",
                 "result_wrapped_contact",
                 "result_wrapped_plural_contact"
               ],
               "downlink" => ["direct_contact"],
               "tracking" => [
                 "source_plural_contact",
                 "source_wrapped_contact",
                 "source_wrapped_plural_contact"
               ]
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => replay_trust_boundaries,
             "branch_local_contact_intent_pressure" => true,
             "branch_local_station_feedback_pressure" => true,
             "branch_local_capacity_pack_pressure" => true,
             "assumptions" => %{
               "contact_generation" => "not_performed_by_summary",
               "contact_allocation" => "not_performed_by_summary",
               "candidate_selection" => "not_performed_by_summary",
               "cadence_write" => "not_performed_by_summary"
             }
           } = replay_summary = CandidateRefresh.contact_intent_replay_summary(candidate_source)

    assert_in_delta replay_summary["capacity_pack_required_capacity_fraction"], 1.6, 1.0e-12

    replay_capacity_by_direction =
      replay_summary["capacity_pack_required_capacity_fraction_by_direction"]

    assert_in_delta replay_capacity_by_direction["command"], 0.65, 1.0e-12
    assert_in_delta replay_capacity_by_direction["downlink"], 0.25, 1.0e-12
    assert_in_delta replay_capacity_by_direction["tracking"], 0.7, 1.0e-12

    replay_direction_routing =
      CandidateRefresh.contact_intent_replay_summary(candidate_source)["direction_routing"]

    assert get_in(replay_direction_routing, ["command", "contact_ids"]) == [
             "canonical_direct_contact",
             "canonical_singular_contact",
             "result_wrapped_contact",
             "result_wrapped_plural_contact"
           ]

    assert get_in(replay_direction_routing, ["command", "capacity_pack_contact_ids"]) == [
             "canonical_direct_contact",
             "canonical_singular_contact",
             "result_wrapped_contact",
             "result_wrapped_plural_contact"
           ]

    assert_in_delta get_in(replay_direction_routing, [
                      "command",
                      "capacity_pack_required_capacity_fraction"
                    ]),
                    0.65,
                    1.0e-12

    assert get_in(replay_direction_routing, ["tracking", "contact_ids"]) == [
             "source_plural_contact",
             "source_wrapped_contact",
             "source_wrapped_plural_contact"
           ]

    assert get_in(replay_direction_routing, ["tracking", "capacity_pack_contact_ids"]) == [
             "source_plural_contact",
             "source_wrapped_contact",
             "source_wrapped_plural_contact"
           ]

    assert_in_delta get_in(replay_direction_routing, [
                      "tracking",
                      "capacity_pack_required_capacity_fraction"
                    ]),
                    0.7,
                    1.0e-12

    assert Enum.sort(replay_source_paths) == [
             "mission_state.contact_intent",
             "mission_state.contact_intents",
             "mission_state.result_artifact.contact_intents[0]",
             "mission_state.result_artifact.source_contact_intent",
             "mission_state.source_contact_intent",
             "mission_state.source_contact_intents",
             "mission_state.source_result_artifact.contact_intent",
             "mission_state.source_result_artifact.source_contact_intents[0]"
           ]

    assert Enum.sort(replay_trust_boundaries) == [
             "canonical_direct_contact_intent_boundary",
             "canonical_singular_contact_intent_boundary",
             "direct_contact_intent_boundary",
             "result_wrapped_contact_intent_boundary",
             "source_plural_contact_intent_boundary",
             "source_wrapped_contact_intent_boundary"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp assert_contact_intent_pressure_score_terms(branch, artifact) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    contact_intent_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &(&1["type"] == "downlink_completion_gap" and &1["feedback_scope"] == "contact_intent")
      )

    assert contact_intent_pressure_count > 0

    assert branch["score_terms"]["contact_intent_pressure_penalty"] ==
             -contact_intent_pressure_count * risk_weight

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) - contact_intent_pressure_count) * risk_weight

    assert "contact_intent_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "contact_intent_pressure_penalty" and &1["value"] < 0.0)
           )
  end
end
