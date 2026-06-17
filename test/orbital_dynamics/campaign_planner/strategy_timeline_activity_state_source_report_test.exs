Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyTimelineActivityStateSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.{CandidateRefresh, Schema, Timeline}

  test "strategy carries mission-state timeline activity states into branch refresh requests" do
    activity_state = fn prefix ->
      planned = %{
        id: "#{prefix}_cmd_pending",
        type: :command,
        status: :planned,
        approval_status: :pending,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        metadata: %{timeline_id: "timeline:#{prefix}:cmd_pending"}
      }

      realized = %{
        id: "#{prefix}_cmd_pending",
        type: :command,
        status: :executed,
        approval_status: :approved,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        metadata: %{timeline_id: "timeline:#{prefix}:cmd_pending"}
      }

      OrbitalDynamics.timeline_activity_state(planned, realized)
    end

    direct_state =
      activity_state.("direct_activity_state")
      |> Map.put("trust_boundary", "direct_activity_state_boundary")

    canonical_state =
      activity_state.("canonical_activity_state")
      |> Map.put("trust_boundary", "canonical_activity_state_boundary")

    wrapped_state =
      activity_state.("wrapped_activity_state")
      |> Map.put("trust_boundary", "wrapped_activity_state_boundary")

    result_wrapped_state =
      activity_state.("result_wrapped_activity_state")
      |> Map.put("trust_boundary", "result_wrapped_activity_state_boundary")

    assert {:ok, %{"schema_contract" => "timeline_activity_state.v1"}} =
             Schema.validate_artifact(direct_state)

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_timeline_activity_state", [direct_state])
      |> Map.put("timeline_activity_state", canonical_state)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "timeline_activity_state" => wrapped_state,
        "provenance" => %{"trust_boundary" => "wrapped_activity_state_artifact_boundary"}
      })
      |> Map.put(:result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "timeline_activity_state" => result_wrapped_state,
        "provenance" => %{"trust_boundary" => "result_wrapped_activity_state_artifact_boundary"}
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
          "mission_state.source_timeline_activity_state",
          "mission_state.timeline_activity_state",
          "mission_state.source_result_artifact.timeline_activity_state",
          "mission_state.result_artifact.timeline_activity_state"
        ] do
      assert source_path in source_report_input_paths

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_timeline_activity_state_row_count" => 4,
             "source_report_timeline_activity_state_review_required_count" => 0,
             "source_report_timeline_activity_state_source_summary_schema_contract_counts" => %{
               "timeline_activity_state.v1" => 4
             },
             "source_report_timeline_activity_state_source_summary_model_counts" => %{
               "artifact_only_timeline_activity_state" => 4
             }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_paths" => replay_source_paths,
             "branch_local_timeline_activity_state_pressure" => true,
             "branch_local_activity_state_review_pressure" => false,
             "branch_local_activity_state_action_pressure" => false,
             "branch_local_activity_state_routing_pressure" => true,
             "assumptions" => %{
               "replay_scope" => "timeline_activity_state_candidate_source_report_summary_only",
               "activity_state_application" => "not_performed_by_summary",
               "timeline_mutation" => "not_performed_by_summary"
             }
           } = CandidateRefresh.timeline_activity_state_replay_summary(candidate_source)

    for source_path <- [
          "mission_state.source_timeline_activity_state",
          "mission_state.timeline_activity_state",
          "mission_state.source_result_artifact.timeline_activity_state",
          "mission_state.result_artifact.timeline_activity_state"
        ] do
      assert source_path in replay_source_paths
    end

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy carries mission-state timeline activity status states into branch refresh requests" do
    status_state = fn prefix ->
      planned = %{
        id: "#{prefix}_obs_running",
        type: :observe,
        status: :executing,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        metadata: %{timeline_id: "timeline:#{prefix}:obs_running"}
      }

      realized = %{
        id: "#{prefix}_obs_running",
        type: :observe,
        status: :completed,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        metadata: %{timeline_id: "timeline:#{prefix}:obs_running"}
      }

      Timeline.activity_status_state(planned, realized)
    end

    direct_state =
      status_state.("direct_status_state")
      |> Map.put("trust_boundary", "direct_status_state_boundary")

    canonical_state =
      status_state.("canonical_status_state")
      |> Map.put("trust_boundary", "canonical_status_state_boundary")

    wrapped_state =
      status_state.("wrapped_status_state")
      |> Map.put("trust_boundary", "wrapped_status_state_boundary")

    result_wrapped_state =
      status_state.("result_wrapped_status_state")
      |> Map.put("trust_boundary", "result_wrapped_status_state_boundary")

    assert {:ok, %{"schema_contract" => "timeline_activity_status_state.v1"}} =
             Schema.validate_artifact(direct_state)

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_timeline_activity_status_state", [direct_state])
      |> Map.put("timeline_activity_status_state", canonical_state)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "timeline_activity_status_state" => wrapped_state,
        "provenance" => %{"trust_boundary" => "wrapped_status_state_artifact_boundary"}
      })
      |> Map.put(:result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "timeline_activity_status_state" => result_wrapped_state,
        "provenance" => %{"trust_boundary" => "result_wrapped_status_state_artifact_boundary"}
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
          "mission_state.source_timeline_activity_status_state",
          "mission_state.timeline_activity_status_state",
          "mission_state.source_result_artifact.timeline_activity_status_state",
          "mission_state.result_artifact.timeline_activity_status_state"
        ] do
      assert source_path in source_report_input_paths

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_timeline_activity_state_row_count" => 4,
             "source_report_timeline_activity_state_review_required_count" => 0,
             "source_report_timeline_activity_state_transition_decision_counts" => %{
               "record" => 4
             },
             "source_report_timeline_activity_state_required_operator_action_counts" => %{
               "record_timeline_change" => 4
             },
             "source_report_timeline_activity_state_import_action_counts" => %{
               "import_replacement_activity" => 4
             }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "source" =>
               "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_activity_state",
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_paths" => replay_source_paths,
             "branch_local_timeline_activity_state_pressure" => true,
             "branch_local_activity_state_review_pressure" => false,
             "branch_local_activity_state_action_pressure" => true,
             "branch_local_activity_state_routing_pressure" => true,
             "assumptions" => %{
               "replay_scope" => "timeline_activity_state_candidate_source_report_summary_only",
               "activity_state_application" => "not_performed_by_summary",
               "timeline_mutation" => "not_performed_by_summary"
             }
           } = CandidateRefresh.timeline_activity_state_replay_summary(candidate_source)

    for source_path <- [
          "mission_state.source_timeline_activity_status_state",
          "mission_state.timeline_activity_status_state",
          "mission_state.source_result_artifact.timeline_activity_status_state",
          "mission_state.result_artifact.timeline_activity_status_state"
        ] do
      assert source_path in replay_source_paths
    end

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy carries mission-state timeline activity approval states into branch refresh requests" do
    approval_state = fn prefix ->
      planned = %{
        id: "#{prefix}_cmd_pending",
        type: :command,
        approval_status: :pending,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        metadata: %{timeline_id: "timeline:#{prefix}:cmd_pending"}
      }

      realized = %{
        id: "#{prefix}_cmd_pending",
        type: :command,
        approval_status: :approved,
        starts_at_s: 10.0,
        ends_at_s: 20.0,
        metadata: %{timeline_id: "timeline:#{prefix}:cmd_pending"}
      }

      Timeline.activity_approval_state(planned, realized)
    end

    direct_state =
      approval_state.("direct_approval_state")
      |> Map.put("trust_boundary", "direct_approval_state_boundary")

    canonical_state =
      approval_state.("canonical_approval_state")
      |> Map.put("trust_boundary", "canonical_approval_state_boundary")

    wrapped_state =
      approval_state.("wrapped_approval_state")
      |> Map.put("trust_boundary", "wrapped_approval_state_boundary")

    result_wrapped_state =
      approval_state.("result_wrapped_approval_state")
      |> Map.put("trust_boundary", "result_wrapped_approval_state_boundary")

    assert {:ok, %{"schema_contract" => "timeline_activity_approval_state.v1"}} =
             Schema.validate_artifact(direct_state)

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_timeline_activity_approval_state", [direct_state])
      |> Map.put("timeline_activity_approval_state", canonical_state)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "timeline_activity_approval_state" => wrapped_state,
        "provenance" => %{"trust_boundary" => "wrapped_approval_state_artifact_boundary"}
      })
      |> Map.put(:result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "timeline_activity_approval_state" => result_wrapped_state,
        "provenance" => %{
          "trust_boundary" => "result_wrapped_approval_state_artifact_boundary"
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
          "mission_state.source_timeline_activity_approval_state",
          "mission_state.timeline_activity_approval_state",
          "mission_state.source_result_artifact.timeline_activity_approval_state",
          "mission_state.result_artifact.timeline_activity_approval_state"
        ] do
      assert source_path in source_report_input_paths

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_timeline_activity_state_row_count" => 4,
             "source_report_timeline_activity_state_review_required_count" => 4,
             "source_report_timeline_activity_state_transition_decision_counts" => %{
               "review" => 4
             },
             "source_report_timeline_activity_state_required_operator_action_counts" => %{
               "review_activity_approval" => 4
             },
             "source_report_timeline_activity_state_import_action_counts" => %{
               "review_timeline_diff" => 4
             }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert %{
             "source" =>
               "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_activity_state",
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_paths" => replay_source_paths,
             "branch_local_timeline_activity_state_pressure" => true,
             "branch_local_activity_state_review_pressure" => true,
             "branch_local_activity_state_action_pressure" => true,
             "branch_local_activity_state_routing_pressure" => true,
             "assumptions" => %{
               "replay_scope" => "timeline_activity_state_candidate_source_report_summary_only",
               "activity_state_application" => "not_performed_by_summary",
               "timeline_mutation" => "not_performed_by_summary"
             }
           } = CandidateRefresh.timeline_activity_state_replay_summary(candidate_source)

    for source_path <- [
          "mission_state.source_timeline_activity_approval_state",
          "mission_state.timeline_activity_approval_state",
          "mission_state.source_result_artifact.timeline_activity_approval_state",
          "mission_state.result_artifact.timeline_activity_approval_state"
        ] do
      assert source_path in replay_source_paths
    end

    assert_timeline_lifecycle_pressure_score_terms(
      urgent,
      artifact,
      "timeline_activity_lifecycle_state_review"
    )

    urgent_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(&(&1["branch_id"] == "urgent"))

    assert "timeline_activity_lifecycle_state_review" in urgent_row["risk_types"]

    assert urgent_row["branch_timeline_activity_lifecycle_state_activity_ids"] == [
             "canonical_approval_state_cmd_pending",
             "direct_approval_state_cmd_pending",
             "result_wrapped_approval_state_cmd_pending",
             "wrapped_approval_state_cmd_pending"
           ]

    assert urgent_row["branch_timeline_activity_lifecycle_state_timeline_ids"] == [
             "timeline:canonical_approval_state:cmd_pending",
             "timeline:direct_approval_state:cmd_pending",
             "timeline:result_wrapped_approval_state:cmd_pending",
             "timeline:wrapped_approval_state:cmd_pending"
           ]

    assert urgent_row["branch_timeline_activity_lifecycle_state_transition_decisions"] == [
             "review"
           ]

    assert urgent_row[
             "branch_timeline_activity_lifecycle_state_required_operator_actions"
           ] == [
             "review_activity_approval"
           ]

    assert urgent_row["branch_timeline_activity_lifecycle_state_import_actions"] == [
             "review_timeline_diff"
           ]

    assert urgent_row[
             "branch_timeline_activity_lifecycle_state_approval_transition_categories"
           ] == [
             "approval_granted"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp assert_timeline_lifecycle_pressure_score_terms(branch, artifact, risk_type) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])
    pressure_term = timeline_lifecycle_pressure_term(risk_type)

    timeline_lifecycle_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &(&1["type"] == risk_type)
      )

    assert timeline_lifecycle_pressure_count == 1

    assert branch["score_terms"][pressure_term] ==
             -timeline_lifecycle_pressure_count * risk_weight

    if pressure_term == "timeline_activity_state_pressure_penalty" do
      assert branch["score_terms"]["timeline_lifecycle_pressure_penalty"] == 0.0
    end

    assert branch["score_terms"]["timeline_pressure_penalty"] == 0.0

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) - timeline_lifecycle_pressure_count) *
               risk_weight

    assert pressure_term in artifact["score_term_report"]["score_term_keys"]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == pressure_term and
                 &1["value"] < 0.0)
           )
  end

  defp timeline_lifecycle_pressure_term("timeline_activity_lifecycle_state_review"),
    do: "timeline_activity_state_pressure_penalty"

  defp timeline_lifecycle_pressure_term(_risk_type),
    do: "timeline_lifecycle_pressure_penalty"
end
