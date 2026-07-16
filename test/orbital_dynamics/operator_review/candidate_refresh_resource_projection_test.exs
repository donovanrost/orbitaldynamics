defmodule OrbitalDynamics.OperatorReview.CandidateRefreshResourceProjectionTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "candidate refresh source resource projection reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:resource_projection_review:001",
      "source_resource_projection_report" => %{
        "schema_contract" => "resource_projection_report.v1",
        "model" => "thin_campaign_selected_activity_resource_projection",
        "invalid_activity_inputs" => [
          %{
            "activity_id" => "bad_projection_activity",
            "type" => "observe",
            "scenario_id" => "leo_1",
            "spacecraft_id" => "sat_1",
            "invalid_activity_input_reason" => "missing_activity_duration",
            "approval_status" => "operator_review_required",
            "approval_requirements" => [
              %{
                "activity_id" => "bad_projection_activity",
                "activity_type" => "observe",
                "action" => "review_invalid_resource_projection_input",
                "requirement_type" => "resource_projection_input_validation"
              }
            ],
            "policy_decision" => %{
              "schema_contract" => "policy_decision.v1",
              "policy_bundle_id" => "resource_projection_input_guard_v1"
            },
            "source_activity" => %{"id" => "bad_projection_activity"}
          }
        ],
        "invalid_resource_summary_inputs" => [
          %{
            "resource_summary_id" => "resource_summary:stale_sat",
            "spacecraft_id" => "sat_1",
            "invalid_resource_summary_input_reason" => "missing_resource_summary_epoch",
            "approval_status" => "operator_review_required",
            "approval_requirements" => [
              %{
                "activity_id" => "resource_summary:stale_sat",
                "activity_type" => "resource_summary",
                "action" => "review_invalid_resource_projection_summary",
                "requirement_type" => "resource_projection_summary_validation"
              }
            ],
            "policy_decision" => %{
              "schema_contract" => "policy_decision.v1",
              "policy_bundle_id" => "resource_projection_summary_guard_v1"
            },
            "source_resource_summary" => %{"resource_summary_id" => "resource_summary:stale_sat"}
          }
        ],
        "projected_resources" => [
          %{
            "spacecraft_id" => "sat_1",
            "activity_count" => 1,
            "effective_activity_count" => 1,
            "ignored_activity_count" => 0,
            "ignored_activity_ids" => [],
            "observation_count" => 1,
            "downlink_count" => 0,
            "estimated_storage_produced_mb" => 20.0,
            "estimated_downlink_mb" => 4.0,
            "storage_limited_downlinked_mb" => 4.0,
            "unused_downlink_capacity_mb" => 0.0,
            "starting_storage_used_mb" => 950.0,
            "projected_storage_used_mb" => 1_020.0,
            "storage_capacity_mb" => 1_000.0,
            "starting_storage_margin" => 0.05,
            "projected_storage_margin" => -0.02,
            "downlink_capacity_mb" => 40.0,
            "starting_downlink_margin" => 0.2,
            "projected_downlink_margin" => 0.0,
            "activity_resource_flow" => [
              %{
                "activity_id" => "obs_overflow",
                "activity_type" => "observe",
                "starts_at_s" => 10.0,
                "storage_overflow_mb" => 12.0,
                "downlink_shortfall_mb" => 0.0,
                "battery_energy_consumed_wh" => 10.0,
                "battery_energy_generated_wh" => 0.0,
                "battery_energy_delta_wh" => 10.0,
                "battery_overuse_wh" => 2.0
              }
            ],
            "resource_source_quality" => "operator_supplied",
            "resource_trust_boundary_status" => "declared",
            "payload_available" => true,
            "antenna_available" => true,
            "approval_requirements" => [
              %{
                "schema_contract" => "approval_requirement.v1",
                "id" => "approval:resource_projection:sat_1:storage_overflow",
                "activity_id" => "resource_projection:sat_1",
                "activity_type" => "resource_projection",
                "action" => "review_resource_projection",
                "requirement_type" => "operator_review",
                "reason" => "storage_overflow 12.0 MB for sat_1"
              }
            ],
            "policy_decision" => %{
              "schema_contract" => "policy_decision.v1",
              "classification" => "blocked_by_policy",
              "policy_bundle_id" => "resource_projection_authority_v1",
              "escalations" => [
                %{
                  "rule_id" => "resource_pressure_block",
                  "required_authority" => "resource_authority",
                  "escalation_level" => "mission_planner",
                  "escalation_queue" => "resource_planning",
                  "escalation_role" => "resource_planner",
                  "sla_s" => 1200
                }
              ]
            }
          }
        ]
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:resource_projection_review:001",
             "review_count" => 3,
             "resource_projection_review_count" => 3
           } = package

    assert %{
             "review_type" => "resource_projection_review",
             "source" =>
               "candidate_refresh.source_resource_projection_report.invalid_activity_inputs",
             "subject_id" => "bad_projection_activity",
             "activity_id" => "bad_projection_activity",
             "required_operator_action" => "review_invalid_resource_projection_input",
             "invalid_activity_input" => true,
             "invalid_activity_input_reason" => "missing_activity_duration",
             "policy_bundle_id" => "resource_projection_input_guard_v1",
             "source_activity" => %{"id" => "bad_projection_activity"},
             "source_resource_projection" => %{"activity_id" => "bad_projection_activity"}
           } =
             Enum.find(
               package["rows"],
               &(&1["required_operator_action"] == "review_invalid_resource_projection_input")
             )

    assert %{
             "review_type" => "resource_projection_review",
             "source" =>
               "candidate_refresh.source_resource_projection_report.invalid_resource_summary_inputs",
             "subject_id" => "resource_summary:stale_sat",
             "spacecraft_id" => "sat_1",
             "required_operator_action" => "review_invalid_resource_projection_summary",
             "invalid_resource_summary_input" => true,
             "invalid_resource_summary_input_reason" => "missing_resource_summary_epoch",
             "policy_bundle_id" => "resource_projection_summary_guard_v1",
             "source_resource_summary" => %{
               "resource_summary_id" => "resource_summary:stale_sat"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["required_operator_action"] == "review_invalid_resource_projection_summary")
             )

    assert %{
             "review_type" => "resource_projection_review",
             "source" =>
               "candidate_refresh.source_resource_projection_report.projected_resources",
             "subject_id" => "sat_1",
             "spacecraft_id" => "sat_1",
             "required_operator_action" => "review_resource_projection",
             "activity_count" => 1,
             "projected_storage_margin" => -0.02,
             "resource_flow_count" => 1,
             "peak_storage_overflow_mb" => 12.0,
             "peak_battery_overuse_wh" => 2.0,
             "first_resource_pressure_activity_id" => "obs_overflow",
             "first_resource_pressure_kind" => "storage_overflow",
             "resource_source_quality" => "operator_supplied",
             "resource_trust_boundary_status" => "declared",
             "policy_bundle_id" => "resource_projection_authority_v1",
             "source_resource_projection" => %{
               "spacecraft_id" => "sat_1",
               "resource_trust_boundary_status" => "declared"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_resource_projection_report.projected_resources")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh source resource projection flow summaries become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:resource_projection_flow_review:001",
      "source_resource_projection_flow_summary" => [
        resource_projection_flow_summary()
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:resource_projection_flow_review:001",
             "review_count" => 1,
             "resource_projection_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "resource_projection_review",
               "source" =>
                 "candidate_refresh.source_resource_projection_flow_summary[0].projected_resources",
               "subject_id" => "leo_1",
               "spacecraft_id" => "leo_1",
               "required_operator_action" => "review_resource_projection",
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
               "source_resource_projection_flow_summary" => %{
                 "schema_contract" => "resource_projection_flow_summary.v1",
                 "resource_flow_status" => "review_required",
                 "source" => "flow_handoff"
               },
               "source_resource_projection" => %{
                 "spacecraft_id" => "leo_1",
                 "source_resource_projection_flow_summary" => %{
                   "schema_contract" => "resource_projection_flow_summary.v1"
                 }
               }
             } = row
           ] = package["rows"]

    assert length(row["source_resource_projection"]["activity_resource_flow"]) == 2

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact resource projection reports become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_resource_projection_review:001",
      "source_result_artifact" => %{
        "schema_contract" => "result_artifact.v1",
        "source_resource_projection_report" => %{
          "schema_contract" => "resource_projection_report.v1",
          "invalid_activity_inputs" => [
            %{
              "activity_id" => "bad_wrapped_projection_activity",
              "type" => "observe",
              "spacecraft_id" => "sat_1",
              "invalid_activity_input_reason" => "missing_activity_duration",
              "source_activity" => %{"id" => "bad_wrapped_projection_activity"}
            }
          ],
          "invalid_resource_summary_inputs" => [
            %{
              "resource_summary_id" => "resource_summary:wrapped_stale_sat",
              "spacecraft_id" => "sat_1",
              "invalid_resource_summary_input_reason" => "missing_resource_summary_epoch",
              "source_resource_summary" => %{
                "resource_summary_id" => "resource_summary:wrapped_stale_sat"
              }
            }
          ],
          "projected_resources" => [
            %{
              "spacecraft_id" => "sat_1",
              "activity_count" => 1,
              "effective_activity_count" => 1,
              "ignored_activity_count" => 0,
              "ignored_activity_ids" => [],
              "starting_storage_used_mb" => 950.0,
              "projected_storage_used_mb" => 1_020.0,
              "storage_capacity_mb" => 1_000.0,
              "projected_storage_margin" => -0.02,
              "activity_resource_flow" => [
                %{
                  "activity_id" => "obs_wrapped_overflow",
                  "activity_type" => "observe",
                  "storage_overflow_mb" => 12.0,
                  "downlink_shortfall_mb" => 0.0
                }
              ],
              "resource_trust_boundary_status" => "declared"
            }
          ]
        }
      }
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" => "candidate_refresh:wrapped_resource_projection_review:001",
             "review_count" => 3,
             "resource_projection_review_count" => 3
           } = package

    assert %{
             "review_type" => "resource_projection_review",
             "source" =>
               "candidate_refresh.source_result_artifact.source_resource_projection_report.invalid_activity_inputs",
             "subject_id" => "bad_wrapped_projection_activity",
             "source_resource_projection" => %{
               "activity_id" => "bad_wrapped_projection_activity"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["required_operator_action"] == "review_invalid_resource_projection_input")
             )

    assert %{
             "review_type" => "resource_projection_review",
             "source" =>
               "candidate_refresh.source_result_artifact.source_resource_projection_report.invalid_resource_summary_inputs",
             "subject_id" => "resource_summary:wrapped_stale_sat",
             "source_resource_summary" => %{
               "resource_summary_id" => "resource_summary:wrapped_stale_sat"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["required_operator_action"] ==
                   "review_invalid_resource_projection_summary")
             )

    assert %{
             "review_type" => "resource_projection_review",
             "source" =>
               "candidate_refresh.source_result_artifact.source_resource_projection_report.projected_resources",
             "subject_id" => "sat_1",
             "spacecraft_id" => "sat_1",
             "peak_storage_overflow_mb" => 12.0,
             "first_resource_pressure_activity_id" => "obs_wrapped_overflow",
             "source_resource_projection" => %{
               "spacecraft_id" => "sat_1",
               "resource_trust_boundary_status" => "declared"
             }
           } =
             Enum.find(
               package["rows"],
               &(&1["source"] ==
                   "candidate_refresh.source_result_artifact.source_resource_projection_report.projected_resources")
             )

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)
  end

  test "candidate refresh result artifact resource projection flow summaries become operator review rows" do
    artifact = %{
      "schema_contract" => "candidate_refresh.v1",
      "refresh_id" => "candidate_refresh:wrapped_resource_projection_flow_review:001",
      "result_artifact" => [
        %{
          "schema_contract" => "result_artifact.v1",
          "resource_projection_flow_summary" => resource_projection_flow_summary()
        }
      ]
    }

    package = OperatorReview.from_candidate_refresh_artifact(artifact)

    assert %{
             "source_artifact_type" => "candidate_refresh.v1",
             "source_artifact_id" =>
               "candidate_refresh:wrapped_resource_projection_flow_review:001",
             "review_count" => 1,
             "resource_projection_review_count" => 1
           } = package

    assert [
             %{
               "review_type" => "resource_projection_review",
               "source" =>
                 "candidate_refresh.result_artifact[0].resource_projection_flow_summary.projected_resources",
               "subject_id" => "leo_1",
               "resource_flow_count" => 2,
               "source_resource_projection_flow_summary" => %{
                 "schema_contract" => "resource_projection_flow_summary.v1",
                 "source" => "flow_handoff"
               }
             } = row
           ] = package["rows"]

    assert length(row["source_resource_projection"]["activity_resource_flow"]) == 2

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
