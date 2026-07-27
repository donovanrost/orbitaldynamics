Code.require_file("../campaign_planner/support.exs", __DIR__)

defmodule OrbitalDynamics.Schema.CampaignRepairSourceRefreshBudgetHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.TestSupport
  alias OrbitalDynamics.OperatorReview.RefreshState
  alias OrbitalDynamics.Schema

  @source "campaign_repair.source_refresh_budget_report"

  setup_all do
    candidate_refresh =
      "study_results/candidate_refresh_v1.json"
      |> read_json!()
      |> Map.fetch!("candidate_refresh")

    [kept_id, dropped_id] =
      Enum.map(candidate_refresh["candidate_activities"], &Map.fetch!(&1, "id"))

    source_report =
      candidate_refresh["refresh_budget_report"]
      |> Map.merge(%{
        "input_candidate_count" => 2,
        "kept_candidate_count" => 1,
        "dropped_candidate_count" => 1,
        "max_candidate_activities" => 1,
        "kept_candidate_ids" => [kept_id],
        "dropped_candidate_ids" => [dropped_id]
      })

    candidate_refresh = Map.put(candidate_refresh, "refresh_budget_report", source_report)

    repair =
      TestSupport.repair(
        %{"activities" => [], "candidate_activities" => []},
        realized_state: %{activities: []},
        current_epoch_s: 0.0,
        candidate_refresh: candidate_refresh
      )

    expected_rows = RefreshState.refresh_budget_rows(source_report, @source)

    %{repair: repair, expected_rows: expected_rows, dropped_id: dropped_id}
  end

  test "replays refresh-budget review eligibility and evidence", %{
    repair: repair,
    expected_rows: expected_rows,
    dropped_id: dropped_id
  } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    assert [%{"source" => @source} = review_row] = source_review_rows(repair)
    assert [import_row] = source_import_rows(repair)
    assert [expected_row] = expected_rows

    assert review_row["subject_id"] == expected_row["subject_id"]
    assert review_row["dropped_candidate_ids"] == [dropped_id]
    assert row_source(import_row) == @source
    assert import_row["dropped_candidate_ids"] == [dropped_id]

    assert review_row["source_refresh_budget_report"] ==
             expected_row["source_refresh_budget_report"]

    assert get_in(import_row, ["source_review_row", "source_refresh_budget_report"]) ==
             expected_row["source_refresh_budget_report"]
  end

  test "keeps additive review packages and source copies optional", %{repair: repair} do
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
          if source_refresh_budget_row?(row) do
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

  test "rejects source refresh-budget identity drift at every produced path", %{
    repair: repair
  } do
    review_index = source_review_index(repair)
    import_index = source_import_index(repair)
    wrong_source = @source <> ".legacy"

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

  test "rejects source refresh-budget copy drift at every evidence path", %{
    repair: repair
  } do
    review_index = source_review_index(repair)
    import_index = source_import_index(repair)

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source_refresh_budget_report",
       put_in(
         repair,
         dropped_ids_path("operator_review_package", review_index, false),
         ["legacy_dropped"]
       )},
      {"$.cadence_import_manifest.rows[#{import_index}].source_refresh_budget_report",
       put_in(
         repair,
         dropped_ids_path("cadence_import_manifest", import_index, false),
         ["legacy_dropped"]
       )},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_refresh_budget_report",
       put_in(
         repair,
         dropped_ids_path("cadence_import_manifest", import_index, true),
         ["legacy_dropped"]
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects coordinated dropped-candidate drift, missing rows, and stale handoffs", %{
    repair: repair
  } do
    review_index = source_review_index(repair)
    import_index = source_import_index(repair)

    coordinated_drift =
      repair
      |> update_in(
        ["operator_review_package", "rows", Access.at(review_index)],
        &put_dropped_candidate_drift(&1, false)
      )
      |> update_in(
        ["cadence_import_manifest", "rows", Access.at(import_index)],
        &put_dropped_candidate_drift(&1, true)
      )

    missing_review =
      update_in(repair, ["operator_review_package", "rows"], fn rows ->
        List.delete_at(rows, review_index)
      end)

    missing_import =
      update_in(repair, ["cadence_import_manifest", "rows"], fn rows ->
        List.delete_at(rows, import_index)
      end)

    stale_handoffs = Map.delete(repair, "source_refresh_budget_report")

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source_refresh_budget_report",
       coordinated_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_refresh_budget_report",
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

  defp put_dropped_candidate_drift(row, nested?) do
    row =
      row
      |> Map.put("dropped_candidate_count", 2)
      |> Map.put("dropped_candidate_ids", ["legacy_a", "legacy_b"])
      |> put_in(["source_refresh_budget_report", "dropped_candidate_count"], 2)
      |> put_in(
        ["source_refresh_budget_report", "dropped_candidate_ids"],
        ["legacy_a", "legacy_b"]
      )

    if nested? do
      row
      |> put_in(["source_review_row", "dropped_candidate_count"], 2)
      |> put_in(
        ["source_review_row", "dropped_candidate_ids"],
        ["legacy_a", "legacy_b"]
      )
      |> put_in(
        ["source_review_row", "source_refresh_budget_report", "dropped_candidate_count"],
        2
      )
      |> put_in(
        ["source_review_row", "source_refresh_budget_report", "dropped_candidate_ids"],
        ["legacy_a", "legacy_b"]
      )
    else
      row
    end
  end

  defp dropped_ids_path(package, index, nested?) do
    prefix = [package, "rows", Access.at(index)]

    evidence_path =
      if nested?,
        do: ["source_review_row", "source_refresh_budget_report"],
        else: ["source_refresh_budget_report"]

    prefix ++ evidence_path ++ ["dropped_candidate_ids"]
  end

  defp drop_source_copy(row) do
    if source_refresh_budget_row?(row),
      do: Map.delete(row, "source_refresh_budget_report"),
      else: row
  end

  defp source_review_rows(repair) do
    Enum.filter(
      get_in(repair, ["operator_review_package", "rows"]),
      &source_refresh_budget_row?/1
    )
  end

  defp source_import_rows(repair) do
    Enum.filter(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &source_refresh_budget_row?/1
    )
  end

  defp source_review_index(repair) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &source_refresh_budget_row?/1
    )
  end

  defp source_import_index(repair) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &source_refresh_budget_row?/1
    )
  end

  defp source_refresh_budget_row?(row) do
    case row_source(row) do
      source when is_binary(source) -> String.starts_with?(source, @source)
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
