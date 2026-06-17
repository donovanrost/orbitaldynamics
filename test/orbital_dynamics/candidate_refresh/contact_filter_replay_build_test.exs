defmodule OrbitalDynamics.CandidateRefresh.ContactFilterReplayBuildTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, CandidateRefresh, Epoch, ResultSet, Schema}
  alias OrbitalDynamics.Communications.ContactFilter

  test "replays contact filter unavailable station suppressions into ground network state" do
    report = %{
      "schema_contract" => "contact_filter_report.v1",
      "suppressed_candidates" => [
        %{
          "id" => "prior_downlink_station_block",
          "type" => "downlink",
          "scenario_id" => "leo_1",
          "ground_station_id" => "equator_prime",
          "direction" => "downlink",
          "starts_at_s" => 250.0,
          "ends_at_s" => 450.0,
          "suppressed_reason" => "ground_station_unavailable",
          "trust_boundary" => "ground_partner_api"
        }
      ]
    }

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_contact_filter_report", report),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_observe_target_a_1"
           ]

    assert [
             %{
               "id" => "leo_1_downlink_equator_prime_1",
               "suppressed_reason" => "ground_station_unavailable",
               "trust_boundary" => "ground_partner_api",
               "source_station_calendar_entry" => %{
                 "source_contact_suppression" => %{
                   "id" => "prior_downlink_station_block"
                 }
               }
             }
           ] = artifact["contact_filter_report"]["suppressed_candidates"]

    assert %{
             "paths" => ["source_contact_filter_report"],
             "contract" => "contact_filter_report.v1",
             "count" => 1,
             "row_count" => 1,
             "suppressed_candidate_count" => 1,
             "invalid_contact_input_count" => 0,
             "suppressed_reason_counts" => %{"ground_station_unavailable" => 1},
             "station_suppression_count" => 1,
             "station_suppression_ground_station_counts" => %{"equator_prime" => 1},
             "station_suppression_availability_counts" => %{"unavailable" => 1},
             "station_suppression_status_counts" => %{"unavailable" => 1},
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["ground_partner_api"]
           } = get_in(artifact, ["provenance", "source_reports", "contact_filter_report"])

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "replays contact filter reserved station suppressions from Cadence import manifests" do
    report = %{
      "schema_contract" => "contact_filter_report.v1",
      "suppressed_candidates" => [
        %{
          "id" => "prior_reserved_contact",
          "type" => "downlink",
          "scenario_id" => "leo_1",
          "ground_station_id" => "equator_prime",
          "direction" => "downlink",
          "starts_at_s" => 250.0,
          "ends_at_s" => 450.0,
          "suppressed_reason" => "ground_station_reserved",
          "station_reservation_id" => "reservation_equator_prime_1",
          "station_reserved_by" => "ops_team_b",
          "station_reservation_status" => "reserved",
          "trust_boundary" => "ground_partner_api"
        }
      ]
    }

    manifest = CadenceImport.from_contact_filter_report(report)

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_cadence_import_manifest", manifest),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_observe_target_a_1"
           ]

    assert [
             %{
               "id" => "leo_1_downlink_equator_prime_1",
               "suppressed_reason" => "ground_station_reserved",
               "station_reservation_id" => "reservation_equator_prime_1",
               "station_reserved_by" => "ops_team_b",
               "station_reservation_status" => "reserved"
             }
           ] = artifact["contact_filter_report"]["suppressed_candidates"]

    assert %{
             "paths" => ["source_cadence_import_manifest.rows.source_contact_suppression"],
             "contract" => "contact_filter_report.v1",
             "count" => 1,
             "row_count" => 1,
             "suppressed_candidate_count" => 1,
             "invalid_contact_input_count" => 0,
             "suppressed_reason_counts" => %{"ground_station_reserved" => 1},
             "station_suppression_count" => 1,
             "station_suppression_ground_station_counts" => %{"equator_prime" => 1},
             "station_suppression_availability_counts" => %{"reserved" => 1},
             "station_suppression_status_counts" => %{"reserved" => 1},
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["ground_partner_api"]
           } = get_in(artifact, ["provenance", "source_reports", "contact_filter_report"])

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "preserves invalid contact filter input replay provenance from Cadence imports" do
    {_kept, report} =
      ContactFilter.filter_candidates(
        [
          %{
            id: :bad_contact,
            type: :downlink,
            scenario_id: :leo_1,
            starts_at_s: 10.0,
            ends_at_s: 20.0
          }
        ],
        []
      )

    manifest = CadenceImport.from_contact_filter_report(report)

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_cadence_import_manifest", manifest),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert %{
             "paths" => ["source_cadence_import_manifest.rows.source_contact_suppression"],
             "contract" => "contact_filter_report.v1",
             "count" => 1,
             "row_count" => 1,
             "suppressed_candidate_count" => 1,
             "invalid_contact_input_count" => 1,
             "suppressed_reason_counts" => %{"invalid_contact_input" => 1}
           } = get_in(artifact, ["provenance", "source_reports", "contact_filter_report"])

    assert "source contact filter reports include invalid contact inputs requiring review" in artifact[
             "warnings"
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
