defmodule OrbitalDynamics.CadenceImportWrappedResourcePlanningTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, Schema}

  test "candidate refresh import preserves wrapped contact-allocation reports" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_contact_allocation_import:001",
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "contact_allocation_report" => %{
            "schema_contract" => "contact_allocation_report.v1",
            "rows" => [
              %{
                "id" => "allocation:dl_wrapped_deferred",
                "contact_id" => "dl_wrapped_deferred",
                "type" => "downlink",
                "spacecraft_id" => "sat_1",
                "ground_station_id" => "equator_prime",
                "direction" => "downlink",
                "allocation_status" => "deferred",
                "allocation_reason" => "reduced_station_capacity",
                "selected" => false,
                "capacity_pack_group_id" => "station:equator_prime:capacity_pack:1",
                "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack",
                "required_capacity_fraction" => 0.3,
                "required_capacity_fraction_source" => "wrapped_contact_allocation_report.rows",
                "station_availability" => "available",
                "station_reservation_id" => "reservation:equator_prime:dl_wrapped_deferred",
                "station_reservation_expires_at_s" => 360.0,
                "station_reserved_by" => "ops",
                "station_reservation_status" => "held",
                "station_reservation_match_status" => "matched",
                "resource_blocking_dimension" => "antenna",
                "source_contact_candidate" => %{"id" => "dl_wrapped_deferred"},
                "source_resource_suppression" => %{
                  "suppressed_reason" => "antenna_unavailable"
                }
              }
            ],
            "reduced_capacity_pack_groups" => [
              %{
                "contention_group_id" => "station:equator_prime:capacity_pack:1",
                "ground_station_id" => "equator_prime",
                "capacity_fraction" => 0.5,
                "used_capacity_fraction" => 0.5,
                "default_required_capacity_fraction" => 0.25,
                "input_contact_ids" => ["dl_wrapped_primary", "dl_wrapped_deferred"],
                "selected_contact_ids" => ["dl_wrapped_primary"],
                "capacity_packed_contact_ids" => ["dl_wrapped_primary"],
                "deferred_contact_ids" => ["dl_wrapped_deferred"],
                "pack_status" => "packed_with_deferred_contacts"
              }
            ]
          }
        }
      ]
    }

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_contact_allocation_import:001",
             "row_count" => 2,
             "review_required_count" => 2,
             "import_action_counts" => %{
               "review_contact_allocation" => 1,
               "review_contact_allocation_capacity_pack" => 1
             },
             "source_review_type_counts" => %{
               "contact_allocation_review" => 1,
               "contact_allocation_capacity_pack_review" => 1
             }
           } = manifest

    assert %{
             "import_action" => "review_contact_allocation",
             "source_review_type" => "contact_allocation_review",
             "source_review_action" => "review_contact_allocation",
             "import_status" => "review_required_before_import",
             "approval_status" => "operator_review_required",
             "subject_id" => "dl_wrapped_deferred",
             "contact_id" => "dl_wrapped_deferred",
             "activity_id" => "dl_wrapped_deferred",
             "allocation_status" => "deferred",
             "allocation_reason" => "reduced_station_capacity",
             "ground_station_id" => "equator_prime",
             "capacity_pack_group_id" => "station:equator_prime:capacity_pack:1",
             "capacity_pack_status" => "deferred_by_reduced_station_capacity_pack",
             "station_reservation_id" => "reservation:equator_prime:dl_wrapped_deferred",
             "station_reservation_match_status" => "matched",
             "resource_blocking_dimension" => "antenna",
             "required_capacity_fraction" => 0.3,
             "required_capacity_fraction_source" => "wrapped_contact_allocation_report.rows",
             "has_cadence_import" => false,
             "source_contact_allocation" => %{
               "contact_id" => "dl_wrapped_deferred",
               "allocation_reason" => "reduced_station_capacity",
               "source_resource_suppression" => %{
                 "suppressed_reason" => "antenna_unavailable"
               }
             },
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.source_result_artifact[0].contact_allocation_report.rows",
               "review_type" => "contact_allocation_review",
               "source_contact_allocation" => %{
                 "contact_id" => "dl_wrapped_deferred",
                 "allocation_status" => "deferred"
               }
             }
           } =
             Enum.find(
               manifest["rows"],
               &(&1["import_action"] == "review_contact_allocation")
             )

    assert %{
             "import_action" => "review_contact_allocation_capacity_pack",
             "source_review_type" => "contact_allocation_capacity_pack_review",
             "source_review_action" => "review_contact_allocation_capacity_pack",
             "import_status" => "review_required_before_import",
             "approval_status" => "operator_review_required",
             "subject_id" => "station:equator_prime:capacity_pack:1",
             "ground_station_id" => "equator_prime",
             "capacity_fraction" => 0.5,
             "used_capacity_fraction" => 0.5,
             "default_required_capacity_fraction" => 0.25,
             "selected_contact_ids" => ["dl_wrapped_primary"],
             "deferred_contact_ids" => ["dl_wrapped_deferred"],
             "has_cadence_import" => false,
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.source_result_artifact[0].contact_allocation_report.reduced_capacity_pack_groups",
               "review_type" => "contact_allocation_capacity_pack_review",
               "source_contact_allocation_capacity_pack" => %{
                 "contention_group_id" => "station:equator_prime:capacity_pack:1",
                 "pack_status" => "packed_with_deferred_contacts"
               }
             }
           } =
             Enum.find(
               manifest["rows"],
               &(&1["import_action"] == "review_contact_allocation_capacity_pack")
             )

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  test "candidate refresh import preserves wrapped resource projection reports" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_resource_projection_import:001",
      "source_result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "source_resource_projection_report" => %{
            "schema_contract" => "resource_projection_report.v1",
            "model" => "thin_campaign_selected_activity_resource_projection",
            "projected_resources" => [
              %{
                "spacecraft_id" => "sat_1",
                "activity_count" => 2,
                "effective_activity_count" => 1,
                "ignored_activity_count" => 1,
                "ignored_activity_ids" => ["dl_rejected"],
                "observation_count" => 1,
                "downlink_count" => 0,
                "starting_storage_used_mb" => 950.0,
                "projected_storage_used_mb" => 1_020.0,
                "storage_capacity_mb" => 1_000.0,
                "projected_storage_margin" => -0.02,
                "storage_limited_downlinked_mb" => 42.0,
                "unused_downlink_capacity_mb" => 8.0,
                "resource_trust_boundary_status" => "declared",
                "activity_resource_flow" => [
                  %{
                    "activity_id" => "obs_wrapped_overflow",
                    "activity_type" => "observe",
                    "starts_at_s" => 10.0,
                    "storage_overflow_mb" => 12.0,
                    "battery_energy_consumed_wh" => 14.0,
                    "battery_energy_delta_wh" => 14.0
                  },
                  %{
                    "activity_id" => "dl_rejected",
                    "activity_type" => "downlink",
                    "starts_at_s" => 20.0,
                    "resource_effect_status" => "ignored",
                    "unused_downlink_capacity_mb" => 8.0
                  }
                ],
                "approval_requirements" => [
                  %{
                    "schema_contract" => "approval_requirement.v1",
                    "id" => "approval:resource_projection:sat_1:storage_overflow",
                    "activity_id" => "resource_projection:sat_1",
                    "activity_type" => "resource_projection",
                    "action" => "review_resource_projection",
                    "requirement_type" => "operator_review"
                  }
                ],
                "policy_decision" => %{
                  "schema_contract" => "policy_decision.v1",
                  "policy_bundle_id" => "resource_projection_authority_v1"
                }
              }
            ]
          },
          "resource_projection_flow_summary" => resource_projection_flow_summary()
        }
      ]
    }

    manifest = CadenceImport.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_resource_projection_import:001",
             "row_count" => 2,
             "review_required_count" => 2,
             "import_action_counts" => %{"review_resource_projection" => 2},
             "source_review_type_counts" => %{"resource_projection_review" => 2}
           } = manifest

    assert %{
             "import_action" => "review_resource_projection",
             "source_review_type" => "resource_projection_review",
             "source_review_action" => "review_resource_projection",
             "import_status" => "review_required_before_import",
             "approval_status" => "operator_review_required",
             "subject_id" => "sat_1",
             "spacecraft_id" => "sat_1",
             "activity_count" => 2,
             "effective_activity_count" => 1,
             "ignored_activity_count" => 1,
             "ignored_activity_ids" => ["dl_rejected"],
             "storage_limited_downlinked_mb" => 42.0,
             "unused_downlink_capacity_mb" => 8.0,
             "projected_storage_margin" => -0.02,
             "resource_flow_count" => 2,
             "peak_storage_overflow_mb" => 12.0,
             "peak_unused_downlink_capacity_mb" => 8.0,
             "first_resource_pressure_activity_id" => "obs_wrapped_overflow",
             "first_resource_pressure_kind" => "storage_overflow",
             "resource_trust_boundary_status" => "declared",
             "policy_bundle_id" => "resource_projection_authority_v1",
             "has_cadence_import" => false,
             "source_resource_projection" => %{
               "spacecraft_id" => "sat_1",
               "resource_trust_boundary_status" => "declared"
             },
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.source_result_artifact[0].source_resource_projection_report.projected_resources",
               "review_type" => "resource_projection_review",
               "source_resource_projection" => %{
                 "spacecraft_id" => "sat_1",
                 "activity_resource_flow" => [
                   %{"activity_id" => "obs_wrapped_overflow"},
                   %{"activity_id" => "dl_rejected"}
                 ]
               },
               "source_policy_decision" => %{
                 "policy_bundle_id" => "resource_projection_authority_v1"
               }
             }
           } =
             Enum.find(
               manifest["rows"],
               &(get_in(&1, ["source_review_row", "source"]) ==
                   "candidate_refresh.source_result_artifact[0].source_resource_projection_report.projected_resources")
             )

    assert %{
             "import_action" => "review_resource_projection",
             "source_review_type" => "resource_projection_review",
             "source_review_action" => "review_resource_projection",
             "import_status" => "review_required_before_import",
             "subject_id" => "leo_1",
             "spacecraft_id" => "leo_1",
             "activity_count" => 2,
             "effective_activity_count" => 2,
             "ignored_activity_count" => 0,
             "resource_flow_count" => 2,
             "total_battery_energy_consumed_wh" => 20.0,
             "total_battery_energy_generated_wh" => 5.0,
             "peak_storage_overflow_mb" => 10.0,
             "peak_downlink_shortfall_mb" => 5.0,
             "first_resource_pressure_activity_id" => "obs_early",
             "first_resource_pressure_kind" => "storage_overflow",
             "has_cadence_import" => false,
             "source_resource_projection_flow_summary" => %{
               "schema_contract" => "resource_projection_flow_summary.v1",
               "resource_flow_status" => "review_required",
               "source" => "flow_handoff"
             },
             "source_resource_projection" => %{
               "source_resource_projection_flow_summary" => %{
                 "schema_contract" => "resource_projection_flow_summary.v1"
               }
             },
             "source_review_row" => %{
               "source" =>
                 "candidate_refresh.source_result_artifact[0].resource_projection_flow_summary.projected_resources",
               "review_type" => "resource_projection_review",
               "source_resource_projection_flow_summary" => %{
                 "schema_contract" => "resource_projection_flow_summary.v1"
               }
             }
           } =
             Enum.find(
               manifest["rows"],
               &(get_in(&1, ["source_review_row", "source"]) ==
                   "candidate_refresh.source_result_artifact[0].resource_projection_flow_summary.projected_resources")
             )

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(manifest)
  end

  defp resource_projection_flow_summary do
    activities = [
      %{
        id: :dl_late,
        type: :downlink,
        scenario_id: :leo_1,
        starts_at_s: 20.0,
        estimated_throughput_mb: 10.0,
        estimated_energy_generated_wh: 5.0
      },
      %{
        id: :obs_early,
        type: :observe,
        scenario_id: :leo_1,
        starts_at_s: 10.0,
        collection_ends_at_s: 15.0,
        planned_delivery_at_s: 45.0,
        max_latency_s: 20.0,
        estimated_storage_mb: 30.0,
        estimated_energy_used_wh: 20.0
      }
    ]

    summaries = [
      %{
        spacecraft_id: :leo_1,
        storage_capacity_mb: 50.0,
        storage_used_mb: 30.0,
        downlink_capacity_mb: 5.0,
        battery_capacity_wh: 100.0,
        battery_energy_used_wh: 10.0
      }
    ]

    OrbitalDynamics.resource_projection_flow_report(activities, summaries, source: "flow_handoff")
  end
end
