defmodule OrbitalDynamics.Schema.CampaignRepairObjectiveTradeoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  setup do
    %{artifact: read_json!("study_results/campaign_repair_readiness_source_handoff_v2.json")}
  end

  test "validates the checked-in repair objective explanation", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  test "keeps the repair objective explanation optional", %{artifact: artifact} do
    artifact = Map.delete(artifact, "objective_tradeoff_report")

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  test "rejects objective-report drift from enclosing repair fields", %{artifact: artifact} do
    report = artifact["objective_tradeoff_report"]
    [row] = report["tradeoffs"]

    score_terms_with_extra = Map.put(row["score_terms"], "future_explanation", 0.0)

    invalid_cases = [
      {"$.objective_tradeoff_report.model",
       put_in(
         artifact,
         ["objective_tradeoff_report", "model"],
         "ranked_timeline_score_term_tradeoffs"
       )},
      {"$.objective_tradeoff_report.ranking_count",
       put_in(artifact, ["objective_tradeoff_report", "ranking_count"], 2)},
      {"$.objective_tradeoff_report.score_term_keys",
       put_in(artifact, ["objective_tradeoff_report", "score_term_keys"], ["activity_score"])},
      {"$.objective_tradeoff_report.policy",
       put_in(artifact, ["objective_tradeoff_report", "policy", "risk_weight"], 2.0)},
      {"$.objective_tradeoff_report.tradeoffs[0].rank",
       put_in(artifact, ["objective_tradeoff_report", "tradeoffs", Access.at(0), "rank"], 2)},
      {"$.objective_tradeoff_report.tradeoffs[0].scenario_id",
       put_in(
         artifact,
         ["objective_tradeoff_report", "tradeoffs", Access.at(0), "scenario_id"],
         "campaign_plan:other:2026-05-13T00:00:00Z"
       )},
      {"$.objective_tradeoff_report.tradeoffs[0].score",
       put_in(artifact, ["objective_tradeoff_report", "tradeoffs", Access.at(0), "score"], -95.0)},
      {"$.objective_tradeoff_report.tradeoffs[0].score_delta_from_selected",
       put_in(
         artifact,
         [
           "objective_tradeoff_report",
           "tradeoffs",
           Access.at(0),
           "score_delta_from_selected"
         ],
         1.0
       )},
      {"$.objective_tradeoff_report.tradeoffs[0].activity_count",
       artifact
       |> put_in(
         ["objective_tradeoff_report", "tradeoffs", Access.at(0), "activity_count"],
         2
       )
       |> put_in(
         ["objective_tradeoff_report", "tradeoffs", Access.at(0), "activity_ids"],
         ["dl_ready", "extra_activity"]
       )},
      {"$.objective_tradeoff_report.tradeoffs[0].activity_ids",
       put_in(
         artifact,
         ["objective_tradeoff_report", "tradeoffs", Access.at(0), "activity_ids"],
         ["other_activity"]
       )},
      {"$.objective_tradeoff_report.tradeoffs[0].score_terms",
       artifact
       |> put_in(
         ["objective_tradeoff_report", "tradeoffs", Access.at(0), "score_terms"],
         score_terms_with_extra
       )
       |> put_in(
         ["objective_tradeoff_report", "score_term_keys"],
         score_terms_with_extra |> Map.keys() |> Enum.sort()
       )},
      {"$.objective_tradeoff_report.tradeoffs[0].selected_observation_count",
       put_in(
         artifact,
         [
           "objective_tradeoff_report",
           "tradeoffs",
           Access.at(0),
           "selected_observation_count"
         ],
         1
       )},
      {"$.objective_tradeoff_report.tradeoffs[0].selected_contact_count",
       put_in(
         artifact,
         [
           "objective_tradeoff_report",
           "tradeoffs",
           Access.at(0),
           "selected_contact_count"
         ],
         1
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, validation_report} = Schema.validate_artifact(invalid)
      assert Enum.any?(validation_report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects an internally counted duplicate repair tradeoff row", %{artifact: artifact} do
    [row] = artifact["objective_tradeoff_report"]["tradeoffs"]

    invalid =
      artifact
      |> put_in(["objective_tradeoff_report", "ranking_count"], 2)
      |> put_in(["objective_tradeoff_report", "tradeoffs"], [row, Map.put(row, "rank", 2)])

    assert {:error, report} = Schema.validate_artifact(invalid)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.objective_tradeoff_report.tradeoffs")
           )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
