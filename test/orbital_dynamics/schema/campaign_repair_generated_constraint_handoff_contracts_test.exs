Code.require_file("../campaign_planner/support.exs", __DIR__)

defmodule OrbitalDynamics.Schema.CampaignRepairGeneratedConstraintHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.TestSupport
  alias OrbitalDynamics.Schema

  @repair_constraint "campaign_repair.constraint_report.rows"

  setup_all do
    activity = TestSupport.refreshed_downlink("dl_1", 100.0, 160.0)

    repair =
      TestSupport.repair(
        %{"activities" => [activity], "candidate_activities" => [activity]},
        realized_state: %{activities: []},
        current_epoch_s: 0.0,
        constraints: %{
          max_timeline_activities: %{threshold: 0, severity: :warning}
        }
      )

    %{repair: repair}
  end

  test "validates Repair generated constraint handoffs in producer order", %{repair: repair} do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    expected = [{"campaign:max_timeline_activities", "warning"}]

    assert expected ==
             repair
             |> get_in(["operator_review_package", "rows"])
             |> Enum.filter(&(row_source(&1) == @repair_constraint))
             |> Enum.map(&{&1["constraint_id"], &1["constraint_status"]})

    assert expected ==
             repair
             |> get_in(["cadence_import_manifest", "rows"])
             |> Enum.filter(&(row_source(&1) == @repair_constraint))
             |> Enum.map(&{&1["constraint_id"], &1["constraint_status"]})
  end

  test "keeps additive generated constraint handoffs optional", %{repair: repair} do
    assert {:ok, %{"schema_version" => 2}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    older =
      repair
      |> update_in(["operator_review_package", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if row_source(row) == @repair_constraint,
            do: Map.delete(row, "source_constraint_row"),
            else: row
        end)
      end)
      |> update_in(["cadence_import_manifest", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if row_source(row) == @repair_constraint do
            row
            |> Map.delete("source_constraint_row")
            |> update_in(["source_review_row"], &Map.delete(&1, "source_constraint_row"))
          else
            row
          end
        end)
      end)

    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(older)
  end

  test "rejects Repair generated constraint handoff drift", %{repair: repair} do
    review_index = constraint_review_index(repair)
    import_index = constraint_import_index(repair)

    review_count_drift =
      put_in(
        repair,
        ["operator_review_package", "rows", Access.at(review_index), "source"],
        "constraint_report.rows"
      )

    cadence_count_drift =
      put_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(import_index), "source"],
        "constraint_report.rows"
      )

    review_copy_drift =
      put_in(
        repair,
        [
          "operator_review_package",
          "rows",
          Access.at(review_index),
          "source_constraint_row",
          "rank"
        ],
        99
      )

    cadence_copy_drift =
      update_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(import_index)],
        fn row ->
          row
          |> put_in(["source_constraint_row", "rank"], 99)
          |> put_in(["source_review_row", "source_constraint_row", "rank"], 99)
        end
      )

    invalid_cases = [
      {"$.operator_review_package.rows", review_count_drift},
      {"$.cadence_import_manifest.rows", cadence_count_drift},
      {"$.operator_review_package.rows[#{review_index}].source_constraint_row",
       review_copy_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_constraint_row",
       cadence_copy_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_constraint_row",
       cadence_copy_drift}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  defp constraint_review_index(repair) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &(Map.get(&1, "review_type") == "constraint_review" and
          row_source(&1) == @repair_constraint)
    )
  end

  defp constraint_import_index(repair) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &(Map.get(&1, "source_review_type") == "constraint_review" and
          row_source(&1) == @repair_constraint)
    )
  end

  defp row_source(row) do
    Map.get(row, "source") || get_in(row, ["source_review_row", "source"])
  end
end
