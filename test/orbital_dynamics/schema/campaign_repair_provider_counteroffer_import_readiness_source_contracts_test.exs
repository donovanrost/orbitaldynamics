defmodule OrbitalDynamics.Schema.CampaignRepairProviderCounterofferImportReadinessSourceContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  setup do
    artifact = read_json!("study_results/leo_constellation_campaign_repair_v2.json")

    source_summary =
      read_json!("study_results/provider_counteroffer_import_readiness_summary_v1.json")

    %{
      artifact:
        Map.put(
          artifact,
          "source_provider_counteroffer_import_readiness_summary",
          source_summary
        )
    }
  end

  test "validates the optional V2 source provider-counteroffer import-readiness summary", %{
    artifact: artifact
  } do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "provider_counteroffer_import_readiness_summary.v1"}} =
             artifact
             |> Map.fetch!("source_provider_counteroffer_import_readiness_summary")
             |> Schema.validate_artifact()

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             artifact
             |> Map.delete("source_provider_counteroffer_import_readiness_summary")
             |> Schema.validate_artifact()
  end

  test "rejects V2 source provider-counteroffer import-readiness drift at the source path", %{
    artifact: artifact
  } do
    invalid_model =
      put_in(
        artifact,
        ["source_provider_counteroffer_import_readiness_summary", "model"],
        "legacy_provider_counteroffer_import_readiness_model"
      )

    assert {:error, model_report} = Schema.validate_artifact(invalid_model)

    assert Enum.any?(
             model_report["errors"],
             &(&1["path"] ==
                 "$.source_provider_counteroffer_import_readiness_summary.model")
           )

    invalid_shape =
      Map.put(artifact, "source_provider_counteroffer_import_readiness_summary", [])

    assert {:error, shape_report} = Schema.validate_artifact(invalid_shape)

    assert Enum.any?(
             shape_report["errors"],
             &(&1["path"] ==
                 "$.source_provider_counteroffer_import_readiness_summary")
           )
  end

  test "exports the source provider-counteroffer import-readiness property" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")

    assert get_in(
             schema,
             [
               "properties",
               "source_provider_counteroffer_import_readiness_summary",
               "type"
             ]
           ) == "object"

    assert get_in(
             schema,
             ["$defs", "provider_counteroffer_import_readiness_summary.v1", "type"]
           ) == "object"
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
