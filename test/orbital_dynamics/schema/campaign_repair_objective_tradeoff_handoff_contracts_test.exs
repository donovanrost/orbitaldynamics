defmodule OrbitalDynamics.Schema.CampaignRepairObjectiveTradeoffHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  @repair_tradeoff_source "campaign_repair.objective_tradeoff_report.tradeoffs"

  setup do
    %{
      repair: read_json!("study_results/leo_constellation_campaign_repair_v2.json"),
      readiness_repair:
        read_json!("study_results/campaign_repair_readiness_source_handoff_v2.json")
    }
  end

  test "validates checked Repair objective-tradeoff review handoffs", context do
    for artifact <- [context.repair, context.readiness_repair] do
      assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
               Schema.validate_artifact(artifact)
    end
  end

  test "keeps additive objective-tradeoff review handoffs optional", %{repair: repair} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    review_index = tradeoff_review_index(repair)
    cadence_index = tradeoff_import_index(repair)

    older =
      repair
      |> update_in(
        ["operator_review_package", "rows", Access.at(review_index)],
        &Map.delete(&1, "source_objective_tradeoff")
      )
      |> update_in(
        ["cadence_import_manifest", "rows", Access.at(cadence_index)],
        fn row ->
          row
          |> Map.delete("source_objective_tradeoff")
          |> update_in(["source_review_row"], &Map.delete(&1, "source_objective_tradeoff"))
        end
      )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(older)
  end

  test "rejects Repair objective-tradeoff review handoff drift", %{repair: repair} do
    review_index = tradeoff_review_index(repair)
    cadence_index = tradeoff_import_index(repair)

    review_count_drift =
      put_in(
        repair,
        ["operator_review_package", "rows", Access.at(review_index), "source"],
        "campaign_repair.source_objective_tradeoff_report.tradeoffs"
      )

    cadence_count_drift =
      repair
      |> put_in(
        ["cadence_import_manifest", "rows", Access.at(cadence_index), "source"],
        "campaign_repair.source_objective_tradeoff_report.tradeoffs"
      )
      |> put_in(
        [
          "cadence_import_manifest",
          "rows",
          Access.at(cadence_index),
          "source_review_row",
          "source"
        ],
        "campaign_repair.source_objective_tradeoff_report.tradeoffs"
      )

    review_copy_drift =
      update_in(
        repair,
        ["operator_review_package", "rows", Access.at(review_index)],
        &drift_tradeoff_row/1
      )

    cadence_copy_drift =
      update_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(cadence_index)],
        fn row ->
          row
          |> drift_tradeoff_row()
          |> update_in(["source_review_row"], &drift_tradeoff_row/1)
        end
      )

    invalid_cases = [
      {"$.operator_review_package.rows", review_count_drift},
      {"$.cadence_import_manifest.rows", cadence_count_drift},
      {"$.operator_review_package.rows[#{review_index}].source_objective_tradeoff",
       review_copy_drift},
      {"$.cadence_import_manifest.rows[#{cadence_index}].source_objective_tradeoff",
       cadence_copy_drift},
      {"$.cadence_import_manifest.rows[#{cadence_index}].source_review_row.source_objective_tradeoff",
       cadence_copy_drift}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  defp drift_tradeoff_row(row) do
    row
    |> Map.put("score", 42)
    |> put_in(["source_objective_tradeoff", "score"], 42)
  end

  defp tradeoff_review_index(repair) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &(Map.get(&1, "review_type") == "objective_tradeoff_review" and
          Map.get(&1, "source") == @repair_tradeoff_source)
    )
  end

  defp tradeoff_import_index(repair) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &(Map.get(&1, "source_review_type") == "objective_tradeoff_review" and
          Map.get(&1, "source") == @repair_tradeoff_source)
    )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
