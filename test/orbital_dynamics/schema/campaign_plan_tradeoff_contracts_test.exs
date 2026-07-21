defmodule OrbitalDynamics.Schema.CampaignPlanTradeoffContractsTest do
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

  test "validates the checked-in objective tradeoff correspondence", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "validates a generated multi-timeline objective tradeoff", %{artifact: artifact} do
    [first_timeline] = artifact["ranked_timelines"]

    second_timeline =
      first_timeline
      |> Map.put("scenario_id", "leo_2")
      |> Map.put("score", first_timeline["score"] - 10.0)

    timelines = [first_timeline, second_timeline]
    policy = artifact["objective_tradeoff_report"]["policy"]

    report =
      ScoreReports.objective_tradeoff_report(
        timelines,
        policy,
        OrbitalDynamics.CampaignPlanner.score_report_model_limits()
      )

    score_term_report =
      ScoreReports.score_term_report(
        timelines,
        get_in(artifact, ["score_term_report", "assumptions", "policy"]),
        OrbitalDynamics.CampaignPlanner.score_report_model_limits()
      )

    artifact =
      artifact
      |> Map.put("ranked_timelines", timelines)
      |> Map.put("objective_tradeoff_report", report)
      |> Map.put("score_term_report", score_term_report)

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "keeps the objective tradeoff report optional", %{artifact: artifact} do
    artifact = Map.delete(artifact, "objective_tradeoff_report")

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "validates empty ranked timeline explanations", %{artifact: artifact} do
    limits = OrbitalDynamics.CampaignPlanner.score_report_model_limits()

    artifact =
      artifact
      |> Map.put("ranked_timelines", [])
      |> Map.put(
        "objective_tradeoff_report",
        ScoreReports.objective_tradeoff_report(
          [],
          artifact["objective_tradeoff_report"]["policy"],
          limits
        )
      )
      |> Map.put(
        "score_term_report",
        ScoreReports.score_term_report(
          [],
          get_in(artifact, ["score_term_report", "assumptions", "policy"]),
          limits
        )
      )

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "rejects malformed ranked timeline activity envelopes", %{artifact: artifact} do
    invalid_cases = [
      {"$.ranked_timelines[0].activity_count",
       put_in(artifact, ["ranked_timelines", Access.at(0), "activity_count"], -1)},
      {"$.ranked_timelines[0].activities",
       put_in(artifact, ["ranked_timelines", Access.at(0), "activities"], %{})},
      {"$.ranked_timelines[0].activities[0]",
       put_in(artifact, ["ranked_timelines", Access.at(0), "activities"], ["not-an-activity"])},
      {"$.ranked_timelines[0].activity_count",
       put_in(artifact, ["ranked_timelines", Access.at(0), "activity_count"], 2)}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects objective tradeoff drift from ranked timelines", %{artifact: artifact} do
    [first_row | _rest] = get_in(artifact, ["objective_tradeoff_report", "tradeoffs"])

    duplicate_row_artifact =
      artifact
      |> update_in(["objective_tradeoff_report", "tradeoffs"], &(&1 ++ [first_row]))
      |> put_in(["objective_tradeoff_report", "ranking_count"], 2)

    invalid_cases = [
      {"$.objective_tradeoff_report.model",
       put_in(
         artifact,
         ["objective_tradeoff_report", "model"],
         "repair_score_term_tradeoffs"
       )},
      {"$.objective_tradeoff_report.assumptions.source",
       put_in(
         artifact,
         ["objective_tradeoff_report", "assumptions", "source"],
         "legacy.ranked_timelines"
       )},
      {"$.objective_tradeoff_report.tradeoffs[0]",
       put_in(artifact, ["objective_tradeoff_report", "tradeoffs", Access.at(0), "rank"], 2)},
      {"$.objective_tradeoff_report.tradeoffs[0].score",
       put_in(
         artifact,
         ["objective_tradeoff_report", "tradeoffs", Access.at(0), "score"],
         -1.0
       )},
      {"$.objective_tradeoff_report.tradeoffs[0].score_delta_from_selected",
       put_in(
         artifact,
         [
           "objective_tradeoff_report",
           "tradeoffs",
           Access.at(0),
           "score_delta_from_selected"
         ],
         -1.0
       )},
      {"$.objective_tradeoff_report.tradeoffs[0].score_terms",
       put_in(
         artifact,
         [
           "objective_tradeoff_report",
           "tradeoffs",
           Access.at(0),
           "score_terms",
           "activity_score"
         ],
         -1.0
       )},
      {"$.objective_tradeoff_report.tradeoffs[0].activity_ids",
       put_in(
         artifact,
         ["objective_tradeoff_report", "tradeoffs", Access.at(0), "activity_ids"],
         ["other_activity"]
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
         0
       )},
      {"$.objective_tradeoff_report.tradeoffs", duplicate_row_artifact}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "reports malformed tradeoff rows without crashing", %{artifact: artifact} do
    invalid_rows =
      put_in(artifact, ["objective_tradeoff_report", "tradeoffs"], ["not-a-row"])

    invalid_assumptions =
      put_in(artifact, ["objective_tradeoff_report", "assumptions"], [])

    assert {:error, rows_report} = Schema.validate_artifact(invalid_rows)
    assert Enum.any?(rows_report["errors"], &(&1["path"] == "$.tradeoffs[0]"))

    assert {:error, assumptions_report} = Schema.validate_artifact(invalid_assumptions)
    assert Enum.any?(assumptions_report["errors"], &(&1["path"] == "$.assumptions"))
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
