defmodule OrbitalDynamics.Schema.CampaignRepairValidationSafetyCaseSourceContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  setup do
    artifact = read_json!("study_results/leo_constellation_campaign_repair_v2.json")
    source_summary = read_json!("study_results/validation_safety_case_summary_v1.json")

    artifact =
      artifact
      |> Map.drop(["operator_review_package", "cadence_import_manifest"])
      |> Map.put("source_validation_safety_case_summary", source_summary)

    %{artifact: artifact}
  end

  test "validates the optional V2 source validation-safety-case summary", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "validation_safety_case_summary.v1"}} =
             artifact
             |> Map.fetch!("source_validation_safety_case_summary")
             |> Schema.validate_artifact()

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             artifact
             |> Map.delete("source_validation_safety_case_summary")
             |> Schema.validate_artifact()
  end

  test "rejects V2 source validation-safety-case drift at the source path", %{
    artifact: artifact
  } do
    invalid_model =
      put_in(
        artifact,
        ["source_validation_safety_case_summary", "model"],
        "legacy_validation_safety_case_summary"
      )

    assert {:error, model_report} = Schema.validate_artifact(invalid_model)

    assert Enum.any?(
             model_report["errors"],
             &(&1["path"] == "$.source_validation_safety_case_summary.model")
           )

    invalid_shape = Map.put(artifact, "source_validation_safety_case_summary", [])

    assert {:error, shape_report} = Schema.validate_artifact(invalid_shape)

    assert Enum.any?(
             shape_report["errors"],
             &(&1["path"] == "$.source_validation_safety_case_summary")
           )

    invalid_evidence =
      put_in(artifact, ["source_validation_safety_case_summary", "evidence"], %{})

    assert {:error, evidence_report} = Schema.validate_artifact(invalid_evidence)

    assert Enum.any?(
             evidence_report["errors"],
             &(&1["path"] == "$.source_validation_safety_case_summary.evidence")
           )

    invalid_evidence_row =
      put_in(artifact, ["source_validation_safety_case_summary", "evidence"], ["invalid"])

    assert {:error, evidence_row_report} = Schema.validate_artifact(invalid_evidence_row)

    assert Enum.any?(
             evidence_row_report["errors"],
             &(&1["path"] == "$.source_validation_safety_case_summary.evidence[0]")
           )
  end

  test "exports the source validation-safety-case property" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")

    assert get_in(schema, [
             "properties",
             "source_validation_safety_case_summary",
             "type"
           ]) == "object"

    assert get_in(schema, ["$defs", "validation_safety_case_summary.v1", "type"]) ==
             "object"
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
