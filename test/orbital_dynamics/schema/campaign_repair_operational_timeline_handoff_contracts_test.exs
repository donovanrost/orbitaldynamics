defmodule OrbitalDynamics.Schema.CampaignRepairOperationalTimelineHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  @repair_operational_timeline_source "operational_timeline_report.rows"

  setup do
    %{
      repair: read_json!("study_results/leo_constellation_campaign_repair_v2.json"),
      readiness_repair:
        read_json!("study_results/campaign_repair_readiness_source_handoff_v2.json")
    }
  end

  test "validates checked Repair operational-timeline review handoffs", context do
    for artifact <- [context.repair, context.readiness_repair] do
      assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
               Schema.validate_artifact(artifact)
    end
  end

  test "keeps additive operational-timeline review handoffs optional", %{
    readiness_repair: repair
  } do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    review_index = timeline_review_index(repair)
    cadence_index = timeline_import_index(repair)

    older =
      repair
      |> update_in(
        ["operator_review_package", "rows", Access.at(review_index)],
        &Map.delete(&1, "source_operational_timeline")
      )
      |> update_in(
        ["cadence_import_manifest", "rows", Access.at(cadence_index)],
        fn row ->
          row
          |> Map.delete("source_operational_timeline")
          |> update_in(
            ["source_review_row"],
            &Map.delete(&1, "source_operational_timeline")
          )
        end
      )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(older)
  end

  test "rejects Repair operational-timeline review handoff drift", %{
    readiness_repair: repair
  } do
    review_index = timeline_review_index(repair)
    cadence_index = timeline_import_index(repair)

    review_count_drift =
      put_in(
        repair,
        ["operator_review_package", "rows", Access.at(review_index), "source"],
        "campaign_repair.operational_timeline_report.rows"
      )

    cadence_count_drift =
      update_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(cadence_index)],
        fn row ->
          row
          |> Map.put("source", "campaign_repair.operational_timeline_report.rows")
          |> put_in(
            ["source_review_row", "source"],
            "campaign_repair.operational_timeline_report.rows"
          )
        end
      )

    review_copy_drift =
      update_in(
        repair,
        [
          "operator_review_package",
          "rows",
          Access.at(review_index),
          "source_operational_timeline"
        ],
        &Map.put(&1, "rank", 99)
      )

    cadence_copy_drift =
      update_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(cadence_index)],
        fn row ->
          row
          |> update_in(["source_operational_timeline"], &Map.put(&1, "rank", 99))
          |> update_in(
            ["source_review_row", "source_operational_timeline"],
            &Map.put(&1, "rank", 99)
          )
        end
      )

    stale_handoffs = Map.delete(repair, "operational_timeline_report")

    invalid_cases = [
      {"$.operator_review_package.rows", review_count_drift},
      {"$.cadence_import_manifest.rows", cadence_count_drift},
      {"$.operator_review_package.rows[#{review_index}].source_operational_timeline",
       review_copy_drift},
      {"$.cadence_import_manifest.rows[#{cadence_index}].source_operational_timeline",
       cadence_copy_drift},
      {"$.cadence_import_manifest.rows[#{cadence_index}].source_review_row.source_operational_timeline",
       cadence_copy_drift},
      {"$.operator_review_package.rows", stale_handoffs},
      {"$.cadence_import_manifest.rows", stale_handoffs}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  defp timeline_review_index(repair) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &(Map.get(&1, "review_type") == "operational_timeline_review" and
          Map.get(&1, "source") == @repair_operational_timeline_source)
    )
  end

  defp timeline_import_index(repair) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &(Map.get(&1, "source_review_type") == "operational_timeline_review" and
          Map.get(&1, "source") == @repair_operational_timeline_source)
    )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
