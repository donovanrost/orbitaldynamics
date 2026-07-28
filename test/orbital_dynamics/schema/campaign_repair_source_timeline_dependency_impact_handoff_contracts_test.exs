defmodule OrbitalDynamics.Schema.CampaignRepairSourceTimelineDependencyImpactHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CadenceImport
  alias OrbitalDynamics.OperatorReview
  alias OrbitalDynamics.OperatorReview.TimelinePublication
  alias OrbitalDynamics.Schema

  @source "campaign_repair.source_timeline_dependency_impact_summary"
  @row_source @source <> ".dependency_impact_rows"

  setup_all do
    summary = read_json!("study_results/timeline_dependency_impact_summary_v1.json")

    repair =
      "study_results/leo_constellation_campaign_repair_v2.json"
      |> read_json!()
      |> Map.drop(["operator_review_package", "cadence_import_manifest"])
      |> Map.put("source_timeline_dependency_impact_summary", summary)

    repair =
      Map.put(repair, "operator_review_package", OperatorReview.from_repair_artifact(repair))

    repair =
      Map.put(repair, "cadence_import_manifest", CadenceImport.from_repair_artifact(repair))

    expected_rows = TimelinePublication.source_dependency_impact_rows(summary, @source)

    %{repair: repair, expected_rows: expected_rows}
  end

  test "replays review-required dependency-impact rows in summary order", %{
    repair: repair,
    expected_rows: expected_rows
  } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    review_rows = source_review_rows(repair)
    import_rows = source_import_rows(repair)

    expected_impacts = Enum.map(expected_rows, & &1["source_timeline_dependency_impact"])

    assert Enum.map(review_rows, & &1["subject_id"]) ==
             Enum.map(expected_rows, & &1["subject_id"])

    assert Enum.map(import_rows, & &1["subject_id"]) ==
             Enum.map(expected_rows, & &1["subject_id"])

    assert Enum.map(review_rows, & &1["source_timeline_dependency_impact"]) ==
             expected_impacts

    assert Enum.map(import_rows, & &1["source_timeline_dependency_impact"]) ==
             expected_impacts

    assert Enum.map(
             import_rows,
             &get_in(&1, ["source_review_row", "source_timeline_dependency_impact"])
           ) ==
             expected_impacts
  end

  test "keeps additive packages and dependency-impact evidence copies optional", %{
    repair: repair
  } do
    assert {:ok, %{"schema_version" => 2}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    older =
      repair
      |> update_in(["operator_review_package", "rows"], fn rows ->
        Enum.map(rows, &drop_impact_copy/1)
      end)
      |> update_in(["cadence_import_manifest", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if source_impact_row?(row) do
            row
            |> Map.delete("source_timeline_dependency_impact")
            |> update_in(["source_review_row"], &drop_impact_copy/1)
          else
            row
          end
        end)
      end)

    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(older)
  end

  test "rejects source dependency-impact identity drift at every produced path", %{
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

  test "rejects dependency-impact drift at every evidence path", %{repair: repair} do
    review_index = source_review_index(repair)
    import_index = source_import_index(repair)

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source_timeline_dependency_impact",
       put_impact_approval(repair, "operator_review_package", review_index, false)},
      {"$.cadence_import_manifest.rows[#{import_index}].source_timeline_dependency_impact",
       put_impact_approval(repair, "cadence_import_manifest", import_index, false)},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_timeline_dependency_impact",
       put_impact_approval(repair, "cadence_import_manifest", import_index, true)}
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
        Enum.map(rows, &put_impact_approval(&1, false))
      end)
      |> update_in(["cadence_import_manifest", "rows"], fn rows ->
        Enum.map(rows, &put_impact_approval(&1, true))
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

    stale_handoffs = Map.delete(repair, "source_timeline_dependency_impact_summary")

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source_timeline_dependency_impact",
       coordinated_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_timeline_dependency_impact",
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

  defp put_impact_approval(repair, package, index, nested?) do
    put_in(
      repair,
      [package, "rows", Access.at(index)] ++ impact_approval_path(nested?),
      "approved"
    )
  end

  defp put_impact_approval(row, nested?) do
    if source_impact_row?(row) do
      row
      |> put_in(impact_approval_path(false), "approved")
      |> maybe_put_nested_impact_approval(nested?)
    else
      row
    end
  end

  defp maybe_put_nested_impact_approval(row, true),
    do: put_in(row, impact_approval_path(true), "approved")

  defp maybe_put_nested_impact_approval(row, false), do: row

  defp impact_approval_path(true),
    do: ["source_review_row", "source_timeline_dependency_impact", "approval_status"]

  defp impact_approval_path(false),
    do: ["source_timeline_dependency_impact", "approval_status"]

  defp drop_impact_copy(row) do
    if source_impact_row?(row),
      do: Map.delete(row, "source_timeline_dependency_impact"),
      else: row
  end

  defp source_review_rows(repair) do
    Enum.filter(get_in(repair, ["operator_review_package", "rows"]), &source_impact_row?/1)
  end

  defp source_import_rows(repair) do
    Enum.filter(get_in(repair, ["cadence_import_manifest", "rows"]), &source_impact_row?/1)
  end

  defp source_review_index(repair) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &source_impact_row?/1
    )
  end

  defp source_import_index(repair) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &source_impact_row?/1
    )
  end

  defp source_impact_row?(row) do
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
