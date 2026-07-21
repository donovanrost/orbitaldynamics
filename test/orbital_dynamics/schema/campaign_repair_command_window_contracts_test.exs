defmodule OrbitalDynamics.Schema.CampaignRepairCommandWindowContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  setup do
    %{artifact: read_json!("study_results/campaign_repair_readiness_source_handoff_v2.json")}
  end

  test "validates checked V2 repair command-window reports", %{artifact: artifact} do
    older_artifact = read_json!("study_results/leo_constellation_campaign_repair_v2.json")

    for checked <- [artifact, older_artifact] do
      assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
               Schema.validate_artifact(checked)
    end
  end

  test "keeps the repair command-window report optional", %{artifact: artifact} do
    artifact = Map.delete(artifact, "command_window_report")

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  test "rejects nested command-window count and source drift", %{artifact: artifact} do
    invalid_cases = [
      {"$.command_window_report.window_count",
       put_in(artifact, ["command_window_report", "window_count"], 1)},
      {"$.command_window_report.source",
       put_in(artifact, ["command_window_report", "source"], "campaign_plan.activities")},
      {"$.command_window_report.assumptions.source",
       put_in(
         artifact,
         ["command_window_report", "assumptions", "source"],
         "planned campaign_plan.activities"
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "exports the nested repair command-window contract" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")

    assert get_in(schema, ["properties", "command_window_report", "type"]) == "object"
    assert get_in(schema, ["$defs", "command_window_report.v1", "type"]) == "object"

    assert get_in(schema, [
             "$defs",
             "command_window_report.v1",
             "properties",
             "model",
             "const"
           ]) == "artifact_only_command_window_report"
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
