Code.require_file("../campaign_planner/support.exs", __DIR__)

defmodule OrbitalDynamics.Schema.CampaignRepairSourceTimelineActivityStateHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.TestSupport
  alias OrbitalDynamics.Schema

  @repair_source_prefix "campaign_repair.source_timeline_activity_states"

  setup_all do
    source_state = read_json!("study_results/timeline_activity_state_v1.json")

    canonical_state =
      source_state
      |> :json.encode()
      |> IO.iodata_to_binary()
      |> String.replace("cmd_lock", "cmd_canonical_state")
      |> :json.decode()

    status_state = read_json!("study_results/timeline_activity_status_state_v1.json")

    approval_state =
      "study_results/timeline_activity_approval_state_v1.json"
      |> read_json!()
      |> :json.encode()
      |> IO.iodata_to_binary()
      |> String.replace("cmd_provider", "cmd_approval_source")
      |> :json.decode()

    candidate_refresh =
      "study_results/candidate_refresh_v1.json"
      |> read_json!()
      |> put_in(["candidate_refresh", "source_timeline_activity_state"], [source_state])
      |> put_in(["candidate_refresh", "timeline_activity_state"], canonical_state)
      |> put_in(
        ["candidate_refresh", "source_timeline_activity_status_state"],
        [status_state]
      )
      |> put_in(
        ["candidate_refresh", "source_timeline_activity_approval_state"],
        [approval_state]
      )

    repair =
      TestSupport.repair(
        %{"activities" => [], "candidate_activities" => []},
        realized_state: %{activities: []},
        current_epoch_s: 0.0,
        candidate_refresh: candidate_refresh
      )

    %{repair: repair}
  end

  test "validates heterogeneous Repair source timeline activity-state handoffs in producer order",
       %{repair: repair} do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    expected = [
      {"#{@repair_source_prefix}[0].state", "timeline:cmd_lock"},
      {"#{@repair_source_prefix}[1].state", "timeline:cmd_canonical_state"},
      {"#{@repair_source_prefix}[2].state", "timeline:obs_provider"},
      {"#{@repair_source_prefix}[3].state", "timeline:cmd_approval_source"}
    ]

    assert expected ==
             repair
             |> get_in(["operator_review_package", "rows"])
             |> Enum.filter(&activity_state_source?/1)
             |> Enum.map(&{row_source(&1), &1["timeline_id"]})

    assert expected ==
             repair
             |> get_in(["cadence_import_manifest", "rows"])
             |> Enum.filter(&activity_state_source?/1)
             |> Enum.map(&{row_source(&1), &1["timeline_id"]})
  end

  test "keeps additive heterogeneous source timeline activity-state handoffs optional", %{
    repair: repair
  } do
    assert {:ok, %{"schema_version" => 2}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    older =
      repair
      |> update_in(["operator_review_package", "rows"], fn rows ->
        Enum.map(rows, &drop_optional_copy/1)
      end)
      |> update_in(["cadence_import_manifest", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if activity_state_source?(row) do
            row
            |> drop_optional_copy()
            |> update_in(["source_review_row"], &drop_optional_copy/1)
          else
            row
          end
        end)
      end)

    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(older)
  end

  test "rejects heterogeneous Repair source timeline activity-state handoff drift", %{
    repair: repair
  } do
    review_index = activity_state_review_index(repair, 0)
    status_review_index = activity_state_review_index(repair, 2)
    import_index = activity_state_import_index(repair, 0)
    status_import_index = activity_state_import_index(repair, 2)
    second_source = "#{@repair_source_prefix}[1].state"

    review_count_drift =
      put_in(
        repair,
        ["operator_review_package", "rows", Access.at(review_index), "source"],
        "campaign_repair.source_timeline_activity_state"
      )

    cadence_count_drift =
      put_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(import_index), "source"],
        "campaign_repair.source_timeline_activity_state"
      )

    review_index_drift =
      put_in(
        repair,
        ["operator_review_package", "rows", Access.at(review_index), "source"],
        second_source
      )

    cadence_index_drift =
      update_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(import_index)],
        fn row ->
          row
          |> Map.put("source", second_source)
          |> put_in(["source_review_row", "source"], second_source)
        end
      )

    review_activity_copy_drift =
      put_in(
        repair,
        [
          "operator_review_package",
          "rows",
          Access.at(review_index),
          "source_timeline_activity_state",
          "rank"
        ],
        99
      )

    review_status_copy_drift =
      put_in(
        repair,
        [
          "operator_review_package",
          "rows",
          Access.at(status_review_index),
          "source_timeline_lifecycle_state",
          "rank"
        ],
        99
      )

    cadence_activity_copy_drift =
      update_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(import_index)],
        fn row ->
          row
          |> put_in(["source_timeline_activity_state", "rank"], 99)
          |> put_in(["source_review_row", "source_timeline_activity_state", "rank"], 99)
        end
      )

    cadence_status_copy_drift =
      update_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(status_import_index)],
        fn row ->
          row
          |> put_in(["source_timeline_lifecycle_state", "rank"], 99)
          |> put_in(["source_review_row", "source_timeline_lifecycle_state", "rank"], 99)
        end
      )

    invalid_cases = [
      {"$.operator_review_package.rows", review_count_drift},
      {"$.cadence_import_manifest.rows", cadence_count_drift},
      {"$.operator_review_package.rows[#{review_index}].source", review_index_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source", cadence_index_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source",
       cadence_index_drift},
      {"$.operator_review_package.rows[#{review_index}].source_timeline_activity_state",
       review_activity_copy_drift},
      {"$.operator_review_package.rows[#{status_review_index}].source_timeline_lifecycle_state",
       review_status_copy_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_timeline_activity_state",
       cadence_activity_copy_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_timeline_activity_state",
       cadence_activity_copy_drift},
      {"$.cadence_import_manifest.rows[#{status_import_index}].source_timeline_lifecycle_state",
       cadence_status_copy_drift},
      {"$.cadence_import_manifest.rows[#{status_import_index}].source_review_row.source_timeline_lifecycle_state",
       cadence_status_copy_drift}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  defp drop_optional_copy(row) do
    if activity_state_source?(row) do
      row
      |> Map.delete("source_timeline_activity_state")
      |> Map.delete("source_timeline_lifecycle_state")
    else
      row
    end
  end

  defp activity_state_review_index(repair, source_index) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &(Map.get(&1, "review_type") == "timeline_lifecycle_state_review" and
          row_source(&1) == "#{@repair_source_prefix}[#{source_index}].state")
    )
  end

  defp activity_state_import_index(repair, source_index) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &(Map.get(&1, "source_review_type") == "timeline_lifecycle_state_review" and
          row_source(&1) == "#{@repair_source_prefix}[#{source_index}].state")
    )
  end

  defp activity_state_source?(row) do
    String.starts_with?(row_source(row) || "", @repair_source_prefix <> "[")
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
