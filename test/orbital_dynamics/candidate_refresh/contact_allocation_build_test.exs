defmodule OrbitalDynamics.CandidateRefresh.ContactAllocationBuildTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{
    CadenceImport,
    CandidateRefresh,
    Epoch,
    OperatorReview,
    ResultSet,
    Schema
  }

  test "embeds deterministic contact allocation over refreshed contact candidates" do
    prior_deferred_contact = %{
      "id" => "leo_1_downlink_equator_prime_2",
      "type" => "downlink",
      "scenario_id" => "leo_1",
      "ground_station_id" => "equator_prime",
      "starts_at_s" => 360.0,
      "ends_at_s" => 480.0,
      "source_window_id" => "window:leo_1:ground_station_access:equator_prime:2"
    }

    artifact =
      result_set_with_overlapping_contacts()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("prior_candidate_activities", [prior_deferred_contact]),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_downlink_equator_prime_1"
           ]

    assert Enum.map(artifact["contact_intents"], & &1["activity_id"]) == [
             "leo_1_downlink_equator_prime_1"
           ]

    assert %{
             "schema_contract" => "contact_allocation_report.v1",
             "source" => "candidate_refresh.candidate_activities",
             "input_contact_count" => 2,
             "allocated_contact_count" => 1,
             "returned_allocated_contact_count" => 1,
             "deferred_contact_count" => 1,
             "blocked_contact_count" => 0,
             "contact_contention_report" => %{
               "schema_contract" => "contact_contention_report.v1",
               "conflict_group_count" => 1
             },
             "contact_contention_resolution_report" => %{
               "schema_contract" => "contact_contention_resolution_report.v1",
               "recommendation_count" => 1
             }
           } = artifact["contact_allocation_report"]

    assert [
             %{
               "contact_id" => "leo_1_downlink_equator_prime_1",
               "allocation_status" => "allocated",
               "effective_allocation_status" => "allocated",
               "allocation_reason" => "selected_by_contention_resolution",
               "selected" => true,
               "deferred_contact_ids" => ["leo_1_downlink_equator_prime_2"]
             },
             %{
               "contact_id" => "leo_1_downlink_equator_prime_2",
               "allocation_status" => "deferred",
               "effective_allocation_status" => "deferred",
               "allocation_reason" => "same_station_contention",
               "selected" => false,
               "selected_contact_id" => "leo_1_downlink_equator_prime_1"
             }
           ] = artifact["contact_allocation_report"]["rows"]

    assert %{
             "input_candidate_count" => 1,
             "kept_candidate_count" => 1,
             "dropped_candidate_count" => 0
           } = artifact["refresh_budget_report"]

    assert [
             %{
               "id" => "leo_1_downlink_equator_prime_2",
               "invalidated_reason" => "dropped_by_contact_allocation",
               "replacement_candidate_id" => "leo_1_downlink_equator_prime_2"
             }
           ] = artifact["invalidated_candidates"]

    assert artifact["candidate_diff_report"]["invalidated_candidates"] ==
             artifact["invalidated_candidates"]

    assert "contact allocation excluded refreshed contact candidates" in artifact["warnings"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "passes contact allocation policy into reduced-capacity refresh packing" do
    refresh =
      refresh_request()
      |> Map.put("ground_network", [
        %{
          "id" => "equator_reduced_capacity",
          "ground_station_id" => "equator_prime",
          "availability" => "available",
          "capacity_fraction" => 0.5,
          "starts_at_s" => 250.0,
          "ends_at_s" => 500.0
        }
      ])
      |> Map.put("contact_allocation_policy", %{
        "default_required_capacity_fraction" => "0.25"
      })

    artifact =
      result_set_with_overlapping_contacts()
      |> CandidateRefresh.build(
        candidate_refresh: refresh,
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_downlink_equator_prime_1",
             "leo_1_downlink_equator_prime_2"
           ]

    assert %{
             "allocated_contact_count" => 2,
             "returned_allocated_contact_count" => 2,
             "deferred_contact_count" => 0,
             "reduced_capacity_pack_group_count" => 1,
             "reduced_capacity_pack_groups" => [
               %{
                 "capacity_fraction" => 0.5,
                 "default_required_capacity_fraction" => 0.25,
                 "used_capacity_fraction" => 0.5,
                 "capacity_packed_contact_ids" => ["leo_1_downlink_equator_prime_2"],
                 "deferred_contact_ids" => [],
                 "capacity_requirement_rows" => [
                   %{
                     "contact_id" => "leo_1_downlink_equator_prime_1",
                     "required_capacity_fraction" => 0.25,
                     "required_capacity_fraction_source" => "default_reduced_capacity_policy"
                   },
                   %{
                     "contact_id" => "leo_1_downlink_equator_prime_2",
                     "required_capacity_fraction" => 0.25,
                     "required_capacity_fraction_source" => "default_reduced_capacity_policy"
                   }
                 ],
                 "pack_status" => "all_fit"
               }
             ],
             "rows" => rows
           } = artifact["contact_allocation_report"]

    assert %{
             "contact_id" => "leo_1_downlink_equator_prime_2",
             "allocation_status" => "allocated",
             "effective_allocation_status" => "allocated",
             "allocation_reason" => "selected_by_reduced_station_capacity_pack",
             "required_capacity_fraction" => 0.25,
             "required_capacity_fraction_source" => "default_reduced_capacity_policy",
             "capacity_pack_status" => "selected_by_reduced_station_capacity_pack",
             "capacity_pack_capacity_fraction" => 0.5,
             "capacity_pack_used_fraction" => 0.5
           } = Enum.find(rows, &(&1["contact_id"] == "leo_1_downlink_equator_prime_2"))

    refute Enum.any?(
             artifact["invalidated_candidates"],
             &(&1["invalidated_reason"] == "dropped_by_contact_allocation")
           )

    review = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "review_type" => "contact_allocation_capacity_pack_review",
             "source" =>
               "candidate_refresh.contact_allocation_report.reduced_capacity_pack_groups",
             "required_operator_action" => "review_contact_allocation_capacity_pack",
             "capacity_fraction" => 0.5,
             "used_capacity_fraction" => 0.5,
             "default_required_capacity_fraction" => 0.25,
             "capacity_packed_contact_ids" => ["leo_1_downlink_equator_prime_2"],
             "capacity_requirement_rows" => [
               %{
                 "contact_id" => "leo_1_downlink_equator_prime_1",
                 "required_capacity_fraction_source" => "default_reduced_capacity_policy"
               },
               %{
                 "contact_id" => "leo_1_downlink_equator_prime_2",
                 "required_capacity_fraction_source" => "default_reduced_capacity_policy"
               }
             ]
           } =
             Enum.find(
               review["rows"],
               &(&1["review_type"] == "contact_allocation_capacity_pack_review")
             )

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "import_action" => "review_contact_allocation_capacity_pack",
             "source_review_type" => "contact_allocation_capacity_pack_review",
             "capacity_fraction" => 0.5,
             "used_capacity_fraction" => 0.5,
             "default_required_capacity_fraction" => 0.25,
             "capacity_packed_contact_ids" => ["leo_1_downlink_equator_prime_2"],
             "source_contact_allocation_capacity_pack" => %{
               "capacity_requirement_rows" => [
                 %{
                   "contact_id" => "leo_1_downlink_equator_prime_1",
                   "required_capacity_fraction_source" => "default_reduced_capacity_policy"
                 },
                 %{
                   "contact_id" => "leo_1_downlink_equator_prime_2",
                   "required_capacity_fraction_source" => "default_reduced_capacity_policy"
                 }
               ]
             }
           } =
             Enum.find(
               manifest["rows"],
               &(&1["source_review_type"] == "contact_allocation_capacity_pack_review")
             )

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(review)

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "drops same-spacecraft cross-station refreshed contact contention" do
    artifact =
      result_set_with_cross_station_overlapping_contacts()
      |> CandidateRefresh.build(
        candidate_refresh:
          refresh_request()
          |> Map.put("prior_candidate_activities", [
            %{
              "id" => "leo_1_downlink_equator_prime_1",
              "type" => "downlink",
              "scenario_id" => "leo_1",
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 300.0,
              "ends_at_s" => 420.0,
              "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1"
            }
          ]),
        generated_at: ~U[2026-05-14 00:00:00Z]
      )

    assert Enum.map(artifact["candidate_activities"], & &1["id"]) == [
             "leo_1_downlink_deep_space_net_1"
           ]

    assert Enum.map(artifact["contact_intents"], & &1["activity_id"]) == [
             "leo_1_downlink_deep_space_net_1"
           ]

    assert %{
             "input_contact_count" => 2,
             "allocated_contact_count" => 1,
             "returned_allocated_contact_count" => 1,
             "deferred_contact_count" => 1,
             "contact_contention_report" => %{
               "conflict_group_count" => 1,
               "conflict_groups" => [
                 %{
                   "id" => "spacecraft:leo_1:contention:1",
                   "resource_scope" => "spacecraft",
                   "ground_station_id" => "multi_station",
                   "ground_station_ids" => ["deep_space_net", "equator_prime"],
                   "spacecraft_id" => "leo_1",
                   "contact_ids" => [
                     "leo_1_downlink_deep_space_net_1",
                     "leo_1_downlink_equator_prime_1"
                   ],
                   "operator_action_reason" => "same_spacecraft_overlapping_contact_windows"
                 }
               ]
             },
             "rows" => allocation_rows
           } = artifact["contact_allocation_report"]

    assert %{
             "contact_id" => "leo_1_downlink_deep_space_net_1",
             "spacecraft_id" => "leo_1",
             "allocation_status" => "allocated",
             "allocation_reason" => "selected_by_contention_resolution",
             "contention_group_id" => "spacecraft:leo_1:contention:1"
           } =
             Enum.find(allocation_rows, &(&1["contact_id"] == "leo_1_downlink_deep_space_net_1"))

    assert %{
             "contact_id" => "leo_1_downlink_equator_prime_1",
             "spacecraft_id" => "leo_1",
             "allocation_status" => "deferred",
             "allocation_reason" => "same_spacecraft_contention",
             "selected_contact_id" => "leo_1_downlink_deep_space_net_1",
             "contention_group_id" => "spacecraft:leo_1:contention:1"
           } =
             Enum.find(allocation_rows, &(&1["contact_id"] == "leo_1_downlink_equator_prime_1"))

    assert [
             %{
               "id" => "leo_1_downlink_equator_prime_1",
               "invalidated_reason" => "dropped_by_contact_allocation",
               "replacement_candidate_id" => "leo_1_downlink_equator_prime_1"
             }
           ] = artifact["invalidated_candidates"]

    assert "contact allocation excluded refreshed contact candidates" in artifact["warnings"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp result_set_with_overlapping_contacts do
    ResultSet.new!(%{
      study_id: :candidate_refresh_demo,
      trajectory_results: [],
      event_results: [
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
                sample_count: 4
              }
            },
            %{
              type: :ground_station_access,
              starts_at: Epoch.new!(360.0, :tdb),
              ends_at: Epoch.new!(480.0, :tdb),
              metadata: %{
                max_elevation_deg: 72.0,
                minimum_elevation_deg: 6.0,
                sample_count: 4
              }
            }
          ],
          source: %{ground_station_id: :equator_prime}
        }
      ],
      errors: [],
      assumptions: %{propagator: OrbitalDynamics.Propagators.TwoBody, outputs: [:access_windows]},
      metadata: %{}
    })
  end

  defp result_set_with_cross_station_overlapping_contacts do
    ResultSet.new!(%{
      study_id: :candidate_refresh_demo,
      trajectory_results: [],
      event_results: [
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
                sample_count: 4
              }
            }
          ],
          source: %{ground_station_id: :equator_prime}
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
                max_elevation_deg: 72.0,
                minimum_elevation_deg: 6.0,
                sample_count: 4
              }
            }
          ],
          source: %{ground_station_id: :deep_space_net}
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
