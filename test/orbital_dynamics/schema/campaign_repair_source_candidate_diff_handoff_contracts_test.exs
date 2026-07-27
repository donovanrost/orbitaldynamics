Code.require_file("../campaign_planner/support.exs", __DIR__)

defmodule OrbitalDynamics.Schema.CampaignRepairSourceCandidateDiffHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.TestSupport
  alias OrbitalDynamics.OperatorReview.CandidateDiff
  alias OrbitalDynamics.Schema

  @source_prefix "campaign_repair.source_candidate_diff_report"

  setup_all do
    candidate_refresh = read_json!("study_results/candidate_refresh_v1.json")

    repair =
      TestSupport.repair(
        %{"activities" => [], "candidate_activities" => []},
        realized_state: %{activities: []},
        current_epoch_s: 0.0,
        candidate_refresh: candidate_refresh
      )

    source_report = repair["source_candidate_diff_report"]

    expected_rows =
      CandidateDiff.report_rows(
        source_report,
        @source_prefix,
        repair["source_window_lineage"]
      )

    %{repair: repair, source_report: source_report, expected_rows: expected_rows}
  end

  test "validates exact review-eligible source diff rows, families, and evidence", %{
    repair: repair,
    expected_rows: expected_rows
  } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    review_rows = source_review_rows(repair)
    import_rows = source_import_rows(repair)

    assert Enum.map(review_rows, &{&1["source"], &1["subject_id"]}) == [
             {@source_prefix <> ".invalidated_candidates", "old_candidate"}
           ]

    assert Enum.map(import_rows, &{row_source(&1), &1["subject_id"]}) == [
             {@source_prefix <> ".invalidated_candidates", "old_candidate"}
           ]

    assert Enum.map(review_rows, & &1["source_candidate_diff"]) ==
             Enum.map(expected_rows, & &1["source_candidate_diff"])

    assert Enum.map(import_rows, &get_in(&1, ["source_review_row", "source_candidate_diff"])) ==
             Enum.map(expected_rows, & &1["source_candidate_diff"])
  end

  test "keeps additive candidate-diff packages and source copies optional", %{repair: repair} do
    assert {:ok, %{"schema_version" => 2}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    older =
      repair
      |> update_in(["operator_review_package", "rows"], fn rows ->
        Enum.map(rows, &drop_source_copy/1)
      end)
      |> update_in(["cadence_import_manifest", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if candidate_diff_row?(row) do
            row
            |> drop_source_copy()
            |> update_in(["source_review_row"], &drop_source_copy/1)
          else
            row
          end
        end)
      end)

    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(older)
  end

  test "rejects source candidate-diff identity drift at every produced path", %{
    repair: repair
  } do
    review_index = source_review_index(repair)
    import_index = source_import_index(repair)
    wrong_source = @source_prefix <> ".invalidated_candidates.legacy"

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source",
       put_in(
         repair,
         ["operator_review_package", "rows", Access.at(review_index), "source"],
         wrong_source
       )},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source",
       put_in(
         repair,
         [
           "cadence_import_manifest",
           "rows",
           Access.at(import_index),
           "source_review_row",
           "source"
         ],
         wrong_source
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects source candidate-diff copy drift at every evidence path", %{repair: repair} do
    review_index = source_review_index(repair)
    import_index = source_import_index(repair)

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source_candidate_diff",
       put_in(
         repair,
         [
           "operator_review_package",
           "rows",
           Access.at(review_index),
           "source_candidate_diff",
           "target_priority"
         ],
         999
       )},
      {"$.cadence_import_manifest.rows[#{import_index}].source_candidate_diff",
       put_in(
         repair,
         [
           "cadence_import_manifest",
           "rows",
           Access.at(import_index),
           "source_candidate_diff",
           "target_priority"
         ],
         999
       )},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_candidate_diff",
       put_in(
         repair,
         [
           "cadence_import_manifest",
           "rows",
           Access.at(import_index),
           "source_review_row",
           "source_candidate_diff",
           "target_priority"
         ],
         999
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects coordinated evidence drift, missing rows, and stale handoffs", %{
    repair: repair
  } do
    review_index = source_review_index(repair)
    import_index = source_import_index(repair)

    coordinated_drift =
      repair
      |> update_in(
        ["operator_review_package", "rows", Access.at(review_index)],
        &put_target_priority_drift(&1, false)
      )
      |> update_in(
        ["cadence_import_manifest", "rows", Access.at(import_index)],
        &put_target_priority_drift(&1, true)
      )

    missing_review =
      update_in(repair, ["operator_review_package", "rows"], fn rows ->
        List.delete_at(rows, review_index)
      end)

    missing_import =
      update_in(repair, ["cadence_import_manifest", "rows"], fn rows ->
        List.delete_at(rows, import_index)
      end)

    stale_handoffs = Map.delete(repair, "source_candidate_diff_report")

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source_candidate_diff",
       coordinated_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_candidate_diff",
       coordinated_drift},
      {"$.operator_review_package.rows", missing_review},
      {"$.cadence_import_manifest.rows", missing_import},
      {"$.operator_review_package.rows", stale_handoffs},
      {"$.cadence_import_manifest.rows", stale_handoffs}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  defp put_target_priority_drift(row, nested?) do
    row =
      row
      |> Map.put("target_priority", 999)
      |> put_in(["source_candidate_diff", "target_priority"], 999)

    if nested? do
      row
      |> put_in(["source_review_row", "target_priority"], 999)
      |> put_in(["source_review_row", "source_candidate_diff", "target_priority"], 999)
    else
      row
    end
  end

  defp drop_source_copy(row) do
    if candidate_diff_row?(row), do: Map.delete(row, "source_candidate_diff"), else: row
  end

  defp source_review_rows(repair) do
    Enum.filter(get_in(repair, ["operator_review_package", "rows"]), &candidate_diff_row?/1)
  end

  defp source_import_rows(repair) do
    Enum.filter(get_in(repair, ["cadence_import_manifest", "rows"]), &candidate_diff_row?/1)
  end

  defp source_review_index(repair) do
    Enum.find_index(get_in(repair, ["operator_review_package", "rows"]), &candidate_diff_row?/1)
  end

  defp source_import_index(repair) do
    Enum.find_index(get_in(repair, ["cadence_import_manifest", "rows"]), &candidate_diff_row?/1)
  end

  defp candidate_diff_row?(row) do
    case row_source(row) do
      source when is_binary(source) -> String.starts_with?(source, @source_prefix)
      _source -> false
    end
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
