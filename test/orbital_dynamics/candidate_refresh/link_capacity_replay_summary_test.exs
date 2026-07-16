defmodule OrbitalDynamics.CandidateRefresh.LinkCapacityReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{
    CadenceImport,
    CandidateRefresh,
    Epoch,
    OperatorReview,
    ResultSet,
    Schema
  }

  alias OrbitalDynamics.Communications.LinkCapacity

  test "derives downlink completion objectives from source link capacity reports" do
    report = %{
      "schema_contract" => "link_capacity_report.v1",
      "rows" => [
        %{
          "ground_station_id" => "equator_prime",
          "required_downlink_mb" => 900.0,
          "selected_downlink_shortfall_mb" => 420.0,
          "capacity_adjusted_throughput_mb" => 480.0,
          "selected_capacity_adjusted_throughput_mb" => 360.0,
          "unused_capacity_adjusted_throughput_mb" => 120.0,
          "downlink_requirement_status" => "shortfall",
          "selected_contact_ids" => ["dl_prior"],
          "source_window_id" => "window_prior",
          "trust_boundary" => "cadence_ops"
        }
      ]
    }

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_link_capacity_report", report),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 420.0
    assert downlink["candidate_downlink_mb"] == 360.0
    assert downlink["selected_downlink_shortfall_mb"] == 60.0
    assert downlink["source_capacity_adjusted_throughput_mb"] == 480.0
    assert downlink["source_selected_capacity_adjusted_throughput_mb"] == 360.0
    assert downlink["source_unused_capacity_adjusted_throughput_mb"] == 120.0

    assert get_in(downlink, ["activity_context", "source_capacity_adjusted_throughput_mb"]) ==
             480.0

    assert downlink["downlink_completion_source"] ==
             "candidate_refresh.objectives.downlink_completion"

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "derives station throughput feedback from source link capacity reports" do
    report = %{
      "schema_contract" => "link_capacity_report.v1",
      "rows" => [
        %{
          "ground_station_id" => "equator_prime",
          "selected_capacity_adjusted_throughput_mb" => 360.0,
          "actual_throughput_mb" => 120.0,
          "actual_downlink_shortfall_mb" => 240.0,
          "actual_downlink_requirement_status" => "shortfall",
          "actual_throughput_contact_ids" => ["dl_prior"],
          "trust_boundary" => "cadence_ops"
        }
      ]
    }

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_link_capacity_report", report),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert get_in(artifact, ["operational_feedback", "station_throughput_factor"]) == %{
             "equator_prime" => 1 / 3
           }

    assert get_in(artifact, ["provenance", "operational_feedback", "trust_boundary"]) ==
             "cadence_ops"

    assert "station_throughput_factor" in get_in(artifact, [
             "provenance",
             "operational_feedback",
             "input_keys"
           ])

    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 240.0
    assert downlink["estimated_throughput_mb"] == 120.0
    assert downlink["candidate_downlink_mb"] == 120.0
    assert downlink["selected_downlink_shortfall_mb"] == 120.0

    assert get_in(downlink, ["throughput_model", "station_throughput_factor"]) == 1 / 3

    assert get_in(downlink, ["throughput_model", "station_throughput_factor_source"]) ==
             "operational_feedback.station_throughput_factor.station"

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "replays link capacity shortfall from result artifact wrappers" do
    report = %{
      "schema_contract" => "link_capacity_report.v1",
      "rows" => [
        %{
          "ground_station_id" => "equator_prime",
          "selected_downlink_shortfall_mb" => 420.0,
          "downlink_requirement_status" => "shortfall"
        }
      ]
    }

    wrapper = %{
      "schema_contract" => "result_artifact.v1",
      "link_capacity_report" => report,
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

  test "replays link capacity shortfall from operator review packages" do
    report = %{
      "schema_contract" => "link_capacity_report.v1",
      "rows" => [
        %{
          "ground_station_id" => "equator_prime",
          "selected_downlink_shortfall_mb" => 420.0,
          "downlink_requirement_status" => "shortfall"
        }
      ]
    }

    package = OperatorReview.from_link_capacity_report(report)

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

  test "replays link capacity shortfall from Cadence import manifests" do
    report = %{
      "schema_contract" => "link_capacity_report.v1",
      "rows" => [
        %{
          "spacecraft_id" => "leo_1",
          "ground_station_id" => "equator_prime",
          "direction" => "downlink",
          "actual_downlink_shortfall_mb" => 420.0,
          "actual_downlink_requirement_status" => "shortfall",
          "source_window_id" => "window_actual"
        }
      ]
    }

    manifest = CadenceImport.from_link_capacity_report(report)

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

    assert %{
             "source_report_link_capacity_paths" => [
               "source_cadence_import_manifest.rows.source_link_capacity"
             ],
             "source_report_link_capacity_source_window_ids_by_direction" => %{
               "downlink" => ["window_actual"]
             },
             "source_report_link_capacity_source_window_ids_by_ground_station" => %{
               "equator_prime" => ["window_actual"]
             },
             "source_report_link_capacity_source_window_ids_by_spacecraft" => %{
               "leo_1" => ["window_actual"]
             },
             "source_report_link_capacity_source_window_ids_by_requirement_status" => %{
               "shortfall" => ["window_actual"]
             }
           } = CandidateRefresh.source_report_summary(artifact)

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

  test "operator review and import lift link capacity summaries from candidate refresh artifacts" do
    link_capacity_summary = fn source, station_id, contact_id ->
      %{
        "schema_contract" => "link_capacity_report.v1",
        "source" => source,
        "rows" => [
          %{
            "ground_station_id" => station_id,
            "contact_count" => 1,
            "effective_contact_count" => 1,
            "selected_contact_count" => 1,
            "selected_downlink_shortfall_mb" => 20.0,
            "actual_downlink_shortfall_mb" => 5.0,
            "capacity_adjusted_throughput_mb" => 80.0,
            "selected_capacity_adjusted_throughput_mb" => 60.0,
            "unused_capacity_adjusted_throughput_mb" => 20.0,
            "downlink_requirement_status" => "shortfall",
            "actual_downlink_requirement_status" => "shortfall",
            "contact_ids" => [contact_id],
            "selected_contact_ids" => [contact_id],
            "actual_throughput_contact_ids" => [contact_id],
            "station_calendar_entry_ids" => ["station_entry_#{station_id}"],
            "station_calendar_provider_entry_ids" => ["provider_entry_#{station_id}"]
          }
        ]
      }
      |> LinkCapacity.summary()
      |> Map.put("provenance", %{"trust_boundary" => source})
    end

    direct_summary =
      link_capacity_summary.(
        "unit_test.link_capacity.direct",
        "direct_station",
        "direct_downlink"
      )

    canonical_summary =
      link_capacity_summary.(
        "unit_test.link_capacity.canonical",
        "canonical_station",
        "canonical_downlink"
      )

    wrapped_summary =
      link_capacity_summary.(
        "unit_test.link_capacity.wrapped",
        "wrapped_station",
        "wrapped_downlink"
      )

    nested_summary =
      link_capacity_summary.(
        "unit_test.link_capacity.nested",
        "nested_station",
        "nested_downlink"
      )

    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:link_capacity_summary_handoff",
      "source_link_capacity_summary" => [direct_summary],
      "link_capacity_summary" => canonical_summary,
      "source_result_artifact" => [
        wrapped_summary,
        %{
          "schema_contract" => "result_artifact.v1",
          "link_capacity_summary" => nested_summary
        }
      ]
    }

    review = OperatorReview.from_candidate_refresh_artifact(artifact)
    import = CadenceImport.from_candidate_refresh_artifact(artifact)

    link_rows = Enum.filter(review["rows"], &(&1["review_type"] == "link_capacity_review"))

    assert length(link_rows) == 4

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:link_capacity_summary_handoff",
             "link_capacity_review_count" => 4,
             "review_type_counts" => %{"link_capacity_review" => 4}
           } = review

    assert Enum.sort(Enum.map(link_rows, & &1["source"])) == [
             "candidate_refresh.link_capacity_summary.rows",
             "candidate_refresh.source_link_capacity_summary[0].rows",
             "candidate_refresh.source_result_artifact[0].rows",
             "candidate_refresh.source_result_artifact[1].link_capacity_summary.rows"
           ]

    assert Enum.any?(
             link_rows,
             &match?(
               %{
                 "source" => "candidate_refresh.link_capacity_summary.rows",
                 "ground_station_id" => "canonical_station",
                 "selected_downlink_shortfall_mb" => 20.0,
                 "actual_downlink_shortfall_mb" => 5.0,
                 "capacity_adjusted_throughput_mb" => 80.0,
                 "selected_capacity_adjusted_throughput_mb" => 60.0,
                 "unused_capacity_adjusted_throughput_mb" => 20.0,
                 "selected_contact_ids" => ["canonical_downlink"],
                 "actual_throughput_contact_ids" => ["canonical_downlink"],
                 "source_link_capacity" => %{
                   "schema_contract" => "link_capacity_summary.v1",
                   "source_link_capacity_summary" => %{
                     "schema_contract" => "link_capacity_summary.v1",
                     "source" => "unit_test.link_capacity.canonical",
                     "station_count" => 1
                   }
                 }
               },
               &1
             )
           )

    import_rows =
      Enum.filter(import["rows"], &(&1["source_review_type"] == "link_capacity_review"))

    assert length(import_rows) == 4

    assert %{
             "import_action_counts" => %{"review_link_capacity" => 4},
             "source_review_type_counts" => %{"link_capacity_review" => 4}
           } = import

    assert Enum.all?(
             import_rows,
             &(&1["import_action"] == "review_link_capacity" and
                 &1["source_review_row"]["source_link_capacity"]["source_link_capacity_summary"])
           )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(import)
  end
end
