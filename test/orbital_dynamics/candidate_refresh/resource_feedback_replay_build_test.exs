defmodule OrbitalDynamics.CandidateRefresh.ResourceFeedbackReplayBuildTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{
    CadenceImport,
    CandidateRefresh,
    Epoch,
    OperatorReview,
    ResourceFilter,
    ResultSet,
    Schema
  }

  test "replayed battery margin feedback supersedes stale base battery derivation inputs" do
    report = %{
      "schema_contract" => "resource_projection_report.v1",
      "projected_resources" => [
        %{
          "spacecraft_id" => "leo_1",
          "resource_pressure_status" => "power_margin",
          "resource_pressure_types" => ["power_margin"],
          "projected_battery_state_of_charge" => 0.05,
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
          |> put_in(["resource_filter_policy"], %{"min_observe_power_margin" => 0.2})
          |> put_in(["resource_summaries", Access.at(0), "battery_capacity_wh"], 100.0)
          |> put_in(["resource_summaries", Access.at(0), "battery_energy_used_wh"], 20.0)
          |> put_in(["resource_summaries", Access.at(0), "battery_state_of_charge"], 0.8)
          |> Map.put("source_operator_review_package", package),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_downlink_equator_prime_1"
           ]

    assert [
             %{
               "id" => "leo_1_observe_target_a_1",
               "spacecraft_id" => "leo_1",
               "suppressed_reason" => "power_margin_below_observe_policy",
               "resource_blocking_dimension" => "power",
               "battery_state_of_charge" => 0.05,
               "power_margin" => 0.05
             }
           ] = artifact["resource_filter_report"]["suppressed_candidates"]

    assert artifact["resource_filter_report"]["invalid_resource_summary_input_count"] == 0
    assert artifact["resource_filter_report"]["invalid_resource_summary_inputs"] == []

    summary = Enum.find(artifact["resource_summaries"], &(&1["spacecraft_id"] == "leo_1"))
    assert summary["battery_state_of_charge"] == 0.05
    refute Map.has_key?(summary, "battery_capacity_wh")
    refute Map.has_key?(summary, "battery_energy_used_wh")

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "Cadence-import battery margin replay supersedes stale base battery derivation inputs" do
    report = %{
      "schema_contract" => "resource_projection_report.v1",
      "projected_resources" => [
        %{
          "spacecraft_id" => "leo_1",
          "resource_pressure_status" => "power_margin",
          "resource_pressure_types" => ["power_margin"],
          "projected_battery_state_of_charge" => 0.05,
          "resource_trust_boundary" => "cadence_ops"
        }
      ]
    }

    manifest = CadenceImport.from_resource_projection_report(report)

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> put_in(["resource_filter_policy"], %{"min_observe_power_margin" => 0.2})
          |> put_in(["resource_summaries", Access.at(0), "battery_capacity_wh"], 100.0)
          |> put_in(["resource_summaries", Access.at(0), "battery_energy_used_wh"], 20.0)
          |> put_in(["resource_summaries", Access.at(0), "battery_state_of_charge"], 0.8)
          |> Map.put("source_cadence_import_manifest", manifest),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [
             %{
               "id" => "leo_1_observe_target_a_1",
               "spacecraft_id" => "leo_1",
               "suppressed_reason" => "power_margin_below_observe_policy",
               "resource_blocking_dimension" => "power",
               "battery_state_of_charge" => 0.05,
               "power_margin" => 0.05
             }
           ] = artifact["resource_filter_report"]["suppressed_candidates"]

    summary = Enum.find(artifact["resource_summaries"], &(&1["spacecraft_id"] == "leo_1"))
    assert summary["battery_state_of_charge"] == 0.05
    refute Map.has_key?(summary, "battery_capacity_wh")
    refute Map.has_key?(summary, "battery_energy_used_wh")

    assert %{
             "paths" => ["source_cadence_import_manifest.rows.source_resource_projection"],
             "contract" => "resource_projection_report.v1",
             "count" => 1,
             "row_count" => 1,
             "projected_resource_count" => 1,
             "resource_pressure_status_counts" => %{"power_margin" => 1},
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["cadence_ops"]
           } = get_in(artifact, ["provenance", "source_reports", "resource_projection_report"])

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "replays resource filter availability suppressions into refreshed resources" do
    report = %{
      "schema_contract" => "resource_filter_report.v1",
      "suppressed_candidates" => [
        %{
          "id" => "prior_observe_payload_block",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "spacecraft_id" => "sat_1",
          "target_id" => "target_a",
          "resource_id" => "payload_1",
          "suppressed_reason" => "payload_unavailable",
          "resource_blocking_dimension" => "payload",
          "resource_trust_boundary" => "cadence_ops"
        }
      ]
    }

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_resource_filter_report", report),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_downlink_equator_prime_1"
           ]

    assert [
             %{
               "id" => "leo_1_observe_target_a_1",
               "suppressed_reason" => "payload_unavailable",
               "resource_trust_boundary" => "cadence_ops"
             }
           ] = artifact["resource_filter_report"]["suppressed_candidates"]

    assert artifact["operational_feedback"]["resource_availability_overrides"]["sat_1"][
             "payload_available"
           ] == false

    assert %{
             "paths" => ["source_resource_filter_report"],
             "contract" => "resource_filter_report.v1",
             "count" => 1,
             "row_count" => 1,
             "suppressed_candidate_count" => 1,
             "suppressed_reason_counts" => %{"payload_unavailable" => 1},
             "resource_filter_spacecraft_counts" => %{"sat_1" => 1},
             "resource_filter_resource_counts" => %{"payload_1" => 1},
             "resource_filter_blocking_dimension_counts" => %{"payload" => 1}
           } = get_in(artifact, ["provenance", "source_reports", "resource_filter_report"])

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "replays resource filter margin suppressions from Cadence import manifests" do
    report = %{
      "schema_contract" => "resource_filter_report.v1",
      "suppressed_candidates" => [
        %{
          "id" => "prior_observe_storage_block",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "spacecraft_id" => "leo_1",
          "target_id" => "target_a",
          "suppressed_reason" => "storage_margin_below_observe_policy",
          "resource_blocking_dimension" => "storage",
          "storage_margin" => 0.0,
          "resource_trust_boundary" => "cadence_ops"
        }
      ]
    }

    manifest = CadenceImport.from_resource_filter_report(report)

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> put_in(["resource_filter_policy"], %{"min_observe_storage_margin" => 0.1})
          |> Map.put("source_cadence_import_manifest", manifest),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_downlink_equator_prime_1"
           ]

    assert [
             %{
               "id" => "leo_1_observe_target_a_1",
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

  test "imported resource filter battery suppressions supersede stale base battery derivation inputs" do
    report = %{
      "schema_contract" => "resource_filter_report.v1",
      "suppressed_candidates" => [
        %{
          "id" => "prior_observe_power_block",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "spacecraft_id" => "leo_1",
          "target_id" => "target_a",
          "suppressed_reason" => "power_margin_below_observe_policy",
          "resource_blocking_dimension" => "power",
          "battery_state_of_charge" => 0.05,
          "resource_trust_boundary" => "cadence_ops"
        }
      ]
    }

    manifest = CadenceImport.from_resource_filter_report(report)

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> put_in(["resource_filter_policy"], %{"min_observe_power_margin" => 0.2})
          |> put_in(["resource_summaries", Access.at(0), "battery_capacity_wh"], 100.0)
          |> put_in(["resource_summaries", Access.at(0), "battery_energy_used_wh"], 20.0)
          |> put_in(["resource_summaries", Access.at(0), "battery_state_of_charge"], 0.8)
          |> Map.put("source_cadence_import_manifest", manifest),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert [
             %{
               "id" => "leo_1_observe_target_a_1",
               "spacecraft_id" => "leo_1",
               "suppressed_reason" => "power_margin_below_observe_policy",
               "resource_blocking_dimension" => "power",
               "battery_state_of_charge" => 0.05
             }
           ] = artifact["resource_filter_report"]["suppressed_candidates"]

    assert artifact["resource_filter_report"]["invalid_resource_summary_input_count"] == 0
    assert artifact["resource_filter_report"]["invalid_resource_summary_inputs"] == []

    summary = Enum.find(artifact["resource_summaries"], &(&1["spacecraft_id"] == "leo_1"))
    assert summary["battery_state_of_charge"] == 0.05
    refute Map.has_key?(summary, "battery_capacity_wh")
    refute Map.has_key?(summary, "battery_energy_used_wh")

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "preserves invalid resource filter summary replay provenance from Cadence imports" do
    {_kept, report} =
      ResourceFilter.filter_candidates(
        [
          %{
            id: :obs_1,
            type: :observe,
            scenario_id: :leo_1,
            spacecraft_id: :sat_1,
            target_id: :target_a,
            starts_at_s: 10.0,
            ends_at_s: 20.0
          }
        ],
        [
          %{
            spacecraft_id: :sat_1,
            payload_available: false,
            power_margin: 1.2,
            source_quality: :operator_supplied,
            provenance: %{trust_boundary: :cadence_ops}
          }
        ]
      )

    manifest = CadenceImport.from_resource_filter_report(report)

    artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_cadence_import_manifest", manifest),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert %{
             "paths" => ["source_cadence_import_manifest.rows.source_resource_suppression"],
             "contract" => "resource_filter_report.v1",
             "count" => 1,
             "row_count" => 1,
             "suppressed_candidate_count" => 0,
             "invalid_resource_summary_input_count" => 1,
             "trust_boundary_status" => "declared",
             "trust_boundaries" => ["cadence_ops"]
           } = get_in(artifact, ["provenance", "source_reports", "resource_filter_report"])

    assert "source resource filter reports include invalid resource summaries requiring review" in artifact[
             "warnings"
           ]

    refute get_in(artifact, ["operational_feedback", "resource_margin_overrides", "sat_1"])
    refute get_in(artifact, ["operational_feedback", "resource_availability_overrides", "sat_1"])

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
