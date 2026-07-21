defmodule OrbitalDynamics.CandidateRefresh.ContactAllocationPressureSourceWrapperBuildTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{
    CadenceImport,
    CandidateRefresh,
    Epoch,
    OperatorReview,
    ResultSet,
    Schema
  }

  alias OrbitalDynamics.Communications.ContactAllocation

  test "replays contact allocation pressure from result artifact wrappers" do
    report = %{
      "schema_contract" => "contact_allocation_report.v1",
      "rows" => [
        %{
          "contact_id" => "dl_prior_blocked",
          "type" => "downlink",
          "allocation_status" => "blocked",
          "effective_allocation_status" => "blocked",
          "ground_station_id" => "equator_prime",
          "required_downlink_mb" => 420.0
        }
      ]
    }

    wrapper = %{
      "schema_contract" => "result_artifact.v1",
      "contact_allocation_report" => report,
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

  test "replays contact allocation pressure from operator review packages" do
    report = %{
      "schema_contract" => "contact_allocation_report.v1",
      "rows" => [
        %{
          "contact_id" => "dl_prior_deferred",
          "type" => "downlink",
          "allocation_status" => "deferred",
          "effective_allocation_status" => "deferred",
          "ground_station_id" => "equator_prime",
          "required_downlink_mb" => 420.0
        }
      ]
    }

    package = OperatorReview.from_contact_allocation_report(report)

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

  test "replays contact allocation pressure from Cadence import manifests" do
    report = %{
      "schema_contract" => "contact_allocation_report.v1",
      "rows" => [
        %{
          "contact_id" => "dl_prior_policy_blocked",
          "type" => "downlink",
          "allocation_status" => "allocated",
          "effective_allocation_status" => "policy_blocked",
          "approval_status" => "blocked_by_policy",
          "ground_station_id" => "equator_prime",
          "required_downlink_mb" => 420.0
        }
      ]
    }

    manifest = CadenceImport.from_contact_allocation_report(report)

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

  test "applies exact allocation resource blocks from review and import wrappers" do
    blocked_contact_id = "leo_1_downlink_equator_prime_1"
    report = resource_blocked_contact_allocation_report(blocked_contact_id, "sat_1")
    operator_review = OperatorReview.from_contact_allocation_report(report)
    cadence_import = CadenceImport.from_contact_allocation_report(report)

    wrapper_cases = [
      {
        "source_operator_review_package",
        operator_review,
        "source_operator_review_package.rows.source_contact_allocation",
        "operator_review_package.rows.source_contact_allocation",
        ["allocation_report_round_trip", "allocation_resource_round_trip"]
      },
      {
        "source_cadence_import_manifest",
        cadence_import,
        "source_cadence_import_manifest.rows.source_contact_allocation",
        "cadence_import_manifest.rows.source_contact_allocation",
        ["allocation_resource_round_trip"]
      }
    ]

    Enum.each(
      wrapper_cases,
      fn {request_key, wrapper, source_path, source, trust_boundaries} ->
        artifact =
          result_set()
          |> CandidateRefresh.build(
            candidate_refresh:
              refresh_request()
              |> Map.put(request_key, wrapper)
              |> Map.put("prior_candidate_activities", [prior_contact(blocked_contact_id)]),
            generated_at: ~U[2026-05-14 00:00:00Z]
          )

        assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
                 "leo_1_observe_target_a_1"
               ]

        assert %{
                 "source" => "candidate_refresh.contact_allocation_unavailable_resource",
                 "rejected_candidate_ids" => [^blocked_contact_id]
               } = rejection_report = artifact["candidate_rejection_report"]

        assert %{
                 "source_report_paths" => [^source_path],
                 "source_report_sources" => [^source],
                 "resource_blocking_dimensions" => ["antenna"],
                 "blocked_spacecraft_ids" => ["sat_1"],
                 "trust_boundaries" => ^trust_boundaries
               } =
                 rejection_report
                 |> Map.fetch!("rows")
                 |> Enum.find(&(&1["candidate_id"] == blocked_contact_id))
                 |> get_in([
                   "activity_context",
                   "provenance",
                   "contact_allocation_candidate_filter"
                 ])

        assert [
                 %{
                   "id" => ^blocked_contact_id,
                   "invalidated_reason" => "dropped_by_contact_allocation_unavailable_resource"
                 }
               ] = artifact["invalidated_candidates"]

        assert "contact allocation resource evidence excluded explicitly scoped contact candidates" in artifact[
                 "warnings"
               ]

        handoff_review = OperatorReview.from_candidate_refresh_artifact(artifact)
        handoff_import = CadenceImport.from_candidate_refresh_artifact(artifact)

        assert Enum.any?(
                 handoff_review["rows"],
                 &(&1["review_type"] == "candidate_rejection_review" and
                     &1["candidate_id"] == blocked_contact_id)
               )

        assert Enum.any?(
                 handoff_import["rows"],
                 &(&1["source_review_type"] == "candidate_rejection_review" and
                     &1["subject_id"] == blocked_contact_id)
               )

        assert {:ok, %{"schema_contract" => "candidate_rejection_report.v1"}} =
                 Schema.validate_artifact(rejection_report)

        assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
                 Schema.validate_artifact(handoff_review)

        assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
                 Schema.validate_artifact(handoff_import)

        assert {:ok, %{"schema_contract" => "candidate_refresh.v1"}} =
                 Schema.validate_artifact(artifact)
      end
    )

    cross_spacecraft_manifest =
      blocked_contact_id
      |> resource_blocked_contact_allocation_report("sat_2")
      |> CadenceImport.from_contact_allocation_report()

    cross_spacecraft_artifact =
      result_set()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("source_cadence_import_manifest", cross_spacecraft_manifest),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert blocked_contact_id in Enum.map(
             cross_spacecraft_artifact["candidate_activities"],
             & &1["id"]
           )

    assert cross_spacecraft_artifact["candidate_rejection_report"]["rejected_count"] == 0

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(operator_review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(cadence_import)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(cross_spacecraft_manifest)
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

  defp resource_blocked_contact_allocation_report(contact_id, spacecraft_id) do
    contact = %{
      id: contact_id,
      type: :downlink,
      direction: :downlink,
      scenario_id: :leo_1,
      spacecraft_id: spacecraft_id,
      station_id: :equator_prime,
      starts_at_s: 300.0,
      ends_at_s: 420.0
    }

    resource_summary = %{
      spacecraft_id: spacecraft_id,
      antenna_available: false,
      source_quality: :operator_supplied,
      provenance: %{trust_boundary: :allocation_resource_round_trip}
    }

    {_allocated_contacts, report} =
      ContactAllocation.allocate_contacts([contact], [],
        source: "candidate_refresh.wrapper_round_trip",
        resource_summaries: [resource_summary]
      )

    Map.put(report, "provenance", %{"trust_boundary" => "allocation_report_round_trip"})
  end

  defp prior_contact(contact_id) do
    %{
      "id" => contact_id,
      "type" => "downlink",
      "scenario_id" => "leo_1",
      "ground_station_id" => "equator_prime",
      "starts_at_s" => 300.0,
      "ends_at_s" => 420.0,
      "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1"
    }
  end
end
