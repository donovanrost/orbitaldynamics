defmodule OrbitalDynamics.Schema.CampaignRepairCandidateRefreshWarningsContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  @source_field "source_candidate_refresh_warnings"

  setup do
    artifact = read_json!("study_results/leo_constellation_campaign_repair_v2.json")

    %{artifact: Map.put(artifact, @source_field, ["source warning", "source warning"])}
  end

  test "validates exact source warning lists and keeps the field optional", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             artifact
             |> Map.put(@source_field, [])
             |> Schema.validate_artifact()

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             artifact
             |> Map.delete(@source_field)
             |> Schema.validate_artifact()
  end

  test "rejects a non-list source warnings field", %{artifact: artifact} do
    assert {:error, report} =
             artifact
             |> Map.put(@source_field, %{})
             |> Schema.validate_artifact()

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.#{@source_field}" and
                 String.contains?(&1["message"], "list"))
           )
  end

  test "rejects non-string warning items at the exact source index", %{artifact: artifact} do
    assert {:error, report} =
             artifact
             |> Map.put(@source_field, ["valid", 42])
             |> Schema.validate_artifact()

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.#{@source_field}[1]" and
                 String.contains?(&1["message"], "string"))
           )
  end

  test "exports the optional source warnings property as a string array" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")
    assert get_in(schema, ["properties", @source_field, "type"]) == "array"
    assert get_in(schema, ["properties", @source_field, "items", "type"]) == "string"
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
