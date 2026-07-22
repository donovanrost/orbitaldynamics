defmodule OrbitalDynamics.Schema.CampaignRepairTimelineFeedbackSourceContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  setup do
    %{artifact: read_json!("study_results/leo_constellation_campaign_repair_v2.json")}
  end

  test "validates the checked V2 timeline feedback source", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "timeline_feedback_report.v1"}} =
             Schema.validate_artifact(artifact["source_timeline_feedback_report"])
  end

  test "keeps timeline feedback source evidence optional", %{artifact: artifact} do
    artifact = Map.delete(artifact, "source_timeline_feedback_report")

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  test "rejects timeline feedback source drift", %{artifact: artifact} do
    report = artifact["source_timeline_feedback_report"]

    invalid_cases = [
      {"$.source_timeline_feedback_report.row_count",
       put_in(
         artifact,
         ["source_timeline_feedback_report", "row_count"],
         report["row_count"] + 1
       )},
      {"$.source_timeline_feedback_report.model_limits",
       put_in(
         artifact,
         ["source_timeline_feedback_report", "model_limits"],
         ["artifact_level_only"]
       )},
      {"$.source_timeline_feedback_report.rows[0].status",
       put_in(
         artifact,
         ["source_timeline_feedback_report", "rows", Access.at(0), "status"],
         "silently_accepted"
       )},
      {"$.source_timeline_feedback_report.operator_review_package",
       put_in(
         artifact,
         ["source_timeline_feedback_report", "operator_review_package"],
         []
       )},
      {"$.source_timeline_feedback_report",
       Map.put(artifact, "source_timeline_feedback_report", [])}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, validation_report} = Schema.validate_artifact(invalid)
      assert Enum.any?(validation_report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "exports the nested timeline feedback source contract" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")

    assert get_in(schema, ["properties", "source_timeline_feedback_report", "type"]) ==
             "object"

    assert get_in(schema, ["$defs", "timeline_feedback_report.v1", "type"]) == "object"
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
