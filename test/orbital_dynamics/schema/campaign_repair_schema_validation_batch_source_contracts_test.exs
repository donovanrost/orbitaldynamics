defmodule OrbitalDynamics.Schema.CampaignRepairSchemaValidationBatchSourceContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  @source_field "source_schema_validation_batch_report"

  setup do
    artifact = read_json!("study_results/leo_constellation_campaign_repair_v2.json")
    source_batch = read_json!("study_results/schema_validation_batch_report_v1.json")

    %{artifact: Map.put(artifact, @source_field, source_batch)}
  end

  test "validates the optional V2 source schema-validation batch", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "schema_validation_batch_report.v1"}} =
             artifact
             |> Map.fetch!(@source_field)
             |> Schema.validate_artifact()

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             artifact
             |> Map.delete(@source_field)
             |> Schema.validate_artifact()
  end

  test "rejects source schema-validation batch drift at the distinct V2 path", %{
    artifact: artifact
  } do
    invalid_count = put_in(artifact, [@source_field, "file_count"], 999)

    assert {:error, count_report} = Schema.validate_artifact(invalid_count)

    assert Enum.any?(
             count_report["errors"],
             &(&1["path"] == "$.#{@source_field}.file_count")
           )

    invalid_shape = Map.put(artifact, @source_field, [])

    assert {:error, shape_report} = Schema.validate_artifact(invalid_shape)
    assert Enum.any?(shape_report["errors"], &(&1["path"] == "$.#{@source_field}"))

    invalid_reports = put_in(artifact, [@source_field, "reports"], %{})

    assert {:error, reports_report} = Schema.validate_artifact(invalid_reports)
    assert Enum.any?(reports_report["errors"], &(&1["path"] == "$.#{@source_field}.reports"))

    invalid_report = put_in(artifact, [@source_field, "reports"], ["invalid"])

    assert {:error, report_report} = Schema.validate_artifact(invalid_report)

    assert Enum.any?(
             report_report["errors"],
             &(&1["path"] == "$.#{@source_field}.reports[0]")
           )

    invalid_skipped = put_in(artifact, [@source_field, "skipped_artifacts"], %{})

    assert {:error, skipped_report} = Schema.validate_artifact(invalid_skipped)

    assert Enum.any?(
             skipped_report["errors"],
             &(&1["path"] == "$.#{@source_field}.skipped_artifacts")
           )
  end

  test "exports the source schema-validation batch property" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")
    assert get_in(schema, ["properties", @source_field, "type"]) == "object"

    assert get_in(schema, ["$defs", "schema_validation_batch_report.v1", "type"]) == "object"
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
