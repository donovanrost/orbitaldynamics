defmodule OrbitalDynamics.Schema.CampaignRepairTimelineActivityLifecycleStatesSourceContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  @source_field "source_timeline_activity_lifecycle_states"

  setup do
    artifact = read_json!("study_results/leo_constellation_campaign_repair_v2.json")
    source_state = read_json!("study_results/timeline_activity_lifecycle_state_v1.json")

    %{artifact: Map.put(artifact, @source_field, [source_state])}
  end

  test "validates every optional V2 source activity-lifecycle state", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    assert Enum.all?(artifact[@source_field], fn state ->
             match?(
               {:ok, %{"schema_contract" => "timeline_activity_lifecycle_state.v1"}},
               Schema.validate_artifact(state)
             )
           end)

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             artifact
             |> Map.delete(@source_field)
             |> Schema.validate_artifact()
  end

  test "rejects indexed source activity-lifecycle drift at the distinct V2 path", %{
    artifact: artifact
  } do
    invalid_contract =
      put_in(artifact, [@source_field, Access.at(0), "schema_contract"], "wrong.v1")

    assert {:error, contract_report} = Schema.validate_artifact(invalid_contract)

    assert Enum.any?(
             contract_report["errors"],
             &(&1["path"] == "$.#{@source_field}[0].schema_contract")
           )

    invalid_shape = Map.put(artifact, @source_field, %{})

    assert {:error, shape_report} = Schema.validate_artifact(invalid_shape)
    assert Enum.any?(shape_report["errors"], &(&1["path"] == "$.#{@source_field}"))
  end

  test "exports the plural source activity-lifecycle property" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")
    assert get_in(schema, ["properties", @source_field, "type"]) == "array"

    assert get_in(schema, ["$defs", "timeline_activity_lifecycle_state.v1", "type"]) ==
             "object"
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
