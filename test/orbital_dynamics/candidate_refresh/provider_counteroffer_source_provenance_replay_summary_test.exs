defmodule OrbitalDynamics.CandidateRefresh.ProviderCounterofferSourceProvenanceReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{
    CadenceImport,
    CandidateRefresh,
    Epoch,
    OperatorReview,
    ResultSet,
    Schema
  }

  test "replays provider-counteroffer source reports from review and import containers" do
    report = %{
      "schema_contract" => "provider_counteroffer_report.v1",
      "source" => "station_calendar_report.affected_contacts",
      "counteroffer_count" => 1,
      "reviewable_count" => 1,
      "rows" => [
        %{
          "id" => "provider_counteroffer:review:counteroffer_1",
          "provider_counteroffer_id" => "counteroffer_1",
          "provider_counteroffer_status" => "proposed",
          "provider_counteroffer_cost_delta" => 40.0,
          "provider_counteroffer_lock_deadline_s" => 360.0,
          "provider_counteroffer_start_delta_s" => 45.0,
          "provider_counteroffer_end_delta_s" => 30.0,
          "provider_counteroffer_duration_delta_s" => -15.0,
          "reviewable" => true,
          "required_operator_action" => "review_provider_counteroffer",
          "trust_boundary" => "counterparty_provider"
        }
      ],
      "provenance" => %{"trust_boundary" => "operator_review_queue"}
    }

    package = OperatorReview.from_provider_counteroffer_report(report)
    manifest = CadenceImport.from_provider_counteroffer_report(report)

    for {source, expected_path, expected_trust_boundaries} <- [
          {
            %{"source_operator_review_package" => package},
            "source_operator_review_package.rows.source_provider_counteroffer",
            ["counterparty_provider", "operator_review_queue"]
          },
          {
            %{"source_cadence_import_manifest" => manifest},
            "source_cadence_import_manifest.rows.source_provider_counteroffer",
            ["counterparty_provider"]
          }
        ] do
      artifact =
        result_set()
        |> CandidateRefresh.build(
          candidate_refresh: Map.merge(refresh_request(), source),
          generated_at: ~U[2026-05-14 00:00:00Z]
        )

      assert %{
               "paths" => [^expected_path],
               "contract" => "provider_counteroffer_report.v1",
               "count" => 1,
               "row_count" => 1,
               "reviewable_count" => 1,
               "counteroffer_cost_delta_count" => 1,
               "counteroffer_cost_delta_total" => 40.0,
               "counteroffer_timing_shift_count" => 1,
               "counteroffer_start_delta_count" => 1,
               "counteroffer_end_delta_count" => 1,
               "counteroffer_duration_delta_count" => 1,
               "counteroffer_lock_deadline_count" => 1,
               "earliest_counteroffer_lock_deadline_s" => 360.0,
               "counteroffer_status_counts" => %{"proposed" => 1},
               "required_operator_action_counts" => %{"review_provider_counteroffer" => 1},
               "trust_boundary_status" => "declared",
               "trust_boundaries" => ^expected_trust_boundaries
             } =
               get_in(artifact, ["provenance", "source_reports", "provider_counteroffer_report"])

      assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
               Schema.validate_artifact(artifact)
    end
  end

  test "summarizes provider-counteroffer plan-impact summaries as source report provenance" do
    counteroffer_report = %{
      "schema_contract" => "provider_counteroffer_report.v1",
      "source" => "station_calendar_report.affected_contacts",
      "source_artifact_type" => "station_calendar_report.v1",
      "counteroffer_count" => 1,
      "reviewable_count" => 1,
      "counteroffer_cost_delta_count" => 1,
      "counteroffer_cost_delta_total" => 75.0,
      "counteroffer_lock_deadline_count" => 1,
      "rows" => [
        %{
          "id" => "provider_counteroffer:impact:counteroffer_1",
          "provider_counteroffer_id" => "counteroffer_1",
          "provider_counteroffer_status" => "proposed",
          "provider_counteroffer_negotiation_state" => "counteroffered",
          "provider_counteroffer_cost_delta" => 75.0,
          "provider_counteroffer_lock_deadline_s" => 360.0,
          "provider_counteroffer_starts_at_s" => 145.0,
          "provider_counteroffer_ends_at_s" => 230.0,
          "starts_at_s" => 100.0,
          "ends_at_s" => 200.0,
          "station_calendar_entry_id" => "contact_original",
          "station_calendar_provider_entry_id" => "provider_offer_1",
          "reviewable" => true,
          "required_operator_action" => "review_provider_counteroffer",
          "trust_boundary" => "counterparty_provider",
          "source_station_calendar_entry" => %{
            "id" => "contact_original",
            "trust_boundary" => "provider_calendar_feed"
          }
        }
      ]
    }

    plan_impact_summary =
      OrbitalDynamics.provider_counteroffer_plan_impact_summary(counteroffer_report,
        now_s: 120.0
      )

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("mission_state", %{
            "source_provider_counteroffer_plan_impact_summary" => plan_impact_summary
          }),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert %{
             "paths" => ["mission_state.source_provider_counteroffer_plan_impact_summary"],
             "contract" => "provider_counteroffer_plan_impact_summary.v1",
             "count" => 1,
             "row_count" => 1,
             "reviewable_count" => 1,
             "counteroffer_cost_delta_count" => 1,
             "counteroffer_cost_delta_total" => 75.0,
             "counteroffer_timing_shift_count" => 1,
             "counteroffer_start_delta_count" => 1,
             "counteroffer_end_delta_count" => 1,
             "counteroffer_duration_delta_count" => 1,
             "counteroffer_lock_deadline_count" => 1,
             "counteroffer_lock_deadline_status_counts" => %{"active" => 1},
             "counteroffer_ids_by_lock_deadline_status" => %{
               "active" => ["counteroffer_1"]
             },
             "earliest_counteroffer_lock_deadline_s" => 360.0,
             "plan_impact_summary_count" => 1,
             "plan_impact_status_counts" => %{"review_required" => 1},
             "affected_station_calendar_entry_ids" => ["contact_original"],
             "affected_provider_entry_ids" => ["provider_offer_1"],
             "impact_counteroffer_ids" => ["counteroffer_1"],
             "timing_shift_counteroffer_ids" => ["counteroffer_1"],
             "cost_delta_counteroffer_ids" => ["counteroffer_1"],
             "counteroffer_status_counts" => %{"proposed" => 1},
             "required_operator_action_counts" => %{"review_provider_counteroffer" => 1},
             "review_counteroffer_ids" => [],
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["provider_calendar_feed"]
           } =
             get_in(artifact, ["provenance", "source_reports", "provider_counteroffer_report"])

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "summarizes provider-counteroffer import-readiness summaries as source report provenance" do
    counteroffer_report = %{
      "schema_contract" => "provider_counteroffer_report.v1",
      "source" => "station_calendar_report.affected_contacts",
      "source_artifact_type" => "station_calendar_report.v1",
      "source_artifact_id" => "station_calendar_report_1",
      "counteroffer_count" => 2,
      "reviewable_count" => 1,
      "counteroffer_cost_delta_count" => 1,
      "counteroffer_cost_delta_total" => 75.0,
      "counteroffer_lock_deadline_count" => 1,
      "rows" => [
        %{
          "id" => "provider_counteroffer:import:counteroffer_review",
          "provider_counteroffer_id" => "counteroffer_review",
          "provider_counteroffer_status" => "proposed",
          "provider_counteroffer_negotiation_state" => "counteroffered",
          "provider_counteroffer_cost_delta" => 75.0,
          "provider_counteroffer_lock_deadline_s" => 360.0,
          "provider_counteroffer_starts_at_s" => 145.0,
          "provider_counteroffer_ends_at_s" => 230.0,
          "starts_at_s" => 100.0,
          "ends_at_s" => 200.0,
          "station_calendar_entry_id" => "contact_original",
          "station_calendar_provider_entry_id" => "provider_offer_1",
          "reviewable" => true,
          "required_operator_action" => "review_provider_counteroffer",
          "trust_boundary" => "counterparty_provider",
          "source_station_calendar_entry" => %{
            "id" => "contact_original",
            "trust_boundary" => "provider_calendar_feed"
          }
        },
        %{
          "id" => "provider_counteroffer:import:counteroffer_clear",
          "provider_counteroffer_id" => "counteroffer_clear",
          "provider_counteroffer_status" => "accepted",
          "provider_counteroffer_negotiation_state" => "accepted",
          "starts_at_s" => 300.0,
          "ends_at_s" => 360.0,
          "station_calendar_entry_id" => "contact_clear",
          "station_calendar_provider_entry_id" => "provider_offer_2",
          "reviewable" => false,
          "required_operator_action" => "none",
          "trust_boundary" => "provider_calendar_feed",
          "source_station_calendar_entry" => %{
            "id" => "contact_clear",
            "trust_boundary" => "provider_calendar_feed"
          }
        }
      ]
    }

    import_readiness_summary =
      counteroffer_report
      |> OrbitalDynamics.provider_counteroffer_import_readiness_summary(now_s: 120.0)
      |> Map.put("provenance", %{"trust_boundary" => "ops_import_readiness_summary"})

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("mission_state", %{
            "source_provider_counteroffer_import_readiness_summary" => import_readiness_summary
          }),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert %{
             "paths" => ["mission_state.source_provider_counteroffer_import_readiness_summary"],
             "contract" => "provider_counteroffer_import_readiness_summary.v1",
             "count" => 1,
             "row_count" => 2,
             "reviewable_count" => 1,
             "counteroffer_cost_delta_count" => 1,
             "counteroffer_cost_delta_total" => 75.0,
             "counteroffer_timing_shift_count" => 1,
             "counteroffer_start_delta_count" => 1,
             "counteroffer_end_delta_count" => 1,
             "counteroffer_duration_delta_count" => 1,
             "counteroffer_lock_deadline_count" => 1,
             "earliest_counteroffer_lock_deadline_s" => 360.0,
             "import_readiness_summary_count" => 1,
             "import_readiness_status_counts" => %{"review_required" => 1},
             "import_classification_counts" => %{"review_only" => 1},
             "provider_counteroffer_import_status_counts" => %{
               "not_applicable" => 1,
               "review_required_before_import" => 1
             },
             "counteroffer_lock_deadline_status_counts" => %{
               "active" => 1,
               "missing" => 1
             },
             "counteroffer_ids_by_import_status" => %{
               "not_applicable" => ["counteroffer_clear"],
               "review_required_before_import" => ["counteroffer_review"]
             },
             "counteroffer_ids_by_required_import_action" => %{
               "none" => ["counteroffer_clear"],
               "review_provider_counteroffer" => ["counteroffer_review"]
             },
             "counteroffer_ids_by_lock_deadline_status" => %{
               "active" => ["counteroffer_review"],
               "missing" => ["counteroffer_clear"]
             },
             "review_counteroffer_ids" => ["counteroffer_review"],
             "no_import_required_counteroffer_ids" => ["counteroffer_clear"],
             "counteroffer_status_counts" => %{"accepted" => 1, "proposed" => 1},
             "required_operator_action_counts" => %{
               "none" => 1,
               "review_provider_counteroffer" => 1
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["ops_import_readiness_summary", "provider_calendar_feed"]
           } =
             get_in(artifact, ["provenance", "source_reports", "provider_counteroffer_report"])

    assert %{
             "import_readiness_summary_count" => 1,
             "import_readiness_status_counts" => %{"review_required" => 1},
             "import_classification_counts" => %{"review_only" => 1},
             "provider_counteroffer_import_status_counts" => %{
               "not_applicable" => 1,
               "review_required_before_import" => 1
             },
             "counteroffer_ids_by_import_status" => %{
               "not_applicable" => ["counteroffer_clear"],
               "review_required_before_import" => ["counteroffer_review"]
             },
             "review_counteroffer_ids" => ["counteroffer_review"],
             "no_import_required_counteroffer_ids" => ["counteroffer_clear"],
             "branch_local_counteroffer_import_readiness_pressure" => true,
             "branch_local_counteroffer_pressure" => true
           } = CandidateRefresh.provider_counteroffer_replay_summary(artifact)

    assert %{
             "source_report_provider_counteroffer_import_readiness_summary_count" => 1,
             "source_report_provider_counteroffer_import_readiness_status_counts" => %{
               "review_required" => 1
             },
             "source_report_provider_counteroffer_import_classification_counts" => %{
               "review_only" => 1
             },
             "source_report_provider_counteroffer_import_status_counts" => %{
               "not_applicable" => 1,
               "review_required_before_import" => 1
             },
             "source_report_provider_counteroffer_counteroffer_ids_by_import_status" => %{
               "not_applicable" => ["counteroffer_clear"],
               "review_required_before_import" => ["counteroffer_review"]
             }
           } =
             CandidateRefresh.source_report_summary(%{
               "mission_state" => %{
                 "source_provider_counteroffer_import_readiness_summary" =>
                   import_readiness_summary
               }
             })

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
