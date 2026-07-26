defmodule OrbitalDynamics.Schema.CampaignRepairCandidateRefreshAssumptionsContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  @source_field "source_candidate_refresh_assumptions"

  setup do
    artifact = read_json!("study_results/leo_constellation_campaign_repair_v2.json")

    source_assumptions =
      "study_results/candidate_refresh_v1.json"
      |> read_json!()
      |> get_in(["candidate_refresh", "assumptions"])

    %{artifact: Map.put(artifact, @source_field, source_assumptions)}
  end

  test "validates exact source assumptions and keeps the field optional", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             artifact
             |> Map.delete(@source_field)
             |> Schema.validate_artifact()
  end

  test "rejects a non-object source assumptions field", %{artifact: artifact} do
    assert {:error, report} =
             artifact
             |> Map.put(@source_field, [])
             |> Schema.validate_artifact()

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.#{@source_field}" and
                 String.contains?(&1["message"], "map"))
           )
  end

  test "exports the optional source assumptions property as an object" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")
    assert get_in(schema, ["properties", @source_field, "type"]) == "object"
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
