defmodule OrbitalDynamics.Schema.CampaignRepairCandidateRefreshAcceptedPlanningStateContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  @source_field "source_candidate_refresh_accepted_planning_state"

  setup do
    artifact = read_json!("study_results/leo_constellation_campaign_repair_v2.json")

    accepted_state =
      artifact[@source_field]
      |> Map.put("source_family", "fleet_snapshot")

    %{artifact: Map.put(artifact, @source_field, accepted_state)}
  end

  test "validates a typed source reference and keeps the field optional", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             artifact
             |> Map.delete(@source_field)
             |> Schema.validate_artifact()
  end

  test "rejects a non-map source reference", %{artifact: artifact} do
    assert {:error, report} =
             artifact
             |> Map.put(@source_field, [])
             |> Schema.validate_artifact()

    assert Enum.any?(report["errors"], fn error ->
             error["path"] == "$.#{@source_field}" and
               String.contains?(error["message"], "map")
           end)
  end

  test "rejects invalid accepted-state fields at exact nested source paths", %{
    artifact: artifact
  } do
    invalid_cases = [
      {Map.delete(artifact[@source_field], "snapshot_id"), ".snapshot_id"},
      {Map.put(artifact[@source_field], "snapshot_id", "invalid id"), ".snapshot_id"},
      {Map.put(artifact[@source_field], "spacecraft_state_count", -1), ".spacecraft_state_count"},
      {Map.put(artifact[@source_field], "accepted_at", 5), ".accepted_at"},
      {Map.put(artifact[@source_field], "maneuver_execution_delta_count", -1),
       ".maneuver_execution_delta_count"}
    ]

    Enum.each(invalid_cases, fn {accepted_state, path_suffix} ->
      assert {:error, report} =
               artifact
               |> Map.put(@source_field, accepted_state)
               |> Schema.validate_artifact()

      assert Enum.any?(
               report["errors"],
               &(&1["path"] == "$.#{@source_field}#{path_suffix}")
             )
    end)
  end

  test "exports the optional source reference with typed fleet counts" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")
    accepted_state = get_in(schema, ["properties", @source_field])

    assert accepted_state["required"] == ["snapshot_id", "spacecraft_state_count"]
    assert get_in(accepted_state, ["properties", "snapshot_id", "pattern"])

    assert get_in(accepted_state, ["properties", "spacecraft_state_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert get_in(accepted_state, ["properties", "maneuver_execution_delta_count"]) == %{
             "type" => "integer",
             "minimum" => 0
           }

    assert accepted_state["additionalProperties"] == true
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
