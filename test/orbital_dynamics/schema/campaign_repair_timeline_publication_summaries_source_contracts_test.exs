defmodule OrbitalDynamics.Schema.CampaignRepairTimelinePublicationSummariesSourceContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  @source_field "source_timeline_publication_summaries"

  setup do
    artifact = read_json!("study_results/leo_constellation_campaign_repair_v2.json")
    source_summary = read_json!("study_results/timeline_publication_summary_v1.json")

    artifact =
      artifact
      |> Map.drop(["operator_review_package", "cadence_import_manifest"])
      |> Map.put(@source_field, [source_summary])

    %{artifact: artifact}
  end

  test "validates every optional V2 source publication summary", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    assert Enum.all?(artifact[@source_field], fn summary ->
             match?(
               {:ok, %{"schema_contract" => "timeline_publication_summary.v1"}},
               Schema.validate_artifact(summary)
             )
           end)

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             artifact
             |> Map.delete(@source_field)
             |> Schema.validate_artifact()
  end

  test "rejects indexed source publication drift at the distinct V2 path", %{
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

  test "exports the plural source publication property" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")
    assert get_in(schema, ["properties", @source_field, "type"]) == "array"

    assert get_in(schema, ["$defs", "timeline_publication_summary.v1", "type"]) == "object"
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
