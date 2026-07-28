Code.require_file("../campaign_planner/support.exs", __DIR__)

defmodule OrbitalDynamics.Schema.CampaignRepairSourceTimelineTransitionApplicationSummaryHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.TestSupport
  alias OrbitalDynamics.Schema

  @repair_source "campaign_repair.source_timeline_transition_application_summary.review_applications"

  setup_all do
    source_summary =
      read_json!("study_results/timeline_transition_application_summary_v1.json")

    candidate_refresh =
      "study_results/candidate_refresh_v1.json"
      |> read_json!()
      |> put_in(
        ["candidate_refresh", "source_timeline_transition_application_summary"],
        [source_summary]
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

  test "validates Repair source transition-application-summary handoffs in producer order", %{
    repair: repair
  } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    expected = [
      {@repair_source, "timeline:cmd_lock"},
      {@repair_source, "timeline:new_cmd"}
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

  test "keeps additive source transition-application-summary handoffs optional", %{
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
          if application_source?(row) do
            row
            |> Map.delete("source_timeline_application")
            |> Map.delete("source_timeline_transition_application_summary")
          else
            row
          end
        end)
      end)
      |> update_in(["cadence_import_manifest", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if application_source?(row) do
            row
            |> Map.delete("source_timeline_application")
            |> Map.delete("source_timeline_transition_application_summary")
            |> update_in(["source_review_row"], fn source_review_row ->
              Map.drop(source_review_row, [
                "source_timeline_application",
                "source_timeline_transition_application_summary"
              ])
            end)
          else
            row
          end
        end)
      end)

    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(older)
  end

  test "rejects Repair source transition-application-summary handoff drift", %{
    repair: repair
  } do
    review_index = application_review_index(repair)
    import_index = application_import_index(repair)
    wrong_source = "campaign_repair.source_timeline_transition_application_summary"

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

    review_application_drift =
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

    cadence_application_drift =
      update_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(import_index)],
        fn row ->
          row
          |> put_in(["source_timeline_application", "rank"], 99)
          |> put_in(["source_review_row", "source_timeline_application", "rank"], 99)
        end
      )

    review_summary_drift =
      put_in(
        repair,
        [
          "operator_review_package",
          "rows",
          Access.at(review_index),
          "source_timeline_transition_application_summary",
          "assumptions",
          "operator_authority"
        ],
        "modified_but_valid"
      )

    cadence_summary_drift =
      update_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(import_index)],
        fn row ->
          row
          |> put_in(
            [
              "source_timeline_transition_application_summary",
              "assumptions",
              "operator_authority"
            ],
            "modified_but_valid"
          )
          |> put_in(
            [
              "source_review_row",
              "source_timeline_transition_application_summary",
              "assumptions",
              "operator_authority"
            ],
            "modified_but_valid"
          )
        end
      )

    eligibility_drift =
      put_in(
        repair,
        [
          "source_timeline_transition_application_summary",
          "review_applications",
          Access.at(0),
          "requires_operator_review"
        ],
        false
      )

    stale_handoffs = Map.delete(repair, "source_timeline_transition_application_summary")

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source", review_source_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source", cadence_source_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source",
       cadence_source_drift},
      {"$.operator_review_package.rows[#{review_index}].source_timeline_application",
       review_application_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_timeline_application",
       cadence_application_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_timeline_application",
       cadence_application_drift},
      {"$.operator_review_package.rows[#{review_index}].source_timeline_transition_application_summary",
       review_summary_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_timeline_transition_application_summary",
       cadence_summary_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_timeline_transition_application_summary",
       cadence_summary_drift},
      {"$.operator_review_package.rows", eligibility_drift},
      {"$.cadence_import_manifest.rows", eligibility_drift},
      {"$.operator_review_package.rows", stale_handoffs},
      {"$.cadence_import_manifest.rows", stale_handoffs}
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
