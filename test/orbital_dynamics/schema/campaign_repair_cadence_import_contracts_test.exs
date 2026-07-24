defmodule OrbitalDynamics.Schema.CampaignRepairCadenceImportContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema
  alias OrbitalDynamics.Schema.CampaignRepairCadenceImportContracts

  setup do
    %{artifact: read_json!("study_results/campaign_repair_readiness_source_handoff_v2.json")}
  end

  test "validates checked V2 repair Cadence import manifests", %{artifact: artifact} do
    older_artifact = read_json!("study_results/leo_constellation_campaign_repair_v2.json")

    for checked <- [artifact, older_artifact] do
      assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
               Schema.validate_artifact(checked)
    end
  end

  test "keeps the repair Cadence import manifest optional", %{artifact: artifact} do
    artifact = Map.delete(artifact, "cadence_import_manifest")

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  test "rejects standalone manifest drift", %{artifact: artifact} do
    invalid_cases = [
      {"$.cadence_import_manifest.row_count",
       update_in(artifact, ["cadence_import_manifest", "row_count"], &(&1 + 1))},
      {"$.cadence_import_manifest.rows[0].import_status",
       put_in(
         artifact,
         ["cadence_import_manifest", "rows", Access.at(0), "import_status"],
         "legacy"
       )},
      {"$.cadence_import_manifest.model_limits",
       put_in(artifact, ["cadence_import_manifest", "model_limits"], ["writes_cadence"])}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects repair source and operator-review join drift", %{artifact: artifact} do
    invalid_cases = [
      {"$.cadence_import_manifest.source_artifact_type",
       put_in(
         artifact,
         ["cadence_import_manifest", "source_artifact_type"],
         "campaign_plan.v1"
       )},
      {"$.cadence_import_manifest.source_artifact_id",
       put_in(artifact, ["cadence_import_manifest", "source_artifact_id"], "another_repair")},
      {"$.cadence_import_manifest.assumptions.row_source",
       put_in(
         artifact,
         ["cadence_import_manifest", "assumptions", "row_source"],
         "campaign_repair.activities"
       )},
      {"$.cadence_import_manifest.provenance.source_review_count",
       update_in(
         artifact,
         ["cadence_import_manifest", "provenance", "source_review_count"],
         &(&1 + 1)
       )},
      {"$.cadence_import_manifest.rows[0].source_review_row_id",
       put_in(
         artifact,
         ["operator_review_package", "rows", Access.at(0), "id"],
         "another_review_row"
       )},
      {"$.operator_review_package", Map.delete(artifact, "operator_review_package")}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "joins manifest rows only to Cadence-eligible operator reviews", %{artifact: artifact} do
    operator_only_row = %{
      "id" => "model_acceptance_review:operator_only",
      "review_type" => "model_acceptance_review"
    }

    artifact =
      artifact
      |> update_in(
        ["operator_review_package", "rows"],
        &[operator_only_row | &1]
      )
      |> update_in(["operator_review_package", "review_count"], &(&1 + 1))
      |> update_in(
        ["cadence_import_manifest", "provenance", "source_review_count"],
        &(&1 + 1)
      )

    assert CampaignRepairCadenceImportContracts.validate([], artifact) == []
  end

  test "exports the nested repair Cadence import contract" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")

    assert get_in(schema, ["properties", "cadence_import_manifest", "type"]) == "object"
    assert get_in(schema, ["$defs", "cadence_import_manifest.v1", "type"]) == "object"

    assert get_in(schema, [
             "$defs",
             "cadence_import_manifest.v1",
             "properties",
             "model",
             "const"
           ]) == "artifact_only_cadence_import_manifest"
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
