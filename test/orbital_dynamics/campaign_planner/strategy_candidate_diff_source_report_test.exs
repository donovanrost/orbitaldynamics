Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyCandidateDiffSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CandidateRefresh
  alias OrbitalDynamics.Schema

  test "strategy carries mission-state candidate-diff reports into branch refresh requests" do
    direct_report = %{
      "schema_contract" => "candidate_diff_report.v1",
      "retained_candidates" => [
        %{
          "id" => "direct_retained_candidate",
          "ground_station_id" => "equator_prime",
          "diff_reason" => "present_in_prior_candidate_set_with_semantic_changes",
          "semantic_change_reasons" => ["contact_window_shifted"],
          "candidate_diff_changed_fields" => ["starts_at_s"],
          "trust_boundary" => "direct_retained_candidate_boundary"
        }
      ],
      "new_candidates" => [
        %{
          "id" => "direct_new_candidate",
          "source_window" => %{"ground_station_id" => "dss_43"},
          "diff_reason" => "not_present_in_prior_candidate_set",
          "trust_boundary" => "direct_new_candidate_boundary"
        }
      ],
      "invalidated_candidates" => [],
      "provenance" => %{"trust_boundary" => "direct_candidate_diff_report_boundary"}
    }

    canonical_report = %{
      "schema_contract" => "candidate_diff_report.v1",
      "retained_candidates" => [],
      "new_candidates" => [],
      "invalidated_candidates" => [
        %{
          "id" => "canonical_invalidated_candidate",
          "ground_station_id" => "dss_14",
          "invalidated_reason" => "not_present_in_refreshed_candidate_set",
          "semantic_change_reasons" => ["link_margin_changed"],
          "candidate_diff_changed_fields" => ["link_margin_s"],
          "trust_boundary" => "canonical_invalidated_candidate_boundary"
        }
      ],
      "provenance" => %{"trust_boundary" => "canonical_candidate_diff_report_boundary"}
    }

    source_wrapped_report = %{
      "schema_contract" => "candidate_diff_report.v1",
      "retained_candidates" => [],
      "new_candidates" => [],
      "invalidated_candidates" => [
        %{
          "id" => "source_wrapped_invalidated_candidate",
          "source_window" => %{"ground_station_id" => "polar_prime"},
          "invalidated_reason" => "not_present_in_refreshed_candidate_set",
          "semantic_change_reasons" => ["station_reservation_changed"],
          "candidate_diff_changed_fields" => ["station_reservation_status"],
          "trust_boundary" => "source_wrapped_invalidated_candidate_boundary"
        }
      ],
      "provenance" => %{"trust_boundary" => "source_wrapped_candidate_diff_fixture"}
    }

    result_wrapped_report = %{
      "schema_contract" => "candidate_diff_report.v1",
      "retained_candidates" => [
        %{
          "id" => "result_wrapped_retained_candidate",
          "ground_station_id" => "polar_prime",
          "diff_reason" => "present_in_prior_candidate_set_with_semantic_changes",
          "semantic_change_reasons" => ["priority_changed"],
          "candidate_diff_changed_fields" => ["priority"],
          "trust_boundary" => "result_wrapped_retained_candidate_boundary"
        }
      ],
      "new_candidates" => [],
      "invalidated_candidates" => [],
      "provenance" => %{"trust_boundary" => "result_wrapped_candidate_diff_fixture"}
    }

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_candidate_diff_report", direct_report)
      |> Map.put("candidate_diff_report", canonical_report)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "candidate_diff_report" => Map.delete(source_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "source_wrapped_candidate_diff_boundary"}
      })
      |> Map.put(:result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_candidate_diff_report" => Map.delete(result_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "result_wrapped_candidate_diff_boundary"}
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
          "mission_state.source_candidate_diff_report",
          "mission_state.candidate_diff_report",
          "mission_state.source_result_artifact.candidate_diff_report",
          "mission_state.result_artifact.source_candidate_diff_report"
        ] do
      assert source_path in candidate_source["source_report_input_paths"]

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 5,
             "source_report_candidate_diff_retained_candidate_count" => 2,
             "source_report_candidate_diff_new_candidate_count" => 1,
             "source_report_candidate_diff_invalidated_candidate_count" => 2,
             "source_report_candidate_diff_diff_reason_counts" => %{
               "not_present_in_prior_candidate_set" => 1,
               "present_in_prior_candidate_set_with_semantic_changes" => 2
             },
             "source_report_candidate_diff_invalidated_reason_counts" => %{
               "not_present_in_refreshed_candidate_set" => 2
             },
             "source_report_candidate_diff_semantic_change_reason_counts" => %{
               "contact_window_shifted" => 1,
               "link_margin_changed" => 1,
               "priority_changed" => 1,
               "station_reservation_changed" => 1
             },
             "source_report_candidate_diff_changed_field_counts" => %{
               "link_margin_s" => 1,
               "priority" => 1,
               "starts_at_s" => 1,
               "station_reservation_status" => 1
             },
             "source_report_candidate_diff_candidate_id_counts" => %{
               "canonical_invalidated_candidate" => 1,
               "direct_new_candidate" => 1,
               "direct_retained_candidate" => 1,
               "result_wrapped_retained_candidate" => 1,
               "source_wrapped_invalidated_candidate" => 1
             },
             "source_report_candidate_diff_ground_station_counts" => %{
               "dss_43" => 1,
               "dss_14" => 1,
               "equator_prime" => 1,
               "polar_prime" => 2
             }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "contract" => "candidate_diff_report.v1",
             "source_report_count" => 4,
             "source_report_row_count" => 5,
             "source_report_paths" => replay_source_paths,
             "retained_candidate_count" => 2,
             "new_candidate_count" => 1,
             "invalidated_candidate_count" => 2,
             "diff_reason_counts" => %{
               "not_present_in_prior_candidate_set" => 1,
               "present_in_prior_candidate_set_with_semantic_changes" => 2
             },
             "invalidated_reason_counts" => %{
               "not_present_in_refreshed_candidate_set" => 2
             },
             "semantic_change_reason_counts" => %{
               "contact_window_shifted" => 1,
               "link_margin_changed" => 1,
               "priority_changed" => 1,
               "station_reservation_changed" => 1
             },
             "candidate_diff_changed_field_counts" => %{
               "link_margin_s" => 1,
               "priority" => 1,
               "starts_at_s" => 1,
               "station_reservation_status" => 1
             },
             "candidate_diff_candidate_id_counts" => %{
               "canonical_invalidated_candidate" => 1,
               "direct_new_candidate" => 1,
               "direct_retained_candidate" => 1,
               "result_wrapped_retained_candidate" => 1,
               "source_wrapped_invalidated_candidate" => 1
             },
             "candidate_diff_ground_station_counts" => %{
               "dss_43" => 1,
               "dss_14" => 1,
               "equator_prime" => 1,
               "polar_prime" => 2
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "canonical_candidate_diff_report_boundary",
               "canonical_invalidated_candidate_boundary",
               "direct_candidate_diff_report_boundary",
               "direct_new_candidate_boundary",
               "direct_retained_candidate_boundary",
               "result_wrapped_candidate_diff_boundary",
               "result_wrapped_retained_candidate_boundary",
               "source_wrapped_candidate_diff_boundary",
               "source_wrapped_invalidated_candidate_boundary"
             ],
             "branch_local_diff_pressure" => true,
             "branch_local_new_candidate_pressure" => true,
             "branch_local_invalidated_candidate_pressure" => true,
             "branch_local_semantic_change_pressure" => true
           } = CandidateRefresh.candidate_diff_replay_summary(candidate_source)

    assert Enum.sort(replay_source_paths) == [
             "mission_state.candidate_diff_report",
             "mission_state.result_artifact.source_candidate_diff_report",
             "mission_state.source_candidate_diff_report",
             "mission_state.source_result_artifact.candidate_diff_report"
           ]

    candidate_diff_pressure_risks =
      Enum.filter(
        urgent["risk_indicators"],
        &(&1["type"] == "candidate_diff_pressure" and
            &1["feedback_source"] == "candidate_source.candidate_diff_replay_summary")
      )

    assert length(candidate_diff_pressure_risks) == 1

    candidate_diff_pressure_risk = List.first(candidate_diff_pressure_risks)

    assert candidate_diff_pressure_risk["contract"] == "candidate_diff_report.v1"
    assert candidate_diff_pressure_risk["source_report_count"] == 4
    assert candidate_diff_pressure_risk["source_report_row_count"] == 5
    assert candidate_diff_pressure_risk["retained_candidate_count"] == 2
    assert candidate_diff_pressure_risk["new_candidate_count"] == 1
    assert candidate_diff_pressure_risk["invalidated_candidate_count"] == 2

    assert Enum.sort(candidate_diff_pressure_risk["source_report_paths"]) == [
             "mission_state.candidate_diff_report",
             "mission_state.result_artifact.source_candidate_diff_report",
             "mission_state.source_candidate_diff_report",
             "mission_state.source_result_artifact.candidate_diff_report"
           ]

    assert candidate_diff_pressure_risk["diff_reason_counts"] == %{
             "not_present_in_prior_candidate_set" => 1,
             "present_in_prior_candidate_set_with_semantic_changes" => 2
           }

    assert candidate_diff_pressure_risk["invalidated_reason_counts"] == %{
             "not_present_in_refreshed_candidate_set" => 2
           }

    assert candidate_diff_pressure_risk["semantic_change_reason_counts"] == %{
             "contact_window_shifted" => 1,
             "link_margin_changed" => 1,
             "priority_changed" => 1,
             "station_reservation_changed" => 1
           }

    assert candidate_diff_pressure_risk["candidate_diff_changed_field_counts"] == %{
             "link_margin_s" => 1,
             "priority" => 1,
             "starts_at_s" => 1,
             "station_reservation_status" => 1
           }

    assert candidate_diff_pressure_risk["candidate_diff_candidate_id_counts"] == %{
             "canonical_invalidated_candidate" => 1,
             "direct_new_candidate" => 1,
             "direct_retained_candidate" => 1,
             "result_wrapped_retained_candidate" => 1,
             "source_wrapped_invalidated_candidate" => 1
           }

    assert candidate_diff_pressure_risk["candidate_diff_ground_station_counts"] == %{
             "dss_43" => 1,
             "dss_14" => 1,
             "equator_prime" => 1,
             "polar_prime" => 2
           }

    assert candidate_diff_pressure_risk["assumptions"]["candidate_selection"] ==
             "not_performed_by_summary"

    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    assert urgent["score_terms"]["candidate_diff_pressure_penalty"] ==
             -length(candidate_diff_pressure_risks) * risk_weight

    assert "candidate_diff_pressure_penalty" in artifact["score_term_report"]["score_term_keys"]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == "urgent" and
                 &1["term_key"] == "candidate_diff_pressure_penalty" and &1["value"] < 0.0)
           )

    urgent_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "urgent"))

    assert "candidate_diff_pressure" in urgent_row["risk_types"]

    assert urgent_row["branch_candidate_diff_source_report_paths"] == [
             "mission_state.candidate_diff_report",
             "mission_state.result_artifact.source_candidate_diff_report",
             "mission_state.source_candidate_diff_report",
             "mission_state.source_result_artifact.candidate_diff_report"
           ]

    assert urgent_row["branch_candidate_diff_reasons"] == [
             "not_present_in_prior_candidate_set",
             "present_in_prior_candidate_set_with_semantic_changes"
           ]

    assert urgent_row["branch_candidate_diff_invalidated_reasons"] == [
             "not_present_in_refreshed_candidate_set"
           ]

    assert urgent_row["branch_candidate_diff_semantic_change_reasons"] == [
             "contact_window_shifted",
             "link_margin_changed",
             "priority_changed",
             "station_reservation_changed"
           ]

    assert urgent_row["branch_candidate_diff_changed_fields"] == [
             "link_margin_s",
             "priority",
             "starts_at_s",
             "station_reservation_status"
           ]

    assert urgent_row["branch_candidate_diff_candidate_ids"] == [
             "canonical_invalidated_candidate",
             "direct_new_candidate",
             "direct_retained_candidate",
             "result_wrapped_retained_candidate",
             "source_wrapped_invalidated_candidate"
           ]

    assert urgent_row["branch_candidate_diff_ground_station_ids"] == [
             "dss_14",
             "dss_43",
             "equator_prime",
             "polar_prime"
           ]

    assert urgent_row["branch_candidate_diff_trust_boundaries"] == [
             "canonical_candidate_diff_report_boundary",
             "canonical_invalidated_candidate_boundary",
             "direct_candidate_diff_report_boundary",
             "direct_new_candidate_boundary",
             "direct_retained_candidate_boundary",
             "result_wrapped_candidate_diff_boundary",
             "result_wrapped_retained_candidate_boundary",
             "source_wrapped_candidate_diff_boundary",
             "source_wrapped_invalidated_candidate_boundary"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy strategic additions preserve candidate-diff semantic context" do
    refreshed_observation =
      "obs_semantic"
      |> observe("leo_1", "target_a", 200.0, 260.0, 20.0)
      |> Map.merge(%{
        "source_window_id" => "window:leo_1:target_visibility:target_a:2",
        "source_window" => %{
          "id" => "window:leo_1:target_visibility:target_a:2",
          "type" => "target_visibility"
        },
        "score_terms" => %{"target_value" => 20.0}
      })

    refreshed_downlink = refreshed_downlink("dl_semantic", 320.0, 380.0)

    candidate_diff_report = %{
      "schema_contract" => "candidate_diff_report.v1",
      "model" => "candidate_id_set_diff_with_semantic_change_reasons",
      "prior_candidate_count" => 2,
      "refreshed_candidate_count" => 2,
      "retained_candidate_count" => 0,
      "new_candidate_count" => 2,
      "invalidated_candidate_count" => 2,
      "retained_candidates" => [],
      "new_candidates" => [
        %{
          "id" => "obs_semantic",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "starts_at_s" => 200.0,
          "ends_at_s" => 260.0,
          "diff_reason" => "semantically_similar_prior_candidate_changed",
          "matched_prior_candidate_id" => "obs_old",
          "semantic_change_reasons" => ["source_window_id_changed"]
        },
        %{
          "id" => "dl_semantic",
          "type" => "downlink",
          "scenario_id" => "leo_1",
          "starts_at_s" => 320.0,
          "ends_at_s" => 380.0,
          "diff_reason" => "semantically_similar_prior_candidate_changed",
          "matched_prior_candidate_id" => "dl_old",
          "semantic_change_reasons" => ["starts_at_s_changed"]
        }
      ],
      "invalidated_candidates" => [
        %{
          "id" => "obs_old",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "starts_at_s" => 100.0,
          "ends_at_s" => 160.0,
          "invalidated_reason" => "replaced_by_semantically_similar_candidate",
          "replacement_candidate_id" => "obs_semantic",
          "candidate_budget_match_status" => "budget_dropped_replacement_candidate",
          "candidate_budget_match_count" => 1,
          "budget_dropped_candidate_ids" => ["obs_semantic"],
          "semantic_change_reasons" => ["source_window_id_changed"]
        },
        %{
          "id" => "dl_old",
          "type" => "downlink",
          "scenario_id" => "leo_1",
          "collection_id" => "collection_alpha",
          "product_ids" => ["image_l0", "image_l1"],
          "payload_id" => "camera_a",
          "instrument_id" => "imager",
          "target_id" => "target_a",
          "source_activity_ids" => ["obs_semantic"],
          "objective_id" => "latency:collection_alpha",
          "objective_type" => "collection_latency",
          "latency_objective" => true,
          "max_latency_s" => 900.0,
          "planned_latency_s" => 540.0,
          "required_downlink_mb" => 300.0,
          "candidate_downlink_mb" => 360.0,
          "downlink_completion_ratio" => 1.0,
          "downlink_requirement_status" => "satisfied",
          "downlink_completion_source" =>
            "candidate_refresh.downlink_demand.objectives_and_operational_feedback",
          "downlink_completion_sources" => [
            "candidate_refresh.objectives.collection_latency",
            "operational_feedback.downlink_demand_mb.station"
          ],
          "starts_at_s" => 100.0,
          "ends_at_s" => 160.0,
          "invalidated_reason" => "replaced_by_semantically_similar_candidate",
          "replacement_candidate_id" => "dl_semantic",
          "candidate_budget_match_status" => "budget_dropped_replacement_candidate",
          "candidate_budget_match_count" => 1,
          "budget_dropped_candidate_ids" => ["dl_semantic"],
          "semantic_change_reasons" => ["starts_at_s_changed"]
        }
      ]
    }

    artifact =
      strategy(base_plan(%{}),
        mission_state:
          mission_state([%{"type" => "downlink_completion", "required_contacts" => 1}]),
        candidate_refresh:
          candidate_refresh_artifact([refreshed_observation, refreshed_downlink],
            candidate_diff_report: candidate_diff_report,
            freshness_report: freshness_report("current")
          ),
        branches: [
          %{id: "baseline"},
          %{
            id: "semantic_additions",
            events: [
              %{type: "urgent_target", target_id: "target_a", priority: 12.0},
              %{type: "downlink_completion_gap", required_contacts: 1}
            ]
          }
        ],
        current_epoch_s: 0.0
      )

    semantic_additions =
      branch(artifact, "semantic_additions")["candidate_plan"]["strategic_additions"]

    observe_addition = Enum.find(semantic_additions, &(&1["type"] == "observe"))
    downlink_addition = Enum.find(semantic_additions, &(&1["type"] == "downlink"))

    assert %{
             "invalidated_candidate_id" => "obs_old",
             "replacement_candidate_id" => "obs_semantic",
             "invalidated_reason" => "replaced_by_semantically_similar_candidate",
             "candidate_budget_match_status" => "budget_dropped_replacement_candidate",
             "candidate_budget_match_count" => 1,
             "budget_dropped_candidate_ids" => ["obs_semantic"],
             "semantic_change_reasons" => ["source_window_id_changed"]
           } = observe_addition["repair"]["candidate_diff"]

    assert observe_addition["feasibility"]["candidate_diff"] ==
             observe_addition["repair"]["candidate_diff"]

    assert %{
             "invalidated_candidate_id" => "dl_old",
             "replacement_candidate_id" => "dl_semantic",
             "invalidated_reason" => "replaced_by_semantically_similar_candidate",
             "candidate_budget_match_status" => "budget_dropped_replacement_candidate",
             "candidate_budget_match_count" => 1,
             "budget_dropped_candidate_ids" => ["dl_semantic"],
             "semantic_change_reasons" => ["starts_at_s_changed"],
             "collection_id" => "collection_alpha",
             "product_ids" => ["image_l0", "image_l1"],
             "payload_id" => "camera_a",
             "instrument_id" => "imager",
             "target_id" => "target_a",
             "source_activity_ids" => ["obs_semantic"],
             "objective_id" => "latency:collection_alpha",
             "objective_type" => "collection_latency",
             "latency_objective" => true,
             "max_latency_s" => 900.0,
             "planned_latency_s" => 540.0,
             "required_downlink_mb" => 300.0,
             "candidate_downlink_mb" => 360.0,
             "downlink_completion_ratio" => 1.0,
             "downlink_requirement_status" => "satisfied",
             "downlink_completion_source" =>
               "candidate_refresh.downlink_demand.objectives_and_operational_feedback",
             "downlink_completion_sources" => [
               "candidate_refresh.objectives.collection_latency",
               "operational_feedback.downlink_demand_mb.station"
             ]
           } = downlink_addition["feasibility"]["candidate_diff"]

    assert downlink_addition["repair"]["candidate_diff"] ==
             downlink_addition["feasibility"]["candidate_diff"]

    assert Enum.any?(
             branch(artifact, "semantic_additions")["approval_requirements"],
             &(Map.get(&1, "candidate_diff") == downlink_addition["repair"]["candidate_diff"])
           )

    assert Enum.any?(
             get_in(artifact, ["recommendation", "requires_approval"]),
             &(Map.get(&1, "candidate_diff") == observe_addition["repair"]["candidate_diff"])
           )

    assert Enum.any?(
             get_in(artifact, ["recommendation", "explanation"]),
             &(&1["type"] == "strategic_addition" and
                 Map.get(&1, "candidate_diff") == observe_addition["repair"]["candidate_diff"])
           )

    assert Enum.any?(
             get_in(artifact, ["operator_review_package", "rows"]),
             &(&1["review_type"] == "approval_requirement" and
                 Map.get(&1, "candidate_diff") == observe_addition["repair"]["candidate_diff"])
           )

    assert %{
             "candidate_budget_match_status" => "budget_dropped_replacement_candidate",
             "candidate_budget_match_count" => 1,
             "budget_dropped_candidate_ids" => ["obs_semantic"]
           } =
             Enum.find(
               get_in(artifact, ["cadence_import_manifest", "rows"]),
               &(&1["source_review_type"] == "approval_requirement" and
                   Map.get(&1, "candidate_diff") == observe_addition["repair"]["candidate_diff"])
             )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp candidate_refresh_artifact(candidates, opts) do
    %{
      "schema_version" => 1,
      "schema_contract" => "candidate_refresh.v1",
      "artifact_type" => "candidate_refresh",
      "generated_at" => "2026-05-14T00:00:00Z",
      "planner" => "OrbitalDynamics.CandidateRefresh.V1",
      "refresh_id" => Keyword.get(opts, :refresh_id, "candidate_refresh:test:abc"),
      "study_id" => "candidate_refresh_test",
      "snapshot_id" => "ops-state-1",
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 1_000.0,
        "output_step_s" => 60.0
      },
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-1",
        "spacecraft_state_count" => 1
      },
      "refreshed_windows" => %{
        "access_windows" => [],
        "target_visibility_windows" => [],
        "eclipse_intervals" => []
      },
      "candidate_activities" => candidates,
      "contact_intents" => Keyword.get(opts, :contact_intents, []),
      "resource_summaries" => Keyword.get(opts, :resource_summaries, []),
      "contact_filter_report" => Keyword.get(opts, :contact_filter_report),
      "contact_allocation_report" => Keyword.get(opts, :contact_allocation_report),
      "resource_filter_report" => Keyword.get(opts, :resource_filter_report),
      "refresh_budget_report" => Keyword.get(opts, :refresh_budget_report),
      "candidate_diff_report" => Keyword.get(opts, :candidate_diff_report),
      "freshness_report" => Keyword.get(opts, :freshness_report),
      "invalidated_candidates" => [],
      "validation_records" => [],
      "warnings" => [],
      "assumptions" => %{},
      "provenance" => %{},
      "source_window_lineage" =>
        Enum.map(candidates, fn candidate ->
          %{
            "candidate_activity_id" => candidate["id"],
            "source_window_id" => candidate["source_window_id"],
            "source_window_type" => get_in(candidate, ["source_window", "type"]),
            "scenario_id" => candidate["scenario_id"]
          }
        end)
    }
  end

  defp freshness_report(status) do
    stale_reasons =
      if status == "stale",
        do: ["accepted_snapshot_older_than_policy"],
        else: []

    %{
      "schema_contract" => "freshness_report.v1",
      "model" => "accepted_snapshot_horizon_and_quality_freshness",
      "generated_at" => "2026-05-14T00:00:00Z",
      "accepted_at" => "2026-05-13T23:00:00Z",
      "current_epoch_s" => 165.0,
      "horizon_starts_at_s" => 165.0,
      "accepted_snapshot_age_s" => 3600.0,
      "horizon_start_offset_s" => 0.0,
      "max_snapshot_age_s" => 60.0,
      "max_horizon_start_offset_s" => 1.0,
      "status" => status,
      "stale_reasons" => stale_reasons,
      "unknown_reasons" => []
    }
  end
end
