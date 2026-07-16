defmodule OrbitalDynamics.CandidateRefresh.DownlinkFeedbackBuildTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CandidateRefresh, Epoch, ResultSet, Schema}

  test "applies station throughput feedback to standalone refreshed downlinks" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> put_in(["operational_feedback"], %{
            "station_throughput_factor" => %{"equator_prime" => 0.5}
          }),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [downlink] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["estimated_throughput_mb"] == 180.0
    assert downlink["score_terms"]["contact_value"] == 30.0
    assert get_in(downlink, ["throughput_model", "station_capacity_fraction"]) == 0.5
    assert get_in(downlink, ["throughput_model", "declared_station_capacity_fraction"]) == 1.0
    assert get_in(downlink, ["throughput_model", "station_throughput_factor"]) == 0.5

    assert get_in(downlink, ["throughput_model", "station_throughput_factor_source"]) ==
             "operational_feedback.station_throughput_factor.station"

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "applies contact success feedback to refreshed downlinks with typed source evidence" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> put_in(["operational_feedback"], %{
            "contact_success_rate" => %{"equator_prime" => 0.4}
          }),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))

    assert downlink["contact_success_factor"] == 0.4

    assert downlink["contact_success_factor_source"] ==
             "operational_feedback.contact_success_rate.station"

    assert get_in(downlink, ["throughput_model", "contact_success_factor"]) == 0.4

    assert get_in(downlink, ["throughput_model", "confidence_source"]) ==
             "operational_feedback.contact_success_rate.station"

    assert downlink["score_terms"]["contact_success_adjustment"] < 0.0

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "applies downlink demand feedback to candidate scoring and budget selection" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> put_in(["candidate_limit_policy"], %{"max_candidate_activities" => 1})
          |> put_in(["scoring_policy", "downlink_completion_weight"], 250.0)
          |> put_in(["operational_feedback"], %{
            "trust_boundary" => "cadence_operational_feedback",
            "downlink_demand_mb" => %{"equator_prime" => 360.0}
          }),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [downlink] = artifact["candidate_activities"]
    assert downlink["id"] == "leo_1_downlink_equator_prime_1"
    assert downlink["required_downlink_mb"] == 360.0
    assert downlink["candidate_downlink_mb"] == 360.0
    assert downlink["downlink_completion_ratio"] == 1.0
    assert downlink["selected_downlink_shortfall_mb"] == 0.0
    assert downlink["downlink_requirement_status"] == "satisfied"

    assert downlink["downlink_completion_source"] ==
             "operational_feedback.downlink_demand_mb.station"

    assert downlink["downlink_completion_sources"] == [
             "operational_feedback.downlink_demand_mb.station"
           ]

    assert downlink["score_terms"]["downlink_completion_value"] == 250.0
    assert downlink["score"] == 310.0

    assert get_in(downlink, ["throughput_model", "required_downlink_mb"]) == 360.0
    assert get_in(downlink, ["throughput_model", "candidate_downlink_mb"]) == 360.0
    assert get_in(downlink, ["throughput_model", "downlink_completion_ratio"]) == 1.0
    assert get_in(downlink, ["throughput_model", "selected_downlink_shortfall_mb"]) == 0.0
    assert get_in(downlink, ["throughput_model", "downlink_requirement_status"]) == "satisfied"

    assert get_in(downlink, ["throughput_model", "downlink_completion_source"]) ==
             "operational_feedback.downlink_demand_mb.station"

    assert get_in(downlink, ["throughput_model", "downlink_completion_sources"]) == [
             "operational_feedback.downlink_demand_mb.station"
           ]

    assert get_in(downlink, ["activity_context", "required_downlink_mb"]) == 360.0
    assert get_in(downlink, ["activity_context", "candidate_downlink_mb"]) == 360.0
    assert get_in(downlink, ["activity_context", "downlink_completion_ratio"]) == 1.0
    assert get_in(downlink, ["activity_context", "selected_downlink_shortfall_mb"]) == 0.0
    assert get_in(downlink, ["activity_context", "downlink_requirement_status"]) == "satisfied"

    assert get_in(downlink, ["activity_context", "downlink_completion_source"]) ==
             "operational_feedback.downlink_demand_mb.station"

    assert get_in(downlink, ["activity_context", "downlink_completion_sources"]) == [
             "operational_feedback.downlink_demand_mb.station"
           ]

    assert artifact["refresh_budget_report"]["kept_candidate_ids"] == [
             "leo_1_downlink_equator_prime_1"
           ]

    assert artifact["refresh_budget_report"]["dropped_candidate_ids"] == [
             "leo_1_observe_target_a_1"
           ]

    assert artifact["provenance"]["operational_feedback"]["input_keys"] == [
             "downlink_demand_mb"
           ]

    refute "operational feedback was applied without a declared trust boundary" in artifact[
             "warnings"
           ]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "does not double count source-report downlink demand already replayed as branch feedback" do
    source_report = %{
      "schema_contract" => "objective_satisfaction_report.v1",
      "rows" => [
        %{
          "id" => "objective:downlink_completion",
          "objective" => "downlink_completion",
          "status" => "partial",
          "scenario_id" => "leo_1",
          "ground_station_id" => "equator_prime",
          "required_downlink_mb" => 120.0,
          "selected_downlink_mb" => 70.0
        }
      ],
      "provenance" => %{"trust_boundary" => "mission_objective_review"}
    }

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> put_in(["operational_feedback"], %{
            "trust_boundary" => "mission_objective_review",
            "downlink_demand_mb" => %{"equator_prime" => 120.0},
            "downlink_demand_context" => %{
              "equator_prime" => %{
                "feedback_source" => "mission_state.source_objective_satisfaction_report",
                "feedback_scope" => "objective_satisfaction"
              }
            }
          })
          |> Map.put("mission_state", %{
            "source_objective_satisfaction_report" => source_report
          }),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 120.0

    assert downlink["downlink_completion_sources"] == [
             "operational_feedback.downlink_demand_mb.station"
           ]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "normalizes clean numeric string branch refresh feedback objectives and policies" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> put_in(["current_epoch_s"], "0.0")
          |> put_in(["remaining_horizon", "starts_at_s"], "0.0")
          |> Map.put("freshness_policy", %{"max_horizon_start_offset_s" => "0.0"})
          |> put_in(["scoring_policy", "downlink_completion_weight"], "250.0")
          |> put_in(["scoring_policy", "contact_value_weight"], "0.1")
          |> put_in(["scoring_policy", "observation_objective_weight"], "25.0")
          |> put_in(["operational_feedback"], %{
            "trust_boundary" => "cadence_operational_feedback",
            "contact_success_rate" => %{"equator_prime" => "0.4"},
            "station_throughput_factor" => %{"equator_prime" => "0.5"},
            "downlink_demand_mb" => %{"equator_prime" => "360.0"},
            "target_priority_overrides" => %{"target_a" => "3.0"}
          })
          |> Map.put("objectives", [
            %{
              "id" => "observe_target_a_twice",
              "type" => "target_observation",
              "target_id" => "target_a",
              "required_count" => "2",
              "target_priority" => "5.0"
            }
          ]),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 360.0
    assert downlink["candidate_downlink_mb"] == 180.0
    assert downlink["downlink_completion_ratio"] == 0.5
    assert downlink["selected_downlink_shortfall_mb"] == 180.0
    assert downlink["contact_success_factor"] == 0.4
    assert downlink["throughput_model"]["station_throughput_factor"] == 0.5
    assert downlink["score_terms"]["downlink_completion_value"] == 125.0

    observe = Enum.find(artifact["candidate_activities"], &(&1["type"] == "observe"))
    assert observe["target_priority"] == 5.0
    assert observe["activity_context"]["required_observations"] == 2.0

    assert observe["activity_context"]["target_priority_objective_ids"] == [
             "observe_target_a_twice"
           ]

    assert observe["score_terms"]["observation_objective_value"] == 50.0

    assert artifact["current_epoch_s"] == 0.0
    assert artifact["freshness_report"]["horizon_start_offset_s"] == 0.0
    assert artifact["freshness_report"]["status"] == "current"

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "preserves downlink demand source lineage in refreshed downlink evidence" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> put_in(["operational_feedback"], %{
            "trust_boundary" => "campaign_strategy_branch_feedback",
            "downlink_demand_mb" => %{"equator_prime" => 180.0},
            "downlink_demand_sources" => %{
              "equator_prime" => [
                "link_capacity.contact.required_downlink_mb:dl_unselected",
                "link_capacity.policy.required_downlink_mb_by_ground_station:equator_prime"
              ]
            }
          }),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [downlink] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 180.0

    assert downlink["downlink_completion_source"] ==
             "operational_feedback.downlink_demand_mb.station"

    assert downlink["downlink_completion_sources"] == [
             "link_capacity.contact.required_downlink_mb:dl_unselected",
             "link_capacity.policy.required_downlink_mb_by_ground_station:equator_prime"
           ]

    assert get_in(downlink, ["throughput_model", "downlink_completion_sources"]) ==
             downlink["downlink_completion_sources"]

    assert get_in(downlink, ["activity_context", "downlink_completion_sources"]) ==
             downlink["downlink_completion_sources"]

    assert artifact["provenance"]["operational_feedback"]["input_keys"] == [
             "downlink_demand_mb",
             "downlink_demand_sources"
           ]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
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
end
