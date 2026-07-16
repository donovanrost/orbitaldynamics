defmodule OrbitalDynamics.CandidateRefresh.ResourceProjectionReplaySummaryTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{
    CadenceImport,
    CandidateRefresh,
    Epoch,
    OperatorReview,
    ResourceProjection,
    ResultSet,
    Schema
  }

  test "derives downlink completion objectives from source resource projection reports" do
    report = %{
      "schema_contract" => "resource_projection_report.v1",
      "projected_resources" => [
        %{
          "spacecraft_id" => "leo_1",
          "resource_pressure_status" => "nominal",
          "projected_downlink_shortfall_mb" => 0.0
        },
        %{
          "spacecraft_id" => "leo_1",
          "resource_pressure_status" => "downlink_shortfall",
          "resource_pressure_types" => ["downlink_shortfall"],
          "projected_downlink_shortfall_mb" => 420.0,
          "first_resource_pressure_activity_id" => "dl_pressure_1",
          "first_resource_pressure_ground_station_id" => "equator_prime"
        }
      ]
    }

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_resource_projection_report", report),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 420.0
    assert downlink["candidate_downlink_mb"] == 360.0
    assert downlink["selected_downlink_shortfall_mb"] == 60.0

    assert downlink["downlink_completion_source"] ==
             "candidate_refresh.objectives.downlink_completion"

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "derives downlink completion objectives from source resource projection flow summaries" do
    flow_summary = resource_projection_flow_summary_fixture()

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("mission_state", %{
            "source_resource_projection_flow_summary" => flow_summary
          }),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    downlink = Enum.find(artifact["candidate_activities"], &(&1["type"] == "downlink"))
    assert downlink["required_downlink_mb"] == 420.0
    assert downlink["candidate_downlink_mb"] == 360.0
    assert downlink["selected_downlink_shortfall_mb"] == 60.0

    assert downlink["downlink_completion_source"] ==
             "candidate_refresh.objectives.downlink_completion"

    assert %{
             "paths" => ["mission_state.source_resource_projection_flow_summary"],
             "contract" => "resource_projection_report.v1",
             "count" => 1,
             "row_count" => 1,
             "projected_resource_count" => 1,
             "source_artifact_type_counts" => %{"resource_projection_flow_summary.v1" => 1},
             "source_flow_summary_model_counts" => %{
               "artifact_only_selected_activity_resource_flow_summary" => 1
             },
             "invalid_activity_input_count" => 0,
             "invalid_resource_summary_input_count" => 0,
             "resource_pressure_status_counts" => %{"downlink_shortfall" => 1},
             "ground_station_counts" => %{"equator_prime" => 1},
             "resource_projection_spacecraft_counts" => %{"leo_1" => 1},
             "resource_pressure_type_counts" => %{"downlink_shortfall" => 1},
             "resource_pressure_activity_id_counts" => %{"dl_flow_pressure" => 1},
             "resource_pressure_ground_station_ids_by_type" => %{
               "downlink_shortfall" => ["equator_prime"]
             },
             "resource_pressure_source_window_ids_by_type" => %{
               "downlink_shortfall" => ["flow_access_window_1"]
             },
             "resource_pressure_station_calendar_entry_ids_by_type" => %{
               "downlink_shortfall" => ["station_flow_window_1"]
             },
             "resource_pressure_station_calendar_provider_ids_by_type" => %{
               "downlink_shortfall" => ["ops_calendar_flow"]
             },
             "resource_pressure_station_calendar_provider_entry_ids_by_type" => %{
               "downlink_shortfall" => ["provider_flow_window_1"]
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["flight_dynamics_model"]
           } = get_in(artifact, ["provenance", "source_reports", "resource_projection_report"])

    source_summary = CandidateRefresh.source_report_summary(artifact)

    assert source_summary["source_report_resource_projection_contract"] ==
             "resource_projection_report.v1"

    assert source_summary["source_report_resource_projection_count"] == 1
    assert source_summary["source_report_resource_projection_row_count"] == 1

    assert source_summary["source_report_resource_projection_paths"] == [
             "mission_state.source_resource_projection_flow_summary"
           ]

    assert source_summary[
             "source_report_resource_projection_source_artifact_type_counts"
           ] == %{"resource_projection_flow_summary.v1" => 1}

    assert source_summary[
             "source_report_resource_projection_source_flow_summary_model_counts"
           ] == %{"artifact_only_selected_activity_resource_flow_summary" => 1}

    replay_summary = CandidateRefresh.resource_projection_replay_summary(artifact)

    assert replay_summary["source_artifact_type_counts"] == %{
             "resource_projection_flow_summary.v1" => 1
           }

    assert replay_summary["source_flow_summary_model_counts"] == %{
             "artifact_only_selected_activity_resource_flow_summary" => 1
           }

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "replays resource projection flow summaries from result artifact wrappers" do
    wrapper = %{
      "schema_contract" => "result_artifact.v1",
      "source_resource_projection_flow_summary" =>
        resource_projection_flow_summary_fixture()
        |> Map.delete("provenance"),
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

    assert %{
             "paths" => ["source_result_artifact.source_resource_projection_flow_summary"],
             "contract" => "resource_projection_report.v1",
             "count" => 1,
             "projected_resource_count" => 1,
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["mission_planning"]
           } = get_in(artifact, ["provenance", "source_reports", "resource_projection_report"])

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "replays resource projection downlink pressure from operator review packages" do
    report = %{
      "schema_contract" => "resource_projection_report.v1",
      "projected_resources" => [
        %{
          "spacecraft_id" => "leo_1",
          "resource_pressure_status" => "downlink shortfall",
          "resource_pressure_types" => ["downlink_shortfall"],
          "projected_downlink_shortfall_mb" => 420.0,
          "first_resource_pressure_activity_id" => "dl_pressure_1",
          "first_resource_pressure_ground_station_id" => "equator_prime"
        }
      ]
    }

    package = OperatorReview.from_resource_projection_report(report)

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

  test "replays resource projection downlink pressure from Cadence import manifests" do
    report = %{
      "schema_contract" => "resource_projection_report.v1",
      "projected_resources" => [
        %{
          "spacecraft_id" => "leo_1",
          "resource_pressure_status" => "downlink_shortfall",
          "resource_pressure_types" => ["downlink_shortfall"],
          "projected_downlink_shortfall_mb" => 420.0,
          "first_resource_pressure_activity_id" => "dl_pressure_1",
          "first_resource_pressure_ground_station_id" => "equator_prime"
        }
      ]
    }

    manifest = CadenceImport.from_resource_projection_report(report)

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

  test "preserves invalid resource projection summary replay provenance from Cadence imports" do
    report =
      ResourceProjection.report(
        [
          %{
            id: :obs_1,
            type: :observe,
            scenario_id: :leo_1,
            estimated_storage_mb: 10.0
          }
        ],
        [
          %{
            storage_capacity_mb: 500.0,
            storage_used_mb: 50.0,
            source_quality: :fleet_default,
            provenance: %{trust_boundary: :fleet_model}
          },
          %{
            spacecraft_id: :leo_1,
            storage_capacity_mb: 100.0,
            storage_used_mb: 0.0,
            source_quality: :operator_supplied,
            provenance: %{trust_boundary: :cadence_ops}
          }
        ]
      )

    manifest = CadenceImport.from_resource_projection_report(report)

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_cadence_import_manifest", manifest),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert %{
             "paths" => ["source_cadence_import_manifest.rows.source_resource_projection"],
             "contract" => "resource_projection_report.v1",
             "count" => 1,
             "row_count" => 2,
             "projected_resource_count" => 1,
             "invalid_activity_input_count" => 0,
             "invalid_resource_summary_input_count" => 1,
             "resource_pressure_status_counts" => %{"nominal" => 1},
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["cadence_ops", "fleet_model"]
           } = get_in(artifact, ["provenance", "source_reports", "resource_projection_report"])

    assert "source resource projection reports include invalid inputs requiring review" in artifact[
             "warnings"
           ]

    refute get_in(artifact, [
             "operational_feedback",
             "resource_margin_overrides",
             "all_spacecraft:mixed_scope"
           ])

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "derives resource availability feedback from source resource projection reports" do
    report = %{
      "schema_contract" => "resource_projection_report.v1",
      "projected_resources" => [
        %{
          "spacecraft_id" => "sat_1",
          "resource_pressure_status" => "payload_unavailable",
          "resource_pressure_types" => ["payload_unavailable"],
          "payload_available" => false,
          "antenna_available" => true,
          "resource_trust_boundary" => "cadence_ops"
        }
      ]
    }

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_resource_projection_report", report),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_downlink_equator_prime_1"
           ]

    assert Enum.any?(
             artifact["resource_summaries"],
             &(&1["spacecraft_id"] == "sat_1" and &1["payload_available"] == false and
                 &1["antenna_available"] == true and
                 &1["source_quality"] == "operational_feedback" and
                 get_in(&1, ["provenance", "trust_boundary"]) == "cadence_ops")
           )

    assert [
             %{
               "id" => "leo_1_observe_target_a_1",
               "spacecraft_id" => "sat_1",
               "suppressed_reason" => "payload_unavailable",
               "resource_blocking_dimension" => "payload",
               "resource_trust_boundary" => "cadence_ops"
             }
           ] = artifact["resource_filter_report"]["suppressed_candidates"]

    assert artifact["operational_feedback"]["resource_availability_overrides"]["sat_1"][
             "payload_available"
           ] == false

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "derives resource margin feedback from reviewed resource projection reports" do
    report = %{
      "schema_contract" => "resource_projection_report.v1",
      "projected_resources" => [
        %{
          "spacecraft_id" => "leo_1",
          "resource_pressure_status" => "storage_overflow",
          "resource_pressure_types" => ["storage_overflow"],
          "projected_storage_overflow_mb" => 25.0,
          "projected_storage_margin" => -0.25,
          "resource_trust_boundary" => "cadence_ops"
        }
      ]
    }

    package = OperatorReview.from_resource_projection_report(report)

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> put_in(["resource_filter_policy"], %{"min_observe_storage_margin" => 0.1})
          |> Map.put("source_operator_review_package", package),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_downlink_equator_prime_1"
           ]

    assert Enum.any?(
             artifact["resource_summaries"],
             &(&1["spacecraft_id"] == "leo_1" and &1["storage_margin"] == 0.0 and
                 &1["source_quality"] == "operational_feedback")
           )

    assert [
             %{
               "id" => "leo_1_observe_target_a_1",
               "spacecraft_id" => "leo_1",
               "suppressed_reason" => "storage_margin_below_observe_policy",
               "resource_blocking_dimension" => "storage"
             }
           ] = artifact["resource_filter_report"]["suppressed_candidates"]

    assert artifact["resource_filter_report"]["invalid_resource_summary_input_count"] == 0
    assert artifact["resource_filter_report"]["invalid_resource_summary_inputs"] == []

    assert artifact["operational_feedback"]["resource_margin_overrides"]["leo_1"][
             "storage_margin"
           ] == 0.0

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

  defp resource_projection_flow_summary_fixture do
    ResourceProjection.report(
      [
        %{
          id: :dl_flow_pressure,
          type: :downlink,
          scenario_id: :leo_1,
          ground_station_id: :equator_prime,
          source_window_id: :flow_access_window_1,
          station_calendar_entry_id: :station_flow_window_1,
          station_calendar_provider_id: :ops_calendar_flow,
          station_calendar_provider_entry_id: :provider_flow_window_1,
          estimated_throughput_mb: 420.0
        }
      ],
      [
        %{
          spacecraft_id: :leo_1,
          storage_capacity_mb: 1_000.0,
          storage_used_mb: 420.0,
          downlink_capacity_mb: 0.0
        }
      ],
      source: "flow_summary_replay_test"
    )
    |> ResourceProjection.flow_summary()
    |> Map.put("provenance", %{"trust_boundary" => "flight_dynamics_model"})
  end
end
