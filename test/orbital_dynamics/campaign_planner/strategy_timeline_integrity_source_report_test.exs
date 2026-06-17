Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyTimelineIntegritySourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.{CandidateRefresh, Schema, Timeline}

  test "strategy carries mission-state timeline integrity reports into branch refresh requests" do
    integrity_report =
      Timeline.integrity_report(
        [
          %{
            id: :cmd_main,
            type: :command,
            starts_at_s: 10.0,
            ends_at_s: 20.0,
            dependencies: [:missing_gate],
            dependency_timeline_ids: [
              :"timeline:missing_gate",
              :"timeline:health_gate",
              :"timeline:health_gate"
            ],
            metadata: %{timeline_id: :"timeline:command:dss_14:10.0"}
          },
          %{
            id: :dl_conflict,
            type: :downlink,
            starts_at_s: 12.0,
            ends_at_s: 18.0,
            exclusive_with: [:cmd_main],
            exclusive_with_timeline_ids: [
              :"timeline:command:dss_14:10.0",
              :"timeline:command:dss_14:10.0"
            ],
            metadata: %{timeline_id: :"timeline:downlink:12.0"}
          }
        ],
        source: "campaign_planner_integrity_inputs"
      )
      |> Map.put("provenance", %{"trust_boundary" => "direct_timeline_integrity_boundary"})

    wrapped_report =
      integrity_report
      |> Map.delete("provenance")
      |> Map.put("provenance", %{"trust_boundary" => "wrapped_timeline_integrity_boundary"})

    result_wrapped_report =
      integrity_report
      |> Map.delete("provenance")
      |> Map.put("provenance", %{
        "trust_boundary" => "result_wrapped_timeline_integrity_boundary"
      })

    canonical_report =
      integrity_report
      |> Map.delete("provenance")
      |> Map.put("provenance", %{"trust_boundary" => "canonical_timeline_integrity_boundary"})

    assert {:ok, %{"schema_contract" => "timeline_integrity_report.v1"}} =
             Schema.validate_artifact(integrity_report)

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_timeline_integrity_report", integrity_report)
      |> Map.put("timeline_integrity_report", canonical_report)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "timeline_integrity_report" => wrapped_report,
        "provenance" => %{"trust_boundary" => "wrapped_timeline_integrity_artifact_boundary"}
      })
      |> Map.put(:result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "timeline_integrity_report" => result_wrapped_report,
        "provenance" => %{
          "trust_boundary" => "result_wrapped_timeline_integrity_artifact_boundary"
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
          "mission_state.source_timeline_integrity_report",
          "mission_state.timeline_integrity_report",
          "mission_state.source_result_artifact.timeline_integrity_report",
          "mission_state.result_artifact.timeline_integrity_report"
        ] do
      assert source_path in source_report_input_paths

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 8,
             "source_report_timeline_integrity_issue_count" => 28,
             "source_report_timeline_integrity_review_count" => 8,
             "source_report_timeline_integrity_dependency_issue_count" => 16,
             "source_report_timeline_integrity_exclusivity_issue_count" => 12,
             "source_report_timeline_integrity_status_counts" => %{
               "review_required" => 8
             },
             "source_report_timeline_integrity_required_operator_action_counts" => %{
               "review_timeline_integrity" => 8
             },
             "source_report_timeline_integrity_review_activity_id_counts" => %{
               "cmd_main" => 4,
               "dl_conflict" => 4
             },
             "source_report_timeline_integrity_review_timeline_id_counts" => %{
               "timeline:command:dss_14:10.0" => 4,
               "timeline:downlink:12.0" => 4
             },
             "source_report_timeline_integrity_missing_dependency_activity_id_counts" => %{
               "missing_gate" => 4
             },
             "source_report_timeline_integrity_missing_dependency_timeline_id_counts" => %{
               "timeline:health_gate" => 4,
               "timeline:missing_gate" => 4
             },
             "source_report_timeline_integrity_exclusivity_violation_activity_id_counts" => %{
               "cmd_main" => 4
             },
             "source_report_timeline_integrity_exclusivity_violation_timeline_id_counts" => %{
               "timeline:command:dss_14:10.0" => 4
             }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "source" =>
               "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_integrity_report",
             "contract" => "timeline_integrity_report.v1",
             "source_report_count" => 4,
             "source_report_row_count" => 8,
             "source_report_paths" => integrity_source_paths,
             "timeline_integrity_issue_count" => 28,
             "timeline_integrity_review_count" => 8,
             "dependency_issue_count" => 16,
             "exclusivity_issue_count" => 12,
             "required_operator_action_counts" => %{"review_timeline_integrity" => 8},
             "review_activity_id_counts" => %{"cmd_main" => 4, "dl_conflict" => 4},
             "review_timeline_id_counts" => %{
               "timeline:command:dss_14:10.0" => 4,
               "timeline:downlink:12.0" => 4
             },
             "missing_dependency_activity_id_counts" => %{"missing_gate" => 4},
             "missing_dependency_timeline_id_counts" => %{
               "timeline:health_gate" => 4,
               "timeline:missing_gate" => 4
             },
             "exclusivity_violation_activity_id_counts" => %{
               "cmd_main" => 4
             },
             "exclusivity_violation_timeline_id_counts" => %{
               "timeline:command:dss_14:10.0" => 4
             },
             "trust_boundary_status" => "declared",
             "branch_local_timeline_integrity_pressure" => true,
             "branch_local_timeline_integrity_review_pressure" => true,
             "branch_local_dependency_integrity_pressure" => true,
             "branch_local_exclusivity_integrity_pressure" => true,
             "assumptions" => %{
               "replay_scope" => "timeline_integrity_candidate_source_report_summary_only",
               "timeline_mutation" => "not_performed_by_summary",
               "candidate_selection" => "not_performed_by_summary",
               "import_approval" => "not_granted_by_timeline_integrity_replay_summary"
             }
           } = CandidateRefresh.timeline_integrity_replay_summary(candidate_source)

    for source_path <- [
          "mission_state.source_timeline_integrity_report",
          "mission_state.timeline_integrity_report",
          "mission_state.source_result_artifact.timeline_integrity_report",
          "mission_state.result_artifact.timeline_integrity_report"
        ] do
      assert source_path in integrity_source_paths
    end

    timeline_integrity_pressure_count =
      Enum.count(
        urgent["risk_indicators"],
        &(&1["type"] == "timeline_integrity_issue" and
            &1["feedback_source"] == "candidate_source.timeline_integrity_replay_summary")
      )

    assert timeline_integrity_pressure_count == 1

    assert Enum.any?(
             urgent["risk_indicators"],
             &(&1["type"] == "timeline_integrity_issue" and
                 &1["timeline_integrity_issue_count"] == 28 and
                 &1["timeline_integrity_review_count"] == 8 and
                 &1["dependency_issue_count"] == 16 and
                 &1["exclusivity_issue_count"] == 12 and
                 &1["timeline_integrity_issue_types"] == [
                   "duplicate_dependency_timeline",
                   "duplicate_exclusivity_timeline",
                   "exclusivity_overlap",
                   "missing_dependency_activity",
                   "missing_dependency_timeline"
                 ] and
                 &1["review_activity_ids"] == ["cmd_main", "dl_conflict"] and
                 &1["missing_dependency_activity_ids"] == ["missing_gate"] and
                 &1["missing_dependency_timeline_ids"] == [
                   "timeline:health_gate",
                   "timeline:missing_gate"
                 ] and
                 &1["exclusivity_violation_activity_ids"] == ["cmd_main"] and
                 &1["exclusivity_violation_timeline_ids"] == [
                   "timeline:command:dss_14:10.0"
                 ] and
                 &1["feedback_scope"] == "timeline_integrity")
           )

    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    assert urgent["score_terms"]["timeline_integrity_pressure_penalty"] ==
             -timeline_integrity_pressure_count * risk_weight

    assert "timeline_integrity_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == urgent["branch_id"] and
                 &1["term_key"] == "timeline_integrity_pressure_penalty" and
                 &1["value"] < 0.0)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch pressure from timeline integrity reports" do
    integrity_report = fn activity_id, missing_activity_id, source, trust_boundary ->
      Timeline.integrity_report(
        [
          %{
            id: activity_id,
            type: :command,
            starts_at_s: 10.0,
            ends_at_s: 20.0,
            dependency_activity_ids: [missing_activity_id],
            metadata: %{timeline_id: :"timeline:#{activity_id}"}
          }
        ],
        source: source
      )
      |> Map.put("provenance", %{"trust_boundary" => trust_boundary})
    end

    prior_integrity_report =
      integrity_report.(
        :cmd_prior_integrity,
        :missing_prior_gate,
        "prior.timeline_integrity",
        "prior_integrity_boundary"
      )

    prior_wrapped_report =
      integrity_report.(
        :cmd_prior_wrapped_integrity,
        :missing_prior_wrapped_gate,
        "prior.wrapped_timeline_integrity",
        "prior_wrapped_integrity_boundary"
      )
      |> Map.delete("provenance")

    prior_bare_report =
      integrity_report.(
        :cmd_prior_bare_integrity,
        :missing_prior_bare_gate,
        "prior.bare_timeline_integrity",
        "prior_bare_integrity_boundary"
      )

    duplicate_direct_report =
      integrity_report.(
        :cmd_duplicate_integrity,
        :missing_duplicate_direct_gate,
        "prior.duplicate_direct_timeline_integrity",
        "duplicate_direct_integrity_boundary"
      )

    duplicate_wrapped_report =
      integrity_report.(
        :cmd_duplicate_integrity,
        :missing_duplicate_wrapped_gate,
        "prior.duplicate_wrapped_timeline_integrity",
        "duplicate_wrapped_integrity_boundary"
      )
      |> Map.delete("provenance")

    mission_integrity_report =
      integrity_report.(
        :cmd_live_integrity,
        :missing_live_gate,
        "mission.timeline_integrity",
        "mission_integrity_boundary"
      )
      |> Map.delete("provenance")

    prior_plan =
      base_plan(%{
        "source_timeline_integrity_report" => [prior_integrity_report, duplicate_direct_report],
        "source_result_artifact" => %{
          "schema_contract" => "result_artifact.v1",
          "artifact_type" => "prior_plan_result_artifact",
          "timeline_integrity_report" => [prior_wrapped_report, duplicate_wrapped_report],
          "provenance" => %{"trust_boundary" => "prior_wrapped_integrity_artifact_boundary"}
        },
        "result_artifact" => prior_bare_report
      })

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "timeline_integrity_report" => mission_integrity_report,
        "provenance" => %{"trust_boundary" => "mission_integrity_artifact_boundary"}
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    prior_branch =
      branch(artifact, "derived_timeline_integrity_pressure_cmd_prior_integrity")

    assert %{
             "type" => "timeline_integrity_feedback",
             "activity_id" => "cmd_prior_integrity",
             "missing_dependency_activity_ids" => ["missing_prior_gate"],
             "feedback_source" => "prior_plan.source_timeline_integrity_report[0].rows",
             "feedback_scope" => "timeline_integrity",
             "trust_boundary" => "prior_integrity_boundary",
             "derivation_reasons" => ["timeline_integrity_report_pressure"]
           } = List.first(prior_branch["events"])

    assert Enum.any?(
             prior_branch["risk_indicators"],
             &(&1["type"] == "timeline_integrity_issue" and
                 &1["severity"] == "high" and
                 &1["missing_dependency_activity_ids"] == ["missing_prior_gate"] and
                 &1["feedback_source"] == "prior_plan.source_timeline_integrity_report[0].rows")
           )

    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    timeline_integrity_pressure_count =
      Enum.count(prior_branch["risk_indicators"], &(&1["type"] == "timeline_integrity_issue"))

    assert timeline_integrity_pressure_count == 1

    assert prior_branch["score_terms"]["timeline_integrity_pressure_penalty"] ==
             -timeline_integrity_pressure_count * risk_weight

    assert prior_branch["score_terms"]["timeline_pressure_penalty"] == 0.0

    assert prior_branch["score_terms"]["risk_penalty"] ==
             -(length(prior_branch["risk_indicators"]) - timeline_integrity_pressure_count) *
               risk_weight

    assert "timeline_integrity_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert "timeline_pressure_penalty" in artifact["score_term_report"]["score_term_keys"]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == "derived_timeline_integrity_pressure_cmd_prior_integrity" and
                 &1["term_key"] == "timeline_integrity_pressure_penalty" and &1["value"] < 0.0)
           )

    prior_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(
        &(&1["branch_id"] == "derived_timeline_integrity_pressure_cmd_prior_integrity")
      )

    assert prior_row["branch_timeline_integrity_activity_ids"] == ["cmd_prior_integrity"]
    assert prior_row["branch_missing_dependency_activity_ids"] == ["missing_prior_gate"]
    assert prior_row["branch_feedback_scopes"] == ["timeline_integrity"]

    prior_wrapped_branch =
      branch(artifact, "derived_timeline_integrity_pressure_cmd_prior_wrapped_integrity")

    assert %{
             "activity_id" => "cmd_prior_wrapped_integrity",
             "missing_dependency_activity_ids" => ["missing_prior_wrapped_gate"],
             "feedback_source" =>
               "prior_plan.source_result_artifact.timeline_integrity_report[0].rows",
             "trust_boundary" => "prior_wrapped_integrity_artifact_boundary"
           } = List.first(prior_wrapped_branch["events"])

    prior_bare_branch =
      branch(artifact, "derived_timeline_integrity_pressure_cmd_prior_bare_integrity")

    assert %{
             "activity_id" => "cmd_prior_bare_integrity",
             "missing_dependency_activity_ids" => ["missing_prior_bare_gate"],
             "feedback_source" => "prior_plan.result_artifact.rows",
             "trust_boundary" => "prior_bare_integrity_boundary"
           } = List.first(prior_bare_branch["events"])

    duplicate_branches =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.map(& &1["branch_id"])
      |> Enum.filter(fn branch_id ->
        String.starts_with?(
          branch_id,
          "derived_timeline_integrity_pressure_cmd_duplicate_integrity"
        )
      end)

    assert length(duplicate_branches) == 2

    assert duplicate_branches
           |> Enum.uniq()
           |> length() == 2

    assert duplicate_branches
           |> Enum.map(&(artifact |> branch(&1) |> Map.get("events") |> List.first()))
           |> Enum.map(& &1["feedback_source"])
           |> Enum.sort() == [
             "prior_plan.source_result_artifact.timeline_integrity_report[1].rows",
             "prior_plan.source_timeline_integrity_report[1].rows"
           ]

    mission_branch =
      branch(artifact, "derived_timeline_integrity_pressure_cmd_live_integrity")

    assert %{
             "type" => "timeline_integrity_feedback",
             "activity_id" => "cmd_live_integrity",
             "missing_dependency_activity_ids" => ["missing_live_gate"],
             "feedback_source" =>
               "mission_state.source_result_artifact.timeline_integrity_report.rows",
             "feedback_scope" => "timeline_integrity",
             "trust_boundary" => "mission_integrity_artifact_boundary"
           } = List.first(mission_branch["events"])

    assert Enum.any?(
             mission_branch["risk_indicators"],
             &(&1["type"] == "timeline_integrity_issue" and
                 &1["missing_dependency_activity_ids"] == ["missing_live_gate"] and
                 &1["trust_boundary"] == "mission_integrity_artifact_boundary")
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end
end
