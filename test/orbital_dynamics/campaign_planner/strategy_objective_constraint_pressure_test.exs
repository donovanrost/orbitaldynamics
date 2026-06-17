Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyObjectiveConstraintPressureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy derives branch refresh from prior objective satisfaction pressure" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          refreshed_downlink("dl_wrong_station", 360.0, 420.0)
          |> Map.put("ground_station_id", "dss14")
          |> Map.put("estimated_throughput_mb", 120.0),
          refreshed_downlink("dl_objective_recovery", 520.0, 580.0)
          |> Map.put("estimated_throughput_mb", 120.0)
        ],
        "objective_satisfaction_report" => %{
          "schema_contract" => "objective_satisfaction_report.v1",
          "model" => "campaign_v1_selected_activity_objective_summary",
          "source" => "campaign_plan.activities",
          "objective_count" => 1,
          "provenance" => %{"trust_boundary" => "ops_objective_review"},
          "rows" => [
            %{
              "id" => "objective:downlink_completion",
              "objective" => "Downlink Completion",
              "status" => "Partial",
              "scenario_id" => "leo_1",
              "ground_station_id" => "equator_prime",
              "starts_at_s" => 0.0,
              "ends_at_s" => 650.0,
              "required_count" => 2,
              "selected_count" => 1,
              "required_downlink_mb" => 120.0,
              "selected_downlink_mb" => 70.0,
              "selected_contact_ids" => ["dl_selected"]
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

    pressure_branch =
      branch(artifact, "derived_objective_satisfaction_objective:downlink_completion")

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             pressure_branch["assumptions"]["candidate_source"]

    assert %{
             "type" => "downlink_completion_gap",
             "objective_id" => "objective:downlink_completion",
             "objective_type" => "downlink_completion",
             "scenario_id" => "leo_1",
             "ground_station_id" => "equator_prime",
             "ends_at_s" => 650.0,
             "required_contacts" => 2,
             "planned_contacts" => 1,
             "required_downlink_mb" => 120.0,
             "planned_downlink_mb" => 70.0,
             "source_activity_ids" => ["dl_selected"],
             "feedback_source" => "prior_plan.objective_satisfaction_report",
             "feedback_scope" => "objective_satisfaction",
             "objective_status" => "partial",
             "trust_boundary" => "ops_objective_review"
           } = List.first(pressure_branch["events"])

    assert List.first(pressure_branch["events"])["starts_at_s"] == 0.0

    assert Enum.any?(
             pressure_branch["repair_result"]["source_candidate_activities"],
             &(&1["type"] == "downlink" and
                 &1["ground_station_id"] == "equator_prime" and
                 &1["starts_at_s"] >= 0.0 and
                 &1["ends_at_s"] <= 650.0 and
                 get_in(&1, ["throughput_model", "required_downlink_mb"]) == 120.0)
           )

    assert Enum.any?(
             pressure_branch["risk_indicators"],
             &(&1["type"] == "downlink_completion_gap" and &1["reason"] =~ "120.0 MB")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from mission-state objective satisfaction pressure" do
    objective_satisfaction_report = %{
      "schema_contract" => "objective_satisfaction_report.v1",
      "model" => "mission_state_objective_summary",
      "source" => "mission_state.objectives",
      "objective_count" => 1,
      "provenance" => %{"trust_boundary" => "mission_objective_review"},
      "rows" => [
        %{
          "id" => "objective:downlink_completion",
          "objective" => "Downlink Completion",
          "status" => "Partial",
          "scenario_id" => "leo_1",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 0.0,
          "ends_at_s" => 650.0,
          "required_count" => 2,
          "selected_count" => 1,
          "required_downlink_mb" => 120.0,
          "selected_downlink_mb" => 70.0,
          "selected_contact_ids" => ["dl_selected"]
        }
      ]
    }

    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          refreshed_downlink("dl_wrong_station", 360.0, 420.0)
          |> Map.put("ground_station_id", "dss14")
          |> Map.put("estimated_throughput_mb", 120.0),
          refreshed_downlink("dl_objective_recovery", 520.0, 580.0)
          |> Map.put("estimated_throughput_mb", 120.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:source_objective_satisfaction_report, objective_satisfaction_report),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    pressure_branch =
      branch(artifact, "derived_objective_satisfaction_objective:downlink_completion")

    assert_candidate_source_report_path(
      pressure_branch,
      "mission_state.source_objective_satisfaction_report"
    )

    assert %{
             "type" => "downlink_completion_gap",
             "objective_id" => "objective:downlink_completion",
             "objective_type" => "downlink_completion",
             "scenario_id" => "leo_1",
             "ground_station_id" => "equator_prime",
             "ends_at_s" => 650.0,
             "required_contacts" => 2,
             "planned_contacts" => 1,
             "required_downlink_mb" => 120.0,
             "planned_downlink_mb" => 70.0,
             "source_activity_ids" => ["dl_selected"],
             "feedback_source" => "mission_state.source_objective_satisfaction_report",
             "feedback_scope" => "objective_satisfaction",
             "objective_status" => "partial",
             "trust_boundary" => "mission_objective_review"
           } = List.first(pressure_branch["events"])

    assert List.first(pressure_branch["events"])["starts_at_s"] == 0.0

    assert Enum.any?(
             pressure_branch["repair_result"]["source_candidate_activities"],
             &(&1["type"] == "downlink" and
                 &1["ground_station_id"] == "equator_prime" and
                 &1["starts_at_s"] >= 0.0 and
                 &1["ends_at_s"] <= 650.0 and
                 get_in(&1, ["throughput_model", "required_downlink_mb"]) == 120.0)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives target refresh from objective satisfaction missed target objects" do
    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          observe("obs_missed_target_recovery", "leo_1", "target_missed", 360.0, 420.0, 12.0)
        ],
        "objective_satisfaction_report" => %{
          "schema_contract" => "objective_satisfaction_report.v1",
          "model" => "provider_objective_satisfaction",
          "source" => "provider.objective_status",
          "objective_count" => 1,
          "provenance" => %{"trust_boundary" => "provider_objective_review"},
          "rows" => [
            %{
              "id" => "objective:missed_targets",
              "objective" => "Target Coverage",
              "status" => "Not Met",
              "scenario_id" => "leo_1",
              "required_observation_count" => 1,
              "selected_observation_count" => 0,
              "candidate_observation_ids" => ["obs_missed_target"],
              "missed_targets" => [
                %{
                  "id" => "target_missed",
                  "priority" => 9.0,
                  "latitude_deg" => 14.0,
                  "longitude_deg" => -42.0,
                  "minimum_elevation_deg" => 18.0
                }
              ]
            }
          ]
        }
      })

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:targets, [])

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    target_branch =
      branch(artifact, "derived_objective_satisfaction_objective:missed_targets:target_missed")

    assert %{
             "type" => "urgent_target",
             "objective_id" => "objective:missed_targets",
             "objective_type" => "target_coverage",
             "target_id" => "target_missed",
             "priority" => 9.0,
             "latitude_deg" => 14.0,
             "longitude_deg" => -42.0,
             "minimum_elevation_deg" => 18.0,
             "required_observations" => 1,
             "planned_observations" => 0,
             "source_activity_ids" => ["obs_missed_target"],
             "feedback_source" => "prior_plan.objective_satisfaction_report",
             "feedback_scope" => "objective_satisfaction",
             "objective_status" => "unmet",
             "trust_boundary" => "provider_objective_review"
           } = List.first(target_branch["events"])

    assert Enum.any?(
             target_branch["candidate_plan"]["strategic_additions"],
             &(&1["type"] == "observe" and &1["target_id"] == "target_missed")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives resource refresh from prior constraint pressure rows" do
    prior_plan =
      base_plan(%{
        "activities" => [
          observe("obs_storage", "leo_1", "target_a", 100.0, 160.0, 12.0)
          |> Map.put("estimated_storage_mb", 20.0)
        ],
        "source_constraint_report" => %{
          "schema_contract" => "constraint_report.v1",
          "model" => "campaign_repair_local_constraint_summary",
          "constraint_count" => 2,
          "row_count" => 2,
          "status" => "warning",
          "provenance" => %{"trust_boundary" => "ops_constraint_review"},
          "rows" => [
            %{
              "constraint_id" => "campaign:min_projected_storage_margin",
              "scenario_id" => "leo_1",
              "spacecraft_id" => "leo_1",
              "metric" => "Projected Storage Margin",
              "operator" => ">=",
              "threshold" => 0.9,
              "value" => 0.25,
              "score" => -0.65,
              "status" => "Warning",
              "violation_severity" => "Warning",
              "activity_id" => "obs_storage"
            },
            %{
              "constraint_id" => "campaign:min_projected_storage_margin_unvalued",
              "scenario_id" => "leo_1",
              "spacecraft_id" => "leo_1",
              "metric" => "Projected Storage Margin",
              "operator" => ">=",
              "threshold" => 0.9,
              "score" => -0.65,
              "status" => "Warning",
              "violation_severity" => "Warning",
              "activity_id" => "obs_storage"
            },
            %{
              "constraint_id" => "campaign:min_projected_thermal_margin_c",
              "scenario_id" => "leo_1",
              "spacecraft_id" => "leo_1",
              "metric" => "min projected thermal margin c",
              "operator" => ">=",
              "threshold" => "2.0",
              "projected_thermal_margin_c" => "1.25",
              "score" => -0.75,
              "status" => "Warning",
              "violation_severity" => "Warning",
              "activity_id" => "obs_storage"
            },
            %{
              "constraint_id" => "campaign:min_projected_fuel_margin",
              "scenario_id" => "leo_1",
              "spacecraft_id" => "leo_1",
              "metric" => "min projected fuel margin",
              "operator" => ">=",
              "threshold" => 0.4,
              "projected_fuel_margin" => 0.1,
              "score" => -0.3,
              "status" => "Warning",
              "violation_severity" => "Warning",
              "activity_id" => "obs_storage"
            }
          ]
        },
        "operator_review_package" => %{
          "schema_contract" => "operator_review_package.v1",
          "source_artifact_type" => "constraint_report.v1",
          "provenance" => %{"trust_boundary" => "ops_constraint_review_queue"},
          "rows" => [
            %{
              "id" => "operator_review:constraint:storage_margin_review",
              "review_type" => "constraint_review",
              "approval_status" => "operator_review_required",
              "constraint_id" => "campaign:min_projected_storage_margin_review",
              "scenario_id" => "leo_1",
              "spacecraft_id" => "leo_1",
              "metric" => "projected storage margin",
              "operator" => ">=",
              "threshold" => 0.7,
              "value" => 0.2,
              "score" => -0.5,
              "constraint_status" => "Warning",
              "violation_severity" => "Warning",
              "activity_id" => "obs_storage"
            }
          ]
        },
        "cadence_import_manifest" => %{
          "schema_contract" => "cadence_import_manifest.v1",
          "source_artifact_type" => "constraint_report.v1",
          "provenance" => %{"trust_boundary" => "cadence_constraint_import_queue"},
          "rows" => [
            %{
              "id" => "cadence_import:constraint:power_margin",
              "import_action" => "review_constraint",
              "source_review_type" => "constraint_review",
              "approval_status" => "operator_review_required",
              "source_constraint_row" => %{
                "constraint_id" => "campaign:min_projected_power_margin",
                "scenario_id" => "leo_1",
                "spacecraft_id" => "leo_1",
                "metric" => "min projected power margin",
                "operator" => ">=",
                "threshold" => 0.8,
                "projected_power_margin" => 0.3,
                "score" => -0.5,
                "status" => "Warning",
                "violation_severity" => "Warning",
                "activity_id" => "obs_storage"
              }
            },
            %{
              "id" => "cadence_import:constraint:downlink_margin",
              "import_action" => "review_constraint",
              "source_review_type" => "constraint_review",
              "approval_status" => "operator_review_required",
              "constraint_id" => "campaign:min_projected_downlink_margin",
              "scenario_id" => "leo_1",
              "spacecraft_id" => "leo_1",
              "metric" => "projected downlink margin",
              "operator" => ">=",
              "threshold" => 0.6,
              "value" => 0.2,
              "score" => -0.4,
              "constraint_status" => "Warning",
              "violation_severity" => "Warning",
              "activity_id" => "obs_storage"
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

    constraint_branch =
      branch(artifact, "derived_constraint_pressure_campaign:min_projected_storage_margin")

    assert %{
             "type" => "resource_margin_pressure",
             "spacecraft_id" => "leo_1",
             "resource_field" => "storage_margin",
             "storage_margin" => 0.25,
             "storage_margin_threshold" => 0.9,
             "activity_id" => "obs_storage",
             "source_activity_ids" => ["obs_storage"],
             "constraint_id" => "campaign:min_projected_storage_margin",
             "constraint_metric" => "projected_storage_margin",
             "constraint_status" => "warning",
             "feedback_source" => "prior_plan.source_constraint_report",
             "feedback_scope" => "constraint_report",
             "trust_boundary" => "ops_constraint_review"
           } = List.first(constraint_branch["events"])

    review_constraint_branch =
      branch(artifact, "derived_constraint_pressure_campaign:min_projected_storage_margin_review")

    assert %{
             "type" => "resource_margin_pressure",
             "spacecraft_id" => "leo_1",
             "resource_field" => "storage_margin",
             "storage_margin" => 0.2,
             "storage_margin_threshold" => 0.7,
             "activity_id" => "obs_storage",
             "constraint_id" => "campaign:min_projected_storage_margin_review",
             "constraint_metric" => "projected_storage_margin",
             "constraint_status" => "warning",
             "feedback_source" => "prior_plan.operator_review_package.rows.constraint_review",
             "feedback_scope" => "constraint_report",
             "trust_boundary" => "ops_constraint_review_queue"
           } = List.first(review_constraint_branch["events"])

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             constraint_branch["assumptions"]["candidate_source"]

    refute branch(
             artifact,
             "derived_constraint_pressure_campaign:min_projected_storage_margin_unvalued"
           )

    assert Enum.any?(
             constraint_branch["risk_indicators"],
             &(&1["type"] == "storage_margin_low" and &1["spacecraft_id"] == "leo_1")
           )

    thermal_constraint_branch =
      branch(artifact, "derived_constraint_pressure_campaign:min_projected_thermal_margin_c")

    assert %{
             "type" => "resource_margin_pressure",
             "spacecraft_id" => "leo_1",
             "resource_field" => "thermal_margin_c",
             "thermal_margin_c" => 1.25,
             "thermal_margin_c_threshold" => 2.0,
             "activity_id" => "obs_storage",
             "source_activity_ids" => ["obs_storage"],
             "constraint_id" => "campaign:min_projected_thermal_margin_c",
             "constraint_metric" => "min_projected_thermal_margin_c",
             "constraint_status" => "warning",
             "feedback_source" => "prior_plan.source_constraint_report",
             "feedback_scope" => "constraint_report",
             "trust_boundary" => "ops_constraint_review"
           } = List.first(thermal_constraint_branch["events"])

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             thermal_constraint_branch["assumptions"]["candidate_source"]

    assert Enum.any?(
             thermal_constraint_branch["risk_indicators"],
             &(&1["type"] == "thermal_margin_c_low" and &1["spacecraft_id"] == "leo_1")
           )

    fuel_constraint_branch =
      branch(artifact, "derived_constraint_pressure_campaign:min_projected_fuel_margin")

    assert %{
             "type" => "resource_margin_pressure",
             "spacecraft_id" => "leo_1",
             "resource_field" => "fuel_margin",
             "fuel_margin" => 0.1,
             "fuel_margin_threshold" => 0.4,
             "activity_id" => "obs_storage",
             "source_activity_ids" => ["obs_storage"],
             "constraint_id" => "campaign:min_projected_fuel_margin",
             "constraint_metric" => "min_projected_fuel_margin",
             "constraint_status" => "warning",
             "feedback_source" => "prior_plan.source_constraint_report",
             "feedback_scope" => "constraint_report",
             "trust_boundary" => "ops_constraint_review"
           } = List.first(fuel_constraint_branch["events"])

    assert Enum.any?(
             fuel_constraint_branch["risk_indicators"],
             &(&1["type"] == "fuel_margin_low" and &1["spacecraft_id"] == "leo_1")
           )

    cadence_constraint_branch =
      branch(artifact, "derived_constraint_pressure_campaign:min_projected_power_margin")

    assert %{
             "type" => "resource_margin_pressure",
             "spacecraft_id" => "leo_1",
             "resource_field" => "power_margin",
             "power_margin" => 0.3,
             "power_margin_threshold" => 0.8,
             "activity_id" => "obs_storage",
             "source_activity_ids" => ["obs_storage"],
             "constraint_id" => "campaign:min_projected_power_margin",
             "constraint_metric" => "min_projected_power_margin",
             "constraint_status" => "warning",
             "feedback_source" => "prior_plan.cadence_import_manifest.rows.source_constraint_row",
             "feedback_scope" => "constraint_report",
             "trust_boundary" => "cadence_constraint_import_queue"
           } = List.first(cadence_constraint_branch["events"])

    flat_cadence_constraint_branch =
      branch(artifact, "derived_constraint_pressure_campaign:min_projected_downlink_margin")

    assert %{
             "type" => "resource_margin_pressure",
             "spacecraft_id" => "leo_1",
             "resource_field" => "downlink_margin",
             "downlink_margin" => 0.2,
             "downlink_margin_threshold" => 0.6,
             "activity_id" => "obs_storage",
             "constraint_id" => "campaign:min_projected_downlink_margin",
             "constraint_metric" => "projected_downlink_margin",
             "constraint_status" => "warning",
             "feedback_source" => "prior_plan.cadence_import_manifest.rows.constraint_review",
             "feedback_scope" => "constraint_report",
             "trust_boundary" => "cadence_constraint_import_queue"
           } = List.first(flat_cadence_constraint_branch["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives resource and downlink refresh from mission-state constraint report rows" do
    constraint_report = %{
      "schema_contract" => "constraint_report.v1",
      "model" => "campaign_repair_local_constraint_summary",
      "constraint_count" => 2,
      "row_count" => 2,
      "status" => "warning",
      "provenance" => %{"trust_boundary" => "mission_constraint_review"},
      "rows" => [
        %{
          "constraint_id" => "campaign:min_projected_storage_margin",
          "scenario_id" => "leo_1",
          "spacecraft_id" => "leo_1",
          "metric" => "Projected Storage Margin",
          "operator" => ">=",
          "threshold" => 0.9,
          "value" => 0.25,
          "score" => -0.65,
          "status" => "Warning",
          "violation_severity" => "Warning",
          "activity_id" => "obs_storage"
        },
        %{
          "constraint_id" => "campaign:max_selected_data_volume_shortfall_mb",
          "metric" => "Max Selected Data Volume Shortfall MB",
          "operator" => "<=",
          "threshold" => 0.0,
          "status" => "Warning",
          "violation_severity" => "Warning",
          "selected_contacts" => [
            %{
              "id" => "dl_short",
              "scenario_id" => "leo_1",
              "station" => %{"id" => "equator_prime"},
              "starts_at_s" => 0.0,
              "ends_at_s" => 650.0,
              "required_contacts" => 1,
              "planned_contacts" => 0,
              "throughput_model" => %{
                "target_data_volume_mb" => 120.0,
                "selected_data_volume_mb" => 40.0,
                "selected_data_volume_shortfall_mb" => 80.0,
                "downlink_completion_sources" => [
                  "constraint.provider.required_downlink:dl_short"
                ]
              }
            }
          ]
        }
      ]
    }

    artifact =
      strategy(base_plan(%{}),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:source_constraint_report, constraint_report),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    resource_branch =
      branch(artifact, "derived_constraint_pressure_campaign:min_projected_storage_margin")

    assert %{
             "type" => "resource_margin_pressure",
             "spacecraft_id" => "leo_1",
             "resource_field" => "storage_margin",
             "storage_margin" => 0.25,
             "storage_margin_threshold" => 0.9,
             "activity_id" => "obs_storage",
             "source_activity_ids" => ["obs_storage"],
             "constraint_id" => "campaign:min_projected_storage_margin",
             "constraint_metric" => "projected_storage_margin",
             "constraint_status" => "warning",
             "feedback_source" => "mission_state.source_constraint_report",
             "feedback_scope" => "constraint_report",
             "trust_boundary" => "mission_constraint_review"
           } = List.first(resource_branch["events"])

    assert_candidate_source_report_path(resource_branch, "mission_state.source_constraint_report")

    downlink_branch =
      branch(
        artifact,
        "derived_constraint_pressure_campaign:max_selected_data_volume_shortfall_mb"
      )

    event = List.first(downlink_branch["events"])

    assert %{
             "type" => "downlink_completion_gap",
             "required_downlink_mb" => 120.0,
             "planned_downlink_mb" => 40.0,
             "scenario_id" => "leo_1",
             "ground_station_id" => "equator_prime",
             "required_contacts" => 1,
             "planned_contacts" => 0,
             "source_activity_ids" => ["dl_short"],
             "downlink_completion_sources" => ["constraint.provider.required_downlink:dl_short"],
             "downlink_demand_sources" => ["constraint.provider.required_downlink:dl_short"],
             "constraint_id" => "campaign:max_selected_data_volume_shortfall_mb",
             "constraint_metric" => "max_selected_data_volume_shortfall_mb",
             "constraint_status" => "warning",
             "feedback_source" => "mission_state.source_constraint_report",
             "feedback_scope" => "constraint_report",
             "trust_boundary" => "mission_constraint_review"
           } = event

    assert event["starts_at_s"] == 0.0
    assert event["ends_at_s"] == 650.0

    assert_candidate_source_report_path(downlink_branch, "mission_state.source_constraint_report")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives constraint pressure from result artifact constraint reports" do
    prior_plan =
      base_plan(%{
        "activities" => [
          observe("obs_storage", "leo_1", "target_a", 100.0, 160.0, 12.0)
          |> Map.put("estimated_storage_mb", 20.0)
        ],
        "source_result_artifact" => %{
          "schema_contract" => "result_artifact.v1",
          "study_id" => "constraint_result_artifact",
          "provenance" => %{"trust_boundary" => "ops_result_artifact"},
          "constraint_report" => %{
            "schema_contract" => "constraint_report.v1",
            "model" => "campaign_repair_local_constraint_summary",
            "constraint_count" => 1,
            "row_count" => 1,
            "status" => "warning",
            "rows" => [
              %{
                "constraint_id" => "campaign:result_artifact_storage_margin",
                "scenario_id" => "leo_1",
                "spacecraft_id" => "leo_1",
                "metric" => "Projected Storage Margin",
                "operator" => ">=",
                "threshold" => 0.8,
                "value" => 0.2,
                "score" => -0.6,
                "status" => "Warning",
                "violation_severity" => "Warning",
                "activity_id" => "obs_storage"
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

    constraint_branch =
      branch(artifact, "derived_constraint_pressure_campaign:result_artifact_storage_margin")

    assert %{
             "type" => "resource_margin_pressure",
             "spacecraft_id" => "leo_1",
             "resource_field" => "storage_margin",
             "storage_margin" => 0.2,
             "storage_margin_threshold" => 0.8,
             "activity_id" => "obs_storage",
             "source_activity_ids" => ["obs_storage"],
             "constraint_id" => "campaign:result_artifact_storage_margin",
             "constraint_metric" => "projected_storage_margin",
             "constraint_status" => "warning",
             "feedback_source" => "prior_plan.source_result_artifact.constraint_report",
             "feedback_scope" => "constraint_report",
             "trust_boundary" => "ops_result_artifact"
           } = List.first(constraint_branch["events"])

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             constraint_branch["assumptions"]["candidate_source"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy keeps independent constraint pressures for the same constraint identity" do
    prior_plan =
      base_plan(%{
        "activities" => [
          observe("obs_storage_a", "leo_1", "target_a", 100.0, 160.0, 12.0)
          |> Map.put("estimated_storage_mb", 20.0),
          observe("obs_storage_b", "leo_1", "target_b", 180.0, 240.0, 12.0)
          |> Map.put("estimated_storage_mb", 30.0)
        ],
        "source_constraint_report" => %{
          "schema_contract" => "constraint_report.v1",
          "model" => "campaign_repair_local_constraint_summary",
          "constraint_count" => 1,
          "row_count" => 1,
          "status" => "warning",
          "provenance" => %{"trust_boundary" => "source_constraint_review"},
          "rows" => [
            %{
              "constraint_id" => "campaign:shared_storage_margin",
              "scenario_id" => "leo_1",
              "spacecraft_id" => "leo_1",
              "metric" => "Projected Storage Margin",
              "operator" => ">=",
              "threshold" => 0.9,
              "value" => 0.25,
              "status" => "Warning",
              "violation_severity" => "Warning",
              "activity_id" => "obs_storage_a"
            }
          ]
        },
        "constraint_report" => %{
          "schema_contract" => "constraint_report.v1",
          "model" => "campaign_repair_local_constraint_summary",
          "constraint_count" => 1,
          "row_count" => 1,
          "status" => "warning",
          "provenance" => %{"trust_boundary" => "canonical_constraint_review"},
          "rows" => [
            %{
              "constraint_id" => "campaign:shared_storage_margin",
              "scenario_id" => "leo_1",
              "spacecraft_id" => "leo_1",
              "metric" => "Projected Storage Margin",
              "operator" => ">=",
              "threshold" => 0.8,
              "value" => 0.1,
              "status" => "Warning",
              "violation_severity" => "Warning",
              "activity_id" => "obs_storage_b"
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

    base_id = "derived_constraint_pressure_campaign:shared_storage_margin"
    refute branch(artifact, base_id)

    constraint_branches =
      Enum.filter(artifact["branches"], &String.starts_with?(&1["branch_id"], "#{base_id}_"))

    assert length(constraint_branches) == 2

    assert MapSet.new(Enum.map(constraint_branches, & &1["derived_source"])) ==
             MapSet.new(["prior_plan.source_constraint_report", "prior_plan.constraint_report"])

    assert MapSet.new(
             Enum.map(
               constraint_branches,
               &get_in(&1, ["events", Access.at(0), "activity_id"])
             )
           ) == MapSet.new(["obs_storage_a", "obs_storage_b"])

    assert MapSet.new(
             Enum.map(
               constraint_branches,
               &get_in(&1, ["events", Access.at(0), "storage_margin"])
             )
           ) == MapSet.new([0.25, 0.1])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives routed downlink refresh from prior constraint shortfall rows" do
    prior_plan =
      base_plan(%{
        "source_constraint_report" => %{
          "schema_contract" => "constraint_report.v1",
          "model" => "campaign_repair_local_constraint_summary",
          "constraint_count" => 1,
          "row_count" => 1,
          "status" => "warning",
          "provenance" => %{"trust_boundary" => "ops_constraint_review"},
          "rows" => [
            %{
              "constraint_id" => "campaign:max_selected_data_volume_shortfall_mb",
              "metric" => "Max Selected Data Volume Shortfall MB",
              "operator" => "<=",
              "threshold" => 0.0,
              "status" => "Warning",
              "violation_severity" => "Warning",
              "selected_contacts" => [
                %{
                  "id" => "dl_short",
                  "scenario_id" => "leo_1",
                  "station" => %{"id" => "equator_prime"},
                  "starts_at_s" => 0.0,
                  "ends_at_s" => 650.0,
                  "required_contacts" => 1,
                  "planned_contacts" => 0,
                  "throughput_model" => %{
                    "target_data_volume_mb" => 120.0,
                    "selected_data_volume_mb" => 40.0,
                    "selected_data_volume_shortfall_mb" => 80.0,
                    "downlink_completion_sources" => [
                      "constraint.provider.required_downlink:dl_short"
                    ]
                  }
                }
              ]
            },
            %{
              "constraint_id" => "campaign:max_selected_data_volume_shortfall_unrouted",
              "scenario_id" => "leo_1",
              "metric" => "Max Selected Data Volume Shortfall MB",
              "operator" => "<=",
              "threshold" => 0.0,
              "source_contact" => %{
                "id" => "dl_short_unrouted",
                "throughput_model" => %{"selected_data_volume_shortfall_mb" => 80.0}
              },
              "status" => "Warning",
              "violation_severity" => "Warning",
              "starts_at_s" => 0.0,
              "ends_at_s" => 650.0,
              "required_contacts" => 1,
              "planned_contacts" => 0
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

    constraint_branch =
      branch(
        artifact,
        "derived_constraint_pressure_campaign:max_selected_data_volume_shortfall_mb"
      )

    event = List.first(constraint_branch["events"])

    assert %{
             "type" => "downlink_completion_gap",
             "required_downlink_mb" => 120.0,
             "planned_downlink_mb" => 40.0,
             "scenario_id" => "leo_1",
             "ground_station_id" => "equator_prime",
             "ends_at_s" => 650.0,
             "required_contacts" => 1,
             "planned_contacts" => 0,
             "source_activity_ids" => ["dl_short"],
             "downlink_completion_sources" => ["constraint.provider.required_downlink:dl_short"],
             "downlink_demand_sources" => ["constraint.provider.required_downlink:dl_short"],
             "constraint_id" => "campaign:max_selected_data_volume_shortfall_mb",
             "constraint_metric" => "max_selected_data_volume_shortfall_mb",
             "constraint_status" => "warning",
             "feedback_source" => "prior_plan.source_constraint_report",
             "feedback_scope" => "constraint_report",
             "trust_boundary" => "ops_constraint_review"
           } = event

    assert event["starts_at_s"] == 0.0

    refute branch(
             artifact,
             "derived_constraint_pressure_campaign:max_selected_data_volume_shortfall_unrouted"
           )

    assert Enum.any?(
             constraint_branch["candidate_plan"]["strategic_additions"],
             &(&1["type"] == "downlink" and &1["ground_station_id"] == "equator_prime" and
                 get_in(&1, ["feasibility", "feedback_scope"]) == "constraint_report" and
                 get_in(&1, ["throughput_model", "downlink_completion_sources"]) == [
                   "constraint.provider.required_downlink:dl_short"
                 ] and
                 get_in(&1, ["activity_context", "downlink_completion_sources"]) == [
                   "constraint.provider.required_downlink:dl_short"
                 ])
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp assert_candidate_source_report_path(branch, expected_path) do
    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             candidate_source = branch["assumptions"]["candidate_source"]

    assert expected_path in candidate_source["source_report_input_paths"]
    candidate_source
  end
end
