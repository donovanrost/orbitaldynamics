defmodule OrbitalDynamics.Schema.CampaignRepairProvenanceHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  setup do
    %{
      repair: read_json!("study_results/leo_constellation_campaign_repair_v2.json"),
      readiness_repair:
        read_json!("study_results/campaign_repair_readiness_source_handoff_v2.json")
    }
  end

  test "validates checked Repair provenance handoffs", context do
    for artifact <- [context.repair, context.readiness_repair] do
      assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
               Schema.validate_artifact(artifact)
    end
  end

  test "keeps additive provenance copies optional for older repairs", %{repair: repair} do
    artifact =
      repair
      |> update_in(
        ["provenance"],
        &Map.drop(&1, ["source_study_id", "source_plan_generated_at"])
      )
      |> update_in(
        ["operator_review_package", "provenance"],
        &Map.drop(&1, ["source_study_id", "source_plan_generated_at"])
      )
      |> update_in(
        ["cadence_import_manifest", "provenance"],
        &Map.drop(&1, ["source_artifact_type", "source_plan_id"])
      )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  test "rejects Repair provenance handoff drift", %{repair: repair} do
    invalid_cases = [
      {"$.provenance.source_study_id", Map.put(repair, "study_id", "study_drift")},
      {"$.operator_review_package.source_artifact_type",
       put_in(
         repair,
         ["operator_review_package", "source_artifact_type"],
         "campaign_plan.v1"
       )},
      {"$.operator_review_package.provenance.source_plan_generated_at",
       put_in(
         repair,
         ["operator_review_package", "provenance", "source_plan_generated_at"],
         "2026-05-14T00:01:00Z"
       )},
      {"$.operator_review_package.provenance.source_provenance",
       put_in(
         repair,
         ["operator_review_package", "provenance", "source_provenance", "git_revision"],
         "drift"
       )},
      {"$.cadence_import_manifest.provenance.source_artifact_type",
       put_in(
         repair,
         ["cadence_import_manifest", "provenance", "source_artifact_type"],
         "campaign_plan.v1"
       )},
      {"$.cadence_import_manifest.provenance.source_plan_id",
       put_in(
         repair,
         ["cadence_import_manifest", "provenance", "source_plan_id"],
         "campaign_plan:drift"
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
