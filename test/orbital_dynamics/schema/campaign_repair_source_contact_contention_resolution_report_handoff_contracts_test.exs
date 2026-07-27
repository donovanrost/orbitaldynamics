Code.require_file("../campaign_planner/support.exs", __DIR__)

defmodule OrbitalDynamics.Schema.CampaignRepairSourceContactContentionResolutionReportHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.TestSupport
  alias OrbitalDynamics.Schema

  @source "campaign_repair.source_contact_contention_resolution_report.recommendations"

  setup_all do
    source_report =
      read_json!("study_results/contact_contention_resolution_report_v1.json")

    candidate_refresh =
      "study_results/candidate_refresh_v1.json"
      |> read_json!()
      |> put_in(
        ["candidate_refresh", "source_contact_contention_resolution_report"],
        source_report
      )

    repair =
      TestSupport.repair(
        %{"activities" => [], "candidate_activities" => []},
        realized_state: %{activities: []},
        current_epoch_s: 0.0,
        candidate_refresh: candidate_refresh
      )

    %{repair: repair, source_report: source_report}
  end

  test "validates source resolution-report handoffs in recommendation order", %{
    repair: repair,
    source_report: source_report
  } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    reviews = source_review_rows(repair)
    imports = source_import_rows(repair)
    recommendations = source_report["recommendations"]

    assert Enum.map(reviews, & &1["subject_id"]) == [
             "station:equator_prime:contention:1",
             "spacecraft:sat_1:contention:1"
           ]

    assert Enum.map(imports, & &1["subject_id"]) == [
             "station:equator_prime:contention:1",
             "spacecraft:sat_1:contention:1"
           ]

    assert Enum.map(reviews, & &1["selected_contact_id"]) == ["dl_1", "dl_3"]
    assert Enum.map(imports, & &1["selected_contact_id"]) == ["dl_1", "dl_3"]
    assert Enum.all?(reviews, &(row_source(&1) == @source))
    assert Enum.all?(imports, &(row_source(&1) == @source))

    assert Enum.map(reviews, & &1["source_recommendation"]) == recommendations
    assert Enum.map(imports, & &1["source_recommendation"]) == recommendations

    assert Enum.map(imports, &get_in(&1, ["source_review_row", "source_recommendation"])) ==
             recommendations
  end

  test "keeps additive source resolution-report handoffs and copies optional", %{
    repair: repair
  } do
    assert {:ok, %{"schema_version" => 2}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    older =
      repair
      |> update_in(["operator_review_package", "rows"], fn rows ->
        Enum.map(rows, &drop_recommendation_copy/1)
      end)
      |> update_in(["cadence_import_manifest", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if report_row?(row) do
            row
            |> drop_recommendation_copy()
            |> update_in(["source_review_row"], &drop_recommendation_copy/1)
          else
            row
          end
        end)
      end)

    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(older)
  end

  test "rejects source resolution-report identity drift", %{repair: repair} do
    review_index = source_review_index(repair)
    import_index = source_import_index(repair)
    wrong_source = @source <> ".legacy"

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

  test "rejects source resolution-report recommendation-copy drift", %{
    repair: repair
  } do
    review_index = source_review_index(repair)
    import_index = source_import_index(repair)

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source_recommendation",
       put_in(
         repair,
         [
           "operator_review_package",
           "rows",
           Access.at(review_index),
           "source_recommendation",
           "selected_contact_id"
         ],
         "dl_2"
       )},
      {"$.cadence_import_manifest.rows[#{import_index}].source_recommendation",
       put_in(
         repair,
         [
           "cadence_import_manifest",
           "rows",
           Access.at(import_index),
           "source_recommendation",
           "selected_contact_id"
         ],
         "dl_2"
       )},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_recommendation",
       put_in(
         repair,
         [
           "cadence_import_manifest",
           "rows",
           Access.at(import_index),
           "source_review_row",
           "source_recommendation",
           "selected_contact_id"
         ],
         "dl_2"
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects coordinated winner drift, missing rows, and stale handoffs", %{
    repair: repair
  } do
    review_index = source_review_index(repair)
    import_index = source_import_index(repair)

    coordinated_winner_drift =
      repair
      |> update_in(
        ["operator_review_package", "rows", Access.at(review_index)],
        &put_winner(&1, false)
      )
      |> update_in(
        ["cadence_import_manifest", "rows", Access.at(import_index)],
        &put_winner(&1, true)
      )

    missing_review =
      update_in(repair, ["operator_review_package", "rows"], fn rows ->
        List.delete_at(rows, review_index)
      end)

    missing_import =
      update_in(repair, ["cadence_import_manifest", "rows"], fn rows ->
        List.delete_at(rows, import_index)
      end)

    stale_handoffs = Map.delete(repair, "source_contact_contention_resolution_report")

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source_recommendation",
       coordinated_winner_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_recommendation",
       coordinated_winner_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_recommendation",
       coordinated_winner_drift},
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

  defp drop_recommendation_copy(row) do
    if report_row?(row), do: Map.delete(row, "source_recommendation"), else: row
  end

  defp put_winner(row, nested?) do
    row =
      row
      |> Map.put("selected_contact_id", "dl_2")
      |> Map.put("deferred_contact_ids", ["dl_1"])
      |> put_in(["source_recommendation", "selected_contact_id"], "dl_2")
      |> put_in(["source_recommendation", "deferred_contact_ids"], ["dl_1"])

    if nested? do
      row
      |> put_in(["source_review_row", "selected_contact_id"], "dl_2")
      |> put_in(["source_review_row", "deferred_contact_ids"], ["dl_1"])
      |> put_in(
        ["source_review_row", "source_recommendation", "selected_contact_id"],
        "dl_2"
      )
      |> put_in(
        ["source_review_row", "source_recommendation", "deferred_contact_ids"],
        ["dl_1"]
      )
    else
      row
    end
  end

  defp source_review_rows(repair) do
    Enum.filter(
      get_in(repair, ["operator_review_package", "rows"]),
      &report_row?/1
    )
  end

  defp source_import_rows(repair) do
    Enum.filter(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &report_row?/1
    )
  end

  defp source_review_index(repair) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &report_row?/1
    )
  end

  defp source_import_index(repair) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &report_row?/1
    )
  end

  defp report_row?(row), do: row_source(row) == @source

  defp row_source(row) do
    Map.get(row, "source") || get_in(row, ["source_review_row", "source"])
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
