defmodule OrbitalDynamics.Schema.CampaignRepairProviderCounterofferReviewSummarySourceContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  setup do
    artifact = read_json!("study_results/leo_constellation_campaign_repair_v2.json")
    source_summary = read_json!("study_results/provider_counteroffer_review_summary_v1.json")

    artifact =
      artifact
      |> Map.drop(["operator_review_package", "cadence_import_manifest"])
      |> Map.put("source_provider_counteroffer_review_summary", source_summary)

    %{artifact: artifact}
  end

  test "validates the optional V2 source provider counteroffer review summary", %{
    artifact: artifact
  } do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "provider_counteroffer_review_summary.v1"}} =
             artifact
             |> Map.fetch!("source_provider_counteroffer_review_summary")
             |> Schema.validate_artifact()

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             artifact
             |> Map.delete("source_provider_counteroffer_review_summary")
             |> Schema.validate_artifact()
  end

  test "rejects V2 source provider counteroffer review drift at the source path", %{
    artifact: artifact
  } do
    invalid_count =
      put_in(
        artifact,
        ["source_provider_counteroffer_review_summary", "counteroffer_count"],
        99
      )

    assert {:error, count_report} = Schema.validate_artifact(invalid_count)

    assert Enum.any?(
             count_report["errors"],
             &(&1["path"] ==
                 "$.source_provider_counteroffer_review_summary.counteroffer_count")
           )

    invalid_shape = Map.put(artifact, "source_provider_counteroffer_review_summary", [])

    assert {:error, shape_report} = Schema.validate_artifact(invalid_shape)

    assert Enum.any?(
             shape_report["errors"],
             &(&1["path"] == "$.source_provider_counteroffer_review_summary")
           )
  end

  test "exports the source provider counteroffer review property" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")

    assert get_in(
             schema,
             ["properties", "source_provider_counteroffer_review_summary", "type"]
           ) == "object"

    assert get_in(schema, ["$defs", "provider_counteroffer_review_summary.v1", "type"]) ==
             "object"
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
