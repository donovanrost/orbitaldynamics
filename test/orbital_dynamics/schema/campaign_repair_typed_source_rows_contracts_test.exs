defmodule OrbitalDynamics.Schema.CampaignRepairTypedSourceRowsContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  setup do
    %{
      artifact:
        "study_results/leo_constellation_campaign_repair_v2.json"
        |> read_json!()
        |> Map.drop(["operator_review_package", "cadence_import_manifest"]),
      contact_intent: read_json!("study_results/contact_intent_v1.json"),
      resource_summary: read_json!("study_results/resource_summary_v1.json")
    }
  end

  test "validates populated V2 typed source rows", context do
    artifact =
      context.artifact
      |> Map.put("source_contact_intents", [context.contact_intent])
      |> Map.put("source_resource_summaries", [context.resource_summary])

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    for row <- artifact["source_contact_intents"] ++ artifact["source_resource_summaries"] do
      assert {:ok, _row} = Schema.validate_artifact(row)
    end
  end

  test "keeps typed source rows optional", %{artifact: artifact} do
    artifact =
      artifact
      |> Map.delete("source_contact_intents")
      |> Map.delete("source_resource_summaries")

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  test "rejects typed source row drift", context do
    invalid_cases = [
      {"$.source_contact_intents[0].schema_contract",
       Map.put(context.contact_intent, "schema_contract", "contact_intent.v0")
       |> then(&Map.put(context.artifact, "source_contact_intents", [&1]))},
      {"$.source_resource_summaries[0].power_margin",
       Map.put(context.resource_summary, "power_margin", 1.1)
       |> then(&Map.put(context.artifact, "source_resource_summaries", [&1]))},
      {"$.source_contact_intents", Map.put(context.artifact, "source_contact_intents", %{})},
      {"$.source_resource_summaries", Map.put(context.artifact, "source_resource_summaries", %{})}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, validation_report} = Schema.validate_artifact(invalid)
      assert Enum.any?(validation_report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "exports typed source arrays and item contracts" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")

    for {field, contract} <- [
          {"source_contact_intents", "contact_intent.v1"},
          {"source_resource_summaries", "resource_summary.v1"}
        ] do
      assert get_in(schema, ["properties", field, "type"]) == "array"
      assert get_in(schema, ["$defs", contract, "type"]) == "object"
    end
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
