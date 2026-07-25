Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.RepairCandidateRefreshSourceReportsTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.Schema

  test "repair can use candidate_refresh.v1 candidates instead of stale prior candidates" do
    refreshed_candidate = refreshed_downlink("dl_refreshed", 500.0, 560.0)
    source_reports = passive_candidate_refresh_source_reports()

    source_link_capacity_report =
      "study_results/link_capacity_report_v1.json"
      |> File.read!()
      |> :json.decode()

    source_contact_allocation_provider_reservation_request_summary =
      "study_results/contact_allocation_provider_reservation_request_summary_v1.json"
      |> File.read!()
      |> :json.decode()

    source_contact_allocation_station_pressure_summary =
      "study_results/contact_allocation_station_pressure_summary_v1.json"
      |> File.read!()
      |> :json.decode()

    source_contact_allocation_reservation_conflict_summary =
      "study_results/contact_allocation_reservation_conflict_summary_v1.json"
      |> File.read!()
      |> :json.decode()

    source_station_reservation_report =
      "study_results/station_calendar_report_v1.json"
      |> File.read!()
      |> :json.decode()
      |> OrbitalDynamics.station_reservation_report()

    source_station_reservation_review_summary =
      "study_results/station_reservation_review_summary_v1.json"
      |> File.read!()
      |> :json.decode()

    source_station_reservation_hold_import_readiness_summary =
      "study_results/station_reservation_hold_import_readiness_summary_v1.json"
      |> File.read!()
      |> :json.decode()

    source_station_reservation_hold_summary =
      "study_results/station_reservation_hold_summary_v1.json"
      |> File.read!()
      |> :json.decode()

    source_station_calendar_precedence_summary =
      "study_results/station_calendar_precedence_summary_v1.json"
      |> File.read!()
      |> :json.decode()

    source_constraint_report =
      "study_results/constraint_report_v1.json"
      |> File.read!()
      |> :json.decode()

    source_objective_satisfaction_report =
      "study_results/objective_satisfaction_report_v1.json"
      |> File.read!()
      |> :json.decode()

    source_objective_tradeoff_report =
      "study_results/objective_tradeoff_report_v1.json"
      |> File.read!()
      |> :json.decode()

    source_score_term_report =
      "study_results/score_term_report_v1.json"
      |> File.read!()
      |> :json.decode()

    source_timeline_diff_report =
      "study_results/timeline_diff_report_v1.json"
      |> File.read!()
      |> :json.decode()

    source_schema_validation_report =
      "study_results/schema_validation_report_v1.json"
      |> File.read!()
      |> :json.decode()
      |> Map.merge(%{
        "status" => "fail",
        "artifact_path" => "study_results/bad_campaign.json",
        "error_count" => 1,
        "errors" => [
          %{"path" => "$.plan_id", "message" => "is required", "severity" => "error"}
        ],
        "remediation_count" => 1,
        "remediation" => [
          %{
            "path" => "$.plan_id",
            "category" => "missing_required_field",
            "action" => "Populate this required field",
            "source_message" => "is required"
          }
        ]
      })

    source_model_acceptance_report =
      OrbitalDynamics.validation_model_acceptance_report(
        ["orbit_data.simple_json", "event.access_windows", "propagator.two_body"],
        intended_use: :operational_import
      )

    source_validation_safety_case_summary =
      "study_results/validation_safety_case_summary_v1.json"
      |> File.read!()
      |> :json.decode()

    source_provider_counteroffer_report =
      OrbitalDynamics.provider_counteroffer_report(
        [
          %{
            id: :provider_counteroffer_window,
            provider_id: :ops_calendar,
            ground_station_id: :dss_14,
            starts_at_s: 130.0,
            ends_at_s: 170.0,
            counteroffer_id: :provider_offer_1,
            counteroffer_status: :proposed,
            counteroffer_reason_code: :provider_shifted_window,
            counteroffer_cost_delta: 125.5,
            counteroffer_lock_deadline_s: 150.0,
            counteroffer_starts_at_s: 160.0,
            counteroffer_ends_at_s: 210.0
          }
        ],
        source: :candidate_refresh_v2_handoff
      )

    source_provider_counteroffer_review_summary =
      "study_results/provider_counteroffer_review_summary_v1.json"
      |> File.read!()
      |> :json.decode()

    source_provider_counteroffer_plan_impact_summary =
      "study_results/provider_counteroffer_plan_impact_summary_v1.json"
      |> File.read!()
      |> :json.decode()

    source_provider_counteroffer_import_readiness_summary =
      "study_results/provider_counteroffer_import_readiness_summary_v1.json"
      |> File.read!()
      |> :json.decode()

    source_operational_import_eligibility_summary =
      "study_results/operational_import_eligibility_summary_v1.json"
      |> File.read!()
      |> :json.decode()

    source_operational_readiness_gate_summary =
      "study_results/operational_readiness_gate_summary_v1.json"
      |> File.read!()
      |> :json.decode()

    source_operational_execution_boundary_summary =
      "study_results/operational_execution_boundary_summary_v1.json"
      |> File.read!()
      |> :json.decode()

    source_operational_quality_gate_summary =
      "study_results/operational_quality_gate_summary_v1.json"
      |> File.read!()
      |> :json.decode()

    source_operational_quality_gate_unavailable_resource_summary =
      "study_results/operational_quality_gate_unavailable_resource_summary_v1.json"
      |> File.read!()
      |> :json.decode()
      |> Map.put("resource_blocking_dimension_counts", %{"antenna" => 1})
      |> Map.put("blocked_contact_ids_by_blocking_dimension", %{
        "antenna" => ["contact:resource_blocked"]
      })
      |> Map.put("blocked_contact_ids_by_spacecraft_id", %{
        "leo_1" => ["contact:resource_blocked"]
      })
      |> Map.put("blocked_contact_ids_by_status", %{
        "review_required" => ["contact:resource_blocked"]
      })

    source_operational_quality_gate_operator_training_summary =
      "study_results/operational_quality_gate_operator_training_summary_v1.json"
      |> File.read!()
      |> :json.decode()

    source_operational_quality_gate_schema_validation_summary =
      "study_results/operational_quality_gate_schema_validation_summary_v1.json"
      |> File.read!()
      |> :json.decode()

    source_operational_quality_gate_import_readiness_summary =
      "study_results/operational_quality_gate_import_readiness_summary_v1.json"
      |> File.read!()
      |> :json.decode()

    candidate_diff_report =
      candidate_diff_report()
      |> update_in(["invalidated_candidates", Access.at(0)], fn candidate ->
        candidate
        |> Map.put("semantic_change_reasons", ["contact_window_shifted"])
        |> Map.put("candidate_diff_changed_fields", ["starts_at_s", "ends_at_s"])
        |> Map.put("semantic_change_details", [
          %{
            "field" => "starts_at_s",
            "reason" => "contact_window_shifted",
            "prior_value" => 700.0,
            "refreshed_value" => 500.0
          }
        ])
      end)

    artifact =
      repair(
        %{
          "activities" => [downlink("dl_1", 100.0, 160.0)],
          "candidate_activities" => [downlink("dl_stale", 700.0, 760.0)]
        },
        realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
        current_epoch_s: 165.0,
        scoring_policy: %{"risk_weight" => "2.5"},
        candidate_refresh:
          [refreshed_candidate]
          |> candidate_refresh_artifact(
            contact_intents: [
              %{
                "schema_contract" => "contact_intent.v1",
                "id" => "contact_intent:dl_refreshed",
                "activity_id" => "dl_refreshed",
                "scenario_id" => "leo_1",
                "ground_station_id" => "equator_prime",
                "direction" => "downlink",
                "starts_at_s" => 500.0,
                "ends_at_s" => 560.0
              }
            ],
            resource_summaries: [
              %{
                "schema_contract" => "resource_summary.v1",
                "spacecraft_id" => "leo_1",
                "antenna_available" => true,
                "payload_available" => true
              }
            ],
            candidate_diff_report: candidate_diff_report,
            freshness_report: freshness_report("stale"),
            contact_filter_report: contact_filter_report(),
            contact_allocation_report: contact_allocation_report(),
            resource_filter_report: resource_filter_report(),
            refresh_budget_report: refresh_budget_report()
          )
          |> Map.put(
            "source_operational_readiness_report",
            source_reports["source_operational_readiness_report"]
          )
          |> Map.put(
            "source_contact_allocation_station_pressure_summary",
            [source_contact_allocation_station_pressure_summary]
          )
          |> Map.put(
            "source_contact_allocation_reservation_conflict_summary",
            [source_contact_allocation_reservation_conflict_summary]
          )
          |> Map.put(
            "source_contact_allocation_provider_reservation_request_summary",
            [source_contact_allocation_provider_reservation_request_summary]
          )
          |> Map.put(
            "source_operational_import_eligibility_summary",
            [source_operational_import_eligibility_summary]
          )
          |> Map.put(
            "source_operational_readiness_gate_summary",
            [source_operational_readiness_gate_summary]
          )
          |> Map.put(
            "source_operational_execution_boundary_summary",
            [source_operational_execution_boundary_summary]
          )
          |> Map.put(
            "source_operational_quality_gate_summary",
            [source_operational_quality_gate_summary]
          )
          |> Map.put(
            "source_operational_quality_gate_unavailable_resource_summary",
            [source_operational_quality_gate_unavailable_resource_summary]
          )
          |> Map.put(
            "source_operational_quality_gate_operator_training_summary",
            [source_operational_quality_gate_operator_training_summary]
          )
          |> Map.put(
            "source_operational_quality_gate_schema_validation_summary",
            [source_operational_quality_gate_schema_validation_summary]
          )
          |> Map.put(
            "source_operational_quality_gate_import_readiness_summary",
            [source_operational_quality_gate_import_readiness_summary]
          )
          |> Map.put("source_link_capacity_report", source_link_capacity_report)
          |> Map.put("source_station_reservation_report", source_station_reservation_report)
          |> Map.put(
            "source_station_reservation_review_summary",
            [source_station_reservation_review_summary]
          )
          |> Map.put(
            "source_station_reservation_hold_import_readiness_summary",
            [source_station_reservation_hold_import_readiness_summary]
          )
          |> Map.put(
            "source_station_reservation_hold_summary",
            [source_station_reservation_hold_summary]
          )
          |> Map.put(
            "source_station_calendar_precedence_summary",
            [source_station_calendar_precedence_summary]
          )
          |> Map.put("source_constraint_report", source_constraint_report)
          |> Map.put(
            "source_objective_satisfaction_report",
            source_objective_satisfaction_report
          )
          |> Map.put("source_objective_tradeoff_report", source_objective_tradeoff_report)
          |> Map.put("source_score_term_report", source_score_term_report)
          |> Map.put("source_timeline_diff_report", source_timeline_diff_report)
          |> Map.put("source_schema_validation_report", source_schema_validation_report)
          |> Map.put("source_model_acceptance_report", [source_model_acceptance_report])
          |> Map.put(
            "source_validation_safety_case_summary",
            [source_validation_safety_case_summary]
          )
          |> Map.put("source_provider_counteroffer_report", [source_provider_counteroffer_report])
          |> Map.put(
            "source_provider_counteroffer_review_summary",
            [source_provider_counteroffer_review_summary]
          )
          |> Map.put(
            "source_provider_counteroffer_plan_impact_summary",
            [source_provider_counteroffer_plan_impact_summary]
          )
          |> Map.put(
            "source_provider_counteroffer_import_readiness_summary",
            [source_provider_counteroffer_import_readiness_summary]
          )
          |> Map.put("source_quality_gate_report", passive_quality_gate_report())
          |> Map.put("operational_feedback", %{
            "station_throughput_factor" => %{"equator_prime" => 0.5}
          })
          |> put_in(["provenance", "operational_feedback"], %{
            "trust_boundary_status" => "declared",
            "trust_boundary" => "candidate_refresh_feedback",
            "input_keys" => ["station_throughput_factor"],
            "source_path" => "operational_feedback"
          })
      )

    assert [%{"id" => "dl_refreshed", "repair" => repair}] = artifact["activities"]
    assert repair["action"] == "moved"
    assert artifact["source_candidate_activities"] == [refreshed_candidate]

    assert %{
             "type" => "candidate_refresh.v1",
             "refresh_id" => "candidate_refresh:test:abc",
             "snapshot_id" => "ops-state-1",
             "operational_feedback_input_keys" => ["station_throughput_factor"],
             "operational_feedback_trust_boundary_status" => "declared",
             "operational_feedback_trust_boundary" => "candidate_refresh_feedback"
           } = artifact["assumptions"]["candidate_source"]

    assert artifact["provenance"]["candidate_source"]["type"] == "candidate_refresh.v1"
    assert artifact["repair_metadata"]["candidate_source"]["candidate_count"] == 1

    assert [%{"activity_id" => "dl_refreshed", "direction" => "downlink"}] =
             artifact["source_contact_intents"]

    assert [%{"spacecraft_id" => "leo_1", "antenna_available" => true}] =
             artifact["source_resource_summaries"]

    assert %{
             "schema_contract" => "candidate_diff_report.v1",
             "new_candidate_count" => 1
           } = artifact["source_candidate_diff_report"]

    assert artifact["score_terms"]["candidate_diff_pressure_penalty"] == -2.5

    assert artifact["score"] == artifact["score_terms"] |> Map.values() |> Enum.sum()

    assert [
             %{
               "term_key" => "candidate_diff_pressure_penalty",
               "value" => -2.5,
               "selected" => true
             }
           ] =
             Enum.filter(
               artifact["score_term_report"]["rows"],
               &(&1["term_key"] == "candidate_diff_pressure_penalty")
             )

    assert %{
             "candidate_diff_review_count" => 1
           } = artifact["operator_review_package"]

    assert %{
             "review_type" => "candidate_diff_review",
             "source" => "campaign_repair.source_candidate_diff_report.invalidated_candidates",
             "required_operator_action" => "review_candidate_diff",
             "invalidated_candidate_id" => "dl_stale",
             "invalidated_reason" => "not_present_in_refreshed_candidate_set",
             "semantic_change_reasons" => ["contact_window_shifted"],
             "candidate_diff_changed_fields" => ["ends_at_s", "starts_at_s"],
             "candidate_diff_changed_field_count" => 2,
             "source_candidate_diff" => %{
               "id" => "dl_stale",
               "invalidated_reason" => "not_present_in_refreshed_candidate_set",
               "semantic_change_reasons" => ["contact_window_shifted"],
               "candidate_diff_changed_fields" => ["starts_at_s", "ends_at_s"]
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "candidate_diff_review")
             )

    assert %{
             "import_action" => "review_candidate_diff",
             "source_review_type" => "candidate_diff_review",
             "invalidated_candidate_id" => "dl_stale",
             "invalidated_reason" => "not_present_in_refreshed_candidate_set",
             "semantic_change_reasons" => ["contact_window_shifted"],
             "candidate_diff_changed_fields" => ["ends_at_s", "starts_at_s"],
             "candidate_diff_changed_field_count" => 2,
             "refresh_gate" => "candidate_diff",
             "import_status" => "review_required_before_import",
             "source_candidate_diff" => %{
               "id" => "dl_stale",
               "semantic_change_reasons" => ["contact_window_shifted"]
             }
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["import_action"] == "review_candidate_diff")
             )

    assert %{
             "schema_contract" => "freshness_report.v1",
             "status" => "stale"
           } = artifact["source_freshness_report"]

    assert artifact["score_terms"]["refresh_freshness_pressure_penalty"] == -2.5

    assert [
             %{
               "term_key" => "refresh_freshness_pressure_penalty",
               "value" => -2.5,
               "selected" => true
             }
           ] =
             Enum.filter(
               artifact["score_term_report"]["rows"],
               &(&1["term_key"] == "refresh_freshness_pressure_penalty")
             )

    assert artifact["source_operational_readiness_report"]["schema_contract"] ==
             "operational_readiness_report.v1"

    assert artifact["source_operational_import_eligibility_summary"] ==
             source_operational_import_eligibility_summary

    assert artifact["source_operational_readiness_gate_summary"] ==
             source_operational_readiness_gate_summary

    assert artifact["source_operational_execution_boundary_summary"] ==
             source_operational_execution_boundary_summary

    assert artifact["source_operational_quality_gate_summary"] ==
             source_operational_quality_gate_summary

    assert artifact["source_operational_quality_gate_unavailable_resource_summary"] ==
             source_operational_quality_gate_unavailable_resource_summary

    assert artifact["source_operational_quality_gate_operator_training_summary"] ==
             source_operational_quality_gate_operator_training_summary

    assert artifact["source_operational_quality_gate_schema_validation_summary"] ==
             source_operational_quality_gate_schema_validation_summary

    assert artifact["source_operational_quality_gate_import_readiness_summary"] ==
             source_operational_quality_gate_import_readiness_summary

    assert artifact["source_quality_gate_report"]["schema_contract"] ==
             "quality_gate_report.v1"

    assert %{
             "freshness_review_count" => 1
           } = artifact["operator_review_package"]

    assert %{
             "review_type" => "freshness_review",
             "source" => "campaign_repair.source_freshness_report",
             "required_operator_action" => "review_refresh_freshness",
             "freshness_status" => "stale",
             "source_freshness_report" => %{"schema_contract" => "freshness_report.v1"}
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "freshness_review")
             )

    assert %{
             "import_action" => "review_refresh_freshness",
             "source_review_type" => "freshness_review",
             "freshness_status" => "stale",
             "import_status" => "review_required_before_import"
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["import_action"] == "review_refresh_freshness")
             )

    assert %{
             "operational_readiness_review_count" => 5,
             "quality_gate_review_count" => 8
           } = artifact["operator_review_package"]

    assert %{
             "review_type" => "operational_readiness_review",
             "source" => "campaign_repair.source_operational_readiness_report",
             "required_operator_action" => "review_operational_readiness",
             "source_operational_readiness_report" => %{
               "schema_contract" => "operational_readiness_report.v1",
               "report_id" => "operational_readiness:planned_activity.v1:passive_source"
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "operational_readiness_review")
             )

    assert %{
             "review_type" => "operational_readiness_review",
             "source" => "campaign_repair.source_operational_import_eligibility_summary",
             "subject_id" => "activity_1",
             "required_operator_action" => "record_operational_readiness_importable",
             "approval_status" => "auto_approvable",
             "cadence_import_status" => "present",
             "readiness_level" => "import_eligible",
             "import_classification" => "importable",
             "operational_readiness_status" => "passed",
             "gate_count" => 5,
             "passed_gate_count" => 5,
             "source_operational_readiness_report" => %{
               "schema_contract" => "operational_import_eligibility_summary.v1",
               "source_summary_schema_contract" => "operational_import_eligibility_summary.v1",
               "source_summary_model" => "artifact_only_import_eligibility_summary",
               "model_limits" => [
                 "operational_import_eligibility_summary_routes_only",
                 "operational_import_eligibility_summary_does_not_approve_or_import"
               ],
               "assumptions" => %{
                 "execution_boundary" => "artifact_only_no_cadence_write",
                 "operator_authority" => "not_granted_by_summary"
               }
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_operational_import_eligibility_summary")
             )

    assert %{
             "import_action" => "review_operational_readiness",
             "source_review_type" => "operational_readiness_review",
             "source_review_action" => "record_operational_readiness_importable",
             "source" => "campaign_repair.source_operational_import_eligibility_summary",
             "subject_id" => "activity_1",
             "import_status" => "ready_for_import",
             "has_cadence_import" => false,
             "approval_status" => "auto_approvable",
             "required_operator_action" => "record_operational_readiness_importable",
             "source_review_row" => %{
               "source_operational_readiness_report" => %{
                 "source_summary_schema_contract" => "operational_import_eligibility_summary.v1",
                 "assumptions" => %{
                   "operator_authority" => "not_granted_by_summary"
                 }
               }
             }
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_operational_import_eligibility_summary")
             )

    assert %{
             "review_type" => "operational_readiness_review",
             "source" => "campaign_repair.source_operational_readiness_gate_summary",
             "subject_id" => "activity_1",
             "required_operator_action" => "record_operational_readiness_importable",
             "approval_status" => "auto_approvable",
             "source_operational_readiness_report" => %{
               "schema_contract" => "operational_readiness_gate_summary.v1",
               "source_summary_schema_contract" => "operational_readiness_gate_summary.v1",
               "source_summary_model" => "artifact_only_operational_readiness_gate_summary",
               "gate_status_counts" => %{"passed" => 5},
               "gate_classification_counts" => %{"importable" => 5},
               "gate_ids_by_status" => %{
                 "passed" => [
                   "adapter_boundary",
                   "cadence_import",
                   "operational_mode",
                   "operator_review",
                   "source_contract"
                 ]
               },
               "non_passed_gate_count" => 0,
               "non_passed_gate_ids" => [],
               "model_limits" => [
                 "operational_readiness_gate_summary_routes_only",
                 "operational_readiness_gate_summary_does_not_approve_or_import"
               ]
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] == "campaign_repair.source_operational_readiness_gate_summary")
             )

    assert %{
             "import_action" => "review_operational_readiness",
             "source_review_type" => "operational_readiness_review",
             "source" => "campaign_repair.source_operational_readiness_gate_summary",
             "import_status" => "ready_for_import",
             "has_cadence_import" => false,
             "source_review_row" => %{
               "source_operational_readiness_report" => %{
                 "gate_ids_by_classification" => %{
                   "importable" => [
                     "adapter_boundary",
                     "cadence_import",
                     "operational_mode",
                     "operator_review",
                     "source_contract"
                   ]
                 },
                 "non_passed_gate_ids" => []
               }
             }
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["source"] == "campaign_repair.source_operational_readiness_gate_summary")
             )

    assert %{
             "review_type" => "operational_readiness_review",
             "source" => "campaign_repair.source_operational_execution_boundary_summary",
             "subject_id" => "activity_1",
             "required_operator_action" => "record_operational_readiness_importable",
             "approval_status" => "auto_approvable",
             "source_operational_readiness_report" => %{
               "schema_contract" => "operational_execution_boundary_summary.v1",
               "source_summary_schema_contract" => "operational_execution_boundary_summary.v1",
               "source_summary_model" => "artifact_only_operational_execution_boundary_summary",
               "import_eligible" => true,
               "handoff_only" => true,
               "execution_allowed" => false,
               "cadence_write_allowed" => false,
               "operator_authority_granted" => false,
               "execution_boundary" => "adapter_handoff_only",
               "operational_mode_gate" => %{
                 "id" => "operational_mode",
                 "status" => "passed",
                 "classification" => "importable"
               },
               "model_limits" => [
                 "operational_execution_boundary_summary_routes_only",
                 "operational_execution_boundary_summary_does_not_execute_or_import"
               ]
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_operational_execution_boundary_summary")
             )

    assert %{
             "import_action" => "review_operational_readiness",
             "source_review_type" => "operational_readiness_review",
             "source" => "campaign_repair.source_operational_execution_boundary_summary",
             "import_status" => "ready_for_import",
             "has_cadence_import" => false,
             "source_review_row" => %{
               "source_operational_readiness_report" => %{
                 "handoff_only" => true,
                 "execution_allowed" => false,
                 "cadence_write_allowed" => false,
                 "operator_authority_granted" => false,
                 "execution_boundary" => "adapter_handoff_only"
               }
             }
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_operational_execution_boundary_summary")
             )

    assert %{
             "review_type" => "quality_gate_review",
             "source" =>
               "campaign_repair.source_operational_quality_gate_operator_training_summary",
             "required_operator_action" => "review_quality_gate",
             "quality_gate_id" => "operator_training",
             "quality_gate_status" => "review_required",
             "quality_gate_classification" => "review_only",
             "operator_training_requirement_count" => 5,
             "operator_training_requirement_counts" => %{
               "certification" => 1,
               "operator_role" => 2,
               "qualification" => 1,
               "training" => 1
             },
             "operator_training_requirement_ids" => [
               "certification",
               "operator_role",
               "qualification",
               "training"
             ],
             "required_operator_roles" => ["contact_operator", "mission_director"],
             "required_training_ids" => ["contact_replan_drill"],
             "required_certification_ids" => ["cadence_import_cert"],
             "required_qualification_ids" => ["sat_ops_current"],
             "source_quality_gate_report" => %{
               "source_summary_schema_contract" =>
                 "operational_quality_gate_operator_training_summary.v1",
               "source_summary_model" => "artifact_only_quality_gate_operator_training_summary",
               "model_limits" => [
                 "quality_gate_operator_training_summary_routes_only",
                 "quality_gate_operator_training_summary_does_not_approve_or_import"
               ]
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_operational_quality_gate_operator_training_summary")
             )

    assert %{
             "import_action" => "review_quality_gate",
             "source_review_type" => "quality_gate_review",
             "source" =>
               "campaign_repair.source_operational_quality_gate_operator_training_summary",
             "import_status" => "review_required_before_import",
             "has_cadence_import" => false,
             "source_review_row" => %{
               "operator_training_requirement_count" => 5,
               "required_operator_roles" => ["contact_operator", "mission_director"],
               "required_training_ids" => ["contact_replan_drill"],
               "required_certification_ids" => ["cadence_import_cert"],
               "required_qualification_ids" => ["sat_ops_current"]
             }
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_operational_quality_gate_operator_training_summary")
             )

    assert %{
             "review_type" => "quality_gate_review",
             "source" =>
               "campaign_repair.source_operational_quality_gate_schema_validation_summary",
             "required_operator_action" => "review_blocked_quality_gate",
             "approval_status" => "blocked_by_policy",
             "quality_gate_id" => "cadence_import",
             "quality_gate_status" => "blocked",
             "quality_gate_classification" => "blocked",
             "schema_validation_pass_count" => 0,
             "schema_validation_fail_count" => 1,
             "schema_validation_error_count" => 1,
             "schema_validation_warning_count" => 0,
             "schema_validation_remediation_count" => 1,
             "schema_validation_status_counts" => %{"fail" => 1},
             "source_quality_gate_report" => %{
               "source_summary_schema_contract" =>
                 "operational_quality_gate_schema_validation_summary.v1",
               "source_summary_model" => "artifact_only_quality_gate_schema_validation_summary",
               "model_limits" => [
                 "quality_gate_schema_validation_summary_routes_only",
                 "quality_gate_schema_validation_summary_does_not_approve_or_import"
               ]
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_operational_quality_gate_schema_validation_summary")
             )

    assert %{
             "import_action" => "review_quality_gate",
             "source_review_type" => "quality_gate_review",
             "source" =>
               "campaign_repair.source_operational_quality_gate_schema_validation_summary",
             "import_status" => "review_required_before_import",
             "has_cadence_import" => false,
             "source_review_row" => %{
               "schema_validation_pass_count" => 0,
               "schema_validation_fail_count" => 1,
               "schema_validation_error_count" => 1,
               "schema_validation_remediation_count" => 1,
               "schema_validation_status_counts" => %{"fail" => 1}
             }
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_operational_quality_gate_schema_validation_summary")
             )

    assert %{
             "review_type" => "quality_gate_review",
             "source" =>
               "campaign_repair.source_operational_quality_gate_import_readiness_summary",
             "required_operator_action" => "review_quality_gate",
             "quality_gate_id" => "cadence_import",
             "quality_gate_status" => "review_required",
             "quality_gate_classification" => "review_only",
             "ready_for_import_count" => 1,
             "manifest_review_required_count" => 0,
             "blocked_import_count" => 0,
             "missing_import_count" => 0,
             "invalid_cadence_import_count" => 0,
             "current_freshness_count" => 0,
             "stale_freshness_count" => 1,
             "unknown_freshness_count" => 0,
             "freshness_status_counts" => %{"stale" => 1},
             "import_status_counts" => %{"ready_for_import" => 1},
             "cadence_import_status_counts" => %{"present" => 1},
             "source_quality_gate_report" => %{
               "source_summary_schema_contract" =>
                 "operational_quality_gate_import_readiness_summary.v1",
               "source_summary_model" => "artifact_only_quality_gate_import_readiness_summary",
               "model_limits" => [
                 "quality_gate_import_readiness_summary_routes_only",
                 "quality_gate_import_readiness_summary_does_not_approve_or_import"
               ]
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_operational_quality_gate_import_readiness_summary")
             )

    assert %{
             "import_action" => "review_quality_gate",
             "source_review_type" => "quality_gate_review",
             "source" =>
               "campaign_repair.source_operational_quality_gate_import_readiness_summary",
             "import_status" => "review_required_before_import",
             "has_cadence_import" => false,
             "source_review_row" => %{
               "ready_for_import_count" => 1,
               "stale_freshness_count" => 1,
               "freshness_status_counts" => %{"stale" => 1},
               "import_status_counts" => %{"ready_for_import" => 1},
               "cadence_import_status_counts" => %{"present" => 1}
             }
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_operational_quality_gate_import_readiness_summary")
             )

    assert %{
             "review_type" => "quality_gate_review",
             "source" =>
               "campaign_repair.source_operational_quality_gate_unavailable_resource_summary",
             "required_operator_action" => "review_quality_gate",
             "quality_gate_id" => "resource_availability",
             "quality_gate_status" => "review_required",
             "resource_availability_pressure_count" => 2,
             "resource_availability_reason_ids" => [
               "antenna_unavailable",
               "payload_unavailable"
             ],
             "resource_blocking_dimension_counts" => %{"antenna" => 1},
             "resource_blocked_contact_ids_by_blocking_dimension" => %{
               "antenna" => ["contact:resource_blocked"]
             },
             "resource_blocked_contact_ids_by_spacecraft_id" => %{
               "leo_1" => ["contact:resource_blocked"]
             },
             "source_quality_gate_report" => %{
               "source_summary_schema_contract" =>
                 "operational_quality_gate_unavailable_resource_summary.v1",
               "source_summary_model" =>
                 "artifact_only_quality_gate_unavailable_resource_summary",
               "model_limits" => [
                 "quality_gate_unavailable_resource_summary_routes_only",
                 "quality_gate_unavailable_resource_summary_does_not_approve_or_import"
               ]
             },
             "source_quality_gate_row" => %{
               "resource_blocked_contact_ids_by_status" => %{
                 "review_required" => ["contact:resource_blocked"]
               }
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_operational_quality_gate_unavailable_resource_summary")
             )

    assert %{
             "import_action" => "review_quality_gate",
             "source_review_type" => "quality_gate_review",
             "source" =>
               "campaign_repair.source_operational_quality_gate_unavailable_resource_summary",
             "import_status" => "review_required_before_import",
             "has_cadence_import" => false,
             "source_review_row" => %{
               "resource_blocked_contact_ids_by_blocking_dimension" => %{
                 "antenna" => ["contact:resource_blocked"]
               },
               "resource_blocked_contact_ids_by_spacecraft_id" => %{
                 "leo_1" => ["contact:resource_blocked"]
               }
             }
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_operational_quality_gate_unavailable_resource_summary")
             )

    assert %{
             "review_type" => "quality_gate_review",
             "source" => "campaign_repair.source_operational_quality_gate_summary.rows",
             "required_operator_action" => "review_quality_gate",
             "quality_gate_id" => "resource_availability",
             "quality_gate_status" => "review_required",
             "quality_gate_classification" => "review_only",
             "source_quality_gate_report" => %{
               "schema_contract" => "quality_gate_report.v1",
               "source_summary_schema_contract" => "operational_quality_gate_summary.v1",
               "source_summary_model" => "artifact_only_quality_gate_summary",
               "source_quality_gate_report_id" =>
                 "quality_gate:resource_projection_report.v1:resource_summaries",
               "non_passed_gate_count" => 3,
               "non_passed_gate_ids" => [
                 "cadence_import",
                 "operator_review",
                 "resource_availability"
               ],
               "non_passed_quality_gate_row_ids" => [
                 "quality_gate:resource_projection_report.v1:resource_summaries:cadence_import:6",
                 "quality_gate:resource_projection_report.v1:resource_summaries:operator_review:5",
                 "quality_gate:resource_projection_report.v1:resource_summaries:resource_availability:4"
               ],
               "model_limits" => [
                 "quality_gate_summary_derives_classification_from_gate_rows",
                 "quality_gate_summary_does_not_approve_or_import"
               ]
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_operational_quality_gate_summary.rows" and
                   &1["quality_gate_id"] == "resource_availability")
             )

    assert %{
             "import_action" => "review_quality_gate",
             "source_review_type" => "quality_gate_review",
             "source" => "campaign_repair.source_operational_quality_gate_summary.rows",
             "import_status" => "review_required_before_import",
             "has_cadence_import" => false,
             "source_review_row" => %{
               "source_quality_gate_report" => %{
                 "source_summary_schema_contract" => "operational_quality_gate_summary.v1",
                 "non_passed_gate_count" => 3
               }
             }
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_operational_quality_gate_summary.rows" and
                   &1["quality_gate_id"] == "resource_availability")
             )

    assert %{
             "review_type" => "quality_gate_review",
             "source" => "campaign_repair.source_quality_gate_report.rows",
             "required_operator_action" => "review_quality_gate",
             "quality_gate_id" => "operator_review",
             "source_quality_gate_report" => %{
               "schema_contract" => "quality_gate_report.v1",
               "report_id" => "quality_gate:planned_activity.v1:passive_source"
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] == "campaign_repair.source_quality_gate_report.rows")
             )

    assert %{
             "import_action" => "review_operational_readiness",
             "source_review_type" => "operational_readiness_review",
             "source" => "campaign_repair.source_operational_readiness_report",
             "source_operational_readiness_report" => %{
               "schema_contract" => "operational_readiness_report.v1"
             }
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["import_action"] == "review_operational_readiness")
             )

    assert %{
             "import_action" => "review_quality_gate",
             "source_review_type" => "quality_gate_review",
             "source" => "campaign_repair.source_quality_gate_report.rows",
             "source_quality_gate_report" => %{"schema_contract" => "quality_gate_report.v1"}
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["source"] == "campaign_repair.source_quality_gate_report.rows")
             )

    assert %{
             "schema_contract" => "contact_filter_report.v1",
             "suppressed_candidate_count" => 1
           } = artifact["source_contact_filter_report"]

    assert %{
             "schema_contract" => "contact_allocation_report.v1",
             "allocated_contact_count" => 1,
             "deferred_contact_count" => 1
           } = artifact["source_contact_allocation_report"]

    assert artifact["source_contact_allocation_provider_reservation_request_summary"] ==
             source_contact_allocation_provider_reservation_request_summary

    assert artifact["source_contact_allocation_station_pressure_summary"] ==
             source_contact_allocation_station_pressure_summary

    assert artifact["source_contact_allocation_reservation_conflict_summary"] ==
             source_contact_allocation_reservation_conflict_summary

    assert %{
             "schema_contract" => "contact_allocation_report.v1",
             "source" => "campaign_repair.activities",
             "allocated_contact_count" => 1,
             "rows" => [
               %{
                 "contact_id" => "dl_refreshed",
                 "allocation_status" => "allocated",
                 "allocation_reason" => "available"
               }
             ]
           } = artifact["contact_allocation_report"]

    assert artifact["source_link_capacity_report"] == source_link_capacity_report

    assert %{
             "review_type" => "link_capacity_review",
             "source" => "campaign_repair.source_link_capacity_report.rows",
             "subject_id" => "equator_prime",
             "contact_ids" => ["leo_1_downlink_equator_prime_1"],
             "capacity_adjusted_throughput_mb" => 172.71212086982393,
             "source_link_capacity" => %{
               "station_availability" => "reduced_capacity"
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] == "campaign_repair.source_link_capacity_report.rows")
             )

    assert %{
             "import_action" => "review_link_capacity",
             "source_review_type" => "link_capacity_review",
             "source" => "campaign_repair.source_link_capacity_report.rows",
             "ground_station_id" => "equator_prime",
             "contact_ids" => ["leo_1_downlink_equator_prime_1"],
             "import_status" => "review_required_before_import"
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["source"] == "campaign_repair.source_link_capacity_report.rows")
             )

    assert artifact["source_station_reservation_report"] ==
             source_station_reservation_report

    assert artifact["source_station_reservation_review_summary"] ==
             source_station_reservation_review_summary

    assert artifact["source_station_reservation_hold_import_readiness_summary"] ==
             source_station_reservation_hold_import_readiness_summary

    assert artifact["source_station_reservation_hold_summary"] ==
             source_station_reservation_hold_summary

    assert artifact["source_station_calendar_precedence_summary"] ==
             source_station_calendar_precedence_summary

    assert %{
             "review_type" => "station_reservation_review",
             "source" => "campaign_repair.source_station_reservation_report.affected_contacts",
             "contact_id" => "cmd_1",
             "ground_station_id" => "equator_prime",
             "station_reservation_id" => "provider_reservation_42",
             "station_reserved_by" => "cadence_ops",
             "station_reservation_status" => "confirmed",
             "source_station_reservation" => %{
               "contact_id" => "cmd_1",
               "station_reservation_id" => "provider_reservation_42"
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_station_reservation_report.affected_contacts")
             )

    assert %{
             "import_action" => "review_station_reservation",
             "source_review_type" => "station_reservation_review",
             "contact_id" => "cmd_1",
             "station_reservation_id" => "provider_reservation_42",
             "import_status" => "review_required_before_import",
             "source_review_row" => %{
               "source" => "campaign_repair.source_station_reservation_report.affected_contacts"
             }
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(get_in(&1, ["source_review_row", "source"]) ==
                   "campaign_repair.source_station_reservation_report.affected_contacts")
             )

    assert %{
             "review_type" => "station_calendar_review",
             "source" => "campaign_repair.source_station_calendar_precedence_summary",
             "subject_id" => "ops_calendar",
             "required_operator_action" => "review_station_calendar",
             "station_calendar_precedence_review_status" => "review_required",
             "station_calendar_precedence_affected_contact_count" => 1,
             "station_calendar_precedence_applied_availability_counts" => %{
               "unavailable" => 1
             },
             "station_calendar_precedence_overlap_availability_counts" => %{
               "reduced_capacity" => 1,
               "reserved" => 1,
               "unavailable" => 1
             },
             "station_calendar_precedence_reserved_under_higher_precedence_contact_ids" => [
               "dl_1"
             ],
             "station_calendar_precedence_model_limits" => [
               "declared_data_only",
               "no_network_calls",
               "no_provider_reservation",
               "no_schedule_mutation",
               "no_conflict_resolution"
             ],
             "source_station_calendar_precedence_summary" => %{
               "schema_contract" => "station_calendar_precedence_summary.v1",
               "source_summary_model" => "artifact_only_station_calendar_precedence_summary",
               "reserved_under_higher_precedence_reservation_ids_by_reserved_by" => %{
                 "ops_team_b" => ["reservation_42"]
               },
               "assumptions" => %{
                 "execution_boundary" => "artifact_only_no_provider_reservation",
                 "operator_authority" => "not_granted_by_summary"
               }
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_station_calendar_precedence_summary")
             )

    assert %{
             "import_action" => "review_station_calendar",
             "source_review_type" => "station_calendar_review",
             "import_status" => "review_required_before_import",
             "has_cadence_import" => false,
             "source_review_row" => %{
               "source" => "campaign_repair.source_station_calendar_precedence_summary",
               "station_calendar_precedence_review_status" => "review_required",
               "source_station_calendar_precedence_summary" => %{
                 "schema_contract" => "station_calendar_precedence_summary.v1",
                 "reserved_under_higher_precedence_contact_ids_by_reserved_by" => %{
                   "ops_team_b" => ["dl_1"]
                 }
               }
             }
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(get_in(&1, ["source_review_row", "source"]) ==
                   "campaign_repair.source_station_calendar_precedence_summary")
             )

    assert %{
             "review_type" => "station_reservation_review",
             "source" =>
               "campaign_repair.source_station_reservation_review_summary.review_rows.affected_contacts",
             "contact_id" => "dl_source_reserved",
             "station_reservation_id" => "reservation_expired",
             "station_reservation_expires_at_s" => 240.0,
             "source_station_reservation" => %{
               "source_station_reservation_summary" => %{
                 "reservation_count" => 3,
                 "affected_contact_reservation_count" => 1,
                 "provider_calendar_contention_group_count" => 2,
                 "reservation_review_status" => "review_required",
                 "reservation_expiration_count" => 2,
                 "earliest_reservation_expires_at_s" => 240.0,
                 "reservation_expiration_status_counts" => %{
                   "active" => 1,
                   "expired" => 1,
                   "missing" => 1
                 },
                 "review_reservation_ids" => [
                   "reservation_active",
                   "reservation_expired",
                   "reservation_missing"
                 ],
                 "model_limits" => [
                   "declared_data_only",
                   "no_network_calls",
                   "no_provider_reservation",
                   "no_schedule_mutation",
                   "no_conflict_resolution"
                 ]
               }
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_station_reservation_review_summary.review_rows.affected_contacts")
             )

    assert %{
             "review_type" => "station_reservation_review",
             "source" =>
               "campaign_repair.source_station_reservation_review_summary.review_rows.provider_calendar_contention_groups",
             "provider_calendar_contention_reservation_ids" => ["reservation_missing"],
             "provider_calendar_contention_reserved_by" => ["partner_calendar"],
             "required_operator_action" => "review_station_provider_contention"
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_station_reservation_review_summary.review_rows.provider_calendar_contention_groups" and
                   &1["provider_calendar_contention_reservation_ids"] == [
                     "reservation_missing"
                   ])
             )

    assert %{
             "import_action" => "review_station_reservation",
             "source_review_type" => "station_reservation_review",
             "contact_id" => "dl_source_reserved",
             "station_reservation_id" => "reservation_expired",
             "import_status" => "review_required_before_import",
             "has_cadence_import" => false,
             "source_review_row" => %{
               "source_station_reservation" => %{
                 "source_station_reservation_summary" => %{
                   "reservation_count" => 3,
                   "reservation_review_status" => "review_required",
                   "earliest_reservation_expires_at_s" => 240.0
                 }
               }
             }
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(get_in(&1, ["source_review_row", "source"]) ==
                   "campaign_repair.source_station_reservation_review_summary.review_rows.affected_contacts")
             )

    assert %{
             "review_type" => "station_reservation_review",
             "source" =>
               "campaign_repair.source_station_reservation_hold_import_readiness_summary.import_readiness_rows.affected_contacts",
             "contact_id" => "dl_source_reserved",
             "ground_station_id" => "equator_prime",
             "station_reservation_id" => "reservation_expired",
             "station_reservation_hold_import_status" => "review_required_before_import",
             "station_reservation_hold_import_readiness_status" => "review_required",
             "station_reservation_hold_import_execution_boundary" =>
               "artifact_only_no_provider_or_cadence_writes",
             "station_reservation_hold_provider_write" => "not_performed_by_summary",
             "station_reservation_hold_cadence_write" => "not_performed_by_summary",
             "station_reservation_hold_reservation_acceptance" => "not_performed_by_summary",
             "source_station_reservation_hold_import_readiness_summary" => %{
               "reservation_hold_count" => 2,
               "import_readiness_status" => "review_required",
               "model_limits" => [
                 "declared_data_only",
                 "no_network_calls",
                 "no_provider_reservation",
                 "no_schedule_mutation",
                 "no_conflict_resolution"
               ]
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_station_reservation_hold_import_readiness_summary.import_readiness_rows.affected_contacts")
             )

    assert %{
             "review_type" => "station_reservation_review",
             "source" =>
               "campaign_repair.source_station_reservation_hold_import_readiness_summary.import_readiness_rows.provider_calendar_contention_groups",
             "provider_calendar_contention_reservation_ids" => ["reservation_missing"],
             "provider_calendar_contention_reserved_by" => ["partner_calendar"],
             "required_operator_action" => "review_station_provider_contention"
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_station_reservation_hold_import_readiness_summary.import_readiness_rows.provider_calendar_contention_groups")
             )

    assert %{
             "import_action" => "review_station_reservation",
             "source_review_type" => "station_reservation_review",
             "contact_id" => "dl_source_reserved",
             "station_reservation_id" => "reservation_expired",
             "import_status" => "review_required_before_import",
             "has_cadence_import" => false,
             "station_reservation_hold_provider_write" => "not_performed_by_summary",
             "station_reservation_hold_cadence_write" => "not_performed_by_summary",
             "station_reservation_hold_reservation_acceptance" => "not_performed_by_summary"
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(get_in(&1, ["source_review_row", "source"]) ==
                   "campaign_repair.source_station_reservation_hold_import_readiness_summary.import_readiness_rows.affected_contacts")
             )

    assert %{
             "review_type" => "station_reservation_review",
             "source" =>
               "campaign_repair.source_station_reservation_hold_summary.review_rows.affected_contacts",
             "contact_id" => "dl_source_reserved",
             "station_reservation_id" => "reservation_expired",
             "station_reservation_expires_at_s" => 240.0,
             "station_reservation_hold_count" => 2,
             "station_reservation_hold_ids" => ["reservation_expired", "reservation_missing"],
             "source_station_reservation" => %{
               "source_station_reservation_summary" => %{
                 "reservation_hold_review_status" => "review_required",
                 "reservation_hold_expiration_count" => 1,
                 "earliest_reservation_hold_expires_at_s" => 240.0,
                 "model_limits" => [
                   "declared_data_only",
                   "no_network_calls",
                   "no_provider_reservation",
                   "no_schedule_mutation",
                   "no_conflict_resolution"
                 ]
               }
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_station_reservation_hold_summary.review_rows.affected_contacts")
             )

    assert %{
             "review_type" => "station_reservation_review",
             "source" =>
               "campaign_repair.source_station_reservation_hold_summary.review_rows.provider_calendar_contention_groups",
             "provider_calendar_contention_reservation_ids" => ["reservation_missing"],
             "provider_calendar_contention_reserved_by" => ["partner_calendar"],
             "required_operator_action" => "review_station_provider_contention"
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_station_reservation_hold_summary.review_rows.provider_calendar_contention_groups")
             )

    assert %{
             "import_action" => "review_station_reservation",
             "source_review_type" => "station_reservation_review",
             "contact_id" => "dl_source_reserved",
             "station_reservation_id" => "reservation_expired",
             "import_status" => "review_required_before_import",
             "has_cadence_import" => false,
             "source_review_row" => %{
               "station_reservation_hold_count" => 2,
               "source_station_reservation" => %{
                 "source_station_reservation_summary" => %{
                   "reservation_hold_review_status" => "review_required",
                   "earliest_reservation_hold_expires_at_s" => 240.0
                 }
               }
             }
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(get_in(&1, ["source_review_row", "source"]) ==
                   "campaign_repair.source_station_reservation_hold_summary.review_rows.affected_contacts")
             )

    assert artifact["source_constraint_report"] == source_constraint_report

    assert %{
             "review_type" => "constraint_review",
             "source" => "campaign_repair.source_constraint_report.rows",
             "scenario_id" => "dispersion_2",
             "constraint_id" => "minimum_operational_altitude",
             "metric" => "min_altitude_km",
             "operator" => ">=",
             "threshold" => 621.5,
             "value" => 621.19,
             "score" => -0.31,
             "constraint_status" => "fail",
             "source_constraint_row" => %{
               "scenario_id" => "dispersion_2",
               "status" => "fail"
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] == "campaign_repair.source_constraint_report.rows" and
                   &1["scenario_id"] == "dispersion_2")
             )

    assert %{
             "import_action" => "review_constraint",
             "source_review_type" => "constraint_review",
             "source" => "campaign_repair.source_constraint_report.rows",
             "scenario_id" => "dispersion_2",
             "constraint_id" => "minimum_operational_altitude",
             "constraint_status" => "fail",
             "import_status" => "review_required_before_import"
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["source"] == "campaign_repair.source_constraint_report.rows" and
                   &1["scenario_id"] == "dispersion_2")
             )

    assert artifact["source_objective_satisfaction_report"] ==
             source_objective_satisfaction_report

    assert %{
             "review_type" => "objective_satisfaction_review",
             "source" => "campaign_repair.source_objective_satisfaction_report.rows",
             "subject_id" => "objective:target_coverage",
             "objective" => "target_coverage",
             "objective_status" => "partial",
             "required_count" => 2,
             "candidate_count" => 1,
             "selected_count" => 1,
             "satisfied_count" => 1,
             "candidate_target_ids" => ["target_a"],
             "selected_target_ids" => ["target_a"],
             "source_objective_satisfaction" => %{
               "id" => "objective:target_coverage",
               "status" => "partial"
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_objective_satisfaction_report.rows" and
                   &1["objective"] == "target_coverage")
             )

    assert %{
             "import_action" => "review_objective_satisfaction",
             "source_review_type" => "objective_satisfaction_review",
             "subject_id" => "objective:target_coverage",
             "objective" => "target_coverage",
             "objective_status" => "partial",
             "required_count" => 2,
             "candidate_count" => 1,
             "selected_count" => 1,
             "satisfied_count" => 1,
             "import_status" => "review_required_before_import",
             "source_review_row" => %{
               "source" => "campaign_repair.source_objective_satisfaction_report.rows"
             }
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(get_in(&1, ["source_review_row", "source"]) ==
                   "campaign_repair.source_objective_satisfaction_report.rows" and
                   &1["objective"] == "target_coverage")
             )

    assert artifact["source_objective_tradeoff_report"] == source_objective_tradeoff_report

    assert %{
             "review_type" => "objective_tradeoff_review",
             "source" => "campaign_repair.source_objective_tradeoff_report.tradeoffs",
             "subject_id" => "leo_1",
             "scenario_id" => "leo_1",
             "score" => 1417.2731832107565,
             "score_delta_from_selected" => 0,
             "activity_count" => 1,
             "selected_observation_count" => 1,
             "selected_contact_count" => 0,
             "activity_ids" => ["leo_1_observe_target_a_1"],
             "score_terms" => %{
               "activity_score" => 1417.2731832107565,
               "target_value" => 1417.2731832107565
             },
             "source_objective_tradeoff" => %{
               "scenario_id" => "leo_1",
               "rank" => 1
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_objective_tradeoff_report.tradeoffs")
             )

    assert %{
             "import_action" => "review_objective_tradeoff",
             "source_review_type" => "objective_tradeoff_review",
             "source" => "campaign_repair.source_objective_tradeoff_report.tradeoffs",
             "subject_id" => "leo_1",
             "scenario_id" => "leo_1",
             "score" => 1417.2731832107565,
             "score_delta_from_selected" => 0,
             "activity_count" => 1,
             "activity_ids" => ["leo_1_observe_target_a_1"],
             "import_status" => "review_required_before_import"
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_objective_tradeoff_report.tradeoffs")
             )

    assert artifact["source_score_term_report"] == source_score_term_report

    assert %{
             "review_type" => "score_term_review",
             "source" => "campaign_repair.source_score_term_report.rows",
             "subject_id" => "score_term:leo_1:1:activity_count_penalty",
             "scenario_id" => "leo_1",
             "term_key" => "activity_count_penalty",
             "value" => 0,
             "timeline_score" => 1417.2731832107565,
             "selected" => true,
             "source_score_term" => %{
               "id" => "score_term:leo_1:1:activity_count_penalty",
               "rank" => 1,
               "term_key" => "activity_count_penalty"
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] == "campaign_repair.source_score_term_report.rows" and
                   &1["term_key"] == "activity_count_penalty")
             )

    assert %{
             "import_action" => "review_score_term",
             "source_review_type" => "score_term_review",
             "source" => "campaign_repair.source_score_term_report.rows",
             "subject_id" => "score_term:leo_1:1:activity_count_penalty",
             "scenario_id" => "leo_1",
             "term_key" => "activity_count_penalty",
             "value" => 0,
             "timeline_score" => 1417.2731832107565,
             "selected" => true,
             "import_status" => "review_required_before_import"
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["source"] == "campaign_repair.source_score_term_report.rows" and
                   &1["term_key"] == "activity_count_penalty")
             )

    assert artifact["source_timeline_diff_report"] == source_timeline_diff_report

    assert %{
             "review_type" => "timeline_diff_review",
             "source" => "campaign_repair.source_timeline_diff_report.rows",
             "subject_id" => "timeline:obs_1",
             "timeline_id" => "timeline:obs_1",
             "diff_status" => "changed",
             "source_activity_id" => "obs_1",
             "replacement_activity_id" => "obs_1b",
             "source_approval_status" => "approved",
             "replacement_approval_status" => "pending",
             "start_delta_s" => 2.0,
             "end_delta_s" => 2.0,
             "changed_fields" => [
               "activity_id",
               "status",
               "approval_status",
               "starts_at_s",
               "ends_at_s"
             ],
             "transition_decision" => "preserve_source",
             "required_operator_action" => "review_changed_protected_activity",
             "source_timeline_diff" => %{
               "id" => "timeline_diff:timeline:obs_1",
               "rank" => 3,
               "requires_operator_review" => true
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] == "campaign_repair.source_timeline_diff_report.rows" and
                   &1["timeline_id"] == "timeline:obs_1")
             )

    assert %{
             "import_action" => "review_timeline_diff",
             "source_review_type" => "timeline_diff_review",
             "subject_id" => "timeline:obs_1",
             "timeline_id" => "timeline:obs_1",
             "diff_status" => "changed",
             "source_activity_id" => "obs_1",
             "replacement_activity_id" => "obs_1b",
             "transition_decision" => "preserve_source",
             "import_status" => "review_required_before_import",
             "source_review_row" => %{
               "source" => "campaign_repair.source_timeline_diff_report.rows"
             }
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(get_in(&1, ["source_review_row", "source"]) ==
                   "campaign_repair.source_timeline_diff_report.rows" and
                   &1["timeline_id"] == "timeline:obs_1")
             )

    assert artifact["source_schema_validation_report"] == source_schema_validation_report

    assert %{
             "review_type" => "schema_validation_review",
             "source" => "campaign_repair.source_schema_validation_report.errors",
             "subject_id" => "campaign_plan.v1",
             "action" => "review_schema_validation_failure",
             "validation_status" => "fail",
             "validation_mode" => "artifact_file",
             "validated_contract" => "campaign_plan.v1",
             "validated_artifact_family" => "campaign_plan",
             "artifact_path" => "study_results/bad_campaign.json",
             "issue_severity" => "error",
             "issue_path" => "$.plan_id",
             "issue_message" => "is required",
             "remediation_category" => "missing_required_field",
             "remediation_action" => "Populate this required field",
             "source_validation_issue" => %{
               "path" => "$.plan_id",
               "message" => "is required"
             },
             "source_schema_validation_report" => %{
               "status" => "fail",
               "error_count" => 1
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] == "campaign_repair.source_schema_validation_report.errors")
             )

    assert %{
             "import_action" => "review_schema_validation",
             "source_review_type" => "schema_validation_review",
             "source" => "campaign_repair.source_schema_validation_report.errors",
             "subject_id" => "campaign_plan.v1",
             "schema_validation_gate" => "artifact_contract_validation",
             "schema_validation_gate_status" => "fail",
             "schema_validation_issue_count" => 1,
             "issue_path" => "$.plan_id",
             "remediation_category" => "missing_required_field",
             "import_status" => "review_required_before_import"
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["source"] == "campaign_repair.source_schema_validation_report.errors")
             )

    assert artifact["source_model_acceptance_report"] == source_model_acceptance_report

    assert %{
             "review_type" => "model_acceptance_review",
             "source" => "campaign_repair.source_model_acceptance_report.rows",
             "subject_id" => "event.access_windows",
             "action" => "review_model_acceptance",
             "required_operator_action" => "review_model_acceptance",
             "approval_status" => "operator_review_required",
             "model_acceptance_report_id" => model_acceptance_report_id,
             "model_acceptance_status" => "review_required",
             "model_acceptance_intended_use" => "operational_import",
             "model_acceptance_validation_level" => "analysis",
             "model_acceptance_model_id" => "event.access_windows",
             "source_model_acceptance_row" => %{
               "model_id" => "event.access_windows",
               "status" => "review_required"
             },
             "source_model_acceptance_report" => %{
               "schema_contract" => "model_acceptance_report.v1",
               "status" => "blocked",
               "model_count" => 3,
               "accepted_count" => 1,
               "review_required_count" => 1,
               "blocked_count" => 1,
               "unknown_model_count" => 0
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] == "campaign_repair.source_model_acceptance_report.rows" and
                   &1["subject_id"] == "event.access_windows")
             )

    assert model_acceptance_report_id == source_model_acceptance_report["report_id"]

    assert %{
             "subject_id" => "propagator.two_body",
             "action" => "review_blocked_model_acceptance",
             "approval_status" => "blocked_by_policy",
             "model_acceptance_status" => "blocked",
             "model_acceptance_validation_level" => "educational"
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] == "campaign_repair.source_model_acceptance_report.rows" and
                   &1["subject_id"] == "propagator.two_body")
             )

    refute Enum.any?(
             artifact["cadence_import_manifest"]["rows"],
             &(&1["source_review_type"] == "model_acceptance_review")
           )

    assert artifact["source_validation_safety_case_summary"] ==
             source_validation_safety_case_summary

    assert %{
             "review_type" => "validation_safety_case_review",
             "source" => "campaign_repair.source_validation_safety_case_summary.evidence",
             "action" => "review_validation_safety_case",
             "required_operator_action" => "review_validation_safety_case",
             "approval_status" => "operator_review_required",
             "validation_safety_case_summary_id" =>
               "validation_safety_case:case:compatibility-example",
             "validation_safety_case_status" => "blocked",
             "validation_safety_case_evidence_status" => "review_required",
             "validation_safety_case_evidence_ref" => evidence_ref,
             "validation_safety_case_input_contract" => "model_acceptance_report.v1",
             "validation_safety_case_blocked_evidence_count" => 2,
             "validation_safety_case_review_required_evidence_count" => 1,
             "source_validation_safety_case_evidence" => %{
               "schema_contract" => "model_acceptance_report.v1",
               "status" => "review_required"
             },
             "source_validation_safety_case_summary" => %{
               "schema_contract" => "validation_safety_case_summary.v1",
               "status" => "blocked",
               "evidence_count" => 4,
               "accepted_evidence_count" => 1,
               "review_required_evidence_count" => 1,
               "blocked_evidence_count" => 2
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_validation_safety_case_summary.evidence" and
                   &1["validation_safety_case_evidence_status"] == "review_required")
             )

    assert evidence_ref ==
             "model_acceptance_report.v1:model_acceptance:operational_import:orbit_data.simple_json__event.access_windows"

    assert %{
             "action" => "review_blocked_validation_safety_case",
             "approval_status" => "blocked_by_policy",
             "validation_safety_case_evidence_status" => "blocked",
             "validation_safety_case_input_contract" => "schema_validation_report.v1"
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_validation_safety_case_summary.evidence" and
                   &1["validation_safety_case_evidence_status"] == "blocked")
             )

    refute Enum.any?(
             artifact["cadence_import_manifest"]["rows"],
             &(&1["source_review_type"] == "validation_safety_case_review")
           )

    assert artifact["source_provider_counteroffer_report"] ==
             source_provider_counteroffer_report

    assert artifact["source_provider_counteroffer_review_summary"] ==
             source_provider_counteroffer_review_summary

    assert %{
             "review_type" => "provider_counteroffer_review",
             "source" => "campaign_repair.source_provider_counteroffer_report.rows",
             "subject_id" => "provider_offer_1",
             "provider_counteroffer_id" => "provider_offer_1",
             "provider_counteroffer_status" => "proposed",
             "provider_counteroffer_negotiation_state" => "proposed",
             "provider_counteroffer_reason_code" => "provider_shifted_window",
             "provider_counteroffer_cost_delta" => 125.5,
             "provider_counteroffer_lock_deadline_s" => 150.0,
             "provider_counteroffer_starts_at_s" => 160.0,
             "provider_counteroffer_ends_at_s" => 210.0,
             "provider_counteroffer_start_delta_s" => 30.0,
             "provider_counteroffer_end_delta_s" => 40.0,
             "provider_counteroffer_duration_delta_s" => 10.0,
             "ground_station_id" => "dss_14",
             "action" => "review_provider_counteroffer",
             "required_operator_action" => "review_provider_counteroffer",
             "approval_status" => "operator_review_required",
             "source_provider_counteroffer" => %{
               "provider_counteroffer_id" => "provider_offer_1",
               "source_station_calendar_entry" => %{
                 "id" => "provider_counteroffer_window"
               }
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] == "campaign_repair.source_provider_counteroffer_report.rows")
             )

    assert %{
             "import_action" => "review_provider_counteroffer",
             "source_review_type" => "provider_counteroffer_review",
             "source" => "campaign_repair.source_provider_counteroffer_report.rows",
             "subject_id" => "provider_offer_1",
             "provider_counteroffer_id" => "provider_offer_1",
             "provider_counteroffer_status" => "proposed",
             "provider_counteroffer_negotiation_state" => "proposed",
             "provider_counteroffer_cost_delta" => 125.5,
             "provider_counteroffer_lock_deadline_s" => 150.0,
             "import_status" => "review_required_before_import",
             "source_review_row" => %{
               "required_operator_action" => "review_provider_counteroffer"
             }
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["source_review_type"] == "provider_counteroffer_review")
             )

    assert %{
             "review_type" => "provider_counteroffer_review",
             "source" =>
               "campaign_repair.source_provider_counteroffer_review_summary.review_rows",
             "provider_counteroffer_id" => "provider_offer_1",
             "provider_counteroffer_status" => "proposed",
             "provider_counteroffer_negotiation_state" => "proposed",
             "provider_counteroffer_lock_deadline_s" => 150.0,
             "required_operator_action" => "review_provider_counteroffer",
             "source_provider_counteroffer" => %{
               "provider_counteroffer_lock_deadline_status" => "expired",
               "source_provider_counteroffer_summary" => %{
                 "schema_contract" => "provider_counteroffer_review_summary.v1",
                 "counteroffer_count" => 1,
                 "reviewable_count" => 1,
                 "review_counteroffer_ids" => ["provider_offer_1"],
                 "counteroffer_review_status" => "review_required",
                 "counteroffer_status_counts" => %{"proposed" => 1},
                 "counteroffer_negotiation_state_counts" => %{"proposed" => 1},
                 "counteroffer_lock_deadline_count" => 1,
                 "earliest_counteroffer_lock_deadline_s" => 150.0,
                 "expired_counteroffer_lock_deadline_count" => 1,
                 "active_counteroffer_lock_deadline_count" => 0,
                 "missing_counteroffer_lock_deadline_count" => 0,
                 "counteroffer_ids_by_lock_deadline_status" => %{
                   "expired" => ["provider_offer_1"]
                 },
                 "assumptions" => %{
                   "execution_boundary" => "artifact_only_no_provider_writes",
                   "operator_authority" => "not_granted_by_summary"
                 }
               }
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_provider_counteroffer_review_summary.review_rows")
             )

    assert %{
             "import_action" => "review_provider_counteroffer",
             "source_review_type" => "provider_counteroffer_review",
             "provider_counteroffer_id" => "provider_offer_1",
             "import_status" => "review_required_before_import",
             "has_cadence_import" => false,
             "source_review_row" => %{
               "source" =>
                 "campaign_repair.source_provider_counteroffer_review_summary.review_rows",
               "source_provider_counteroffer" => %{
                 "source_provider_counteroffer_summary" => %{
                   "counteroffer_review_status" => "review_required",
                   "counteroffer_lock_deadline_status_counts" => %{"expired" => 1}
                 }
               }
             }
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_provider_counteroffer_review_summary.review_rows")
             )

    assert artifact["source_provider_counteroffer_plan_impact_summary"] ==
             source_provider_counteroffer_plan_impact_summary

    assert %{
             "review_type" => "provider_counteroffer_review",
             "source" =>
               "campaign_repair.source_provider_counteroffer_plan_impact_summary.impact_rows",
             "subject_id" => "provider_offer_1",
             "provider_counteroffer_id" => "provider_offer_1",
             "provider_counteroffer_cost_delta" => 125.5,
             "provider_counteroffer_lock_deadline_s" => 150.0,
             "provider_counteroffer_starts_at_s" => 130.0,
             "provider_counteroffer_ends_at_s" => 170.0,
             "provider_counteroffer_start_delta_s" => 30.0,
             "provider_counteroffer_end_delta_s" => 30.0,
             "provider_counteroffer_duration_delta_s" => plan_impact_duration_delta,
             "station_calendar_entry_id" => "provider_counteroffer_window",
             "required_operator_action" => "review_provider_counteroffer",
             "source_provider_counteroffer" => %{
               "source_provider_counteroffer_summary" => %{
                 "schema_contract" => "provider_counteroffer_plan_impact_summary.v1",
                 "plan_impact_status" => "review_required",
                 "counteroffer_lock_deadline_status_counts" => %{"active" => 1}
               },
               "source_station_calendar_entry" => %{
                 "id" => "provider_counteroffer_window"
               }
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_provider_counteroffer_plan_impact_summary.impact_rows")
             )

    assert plan_impact_duration_delta == 0.0

    assert %{
             "import_action" => "review_provider_counteroffer",
             "source_review_type" => "provider_counteroffer_review",
             "source" =>
               "campaign_repair.source_provider_counteroffer_plan_impact_summary.impact_rows",
             "subject_id" => "provider_offer_1",
             "provider_counteroffer_start_delta_s" => 30.0,
             "provider_counteroffer_end_delta_s" => 30.0,
             "provider_counteroffer_duration_delta_s" => import_duration_delta,
             "import_status" => "review_required_before_import",
             "source_review_row" => %{
               "source_provider_counteroffer" => %{
                 "source_provider_counteroffer_summary" => %{
                   "plan_impact_status" => "review_required"
                 }
               }
             }
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_provider_counteroffer_plan_impact_summary.impact_rows")
             )

    assert import_duration_delta == 0.0

    assert artifact["source_provider_counteroffer_import_readiness_summary"] ==
             source_provider_counteroffer_import_readiness_summary

    assert %{
             "review_type" => "provider_counteroffer_review",
             "source" =>
               "campaign_repair.source_provider_counteroffer_import_readiness_summary.import_readiness_rows",
             "subject_id" => "provider_offer_1",
             "provider_counteroffer_id" => "provider_offer_1",
             "provider_counteroffer_lock_deadline_s" => 150.0,
             "required_operator_action" => "review_provider_counteroffer",
             "source_provider_counteroffer" => %{
               "provider_counteroffer_import_status" => "review_required_before_import",
               "provider_counteroffer_lock_deadline_status" => "expired",
               "source_provider_counteroffer_summary" => %{
                 "schema_contract" => "provider_counteroffer_import_readiness_summary.v1",
                 "import_readiness_status" => "review_required",
                 "import_classification" => "review_only",
                 "provider_counteroffer_import_status_counts" => %{
                   "review_required_before_import" => 1
                 },
                 "required_import_action_counts" => %{
                   "review_provider_counteroffer" => 1
                 }
               }
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_provider_counteroffer_import_readiness_summary.import_readiness_rows")
             )

    assert %{
             "import_action" => "review_provider_counteroffer",
             "source_review_type" => "provider_counteroffer_review",
             "source" =>
               "campaign_repair.source_provider_counteroffer_import_readiness_summary.import_readiness_rows",
             "subject_id" => "provider_offer_1",
             "import_status" => "review_required_before_import",
             "source_review_row" => %{
               "source_provider_counteroffer" => %{
                 "provider_counteroffer_import_status" => "review_required_before_import",
                 "source_provider_counteroffer_summary" => %{
                   "import_classification" => "review_only",
                   "import_readiness_status" => "review_required"
                 }
               }
             }
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_provider_counteroffer_import_readiness_summary.import_readiness_rows")
             )

    assert %{
             "contact_allocation_review_count" => 7,
             "station_pressure_contact_count" => 1,
             "station_pressure_review_contact_count" => 1,
             "station_pressure_contact_ids" => ["dl_3"],
             "station_pressure_review_contact_ids" => ["dl_3"],
             "station_pressure_contact_ids_by_ground_station_id" => %{
               "equator_prime" => ["dl_3"]
             },
             "station_pressure_contact_counts_by_ground_station_id" => %{
               "equator_prime" => 1
             },
             "station_pressure_contact_ids_by_availability" => %{"reserved" => ["dl_3"]},
             "station_pressure_contact_counts_by_availability" => %{"reserved" => 1},
             "station_pressure_contact_ids_by_precedence_availability" => %{
               "reserved" => ["dl_3"]
             },
             "station_pressure_contact_counts_by_precedence_availability" => %{
               "reserved" => 1
             },
             "station_pressure_contact_ids_by_precedence_rank" => %{"1" => ["dl_3"]},
             "station_pressure_contact_counts_by_precedence_rank" => %{"1" => 1},
             "station_pressure_contact_ids_by_status" => %{"reserved" => ["dl_3"]},
             "station_pressure_contact_counts_by_status" => %{"reserved" => 1},
             "station_pressure_contact_ids_by_direction" => %{"downlink" => ["dl_3"]},
             "station_pressure_contact_ids_by_direction_and_ground_station_id" => %{
               "downlink" => %{"equator_prime" => ["dl_3"]}
             },
             "station_reservation_match_status_counts" => %{
               "matched" => 1,
               "overlap" => 1
             },
             "station_reservation_contact_ids_by_match_status" => %{
               "matched" => ["dl_reserved_owner"],
               "overlap" => ["dl_reserved_intruder"]
             },
             "station_reservation_status_counts" => %{"confirmed" => 2},
             "station_reservation_contact_ids_by_status" => %{
               "confirmed" => ["dl_reserved_intruder", "dl_reserved_owner"]
             },
             "station_reserved_by_counts" => %{"ops_team_b" => 2},
             "station_reservation_contact_ids_by_reserved_by" => %{
               "ops_team_b" => ["dl_reserved_intruder", "dl_reserved_owner"]
             },
             "station_reservation_expiration_status_counts" => %{"expired" => 2},
             "station_reservation_contact_ids_by_expiration_status" => %{
               "expired" => ["dl_reserved_intruder", "dl_reserved_owner"]
             },
             "station_reservation_ids" => ["reservation_1"],
             "station_reservation_ids_by_match_status" => %{
               "matched" => ["reservation_1"],
               "overlap" => ["reservation_1"]
             },
             "reservation_conflict_contact_ids_by_direction" => %{
               "downlink" => ["dl_reserved_intruder"]
             },
             "reservation_conflict_contact_ids_by_direction_and_ground_station_id" => %{
               "downlink" => %{"equator_prime" => ["dl_reserved_intruder"]}
             },
             "provider_reservation_candidate_contact_count" => 2,
             "provider_reservation_request_contact_count" => 1,
             "provider_reservation_review_contact_count" => 1,
             "provider_reservation_no_request_contact_count" => 2,
             "provider_reservation_request_status_counts" => %{"review_required" => 1}
           } = artifact["operator_review_package"]

    assert %{
             "review_type" => "contact_allocation_review",
             "source" =>
               "campaign_repair.source_contact_allocation_reservation_conflict_summary.reservation_review_rows",
             "contact_id" => "dl_reserved_intruder",
             "ground_station_id" => "equator_prime",
             "required_operator_action" => "review_contact_allocation",
             "station_reservation_id" => "reservation_1",
             "station_reservation_match_status" => "overlap",
             "station_reservation_status" => "confirmed",
             "station_reserved_by" => "ops_team_b",
             "source_contact_allocation" => %{
               "source_contact_allocation_summary" => %{
                 "schema_contract" => "contact_allocation_reservation_conflict_summary.v1",
                 "reservation_conflict_contact_ids_by_direction" => %{
                   "downlink" => ["dl_reserved_intruder"]
                 },
                 "assumptions" => %{
                   "execution_boundary" =>
                     "artifact_only_no_provider_reservation_or_schedule_mutation",
                   "operator_authority" => "not_granted_by_reservation_conflict_summary"
                 }
               }
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_contact_allocation_reservation_conflict_summary.reservation_review_rows")
             )

    assert %{
             "import_action" => "review_contact_allocation",
             "source_review_type" => "contact_allocation_review",
             "contact_id" => "dl_reserved_intruder",
             "has_cadence_import" => false,
             "source_review_row" => %{
               "source" =>
                 "campaign_repair.source_contact_allocation_reservation_conflict_summary.reservation_review_rows",
               "source_contact_allocation" => %{
                 "source_contact_allocation_summary" => %{
                   "schema_contract" => "contact_allocation_reservation_conflict_summary.v1"
                 }
               }
             }
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["contact_id"] == "dl_reserved_intruder")
             )

    assert %{
             "review_type" => "contact_allocation_review",
             "source" =>
               "campaign_repair.source_contact_allocation_station_pressure_summary.review_rows",
             "contact_id" => "dl_3",
             "ground_station_id" => "equator_prime",
             "required_operator_action" => "review_contact_allocation",
             "station_availability" => "reserved",
             "station_reservation_id" => "reservation_1",
             "station_reservation_match_status" => "overlap",
             "source_contact_allocation" => %{
               "station_calendar_precedence_availability" => "reserved",
               "station_calendar_precedence_rank" => 1,
               "source_contact_allocation_summary" => %{
                 "schema_contract" => "contact_allocation_station_pressure_summary.v1",
                 "station_pressure_review_contact_ids" => ["dl_3"],
                 "assumptions" => %{
                   "execution_boundary" =>
                     "artifact_only_no_provider_reservation_or_schedule_mutation",
                   "operator_authority" => "not_granted_by_station_pressure_summary"
                 }
               }
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_contact_allocation_station_pressure_summary.review_rows")
             )

    assert %{
             "import_action" => "review_contact_allocation",
             "source_review_type" => "contact_allocation_review",
             "contact_id" => "dl_3",
             "has_cadence_import" => false,
             "source_review_row" => %{
               "source" =>
                 "campaign_repair.source_contact_allocation_station_pressure_summary.review_rows",
               "source_contact_allocation" => %{
                 "source_contact_allocation_summary" => %{
                   "schema_contract" => "contact_allocation_station_pressure_summary.v1"
                 }
               }
             }
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["contact_id"] == "dl_3")
             )

    assert %{
             "review_type" => "contact_allocation_review",
             "source" =>
               "campaign_repair.source_contact_allocation_provider_reservation_request_summary.provider_reservation_request_rows",
             "contact_id" => "dl_reserved_owner",
             "required_operator_action" => "review_provider_reservation_request",
             "station_reservation_id" => "reservation_1",
             "station_reservation_match_status" => "matched",
             "provider_reservation_request_status" => "request_ready",
             "provider_reservation_request_execution_boundary" =>
               "artifact_only_no_provider_reservation_or_schedule_mutation",
             "provider_reservation_execution" => "not_performed_by_summary"
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["source"] ==
                   "campaign_repair.source_contact_allocation_provider_reservation_request_summary.provider_reservation_request_rows")
             )

    assert %{
             "import_action" => "review_provider_reservation_request",
             "source_review_type" => "contact_allocation_review",
             "contact_id" => "dl_reserved_owner",
             "provider_reservation_request_status" => "request_ready",
             "provider_reservation_execution" => "not_performed_by_summary",
             "has_cadence_import" => false,
             "source_review_row" => %{
               "source" =>
                 "campaign_repair.source_contact_allocation_provider_reservation_request_summary.provider_reservation_request_rows",
               "source_provider_reservation_request_summary" => %{
                 "schema_contract" =>
                   "contact_allocation_provider_reservation_request_summary.v1",
                 "provider_reservation_request_status" => "review_required"
               }
             }
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["contact_id"] == "dl_reserved_owner")
             )

    assert Enum.any?(
             artifact["operator_review_package"]["rows"],
             &(&1["review_type"] == "contact_allocation_review" and
                 &1["source"] == "campaign_repair.source_contact_allocation_report.rows" and
                 &1["required_operator_action"] == "review_contact_allocation")
           )

    assert Enum.any?(
             artifact["operator_review_package"]["rows"],
             &(&1["review_type"] == "contact_allocation_review" and
                 &1["source"] == "campaign_repair.contact_allocation_report.rows" and
                 &1["contact_id"] == "dl_refreshed")
           )

    assert %{
             "import_action" => "review_contact_allocation",
             "source_review_type" => "contact_allocation_review",
             "allocation_status" => "deferred",
             "contact_id" => "dl_deferred",
             "import_status" => "review_required_before_import"
           } =
             artifact["cadence_import_manifest"]["rows"]
             |> Enum.find(&(&1["contact_id"] == "dl_deferred"))

    assert artifact["cadence_import_manifest"]["assumptions"]["row_source"] ==
             "operator_review_package.rows"

    assert %{
             "schema_contract" => "resource_filter_report.v1",
             "suppressed_candidate_count" => 1
           } = artifact["source_resource_filter_report"]

    assert %{
             "schema_contract" => "refresh_budget_report.v1",
             "input_candidate_count" => 2,
             "kept_candidate_count" => 1,
             "dropped_candidate_count" => 1,
             "kept_candidate_ids" => ["dl_refreshed"],
             "dropped_candidate_ids" => ["dl_deferred"]
           } = artifact["source_refresh_budget_report"]

    assert %{
             "refresh_budget_review_count" => 1
           } = artifact["operator_review_package"]

    assert %{
             "review_type" => "refresh_budget_review",
             "source" => "campaign_repair.source_refresh_budget_report",
             "required_operator_action" => "review_refresh_budget",
             "dropped_candidate_count" => 1,
             "dropped_candidate_ids" => ["dl_deferred"],
             "source_refresh_budget_report" => %{"schema_contract" => "refresh_budget_report.v1"}
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "refresh_budget_review")
             )

    assert %{
             "import_action" => "review_refresh_budget",
             "source_review_type" => "refresh_budget_review",
             "dropped_candidate_count" => 1,
             "dropped_candidate_ids" => ["dl_deferred"],
             "import_status" => "review_required_before_import"
           } =
             Enum.find(
               artifact["cadence_import_manifest"]["rows"],
               &(&1["import_action"] == "review_refresh_budget")
             )

    assert %{
             "schema_contract" => "operational_timeline_report.v1",
             "source" => "campaign_repair.activities",
             "activity_count" => 1,
             "row_count" => 1,
             "contact_count" => 1,
             "command_count" => 0,
             "rows" => [
               %{
                 "activity_id" => "dl_refreshed",
                 "activity_type" => "downlink",
                 "approval_status" => "not_evaluated",
                 "ground_station_id" => "equator_prime",
                 "timeline_identity" => %{
                   "activity_id" => "dl_refreshed",
                   "activity_type" => "downlink"
                 }
               }
             ]
           } = artifact["operational_timeline_report"]

    assert {:ok, %{"schema_contract" => "operational_timeline_report.v1"}} =
             Schema.validate_artifact(artifact["operational_timeline_report"])

    assert "candidate refresh freshness policy marked the snapshot, horizon, or state quality stale" in artifact[
             "warnings"
           ]

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  test "repair omits candidate diff pressure for empty and absent reports" do
    plan = %{"activities" => [], "candidate_activities" => []}

    common_opts = [
      realized_state: %{activities: []},
      current_epoch_s: 165.0,
      scoring_policy: %{"risk_weight" => "1.75"}
    ]

    empty_artifact =
      repair(
        plan,
        Keyword.put(
          common_opts,
          :candidate_refresh,
          candidate_refresh_artifact([], candidate_diff_report: empty_candidate_diff_report())
        )
      )

    absent_artifact =
      repair(
        plan,
        Keyword.put(
          common_opts,
          :candidate_refresh,
          candidate_refresh_artifact([], [])
        )
      )

    assert empty_artifact["source_candidate_diff_report"]["schema_contract"] ==
             "candidate_diff_report.v1"

    refute Map.has_key?(empty_artifact["score_terms"], "candidate_diff_pressure_penalty")

    refute "candidate_diff_pressure_penalty" in empty_artifact["score_term_report"][
             "score_term_keys"
           ]

    assert is_nil(absent_artifact["source_candidate_diff_report"])
    refute Map.has_key?(absent_artifact["score_terms"], "candidate_diff_pressure_penalty")

    refute "candidate_diff_pressure_penalty" in absent_artifact["score_term_report"][
             "score_term_keys"
           ]

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(empty_artifact)

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(absent_artifact)
  end

  test "repair scores unknown freshness once and omits an absent freshness report" do
    plan = %{
      "activities" => [downlink("dl_1", 100.0, 160.0)],
      "candidate_activities" => [downlink("dl_stale", 700.0, 760.0)]
    }

    common_opts = [
      realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
      current_epoch_s: 165.0,
      scoring_policy: %{"risk_weight" => "1.75"}
    ]

    unknown_artifact =
      repair(
        plan,
        Keyword.put(
          common_opts,
          :candidate_refresh,
          candidate_refresh_artifact(
            [refreshed_downlink("dl_unknown", 500.0, 560.0)],
            freshness_report: freshness_report("unknown")
          )
        )
      )

    absent_artifact =
      repair(
        plan,
        Keyword.put(
          common_opts,
          :candidate_refresh,
          candidate_refresh_artifact(
            [refreshed_downlink("dl_absent", 500.0, 560.0)],
            []
          )
        )
      )

    assert unknown_artifact["score_terms"]["refresh_freshness_pressure_penalty"] == -1.75
    assert unknown_artifact["source_freshness_report"]["status"] == "unknown"

    assert Enum.any?(
             unknown_artifact["operator_review_package"]["rows"],
             &(&1["review_type"] == "freshness_review" and
                 &1["freshness_status"] == "unknown")
           )

    assert Enum.any?(
             unknown_artifact["cadence_import_manifest"]["rows"],
             &(&1["import_action"] == "review_refresh_freshness" and
                 &1["freshness_status"] == "unknown")
           )

    assert [
             %{
               "term_key" => "refresh_freshness_pressure_penalty",
               "value" => -1.75,
               "selected" => true
             }
           ] =
             Enum.filter(
               unknown_artifact["score_term_report"]["rows"],
               &(&1["term_key"] == "refresh_freshness_pressure_penalty")
             )

    assert unknown_artifact["score"] ==
             unknown_artifact["score_terms"] |> Map.values() |> Enum.sum()

    refute Map.has_key?(absent_artifact["score_terms"], "refresh_freshness_pressure_penalty")

    refute "refresh_freshness_pressure_penalty" in absent_artifact["score_term_report"][
             "score_term_keys"
           ]

    assert is_nil(absent_artifact["source_freshness_report"])

    refute Enum.any?(
             absent_artifact["operator_review_package"]["rows"],
             &(&1["review_type"] == "freshness_review")
           )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(unknown_artifact)

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(absent_artifact)
  end

  test "repair preserves canonical candidate refresh readiness and quality source reports" do
    source_reports = passive_candidate_refresh_source_reports()

    artifact =
      repair(
        %{
          "activities" => [downlink("dl_1", 100.0, 160.0)],
          "candidate_activities" => [downlink("dl_stale", 700.0, 760.0)]
        },
        realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
        current_epoch_s: 165.0,
        candidate_refresh:
          [refreshed_downlink("dl_ready", 500.0, 560.0)]
          |> candidate_refresh_artifact(freshness_report: freshness_report("current"))
          |> Map.put(
            "operational_readiness_report",
            source_reports["source_operational_readiness_report"]
          )
          |> Map.put("quality_gate_report", passive_quality_gate_report())
      )

    assert [%{"id" => "dl_ready", "repair" => %{"action" => "moved"}}] =
             artifact["activities"]

    assert artifact["source_operational_readiness_report"]["schema_contract"] ==
             "operational_readiness_report.v1"

    assert artifact["source_quality_gate_report"]["schema_contract"] ==
             "quality_gate_report.v1"

    assert artifact["source_freshness_report"]["status"] == "current"

    refute Map.has_key?(artifact["score_terms"], "refresh_freshness_pressure_penalty")

    refute "refresh_freshness_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    refute Enum.any?(
             artifact["operator_review_package"]["rows"],
             &(&1["review_type"] == "freshness_review")
           )

    refute Enum.any?(
             artifact["cadence_import_manifest"]["rows"],
             &(&1["import_action"] == "review_refresh_freshness")
           )

    assert artifact["score_terms"]["operational_readiness_pressure_penalty"] == -2.0

    assert "operational_readiness_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert [
             %{
               "term_key" => "operational_readiness_pressure_penalty",
               "value" => -2.0,
               "selected" => true
             }
           ] =
             Enum.filter(
               artifact["score_term_report"]["rows"],
               &(&1["term_key"] == "operational_readiness_pressure_penalty")
             )

    assert artifact["score_terms"]["quality_gate_pressure_penalty"] == -1.0

    assert "quality_gate_pressure_penalty" in artifact["score_term_report"]["score_term_keys"]

    assert [
             %{
               "term_key" => "quality_gate_pressure_penalty",
               "value" => -1.0,
               "selected" => true
             }
           ] =
             Enum.filter(
               artifact["score_term_report"]["rows"],
               &(&1["term_key"] == "quality_gate_pressure_penalty")
             )

    assert %{
             "review_type" => "operational_readiness_review",
             "source" => "campaign_repair.source_operational_readiness_report",
             "source_operational_readiness_report" => %{
               "report_id" => "operational_readiness:planned_activity.v1:passive_source"
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "operational_readiness_review")
             )

    assert %{
             "review_type" => "quality_gate_review",
             "source" => "campaign_repair.source_quality_gate_report.rows",
             "source_quality_gate_report" => %{
               "report_id" => "quality_gate:planned_activity.v1:passive_source"
             }
           } =
             Enum.find(
               artifact["operator_review_package"]["rows"],
               &(&1["review_type"] == "quality_gate_review")
             )

    assert Enum.any?(
             artifact["cadence_import_manifest"]["rows"],
             &(&1["import_action"] == "review_operational_readiness" and
                 &1["source"] == "campaign_repair.source_operational_readiness_report")
           )

    assert Enum.any?(
             artifact["cadence_import_manifest"]["rows"],
             &(&1["import_action"] == "review_quality_gate" and
                 &1["source"] == "campaign_repair.source_quality_gate_report.rows")
           )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  test "repair scores each selected pressured contact intent once" do
    blocked_intent =
      contact_intent("dl_refreshed", %{"approval_status" => "blocked_by_policy"})

    artifact = repair_with_contact_intents([blocked_intent, blocked_intent])

    assert artifact["score_terms"]["contact_intent_pressure_penalty"] == -2.5
    assert artifact["score"] == artifact["score_terms"] |> Map.values() |> Enum.sum()

    assert [
             %{
               "term_key" => "contact_intent_pressure_penalty",
               "value" => -2.5,
               "selected" => true
             }
           ] =
             Enum.filter(
               artifact["score_term_report"]["rows"],
               &(&1["term_key"] == "contact_intent_pressure_penalty")
             )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    tampered_score = artifact["score"] + 1.0

    mismatched_score_term =
      artifact
      |> put_in(["score_terms", "contact_intent_pressure_penalty"], -1.5)
      |> Map.put("score", tampered_score)
      |> update_in(["score_term_report", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          row = Map.put(row, "timeline_score", tampered_score)

          if row["term_key"] == "contact_intent_pressure_penalty",
            do: Map.put(row, "value", -1.5),
            else: row
        end)
      end)

    assert {:error, score_term_report} = Schema.validate_artifact(mismatched_score_term)

    assert Enum.any?(
             score_term_report["errors"],
             &(&1["path"] == "$.score_terms.contact_intent_pressure_penalty")
           )
  end

  test "repair keeps unrelated and nonblocking contact intents score-neutral" do
    contact_intents = [
      contact_intent("dl_refreshed", %{"approval_status" => "operator_review_required"}),
      contact_intent("dl_other", %{"approval_status" => "blocked_by_policy"}),
      contact_intent("dl_refreshed", %{
        "activity_type" => "command",
        "direction" => "command",
        "approval_status" => "blocked_by_policy"
      }),
      contact_intent("obs_1", %{"approval_status" => "blocked_by_policy"})
    ]

    artifact =
      repair_with_contact_intents(contact_intents, [
        observe("obs_1", "leo_1", "target_a", 200.0, 260.0, 10.0)
      ])

    refute Map.has_key?(artifact["score_terms"], "contact_intent_pressure_penalty")

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  test "repair reuses every exact V3 contact-intent gate pressure status" do
    for pressure_fields <- [
          %{"cadence_import_status" => "missing"},
          %{"cadence_import_status" => "invalid"},
          %{
            "invalid_activity_input" => true,
            "invalid_activity_input_reason" => "invalid_activity_id"
          }
        ] do
      artifact =
        repair_with_contact_intents([
          contact_intent("dl_refreshed", pressure_fields)
        ])

      assert artifact["score_terms"]["contact_intent_pressure_penalty"] == -2.5
      assert artifact["score"] == artifact["score_terms"] |> Map.values() |> Enum.sum()
    end
  end

  test "repair rejects malformed contact-intent evidence before scoring" do
    assert_raise ArgumentError, ~r/invalid candidate_refresh.v1 artifact/, fn ->
      repair_with_contact_intents(["not-a-contact-intent"])
    end
  end

  test "repair replacement ranking prefers an unpressured lower-value downlink" do
    high = scored_refreshed_downlink("dl_high", 12.0)
    low = scored_refreshed_downlink("dl_low", 10.0)

    blocked = contact_intent("dl_high", %{"approval_status" => "blocked_by_policy"})
    invalid = contact_intent("dl_high", %{"cadence_import_status" => "invalid"})

    artifact =
      repair_with_ranked_contact_intents(
        [high, low],
        [blocked, invalid, blocked],
        5.0
      )

    assert [%{"id" => "dl_low", "repair" => %{"replacement_ranking" => ranking}}] =
             artifact["activities"]

    high_row = Enum.find(ranking["rows"], &(&1["candidate_id"] == "dl_high"))
    low_row = Enum.find(ranking["rows"], &(&1["candidate_id"] == "dl_low"))

    assert high_row["contact_intent_pressure_penalty"] == -5.0

    assert high_row["contact_intent_pressure_statuses"] == [
             "blocked_by_policy",
             "cadence_import_invalid"
           ]

    high_index = Enum.find_index(ranking["rows"], &(&1["candidate_id"] == "dl_high"))

    mismatched_statuses =
      put_in(
        artifact,
        [
          "activities",
          Access.at(0),
          "repair",
          "replacement_ranking",
          "rows",
          Access.at(high_index),
          "contact_intent_pressure_statuses"
        ],
        ["blocked_by_policy"]
      )

    assert {:error, mismatch_report} = Schema.validate_artifact(mismatched_statuses)

    assert Enum.any?(
             mismatch_report["errors"],
             &(&1["path"] ==
                 "$.activities[0].repair.replacement_ranking.rows[#{high_index}].contact_intent_pressure_statuses")
           )

    assert high_row["selected"] == false
    assert low_row["contact_intent_pressure_penalty"] == 0.0
    refute Map.has_key?(low_row, "contact_intent_pressure_statuses")
    assert low_row["selected"] == true
    refute Map.has_key?(artifact["score_terms"], "contact_intent_pressure_penalty")

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  test "repair replacement ranking preserves zero-weight pressure evidence" do
    high = scored_refreshed_downlink("dl_high", 12.0)
    low = scored_refreshed_downlink("dl_low", 10.0)

    artifact =
      repair_with_ranked_contact_intents(
        [high, low],
        [contact_intent("dl_high", %{"approval_status" => "blocked_by_policy"})],
        0.0
      )

    assert [%{"id" => "dl_high", "repair" => %{"replacement_ranking" => ranking}}] =
             artifact["activities"]

    high_row = Enum.find(ranking["rows"], &(&1["candidate_id"] == "dl_high"))

    assert high_row["contact_intent_pressure_penalty"] == 0.0
    assert high_row["contact_intent_pressure_statuses"] == ["blocked_by_policy"]
    assert artifact["score_terms"]["contact_intent_pressure_penalty"] == 0.0

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    legacy_ranking =
      update_in(
        artifact,
        ["activities", Access.at(0), "repair", "replacement_ranking", "rows"],
        fn rows ->
          Enum.map(rows, fn row ->
            Map.drop(row, [
              "contact_intent_pressure_penalty",
              "contact_intent_pressure_statuses"
            ])
          end)
        end
      )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(legacy_ranking)
  end

  test "repair replacement ranking keeps review-only intent evidence neutral" do
    high = scored_refreshed_downlink("dl_high", 12.0)
    low = scored_refreshed_downlink("dl_low", 10.0)

    artifact =
      repair_with_ranked_contact_intents(
        [high, low],
        [
          contact_intent("dl_high", %{
            "approval_status" => "operator_review_required"
          })
        ],
        5.0
      )

    assert [%{"id" => "dl_high", "repair" => %{"replacement_ranking" => ranking}}] =
             artifact["activities"]

    high_row = Enum.find(ranking["rows"], &(&1["candidate_id"] == "dl_high"))

    assert high_row["contact_intent_pressure_penalty"] == 0.0
    refute Map.has_key?(high_row, "contact_intent_pressure_statuses")
    refute Map.has_key?(artifact["score_terms"], "contact_intent_pressure_penalty")

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
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

  defp repair_with_contact_intents(contact_intents, additional_activities \\ []) do
    refreshed_candidate = refreshed_downlink("dl_refreshed", 500.0, 560.0)

    repair(
      %{
        "activities" => [downlink("dl_1", 100.0, 160.0)] ++ additional_activities,
        "candidate_activities" => [downlink("dl_stale", 700.0, 760.0)]
      },
      realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
      current_epoch_s: 165.0,
      scoring_policy: %{"risk_weight" => "2.5"},
      candidate_refresh:
        candidate_refresh_artifact([refreshed_candidate],
          contact_intents: contact_intents
        )
    )
  end

  defp repair_with_ranked_contact_intents(candidates, contact_intents, risk_weight) do
    repair(
      %{
        "activities" => [downlink("dl_1", 100.0, 160.0)],
        "candidate_activities" => [downlink("dl_stale", 700.0, 760.0)]
      },
      realized_state: %{activities: [%{id: "dl_1", status: "missed"}]},
      current_epoch_s: 165.0,
      scoring_policy: %{"risk_weight" => risk_weight},
      candidate_refresh:
        candidate_refresh_artifact(candidates,
          contact_intents: contact_intents
        )
    )
  end

  defp scored_refreshed_downlink(id, score) do
    id
    |> refreshed_downlink(500.0, 560.0)
    |> Map.put("score", score)
    |> put_in(["score_terms", "contact_value"], score)
  end

  defp contact_intent(activity_id, fields) do
    Map.merge(
      %{
        "schema_contract" => "contact_intent.v1",
        "id" => activity_id,
        "activity_id" => activity_id,
        "activity_type" => "downlink",
        "scenario_id" => "leo_1",
        "ground_station_id" => "equator_prime",
        "direction" => "downlink",
        "starts_at_s" => 500.0,
        "ends_at_s" => 560.0
      },
      fields
    )
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

  defp empty_candidate_diff_report do
    %{
      "schema_contract" => "candidate_diff_report.v1",
      "model" => "candidate_id_set_diff_with_semantic_change_reasons",
      "prior_candidate_count" => 0,
      "refreshed_candidate_count" => 0,
      "retained_candidate_count" => 0,
      "new_candidate_count" => 0,
      "invalidated_candidate_count" => 0,
      "retained_candidates" => [],
      "new_candidates" => [],
      "invalidated_candidates" => []
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

  defp contact_allocation_report do
    %{
      "schema_contract" => "contact_allocation_report.v1",
      "model" => "deterministic_station_contact_allocation",
      "source" => "candidate_refresh.candidate_activities",
      "input_contact_count" => 2,
      "allocated_contact_count" => 1,
      "deferred_contact_count" => 1,
      "blocked_contact_count" => 0,
      "effective_allocation_status_counts" => %{"allocated" => 1, "deferred" => 1},
      "rows" => [
        %{
          "id" => "contact_allocation:dl_refreshed",
          "contact_id" => "dl_refreshed",
          "allocation_status" => "allocated",
          "effective_allocation_status" => "allocated",
          "allocation_reason" => "selected_by_contention_resolution",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 500.0,
          "ends_at_s" => 560.0,
          "selected" => true,
          "contention_group_id" => "station:equator_prime:contention:1",
          "deferred_contact_ids" => ["dl_deferred"]
        },
        %{
          "id" => "contact_allocation:dl_deferred",
          "contact_id" => "dl_deferred",
          "allocation_status" => "deferred",
          "effective_allocation_status" => "deferred",
          "allocation_reason" => "same_station_contention",
          "ground_station_id" => "equator_prime",
          "starts_at_s" => 520.0,
          "ends_at_s" => 580.0,
          "selected" => false,
          "contention_group_id" => "station:equator_prime:contention:1",
          "selected_contact_id" => "dl_refreshed"
        }
      ],
      "contact_filter_report" => %{
        "schema_contract" => "contact_filter_report.v1",
        "model" => "thin_ground_network_availability_filter",
        "input_candidate_count" => 2,
        "kept_candidate_count" => 2,
        "suppressed_candidate_count" => 0,
        "suppressed_candidates" => []
      },
      "contact_contention_report" => %{
        "schema_contract" => "contact_contention_report.v1",
        "model" => "single_station_interval_overlap",
        "input_contact_count" => 2,
        "conflicted_contact_count" => 2,
        "conflict_group_count" => 1,
        "conflict_groups" => [
          %{
            "id" => "station:equator_prime:contention:1",
            "ground_station_id" => "equator_prime",
            "contact_count" => 2,
            "starts_at_s" => 500.0,
            "ends_at_s" => 580.0,
            "direction" => "downlink",
            "required_operator_action" => "review_contact_contention",
            "approval_status" => "operator_review_required",
            "contact_ids" => ["dl_refreshed", "dl_deferred"],
            "source_window_ids" => [],
            "scenario_ids" => ["leo_1"]
          }
        ]
      },
      "contact_contention_resolution_report" => %{
        "schema_contract" => "contact_contention_resolution_report.v1",
        "model" => "deterministic_contact_contention_recommendation",
        "policy" => %{
          "selection_rule" => "highest_score_earliest_start",
          "tie_breakers" => ["starts_at_s", "id"],
          "action" => "recommend_preferred_contact_for_operator_review"
        },
        "conflict_group_count" => 1,
        "recommendation_count" => 1,
        "recommendations" => [
          %{
            "group_id" => "station:equator_prime:contention:1",
            "ground_station_id" => "equator_prime",
            "starts_at_s" => 500.0,
            "ends_at_s" => 580.0,
            "selected_contact_id" => "dl_refreshed",
            "selected_scenario_id" => "leo_1",
            "deferred_contact_ids" => ["dl_deferred"],
            "candidate_count" => 2,
            "selection_reason" => "highest_score_earliest_start",
            "action" => "recommend_preferred_contact_for_operator_review",
            "review_status" => "operator_review_required"
          }
        ]
      },
      "assumptions" => %{
        "execution_boundary" => "artifact_only_no_provider_reservation_or_schedule_mutation"
      }
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

  defp refresh_budget_report do
    %{
      "schema_contract" => "refresh_budget_report.v1",
      "model" => "deterministic_candidate_limit_after_filters",
      "input_candidate_count" => 2,
      "kept_candidate_count" => 1,
      "dropped_candidate_count" => 1,
      "max_candidate_activities" => 1,
      "selection_order" => "score_descending_then_start_then_id",
      "kept_candidate_ids" => ["dl_refreshed"],
      "dropped_candidate_ids" => ["dl_deferred"],
      "assumptions" => %{
        "budget_stage" => "after_contact_resource_and_allocation_filters",
        "optimizer_search_performed" => false
      }
    }
  end

  defp freshness_report(status) do
    accepted_snapshot_age_s = if status == "stale", do: 3_600.0, else: 30.0
    accepted_at = if status == "stale", do: "2026-05-13T23:00:00Z", else: "2026-05-13T23:59:30Z"

    stale_reasons =
      if status == "stale",
        do: ["accepted_snapshot_older_than_policy"],
        else: []

    unknown_reasons =
      if status == "unknown",
        do: ["accepted_state_quality_unknown"],
        else: []

    report = %{
      "schema_contract" => "freshness_report.v1",
      "model" => "accepted_snapshot_horizon_and_quality_freshness",
      "generated_at" => "2026-05-14T00:00:00Z",
      "accepted_at" => accepted_at,
      "current_epoch_s" => 165.0,
      "horizon_starts_at_s" => 165.0,
      "accepted_snapshot_age_s" => accepted_snapshot_age_s,
      "horizon_start_offset_s" => 0.0,
      "max_snapshot_age_s" => 60.0,
      "max_horizon_start_offset_s" => 1.0,
      "status" => status,
      "stale_reasons" => stale_reasons,
      "unknown_reasons" => unknown_reasons
    }

    if status == "unknown",
      do: report,
      else: Map.put(report, "accepted_state_quality_level", "accepted")
  end

  defp passive_candidate_refresh_source_reports do
    %{
      "source_candidate_diff_report" => %{
        "schema_contract" => "candidate_diff_report.v1",
        "retained_candidates" => [],
        "new_candidates" => [],
        "invalidated_candidates" => []
      },
      "source_candidate_rejection_report" => %{
        "schema_contract" => "candidate_rejection_report.v1",
        "rows" => []
      },
      "source_schema_validation_report" => %{
        "schema_contract" => "schema_validation_report.v1",
        "validation_mode" => "artifact",
        "validated_contract" => "candidate_refresh.v1",
        "status" => "pass",
        "error_count" => 0,
        "warning_count" => 0,
        "remediation_count" => 0,
        "errors" => [],
        "warnings" => [],
        "remediation" => []
      },
      "source_freshness_report" => %{
        "schema_contract" => "freshness_report.v1",
        "status" => "fresh",
        "stale_reasons" => [],
        "unknown_reasons" => []
      },
      "source_refresh_budget_report" => %{
        "schema_contract" => "refresh_budget_report.v1",
        "input_candidate_count" => 1,
        "kept_candidate_count" => 1,
        "dropped_candidate_count" => 0
      },
      "source_operational_readiness_report" => passive_readiness_report(),
      "source_provider_counteroffer_report" => %{
        "schema_contract" => "provider_counteroffer_report.v1",
        "source" => "station_calendar_report.affected_contacts",
        "source_artifact_type" => "station_calendar_report.v1",
        "source_artifact_id" => "station_calendar_report",
        "counteroffer_count" => 1,
        "reviewable_count" => 1,
        "counteroffer_status_counts" => %{"proposed" => 1},
        "required_operator_action_counts" => %{"review_provider_counteroffer" => 1},
        "rows" => [
          %{
            "id" => "provider_counteroffer:1:provider_offer_1",
            "provider_counteroffer_id" => "provider_offer_1",
            "provider_counteroffer_status" => "proposed",
            "reviewable" => true,
            "required_operator_action" => "review_provider_counteroffer"
          }
        ],
        "assumptions" => %{},
        "model_limits" => ["artifact_only"]
      },
      "source_station_calendar_report" => %{
        "schema_contract" => "station_calendar_report.v1",
        "affected_contacts" => [],
        "provider_calendar_contention_groups" => []
      },
      "source_station_reservation_report" => %{
        "schema_contract" => "station_reservation_report.v1",
        "source" => "station_calendar_report.reservation_evidence",
        "affected_contacts" => [
          %{
            "contact_id" => "dl_reserved_intruder",
            "station_reservation_match_status" => "overlap",
            "station_calendar_reservation_ids" => ["reservation_partner"],
            "station_calendar_reservation_statuses" => ["confirmed"],
            "station_calendar_reservation_expires_at_s" => [360.0],
            "required_operator_action" => "review_station_reservation_overlap",
            "trust_boundary" => "reservation_report_rows"
          }
        ],
        "provider_calendar_contention_groups" => [],
        "trust_boundary" => "reservation_report"
      },
      "source_station_reservation_hold_import_readiness_summary" => %{
        "model" => "artifact_only_station_reservation_hold_import_readiness_summary",
        "source_artifact_type" => "station_reservation_report.v1",
        "source" => "station_calendar_report.reservation_evidence",
        "reservation_hold_count" => 2,
        "import_readiness_status" => "review_required",
        "import_classification" => "review_only",
        "ready_for_import_count" => 0,
        "review_required_before_import_count" => 2,
        "no_import_required_count" => 0,
        "reservation_hold_import_status_counts" => %{
          "review_required_before_import" => 2
        },
        "required_import_action_counts" => %{
          "review_station_provider_contention" => 1,
          "review_station_reservation_overlap" => 1
        },
        "reservation_hold_ids" => ["reservation_expired", "reservation_missing"],
        "reservation_hold_ids_by_import_status" => %{
          "review_required_before_import" => ["reservation_expired", "reservation_missing"]
        },
        "reservation_hold_ids_by_required_import_action" => %{
          "review_station_provider_contention" => ["reservation_missing"],
          "review_station_reservation_overlap" => ["reservation_expired"]
        },
        "reservation_hold_contact_ids_by_import_status" => %{
          "review_required_before_import" => ["dl_reserved_intruder"]
        },
        "import_readiness_rows" => [
          %{
            "reservation_review_row_type" => "affected_contact",
            "contact_id" => "dl_reserved_intruder",
            "reservation_ids" => ["reservation_expired"],
            "reservation_statuses" => ["held"],
            "reserved_by" => ["ops_calendar"],
            "station_reservation_hold_import_status" => "review_required_before_import",
            "required_operator_action" => "review_station_reservation_overlap"
          },
          %{
            "reservation_review_row_type" => "provider_calendar_contention_group",
            "reservation_ids" => ["reservation_missing"],
            "reservation_statuses" => ["held"],
            "reserved_by" => ["partner_calendar"],
            "station_reservation_hold_import_status" => "review_required_before_import",
            "required_operator_action" => "review_station_provider_contention"
          }
        ],
        "assumptions" => %{
          "execution_boundary" => "artifact_only_no_provider_or_cadence_writes",
          "provider_write" => "not_performed_by_summary",
          "cadence_write" => "not_performed_by_summary",
          "reservation_acceptance" => "not_performed_by_summary"
        }
      },
      "source_contact_filter_report" => %{
        "schema_contract" => "contact_filter_report.v1",
        "suppressed_candidates" => [],
        "invalid_contact_inputs" => []
      },
      "source_contact_allocation_report" => %{
        "schema_contract" => "contact_allocation_report.v1",
        "rows" => []
      },
      "source_contact_contention_report" => %{
        "schema_contract" => "contact_contention_report.v1",
        "conflict_groups" => [],
        "invalid_contact_inputs" => []
      },
      "source_contact_contention_resolution_report" => %{
        "schema_contract" => "contact_contention_resolution_report.v1",
        "recommendations" => []
      },
      "source_link_capacity_report" => %{
        "schema_contract" => "link_capacity_report.v1",
        "rows" => []
      },
      "source_resource_projection_report" => %{
        "schema_contract" => "resource_projection_report.v1",
        "projected_resources" => []
      },
      "source_resource_filter_report" => %{
        "schema_contract" => "resource_filter_report.v1",
        "suppressed_candidates" => [],
        "invalid_resource_summary_inputs" => []
      },
      "source_timeline_diff_report" => %{
        "schema_contract" => "timeline_diff_report.v1",
        "rows" => []
      },
      "source_constraint_report" => %{
        "schema_contract" => "constraint_report.v1",
        "rows" => []
      },
      "source_objective_satisfaction_report" => %{
        "schema_contract" => "objective_satisfaction_report.v1",
        "rows" => []
      },
      "source_objective_tradeoff_report" => %{
        "schema_contract" => "objective_tradeoff_report.v1",
        "tradeoffs" => []
      },
      "source_score_term_report" => %{
        "schema_contract" => "score_term_report.v1",
        "rows" => []
      }
    }
  end

  defp passive_quality_gate_report do
    OrbitalDynamics.operational_quality_gate_report(passive_readiness_report())
  end

  defp passive_readiness_report do
    %{
      "schema_contract" => "operational_readiness_report.v1",
      "schema_version" => 1,
      "model" => "artifact_only_operational_readiness_classifier",
      "report_id" => "operational_readiness:planned_activity.v1:passive_source",
      "source_artifact_type" => "planned_activity.v1",
      "source_artifact_id" => "passive_source",
      "readiness_level" => "operator_review",
      "import_classification" => "review_only",
      "status" => "review_required",
      "gate_count" => 1,
      "passed_gate_count" => 0,
      "review_gate_count" => 1,
      "analysis_gate_count" => 0,
      "blocked_gate_count" => 0,
      "gates" => [
        %{
          "id" => "operator_review",
          "status" => "review_required",
          "classification" => "review_only",
          "reason" => "operator review required"
        }
      ],
      "evidence" => %{},
      "assumptions" => [
        "classification_uses_declared_operator_review_and_cadence_import_manifest_evidence",
        "cadence_import_manifest_rows_are_adapter_handoff_not_external_import_writes"
      ],
      "model_limits" => [
        "artifact_only",
        "does_not_write_cadence",
        "does_not_approve_operator_actions",
        "does_not_execute_commands",
        "uses_declared_review_and_import_evidence"
      ]
    }
  end
end
