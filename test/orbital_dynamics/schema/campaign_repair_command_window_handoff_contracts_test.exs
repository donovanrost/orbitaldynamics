Code.require_file("../campaign_planner/support.exs", __DIR__)

defmodule OrbitalDynamics.Schema.CampaignRepairCommandWindowHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.TestSupport
  alias OrbitalDynamics.Schema

  @repair_command_window_source "command_window_report.rows"
  @repair_source_command_window_source "campaign_repair.source_command_window_report.rows"

  setup_all do
    command = %{
      "id" => "cmd_1",
      "type" => "command",
      "scenario_id" => "leo_1",
      "direction" => "uplink",
      "ground_station_id" => "equator_prime",
      "starts_at_s" => 100.0,
      "ends_at_s" => 130.0,
      "duration_s" => 30.0,
      "score" => 1.0
    }

    generated_repair =
      TestSupport.repair(
        %{"activities" => [command], "candidate_activities" => []},
        realized_state: %{activities: []},
        current_epoch_s: 0.0
      )

    source_command_window_report = read_json!("study_results/command_window_report_v1.json")

    candidate_refresh =
      "study_results/candidate_refresh_v1.json"
      |> read_json!()
      |> put_in(
        ["candidate_refresh", "source_command_window_report"],
        source_command_window_report
      )

    source_repair =
      TestSupport.repair(
        %{"activities" => [], "candidate_activities" => []},
        realized_state: %{activities: []},
        current_epoch_s: 0.0,
        candidate_refresh: candidate_refresh
      )

    %{repair: generated_repair, source_repair: source_repair}
  end

  test "validates generated Repair command-window review handoffs", %{repair: repair} do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)
  end

  test "keeps additive generated command-window handoffs optional", %{repair: repair} do
    assert {:ok, %{"schema_version" => 2}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    review_index = command_window_review_index(repair)
    import_index = command_window_import_index(repair)

    older =
      repair
      |> update_in(
        ["operator_review_package", "rows", Access.at(review_index)],
        &Map.delete(&1, "source_command_window")
      )
      |> update_in(
        ["cadence_import_manifest", "rows", Access.at(import_index)],
        fn row ->
          row
          |> Map.delete("source_command_window")
          |> update_in(["source_review_row"], &Map.delete(&1, "source_command_window"))
        end
      )

    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(older)
  end

  test "rejects generated Repair command-window review handoff drift", %{repair: repair} do
    review_index = command_window_review_index(repair)
    import_index = command_window_import_index(repair)

    review_count_drift =
      put_in(
        repair,
        ["operator_review_package", "rows", Access.at(review_index), "source"],
        "campaign_repair.command_window_report.rows"
      )

    cadence_count_drift =
      update_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(import_index)],
        fn row ->
          row
          |> Map.put("source", "campaign_repair.command_window_report.rows")
          |> put_in(
            ["source_review_row", "source"],
            "campaign_repair.command_window_report.rows"
          )
        end
      )

    review_copy_drift =
      put_in(
        repair,
        [
          "operator_review_package",
          "rows",
          Access.at(review_index),
          "source_command_window",
          "rank"
        ],
        99
      )

    cadence_copy_drift =
      update_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(import_index)],
        fn row ->
          row
          |> put_in(["source_command_window", "rank"], 99)
          |> put_in(["source_review_row", "source_command_window", "rank"], 99)
        end
      )

    invalid_cases = [
      {"$.operator_review_package.rows", review_count_drift},
      {"$.cadence_import_manifest.rows", cadence_count_drift},
      {"$.operator_review_package.rows[#{review_index}].source_command_window",
       review_copy_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_command_window",
       cadence_copy_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_command_window",
       cadence_copy_drift}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "validates source Repair command-window review handoffs", %{
    source_repair: repair
  } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    assert ["cmd_window", "uplink_contact"] ==
             repair
             |> get_in(["operator_review_package", "rows"])
             |> Enum.filter(&(row_source(&1) == @repair_source_command_window_source))
             |> Enum.map(& &1["activity_id"])

    assert ["cmd_window", "uplink_contact"] ==
             repair
             |> get_in(["cadence_import_manifest", "rows"])
             |> Enum.filter(&(row_source(&1) == @repair_source_command_window_source))
             |> Enum.map(& &1["activity_id"])
  end

  test "keeps additive source command-window handoffs optional", %{source_repair: repair} do
    assert {:ok, %{"schema_version" => 2}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    older =
      repair
      |> update_in(["operator_review_package", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if row_source(row) == @repair_source_command_window_source,
            do: Map.delete(row, "source_command_window"),
            else: row
        end)
      end)
      |> update_in(["cadence_import_manifest", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if row_source(row) == @repair_source_command_window_source do
            row
            |> Map.delete("source_command_window")
            |> update_in(["source_review_row"], &Map.delete(&1, "source_command_window"))
          else
            row
          end
        end)
      end)

    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(older)
  end

  test "rejects source Repair command-window review handoff drift", %{
    source_repair: repair
  } do
    review_index = command_window_review_index(repair, @repair_source_command_window_source)
    import_index = command_window_import_index(repair, @repair_source_command_window_source)

    review_count_drift =
      put_in(
        repair,
        ["operator_review_package", "rows", Access.at(review_index), "source"],
        "source_command_window_report.rows"
      )

    cadence_count_drift =
      put_in(
        repair,
        [
          "cadence_import_manifest",
          "rows",
          Access.at(import_index),
          "source_review_row",
          "source"
        ],
        "source_command_window_report.rows"
      )

    review_copy_drift =
      put_in(
        repair,
        [
          "operator_review_package",
          "rows",
          Access.at(review_index),
          "source_command_window",
          "rank"
        ],
        99
      )

    cadence_copy_drift =
      update_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(import_index)],
        fn row ->
          row
          |> put_in(["source_command_window", "rank"], 99)
          |> put_in(["source_review_row", "source_command_window", "rank"], 99)
        end
      )

    invalid_cases = [
      {"$.operator_review_package.rows", review_count_drift},
      {"$.cadence_import_manifest.rows", cadence_count_drift},
      {"$.operator_review_package.rows[#{review_index}].source_command_window",
       review_copy_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_command_window",
       cadence_copy_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_command_window",
       cadence_copy_drift}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  defp command_window_review_index(repair) do
    command_window_review_index(repair, @repair_command_window_source)
  end

  defp command_window_review_index(repair, source) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &(Map.get(&1, "review_type") == "command_window_review" and row_source(&1) == source)
    )
  end

  defp command_window_import_index(repair) do
    command_window_import_index(repair, @repair_command_window_source)
  end

  defp command_window_import_index(repair, source) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &(Map.get(&1, "source_review_type") == "command_window_review" and
          row_source(&1) == source)
    )
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
