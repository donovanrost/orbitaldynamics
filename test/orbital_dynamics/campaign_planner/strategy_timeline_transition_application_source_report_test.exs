Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyTimelineTransitionApplicationSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.{CandidateRefresh, Schema, Timeline}

  test "strategy carries mission-state timeline transition-application summaries into branch refresh requests" do
    protected_source = %{
      id: :cmd_lock,
      type: :command,
      status: :planned,
      approval_status: :approved,
      locked: true,
      starts_at_s: 10.0,
      ends_at_s: 20.0,
      metadata: %{timeline_id: :"timeline:cmd_lock"}
    }

    protected_replacement = %{
      id: :cmd_lock,
      type: :command,
      status: :planned,
      approval_status: :approved,
      locked: true,
      starts_at_s: 12.0,
      ends_at_s: 22.0,
      metadata: %{timeline_id: :"timeline:cmd_lock"}
    }

    unchanged = %{
      id: :obs_keep,
      type: :observe,
      target_id: :target_a,
      starts_at_s: 30.0,
      ends_at_s: 40.0,
      metadata: %{timeline_id: :"timeline:obs_keep"}
    }

    added = %{
      id: :new_cmd,
      type: :command,
      starts_at_s: 70.0,
      ends_at_s: 80.0,
      metadata: %{timeline_id: :"timeline:new_cmd"}
    }

    direct_summary =
      [protected_source, unchanged]
      |> Timeline.transition_application_summary([protected_replacement, unchanged, added])
      |> Map.put("provenance", %{"trust_boundary" => "direct_transition_summary_boundary"})

    wrapped_summary =
      direct_summary
      |> Map.delete("provenance")
      |> Map.put("provenance", %{"trust_boundary" => "wrapped_transition_summary_boundary"})

    result_wrapped_summary =
      direct_summary
      |> Map.delete("provenance")
      |> Map.put("provenance", %{
        "trust_boundary" => "result_wrapped_transition_summary_boundary"
      })

    canonical_summary =
      direct_summary
      |> Map.delete("provenance")
      |> Map.put("provenance", %{"trust_boundary" => "canonical_transition_summary_boundary"})

    assert {:ok, %{"schema_contract" => "timeline_transition_application_summary.v1"}} =
             Schema.validate_artifact(direct_summary)

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_timeline_transition_application_summary", direct_summary)
      |> Map.put("timeline_transition_application_summary", canonical_summary)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "timeline_transition_application_summary" => wrapped_summary,
        "provenance" => %{"trust_boundary" => "wrapped_transition_summary_artifact_boundary"}
      })
      |> Map.put(:result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "timeline_transition_application_summary" => result_wrapped_summary,
        "provenance" => %{
          "trust_boundary" => "result_wrapped_transition_summary_artifact_boundary"
        }
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    urgent = branch(artifact, "urgent")

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             candidate_source = urgent["assumptions"]["candidate_source"]

    source_report_input_paths = candidate_source["source_report_input_paths"]

    for source_path <- [
          "mission_state.source_timeline_transition_application_summary",
          "mission_state.timeline_transition_application_summary",
          "mission_state.source_result_artifact.timeline_transition_application_summary",
          "mission_state.result_artifact.timeline_transition_application_summary"
        ] do
      assert source_path in source_report_input_paths

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert %{
             "source_report_count" => 4,
             "source_report_timeline_transition_application_application_count" => 12,
             "source_report_timeline_transition_application_selected_activity_count" => 8,
             "source_report_timeline_transition_application_selected_activity_id_counts" => %{
               "cmd_lock" => 4,
               "obs_keep" => 4
             },
             "source_report_timeline_transition_application_review_activity_id_counts" => %{
               "cmd_lock" => 4,
               "new_cmd" => 4
             },
             "source_report_timeline_transition_application_review_required_count" => 8,
             "source_report_timeline_transition_application_preserved_source_count" => 4,
             "source_report_timeline_transition_application_recorded_replacement_count" => 0,
             "source_report_timeline_transition_application_withheld_review_count" => 4,
             "source_report_timeline_transition_application_status_counts" => %{
               "operator_review_required" => 4,
               "source_preserved_pending_review" => 4,
               "source_unchanged" => 4
             },
             "source_report_timeline_transition_application_decision_counts" => %{
               "none" => 4,
               "preserve_source" => 4,
               "review" => 4
             },
             "source_report_timeline_transition_application_required_operator_action_counts" => %{
               "review_added_activity" => 4,
               "review_changed_protected_activity" => 4
             }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "contract" => "timeline_transition_application_summary.v1",
             "source_report_count" => 4,
             "source_application_count" => 12,
             "source_report_paths" => transition_source_paths,
             "selected_activity_count" => 8,
             "selected_activity_id_counts" => %{"cmd_lock" => 4, "obs_keep" => 4},
             "review_activity_id_counts" => %{"cmd_lock" => 4, "new_cmd" => 4},
             "review_required_count" => 8,
             "preserved_source_count" => 4,
             "recorded_replacement_count" => 0,
             "withheld_review_count" => 4,
             "application_status_counts" => %{
               "operator_review_required" => 4,
               "source_preserved_pending_review" => 4,
               "source_unchanged" => 4
             },
             "transition_decision_counts" => %{
               "none" => 4,
               "preserve_source" => 4,
               "review" => 4
             },
             "required_operator_action_counts" => %{
               "review_added_activity" => 4,
               "review_changed_protected_activity" => 4
             },
             "trust_boundary_status" => "declared",
             "branch_local_timeline_transition_application_pressure" => true,
             "branch_local_selected_activity_pressure" => true,
             "branch_local_review_required_pressure" => true,
             "branch_local_preserved_transition_pressure" => true,
             "branch_local_operator_review_pressure" => true
           } = CandidateRefresh.timeline_transition_application_replay_summary(candidate_source)

    for source_path <- [
          "mission_state.source_timeline_transition_application_summary",
          "mission_state.timeline_transition_application_summary",
          "mission_state.source_result_artifact.timeline_transition_application_summary",
          "mission_state.result_artifact.timeline_transition_application_summary"
        ] do
      assert source_path in transition_source_paths
    end

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy carries mission-state timeline transition-application reports into branch refresh requests" do
    transition_application_report =
      fn prefix,
         application_status,
         transition_decision,
         required_operator_action,
         row_overrides ->
        application =
          %{
            "id" => "timeline_application:#{prefix}",
            "rank" => 1,
            "timeline_id" => "timeline:#{prefix}",
            "application_status" => application_status,
            "transition_decision" => transition_decision,
            "required_operator_action" => required_operator_action,
            "trust_boundary" => "#{prefix}_transition_application_row_boundary"
          }
          |> Map.merge(row_overrides)

        %{
          "schema_contract" => "timeline_transition_application_report.v1",
          "model" => "artifact_only_timeline_transition_application",
          "source" => "campaign_planner_test.#{prefix}.timeline_transition_application_report",
          "applications" => [application],
          "provenance" => %{
            "trust_boundary" => "#{prefix}_transition_application_report_boundary"
          }
        }
      end

    direct_report =
      transition_application_report.("direct", "selected", "apply", "none", %{
        "selected_activity" => %{"activity_id" => "direct_selected_activity"}
      })

    canonical_report =
      transition_application_report.("canonical", "selected", "apply", "none", %{
        "selected_activity" => %{"activity_id" => "canonical_selected_activity"}
      })

    source_wrapped_report =
      transition_application_report.(
        "source_wrapped",
        "operator_review_required",
        "review",
        "review_timeline_change",
        %{
          "timeline_identity_collision" => true,
          "duplicate_timeline_identity_scope" => "source"
        }
      )

    result_wrapped_report =
      transition_application_report.(
        "result_wrapped",
        "withheld_review",
        "withhold",
        "review_duplicate_timeline_identity",
        %{
          "timeline_identity_collision" => true,
          "duplicate_timeline_identity_scope" => "replacement"
        }
      )

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_timeline_transition_application_report", direct_report)
      |> Map.put("timeline_transition_application_report", canonical_report)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "timeline_transition_application_report" =>
          Map.delete(source_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "source_wrapped_transition_application_boundary"}
      })
      |> Map.put(:result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_timeline_transition_application_report" =>
          Map.delete(result_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "result_wrapped_transition_application_boundary"}
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}]
          }
        ],
        current_epoch_s: 0.0
      )

    urgent = branch(artifact, "urgent")

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch_generated"} =
             candidate_source = urgent["assumptions"]["candidate_source"]

    for source_path <- [
          "mission_state.source_timeline_transition_application_report",
          "mission_state.timeline_transition_application_report",
          "mission_state.source_result_artifact.timeline_transition_application_report",
          "mission_state.result_artifact.source_timeline_transition_application_report"
        ] do
      assert source_path in candidate_source["source_report_input_paths"]

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert %{
             "source_report_count" => 4,
             "source_report_timeline_transition_application_application_count" => 4,
             "source_report_timeline_transition_application_selected_activity_count" => 2,
             "source_report_timeline_transition_application_selected_activity_id_counts" => %{
               "canonical_selected_activity" => 1,
               "direct_selected_activity" => 1
             },
             "source_report_timeline_transition_application_review_required_count" => 2,
             "source_report_timeline_transition_application_preserved_source_count" => 0,
             "source_report_timeline_transition_application_recorded_replacement_count" => 0,
             "source_report_timeline_transition_application_withheld_review_count" => 2,
             "source_report_timeline_transition_application_duplicate_timeline_identity_count" =>
               2,
             "source_report_timeline_transition_application_duplicate_source_timeline_identity_count" =>
               1,
             "source_report_timeline_transition_application_duplicate_replacement_timeline_identity_count" =>
               1,
             "source_report_timeline_transition_application_status_counts" => %{
               "operator_review_required" => 1,
               "selected" => 2,
               "withheld_review" => 1
             },
             "source_report_timeline_transition_application_decision_counts" => %{
               "apply" => 2,
               "review" => 1,
               "withhold" => 1
             },
             "source_report_timeline_transition_application_required_operator_action_counts" => %{
               "none" => 2,
               "review_duplicate_timeline_identity" => 1,
               "review_timeline_change" => 1
             },
             "source_report_timeline_transition_application_duplicate_timeline_identity_scope_counts" =>
               %{
                 "replacement" => 1,
                 "source" => 1
               }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "source" =>
               "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_transition_application_report",
             "contract" => "timeline_transition_application_report.v1",
             "source_report_count" => 4,
             "source_application_count" => 4,
             "source_report_paths" => transition_source_paths,
             "selected_activity_count" => 2,
             "selected_activity_id_counts" => %{
               "canonical_selected_activity" => 1,
               "direct_selected_activity" => 1
             },
             "review_required_count" => 2,
             "preserved_source_count" => 0,
             "recorded_replacement_count" => 0,
             "withheld_review_count" => 2,
             "duplicate_timeline_identity_count" => 2,
             "duplicate_source_timeline_identity_count" => 1,
             "duplicate_replacement_timeline_identity_count" => 1,
             "application_status_counts" => %{
               "operator_review_required" => 1,
               "selected" => 2,
               "withheld_review" => 1
             },
             "transition_decision_counts" => %{
               "apply" => 2,
               "review" => 1,
               "withhold" => 1
             },
             "required_operator_action_counts" => %{
               "none" => 2,
               "review_duplicate_timeline_identity" => 1,
               "review_timeline_change" => 1
             },
             "duplicate_timeline_identity_scope_counts" => %{
               "replacement" => 1,
               "source" => 1
             },
             "trust_boundary_status" => "declared",
             "trust_boundaries" => transition_trust_boundaries,
             "branch_local_timeline_transition_application_pressure" => true,
             "branch_local_selected_activity_pressure" => true,
             "branch_local_review_required_pressure" => true,
             "branch_local_preserved_transition_pressure" => false,
             "branch_local_duplicate_identity_pressure" => true,
             "branch_local_operator_review_pressure" => true,
             "assumptions" => %{
               "replay_scope" =>
                 "timeline_transition_application_candidate_source_report_summary_only",
               "timeline_application" => "not_performed_by_summary",
               "timeline_mutation" => "not_performed_by_summary",
               "candidate_selection" => "not_performed_by_summary",
               "cadence_write" => "not_performed_by_summary"
             }
           } = CandidateRefresh.timeline_transition_application_replay_summary(candidate_source)

    assert Enum.sort(transition_source_paths) == [
             "mission_state.result_artifact.source_timeline_transition_application_report",
             "mission_state.source_result_artifact.timeline_transition_application_report",
             "mission_state.source_timeline_transition_application_report",
             "mission_state.timeline_transition_application_report"
           ]

    assert Enum.sort(transition_trust_boundaries) == [
             "canonical_transition_application_report_boundary",
             "canonical_transition_application_row_boundary",
             "direct_transition_application_report_boundary",
             "direct_transition_application_row_boundary",
             "result_wrapped_transition_application_boundary",
             "result_wrapped_transition_application_row_boundary",
             "source_wrapped_transition_application_boundary",
             "source_wrapped_transition_application_row_boundary"
           ]

    transition_application_pressure_count =
      Enum.count(
        urgent["risk_indicators"],
        &(&1["type"] == "timeline_transition_application_pressure" and
            &1["feedback_source"] ==
              "candidate_source.timeline_transition_application_replay_summary")
      )

    assert transition_application_pressure_count == 1

    assert Enum.any?(
             urgent["risk_indicators"],
             &(&1["type"] == "timeline_transition_application_pressure" and
                 &1["selected_activity_ids"] == [
                   "canonical_selected_activity",
                   "direct_selected_activity"
                 ] and
                 &1["review_activity_ids"] == [] and
                 &1["review_required_count"] == 2 and
                 &1["withheld_review_count"] == 2 and
                 &1["duplicate_timeline_identity_count"] == 2 and
                 &1["feedback_scope"] == "timeline_transition_application")
           )

    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    assert urgent["score_terms"]["timeline_transition_application_pressure_penalty"] ==
             -transition_application_pressure_count * risk_weight

    assert "timeline_transition_application_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == urgent["branch_id"] and
                 &1["term_key"] == "timeline_transition_application_pressure_penalty" and
                 &1["value"] < 0.0)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy scores derived timeline transition-application pressure separately" do
    transition_application_report = %{
      "schema_contract" => "timeline_transition_application_report.v1",
      "model" => "artifact_only_timeline_transition_application",
      "source" => "campaign_planner_test.transition_application_pressure",
      "applications" => [
        %{
          "id" => "timeline_application:cmd_review",
          "rank" => 1,
          "timeline_id" => "timeline:cmd_review",
          "source_activity_id" => "cmd_review",
          "application_status" => "withheld_review",
          "transition_decision" => "withhold",
          "required_operator_action" => "review_timeline_change",
          "operator_action_reason" => "activity_locked_or_approved",
          "trust_boundary" => "transition_application_row_boundary"
        }
      ],
      "provenance" => %{"trust_boundary" => "transition_application_report_boundary"}
    }

    artifact =
      strategy(
        base_plan(%{
          "source_timeline_transition_application_report" => transition_application_report
        }),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    pressure_branch =
      Enum.find(artifact["branches"], fn branch ->
        Enum.any?(
          branch["risk_indicators"],
          &(&1["type"] == "timeline_transition_application_pressure")
        )
      end)

    assert %{"branch_id" => branch_id} = pressure_branch

    assert %{
             "type" => "timeline_transition_application_pressure",
             "activity_id" => "cmd_review",
             "timeline_id" => "timeline:cmd_review",
             "application_status" => "withheld_review",
             "transition_decision" => "withhold",
             "required_operator_action" => "review_timeline_change",
             "feedback_source" =>
               "prior_plan.source_timeline_transition_application_report.applications",
             "feedback_scope" => "timeline_transition_application",
             "trust_boundary" => "transition_application_row_boundary",
             "derivation_reasons" => ["timeline_transition_application_pressure"]
           } = List.first(pressure_branch["events"])

    transition_application_pressure_count =
      Enum.count(
        pressure_branch["risk_indicators"],
        &(&1["type"] == "timeline_transition_application_pressure")
      )

    assert transition_application_pressure_count == 1

    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    assert pressure_branch["score_terms"]["timeline_transition_application_pressure_penalty"] ==
             -transition_application_pressure_count * risk_weight

    assert pressure_branch["score_terms"]["timeline_pressure_penalty"] == 0.0

    assert pressure_branch["score_terms"]["risk_penalty"] ==
             -(length(pressure_branch["risk_indicators"]) - transition_application_pressure_count) *
               risk_weight

    assert "timeline_transition_application_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch_id and
                 &1["term_key"] == "timeline_transition_application_pressure_penalty" and
                 &1["value"] < 0.0)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
