Code.require_file("../campaign_planner/support.exs", __DIR__)

defmodule OrbitalDynamics.Schema.CampaignRepairSourceTimelineTransitionApplicationReportHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.TestSupport
  alias OrbitalDynamics.Schema

  @repair_source "campaign_repair.source_timeline_transition_application_report.applications"

  setup_all do
    source_report =
      read_json!("study_results/timeline_transition_application_report_v1.json")

    candidate_refresh =
      "study_results/candidate_refresh_v1.json"
      |> read_json!()
      |> put_in(
        ["candidate_refresh", "source_timeline_transition_application_report"],
        [source_report]
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

  test "validates Repair source timeline transition-application-report handoffs in producer order",
       %{repair: repair} do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    expected = [
      {@repair_source, "timeline:cmd_lock"},
      {@repair_source, "timeline:new_cmd"},
      {@repair_source, "timeline:old_contact"}
    ]

    assert expected ==
             repair
             |> get_in(["operator_review_package", "rows"])
             |> Enum.filter(&application_source?/1)
             |> Enum.map(&{row_source(&1), &1["timeline_id"]})

    assert expected ==
             repair
             |> get_in(["cadence_import_manifest", "rows"])
             |> Enum.filter(&application_source?/1)
             |> Enum.map(&{row_source(&1), &1["timeline_id"]})
  end

  test "keeps additive source timeline transition-application-report handoffs optional", %{
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
          if application_source?(row),
            do: Map.delete(row, "source_timeline_application"),
            else: row
        end)
      end)
      |> update_in(["cadence_import_manifest", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if application_source?(row) do
            row
            |> Map.delete("source_timeline_application")
            |> update_in(
              ["source_review_row"],
              &Map.delete(&1, "source_timeline_application")
            )
          else
            row
          end
        end)
      end)

    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(older)
  end

  test "rejects Repair source timeline transition-application-report handoff drift", %{
    repair: repair
  } do
    review_index = application_review_index(repair)
    import_index = application_import_index(repair)
    wrong_source = "campaign_repair.source_timeline_transition_application_report"

    review_source_drift =
      put_in(
        repair,
        ["operator_review_package", "rows", Access.at(review_index), "source"],
        wrong_source
      )

    cadence_source_drift =
      update_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(import_index)],
        fn row ->
          row
          |> Map.put("source", wrong_source)
          |> put_in(["source_review_row", "source"], wrong_source)
        end
      )

    review_copy_drift =
      put_in(
        repair,
        [
          "operator_review_package",
          "rows",
          Access.at(review_index),
          "source_timeline_application",
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
          |> put_in(["source_timeline_application", "rank"], 99)
          |> put_in(["source_review_row", "source_timeline_application", "rank"], 99)
        end
      )

    eligibility_drift =
      put_in(
        repair,
        [
          "source_timeline_transition_application_report",
          "applications",
          Access.at(2),
          "requires_operator_review"
        ],
        true
      )

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source", review_source_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source", cadence_source_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source",
       cadence_source_drift},
      {"$.operator_review_package.rows[#{review_index}].source_timeline_application",
       review_copy_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_timeline_application",
       cadence_copy_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_timeline_application",
       cadence_copy_drift},
      {"$.operator_review_package.rows", eligibility_drift},
      {"$.cadence_import_manifest.rows", eligibility_drift}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  defp application_review_index(repair) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &(Map.get(&1, "review_type") == "timeline_diff_review" and
          row_source(&1) == @repair_source)
    )
  end

  defp application_import_index(repair) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &(Map.get(&1, "source_review_type") == "timeline_diff_review" and
          row_source(&1) == @repair_source)
    )
  end

  defp application_source?(row), do: row_source(row) == @repair_source

  defp row_source(row) do
    Map.get(row, "source") || get_in(row, ["source_review_row", "source"])
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
