defmodule OrbitalDynamics.CandidateRefresh.OperationalReadinessReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{
    CadenceImport,
    CandidateRefresh,
    Epoch,
    OperationalReadiness,
    OperatorReview,
    ResultSet,
    Schema
  }

  test "replays operational-readiness source reports from review and import containers" do
    readiness_report = %{
      "schema_contract" => "operational_readiness_report.v1",
      "schema_version" => 1,
      "model" => "artifact_only_operational_readiness_classifier",
      "report_id" => "operational_readiness:contact_allocation_report.v1:allocation_1",
      "source_artifact_type" => "contact_allocation_report.v1",
      "source_artifact_id" => "allocation_1",
      "readiness_level" => "operator_review",
      "import_classification" => "review_only",
      "status" => "review_required",
      "gate_count" => 4,
      "passed_gate_count" => 2,
      "review_gate_count" => 2,
      "analysis_gate_count" => 0,
      "blocked_gate_count" => 0,
      "gates" => [
        %{
          "id" => "operator_review",
          "status" => "review_required",
          "classification" => "review_only",
          "reason" => "operator review required"
        }
      ],
      "evidence" => %{
        "review_required_count" => 1,
        "ready_for_import_count" => 0,
        "manifest_review_required_count" => 1,
        "missing_import_count" => 1,
        "stale_freshness_count" => 1,
        "freshness_status_counts" => %{"stale" => 1},
        "schema_validation_fail_count" => 1,
        "schema_validation_error_count" => 1,
        "schema_validation_status_counts" => %{"fail" => 1},
        "import_status_counts" => %{"review_required_before_import" => 1},
        "cadence_import_status_counts" => %{"missing" => 1},
        "review_type_counts" => %{"contact_allocation_review" => 1},
        "import_action_counts" => %{"review_contact_allocation" => 1},
        "source_review_type_counts" => %{"contact_allocation_review" => 1}
      },
      "provenance" => %{"trust_boundary" => "readiness_report"}
    }

    package = OperatorReview.from_operational_readiness_report(readiness_report)
    manifest = CadenceImport.from_operational_readiness_report(readiness_report)

    for {source, expected_path, expected_trust_boundary_status, expected_trust_boundaries} <- [
          {%{"source_operator_review_package" => package},
           "source_operator_review_package.rows.source_operational_readiness_report", "declared",
           ["readiness_report"]},
          {%{"source_cadence_import_manifest" => manifest},
           "source_cadence_import_manifest.rows.source_operational_readiness_report", "missing",
           []}
        ] do
      artifact =
        result_set()
        |> CandidateRefresh.build(
          candidate_refresh: Map.merge(refresh_request(), source),
          generated_at: ~U[2026-05-14 00:00:00Z]
        )

      assert %{
               "paths" => [^expected_path],
               "contract" => "operational_readiness_report.v1",
               "count" => 1,
               "row_count" => 1,
               "readiness_level_counts" => %{"operator_review" => 1},
               "import_classification_counts" => %{"review_only" => 1},
               "status_counts" => %{"review_required" => 1},
               "gate_count" => 4,
               "review_gate_count" => 2,
               "ready_for_import_count" => 0,
               "manifest_review_required_count" => 1,
               "missing_import_count" => 1,
               "review_required_count" => 1,
               "stale_freshness_count" => 1,
               "freshness_status_counts" => %{"stale" => 1},
               "schema_validation_fail_count" => 1,
               "schema_validation_error_count" => 1,
               "schema_validation_status_counts" => %{"fail" => 1},
               "import_status_counts" => %{"review_required_before_import" => 1},
               "cadence_import_status_counts" => %{"missing" => 1},
               "review_type_counts" => %{"contact_allocation_review" => 1},
               "import_action_counts" => %{"review_contact_allocation" => 1},
               "source_review_type_counts" => %{"contact_allocation_review" => 1},
               "trust_boundary_status" => ^expected_trust_boundary_status,
               "trust_boundaries" => ^expected_trust_boundaries
             } =
               get_in(artifact, [
                 "provenance",
                 "source_reports",
                 "operational_readiness_report"
               ])

      assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
               Schema.validate_artifact(artifact)

      invalid_source_report_count =
        put_in(
          artifact,
          [
            "provenance",
            "source_reports",
            "operational_readiness_report",
            "freshness_status_counts",
            "stale"
          ],
          -1
        )

      assert {:error, invalid_source_report_count_report} =
               Schema.validate_artifact(invalid_source_report_count)

      assert Enum.any?(
               invalid_source_report_count_report["errors"],
               &(&1["path"] ==
                   "$.provenance.source_reports.operational_readiness_report.freshness_status_counts.stale")
             )
    end
  end

  test "canonical readiness blocked-contact evidence filters only the scoped regenerated contact" do
    blocked_contact_id = "leo_1_downlink_equator_prime_1"

    review_source = %{
      "schema_contract" => "operator_review_package.v1",
      "source_artifact_type" => "contact_allocation_report.v1",
      "package_id" => "allocation_resource_review",
      "rows" => [
        %{
          "id" => "operator_review:contact_allocation:#{blocked_contact_id}",
          "review_type" => "contact_allocation_review",
          "approval_status" => "operator_review_required",
          "source_contact_allocation" => %{
            "contact_id" => blocked_contact_id,
            "type" => "downlink",
            "spacecraft_id" => "sat_1",
            "ground_station_id" => "equator_prime",
            "starts_at_s" => 300.0,
            "ends_at_s" => 420.0,
            "allocation_status" => "blocked",
            "allocation_reason" => "antenna_unavailable",
            "source_resource_suppression" => %{
              "id" => blocked_contact_id,
              "type" => "downlink",
              "spacecraft_id" => "sat_1",
              "suppressed_reason" => "antenna_unavailable",
              "resource_blocking_dimension" => "antenna",
              "antenna_available" => false,
              "resource_source_quality" => "operator_supplied",
              "resource_trust_boundary_status" => "declared"
            }
          }
        }
      ]
    }

    readiness_report =
      review_source
      |> OperationalReadiness.report()
      |> Map.put("provenance", %{"trust_boundary" => "canonical_readiness"})

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
        ["accepted_planning_state", "source_operational_readiness_report"],
        readiness_report
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
             "source" => "candidate_refresh.operational_readiness_unavailable_resource",
             "candidate_count" => 2,
             "rejected_count" => 1,
             "rejected_candidate_ids" => [^blocked_contact_id],
             "rejection_reason_counts" => %{"quality_gate_failed" => 1}
           } = rejection_report = artifact["candidate_rejection_report"]

    assert %{
             "candidate_id" => ^blocked_contact_id,
             "activity_context" => %{
               "provenance" => %{
                 "operational_readiness_candidate_filter" => %{
                   "source_schema_contract" => "operational_readiness_report.v1",
                   "source_report_paths" => [
                     "accepted_planning_state.source_operational_readiness_report"
                   ],
                   "source_artifact_ids" => ["allocation_resource_review"],
                   "blocked_spacecraft_ids" => ["sat_1"],
                   "trust_boundaries" => ["canonical_readiness"]
                 }
               }
             }
           } = Enum.find(rejection_report["rows"], &(&1["candidate_id"] == blocked_contact_id))

    assert [
             %{
               "id" => ^blocked_contact_id,
               "invalidated_reason" => "dropped_by_operational_readiness_unavailable_resource",
               "replacement_candidate_id" => ^blocked_contact_id
             }
           ] = artifact["invalidated_candidates"]

    assert "operational readiness excluded explicitly scoped unavailable-resource contact candidates" in artifact[
             "warnings"
           ]

    assert {:ok, %{"schema_contract" => "operational_readiness_report.v1"}} =
             Schema.validate_artifact(readiness_report)

    assert {:ok, %{"schema_contract" => "candidate_rejection_report.v1"}} =
             Schema.validate_artifact(rejection_report)

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

  test "source report summaries separate station and unavailable readiness reasons" do
    reason_counts = %{"ground_station_reserved" => 1, "payload_unavailable" => 1}

    readiness_report = %{
      "schema_contract" => "operational_readiness_report.v1",
      "readiness_level" => "operator_review",
      "import_classification" => "review_only",
      "status" => "review_required",
      "gates" => [
        %{
          "id" => "resource_availability",
          "status" => "review_required",
          "classification" => "review_only",
          "reason" => "resource availability requires review",
          "resource_availability_pressure_count" => 2,
          "resource_availability_reason_counts" => reason_counts,
          "station_availability_reason_ids" => ["ground_station_reserved"],
          "unavailable_resource_reason_ids" => ["payload_unavailable"]
        }
      ],
      "evidence" => %{
        "resource_availability_pressure_count" => 2,
        "resource_availability_reason_counts" => reason_counts
      },
      "provenance" => %{"trust_boundary" => "mission_state_readiness"}
    }

    quality_gate_report = %{
      "schema_contract" => "quality_gate_report.v1",
      "readiness_level" => "operator_review",
      "import_classification" => "review_only",
      "status" => "review_required",
      "gate_count" => 1,
      "review_gate_count" => 1,
      "rows" => [
        %{
          "id" => "quality_gate:activity_1:resource_availability:1",
          "rank" => 1,
          "gate_id" => "resource_availability",
          "status" => "review_required",
          "classification" => "review_only",
          "reason" => "resource availability requires review",
          "resource_availability_pressure_count" => 2,
          "resource_availability_reason_counts" => reason_counts,
          "station_availability_reason_ids" => ["ground_station_reserved"],
          "unavailable_resource_reason_ids" => ["payload_unavailable"]
        }
      ],
      "provenance" => %{"trust_boundary" => "mission_state_quality_gate"}
    }

    summary =
      CandidateRefresh.source_report_summary(%{
        "mission_state" => %{
          "source_operational_readiness_report" => readiness_report,
          "source_quality_gate_report" => quality_gate_report
        }
      })

    assert %{
             "source_reports" => %{
               "operational_readiness_report" => %{
                 "resource_availability_reason_counts" => ^reason_counts,
                 "resource_availability_reason_ids" => [
                   "ground_station_reserved",
                   "payload_unavailable"
                 ],
                 "station_availability_reason_ids" => ["ground_station_reserved"],
                 "station_availability_reason_counts" => %{"ground_station_reserved" => 1},
                 "unavailable_resource_reason_ids" => ["payload_unavailable"]
               },
               "quality_gate_report" => %{
                 "resource_availability_reason_counts" => ^reason_counts,
                 "resource_availability_reason_ids" => [
                   "ground_station_reserved",
                   "payload_unavailable"
                 ],
                 "station_availability_reason_ids" => ["ground_station_reserved"],
                 "station_availability_reason_counts" => %{"ground_station_reserved" => 1},
                 "unavailable_resource_reason_ids" => ["payload_unavailable"]
               }
             }
           } = summary

    artifact =
      ordered_event_result_set(:canonical)
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("mission_state", %{
            "source_operational_readiness_report" => readiness_report,
            "source_quality_gate_report" => quality_gate_report
          }),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    refute Map.has_key?(artifact, "candidate_rejection_report")

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
             Schema.validate_artifact(artifact)

    assert get_in(artifact, [
             "provenance",
             "source_reports",
             "operational_readiness_report",
             "station_availability_reason_ids"
           ]) == ["ground_station_reserved"]

    assert get_in(artifact, [
             "provenance",
             "source_reports",
             "operational_readiness_report",
             "station_availability_reason_counts"
           ]) == %{"ground_station_reserved" => 1}

    assert get_in(artifact, [
             "provenance",
             "source_reports",
             "quality_gate_report",
             "station_availability_reason_ids"
           ]) == ["ground_station_reserved"]

    assert get_in(artifact, [
             "provenance",
             "source_reports",
             "quality_gate_report",
             "station_availability_reason_counts"
           ]) == %{"ground_station_reserved" => 1}

    stale_quality_gate_source_report =
      artifact
      |> put_in(
        [
          "provenance",
          "source_reports",
          "quality_gate_report",
          "station_availability_reason_ids"
        ],
        []
      )
      |> put_in(
        [
          "provenance",
          "source_reports",
          "quality_gate_report",
          "station_availability_reason_counts"
        ],
        %{}
      )

    assert {:error, stale_quality_gate_source_report_errors} =
             Schema.validate_artifact(stale_quality_gate_source_report)

    assert Enum.any?(
             stale_quality_gate_source_report_errors["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.quality_gate_report.station_availability_reason_ids" and
                 &1["message"] ==
                   "must equal station availability reason IDs from resource_availability_reason_counts")
           )

    assert Enum.any?(
             stale_quality_gate_source_report_errors["errors"],
             &(&1["path"] ==
                 "$.provenance.source_reports.quality_gate_report.station_availability_reason_counts" and
                 &1["message"] ==
                   "must equal station availability reason counts from resource_availability_reason_counts")
           )
  end
end
