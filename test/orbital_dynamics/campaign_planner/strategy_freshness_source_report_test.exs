Code.require_file("support.exs", __DIR__)

defmodule OrbitalDynamics.CampaignPlanner.StrategyFreshnessSourceReportTest do
  use ExUnit.Case, async: true

  import OrbitalDynamics.CampaignPlanner.TestSupport

  alias OrbitalDynamics.CandidateRefresh
  alias OrbitalDynamics.Schema

  test "strategy carries mission-state freshness reports into branch refresh requests" do
    direct_report =
      freshness_report("stale")
      |> Map.put("stale_reasons", ["accepted_snapshot_older_than_policy"])
      |> Map.put("provenance", %{"trust_boundary" => "direct_freshness_boundary"})

    canonical_report =
      freshness_report("stale")
      |> Map.put("stale_reasons", ["horizon_start_offset_exceeds_policy"])
      |> Map.put("provenance", %{"trust_boundary" => "canonical_freshness_boundary"})

    source_wrapped_report =
      freshness_report("unknown")
      |> Map.put("unknown_reasons", ["accepted_snapshot_missing"])
      |> Map.put("provenance", %{"trust_boundary" => "source_wrapped_freshness_boundary"})

    result_wrapped_report =
      freshness_report("stale")
      |> Map.put("stale_reasons", ["horizon_start_offset_exceeds_policy"])
      |> Map.put("provenance", %{"trust_boundary" => "result_wrapped_freshness_boundary"})

    mission_state =
      mission_state_with_refresh_inputs()
      |> Map.put("source_freshness_report", direct_report)
      |> Map.put("freshness_report", canonical_report)
      |> Map.put(:source_result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "freshness_report" => Map.delete(source_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "source_wrapped_freshness_boundary"}
      })
      |> Map.put(:result_artifact, %{
        "schema_contract" => "result_artifact.v1",
        "artifact_type" => "mission_state_result_artifact",
        "source_freshness_report" => Map.delete(result_wrapped_report, "provenance"),
        "provenance" => %{"trust_boundary" => "result_wrapped_freshness_boundary"}
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
          "mission_state.source_freshness_report",
          "mission_state.freshness_report",
          "mission_state.source_result_artifact.freshness_report",
          "mission_state.result_artifact.source_freshness_report"
        ] do
      assert source_path in candidate_source["source_report_input_paths"]

      assert source_path in candidate_source[
               "candidate_refresh_request_source_report_input_paths"
             ]
    end

    assert %{
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_freshness_status_counts" => %{"stale" => 3, "unknown" => 1},
             "source_report_freshness_stale_reason_count" => 3,
             "source_report_freshness_stale_reasons" => stale_reasons,
             "source_report_freshness_stale_reason_counts" => %{
               "accepted_snapshot_older_than_policy" => 1,
               "horizon_start_offset_exceeds_policy" => 2
             },
             "source_report_freshness_unknown_reason_count" => 1,
             "source_report_freshness_unknown_reasons" => ["accepted_snapshot_missing"],
             "source_report_freshness_unknown_reason_counts" => %{
               "accepted_snapshot_missing" => 1
             }
           } = candidate_source["candidate_refresh_request_source_report_summary"]

    assert Enum.sort(stale_reasons) == [
             "accepted_snapshot_older_than_policy",
             "horizon_start_offset_exceeds_policy"
           ]

    assert %{
             "contract" => "freshness_report.v1",
             "source_report_count" => 4,
             "source_report_row_count" => 4,
             "source_report_paths" => replay_source_paths,
             "status_counts" => %{"stale" => 3, "unknown" => 1},
             "stale_reason_count" => 3,
             "stale_reasons" => replay_stale_reasons,
             "stale_reason_counts" => %{
               "accepted_snapshot_older_than_policy" => 1,
               "horizon_start_offset_exceeds_policy" => 2
             },
             "unknown_reason_count" => 1,
             "unknown_reasons" => ["accepted_snapshot_missing"],
             "unknown_reason_counts" => %{"accepted_snapshot_missing" => 1},
             "trust_boundary_status" => "declared",
             "branch_local_stale_pressure" => true,
             "branch_local_unknown_pressure" => true,
             "branch_local_freshness_pressure" => true
           } = CandidateRefresh.freshness_replay_summary(candidate_source)

    assert Enum.sort(replay_stale_reasons) == [
             "accepted_snapshot_older_than_policy",
             "horizon_start_offset_exceeds_policy"
           ]

    assert Enum.sort(replay_source_paths) == [
             "mission_state.freshness_report",
             "mission_state.result_artifact.source_freshness_report",
             "mission_state.source_freshness_report",
             "mission_state.source_result_artifact.freshness_report"
           ]

    freshness_pressure_count =
      Enum.count(
        urgent["risk_indicators"],
        &(&1["type"] == "refresh_freshness_pressure" and
            &1["feedback_source"] == "candidate_source.freshness_replay_summary")
      )

    assert freshness_pressure_count == 1

    assert Enum.any?(
             urgent["risk_indicators"],
             &(&1["type"] == "refresh_freshness_pressure" and
                 &1["feedback_scope"] == "refresh_freshness" and
                 &1["severity"] == "medium" and
                 &1["source_report_count"] == 4 and
                 &1["source_report_row_count"] == 4 and
                 &1["source_report_paths"] == replay_source_paths and
                 &1["status_counts"] == %{"stale" => 3, "unknown" => 1} and
                 &1["freshness_status"] == "stale" and
                 &1["freshness_statuses"] == ["stale", "unknown"] and
                 &1["state_quality_status"] == "stale" and
                 &1["stale_reason_count"] == 3 and
                 &1["stale_reasons"] == Enum.sort(replay_stale_reasons) and
                 &1["stale_reason_counts"] == %{
                   "accepted_snapshot_older_than_policy" => 1,
                   "horizon_start_offset_exceeds_policy" => 2
                 } and
                 &1["unknown_reason_count"] == 1 and
                 &1["unknown_reasons"] == ["accepted_snapshot_missing"] and
                 &1["unknown_reason_counts"] == %{"accepted_snapshot_missing" => 1} and
                 &1["branch_local_stale_pressure"] == true and
                 &1["branch_local_unknown_pressure"] == true and
                 &1["branch_local_freshness_pressure"] == true)
           )

    assert_validation_refresh_pressure_score_terms(urgent, artifact, "refresh_freshness")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "strategy challenge scores freshness replay from reasons when top-level status is stale" do
    stale_current_report =
      freshness_report("current")
      |> Map.put("stale_reasons", [
        "accepted_snapshot_older_than_policy",
        "horizon_start_offset_exceeds_policy"
      ])
      |> Map.put("unknown_reasons", ["state_quality_missing"])
      |> Map.put("provenance", %{"trust_boundary" => "stale_current_freshness_boundary"})

    artifact =
      strategy(base_plan(%{}),
        mission_state:
          mission_state_with_refresh_inputs()
          |> Map.put(:source_freshness_report, stale_current_report),
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
             "status_counts" => %{"current" => 1},
             "stale_reason_count" => 2,
             "stale_reasons" => stale_reasons,
             "stale_reason_counts" => %{
               "accepted_snapshot_older_than_policy" => 1,
               "horizon_start_offset_exceeds_policy" => 1
             },
             "unknown_reason_count" => 1,
             "unknown_reasons" => ["state_quality_missing"],
             "unknown_reason_counts" => %{"state_quality_missing" => 1},
             "branch_local_stale_pressure" => true,
             "branch_local_unknown_pressure" => true,
             "branch_local_freshness_pressure" => true
           } = CandidateRefresh.freshness_replay_summary(candidate_source)

    assert Enum.sort(stale_reasons) == [
             "accepted_snapshot_older_than_policy",
             "horizon_start_offset_exceeds_policy"
           ]

    assert Enum.any?(
             urgent["risk_indicators"],
             &(&1["type"] == "refresh_freshness_pressure" and
                 &1["feedback_source"] == "candidate_source.freshness_replay_summary" and
                 &1["severity"] == "medium" and
                 &1["freshness_status"] == "stale" and
                 &1["freshness_statuses"] == ["current", "stale", "unknown"] and
                 &1["state_quality_status"] == "stale" and
                 &1["status_counts"] == %{"current" => 1} and
                 &1["stale_reason_count"] == 2 and
                 &1["stale_reasons"] == Enum.sort(stale_reasons) and
                 &1["unknown_reason_count"] == 1 and
                 &1["unknown_reasons"] == ["state_quality_missing"] and
                 &1["branch_local_stale_pressure"] == true and
                 &1["branch_local_unknown_pressure"] == true and
                 &1["branch_local_freshness_pressure"] == true)
           )

    assert_validation_refresh_pressure_score_terms(urgent, artifact, "refresh_freshness")

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  defp freshness_report(status) do
    stale_reasons =
      if status == "stale",
        do: ["accepted_snapshot_older_than_policy"],
        else: []

    %{
      "schema_contract" => "freshness_report.v1",
      "model" => "accepted_snapshot_horizon_and_quality_freshness",
      "generated_at" => "2026-05-14T00:00:00Z",
      "accepted_at" => "2026-05-13T23:00:00Z",
      "current_epoch_s" => 165.0,
      "horizon_starts_at_s" => 165.0,
      "accepted_snapshot_age_s" => 3600.0,
      "horizon_start_offset_s" => 0.0,
      "max_snapshot_age_s" => 60.0,
      "max_horizon_start_offset_s" => 1.0,
      "status" => status,
      "stale_reasons" => stale_reasons,
      "unknown_reasons" => []
    }
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
