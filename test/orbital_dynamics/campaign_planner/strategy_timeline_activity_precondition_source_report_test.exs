Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyTimelineActivityPreconditionSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.{CandidateRefresh, Schema, Timeline}

  test "strategy carries mission-state timeline activity-precondition summaries into branch refresh requests" do
    precondition_summary =
      Timeline.activity_precondition_summary(%{
        id: :branch_precondition_cmd_precondition,
        type: :command,
        scenario_id: :leo_1,
        subject_id: :dss_14,
        payload_available: false,
        degraded: true,
        command_authorized: false,
        command_safety_status: :failed,
        command_safety_checked: false,
        resource_blocking_dimension: :battery,
        dependency_activity_ids: [:health_check, :health_check],
        dependency_timeline_ids: [:"timeline:health_check"],
        exclusive_with: [:downlink_conflict, :downlink_conflict],
        exclusive_with_timeline_ids: [:"timeline:downlink_conflict"],
        allow_overlap: true,
        metadata: %{timeline_id: "timeline:branch_precondition:cmd_precondition"},
        activity_context: %{
          activity_template: %{
            schema_contract: "activity_template.v1",
            id: "branch_precondition_command_template",
            activity_type: "command",
            subsystem_state_hints: %{
              required_states: [
                %{
                  subsystem: "commanding",
                  state: "armed",
                  reason: "template requires armed commanding state"
                }
              ]
            }
          }
        }
      })
      |> Map.put("provenance", %{"trust_boundary" => "branch_precondition_boundary"})

    assert {:ok, %{"schema_contract" => "timeline_activity_precondition_summary.v1"}} =
             Schema.validate_artifact(precondition_summary)

    artifact =
      strategy(base_plan(%{}),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put("source_timeline_activity_precondition_summary", precondition_summary),
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

    assert "mission_state.source_timeline_activity_precondition_summary" in candidate_source[
             "source_report_input_paths"
           ]

    assert "mission_state.source_timeline_activity_precondition_summary" in candidate_source[
             "candidate_refresh_request_source_report_input_paths"
           ]

    assert %{
             "source" =>
               "candidate_refresh.candidate_source.candidate_refresh_request_source_report_summary.timeline_activity_precondition_summary",
             "contract" => "timeline_activity_precondition_summary.v1",
             "source_report_count" => 1,
             "source_report_row_count" => 7,
             "source_report_paths" => [
               "mission_state.source_timeline_activity_precondition_summary"
             ],
             "blocked_precondition_count" => 3,
             "review_precondition_count" => 4,
             "blocked_precondition_type_counts" => %{
               "command_safety_failed" => 1,
               "payload_unavailable" => 1,
               "resource_block_declared" => 1
             },
             "review_precondition_type_counts" => %{
               "command_authority_missing" => 1,
               "command_safety_unchecked" => 1,
               "degraded_mode" => 1,
               "subsystem_state_required" => 1
             },
             "activity_id_counts" => %{"branch_precondition_cmd_precondition" => 2},
             "timeline_id_counts" => %{"timeline:branch_precondition:cmd_precondition" => 2},
             "dependency_activity_id_counts" => %{"health_check" => 1},
             "dependency_timeline_id_counts" => %{"timeline:health_check" => 1},
             "duplicate_dependency_activity_id_counts" => %{"health_check" => 1},
             "exclusive_with_activity_id_counts" => %{"downlink_conflict" => 1},
             "exclusive_with_timeline_id_counts" => %{"timeline:downlink_conflict" => 1},
             "duplicate_exclusivity_activity_id_counts" => %{"downlink_conflict" => 1},
             "branch_local_timeline_activity_precondition_pressure" => true,
             "branch_local_activity_precondition_review_pressure" => true,
             "branch_local_activity_precondition_dependency_pressure" => true,
             "branch_local_activity_precondition_exclusivity_pressure" => true
           } = CandidateRefresh.timeline_activity_precondition_replay_summary(candidate_source)

    precondition_pressure_count =
      Enum.count(
        urgent["risk_indicators"],
        &(&1["type"] == "timeline_activity_precondition_review" and
            &1["feedback_source"] ==
              "candidate_source.timeline_activity_precondition_replay_summary")
      )

    assert precondition_pressure_count == 1

    assert Enum.any?(
             urgent["risk_indicators"],
             &(&1["type"] == "timeline_activity_precondition_review" and
                 &1["blocked_precondition_count"] == 3 and
                 &1["review_precondition_count"] == 4 and
                 &1["blocked_precondition_types"] == [
                   "command_safety_failed",
                   "payload_unavailable",
                   "resource_block_declared"
                 ] and
                 &1["review_precondition_types"] == [
                   "command_authority_missing",
                   "command_safety_unchecked",
                   "degraded_mode",
                   "subsystem_state_required"
                 ] and
                 &1["activity_ids"] == ["branch_precondition_cmd_precondition"] and
                 &1["dependency_activity_ids"] == ["health_check"] and
                 &1["duplicate_dependency_activity_ids"] == ["health_check"] and
                 &1["exclusive_with_activity_ids"] == ["downlink_conflict"] and
                 &1["duplicate_exclusivity_activity_ids"] == ["downlink_conflict"] and
                 &1["feedback_scope"] == "timeline_activity_precondition")
           )

    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    assert urgent["score_terms"]["timeline_precondition_pressure_penalty"] ==
             -precondition_pressure_count * risk_weight

    assert "timeline_precondition_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == urgent["branch_id"] and
                 &1["term_key"] == "timeline_precondition_pressure_penalty" and
                 &1["value"] < 0.0)
           )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives branch pressure from timeline activity precondition summaries" do
    precondition_summary = fn prefix, trust_boundary ->
      Timeline.activity_precondition_summary(%{
        id: :"#{prefix}_cmd_precondition",
        type: :command,
        scenario_id: :leo_1,
        subject_id: :dss_14,
        payload_available: false,
        degraded: true,
        command_authorized: false,
        command_safety_status: :failed,
        command_safety_checked: false,
        resource_blocking_dimension: :battery,
        dependency_activity_ids: [:health_check, :health_check],
        dependency_timeline_ids: [:"timeline:health_check"],
        exclusive_with: [:downlink_conflict, :downlink_conflict],
        exclusive_with_timeline_ids: [:"timeline:downlink_conflict"],
        allow_overlap: true,
        metadata: %{timeline_id: "timeline:#{prefix}:cmd_precondition"},
        activity_context: %{
          activity_template: %{
            schema_contract: "activity_template.v1",
            id: "#{prefix}_command_template",
            activity_type: "command",
            subsystem_state_hints: %{
              required_states: [
                %{
                  subsystem: "commanding",
                  state: "armed",
                  reason: "template requires armed commanding state"
                }
              ]
            }
          }
        }
      })
      |> Map.put("provenance", %{"trust_boundary" => trust_boundary})
    end

    direct_summary =
      precondition_summary.("direct_precondition", "direct_precondition_boundary")

    canonical_summary =
      precondition_summary.("canonical_precondition", "canonical_precondition_boundary")

    wrapped_invalid_summary =
      Timeline.activity_precondition_summary(%{id: :wrapped_bad_missing_type})
      |> Map.delete("provenance")

    assert {:ok, %{"schema_contract" => "timeline_activity_precondition_summary.v1"}} =
             Schema.validate_artifact(direct_summary)

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_timeline_activity_precondition_summary", direct_summary)
      |> Map.put("timeline_activity_precondition_summary", canonical_summary)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "timeline_activity_precondition_summary" => wrapped_invalid_summary,
        "provenance" => %{"trust_boundary" => "wrapped_precondition_artifact_boundary"}
      })

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    direct_branch =
      branch(
        artifact,
        "derived_timeline_activity_precondition_pressure_direct_precondition_cmd_precondition"
      )

    assert %{
             "type" => "timeline_activity_precondition_pressure",
             "activity_id" => "direct_precondition_cmd_precondition",
             "timeline_id" => "timeline:direct_precondition:cmd_precondition",
             "activity_type" => "command",
             "precondition_status" => "blocked",
             "blocked_precondition_count" => 3,
             "review_precondition_count" => 4,
             "blocked_precondition_types" => [
               "command_safety_failed",
               "payload_unavailable",
               "resource_block_declared"
             ],
             "review_precondition_types" => [
               "command_authority_missing",
               "command_safety_unchecked",
               "degraded_mode",
               "subsystem_state_required"
             ],
             "dependency_activity_ids" => ["health_check"],
             "dependency_timeline_ids" => ["timeline:health_check"],
             "exclusive_with_activity_ids" => ["downlink_conflict"],
             "exclusive_with_timeline_ids" => ["timeline:downlink_conflict"],
             "duplicate_dependency_activity_ids" => ["health_check"],
             "duplicate_exclusivity_activity_ids" => ["downlink_conflict"],
             "allow_overlap" => true,
             "feedback_source" => "mission_state.source_timeline_activity_precondition_summary",
             "feedback_scope" => "timeline_activity_precondition",
             "trust_boundary" => "direct_precondition_boundary",
             "requires_operator_review" => true,
             "required_operator_action" => "review_blocked_activity_precondition",
             "derivation_reasons" => ["timeline_activity_precondition_summary_pressure"]
           } = List.first(direct_branch["events"])

    assert Enum.any?(
             direct_branch["risk_indicators"],
             &(&1["type"] == "timeline_activity_precondition_review" and
                 &1["precondition_status"] == "blocked" and
                 &1["dependency_activity_ids"] == ["health_check"] and
                 &1["feedback_source"] ==
                   "mission_state.source_timeline_activity_precondition_summary")
           )

    assert_timeline_precondition_pressure_score_terms(direct_branch, artifact)

    direct_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(
        &(&1["branch_id"] ==
            "derived_timeline_activity_precondition_pressure_direct_precondition_cmd_precondition")
      )

    assert direct_row["branch_timeline_activity_precondition_activity_ids"] == [
             "direct_precondition_cmd_precondition"
           ]

    assert direct_row["branch_timeline_activity_precondition_timeline_ids"] == [
             "timeline:direct_precondition:cmd_precondition"
           ]

    assert direct_row["branch_timeline_activity_precondition_statuses"] == ["blocked"]

    assert direct_row["branch_timeline_activity_precondition_blocked_types"] == [
             "command_safety_failed",
             "payload_unavailable",
             "resource_block_declared"
           ]

    assert direct_row["branch_timeline_activity_precondition_review_types"] == [
             "command_authority_missing",
             "command_safety_unchecked",
             "degraded_mode",
             "subsystem_state_required"
           ]

    assert direct_row["branch_timeline_activity_precondition_dependency_activity_ids"] == [
             "health_check"
           ]

    assert direct_row["branch_timeline_activity_precondition_exclusive_with_activity_ids"] == [
             "downlink_conflict"
           ]

    assert direct_row[
             "branch_timeline_activity_precondition_duplicate_dependency_activity_ids"
           ] == ["health_check"]

    assert direct_row[
             "branch_timeline_activity_precondition_duplicate_exclusivity_activity_ids"
           ] == ["downlink_conflict"]

    wrapped_branch =
      branch(
        artifact,
        "derived_timeline_activity_precondition_pressure_wrapped_bad_missing_type"
      )

    assert %{
             "activity_id" => "wrapped_bad_missing_type",
             "precondition_status" => "review_required",
             "invalid_activity_input" => true,
             "invalid_activity_input_reason" => "missing_activity_type",
             "feedback_source" =>
               "mission_state.source_result_artifact.timeline_activity_precondition_summary",
             "trust_boundary" => "wrapped_precondition_artifact_boundary",
             "required_operator_action" => "review_invalid_activity_input"
           } = List.first(wrapped_branch["events"])

    wrapped_row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(
        &(&1["branch_id"] ==
            "derived_timeline_activity_precondition_pressure_wrapped_bad_missing_type")
      )

    assert wrapped_row[
             "branch_timeline_activity_precondition_invalid_activity_input_reasons"
           ] == ["missing_activity_type"]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy derives activity precondition pressure from row-local stale aggregate evidence" do
    stale_summary =
      Timeline.activity_precondition_summary(%{
        id: :stale_precondition_cmd_precondition,
        type: :command,
        scenario_id: :leo_1,
        subject_id: :dss_14,
        payload_available: false,
        degraded: true,
        command_authorized: false,
        command_safety_status: :failed,
        command_safety_checked: false,
        resource_blocking_dimension: :battery,
        dependency_activity_ids: [:health_check, :health_check],
        dependency_timeline_ids: [:"timeline:health_check"],
        exclusive_with: [:downlink_conflict, :downlink_conflict],
        exclusive_with_timeline_ids: [:"timeline:downlink_conflict"],
        allow_overlap: true,
        metadata: %{timeline_id: "timeline:stale_precondition:cmd_precondition"},
        activity_context: %{
          activity_template: %{
            schema_contract: "activity_template.v1",
            id: "stale_precondition_command_template",
            activity_type: "command",
            subsystem_state_hints: %{
              required_states: [
                %{
                  subsystem: "commanding",
                  state: "armed",
                  reason: "template requires armed commanding state"
                }
              ]
            }
          }
        }
      })
      |> Map.put("provenance", %{"trust_boundary" => "stale_precondition_boundary"})
      |> Map.update!("preconditions", fn preconditions ->
        Enum.map(preconditions, fn precondition ->
          precondition
          |> Map.put("blocked_precondition_count", 99)
          |> Map.put("review_precondition_count", 99)
          |> Map.put("blocked_precondition_types", ["bogus_blocked_row_type"])
          |> Map.put("review_precondition_types", ["bogus_review_row_type"])
        end)
      end)
      |> Map.merge(%{
        "precondition_status" => "clear",
        "blocked_precondition_count" => 0,
        "review_precondition_count" => 0,
        "blocked_precondition_types" => [],
        "review_precondition_types" => []
      })

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_timeline_activity_precondition_summary", stale_summary)

    artifact =
      strategy(base_plan(%{}),
        mission_state: mission_state,
        derive_branches?: true,
        branches: [%{id: "baseline"}],
        current_epoch_s: 0.0
      )

    branch =
      branch(
        artifact,
        "derived_timeline_activity_precondition_pressure_stale_precondition_cmd_precondition"
      )

    assert %{
             "type" => "timeline_activity_precondition_pressure",
             "activity_id" => "stale_precondition_cmd_precondition",
             "timeline_id" => "timeline:stale_precondition:cmd_precondition",
             "precondition_status" => "blocked",
             "blocked_precondition_count" => 3,
             "review_precondition_count" => 4,
             "blocked_precondition_types" => [
               "command_safety_failed",
               "payload_unavailable",
               "resource_block_declared"
             ],
             "review_precondition_types" => [
               "command_authority_missing",
               "command_safety_unchecked",
               "degraded_mode",
               "subsystem_state_required"
             ],
             "feedback_source" => "mission_state.source_timeline_activity_precondition_summary",
             "trust_boundary" => "stale_precondition_boundary",
             "requires_operator_review" => true,
             "required_operator_action" => "review_blocked_activity_precondition"
           } = List.first(branch["events"])

    assert Enum.any?(
             branch["risk_indicators"],
             &(&1["type"] == "timeline_activity_precondition_review" and
                 &1["precondition_status"] == "blocked" and
                 &1["blocked_precondition_types"] == [
                   "command_safety_failed",
                   "payload_unavailable",
                   "resource_block_declared"
                 ])
           )

    assert_timeline_precondition_pressure_score_terms(branch, artifact)

    row =
      artifact["branch_comparison_report"]["rows"]
      |> Enum.find(
        &(&1["branch_id"] ==
            "derived_timeline_activity_precondition_pressure_stale_precondition_cmd_precondition")
      )

    assert row["branch_timeline_activity_precondition_statuses"] == ["blocked"]

    assert row["branch_timeline_activity_precondition_blocked_types"] == [
             "command_safety_failed",
             "payload_unavailable",
             "resource_block_declared"
           ]

    assert row["branch_timeline_activity_precondition_review_types"] == [
             "command_authority_missing",
             "command_safety_unchecked",
             "degraded_mode",
             "subsystem_state_required"
           ]

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp assert_timeline_precondition_pressure_score_terms(branch, artifact) do
    risk_weight = get_in(artifact, ["score_term_report", "assumptions", "policy", "risk_weight"])

    timeline_precondition_pressure_count =
      Enum.count(
        branch["risk_indicators"],
        &(&1["type"] == "timeline_activity_precondition_review")
      )

    assert timeline_precondition_pressure_count == 1

    assert branch["score_terms"]["timeline_precondition_pressure_penalty"] ==
             -timeline_precondition_pressure_count * risk_weight

    assert branch["score_terms"]["timeline_pressure_penalty"] == 0.0

    assert branch["score_terms"]["risk_penalty"] ==
             -(length(branch["risk_indicators"]) - timeline_precondition_pressure_count) *
               risk_weight

    assert "timeline_precondition_pressure_penalty" in artifact["score_term_report"][
             "score_term_keys"
           ]

    assert Enum.any?(
             artifact["score_term_report"]["rows"],
             &(&1["branch_id"] == branch["branch_id"] and
                 &1["term_key"] == "timeline_precondition_pressure_penalty" and
                 &1["value"] < 0.0)
           )
  end
end
