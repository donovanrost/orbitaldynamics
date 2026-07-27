defmodule OrbitalDynamics.Schema.CampaignRepairResourceFilterSummarySourceContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  @source_field "source_resource_filter_summary"

  setup do
    artifact = read_json!("study_results/leo_constellation_campaign_repair_v2.json")
    source_summary = read_json!("study_results/resource_filter_summary_v1.json")

    artifact =
      artifact
      |> Map.put(@source_field, source_summary)
      |> Map.drop(["operator_review_package", "cadence_import_manifest"])

    %{artifact: artifact}
  end

  test "validates the optional V2 source resource-filter summary", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "resource_filter_summary.v1"}} =
             artifact
             |> Map.fetch!(@source_field)
             |> Schema.validate_artifact()

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             artifact
             |> Map.delete(@source_field)
             |> Schema.validate_artifact()
  end

  test "rejects source resource-filter drift at the distinct V2 path", %{artifact: artifact} do
    invalid_count = put_in(artifact, [@source_field, "suppressed_candidate_count"], 99)

    assert {:error, count_report} = Schema.validate_artifact(invalid_count)

    assert Enum.any?(
             count_report["errors"],
             &(&1["path"] == "$.#{@source_field}.suppressed_candidate_count")
           )

    invalid_shape = Map.put(artifact, @source_field, [])

    assert {:error, shape_report} = Schema.validate_artifact(invalid_shape)
    assert Enum.any?(shape_report["errors"], &(&1["path"] == "$.#{@source_field}"))
  end

  test "exports the source resource-filter summary property" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")
    assert get_in(schema, ["properties", @source_field, "type"]) == "object"

    assert get_in(schema, ["$defs", "resource_filter_summary.v1", "type"]) == "object"
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
