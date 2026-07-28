defmodule OrbitalDynamics.Schema.CampaignRepairSourceRealizedStateSnapshotHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CadenceImport
  alias OrbitalDynamics.OperatorReview
  alias OrbitalDynamics.OperatorReview.RealizedStateSnapshot
  alias OrbitalDynamics.Schema

  @source "campaign_repair.source_realized_state_snapshot"
  @row_source @source <> ".activities"

  setup_all do
    snapshot = read_json!("study_results/realized_state_snapshot_v1.json")

    repair =
      "study_results/leo_constellation_campaign_repair_v2.json"
      |> read_json!()
      |> Map.drop(["operator_review_package", "cadence_import_manifest"])
      |> Map.put("source_realized_state_snapshot", snapshot)

    repair =
      Map.put(repair, "operator_review_package", OperatorReview.from_repair_artifact(repair))

    repair =
      Map.put(repair, "cadence_import_manifest", CadenceImport.from_repair_artifact(repair))

    expected_rows = RealizedStateSnapshot.source_rows(snapshot, @source)

    %{repair: repair, snapshot: snapshot, expected_rows: expected_rows}
  end

  test "replays realized-state reconciliation in snapshot activity order", %{
    repair: repair,
    snapshot: snapshot,
    expected_rows: expected_rows
  } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    review_rows = source_review_rows(repair)
    import_rows = source_import_rows(repair)

    assert Enum.map(review_rows, & &1["subject_id"]) ==
             Enum.map(expected_rows, & &1["subject_id"])

    assert Enum.map(import_rows, & &1["subject_id"]) ==
             Enum.map(expected_rows, & &1["subject_id"])

    assert Enum.map(review_rows, & &1["realized_activity"]) ==
             Enum.map(expected_rows, & &1["realized_activity"])

    assert Enum.map(import_rows, & &1["realized_activity"]) ==
             Enum.map(expected_rows, & &1["realized_activity"])

    assert Enum.all?(review_rows, &(&1["source_realized_state_snapshot"] == snapshot))

    assert Enum.all?(import_rows, fn row ->
             get_in(row, ["source_review_row", "source_realized_state_snapshot"]) == snapshot
           end)
  end

  test "keeps additive review packages and source snapshots optional", %{repair: repair} do
    assert {:ok, %{"schema_version" => 2}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    older =
      repair
      |> update_in(["operator_review_package", "rows"], fn rows ->
        Enum.map(rows, &drop_snapshot_copy/1)
      end)
      |> update_in(["cadence_import_manifest", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if source_snapshot_row?(row) do
            update_in(row, ["source_review_row"], &drop_snapshot_copy/1)
          else
            row
          end
        end)
      end)

    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(older)
  end

  test "rejects source realized-state identity drift at every produced path", %{
    repair: repair
  } do
    review_index = source_review_index(repair)
    import_index = source_import_index(repair)
    wrong_source = @row_source <> ".legacy"

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

  test "rejects realized-activity and snapshot drift at every evidence path", %{
    repair: repair
  } do
    review_index = source_review_index(repair)
    import_index = source_import_index(repair)

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].realized_activity",
       put_in(
         repair,
         activity_provider_path("operator_review_package", review_index, false),
         "legacy_provider"
       )},
      {"$.cadence_import_manifest.rows[#{import_index}].realized_activity",
       put_in(
         repair,
         activity_provider_path("cadence_import_manifest", import_index, false),
         "legacy_provider"
       )},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.realized_activity",
       put_in(
         repair,
         activity_provider_path("cadence_import_manifest", import_index, true),
         "legacy_provider"
       )},
      {"$.operator_review_package.rows[#{review_index}].source_realized_state_snapshot",
       put_in(
         repair,
         snapshot_provider_path("operator_review_package", review_index, false),
         "legacy_provider"
       )},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_realized_state_snapshot",
       put_in(
         repair,
         snapshot_provider_path("cadence_import_manifest", import_index, true),
         "legacy_provider"
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects coordinated snapshot drift, missing rows, and stale handoffs", %{
    repair: repair
  } do
    coordinated_drift =
      repair
      |> update_in(["operator_review_package", "rows"], fn rows ->
        Enum.map(rows, &put_snapshot_provider_drift(&1, false))
      end)
      |> update_in(["cadence_import_manifest", "rows"], fn rows ->
        Enum.map(rows, &put_snapshot_provider_drift(&1, true))
      end)

    review_index = source_review_index(repair)
    import_index = source_import_index(repair)

    missing_review =
      update_in(repair, ["operator_review_package", "rows"], fn rows ->
        List.delete_at(rows, review_index)
      end)

    missing_import =
      update_in(repair, ["cadence_import_manifest", "rows"], fn rows ->
        List.delete_at(rows, import_index)
      end)

    stale_handoffs = Map.delete(repair, "source_realized_state_snapshot")

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source_realized_state_snapshot",
       coordinated_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_realized_state_snapshot",
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

  defp put_snapshot_provider_drift(row, nested?) do
    if source_snapshot_row?(row) do
      if nested? do
        put_in(
          row,
          ["source_review_row", "source_realized_state_snapshot", "metadata", "provider"],
          "legacy_provider"
        )
      else
        put_in(
          row,
          ["source_realized_state_snapshot", "metadata", "provider"],
          "legacy_provider"
        )
      end
    else
      row
    end
  end

  defp activity_provider_path(package, index, nested?) do
    prefix = [package, "rows", Access.at(index)]

    evidence_path =
      if nested?, do: ["source_review_row", "realized_activity"], else: ["realized_activity"]

    prefix ++ evidence_path ++ ["provider"]
  end

  defp snapshot_provider_path(package, index, nested?) do
    prefix = [package, "rows", Access.at(index)]

    evidence_path =
      if nested?,
        do: ["source_review_row", "source_realized_state_snapshot"],
        else: ["source_realized_state_snapshot"]

    prefix ++ evidence_path ++ ["metadata", "provider"]
  end

  defp drop_snapshot_copy(row) do
    if source_snapshot_row?(row),
      do: Map.delete(row, "source_realized_state_snapshot"),
      else: row
  end

  defp source_review_rows(repair) do
    Enum.filter(get_in(repair, ["operator_review_package", "rows"]), &source_snapshot_row?/1)
  end

  defp source_import_rows(repair) do
    Enum.filter(get_in(repair, ["cadence_import_manifest", "rows"]), &source_snapshot_row?/1)
  end

  defp source_review_index(repair) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &source_snapshot_row?/1
    )
  end

  defp source_import_index(repair) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &source_snapshot_row?/1
    )
  end

  defp source_snapshot_row?(row) do
    case row_source(row) do
      source when is_binary(source) -> String.starts_with?(source, @row_source)
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
