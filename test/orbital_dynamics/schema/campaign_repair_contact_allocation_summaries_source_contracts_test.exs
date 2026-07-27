defmodule OrbitalDynamics.Schema.CampaignRepairContactAllocationSummariesSourceContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  @singular_field "source_contact_allocation_summary"
  @plural_field "source_contact_allocation_summaries"

  setup do
    artifact =
      "study_results/leo_constellation_campaign_repair_v2.json"
      |> read_json!()
      |> Map.drop(["operator_review_package", "cadence_import_manifest"])

    source_summary = read_json!("study_results/contact_allocation_summary_v1.json")

    artifact =
      artifact
      |> Map.put(@singular_field, source_summary)
      |> Map.put(@plural_field, [source_summary, source_summary])

    %{artifact: artifact}
  end

  test "validates every ordered V2 source compact allocation summary", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    assert Enum.all?(artifact[@plural_field], fn summary ->
             match?(
               {:ok, %{"schema_contract" => "contact_allocation_summary.v1"}},
               Schema.validate_artifact(summary)
             )
           end)

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             artifact
             |> Map.delete(@singular_field)
             |> Schema.validate_artifact()

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             artifact
             |> Map.delete(@plural_field)
             |> Schema.validate_artifact()
  end

  test "rejects indexed source drift and a non-list plural shape", %{artifact: artifact} do
    invalid_count = put_in(artifact, [@plural_field, Access.at(1), "input_contact_count"], 99)

    assert {:error, count_report} = Schema.validate_artifact(invalid_count)

    assert Enum.any?(
             count_report["errors"],
             &(&1["path"] == "$.#{@plural_field}[1].input_contact_count")
           )

    invalid_shape = Map.put(artifact, @plural_field, %{})

    assert {:error, shape_report} = Schema.validate_artifact(invalid_shape)
    assert Enum.any?(shape_report["errors"], &(&1["path"] == "$.#{@plural_field}"))
  end

  test "rejects drift and absence in the singular compatibility mirror", %{
    artifact: artifact
  } do
    drifted =
      update_in(artifact, [@singular_field], &Map.put(&1, "compatibility_marker", "drift"))

    assert {:error, drift_report} = Schema.validate_artifact(drifted)

    assert Enum.any?(
             drift_report["errors"],
             &(&1["path"] == "$.#{@singular_field}" and
                 String.contains?(&1["message"], "#{@plural_field}[0]"))
           )

    assert {:error, empty_report} =
             artifact
             |> Map.put(@plural_field, [])
             |> Schema.validate_artifact()

    assert Enum.any?(
             empty_report["errors"],
             &(&1["path"] == "$.#{@singular_field}" and
                 String.contains?(&1["message"], "#{@plural_field}[0]"))
           )
  end

  test "exports the plural source compact allocation-summary property" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")
    assert get_in(schema, ["properties", @plural_field, "type"]) == "array"
    assert get_in(schema, ["$defs", "contact_allocation_summary.v1", "type"]) == "object"
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
