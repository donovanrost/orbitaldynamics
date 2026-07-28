defmodule OrbitalDynamics.Schema.CampaignRepairSourceOperationalTimelineHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CadenceImport
  alias OrbitalDynamics.OperatorReview
  alias OrbitalDynamics.OperatorReview.OperationalTimeline
  alias OrbitalDynamics.Schema

  @source "campaign_repair.source_operational_timeline_report"
  @row_source @source <> ".rows"

  setup_all do
    report = read_json!("study_results/operational_timeline_report_v1.json")

    repair =
      "study_results/leo_constellation_campaign_repair_v2.json"
      |> read_json!()
      |> Map.drop(["operator_review_package", "cadence_import_manifest"])
      |> Map.put("source_operational_timeline_report", report)

    repair =
      Map.put(repair, "operator_review_package", OperatorReview.from_repair_artifact(repair))

    repair =
      Map.put(repair, "cadence_import_manifest", CadenceImport.from_repair_artifact(repair))

    expected_rows = OperationalTimeline.source_report_rows(report, @source)

    %{repair: repair, expected_rows: expected_rows}
  end

  test "replays reviewable operational-timeline rows in report order", %{
    repair: repair,
    expected_rows: expected_rows
  } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    review_rows = source_review_rows(repair)
    import_rows = source_import_rows(repair)
    expected_evidence = Enum.map(expected_rows, & &1["source_operational_timeline"])

    assert Enum.map(review_rows, & &1["subject_id"]) ==
             Enum.map(expected_rows, & &1["subject_id"])

    assert Enum.map(import_rows, & &1["subject_id"]) ==
             Enum.map(expected_rows, & &1["subject_id"])

    assert Enum.map(review_rows, & &1["source_operational_timeline"]) == expected_evidence
    assert Enum.map(import_rows, & &1["source_operational_timeline"]) == expected_evidence

    assert Enum.map(
             import_rows,
             &get_in(&1, ["source_review_row", "source_operational_timeline"])
           ) == expected_evidence
  end

  test "keeps additive packages and operational-timeline evidence copies optional", %{
    repair: repair
  } do
    assert {:ok, %{"schema_version" => 2}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    older =
      repair
      |> update_in(["operator_review_package", "rows"], fn rows ->
        Enum.map(rows, &drop_timeline_copy/1)
      end)
      |> update_in(["cadence_import_manifest", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if source_timeline_row?(row) do
            row
            |> Map.delete("source_operational_timeline")
            |> update_in(["source_review_row"], &drop_timeline_copy/1)
          else
            row
          end
        end)
      end)

    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(older)
  end

  test "rejects source operational-timeline identity drift at every produced path", %{
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
      {"$.cadence_import_manifest.rows[#{import_index}].source",
       put_in(
         repair,
         ["cadence_import_manifest", "rows", Access.at(import_index), "source"],
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

  test "rejects operational-timeline evidence drift at every produced path", %{
    repair: repair
  } do
    review_index = source_review_index(repair)
    import_index = source_import_index(repair)

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source_operational_timeline",
       put_timeline_duration(repair, "operator_review_package", review_index, false)},
      {"$.cadence_import_manifest.rows[#{import_index}].source_operational_timeline",
       put_timeline_duration(repair, "cadence_import_manifest", import_index, false)},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_operational_timeline",
       put_timeline_duration(repair, "cadence_import_manifest", import_index, true)}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects coordinated evidence drift, missing rows, and stale handoffs", %{
    repair: repair
  } do
    coordinated_drift =
      repair
      |> update_in(["operator_review_package", "rows"], fn rows ->
        Enum.map(rows, &put_timeline_duration(&1, false))
      end)
      |> update_in(["cadence_import_manifest", "rows"], fn rows ->
        Enum.map(rows, &put_timeline_duration(&1, true))
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

    stale_handoffs = Map.delete(repair, "source_operational_timeline_report")

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source_operational_timeline",
       coordinated_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_operational_timeline",
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

  defp put_timeline_duration(repair, package, index, nested?) do
    put_in(
      repair,
      [package, "rows", Access.at(index)] ++ timeline_duration_path(nested?),
      11.0
    )
  end

  defp put_timeline_duration(row, nested?) do
    if source_timeline_row?(row) do
      row
      |> put_in(timeline_duration_path(false), 11.0)
      |> maybe_put_nested_timeline_duration(nested?)
    else
      row
    end
  end

  defp maybe_put_nested_timeline_duration(row, true),
    do: put_in(row, timeline_duration_path(true), 11.0)

  defp maybe_put_nested_timeline_duration(row, false), do: row

  defp timeline_duration_path(true),
    do: ["source_review_row", "source_operational_timeline", "activity_context", "duration_s"]

  defp timeline_duration_path(false),
    do: ["source_operational_timeline", "activity_context", "duration_s"]

  defp drop_timeline_copy(row) do
    if source_timeline_row?(row),
      do: Map.delete(row, "source_operational_timeline"),
      else: row
  end

  defp source_review_rows(repair) do
    Enum.filter(get_in(repair, ["operator_review_package", "rows"]), &source_timeline_row?/1)
  end

  defp source_import_rows(repair) do
    Enum.filter(get_in(repair, ["cadence_import_manifest", "rows"]), &source_timeline_row?/1)
  end

  defp source_review_index(repair) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &source_timeline_row?/1
    )
  end

  defp source_import_index(repair) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &source_timeline_row?/1
    )
  end

  defp source_timeline_row?(row) do
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
