defmodule OrbitalDynamics.CandidateRefresh.QualityGateUnavailableResourceReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{
    CadenceImport,
    CandidateRefresh,
    Epoch,
    OperatorReview,
    ResultSet,
    Schema
  }

  test "quality gate replay accepts operational unavailable-resource summaries" do
    unavailable_resource_summary =
      quality_gate_unavailable_resource_summary_fixture()
      |> Map.put("resource_availability_row_count", 99)

    refresh = %{
      "accepted_planning_state" => %{
        "operational_quality_gate_unavailable_resource_summary" => unavailable_resource_summary
      },
      "mission_state" => %{
        "source_operational_quality_gate_unavailable_resource_summary" =>
          unavailable_resource_summary
      },
      "source_operational_quality_gate_unavailable_resource_summary" =>
        unavailable_resource_summary
    }

    assert %{
             "source_report_family_count" => 1,
             "source_report_count" => 3,
             "source_report_row_count" => 3,
             "source_report_quality_gate_contract" => "quality_gate_report.v1",
             "source_report_quality_gate_count" => 3,
             "source_report_quality_gate_row_count" => 3,
             "source_report_quality_gate_paths" => [
               "accepted_planning_state.operational_quality_gate_unavailable_resource_summary",
               "mission_state.source_operational_quality_gate_unavailable_resource_summary",
               "source_operational_quality_gate_unavailable_resource_summary"
             ],
             "source_report_quality_gate_source_summary_model_counts" => %{
               "artifact_only_quality_gate_unavailable_resource_summary" => 3
             },
             "source_report_quality_gate_source_summary_schema_contract_counts" => %{
               "operational_quality_gate_unavailable_resource_summary.v1" => 3
             },
             "source_report_quality_gate_resource_availability_pressure_count" => 6,
             "source_report_quality_gate_resource_availability_reason_counts" => %{
               "ground_station_unavailable" => 3,
               "payload_unavailable" => 3
             },
             "source_report_quality_gate_station_availability_reason_ids" => [
               "ground_station_unavailable"
             ],
             "source_report_quality_gate_station_availability_reason_counts" => %{
               "ground_station_unavailable" => 3
             },
             "source_report_quality_gate_unavailable_resource_reason_ids" => [
               "payload_unavailable"
             ],
             "source_report_quality_gate_resource_blocking_dimension_counts" => %{
               "payload" => 3
             },
             "source_report_quality_gate_blocked_contact_ids_by_blocking_dimension" => %{
               "payload" => ["contact:payload_blocked"]
             },
             "source_report_quality_gate_blocked_contact_ids_by_spacecraft_id" => %{
               "leo_1" => ["contact:payload_blocked"]
             },
             "source_report_quality_gate_blocked_contact_ids_by_status" => %{
               "review_required" => ["contact:payload_blocked"]
             },
             "source_reports" => %{
               "quality_gate_report" => %{
                 "paths" => [
                   "accepted_planning_state.operational_quality_gate_unavailable_resource_summary",
                   "mission_state.source_operational_quality_gate_unavailable_resource_summary",
                   "source_operational_quality_gate_unavailable_resource_summary"
                 ],
                 "contract" => "quality_gate_report.v1",
                 "count" => 3,
                 "row_count" => 3,
                 "source_summary_schema_contract_counts" => %{
                   "operational_quality_gate_unavailable_resource_summary.v1" => 3
                 },
                 "resource_availability_reason_counts" => %{
                   "ground_station_unavailable" => 3,
                   "payload_unavailable" => 3
                 }
               }
             }
           } = source_report_summary = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "source_report_paths" => [
               "accepted_planning_state.operational_quality_gate_unavailable_resource_summary",
               "mission_state.source_operational_quality_gate_unavailable_resource_summary",
               "source_operational_quality_gate_unavailable_resource_summary"
             ],
             "source_report_row_count" => 3,
             "source_summary_model_counts" => %{
               "artifact_only_quality_gate_unavailable_resource_summary" => 3
             },
             "source_summary_schema_contract_counts" => %{
               "operational_quality_gate_unavailable_resource_summary.v1" => 3
             },
             "resource_availability_pressure_count" => 6,
             "resource_availability_reason_counts" => %{
               "ground_station_unavailable" => 3,
               "payload_unavailable" => 3
             },
             "resource_availability_reason_ids" => [
               "ground_station_unavailable",
               "payload_unavailable"
             ],
             "station_availability_reason_ids" => ["ground_station_unavailable"],
             "station_availability_reason_counts" => %{"ground_station_unavailable" => 3},
             "unavailable_resource_reason_ids" => ["payload_unavailable"],
             "resource_blocking_dimension_counts" => %{"payload" => 3},
             "blocked_contact_ids_by_blocking_dimension" => %{
               "payload" => ["contact:payload_blocked"]
             },
             "blocked_contact_ids_by_spacecraft_id" => %{
               "leo_1" => ["contact:payload_blocked"]
             },
             "blocked_contact_ids_by_status" => %{
               "review_required" => ["contact:payload_blocked"]
             },
             "review_required_quality_gate_row_ids" => [
               "quality_gate:activity_1:resource_availability"
             ],
             "branch_local_review_pressure" => true,
             "branch_local_import_pressure" => false,
             "branch_local_resource_pressure" => true
           } = replay_summary = CandidateRefresh.quality_gate_replay_summary(refresh)

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "provenance" => %{"source_reports" => source_report_summary["source_reports"]}
    }

    assert CandidateRefresh.quality_gate_replay_summary(artifact) == replay_summary
  end

  test "quality gate replay treats explicit empty unavailable-resource status maps as zero rows" do
    unavailable_resource_summary =
      quality_gate_unavailable_resource_summary_fixture()
      |> Map.merge(%{
        "resource_availability_row_count" => 99,
        "quality_gate_row_ids_by_status" => %{},
        "quality_gate_ids_by_status" => %{}
      })

    refresh = %{
      "source_operational_quality_gate_unavailable_resource_summary" =>
        unavailable_resource_summary
    }

    source_report_summary = CandidateRefresh.source_report_summary(refresh)

    assert %{
             "source_report_count" => 1,
             "source_report_row_count" => 0,
             "source_report_quality_gate_count" => 1,
             "source_report_quality_gate_row_count" => 0,
             "source_report_quality_gate_gate_count" => 0,
             "source_report_quality_gate_resource_availability_pressure_count" => 2,
             "source_report_quality_gate_resource_availability_reason_counts" => %{
               "ground_station_unavailable" => 1,
               "payload_unavailable" => 1
             },
             "source_reports" => %{
               "quality_gate_report" => %{
                 "row_count" => 0,
                 "gate_count" => 0,
                 "resource_availability_pressure_count" => 2
               }
             }
           } = source_report_summary

    assert Map.get(
             source_report_summary,
             "source_report_quality_gate_quality_gate_row_ids_by_status",
             %{}
           ) ==
             %{}

    replay_summary = CandidateRefresh.quality_gate_replay_summary(refresh)

    assert %{
             "source_report_count" => 1,
             "source_report_row_count" => 0,
             "gate_count" => 0,
             "resource_availability_pressure_count" => 2,
             "branch_local_resource_pressure" => true
           } = replay_summary

    assert Map.get(replay_summary, "quality_gate_row_ids_by_status", %{}) == %{}
    assert Map.get(replay_summary, "review_required_quality_gate_row_ids", []) == []
  end

  test "explicit spacecraft-scoped unavailable-resource contact ids filter regenerated contacts" do
    blocked_contact_id = "leo_1_downlink_equator_prime_1"

    unavailable_resource_summary =
      quality_gate_unavailable_resource_summary_fixture()
      |> Map.merge(%{
        "blocked_contact_ids_by_blocking_dimension" => %{
          "payload" => [blocked_contact_id]
        },
        "blocked_contact_ids_by_spacecraft_id" => %{
          "sat_1" => [blocked_contact_id]
        },
        "blocked_contact_ids_by_status" => %{
          "review_required" => [blocked_contact_id]
        }
      })

    assert {:ok,
            %{"schema_contract" => "operational_quality_gate_unavailable_resource_summary.v1"}} =
             Schema.validate_artifact(unavailable_resource_summary)

    prior_contact = %{
      "id" => blocked_contact_id,
      "type" => "downlink",
      "scenario_id" => "leo_1",
      "ground_station_id" => "equator_prime",
      "starts_at_s" => 300.0,
      "ends_at_s" => 420.0,
      "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1"
    }

    refresh =
      refresh_request()
      |> put_in(
        ["accepted_planning_state", "operational_quality_gate_unavailable_resource_summary"],
        unavailable_resource_summary
      )
      |> Map.put("prior_candidate_activities", [prior_contact])

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_observe_target_a_1"
           ]

    assert %{
             "schema_contract" => "candidate_rejection_report.v1",
             "source" =>
               "candidate_refresh.operational_quality_gate_unavailable_resource_summary",
             "candidate_count" => 2,
             "rejected_count" => 1,
             "not_rejected_count" => 1,
             "rejected_candidate_ids" => [^blocked_contact_id],
             "not_rejected_candidate_ids" => ["leo_1_observe_target_a_1"],
             "rejection_reason_counts" => %{"quality_gate_failed" => 1}
           } = rejection_report = artifact["candidate_rejection_report"]

    assert %{
             "candidate_id" => ^blocked_contact_id,
             "rejection_status" => "rejected",
             "rejection_reasons" => ["quality_gate_failed"],
             "activity_context" => %{
               "provenance" => %{
                 "quality_gate_candidate_filter" => %{
                   "source_summary_schema_contract" =>
                     "operational_quality_gate_unavailable_resource_summary.v1",
                   "source_report_paths" => [
                     "accepted_planning_state.operational_quality_gate_unavailable_resource_summary"
                   ],
                   "blocked_spacecraft_ids" => ["sat_1"]
                 }
               }
             }
           } = Enum.find(rejection_report["rows"], &(&1["candidate_id"] == blocked_contact_id))

    assert [
             %{
               "id" => ^blocked_contact_id,
               "invalidated_reason" => "dropped_by_quality_gate_unavailable_resource",
               "replacement_candidate_id" => ^blocked_contact_id
             }
           ] = artifact["invalidated_candidates"]

    assert "unavailable-resource quality gates excluded explicitly scoped contact candidates" in artifact[
             "warnings"
           ]

    review = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "review_type" => "candidate_rejection_review",
             "candidate_id" => ^blocked_contact_id,
             "source" => "candidate_refresh.candidate_rejection_report.rows"
           } = Enum.find(review["rows"], &(&1["candidate_id"] == blocked_contact_id))

    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_review_type" => "candidate_rejection_review",
             "subject_id" => ^blocked_contact_id,
             "source_candidate_rejection" => %{"candidate_id" => ^blocked_contact_id}
           } =
             Enum.find(
               import["rows"],
               &(&1["subject_id"] == blocked_contact_id and
                   &1["source_review_type"] == "candidate_rejection_review")
             )

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "candidate_rejection_report.v1"}} =
             Schema.validate_artifact(rejection_report)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end

  test "stale unavailable-resource summary lineage remains provenance-only" do
    blocked_contact_id = "leo_1_downlink_equator_prime_1"

    stale_summary =
      quality_gate_unavailable_resource_summary_fixture()
      |> Map.put(
        "source_quality_gate_report_id",
        "quality_gate:contact_filter_report.v1:stale_filter"
      )
      |> put_in(
        ["blocked_contact_ids_by_blocking_dimension"],
        %{"payload" => [blocked_contact_id]}
      )
      |> put_in(
        ["blocked_contact_ids_by_spacecraft_id"],
        %{"sat_1" => [blocked_contact_id]}
      )
      |> put_in(
        ["blocked_contact_ids_by_status"],
        %{"review_required" => [blocked_contact_id]}
      )

    assert {:error, %{"errors" => errors}} = Schema.validate_artifact(stale_summary)

    assert Enum.any?(
             errors,
             &(&1["path"] == "$.source_quality_gate_report_id" and
                 &1["message"] == "must match source artifact identity")
           )

    prior_contact = %{
      "id" => blocked_contact_id,
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
          |> put_in(
            ["accepted_planning_state", "operational_quality_gate_unavailable_resource_summary"],
            stale_summary
          )
          |> Map.put("prior_candidate_activities", [prior_contact]),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_observe_target_a_1",
             blocked_contact_id
           ]

    refute Map.has_key?(artifact, "candidate_rejection_report")

    assert %{
             "source_summary_schema_contract_counts" => %{
               "operational_quality_gate_unavailable_resource_summary.v1" => 1
             }
           } = get_in(artifact, ["provenance", "source_reports", "quality_gate_report"])

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "aggregate pressure and contact ids under another spacecraft do not filter candidates" do
    unavailable_resource_summary =
      quality_gate_unavailable_resource_summary_fixture()
      |> Map.merge(%{
        "blocked_contact_ids_by_blocking_dimension" => %{
          "payload" => ["leo_1_downlink_equator_prime_1"]
        },
        "blocked_contact_ids_by_spacecraft_id" => %{
          "sat_2" => ["leo_1_downlink_equator_prime_1"]
        },
        "blocked_contact_ids_by_status" => %{
          "review_required" => ["leo_1_downlink_equator_prime_1"]
        }
      })

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put(
            "source_operational_quality_gate_unavailable_resource_summary",
            unavailable_resource_summary
          ),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_observe_target_a_1",
             "leo_1_downlink_equator_prime_1"
           ]

    assert %{
             "candidate_count" => 2,
             "rejected_count" => 0,
             "not_rejected_count" => 2,
             "rejected_candidate_ids" => []
           } = artifact["candidate_rejection_report"]

    refute "unavailable-resource quality gates excluded explicitly scoped contact candidates" in artifact[
             "warnings"
           ]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "refreshes without unavailable-resource summaries do not add a rejection report" do
    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh: refresh_request(),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    refute Map.has_key?(artifact, "candidate_rejection_report")
  end

  test "quality gate replay accepts wrapped operational unavailable-resource summaries" do
    unavailable_resource_summary = quality_gate_unavailable_resource_summary_fixture()

    wrapper = %{
      "schema_contract" => "result_artifact.v1",
      "provenance" => %{"trust_boundary" => "unavailable_resource_adapter"},
      "source_operational_quality_gate_unavailable_resource_summary" =>
        unavailable_resource_summary
    }

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_result_artifact", [wrapper]),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert %{
             "paths" => [
               "source_result_artifact[0].source_operational_quality_gate_unavailable_resource_summary"
             ],
             "source_summary_schema_contract_counts" => %{
               "operational_quality_gate_unavailable_resource_summary.v1" => 1
             },
             "resource_availability_reason_counts" => %{
               "ground_station_unavailable" => 1,
               "payload_unavailable" => 1
             },
             "blocked_contact_ids_by_spacecraft_id" => %{
               "leo_1" => ["contact:payload_blocked"]
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => [
               "unavailable_resource_adapter",
               "unavailable_resource_summary_fixture"
             ]
           } = get_in(artifact, ["provenance", "source_reports", "quality_gate_report"])

    assert %{
             "source_report_paths" => [
               "source_result_artifact[0].source_operational_quality_gate_unavailable_resource_summary"
             ],
             "source_summary_schema_contract_counts" => %{
               "operational_quality_gate_unavailable_resource_summary.v1" => 1
             },
             "resource_availability_reason_counts" => %{
               "ground_station_unavailable" => 1,
               "payload_unavailable" => 1
             },
             "blocked_contact_ids_by_spacecraft_id" => %{
               "leo_1" => ["contact:payload_blocked"]
             },
             "branch_local_resource_pressure" => true
           } = CandidateRefresh.quality_gate_replay_summary(artifact)

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

  defp quality_gate_unavailable_resource_summary_fixture do
    %{
      "schema_contract" => "operational_quality_gate_unavailable_resource_summary.v1",
      "model" => "artifact_only_quality_gate_unavailable_resource_summary",
      "source" => "quality_gate_report.v1",
      "source_artifact_type" => "contact_filter_report.v1",
      "source_artifact_id" => "contact_filter:payload_blocked",
      "source_quality_gate_report_id" =>
        "quality_gate:contact_filter_report.v1:contact_filter:payload_blocked",
      "source_readiness_report_id" =>
        "operational_readiness:contact_filter_report.v1:contact_filter:payload_blocked",
      "resource_availability_row_count" => 1,
      "unavailable_resource_row_count" => 1,
      "unavailable_resource_pressure_count" => 1,
      "unavailable_resource_reason_counts" => %{"payload_unavailable" => 1},
      "unavailable_resource_reason_ids" => ["payload_unavailable"],
      "station_availability_reason_counts" => %{"ground_station_unavailable" => 1},
      "station_availability_reason_ids" => ["ground_station_unavailable"],
      "resource_blocking_dimension_counts" => %{"payload" => 1},
      "blocked_contact_ids_by_blocking_dimension" => %{
        "payload" => ["contact:payload_blocked"]
      },
      "blocked_contact_ids_by_spacecraft_id" => %{
        "leo_1" => ["contact:payload_blocked"]
      },
      "blocked_contact_ids_by_status" => %{
        "review_required" => ["contact:payload_blocked"]
      },
      "quality_gate_row_ids_by_status" => %{
        "review_required" => ["quality_gate:activity_1:resource_availability"]
      },
      "quality_gate_ids_by_status" => %{"review_required" => ["resource_availability"]},
      "review_required_quality_gate_row_ids" => [
        "quality_gate:activity_1:resource_availability"
      ],
      "blocked_quality_gate_row_ids" => [],
      "resource_availability_gate_ids" => ["resource_availability"],
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_cadence_write",
        "source" => "quality_gate_report.v1",
        "operator_authority" => "not_granted_by_unavailable_resource_summary",
        "cadence_write" => "not_performed_by_summary",
        "command_execution" => "not_performed_by_summary"
      },
      "model_limits" => [
        "quality_gate_unavailable_resource_summary_routes_only",
        "quality_gate_unavailable_resource_summary_does_not_approve_or_import"
      ],
      "provenance" => %{"trust_boundary" => "unavailable_resource_summary_fixture"}
    }
  end
end
