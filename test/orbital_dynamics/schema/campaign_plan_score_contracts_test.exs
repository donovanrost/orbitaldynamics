defmodule OrbitalDynamics.Schema.CampaignPlanScoreContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.ScoreReports
  alias OrbitalDynamics.Schema

  setup do
    artifact =
      "study_results/leo_constellation_campaign.json"
      |> read_json!()
      |> Map.fetch!("campaign_plan")

    %{artifact: artifact}
  end

  test "validates the checked-in ranked timeline score explanation", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "validates a multi-timeline score report", %{artifact: artifact} do
    [first_timeline] = artifact["ranked_timelines"]

    second_timeline =
      first_timeline
      |> Map.put("scenario_id", "leo_2")
      |> Map.put("score", first_timeline["score"] - 10.0)

    timelines = [first_timeline, second_timeline]
    policy = get_in(artifact, ["score_term_report", "assumptions", "policy"])

    report =
      ScoreReports.score_term_report(
        timelines,
        policy,
        OrbitalDynamics.CampaignPlanner.score_report_model_limits()
      )

    tradeoff_report =
      ScoreReports.objective_tradeoff_report(
        timelines,
        artifact["objective_tradeoff_report"]["policy"],
        OrbitalDynamics.CampaignPlanner.score_report_model_limits()
      )

    artifact =
      artifact
      |> Map.put("ranked_timelines", timelines)
      |> Map.put("score_term_report", report)
      |> Map.put("objective_tradeoff_report", tradeoff_report)
      |> Map.put("optimizer_contract", optimizer_contract(artifact, timelines))

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "keeps the score-term report optional", %{artifact: artifact} do
    artifact = Map.delete(artifact, "score_term_report")

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "rejects malformed ranked timeline score shapes", %{artifact: artifact} do
    invalid_cases = [
      {"$.ranked_timelines[0]", Map.put(artifact, "ranked_timelines", ["not-a-timeline"])},
      {"$.ranked_timelines[0].scenario_id",
       put_in(artifact, ["ranked_timelines", Access.at(0), "scenario_id"], "bad id")},
      {"$.ranked_timelines[0].score",
       put_in(artifact, ["ranked_timelines", Access.at(0), "score"], "10")},
      {"$.ranked_timelines[0].score_terms",
       put_in(artifact, ["ranked_timelines", Access.at(0), "score_terms"], [])},
      {"$.ranked_timelines[0].score_terms.activity_score",
       put_in(
         artifact,
         ["ranked_timelines", Access.at(0), "score_terms", "activity_score"],
         "10"
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects score-term report drift from ranked timelines", %{artifact: artifact} do
    [first_row | _rest] = get_in(artifact, ["score_term_report", "rows"])

    duplicate_row_artifact =
      artifact
      |> update_in(["score_term_report", "rows"], &(&1 ++ [first_row]))
      |> put_in(["score_term_report", "row_count"], 8)

    invalid_cases = [
      {"$.score_term_report.model",
       put_in(artifact, ["score_term_report", "model"], "repair_score_terms")},
      {"$.score_term_report.source",
       put_in(artifact, ["score_term_report", "source"], "legacy.ranked_timelines")},
      {"$.score_term_report.rows[0]",
       put_in(artifact, ["score_term_report", "rows", Access.at(0), "rank"], 2)},
      {"$.score_term_report.rows[0]",
       put_in(artifact, ["score_term_report", "rows", Access.at(0), "scenario_id"], "leo_2")},
      {"$.score_term_report.rows[0].value",
       put_in(artifact, ["score_term_report", "rows", Access.at(0), "value"], -1.0)},
      {"$.score_term_report.rows[0].timeline_score",
       put_in(
         artifact,
         ["score_term_report", "rows", Access.at(0), "timeline_score"],
         -1.0
       )},
      {"$.score_term_report.rows[0].selected",
       put_in(artifact, ["score_term_report", "rows", Access.at(0), "selected"], false)},
      {"$.score_term_report.rows", duplicate_row_artifact}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "reports malformed score-term rows without crashing", %{artifact: artifact} do
    invalid = put_in(artifact, ["score_term_report", "rows"], ["not-a-row"])

    assert {:error, report} = Schema.validate_artifact(invalid)
    assert Enum.any?(report["errors"], &(&1["path"] == "$.rows[0]"))
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end

  defp optimizer_contract(artifact, timelines) do
    OrbitalDynamics.Optimizer.greedy_timeline_contract(
      artifact["candidate_activities"],
      timelines,
      plan_id: artifact["plan_id"],
      constraints: get_in(artifact, ["assumptions", "constraints"]),
      scoring_policy: get_in(artifact, ["assumptions", "scoring_policy"])
    )
  end
end
