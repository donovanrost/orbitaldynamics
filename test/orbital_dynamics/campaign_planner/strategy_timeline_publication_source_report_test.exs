Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyTimelinePublicationSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.{CandidateRefresh, Schema, Timeline}

  test "strategy derives branch pressure from timeline publication summaries" do
    source = [
      %{id: :health_gate, type: :health_check, starts_at_s: 0.0, ends_at_s: 10.0},
      %{
        id: :cmd_main,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependencies: [:health_gate]
      }
    ]

    replacement = [
      %{id: :health_gate, type: :health_check, starts_at_s: 5.0, ends_at_s: 15.0},
      %{
        id: :cmd_main,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependencies: [:health_gate]
      }
    ]

    dependency_impact = Timeline.dependency_impact_summary(source, replacement)
    timeline_diff_summary = Timeline.diff_summary(source, replacement)

    direct_summary =
      %{
        "schema_contract" => "operational_timeline_report.v1",
        "id" => "timeline:published_plan:v2"
      }
      |> Timeline.publication_summary(
        publication_sequence: 7,
        publication_authority: :mission_operations,
        supersedes_artifact_ids: ["timeline:published_plan:v1"],
        downstream_product_ids: ["operator_review:plan:v1", "cadence_import:plan:v1"],
        dependency_impact_summary: dependency_impact,
        timeline_diff_summary: timeline_diff_summary
      )
      |> Map.put("provenance", %{"trust_boundary" => "prior_publication_boundary"})

    bare_summary =
      direct_summary
      |> Map.delete("provenance")
      |> Map.put("provenance", %{"trust_boundary" => "bare_publication_boundary"})

    wrapped_summary = Map.delete(direct_summary, "provenance")

    assert {:ok, %{"schema_contract" => "timeline_publication_summary.v1"}} =
             Schema.validate_artifact(direct_summary)

    prior_plan =
      base_plan(%{
        "source_timeline_publication_summary" => [direct_summary],
        "source_result_artifact" => bare_summary
      })

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "timeline_publication_summary" => wrapped_summary,
        "provenance" => %{"trust_boundary" => "mission_publication_artifact_boundary"}
      })

    artifact =
      strategy(prior_plan,
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    publication_branch_ids =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.map(& &1["branch_id"])
      |> Enum.filter(&String.starts_with?(&1, "derived_timeline_publication_pressure_"))

    assert length(publication_branch_ids) == 3
    assert length(Enum.uniq(publication_branch_ids)) == 3

    publication_branches =
      Enum.map(publication_branch_ids, fn branch_id ->
        {branch_id, branch(artifact, branch_id)}
      end)

    {prior_source_branch_id, prior_source_branch} =
      Enum.find_value(publication_branches, fn {branch_id, candidate_branch} ->
        event = List.first(candidate_branch["events"])

        if event["feedback_source"] == "prior_plan.source_timeline_publication_summary[0]" do
          {branch_id, candidate_branch}
        end
      end)

    assert %{
             "type" => "timeline_publication_pressure",
             "publication_id" =>
               "timeline_publication:7:timeline:published_plan:v2:timeline:published_plan:v1",
             "publication_status" => "published_with_downstream_invalidations",
             "downstream_invalidation_status" => "invalidated",
             "dependency_impact_status" => "review_required",
             "invalidated_downstream_product_ids" => [
               "cadence_import:plan:v1",
               "operator_review:plan:v1"
             ],
             "downstream_invalidation_reasons" => ["dependency_impact_review_required"],
             "changed_fields" => ["timeline_presence"],
             "review_timeline_ids" => [
               "timeline:health_check:0.0",
               "timeline:health_check:5.0"
             ],
             "feedback_scope" => "timeline_publication",
             "trust_boundary" => "prior_publication_boundary",
             "derivation_reasons" => ["timeline_publication_summary_pressure"],
             "assumptions" => %{
               "publication_execution" => "not_performed_by_strategy_branch",
               "notification_delivery" => "not_performed_by_strategy_branch",
               "operator_authority" => "not_granted_by_strategy_branch",
               "import_approval" => "not_granted_by_strategy_branch"
             }
           } = List.first(prior_source_branch["events"])

    assert Enum.any?(
             prior_source_branch["risk_indicators"],
             &(&1["type"] == "timeline_publication_pressure" and &1["severity"] == "high" and
                 &1["publication_status"] == "published_with_downstream_invalidations")
           )

    assert_timeline_publication_pressure_score_terms(prior_source_branch, artifact)

    prior_source_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == prior_source_branch_id))

    assert prior_source_row["branch_timeline_publication_statuses"] == [
             "published_with_downstream_invalidations"
           ]

    assert prior_source_row[
             "branch_timeline_publication_downstream_invalidation_statuses"
           ] == ["invalidated"]

    assert prior_source_row[
             "branch_timeline_publication_invalidated_downstream_product_ids"
           ] == ["cadence_import:plan:v1", "operator_review:plan:v1"]

    assert prior_source_row["branch_timeline_publication_changed_fields"] == [
             "timeline_presence"
           ]

    assert prior_source_row["branch_timeline_publication_review_timeline_ids"] == [
             "timeline:health_check:0.0",
             "timeline:health_check:5.0"
           ]

    publication_review_row =
      artifact["operator_review_package"]["rows"]
      |> Enum.find(
        &(&1["review_type"] == "strategy_tradeoff" and
            &1["branch_id"] == prior_source_branch_id and
            &1["source"] == "campaign_strategy.branch_comparison_report.rows")
      )

    assert publication_review_row["branch_timeline_publication_ids"] == [
             "timeline_publication:7:timeline:published_plan:v2:timeline:published_plan:v1"
           ]

    assert publication_review_row[
             "branch_timeline_publication_downstream_invalidation_statuses"
           ] == ["invalidated"]

    assert publication_review_row[
             "branch_timeline_publication_invalidated_downstream_product_ids"
           ] == ["cadence_import:plan:v1", "operator_review:plan:v1"]

    assert publication_review_row["branch_timeline_publication_review_timeline_ids"] == [
             "timeline:health_check:0.0",
             "timeline:health_check:5.0"
           ]

    assert get_in(publication_review_row, [
             "source_branch_comparison",
             "branch_timeline_publication_review_timeline_ids"
           ]) == ["timeline:health_check:0.0", "timeline:health_check:5.0"]

    publication_import_row =
      artifact["cadence_import_manifest"]["rows"]
      |> Enum.find(
        &(&1["source_review_type"] == "strategy_branch_comparison" and
            &1["branch_id"] == prior_source_branch_id)
      )

    assert publication_import_row["branch_timeline_publication_ids"] == [
             "timeline_publication:7:timeline:published_plan:v2:timeline:published_plan:v1"
           ]

    assert publication_import_row[
             "branch_timeline_publication_downstream_invalidation_statuses"
           ] == ["invalidated"]

    assert publication_import_row[
             "branch_timeline_publication_invalidated_downstream_product_ids"
           ] == ["cadence_import:plan:v1", "operator_review:plan:v1"]

    assert publication_import_row["branch_timeline_publication_review_timeline_ids"] == [
             "timeline:health_check:0.0",
             "timeline:health_check:5.0"
           ]

    assert get_in(publication_import_row, [
             "source_branch_comparison",
             "branch_timeline_publication_review_timeline_ids"
           ]) == ["timeline:health_check:0.0", "timeline:health_check:5.0"]

    bare_branch =
      Enum.find_value(publication_branches, fn {_branch_id, candidate_branch} ->
        event = List.first(candidate_branch["events"])

        if event["feedback_source"] == "prior_plan.source_result_artifact" do
          candidate_branch
        end
      end)

    assert %{
             "type" => "timeline_publication_pressure",
             "feedback_scope" => "timeline_publication",
             "trust_boundary" => "bare_publication_boundary"
           } = List.first(bare_branch["events"])

    mission_branch =
      Enum.find_value(publication_branches, fn {_branch_id, candidate_branch} ->
        event = List.first(candidate_branch["events"])

        if event["feedback_source"] ==
             "mission_state.source_result_artifact.timeline_publication_summary" do
          candidate_branch
        end
      end)

    assert %{
             "type" => "timeline_publication_pressure",
             "feedback_scope" => "timeline_publication",
             "trust_boundary" => "mission_publication_artifact_boundary"
           } = List.first(mission_branch["events"])

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)

    clean_summary =
      %{
        "schema_contract" => "operational_timeline_report.v1",
        "id" => "timeline:published_plan:v3"
      }
      |> Timeline.publication_summary(
        publication_sequence: 8,
        downstream_product_ids: ["operator_review:plan:v2"]
      )

    clean_artifact =
      strategy(base_plan(%{"source_timeline_publication_summary" => clean_summary}),
        mission_state: mission_state_with_refresh_inputs(),
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    refute clean_artifact["branch_comparison_report"]["rows"]
           |> Enum.map(& &1["branch_id"])
           |> Enum.any?(&String.starts_with?(&1, "derived_timeline_publication_pressure_"))
  end

  test "strategy scores branch-local timeline publication replay pressure" do
    source = [
      %{id: :health_gate, type: :health_check, starts_at_s: 0.0, ends_at_s: 10.0},
      %{
        id: :cmd_main,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependencies: [:health_gate]
      }
    ]

    replacement = [
      %{id: :health_gate, type: :health_check, starts_at_s: 5.0, ends_at_s: 15.0},
      %{
        id: :cmd_main,
        type: :command,
        starts_at_s: 20.0,
        ends_at_s: 30.0,
        dependencies: [:health_gate]
      }
    ]

    publication_summary =
      %{
        "schema_contract" => "operational_timeline_report.v1",
        "id" => "timeline:published_plan:replay"
      }
      |> Timeline.publication_summary(
        publication_sequence: 11,
        publication_authority: :mission_operations,
        supersedes_artifact_ids: ["timeline:published_plan:previous"],
        downstream_product_ids: ["operator_review:plan:previous", "cadence_import:plan:previous"],
        dependency_impact_summary: Timeline.dependency_impact_summary(source, replacement),
        timeline_diff_summary: Timeline.diff_summary(source, replacement)
      )
      |> Map.put("provenance", %{"trust_boundary" => "replay_publication_boundary"})

    assert {:ok, %{"schema_contract" => "timeline_publication_summary.v1"}} =
             Schema.validate_artifact(publication_summary)

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_timeline_publication_summary", [publication_summary])

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        branches: [
          %{id: "baseline"},
          %{
            id: "urgent",
            events: [%{type: "urgent_target", target_id: "target_a", priority: 12.0}],
            candidate_refresh:
              candidate_refresh_artifact(
                [refreshed_downlink("dl_publication_replay", 500.0, 560.0)],
                refresh_id: "candidate_refresh:publication_replay"
              ),
            candidate_refresh_request: %{
              source_timeline_publication_summary: [publication_summary]
            }
          }
        ],
        current_epoch_s: 0.0
      )

    urgent = branch(artifact, "urgent")

    assert %{"type" => "candidate_refresh.v1", "scope" => "branch"} =
             candidate_source = urgent["assumptions"]["candidate_source"]

    assert "source_timeline_publication_summary[0]" in candidate_source[
             "source_report_input_paths"
           ]

    assert %{
             "branch_local_timeline_publication_pressure" => true,
             "branch_local_timeline_publication_dependency_pressure" => true,
             "branch_local_timeline_publication_invalidation_pressure" => true,
             "branch_local_timeline_publication_review_pressure" => true,
             "publication_ids" => [
               "timeline_publication:11:timeline:published_plan:replay:timeline:published_plan:previous"
             ],
             "invalidated_downstream_product_ids" => [
               "cadence_import:plan:previous",
               "operator_review:plan:previous"
             ],
             "review_timeline_ids" => [
               "timeline:health_check:0.0",
               "timeline:health_check:5.0"
             ]
           } = CandidateRefresh.timeline_publication_replay_summary(candidate_source)

    assert_timeline_publication_pressure_score_terms(urgent, artifact)

    urgent_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "urgent"))

    assert "timeline_publication_pressure" in urgent_row["risk_types"]

    assert urgent_row["branch_timeline_publication_ids"] == [
             "timeline_publication:11:timeline:published_plan:replay:timeline:published_plan:previous"
           ]

    assert urgent_row[
             "branch_timeline_publication_invalidated_downstream_product_ids"
           ] == ["cadence_import:plan:previous", "operator_review:plan:previous"]

    assert urgent_row["branch_timeline_publication_changed_timeline_ids"] == [
             "timeline:health_check:0.0",
             "timeline:health_check:5.0"
           ]

    assert urgent_row["branch_timeline_publication_review_timeline_ids"] == [
             "timeline:health_check:0.0",
             "timeline:health_check:5.0"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp assert_timeline_publication_pressure_score_terms(branch, artifact) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    timeline_publication_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &(&1["type"] == "timeline_publication_pressure")
      )

    assert timeline_publication_pressure_count == 1

    assert branch["score_terms"]["timeline_publication_pressure_penalty"] ==
             -timeline_publication_pressure_count * risk_weight

    assert branch["score_terms"]["timeline_pressure_penalty"] == 0.0

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) - timeline_publication_pressure_count) *
               risk_weight

    assert "timeline_publication_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "timeline_publication_pressure_penalty" and
                 &1["value"] < 0.0)
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
end
