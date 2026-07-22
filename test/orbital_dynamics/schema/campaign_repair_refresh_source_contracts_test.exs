defmodule OrbitalDynamics.Schema.CampaignRepairRefreshSourceContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  setup do
    %{artifact: read_json!("study_results/leo_constellation_campaign_repair_v2.json")}
  end

  test "validates checked V2 candidate-refresh source reports", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    for key <- [
          "source_candidate_diff_report",
          "source_freshness_report",
          "source_refresh_budget_report"
        ] do
      assert {:ok, _report} = Schema.validate_artifact(Map.fetch!(artifact, key))
    end
  end

  test "keeps candidate-refresh source reports optional" do
    artifact = read_json!("study_results/campaign_repair_readiness_source_handoff_v2.json")

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  test "rejects candidate-refresh source report drift", %{artifact: artifact} do
    invalid_cases = [
      {"$.source_candidate_diff_report.new_candidate_count",
       put_in(artifact, ["source_candidate_diff_report", "new_candidate_count"], 1)},
      {"$.source_freshness_report.status",
       put_in(artifact, ["source_freshness_report", "status"], "stale")},
      {"$.source_refresh_budget_report.kept_candidate_count",
       put_in(artifact, ["source_refresh_budget_report", "kept_candidate_count"], 1)},
      {"$.source_refresh_budget_report.model_limits",
       put_in(artifact, ["source_refresh_budget_report", "model_limits"], ["artifact_only"])}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "exports nested candidate-refresh source contracts" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")

    for {field, contract} <- [
          {"source_candidate_diff_report", "candidate_diff_report.v1"},
          {"source_freshness_report", "freshness_report.v1"},
          {"source_refresh_budget_report", "refresh_budget_report.v1"}
        ] do
      assert get_in(schema, ["properties", field, "type"]) == "object"
      assert get_in(schema, ["$defs", contract, "type"]) == "object"
    end
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
