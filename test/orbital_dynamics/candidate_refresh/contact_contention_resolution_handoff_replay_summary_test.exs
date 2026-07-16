defmodule OrbitalDynamics.CandidateRefresh.ContactContentionResolutionHandoffReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{
    CadenceImport,
    CandidateRefresh,
    Epoch,
    OperatorReview,
    ResultSet,
    Schema
  }

  test "derives downlink completion objectives from source contact contention resolution reports" do
    report = %{
      "schema_contract" => "contact_contention_resolution_report.v1",
      "recommendations" => [
        %{
          "group_id" => "station:equator_prime:contention:prior",
          "ground_station_id" => "equator_prime",
          "selected_contact_id" => "dl_selected",
          "deferred_contact_ids" => ["dl_deferred"],
          "selection_reason" => "highest_score_earliest_start",
          "source_contact_candidates" => [
            %{
              "id" => "dl_deferred",
              "type" => "downlink",
              "spacecraft_id" => "sat_1",
              "ground_station_id" => "equator_prime",
              "required_downlink_mb" => 420.0,
              "source_window_id" => "window_deferred",
              "trust_boundary" => "cadence_ops"
            }
          ]
        }
      ]
    }

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_contact_contention_resolution_report", report),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 420.0
    assert downlink["selected_downlink_shortfall_mb"] == 60.0

    assert downlink["downlink_completion_source"] ==
             "candidate_refresh.objectives.downlink_completion"

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "replays contact contention resolution pressure from result artifact wrappers" do
    report = %{
      "schema_contract" => "contact_contention_resolution_report.v1",
      "recommendations" => [
        %{
          "group_id" => "station:equator_prime:contention:prior",
          "ground_station_id" => "equator_prime",
          "selected_contact_id" => "dl_selected",
          "deferred_contact_ids" => ["dl_deferred"],
          "required_downlink_mb" => 420.0
        }
      ]
    }

    wrapper = %{
      "schema_contract" => "result_artifact.v1",
      "contact_contention_resolution_report" => report,
      "provenance" => %{"trust_boundary" => "mission_planning"}
    }

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_result_artifact", wrapper),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 420.0
    assert downlink["selected_downlink_shortfall_mb"] == 60.0

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "replays contact contention resolution pressure from operator review packages" do
    report = %{
      "schema_contract" => "contact_contention_resolution_report.v1",
      "recommendations" => [
        %{
          "group_id" => "station:equator_prime:contention:prior",
          "ground_station_id" => "equator_prime",
          "selected_contact_id" => "dl_selected",
          "deferred_contact_ids" => ["dl_deferred"],
          "required_downlink_mb" => 420.0
        }
      ]
    }

    package = OperatorReview.from_contact_contention_resolution_report(report)

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_operator_review_package", package),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 420.0
    assert downlink["selected_downlink_shortfall_mb"] == 60.0

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "replays contact contention resolution pressure from Cadence import manifests" do
    report = %{
      "schema_contract" => "contact_contention_resolution_report.v1",
      "recommendations" => [
        %{
          "group_id" => "station:equator_prime:contention:prior",
          "ground_station_id" => "equator_prime",
          "selected_contact_id" => "dl_selected",
          "deferred_contact_ids" => ["dl_deferred"],
          "required_downlink_mb" => 420.0
        }
      ]
    }

    manifest = CadenceImport.from_contact_contention_resolution_report(report)

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_cadence_import_manifest", manifest),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 420.0
    assert downlink["selected_downlink_shortfall_mb"] == 60.0

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "operator review and import lift contact contention resolution summaries from candidate refresh artifacts" do
    resolution_summary = fn source,
                            group_id,
                            station_id,
                            selected_contact_id,
                            deferred_contact_id ->
      %{
        "schema_contract" => "contact_contention_resolution_summary.v1",
        "model" => "artifact_only_contact_contention_resolution_summary",
        "source_artifact_type" => "contact_contention_resolution_report.v1",
        "source" => source,
        "conflict_group_count" => 1,
        "recommendation_count" => 1,
        "recommendation_group_ids" => [group_id],
        "review_group_ids" => [group_id],
        "selected_contact_ids" => [selected_contact_id],
        "selected_contact_ids_by_group_id" => %{group_id => [selected_contact_id]},
        "deferred_contact_ids" => [deferred_contact_id],
        "deferred_contact_ids_by_group_id" => %{group_id => [deferred_contact_id]},
        "review_contact_ids" => [deferred_contact_id, selected_contact_id],
        "review_contact_ids_by_group_id" => %{
          group_id => [deferred_contact_id, selected_contact_id]
        },
        "review_recommendation_count" => 1,
        "ground_station_ids_by_group_id" => %{group_id => [station_id]},
        "resource_scopes_by_group_id" => %{group_id => ["ground_station"]},
        "selection_reason_counts" => %{"highest_score_earliest_start" => 1},
        "selection_reasons_by_group_id" => %{group_id => ["highest_score_earliest_start"]},
        "selected_contact_ids_by_selection_reason" => %{
          "highest_score_earliest_start" => [selected_contact_id]
        },
        "action_counts" => %{"recommend_preferred_contact_for_operator_review" => 1},
        "actions_by_group_id" => %{
          group_id => ["recommend_preferred_contact_for_operator_review"]
        },
        "review_contact_ids_by_action" => %{
          "recommend_preferred_contact_for_operator_review" => [
            deferred_contact_id,
            selected_contact_id
          ]
        },
        "capacity_pack_required_capacity_fraction" => 0.55,
        "capacity_pack_selected_required_capacity_fraction" => 0.2,
        "capacity_pack_deferred_required_capacity_fraction" => 0.35,
        "capacity_pack_required_capacity_fraction_by_status" => %{
          "deferred" => 0.35,
          "selected" => 0.2
        },
        "capacity_pack_required_capacity_fraction_by_ground_station_id" => %{
          station_id => 0.55
        },
        "required_capacity_fraction_source_counts" => %{
          "source_contact_candidate.required_capacity_fraction" => 2
        },
        "assumptions" => %{
          "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation",
          "candidate_mutation" => "none",
          "operator_authority" => "not_granted_by_summary",
          "cadence_write" => "not_performed_by_summary"
        },
        "provenance" => %{"trust_boundary" => source}
      }
    end

    direct_summary =
      resolution_summary.(
        "unit_test.contact_contention_resolution.direct",
        "station:direct:contention:1",
        "direct_station",
        "direct_selected",
        "direct_deferred"
      )

    canonical_summary =
      resolution_summary.(
        "unit_test.contact_contention_resolution.canonical",
        "station:canonical:contention:1",
        "canonical_station",
        "canonical_selected",
        "canonical_deferred"
      )

    wrapped_summary =
      resolution_summary.(
        "unit_test.contact_contention_resolution.wrapped",
        "station:wrapped:contention:1",
        "wrapped_station",
        "wrapped_selected",
        "wrapped_deferred"
      )

    nested_summary =
      resolution_summary.(
        "unit_test.contact_contention_resolution.nested",
        "station:nested:contention:1",
        "nested_station",
        "nested_selected",
        "nested_deferred"
      )

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:contact_contention_resolution_summary_handoff",
      "source_contact_contention_resolution_summary" => [direct_summary],
      "contact_contention_resolution_summary" => canonical_summary,
      "source_result_artifact" => [
        wrapped_summary,
        %{
          "schema_contract" => "result_artifact.v1",
          "contact_contention_resolution_summary" => nested_summary
        }
      ]
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    recommendation_rows =
      Enum.filter(review["rows"], &(&1["review_type"] == "contact_contention_recommendation"))

    assert length(recommendation_rows) == 4

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" =>
               "candidate_refresh:contact_contention_resolution_summary_handoff",
             "contention_recommendation_count" => 4,
             "review_type_counts" => %{"contact_contention_recommendation" => 4}
           } = review

    assert Enum.sort(Enum.map(recommendation_rows, & &1["source"])) == [
             "candidate_refresh.contact_contention_resolution_summary.summary_recommendations",
             "candidate_refresh.source_contact_contention_resolution_summary[0].summary_recommendations",
             "candidate_refresh.source_result_artifact[0].summary_recommendations",
             "candidate_refresh.source_result_artifact[1].contact_contention_resolution_summary.summary_recommendations"
           ]

    assert Enum.any?(
             recommendation_rows,
             &match?(
               %{
                 "source" =>
                   "candidate_refresh.contact_contention_resolution_summary.summary_recommendations",
                 "subject_id" => "station:canonical:contention:1",
                 "ground_station_id" => "canonical_station",
                 "selected_contact_id" => "canonical_selected",
                 "selected_contact_ids" => ["canonical_selected"],
                 "deferred_contact_ids" => ["canonical_deferred"],
                 "review_contact_ids" => ["canonical_deferred", "canonical_selected"],
                 "candidate_count" => 2,
                 "selection_reason" => "highest_score_earliest_start",
                 "capacity_pack_required_capacity_fraction" => 0.55,
                 "capacity_pack_selected_required_capacity_fraction" => 0.2,
                 "capacity_pack_deferred_required_capacity_fraction" => 0.35,
                 "source_summary_schema_contract" => "contact_contention_resolution_summary.v1",
                 "source_contact_contention_resolution_summary" => %{
                   "schema_contract" => "contact_contention_resolution_summary.v1",
                   "source" => "unit_test.contact_contention_resolution.canonical",
                   "recommendation_count" => 1
                 },
                 "source_recommendation" => %{
                   "schema_contract" => "contact_contention_resolution_summary.v1",
                   "source_contact_contention_resolution_summary" => %{
                     "schema_contract" => "contact_contention_resolution_summary.v1"
                   }
                 }
               },
               &1
             )
           )

    import_rows =
      Enum.filter(
        import["rows"],
        &(&1["source_review_type"] == "contact_contention_recommendation")
      )

    assert length(import_rows) == 4

    assert %{
             "import_action_counts" => %{"review_contact_contention_resolution" => 4},
             "source_review_type_counts" => %{"contact_contention_recommendation" => 4}
           } = import

    assert Enum.all?(
             import_rows,
             &(&1["import_action"] == "review_contact_contention_resolution" and
                 &1["source_contact_contention_resolution_summary"]["schema_contract"] ==
                   "contact_contention_resolution_summary.v1" and
                 &1["source_review_row"]["source_contact_contention_resolution_summary"][
                   "schema_contract"
                 ] == "contact_contention_resolution_summary.v1")
           )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
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
