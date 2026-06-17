Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.CampaignLocalConstraintsTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.{CampaignPlanner, Epoch, ResultSet, Schema}

  test "campaign local constraints can emit warning rows for operator review" do
    result_set =
      campaign_result_set([
        target_visibility_result(:leo_1, :target_a, 0.0, 10.0, 2.0)
      ])

    artifact =
      CampaignPlanner.build(result_set,
        generated_at: ~U[2026-05-14 00:00:00Z],
        campaign: %{
          "targets" => [%{"id" => "target_a", "priority" => 2.0}],
          "constraints" => %{
            "max_timeline_activities" => %{threshold: 0, severity: :warning}
          },
          "scoring_policy" => %{"target_value_weight" => 1.0}
        }
      )

    assert %{
             "schema_contract" => "constraint_report.v1",
             "constraint_count" => 1,
             "row_count" => 1,
             "status" => "warning",
             "status_counts" => %{"pass" => 0, "warning" => 1, "fail" => 0},
             "rows" => [constraint_row]
           } = artifact["constraint_report"]

    assert %{
             "constraint_id" => "campaign:max_timeline_activities",
             "metric" => "activity_count",
             "operator" => "<=",
             "threshold" => 0,
             "value" => 1,
             "status" => "warning",
             "violation_severity" => "warning"
           } = constraint_row

    review_row =
      Enum.find(
        artifact["operator_review_package"]["rows"],
        &(&1["review_type"] == "constraint_review")
      )

    assert %{
             "constraint_id" => "campaign:max_timeline_activities",
             "constraint_status" => "warning",
             "violation_severity" => "warning",
             "source_constraint_row" => %{"violation_severity" => "warning"}
           } = review_row

    import_row =
      Enum.find(
        artifact["cadence_import_manifest"]["rows"],
        &(&1["source_review_type"] == "constraint_review")
      )

    assert %{
             "constraint_id" => "campaign:max_timeline_activities",
             "constraint_status" => "warning",
             "violation_severity" => "warning",
             "source_constraint_row" => %{"violation_severity" => "warning"}
           } = import_row

    assert {:ok, %{"schema_contract" => "constraint_report.v1"}} =
             Schema.validate_artifact(artifact["constraint_report"])

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(artifact["operator_review_package"])

    assert {:ok, %{"schema_contract" => "cadence_import_manifest.v1"}} =
             Schema.validate_artifact(artifact["cadence_import_manifest"])
  end

  test "campaign local constraints include resource projection margin thresholds" do
    result_set =
      campaign_result_set([
        target_visibility_result(:leo_1, :target_a, 0.0, 10.0, 2.0)
      ])

    artifact =
      CampaignPlanner.build(result_set,
        generated_at: ~U[2026-05-14 00:00:00Z],
        campaign: %{
          "targets" => [%{"id" => "target_a", "priority" => 2.0}],
          "constraints" => %{
            "min_projected_storage_margin" => %{"threshold" => 0.95, "severity" => "warning"},
            "min_projected_power_margin" => 0.5
          },
          "resource_summaries" => [
            %{
              "schema_contract" => "resource_summary.v1",
              "spacecraft_id" => "leo_1",
              "storage_capacity_mb" => 100.0,
              "storage_used_mb" => 10.0,
              "power_margin" => 0.7
            }
          ],
          "scoring_policy" => %{"target_value_weight" => 1.0}
        }
      )

    assert %{
             "schema_contract" => "resource_projection_report.v1",
             "projected_resources" => [
               %{
                 "spacecraft_id" => "leo_1",
                 "projected_storage_margin" => projected_storage_margin,
                 "projected_power_margin" => 0.7
               }
             ]
           } = artifact["resource_projection_report"]

    assert_in_delta projected_storage_margin, 0.9, 1.0e-12

    assert %{
             "schema_contract" => "constraint_report.v1",
             "constraint_count" => 2,
             "row_count" => 2,
             "status" => "warning",
             "status_counts" => %{"pass" => 1, "warning" => 1, "fail" => 0}
           } = report = artifact["constraint_report"]

    assert %{
             "constraint_id" => "campaign:min_projected_storage_margin",
             "scenario_id" => "leo_1",
             "spacecraft_id" => "leo_1",
             "metric" => "projected_storage_margin",
             "operator" => ">=",
             "threshold" => 0.95,
             "value" => ^projected_storage_margin,
             "status" => "warning",
             "violation_severity" => "warning"
           } =
             Enum.find(
               report["rows"],
               &(&1["constraint_id"] == "campaign:min_projected_storage_margin")
             )

    assert %{
             "constraint_id" => "campaign:min_projected_power_margin",
             "scenario_id" => "leo_1",
             "spacecraft_id" => "leo_1",
             "metric" => "projected_power_margin",
             "operator" => ">=",
             "threshold" => 0.5,
             "value" => 0.7,
             "status" => "pass",
             "violation_severity" => "fail"
           } =
             Enum.find(
               report["rows"],
               &(&1["constraint_id"] == "campaign:min_projected_power_margin")
             )

    assert "resource_projection_constraints_are_planning_grade" in report["model_limits"]

    assert {:ok, %{"schema_contract" => "constraint_report.v1"}} =
             Schema.validate_artifact(report)

    assert %{
             "constraint_id" => "campaign:min_projected_storage_margin",
             "constraint_status" => "warning",
             "subject_id" => "leo_1",
             "source_constraint_row" => %{
               "resource_pressure_status" => "nominal",
               "spacecraft_id" => "leo_1"
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["constraint_id"] == "campaign:min_projected_storage_margin")
             )
  end

  test "repair local constraints include source resource projection margin thresholds" do
    artifact =
      repair(
        %{
          "activities" => [
            Map.put(downlink("dl_1", 100.0, 160.0), "estimated_throughput_mb", 60.0)
          ],
          "candidate_activities" => [
            Map.put(downlink("dl_1", 100.0, 160.0), "estimated_throughput_mb", 60.0)
          ]
        },
        realized_state: %{activities: []},
        current_epoch_s: 0.0,
        constraints: %{
          min_projected_downlink_margin: %{threshold: 0.9, severity: :warning}
        },
        candidate_refresh:
          candidate_refresh_artifact([],
            resource_summaries: [
              %{
                "schema_contract" => "resource_summary.v1",
                "spacecraft_id" => "leo_1",
                "downlink_capacity_mb" => 100.0,
                "downlink_margin" => 1.0
              }
            ]
          )
      )

    assert %{
             "schema_contract" => "resource_projection_report.v1",
             "projected_resources" => [
               %{
                 "spacecraft_id" => "leo_1",
                 "projected_downlink_margin" => projected_downlink_margin
               }
             ]
           } = artifact["source_resource_projection_report"]

    assert projected_downlink_margin < 0.9

    assert %{
             "schema_contract" => "constraint_report.v1",
             "model" => "campaign_repair_local_constraint_summary",
             "constraint_count" => 1,
             "row_count" => 1,
             "status" => "warning",
             "rows" => [
               %{
                 "constraint_id" => "campaign:min_projected_downlink_margin",
                 "scenario_id" => "leo_1",
                 "spacecraft_id" => "leo_1",
                 "metric" => "projected_downlink_margin",
                 "operator" => ">=",
                 "threshold" => 0.9,
                 "value" => ^projected_downlink_margin,
                 "status" => "warning",
                 "violation_severity" => "warning"
               }
             ]
           } = report = artifact["constraint_report"]

    assert {:ok, %{"schema_contract" => "constraint_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "campaign local constraints include link capacity thresholds" do
    result_set =
      campaign_result_set([
        access_result(:leo_1, :equator_prime, 0.0, 100.0),
        access_result(:leo_1, :equator_prime, 20.0, 120.0)
      ])

    artifact =
      CampaignPlanner.build(result_set,
        generated_at: ~U[2026-05-14 00:00:00Z],
        campaign: %{
          "objectives" => [
            %{"type" => "downlink_completion", "required_downlink_mb" => 150.0}
          ],
          "constraints" => %{
            "min_selected_capacity_utilization_fraction" => %{
              "threshold" => 0.75,
              "severity" => "warning"
            },
            "max_selected_downlink_shortfall_mb" => 0.0
          },
          "scoring_policy" => %{
            "contact_value_weight" => 1.0,
            "downlink_rate_mb_s" => 1.0
          }
        }
      )

    assert %{
             "schema_contract" => "link_capacity_report.v1",
             "selected_capacity_utilization_fraction" => selected_utilization,
             "selected_downlink_shortfall_mb" => selected_shortfall
           } = artifact["link_capacity_report"]

    assert selected_utilization < 0.75
    assert selected_shortfall > 0.0

    assert %{
             "schema_contract" => "constraint_report.v1",
             "constraint_count" => 2,
             "row_count" => 2,
             "status" => "fail",
             "status_counts" => %{"pass" => 0, "warning" => 1, "fail" => 1}
           } = report = artifact["constraint_report"]

    assert %{
             "constraint_id" => "campaign:min_selected_capacity_utilization_fraction",
             "scenario_id" => "link_capacity",
             "metric" => "selected_capacity_utilization_fraction",
             "operator" => ">=",
             "threshold" => 0.75,
             "value" => ^selected_utilization,
             "status" => "warning",
             "violation_severity" => "warning"
           } =
             Enum.find(
               report["rows"],
               &(&1["constraint_id"] ==
                   "campaign:min_selected_capacity_utilization_fraction")
             )

    assert %{
             "constraint_id" => "campaign:max_selected_downlink_shortfall_mb",
             "scenario_id" => "link_capacity",
             "metric" => "selected_downlink_shortfall_mb",
             "operator" => "<=",
             "value" => ^selected_shortfall,
             "status" => "fail",
             "violation_severity" => "fail"
           } =
             shortfall_row =
             Enum.find(
               report["rows"],
               &(&1["constraint_id"] == "campaign:max_selected_downlink_shortfall_mb")
             )

    assert shortfall_row["threshold"] == 0.0

    assert "link_capacity_constraints_are_fixed_rate_summaries" in report["model_limits"]

    assert {:ok, %{"schema_contract" => "constraint_report.v1"}} =
             Schema.validate_artifact(report)
  end

  test "repair local constraints include link capacity thresholds" do
    artifact =
      repair(
        %{
          "activities" => [
            Map.put(downlink("dl_1", 100.0, 160.0), "estimated_throughput_mb", 60.0)
          ],
          "candidate_activities" => [
            Map.put(downlink("dl_1", 100.0, 160.0), "estimated_throughput_mb", 60.0)
          ]
        },
        realized_state: %{activities: []},
        current_epoch_s: 0.0,
        scoring_policy: %{required_downlink_mb: 100.0},
        constraints: %{
          max_selected_downlink_shortfall_mb: %{threshold: 0.0, severity: :warning}
        }
      )

    assert %{
             "schema_contract" => "link_capacity_report.v1",
             "selected_downlink_shortfall_mb" => selected_shortfall
           } = artifact["link_capacity_report"]

    assert selected_shortfall > 0.0

    assert %{
             "schema_contract" => "constraint_report.v1",
             "model" => "campaign_repair_local_constraint_summary",
             "constraint_count" => 1,
             "row_count" => 1,
             "status" => "warning",
             "rows" => [
               %{
                 "constraint_id" => "campaign:max_selected_downlink_shortfall_mb",
                 "scenario_id" => "link_capacity",
                 "metric" => "selected_downlink_shortfall_mb",
                 "operator" => "<=",
                 "value" => ^selected_shortfall,
                 "status" => "warning",
                 "violation_severity" => "warning"
               } = row
             ]
           } = report = artifact["constraint_report"]

    assert row["threshold"] == 0.0

    assert {:ok, %{"schema_contract" => "constraint_report.v1"}} =
             Schema.validate_artifact(report)
  end

  defp candidate_refresh_artifact(candidates, opts) do
    %{
      "schema_version" => 1,
      "schema_contract" => "candidate_refresh.v1",
      "artifact_type" => "candidate_refresh",
      "generated_at" => "2026-05-14T00:00:00Z",
      "planner" => "OrbitalDynamics.CandidateRefresh.V1",
      "refresh_id" => Keyword.get(opts, :refresh_id, "candidate_refresh:test:abc"),
      "study_id" => "candidate_refresh_test",
      "snapshot_id" => "ops-state-1",
      "current_epoch_s" => 0.0,
      "remaining_horizon" => %{
        "starts_at_s" => 0.0,
        "ends_at_s" => 1_000.0,
        "output_step_s" => 60.0
      },
      "accepted_planning_state" => %{
        "snapshot_id" => "ops-state-1",
        "spacecraft_state_count" => 1
      },
      "refreshed_windows" => %{
        "access_windows" => [],
        "target_visibility_windows" => [],
        "eclipse_intervals" => []
      },
      "candidate_activities" => candidates,
      "contact_intents" => Keyword.get(opts, :contact_intents, []),
      "resource_summaries" => Keyword.get(opts, :resource_summaries, []),
      "contact_filter_report" => Keyword.get(opts, :contact_filter_report),
      "contact_allocation_report" => Keyword.get(opts, :contact_allocation_report),
      "resource_filter_report" => Keyword.get(opts, :resource_filter_report),
      "refresh_budget_report" => Keyword.get(opts, :refresh_budget_report),
      "candidate_diff_report" => Keyword.get(opts, :candidate_diff_report),
      "freshness_report" => Keyword.get(opts, :freshness_report),
      "invalidated_candidates" => [],
      "validation_records" => [],
      "warnings" => [],
      "assumptions" => %{},
      "provenance" => %{},
      "source_window_lineage" =>
        Enum.map(candidates, fn candidate ->
          %{
            "candidate_activity_id" => candidate["id"],
            "source_window_id" => candidate["source_window_id"],
            "source_window_type" => get_in(candidate, ["source_window", "type"]),
            "scenario_id" => candidate["scenario_id"]
          }
        end)
    }
  end

  defp campaign_result_set(event_results) do
    ResultSet.new!(%{
      study_id: :campaign,
      trajectory_results: [],
      event_results: event_results,
      errors: [],
      assumptions: %{},
      metadata: %{}
    })
  end

  defp target_visibility_result(scenario_id, target_id, starts_at_s, ends_at_s, priority) do
    %{
      scenario_id: scenario_id,
      event_type: :target_visibility,
      events: [
        %{
          type: :target_visibility,
          starts_at: Epoch.new!(starts_at_s, :tdb),
          ends_at: Epoch.new!(ends_at_s, :tdb),
          metadata: %{
            target_id: target_id,
            target_priority: priority,
            max_elevation_deg: 60.0,
            minimum_elevation_deg: 10.0
          }
        }
      ],
      source: %{target_id: target_id}
    }
  end

  defp access_result(scenario_id, ground_station_id, starts_at_s, ends_at_s) do
    %{
      scenario_id: scenario_id,
      event_type: :ground_station_access,
      events: [
        %{
          type: :ground_station_access,
          starts_at: Epoch.new!(starts_at_s, :tdb),
          ends_at: Epoch.new!(ends_at_s, :tdb),
          metadata: %{
            max_elevation_deg: 45.0,
            minimum_elevation_deg: 5.0
          }
        }
      ],
      source: %{ground_station_id: ground_station_id}
    }
  end
end
