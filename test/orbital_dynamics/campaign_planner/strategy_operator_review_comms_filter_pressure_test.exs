Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyOperatorReviewCommsFilterPressureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy derives communications refresh from operator review source rows" do
    prior_plan =
      base_plan(%{
        "operator_review_package" => %{
          "schema_contract" => "operator_review_package.v1",
          "source_artifact_type" => "campaign_strategy.v3",
          "review_count" => 8,
          "provenance" => %{"trust_boundary" => "ops_review_queue"},
          "rows" => [
            %{
              "id" => "operator_review:resource_projection:leo_1",
              "review_type" => "resource_projection_review",
              "source" => "resource_projection_report.projected_resources",
              "subject_id" => "leo_1",
              "spacecraft_id" => "leo_1",
              "approval_status" => "operator_review_required",
              "source_resource_projection" => %{
                "spacecraft_id" => "leo_1",
                "scenario_id" => "leo_1",
                "projected_storage_overflow_mb" => 25.0,
                "resource_source_quality" => "operator_supplied"
              }
            },
            %{
              "id" => "operator_review:resource_projection:leo_flat",
              "review_type" => "resource_projection_review",
              "source" => "resource_projection_report.projected_resources",
              "subject_id" => "leo_flat",
              "spacecraft_id" => "leo_flat",
              "scenario_id" => "leo_flat",
              "projected_storage_overflow_mb" => 18.0,
              "resource_source_quality" => "operator_supplied",
              "approval_status" => "operator_review_required"
            },
            %{
              "id" => "operator_review:resource_projection:leo_review_thermal",
              "review_type" => "resource_projection_review",
              "source" => "resource_projection_report.projected_resources",
              "subject_id" => "leo_review_thermal",
              "spacecraft_id" => "leo_review_thermal",
              "scenario_id" => "leo_review_thermal",
              "thermal_margin_c" => -1.25,
              "resource_pressure_status" => "resource_pressure",
              "resource_pressure_types" => ["thermal_margin_below_limit"],
              "resource_source_quality" => "operator_supplied",
              "approval_status" => "operator_review_required"
            },
            %{
              "id" => "operator_review:resource_projection:leo_review_activity_type",
              "review_type" => "resource_projection_review",
              "source" => "resource_projection_report.projected_resources",
              "subject_id" => "leo_review_activity_type",
              "spacecraft_id" => "leo_review_activity_type",
              "scenario_id" => "leo_review_activity_type",
              "resource_pressure_status" => "resource_availability_pressure",
              "resource_pressure_types" => ["activity_type_suppressed_by_resource_summary"],
              "suppressed_activity_types" => ["observe"],
              "source_activity_id" => "obs_review_activity_type",
              "resource_source_quality" => "operator_supplied",
              "approval_status" => "operator_review_required"
            },
            %{
              "id" => "operator_review:link_capacity:equator_prime",
              "review_type" => "link_capacity_review",
              "source" => "link_capacity_report.rows",
              "subject_id" => "equator_prime",
              "ground_station_id" => "equator_prime",
              "approval_status" => "operator_review_required",
              "source_link_capacity" => %{
                "id" => "link_capacity:equator_prime",
                "ground_station_id" => "equator_prime",
                "selected_downlink_shortfall_mb" => 60.0,
                "selected_capacity_adjusted_throughput_mb" => 20.0,
                "downlink_requirement_status" => "shortfall"
              }
            },
            %{
              "id" => "operator_review:link_capacity:polar_aux",
              "review_type" => "link_capacity_review",
              "source" => "link_capacity_report.rows",
              "subject_id" => "polar_aux",
              "ground_station_id" => "polar_aux",
              "approval_status" => "operator_review_required",
              "selected_downlink_shortfall_mb" => 47.0,
              "selected_capacity_adjusted_throughput_mb" => 13.0,
              "downlink_requirement_status" => "shortfall"
            },
            %{
              "id" => "operator_review:contact_allocation:dl_deferred",
              "review_type" => "contact_allocation_review",
              "source" => "contact_allocation_report.rows",
              "subject_id" => "dl_deferred",
              "contact_id" => "dl_deferred",
              "approval_status" => "operator_review_required",
              "source_contact_allocation" => %{
                "id" => "contact_allocation:dl_deferred",
                "contact_id" => "dl_deferred",
                "type" => "downlink",
                "allocation_status" => "deferred",
                "allocation_reason" => "same_station_contention",
                "ground_station_id" => "equator_prime",
                "scenario_id" => "leo_1",
                "starts_at_s" => 220.0,
                "ends_at_s" => 280.0,
                "required_downlink_mb" => 40.0
              }
            },
            %{
              "id" => "operator_review:contact_allocation:dl_flat_allocation_deferred",
              "review_type" => "contact_allocation_review",
              "source" => "contact_allocation_report.rows",
              "subject_id" => "dl_flat_allocation_deferred",
              "contact_id" => "dl_flat_allocation_deferred",
              "type" => "downlink",
              "allocation_status" => "deferred",
              "allocation_reason" => "same_station_contention",
              "ground_station_id" => "polar_aux",
              "scenario_id" => "leo_1",
              "starts_at_s" => 260.0,
              "ends_at_s" => 320.0,
              "required_downlink_mb" => 33.0,
              "approval_status" => "operator_review_required"
            },
            %{
              "id" => "operator_review:contact_contention:dl_review_deferred",
              "review_type" => "contact_contention_recommendation",
              "source" => "contact_contention_resolution_report.recommendations",
              "subject_id" => "station:equator_prime:contention:review",
              "ground_station_id" => "equator_prime",
              "approval_status" => "operator_review_required",
              "source_recommendation" => %{
                "group_id" => "station:equator_prime:contention:review",
                "ground_station_id" => "equator_prime",
                "starts_at_s" => 420.0,
                "ends_at_s" => 485.0,
                "selected_contact_id" => "dl_review_selected",
                "selected_priority_source" => "policy_contact_priority",
                "deferred_contact_ids" => ["dl_review_deferred"],
                "candidate_count" => 2,
                "selection_reason" => "highest_priority_highest_score",
                "resolution_selection_rule" => "highest_priority_highest_score",
                "direction" => "downlink",
                "directions" => ["downlink"],
                "source_contact_candidates" => [
                  downlink("dl_review_selected", 420.0, 470.0)
                  |> Map.put("estimated_throughput_mb", 25.0),
                  downlink("dl_review_deferred", 435.0, 485.0)
                  |> Map.put("estimated_throughput_mb", 35.0)
                  |> Map.put("source_window_id", "window:review:deferred")
                ]
              }
            },
            %{
              "id" => "operator_review:contact_contention:dl_flat_review_deferred",
              "review_type" => "contact_contention_recommendation",
              "source" => "contact_contention_resolution_report.recommendations",
              "subject_id" => "station:equator_prime:contention:flat_review",
              "group_id" => "station:equator_prime:contention:flat_review",
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 610.0,
              "ends_at_s" => 675.0,
              "selected_contact_id" => "dl_flat_review_selected",
              "selected_priority_source" => "policy_contact_priority",
              "deferred_contact_ids" => ["dl_flat_review_deferred"],
              "candidate_count" => 2,
              "selection_reason" => "highest_priority_highest_score",
              "resolution_selection_rule" => "highest_priority_highest_score",
              "direction" => "downlink",
              "directions" => ["downlink"],
              "approval_status" => "operator_review_required",
              "source_contact_candidates" => [
                downlink("dl_flat_review_selected", 610.0, 660.0)
                |> Map.put("estimated_throughput_mb", 28.0),
                downlink("dl_flat_review_deferred", 625.0, 675.0)
                |> Map.put("estimated_throughput_mb", 38.0)
                |> Map.put("source_window_id", "window:flat-review:deferred")
              ]
            }
          ]
        },
        "cadence_import_manifest" => %{
          "schema_contract" => "cadence_import_manifest.v1",
          "source_artifact_type" => "campaign_strategy.v3",
          "provenance" => %{"trust_boundary" => "cadence_comms_import_queue"},
          "rows" => [
            %{
              "id" => "cadence_import:resource_projection:leo_2",
              "import_action" => "review_resource_projection",
              "source_review_type" => "resource_projection_review",
              "approval_status" => "operator_review_required",
              "source_resource_projection" => %{
                "spacecraft_id" => "leo_2",
                "scenario_id" => "leo_2",
                "projected_storage_overflow_mb" => 15.0,
                "resource_source_quality" => "operator_supplied"
              }
            },
            %{
              "id" => "cadence_import:resource_projection:leo_flat_import",
              "import_action" => "review_resource_projection",
              "source_review_type" => "resource_projection_review",
              "spacecraft_id" => "leo_flat_import",
              "scenario_id" => "leo_flat_import",
              "projected_storage_overflow_mb" => 16.0,
              "resource_source_quality" => "operator_supplied",
              "approval_status" => "operator_review_required"
            },
            %{
              "id" => "cadence_import:resource_projection:leo_flat_import_thermal",
              "import_action" => "review_resource_projection",
              "source_review_type" => "resource_projection_review",
              "spacecraft_id" => "leo_flat_import_thermal",
              "scenario_id" => "leo_flat_import_thermal",
              "thermal_margin_c" => -2.5,
              "resource_pressure_status" => "resource_pressure",
              "resource_pressure_types" => ["thermal_margin_below_limit"],
              "resource_source_quality" => "operator_supplied",
              "approval_status" => "operator_review_required"
            },
            %{
              "id" => "cadence_import:resource_projection:leo_flat_import_payload",
              "import_action" => "review_resource_projection",
              "source_review_type" => "resource_projection_review",
              "spacecraft_id" => "leo_flat_import_payload",
              "scenario_id" => "leo_flat_import_payload",
              "payload_available" => false,
              "resource_pressure_status" => "resource_availability_pressure",
              "resource_pressure_types" => ["payload_unavailable"],
              "resource_source_quality" => "operator_supplied",
              "approval_status" => "operator_review_required"
            },
            %{
              "id" => "cadence_import:resource_projection:leo_flat_import_activity_type",
              "import_action" => "review_resource_projection",
              "source_review_type" => "resource_projection_review",
              "spacecraft_id" => "leo_flat_import_activity_type",
              "scenario_id" => "leo_flat_import_activity_type",
              "resource_pressure_status" => "resource_availability_pressure",
              "resource_pressure_types" => [
                "activity_type_incompatible_with_resource_summary"
              ],
              "incompatible_activity_types" => ["downlink"],
              "source_activity_ids" => ["dl_flat_import_activity_type"],
              "resource_source_quality" => "operator_supplied",
              "approval_status" => "operator_review_required"
            },
            %{
              "id" => "cadence_import:link_capacity:deep_space_net",
              "import_action" => "review_link_capacity",
              "source_review_type" => "link_capacity_review",
              "approval_status" => "operator_review_required",
              "source_link_capacity" => %{
                "id" => "link_capacity:deep_space_net",
                "ground_station_id" => "deep_space_net",
                "selected_downlink_shortfall_mb" => 55.0,
                "selected_capacity_adjusted_throughput_mb" => 15.0,
                "downlink_requirement_status" => "shortfall"
              }
            },
            %{
              "id" => "cadence_import:link_capacity:southern_pass",
              "import_action" => "review_link_capacity",
              "source_review_type" => "link_capacity_review",
              "ground_station_id" => "southern_pass",
              "approval_status" => "operator_review_required",
              "selected_downlink_shortfall_mb" => 49.0,
              "selected_capacity_adjusted_throughput_mb" => 19.0,
              "downlink_requirement_status" => "shortfall"
            },
            %{
              "id" => "cadence_import:contact_allocation:dl_import_deferred",
              "import_action" => "review_contact_allocation",
              "source_review_type" => "contact_allocation_review",
              "approval_status" => "operator_review_required",
              "source_contact_allocation" => %{
                "id" => "contact_allocation:dl_import_deferred",
                "contact_id" => "dl_import_deferred",
                "type" => "downlink",
                "allocation_status" => "deferred",
                "allocation_reason" => "same_station_contention",
                "ground_station_id" => "deep_space_net",
                "scenario_id" => "leo_2",
                "starts_at_s" => 320.0,
                "ends_at_s" => 380.0,
                "required_downlink_mb" => 45.0
              }
            },
            %{
              "id" => "cadence_import:contact_allocation:dl_flat_import_allocation_deferred",
              "import_action" => "review_contact_allocation",
              "source_review_type" => "contact_allocation_review",
              "contact_id" => "dl_flat_import_allocation_deferred",
              "type" => "downlink",
              "allocation_status" => "deferred",
              "allocation_reason" => "same_station_contention",
              "ground_station_id" => "southern_pass",
              "scenario_id" => "leo_2",
              "starts_at_s" => 360.0,
              "ends_at_s" => 420.0,
              "required_downlink_mb" => 37.0,
              "approval_status" => "operator_review_required"
            },
            %{
              "id" => "cadence_import:contact_contention:dl_import_contention_deferred",
              "import_action" => "review_contact_contention_resolution",
              "source_review_type" => "contact_contention_recommendation",
              "approval_status" => "operator_review_required",
              "source_recommendation" => %{
                "group_id" => "station:deep_space_net:contention:import",
                "ground_station_id" => "deep_space_net",
                "starts_at_s" => 520.0,
                "ends_at_s" => 590.0,
                "selected_contact_id" => "dl_import_contention_selected",
                "selected_priority_source" => "policy_contact_priority",
                "deferred_contact_ids" => ["dl_import_contention_deferred"],
                "candidate_count" => 2,
                "selection_reason" => "highest_priority_highest_score",
                "resolution_selection_rule" => "highest_priority_highest_score",
                "direction" => "downlink",
                "directions" => ["downlink"],
                "source_contact_candidates" => [
                  downlink("dl_import_contention_selected", 520.0, 575.0)
                  |> Map.put("ground_station_id", "deep_space_net")
                  |> Map.put("estimated_throughput_mb", 30.0),
                  downlink("dl_import_contention_deferred", 540.0, 590.0)
                  |> Map.put("ground_station_id", "deep_space_net")
                  |> Map.put("estimated_throughput_mb", 50.0)
                  |> Map.put("source_window_id", "window:import:deferred")
                ]
              }
            },
            %{
              "id" => "cadence_import:contact_contention:dl_flat_import_contention_deferred",
              "import_action" => "review_contact_contention_resolution",
              "source_review_type" => "contact_contention_recommendation",
              "group_id" => "station:deep_space_net:contention:flat_import",
              "ground_station_id" => "deep_space_net",
              "starts_at_s" => 700.0,
              "ends_at_s" => 760.0,
              "selected_contact_id" => "dl_flat_import_contention_selected",
              "selected_priority_source" => "policy_contact_priority",
              "deferred_contact_ids" => ["dl_flat_import_contention_deferred"],
              "candidate_count" => 2,
              "selection_reason" => "highest_priority_highest_score",
              "resolution_selection_rule" => "highest_priority_highest_score",
              "direction" => "downlink",
              "directions" => ["downlink"],
              "approval_status" => "operator_review_required",
              "source_contact_candidates" => [
                downlink("dl_flat_import_contention_selected", 700.0, 745.0)
                |> Map.put("ground_station_id", "deep_space_net")
                |> Map.put("estimated_throughput_mb", 32.0),
                downlink("dl_flat_import_contention_deferred", 715.0, 760.0)
                |> Map.put("ground_station_id", "deep_space_net")
                |> Map.put("estimated_throughput_mb", 52.0)
                |> Map.put("source_window_id", "window:flat-import:deferred")
              ]
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    resource_branch = branch(artifact, "derived_projected_resource_pressure_leo_1")

    assert Enum.any?(
             resource_branch["events"],
             &(&1["type"] == "resource_margin_pressure" and
                 &1["resource_field"] == "storage_margin" and
                 &1["feedback_source"] ==
                   "prior_plan.operator_review_package.rows.source_resource_projection" and
                 &1["trust_boundary"] == "ops_review_queue")
           )

    cadence_resource_branch = branch(artifact, "derived_projected_resource_pressure_leo_2")

    assert Enum.any?(
             cadence_resource_branch["events"],
             &(&1["type"] == "resource_margin_pressure" and
                 &1["resource_field"] == "storage_margin" and
                 &1["feedback_source"] ==
                   "prior_plan.cadence_import_manifest.rows.source_resource_projection" and
                 &1["trust_boundary"] == "cadence_comms_import_queue")
           )

    flat_resource_branch = branch(artifact, "derived_projected_resource_pressure_leo_flat")

    assert Enum.any?(
             flat_resource_branch["events"],
             &(&1["type"] == "resource_margin_pressure" and
                 &1["resource_field"] == "storage_margin" and
                 &1["feedback_source"] ==
                   "prior_plan.operator_review_package.rows.resource_projection_review" and
                 &1["trust_boundary"] == "ops_review_queue")
           )

    flat_cadence_resource_branch =
      branch(artifact, "derived_projected_resource_pressure_leo_flat_import")

    assert Enum.any?(
             flat_cadence_resource_branch["events"],
             &(&1["type"] == "resource_margin_pressure" and
                 &1["resource_field"] == "storage_margin" and
                 &1["feedback_source"] ==
                   "prior_plan.cadence_import_manifest.rows.resource_projection_review" and
                 &1["trust_boundary"] == "cadence_comms_import_queue")
           )

    review_thermal_branch =
      branch(artifact, "derived_projected_resource_pressure_leo_review_thermal")

    assert review_thermal_event =
             Enum.find(
               review_thermal_branch["events"],
               &(&1["type"] == "resource_margin_pressure" and
                   &1["resource_field"] == "thermal_margin_c")
             )

    assert review_thermal_event["thermal_margin_c"] == -1.25
    assert review_thermal_event["thermal_margin_c_threshold"] == 0.0

    assert review_thermal_event["feedback_source"] ==
             "prior_plan.operator_review_package.rows.resource_projection_review"

    assert review_thermal_event["trust_boundary"] == "ops_review_queue"

    flat_cadence_thermal_branch =
      branch(artifact, "derived_projected_resource_pressure_leo_flat_import_thermal")

    assert flat_cadence_thermal_event =
             Enum.find(
               flat_cadence_thermal_branch["events"],
               &(&1["type"] == "resource_margin_pressure" and
                   &1["resource_field"] == "thermal_margin_c")
             )

    assert flat_cadence_thermal_event["thermal_margin_c"] == -2.5
    assert flat_cadence_thermal_event["thermal_margin_c_threshold"] == 0.0

    assert flat_cadence_thermal_event["feedback_source"] ==
             "prior_plan.cadence_import_manifest.rows.resource_projection_review"

    assert flat_cadence_thermal_event["trust_boundary"] == "cadence_comms_import_queue"

    flat_cadence_payload_branch =
      branch(artifact, "derived_projected_resource_pressure_leo_flat_import_payload")

    assert %{
             "type" => "resource_availability_constraint",
             "spacecraft_id" => "leo_flat_import_payload",
             "resource_field" => "payload_available",
             "payload_available" => false,
             "available" => false,
             "feedback_source" =>
               "prior_plan.cadence_import_manifest.rows.resource_projection_review",
             "trust_boundary" => "cadence_comms_import_queue"
           } =
             Enum.find(
               flat_cadence_payload_branch["events"],
               &(&1["type"] == "resource_availability_constraint" and
                   &1["resource_field"] == "payload_available")
             )

    review_activity_type_branch =
      branch(artifact, "derived_projected_resource_pressure_leo_review_activity_type")

    assert %{
             "type" => "degraded_spacecraft",
             "spacecraft_id" => "leo_review_activity_type",
             "mode" => "resource_activity_type_constraint",
             "incompatible_activity_types" => ["observe"],
             "source_activity_id" => "obs_review_activity_type",
             "source_activity_ids" => ["obs_review_activity_type"],
             "derivation_reasons" => [
               "projected_activity_type_suppressed_by_resource_summary"
             ],
             "feedback_source" =>
               "prior_plan.operator_review_package.rows.resource_projection_review",
             "trust_boundary" => "ops_review_queue"
           } =
             Enum.find(
               review_activity_type_branch["events"],
               &(&1["type"] == "degraded_spacecraft")
             )

    flat_cadence_activity_type_branch =
      branch(artifact, "derived_projected_resource_pressure_leo_flat_import_activity_type")

    assert %{
             "type" => "degraded_spacecraft",
             "spacecraft_id" => "leo_flat_import_activity_type",
             "mode" => "resource_activity_type_constraint",
             "incompatible_activity_types" => ["downlink"],
             "source_activity_id" => "dl_flat_import_activity_type",
             "source_activity_ids" => ["dl_flat_import_activity_type"],
             "derivation_reasons" => [
               "projected_activity_type_incompatible_with_resource_summary"
             ],
             "feedback_source" =>
               "prior_plan.cadence_import_manifest.rows.resource_projection_review",
             "trust_boundary" => "cadence_comms_import_queue"
           } =
             Enum.find(
               flat_cadence_activity_type_branch["events"],
               &(&1["type"] == "degraded_spacecraft")
             )

    link_branch = branch(artifact, "derived_link_capacity_pressure_equator_prime")

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "equator_prime",
             "required_downlink_mb" => 60.0,
             "selected_capacity_adjusted_throughput_mb" => 20.0,
             "feedback_source" => "prior_plan.operator_review_package.rows.source_link_capacity",
             "feedback_scope" => "link_capacity",
             "trust_boundary" => "ops_review_queue"
           } = List.first(link_branch["events"])

    cadence_link_branch = branch(artifact, "derived_link_capacity_pressure_deep_space_net")

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "deep_space_net",
             "required_downlink_mb" => 55.0,
             "selected_capacity_adjusted_throughput_mb" => 15.0,
             "feedback_source" => "prior_plan.cadence_import_manifest.rows.source_link_capacity",
             "feedback_scope" => "link_capacity",
             "trust_boundary" => "cadence_comms_import_queue"
           } = List.first(cadence_link_branch["events"])

    flat_link_branch = branch(artifact, "derived_link_capacity_pressure_polar_aux")

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "polar_aux",
             "required_downlink_mb" => 47.0,
             "selected_capacity_adjusted_throughput_mb" => 13.0,
             "feedback_source" => "prior_plan.operator_review_package.rows.link_capacity_review",
             "feedback_scope" => "link_capacity",
             "trust_boundary" => "ops_review_queue"
           } = List.first(flat_link_branch["events"])

    flat_cadence_link_branch = branch(artifact, "derived_link_capacity_pressure_southern_pass")

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "southern_pass",
             "required_downlink_mb" => 49.0,
             "selected_capacity_adjusted_throughput_mb" => 19.0,
             "feedback_source" => "prior_plan.cadence_import_manifest.rows.link_capacity_review",
             "feedback_scope" => "link_capacity",
             "trust_boundary" => "cadence_comms_import_queue"
           } = List.first(flat_cadence_link_branch["events"])

    allocation_branch =
      branch(artifact, "derived_contact_allocation_pressure_deferred_dl_deferred")

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "equator_prime",
             "required_downlink_mb" => 40.0,
             "contact_id" => "dl_deferred",
             "allocation_status" => "deferred",
             "feedback_source" =>
               "prior_plan.operator_review_package.rows.source_contact_allocation",
             "feedback_scope" => "contact_allocation",
             "trust_boundary" => "ops_review_queue"
           } = List.first(allocation_branch["events"])

    cadence_allocation_branch =
      branch(artifact, "derived_contact_allocation_pressure_deferred_dl_import_deferred")

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "deep_space_net",
             "required_downlink_mb" => 45.0,
             "contact_id" => "dl_import_deferred",
             "allocation_status" => "deferred",
             "feedback_source" =>
               "prior_plan.cadence_import_manifest.rows.source_contact_allocation",
             "feedback_scope" => "contact_allocation",
             "trust_boundary" => "cadence_comms_import_queue"
           } = List.first(cadence_allocation_branch["events"])

    flat_allocation_branch =
      branch(artifact, "derived_contact_allocation_pressure_deferred_dl_flat_allocation_deferred")

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "polar_aux",
             "required_downlink_mb" => 33.0,
             "contact_id" => "dl_flat_allocation_deferred",
             "allocation_status" => "deferred",
             "feedback_source" =>
               "prior_plan.operator_review_package.rows.contact_allocation_review",
             "feedback_scope" => "contact_allocation",
             "trust_boundary" => "ops_review_queue"
           } = List.first(flat_allocation_branch["events"])

    flat_cadence_allocation_branch =
      branch(
        artifact,
        "derived_contact_allocation_pressure_deferred_dl_flat_import_allocation_deferred"
      )

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "southern_pass",
             "required_downlink_mb" => 37.0,
             "contact_id" => "dl_flat_import_allocation_deferred",
             "allocation_status" => "deferred",
             "feedback_source" =>
               "prior_plan.cadence_import_manifest.rows.contact_allocation_review",
             "feedback_scope" => "contact_allocation",
             "trust_boundary" => "cadence_comms_import_queue"
           } = List.first(flat_cadence_allocation_branch["events"])

    review_contention_branch =
      branch(artifact, "derived_contact_contention_pressure_deferred_dl_review_deferred")

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "equator_prime",
             "required_downlink_mb" => 35.0,
             "contact_id" => "dl_review_deferred",
             "selected_contact_id" => "dl_review_selected",
             "feedback_source" => "prior_plan.operator_review_package.rows.source_recommendation",
             "feedback_scope" => "contact_contention_resolution",
             "trust_boundary" => "ops_review_queue"
           } = List.first(review_contention_branch["events"])

    flat_review_contention_branch =
      branch(artifact, "derived_contact_contention_pressure_deferred_dl_flat_review_deferred")

    assert %{
             "type" => "downlink_completion_gap",
             "required_downlink_mb" => 38.0,
             "contact_id" => "dl_flat_review_deferred",
             "selected_contact_id" => "dl_flat_review_selected",
             "feedback_source" =>
               "prior_plan.operator_review_package.rows.contact_contention_recommendation",
             "feedback_scope" => "contact_contention_resolution",
             "trust_boundary" => "ops_review_queue"
           } = List.first(flat_review_contention_branch["events"])

    cadence_contention_branch =
      branch(
        artifact,
        "derived_contact_contention_pressure_deferred_dl_import_contention_deferred"
      )

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "deep_space_net",
             "required_downlink_mb" => 50.0,
             "contact_id" => "dl_import_contention_deferred",
             "selected_contact_id" => "dl_import_contention_selected",
             "feedback_source" => "prior_plan.cadence_import_manifest.rows.source_recommendation",
             "feedback_scope" => "contact_contention_resolution",
             "trust_boundary" => "cadence_comms_import_queue"
           } = List.first(cadence_contention_branch["events"])

    flat_cadence_contention_branch =
      branch(
        artifact,
        "derived_contact_contention_pressure_deferred_dl_flat_import_contention_deferred"
      )

    assert %{
             "type" => "downlink_completion_gap",
             "required_downlink_mb" => 52.0,
             "contact_id" => "dl_flat_import_contention_deferred",
             "selected_contact_id" => "dl_flat_import_contention_selected",
             "feedback_source" =>
               "prior_plan.cadence_import_manifest.rows.contact_contention_recommendation",
             "feedback_scope" => "contact_contention_resolution",
             "trust_boundary" => "cadence_comms_import_queue"
           } = List.first(flat_cadence_contention_branch["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives filter pressure from operator review suppression source rows" do
    prior_plan =
      base_plan(%{
        "operator_review_package" => %{
          "schema_contract" => "operator_review_package.v1",
          "source_artifact_type" => "campaign_repair.v2",
          "review_count" => 2,
          "provenance" => %{"trust_boundary" => "ops_review_queue"},
          "rows" => [
            %{
              "id" => "operator_review:contact_suppression:dl_reserved",
              "review_type" => "contact_suppression",
              "approval_status" => "operator_review_required",
              "source_contact_suppression" => %{
                "id" => "dl_reserved",
                "type" => "downlink",
                "scenario_id" => "leo_1",
                "ground_station_id" => "equator_prime",
                "starts_at_s" => 220.0,
                "ends_at_s" => 280.0,
                "suppressed_reason" => "station_reserved",
                "review_status" => "operator_review_required",
                "station_reservation_id" => "reservation_alpha",
                "station_reserved_by" => "leo_1",
                "station_reservation_status" => "confirmed",
                "station_reservation_match_status" => "unmatched_overlap",
                "required_downlink_mb" => 35.0
              }
            },
            %{
              "id" => "operator_review:contact_suppression:dl_flat_reserved",
              "review_type" => "contact_suppression",
              "contact_id" => "dl_flat_reserved",
              "type" => "downlink",
              "scenario_id" => "leo_1",
              "ground_station_id" => "polar_aux",
              "starts_at_s" => 240.0,
              "ends_at_s" => 300.0,
              "suppressed_reason" => "station_reserved",
              "review_status" => "operator_review_required",
              "station_reservation_id" => "reservation_flat_alpha",
              "station_reserved_by" => "leo_1",
              "station_reservation_status" => "confirmed",
              "station_reservation_match_status" => "unmatched_overlap",
              "required_downlink_mb" => 31.0,
              "approval_status" => "operator_review_required"
            },
            %{
              "id" => "operator_review:resource_suppression:dl_antenna",
              "review_type" => "resource_suppression",
              "approval_status" => "operator_review_required",
              "source_resource_suppression" => %{
                "id" => "dl_antenna",
                "type" => "downlink",
                "scenario_id" => "leo_1",
                "spacecraft_id" => "leo_1",
                "ground_station_id" => "equator_prime",
                "starts_at_s" => 300.0,
                "ends_at_s" => 360.0,
                "suppressed_reason" => "antenna_unavailable",
                "antenna_available" => false,
                "resource_source_quality" => "operator_supplied",
                "resource_trust_boundary_status" => "declared"
              }
            },
            %{
              "id" => "operator_review:resource_suppression:dl_flat_antenna",
              "review_type" => "resource_suppression",
              "activity_id" => "dl_flat_antenna",
              "type" => "downlink",
              "scenario_id" => "leo_1",
              "spacecraft_id" => "leo_1",
              "ground_station_id" => "polar_aux",
              "starts_at_s" => 340.0,
              "ends_at_s" => 400.0,
              "suppressed_reason" => "antenna_unavailable",
              "antenna_available" => false,
              "resource_source_quality" => "operator_supplied",
              "resource_trust_boundary_status" => "declared",
              "approval_status" => "operator_review_required"
            }
          ]
        },
        "cadence_import_manifest" => %{
          "schema_contract" => "cadence_import_manifest.v1",
          "source_artifact_type" => "campaign_repair.v2",
          "provenance" => %{"trust_boundary" => "cadence_filter_import_queue"},
          "rows" => [
            %{
              "id" => "cadence_import:contact_suppression:dl_import_reserved",
              "import_action" => "review_contact_suppression",
              "source_review_type" => "contact_suppression",
              "approval_status" => "operator_review_required",
              "source_contact_suppression" => %{
                "id" => "dl_import_reserved",
                "type" => "downlink",
                "scenario_id" => "leo_2",
                "ground_station_id" => "deep_space_net",
                "starts_at_s" => 420.0,
                "ends_at_s" => 480.0,
                "suppressed_reason" => "station_reserved",
                "review_status" => "operator_review_required",
                "station_reservation_id" => "reservation_beta",
                "station_reserved_by" => "leo_2",
                "station_reservation_status" => "confirmed",
                "station_reservation_match_status" => "unmatched_overlap",
                "required_downlink_mb" => 30.0
              }
            },
            %{
              "id" => "cadence_import:contact_suppression:dl_flat_import_reserved",
              "import_action" => "review_contact_suppression",
              "source_review_type" => "contact_suppression",
              "contact_id" => "dl_flat_import_reserved",
              "type" => "downlink",
              "scenario_id" => "leo_2",
              "ground_station_id" => "southern_pass",
              "starts_at_s" => 450.0,
              "ends_at_s" => 510.0,
              "suppressed_reason" => "station_reserved",
              "review_status" => "operator_review_required",
              "station_reservation_id" => "reservation_flat_beta",
              "station_reserved_by" => "leo_2",
              "station_reservation_status" => "confirmed",
              "station_reservation_match_status" => "unmatched_overlap",
              "required_downlink_mb" => 29.0,
              "approval_status" => "operator_review_required"
            },
            %{
              "id" => "cadence_import:resource_suppression:dl_import_antenna",
              "import_action" => "review_resource_suppression",
              "source_review_type" => "resource_suppression",
              "approval_status" => "operator_review_required",
              "source_resource_suppression" => %{
                "id" => "dl_import_antenna",
                "type" => "downlink",
                "scenario_id" => "leo_2",
                "spacecraft_id" => "leo_2",
                "ground_station_id" => "deep_space_net",
                "starts_at_s" => 500.0,
                "ends_at_s" => 560.0,
                "suppressed_reason" => "antenna_unavailable",
                "antenna_available" => false,
                "resource_source_quality" => "operator_supplied",
                "resource_trust_boundary_status" => "declared"
              }
            },
            %{
              "id" => "cadence_import:resource_suppression:dl_flat_import_antenna",
              "import_action" => "review_resource_suppression",
              "source_review_type" => "resource_suppression",
              "activity_id" => "dl_flat_import_antenna",
              "type" => "downlink",
              "scenario_id" => "leo_2",
              "spacecraft_id" => "leo_2",
              "ground_station_id" => "southern_pass",
              "starts_at_s" => 540.0,
              "ends_at_s" => 600.0,
              "suppressed_reason" => "antenna_unavailable",
              "antenna_available" => false,
              "resource_source_quality" => "operator_supplied",
              "resource_trust_boundary_status" => "declared",
              "approval_status" => "operator_review_required"
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    contact_branch =
      branch(artifact, "derived_contact_filter_pressure_station_reserved_dl_reserved")

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "equator_prime",
             "required_downlink_mb" => 35.0,
             "contact_id" => "dl_reserved",
             "station_reservation_id" => "reservation_alpha",
             "station_reservation_match_status" => "unmatched_overlap",
             "feedback_source" =>
               "prior_plan.operator_review_package.rows.source_contact_suppression",
             "feedback_scope" => "contact_filter",
             "trust_boundary" => "ops_review_queue"
           } = List.first(contact_branch["events"])

    cadence_contact_branch =
      branch(artifact, "derived_contact_filter_pressure_station_reserved_dl_import_reserved")

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "deep_space_net",
             "required_downlink_mb" => 30.0,
             "contact_id" => "dl_import_reserved",
             "station_reservation_id" => "reservation_beta",
             "station_reservation_match_status" => "unmatched_overlap",
             "feedback_source" =>
               "prior_plan.cadence_import_manifest.rows.source_contact_suppression",
             "feedback_scope" => "contact_filter",
             "trust_boundary" => "cadence_filter_import_queue"
           } = List.first(cadence_contact_branch["events"])

    flat_contact_branch =
      branch(artifact, "derived_contact_filter_pressure_station_reserved_dl_flat_reserved")

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "polar_aux",
             "required_downlink_mb" => 31.0,
             "contact_id" => "dl_flat_reserved",
             "station_reservation_id" => "reservation_flat_alpha",
             "station_reservation_match_status" => "unmatched_overlap",
             "feedback_source" => "prior_plan.operator_review_package.rows.contact_suppression",
             "feedback_scope" => "contact_filter",
             "trust_boundary" => "ops_review_queue"
           } = List.first(flat_contact_branch["events"])

    flat_cadence_contact_branch =
      branch(artifact, "derived_contact_filter_pressure_station_reserved_dl_flat_import_reserved")

    assert %{
             "type" => "downlink_completion_gap",
             "ground_station_id" => "southern_pass",
             "required_downlink_mb" => 29.0,
             "contact_id" => "dl_flat_import_reserved",
             "station_reservation_id" => "reservation_flat_beta",
             "station_reservation_match_status" => "unmatched_overlap",
             "feedback_source" => "prior_plan.cadence_import_manifest.rows.contact_suppression",
             "feedback_scope" => "contact_filter",
             "trust_boundary" => "cadence_filter_import_queue"
           } = List.first(flat_cadence_contact_branch["events"])

    resource_branch =
      branch(artifact, "derived_resource_filter_pressure_antenna_unavailable_dl_antenna")

    assert %{
             "type" => "resource_availability_constraint",
             "resource_field" => "antenna_available",
             "available" => false,
             "source_activity_id" => "dl_antenna",
             "feedback_source" =>
               "prior_plan.operator_review_package.rows.source_resource_suppression",
             "feedback_scope" => "resource_filter",
             "trust_boundary" => "ops_review_queue"
           } = List.first(resource_branch["events"])

    cadence_resource_branch =
      branch(artifact, "derived_resource_filter_pressure_antenna_unavailable_dl_import_antenna")

    assert %{
             "type" => "resource_availability_constraint",
             "resource_field" => "antenna_available",
             "available" => false,
             "source_activity_id" => "dl_import_antenna",
             "feedback_source" =>
               "prior_plan.cadence_import_manifest.rows.source_resource_suppression",
             "feedback_scope" => "resource_filter",
             "trust_boundary" => "cadence_filter_import_queue"
           } = List.first(cadence_resource_branch["events"])

    flat_resource_branch =
      branch(artifact, "derived_resource_filter_pressure_antenna_unavailable_dl_flat_antenna")

    assert %{
             "type" => "resource_availability_constraint",
             "resource_field" => "antenna_available",
             "available" => false,
             "source_activity_id" => "dl_flat_antenna",
             "feedback_source" => "prior_plan.operator_review_package.rows.resource_suppression",
             "feedback_scope" => "resource_filter",
             "trust_boundary" => "ops_review_queue"
           } = List.first(flat_resource_branch["events"])

    flat_cadence_resource_branch =
      branch(
        artifact,
        "derived_resource_filter_pressure_antenna_unavailable_dl_flat_import_antenna"
      )

    assert %{
             "type" => "resource_availability_constraint",
             "resource_field" => "antenna_available",
             "available" => false,
             "source_activity_id" => "dl_flat_import_antenna",
             "feedback_source" => "prior_plan.cadence_import_manifest.rows.resource_suppression",
             "feedback_scope" => "resource_filter",
             "trust_boundary" => "cadence_filter_import_queue"
           } = List.first(flat_cadence_resource_branch["events"])

    assert resource_branch["repair_result"]["source_resource_filter_report"][
             "suppressed_candidate_count"
           ] >= 1

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy replays allocation resource suppressions from review and Cadence import rows" do
    prior_plan =
      base_plan(%{
        "operator_review_package" => %{
          "schema_contract" => "operator_review_package.v1",
          "source_artifact_type" => "contact_allocation_report.v1",
          "provenance" => %{"trust_boundary" => "ops_allocation_review"},
          "rows" => [
            %{
              "id" => "operator_review:contact_allocation:dl_review_resource_blocked",
              "review_type" => "contact_allocation_review",
              "approval_status" => "operator_review_required",
              "source_contact_allocation" => %{
                "contact_id" => "dl_review_resource_blocked",
                "type" => "downlink",
                "scenario_id" => "leo_1",
                "spacecraft_id" => "leo_1",
                "ground_station_id" => "equator_prime",
                "starts_at_s" => 620.0,
                "ends_at_s" => 680.0,
                "allocation_status" => "blocked",
                "allocation_reason" => "antenna_unavailable",
                "suppressed_reason" => "antenna_unavailable",
                "required_downlink_mb" => 34.0,
                "resource_source_quality" => "operator_supplied",
                "resource_trust_boundary_status" => "declared",
                "source_resource_suppression" => %{
                  "id" => "dl_review_resource_blocked",
                  "type" => "downlink",
                  "scenario_id" => "leo_1",
                  "spacecraft_id" => "leo_1",
                  "suppressed_reason" => "antenna_unavailable",
                  "antenna_available" => false,
                  "resource_source_quality" => "operator_supplied",
                  "resource_trust_boundary_status" => "declared"
                }
              }
            }
          ]
        },
        "cadence_import_manifest" => %{
          "schema_contract" => "cadence_import_manifest.v1",
          "source_artifact_type" => "contact_allocation_report.v1",
          "provenance" => %{"trust_boundary" => "cadence_allocation_import"},
          "rows" => [
            %{
              "id" => "cadence_import:contact_allocation:dl_import_resource_blocked",
              "import_action" => "review_contact_allocation",
              "source_review_type" => "contact_allocation_review",
              "approval_status" => "operator_review_required",
              "source_contact_allocation" => %{
                "contact_id" => "dl_import_resource_blocked",
                "type" => "downlink",
                "scenario_id" => "leo_2",
                "spacecraft_id" => "leo_2",
                "ground_station_id" => "deep_space_net",
                "starts_at_s" => 700.0,
                "ends_at_s" => 760.0,
                "allocation_status" => "blocked",
                "allocation_reason" => "payload_unavailable",
                "suppressed_reason" => "payload_unavailable",
                "required_downlink_mb" => 42.0,
                "resource_source_quality" => "operator_supplied",
                "resource_trust_boundary_status" => "declared",
                "source_resource_suppression" => %{
                  "id" => "dl_import_resource_blocked",
                  "type" => "downlink",
                  "scenario_id" => "leo_2",
                  "spacecraft_id" => "leo_2",
                  "suppressed_reason" => "payload_unavailable",
                  "payload_available" => false,
                  "resource_source_quality" => "operator_supplied",
                  "resource_trust_boundary_status" => "declared"
                }
              }
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    review_allocation_branch =
      branch(artifact, "derived_contact_allocation_pressure_blocked_dl_review_resource_blocked")

    assert %{
             "type" => "downlink_completion_gap",
             "contact_id" => "dl_review_resource_blocked",
             "required_downlink_mb" => 34.0,
             "feedback_source" =>
               "prior_plan.operator_review_package.rows.source_contact_allocation",
             "feedback_scope" => "contact_allocation",
             "trust_boundary" => "ops_allocation_review"
           } = List.first(review_allocation_branch["events"])

    review_resource_branch =
      branch(
        artifact,
        "derived_resource_filter_pressure_antenna_unavailable_dl_review_resource_blocked"
      )

    assert %{
             "type" => "resource_availability_constraint",
             "resource_field" => "antenna_available",
             "available" => false,
             "source_activity_id" => "dl_review_resource_blocked",
             "feedback_source" =>
               "prior_plan.operator_review_package.rows.source_contact_allocation.source_resource_suppression",
             "feedback_scope" => "resource_filter",
             "trust_boundary" => "ops_allocation_review"
           } = List.first(review_resource_branch["events"])

    cadence_allocation_branch =
      branch(artifact, "derived_contact_allocation_pressure_blocked_dl_import_resource_blocked")

    assert %{
             "type" => "downlink_completion_gap",
             "contact_id" => "dl_import_resource_blocked",
             "required_downlink_mb" => 42.0,
             "feedback_source" =>
               "prior_plan.cadence_import_manifest.rows.source_contact_allocation",
             "feedback_scope" => "contact_allocation",
             "trust_boundary" => "cadence_allocation_import"
           } = List.first(cadence_allocation_branch["events"])

    cadence_resource_branch =
      branch(
        artifact,
        "derived_resource_filter_pressure_payload_unavailable_dl_import_resource_blocked"
      )

    assert %{
             "type" => "resource_availability_constraint",
             "resource_field" => "payload_available",
             "available" => false,
             "source_activity_id" => "dl_import_resource_blocked",
             "feedback_source" =>
               "prior_plan.cadence_import_manifest.rows.source_contact_allocation.source_resource_suppression",
             "feedback_scope" => "resource_filter",
             "trust_boundary" => "cadence_allocation_import"
           } = List.first(cadence_resource_branch["events"])

    assert review_resource_branch["repair_result"]["source_resource_filter_report"][
             "suppressed_candidate_count"
           ] >= 1

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy replays allocation contact suppressions from review and Cadence import rows" do
    prior_plan =
      base_plan(%{
        "operator_review_package" => %{
          "schema_contract" => "operator_review_package.v1",
          "source_artifact_type" => "contact_allocation_report.v1",
          "provenance" => %{"trust_boundary" => "ops_allocation_review"},
          "rows" => [
            %{
              "id" => "operator_review:contact_allocation:dl_review_station_reserved",
              "review_type" => "contact_allocation_review",
              "approval_status" => "operator_review_required",
              "source_contact_allocation" => %{
                "contact_id" => "dl_review_station_reserved",
                "type" => "downlink",
                "scenario_id" => "leo_1",
                "spacecraft_id" => "leo_1",
                "ground_station_id" => "equator_prime",
                "starts_at_s" => 780.0,
                "ends_at_s" => 840.0,
                "allocation_status" => "blocked",
                "allocation_reason" => "station_reserved",
                "suppressed_reason" => "station_reserved",
                "required_downlink_mb" => 36.0,
                "station_reservation_id" => "reservation_review",
                "station_reserved_by" => "leo_2",
                "station_reservation_status" => "confirmed",
                "station_reservation_match_status" => "unmatched_overlap",
                "source_contact_suppression" => %{
                  "id" => "dl_review_station_reserved",
                  "type" => "downlink",
                  "scenario_id" => "leo_1",
                  "ground_station_id" => "equator_prime",
                  "starts_at_s" => 780.0,
                  "ends_at_s" => 840.0,
                  "suppressed_reason" => "station_reserved",
                  "station_reservation_id" => "reservation_review",
                  "station_reserved_by" => "leo_2",
                  "station_reservation_status" => "confirmed",
                  "station_reservation_match_status" => "unmatched_overlap",
                  "required_downlink_mb" => 36.0
                }
              }
            }
          ]
        },
        "cadence_import_manifest" => %{
          "schema_contract" => "cadence_import_manifest.v1",
          "source_artifact_type" => "contact_allocation_report.v1",
          "provenance" => %{"trust_boundary" => "cadence_allocation_import"},
          "rows" => [
            %{
              "id" => "cadence_import:contact_allocation:dl_import_station_reserved",
              "import_action" => "review_contact_allocation",
              "source_review_type" => "contact_allocation_review",
              "approval_status" => "operator_review_required",
              "source_contact_allocation" => %{
                "contact_id" => "dl_import_station_reserved",
                "type" => "downlink",
                "scenario_id" => "leo_2",
                "spacecraft_id" => "leo_2",
                "ground_station_id" => "deep_space_net",
                "starts_at_s" => 860.0,
                "ends_at_s" => 920.0,
                "allocation_status" => "blocked",
                "allocation_reason" => "station_reserved",
                "suppressed_reason" => "station_reserved",
                "required_downlink_mb" => 44.0,
                "station_reservation_id" => "reservation_import",
                "station_reserved_by" => "leo_3",
                "station_reservation_status" => "confirmed",
                "station_reservation_match_status" => "unmatched_overlap",
                "source_contact_suppression" => %{
                  "id" => "dl_import_station_reserved",
                  "type" => "downlink",
                  "scenario_id" => "leo_2",
                  "ground_station_id" => "deep_space_net",
                  "starts_at_s" => 860.0,
                  "ends_at_s" => 920.0,
                  "suppressed_reason" => "station_reserved",
                  "station_reservation_id" => "reservation_import",
                  "station_reserved_by" => "leo_3",
                  "station_reservation_status" => "confirmed",
                  "station_reservation_match_status" => "unmatched_overlap",
                  "required_downlink_mb" => 44.0
                }
              }
            }
          ]
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    review_allocation_branch =
      branch(artifact, "derived_contact_allocation_pressure_blocked_dl_review_station_reserved")

    assert %{
             "type" => "downlink_completion_gap",
             "contact_id" => "dl_review_station_reserved",
             "required_downlink_mb" => 36.0,
             "feedback_source" =>
               "prior_plan.operator_review_package.rows.source_contact_allocation",
             "feedback_scope" => "contact_allocation",
             "trust_boundary" => "ops_allocation_review"
           } = List.first(review_allocation_branch["events"])

    review_filter_branch =
      branch(
        artifact,
        "derived_contact_filter_pressure_station_reserved_dl_review_station_reserved"
      )

    assert %{
             "type" => "downlink_completion_gap",
             "contact_id" => "dl_review_station_reserved",
             "required_downlink_mb" => 36.0,
             "station_reservation_id" => "reservation_review",
             "station_reservation_match_status" => "unmatched_overlap",
             "feedback_source" =>
               "prior_plan.operator_review_package.rows.source_contact_allocation.source_contact_suppression",
             "feedback_scope" => "contact_filter",
             "trust_boundary" => "ops_allocation_review"
           } = List.first(review_filter_branch["events"])

    cadence_allocation_branch =
      branch(artifact, "derived_contact_allocation_pressure_blocked_dl_import_station_reserved")

    assert %{
             "type" => "downlink_completion_gap",
             "contact_id" => "dl_import_station_reserved",
             "required_downlink_mb" => 44.0,
             "feedback_source" =>
               "prior_plan.cadence_import_manifest.rows.source_contact_allocation",
             "feedback_scope" => "contact_allocation",
             "trust_boundary" => "cadence_allocation_import"
           } = List.first(cadence_allocation_branch["events"])

    cadence_filter_branch =
      branch(
        artifact,
        "derived_contact_filter_pressure_station_reserved_dl_import_station_reserved"
      )

    assert %{
             "type" => "downlink_completion_gap",
             "contact_id" => "dl_import_station_reserved",
             "required_downlink_mb" => 44.0,
             "station_reservation_id" => "reservation_import",
             "station_reservation_match_status" => "unmatched_overlap",
             "feedback_source" =>
               "prior_plan.cadence_import_manifest.rows.source_contact_allocation.source_contact_suppression",
             "feedback_scope" => "contact_filter",
             "trust_boundary" => "cadence_allocation_import"
           } = List.first(cadence_filter_branch["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
