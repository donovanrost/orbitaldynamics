defmodule OrbitalDynamics.Schema.CampaignRepairSourceOperationalQualityGateOperatorTrainingHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CadenceImport
  alias OrbitalDynamics.OperatorReview
  alias OrbitalDynamics.OperatorReview.QualityGate
  alias OrbitalDynamics.Schema

  @source "campaign_repair.source_operational_quality_gate_operator_training_summary"

  setup_all do
    summary =
      read_json!("study_results/operational_quality_gate_operator_training_summary_v1.json")

    repair =
      "study_results/leo_constellation_campaign_repair_v2.json"
      |> read_json!()
      |> Map.drop(["operator_review_package", "cadence_import_manifest"])
      |> Map.put("source_operational_quality_gate_operator_training_summary", summary)

    repair =
      Map.put(repair, "operator_review_package", OperatorReview.from_repair_artifact(repair))

    repair =
      Map.put(repair, "cadence_import_manifest", CadenceImport.from_repair_artifact(repair))

    expected_rows = QualityGate.source_report_rows(summary, @source)

    %{repair: repair, expected_rows: expected_rows}
  end

  test "replays the normalized operator-training quality-gate row", %{
    repair: repair,
    expected_rows: expected_rows
  } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    review_rows = source_review_rows(repair)
    import_rows = source_import_rows(repair)
    expected_ids = Enum.map(expected_rows, & &1["subject_id"])
    expected_source_rows = Enum.map(expected_rows, & &1["source_quality_gate_row"])
    expected_source_reports = Enum.map(expected_rows, & &1["source_quality_gate_report"])

    assert Enum.map(review_rows, & &1["subject_id"]) == expected_ids
    assert Enum.map(import_rows, & &1["subject_id"]) == expected_ids
    assert Enum.map(review_rows, & &1["source_quality_gate_row"]) == expected_source_rows
    assert Enum.map(import_rows, & &1["source_quality_gate_row"]) == expected_source_rows

    assert Enum.map(review_rows, & &1["source_quality_gate_report"]) ==
             expected_source_reports

    assert Enum.map(import_rows, & &1["source_quality_gate_report"]) ==
             expected_source_reports

    assert Enum.map(import_rows, &get_in(&1, ["source_review_row", "source_quality_gate_row"])) ==
             expected_source_rows

    assert Enum.map(
             import_rows,
             &get_in(&1, ["source_review_row", "source_quality_gate_report"])
           ) == expected_source_reports
  end

  test "keeps additive packages and normalized evidence copies optional", %{repair: repair} do
    assert {:ok, %{"schema_version" => 2}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    older =
      repair
      |> update_in(["operator_review_package", "rows"], fn rows ->
        Enum.map(rows, &drop_quality_gate_copies/1)
      end)
      |> update_in(["cadence_import_manifest", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if source_quality_gate_row?(row) do
            row
            |> drop_quality_gate_copies()
            |> update_in(["source_review_row"], &drop_quality_gate_copies/1)
          else
            row
          end
        end)
      end)

    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(older)
  end

  test "rejects operator-training source identity drift at every produced path", %{
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

  test "rejects normalized training row and report drift at every produced path", %{
    repair: repair
  } do
    review_index = source_review_index(repair)
    import_index = source_import_index(repair)

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source_quality_gate_row",
       put_training_requirement_count(repair, "operator_review_package", review_index, false)},
      {"$.cadence_import_manifest.rows[#{import_index}].source_quality_gate_row",
       put_training_requirement_count(repair, "cadence_import_manifest", import_index, false)},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_quality_gate_row",
       put_training_requirement_count(repair, "cadence_import_manifest", import_index, true)},
      {"$.operator_review_package.rows[#{review_index}].source_quality_gate_report",
       put_report_authority(repair, "operator_review_package", review_index, false)},
      {"$.cadence_import_manifest.rows[#{import_index}].source_quality_gate_report",
       put_report_authority(repair, "cadence_import_manifest", import_index, false)},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_quality_gate_report",
       put_report_authority(repair, "cadence_import_manifest", import_index, true)}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects coordinated report drift, missing rows, and stale handoffs", %{repair: repair} do
    coordinated_drift =
      repair
      |> update_in(["operator_review_package", "rows"], fn rows ->
        Enum.map(rows, &put_report_authority(&1, false))
      end)
      |> update_in(["cadence_import_manifest", "rows"], fn rows ->
        Enum.map(rows, &put_report_authority(&1, true))
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

    stale_handoffs =
      Map.delete(repair, "source_operational_quality_gate_operator_training_summary")

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source_quality_gate_report",
       coordinated_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_quality_gate_report",
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

  defp put_training_requirement_count(repair, package, index, nested?) do
    put_in(
      repair,
      [package, "rows", Access.at(index)] ++ training_requirement_count_path(nested?),
      99
    )
  end

  defp put_report_authority(repair, package, index, nested?) do
    put_in(
      repair,
      [package, "rows", Access.at(index)] ++ report_authority_path(nested?),
      "legacy_authority"
    )
  end

  defp put_report_authority(row, nested?) do
    if source_quality_gate_row?(row) do
      row
      |> put_in(report_authority_path(false), "legacy_authority")
      |> maybe_put_nested_report_authority(nested?)
    else
      row
    end
  end

  defp maybe_put_nested_report_authority(row, true),
    do: put_in(row, report_authority_path(true), "legacy_authority")

  defp maybe_put_nested_report_authority(row, false), do: row

  defp training_requirement_count_path(true),
    do: ["source_review_row", "source_quality_gate_row", "operator_training_requirement_count"]

  defp training_requirement_count_path(false),
    do: ["source_quality_gate_row", "operator_training_requirement_count"]

  defp report_authority_path(true),
    do: ["source_review_row", "source_quality_gate_report", "assumptions", "operator_authority"]

  defp report_authority_path(false),
    do: ["source_quality_gate_report", "assumptions", "operator_authority"]

  defp drop_quality_gate_copies(row) do
    if source_quality_gate_row?(row) do
      row
      |> Map.delete("source_quality_gate_row")
      |> Map.delete("source_quality_gate_report")
    else
      row
    end
  end

  defp source_review_rows(repair) do
    Enum.filter(get_in(repair, ["operator_review_package", "rows"]), &source_quality_gate_row?/1)
  end

  defp source_import_rows(repair) do
    Enum.filter(get_in(repair, ["cadence_import_manifest", "rows"]), &source_quality_gate_row?/1)
  end

  defp source_review_index(repair) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &source_quality_gate_row?/1
    )
  end

  defp source_import_index(repair) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &source_quality_gate_row?/1
    )
  end

  defp source_quality_gate_row?(row) do
    row_source(row) == @source
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
