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

  test "exports numeric activity score terms on every V1 activity surface" do
    assert {:ok, schema} = Schema.json_schema("campaign_plan.v1")

    for {schema_path, _artifact_path} <- activity_surfaces() do
      activity_schema = get_in(schema, schema_path)

      assert "score" in activity_schema["required"]
      assert "score_terms" in activity_schema["required"]
      assert get_in(activity_schema, ["properties", "score", "type"]) == "number"

      assert get_in(activity_schema, [
               "properties",
               "score_terms",
               "additionalProperties",
               "type"
             ]) == "number"
    end
  end

  test "requires activity score evidence on every V1 activity surface", %{artifact: artifact} do
    for {_schema_path, {access, path}} <- activity_surfaces(),
        field <- ["score", "score_terms"] do
      invalid = update_in(artifact, access, &Map.delete(&1, field))

      assert {:error, report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               report["errors"],
               &(&1["path"] == "#{path}.#{field}" and &1["message"] == "is required")
             )
    end
  end

  test "rejects malformed activity score shapes on every V1 activity surface", %{
    artifact: artifact
  } do
    for {_schema_path, {access, path}} <- activity_surfaces() do
      invalid_score = put_in(artifact, access ++ ["score"], "10")
      assert {:error, score_report} = Schema.validate_artifact(invalid_score)

      assert Enum.any?(
               score_report["errors"],
               &(&1["path"] == path <> ".score" and &1["message"] == "must be a number")
             )

      invalid_terms = put_in(artifact, access ++ ["score_terms"], [])
      assert {:error, terms_report} = Schema.validate_artifact(invalid_terms)

      assert Enum.any?(
               terms_report["errors"],
               &(&1["path"] == path <> ".score_terms" and
                   &1["message"] == "must be a map")
             )
    end
  end

  test "rejects non-numeric activity score terms on every V1 activity surface", %{
    artifact: artifact
  } do
    for {_schema_path, {access, path}} <- activity_surfaces() do
      invalid = put_in(artifact, access ++ ["score_terms", "invalid_term"], "10")

      assert {:error, report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               report["errors"],
               &(&1["path"] == path <> ".score_terms.invalid_term" and
                   &1["message"] == "must be a number")
             )
    end
  end

  test "reconciles activity score to its terms on every V1 activity surface", %{
    artifact: artifact
  } do
    for {_schema_path, {access, path}} <- activity_surfaces() do
      invalid = update_in(artifact, access ++ ["score"], &(&1 + 1.0))

      assert {:error, report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               report["errors"],
               &(&1["path"] == path <> ".score" and
                   &1["message"] == "must equal numeric score_terms sum")
             )
    end
  end

  test "validates a multi-timeline score report", %{artifact: artifact} do
    artifact = with_timelines(artifact, ranked_timelines(artifact))

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "requires ranked timelines to follow descending planner score order", %{
    artifact: artifact
  } do
    invalid = with_timelines(artifact, Enum.reverse(ranked_timelines(artifact)))

    assert {:error, report} = Schema.validate_artifact(invalid)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.ranked_timelines[1]" and
                 &1["message"] ==
                   "must follow descending score and ascending scenario_id tie-break order")
           )
  end

  test "uses scenario identity as the deterministic equal-score tie-break", %{
    artifact: artifact
  } do
    [first, second] = ranked_timelines(artifact)
    tied = [first, Map.put(second, "score", first["score"])]

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             artifact |> with_timelines(tied) |> Schema.validate_artifact()

    assert {:error, report} =
             artifact
             |> with_timelines(Enum.reverse(tied))
             |> Schema.validate_artifact()

    assert Enum.any?(report["errors"], &(&1["path"] == "$.ranked_timelines[1]"))
  end

  test "does not add ordering errors for malformed ranking fields", %{artifact: artifact} do
    [first, second] = ranked_timelines(artifact)
    invalid = with_timelines(artifact, [first, Map.put(second, "scenario_id", "bad id")])

    assert {:error, report} = Schema.validate_artifact(invalid)
    assert Enum.any?(report["errors"], &(&1["path"] == "$.ranked_timelines[1].scenario_id"))

    refute Enum.any?(
             report["errors"],
             &(&1["message"] ==
                 "must follow descending score and ascending scenario_id tie-break order")
           )
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

  defp ranked_timelines(artifact) do
    [first] = artifact["ranked_timelines"]

    second =
      first
      |> Map.put("scenario_id", "leo_2")
      |> Map.put("score", first["score"] - 10.0)

    [first, second]
  end

  defp with_timelines(artifact, timelines) do
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

    artifact
    |> Map.put("ranked_timelines", timelines)
    |> Map.put("score_term_report", report)
    |> Map.put("objective_tradeoff_report", tradeoff_report)
    |> Map.put("optimizer_contract", optimizer_contract(artifact, timelines))
  end

  defp activity_surfaces do
    [
      {[
         "properties",
         "activities",
         "items"
       ], {["activities", Access.at(0)], "$.activities[0]"}},
      {[
         "properties",
         "candidate_activities",
         "items"
       ], {["candidate_activities", Access.at(0)], "$.candidate_activities[0]"}},
      {[
         "properties",
         "ranked_timelines",
         "items",
         "properties",
         "activities",
         "items"
       ],
       {[
          "ranked_timelines",
          Access.at(0),
          "activities",
          Access.at(0)
        ], "$.ranked_timelines[0].activities[0]"}}
    ]
  end
end
