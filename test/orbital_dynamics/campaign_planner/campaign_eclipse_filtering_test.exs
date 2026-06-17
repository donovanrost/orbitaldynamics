defmodule OrbitalDynamics.CampaignPlanner.CampaignEclipseFilteringTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{
    CadenceImport,
    CampaignPlanner,
    Epoch,
    OperatorReview,
    ResultSet,
    Schema,
    Timeline
  }

  test "eclipse filtering only compares windows within the candidate scenario" do
    result_set =
      ResultSet.new!(%{
        study_id: :campaign,
        trajectory_results: [],
        event_results: [
          %{
            scenario_id: :sunlit,
            event_type: :target_visibility,
            events: [
              %{
                type: :target_visibility,
                starts_at: Epoch.new!(0.0, :tdb),
                ends_at: Epoch.new!(10.0, :tdb),
                metadata: %{
                  target_id: :target_a,
                  target_priority: 2.0,
                  max_elevation_deg: 60.0,
                  minimum_elevation_deg: 10.0,
                  event_timing_policy: :sampled_state_linear_boundary,
                  event_detector: :target_visibility,
                  event_time_tolerance_s: 60.0,
                  max_sample_step_s: 60.0,
                  confidence: :bounded_by_sample_cadence
                }
              }
            ],
            source: %{target_id: :target_a}
          },
          %{
            scenario_id: :shadowed,
            event_type: :eclipse,
            events: [
              %{
                type: :eclipse,
                starts_at: Epoch.new!(0.0, :tdb),
                ends_at: Epoch.new!(10.0, :tdb),
                metadata: %{}
              }
            ],
            source: %{shadow_model: :cylindrical_central_body_shadow}
          }
        ],
        errors: [],
        assumptions: %{},
        metadata: %{}
      })

    campaign = %{
      "targets" => [%{"id" => "target_a", "priority" => 2.0}],
      "constraints" => %{"avoid_eclipse" => true},
      "scoring_policy" => %{"target_value_weight" => 1.0},
      "resource_summaries" => [
        %{
          "schema_contract" => "resource_summary.v1",
          "spacecraft_id" => "sunlit",
          "storage_capacity_mb" => 100.0,
          "storage_used_mb" => 10.0,
          "downlink_capacity_mb" => 50.0,
          "downlink_margin" => 0.8
        }
      ]
    }

    artifact = CampaignPlanner.build(result_set, campaign: campaign)

    assert [candidate] = artifact["candidate_activities"]
    assert candidate["scenario_id"] == "sunlit"
    assert candidate["type"] == "observe"
    assert candidate["eclipse_overlap_s"] == 0.0
    assert candidate["eclipse_overlap_fraction"] == 0.0
    assert candidate["lighting_condition"] == "sunlit"
    assert candidate["lighting_condition_detail"] == "sunlit"
    assert candidate["lighting_condition_model"] == "sampled_eclipse_overlap_tag"
    assert candidate["lighting_detail_model"] == "sampled_eclipse_overlap_fraction_tag"
    assert candidate["source_window_id"] == "window:sunlit:target_visibility:target_a:1"
    assert candidate["source_window"]["id"] == "window:sunlit:target_visibility:target_a:1"
    assert candidate["source_window"]["event_timing_policy"] == "sampled_state_linear_boundary"
    assert candidate["source_window"]["event_time_tolerance_s"] == 60.0

    assert %{
             "schema_contract" => "contact_filter_report.v1",
             "input_candidate_count" => 1,
             "kept_candidate_count" => 1,
             "suppressed_candidate_count" => 0,
             "suppressed_candidates" => []
           } = artifact["contact_filter_report"]

    assert [
             %{
               "target_id" => "target_a",
               "candidate_activity_count" => 1,
               "selected_activity_count" => 1,
               "selected_activity_ids" => [selected_id],
               "status" => "selected"
             }
           ] = artifact["target_commitments"]

    assert selected_id == candidate["id"]

    assert %{
             "schema_contract" => "objective_satisfaction_report.v1",
             "model" => "campaign_v1_selected_activity_objective_summary",
             "model_limits" => objective_model_limits,
             "objective_count" => 3,
             "rows" => objective_rows
           } = artifact["objective_satisfaction_report"]

    assert "selected_activity_summary_only" in objective_model_limits
    assert "planned_not_executed" in objective_model_limits

    assert %{
             "objective" => "target_coverage",
             "status" => "met",
             "required_count" => 1,
             "candidate_count" => 1,
             "selected_count" => 1,
             "satisfied_count" => 1,
             "selected_target_ids" => ["target_a"]
           } = Enum.find(objective_rows, &(&1["objective"] == "target_coverage"))

    assert %{
             "objective" => "downlink_completion",
             "status" => "no_requirement",
             "candidate_count" => 0,
             "selected_count" => 0
           } = Enum.find(objective_rows, &(&1["objective"] == "downlink_completion"))

    assert {:ok, %{"schema_contract" => "objective_satisfaction_report.v1"}} =
             Schema.validate_artifact(artifact["objective_satisfaction_report"])

    assert %{
             "schema_contract" => "resource_projection_report.v1",
             "model" => "thin_campaign_selected_activity_resource_projection",
             "input_resource_summary_count" => 1,
             "activity_count" => 1,
             "projected_resources" => [
               %{
                 "spacecraft_id" => "sunlit",
                 "activity_count" => 1,
                 "observation_count" => 1,
                 "downlink_count" => 0,
                 "starting_storage_used_mb" => 10.0,
                 "projected_storage_used_mb" => 10.0,
                 "projected_storage_margin" => projected_storage_margin,
                 "projected_downlink_margin" => 1.0
               }
             ],
             "assumptions" => %{"source" => "campaign.resource_summaries"}
           } = artifact["resource_projection_report"]

    assert_in_delta projected_storage_margin, 0.9, 1.0e-12

    assert {:ok, %{"schema_contract" => "resource_projection_report.v1"}} =
             Schema.validate_artifact(artifact["resource_projection_report"])

    assert %{
             "schema_contract" => "resource_projection_flow_summary.v1",
             "model" => "artifact_only_selected_activity_resource_flow_summary",
             "source" => "campaign.resource_summaries",
             "activity_count" => 1,
             "valid_activity_count" => 1,
             "projected_resource_count" => 1,
             "flow_row_count" => 1,
             "resource_flow_status" => "clear",
             "resource_pressure_status" => "clear",
             "resource_pressure_count" => 0,
             "projected_resources" => [
               %{
                 "spacecraft_id" => "sunlit",
                 "activity_count" => 1,
                 "projected_storage_remaining_mb" => 90.0,
                 "projected_downlink_remaining_mb" => 50.0
               }
             ],
             "activity_resource_flow" => [
               %{
                 "activity_id" => ^selected_id,
                 "activity_type" => "observe",
                 "storage_used_after_mb" => 10.0,
                 "downlink_used_after_mb" => +0.0
               }
             ],
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_schedule_mutation",
               "subsystem_simulation" => "not_performed"
             }
           } = artifact["resource_projection_flow_summary"]

    assert {:ok, %{"schema_contract" => "resource_projection_flow_summary.v1"}} =
             Schema.validate_artifact(artifact["resource_projection_flow_summary"])

    assert [
             %{
               "schema_contract" => "timeline_activity_precondition_summary.v1",
               "model" => "artifact_only_timeline_activity_precondition_summary",
               "source" => "campaign_plan.activities",
               "validation_level" => "artifact_contract",
               "activity_id" => ^selected_id,
               "activity_type" => "observe",
               "precondition_status" => "clear",
               "blocked_precondition_count" => 0,
               "review_precondition_count" => 0,
               "preconditions" => [],
               "assumptions" => %{
                 "execution_boundary" => "artifact_only_no_schedule_mutation",
                 "operator_authority" => "not_granted_by_precondition_summary",
                 "resource_authority" => "not_reserved_by_precondition_summary"
               }
             } = activity_precondition_summary
           ] = artifact["timeline_activity_precondition_summaries"]

    assert {:ok, %{"schema_contract" => "timeline_activity_precondition_summary.v1"}} =
             Schema.validate_artifact(activity_precondition_summary)

    assert %{
             "schema_contract" => "timeline_integrity_report.v1",
             "model" => "artifact_only_timeline_integrity_summary",
             "source" => "campaign_plan.activities",
             "activity_count" => 1,
             "valid_activity_count" => 1,
             "invalid_activity_input_count" => 0,
             "timeline_integrity_status" => "clear",
             "timeline_integrity_review_count" => 0,
             "timeline_integrity_issue_count" => 0,
             "rows" => [],
             "assumptions" => %{
               "execution_boundary" => "artifact_only_no_schedule_mutation",
               "missing_dependency_validation" => "disabled"
             }
           } = artifact["timeline_integrity_report"]

    assert {:ok, %{"schema_contract" => "timeline_integrity_report.v1"}} =
             Schema.validate_artifact(artifact["timeline_integrity_report"])

    assert %{
             "resource_projection_review_count" => 2,
             "timeline_activity_precondition_review_count" => 1
           } = artifact["operator_review_package"]

    assert %{
             "review_type" => "resource_projection_review",
             "source" => "campaign_plan.resource_projection_report.projected_resources",
             "spacecraft_id" => "sunlit",
             "activity_count" => 1,
             "observation_count" => 1,
             "downlink_count" => 0,
             "projected_storage_margin" => ^projected_storage_margin,
             "projected_downlink_margin" => 1.0,
             "required_operator_action" => "review_resource_projection",
             "source_resource_projection" => %{"spacecraft_id" => "sunlit"}
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "resource_projection_review")
             )

    assert %{
             "review_type" => "resource_projection_review",
             "source" => "campaign_plan.resource_projection_flow_summary.projected_resources",
             "spacecraft_id" => "sunlit",
             "resource_flow_count" => 1,
             "source_resource_projection_flow_summary" => %{
               "schema_contract" => "resource_projection_flow_summary.v1",
               "source" => "campaign.resource_summaries",
               "resource_flow_status" => "clear"
             },
             "source_resource_projection" => %{"spacecraft_id" => "sunlit"}
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] ==
                   "campaign_plan.resource_projection_flow_summary.projected_resources")
             )

    assert %{
             "review_type" => "timeline_activity_precondition_review",
             "source" => "campaign_plan.timeline_activity_precondition_summaries[0].summary",
             "activity_id" => ^selected_id,
             "precondition_status" => "clear",
             "required_operator_action" => "record_activity_precondition",
             "approval_status" => "not_required",
             "source_timeline_activity_precondition_summary" => %{
               "schema_contract" => "timeline_activity_precondition_summary.v1",
               "source" => "campaign_plan.activities"
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] ==
                   "campaign_plan.timeline_activity_precondition_summaries[0].summary")
             )

    assert %{
             "import_action" => "review_resource_projection",
             "source_review_type" => "resource_projection_review",
             "spacecraft_id" => "sunlit",
             "activity_count" => 1,
             "observation_count" => 1,
             "projected_storage_margin" => ^projected_storage_margin,
             "projected_downlink_margin" => 1.0,
             "source_resource_projection" => %{"spacecraft_id" => "sunlit"}
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["source_review_type"] == "resource_projection_review")
             )

    assert %{
             "import_action" => "review_resource_projection",
             "source_review_type" => "resource_projection_review",
             "spacecraft_id" => "sunlit",
             "resource_flow_count" => 1,
             "source_resource_projection_flow_summary" => %{
               "schema_contract" => "resource_projection_flow_summary.v1",
               "source" => "campaign.resource_summaries",
               "resource_flow_status" => "clear"
             }
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(get_in(&1, ["source_review_row", "source"]) ==
                   "campaign_plan.resource_projection_flow_summary.projected_resources")
             )

    assert %{
             "import_action" => "review_timeline_precondition",
             "source_review_type" => "timeline_activity_precondition_review",
             "activity_id" => ^selected_id,
             "precondition_status" => "clear",
             "source_timeline_activity_precondition_summary" => %{
               "schema_contract" => "timeline_activity_precondition_summary.v1",
               "source" => "campaign_plan.activities"
             }
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(get_in(&1, ["source_review_row", "source"]) ==
                   "campaign_plan.timeline_activity_precondition_summaries[0].summary")
             )

    integrity_issue_report =
      Timeline.integrity_report([
        %{
          id: :health_gate,
          type: :health_check,
          starts_at_s: 0.0,
          ends_at_s: 15.0,
          ground_station_id: :dss_14,
          direction: :command
        },
        %{
          id: :cmd_main,
          type: :command,
          starts_at_s: 10.0,
          ends_at_s: 20.0,
          ground_station_id: :dss_14,
          direction: :command,
          dependencies: [:health_gate, :missing_gate],
          exclusive_with: [:dl_conflict]
        },
        %{
          id: :dl_conflict,
          type: :downlink,
          starts_at_s: 12.0,
          ends_at_s: 22.0,
          ground_station_id: :dss_14,
          direction: :downlink
        }
      ])

    integrity_issue_artifact = %{
      "plan_id" => "campaign:timeline_integrity_review",
      "timeline_integrity_report" => integrity_issue_report
    }

    integrity_issue_review = OperatorReview.from_campaign_artifact(integrity_issue_artifact)

    assert %{
             "review_type" => "timeline_integrity_review",
             "source" => "campaign_plan.timeline_integrity_report.rows",
             "activity_id" => "cmd_main",
             "timeline_integrity_status" => "review_required",
             "required_operator_action" => "review_timeline_integrity",
             "source_timeline_integrity" => %{
               "activity_id" => "cmd_main",
               "timeline_integrity_status" => "review_required"
             }
           } =
             Enum.find(
               integrity_issue_review["rows"],
               &(&1["review_type"] == "timeline_integrity_review")
             )

    integrity_issue_import = CadenceImport.from_campaign_artifact(integrity_issue_artifact)

    assert %{
             "import_action" => "review_timeline_integrity",
             "source_review_type" => "timeline_integrity_review",
             "activity_id" => "cmd_main",
             "timeline_integrity_status" => "review_required",
             "source_timeline_integrity" => %{
               "activity_id" => "cmd_main",
               "timeline_integrity_status" => "review_required"
             }
           } =
             Enum.find(
               integrity_issue_import["rows"],
               &(&1["source_review_type"] == "timeline_integrity_review")
             )

    blocked_precondition_summary =
      Timeline.activity_precondition_summary(%{
        id: :blocked_payload_observe,
        type: :observe,
        payload_available: false
      })

    blocked_precondition_artifact = %{
      "plan_id" => "campaign:blocked_preconditions",
      "timeline_activity_precondition_summaries" => [blocked_precondition_summary]
    }

    blocked_precondition_review =
      OperatorReview.from_campaign_artifact(blocked_precondition_artifact)

    assert %{
             "review_type" => "timeline_activity_precondition_review",
             "source" => "campaign_plan.timeline_activity_precondition_summaries[0].summary",
             "activity_id" => "blocked_payload_observe",
             "precondition_status" => "blocked",
             "required_operator_action" => "review_blocked_activity_precondition",
             "source_timeline_activity_precondition_summary" => %{
               "schema_contract" => "timeline_activity_precondition_summary.v1",
               "precondition_status" => "blocked"
             }
           } =
             Enum.find(
               blocked_precondition_review["rows"],
               &(&1["review_type"] == "timeline_activity_precondition_review")
             )

    blocked_precondition_import =
      CadenceImport.from_campaign_artifact(blocked_precondition_artifact)

    assert %{
             "import_action" => "review_timeline_precondition",
             "source_review_type" => "timeline_activity_precondition_review",
             "activity_id" => "blocked_payload_observe",
             "precondition_status" => "blocked",
             "source_timeline_activity_precondition_summary" => %{
               "schema_contract" => "timeline_activity_precondition_summary.v1",
               "precondition_status" => "blocked"
             }
           } =
             Enum.find(
               blocked_precondition_import["rows"],
               &(&1["source_review_type"] == "timeline_activity_precondition_review")
             )

    assert %{
             "schema_contract" => "operational_readiness_report.v1",
             "source_artifact_type" => "campaign_plan.v1",
             "source_artifact_id" => source_artifact_id,
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "status" => "review_required",
             "evidence" => readiness_evidence
           } = artifact["operational_readiness_report"]

    assert source_artifact_id == artifact["plan_id"]
    assert readiness_evidence["review_type_counts"]["resource_projection_review"] == 2
    assert readiness_evidence["review_type_counts"]["timeline_activity_precondition_review"] == 1
    assert readiness_evidence["import_action_counts"]["review_resource_projection"] == 2
    assert readiness_evidence["import_action_counts"]["review_timeline_precondition"] == 1

    assert {:ok, %{"schema_contract" => "operational_readiness_report.v1"}} =
             Schema.validate_artifact(artifact["operational_readiness_report"])

    assert %{
             "schema_contract" => "quality_gate_report.v1",
             "source_artifact_type" => "campaign_plan.v1",
             "source_artifact_id" => ^source_artifact_id,
             "source_readiness_report_id" => source_readiness_report_id,
             "readiness_level" => "operator_review",
             "import_classification" => "review_only",
             "status" => "review_required",
             "handoff_only" => true,
             "execution_allowed" => false,
             "cadence_write_allowed" => false,
             "operator_authority_granted" => false,
             "review_required_gate_ids" => review_required_gate_ids
           } = artifact["quality_gate_report"]

    assert source_readiness_report_id == artifact["operational_readiness_report"]["report_id"]
    assert "operator_review" in review_required_gate_ids
    assert "cadence_import" in review_required_gate_ids

    assert {:ok, %{"schema_contract" => "quality_gate_report.v1"}} =
             Schema.validate_artifact(artifact["quality_gate_report"])

    assert %{
             "schema_contract" => "operational_timeline_report.v1",
             "model" => "selected_activity_operational_context_summary",
             "activity_count" => 1,
             "row_count" => 1,
             "contact_count" => 0,
             "command_count" => 0,
             "locked_count" => 0,
             "approved_count" => 0,
             "executed_count" => 0,
             "source_window_lineage_count" => 1,
             "rows" => [
               %{
                 "activity_id" => ^selected_id,
                 "activity_type" => "observe",
                 "status" => "planned",
                 "approval_status" => "not_evaluated",
                 "locked" => false,
                 "target_id" => "target_a",
                 "has_source_window" => true,
                 "has_cadence_import" => true,
                 "timeline_identity" => %{
                   "activity_id" => ^selected_id,
                   "activity_type" => "observe",
                   "scenario_id" => "sunlit",
                   "subject_id" => "target_a"
                 }
               }
             ]
           } = artifact["operational_timeline_report"]

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(artifact["operational_timeline_report"])

    assert [
             %{
               "score_terms" => %{
                 "activity_score" => 20.0,
                 "target_value" => 20.0,
                 "contact_value" => contact_value,
                 "selected_observation_count" => 1,
                 "selected_contact_count" => 0
               }
             }
           ] = artifact["ranked_timelines"]

    assert contact_value == 0.0

    assert %{
             "schema_contract" => "objective_tradeoff_report.v1",
             "model" => "ranked_timeline_score_term_tradeoffs",
             "ranking_count" => 1,
             "tradeoffs" => [
               %{
                 "rank" => 1,
                 "scenario_id" => "sunlit",
                 "score" => 20.0,
                 "score_delta_from_selected" => campaign_delta,
                 "activity_ids" => [^selected_id],
                 "score_terms" => %{"activity_score" => 20.0}
               }
             ]
           } = artifact["objective_tradeoff_report"]

    assert campaign_delta == 0.0
    assert "target_value" in artifact["objective_tradeoff_report"]["score_term_keys"]

    assert %{
             "schema_contract" => "optimizer_contract.v1",
             "optimizer" => "per_spacecraft_greedy_non_overlapping",
             "candidate_count" => 1,
             "ranked_timeline_count" => 1,
             "selected_activity_count" => 1,
             "selected_activity_ids" => [^selected_id],
             "ranked_scenario_ids" => ["sunlit"],
             "preserved_lineage_fields" => preserved_lineage_fields,
             "assumptions" => %{"external_solver" => false}
           } = artifact["optimizer_contract"]

    assert "source_window" in preserved_lineage_fields

    assert {:ok, %{"schema_contract" => "optimizer_contract.v1"}} =
             Schema.validate_artifact(artifact["optimizer_contract"])

    assert %{
             "schema_contract" => "constraint_report.v1",
             "model" => "campaign_planner_local_constraint_summary",
             "constraint_count" => 1,
             "row_count" => 1,
             "status" => "pass",
             "rows" => [constraint_row]
           } = artifact["constraint_report"]

    assert %{
             "constraint_id" => "campaign:avoid_eclipse",
             "scenario_id" => "sunlit",
             "metric" => "eclipse_overlap_s",
             "operator" => "==",
             "status" => "pass",
             "activity_id" => ^selected_id
           } = constraint_row

    assert constraint_row["threshold"] == 0.0
    assert constraint_row["value"] == 0.0
    assert constraint_row["violation_severity"] == "fail"

    assert {:ok, %{"schema_contract" => "constraint_report.v1"}} =
             Schema.validate_artifact(artifact["constraint_report"])

    assert %{
             "schema_contract" => "score_term_report.v1",
             "model" => "ranked_timeline_score_terms",
             "row_count" => 7,
             "rows" => score_term_rows
           } = artifact["score_term_report"]

    assert %{
             "rank" => 1,
             "scenario_id" => "sunlit",
             "term_key" => "activity_score",
             "value" => 20.0,
             "timeline_score" => 20.0,
             "selected" => true
           } = Enum.find(score_term_rows, &(&1["term_key"] == "activity_score"))

    assert %{
             "score_term_review_count" => 7,
             "objective_tradeoff_review_count" => 1
           } = artifact["operator_review_package"]

    assert %{
             "review_type" => "score_term_review",
             "source" => "campaign_plan.score_term_report.rows",
             "scenario_id" => "sunlit",
             "term_key" => "activity_score",
             "value" => 20.0,
             "timeline_score" => 20.0,
             "selected" => true,
             "source_score_term" => %{"term_key" => "activity_score"}
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "score_term_review" and
                   &1["term_key"] == "activity_score")
             )

    assert %{
             "review_type" => "objective_tradeoff_review",
             "source" => "campaign_plan.objective_tradeoff_report.tradeoffs",
             "scenario_id" => "sunlit",
             "score" => 20.0,
             "score_delta_from_selected" => review_score_delta,
             "activity_ids" => [^selected_id],
             "source_objective_tradeoff" => %{"scenario_id" => "sunlit"}
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "objective_tradeoff_review")
             )

    assert review_score_delta == 0.0

    assert %{
             "import_action" => "review_score_term",
             "source_review_type" => "score_term_review",
             "scenario_id" => "sunlit",
             "term_key" => "activity_score",
             "value" => 20.0,
             "source_score_term" => %{"term_key" => "activity_score"}
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["source_review_type"] == "score_term_review" and
                   &1["term_key"] == "activity_score")
             )

    assert %{
             "import_action" => "review_objective_tradeoff",
             "source_review_type" => "objective_tradeoff_review",
             "scenario_id" => "sunlit",
             "score" => 20.0,
             "score_delta_from_selected" => import_score_delta,
             "activity_ids" => [^selected_id],
             "source_objective_tradeoff" => %{"scenario_id" => "sunlit"}
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["source_review_type"] == "objective_tradeoff_review")
             )

    assert import_score_delta == 0.0

    assert {:ok, %{"schema_contract" => "campaign_plan.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "campaign normalizes string false for eclipse filtering" do
    result_set =
      ResultSet.new!(%{
        study_id: :campaign,
        trajectory_results: [],
        event_results: [
          %{
            scenario_id: :leo_1,
            event_type: :target_visibility,
            events: [
              %{
                type: :target_visibility,
                starts_at: Epoch.new!(0.0, :tdb),
                ends_at: Epoch.new!(10.0, :tdb),
                metadata: %{
                  target_id: :target_a,
                  target_priority: 2.0,
                  max_elevation_deg: 60.0,
                  minimum_elevation_deg: 10.0
                }
              }
            ],
            source: %{target_id: :target_a}
          },
          %{
            scenario_id: :leo_1,
            event_type: :eclipse,
            events: [
              %{
                type: :eclipse,
                starts_at: Epoch.new!(0.0, :tdb),
                ends_at: Epoch.new!(10.0, :tdb),
                metadata: %{}
              }
            ],
            source: %{shadow_model: :cylindrical_central_body_shadow}
          }
        ],
        errors: [],
        assumptions: %{},
        metadata: %{}
      })

    artifact =
      CampaignPlanner.build(result_set,
        campaign: %{
          "targets" => [%{"id" => "target_a", "priority" => 2.0}],
          "constraints" => %{"avoid_eclipse" => "false"},
          "scoring_policy" => %{"target_value_weight" => 1.0}
        }
      )

    assert [candidate] = artifact["candidate_activities"]
    assert candidate["scenario_id"] == "leo_1"
    assert candidate["eclipse_overlap_s"] == 10.0
    assert candidate["lighting_condition"] == "eclipsed"

    assert {:ok, %{"schema_contract" => "campaign_plan.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
