defmodule OrbitalDynamics.Schema.CampaignRepairScoreContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

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

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
