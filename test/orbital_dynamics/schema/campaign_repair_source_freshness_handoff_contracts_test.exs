Code.require_file("../campaign_planner/support.exs", __DIR__)

defmodule OrbitalDynamics.Schema.CampaignRepairSourceFreshnessHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.TestSupport
  alias OrbitalDynamics.OperatorReview.RefreshState
  alias OrbitalDynamics.Schema

  @source "campaign_repair.source_freshness_report"

  setup_all do
    candidate_refresh =
      "study_results/candidate_refresh_v1.json"
      |> read_json!()
      |> Map.fetch!("candidate_refresh")

    source_report =
      candidate_refresh["freshness_report"]
      |> Map.merge(%{
        "status" => "stale",
        "accepted_snapshot_age_s" => 7_200.0,
        "max_snapshot_age_s" => 60.0,
        "stale_reasons" => ["accepted_snapshot_older_than_policy"],
        "unknown_reasons" => []
      })

    candidate_refresh = Map.put(candidate_refresh, "freshness_report", source_report)

    repair =
      TestSupport.repair(
        %{"activities" => [], "candidate_activities" => []},
        realized_state: %{activities: []},
        current_epoch_s: 0.0,
        candidate_refresh: candidate_refresh
      )

    expected_rows = RefreshState.freshness_rows(source_report, @source)

    %{repair: repair, expected_rows: expected_rows}
  end

  test "replays freshness review eligibility and evidence", %{
    repair: repair,
    expected_rows: expected_rows
  } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    assert [%{"source" => @source} = review_row] = source_review_rows(repair)
    assert [import_row] = source_import_rows(repair)
    assert [expected_row] = expected_rows

    assert review_row["subject_id"] == expected_row["subject_id"]
    assert review_row["freshness_status"] == "stale"
    assert review_row["accepted_snapshot_age_s"] == 7_200.0
    assert row_source(import_row) == @source
    assert import_row["accepted_snapshot_age_s"] == 7_200.0

    assert review_row["source_freshness_report"] ==
             expected_row["source_freshness_report"]

    assert get_in(import_row, ["source_review_row", "source_freshness_report"]) ==
             expected_row["source_freshness_report"]
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
          if source_freshness_row?(row) do
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

  test "rejects source freshness identity drift at every produced path", %{
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

  test "rejects source freshness copy drift at every evidence path", %{
    repair: repair
  } do
    review_index = source_review_index(repair)
    import_index = source_import_index(repair)

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source_freshness_report",
       put_in(
         repair,
         snapshot_age_path("operator_review_package", review_index, false),
         7_100.0
       )},
      {"$.cadence_import_manifest.rows[#{import_index}].source_freshness_report",
       put_in(
         repair,
         snapshot_age_path("cadence_import_manifest", import_index, false),
         7_100.0
       )},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_freshness_report",
       put_in(
         repair,
         snapshot_age_path("cadence_import_manifest", import_index, true),
         7_100.0
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects coordinated snapshot-age drift, missing rows, and stale handoffs", %{
    repair: repair
  } do
    review_index = source_review_index(repair)
    import_index = source_import_index(repair)

    coordinated_drift =
      repair
      |> update_in(
        ["operator_review_package", "rows", Access.at(review_index)],
        &put_snapshot_age_drift(&1, false)
      )
      |> update_in(
        ["cadence_import_manifest", "rows", Access.at(import_index)],
        &put_snapshot_age_drift(&1, true)
      )

    missing_review =
      update_in(repair, ["operator_review_package", "rows"], fn rows ->
        List.delete_at(rows, review_index)
      end)

    missing_import =
      update_in(repair, ["cadence_import_manifest", "rows"], fn rows ->
        List.delete_at(rows, import_index)
      end)

    stale_handoffs = Map.delete(repair, "source_freshness_report")

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source_freshness_report",
       coordinated_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_freshness_report",
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

  defp put_snapshot_age_drift(row, nested?) do
    row =
      row
      |> Map.put("accepted_snapshot_age_s", 7_100.0)
      |> put_in(["source_freshness_report", "accepted_snapshot_age_s"], 7_100.0)

    if nested? do
      row
      |> put_in(["source_review_row", "accepted_snapshot_age_s"], 7_100.0)
      |> put_in(
        ["source_review_row", "source_freshness_report", "accepted_snapshot_age_s"],
        7_100.0
      )
    else
      row
    end
  end

  defp snapshot_age_path(package, index, nested?) do
    prefix = [package, "rows", Access.at(index)]

    evidence_path =
      if nested?,
        do: ["source_review_row", "source_freshness_report"],
        else: ["source_freshness_report"]

    prefix ++ evidence_path ++ ["accepted_snapshot_age_s"]
  end

  defp drop_source_copy(row) do
    if source_freshness_row?(row),
      do: Map.delete(row, "source_freshness_report"),
      else: row
  end

  defp source_review_rows(repair) do
    Enum.filter(get_in(repair, ["operator_review_package", "rows"]), &source_freshness_row?/1)
  end

  defp source_import_rows(repair) do
    Enum.filter(get_in(repair, ["cadence_import_manifest", "rows"]), &source_freshness_row?/1)
  end

  defp source_review_index(repair) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &source_freshness_row?/1
    )
  end

  defp source_import_index(repair) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &source_freshness_row?/1
    )
  end

  defp source_freshness_row?(row) do
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
