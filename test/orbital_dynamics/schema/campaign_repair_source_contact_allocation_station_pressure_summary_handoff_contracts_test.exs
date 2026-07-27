Code.require_file("../campaign_planner/support.exs", __DIR__)

defmodule OrbitalDynamics.Schema.CampaignRepairSourceContactAllocationStationPressureSummaryHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CadenceImport
  alias OrbitalDynamics.CampaignPlanner.TestSupport
  alias OrbitalDynamics.OperatorReview
  alias OrbitalDynamics.Schema

  @plural_prefix "campaign_repair.source_contact_allocation_station_pressure_summaries[0]"
  @plural_source @plural_prefix <> ".review_rows"
  @singular_source "campaign_repair.source_contact_allocation_station_pressure_summary.review_rows"

  setup_all do
    source_summary =
      read_json!("study_results/contact_allocation_station_pressure_summary_v1.json")

    candidate_refresh =
      "study_results/candidate_refresh_v1.json"
      |> read_json!()
      |> put_in(
        ["candidate_refresh", "source_contact_allocation_station_pressure_summary"],
        [source_summary]
      )

    repair =
      TestSupport.repair(
        %{"activities" => [], "candidate_activities" => []},
        realized_state: %{activities: []},
        current_epoch_s: 0.0,
        candidate_refresh: candidate_refresh
      )

    singular_repair =
      repair
      |> Map.delete("source_contact_allocation_station_pressure_summaries")
      |> Map.drop(["operator_review_package", "cadence_import_manifest"])
      |> rebuild_review_handoffs()

    %{
      repair: repair,
      singular_repair: singular_repair,
      source_summary: source_summary
    }
  end

  test "validates ordered Repair source station-pressure-summary review handoffs", %{
    repair: repair,
    source_summary: source_summary
  } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    review_rows = source_review_rows(repair, @plural_source)
    import_rows = source_import_rows(repair, @plural_source)
    source_contact_ids = Enum.map(source_summary["review_rows"], & &1["contact_id"])

    assert source_contact_ids == ["dl_3"]
    assert length(source_summary["rows"]) == 3
    assert Enum.map(review_rows, & &1["contact_id"]) == source_contact_ids
    assert Enum.map(import_rows, & &1["contact_id"]) == source_contact_ids
    assert Enum.all?(review_rows, &(row_source(&1) == @plural_source))
    assert Enum.all?(import_rows, &(row_source(&1) == @plural_source))

    assert Enum.map(review_rows, &summary_schema_contract/1) ==
             ["contact_allocation_station_pressure_summary.v1"]

    assert Enum.map(import_rows, &summary_schema_contract/1) ==
             ["contact_allocation_station_pressure_summary.v1"]

    assert Enum.map(import_rows, &nested_summary_schema_contract/1) ==
             ["contact_allocation_station_pressure_summary.v1"]
  end

  test "validates the singular station-pressure-summary compatibility fallback", %{
    singular_repair: repair,
    source_summary: source_summary
  } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    review_rows = source_review_rows(repair, @singular_source)
    import_rows = source_import_rows(repair, @singular_source)
    source_contact_ids = Enum.map(source_summary["review_rows"], & &1["contact_id"])

    assert Enum.map(review_rows, & &1["contact_id"]) == source_contact_ids
    assert Enum.map(import_rows, & &1["contact_id"]) == source_contact_ids
    assert Enum.all?(review_rows, &(row_source(&1) == @singular_source))
    assert Enum.all?(import_rows, &(row_source(&1) == @singular_source))
  end

  test "keeps additive source station-pressure-summary handoffs optional", %{
    repair: repair
  } do
    assert {:ok, %{"schema_version" => 2}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    older =
      repair
      |> update_in(["operator_review_package", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if summary_row?(row),
            do: Map.delete(row, "source_contact_allocation"),
            else: row
        end)
      end)
      |> update_in(["cadence_import_manifest", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if summary_row?(row) do
            row
            |> Map.delete("source_contact_allocation")
            |> update_in(["source_review_row"], &Map.delete(&1, "source_contact_allocation"))
          else
            row
          end
        end)
      end)

    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(older)
  end

  test "rejects Repair source station-pressure-summary handoff drift", %{
    repair: repair
  } do
    review_index = source_review_index(repair, @plural_source)
    import_index = source_import_index(repair, @plural_source)
    wrong_source = @plural_source <> ".legacy"

    review_source_drift =
      put_in(
        repair,
        ["operator_review_package", "rows", Access.at(review_index), "source"],
        wrong_source
      )

    review_copy_drift =
      put_in(
        repair,
        [
          "operator_review_package",
          "rows",
          Access.at(review_index),
          "source_contact_allocation",
          "review_status"
        ],
        "drifted"
      )

    import_source_drift =
      put_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(import_index), "source"],
        wrong_source
      )

    import_nested_source_drift =
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
      )

    import_outer_copy_drift =
      put_in(
        repair,
        [
          "cadence_import_manifest",
          "rows",
          Access.at(import_index),
          "source_contact_allocation",
          "review_status"
        ],
        "drifted"
      )

    import_nested_copy_drift =
      put_in(
        repair,
        [
          "cadence_import_manifest",
          "rows",
          Access.at(import_index),
          "source_review_row",
          "source_contact_allocation",
          "review_status"
        ],
        "drifted"
      )

    empty_summary =
      []
      |> OrbitalDynamics.contact_allocation_report([])
      |> OrbitalDynamics.contact_allocation_station_pressure_summary()

    eligibility_drift =
      repair
      |> Map.put("source_contact_allocation_station_pressure_summary", empty_summary)
      |> Map.put("source_contact_allocation_station_pressure_summaries", [empty_summary])

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source", review_source_drift},
      {"$.operator_review_package.rows[#{review_index}].source_contact_allocation",
       review_copy_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source", import_source_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source",
       import_nested_source_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_contact_allocation",
       import_outer_copy_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_contact_allocation",
       import_nested_copy_drift},
      {"$.operator_review_package.rows", eligibility_drift},
      {"$.cadence_import_manifest.rows", eligibility_drift}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  defp rebuild_review_handoffs(repair) do
    review_package = OperatorReview.from_repair_artifact(repair)
    repair = Map.put(repair, "operator_review_package", review_package)
    Map.put(repair, "cadence_import_manifest", CadenceImport.from_repair_artifact(repair))
  end

  defp source_review_rows(repair, source) do
    Enum.filter(
      get_in(repair, ["operator_review_package", "rows"]),
      &(row_source(&1) == source)
    )
  end

  defp source_import_rows(repair, source) do
    Enum.filter(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &(row_source(&1) == source)
    )
  end

  defp source_review_index(repair, source) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &(row_source(&1) == source)
    )
  end

  defp source_import_index(repair, source) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &(row_source(&1) == source)
    )
  end

  defp summary_schema_contract(row) do
    get_in(row, [
      "source_contact_allocation",
      "source_contact_allocation_summary",
      "schema_contract"
    ])
  end

  defp nested_summary_schema_contract(row) do
    get_in(row, [
      "source_review_row",
      "source_contact_allocation",
      "source_contact_allocation_summary",
      "schema_contract"
    ])
  end

  defp summary_row?(row) do
    case row_source(row) do
      source when is_binary(source) -> String.starts_with?(source, @plural_prefix)
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
