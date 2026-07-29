defmodule OrbitalDynamics.Schema.CampaignStrategyProducedSurfaceContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema
  alias OrbitalDynamics.Schema.CampaignStrategyProducedSurfaceContracts

  @produced_fields ~w(
    source_repair_id
    score_term_report
    objective_tradeoff_report
    pareto_frontier_report
    operational_feedback_provenance
    cadence_import_manifest
  )

  setup_all do
    %{strategy: read_json!("study_results/leo_constellation_campaign_strategy_v3.json")}
  end

  test "validates the complete checked V3 produced top-level surface", %{strategy: strategy} do
    assert {:ok, schema} = Schema.json_schema("campaign_strategy.v3")
    declared_fields = schema["properties"] |> Map.keys() |> MapSet.new()

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3"}} =
             Schema.validate_artifact(strategy)

    assert strategy
           |> Map.keys()
           |> MapSet.new()
           |> MapSet.subset?(declared_fields)
  end

  test "keeps produced-surface fields optional for older strategies", %{strategy: strategy} do
    artifact = Map.drop(strategy, @produced_fields)

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3"}} =
             Schema.validate_artifact(artifact)
  end

  test "rejects CampaignStrategy branch metadata drift", %{strategy: strategy} do
    nonbaseline_branch_id =
      strategy["branches"]
      |> Enum.find(&(&1["branch_id"] != "baseline"))
      |> Map.fetch!("branch_id")

    invalid_cases = [
      {"$.strategy_metadata.branch_count",
       put_in(strategy, ["strategy_metadata", "branch_count"], 0)},
      {"$.strategy_metadata.baseline_branch_id",
       put_in(
         strategy,
         ["strategy_metadata", "baseline_branch_id"],
         nonbaseline_branch_id
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects CampaignStrategy ranked branch eligibility drift", %{strategy: strategy} do
    ranked_branch_ids = strategy["recommendation"]["ranked_branch_ids"]

    blocked_branch_id =
      strategy["branches"]
      |> Enum.find(&(&1["approval_status"] == "blocked_by_policy"))
      |> Map.fetch!("branch_id")

    invalid_cases = [
      ranked_branch_ids ++ [blocked_branch_id],
      Enum.drop(ranked_branch_ids, -1),
      ranked_branch_ids ++ [List.last(ranked_branch_ids)],
      [hd(ranked_branch_ids) | Enum.reverse(tl(ranked_branch_ids))]
    ]

    for invalid_ranked_branch_ids <- invalid_cases do
      invalid =
        put_in(
          strategy,
          ["recommendation", "ranked_branch_ids"],
          invalid_ranked_branch_ids
        )

      assert {:error, report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               report["errors"],
               &(&1["path"] == "$.recommendation.ranked_branch_ids")
             )
    end
  end

  test "keeps the producer all-blocked ranking fallback" do
    artifact = %{
      "branches" => [
        %{"branch_id" => "branch:first", "approval_status" => "blocked_by_policy"},
        %{"branch_id" => "branch:second", "approval_status" => "blocked_by_policy"}
      ],
      "recommendation" => %{
        "ranked_branch_ids" => ["branch:first", "branch:second"]
      }
    }

    assert [] == CampaignStrategyProducedSurfaceContracts.validate([], artifact)
  end

  test "rejects CampaignStrategy recommended branch evidence drift", %{strategy: strategy} do
    approval_status_drift =
      strategy
      |> put_in(["recommendation", "approval_status"], "blocked_by_policy")
      |> update_in(["recommendation", "requires_approval"], fn rows ->
        Enum.map(rows, &Map.put(&1, "policy_classification", "blocked_by_policy"))
      end)

    invalid_cases = [
      {"$.recommendation.reason",
       put_in(strategy, ["recommendation", "reason"], "schema_valid_drift")},
      {"$.recommendation.risks_remaining",
       update_in(strategy, ["recommendation", "risks_remaining"], &tl/1)},
      {"$.recommendation.requires_approval",
       put_in(strategy, ["recommendation", "requires_approval"], [])},
      {"$.recommendation.approval_status", approval_status_drift}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "accepts every producer recommendation reason" do
    cases = [
      {"auto_approvable", "best_expected_score_within_auto_approval_policy"},
      {"operator_review_required", "best_expected_score_requiring_operator_review"},
      {"blocked_by_policy", "all_branches_blocked_highest_score_reported_for_review"}
    ]

    for {approval_status, reason} <- cases do
      artifact = %{
        "branches" => [
          %{
            "branch_id" => "branch:selected",
            "approval_status" => approval_status,
            "risk_indicators" => [],
            "approval_requirements" => []
          }
        ],
        "recommendation" => %{
          "recommended_branch_id" => "branch:selected",
          "ranked_branch_ids" => ["branch:selected"],
          "approval_status" => approval_status,
          "reason" => reason,
          "risks_remaining" => [],
          "requires_approval" => []
        }
      }

      assert [] == CampaignStrategyProducedSurfaceContracts.validate([], artifact)
    end
  end

  test "rejects CampaignStrategy branch comparison identity drift", %{strategy: strategy} do
    report = strategy["branch_comparison_report"]
    [first, second, third | rest] = report["rows"]

    reordered =
      put_in(
        strategy,
        ["branch_comparison_report", "rows"],
        [first, third, second | rest]
      )

    alternate_recommended_branch_id = second["branch_id"]
    alternate_recommended_score = second["score"]

    alternate_report =
      report
      |> Map.put("recommended_branch_id", alternate_recommended_branch_id)
      |> Map.update!("rows", fn rows ->
        Enum.map(rows, fn row ->
          row
          |> Map.put("selected", row["branch_id"] == alternate_recommended_branch_id)
          |> Map.put(
            "score_delta_from_recommended",
            row["score"] - alternate_recommended_score
          )
        end)
      end)

    invalid_cases = [
      {"$.branch_comparison_report.rows", reordered},
      {"$.branch_comparison_report.recommended_branch_id",
       Map.put(strategy, "branch_comparison_report", alternate_report)}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, validation_report} = Schema.validate_artifact(invalid)
      assert Enum.any?(validation_report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "keeps additive CampaignStrategy source provenance copies optional", %{
    strategy: strategy
  } do
    older =
      strategy
      |> update_in(["provenance"], &Map.delete(&1, "source_plan_id"))
      |> update_in(
        ["operator_review_package", "provenance"],
        &Map.delete(&1, "source_plan_id")
      )
      |> update_in(
        ["cadence_import_manifest", "provenance"],
        &Map.delete(&1, "source_plan_id")
      )

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3"}} =
             Schema.validate_artifact(older)
  end

  test "rejects CampaignStrategy source provenance drift", %{strategy: strategy} do
    invalid_cases = [
      {"$.provenance.source_plan_id",
       put_in(strategy, ["provenance", "source_plan_id"], "campaign_plan:drift")},
      {"$.operator_review_package.provenance.source_plan_id",
       put_in(
         strategy,
         ["operator_review_package", "provenance", "source_plan_id"],
         "campaign_plan:drift"
       )},
      {"$.operator_review_package.provenance.source_planner",
       put_in(
         strategy,
         ["operator_review_package", "provenance", "source_planner"],
         "OrbitalDynamics.CampaignPlanner.Drift"
       )},
      {"$.operator_review_package.provenance.source_plan_generated_at",
       put_in(
         strategy,
         ["operator_review_package", "provenance", "source_plan_generated_at"],
         "2026-05-15T00:00:00Z"
       )},
      {"$.operator_review_package.provenance.source_provenance",
       update_in(
         strategy,
         ["operator_review_package", "provenance", "source_provenance"],
         &Map.put(&1, "run_id", "drift")
       )},
      {"$.cadence_import_manifest.provenance.source_plan_id",
       put_in(
         strategy,
         ["cadence_import_manifest", "provenance", "source_plan_id"],
         "campaign_plan:drift"
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects produced-surface drift at nested paths", %{strategy: strategy} do
    invalid =
      strategy
      |> Map.put("source_repair_id", "not a stable id")
      |> put_in(["score_term_report", "schema_contract"], "score_term_report.v0")
      |> put_in(
        ["objective_tradeoff_report", "schema_contract"],
        "objective_tradeoff_report.v0"
      )
      |> put_in(["pareto_frontier_report", "schema_contract"], "pareto_frontier_report.v0")
      |> put_in(["operational_feedback_provenance", "source_count"], 2)
      |> put_in(["cadence_import_manifest", "schema_contract"], "cadence_import_manifest.v0")

    assert {:error, validation_report} = Schema.validate_artifact(invalid)

    expected_paths = [
      "$.source_repair_id",
      "$.score_term_report.schema_contract",
      "$.objective_tradeoff_report.schema_contract",
      "$.pareto_frontier_report.schema_contract",
      "$.operational_feedback_provenance.source_count",
      "$.cadence_import_manifest.schema_contract"
    ]

    for expected_path <- expected_paths do
      assert Enum.any?(validation_report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "exports direct schemas for every produced-surface report" do
    assert {:ok, schema} = Schema.json_schema("campaign_strategy.v3")
    properties = schema["properties"]

    assert properties["source_repair_id"]["type"] == ["string", "null"]

    assert get_in(properties, ["score_term_report", "properties", "schema_contract", "const"]) ==
             "score_term_report.v1"

    assert get_in(properties, [
             "objective_tradeoff_report",
             "properties",
             "schema_contract",
             "const"
           ]) == "objective_tradeoff_report.v1"

    assert get_in(properties, [
             "pareto_frontier_report",
             "properties",
             "schema_contract",
             "const"
           ]) == "pareto_frontier_report.v1"

    assert get_in(properties, [
             "cadence_import_manifest",
             "properties",
             "schema_contract",
             "const"
           ]) == "cadence_import_manifest.v1"

    assert get_in(properties, [
             "operational_feedback_provenance",
             "properties",
             "source_count"
           ]) == %{"minimum" => 0, "type" => "integer"}
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
