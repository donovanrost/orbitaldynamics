defmodule OrbitalDynamics.Schema.CampaignRepairSourceStationCalendarHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CadenceImport
  alias OrbitalDynamics.OperatorReview
  alias OrbitalDynamics.OperatorReview.StationCalendar
  alias OrbitalDynamics.Schema

  @source "campaign_repair.source_station_calendar_report.affected_contacts"

  setup_all do
    source_report = read_json!("study_results/station_calendar_report_v1.json")

    repair =
      "study_results/leo_constellation_campaign_repair_v2.json"
      |> read_json!()
      |> Map.drop(["operator_review_package", "cadence_import_manifest"])
      |> Map.put("source_station_calendar_report", source_report)

    repair =
      Map.put(repair, "operator_review_package", OperatorReview.from_repair_artifact(repair))

    repair =
      Map.put(repair, "cadence_import_manifest", CadenceImport.from_repair_artifact(repair))

    expected_rows = StationCalendar.rows(source_report["affected_contacts"], @source)

    %{repair: repair, expected_rows: expected_rows}
  end

  test "validates every source station-calendar contact in report order", %{
    repair: repair,
    expected_rows: expected_rows
  } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    review_rows = source_review_rows(repair)
    import_rows = source_import_rows(repair)
    expected_subject_ids = ["dl_1", "cmd_1"]

    assert Enum.map(review_rows, &{&1["source"], &1["subject_id"]}) ==
             Enum.map(expected_subject_ids, &{@source, &1})

    assert Enum.map(import_rows, &{row_source(&1), &1["subject_id"]}) ==
             Enum.map(expected_subject_ids, &{@source, &1})

    assert Enum.map(review_rows, & &1["source_station_calendar_review"]) ==
             Enum.map(expected_rows, & &1["source_station_calendar_review"])

    assert Enum.map(
             import_rows,
             &get_in(&1, ["source_review_row", "source_station_calendar_review"])
           ) ==
             Enum.map(expected_rows, & &1["source_station_calendar_review"])
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
          if source_calendar_row?(row) do
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

  test "rejects source station-calendar identity drift at every produced path", %{
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

  test "rejects source station-calendar copy drift at every evidence path", %{repair: repair} do
    review_index = source_review_index(repair)
    import_index = source_import_index(repair)
    reason = "legacy station calendar rationale"

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source_station_calendar_review",
       put_in(
         repair,
         [
           "operator_review_package",
           "rows",
           Access.at(review_index),
           "source_station_calendar_review",
           "operator_action_reason"
         ],
         reason
       )},
      {"$.cadence_import_manifest.rows[#{import_index}].source_station_calendar_review",
       put_in(
         repair,
         [
           "cadence_import_manifest",
           "rows",
           Access.at(import_index),
           "source_station_calendar_review",
           "operator_action_reason"
         ],
         reason
       )},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_station_calendar_review",
       put_in(
         repair,
         [
           "cadence_import_manifest",
           "rows",
           Access.at(import_index),
           "source_review_row",
           "source_station_calendar_review",
           "operator_action_reason"
         ],
         reason
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
        &put_operator_reason_drift(&1, false)
      )
      |> update_in(
        ["cadence_import_manifest", "rows", Access.at(import_index)],
        &put_operator_reason_drift(&1, true)
      )

    missing_review =
      update_in(repair, ["operator_review_package", "rows"], fn rows ->
        List.delete_at(rows, review_index)
      end)

    missing_import =
      update_in(repair, ["cadence_import_manifest", "rows"], fn rows ->
        List.delete_at(rows, import_index)
      end)

    stale_handoffs = Map.delete(repair, "source_station_calendar_report")

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source_station_calendar_review",
       coordinated_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_station_calendar_review",
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

  defp put_operator_reason_drift(row, nested?) do
    reason = "legacy station calendar rationale"

    row =
      row
      |> Map.put("reason", reason)
      |> Map.put("operator_action_reason", reason)
      |> put_in(["source_station_calendar_review", "operator_action_reason"], reason)

    if nested? do
      row
      |> put_in(["source_review_row", "reason"], reason)
      |> put_in(["source_review_row", "operator_action_reason"], reason)
      |> put_in(
        ["source_review_row", "source_station_calendar_review", "operator_action_reason"],
        reason
      )
    else
      row
    end
  end

  defp drop_source_copy(row) do
    if source_calendar_row?(row),
      do: Map.delete(row, "source_station_calendar_review"),
      else: row
  end

  defp source_review_rows(repair) do
    Enum.filter(get_in(repair, ["operator_review_package", "rows"]), &source_calendar_row?/1)
  end

  defp source_import_rows(repair) do
    Enum.filter(get_in(repair, ["cadence_import_manifest", "rows"]), &source_calendar_row?/1)
  end

  defp source_review_index(repair) do
    Enum.find_index(get_in(repair, ["operator_review_package", "rows"]), &source_calendar_row?/1)
  end

  defp source_import_index(repair) do
    Enum.find_index(get_in(repair, ["cadence_import_manifest", "rows"]), &source_calendar_row?/1)
  end

  defp source_calendar_row?(row) do
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
