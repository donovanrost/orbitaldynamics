Code.require_file("../campaign_planner/support.exs", __DIR__)

defmodule OrbitalDynamics.Schema.CampaignRepairSourceRelayDataPathSummaryHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.TestSupport
  alias OrbitalDynamics.Schema

  @repair_source "campaign_repair.source_relay_data_path_summary.rows"
  @summary_context_fields [
    "model",
    "schema_contract",
    "source_artifact_type",
    "source",
    "route_count",
    "relay_route_count",
    "direct_downlink_route_count",
    "route_ids",
    "route_ids_by_ground_station_id",
    "route_ids_by_latency_status",
    "route_ids_by_risk_status",
    "route_ids_by_custody_status",
    "source_spacecraft_ids",
    "relay_spacecraft_ids",
    "ground_downlink_contact_ids",
    "custody_status_counts",
    "latency_status_counts",
    "risk_status_counts",
    "station_count",
    "contact_count",
    "selected_contact_count",
    "selected_downlink_shortfall_mb",
    "actual_downlink_shortfall_mb",
    "capacity_adjusted_throughput_mb",
    "selected_capacity_adjusted_throughput_mb",
    "unused_capacity_adjusted_throughput_mb",
    "selected_contact_ids",
    "actual_throughput_contact_ids",
    "assumptions"
  ]

  setup_all do
    source_summary = read_json!("study_results/relay_data_path_summary_v1.json")

    candidate_refresh =
      "study_results/candidate_refresh_v1.json"
      |> read_json!()
      |> put_in(
        ["candidate_refresh", "source_relay_data_path_summary"],
        [source_summary]
      )

    repair =
      TestSupport.repair(
        %{"activities" => [], "candidate_activities" => []},
        realized_state: %{activities: []},
        current_epoch_s: 0.0,
        candidate_refresh: candidate_refresh
      )

    %{repair: repair, source_summary: source_summary}
  end

  test "validates Repair source relay-data-path-summary handoffs in producer order", %{
    repair: repair,
    source_summary: source_summary
  } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    expected_source_rows = source_summary_rows(source_summary)
    review_rows = source_review_rows(repair)
    import_rows = source_import_rows(repair)

    assert ["relay_data_path:sat_a:downlink_1:54b7e7ff594c", "route_direct"] ==
             Enum.map(review_rows, &get_in(&1, ["source_link_capacity", "route_id"]))

    assert ["dss_14", "dss_35"] == Enum.map(review_rows, & &1["ground_station_id"])
    assert ["dss_14", "dss_35"] == Enum.map(import_rows, & &1["ground_station_id"])

    assert Enum.all?(review_rows, &(row_source(&1) == @repair_source))
    assert Enum.all?(import_rows, &(row_source(&1) == @repair_source))

    assert Enum.map(review_rows, & &1["source_link_capacity"]) == expected_source_rows
    assert Enum.map(import_rows, & &1["source_link_capacity"]) == expected_source_rows

    assert Enum.map(import_rows, &get_in(&1, ["source_review_row", "source_link_capacity"])) ==
             expected_source_rows
  end

  test "keeps additive source relay-data-path-summary handoffs optional", %{repair: repair} do
    assert {:ok, %{"schema_version" => 2}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    older =
      repair
      |> update_in(["operator_review_package", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if source_summary_row?(row),
            do: Map.delete(row, "source_link_capacity"),
            else: row
        end)
      end)
      |> update_in(["cadence_import_manifest", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if source_summary_row?(row) do
            row
            |> Map.delete("source_link_capacity")
            |> update_in(["source_review_row"], &Map.delete(&1, "source_link_capacity"))
          else
            row
          end
        end)
      end)

    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(older)
  end

  test "rejects Repair source relay-data-path-summary handoff drift", %{repair: repair} do
    review_index = source_review_index(repair)
    import_index = source_import_index(repair)
    wrong_source = @repair_source <> ".legacy"

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
          "source_link_capacity",
          "source_link_capacity_summary",
          "route_count"
        ],
        99
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
          "source_link_capacity",
          "source_link_capacity_summary",
          "route_count"
        ],
        99
      )

    import_nested_copy_drift =
      put_in(
        repair,
        [
          "cadence_import_manifest",
          "rows",
          Access.at(import_index),
          "source_review_row",
          "source_link_capacity",
          "source_link_capacity_summary",
          "route_count"
        ],
        99
      )

    eligibility_drift =
      Map.put(
        repair,
        "source_relay_data_path_summary",
        OrbitalDynamics.relay_data_path_summary([], source: "relay_ops")
      )

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source", review_source_drift},
      {"$.operator_review_package.rows[#{review_index}].source_link_capacity", review_copy_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source", import_source_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source",
       import_nested_source_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_link_capacity",
       import_outer_copy_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_link_capacity",
       import_nested_copy_drift},
      {"$.operator_review_package.rows", eligibility_drift},
      {"$.cadence_import_manifest.rows", eligibility_drift}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  defp source_summary_rows(summary) do
    context =
      summary
      |> Map.take(@summary_context_fields)
      |> compact_map()

    Enum.map(summary["rows"], fn row ->
      row
      |> Map.put("source_link_capacity_summary", context)
      |> Map.put("source_summary_model", summary["model"])
      |> Map.put("source_summary_schema_contract", summary["schema_contract"])
      |> Map.put("source_artifact_type", summary["source_artifact_type"])
      |> Map.put("schema_contract", summary["schema_contract"])
      |> compact_map()
    end)
  end

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_field, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp source_review_rows(repair) do
    Enum.filter(get_in(repair, ["operator_review_package", "rows"]), &source_summary_row?/1)
  end

  defp source_import_rows(repair) do
    Enum.filter(get_in(repair, ["cadence_import_manifest", "rows"]), &source_summary_row?/1)
  end

  defp source_review_index(repair) do
    Enum.find_index(get_in(repair, ["operator_review_package", "rows"]), &source_summary_row?/1)
  end

  defp source_import_index(repair) do
    Enum.find_index(get_in(repair, ["cadence_import_manifest", "rows"]), &source_summary_row?/1)
  end

  defp source_summary_row?(row) do
    row_source(row) == @repair_source and
      (row["review_type"] == "link_capacity_review" or
         row["source_review_type"] == "link_capacity_review")
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
