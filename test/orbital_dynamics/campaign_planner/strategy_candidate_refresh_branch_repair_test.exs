Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyCandidateRefreshBranchRepairTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "strategy passes candidate refresh candidates into branch repair" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_500.0},
        "activities" => [downlink("dl_1", 100.0, 160.0)],
        "candidate_activities" => [downlink("dl_stale", 700.0, 760.0)]
      })

    artifact =
      strategy(prior_plan,
        branches: [
          %{id: "baseline"},
          %{
            id: "outage",
            events: [
              %{
                type: "ground_station_outage",
                ground_station_id: "equator_prime",
                starts_at_s: 90.0,
                ends_at_s: 200.0
              }
            ]
          }
        ],
        candidate_refresh:
          candidate_refresh_artifact(
            [
              refreshed_downlink("dl_refreshed", 500.0, 560.0)
              |> Map.put("estimated_energy_used_wh", 80.0)
              |> Map.put("source_station_calendar_entry", %{
                "id" => "station_calendar_entry_1",
                "provider_id" => "ops_calendar",
                "provider_entry_id" => "ops_calendar_window_1",
                "direction" => "uplink"
              })
            ],
            contact_filter_report: contact_filter_report(),
            resource_filter_report: resource_filter_report(),
            resource_summaries: [
              %{
                "schema_contract" => "resource_summary.v1",
                "spacecraft_id" => "leo_1",
                "storage_capacity_mb" => 1000.0,
                "storage_used_mb" => 30.0,
                "downlink_capacity_mb" => 10.0,
                "battery_capacity_wh" => 100.0,
                "battery_energy_used_wh" => 50.0,
                "fuel_margin" => 0.8,
                "power_margin" => 0.7,
                "payload_available" => true,
                "antenna_available" => true
              }
            ]
          ),
        current_epoch_s: 0.0
      )

    assert [
             %{
               "activity_id" => "dl_1",
               "repair_action" => "moved",
               "replacement_activity_id" => "dl_refreshed"
             }
           ] =
             branch(artifact, "outage")["repair_result"]["deltas"]
             |> Enum.filter(&(&1["activity_id"] == "dl_1"))

    assert branch(artifact, "outage")["repair_result"]["assumptions"]["candidate_source"][
             "type"
           ] == "candidate_refresh.v1"

    assert branch(artifact, "outage")["repair_result"]["source_contact_filter_report"][
             "schema_contract"
           ] == "contact_filter_report.v1"

    assert branch(artifact, "outage")["repair_result"]["source_resource_filter_report"][
             "schema_contract"
           ] == "resource_filter_report.v1"

    assert %{
             "schema_contract" => "resource_projection_report.v1",
             "model" => "thin_strategy_branch_activity_resource_projection",
             "resource_source_quality_counts" => %{"unknown" => 1},
             "resource_trust_boundary_status_counts" => %{"missing" => 1},
             "projected_resources" => [
               %{
                 "spacecraft_id" => "leo_1",
                 "downlink_count" => 1,
                 "estimated_downlink_mb" => 60.0,
                 "storage_limited_downlinked_mb" => 30.0,
                 "unused_downlink_capacity_mb" => 30.0,
                 "projected_storage_margin" => projected_storage_margin,
                 "projected_downlink_margin" => projected_downlink_margin,
                 "projected_downlink_shortfall_mb" => 50.0,
                 "projected_power_margin" => projected_power_margin,
                 "projected_battery_overuse_wh" => 30.0,
                 "activity_resource_flow" => [
                   %{
                     "activity_id" => "dl_refreshed",
                     "activity_type" => "downlink",
                     "ground_station_id" => "equator_prime",
                     "direction" => "downlink",
                     "station_calendar_entry_id" => "station_calendar_entry_1",
                     "station_calendar_directions" => ["command"],
                     "planned_downlink_mb" => 60.0,
                     "downlinked_mb" => 30.0,
                     "unused_downlink_capacity_mb" => 30.0,
                     "downlink_shortfall_mb" => 50.0,
                     "battery_energy_consumed_wh" => 80.0,
                     "battery_energy_used_after_wh" => 130.0,
                     "battery_overuse_wh" => 30.0
                   }
                 ]
               }
             ]
           } = branch(artifact, "outage")["resource_projection_report"]

    assert projected_storage_margin == 1.0
    assert projected_downlink_margin == 0.0
    assert projected_power_margin == 0.0
    projected_storage_remaining_mb = 1000.0
    projected_downlink_remaining_mb = 0.0

    outage_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "outage"))

    assert outage_row["resource_projection_spacecraft_count"] == 1
    assert outage_row["projected_storage_margin"] == 1.0
    assert outage_row["projected_storage_remaining_mb"] == projected_storage_remaining_mb
    assert outage_row["projected_downlink_margin"] == 0.0
    assert outage_row["projected_downlink_remaining_mb"] == projected_downlink_remaining_mb
    assert outage_row["projected_power_margin"] == 0.0
    assert outage_row["projected_downlink_shortfall_mb"] == 50.0
    assert outage_row["projected_battery_overuse_wh"] == 30.0
    assert outage_row["storage_limited_downlinked_mb"] == 30.0
    assert outage_row["unused_downlink_capacity_mb"] == 30.0
    assert outage_row["resource_projection_flow_count"] == 1
    assert outage_row["resource_projection_peak_downlink_shortfall_mb"] == 50.0
    assert outage_row["resource_projection_peak_battery_overuse_wh"] == 30.0
    assert outage_row["resource_projection_peak_unused_downlink_capacity_mb"] == 30.0
    assert outage_row["resource_source_quality_counts"] == %{"unknown" => 1}
    assert outage_row["resource_trust_boundary_status_counts"] == %{"missing" => 1}
    assert outage_row["first_resource_pressure_activity_id"] == "dl_refreshed"
    assert outage_row["first_resource_pressure_kind"] == "downlink_shortfall"
    assert outage_row["first_resource_pressure_direction"] == "downlink"
    assert outage_row["first_resource_pressure_ground_station_id"] == "equator_prime"

    assert outage_row["first_resource_pressure_station_calendar_entry_id"] ==
             "station_calendar_entry_1"

    assert outage_row["first_resource_pressure_station_calendar_provider_id"] == "ops_calendar"

    assert outage_row["first_resource_pressure_station_calendar_provider_entry_id"] ==
             "ops_calendar_window_1"

    assert outage_row["first_resource_pressure_station_calendar_directions"] == ["command"]

    assert %{
             "value" => 50.0,
             "direction" => "downlink",
             "ground_station_id" => "equator_prime",
             "station_calendar_entry_id" => "station_calendar_entry_1",
             "station_calendar_provider_id" => "ops_calendar",
             "station_calendar_provider_entry_id" => "ops_calendar_window_1",
             "station_calendar_directions" => ["command"],
             "first_resource_pressure_activity_id" => "dl_refreshed",
             "first_resource_pressure_direction" => "downlink",
             "first_resource_pressure_ground_station_id" => "equator_prime",
             "first_resource_pressure_station_calendar_entry_id" => "station_calendar_entry_1",
             "first_resource_pressure_station_calendar_provider_id" => "ops_calendar",
             "first_resource_pressure_station_calendar_provider_entry_id" =>
               "ops_calendar_window_1",
             "first_resource_pressure_station_calendar_directions" => ["command"]
           } =
             branch(artifact, "outage")["risk_indicators"]
             |> Enum.find(&(&1["type"] == "downlink_shortfall"))

    assert_storage_downlink_pressure_score_terms(branch(artifact, "outage"), artifact, 1, 2)

    assert %{
             "review_type" => "strategy_tradeoff",
             "branch_id" => "outage",
             "required_operator_action" => "review_branch_comparison",
             "projected_storage_remaining_mb" => ^projected_storage_remaining_mb,
             "projected_downlink_remaining_mb" => ^projected_downlink_remaining_mb,
             "first_resource_pressure_station_calendar_provider_id" => "ops_calendar",
             "first_resource_pressure_station_calendar_provider_entry_id" =>
               "ops_calendar_window_1",
             "source_branch_comparison" => %{
               "projected_storage_remaining_mb" => ^projected_storage_remaining_mb,
               "projected_downlink_remaining_mb" => ^projected_downlink_remaining_mb,
               "first_resource_pressure_station_calendar_provider_id" => "ops_calendar",
               "first_resource_pressure_station_calendar_provider_entry_id" =>
                 "ops_calendar_window_1"
             }
           } =
             artifact["operator_review_package"]["rows"]
             |> Enum.find(
               &(&1["review_type"] == "strategy_tradeoff" and &1["branch_id"] == "outage" and
                   &1["required_operator_action"] == "review_branch_comparison")
             )

    assert %{
             "import_action" => "review_strategy_tradeoff",
             "branch_id" => "outage",
             "required_operator_action" => "review_branch_comparison",
             "projected_storage_remaining_mb" => ^projected_storage_remaining_mb,
             "projected_downlink_remaining_mb" => ^projected_downlink_remaining_mb,
             "first_resource_pressure_station_calendar_provider_id" => "ops_calendar",
             "first_resource_pressure_station_calendar_provider_entry_id" =>
               "ops_calendar_window_1",
             "source_branch_comparison" => %{
               "projected_storage_remaining_mb" => ^projected_storage_remaining_mb,
               "projected_downlink_remaining_mb" => ^projected_downlink_remaining_mb,
               "first_resource_pressure_station_calendar_provider_id" => "ops_calendar",
               "first_resource_pressure_station_calendar_provider_entry_id" =>
                 "ops_calendar_window_1"
             }
           } =
             artifact["cadence_import_manifest"]["rows"]
             |> Enum.find(
               &(&1["import_action"] == "review_strategy_tradeoff" and
                   &1["branch_id"] == "outage" and
                   &1["required_operator_action"] == "review_branch_comparison")
             )

    assert Enum.any?(
             branch(artifact, "outage")["risk_indicators"],
             &(&1["type"] == "battery_depletion" and &1["value"] == 30.0 and
                 &1["first_resource_pressure_kind"] == "battery_depletion")
           )

    assert_battery_depletion_pressure_score_terms(branch(artifact, "outage"), artifact, 2)

    assert branch(artifact, "outage")["approval_status"] == "blocked_by_policy"
    assert get_in(branch(artifact, "outage"), ["policy_decision", "risk_count"]) >= 2

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(branch(artifact, "outage")["resource_projection_report"])

    assert {:ok, %{"schema_contract" => "branch_comparison_report.v1"}} =
             Schema.validate_artifact(artifact["branch_comparison_report"])
  end

  test "strategy branch can override shared candidate refresh candidates" do
    prior_plan =
      base_plan(%{
        "planning_horizon" => %{"duration_s" => 1_500.0},
        "activities" => [downlink("dl_1", 100.0, 160.0)],
        "candidate_activities" => [downlink("dl_stale", 700.0, 760.0)]
      })

    branch_refreshed_windows = %{
      "access_windows" => [],
      "target_visibility_windows" => [
        %{
          "id" => "window:leo_1:target_visibility:target_a_late:1",
          "type" => "target_visibility",
          "scenario_id" => "leo_1",
          "target_id" => "target_a",
          "starts_at_s" => 600.0,
          "ends_at_s" => 660.0
        }
      ],
      "eclipse_intervals" => []
    }

    branch_candidate_refresh_assumptions = %{
      "refresh_model" => "accepted_planning_state_to_sampled_windows_v1",
      "constraints" => %{"avoid_eclipse" => false},
      "scoring_policy" => %{"target_value_weight" => 3.0},
      "propagator_opts" => %{"max_step_s" => 15.0}
    }

    branch_candidate_refresh_warnings = [
      "branch-local source warning",
      "no prior candidates compared",
      "branch-local source warning"
    ]

    artifact =
      strategy(prior_plan,
        branches: [
          %{id: "baseline"},
          %{
            id: "outage",
            events: [
              %{
                type: "ground_station_outage",
                ground_station_id: "equator_prime",
                starts_at_s: 90.0,
                ends_at_s: 200.0
              }
            ],
            candidate_refresh:
              candidate_refresh_artifact(
                [refreshed_downlink("dl_branch_refreshed", 600.0, 660.0)],
                refresh_id: "candidate_refresh:test:branch",
                candidate_diff_report: candidate_diff_report(),
                freshness_report: freshness_report("stale"),
                refreshed_windows: branch_refreshed_windows,
                assumptions: branch_candidate_refresh_assumptions,
                warnings: branch_candidate_refresh_warnings
              )
          }
        ],
        candidate_refresh:
          candidate_refresh_artifact(
            [refreshed_downlink("dl_shared_refreshed", 500.0, 560.0)],
            refresh_id: "candidate_refresh:test:shared"
          ),
        current_epoch_s: 0.0
      )

    outage = branch(artifact, "outage")

    assert [
             %{
               "activity_id" => "dl_1",
               "repair_action" => "moved",
               "replacement_activity_id" => "dl_branch_refreshed"
             }
           ] =
             outage["repair_result"]["deltas"]
             |> Enum.filter(&(&1["activity_id"] == "dl_1"))

    assert outage["repair_result"]["assumptions"]["candidate_source"]["refresh_id"] ==
             "candidate_refresh:test:branch"

    assert outage["repair_result"]["source_refreshed_windows"] == branch_refreshed_windows

    assert outage["repair_result"]["source_candidate_refresh_assumptions"] ==
             branch_candidate_refresh_assumptions

    assert outage["repair_result"]["source_candidate_refresh_warnings"] ==
             branch_candidate_refresh_warnings

    assert Enum.count(outage["repair_result"]["warnings"], &(&1 == "branch-local source warning")) ==
             1

    assert outage["assumptions"]["candidate_source"]["scope"] == "branch"
    assert outage["provenance"]["candidate_source"]["scope"] == "branch"

    refute Enum.any?(
             artifact["operator_review_package"]["rows"],
             &String.contains?(&1["source"] || "", "source_refreshed_windows")
           )

    refute Enum.any?(
             artifact["cadence_import_manifest"]["rows"],
             &String.contains?(
               &1["source"] || get_in(&1, ["source_review_row", "source"]) || "",
               "source_refreshed_windows"
             )
           )

    refute Enum.any?(
             artifact["operator_review_package"]["rows"],
             &String.contains?(&1["source"] || "", "source_candidate_refresh_warnings")
           )

    refute Enum.any?(
             artifact["cadence_import_manifest"]["rows"],
             &String.contains?(
               &1["source"] || get_in(&1, ["source_review_row", "source"]) || "",
               "source_candidate_refresh_warnings"
             )
           )

    refute Enum.any?(
             artifact["operator_review_package"]["rows"],
             &String.contains?(&1["source"] || "", "source_candidate_refresh_assumptions")
           )

    refute Enum.any?(
             artifact["cadence_import_manifest"]["rows"],
             &String.contains?(
               &1["source"] || get_in(&1, ["source_review_row", "source"]) || "",
               "source_candidate_refresh_assumptions"
             )
           )

    assert %{
             "branch_id" => "outage",
             "review_type" => "candidate_diff_review",
             "source" =>
               "campaign_strategy.branches.repair_result.source_candidate_diff_report.invalidated_candidates",
             "required_operator_action" => "review_candidate_diff",
             "invalidated_candidate_id" => "dl_stale"
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "candidate_diff_review" and &1["branch_id"] == "outage")
             )

    assert %{
             "branch_id" => "outage",
             "import_action" => "review_candidate_diff",
             "source_review_type" => "candidate_diff_review",
             "invalidated_candidate_id" => "dl_stale",
             "refresh_gate" => "candidate_diff",
             "import_status" => "review_required_before_import"
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["import_action"] == "review_candidate_diff" and &1["branch_id"] == "outage")
             )

    assert %{
             "branch_id" => "outage",
             "review_type" => "freshness_review",
             "source" => "campaign_strategy.branches.repair_result.source_freshness_report",
             "required_operator_action" => "review_refresh_freshness",
             "freshness_status" => "stale",
             "source_freshness_report" => %{"schema_contract" => "freshness_report.v1"}
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "freshness_review" and &1["branch_id"] == "outage")
             )

    assert %{
             "branch_id" => "outage",
             "import_action" => "review_refresh_freshness",
             "source_review_type" => "freshness_review",
             "freshness_status" => "stale",
             "import_status" => "review_required_before_import"
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["import_action"] == "review_refresh_freshness" and
                   &1["branch_id"] == "outage")
             )
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
      "refreshed_windows" =>
        Keyword.get(opts, :refreshed_windows, %{
          "access_windows" => [],
          "target_visibility_windows" => [],
          "eclipse_intervals" => []
        }),
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
      "warnings" => Keyword.get(opts, :warnings, []),
      "assumptions" => Keyword.get(opts, :assumptions, %{}),
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

  defp candidate_diff_report do
    %{
      "schema_contract" => "candidate_diff_report.v1",
      "model" => "candidate_id_set_diff_with_semantic_change_reasons",
      "prior_candidate_count" => 1,
      "refreshed_candidate_count" => 1,
      "retained_candidate_count" => 0,
      "new_candidate_count" => 1,
      "invalidated_candidate_count" => 1,
      "retained_candidates" => [],
      "new_candidates" => [
        %{
          "id" => "dl_refreshed",
          "type" => "downlink",
          "scenario_id" => "leo_1",
          "starts_at_s" => 500.0,
          "ends_at_s" => 560.0,
          "diff_reason" => "not_present_in_prior_candidate_set"
        }
      ],
      "invalidated_candidates" => [
        %{
          "id" => "dl_stale",
          "invalidated_reason" => "not_present_in_refreshed_candidate_set"
        }
      ]
    }
  end

  defp contact_filter_report do
    %{
      "schema_contract" => "contact_filter_report.v1",
      "model" => "thin_ground_network_availability_filter",
      "input_candidate_count" => 2,
      "kept_candidate_count" => 1,
      "suppressed_candidate_count" => 1,
      "suppressed_candidates" => [
        %{
          "id" => "dl_suppressed_contact",
          "type" => "downlink",
          "scenario_id" => "leo_1",
          "starts_at_s" => 400.0,
          "ends_at_s" => 460.0,
          "suppressed_reason" => "ground_station_unavailable"
        }
      ]
    }
  end

  defp resource_filter_report do
    %{
      "schema_contract" => "resource_filter_report.v1",
      "model" => "resource_summary_availability_and_margin_filter",
      "input_candidate_count" => 2,
      "kept_candidate_count" => 1,
      "suppressed_candidate_count" => 1,
      "suppressed_candidates" => [
        %{
          "id" => "obs_suppressed_resource",
          "type" => "observe",
          "scenario_id" => "leo_1",
          "starts_at_s" => 300.0,
          "ends_at_s" => 360.0,
          "suppressed_reason" => "payload_unavailable"
        }
      ]
    }
  end

  defp freshness_report(status) do
    stale_reasons =
      if status == "stale",
        do: ["accepted_snapshot_older_than_policy"],
        else: []

    %{
      "schema_contract" => "freshness_report.v1",
      "model" => "accepted_snapshot_horizon_and_quality_freshness",
      "generated_at" => "2026-05-14T00:00:00Z",
      "accepted_at" => "2026-05-13T23:00:00Z",
      "current_epoch_s" => 165.0,
      "horizon_starts_at_s" => 165.0,
      "accepted_snapshot_age_s" => 3600.0,
      "horizon_start_offset_s" => 0.0,
      "max_snapshot_age_s" => 60.0,
      "max_horizon_start_offset_s" => 1.0,
      "status" => status,
      "stale_reasons" => stale_reasons,
      "unknown_reasons" => []
    }
  end

  defp assert_storage_downlink_pressure_score_terms(
         branch,
         artifact,
         expected_pressure_count,
         extra_split_pressure_count
       ) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    storage_downlink_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &(&1["type"] in [
            "storage_overflow",
            "downlink_shortfall",
            "storage_margin_low",
            "downlink_margin_low"
          ])
      )

    assert storage_downlink_pressure_count == expected_pressure_count

    assert branch["score_terms"]["storage_downlink_pressure_penalty"] ==
             -storage_downlink_pressure_count * risk_weight

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) -
                 storage_downlink_pressure_count - extra_split_pressure_count) * risk_weight

    assert "storage_downlink_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "storage_downlink_pressure_penalty" and
                 &1["value"] < 0.0)
           )
  end

  defp assert_battery_depletion_pressure_score_terms(branch, artifact, extra_split_pressure_count) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    battery_depletion_pressure_count =
      Enum.count(branch["risk_indicators"], &(&1["type"] == "battery_depletion"))

    assert battery_depletion_pressure_count > 0

    assert branch["score_terms"]["battery_depletion_pressure_penalty"] ==
             -battery_depletion_pressure_count * risk_weight

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) -
                 battery_depletion_pressure_count - extra_split_pressure_count) *
               risk_weight

    assert "battery_depletion_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "battery_depletion_pressure_penalty" and &1["value"] < 0.0)
           )
  end
end
