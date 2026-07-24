defmodule OrbitalDynamics.Schema.CampaignRepairContentionSourceContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  setup do
    artifact = read_json!("study_results/leo_constellation_campaign_repair_v2.json")

    resolution_report =
      get_in(artifact, [
        "source_contact_allocation_report",
        "contact_contention_resolution_report"
      ])

    %{
      artifact:
        Map.put(
          artifact,
          "source_contact_contention_resolution_report",
          resolution_report
        )
    }
  end

  test "validates the optional V2 contention-resolution source report", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "contact_contention_resolution_report.v1"}} =
             artifact
             |> Map.fetch!("source_contact_contention_resolution_report")
             |> Schema.validate_artifact()

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             artifact
             |> Map.delete("source_contact_contention_resolution_report")
             |> Schema.validate_artifact()
  end

  test "rejects V2 contention-resolution source drift at the source path", %{
    artifact: artifact
  } do
    invalid_model =
      put_in(
        artifact,
        ["source_contact_contention_resolution_report", "model"],
        "legacy_contention_resolution"
      )

    assert {:error, model_report} = Schema.validate_artifact(invalid_model)

    assert Enum.any?(
             model_report["errors"],
             &(&1["path"] == "$.source_contact_contention_resolution_report.model")
           )

    invalid_shape = Map.put(artifact, "source_contact_contention_resolution_report", [])

    assert {:error, shape_report} = Schema.validate_artifact(invalid_shape)

    assert Enum.any?(
             shape_report["errors"],
             &(&1["path"] == "$.source_contact_contention_resolution_report")
           )
  end

  test "exports the nested contention-resolution source contract" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")

    assert get_in(schema, [
             "properties",
             "source_contact_contention_resolution_report",
             "type"
           ]) == "object"

    assert get_in(schema, [
             "$defs",
             "contact_contention_resolution_report.v1",
             "type"
           ]) == "object"
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
