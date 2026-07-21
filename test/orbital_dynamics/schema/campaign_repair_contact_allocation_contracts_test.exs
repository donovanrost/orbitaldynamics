defmodule OrbitalDynamics.Schema.CampaignRepairContactAllocationContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  setup do
    %{artifact: read_json!("study_results/campaign_repair_readiness_source_handoff_v2.json")}
  end

  test "validates checked V2 repair allocation reports", %{artifact: artifact} do
    older_artifact = read_json!("study_results/leo_constellation_campaign_repair_v2.json")

    for checked <- [artifact, older_artifact] do
      assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
               Schema.validate_artifact(checked)
    end
  end

  test "keeps the repair allocation report optional", %{artifact: artifact} do
    artifact = Map.delete(artifact, "contact_allocation_report")

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  test "rejects nested allocation count and source drift", %{artifact: artifact} do
    invalid_cases = [
      {"$.contact_allocation_report.allocation_status_counts",
       put_in(
         artifact,
         ["contact_allocation_report", "allocation_status_counts"],
         %{"allocated" => 2}
       )},
      {"$.contact_allocation_report.source",
       put_in(artifact, ["contact_allocation_report", "source"], "campaign_plan.activities")}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "exports the nested repair allocation contract" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")

    assert get_in(schema, ["properties", "contact_allocation_report", "type"]) == "object"
    assert get_in(schema, ["$defs", "contact_allocation_report.v1", "type"]) == "object"

    assert get_in(schema, [
             "$defs",
             "contact_allocation_report.v1",
             "properties",
             "model",
             "const"
           ]) == "deterministic_station_contact_allocation"
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
