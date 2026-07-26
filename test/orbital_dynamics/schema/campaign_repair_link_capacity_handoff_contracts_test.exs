defmodule OrbitalDynamics.Schema.CampaignRepairLinkCapacityHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  @repair_capacity_source "campaign_repair.link_capacity_report.rows"

  setup do
    %{
      repair: read_json!("study_results/leo_constellation_campaign_repair_v2.json"),
      readiness_repair:
        read_json!("study_results/campaign_repair_readiness_source_handoff_v2.json")
    }
  end

  test "validates checked Repair link-capacity review handoffs", context do
    for artifact <- [context.repair, context.readiness_repair] do
      assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
               Schema.validate_artifact(artifact)
    end
  end

  test "keeps additive link-capacity review handoffs optional", %{readiness_repair: repair} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    review_index = capacity_review_index(repair)
    cadence_index = capacity_import_index(repair)

    older =
      repair
      |> update_in(
        ["operator_review_package", "rows", Access.at(review_index)],
        &Map.delete(&1, "source_link_capacity")
      )
      |> update_in(
        ["cadence_import_manifest", "rows", Access.at(cadence_index)],
        fn row ->
          row
          |> Map.delete("source_link_capacity")
          |> update_in(["source_review_row"], &Map.delete(&1, "source_link_capacity"))
        end
      )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(older)
  end

  test "rejects Repair link-capacity review handoff drift", %{readiness_repair: repair} do
    review_index = capacity_review_index(repair)
    cadence_index = capacity_import_index(repair)

    review_count_drift =
      put_in(
        repair,
        ["operator_review_package", "rows", Access.at(review_index), "source"],
        "campaign_repair.source_link_capacity_report.rows"
      )

    cadence_count_drift =
      update_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(cadence_index)],
        fn row ->
          row
          |> Map.put("source", "campaign_repair.source_link_capacity_report.rows")
          |> put_in(
            ["source_review_row", "source"],
            "campaign_repair.source_link_capacity_report.rows"
          )
        end
      )

    review_copy_drift =
      update_in(
        repair,
        ["operator_review_package", "rows", Access.at(review_index), "source_link_capacity"],
        &Map.put(&1, "effective_contact_count", 99)
      )

    cadence_copy_drift =
      update_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(cadence_index)],
        fn row ->
          row
          |> update_in(
            ["source_link_capacity"],
            &Map.put(&1, "effective_contact_count", 99)
          )
          |> update_in(
            ["source_review_row", "source_link_capacity"],
            &Map.put(&1, "effective_contact_count", 99)
          )
        end
      )

    invalid_cases = [
      {"$.operator_review_package.rows", review_count_drift},
      {"$.cadence_import_manifest.rows", cadence_count_drift},
      {"$.operator_review_package.rows[#{review_index}].source_link_capacity", review_copy_drift},
      {"$.cadence_import_manifest.rows[#{cadence_index}].source_link_capacity",
       cadence_copy_drift},
      {"$.cadence_import_manifest.rows[#{cadence_index}].source_review_row.source_link_capacity",
       cadence_copy_drift}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  defp capacity_review_index(repair) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &(Map.get(&1, "review_type") == "link_capacity_review" and
          Map.get(&1, "source") == @repair_capacity_source)
    )
  end

  defp capacity_import_index(repair) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &(Map.get(&1, "source_review_type") == "link_capacity_review" and
          Map.get(&1, "source") == @repair_capacity_source)
    )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
