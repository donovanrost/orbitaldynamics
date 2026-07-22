defmodule OrbitalDynamics.Schema.CampaignRepairStationSourceContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  setup do
    %{artifact: read_json!("study_results/leo_constellation_campaign_repair_v2.json")}
  end

  test "validates checked V2 station source reports", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    for key <- ["source_contact_allocation_report", "source_station_calendar_report"] do
      assert {:ok, _report} = Schema.validate_artifact(Map.fetch!(artifact, key))
    end
  end

  test "keeps station source reports optional" do
    artifact = read_json!("study_results/campaign_repair_readiness_source_handoff_v2.json")

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  test "rejects station source report drift", %{artifact: artifact} do
    invalid_cases = [
      {"$.source_contact_allocation_report.model",
       put_in(
         artifact,
         ["source_contact_allocation_report", "model"],
         "legacy_station_allocator"
       )},
      {"$.source_contact_allocation_report.model_limits",
       put_in(
         artifact,
         ["source_contact_allocation_report", "model_limits"],
         ["artifact_only"]
       )},
      {"$.source_station_calendar_report.affected_contact_count",
       put_in(artifact, ["source_station_calendar_report", "affected_contact_count"], 1)},
      {"$.source_station_calendar_report.model_limits",
       put_in(
         artifact,
         ["source_station_calendar_report", "model_limits"],
         ["artifact_only"]
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "exports nested station source contracts" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")

    for {field, contract} <- [
          {"source_contact_allocation_report", "contact_allocation_report.v1"},
          {"source_station_calendar_report", "station_calendar_report.v1"}
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
