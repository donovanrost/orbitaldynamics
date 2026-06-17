defmodule OrbitalDynamics.CandidateRefresh.BuildIdentityTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CandidateRefresh, Epoch, ResultSet, Schema}

  test "generated candidate and source-window IDs are stable across event ordering" do
    refresh =
      refresh_request()
      |> put_in(["constraints", "avoid_eclipse"], false)

    left =
      ordered_event_result_set(:canonical)
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    right =
      ordered_event_result_set(:reversed)
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert left == right

    assert Enum.map(left["candidate_activities"], &{&1["id"], &1["starts_at_s"]}) == [
             {"leo_1_observe_target_a_1", 120.0},
             {"leo_1_observe_target_a_2", 260.0},
             {"leo_1_downlink_equator_prime_1", 300.0},
             {"leo_1_downlink_equator_prime_2", 430.0}
           ]

    assert Enum.map(left["refreshed_windows"]["target_visibility_windows"], & &1["id"]) == [
             "window:leo_1:target_visibility:target_a:1",
             "window:leo_1:target_visibility:target_a:2"
           ]

    assert Enum.map(left["refreshed_windows"]["access_windows"], & &1["id"]) == [
             "window:leo_1:ground_station_access:equator_prime:1",
             "window:leo_1:ground_station_access:equator_prime:2"
           ]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(left)
  end

  test "classifies refreshed contact intents with the refresh approval policy" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("approval_policy", %{"policy_bundle_id" => "command_contact_authority_v1"}),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [
             %{
               "schema_contract" => "contact_intent.v1",
               "activity_id" => "leo_1_downlink_equator_prime_1",
               "direction" => "downlink",
               "approval_status" => "operator_review_required",
               "approval_requirements" => [
                 %{
                   "action" => "review_contact_intent",
                   "requirement_type" => "contact_schedule_change"
                 }
               ],
               "approval_rule_matches" => [
                 %{
                   "rule_id" => "downlink_schedule_authority_review",
                   "required_authority" => "contact_schedule_authority"
                 }
               ],
               "policy_decision" => %{
                 "schema_contract" => "policy_decision.v1",
                 "policy_bundle_id" => "command_contact_authority_v1",
                 "classification" => "operator_review_required"
               }
             }
           ] = artifact["contact_intents"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "refresh id changes when material refresh inputs change" do
    base =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh_request(),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    with_feedback =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> put_in(["operational_feedback"], %{
            "contact_success_rate" => %{"equator_prime" => 0.5}
          }),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    with_ground_network =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> put_in(["ground_network"], [
            %{
              "ground_station_id" => "equator_prime",
              "capacity_fraction" => 0.5
            }
          ]),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    with_resource_policy =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> put_in(["resource_filter_policy"], %{"min_downlink_margin" => 0.25}),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    with_candidate_limit =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> put_in(["candidate_limit_policy"], %{"max_candidate_activities" => 1}),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    refresh_ids =
      [base, with_feedback, with_ground_network, with_resource_policy, with_candidate_limit]
      |> Enum.map(& &1["refresh_id"])

    assert Enum.all?(refresh_ids, &String.starts_with?(&1, "candidate_refresh:"))
    assert length(Enum.uniq(refresh_ids)) == 5

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(with_feedback)
  end

  defp result_set do
    ResultSet.new!(%{
      study_id: :candidate_refresh_demo,
      trajectory_results: [],
      event_results: [
        %{
          scenario_id: :leo_1,
          event_type: :target_visibility,
          events: [
            %{
              type: :target_visibility,
              starts_at: Epoch.new!(120.0, :tdb),
              ends_at: Epoch.new!(240.0, :tdb),
              metadata: %{
                target_id: :target_a,
                target_priority: 1.0,
                max_elevation_deg: 80.0,
                minimum_elevation_deg: 10.0,
                sample_count: 3,
                interpolation: :linear_sample_crossing,
                boundary_refinement: :target_visibility_linear_margin_interpolation,
                start_boundary: :clipped_start,
                end_boundary: :visibility_end,
                start_boundary_detail: %{
                  boundary: :clipped_start,
                  interpolation: :clipped_to_sample,
                  interpolation_fraction: 0.0,
                  sample_index: 1,
                  elevation_deg: 80.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                end_boundary_detail: %{
                  edge: :end,
                  boundary: :visibility_end,
                  interpolation: :linear_sample_crossing,
                  interpolation_fraction: 0.5,
                  before_sample_index: 4,
                  after_sample_index: 5,
                  before_elevation_deg: 20.0,
                  after_elevation_deg: 0.0,
                  minimum_elevation_deg: 10.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                event_timing_policy: :sampled_state_linear_boundary,
                event_detector: :target_visibility,
                event_time_tolerance_s: 60.0,
                max_sample_step_s: 60.0,
                confidence: :bounded_by_sample_cadence
              }
            }
          ],
          source: %{target_id: :target_a}
        },
        %{
          scenario_id: :leo_1,
          event_type: :ground_station_access,
          events: [
            %{
              type: :ground_station_access,
              starts_at: Epoch.new!(300.0, :tdb),
              ends_at: Epoch.new!(420.0, :tdb),
              metadata: %{
                max_elevation_deg: 70.0,
                minimum_elevation_deg: 5.0,
                sample_count: 4,
                interpolation: :linear_sample_crossing,
                boundary_refinement: :aos_los_linear_margin_interpolation,
                start_boundary: :aos,
                end_boundary: :los,
                start_boundary_detail: %{
                  edge: :start,
                  boundary: :aos,
                  interpolation: :linear_sample_crossing,
                  interpolation_fraction: 0.25,
                  before_sample_index: 2,
                  after_sample_index: 3,
                  before_elevation_deg: 0.0,
                  after_elevation_deg: 20.0,
                  minimum_elevation_deg: 5.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                end_boundary_detail: %{
                  edge: :end,
                  boundary: :los,
                  interpolation: :linear_sample_crossing,
                  interpolation_fraction: 0.75,
                  before_sample_index: 4,
                  after_sample_index: 5,
                  before_elevation_deg: 20.0,
                  after_elevation_deg: 0.0,
                  minimum_elevation_deg: 5.0,
                  root_solved: false,
                  confidence: :bounded_by_sample_cadence
                },
                event_timing_policy: :sampled_state_linear_boundary,
                event_detector: :access_windows,
                event_time_tolerance_s: 60.0,
                max_sample_step_s: 60.0,
                confidence: :bounded_by_sample_cadence
              }
            }
          ],
          source: %{ground_station_id: :equator_prime}
        },
        %{
          scenario_id: :other,
          event_type: :eclipse,
          events: [
            %{
              type: :eclipse,
              starts_at: Epoch.new!(120.0, :tdb),
              ends_at: Epoch.new!(240.0, :tdb),
              metadata: %{sample_count: 3}
            }
          ],
          source: %{shadow_model: :cylindrical_central_body_shadow}
        }
      ],
      errors: [],
      assumptions: %{propagator: OrbitalDynamics.Propagators.TwoBody, outputs: [:access_windows]},
      metadata: %{}
    })
  end

  defp refresh_request do
    %{
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-1",
        "accepted_at" => "2026-05-14T00:00:00Z",
        "spacecraft_states" => [%{"spacecraft_id" => "sat_1", "scenario_id" => "leo_1"}],
        "maneuver_execution_deltas" => [],
        "source" => %{"system" => "cadence"},
        "quality" => %{"level" => "accepted"},
        "provenance" => %{"created_by" => "test"}
      },
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 600.0,
        "output_step_s" => 60.0
      },
      "targets" => [%{"id" => "target_a", "priority" => 2.0}],
      "constraints" => %{"avoid_eclipse" => true, "min_activity_duration_s" => 60.0},
      "scoring_policy" => %{
        "target_value_weight" => 1.0,
        "contact_value_weight" => 0.5,
        "downlink_rate_mb_s" => 3.0
      },
      "model_assumptions" => %{"refresh_level" => "sampled_v1"},
      "resource_summaries" => [
        %{
          "spacecraft_id" => "leo_1",
          "fuel_margin" => 0.9,
          "storage_capacity_mb" => 1000.0,
          "storage_used_mb" => 200.0
        }
      ],
      "prior_candidate_activities" => [
        %{
          "id" => "stale_observe",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "starts_at_s" => 10.0,
          "ends_at_s" => 20.0
        }
      ]
    }
  end

  defp ordered_event_result_set(order) do
    target_events = [
      target_visibility_event(120.0, 240.0),
      target_visibility_event(260.0, 340.0)
    ]

    access_events = [
      access_event(300.0, 420.0),
      access_event(430.0, 500.0)
    ]

    event_results = [
      %{
        scenario_id: :leo_1,
        event_type: :target_visibility,
        events: order_events(target_events, order),
        source: %{target_id: :target_a}
      },
      %{
        scenario_id: :leo_1,
        event_type: :ground_station_access,
        events: order_events(access_events, order),
        source: %{ground_station_id: :equator_prime}
      }
    ]

    ResultSet.new!(%{
      study_id: :candidate_refresh_demo,
      trajectory_results: [],
      event_results: order_events(event_results, order),
      errors: [],
      assumptions: %{propagator: OrbitalDynamics.Propagators.TwoBody, outputs: [:access_windows]},
      metadata: %{}
    })
  end

  defp order_events(events, :reversed), do: Enum.reverse(events)
  defp order_events(events, _order), do: events

  defp target_visibility_event(starts_at_s, ends_at_s) do
    %{
      type: :target_visibility,
      starts_at: Epoch.new!(starts_at_s, :tdb),
      ends_at: Epoch.new!(ends_at_s, :tdb),
      metadata: %{
        target_id: :target_a,
        target_priority: 1.0,
        max_elevation_deg: 80.0,
        minimum_elevation_deg: 10.0,
        sample_count: 3
      }
    }
  end

  defp access_event(starts_at_s, ends_at_s) do
    %{
      type: :ground_station_access,
      starts_at: Epoch.new!(starts_at_s, :tdb),
      ends_at: Epoch.new!(ends_at_s, :tdb),
      metadata: %{
        max_elevation_deg: 70.0,
        minimum_elevation_deg: 5.0,
        sample_count: 4
      }
    }
  end

  test "builds refreshed candidates with source-window lineage and stale prior comparison" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh_request(),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert artifact["schema_contract"] == "candidate_refresh.v1"
    assert artifact["planner"] == "OrbitalDynamics.CandidateRefresh.V1"
    assert artifact["snapshot_id"] == "ops-state-1"
    assert artifact["current_epoch_s"] == 0.0
    assert "requires_precomputed_refreshed_event_results" in artifact["model_limits"]
    assert "artifact_only_no_schedule_mutation" in artifact["model_limits"]
    assert artifact["model_limits"] == CandidateRefresh.model_limits()

    assert [observe] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "observe"))
    assert observe["source_window_id"] == "window:leo_1:target_visibility:target_a:1"
    assert observe["score_terms"]["target_value"] == 240.0
    assert observe["target_priority"] == 2.0
    assert observe["observation_success_factor"] == 1.0
    assert observe["eclipse_overlap_s"] == 0.0
    assert observe["eclipse_overlap_fraction"] == 0.0
    assert observe["lighting_condition"] == "sunlit"
    assert observe["lighting_condition_detail"] == "sunlit"
    assert observe["lighting_condition_model"] == "sampled_eclipse_overlap_tag"
    assert observe["lighting_detail_model"] == "sampled_eclipse_overlap_fraction_tag"
    assert observe["lighting_confidence"] == "bounded_by_sampled_eclipse_overlap"
    assert observe["activity_context"]["activity_id"] == observe["id"]

    assert observe["activity_context"]["lighting_confidence"] ==
             "bounded_by_sampled_eclipse_overlap"

    assert observe["source_window"]["interpolation"] == "linear_sample_crossing"

    assert observe["source_window"]["boundary_refinement"] ==
             "target_visibility_linear_margin_interpolation"

    assert observe["source_window"]["start_boundary"] == "clipped_start"
    assert observe["source_window"]["end_boundary"] == "visibility_end"

    assert observe["source_window"]["end_boundary_detail"] == %{
             "edge" => "end",
             "boundary" => "visibility_end",
             "interpolation" => "linear_sample_crossing",
             "interpolation_fraction" => 0.5,
             "before_sample_index" => 4,
             "after_sample_index" => 5,
             "before_elevation_deg" => 20.0,
             "after_elevation_deg" => 0.0,
             "minimum_elevation_deg" => 10.0,
             "root_solved" => false,
             "confidence" => "bounded_by_sample_cadence"
           }

    assert observe["activity_context"]["timeline_id"] ==
             "timeline:leo_1:observe:target_a:window:leo_1:target_visibility:target_a:1"

    assert observe["activity_context"]["activity_type"] == "observe"
    assert observe["activity_context"]["source_window_id"] == observe["source_window_id"]

    assert observe["activity_context"]["timeline_identity"] == %{
             "activity_id" => observe["id"],
             "activity_type" => "observe",
             "scenario_id" => "leo_1",
             "source_window_id" => observe["source_window_id"],
             "subject_id" => "target_a",
             "timeline_id" => observe["activity_context"]["timeline_id"]
           }

    assert [downlink] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["direction"] == "downlink"
    assert downlink["estimated_throughput_mb"] == 360.0
    assert downlink["source_window"]["interpolation"] == "linear_sample_crossing"

    assert downlink["source_window"]["boundary_refinement"] ==
             "aos_los_linear_margin_interpolation"

    assert downlink["source_window"]["start_boundary"] == "aos"
    assert downlink["source_window"]["end_boundary"] == "los"

    assert downlink["source_window"]["start_boundary_detail"] == %{
             "edge" => "start",
             "boundary" => "aos",
             "interpolation" => "linear_sample_crossing",
             "interpolation_fraction" => 0.25,
             "before_sample_index" => 2,
             "after_sample_index" => 3,
             "before_elevation_deg" => 0.0,
             "after_elevation_deg" => 20.0,
             "minimum_elevation_deg" => 5.0,
             "root_solved" => false,
             "confidence" => "bounded_by_sample_cadence"
           }

    assert downlink["source_window"]["event_timing_policy"] == "sampled_state_linear_boundary"
    assert downlink["source_window"]["event_time_tolerance_s"] == 60.0
    assert downlink["activity_context"]["activity_id"] == downlink["id"]
    assert downlink["activity_context"]["ground_station_id"] == "equator_prime"
    assert downlink["activity_context"]["direction"] == "downlink"

    assert [
             %{
               "assumptions" => %{
                 "event_timing_policy" => "sampled_state_linear_boundary",
                 "event_time_tolerance_s" => 60.0
               }
             }
           ] = artifact["refreshed_windows"]["access_windows"]

    assert [
             %{
               "schema_contract" => "contact_intent.v1",
               "activity_id" => "leo_1_downlink_equator_prime_1",
               "direction" => "downlink"
             }
           ] = artifact["contact_intents"]

    assert [
             %{
               "schema_contract" => "resource_summary.v1",
               "spacecraft_id" => "leo_1",
               "storage_margin" => 0.8
             }
           ] = artifact["resource_summaries"]

    assert [
             %{
               "id" => "stale_observe",
               "invalidated_reason" => "not_present_in_refreshed_candidate_set"
             }
           ] = artifact["invalidated_candidates"]

    assert %{
             "schema_contract" => "candidate_diff_report.v1",
             "model" => "candidate_id_set_diff_with_semantic_change_reasons",
             "model_limits" => candidate_diff_model_limits,
             "prior_candidate_count" => 1,
             "refreshed_candidate_count" => 2,
             "retained_candidate_count" => 0,
             "new_candidate_count" => 2,
             "invalidated_candidate_count" => 1,
             "retained_candidates" => [],
             "invalidated_candidates" => [
               %{
                 "id" => "stale_observe",
                 "invalidated_reason" => "not_present_in_refreshed_candidate_set"
               }
             ]
           } = artifact["candidate_diff_report"]

    assert candidate_diff_model_limits == artifact["model_limits"]

    assert Enum.map(artifact["candidate_diff_report"]["new_candidates"], & &1["id"]) == [
             "leo_1_observe_target_a_1",
             "leo_1_downlink_equator_prime_1"
           ]

    assert Enum.all?(
             artifact["candidate_diff_report"]["new_candidates"],
             &(&1["diff_reason"] == "not_present_in_prior_candidate_set")
           )

    assert %{
             "schema_contract" => "freshness_report.v1",
             "model" => "accepted_snapshot_horizon_and_quality_freshness",
             "model_limits" => freshness_model_limits,
             "accepted_state_quality_level" => "accepted",
             "state_quality_status" => "accepted",
             "allowed_state_quality_levels" => ["accepted", "planning_accepted"],
             "status" => "current",
             "stale_reasons" => []
           } = artifact["freshness_report"]

    assert freshness_model_limits == artifact["model_limits"]
    assert artifact["freshness_report"]["accepted_snapshot_age_s"] == 0.0
    assert artifact["freshness_report"]["horizon_start_offset_s"] == 0.0

    assert %{
             "schema_contract" => "refresh_budget_report.v1",
             "model" => "deterministic_candidate_limit_after_filters",
             "model_limits" => refresh_budget_model_limits,
             "input_candidate_count" => 2,
             "kept_candidate_count" => 2,
             "dropped_candidate_count" => 0,
             "selection_order" => "score_descending_then_start_then_id",
             "kept_candidate_ids" => [
               "leo_1_observe_target_a_1",
               "leo_1_downlink_equator_prime_1"
             ],
             "dropped_candidate_ids" => []
           } = artifact["refresh_budget_report"]

    assert refresh_budget_model_limits == artifact["model_limits"]

    assert [
             %{
               "schema_contract" => "source_window_lineage.v1",
               "candidate_activity_id" => "leo_1_downlink_equator_prime_1",
               "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1",
               "source_window_type" => "ground_station_access",
               "scenario_id" => "leo_1",
               "source_window" => %{
                 "id" => "window:leo_1:ground_station_access:equator_prime:1",
                 "type" => "ground_station_access",
                 "scenario_id" => "leo_1",
                 "ground_station_id" => "equator_prime",
                 "starts_at_s" => 300.0,
                 "ends_at_s" => 420.0,
                 "boundary_refinement" => "aos_los_linear_margin_interpolation"
               }
             },
             %{
               "schema_contract" => "source_window_lineage.v1",
               "candidate_activity_id" => "leo_1_observe_target_a_1",
               "source_window_id" => "window:leo_1:target_visibility:target_a:1",
               "source_window_type" => "target_visibility",
               "scenario_id" => "leo_1",
               "source_window" => %{
                 "id" => "window:leo_1:target_visibility:target_a:1",
                 "type" => "target_visibility",
                 "scenario_id" => "leo_1",
                 "target_id" => "target_a",
                 "starts_at_s" => 120.0,
                 "ends_at_s" => 240.0,
                 "boundary_refinement" => "target_visibility_linear_margin_interpolation"
               }
             }
           ] = artifact["source_window_lineage"]

    assert artifact["candidate_diff_report"]["source_window_lineage"] ==
             artifact["source_window_lineage"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
