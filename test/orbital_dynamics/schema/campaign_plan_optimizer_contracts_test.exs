defmodule OrbitalDynamics.Schema.CampaignPlanOptimizerContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  setup do
    artifact =
      "study_results/leo_constellation_campaign.json"
      |> read_json!()
      |> Map.fetch!("campaign_plan")

    %{artifact: artifact}
  end

  test "validates the checked-in V1 optimizer handoff", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "keeps the optimizer contract optional", %{artifact: artifact} do
    artifact = Map.delete(artifact, "optimizer_contract")

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "rejects malformed ranking explanations", %{artifact: artifact} do
    invalid_cases = [
      {"$.ranking_explanation.objective",
       put_in(artifact, ["ranking_explanation", "objective"], 1)},
      {"$.ranking_explanation.formula",
       put_in(artifact, ["ranking_explanation", "formula"], nil)},
      {"$.ranking_explanation.policy", put_in(artifact, ["ranking_explanation", "policy"], [])}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects optimizer collection drift from the enclosing plan", %{artifact: artifact} do
    optimizer = artifact["optimizer_contract"]

    candidate_drift =
      artifact
      |> put_in(
        ["optimizer_contract", "candidate_activity_ids"],
        optimizer["candidate_activity_ids"] ++ ["other_candidate"]
      )
      |> put_in(["optimizer_contract", "candidate_count"], optimizer["candidate_count"] + 1)

    selected_drift =
      artifact
      |> put_in(
        ["optimizer_contract", "selected_activity_ids"],
        [List.first(optimizer["candidate_activity_ids"])]
      )

    ranked_drift =
      artifact
      |> put_in(["optimizer_contract", "ranked_scenario_ids"], ["leo_2"])

    term_drift =
      artifact
      |> put_in(["optimizer_contract", "score_term_keys"], ["legacy_score"])

    invalid_cases = [
      {"$.optimizer_contract.candidate_activity_ids", candidate_drift},
      {"$.optimizer_contract.selected_activity_ids", selected_drift},
      {"$.optimizer_contract.ranked_scenario_ids", ranked_drift},
      {"$.optimizer_contract.score_term_keys", term_drift}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects optimizer policy and objective drift", %{artifact: artifact} do
    invalid_cases = [
      {"$.optimizer_contract.optimizer",
       put_in(artifact, ["optimizer_contract", "optimizer"], "legacy_optimizer")},
      {"$.optimizer_contract.selection_policy",
       put_in(
         artifact,
         ["optimizer_contract", "selection_policy"],
         "legacy_selection"
       )},
      {"$.optimizer_contract.constraints",
       put_in(artifact, ["optimizer_contract", "constraints", "avoid_eclipse"], false)},
      {"$.optimizer_contract.scoring_policy",
       put_in(artifact, ["optimizer_contract", "scoring_policy", "rank_limit"], 3)},
      {"$.ranking_explanation.policy",
       put_in(artifact, ["ranking_explanation", "policy", "rank_limit"], 3)},
      {"$.objective_tradeoff_report.policy",
       put_in(artifact, ["objective_tradeoff_report", "policy", "rank_limit"], 3)},
      {"$.score_term_report.assumptions.policy",
       put_in(artifact, ["score_term_report", "assumptions", "policy", "rank_limit"], 3)},
      {"$.optimizer_contract.objective",
       put_in(artifact, ["optimizer_contract", "objective"], "legacy objective")},
      {"$.objective_tradeoff_report.objective",
       put_in(artifact, ["objective_tradeoff_report", "objective"], "legacy objective")}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "reports malformed optimizer input without crashing", %{artifact: artifact} do
    invalid = put_in(artifact, ["optimizer_contract", "assumptions"], [])

    assert {:error, report} = Schema.validate_artifact(invalid)
    assert Enum.any?(report["errors"], &(&1["path"] == "$.assumptions"))
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
