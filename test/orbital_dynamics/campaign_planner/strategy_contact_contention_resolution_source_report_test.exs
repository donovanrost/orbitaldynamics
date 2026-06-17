Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyContactContentionResolutionSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CandidateRefresh
  alias OrbitalDynamics.Schema

  test "strategy carries mission-state contact-contention resolution summaries into branch refresh requests" do
    resolution_summary = fn prefix, required_fraction ->
      group_id = "#{prefix}_contention_group"
      selected_contact_id = "#{prefix}_selected_contact"
      deferred_contact_id = "#{prefix}_deferred_contact"

      %{
        "schema_contract" => "contact_contention_resolution_summary.v1",
        "model" => "artifact_only_contact_contention_resolution_summary",
        "source_artifact_type" => "contact_contention_resolution_report.v1",
        "policy" => %{"selection_rule" => "highest_score_earliest_start"},
        "conflict_group_count" => 1,
        "recommendation_count" => 1,
        "recommendation_group_ids" => [group_id],
        "review_group_ids" => [group_id],
        "selected_contact_ids" => [selected_contact_id],
        "selected_contact_ids_by_group_id" => %{group_id => [selected_contact_id]},
        "deferred_contact_ids" => [deferred_contact_id],
        "deferred_contact_ids_by_group_id" => %{group_id => [deferred_contact_id]},
        "ambiguous_group_ids" => [],
        "ambiguous_duplicate_contact_ids" => [],
        "ambiguous_duplicate_contact_ids_by_group_id" => %{},
        "review_contact_ids" => [deferred_contact_id, selected_contact_id],
        "review_contact_ids_by_group_id" => %{
          group_id => [deferred_contact_id, selected_contact_id]
        },
        "review_recommendation_count" => 1,
        "resource_scope_counts" => %{"ground_station" => 1},
        "selected_contact_ids_by_resource_scope" => %{
          "ground_station" => [selected_contact_id]
        },
        "deferred_contact_ids_by_resource_scope" => %{
          "ground_station" => [deferred_contact_id]
        },
        "review_contact_ids_by_resource_scope" => %{
          "ground_station" => [deferred_contact_id, selected_contact_id]
        },
        "selection_reason_counts" => %{"highest_score_earliest_start" => 1},
        "selected_contact_ids_by_selection_reason" => %{
          "highest_score_earliest_start" => [selected_contact_id]
        },
        "action_counts" => %{"recommend_preferred_contact_for_operator_review" => 1},
        "review_contact_ids_by_action" => %{
          "recommend_preferred_contact_for_operator_review" => [
            deferred_contact_id,
            selected_contact_id
          ]
        },
        "capacity_pack_required_capacity_fraction" => required_fraction,
        "capacity_pack_selected_required_capacity_fraction" => required_fraction / 2,
        "capacity_pack_deferred_required_capacity_fraction" => required_fraction / 2,
        "capacity_pack_required_capacity_fraction_by_status" => %{
          "deferred" => required_fraction / 2,
          "selected" => required_fraction / 2
        },
        "capacity_pack_required_capacity_fraction_by_ground_station_id" => %{
          "equator_prime" => required_fraction
        },
        "capacity_pack_selected_required_capacity_fraction_by_ground_station_id" => %{
          "equator_prime" => required_fraction / 2
        },
        "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id" => %{
          "equator_prime" => required_fraction / 2
        },
        "required_capacity_fraction_source_counts" => %{
          "source_contact_candidate.required_capacity_fraction" => 2
        },
        "required_capacity_fraction_contact_ids_by_source" => %{
          "source_contact_candidate.required_capacity_fraction" => [
            deferred_contact_id,
            selected_contact_id
          ]
        },
        "assumptions" => %{
          "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
          "candidate_mutation" => "none",
          "operator_authority" => "not_granted_by_summary",
          "source" => "contact_contention_resolution_report.v1"
        },
        "provenance" => %{
          "trust_boundary" => "#{prefix}_contact_contention_resolution_summary_boundary"
        }
      }
    end

    direct_summary = resolution_summary.("direct", 0.55)
    canonical_summary = resolution_summary.("canonical", 0.65)
    wrapped_summary = resolution_summary.("wrapped", 0.45)

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_contact_contention_resolution_summary", direct_summary)
      |> Map.put("contact_contention_resolution_summary", canonical_summary)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "contact_contention_resolution_summary" => Map.delete(wrapped_summary, "provenance"),
        "provenance" => %{"trust_boundary" => "wrapped_contact_contention_resolution_boundary"}
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
          "mission_state.source_contact_contention_resolution_summary",
          "mission_state.contact_contention_resolution_summary",
          "mission_state.source_result_artifact.contact_contention_resolution_summary"
        ] do
      assert source_path in source_report_input_paths

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    request_summary = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "source_report_count" => 3,
             "source_report_row_count" => 3,
             "source_report_contact_contention_resolution_recommendation_count" => 3,
             "source_report_contact_contention_resolution_conflict_group_count" => 3,
             "source_report_contact_contention_resolution_review_recommendation_count" => 3,
             "source_report_contact_contention_resolution_source_summary_model_counts" => %{
               "artifact_only_contact_contention_resolution_summary" => 3
             },
             "source_report_contact_contention_resolution_source_summary_schema_contract_counts" =>
               %{"contact_contention_resolution_summary.v1" => 3},
             "source_report_contact_contention_resolution_selected_contact_ids" => [
               "canonical_selected_contact",
               "direct_selected_contact",
               "wrapped_selected_contact"
             ],
             "source_report_contact_contention_resolution_deferred_contact_ids" => [
               "canonical_deferred_contact",
               "direct_deferred_contact",
               "wrapped_deferred_contact"
             ],
             "source_report_contact_contention_resolution_review_contact_ids" => [
               "canonical_deferred_contact",
               "canonical_selected_contact",
               "direct_deferred_contact",
               "direct_selected_contact",
               "wrapped_deferred_contact",
               "wrapped_selected_contact"
             ],
             "source_report_contact_contention_resolution_resource_scope_counts" => %{
               "ground_station" => 3
             },
             "source_report_contact_contention_resolution_selection_reason_counts" => %{
               "highest_score_earliest_start" => 3
             },
             "source_report_contact_contention_resolution_required_operator_action_counts" => %{
               "recommend_preferred_contact_for_operator_review" => 3
             }
           } = request_summary

    assert_in_delta request_summary[
                      "source_report_contact_contention_capacity_pack_required_capacity_fraction"
                    ],
                    1.65,
                    1.0e-9

    assert_in_delta request_summary[
                      "source_report_contact_contention_capacity_pack_selected_required_capacity_fraction"
                    ],
                    0.825,
                    1.0e-9

    assert_in_delta request_summary[
                      "source_report_contact_contention_capacity_pack_deferred_required_capacity_fraction"
                    ],
                    0.825,
                    1.0e-9

    assert_in_delta request_summary[
                      "source_report_contact_contention_capacity_pack_required_capacity_fraction_by_ground_station"
                    ]["equator_prime"],
                    1.65,
                    1.0e-9

    assert_in_delta request_summary[
                      "source_report_contact_contention_capacity_pack_required_capacity_fraction_by_status"
                    ]["deferred"],
                    0.825,
                    1.0e-9

    assert_in_delta request_summary[
                      "source_report_contact_contention_capacity_pack_required_capacity_fraction_by_status"
                    ]["selected"],
                    0.825,
                    1.0e-9

    assert %{
             "contract" => "contact_contention_resolution_summary.v1",
             "source_report_count" => 3,
             "source_report_row_count" => 3,
             "source_report_paths" => replay_source_paths,
             "source_summary_model_counts" => %{
               "artifact_only_contact_contention_resolution_summary" => 3
             },
             "source_summary_schema_contract_counts" => %{
               "contact_contention_resolution_summary.v1" => 3
             },
             "conflict_group_count" => 3,
             "recommendation_count" => 3,
             "review_recommendation_count" => 3,
             "deferred_contact_count" => 3,
             "recommendation_group_ids" => [
               "canonical_contention_group",
               "direct_contention_group",
               "wrapped_contention_group"
             ],
             "review_group_ids" => [
               "canonical_contention_group",
               "direct_contention_group",
               "wrapped_contention_group"
             ],
             "selected_contact_ids" => [
               "canonical_selected_contact",
               "direct_selected_contact",
               "wrapped_selected_contact"
             ],
             "deferred_contact_ids" => [
               "canonical_deferred_contact",
               "direct_deferred_contact",
               "wrapped_deferred_contact"
             ],
             "review_contact_ids" => [
               "canonical_deferred_contact",
               "canonical_selected_contact",
               "direct_deferred_contact",
               "direct_selected_contact",
               "wrapped_deferred_contact",
               "wrapped_selected_contact"
             ],
             "resource_scope_counts" => %{"ground_station" => 3},
             "required_operator_action_counts" => %{
               "recommend_preferred_contact_for_operator_review" => 3
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => replay_trust_boundaries,
             "branch_local_contact_contention_resolution_pressure" => true,
             "branch_local_deferred_contact_pressure" => true,
             "branch_local_capacity_pack_pressure" => true,
             "branch_local_contact_contention_resolution_action_pressure" => true,
             "assumptions" => %{
               "contact_allocation" => "not_performed_by_summary",
               "candidate_selection" => "not_performed_by_summary",
               "candidate_generation" => "not_performed_by_summary",
               "cadence_write" => "not_performed_by_summary"
             }
           } =
             replay_summary =
             CandidateRefresh.contact_contention_resolution_replay_summary(candidate_source)

    assert_in_delta replay_summary["capacity_pack_required_capacity_fraction"], 1.65, 1.0e-9

    assert_in_delta replay_summary["capacity_pack_selected_required_capacity_fraction"],
                    0.825,
                    1.0e-9

    assert_in_delta replay_summary["capacity_pack_deferred_required_capacity_fraction"],
                    0.825,
                    1.0e-9

    assert_in_delta replay_summary["capacity_pack_required_capacity_fraction_by_status"][
                      "deferred"
                    ],
                    0.825,
                    1.0e-9

    assert_in_delta replay_summary["capacity_pack_required_capacity_fraction_by_status"][
                      "selected"
                    ],
                    0.825,
                    1.0e-9

    assert_in_delta replay_summary[
                      "capacity_pack_required_capacity_fraction_by_ground_station"
                    ]["equator_prime"],
                    1.65,
                    1.0e-9

    assert Enum.sort(replay_source_paths) == [
             "mission_state.contact_contention_resolution_summary",
             "mission_state.source_contact_contention_resolution_summary",
             "mission_state.source_result_artifact.contact_contention_resolution_summary"
           ]

    assert Enum.sort(replay_trust_boundaries) == [
             "canonical_contact_contention_resolution_summary_boundary",
             "direct_contact_contention_resolution_summary_boundary",
             "wrapped_contact_contention_resolution_boundary"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy carries mission-state contact-contention resolution reports into branch refresh requests" do
    resolution_report = fn prefix,
                           trust_boundary,
                           selected_direction,
                           deferred_direction,
                           station_id,
                           required_action,
                           selected_fraction,
                           deferred_fraction ->
      %{
        "schema_contract" => "contact_contention_resolution_report.v1",
        "model" => "deterministic_contact_contention_resolution",
        "recommendations" => [
          %{
            "group_id" => "#{prefix}_contention_group",
            "ground_station_id" => station_id,
            "selected_contact_id" => "#{prefix}_selected_contact",
            "deferred_contact_ids" => ["#{prefix}_deferred_contact"],
            "resolution_status" => "deferred",
            "selection_reason" => "highest_score_earliest_start",
            "required_operator_action" => required_action,
            "trust_boundary" => "#{prefix}_resolution_recommendation_boundary",
            "source_contact_candidates" => [
              %{
                "id" => "#{prefix}_selected_contact",
                "direction" => selected_direction,
                "ground_station_id" => station_id,
                "required_capacity_fraction" => selected_fraction
              },
              %{
                "id" => "#{prefix}_deferred_contact",
                "direction" => deferred_direction,
                "ground_station_id" => station_id,
                "required_capacity_fraction" => deferred_fraction
              }
            ]
          }
        ],
        "provenance" => %{"trust_boundary" => trust_boundary}
      }
    end

    direct_report =
      resolution_report.(
        "direct",
        "direct_contact_contention_resolution_report_boundary",
        "downlink",
        "s-band command",
        "equator_prime",
        "review_contact_contention_resolution",
        0.25,
        0.3
      )

    canonical_report =
      resolution_report.(
        "canonical",
        "canonical_contact_contention_resolution_report_boundary",
        "tracking",
        "uplink",
        "canberra_deep",
        "review_contact_contention_resolution",
        0.1,
        0.15
      )

    source_wrapped_report =
      resolution_report.(
        "source_wrapped",
        "source_wrapped_contact_contention_resolution_fixture",
        "uplink",
        "tracking",
        "dss_43",
        "review_capacity_pack_contention_resolution",
        0.2,
        0.25
      )

    result_wrapped_report =
      resolution_report.(
        "result_wrapped",
        "result_wrapped_contact_contention_resolution_fixture",
        "s-band command",
        "Down Link",
        "polar_prime",
        "review_partner_contention_resolution",
        0.3,
        0.35
      )

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_contact_contention_resolution_report", direct_report)
      |> Map.put("contact_contention_resolution_report", canonical_report)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "contact_contention_resolution_report" => Map.delete(source_wrapped_report, "provenance"),
        "provenance" => %{
          "trust_boundary" => "source_wrapped_contact_contention_resolution_boundary"
        }
      })
      |> Map.put(:result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_contact_contention_resolution_report" =>
          Map.delete(result_wrapped_report, "provenance"),
        "provenance" => %{
          "trust_boundary" => "result_wrapped_contact_contention_resolution_boundary"
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

    for source_path <- [
          "mission_state.source_contact_contention_resolution_report",
          "mission_state.contact_contention_resolution_report",
          "mission_state.source_result_artifact.contact_contention_resolution_report",
          "mission_state.result_artifact.source_contact_contention_resolution_report"
        ] do
      assert source_path in candidate_source["source_report_input_paths"]

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_contact_contention_resolution_recommendation_count" => 4,
             "source_report_contact_contention_resolution_deferred_contact_count" => 4,
             "source_report_contact_contention_resolution_status_counts" => %{
               "deferred" => 4
             },
             "source_report_contact_contention_resolution_selection_reason_counts" => %{
               "highest_score_earliest_start" => 4
             },
             "source_report_contact_contention_capacity_pack_required_capacity_fraction" => 1.9,
             "source_report_contact_contention_capacity_pack_selected_required_capacity_fraction" =>
               0.8500000000000001,
             "source_report_contact_contention_capacity_pack_deferred_required_capacity_fraction" =>
               1.0499999999999998,
             "source_report_contact_contention_capacity_pack_required_capacity_fraction_by_ground_station" =>
               %{
                 "canberra_deep" => 0.25,
                 "dss_43" => 0.45,
                 "equator_prime" => 0.55,
                 "polar_prime" => 0.6499999999999999
               },
             "source_report_contact_contention_resolution_direction_counts" => %{
               "command" => 2,
               "downlink" => 2,
               "tracking" => 2,
               "uplink" => 2
             },
             "source_report_contact_contention_resolution_required_operator_action_counts" => %{
               "review_capacity_pack_contention_resolution" => 1,
               "review_contact_contention_resolution" => 2,
               "review_partner_contention_resolution" => 1
             }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "contract" => "contact_contention_resolution_report.v1",
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_paths" => replay_source_paths,
             "recommendation_count" => 4,
             "deferred_contact_count" => 4,
             "resolution_status_counts" => %{"deferred" => 4},
             "selection_reason_counts" => %{"highest_score_earliest_start" => 4},
             "capacity_pack_required_capacity_fraction" => 1.9,
             "capacity_pack_selected_required_capacity_fraction" => 0.8500000000000001,
             "capacity_pack_deferred_required_capacity_fraction" => 1.0499999999999998,
             "capacity_pack_required_capacity_fraction_by_ground_station" => %{
               "canberra_deep" => 0.25,
               "dss_43" => 0.45,
               "equator_prime" => 0.55,
               "polar_prime" => 0.6499999999999999
             },
             "capacity_pack_selected_required_capacity_fraction_by_ground_station" => %{
               "canberra_deep" => 0.1,
               "dss_43" => 0.2,
               "equator_prime" => 0.25,
               "polar_prime" => 0.3
             },
             "capacity_pack_deferred_required_capacity_fraction_by_ground_station" => %{
               "canberra_deep" => 0.15,
               "dss_43" => 0.25,
               "equator_prime" => 0.3,
               "polar_prime" => 0.35
             },
             "selected_contact_ids" => [
               "canonical_selected_contact",
               "direct_selected_contact",
               "result_wrapped_selected_contact",
               "source_wrapped_selected_contact"
             ],
             "deferred_contact_ids" => [
               "canonical_deferred_contact",
               "direct_deferred_contact",
               "result_wrapped_deferred_contact",
               "source_wrapped_deferred_contact"
             ],
             "direction_counts" => %{
               "command" => 2,
               "downlink" => 2,
               "tracking" => 2,
               "uplink" => 2
             },
             "contact_ids_by_direction" => %{
               "command" => [
                 "direct_deferred_contact",
                 "result_wrapped_selected_contact"
               ],
               "downlink" => [
                 "direct_selected_contact",
                 "result_wrapped_deferred_contact"
               ],
               "tracking" => [
                 "canonical_selected_contact",
                 "source_wrapped_deferred_contact"
               ],
               "uplink" => [
                 "canonical_deferred_contact",
                 "source_wrapped_selected_contact"
               ]
             },
             "direction_routing" => %{
               "command" => %{
                 "contact_count" => 2,
                 "contact_ids" => [
                   "direct_deferred_contact",
                   "result_wrapped_selected_contact"
                 ]
               },
               "downlink" => %{
                 "contact_count" => 2,
                 "contact_ids" => [
                   "direct_selected_contact",
                   "result_wrapped_deferred_contact"
                 ]
               },
               "tracking" => %{
                 "contact_count" => 2,
                 "contact_ids" => [
                   "canonical_selected_contact",
                   "source_wrapped_deferred_contact"
                 ]
               },
               "uplink" => %{
                 "contact_count" => 2,
                 "contact_ids" => [
                   "canonical_deferred_contact",
                   "source_wrapped_selected_contact"
                 ]
               }
             },
             "required_operator_action_counts" => %{
               "review_capacity_pack_contention_resolution" => 1,
               "review_contact_contention_resolution" => 2,
               "review_partner_contention_resolution" => 1
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "canonical_contact_contention_resolution_report_boundary",
               "canonical_resolution_recommendation_boundary",
               "direct_contact_contention_resolution_report_boundary",
               "direct_resolution_recommendation_boundary",
               "result_wrapped_contact_contention_resolution_boundary",
               "result_wrapped_resolution_recommendation_boundary",
               "source_wrapped_contact_contention_resolution_boundary",
               "source_wrapped_resolution_recommendation_boundary"
             ],
             "branch_local_contact_contention_resolution_pressure" => true,
             "branch_local_deferred_contact_pressure" => true,
             "branch_local_capacity_pack_pressure" => true,
             "branch_local_contact_contention_resolution_action_pressure" => true
           } = CandidateRefresh.contact_contention_resolution_replay_summary(candidate_source)

    assert Enum.sort(replay_source_paths) == [
             "mission_state.contact_contention_resolution_report",
             "mission_state.result_artifact.source_contact_contention_resolution_report",
             "mission_state.source_contact_contention_resolution_report",
             "mission_state.source_result_artifact.contact_contention_resolution_report"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
