defmodule OrbitalDynamics.Schema.CampaignRepairApprovalHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  @repair_approval_source "campaign_repair.approval_requirements"

  setup do
    %{
      repair: read_json!("study_results/leo_constellation_campaign_repair_v2.json"),
      readiness_repair:
        read_json!("study_results/campaign_repair_readiness_source_handoff_v2.json")
    }
  end

  test "validates checked Repair approval review handoffs", context do
    for artifact <- [context.repair, context.readiness_repair] do
      assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
               Schema.validate_artifact(artifact)
    end
  end

  test "keeps additive approval review handoffs optional", %{repair: repair} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    review_index = approval_review_index(repair)
    cadence_index = approval_import_index(repair)

    older =
      repair
      |> update_in(
        ["operator_review_package", "rows", Access.at(review_index)],
        &Map.delete(&1, "source_requirement")
      )
      |> update_in(
        ["cadence_import_manifest", "rows", Access.at(cadence_index)],
        fn row ->
          row
          |> Map.delete("source_requirement")
          |> update_in(["source_review_row"], &Map.delete(&1, "source_requirement"))
        end
      )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(older)
  end

  test "rejects Repair approval review handoff drift", %{repair: repair} do
    review_index = approval_review_index(repair)
    cadence_index = approval_import_index(repair)

    review_source_drift =
      put_in(
        repair,
        ["operator_review_package", "rows", Access.at(review_index), "source"],
        "campaign_plan.approval_requirements"
      )

    review_drift =
      update_in(
        repair,
        ["operator_review_package", "rows", Access.at(review_index)],
        fn row ->
          row
          |> Map.put("reason", "drifted requirement reason")
          |> put_in(["source_requirement", "reason"], "drifted requirement reason")
        end
      )

    cadence_drift =
      update_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(cadence_index)],
        fn row ->
          row
          |> Map.put("reason", "drifted requirement reason")
          |> put_in(["source_requirement", "reason"], "drifted requirement reason")
          |> put_in(["source_review_row", "reason"], "drifted requirement reason")
          |> put_in(
            ["source_review_row", "source_requirement", "reason"],
            "drifted requirement reason"
          )
        end
      )

    invalid_cases = [
      {"$.operator_review_package.approval_requirement_count",
       put_in(repair, ["operator_review_package", "approval_requirement_count"], 2)},
      {"$.operator_review_package.rows", review_source_drift},
      {"$.operator_review_package.rows[#{review_index}].source_requirement", review_drift},
      {"$.cadence_import_manifest.rows[#{cadence_index}].source_requirement", cadence_drift}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  defp approval_review_index(repair) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &(Map.get(&1, "review_type") == "approval_requirement" and
          Map.get(&1, "source") == @repair_approval_source)
    )
  end

  defp approval_import_index(repair) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &(Map.get(&1, "source_review_type") == "approval_requirement")
    )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
