defmodule OrbitalDynamics.Schema.CampaignRepairWarningHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  @repair_warning_source "campaign_repair.warnings"

  setup do
    %{
      repair: read_json!("study_results/leo_constellation_campaign_repair_v2.json"),
      readiness_repair:
        read_json!("study_results/campaign_repair_readiness_source_handoff_v2.json")
    }
  end

  test "validates checked Repair warning review handoffs", context do
    for artifact <- [context.repair, context.readiness_repair] do
      assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
               Schema.validate_artifact(artifact)
    end
  end

  test "keeps additive warning review handoffs optional", %{repair: repair} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    cadence_index = warning_import_index(repair)

    older =
      update_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(cadence_index)],
        &Map.delete(&1, "source_review_row")
      )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(older)
  end

  test "rejects Repair warning review handoff drift", %{repair: repair} do
    review_index = warning_review_index(repair)
    cadence_index = warning_import_index(repair)

    review_source_drift =
      put_in(
        repair,
        ["operator_review_package", "rows", Access.at(review_index), "source"],
        "campaign_plan.warnings"
      )

    cadence_source_drift =
      repair
      |> put_in(
        ["cadence_import_manifest", "rows", Access.at(cadence_index), "source"],
        "campaign_plan.warnings"
      )
      |> put_in(
        [
          "cadence_import_manifest",
          "rows",
          Access.at(cadence_index),
          "source_review_row",
          "source"
        ],
        "campaign_plan.warnings"
      )

    review_drift =
      put_in(
        repair,
        ["operator_review_package", "rows", Access.at(review_index), "reason"],
        "drifted warning"
      )

    cadence_drift =
      repair
      |> put_in(
        ["cadence_import_manifest", "rows", Access.at(cadence_index), "reason"],
        "drifted warning"
      )
      |> put_in(
        [
          "cadence_import_manifest",
          "rows",
          Access.at(cadence_index),
          "source_review_row",
          "reason"
        ],
        "drifted warning"
      )

    invalid_cases = [
      {"$.operator_review_package.warning_count",
       put_in(repair, ["operator_review_package", "warning_count"], 4)},
      {"$.operator_review_package.rows", review_source_drift},
      {"$.cadence_import_manifest.rows", cadence_source_drift},
      {"$.operator_review_package.rows[#{review_index}].reason", review_drift},
      {"$.cadence_import_manifest.rows[#{cadence_index}].reason", cadence_drift},
      {"$.cadence_import_manifest.rows[#{cadence_index}].source_review_row.reason", cadence_drift}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  defp warning_review_index(repair) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &(Map.get(&1, "review_type") == "warning" and
          Map.get(&1, "source") == @repair_warning_source)
    )
  end

  defp warning_import_index(repair) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &(Map.get(&1, "source_review_type") == "warning" and
          Map.get(&1, "source") == @repair_warning_source)
    )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
