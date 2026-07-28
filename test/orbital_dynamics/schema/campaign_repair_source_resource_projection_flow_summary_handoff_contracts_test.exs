defmodule OrbitalDynamics.Schema.CampaignRepairSourceResourceProjectionFlowSummaryHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CadenceImport
  alias OrbitalDynamics.OperatorReview
  alias OrbitalDynamics.OperatorReview.ResourceProjection
  alias OrbitalDynamics.Schema

  @field "source_resource_projection_flow_summary"
  @source "campaign_repair.source_resource_projection_flow_summary.projected_resources"

  setup_all do
    summary = read_json!("study_results/resource_projection_flow_summary_v1.json")

    repair =
      "study_results/leo_constellation_campaign_repair_v2.json"
      |> read_json!()
      |> Map.drop(["operator_review_package", "cadence_import_manifest"])
      |> Map.put(@field, summary)

    repair =
      Map.put(repair, "operator_review_package", OperatorReview.from_repair_artifact(repair))

    repair =
      Map.put(repair, "cadence_import_manifest", CadenceImport.from_repair_artifact(repair))

    %{repair: repair, expected: ResourceProjection.flow_summary_rows(summary, @source)}
  end

  test "replays normalized resource-flow projections", %{repair: repair, expected: expected} do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)
    review = source_rows(repair, "operator_review_package")
    imports = source_rows(repair, "cadence_import_manifest")
    ids = Enum.map(expected, & &1["subject_id"])
    projections = Enum.map(expected, & &1["source_resource_projection"])

    assert Enum.map(review, & &1["subject_id"]) == ids
    assert Enum.map(imports, & &1["subject_id"]) == ids
    assert Enum.map(review, & &1["source_resource_projection"]) == projections
    assert Enum.map(imports, & &1["source_resource_projection"]) == projections

    assert Enum.map(imports, &get_in(&1, ["source_review_row", "source_resource_projection"])) ==
             projections
  end

  test "keeps additive packages and projection copies optional", %{repair: repair} do
    assert {:ok, %{"schema_version" => 2}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    older =
      repair
      |> update_in(
        ["operator_review_package", "rows"],
        &Enum.map(&1, fn row -> drop_copy(row, false) end)
      )
      |> update_in(
        ["cadence_import_manifest", "rows"],
        &Enum.map(&1, fn row -> drop_copy(row, true) end)
      )

    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(older)
  end

  test "rejects flow-summary identity drift at every produced path", %{repair: repair} do
    ri = source_index(repair, "operator_review_package")
    ci = source_index(repair, "cadence_import_manifest")

    for {error_path, path} <- [
          {"$.operator_review_package.rows[#{ri}].source",
           ["operator_review_package", "rows", Access.at(ri), "source"]},
          {"$.cadence_import_manifest.rows[#{ci}].source",
           ["cadence_import_manifest", "rows", Access.at(ci), "source"]},
          {"$.cadence_import_manifest.rows[#{ci}].source_review_row.source",
           ["cadence_import_manifest", "rows", Access.at(ci), "source_review_row", "source"]}
        ] do
      assert_error(put_in(repair, path, @source <> ".legacy"), error_path)
    end
  end

  test "rejects normalized projection drift at every produced path", %{repair: repair} do
    ri = source_index(repair, "operator_review_package")
    ci = source_index(repair, "cadence_import_manifest")

    for {error_path, path} <- [
          {"$.operator_review_package.rows[#{ri}].source_resource_projection",
           [
             "operator_review_package",
             "rows",
             Access.at(ri),
             "source_resource_projection",
             "source_resource_projection_flow_summary",
             "model"
           ]},
          {"$.cadence_import_manifest.rows[#{ci}].source_resource_projection",
           [
             "cadence_import_manifest",
             "rows",
             Access.at(ci),
             "source_resource_projection",
             "source_resource_projection_flow_summary",
             "model"
           ]},
          {"$.cadence_import_manifest.rows[#{ci}].source_review_row.source_resource_projection",
           [
             "cadence_import_manifest",
             "rows",
             Access.at(ci),
             "source_review_row",
             "source_resource_projection",
             "source_resource_projection_flow_summary",
             "model"
           ]}
        ] do
      assert_error(put_in(repair, path, "legacy_resource_flow"), error_path)
    end
  end

  test "rejects coordinated drift, missing rows, and stale handoffs", %{repair: repair} do
    coordinated =
      repair
      |> update_in(
        ["operator_review_package", "rows"],
        &Enum.map(&1, fn row -> drift(row, false) end)
      )
      |> update_in(
        ["cadence_import_manifest", "rows"],
        &Enum.map(&1, fn row -> drift(row, true) end)
      )

    ri = source_index(repair, "operator_review_package")
    ci = source_index(repair, "cadence_import_manifest")

    missing_review =
      update_in(repair, ["operator_review_package", "rows"], &List.delete_at(&1, ri))

    missing_import =
      update_in(repair, ["cadence_import_manifest", "rows"], &List.delete_at(&1, ci))

    stale = Map.delete(repair, @field)

    for {path, invalid} <- [
          {"$.operator_review_package.rows[#{ri}].source_resource_projection", coordinated},
          {"$.cadence_import_manifest.rows[#{ci}].source_review_row.source_resource_projection",
           coordinated},
          {"$.operator_review_package.rows", missing_review},
          {"$.cadence_import_manifest.rows", missing_import},
          {"$.operator_review_package.rows", stale},
          {"$.cadence_import_manifest.rows", stale}
        ],
        do: assert_error(invalid, path)
  end

  defp drop_copy(row, nested?) do
    if source_row?(row) do
      row = Map.delete(row, "source_resource_projection")

      if nested?,
        do: update_in(row, ["source_review_row"], &Map.delete(&1, "source_resource_projection")),
        else: row
    else
      row
    end
  end

  defp drift(row, nested?) do
    if source_row?(row) do
      row =
        put_in(
          row,
          ["source_resource_projection", "source_resource_projection_flow_summary", "model"],
          "legacy_resource_flow"
        )

      if nested?,
        do:
          put_in(
            row,
            [
              "source_review_row",
              "source_resource_projection",
              "source_resource_projection_flow_summary",
              "model"
            ],
            "legacy_resource_flow"
          ),
        else: row
    else
      row
    end
  end

  defp source_rows(repair, package),
    do: Enum.filter(get_in(repair, [package, "rows"]), &source_row?/1)

  defp source_index(repair, package),
    do: Enum.find_index(get_in(repair, [package, "rows"]), &source_row?/1)

  defp source_row?(row),
    do: (row["source"] || get_in(row, ["source_review_row", "source"])) == @source

  defp assert_error(invalid, path) do
    assert {:error, report} = Schema.validate_artifact(invalid)
    assert Enum.any?(report["errors"], &(&1["path"] == path))
  end

  defp read_json!(path), do: path |> File.read!() |> :json.decode()
end
