defmodule OrbitalDynamics.Schema.CampaignRepairRealizedStateSnapshotSourceContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  @source_field "source_realized_state_snapshot"

  setup do
    artifact = read_json!("study_results/leo_constellation_campaign_repair_v2.json")
    source_snapshot = read_json!("study_results/realized_state_snapshot_v1.json")

    %{artifact: Map.put(artifact, @source_field, source_snapshot)}
  end

  test "validates the optional V2 source realized-state snapshot", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "realized_state_snapshot.v1"}} =
             artifact
             |> Map.fetch!(@source_field)
             |> Schema.validate_artifact()

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             artifact
             |> Map.delete(@source_field)
             |> Schema.validate_artifact()
  end

  test "rejects source realized-state drift at the distinct V2 path", %{artifact: artifact} do
    invalid_count = put_in(artifact, [@source_field, "activity_count"], 999)

    assert {:error, count_report} = Schema.validate_artifact(invalid_count)

    assert Enum.any?(
             count_report["errors"],
             &(&1["path"] == "$.#{@source_field}.activity_count")
           )

    invalid_shape = Map.put(artifact, @source_field, [])

    assert {:error, shape_report} = Schema.validate_artifact(invalid_shape)
    assert Enum.any?(shape_report["errors"], &(&1["path"] == "$.#{@source_field}"))
  end

  test "exports the source realized-state snapshot property" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")
    assert get_in(schema, ["properties", @source_field, "type"]) == "object"

    assert get_in(schema, ["$defs", "realized_state_snapshot.v1", "type"]) == "object"
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
