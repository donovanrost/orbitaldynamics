Code.require_file("../campaign_planner/support.exs", __DIR__)

defmodule OrbitalDynamics.Schema.CampaignRepairConstraintHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.TestSupport
  alias OrbitalDynamics.Schema

  @repair_source_constraint "campaign_repair.source_constraint_report.rows"

  setup_all do
    source_report = read_json!("study_results/constraint_report_v1.json")

    candidate_refresh =
      "study_results/candidate_refresh_v1.json"
      |> read_json!()
      |> put_in(["candidate_refresh", "source_constraint_report"], source_report)

    repair =
      TestSupport.repair(
        %{"activities" => [], "candidate_activities" => []},
        realized_state: %{activities: []},
        current_epoch_s: 0.0,
        candidate_refresh: candidate_refresh
      )

    %{repair: repair}
  end

  test "validates Repair source constraint handoffs in producer order", %{repair: repair} do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    expected = [
      {"minimum_operational_altitude", "fail"},
      {"downlink_margin", "warning"}
    ]

    assert expected ==
             repair
             |> get_in(["operator_review_package", "rows"])
             |> Enum.filter(&(row_source(&1) == @repair_source_constraint))
             |> Enum.map(&{&1["constraint_id"], &1["constraint_status"]})

    assert expected ==
             repair
             |> get_in(["cadence_import_manifest", "rows"])
             |> Enum.filter(&(row_source(&1) == @repair_source_constraint))
             |> Enum.map(&{&1["constraint_id"], &1["constraint_status"]})
  end

  test "keeps additive source constraint handoffs optional", %{repair: repair} do
    assert {:ok, %{"schema_version" => 2}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    older =
      repair
      |> update_in(["operator_review_package", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if row_source(row) == @repair_source_constraint,
            do: Map.delete(row, "source_constraint_row"),
            else: row
        end)
      end)
      |> update_in(["cadence_import_manifest", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if row_source(row) == @repair_source_constraint do
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

  test "rejects Repair source constraint handoff drift", %{repair: repair} do
    review_index = constraint_review_index(repair)
    import_index = constraint_import_index(repair)

    review_count_drift =
      put_in(
        repair,
        ["operator_review_package", "rows", Access.at(review_index), "source"],
        "source_constraint_report.rows"
      )

    cadence_count_drift =
      put_in(
        repair,
        [
          "cadence_import_manifest",
          "rows",
          Access.at(import_index),
          "source"
        ],
        "source_constraint_report.rows"
      )

    cadence_nested_source_drift =
      put_in(
        repair,
        [
          "cadence_import_manifest",
          "rows",
          Access.at(import_index),
          "source_review_row",
          "source"
        ],
        "campaign_repair.unrelated.rows"
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

    stale_handoffs = Map.delete(repair, "source_constraint_report")

    invalid_cases = [
      {"$.operator_review_package.rows", review_count_drift},
      {"$.cadence_import_manifest.rows", cadence_count_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source",
       cadence_nested_source_drift},
      {"$.operator_review_package.rows[#{review_index}].source_constraint_row",
       review_copy_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_constraint_row",
       cadence_copy_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_constraint_row",
       cadence_copy_drift},
      {"$.operator_review_package.rows", stale_handoffs},
      {"$.cadence_import_manifest.rows", stale_handoffs}
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
          row_source(&1) == @repair_source_constraint)
    )
  end

  defp constraint_import_index(repair) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &(Map.get(&1, "source_review_type") == "constraint_review" and
          row_source(&1) == @repair_source_constraint)
    )
  end

  defp row_source(row) do
    Map.get(row, "source") || get_in(row, ["source_review_row", "source"])
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
