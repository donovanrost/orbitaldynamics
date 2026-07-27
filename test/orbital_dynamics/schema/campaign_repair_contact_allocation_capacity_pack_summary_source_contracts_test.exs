defmodule OrbitalDynamics.Schema.CampaignRepairContactAllocationCapacityPackSummarySourceContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  @source_field "source_contact_allocation_capacity_pack_summary"

  setup do
    artifact =
      "study_results/leo_constellation_campaign_repair_v2.json"
      |> read_json!()
      |> Map.drop(["operator_review_package", "cadence_import_manifest"])

    source_summary = read_json!("study_results/contact_allocation_capacity_pack_summary_v1.json")

    %{artifact: Map.put(artifact, @source_field, source_summary)}
  end

  test "validates the optional V2 source capacity-pack summary", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "contact_allocation_capacity_pack_summary.v1"}} =
             artifact
             |> Map.fetch!(@source_field)
             |> Schema.validate_artifact()

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             artifact
             |> Map.delete(@source_field)
             |> Schema.validate_artifact()
  end

  test "rejects source summary drift at the distinct V2 path", %{artifact: artifact} do
    invalid_count = put_in(artifact, [@source_field, "input_contact_count"], 99)

    assert {:error, count_report} = Schema.validate_artifact(invalid_count)

    assert Enum.any?(
             count_report["errors"],
             &(&1["path"] == "$.#{@source_field}.input_contact_count")
           )

    invalid_shape = Map.put(artifact, @source_field, [])

    assert {:error, shape_report} = Schema.validate_artifact(invalid_shape)
    assert Enum.any?(shape_report["errors"], &(&1["path"] == "$.#{@source_field}"))
  end

  test "exports the source capacity-pack-summary property" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")
    assert get_in(schema, ["properties", @source_field, "type"]) == "object"

    assert get_in(
             schema,
             ["$defs", "contact_allocation_capacity_pack_summary.v1", "type"]
           ) == "object"
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
