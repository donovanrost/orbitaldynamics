defmodule OrbitalDynamics.CandidateRefresh.CandidateBudgetBuildTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{
    CadenceImport,
    CandidateRefresh,
    Epoch,
    OperatorReview,
    ResultSet,
    Schema
  }

  test "does not score observations from duplicate target ids in refresh request" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("targets", [
            %{"id" => "target_a", "priority" => 10.0},
            %{"id" => "target_a", "priority" => 2.0}
          ]),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [observe] = Enum.filter(artifact["candidate_activities"], &(&1["type"] == "observe"))

    assert observe["score_terms"]["target_value"] == 120.0

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "limits refreshed candidates with deterministic post-filter budget policy" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> put_in(["candidate_limit_policy"], %{"max_candidate_activities" => 1}),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_observe_target_a_1"
           ]

    assert artifact["contact_intents"] == []

    assert %{
             "schema_contract" => "refresh_budget_report.v1",
             "input_candidate_count" => 2,
             "kept_candidate_count" => 1,
             "dropped_candidate_count" => 1,
             "max_candidate_activities" => 1,
             "kept_candidate_ids" => ["leo_1_observe_target_a_1"],
             "dropped_candidate_ids" => ["leo_1_downlink_equator_prime_1"]
           } = artifact["refresh_budget_report"]

    assert artifact["candidate_diff_report"]["refreshed_candidate_count"] == 1

    assert "candidate refresh budget dropped candidate activities" in artifact["warnings"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "reports no candidate budget limit as the full post-filter candidate count" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh_request(),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert %{
             "input_candidate_count" => 2,
             "kept_candidate_count" => 2,
             "dropped_candidate_count" => 0,
             "max_candidate_activities" => 2
           } = artifact["refresh_budget_report"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "normalizes clean numeric-string candidate budget limits" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> put_in(["candidate_limit_policy"], %{"max_candidate_activities" => "1.0"}),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_observe_target_a_1"
           ]

    assert %{
             "kept_candidate_count" => 1,
             "dropped_candidate_count" => 1,
             "invalid_candidate_limit_policy" => false,
             "max_candidate_activities" => 1
           } = artifact["refresh_budget_report"]

    refute Map.has_key?(
             artifact["refresh_budget_report"],
             "invalid_candidate_limit_policy_reason"
           )

    refute "candidate refresh budget policy is invalid" in artifact["warnings"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "candidate diff distinguishes budget-dropped refreshed replacements" do
    prior_downlink = %{
      "id" => "leo_1_downlink_equator_prime_1",
      "type" => "downlink",
      "scenario_id" => "leo_1",
      "ground_station_id" => "equator_prime",
      "starts_at_s" => 300.0,
      "ends_at_s" => 420.0,
      "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1"
    }

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("prior_candidate_activities", [prior_downlink])
          |> put_in(["candidate_limit_policy"], %{"max_candidate_activities" => 1}),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert artifact["refresh_budget_report"]["dropped_candidate_ids"] == [
             "leo_1_downlink_equator_prime_1"
           ]

    assert %{
             "refreshed_candidate_count" => 1,
             "invalidated_candidate_count" => 1,
             "invalidated_candidates" => [
               %{
                 "id" => "leo_1_downlink_equator_prime_1",
                 "invalidated_reason" => "dropped_by_candidate_budget",
                 "replacement_candidate_id" => "leo_1_downlink_equator_prime_1",
                 "candidate_budget_match_status" => "budget_dropped_replacement_candidate",
                 "candidate_budget_match_count" => 1,
                 "budget_dropped_candidate_ids" => ["leo_1_downlink_equator_prime_1"]
               }
             ]
           } = artifact["candidate_diff_report"]

    assert artifact["candidate_diff_report"]["invalidated_candidates"] ==
             artifact["invalidated_candidates"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "candidate budget drops duplicate candidate ids by row identity" do
    artifact =
      result_set_with_duplicate_observation_ids()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> put_in(["candidate_limit_policy"], %{"max_candidate_activities" => 1}),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_observe_target_a_1"
           ]

    assert %{
             "schema_contract" => "refresh_budget_report.v1",
             "input_candidate_count" => 2,
             "kept_candidate_count" => 1,
             "dropped_candidate_count" => 1,
             "kept_candidate_ids" => ["leo_1_observe_target_a_1"],
             "dropped_candidate_ids" => ["leo_1_observe_target_a_1:occurrence:2"]
           } = artifact["refresh_budget_report"]

    assert "candidate refresh budget dropped candidate activities" in artifact["warnings"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "invalid candidate budget policy is review gated instead of silently ignored" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> put_in(["candidate_limit_policy"], %{"max_candidate_activities" => "one"}),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert %{
             "input_candidate_count" => 2,
             "kept_candidate_count" => 2,
             "dropped_candidate_count" => 0,
             "invalid_candidate_limit_policy" => true,
             "invalid_candidate_limit_policy_reason" =>
               "max_candidate_activities_must_be_integer",
             "source_candidate_limit_policy" => %{"max_candidate_activities" => "one"}
           } = artifact["refresh_budget_report"]

    assert "candidate refresh budget policy is invalid" in artifact["warnings"]

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "review_type" => "refresh_budget_review",
             "required_operator_action" => "review_refresh_budget",
             "reason" =>
               "candidate refresh budget policy is invalid: max_candidate_activities_must_be_integer",
             "invalid_candidate_limit_policy" => true,
             "invalid_candidate_limit_policy_reason" =>
               "max_candidate_activities_must_be_integer",
             "source_candidate_limit_policy" => %{"max_candidate_activities" => "one"}
           } = Enum.find(review["rows"], &(&1["review_type"] == "refresh_budget_review"))

    assert %{
             "import_action" => "review_refresh_budget",
             "refresh_gate_status" => "invalid_candidate_limit_policy",
             "invalid_candidate_limit_policy" => true,
             "invalid_candidate_limit_policy_reason" =>
               "max_candidate_activities_must_be_integer",
             "source_candidate_limit_policy" => %{"max_candidate_activities" => "one"}
           } = Enum.find(import["rows"], &(&1["import_action"] == "review_refresh_budget"))

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "invalid candidate budget policy shape is review gated instead of raising" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("candidate_limit_policy", "max_one_candidate"),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert %{
             "input_candidate_count" => 2,
             "kept_candidate_count" => 2,
             "dropped_candidate_count" => 0,
             "invalid_candidate_limit_policy" => true,
             "invalid_candidate_limit_policy_reason" => "candidate_limit_policy_must_be_object",
             "source_candidate_limit_policy" => %{"invalid_policy_shape" => "max_one_candidate"}
           } = artifact["refresh_budget_report"]

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "review_type" => "refresh_budget_review",
             "required_operator_action" => "review_refresh_budget",
             "reason" =>
               "candidate refresh budget policy is invalid: candidate_limit_policy_must_be_object",
             "invalid_candidate_limit_policy" => true,
             "source_candidate_limit_policy" => %{"invalid_policy_shape" => "max_one_candidate"}
           } = Enum.find(review["rows"], &(&1["review_type"] == "refresh_budget_review"))

    assert %{
             "import_action" => "review_refresh_budget",
             "refresh_gate_status" => "invalid_candidate_limit_policy",
             "invalid_candidate_limit_policy" => true,
             "source_candidate_limit_policy" => %{"invalid_policy_shape" => "max_one_candidate"}
           } = Enum.find(import["rows"], &(&1["import_action"] == "review_refresh_budget"))

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "candidate diff matches duplicate candidate ids by occurrence" do
    prior_observation = %{
      "id" => "leo_1_observe_target_a_1",
      "type" => "observe",
      "scenario_id" => "leo_1",
      "target_id" => "target_a",
      "starts_at_s" => 120.0,
      "ends_at_s" => 240.0,
      "source_window_id" => "window:leo_1:target_visibility:target_a:1"
    }

    artifact =
      result_set_with_duplicate_observation_ids()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("prior_candidate_activities", [prior_observation]),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert %{
             "prior_candidate_count" => 1,
             "refreshed_candidate_count" => 2,
             "retained_candidate_count" => 1,
             "new_candidate_count" => 1,
             "invalidated_candidate_count" => 0,
             "invalidated_candidates" => []
           } = artifact["candidate_diff_report"]

    assert [%{"id" => "leo_1_observe_target_a_1"}] =
             artifact["candidate_diff_report"]["retained_candidates"]

    assert [%{"id" => "leo_1_observe_target_a_1"}] =
             artifact["candidate_diff_report"]["new_candidates"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "candidate diff invalidates unmatched duplicate prior candidate ids" do
    duplicate_prior_downlinks = [
      %{
        "id" => "leo_1_downlink_equator_prime_1",
        "type" => "downlink",
        "scenario_id" => "leo_1",
        "starts_at_s" => 300.0,
        "ends_at_s" => 420.0,
        "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1"
      },
      %{
        "id" => "leo_1_downlink_equator_prime_1",
        "type" => "downlink",
        "scenario_id" => "leo_1",
        "starts_at_s" => 360.0,
        "ends_at_s" => 480.0,
        "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1"
      }
    ]

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("prior_candidate_activities", duplicate_prior_downlinks),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert %{
             "prior_candidate_count" => 2,
             "refreshed_candidate_count" => 2,
             "retained_candidate_count" => 1,
             "new_candidate_count" => 1,
             "invalidated_candidate_count" => 1,
             "invalidated_candidates" => [
               %{
                 "id" => "leo_1_downlink_equator_prime_1",
                 "invalidated_reason" => "not_present_in_refreshed_candidate_set"
               }
             ]
           } = artifact["candidate_diff_report"]

    assert artifact["candidate_diff_report"]["invalidated_candidates"] ==
             artifact["invalidated_candidates"]

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

  defp result_set_with_duplicate_observation_ids do
    duplicate_observation_result = %{
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
            sample_count: 3
          }
        }
      ],
      source: %{target_id: :target_a}
    }

    ResultSet.new!(%{
      study_id: :candidate_refresh_demo,
      trajectory_results: [],
      event_results: [duplicate_observation_result, duplicate_observation_result],
      errors: [],
      assumptions: %{propagator: OrbitalDynamics.Propagators.TwoBody, outputs: [:visibility]},
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
