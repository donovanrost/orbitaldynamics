defmodule OrbitalDynamics.Schema.CampaignRepairSourceOperationalQualityGateImportReadinessHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CadenceImport
  alias OrbitalDynamics.OperatorReview
  alias OrbitalDynamics.OperatorReview.QualityGate
  alias OrbitalDynamics.Schema

  @field "source_operational_quality_gate_import_readiness_summary"
  @source "campaign_repair.source_operational_quality_gate_import_readiness_summary"

  setup_all do
    summary =
      read_json!("study_results/operational_quality_gate_import_readiness_summary_v1.json")

    repair =
      "study_results/leo_constellation_campaign_repair_v2.json"
      |> read_json!()
      |> Map.drop(["operator_review_package", "cadence_import_manifest"])
      |> Map.put(@field, summary)

    repair =
      Map.put(repair, "operator_review_package", OperatorReview.from_repair_artifact(repair))

    repair =
      Map.put(repair, "cadence_import_manifest", CadenceImport.from_repair_artifact(repair))

    %{repair: repair, expected_rows: QualityGate.source_report_rows(summary, @source)}
  end

  test "replays the normalized import-readiness quality-gate row", context do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(context.repair)

    review_rows = source_rows(context.repair, "operator_review_package")
    import_rows = source_rows(context.repair, "cadence_import_manifest")
    expected_ids = Enum.map(context.expected_rows, & &1["subject_id"])
    expected_rows = Enum.map(context.expected_rows, & &1["source_quality_gate_row"])
    expected_reports = Enum.map(context.expected_rows, & &1["source_quality_gate_report"])

    assert Enum.map(review_rows, & &1["subject_id"]) == expected_ids
    assert Enum.map(import_rows, & &1["subject_id"]) == expected_ids
    assert Enum.map(review_rows, & &1["source_quality_gate_row"]) == expected_rows
    assert Enum.map(import_rows, & &1["source_quality_gate_row"]) == expected_rows
    assert Enum.map(review_rows, & &1["source_quality_gate_report"]) == expected_reports
    assert Enum.map(import_rows, & &1["source_quality_gate_report"]) == expected_reports

    assert Enum.map(import_rows, &get_in(&1, ["source_review_row", "source_quality_gate_row"])) ==
             expected_rows

    assert Enum.map(
             import_rows,
             &get_in(&1, ["source_review_row", "source_quality_gate_report"])
           ) == expected_reports
  end

  test "keeps additive packages and normalized evidence copies optional", %{repair: repair} do
    assert {:ok, %{"schema_version" => 2}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    older =
      repair
      |> update_in(
        ["operator_review_package", "rows"],
        &Enum.map(&1, fn row -> drop_copies(row, false) end)
      )
      |> update_in(
        ["cadence_import_manifest", "rows"],
        &Enum.map(&1, fn row -> drop_copies(row, true) end)
      )

    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(older)
  end

  test "rejects import-readiness source identity drift at every produced path", %{repair: repair} do
    review_index = source_index(repair, "operator_review_package")
    import_index = source_index(repair, "cadence_import_manifest")

    cases = [
      {"$.operator_review_package.rows[#{review_index}].source",
       ["operator_review_package", "rows", Access.at(review_index), "source"]},
      {"$.cadence_import_manifest.rows[#{import_index}].source",
       ["cadence_import_manifest", "rows", Access.at(import_index), "source"]},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source",
       ["cadence_import_manifest", "rows", Access.at(import_index), "source_review_row", "source"]}
    ]

    for {expected_path, path} <- cases do
      invalid = put_in(repair, path, @source <> ".legacy")
      assert_error_path(invalid, expected_path)
    end
  end

  test "rejects normalized import row and report drift at every produced path", %{repair: repair} do
    review_index = source_index(repair, "operator_review_package")
    import_index = source_index(repair, "cadence_import_manifest")

    cases = [
      {"$.operator_review_package.rows[#{review_index}].source_quality_gate_row",
       [
         "operator_review_package",
         "rows",
         Access.at(review_index),
         "source_quality_gate_row",
         "ready_for_import_count"
       ], 99},
      {"$.cadence_import_manifest.rows[#{import_index}].source_quality_gate_row",
       [
         "cadence_import_manifest",
         "rows",
         Access.at(import_index),
         "source_quality_gate_row",
         "ready_for_import_count"
       ], 99},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_quality_gate_row",
       [
         "cadence_import_manifest",
         "rows",
         Access.at(import_index),
         "source_review_row",
         "source_quality_gate_row",
         "ready_for_import_count"
       ], 99},
      {"$.operator_review_package.rows[#{review_index}].source_quality_gate_report",
       report_authority_path("operator_review_package", review_index, false), "legacy_authority"},
      {"$.cadence_import_manifest.rows[#{import_index}].source_quality_gate_report",
       report_authority_path("cadence_import_manifest", import_index, false), "legacy_authority"},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_quality_gate_report",
       report_authority_path("cadence_import_manifest", import_index, true), "legacy_authority"}
    ]

    for {expected_path, path, value} <- cases do
      assert_error_path(put_in(repair, path, value), expected_path)
    end
  end

  test "rejects coordinated report drift, missing rows, and stale handoffs", %{repair: repair} do
    coordinated =
      repair
      |> update_in(
        ["operator_review_package", "rows"],
        &Enum.map(&1, fn row -> drift_report(row, false) end)
      )
      |> update_in(
        ["cadence_import_manifest", "rows"],
        &Enum.map(&1, fn row -> drift_report(row, true) end)
      )

    review_index = source_index(repair, "operator_review_package")
    import_index = source_index(repair, "cadence_import_manifest")

    missing_review =
      update_in(repair, ["operator_review_package", "rows"], &List.delete_at(&1, review_index))

    missing_import =
      update_in(repair, ["cadence_import_manifest", "rows"], &List.delete_at(&1, import_index))

    stale = Map.delete(repair, @field)

    for {path, invalid} <- [
          {"$.operator_review_package.rows[#{review_index}].source_quality_gate_report",
           coordinated},
          {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_quality_gate_report",
           coordinated},
          {"$.operator_review_package.rows", missing_review},
          {"$.cadence_import_manifest.rows", missing_import},
          {"$.operator_review_package.rows", stale},
          {"$.cadence_import_manifest.rows", stale}
        ] do
      assert_error_path(invalid, path)
    end
  end

  defp drop_copies(row, nested?) do
    if source_row?(row) do
      row =
        row |> Map.delete("source_quality_gate_row") |> Map.delete("source_quality_gate_report")

      if nested?,
        do:
          update_in(
            row,
            ["source_review_row"],
            &(&1
              |> Map.delete("source_quality_gate_row")
              |> Map.delete("source_quality_gate_report"))
          ),
        else: row
    else
      row
    end
  end

  defp drift_report(row, nested?) do
    if source_row?(row) do
      row =
        put_in(
          row,
          ["source_quality_gate_report", "assumptions", "operator_authority"],
          "legacy_authority"
        )

      if nested?,
        do:
          put_in(
            row,
            [
              "source_review_row",
              "source_quality_gate_report",
              "assumptions",
              "operator_authority"
            ],
            "legacy_authority"
          ),
        else: row
    else
      row
    end
  end

  defp report_authority_path(package, index, nested?) do
    [package, "rows", Access.at(index)] ++
      if(nested?, do: ["source_review_row"], else: []) ++
      ["source_quality_gate_report", "assumptions", "operator_authority"]
  end

  defp source_rows(repair, package),
    do: Enum.filter(get_in(repair, [package, "rows"]), &source_row?/1)

  defp source_index(repair, package),
    do: Enum.find_index(get_in(repair, [package, "rows"]), &source_row?/1)

  defp source_row?(row),
    do: (Map.get(row, "source") || get_in(row, ["source_review_row", "source"])) == @source

  defp assert_error_path(invalid, path) do
    assert {:error, report} = Schema.validate_artifact(invalid)
    assert Enum.any?(report["errors"], &(&1["path"] == path))
  end

  defp read_json!(path), do: path |> File.read!() |> :json.decode()
end
