defmodule OrbitalDynamics.Schema.CampaignRepairFeasibilitySourceContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  setup do
    %{artifact: read_json!("study_results/leo_constellation_campaign_repair_v2.json")}
  end

  test "validates checked V2 feasibility source reports", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    for key <- [
          "source_contact_filter_report",
          "source_resource_filter_report",
          "source_resource_projection_report"
        ] do
      assert {:ok, _report} = Schema.validate_artifact(Map.fetch!(artifact, key))
    end
  end

  test "keeps feasibility source reports optional" do
    artifact = read_json!("study_results/campaign_repair_readiness_source_handoff_v2.json")

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  test "rejects feasibility source report drift", %{artifact: artifact} do
    invalid_cases = [
      {"$.source_contact_filter_report.suppressed_candidate_count",
       put_in(artifact, ["source_contact_filter_report", "suppressed_candidate_count"], 1)},
      {"$.source_resource_filter_report.suppressed_candidate_count",
       put_in(artifact, ["source_resource_filter_report", "suppressed_candidate_count"], 1)},
      {"$.source_resource_projection_report.model",
       put_in(
         artifact,
         ["source_resource_projection_report", "model"],
         "legacy_resource_projection"
       )},
      {"$.source_resource_projection_report.model_limits",
       put_in(
         artifact,
         ["source_resource_projection_report", "model_limits"],
         ["artifact_only"]
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "exports nested feasibility source contracts" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")

    for {field, contract} <- [
          {"source_contact_filter_report", "contact_filter_report.v1"},
          {"source_resource_filter_report", "resource_filter_report.v1"},
          {"source_resource_projection_report", "resource_projection_report.v1"}
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
