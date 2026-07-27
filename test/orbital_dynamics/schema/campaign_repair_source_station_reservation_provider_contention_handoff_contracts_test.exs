defmodule OrbitalDynamics.Schema.CampaignRepairSourceStationReservationProviderContentionHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CadenceImport
  alias OrbitalDynamics.OperatorReview
  alias OrbitalDynamics.OperatorReview.StationReservation
  alias OrbitalDynamics.Schema

  @source "campaign_repair.source_station_reservation_report.provider_calendar_contention_groups"

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

    expected_rows =
      StationReservation.provider_contention_rows(
        source_report["provider_calendar_contention_groups"],
        @source
      )

    %{repair: repair, expected_rows: expected_rows}
  end

  test "validates every source provider-contention group in report order", %{
    repair: repair,
    expected_rows: expected_rows
  } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    assert [%{"source" => @source} = review_row] = source_review_rows(repair)
    assert [import_row] = source_import_rows(repair)

    assert review_row["subject_id"] == hd(expected_rows)["subject_id"]
    assert row_source(import_row) == @source
    assert import_row["subject_id"] == hd(expected_rows)["subject_id"]

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
          if source_contention_row?(row) do
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

  test "rejects source provider-contention identity drift at every produced path", %{
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

  test "rejects source provider-contention copy drift at every evidence path", %{
    repair: repair
  } do
    review_index = source_review_index(repair)
    import_index = source_import_index(repair)
    reason = "legacy provider contention rationale"

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source_station_reservation",
       put_in(
         repair,
         contention_reason_path("operator_review_package", review_index, false),
         reason
       )},
      {"$.cadence_import_manifest.rows[#{import_index}].source_station_reservation",
       put_in(
         repair,
         contention_reason_path("cadence_import_manifest", import_index, false),
         reason
       )},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_station_reservation",
       put_in(
         repair,
         contention_reason_path("cadence_import_manifest", import_index, true),
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
        &put_contention_reason_drift(&1, false)
      )
      |> update_in(
        ["cadence_import_manifest", "rows", Access.at(import_index)],
        &put_contention_reason_drift(&1, true)
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

  defp put_contention_reason_drift(row, nested?) do
    reason = "legacy provider contention rationale"

    row =
      row
      |> Map.put("reason", reason)
      |> Map.put("operator_action_reason", reason)
      |> put_in(["source_station_calendar_provider_contention", "operator_action_reason"], reason)
      |> put_in(["source_station_reservation", "operator_action_reason"], reason)

    if nested? do
      row
      |> put_in(["source_review_row", "reason"], reason)
      |> put_in(["source_review_row", "operator_action_reason"], reason)
      |> put_in(
        [
          "source_review_row",
          "source_station_calendar_provider_contention",
          "operator_action_reason"
        ],
        reason
      )
      |> put_in(
        ["source_review_row", "source_station_reservation", "operator_action_reason"],
        reason
      )
    else
      row
    end
  end

  defp contention_reason_path(package, index, nested?) do
    prefix = [package, "rows", Access.at(index)]

    evidence_path =
      if nested?,
        do: ["source_review_row", "source_station_reservation"],
        else: ["source_station_reservation"]

    prefix ++ evidence_path ++ ["operator_action_reason"]
  end

  defp drop_source_copy(row) do
    if source_contention_row?(row),
      do: Map.delete(row, "source_station_reservation"),
      else: row
  end

  defp source_review_rows(repair) do
    Enum.filter(get_in(repair, ["operator_review_package", "rows"]), &source_contention_row?/1)
  end

  defp source_import_rows(repair) do
    Enum.filter(get_in(repair, ["cadence_import_manifest", "rows"]), &source_contention_row?/1)
  end

  defp source_review_index(repair) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &source_contention_row?/1
    )
  end

  defp source_import_index(repair) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &source_contention_row?/1
    )
  end

  defp source_contention_row?(row) do
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
