defmodule OrbitalDynamics.Schema.CampaignRepairConstraintContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  setup do
    %{artifact: read_json!("study_results/campaign_repair_readiness_source_handoff_v2.json")}
  end

  test "validates the checked-in V2 repair constraint report", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  test "keeps the repair constraint report optional", %{artifact: artifact} do
    artifact = Map.delete(artifact, "constraint_report")

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  test "accepts configured constraints that have no evaluated row" do
    artifact = read_json!("study_results/leo_constellation_campaign_repair_v2.json")

    assert %{
             "constraint_count" => 3,
             "row_count" => 1,
             "rows" => [%{"constraint_id" => "campaign:max_timeline_activities"}]
           } = artifact["constraint_report"]

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    invalid = put_in(artifact, ["constraint_report", "constraint_count"], 0)

    assert {:error, report} = Schema.validate_artifact(invalid)
    assert Enum.any?(report["errors"], &(&1["path"] == "$.constraint_count"))
  end

  test "rejects nested constraint shape and repair identity drift", %{artifact: artifact} do
    invalid_cases = [
      {"$.row_count", put_in(artifact, ["constraint_report", "row_count"], 1)},
      {"$.constraint_report.model",
       put_in(
         artifact,
         ["constraint_report", "model"],
         "campaign_planner_local_constraint_summary"
       )},
      {"$.constraint_report.assumptions.constraint_model",
       put_in(
         artifact,
         ["constraint_report", "assumptions", "constraint_model"],
         "campaign_v1_planner_local_constraints"
       )},
      {"$.constraint_report.assumptions.source",
       put_in(
         artifact,
         ["constraint_report", "assumptions", "source"],
         "campaign_plan.assumptions.constraints"
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "exports the nested repair constraint contract" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")

    assert get_in(schema, ["properties", "constraint_report", "type"]) == "object"
    assert get_in(schema, ["$defs", "constraint_report.v1", "type"]) == "object"

    assert get_in(schema, ["$defs", "constraint_report.v1", "properties", "model", "enum"]) ==
             [
               "artifact_metric_threshold",
               "campaign_planner_local_constraint_summary",
               "campaign_repair_local_constraint_summary"
             ]
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
