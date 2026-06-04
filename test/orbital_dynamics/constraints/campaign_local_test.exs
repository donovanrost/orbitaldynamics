defmodule OrbitalDynamics.Constraints.CampaignLocalTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Constraints.CampaignLocal
  alias OrbitalDynamics.Schema

  test "declares campaign-local constraint capabilities" do
    assert %{
             constraint: :campaign_local,
             model: :campaign_planner_local_constraint_summary,
             validation_level: :artifact_contract,
             supported_constraints: supported_constraints,
             known_limits: known_limits
           } = CampaignLocal.capabilities()

    assert "max_timeline_activities" in supported_constraints
    assert "min_projected_storage_margin" in supported_constraints
    assert "min_actual_completion_fraction" in supported_constraints
    assert :planner_local_constraints_only in known_limits
    assert :not_a_general_constraint_solver in known_limits
  end

  test "builds schema-validated campaign constraint report rows" do
    assert %{
             "schema_contract" => "constraint_report.v1",
             "model" => "campaign_planner_local_constraint_summary",
             "constraint_count" => 4,
             "row_count" => 4,
             "status" => "warning",
             "status_counts" => %{"pass" => 2, "fail" => 0, "warning" => 2},
             "model_limits" => model_limits,
             "rows" => rows
           } =
             report =
             CampaignLocal.report(
               candidates(),
               timelines(),
               %{
                 max_timeline_activities: %{threshold: 1, severity: :warning},
                 min_activity_duration_s: 60.0,
                 avoid_eclipse: true,
                 min_projected_storage_margin: %{threshold: 0.8, severity: :warning}
               },
               resource_projection_report(),
               nil
             )

    assert "planner_local_constraints_only" in model_limits
    assert "resource_projection_constraints_are_planning_grade" in model_limits

    assert %{
             "constraint_id" => "campaign:max_timeline_activities",
             "scenario_id" => "scenario_a",
             "metric" => "activity_count",
             "operator" => "<=",
             "threshold" => 1,
             "value" => 2,
             "status" => "warning",
             "violation_severity" => "warning"
           } = Enum.find(rows, &(&1["constraint_id"] == "campaign:max_timeline_activities"))

    assert %{
             "constraint_id" => "campaign:min_activity_duration_s",
             "activity_id" => "obs_1",
             "status" => "pass"
           } =
             Enum.find(
               rows,
               &(&1["constraint_id"] == "campaign:min_activity_duration_s")
             )

    assert %{
             "constraint_id" => "campaign:avoid_eclipse",
             "activity_id" => "obs_1",
             "value" => eclipse_overlap_s,
             "status" => "pass"
           } = Enum.find(rows, &(&1["constraint_id"] == "campaign:avoid_eclipse"))

    assert eclipse_overlap_s == 0.0

    assert %{
             "constraint_id" => "campaign:min_projected_storage_margin",
             "scenario_id" => "leo_1",
             "spacecraft_id" => "leo_1",
             "metric" => "projected_storage_margin",
             "threshold" => 0.8,
             "value" => 0.6,
             "status" => "warning",
             "resource_pressure_status" => "storage_overflow",
             "resource_pressure_types" => ["storage_overflow"]
           } =
             Enum.find(
               rows,
               &(&1["constraint_id"] == "campaign:min_projected_storage_margin")
             )

    assert {:ok, %{"schema_contract" => "constraint_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "evaluates link-capacity constraints through top-level public API" do
    report =
      OrbitalDynamics.campaign_local_constraint_report(
        [],
        [],
        %{
          "max_selected_downlink_shortfall_mb" => %{threshold: 0.0, severity: :warning},
          "min_actual_completion_fraction" => 0.8
        },
        nil,
        %{
          "ground_station_id" => "gs_1",
          "selected_downlink_shortfall_mb" => 12.5,
          "actual_completion_fraction" => 0.9,
          "downlink_requirement_status" => "shortfall",
          "actual_downlink_requirement_status" => "complete"
        },
        model: "campaign_repair_local_constraint_summary",
        source: "campaign_repair.assumptions.constraints",
        constraint_model: "campaign_repair_v2_planner_local_constraints"
      )

    assert %{
             "model" => "campaign_repair_local_constraint_summary",
             "constraint_count" => 2,
             "status" => "warning",
             "assumptions" => %{
               "source" => "campaign_repair.assumptions.constraints",
               "constraint_model" => "campaign_repair_v2_planner_local_constraints"
             },
             "rows" => rows
           } = report

    assert %{
             "constraint_id" => "campaign:max_selected_downlink_shortfall_mb",
             "scenario_id" => "link_capacity:gs_1",
             "ground_station_id" => "gs_1",
             "operator" => "<=",
             "value" => 12.5,
             "status" => "warning",
             "downlink_requirement_status" => "shortfall"
           } =
             Enum.find(
               rows,
               &(&1["constraint_id"] == "campaign:max_selected_downlink_shortfall_mb")
             )

    assert %{
             "constraint_id" => "campaign:min_actual_completion_fraction",
             "operator" => ">=",
             "value" => 0.9,
             "status" => "pass",
             "actual_downlink_requirement_status" => "complete"
           } =
             Enum.find(rows, &(&1["constraint_id"] == "campaign:min_actual_completion_fraction"))

    assert {:ok, result} =
             CampaignLocal.evaluate(
               %{
                 candidates: [],
                 timelines: [],
                 constraints: %{"min_actual_completion_fraction" => 0.95},
                 link_capacity_report: %{"actual_completion_fraction" => 0.9}
               },
               []
             )

    assert result.status == :fail
    assert %{"report" => %{"schema_contract" => "constraint_report.v1"}} = result.metadata

    assert {:ok, %{"schema_contract" => "constraint_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "normalizes clean numeric string campaign-local constraint thresholds" do
    report =
      OrbitalDynamics.campaign_local_constraint_report(
        [
          %{
            id: :short_activity,
            scenario_id: :leo_1,
            duration_s: "30.0",
            eclipse_overlap_s: "5.0"
          }
        ],
        [
          %{
            scenario_id: :leo_1,
            activity_count: "3"
          }
        ],
        %{
          "max_timeline_activities" => %{"threshold" => "2", "severity" => "warning"},
          "min_activity_duration_s" => "60.0",
          "avoid_eclipse" => %{"value" => true, "severity" => "warning"},
          "min_selected_capacity_utilization_fraction" => "0.75",
          "bad_threshold" => "not-a-number"
        },
        nil,
        %{
          ground_station_id: :equator_prime,
          selected_capacity_utilization_fraction: "0.5"
        }
      )

    assert %{
             "constraint_count" => 4,
             "row_count" => 4,
             "status_counts" => %{"pass" => 0, "fail" => 2, "warning" => 2}
           } = report

    assert %{
             "constraint_id" => "campaign:max_timeline_activities",
             "threshold" => 2.0,
             "value" => 3.0,
             "status" => "warning"
           } =
             Enum.find(
               report["rows"],
               &(&1["constraint_id"] == "campaign:max_timeline_activities")
             )

    assert %{
             "constraint_id" => "campaign:min_activity_duration_s",
             "threshold" => 60.0,
             "value" => 30.0,
             "status" => "fail"
           } =
             Enum.find(
               report["rows"],
               &(&1["constraint_id"] == "campaign:min_activity_duration_s")
             )

    eclipse_row = Enum.find(report["rows"], &(&1["constraint_id"] == "campaign:avoid_eclipse"))

    assert Map.take(eclipse_row, ["constraint_id", "value", "status"]) == %{
             "constraint_id" => "campaign:avoid_eclipse",
             "value" => 5.0,
             "status" => "warning"
           }

    assert eclipse_row["threshold"] == 0.0

    assert %{
             "constraint_id" => "campaign:min_selected_capacity_utilization_fraction",
             "threshold" => 0.75,
             "value" => 0.5,
             "status" => "fail"
           } =
             Enum.find(
               report["rows"],
               &(&1["constraint_id"] == "campaign:min_selected_capacity_utilization_fraction")
             )

    assert {:ok, %{"schema_contract" => "constraint_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "normalizes atom keyed resource and link capacity report rows" do
    report =
      CampaignLocal.report(
        [],
        [],
        %{
          min_projected_storage_margin: %{threshold: "0.8", severity: :warning},
          max_selected_downlink_shortfall_mb: "10.0"
        },
        %{
          schema_contract: :resource_projection_report_v1,
          projected_resources: [
            %{
              scenario_id: :leo_1,
              spacecraft_id: :leo_1,
              projected_storage_margin: "0.6",
              first_resource_pressure_activity_id: :obs_1,
              resource_pressure_status: :storage_overflow,
              resource_pressure_types: [:storage_overflow]
            }
          ]
        },
        %{
          ground_station_id: :equator_prime,
          selected_downlink_shortfall_mb: "12.5",
          downlink_requirement_status: :shortfall
        }
      )

    assert %{
             "constraint_count" => 2,
             "row_count" => 2,
             "status_counts" => %{"pass" => 0, "fail" => 1, "warning" => 1}
           } = report

    assert %{
             "constraint_id" => "campaign:min_projected_storage_margin",
             "scenario_id" => "leo_1",
             "spacecraft_id" => "leo_1",
             "threshold" => 0.8,
             "value" => 0.6,
             "status" => "warning",
             "activity_id" => "obs_1",
             "resource_pressure_status" => "storage_overflow",
             "resource_pressure_types" => ["storage_overflow"]
           } =
             Enum.find(
               report["rows"],
               &(&1["constraint_id"] == "campaign:min_projected_storage_margin")
             )

    assert %{
             "constraint_id" => "campaign:max_selected_downlink_shortfall_mb",
             "scenario_id" => "link_capacity:equator_prime",
             "ground_station_id" => "equator_prime",
             "threshold" => 10.0,
             "value" => 12.5,
             "status" => "fail",
             "downlink_requirement_status" => "shortfall"
           } =
             Enum.find(
               report["rows"],
               &(&1["constraint_id"] == "campaign:max_selected_downlink_shortfall_mb")
             )

    assert {:ok, %{"schema_contract" => "constraint_report.v1"}} =
             Schema.validate_artifact(report)
  end

  defp candidates do
    [
      %{
        "id" => "obs_1",
        "scenario_id" => "scenario_a",
        "duration_s" => 120.0,
        "eclipse_overlap_s" => 0.0
      }
    ]
  end

  defp timelines do
    [
      %{
        "scenario_id" => "scenario_a",
        "activity_count" => 2
      }
    ]
  end

  defp resource_projection_report do
    %{
      "schema_contract" => "resource_projection_report.v1",
      "projected_resources" => [
        %{
          "scenario_id" => "leo_1",
          "spacecraft_id" => "leo_1",
          "projected_storage_margin" => 0.6,
          "first_resource_pressure_activity_id" => "obs_1",
          "resource_pressure_status" => "storage_overflow",
          "resource_pressure_types" => ["storage_overflow"]
        }
      ]
    }
  end
end
