Code.require_file("../campaign_planner/support.exs", __DIR__)

defmodule OrbitalDynamics.Schema.CampaignRepairSourceContactIntentSummaryHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.TestSupport
  alias OrbitalDynamics.OperatorReview.ContactIntent
  alias OrbitalDynamics.Schema

  @source_prefix "campaign_repair.source_contact_intent_summary"
  @source @source_prefix <> ".summary_contacts"

  setup_all do
    source_summary = read_json!("study_results/contact_intent_summary_v1.json")

    candidate_refresh =
      "study_results/candidate_refresh_v1.json"
      |> read_json!()
      |> put_in(["candidate_refresh", "source_contact_intent_summary"], source_summary)

    repair =
      TestSupport.repair(
        %{"activities" => [], "candidate_activities" => []},
        realized_state: %{activities: []},
        current_epoch_s: 0.0,
        candidate_refresh: candidate_refresh
      )

    expected_rows = ContactIntent.source_summary_rows(source_summary, @source_prefix)

    %{repair: repair, source_summary: source_summary, expected_rows: expected_rows}
  end

  test "validates exact source summary rows, order, and evidence", %{
    repair: repair,
    expected_rows: expected_rows
  } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    review_rows = source_review_rows(repair)
    import_rows = source_import_rows(repair)

    assert Enum.map(review_rows, & &1["direction"]) == ["command", "downlink", "tracking"]
    assert Enum.map(import_rows, & &1["direction"]) == ["command", "downlink", "tracking"]

    assert Enum.map(review_rows, & &1["source_contact_intent"]) ==
             Enum.map(expected_rows, & &1["source_contact_intent"])

    assert Enum.map(import_rows, & &1["source_contact_intent_summary"]) ==
             Enum.map(expected_rows, & &1["source_contact_intent_summary"])

    assert Enum.map(import_rows, &get_in(&1, ["source_review_row", "source_contact_intent"])) ==
             Enum.map(expected_rows, & &1["source_contact_intent"])
  end

  test "keeps additive summary packages and evidence copies optional", %{repair: repair} do
    assert {:ok, %{"schema_version" => 2}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    older =
      repair
      |> update_in(["operator_review_package", "rows"], fn rows ->
        Enum.map(rows, &drop_summary_copies/1)
      end)
      |> update_in(["cadence_import_manifest", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if summary_row?(row) do
            row
            |> drop_summary_copies()
            |> update_in(["source_review_row"], &drop_summary_copies/1)
          else
            row
          end
        end)
      end)

    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(older)
  end

  test "rejects source summary identity drift at every produced source path", %{
    repair: repair
  } do
    review_index = source_review_index(repair, "downlink")
    import_index = source_import_index(repair, "downlink")
    wrong_source = @source <> ".legacy"

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source",
       put_in(
         repair,
         ["operator_review_package", "rows", Access.at(review_index), "source"],
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

  test "rejects source summary producer-row and context-copy drift", %{repair: repair} do
    review_index = source_review_index(repair, "downlink")
    import_index = source_import_index(repair, "downlink")

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source_contact_intent",
       put_in(
         repair,
         [
           "operator_review_package",
           "rows",
           Access.at(review_index),
           "source_contact_intent",
           "contact_ids"
         ],
         ["drifted_contact"]
       )},
      {"$.operator_review_package.rows[#{review_index}].source_contact_intent_summary",
       put_in(
         repair,
         [
           "operator_review_package",
           "rows",
           Access.at(review_index),
           "source_contact_intent_summary",
           "contact_intent_count"
         ],
         4
       )},
      {"$.cadence_import_manifest.rows[#{import_index}].source_contact_intent",
       put_in(
         repair,
         [
           "cadence_import_manifest",
           "rows",
           Access.at(import_index),
           "source_contact_intent",
           "contact_ids"
         ],
         ["drifted_contact"]
       )},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_contact_intent",
       put_in(
         repair,
         [
           "cadence_import_manifest",
           "rows",
           Access.at(import_index),
           "source_review_row",
           "source_contact_intent",
           "contact_ids"
         ],
         ["drifted_contact"]
       )},
      {"$.cadence_import_manifest.rows[#{import_index}].source_contact_intent_summary",
       put_in(
         repair,
         [
           "cadence_import_manifest",
           "rows",
           Access.at(import_index),
           "source_contact_intent_summary",
           "contact_intent_count"
         ],
         4
       )},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_contact_intent_summary",
       put_in(
         repair,
         [
           "cadence_import_manifest",
           "rows",
           Access.at(import_index),
           "source_review_row",
           "source_contact_intent_summary",
           "contact_intent_count"
         ],
         4
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects coordinated drift, missing rows, stale handoffs, and malformed summaries", %{
    repair: repair
  } do
    review_index = source_review_index(repair, "downlink")
    import_index = source_import_index(repair, "downlink")

    coordinated_drift =
      repair
      |> update_in(
        ["operator_review_package", "rows", Access.at(review_index)],
        &put_summary_count(&1, false)
      )
      |> update_in(
        ["cadence_import_manifest", "rows", Access.at(import_index)],
        &put_summary_count(&1, true)
      )

    missing_review =
      update_in(repair, ["operator_review_package", "rows"], fn rows ->
        List.delete_at(rows, review_index)
      end)

    missing_import =
      update_in(repair, ["cadence_import_manifest", "rows"], fn rows ->
        List.delete_at(rows, import_index)
      end)

    stale_handoffs = Map.delete(repair, "source_contact_intent_summary")

    malformed_summary =
      put_in(
        repair,
        ["source_contact_intent_summary", "direction_routing", "downlink"],
        "malformed_route"
      )

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source_contact_intent_summary",
       coordinated_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_contact_intent_summary",
       coordinated_drift},
      {"$.operator_review_package.rows", missing_review},
      {"$.cadence_import_manifest.rows", missing_import},
      {"$.operator_review_package.rows", stale_handoffs},
      {"$.cadence_import_manifest.rows", stale_handoffs},
      {"$.source_contact_intent_summary.direction_routing.downlink", malformed_summary}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  defp put_summary_count(row, nested?) do
    row =
      row
      |> put_in(["source_contact_intent_summary", "contact_intent_count"], 4)
      |> put_in(
        ["source_contact_intent", "source_contact_intent_summary", "contact_intent_count"],
        4
      )

    if nested? do
      row
      |> put_in(
        ["source_review_row", "source_contact_intent_summary", "contact_intent_count"],
        4
      )
      |> put_in(
        [
          "source_review_row",
          "source_contact_intent",
          "source_contact_intent_summary",
          "contact_intent_count"
        ],
        4
      )
    else
      row
    end
  end

  defp drop_summary_copies(row) do
    if summary_row?(row) do
      Map.drop(row, ["source_contact_intent", "source_contact_intent_summary"])
    else
      row
    end
  end

  defp source_review_rows(repair) do
    Enum.filter(get_in(repair, ["operator_review_package", "rows"]), &summary_row?/1)
  end

  defp source_import_rows(repair) do
    Enum.filter(get_in(repair, ["cadence_import_manifest", "rows"]), &summary_row?/1)
  end

  defp source_review_index(repair, direction) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &(summary_row?(&1) and &1["direction"] == direction)
    )
  end

  defp source_import_index(repair, direction) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &(summary_row?(&1) and &1["direction"] == direction)
    )
  end

  defp summary_row?(row) do
    case row_source(row) do
      source when is_binary(source) -> String.starts_with?(source, @source)
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
