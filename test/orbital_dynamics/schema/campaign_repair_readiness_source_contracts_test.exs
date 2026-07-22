defmodule OrbitalDynamics.Schema.CampaignRepairReadinessSourceContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  setup do
    %{artifact: read_json!("study_results/campaign_repair_readiness_source_handoff_v2.json")}
  end

  test "validates checked V2 readiness source reports", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    for key <- ["source_operational_readiness_report", "source_quality_gate_report"] do
      assert {:ok, _report} = Schema.validate_artifact(Map.fetch!(artifact, key))
    end
  end

  test "keeps readiness source reports optional" do
    artifact = read_json!("study_results/leo_constellation_campaign_repair_v2.json")

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  test "rejects standalone readiness source drift", %{artifact: artifact} do
    invalid_cases = [
      {"$.source_operational_readiness_report.model",
       put_in(
         artifact,
         ["source_operational_readiness_report", "model"],
         "legacy_readiness_model"
       )},
      {"$.source_operational_readiness_report.gate_count",
       update_in(
         artifact,
         ["source_operational_readiness_report", "gate_count"],
         &(&1 + 1)
       )},
      {"$.source_quality_gate_report.handoff_only",
       put_in(artifact, ["source_quality_gate_report", "handoff_only"], false)},
      {"$.source_quality_gate_report.status",
       put_in(
         artifact,
         ["source_quality_gate_report", "rows", Access.at(0), "status"],
         "passed"
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects drift between readiness and quality-gate sources", %{artifact: artifact} do
    invalid_cases = [
      {"$.source_quality_gate_report.source_readiness_report_id",
       put_in(
         artifact,
         ["source_quality_gate_report", "source_readiness_report_id"],
         "operational_readiness:planned_activity.v1:another_source"
       )},
      {"$.source_quality_gate_report.source_artifact_type",
       put_in(
         artifact,
         ["source_quality_gate_report", "source_artifact_type"],
         "campaign_plan.v1"
       )},
      {"$.source_quality_gate_report.source_artifact_id",
       put_in(
         artifact,
         ["source_quality_gate_report", "source_artifact_id"],
         "another_source"
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "exports nested readiness source contracts" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")

    for {field, contract} <- [
          {"source_operational_readiness_report", "operational_readiness_report.v1"},
          {"source_quality_gate_report", "quality_gate_report.v1"}
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
