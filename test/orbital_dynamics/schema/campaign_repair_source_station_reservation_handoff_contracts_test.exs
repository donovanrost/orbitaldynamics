defmodule OrbitalDynamics.Schema.CampaignRepairSourceStationReservationHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CadenceImport
  alias OrbitalDynamics.OperatorReview
  alias OrbitalDynamics.OperatorReview.StationReservation
  alias OrbitalDynamics.Schema

  @source "campaign_repair.source_station_reservation_report.affected_contacts"

  setup_all do
    source_report =
      "study_results/station_calendar_report_v1.json"
      |> read_json!()
      |> OrbitalDynamics.station_reservation_report()

    repair =
      "study_results/leo_constellation_campaign_repair_v2.json"
      |> read_json!()
      |> Map.drop(["operator_review_package", "cadence_import_manifest"])
      |> Map.put("source_station_reservation_report", source_report)

    repair =
      Map.put(repair, "operator_review_package", OperatorReview.from_repair_artifact(repair))

    repair =
      Map.put(repair, "cadence_import_manifest", CadenceImport.from_repair_artifact(repair))

    expected_rows = StationReservation.rows(source_report["affected_contacts"], @source)

    %{repair: repair, expected_rows: expected_rows}
  end

  test "validates every source station-reservation contact in report order", %{
    repair: repair,
    expected_rows: expected_rows
  } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    assert [%{"source" => @source, "subject_id" => "cmd_1"} = review_row] =
             source_review_rows(repair)

    assert [import_row] = source_import_rows(repair)
    assert row_source(import_row) == @source
    assert import_row["subject_id"] == "cmd_1"

    assert review_row["source_station_reservation"] ==
             hd(expected_rows)["source_station_reservation"]

    assert get_in(import_row, ["source_review_row", "source_station_reservation"]) ==
             hd(expected_rows)["source_station_reservation"]
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
          if source_reservation_row?(row) do
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

  test "rejects source station-reservation identity drift at every produced path", %{
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

  test "rejects source station-reservation copy drift at every evidence path", %{
    repair: repair
  } do
    review_index = source_review_index(repair)
    import_index = source_import_index(repair)
    reason = "legacy station reservation rationale"

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source_station_reservation",
       put_in(
         repair,
         reservation_reason_path("operator_review_package", review_index, false),
         reason
       )},
      {"$.cadence_import_manifest.rows[#{import_index}].source_station_reservation",
       put_in(
         repair,
         reservation_reason_path("cadence_import_manifest", import_index, false),
         reason
       )},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_station_reservation",
       put_in(
         repair,
         reservation_reason_path("cadence_import_manifest", import_index, true),
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
        &put_reservation_reason_drift(&1, false)
      )
      |> update_in(
        ["cadence_import_manifest", "rows", Access.at(import_index)],
        &put_reservation_reason_drift(&1, true)
      )

    missing_review =
      update_in(repair, ["operator_review_package", "rows"], fn rows ->
        List.delete_at(rows, review_index)
      end)

    missing_import =
      update_in(repair, ["cadence_import_manifest", "rows"], fn rows ->
        List.delete_at(rows, import_index)
      end)

    stale_handoffs = Map.delete(repair, "source_station_reservation_report")

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source_station_reservation",
       coordinated_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_station_reservation",
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

  defp put_reservation_reason_drift(row, nested?) do
    reason = "legacy station reservation rationale"
    row = put_in(row, ["source_station_reservation", "operator_action_reason"], reason)

    if nested? do
      put_in(
        row,
        ["source_review_row", "source_station_reservation", "operator_action_reason"],
        reason
      )
    else
      row
    end
  end

  defp reservation_reason_path(package, index, nested?) do
    prefix = [package, "rows", Access.at(index)]

    evidence_path =
      if nested?,
        do: ["source_review_row", "source_station_reservation"],
        else: ["source_station_reservation"]

    prefix ++ evidence_path ++ ["operator_action_reason"]
  end

  defp drop_source_copy(row) do
    if source_reservation_row?(row),
      do: Map.delete(row, "source_station_reservation"),
      else: row
  end

  defp source_review_rows(repair) do
    Enum.filter(get_in(repair, ["operator_review_package", "rows"]), &source_reservation_row?/1)
  end

  defp source_import_rows(repair) do
    Enum.filter(get_in(repair, ["cadence_import_manifest", "rows"]), &source_reservation_row?/1)
  end

  defp source_review_index(repair) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &source_reservation_row?/1
    )
  end

  defp source_import_index(repair) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &source_reservation_row?/1
    )
  end

  defp source_reservation_row?(row) do
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
