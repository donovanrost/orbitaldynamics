defmodule OrbitalDynamics.Schema.CampaignRepairOperationalQualityGateSchemaValidationSummarySourceContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  setup do
    artifact = read_json!("study_results/leo_constellation_campaign_repair_v2.json")

    source_summary =
      read_json!("study_results/operational_quality_gate_schema_validation_summary_v1.json")

    artifact =
      artifact
      |> Map.put("source_operational_quality_gate_schema_validation_summary", source_summary)
      |> Map.drop(["operator_review_package", "cadence_import_manifest"])

    %{artifact: artifact}
  end

  test "validates the optional V2 source schema-validation quality-gate summary", %{
    artifact: artifact
  } do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    assert {:ok,
            %{
              "schema_contract" => "operational_quality_gate_schema_validation_summary.v1"
            }} =
             artifact
             |> Map.fetch!("source_operational_quality_gate_schema_validation_summary")
             |> Schema.validate_artifact()

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             artifact
             |> Map.delete("source_operational_quality_gate_schema_validation_summary")
             |> Schema.validate_artifact()
  end

  test "rejects V2 source schema-validation drift at the source path", %{
    artifact: artifact
  } do
    invalid_blocked =
      put_in(
        artifact,
        [
          "source_operational_quality_gate_schema_validation_summary",
          "schema_validation_import_blocked"
        ],
        false
      )

    assert {:error, blocked_report} = Schema.validate_artifact(invalid_blocked)

    assert Enum.any?(
             blocked_report["errors"],
             &(&1["path"] ==
                 "$.source_operational_quality_gate_schema_validation_summary.schema_validation_import_blocked")
           )

    invalid_shape =
      Map.put(artifact, "source_operational_quality_gate_schema_validation_summary", [])

    assert {:error, shape_report} = Schema.validate_artifact(invalid_shape)

    assert Enum.any?(
             shape_report["errors"],
             &(&1["path"] == "$.source_operational_quality_gate_schema_validation_summary")
           )
  end

  test "exports the source schema-validation quality-gate property" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")

    assert get_in(
             schema,
             [
               "properties",
               "source_operational_quality_gate_schema_validation_summary",
               "type"
             ]
           ) == "object"

    assert get_in(
             schema,
             ["$defs", "operational_quality_gate_schema_validation_summary.v1", "type"]
           ) == "object"
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
