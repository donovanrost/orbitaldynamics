defmodule OrbitalDynamics.Schema.CampaignRepairScoreContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema
  alias OrbitalDynamics.Schema.CampaignRepairScoreContracts

  setup do
    %{artifact: read_json!("study_results/campaign_repair_readiness_source_handoff_v2.json")}
  end

  test "validates the checked-in aggregate repair score explanation", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  test "keeps the score-term report optional", %{artifact: artifact} do
    artifact = Map.delete(artifact, "score_term_report")

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  test "rejects stale aggregate score and score-term values", %{artifact: artifact} do
    invalid_cases = [
      {"$.score", Map.put(artifact, "score", "-96")},
      {"$.score_terms", Map.put(artifact, "score_terms", [])},
      {"$.score_terms.activity_score", put_in(artifact, ["score_terms", "activity_score"], "10")},
      {"$.score", Map.put(artifact, "score", -95.0)}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects activity-score drift hidden by consistent aggregate arithmetic", %{
    artifact: artifact
  } do
    tampered_score = artifact["score"] + 1.0

    invalid =
      artifact
      |> put_in(["score_terms", "activity_score"], 11.0)
      |> Map.put("score", tampered_score)
      |> update_in(["score_term_report", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          row = Map.put(row, "timeline_score", tampered_score)

          if row["term_key"] == "activity_score",
            do: Map.put(row, "value", 11.0),
            else: row
        end)
      end)

    assert {:error, report} = Schema.validate_artifact(invalid)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.score_terms.activity_score")
           )
  end

  test "keeps the activity-score term optional and defaults missing activity values to zero", %{
    artifact: artifact
  } do
    terms_without_activity_score = Map.delete(artifact["score_terms"], "activity_score")

    legacy = %{
      artifact
      | "score" => terms_without_activity_score |> Map.values() |> Enum.sum(),
        "score_terms" => terms_without_activity_score
    }

    assert [] ==
             CampaignRepairScoreContracts.validate(
               [],
               Map.delete(legacy, "score_term_report")
             )

    default_zero =
      legacy
      |> put_in(
        ["activities", Access.at(0)],
        artifact["activities"] |> hd() |> Map.delete("score")
      )
      |> put_in(["score_terms", "activity_score"], 0.0)

    assert [] ==
             CampaignRepairScoreContracts.validate(
               [],
               Map.delete(default_zero, "score_term_report")
             )
  end

  test "rejects schedule-term drift hidden by consistent aggregate arithmetic", %{
    artifact: artifact
  } do
    for term_key <- ["schedule_churn_penalty", "schedule_move_penalty"] do
      invalid = coordinated_term_edit(artifact, term_key, 1.0)

      assert {:error, report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               report["errors"],
               &(&1["path"] == "$.score_terms.#{term_key}")
             )
    end
  end

  test "keeps schedule terms optional and honors action, zero, and default policy semantics", %{
    artifact: artifact
  } do
    unchanged_delta = %{"repair_action" => "unchanged"}

    ignored_action =
      artifact
      |> update_in(["deltas"], &(&1 ++ [unchanged_delta]))
      |> Map.delete("score_term_report")

    assert [] == CampaignRepairScoreContracts.validate([], ignored_action)

    policy_variants = [
      Map.drop(artifact["scoring_policy"], [
        "schedule_churn_cost_weight",
        "schedule_move_cost_weight"
      ]),
      artifact["scoring_policy"]
      |> Map.put("schedule_churn_cost_weight", "100")
      |> Map.put("schedule_move_cost_weight", "0.01")
    ]

    for scoring_policy <- policy_variants do
      variant =
        artifact
        |> Map.put("scoring_policy", scoring_policy)
        |> Map.delete("score_term_report")

      assert [] == CampaignRepairScoreContracts.validate([], variant)
    end

    zero_move =
      artifact
      |> update_in(
        ["activities", Access.at(0), "repair"],
        &Map.delete(&1, "schedule_churn_s")
      )
      |> put_in(["score_terms", "schedule_move_penalty"], 0.0)
      |> Map.put("score", artifact["score"] + 4.0)
      |> Map.delete("score_term_report")

    assert [] == CampaignRepairScoreContracts.validate([], zero_move)

    legacy_terms =
      artifact["score_terms"]
      |> Map.delete("schedule_churn_penalty")
      |> Map.delete("schedule_move_penalty")

    legacy =
      artifact
      |> Map.put("score_terms", legacy_terms)
      |> Map.put("score", legacy_terms |> Map.values() |> Enum.sum())
      |> Map.delete("score_term_report")

    assert [] == CampaignRepairScoreContracts.validate([], legacy)
  end

  test "rejects report-pressure drift hidden by consistent aggregate arithmetic", %{
    artifact: artifact
  } do
    pressured_cases = [
      {"link_capacity_pressure_penalty",
       artifact
       |> put_in(["link_capacity_report", "selected_downlink_shortfall_mb"], 1.0)
       |> put_score_term("link_capacity_pressure_penalty", -1.0)},
      {"resource_projection_pressure_penalty",
       artifact
       |> Map.put("source_resource_projection_report", resource_projection_report())
       |> put_score_term("resource_projection_pressure_penalty", -2.0)}
    ]

    for {term_key, valid} <- pressured_cases do
      assert [] == CampaignRepairScoreContracts.validate([], valid)

      invalid = coordinated_term_edit(valid, term_key, 1.0)

      assert errors = CampaignRepairScoreContracts.validate([], invalid)

      assert Enum.any?(
               errors,
               &(&1["path"] == "$.score_terms.#{term_key}")
             )
    end
  end

  test "honors report-pressure optional, policy, nominal, and malformed semantics", %{
    artifact: artifact
  } do
    numeric_string_policy =
      artifact
      |> put_in(["link_capacity_report", "selected_downlink_shortfall_mb"], 1.0)
      |> put_in(["scoring_policy", "risk_weight"], "0.25")
      |> put_score_term("link_capacity_pressure_penalty", -0.25)

    assert [] == CampaignRepairScoreContracts.validate([], numeric_string_policy)

    zero_risk_weight =
      artifact
      |> Map.put("source_resource_projection_report", resource_projection_report())
      |> put_in(["scoring_policy", "risk_weight"], 0.0)
      |> put_score_term("resource_projection_pressure_penalty", 0.0)

    assert [] == CampaignRepairScoreContracts.validate([], zero_risk_weight)

    nominal_terms =
      artifact
      |> put_score_term("link_capacity_pressure_penalty", 0.0)
      |> put_score_term("resource_projection_pressure_penalty", 0.0)

    assert [] == CampaignRepairScoreContracts.validate([], nominal_terms)

    malformed_reports =
      nominal_terms
      |> Map.put("link_capacity_report", [])
      |> Map.put("source_resource_projection_report", %{"projected_resources" => ["invalid"]})

    assert [] == CampaignRepairScoreContracts.validate([], malformed_reports)
  end

  test "rejects CandidateRefresh pressure drift hidden by aggregate arithmetic", %{
    artifact: artifact
  } do
    pressured_cases = [
      {"candidate_diff_pressure_penalty",
       artifact
       |> Map.put("source_candidate_diff_report", candidate_diff_report())
       |> put_score_term("candidate_diff_pressure_penalty", -1.0)},
      {"refresh_freshness_pressure_penalty",
       artifact
       |> Map.put("source_freshness_report", %{"status" => "stale"})
       |> put_score_term("refresh_freshness_pressure_penalty", -1.0)},
      {"refresh_budget_pressure_penalty",
       artifact
       |> Map.put("source_refresh_budget_report", %{
         "dropped_candidate_ids" => ["dropped_1", nil, "", "dropped_2"]
       })
       |> put_score_term("refresh_budget_pressure_penalty", -2.0)}
    ]

    for {term_key, valid} <- pressured_cases do
      assert [] == CampaignRepairScoreContracts.validate([], valid)

      invalid = coordinated_term_edit(valid, term_key, 1.0)

      assert errors = CampaignRepairScoreContracts.validate([], invalid)

      assert Enum.any?(
               errors,
               &(&1["path"] == "$.score_terms.#{term_key}")
             )
    end
  end

  test "honors CandidateRefresh pressure policy, fallback, and malformed semantics", %{
    artifact: artifact
  } do
    numeric_string_policy =
      artifact
      |> Map.put("source_candidate_diff_report", candidate_diff_report())
      |> put_in(["scoring_policy", "risk_weight"], "0.25")
      |> put_score_term("candidate_diff_pressure_penalty", -0.25)

    assert [] == CampaignRepairScoreContracts.validate([], numeric_string_policy)

    zero_risk_weight =
      artifact
      |> Map.put("source_freshness_report", %{"freshness_status" => "unknown"})
      |> put_in(["scoring_policy", "risk_weight"], 0.0)
      |> put_score_term("refresh_freshness_pressure_penalty", 0.0)

    assert [] == CampaignRepairScoreContracts.validate([], zero_risk_weight)

    fallback_reports = [
      {%{"dropped_candidate_count" => 2.9}, -2.0},
      {%{"invalid_candidate_limit_policy" => true}, -1.0}
    ]

    for {report, expected} <- fallback_reports do
      fallback =
        artifact
        |> Map.put("source_refresh_budget_report", report)
        |> put_score_term("refresh_budget_pressure_penalty", expected)

      assert [] == CampaignRepairScoreContracts.validate([], fallback)
    end

    nominal_terms =
      artifact
      |> put_score_term("candidate_diff_pressure_penalty", 0.0)
      |> put_score_term("refresh_freshness_pressure_penalty", 0.0)
      |> put_score_term("refresh_budget_pressure_penalty", 0.0)

    malformed_reports =
      nominal_terms
      |> Map.put("source_candidate_diff_report", %{
        "invalidated_candidates" => ["invalid"]
      })
      |> Map.put("source_freshness_report", [])
      |> Map.put("source_refresh_budget_report", %{"dropped_candidate_ids" => "invalid"})

    assert [] == CampaignRepairScoreContracts.validate([], malformed_reports)
  end

  test "rejects score-term report drift from the enclosing repair artifact", %{
    artifact: artifact
  } do
    [first_row | _rest] = get_in(artifact, ["score_term_report", "rows"])

    duplicate_term_artifact =
      artifact
      |> update_in(["score_term_report", "rows"], &(&1 ++ [first_row]))
      |> put_in(["score_term_report", "row_count"], 6)

    invalid_cases = [
      {"$.score_term_report.source",
       put_in(artifact, ["score_term_report", "source"], "legacy.score_terms")},
      {"$.score_term_report.rows[0].value",
       put_in(artifact, ["score_term_report", "rows", Access.at(0), "value"], 11.0)},
      {"$.score_term_report.rows[0].timeline_score",
       put_in(
         artifact,
         ["score_term_report", "rows", Access.at(0), "timeline_score"],
         -95.0
       )},
      {"$.score_term_report.rows[0].selected",
       put_in(artifact, ["score_term_report", "rows", Access.at(0), "selected"], false)},
      {"$.score_term_report.rows[0].rank",
       put_in(artifact, ["score_term_report", "rows", Access.at(0), "rank"], 2)},
      {"$.score_term_report.rows", duplicate_term_artifact}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  defp coordinated_term_edit(artifact, term_key, delta) do
    tampered_score = artifact["score"] + delta
    tampered_term = artifact["score_terms"][term_key] + delta

    tampered =
      artifact
      |> put_in(["score_terms", term_key], tampered_term)
      |> Map.put("score", tampered_score)

    case Map.get(tampered, "score_term_report") do
      %{"rows" => _rows} ->
        update_in(tampered, ["score_term_report", "rows"], fn rows ->
          Enum.map(rows, fn row ->
            row = Map.put(row, "timeline_score", tampered_score)

            if row["term_key"] == term_key,
              do: Map.put(row, "value", tampered_term),
              else: row
          end)
        end)

      _report ->
        tampered
    end
  end

  defp put_score_term(artifact, term_key, value) do
    score_terms = Map.put(artifact["score_terms"], term_key, value)

    artifact
    |> Map.put("score_terms", score_terms)
    |> Map.put("score", score_terms |> Map.values() |> Enum.sum())
    |> Map.delete("score_term_report")
  end

  defp resource_projection_report do
    %{
      "projected_resources" => [
        %{
          "spacecraft_id" => "leo_1",
          "projected_storage_overflow_mb" => 1.0,
          "projected_battery_overuse_wh" => 1.0
        }
      ]
    }
  end

  defp candidate_diff_report do
    %{
      "schema_contract" => "candidate_diff_report.v1",
      "model" => "candidate_id_set_diff_with_semantic_change_reasons",
      "prior_candidate_count" => 0,
      "refreshed_candidate_count" => 1,
      "retained_candidate_count" => 0,
      "new_candidate_count" => 1,
      "invalidated_candidate_count" => 0,
      "retained_candidates" => [],
      "new_candidates" => [
        %{
          "id" => "new_candidate",
          "diff_reason" => "not_present_in_prior_candidate_set"
        }
      ],
      "invalidated_candidates" => []
    }
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
