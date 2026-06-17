Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyRefreshBudgetSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CandidateRefresh
  alias OrbitalDynamics.Schema

  test "strategy carries mission-state refresh-budget reports into branch refresh requests" do
    refresh_budget_report = fn prefix, input_count, kept_count, dropped_count, invalid_limit? ->
      report = %{
        "schema_contract" => "refresh_budget_report.v1",
        "model" => "deterministic_candidate_limit_after_filters",
        "input_candidate_count" => input_count,
        "kept_candidate_count" => kept_count,
        "dropped_candidate_count" => dropped_count,
        "max_candidate_activities" => kept_count,
        "selection_order" => "score_descending_then_start_then_id",
        "kept_candidate_ids" =>
          if(kept_count > 0, do: Enum.map(1..kept_count, &"#{prefix}_kept_#{&1}"), else: []),
        "dropped_candidate_ids" =>
          if(dropped_count > 0,
            do: Enum.map(1..dropped_count, &"#{prefix}_dropped_#{&1}"),
            else: []
          ),
        "assumptions" => %{
          "budget_stage" => "after_contact_resource_and_allocation_filters",
          "optimizer_search_performed" => false
        },
        "provenance" => %{"trust_boundary" => "#{prefix}_refresh_budget_boundary"}
      }

      if invalid_limit? do
        report
        |> Map.put("invalid_candidate_limit_policy", true)
        |> Map.put(
          "invalid_candidate_limit_policy_reason",
          "max_candidate_activities_must_be_integer"
        )
      else
        report
      end
    end

    direct_report = refresh_budget_report.("direct", 4, 2, 2, false)
    canonical_report = refresh_budget_report.("canonical", 5, 3, 2, false)
    source_wrapped_report = refresh_budget_report.("source_wrapped", 3, 1, 2, true)
    result_wrapped_report = refresh_budget_report.("result_wrapped", 2, 2, 0, false)

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_refresh_budget_report", direct_report)
      |> Map.put("refresh_budget_report", canonical_report)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "refresh_budget_report" => Map.delete(source_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "source_wrapped_refresh_budget_boundary"}
      })
      |> Map.put(:result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_refresh_budget_report" => Map.delete(result_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "result_wrapped_refresh_budget_boundary"}
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
          "mission_state.source_refresh_budget_report",
          "mission_state.refresh_budget_report",
          "mission_state.source_result_artifact.refresh_budget_report",
          "mission_state.result_artifact.source_refresh_budget_report"
        ] do
      assert source_path in candidate_source["source_report_input_paths"]

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_refresh_budget_input_candidate_count" => 14,
             "source_report_refresh_budget_kept_candidate_count" => 8,
             "source_report_refresh_budget_dropped_candidate_count" => 6,
             "source_report_refresh_budget_invalid_candidate_limit_policy_count" => 1,
             "source_report_refresh_budget_invalid_candidate_limit_policy_reason_counts" => %{
               "max_candidate_activities_must_be_integer" => 1
             },
             "source_report_refresh_budget_kept_candidate_ids" => kept_candidate_ids,
             "source_report_refresh_budget_dropped_candidate_ids" => dropped_candidate_ids
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert Enum.sort(kept_candidate_ids) == [
             "canonical_kept_1",
             "canonical_kept_2",
             "canonical_kept_3",
             "direct_kept_1",
             "direct_kept_2",
             "result_wrapped_kept_1",
             "result_wrapped_kept_2",
             "source_wrapped_kept_1"
           ]

    assert Enum.sort(dropped_candidate_ids) == [
             "canonical_dropped_1",
             "canonical_dropped_2",
             "direct_dropped_1",
             "direct_dropped_2",
             "source_wrapped_dropped_1",
             "source_wrapped_dropped_2"
           ]

    assert %{
             "contract" => "refresh_budget_report.v1",
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_paths" => replay_source_paths,
             "input_candidate_count" => 14,
             "kept_candidate_count" => 8,
             "dropped_candidate_count" => 6,
             "invalid_candidate_limit_policy_count" => 1,
             "invalid_candidate_limit_policy_reason_counts" => %{
               "max_candidate_activities_must_be_integer" => 1
             },
             "kept_candidate_ids" => replay_kept_candidate_ids,
             "dropped_candidate_ids" => replay_dropped_candidate_ids,
             "trust_boundary_status" => "declared",
             "branch_local_budget_pressure" => true,
             "branch_local_dropped_candidate_pressure" => true,
             "branch_local_invalid_limit_pressure" => true,
             "branch_local_candidate_limit_applied" => true
           } = CandidateRefresh.refresh_budget_replay_summary(candidate_source)

    assert Enum.sort(replay_kept_candidate_ids) == Enum.sort(kept_candidate_ids)
    assert Enum.sort(replay_dropped_candidate_ids) == Enum.sort(dropped_candidate_ids)

    assert Enum.sort(replay_source_paths) == [
             "mission_state.refresh_budget_report",
             "mission_state.result_artifact.source_refresh_budget_report",
             "mission_state.source_refresh_budget_report",
             "mission_state.source_result_artifact.refresh_budget_report"
           ]

    refresh_budget_pressure_count =
      Enum.count(
        urgent["risk_indicators"],
        &(&1["type"] == "refresh_budget_pressure" and
            &1["feedback_source"] == "candidate_source.refresh_budget_replay_summary")
      )

    assert refresh_budget_pressure_count == 1

    assert Enum.any?(
             urgent["risk_indicators"],
             &(&1["type"] == "refresh_budget_pressure" and
                 &1["feedback_scope"] == "refresh_budget" and
                 &1["severity"] == "high" and
                 &1["source_report_count"] == 4 and
                 &1["source_report_row_count"] == 4 and
                 &1["source_report_paths"] == replay_source_paths and
                 &1["input_candidate_count"] == 14 and
                 &1["kept_candidate_count"] == 8 and
                 &1["dropped_candidate_count"] == 6 and
                 &1["invalid_candidate_limit_policy_count"] == 1 and
                 &1["invalid_candidate_limit_policy_reason_counts"] == %{
                   "max_candidate_activities_must_be_integer" => 1
                 } and
                 &1["candidate_limit_status"] == "invalid" and
                 &1["refresh_budget_status"] == "invalid" and
                 &1["kept_candidate_ids"] == Enum.sort(replay_kept_candidate_ids) and
                 &1["dropped_candidate_ids"] == Enum.sort(replay_dropped_candidate_ids) and
                 &1["branch_local_budget_pressure"] == true and
                 &1["branch_local_dropped_candidate_pressure"] == true and
                 &1["branch_local_invalid_limit_pressure"] == true and
                 &1["branch_local_candidate_limit_applied"] == true)
           )

    assert_validation_refresh_pressure_score_terms(urgent, artifact, "refresh_budget")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy challenge scores refresh-budget replay from dropped IDs when counts are stale" do
    stale_report = %{
      "schema_contract" => "refresh_budget_report.v1",
      "model" => "deterministic_candidate_limit_after_filters",
      "input_candidate_count" => 2,
      "kept_candidate_count" => 2,
      "dropped_candidate_count" => 0,
      "max_candidate_activities" => 2,
      "selection_order" => "score_descending_then_start_then_id",
      "kept_candidate_ids" => ["kept_a", "kept_b"],
      "dropped_candidate_ids" => ["stale_dropped_candidate"],
      "assumptions" => %{
        "budget_stage" => "after_contact_resource_and_allocation_filters",
        "optimizer_search_performed" => false,
        "stale_count_challenge" => true
      },
      "provenance" => %{"trust_boundary" => "stale_refresh_budget_boundary"}
    }

    artifact =
      strategy(base_plan(%{}),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:source_refresh_budget_report, stale_report),
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

    assert %{
             "input_candidate_count" => 2,
             "kept_candidate_count" => 2,
             "dropped_candidate_count" => 0,
             "kept_candidate_ids" => ["kept_a", "kept_b"],
             "dropped_candidate_ids" => ["stale_dropped_candidate"],
             "branch_local_budget_pressure" => true,
             "branch_local_dropped_candidate_pressure" => true,
             "branch_local_invalid_limit_pressure" => false,
             "branch_local_candidate_limit_applied" => true
           } = CandidateRefresh.refresh_budget_replay_summary(candidate_source)

    assert Enum.any?(
             urgent["risk_indicators"],
             &(&1["type"] == "refresh_budget_pressure" and
                 &1["feedback_source"] == "candidate_source.refresh_budget_replay_summary" and
                 &1["severity"] == "medium" and
                 &1["candidate_limit_status"] == "dropped" and
                 &1["refresh_budget_status"] == "dropped" and
                 &1["input_candidate_count"] == 2 and
                 &1["kept_candidate_count"] == 2 and
                 &1["dropped_candidate_count"] == 0 and
                 &1["kept_candidate_ids"] == ["kept_a", "kept_b"] and
                 &1["dropped_candidate_ids"] == ["stale_dropped_candidate"] and
                 &1["branch_local_budget_pressure"] == true and
                 &1["branch_local_dropped_candidate_pressure"] == true and
                 &1["branch_local_candidate_limit_applied"] == true)
           )

    assert_validation_refresh_pressure_score_terms(urgent, artifact, "refresh_budget")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
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
