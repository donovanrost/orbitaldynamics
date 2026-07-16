defmodule OrbitalDynamics.OperatorReview.ResourceProjectionTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "resource projection report source ids fall back through report id generation" do
    assert %{"source_artifact_id" => "resource-projection:report"} =
             OperatorReview.from_resource_projection_report(%{id: :"resource-projection:report"})

    assert %{"source_artifact_id" => "resource-projection:source"} =
             OperatorReview.from_resource_projection_report(%{
               assumptions: %{source: :"resource-projection:source"}
             })

    assert %{"source_artifact_id" => "resource_projection_report"} =
             OperatorReview.from_resource_projection_report(%{})
  end

  test "resource projection flow summary source ids fall back through summary id generation" do
    assert %{"source_artifact_id" => "resource-projection:flow"} =
             OperatorReview.from_resource_projection_flow_summary(%{
               id: :"resource-projection:flow"
             })

    assert %{"source_artifact_id" => "resource-projection:summary-source"} =
             OperatorReview.from_resource_projection_flow_summary(%{
               source: :"resource-projection:summary-source"
             })

    assert %{"source_artifact_id" => "resource-projection:assumption-source"} =
             OperatorReview.from_resource_projection_flow_summary(%{
               assumptions: %{source: :"resource-projection:assumption-source"}
             })

    assert %{"source_artifact_id" => "resource_projection_flow_summary"} =
             OperatorReview.from_resource_projection_flow_summary(%{})
  end

  test "builds review package from standalone resource projection report rows" do
    report = %{
      "schema_contract" => "resource_projection_report.v1",
      "model" => "thin_campaign_selected_activity_resource_projection",
      "input_resource_summary_count" => 1,
      "activity_count" => 2,
      "projected_resources" => [
        %{
          "spacecraft_id" => "leo_1",
          "activity_count" => 2,
          "effective_activity_count" => 2,
          "ignored_activity_count" => 0,
          "ignored_activity_ids" => [],
          "observation_count" => 1,
          "downlink_count" => 1,
          "estimated_storage_produced_mb" => 0.0,
          "estimated_downlink_mb" => 0.0,
          "storage_limited_downlinked_mb" => 0.0,
          "unused_downlink_capacity_mb" => 0.0,
          "starting_storage_used_mb" => 250.0,
          "projected_storage_used_mb" => 250.0,
          "storage_capacity_mb" => 1000.0,
          "starting_storage_margin" => 0.75,
          "projected_storage_margin" => 0.75,
          "downlink_capacity_mb" => 600.0,
          "starting_downlink_margin" => 0.65,
          "projected_downlink_margin" => 1.0,
          "activity_resource_flow" => [
            %{
              "activity_id" => "obs_1",
              "activity_type" => "observe",
              "starts_at_s" => 10.0,
              "storage_overflow_mb" => 12.0,
              "downlink_shortfall_mb" => 0.0,
              "battery_energy_consumed_wh" => 20.0,
              "battery_energy_generated_wh" => 0.0,
              "battery_energy_delta_wh" => 20.0,
              "battery_overuse_wh" => 4.0
            },
            %{
              "activity_id" => "dl_1",
              "activity_type" => "downlink",
              "starts_at_s" => 20.0,
              "storage_overflow_mb" => 0.0,
              "downlink_shortfall_mb" => 3.0,
              "unused_downlink_capacity_mb" => 8.0,
              "battery_energy_consumed_wh" => 3.0,
              "battery_energy_generated_wh" => 8.0,
              "battery_energy_delta_wh" => -5.0,
              "battery_overuse_wh" => 0.0
            }
          ],
          "fuel_margin" => 0.82,
          "power_margin" => 0.74,
          "resource_source_quality" => "operator_supplied",
          "resource_trust_boundary_status" => "declared",
          "payload_available" => true,
          "antenna_available" => true,
          "approval_requirements" => [
            %{
              "schema_contract" => "approval_requirement.v1",
              "id" => "approval:resource_projection:leo_1:storage_overflow",
              "activity_id" => "resource_projection:leo_1",
              "activity_type" => "resource_projection",
              "action" => "review_resource_projection",
              "requirement_type" => "operator_review",
              "reason" => "storage_overflow 12.0 MB for leo_1",
              "activity_context" => %{
                "spacecraft_id" => "leo_1",
                "risk_type" => "storage_overflow"
              }
            }
          ],
          "approval_rule_matches" => [
            %{
              "rule_id" => "resource_pressure_block",
              "classification" => "blocked_by_policy",
              "risk_type" => "storage_overflow"
            }
          ],
          "policy_decision" => %{
            "schema_contract" => "policy_decision.v1",
            "classification" => "blocked_by_policy",
            "policy_bundle_id" => "resource_projection_authority_v1",
            "approval_requirement_count" => 1,
            "risk_count" => 1,
            "rule_matches" => [],
            "escalations" => [
              %{
                "rule_id" => "unmatched_resource_rule",
                "escalation_queue" => "ignore_queue"
              },
              %{
                "rule_id" => "resource_pressure_block",
                "required_authority" => "resource_authority",
                "escalation_level" => "mission_planner",
                "escalation_queue" => "resource_planning",
                "escalation_role" => "resource_planner",
                "sla_s" => 1200
              }
            ]
          },
          "warnings" => []
        }
      ],
      "assumptions" => %{"source" => "campaign.resource_summaries"}
    }

    package = OperatorReview.from_resource_projection_report(report)

    assert OrbitalDynamics.operator_review_package(report) == package

    assert %{
             "source_artifact_type" => "resource_projection_report.v1",
             "source_artifact_id" => "campaign.resource_summaries",
             "review_count" => 1,
             "resource_projection_review_count" => 1
           } = package

    first_row = List.first(package["rows"])

    assert %{
             "review_type" => "resource_projection_review",
             "source" => "resource_projection_report.projected_resources",
             "subject_id" => "leo_1",
             "spacecraft_id" => "leo_1",
             "required_operator_action" => "review_resource_projection",
             "activity_count" => 2,
             "effective_activity_count" => 2,
             "ignored_activity_count" => 0,
             "ignored_activity_ids" => [],
             "observation_count" => 1,
             "downlink_count" => 1,
             "projected_storage_margin" => 0.75,
             "projected_downlink_margin" => 1.0,
             "resource_flow_count" => 2,
             "total_battery_energy_consumed_wh" => 23.0,
             "total_battery_energy_generated_wh" => 8.0,
             "net_battery_energy_delta_wh" => 15.0,
             "peak_storage_overflow_mb" => 12.0,
             "peak_downlink_shortfall_mb" => 3.0,
             "peak_battery_overuse_wh" => 4.0,
             "peak_unused_downlink_capacity_mb" => 8.0,
             "first_resource_pressure_activity_id" => "obs_1",
             "first_resource_pressure_activity_type" => "observe",
             "first_resource_pressure_kind" => "storage_overflow",
             "first_resource_pressure_starts_at_s" => 10.0,
             "reason" => "review leo_1 resource pressure at obs_1: storage_overflow",
             "resource_source_quality" => "operator_supplied",
             "resource_trust_boundary_status" => "declared",
             "payload_available" => true,
             "antenna_available" => true,
             "approval_requirements" => [
               %{
                 "id" => "approval:resource_projection:leo_1:storage_overflow",
                 "action" => "review_resource_projection"
               }
             ],
             "approval_rule_matches" => [
               %{
                 "rule_id" => "resource_pressure_block",
                 "classification" => "blocked_by_policy",
                 "risk_type" => "storage_overflow"
               }
             ],
             "requirement_type" => "operator_review",
             "required_authority" => "resource_authority",
             "policy_bundle_id" => "resource_projection_authority_v1",
             "rule_id" => "resource_pressure_block",
             "escalation_level" => "mission_planner",
             "escalation_queue" => "resource_planning",
             "escalation_role" => "resource_planner",
             "sla_s" => 1200,
             "source_policy_decision" => %{
               "schema_contract" => "policy_decision.v1",
               "policy_bundle_id" => "resource_projection_authority_v1"
             },
             "source_policy_escalation" => %{
               "rule_id" => "resource_pressure_block",
               "escalation_queue" => "resource_planning"
             },
             "source_resource_projection" => %{
               "spacecraft_id" => "leo_1",
               "resource_trust_boundary_status" => "declared"
             }
           } = first_row

    assert first_row["estimated_storage_produced_mb"] == 0.0
    assert first_row["estimated_downlink_mb"] == 0.0
    assert first_row["storage_limited_downlinked_mb"] == 0.0
    assert first_row["unused_downlink_capacity_mb"] == 0.0

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid =
      update_in(package, ["rows"], fn [row | rows] ->
        stale_row =
          row
          |> Map.put("activity_count", 99)
          |> Map.put("effective_activity_count", 99)
          |> Map.put("observation_count", 99)
          |> Map.put("downlink_count", 99)
          |> Map.put("ignored_activity_count", 1)
          |> Map.put("ignored_activity_ids", ["stale_ignored"])

        [stale_row | rows]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].activity_count" and
                 &1["message"] == "must equal source_resource_projection flow row count")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].effective_activity_count" and
                 &1["message"] ==
                   "must equal source_resource_projection projected flow row count")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].ignored_activity_ids" and
                 &1["message"] ==
                   "must match source_resource_projection ignored activity flow row IDs")
           )
  end

  test "builds review package from resource projection flow summary rows" do
    flow_summary = resource_projection_flow_summary()

    package = OperatorReview.from_resource_projection_flow_summary(flow_summary)

    assert OrbitalDynamics.operator_review_package(flow_summary) == package

    assert %{
             "source_artifact_type" => "resource_projection_flow_summary.v1",
             "source_artifact_id" => "flow_handoff",
             "review_count" => 1,
             "resource_projection_review_count" => 1
           } = package

    first_row = List.first(package["rows"])

    assert %{
             "review_type" => "resource_projection_review",
             "source" => "resource_projection_flow_summary.projected_resources",
             "subject_id" => "leo_1",
             "spacecraft_id" => "leo_1",
             "required_operator_action" => "review_resource_projection",
             "activity_count" => 2,
             "effective_activity_count" => 2,
             "ignored_activity_count" => 0,
             "ignored_activity_ids" => [],
             "resource_flow_count" => 2,
             "total_battery_energy_consumed_wh" => 20.0,
             "total_battery_energy_generated_wh" => 5.0,
             "net_battery_energy_delta_wh" => 15.0,
             "peak_storage_overflow_mb" => 10.0,
             "peak_downlink_shortfall_mb" => 5.0,
             "first_resource_pressure_activity_id" => "obs_early",
             "first_resource_pressure_activity_type" => "observe",
             "first_resource_pressure_kind" => "storage_overflow",
             "source_resource_projection_flow_summary" => %{
               "schema_contract" => "resource_projection_flow_summary.v1",
               "resource_flow_status" => "review_required",
               "resource_pressure_types" => ["downlink_shortfall", "storage_overflow"],
               "total_downlink_shortfall_mb" => 5.0
             },
             "source_resource_projection" => %{
               "spacecraft_id" => "leo_1",
               "source_resource_projection_flow_summary" => %{
                 "schema_contract" => "resource_projection_flow_summary.v1"
               }
             }
           } = first_row

    assert length(first_row["source_resource_projection"]["activity_resource_flow"]) == 2
    assert first_row["projected_storage_remaining_mb"] == 0.0
    assert first_row["projected_downlink_remaining_mb"] == 0.0

    flow_context = first_row["source_resource_projection_flow_summary"]
    assert flow_context["total_projected_storage_remaining_mb"] == 0.0
    assert flow_context["minimum_projected_storage_remaining_mb"] == 0.0
    assert flow_context["total_projected_downlink_remaining_mb"] == 0.0
    assert flow_context["minimum_projected_downlink_remaining_mb"] == 0.0

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    stale_source_summary =
      update_in(package, ["rows"], fn [row | rows] ->
        stale_row =
          put_in(
            row,
            [
              "source_resource_projection",
              "source_resource_projection_flow_summary",
              "total_downlink_shortfall_mb"
            ],
            6.0
          )

        [stale_row | rows]
      end)

    assert {:error, report} = Schema.validate_artifact(stale_source_summary)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_resource_projection_flow_summary" and
                 &1["message"] ==
                   "must match source_resource_projection.source_resource_projection_flow_summary")
           )

    invalid_source_evidence_id =
      update_in(package, ["rows"], fn [row | rows] ->
        invalid_row =
          row
          |> put_in(["source_resource_projection_flow_summary", "id"], "summary with spaces")
          |> put_in(
            ["source_resource_projection", "source_resource_projection_flow_summary", "id"],
            "summary with spaces"
          )

        [invalid_row | rows]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_evidence_id)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_resource_projection_flow_summary.id")
           )

    invalid =
      update_in(package, ["rows"], fn [row | rows] ->
        stale_row =
          row
          |> Map.put("activity_count", 99)
          |> Map.put("ignored_activity_count", 1)
          |> Map.put("ignored_activity_ids", ["stale_ignored"])

        [stale_row | rows]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].activity_count" and
                 &1["message"] == "must equal source_resource_projection flow row count")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].ignored_activity_ids" and
                 &1["message"] ==
                   "must match source_resource_projection ignored activity flow row IDs")
           )
  end

  test "preserves source-row first resource pressure fields without nested flow rows" do
    report = %{
      "schema_contract" => "resource_projection_report.v1",
      "model" => "thin_selected_activity_resource_projection",
      "input_resource_summary_count" => 1,
      "activity_count" => 1,
      "projected_resources" => [
        %{
          "spacecraft_id" => "leo_1",
          "activity_count" => 1,
          "observation_count" => 0,
          "downlink_count" => 1,
          "estimated_storage_produced_mb" => 0.0,
          "estimated_downlink_mb" => 50.0,
          "projected_downlink_shortfall_mb" => 20.0,
          "resource_pressure_status" => "downlink_shortfall",
          "resource_pressure_types" => ["downlink_shortfall"],
          "first_resource_pressure_activity_id" => "dl_flattened",
          "first_resource_pressure_activity_type" => "downlink",
          "first_resource_pressure_kind" => "downlink_shortfall",
          "first_resource_pressure_starts_at_s" => 120.0,
          "first_resource_pressure_source_window_id" =>
            "window:leo_1:ground_station_access:equator_prime:2",
          "first_resource_pressure_source_window_type" => "ground_station_access",
          "first_resource_pressure_source_window" => %{
            "id" => "window:leo_1:ground_station_access:equator_prime:2",
            "type" => "ground_station_access",
            "ground_station_id" => "equator_prime"
          }
        }
      ],
      "warnings" => [],
      "assumptions" => %{"source" => "flattened.resource_projection"}
    }

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(report)

    package = OperatorReview.from_resource_projection_report(report)

    assert [
             %{
               "review_type" => "resource_projection_review",
               "resource_flow_count" => 0,
               "first_resource_pressure_activity_id" => "dl_flattened",
               "first_resource_pressure_activity_type" => "downlink",
               "first_resource_pressure_kind" => "downlink_shortfall",
               "first_resource_pressure_starts_at_s" => 120.0,
               "first_resource_pressure_source_window_id" =>
                 "window:leo_1:ground_station_access:equator_prime:2",
               "source_window_id" => "window:leo_1:ground_station_access:equator_prime:2",
               "source_window_type" => "ground_station_access",
               "reason" => "review leo_1 resource pressure at dl_flattened: downlink_shortfall"
             }
           ] = package["rows"]

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
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
