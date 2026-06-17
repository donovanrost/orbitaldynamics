Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyMissionStateValidationPressureTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.{Schema, Timeline}

  test "strategy derives branch refresh from mission-state candidate diff reports" do
    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:source_candidate_diff_report, %{
        "schema_contract" => "candidate_diff_report.v1",
        "model" => "candidate_id_set_diff_with_semantic_change_reasons",
        "prior_candidate_count" => 1,
        "refreshed_candidate_count" => 1,
        "retained_candidate_count" => 0,
        "new_candidate_count" => 1,
        "invalidated_candidate_count" => 1,
        "retained_candidates" => [],
        "new_candidates" => [],
        "invalidated_candidates" => [
          %{
            "id" => "dl_mission_stale",
            "type" => "downlink",
            "scenario_id" => "leo_1",
            "ground_station_id" => "equator_prime",
            "invalidated_reason" => "replaced_by_semantically_similar_candidate",
            "replacement_candidate_id" => "dl_mission_replacement",
            "required_downlink_mb" => 180.0,
            "candidate_downlink_mb" => 240.0,
            "downlink_completion_ratio" => 1.0,
            "source_window_id" => "window:leo_1:ground_station_access:equator_prime:stale",
            "replacement_source_window_id" =>
              "window:leo_1:ground_station_access:equator_prime:replacement"
          }
        ],
        "provenance" => %{"trust_boundary" => "mission_state_refresh_report"}
      })

    prior_plan =
      base_plan(%{
        "candidate_activities" => [
          downlink("dl_mission_replacement", 500.0, 560.0)
        ]
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    diff_branch = branch(artifact, "derived_candidate_diff_replacement_dl_mission_replacement")

    assert %{
             "type" => "candidate_diff_replacement",
             "replacement_candidate_id" => "dl_mission_replacement",
             "invalidated_candidate_id" => "dl_mission_stale",
             "required_downlink_mb" => 180.0,
             "candidate_downlink_mb" => 240.0,
             "feedback_source" =>
               "mission_state.source_candidate_diff_report.invalidated_candidates",
             "feedback_scope" => "candidate_diff",
             "trust_boundary" => "mission_state_refresh_report"
           } = List.first(diff_branch["events"])

    assert %{
             "id" => "dl_mission_replacement",
             "repair" => %{
               "action" => "strategic_addition",
               "reason" => "candidate_diff_replacement_inserted",
               "candidate_diff" => %{
                 "invalidated_reason" => "replaced_by_semantically_similar_candidate",
                 "replacement_candidate_id" => "dl_mission_replacement"
               }
             },
             "feasibility" => %{
               "status" => "validated_candidate_diff_replacement",
               "feedback_scope" => "candidate_diff"
             }
           } =
             Enum.find(
               diff_branch["candidate_plan"]["strategic_additions"],
               &(&1["id"] == "dl_mission_replacement")
             )

    assert "mission_state.source_candidate_diff_report" in get_in(
             diff_branch,
             ["assumptions", "candidate_source", "source_report_input_paths"]
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from mission-state candidate rejection reports" do
    rejection_report =
      Timeline.candidate_rejection_report(
        [
          %{
            id: :dl_rejected,
            type: :downlink,
            scenario_id: :leo_1,
            ground_station_id: :equator_prime,
            source_window_id: :equator_prime_rejected_window,
            station_availability: "reservation_hold",
            capacity_fraction: 0.5,
            starts_at_s: 700.0,
            ends_at_s: 705.0,
            min_duration_s: 10.0
          }
        ],
        source: :mission_state_candidate_rejections
      )
      |> Map.put("provenance", %{"trust_boundary" => "mission_state_candidate_rejection_report"})

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:source_candidate_rejection_report, rejection_report)

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    rejection_branch = branch(artifact, "derived_candidate_rejection_pressure_dl_rejected")

    assert %{
             "type" => "candidate_rejection_pressure",
             "candidate_id" => "dl_rejected",
             "activity_type" => "downlink",
             "ground_station_id" => "equator_prime",
             "primary_rejection_reason" => "contact_too_short",
             "rejection_reasons" => rejection_reasons,
             "feedback_source" => "mission_state.source_candidate_rejection_report.rows",
             "feedback_scope" => "candidate_rejection",
             "trust_boundary" => "mission_state_candidate_rejection_report",
             "source_candidate_rejection" => %{
               "candidate_id" => "dl_rejected",
               "required_operator_action" => "review_candidate_rejection"
             }
           } = List.first(rejection_branch["events"])

    assert "contact_too_short" in rejection_reasons
    assert "station_capacity_reduced" in rejection_reasons
    assert "station_reserved" in rejection_reasons

    assert %{
             "type" => "candidate_refresh.v1",
             "scope" => "branch_generated"
           } = rejection_branch["assumptions"]["candidate_source"]

    assert "mission_state.source_candidate_rejection_report" in get_in(
             rejection_branch,
             ["assumptions", "candidate_source", "source_report_input_paths"]
           )

    assert_candidate_rejection_pressure_score_terms(rejection_branch, artifact)

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from mission-state provider counteroffer reports" do
    counteroffer_report =
      %{
        "schema_contract" => "provider_counteroffer_report.v1",
        "source" => "station_calendar_report.affected_contacts",
        "source_artifact_type" => "station_calendar_report.v1",
        "source_artifact_id" => "station_calendar_report",
        "counteroffer_count" => 1,
        "reviewable_count" => 1,
        "counteroffer_status_counts" => %{"proposed" => 1},
        "counteroffer_negotiation_state_counts" => %{"proposed" => 1},
        "required_operator_action_counts" => %{"review_provider_counteroffer" => 1},
        "rows" => [
          %{
            "id" => "provider_counteroffer:1:provider_offer_1",
            "provider_counteroffer_id" => "provider_offer_1",
            "provider_counteroffer_status" => "proposed",
            "provider_counteroffer_negotiation_state" => "proposed",
            "provider_counteroffer_reason_code" => "provider_shifted_window",
            "provider_counteroffer_cost_delta" => 125.5,
            "provider_counteroffer_lock_deadline_s" => 150.0,
            "provider_counteroffer_starts_at_s" => 130.0,
            "provider_counteroffer_ends_at_s" => 170.0,
            "provider_counteroffer_start_delta_s" => 30.0,
            "provider_counteroffer_end_delta_s" => 30.0,
            "provider_counteroffer_duration_delta_s" => 0.0,
            "ground_station_id" => "equator_prime",
            "starts_at_s" => 100.0,
            "ends_at_s" => 140.0,
            "station_calendar_entry_id" => "provider_counteroffer_window",
            "station_calendar_provider_id" => "partner_calendar",
            "station_calendar_provider_entry_id" => "partner_entry_42",
            "station_availability" => "counteroffer",
            "reviewable" => true,
            "required_operator_action" => "review_provider_counteroffer",
            "source_station_calendar_entry" => %{
              "provider_counteroffer_id" => "provider_offer_1"
            }
          }
        ],
        "provenance" => %{"trust_boundary" => "mission_state_provider_counteroffer_report"}
      }

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:source_provider_counteroffer_report, counteroffer_report)

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    counteroffer_branch =
      branch(artifact, "derived_provider_counteroffer_pressure_provider_offer_1")

    assert %{
             "type" => "provider_counteroffer_pressure",
             "provider_counteroffer_id" => "provider_offer_1",
             "provider_counteroffer_status" => "proposed",
             "provider_counteroffer_negotiation_state" => "proposed",
             "provider_counteroffer_reason_code" => "provider_shifted_window",
             "provider_counteroffer_cost_delta" => 125.5,
             "provider_counteroffer_lock_deadline_s" => 150.0,
             "provider_counteroffer_starts_at_s" => 130.0,
             "provider_counteroffer_ends_at_s" => 170.0,
             "provider_counteroffer_start_delta_s" => 30.0,
             "provider_counteroffer_end_delta_s" => 30.0,
             "ground_station_id" => "equator_prime",
             "station_calendar_provider_id" => "partner_calendar",
             "feedback_source" => "mission_state.source_provider_counteroffer_report.rows",
             "feedback_scope" => "provider_counteroffer",
             "trust_boundary" => "mission_state_provider_counteroffer_report",
             "assumptions" => %{
               "provider_write" => "not_performed_by_strategy_branch",
               "schedule_mutation" => "not_performed_by_strategy_branch",
               "operator_authority" => "not_granted_by_strategy_branch"
             },
             "source_provider_counteroffer" => %{
               "provider_counteroffer_id" => "provider_offer_1",
               "required_operator_action" => "review_provider_counteroffer"
             }
           } = List.first(counteroffer_branch["events"])

    assert List.first(counteroffer_branch["events"])[
             "provider_counteroffer_duration_delta_s"
           ] == 0.0

    assert Enum.any?(
             counteroffer_branch["risk_indicators"],
             &(&1["type"] == "provider_counteroffer_pressure" and
                 &1["provider_counteroffer_id"] == "provider_offer_1")
           )

    assert %{
             "type" => "candidate_refresh.v1",
             "scope" => "branch_generated"
           } = counteroffer_branch["assumptions"]["candidate_source"]

    assert "mission_state.source_provider_counteroffer_report" in get_in(
             counteroffer_branch,
             ["assumptions", "candidate_source", "source_report_input_paths"]
           )

    assert_provider_counteroffer_pressure_score_terms(counteroffer_branch, artifact)

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch refresh from mission-state schema validation reports" do
    schema_validation_report =
      %{
        "schema_contract" => "schema_validation_report.v1",
        "validation_mode" => "artifact_file",
        "validated_contract" => "candidate_refresh.v1",
        "validated_artifact_family" => "candidate_refresh",
        "status" => "fail",
        "error_count" => 1,
        "warning_count" => 0,
        "remediation_count" => 1,
        "errors" => [
          %{
            "path" => "candidate_refresh_targets",
            "message" => "must include at least one target"
          }
        ],
        "warnings" => [],
        "remediation" => [
          %{
            "path" => "candidate_refresh_targets",
            "category" => "missing_required_field",
            "action" => "Populate this required field"
          }
        ],
        "artifact_path" => "study_results/candidate_refresh_v1.json",
        "provenance" => %{"trust_boundary" => "mission_state_schema_validation_report"}
      }

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:source_schema_validation_report, schema_validation_report)

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    schema_branch =
      branch(artifact, "derived_schema_validation_pressure_candidate_refresh.v1")

    assert %{
             "type" => "schema_validation_pressure",
             "validation_status" => "fail",
             "validation_mode" => "artifact_file",
             "validated_contract" => "candidate_refresh.v1",
             "issue_severity" => "error",
             "issue_path" => "candidate_refresh_targets",
             "issue_message" => "must include at least one target",
             "remediation_category" => "missing_required_field",
             "remediation_action" => "Populate this required field",
             "required_operator_action" => "review_schema_validation",
             "feedback_source" => "mission_state.source_schema_validation_report.errors",
             "feedback_scope" => "schema_validation",
             "trust_boundary" => "mission_state_schema_validation_report",
             "source_schema_validation_report" => %{
               "validated_contract" => "candidate_refresh.v1",
               "status" => "fail"
             }
           } = List.first(schema_branch["events"])

    assert %{
             "type" => "candidate_refresh.v1",
             "scope" => "branch_generated"
           } = schema_branch["assumptions"]["candidate_source"]

    assert "mission_state.source_schema_validation_report" in get_in(
             schema_branch,
             ["assumptions", "candidate_source", "source_report_input_paths"]
           )

    assert_validation_refresh_pressure_score_terms(schema_branch, artifact, "schema_validation")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp assert_candidate_rejection_pressure_score_terms(branch, artifact) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    candidate_rejection_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &(&1["feedback_scope"] == "candidate_rejection")
      )

    assert candidate_rejection_pressure_count > 0

    assert branch["score_terms"]["candidate_rejection_pressure_penalty"] ==
             -candidate_rejection_pressure_count * risk_weight

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) - candidate_rejection_pressure_count) *
               risk_weight

    assert "candidate_rejection_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "candidate_rejection_pressure_penalty" and
                 &1["value"] < 0.0)
           )
  end

  defp assert_provider_counteroffer_pressure_score_terms(branch, artifact) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    provider_counteroffer_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &(&1["feedback_scope"] == "provider_counteroffer")
      )

    assert provider_counteroffer_pressure_count > 0

    assert branch["score_terms"]["provider_counteroffer_pressure_penalty"] ==
             -provider_counteroffer_pressure_count * risk_weight

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) - provider_counteroffer_pressure_count) *
               risk_weight

    assert "provider_counteroffer_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "provider_counteroffer_pressure_penalty" and
                 &1["value"] < 0.0)
           )
  end

  defp assert_validation_refresh_pressure_score_terms(branch, artifact, feedback_scope) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    source_report_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &validation_refresh_source_report_pressure?(&1, feedback_scope)
      )

    scoped_pressure_count =
      Enum.count(branch["risk_indicators"], &(&1["feedback_scope"] == feedback_scope))

    scored_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &validation_refresh_scored_pressure?(&1, feedback_scope)
      )

    blended_validation_refresh_pressure_count =
      Enum.count(branch["risk_indicators"], &validation_refresh_pressure?/1)

    validation_refresh_family_pressure_count =
      Enum.count(branch["risk_indicators"], &validation_refresh_family_pressure?/1)

    pressure_term =
      if feedback_scope == "schema_validation" and scored_pressure_count == 0 and
           source_report_pressure_count > 0 do
        "validation_refresh_pressure_penalty"
      else
        validation_refresh_pressure_term(feedback_scope)
      end

    validation_refresh_pressure_count =
      if pressure_term == "validation_refresh_pressure_penalty" do
        blended_validation_refresh_pressure_count
      else
        scored_pressure_count
      end

    requested_validation_refresh_pressure_count =
      source_report_pressure_count + scoped_pressure_count

    assert requested_validation_refresh_pressure_count > 0
    assert validation_refresh_pressure_count > 0

    assert branch["score_terms"][pressure_term] ==
             -validation_refresh_pressure_count * risk_weight

    assert branch["score_terms"]["validation_refresh_pressure_penalty"] ==
             -blended_validation_refresh_pressure_count * risk_weight

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) - validation_refresh_family_pressure_count) *
               risk_weight

    assert pressure_term in artifact["score_term_report"]["score_term_keys"]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == pressure_term and
                 &1["value"] < 0.0)
           )
  end

  defp validation_refresh_pressure_term("model_acceptance"),
    do: "model_acceptance_pressure_penalty"

  defp validation_refresh_pressure_term("validation_safety_case"),
    do: "validation_safety_case_pressure_penalty"

  defp validation_refresh_pressure_term("schema_validation"),
    do: "schema_validation_pressure_penalty"

  defp validation_refresh_pressure_term("refresh_budget"),
    do: "refresh_budget_pressure_penalty"

  defp validation_refresh_pressure_term("refresh_freshness"),
    do: "refresh_freshness_pressure_penalty"

  defp validation_refresh_pressure_term(_feedback_scope),
    do: "validation_refresh_pressure_penalty"

  defp validation_refresh_scored_pressure?(risk, "model_acceptance"),
    do:
      risk["feedback_scope"] == "model_acceptance" or risk["type"] == "model_acceptance_pressure"

  defp validation_refresh_scored_pressure?(risk, "validation_safety_case"),
    do:
      risk["feedback_scope"] == "validation_safety_case" or
        risk["type"] == "validation_safety_case_pressure"

  defp validation_refresh_scored_pressure?(risk, "schema_validation"),
    do:
      risk["feedback_scope"] == "schema_validation" or
        risk["type"] == "schema_validation_pressure"

  defp validation_refresh_scored_pressure?(risk, "refresh_budget"),
    do: risk["feedback_scope"] == "refresh_budget" or risk["type"] == "refresh_budget_pressure"

  defp validation_refresh_scored_pressure?(risk, "refresh_freshness"),
    do:
      risk["feedback_scope"] == "refresh_freshness" or
        risk["type"] == "refresh_freshness_pressure"

  defp validation_refresh_scored_pressure?(risk, _feedback_scope),
    do: validation_refresh_pressure?(risk)

  defp validation_refresh_family_pressure?(risk) do
    validation_refresh_pressure?(risk) or
      validation_refresh_scored_pressure?(risk, "model_acceptance") or
      validation_refresh_scored_pressure?(risk, "validation_safety_case") or
      validation_refresh_scored_pressure?(risk, "schema_validation") or
      validation_refresh_scored_pressure?(risk, "refresh_budget") or
      validation_refresh_scored_pressure?(risk, "refresh_freshness")
  end

  defp validation_refresh_pressure?(risk) do
    validation_refresh_source_report_pressure?(risk, "schema_validation")
  end

  defp validation_refresh_source_report_pressure?(risk, "schema_validation"),
    do: schema_validation_source_report_pressure?(risk)

  defp validation_refresh_source_report_pressure?(_risk, _feedback_scope), do: false

  defp schema_validation_source_report_pressure?(%{"type" => "quality_gate_pressure"} = risk) do
    risk["schema_validation_import_blocked"] == true or
      is_map(risk["schema_validation_status_counts"]) or
      risk["failed_schema_validation_quality_gate_row_ids"] not in [nil, []]
  end

  defp schema_validation_source_report_pressure?(
         %{"type" => "operational_readiness_pressure"} = risk
       ) do
    risk["schema_validation_import_blocked"] == true or
      risk["schema_validation_row_count"] not in [nil, 0] or
      risk["schema_validation_fail_count"] not in [nil, 0] or
      risk["schema_validation_error_count"] not in [nil, 0] or
      risk["schema_validation_warning_count"] not in [nil, 0] or
      risk["schema_validation_remediation_count"] not in [nil, 0] or
      is_map(risk["schema_validation_status_counts"]) or
      risk["failed_schema_validation_quality_gate_row_ids"] not in [nil, []]
  end

  defp schema_validation_source_report_pressure?(_risk), do: false
end
