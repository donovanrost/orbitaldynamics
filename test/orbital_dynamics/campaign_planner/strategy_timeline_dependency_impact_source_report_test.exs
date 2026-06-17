Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyTimelineDependencyImpactSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.{CandidateRefresh, Schema, Timeline}

  test "strategy carries mission-state timeline dependency-impact summaries into branch refresh requests" do
    source = [
      %{
        id: :health_gate,
        type: :health_check,
        starts_at_s: 0.0,
        ends_at_s: 10.0
      },
      %{
        id: :cmd_combo,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependency_timeline_ids: [:"timeline:health_check:0.0"],
        exclusive_with: [:health_gate]
      }
    ]

    replacement = [
      %{
        id: :health_gate,
        type: :health_check,
        starts_at_s: 5.0,
        ends_at_s: 15.0
      },
      %{
        id: :cmd_combo,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependency_timeline_ids: [:"timeline:health_check:0.0"],
        exclusive_with: [:health_gate]
      }
    ]

    direct_summary =
      source
      |> Timeline.dependency_impact_summary(replacement)
      |> Map.put("provenance", %{"trust_boundary" => "direct_dependency_impact_boundary"})

    wrapped_summary =
      direct_summary
      |> Map.delete("provenance")
      |> Map.put("provenance", %{"trust_boundary" => "wrapped_dependency_impact_boundary"})

    result_wrapped_summary =
      direct_summary
      |> Map.delete("provenance")
      |> Map.put("provenance", %{
        "trust_boundary" => "result_wrapped_dependency_impact_boundary"
      })

    canonical_summary =
      direct_summary
      |> Map.delete("provenance")
      |> Map.put("provenance", %{"trust_boundary" => "canonical_dependency_impact_boundary"})

    assert {:ok, %{"schema_contract" => "timeline_dependency_impact_summary.v1"}} =
             Schema.validate_artifact(direct_summary)

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_timeline_dependency_impact_summary", direct_summary)
      |> Map.put("timeline_dependency_impact_summary", canonical_summary)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "timeline_dependency_impact_summary" => wrapped_summary,
        "provenance" => %{"trust_boundary" => "wrapped_dependency_impact_artifact_boundary"}
      })
      |> Map.put(:result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "timeline_dependency_impact_summary" => result_wrapped_summary,
        "provenance" => %{
          "trust_boundary" => "result_wrapped_dependency_impact_artifact_boundary"
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
          "mission_state.source_timeline_dependency_impact_summary",
          "mission_state.timeline_dependency_impact_summary",
          "mission_state.source_result_artifact.timeline_dependency_impact_summary",
          "mission_state.result_artifact.timeline_dependency_impact_summary"
        ] do
      assert source_path in source_report_input_paths

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 8,
             "source_report_timeline_dependency_impact_row_count" => 8,
             "source_report_timeline_dependency_impact_changed_source_activity_count" => 4,
             "source_report_timeline_dependency_impact_changed_source_timeline_count" => 4,
             "source_report_timeline_dependency_impact_dependent_activity_count" => 8,
             "source_report_timeline_dependency_impact_source_dependent_activity_count" => 4,
             "source_report_timeline_dependency_impact_replacement_dependent_activity_count" => 4,
             "source_report_timeline_dependency_impact_status_counts" => %{
               "review_required" => 8
             },
             "source_report_timeline_dependency_impact_scope_counts" => %{
               "replacement" => 4,
               "source" => 4
             },
             "source_report_timeline_dependency_impact_required_operator_action_counts" => %{
               "review_timeline_integrity" => 8
             },
             "source_report_timeline_dependency_impact_impacted_source_activity_id_counts" => %{
               "health_gate" => 4
             },
             "source_report_timeline_dependency_impact_impacted_source_timeline_id_counts" => %{
               "timeline:health_check:0.0" => 4
             },
             "source_report_timeline_dependency_impact_impacted_dependency_timeline_id_counts" =>
               %{
                 "timeline:health_check:0.0" => 8
               },
             "source_report_timeline_dependency_impact_impacted_exclusive_activity_id_counts" =>
               %{
                 "health_gate" => 8
               },
             "source_report_timeline_dependency_impact_dependent_activity_id_counts" => %{
               "cmd_combo" => 8
             },
             "source_report_timeline_dependency_impact_dependent_timeline_id_counts" => %{
               "timeline:command:20.0" => 8
             }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "source" =>
               "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_dependency_impact_summary",
             "contract" => "timeline_dependency_impact_summary.v1",
             "source_report_count" => 4,
             "source_report_row_count" => 8,
             "source_report_paths" => dependency_source_paths,
             "changed_source_activity_count" => 4,
             "changed_source_timeline_count" => 4,
             "dependency_impact_status_counts" => %{"review_required" => 8},
             "dependency_impact_scope_counts" => %{"replacement" => 4, "source" => 4},
             "required_operator_action_counts" => %{"review_timeline_integrity" => 8},
             "impacted_source_activity_id_counts" => %{"health_gate" => 4},
             "impacted_source_timeline_id_counts" => %{"timeline:health_check:0.0" => 4},
             "impacted_dependency_activity_id_counts" => %{},
             "impacted_dependency_timeline_id_counts" => %{
               "timeline:health_check:0.0" => 8
             },
             "impacted_exclusive_activity_id_counts" => %{"health_gate" => 8},
             "impacted_exclusive_timeline_id_counts" => %{},
             "dependent_activity_id_counts" => %{"cmd_combo" => 8},
             "dependent_timeline_id_counts" => %{"timeline:command:20.0" => 8},
             "trust_boundary_status" => "declared",
             "branch_local_timeline_dependency_impact_pressure" => true,
             "branch_local_changed_source_pressure" => true,
             "branch_local_dependency_pressure" => true,
             "branch_local_exclusivity_pressure" => true,
             "branch_local_dependent_activity_pressure" => true,
             "branch_local_operator_review_pressure" => true,
             "assumptions" => %{
               "replay_scope" =>
                 "timeline_dependency_impact_candidate_source_report_summary_only",
               "timeline_mutation" => "not_performed_by_summary",
               "candidate_selection" => "not_performed_by_summary",
               "import_approval" => "not_granted_by_timeline_dependency_impact_replay_summary"
             }
           } = CandidateRefresh.timeline_dependency_impact_replay_summary(candidate_source)

    for source_path <- [
          "mission_state.source_timeline_dependency_impact_summary",
          "mission_state.timeline_dependency_impact_summary",
          "mission_state.source_result_artifact.timeline_dependency_impact_summary",
          "mission_state.result_artifact.timeline_dependency_impact_summary"
        ] do
      assert source_path in dependency_source_paths
    end

    timeline_dependency_impact_pressure_count =
      Enum.count(
        urgent["risk_indicators"],
        &(&1["type"] == "timeline_dependency_impact" and
            &1["feedback_source"] ==
              "candidate_source.timeline_dependency_impact_replay_summary")
      )

    assert timeline_dependency_impact_pressure_count == 1

    assert Enum.any?(
             urgent["risk_indicators"],
             &(&1["type"] == "timeline_dependency_impact" and
                 &1["impacted_source_activity_ids"] == ["health_gate"] and
                 &1["impacted_source_timeline_ids"] == ["timeline:health_check:0.0"] and
                 &1["impacted_dependency_timeline_ids"] == [
                   "timeline:health_check:0.0"
                 ] and
                 &1["impacted_exclusive_with_activity_ids"] == ["health_gate"] and
                 &1["dependent_activity_ids"] == ["cmd_combo"] and
                 &1["feedback_scope"] == "timeline_dependency_impact")
           )

    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    assert urgent["score_terms"]["timeline_dependency_impact_pressure_penalty"] ==
             -timeline_dependency_impact_pressure_count * risk_weight

    assert "timeline_dependency_impact_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == urgent["branch_id"] and
                 &1["term_key"] == "timeline_dependency_impact_pressure_penalty" and
                 &1["value"] < 0.0)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch pressure from timeline dependency-impact summaries" do
    source = [
      %{id: :health_gate, type: :health_check, starts_at_s: 0.0, ends_at_s: 10.0},
      %{
        id: :cmd_combo,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependency_timeline_ids: [:"timeline:health_check:0.0"],
        exclusive_with: [:health_gate]
      }
    ]

    replacement = [
      %{id: :health_gate, type: :health_check, starts_at_s: 5.0, ends_at_s: 15.0},
      %{
        id: :cmd_combo,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependency_timeline_ids: [:"timeline:health_check:0.0"],
        exclusive_with: [:health_gate]
      }
    ]

    direct_summary =
      source
      |> Timeline.dependency_impact_summary(replacement)
      |> Map.put("provenance", %{"trust_boundary" => "prior_dependency_impact_boundary"})

    wrapped_summary = Map.delete(direct_summary, "provenance")

    prior_plan =
      base_plan(%{"source_timeline_dependency_impact_summary" => direct_summary})

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "timeline_dependency_impact_summary" => wrapped_summary,
        "provenance" => %{"trust_boundary" => "mission_dependency_impact_artifact_boundary"}
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    dependency_branch_ids =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.map(& &1["branch_id"])
      |> Enum.filter(
        &String.starts_with?(&1, "derived_timeline_dependency_impact_pressure_cmd_combo")
      )

    assert length(dependency_branch_ids) == 4
    assert length(Enum.uniq(dependency_branch_ids)) == 4

    dependency_branches =
      Enum.map(dependency_branch_ids, fn branch_id ->
        {branch_id, branch(artifact, branch_id)}
      end)

    {prior_source_branch_id, prior_source_branch} =
      Enum.find_value(dependency_branches, fn {branch_id, candidate_branch} ->
        event = List.first(candidate_branch["events"])

        if event["feedback_source"] ==
             "prior_plan.source_timeline_dependency_impact_summary.dependency_impact_rows" and
             event["dependency_impact_scope"] == "source" do
          {branch_id, candidate_branch}
        end
      end)

    assert %{
             "type" => "timeline_dependency_impact_pressure",
             "activity_id" => "cmd_combo",
             "dependency_impact_scope" => "source",
             "impacted_dependency_timeline_ids" => ["timeline:health_check:0.0"],
             "feedback_scope" => "timeline_dependency_impact",
             "trust_boundary" => "prior_dependency_impact_boundary",
             "derivation_reasons" => ["timeline_dependency_impact_summary_pressure"]
           } = List.first(prior_source_branch["events"])

    assert Enum.any?(
             prior_source_branch["risk_indicators"],
             &(&1["type"] == "timeline_dependency_impact" and &1["severity"] == "high" and
                 &1["impacted_dependency_timeline_ids"] == ["timeline:health_check:0.0"])
           )

    assert_timeline_dependency_impact_pressure_score_terms(prior_source_branch, artifact)

    prior_source_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == prior_source_branch_id))

    assert prior_source_row["branch_timeline_dependency_impact_activity_ids"] == ["cmd_combo"]
    assert prior_source_row["branch_timeline_dependency_impact_scopes"] == ["source"]

    assert prior_source_row["branch_impacted_dependency_timeline_ids"] == [
             "timeline:health_check:0.0"
           ]

    dependency_review_row =
      artifact["operator_review_package"]["rows"]
      |> Enum.find(
        &(&1["review_type"] == "strategy_tradeoff" and
            &1["branch_id"] == prior_source_branch_id and
            &1["source"] == "campaign_strategy.branch_comparison_report.rows")
      )

    assert dependency_review_row["branch_timeline_dependency_impact_activity_ids"] == [
             "cmd_combo"
           ]

    assert dependency_review_row["branch_timeline_dependency_impact_scopes"] == ["source"]

    assert dependency_review_row["branch_impacted_dependency_timeline_ids"] == [
             "timeline:health_check:0.0"
           ]

    assert get_in(dependency_review_row, [
             "source_branch_comparison",
             "branch_impacted_dependency_timeline_ids"
           ]) == ["timeline:health_check:0.0"]

    dependency_import_row =
      artifact["cadence_import_manifest"]["rows"]
      |> Enum.find(
        &(&1["source_review_type"] == "strategy_branch_comparison" and
            &1["branch_id"] == prior_source_branch_id)
      )

    assert dependency_import_row["branch_timeline_dependency_impact_activity_ids"] == [
             "cmd_combo"
           ]

    assert dependency_import_row["branch_timeline_dependency_impact_scopes"] == ["source"]

    assert dependency_import_row["branch_impacted_dependency_timeline_ids"] == [
             "timeline:health_check:0.0"
           ]

    assert get_in(dependency_import_row, [
             "source_branch_comparison",
             "branch_impacted_dependency_timeline_ids"
           ]) == ["timeline:health_check:0.0"]

    mission_branch =
      Enum.find_value(dependency_branches, fn {_branch_id, candidate_branch} ->
        event = List.first(candidate_branch["events"])

        if event["feedback_source"] ==
             "mission_state.source_result_artifact.timeline_dependency_impact_summary.dependency_impact_rows" and
             event["dependency_impact_scope"] == "replacement" do
          candidate_branch
        end
      end)

    assert %{
             "type" => "timeline_dependency_impact_pressure",
             "activity_id" => "cmd_combo",
             "dependency_impact_scope" => "replacement",
             "feedback_scope" => "timeline_dependency_impact",
             "trust_boundary" => "mission_dependency_impact_artifact_boundary"
           } = List.first(mission_branch["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp assert_timeline_dependency_impact_pressure_score_terms(branch, artifact) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    timeline_dependency_impact_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &(&1["type"] == "timeline_dependency_impact")
      )

    assert timeline_dependency_impact_pressure_count == 1

    assert branch["score_terms"]["timeline_dependency_impact_pressure_penalty"] ==
             -timeline_dependency_impact_pressure_count * risk_weight

    assert branch["score_terms"]["timeline_pressure_penalty"] == 0.0

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) - timeline_dependency_impact_pressure_count) *
               risk_weight

    assert "timeline_dependency_impact_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "timeline_dependency_impact_pressure_penalty" and
                 &1["value"] < 0.0)
           )
  end
end
