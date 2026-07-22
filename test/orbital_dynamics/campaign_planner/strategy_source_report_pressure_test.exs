Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategySourceReportPressureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy derives prior result-artifact resource and comms pressure from source report keys" do
    prior_plan =
      base_plan(%{
        "activities" => [
          observe(
            "obs_source_wrapper_resource",
            "leo_source_wrapper",
            "target_a",
            100.0,
            160.0,
            20.0
          ),
          downlink("dl_source_station_calendar", 500.0, 560.0),
          downlink("dl_source_contention_deferred", 520.0, 580.0),
          downlink("dl_source_link", 600.0, 660.0)
        ],
        "candidate_activities" => [
          refreshed_downlink("dl_source_wrapper_recovery", 700.0, 760.0)
          |> Map.put("estimated_throughput_mb", 90.0)
        ],
        "source_result_artifact" => %{
          "schema_contract" => "result_artifact.v1",
          "study_id" => "source_resource_comms_result_artifact",
          "metadata" => %{"trust_boundary" => "ops_source_resource_comms_artifact"},
          "source_resource_projection_report" => %{
            "schema_contract" => "resource_projection_report.v1",
            "projected_resources" => [
              %{
                "spacecraft_id" => "leo_source_wrapper",
                "resource_source_quality" => "operator_supplied",
                "resource_trust_boundary_status" => "declared",
                "projected_storage_overflow_mb" => 25.0,
                "activity_resource_flow" => [
                  %{
                    "activity_id" => "obs_source_wrapper_resource",
                    "activity_type" => "observe",
                    "starts_at_s" => 100.0,
                    "ends_at_s" => 160.0,
                    "storage_overflow_mb" => 25.0
                  }
                ]
              }
            ]
          },
          "source_resource_filter_report" => %{
            "schema_contract" => "resource_filter_report.v1",
            "model" => "resource_summary_availability_and_margin_filter",
            "input_candidate_count" => 1,
            "kept_candidate_count" => 0,
            "suppressed_candidate_count" => 1,
            "suppressed_candidates" => [
              %{
                "id" => "obs_source_wrapper_filter",
                "type" => "observe",
                "scenario_id" => "leo_source_wrapper",
                "spacecraft_id" => "leo_source_wrapper",
                "target_id" => "target_a",
                "starts_at_s" => 200.0,
                "ends_at_s" => 260.0,
                "suppressed_reason" => "payload_unavailable",
                "payload_available" => false,
                "resource_source_quality" => "operator_supplied",
                "resource_trust_boundary_status" => "declared"
              }
            ]
          },
          "source_contact_filter_report" => %{
            "schema_contract" => "contact_filter_report.v1",
            "model" => "thin_ground_network_availability_filter",
            "input_candidate_count" => 1,
            "kept_candidate_count" => 0,
            "suppressed_candidate_count" => 1,
            "suppressed_candidates" => [
              %{
                "id" => "dl_source_contact_filter",
                "type" => "downlink",
                "scenario_id" => "leo_1",
                "spacecraft_id" => "leo_1",
                "ground_station_id" => "equator_prime",
                "starts_at_s" => 300.0,
                "ends_at_s" => 360.0,
                "suppressed_reason" => "ground_station_unavailable",
                "station_calendar_entry_status" => "unavailable",
                "estimated_throughput_mb" => 55.0,
                "source_window_id" => "window:source:contact_filter"
              }
            ]
          },
          "source_contact_allocation_report" => %{
            "schema_contract" => "contact_allocation_report.v1",
            "model" => "deterministic_station_contact_allocation",
            "input_contact_count" => 1,
            "allocated_contact_count" => 0,
            "deferred_contact_count" => 1,
            "blocked_contact_count" => 0,
            "rows" => [
              %{
                "id" => "contact_allocation:dl_source_allocation_deferred",
                "contact_id" => "dl_source_allocation_deferred",
                "allocation_status" => "Deferred",
                "effective_allocation_status" => "Deferred",
                "allocation_reason" => "same_station_contention",
                "type" => "downlink",
                "scenario_id" => "leo_1",
                "spacecraft_id" => "leo_1",
                "ground_station_id" => "equator_prime",
                "starts_at_s" => 520.0,
                "ends_at_s" => 580.0,
                "estimated_throughput_mb" => 42.0
              }
            ]
          },
          "source_contact_contention_resolution_report" => %{
            "schema_contract" => "contact_contention_resolution_report.v1",
            "model" => "deterministic_contact_contention_recommendation",
            "conflict_group_count" => 1,
            "recommendation_count" => 1,
            "recommendations" => [
              %{
                "group_id" => "station:equator_prime:contention:source",
                "ground_station_id" => "equator_prime",
                "starts_at_s" => 520.0,
                "ends_at_s" => 580.0,
                "selected_contact_id" => "dl_source_selected",
                "deferred_contact_ids" => ["dl_source_contention_deferred"],
                "selection_reason" => "highest_score_earliest_start",
                "direction" => "downlink",
                "source_contact_candidates" => [
                  downlink("dl_source_selected", 500.0, 560.0)
                  |> Map.put("estimated_throughput_mb", 40.0),
                  downlink("dl_source_contention_deferred", 520.0, 580.0)
                  |> Map.put("estimated_throughput_mb", 42.0)
                  |> Map.put("source_window_id", "window:source:contention")
                ]
              }
            ]
          },
          "source_link_capacity_report" => %{
            "schema_contract" => "link_capacity_report.v1",
            "model" => "fixed_rate_downlink_capacity_summary",
            "source" => "adapter.link_capacity",
            "contact_count" => 1,
            "rows" => [
              %{
                "id" => "link_capacity:source_station",
                "ground_station_id" => "source_station",
                "selected_downlink_shortfall_mb" => 30.0,
                "downlink_requirement_status" => "shortfall",
                "required_downlink_contact_ids" => ["dl_source_link"]
              }
            ]
          },
          "source_station_calendar_report" => %{
            "schema_contract" => "station_calendar_report.v1",
            "model" => "campaign_ground_network_interval_overlay",
            "affected_contacts" => [
              %{
                "id" => "station_calendar:source:dl_source_station_calendar",
                "contact_id" => "dl_source_station_calendar",
                "scenario_id" => "leo_1",
                "ground_station_id" => "equator_prime",
                "starts_at_s" => 500.0,
                "ends_at_s" => 560.0,
                "station_calendar_entry_id" => "source_calendar_reserved",
                "station_calendar_status" => "reserved",
                "station_availability" => "reserved",
                "station_reservation_id" => "source_reservation",
                "station_reserved_by" => "ops_source",
                "station_reservation_status" => "confirmed",
                "station_calendar_trust_boundary_status" => "declared"
              }
            ]
          }
        }
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    projection_branch = branch(artifact, "derived_projected_resource_pressure_leo_source_wrapper")

    assert %{
             "type" => "downlink_completion_gap",
             "source_activity_id" => "obs_source_wrapper_resource",
             "feedback_source" =>
               "prior_plan.source_result_artifact.source_resource_projection_report",
             "trust_boundary" => "ops_source_resource_comms_artifact"
           } =
             Enum.find(
               projection_branch["events"],
               &("projected_storage_overflow" in Map.get(&1, "derivation_reasons", []))
             )

    resource_branch =
      branch(
        artifact,
        "derived_resource_filter_pressure_payload_unavailable_obs_source_wrapper_filter"
      )

    assert %{
             "type" => "resource_availability_constraint",
             "source_activity_id" => "obs_source_wrapper_filter",
             "feedback_source" =>
               "prior_plan.source_result_artifact.source_resource_filter_report",
             "trust_boundary" => "ops_source_resource_comms_artifact"
           } = List.first(resource_branch["events"])

    contact_filter_branch =
      branch(
        artifact,
        "derived_contact_filter_pressure_ground_station_unavailable_dl_source_contact_filter"
      )

    assert %{
             "type" => "downlink_completion_gap",
             "source_activity_id" => "dl_source_contact_filter",
             "feedback_source" =>
               "prior_plan.source_result_artifact.source_contact_filter_report",
             "trust_boundary" => "ops_source_resource_comms_artifact"
           } = List.first(contact_filter_branch["events"])

    allocation_branch =
      branch(
        artifact,
        "derived_contact_allocation_pressure_deferred_dl_source_allocation_deferred"
      )

    assert %{
             "type" => "downlink_completion_gap",
             "source_activity_id" => "dl_source_allocation_deferred",
             "feedback_source" =>
               "prior_plan.source_result_artifact.source_contact_allocation_report",
             "trust_boundary" => "ops_source_resource_comms_artifact"
           } = List.first(allocation_branch["events"])

    contention_branch =
      branch(
        artifact,
        "derived_contact_contention_pressure_deferred_dl_source_contention_deferred"
      )

    assert %{
             "type" => "downlink_completion_gap",
             "source_activity_id" => "dl_source_contention_deferred",
             "feedback_source" =>
               "prior_plan.source_result_artifact.source_contact_contention_resolution_report",
             "trust_boundary" => "ops_source_resource_comms_artifact"
           } = List.first(contention_branch["events"])

    link_branch = branch(artifact, "derived_link_capacity_pressure_source_station")

    assert %{
             "type" => "downlink_completion_gap",
             "source_activity_ids" => ["dl_source_link"],
             "feedback_source" => "prior_plan.source_result_artifact.source_link_capacity_report",
             "trust_boundary" => "ops_source_resource_comms_artifact"
           } = List.first(link_branch["events"])

    calendar_branch =
      branch(artifact, "derived_station_calendar_pressure_reserved_dl_source_station_calendar")

    assert %{
             "type" => "ground_station_reserved",
             "station_calendar_entry_id" => "source_calendar_reserved",
             "station_reservation_id" => "source_reservation",
             "feedback_source" =>
               "prior_plan.source_result_artifact.source_station_calendar_report",
             "trust_boundary" => "ops_source_resource_comms_artifact"
           } = List.first(calendar_branch["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy keeps independent resource projection pressures for the same spacecraft" do
    prior_plan =
      base_plan(%{
        "activities" => [
          observe("obs_pressure_alpha", "leo_1", "target_a", 100.0, 160.0, 20.0)
          |> Map.put("estimated_storage_mb", 20.0),
          observe("obs_pressure_beta", "leo_1", "target_b", 180.0, 240.0, 20.0)
          |> Map.put("estimated_storage_mb", 30.0)
        ],
        "source_resource_projection_report" => %{
          "schema_contract" => "resource_projection_report.v1",
          "provenance" => %{"trust_boundary" => "ops_resource_projection"},
          "projected_resources" => [
            %{
              "spacecraft_id" => "leo_1",
              "resource_source_quality" => "operator_supplied",
              "resource_trust_boundary_status" => "declared",
              "projected_storage_overflow_mb" => 20.0,
              "activity_resource_flow" => [
                %{
                  "activity_id" => "obs_pressure_alpha",
                  "activity_type" => "observe",
                  "starts_at_s" => 100.0,
                  "ends_at_s" => 160.0,
                  "storage_overflow_mb" => 20.0
                }
              ]
            },
            %{
              "spacecraft_id" => "leo_1",
              "resource_source_quality" => "operator_supplied",
              "resource_trust_boundary_status" => "declared",
              "projected_storage_overflow_mb" => 30.0,
              "activity_resource_flow" => [
                %{
                  "activity_id" => "obs_pressure_beta",
                  "activity_type" => "observe",
                  "starts_at_s" => 180.0,
                  "ends_at_s" => 240.0,
                  "storage_overflow_mb" => 30.0
                }
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

    branch_ids = Enum.map(artifact["branches"], & &1["branch_id"])

    refute "derived_projected_resource_pressure_leo_1" in branch_ids

    alpha_branch_id =
      Enum.find(
        branch_ids,
        &String.starts_with?(&1, "derived_projected_resource_pressure_leo_1_obs_pressure_alpha")
      )

    beta_branch_id =
      Enum.find(
        branch_ids,
        &String.starts_with?(&1, "derived_projected_resource_pressure_leo_1_obs_pressure_beta")
      )

    assert alpha_branch_id
    assert beta_branch_id

    alpha_branch = branch(artifact, alpha_branch_id)
    beta_branch = branch(artifact, beta_branch_id)

    assert %{
             "type" => "downlink_completion_gap",
             "required_downlink_mb" => 20.0,
             "source_activity_id" => "obs_pressure_alpha",
             "source_activity_ids" => ["obs_pressure_alpha"],
             "feedback_source" => "prior_plan.source_resource_projection_report",
             "trust_boundary" => "ops_resource_projection"
           } =
             Enum.find(
               alpha_branch["events"],
               &("projected_storage_overflow" in Map.get(&1, "derivation_reasons", []))
             )

    assert %{
             "type" => "downlink_completion_gap",
             "required_downlink_mb" => 30.0,
             "source_activity_id" => "obs_pressure_beta",
             "source_activity_ids" => ["obs_pressure_beta"],
             "feedback_source" => "prior_plan.source_resource_projection_report",
             "trust_boundary" => "ops_resource_projection"
           } =
             Enum.find(
               beta_branch["events"],
               &("projected_storage_overflow" in Map.get(&1, "derivation_reasons", []))
             )

    comparison_branch_ids =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.map(& &1["branch_id"])

    assert alpha_branch_id in comparison_branch_ids
    assert beta_branch_id in comparison_branch_ids

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
