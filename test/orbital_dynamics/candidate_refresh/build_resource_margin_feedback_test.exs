defmodule OrbitalDynamics.CandidateRefresh.BuildResourceMarginFeedbackTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CandidateRefresh, Epoch, ResultSet, Schema}

  test "applies resource margin feedback to refreshed resource summaries" do
    refresh =
      refresh_request()
      |> Map.put("resource_filter_policy", %{"min_downlink_margin" => 0.2})
      |> put_in(["operational_feedback"], %{
        "resource_margin_overrides" => %{
          "sat_1" => %{"downlink_capacity_margin" => "0.05"}
        }
      })

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_observe_target_a_1"
           ]

    assert Enum.any?(
             artifact["resource_summaries"],
             &(&1["spacecraft_id"] == "sat_1" and &1["downlink_margin"] == 0.05 and
                 not Map.has_key?(&1, "downlink_capacity_margin") and
                 &1["source_quality"] == "operational_feedback")
           )

    assert [
             %{
               "id" => "leo_1_downlink_equator_prime_1",
               "spacecraft_id" => "sat_1",
               "suppressed_reason" => "downlink_margin_below_policy",
               "resource_blocking_dimension" => "downlink",
               "downlink_margin" => 0.05
             }
           ] = artifact["resource_filter_report"]["suppressed_candidates"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "applies storage capacity margin feedback alias before resource filtering" do
    refresh =
      refresh_request()
      |> Map.put("resource_filter_policy", %{"min_observe_storage_margin" => 0.2})
      |> put_in(["operational_feedback"], %{
        "resource_margin_overrides" => %{
          "sat_1" => %{"storage_capacity_margin" => "0.05"}
        }
      })

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_downlink_equator_prime_1"
           ]

    assert Enum.any?(
             artifact["resource_summaries"],
             &(&1["spacecraft_id"] == "sat_1" and &1["storage_margin"] == 0.05 and
                 not Map.has_key?(&1, "storage_capacity_margin") and
                 &1["source_quality"] == "operational_feedback")
           )

    assert [
             %{
               "id" => "leo_1_observe_target_a_1",
               "spacecraft_id" => "sat_1",
               "suppressed_reason" => "storage_margin_below_observe_policy",
               "resource_blocking_dimension" => "storage",
               "storage_margin" => 0.05
             }
           ] = artifact["resource_filter_report"]["suppressed_candidates"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "invalid resource feedback overrides are review gated before filtering" do
    refresh =
      refresh_request()
      |> Map.put("resource_filter_policy", %{"min_observe_power_margin" => 0.2})
      |> put_in(["operational_feedback"], %{
        "resource_margin_overrides" => %{
          "sat_1" => %{"power_margin" => 1.2}
        }
      })

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    refute Enum.any?(artifact["resource_summaries"], &(&1["spacecraft_id"] == "sat_1"))

    assert %{
             "input_resource_summary_count" => 2,
             "valid_resource_summary_count" => 1,
             "invalid_resource_summary_input_count" => 1,
             "invalid_resource_summary_inputs" => [
               %{
                 "resource_summary_id" => "sat_1",
                 "invalid_resource_summary_input_reason" => "invalid_power_margin",
                 "source_resource_summary" => %{
                   "power_margin" => 1.2,
                   "source_quality" => "operational_feedback",
                   "provenance" => %{
                     "resource_feedback_source" => "operational_feedback",
                     "trust_boundary" => "operational_feedback"
                   }
                 }
               }
             ],
             "suppressed_candidate_count" => 0
           } = artifact["resource_filter_report"]

    assert "resource summary inputs require operator review" in artifact["warnings"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "uses battery state of charge feedback as refresh-local power margin" do
    refresh =
      refresh_request()
      |> Map.put("resource_filter_policy", %{"min_observe_power_margin" => 0.2})
      |> put_in(["operational_feedback"], %{
        "resource_margin_overrides" => %{
          "sat_1" => %{"battery_soc" => "0.05"}
        }
      })

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_downlink_equator_prime_1"
           ]

    assert Enum.any?(
             artifact["resource_summaries"],
             &(&1["spacecraft_id"] == "sat_1" and &1["battery_state_of_charge"] == 0.05 and
                 &1["power_margin"] == 0.05 and
                 not Map.has_key?(&1, "battery_soc") and
                 &1["source_quality"] == "operational_feedback")
           )

    assert [
             %{
               "id" => "leo_1_observe_target_a_1",
               "spacecraft_id" => "sat_1",
               "suppressed_reason" => "power_margin_below_observe_policy",
               "resource_blocking_dimension" => "power",
               "power_margin" => 0.05
             }
           ] = artifact["resource_filter_report"]["suppressed_candidates"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "uses thermal margin feedback as a refresh-local resource margin" do
    refresh =
      refresh_request()
      |> Map.put("resource_filter_policy", %{"min_activity_thermal_margin_c" => 2.0})
      |> put_in(["operational_feedback"], %{
        "resource_margin_overrides" => %{
          "sat_1" => %{"thermal_margin_c" => "1.5"}
        },
        "trust_boundary" => "ops_thermal_feedback"
      })

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert artifact["candidate_activities"] == []

    assert Enum.any?(
             artifact["resource_summaries"],
             &(&1["spacecraft_id"] == "sat_1" and &1["thermal_margin_c"] == 1.5 and
                 &1["source_quality"] == "operational_feedback" and
                 get_in(&1, ["provenance", "trust_boundary"]) == "ops_thermal_feedback")
           )

    assert Enum.map(
             artifact["resource_filter_report"]["suppressed_candidates"],
             &{&1["id"], &1["suppressed_reason"], &1["resource_blocking_dimension"],
              &1["thermal_margin_c"]}
           ) == [
             {"leo_1_observe_target_a_1", "thermal_margin_below_policy", "thermal", 1.5},
             {"leo_1_downlink_equator_prime_1", "thermal_margin_below_policy", "thermal", 1.5}
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
