defmodule OrbitalDynamics.Schema.CampaignPlanCadenceImportContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  setup do
    artifact =
      "study_results/leo_constellation_campaign.json"
      |> read_json!()
      |> Map.fetch!("campaign_plan")

    %{artifact: artifact}
  end

  test "validates the checked-in V1 Cadence import manifest", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "keeps the Cadence import manifest optional", %{artifact: artifact} do
    artifact = Map.delete(artifact, "cadence_import_manifest")

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "rejects a Cadence manifest copied from another source", %{artifact: artifact} do
    invalid_cases = [
      {"$.cadence_import_manifest.source_artifact_type",
       put_in(
         artifact,
         ["cadence_import_manifest", "source_artifact_type"],
         "campaign_repair.v2"
       )},
      {"$.cadence_import_manifest.source_artifact_id",
       put_in(artifact, ["cadence_import_manifest", "source_artifact_id"], "another_plan")}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "runs standalone manifest and row guarantees", %{artifact: artifact} do
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
       put_in(artifact, ["cadence_import_manifest", "model_limits"], ["does_not_write_cadence"])},
      {"$.cadence_import_manifest.assumptions.execution_boundary",
       put_in(
         artifact,
         ["cadence_import_manifest", "assumptions", "execution_boundary"],
         "writes_cadence"
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects malformed manifest and row shapes without crashing", %{artifact: artifact} do
    invalid_manifest = Map.put(artifact, "cadence_import_manifest", [])
    invalid_row = put_in(artifact, ["cadence_import_manifest", "rows"], ["not-a-row"])

    assert {:error, manifest_shape} = Schema.validate_artifact(invalid_manifest)
    assert Enum.any?(manifest_shape["errors"], &(&1["path"] == "$.cadence_import_manifest"))

    assert {:error, row_shape} = Schema.validate_artifact(invalid_row)

    assert Enum.any?(
             row_shape["errors"],
             &(&1["path"] == "$.cadence_import_manifest.rows[0]")
           )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
