Code.require_file("../campaign_planner/support.exs", __DIR__)

defmodule OrbitalDynamics.Schema.CampaignRepairSourceScoreTermHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.TestSupport
  alias OrbitalDynamics.Schema

  @repair_source_score_term "campaign_repair.source_score_term_report.rows"

  setup_all do
    source_report = read_json!("study_results/score_term_report_v1.json")

    candidate_refresh =
      "study_results/candidate_refresh_v1.json"
      |> read_json!()
      |> put_in(["candidate_refresh", "source_score_term_report"], source_report)

    repair =
      TestSupport.repair(
        %{"activities" => [], "candidate_activities" => []},
        realized_state: %{activities: []},
        current_epoch_s: 0.0,
        candidate_refresh: candidate_refresh
      )

    %{repair: repair, source_rows: source_report["rows"]}
  end

  test "validates Repair source score-term handoffs in producer order", %{
    repair: repair,
    source_rows: source_rows
  } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    expected = Enum.map(source_rows, &{&1["id"], &1["rank"], &1["term_key"]})

    assert expected ==
             repair
             |> get_in(["operator_review_package", "rows"])
             |> Enum.filter(&(row_source(&1) == @repair_source_score_term))
             |> Enum.map(&score_term_identity/1)

    assert expected ==
             repair
             |> get_in(["cadence_import_manifest", "rows"])
             |> Enum.filter(&(row_source(&1) == @repair_source_score_term))
             |> Enum.map(&score_term_identity/1)
  end

  test "keeps additive source score-term handoffs optional", %{repair: repair} do
    assert {:ok, %{"schema_version" => 2}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    older =
      repair
      |> update_in(["operator_review_package", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if row_source(row) == @repair_source_score_term,
            do: Map.delete(row, "source_score_term"),
            else: row
        end)
      end)
      |> update_in(["cadence_import_manifest", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if row_source(row) == @repair_source_score_term do
            row
            |> Map.delete("source_score_term")
            |> update_in(["source_review_row"], &Map.delete(&1, "source_score_term"))
          else
            row
          end
        end)
      end)

    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(older)
  end

  test "rejects Repair source score-term handoff drift", %{repair: repair} do
    review_index = score_term_review_index(repair)
    import_index = score_term_import_index(repair)

    review_count_drift =
      put_in(
        repair,
        ["operator_review_package", "rows", Access.at(review_index), "source"],
        "source_score_term_report.rows"
      )

    cadence_count_drift =
      put_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(import_index), "source"],
        "source_score_term_report.rows"
      )

    review_copy_drift =
      put_in(
        repair,
        [
          "operator_review_package",
          "rows",
          Access.at(review_index),
          "source_score_term",
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
          |> put_in(["source_score_term", "rank"], 99)
          |> put_in(["source_review_row", "source_score_term", "rank"], 99)
        end
      )

    invalid_cases = [
      {"$.operator_review_package.rows", review_count_drift},
      {"$.cadence_import_manifest.rows", cadence_count_drift},
      {"$.operator_review_package.rows[#{review_index}].source_score_term", review_copy_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_score_term", cadence_copy_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_score_term",
       cadence_copy_drift}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  defp score_term_identity(row) do
    {row["source_score_term"]["id"], row["source_score_term"]["rank"], row["term_key"]}
  end

  defp score_term_review_index(repair) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &(Map.get(&1, "review_type") == "score_term_review" and
          row_source(&1) == @repair_source_score_term)
    )
  end

  defp score_term_import_index(repair) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &(Map.get(&1, "source_review_type") == "score_term_review" and
          row_source(&1) == @repair_source_score_term)
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
