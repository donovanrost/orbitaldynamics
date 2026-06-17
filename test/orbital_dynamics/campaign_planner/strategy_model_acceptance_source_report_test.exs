Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyModelAcceptanceSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CandidateRefresh
  alias OrbitalDynamics.Schema

  test "strategy carries mission-state model-acceptance reports into branch refresh requests" do
    model_acceptance_report = fn prefix, review_model_id, blocked_model_id, unknown_model_id ->
      %{
        "schema_contract" => "model_acceptance_report.v1",
        "schema_version" => 1,
        "report_id" => "model_acceptance:operational_import:#{prefix}",
        "model" => "registry_model_acceptance_classifier",
        "intended_use" => "operational_import",
        "status" => "blocked",
        "model_count" => 3,
        "accepted_count" => 0,
        "review_required_count" => 1,
        "blocked_count" => 2,
        "unknown_model_count" => 1,
        "status_counts" => %{"blocked" => 2, "review_required" => 1},
        "validation_level_counts" => %{"analysis" => 1, "educational" => 1, "unknown" => 1},
        "model_ids_by_status" => %{
          "blocked" => [blocked_model_id, unknown_model_id],
          "review_required" => [review_model_id]
        },
        "model_ids_by_validation_level" => %{
          "analysis" => [review_model_id],
          "educational" => [blocked_model_id],
          "unknown" => [unknown_model_id]
        },
        "model_ids_by_intended_use" => %{
          "operational_import" => [review_model_id, blocked_model_id, unknown_model_id]
        },
        "rows" => [
          %{
            "id" => "model_acceptance:#{prefix}:review",
            "model_id" => review_model_id,
            "validation_level" => "analysis",
            "status" => "review_required"
          },
          %{
            "id" => "model_acceptance:#{prefix}:blocked",
            "model_id" => blocked_model_id,
            "validation_level" => "educational",
            "status" => "blocked"
          },
          %{
            "id" => "model_acceptance:#{prefix}:unknown",
            "model_id" => unknown_model_id,
            "validation_level" => "unknown",
            "status" => "blocked"
          }
        ],
        "records" => [
          %{"record_id" => "acceptance:#{prefix}:review"},
          %{"record_id" => "acceptance:#{prefix}:blocked"}
        ],
        "assumptions" => %{"source" => "campaign_planner_test.#{prefix}.model_acceptance"},
        "model_limits" => ["artifact_only"],
        "provenance" => %{"trust_boundary" => "#{prefix}_model_acceptance_boundary"}
      }
    end

    direct_report =
      model_acceptance_report.(
        "direct",
        "direct_review_model",
        "direct_blocked_model",
        "direct_unknown_model"
      )

    canonical_report =
      model_acceptance_report.(
        "canonical",
        "canonical_review_model",
        "canonical_blocked_model",
        "canonical_unknown_model"
      )

    source_wrapped_report =
      model_acceptance_report.(
        "source_wrapped",
        "source_wrapped_review_model",
        "source_wrapped_blocked_model",
        "source_wrapped_unknown_model"
      )

    result_wrapped_report =
      model_acceptance_report.(
        "result_wrapped",
        "result_wrapped_review_model",
        "result_wrapped_blocked_model",
        "result_wrapped_unknown_model"
      )

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_model_acceptance_report", direct_report)
      |> Map.put("model_acceptance_report", canonical_report)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "model_acceptance_report" => Map.delete(source_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "source_wrapped_model_acceptance_boundary"}
      })
      |> Map.put(:result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_model_acceptance_report" => Map.delete(result_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "result_wrapped_model_acceptance_boundary"}
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
          "mission_state.source_model_acceptance_report",
          "mission_state.model_acceptance_report",
          "mission_state.source_result_artifact.model_acceptance_report",
          "mission_state.result_artifact.source_model_acceptance_report"
        ] do
      assert source_path in candidate_source["source_report_input_paths"]

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 12,
             "source_report_model_acceptance_record_count" => 8,
             "source_report_model_acceptance_intended_use_counts" => %{
               "operational_import" => 4
             },
             "source_report_model_acceptance_status_counts" => %{"blocked" => 4},
             "source_report_model_acceptance_model_count" => 12,
             "source_report_model_acceptance_review_required_count" => 4,
             "source_report_model_acceptance_blocked_count" => 8,
             "source_report_model_acceptance_unknown_model_count" => 4,
             "source_report_model_acceptance_validation_level_counts" => %{
               "analysis" => 4,
               "educational" => 4,
               "unknown" => 4
             },
             "source_report_model_acceptance_model_ids_by_status" => %{
               "blocked" => blocked_ids,
               "review_required" => review_ids
             },
             "source_report_model_acceptance_model_ids_by_validation_level" => %{
               "analysis" => analysis_ids,
               "educational" => educational_ids,
               "unknown" => unknown_ids
             },
             "source_report_model_acceptance_model_ids_by_intended_use" => %{
               "operational_import" => intended_use_ids
             }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    for expected_id <- [
          "direct_blocked_model",
          "direct_unknown_model",
          "canonical_blocked_model",
          "canonical_unknown_model",
          "source_wrapped_blocked_model",
          "source_wrapped_unknown_model",
          "result_wrapped_blocked_model",
          "result_wrapped_unknown_model"
        ] do
      assert expected_id in blocked_ids
    end

    for expected_id <- [
          "direct_review_model",
          "canonical_review_model",
          "source_wrapped_review_model",
          "result_wrapped_review_model"
        ] do
      assert expected_id in review_ids
      assert expected_id in analysis_ids
      assert expected_id in intended_use_ids
    end

    assert "direct_blocked_model" in educational_ids
    assert "canonical_blocked_model" in educational_ids
    assert "source_wrapped_blocked_model" in educational_ids
    assert "result_wrapped_blocked_model" in educational_ids
    assert "direct_unknown_model" in unknown_ids
    assert "canonical_unknown_model" in unknown_ids
    assert "source_wrapped_unknown_model" in unknown_ids
    assert "result_wrapped_unknown_model" in unknown_ids

    assert %{
             "contract" => "model_acceptance_report.v1",
             "source_report_count" => 4,
             "source_report_row_count" => 12,
             "source_report_record_count" => 8,
             "source_report_paths" => replay_source_paths,
             "intended_use_counts" => %{"operational_import" => 4},
             "status_counts" => %{"blocked" => 4},
             "model_count" => 12,
             "review_required_count" => 4,
             "blocked_count" => 8,
             "unknown_model_count" => 4,
             "validation_level_counts" => %{
               "analysis" => 4,
               "educational" => 4,
               "unknown" => 4
             },
             "model_ids_by_status" => %{
               "blocked" => replay_blocked_ids,
               "review_required" => replay_review_ids
             },
             "model_ids_by_validation_level" => %{
               "analysis" => replay_analysis_ids,
               "educational" => replay_educational_ids,
               "unknown" => replay_unknown_ids
             },
             "model_ids_by_intended_use" => %{
               "operational_import" => replay_intended_use_ids
             },
             "trust_boundary_status" => "declared",
             "branch_local_review_pressure" => true,
             "branch_local_blocking_pressure" => true,
             "branch_local_unknown_model_pressure" => true
           } = CandidateRefresh.model_acceptance_replay_summary(candidate_source)

    assert Enum.sort(replay_source_paths) == [
             "mission_state.model_acceptance_report",
             "mission_state.result_artifact.source_model_acceptance_report",
             "mission_state.source_model_acceptance_report",
             "mission_state.source_result_artifact.model_acceptance_report"
           ]

    assert Enum.sort(replay_blocked_ids) == Enum.sort(blocked_ids)
    assert Enum.sort(replay_review_ids) == Enum.sort(review_ids)
    assert Enum.sort(replay_analysis_ids) == Enum.sort(analysis_ids)
    assert Enum.sort(replay_educational_ids) == Enum.sort(educational_ids)
    assert Enum.sort(replay_unknown_ids) == Enum.sort(unknown_ids)
    assert Enum.sort(replay_intended_use_ids) == Enum.sort(intended_use_ids)

    model_acceptance_pressure_count =
      Enum.count(
        urgent["risk_indicators"],
        &(&1["type"] == "model_acceptance_pressure" and
            &1["feedback_source"] == "candidate_source.model_acceptance_replay_summary")
      )

    assert model_acceptance_pressure_count == 1

    assert Enum.any?(
             urgent["risk_indicators"],
             &(&1["type"] == "model_acceptance_pressure" and
                 &1["feedback_scope"] == "model_acceptance" and
                 &1["severity"] == "high" and
                 &1["source_report_count"] == 4 and
                 &1["source_report_row_count"] == 12 and
                 &1["source_report_record_count"] == 8 and
                 &1["source_report_paths"] == replay_source_paths and
                 &1["intended_use_counts"] == %{"operational_import" => 4} and
                 &1["status_counts"] == %{"blocked" => 4} and
                 &1["validation_level_counts"] == %{
                   "analysis" => 4,
                   "educational" => 4,
                   "unknown" => 4
                 } and
                 &1["model_count"] == 12 and
                 &1["review_required_count"] == 4 and
                 &1["blocked_count"] == 8 and
                 &1["unknown_model_count"] == 4 and
                 &1["model_ids_by_status"] == %{
                   "blocked" => replay_blocked_ids,
                   "review_required" => replay_review_ids
                 } and
                 &1["model_ids_by_validation_level"] == %{
                   "analysis" => replay_analysis_ids,
                   "educational" => replay_educational_ids,
                   "unknown" => replay_unknown_ids
                 } and
                 &1["model_ids_by_intended_use"] == %{
                   "operational_import" => replay_intended_use_ids
                 } and
                 &1["model_ids"] == Enum.sort(Enum.uniq(replay_intended_use_ids)) and
                 &1["branch_local_review_pressure"] == true and
                 &1["branch_local_blocking_pressure"] == true and
                 &1["branch_local_unknown_model_pressure"] == true)
           )

    assert_validation_refresh_pressure_score_terms(urgent, artifact, "model_acceptance")

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
