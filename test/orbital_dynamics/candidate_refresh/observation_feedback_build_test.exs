defmodule OrbitalDynamics.CandidateRefresh.ObservationFeedbackBuildTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CandidateRefresh, Epoch, ResultSet, Schema, TimelineFeedback}

  test "candidate diff records semantic change details for target priority" do
    refresh =
      refresh_request()
      |> Map.put("prior_candidate_activities", [
        %{
          "id" => "leo_1_observe_target_a_1",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "target_id" => "target_a",
          "target_priority" => 1.0
        }
      ])
      |> Map.put("objectives", [
        %{
          "id" => "urgent:target_a",
          "type" => "urgent_target",
          "target_id" => "target_a",
          "priority" => 12.0
        }
      ])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [
             %{
               "id" => "leo_1_observe_target_a_1",
               "diff_reason" => "present_in_prior_candidate_set_with_semantic_changes",
               "changed_fields" => ["target_priority"],
               "candidate_diff_changed_fields" => ["target_priority"],
               "candidate_diff_changed_field_count" => 1,
               "semantic_change_reasons" => ["target_priority_changed"],
               "semantic_change_details" => [
                 %{
                   "field" => "target_priority",
                   "reason" => "target_priority_changed",
                   "prior_path" => "target_priority",
                   "refreshed_path" => "target_priority",
                   "prior_value" => 1.0,
                   "refreshed_value" => 12.0
                 }
               ]
             }
           ] = artifact["candidate_diff_report"]["retained_candidates"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "applies standalone observation success and target priority feedback to observations" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> put_in(["operational_feedback"], %{
            "observation_success_rate" => %{"target_a" => 0.5},
            "target_priority_overrides" => %{"target_a" => 5.0}
          }),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [observe] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "observe"))
    assert observe["score_terms"]["target_value"] == 300.0
    assert observe["target_priority"] == 2.5
    assert observe["observation_success_factor"] == 0.5

    assert observe["observation_success_factor_source"] ==
             "operational_feedback.observation_success_rate.target"

    assert %{
             "operational_feedback" => %{
               "trust_boundary_status" => "missing",
               "input_keys" => ["observation_success_rate", "target_priority_overrides"]
             }
           } = artifact["provenance"]

    assert "operational feedback was applied without a declared trust boundary" in artifact[
             "warnings"
           ]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "applies target priority overrides derived from realized timeline feedback" do
    feedback =
      TimelineFeedback.reconcile(
        [
          %{
            id: :obs_target_a,
            type: :observe,
            target_id: :target_a,
            starts_at_s: 10.0,
            ends_at_s: 20.0
          }
        ],
        [
          %{
            id: :obs_target_a_feedback,
            planned_activity_id: :obs_target_a,
            type: :observe,
            status: :completed,
            target_id: :target_a,
            target_priority: 6.0
          }
        ]
      )

    assert get_in(feedback, ["operational_feedback", "target_priority_overrides"]) == %{
             "target_a" => 6.0
           }

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> put_in(["operational_feedback"], feedback["operational_feedback"]),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [observe] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "observe"))
    assert observe["target_priority"] == 6.0
    assert observe["score_terms"]["target_value"] == 720.0

    assert "target_priority_overrides" in get_in(artifact, [
             "provenance",
             "operational_feedback",
             "input_keys"
           ])

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "applies realized observation quality feedback through observation success handoff" do
    feedback =
      TimelineFeedback.reconcile(
        [
          %{
            id: :obs_quality,
            type: :observe,
            target_id: :target_a,
            starts_at_s: 10.0,
            ends_at_s: 20.0
          }
        ],
        [
          %{
            id: :obs_quality_feedback,
            planned_activity_id: :obs_quality,
            type: :observe,
            target_id: :target_a,
            status: :completed,
            image_quality_score: 0.67,
            image_quality_status: :usable,
            image_quality_source: :provider_image_assessment,
            cloud_cover_fraction: "0.18",
            image_blur_score: 0.06
          }
        ]
      )

    assert get_in(feedback, ["operational_feedback", "observation_success_rate"]) == %{
             "target_a" => 0.67
           }

    assert get_in(feedback, ["operational_feedback", "image_quality_score"]) == %{
             "target_a" => 0.67
           }

    assert get_in(feedback, ["operational_feedback", "image_quality_status"]) == %{
             "target_a" => "usable"
           }

    assert get_in(feedback, ["operational_feedback", "image_quality_source"]) == %{
             "target_a" => "provider_image_assessment"
           }

    assert get_in(feedback, ["operational_feedback", "cloud_cover_fraction"]) == %{
             "target_a" => 0.18
           }

    assert get_in(feedback, ["operational_feedback", "blur_score"]) == %{
             "target_a" => 0.06
           }

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> put_in(["operational_feedback"], feedback["operational_feedback"]),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [observe] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "observe"))
    assert observe["observation_success_factor"] == 0.67
    assert observe["image_quality_score"] == 0.67
    assert observe["image_quality_status"] == "usable"
    assert observe["image_quality_source"] == "provider_image_assessment"
    assert observe["cloud_cover_fraction"] == 0.18
    assert observe["blur_score"] == 0.06

    assert observe["observation_success_factor_source"] ==
             "operational_feedback.observation_success_rate.target"

    assert "observation_success_rate" in get_in(artifact, [
             "provenance",
             "operational_feedback",
             "input_keys"
           ])

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "does not double apply observation success feedback already encoded in targets" do
    refresh =
      refresh_request()
      |> Map.put("targets", [
        %{
          "id" => "target_a",
          "priority" => 1.0,
          "observation_success_factor" => "0.5"
        }
      ])
      |> put_in(["operational_feedback"], %{
        "observation_success_rate" => %{"target_a" => 0.5}
      })

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [observe] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "observe"))
    assert observe["score_terms"]["target_value"] == 120.0
    assert observe["target_priority"] == 1.0
    assert observe["observation_success_factor"] == 0.5

    assert observe["observation_success_factor_source"] ==
             "operational_feedback.observation_success_rate.encoded"

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "malformed encoded observation success feedback falls back to operational feedback" do
    refresh =
      refresh_request()
      |> Map.put("targets", [
        %{
          "id" => "target_a",
          "priority" => 1.0,
          "observation_success_factor" => "unknown"
        }
      ])
      |> put_in(["operational_feedback"], %{
        "observation_success_rate" => %{"target_a" => 0.5}
      })

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [observe] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "observe"))
    assert observe["target_priority"] == 0.5
    assert observe["observation_success_factor"] == 0.5

    assert observe["observation_success_factor_source"] ==
             "operational_feedback.observation_success_rate.target"

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
