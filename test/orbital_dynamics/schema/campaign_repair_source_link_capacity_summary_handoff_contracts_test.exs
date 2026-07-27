Code.require_file("../campaign_planner/support.exs", __DIR__)

defmodule OrbitalDynamics.Schema.CampaignRepairSourceLinkCapacitySummaryHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.TestSupport
  alias OrbitalDynamics.Schema

  @repair_source "campaign_repair.source_link_capacity_summary.rows"
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
    source_summary = source_summary()

    candidate_refresh =
      "study_results/candidate_refresh_v1.json"
      |> read_json!()
      |> put_in(
        ["candidate_refresh", "source_link_capacity_summary"],
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

  test "validates Repair source link-capacity-summary handoffs in producer order", %{
    repair: repair,
    source_summary: source_summary
  } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    expected_source_rows = source_summary_rows(source_summary)
    review_rows = source_review_rows(repair)
    import_rows = source_import_rows(repair)

    assert ["dss_14", "dss_24"] == Enum.map(review_rows, & &1["ground_station_id"])
    assert ["dss_14", "dss_24"] == Enum.map(import_rows, & &1["ground_station_id"])

    assert Enum.all?(review_rows, &(row_source(&1) == @repair_source))
    assert Enum.all?(import_rows, &(row_source(&1) == @repair_source))

    assert Enum.map(review_rows, & &1["source_link_capacity"]) == expected_source_rows
    assert Enum.map(import_rows, & &1["source_link_capacity"]) == expected_source_rows

    assert Enum.map(import_rows, &get_in(&1, ["source_review_row", "source_link_capacity"])) ==
             expected_source_rows
  end

  test "keeps additive source link-capacity-summary handoffs optional", %{repair: repair} do
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

  test "rejects Repair source link-capacity-summary handoff drift", %{repair: repair} do
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
          "station_count"
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
          "station_count"
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
          "station_count"
        ],
        99
      )

    eligibility_drift = Map.put(repair, "source_link_capacity_summary", empty_summary())

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

  defp source_summary do
    OrbitalDynamics.link_capacity_summary(
      [
        %{
          id: :contact_1,
          type: :downlink,
          scenario_id: :leo_1,
          ground_station_id: :dss_14,
          planned_data_volume_mb: 100.0
        },
        %{
          id: :contact_2,
          type: :downlink,
          scenario_id: :leo_1,
          ground_station_id: :dss_24,
          planned_data_volume_mb: 80.0
        }
      ],
      [
        %{
          id: :contact_1,
          type: :downlink,
          ground_station_id: :dss_14,
          actual_data_volume_mb: 90.0
        },
        %{
          id: :contact_2,
          type: :downlink,
          ground_station_id: :dss_24,
          actual_data_volume_mb: 70.0
        }
      ],
      source: "timeline_feedback"
    )
  end

  defp empty_summary do
    OrbitalDynamics.link_capacity_summary([], [], source: "timeline_feedback")
    |> Map.put("contact_ids", [])
    |> Map.put("selected_contact_ids", [])
  end

  defp source_summary_rows(summary) do
    context = summary_context(summary)

    Enum.map(summary["ground_station_ids"], fn station_id ->
      summary
      |> station_summary_row(station_id)
      |> Map.put("source_link_capacity_summary", context)
      |> Map.put("source_summary_model", summary["model"])
      |> Map.put("source_summary_schema_contract", summary["schema_contract"])
      |> Map.put("source_artifact_type", summary["source_artifact_type"])
      |> Map.put("schema_contract", summary["schema_contract"])
      |> compact_map()
    end)
  end

  defp station_summary_row(summary, station_id) do
    selected_contact_ids = station_ids(summary, station_id, "selected_contact_ids")
    actual_contact_ids = station_ids(summary, station_id, "actual_throughput_contact_ids")
    required_contact_ids = station_ids(summary, station_id, "required_downlink_contact_ids")
    contact_ids = Enum.uniq(selected_contact_ids ++ actual_contact_ids ++ required_contact_ids)

    %{
      "ground_station_id" => station_id,
      "contact_count" => length(contact_ids),
      "contact_ids" => contact_ids,
      "selected_contact_count" => length(selected_contact_ids),
      "selected_contact_ids" => selected_contact_ids,
      "actual_throughput_contact_count" => length(actual_contact_ids),
      "actual_throughput_contact_ids" => actual_contact_ids,
      "required_downlink_contact_count" => length(required_contact_ids),
      "required_downlink_contact_ids" => required_contact_ids,
      "selected_downlink_shortfall_mb" =>
        station_number(summary, station_id, "selected_downlink_shortfall_mb"),
      "actual_downlink_shortfall_mb" =>
        station_number(summary, station_id, "actual_downlink_shortfall_mb"),
      "capacity_adjusted_throughput_mb" =>
        station_number(summary, station_id, "capacity_adjusted_throughput_mb"),
      "selected_capacity_adjusted_throughput_mb" =>
        station_number(summary, station_id, "selected_capacity_adjusted_throughput_mb"),
      "unused_capacity_adjusted_throughput_mb" =>
        station_number(summary, station_id, "unused_capacity_adjusted_throughput_mb"),
      "downlink_requirement_status" =>
        shortfall_status(summary, station_id, "shortfall_ground_station_ids"),
      "actual_downlink_requirement_status" =>
        shortfall_status(summary, station_id, "actual_shortfall_ground_station_ids"),
      "station_calendar_entry_ids" =>
        station_ids(summary, station_id, "station_calendar_entry_ids"),
      "station_calendar_provider_entry_ids" =>
        station_ids(summary, station_id, "station_calendar_provider_entry_ids"),
      "station_reservation_ids" => station_ids(summary, station_id, "station_reservation_ids")
    }
    |> compact_map()
  end

  defp station_ids(summary, station_id, field) do
    summary
    |> Map.get("#{field}_by_ground_station_id", %{})
    |> Map.get(station_id, [])
  end

  defp station_number(summary, station_id, field) do
    summary
    |> Map.get("#{field}_by_ground_station_id", %{})
    |> Map.get(station_id)
  end

  defp shortfall_status(summary, station_id, field) do
    if station_id in Map.get(summary, field, []), do: "shortfall"
  end

  defp summary_context(summary) do
    summary
    |> Map.take(@summary_context_fields)
    |> compact_map()
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
