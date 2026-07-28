Code.require_file("../campaign_planner/support.exs", __DIR__)

defmodule OrbitalDynamics.Schema.CampaignRepairSourceTimelinePublicationSummaryHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.TestSupport
  alias OrbitalDynamics.Schema

  @repair_source_prefix "campaign_repair.source_timeline_publication_summaries"

  setup_all do
    source_summary = read_json!("study_results/timeline_publication_summary_v1.json")

    canonical_summary =
      source_summary
      |> :json.encode()
      |> IO.iodata_to_binary()
      |> String.replace("published_plan", "canonical_plan")
      |> :json.decode()

    candidate_refresh =
      "study_results/candidate_refresh_v1.json"
      |> read_json!()
      |> put_in(
        ["candidate_refresh", "source_timeline_publication_summary"],
        [source_summary]
      )
      |> put_in(
        ["candidate_refresh", "timeline_publication_summary"],
        canonical_summary
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

  test "validates Repair source timeline publication-summary handoffs in producer order", %{
    repair: repair
  } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    expected = [
      {"#{@repair_source_prefix}[0]",
       "timeline_publication:7:timeline:published_plan:v2:timeline:published_plan:v1"},
      {"#{@repair_source_prefix}[1]",
       "timeline_publication:7:timeline:canonical_plan:v2:timeline:canonical_plan:v1"}
    ]

    assert expected ==
             repair
             |> get_in(["operator_review_package", "rows"])
             |> Enum.filter(&publication_source?/1)
             |> Enum.map(&{row_source(&1), &1["publication_id"]})

    assert expected ==
             repair
             |> get_in(["cadence_import_manifest", "rows"])
             |> Enum.filter(&publication_source?/1)
             |> Enum.map(&{row_source(&1), &1["publication_id"]})
  end

  test "keeps additive source timeline publication-summary packages optional", %{
    repair: repair
  } do
    assert {:ok, %{"schema_version" => 2}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()
  end

  test "rejects Repair source timeline publication-summary handoff drift", %{
    repair: repair
  } do
    review_index = publication_review_index(repair)
    import_index = publication_import_index(repair)
    second_source = "#{@repair_source_prefix}[1]"

    review_count_drift =
      put_in(
        repair,
        ["operator_review_package", "rows", Access.at(review_index), "source"],
        "campaign_repair.source_timeline_publication_summary"
      )

    cadence_count_drift =
      update_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(import_index)],
        fn row ->
          row
          |> Map.put("source", "campaign_repair.source_timeline_publication_summary")
          |> put_in(
            ["source_review_row", "source"],
            "campaign_repair.source_timeline_publication_summary"
          )
        end
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

    review_copy_drift =
      put_in(
        repair,
        [
          "operator_review_package",
          "rows",
          Access.at(review_index),
          "source_timeline_publication_summary",
          "assumptions",
          "operator_authority"
        ],
        "modified_but_valid"
      )

    cadence_copy_drift =
      update_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(import_index)],
        fn row ->
          row
          |> put_in(
            ["source_timeline_publication_summary", "assumptions", "operator_authority"],
            "modified_but_valid"
          )
          |> put_in(
            [
              "source_review_row",
              "source_timeline_publication_summary",
              "assumptions",
              "operator_authority"
            ],
            "modified_but_valid"
          )
        end
      )

    stale_handoffs = Map.delete(repair, "source_timeline_publication_summaries")

    stale_indexed_handoffs =
      update_in(repair, ["source_timeline_publication_summaries"], &Enum.take(&1, 1))

    invalid_cases = [
      {"$.operator_review_package.rows", review_count_drift},
      {"$.cadence_import_manifest.rows", cadence_count_drift},
      {"$.operator_review_package.rows[#{review_index}].source", review_index_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source", cadence_index_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source",
       cadence_index_drift},
      {"$.operator_review_package.rows[#{review_index}].source_timeline_publication_summary",
       review_copy_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_timeline_publication_summary",
       cadence_copy_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_timeline_publication_summary",
       cadence_copy_drift},
      {"$.operator_review_package.rows", stale_handoffs},
      {"$.cadence_import_manifest.rows", stale_handoffs},
      {"$.operator_review_package.rows", stale_indexed_handoffs},
      {"$.cadence_import_manifest.rows", stale_indexed_handoffs}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  defp publication_review_index(repair) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &(Map.get(&1, "review_type") == "timeline_publication_review" and
          row_source(&1) == "#{@repair_source_prefix}[0]")
    )
  end

  defp publication_import_index(repair) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &(Map.get(&1, "source_review_type") == "timeline_publication_review" and
          row_source(&1) == "#{@repair_source_prefix}[0]")
    )
  end

  defp publication_source?(row) do
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
