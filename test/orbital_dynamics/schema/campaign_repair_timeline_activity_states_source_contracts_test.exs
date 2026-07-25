defmodule OrbitalDynamics.Schema.CampaignRepairTimelineActivityStatesSourceContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  @source_field "source_timeline_activity_states"

  setup do
    artifact = read_json!("study_results/leo_constellation_campaign_repair_v2.json")

    source_states = [
      read_json!("study_results/timeline_activity_state_v1.json"),
      read_json!("study_results/timeline_activity_status_state_v1.json"),
      read_json!("study_results/timeline_activity_approval_state_v1.json")
    ]

    %{artifact: Map.put(artifact, @source_field, source_states)}
  end

  test "validates every optional V2 source activity-state contract", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    assert Enum.all?(artifact[@source_field], fn state ->
             match?({:ok, %{}}, Schema.validate_artifact(state))
           end)

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             artifact
             |> Map.delete(@source_field)
             |> Schema.validate_artifact()
  end

  test "rejects indexed activity-state contract drift at the distinct V2 path", %{
    artifact: artifact
  } do
    invalid_contract =
      put_in(artifact, [@source_field, Access.at(1), "schema_contract"], "wrong.v1")

    assert {:error, contract_report} = Schema.validate_artifact(invalid_contract)

    assert Enum.any?(
             contract_report["errors"],
             &(&1["path"] == "$.#{@source_field}[1].schema_contract")
           )

    invalid_shape = Map.put(artifact, @source_field, %{})

    assert {:error, shape_report} = Schema.validate_artifact(invalid_shape)
    assert Enum.any?(shape_report["errors"], &(&1["path"] == "$.#{@source_field}"))
  end

  test "exports the heterogeneous plural activity-state property" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")
    assert get_in(schema, ["properties", @source_field, "type"]) == "array"

    for contract <- [
          "timeline_activity_state.v1",
          "timeline_activity_status_state.v1",
          "timeline_activity_approval_state.v1"
        ] do
      assert get_in(schema, ["$defs", contract, "type"]) == "object"
    end
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
