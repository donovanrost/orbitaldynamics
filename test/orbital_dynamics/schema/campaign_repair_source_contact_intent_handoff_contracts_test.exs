Code.require_file("../campaign_planner/support.exs", __DIR__)

defmodule OrbitalDynamics.Schema.CampaignRepairSourceContactIntentHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.TestSupport
  alias OrbitalDynamics.OperatorReview.ContactIntent
  alias OrbitalDynamics.Schema

  @source "campaign_repair.source_contact_intents"

  setup_all do
    first_intent = read_json!("study_results/contact_intent_v1.json")

    passive_intent =
      first_intent
      |> rename_intent("refresh_downlink_passive")
      |> Map.put("approval_status", "not_evaluated")
      |> Map.drop(["approval_requirements", "approval_rule_matches", "policy_decision"])

    second_intent =
      first_intent
      |> rename_intent("refresh_downlink_2")
      |> Map.merge(%{
        "starts_at_s" => 200,
        "ends_at_s" => 260,
        "estimated_throughput_mb" => 80
      })

    source_intents = [first_intent, passive_intent, second_intent]

    candidate_refresh =
      "study_results/candidate_refresh_v1.json"
      |> read_json!()
      |> put_in(["candidate_refresh", "contact_intents"], source_intents)

    repair =
      TestSupport.repair(
        %{"activities" => [], "candidate_activities" => []},
        realized_state: %{activities: []},
        current_epoch_s: 0.0,
        candidate_refresh: candidate_refresh
      )

    expected_rows = ContactIntent.rows(source_intents, @source)

    %{repair: repair, source_intents: source_intents, expected_rows: expected_rows}
  end

  test "validates exact review-eligible source intents in producer order", %{
    repair: repair,
    source_intents: source_intents,
    expected_rows: expected_rows
  } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)
    assert repair["source_contact_intents"] == source_intents

    review_rows = source_review_rows(repair)
    import_rows = source_import_rows(repair)

    assert Enum.map(review_rows, & &1["subject_id"]) == [
             "refresh_downlink",
             "refresh_downlink_2"
           ]

    assert Enum.map(import_rows, & &1["subject_id"]) == [
             "refresh_downlink",
             "refresh_downlink_2"
           ]

    assert Enum.map(review_rows, & &1["source_contact_intent"]) ==
             Enum.map(expected_rows, & &1["source_contact_intent"])

    assert Enum.map(import_rows, &get_in(&1, ["source_review_row", "source_contact_intent"])) ==
             Enum.map(expected_rows, & &1["source_contact_intent"])
  end

  test "keeps additive direct-intent packages and source copies optional", %{repair: repair} do
    assert {:ok, %{"schema_version" => 2}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    older =
      repair
      |> update_in(["operator_review_package", "rows"], fn rows ->
        Enum.map(rows, &drop_source_copy/1)
      end)
      |> update_in(["cadence_import_manifest", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if direct_intent_row?(row) do
            row
            |> drop_source_copy()
            |> update_in(["source_review_row"], &drop_source_copy/1)
          else
            row
          end
        end)
      end)

    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(older)
  end

  test "rejects direct source-intent identity drift at every produced path", %{
    repair: repair
  } do
    review_index = source_review_index(repair, "refresh_downlink")
    import_index = source_import_index(repair, "refresh_downlink")
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

  test "rejects direct source-intent copy drift at every evidence path", %{repair: repair} do
    review_index = source_review_index(repair, "refresh_downlink")
    import_index = source_import_index(repair, "refresh_downlink")

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source_contact_intent",
       put_in(
         repair,
         [
           "operator_review_package",
           "rows",
           Access.at(review_index),
           "source_contact_intent",
           "estimated_throughput_mb"
         ],
         999
       )},
      {"$.cadence_import_manifest.rows[#{import_index}].source_contact_intent",
       put_in(
         repair,
         [
           "cadence_import_manifest",
           "rows",
           Access.at(import_index),
           "source_contact_intent",
           "estimated_throughput_mb"
         ],
         999
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
           "estimated_throughput_mb"
         ],
         999
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects coordinated evidence drift, missing rows, and stale handoffs", %{
    repair: repair
  } do
    review_index = source_review_index(repair, "refresh_downlink")
    import_index = source_import_index(repair, "refresh_downlink")

    coordinated_drift =
      repair
      |> update_in(
        ["operator_review_package", "rows", Access.at(review_index)],
        &put_throughput_drift(&1, false)
      )
      |> update_in(
        ["cadence_import_manifest", "rows", Access.at(import_index)],
        &put_throughput_drift(&1, true)
      )

    missing_review =
      update_in(repair, ["operator_review_package", "rows"], fn rows ->
        List.delete_at(rows, review_index)
      end)

    missing_import =
      update_in(repair, ["cadence_import_manifest", "rows"], fn rows ->
        List.delete_at(rows, import_index)
      end)

    stale_handoffs = Map.delete(repair, "source_contact_intents")

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source_contact_intent",
       coordinated_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_contact_intent",
       coordinated_drift},
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

  defp rename_intent(intent, id) do
    intent
    |> Map.put("id", id)
    |> Map.put("activity_id", id)
    |> put_in(["cadence_import", "external_id"], id)
    |> update_in(["approval_requirements"], fn requirements ->
      Enum.map(requirements, fn requirement ->
        requirement
        |> Map.put("id", "approval:#{id}")
        |> Map.put("activity_id", id)
      end)
    end)
  end

  defp put_throughput_drift(row, nested?) do
    row =
      row
      |> Map.put("estimated_throughput_mb", 999)
      |> put_in(["source_contact_intent", "estimated_throughput_mb"], 999)

    if nested? do
      row
      |> put_in(["source_review_row", "estimated_throughput_mb"], 999)
      |> put_in(["source_review_row", "source_contact_intent", "estimated_throughput_mb"], 999)
    else
      row
    end
  end

  defp drop_source_copy(row) do
    if direct_intent_row?(row), do: Map.delete(row, "source_contact_intent"), else: row
  end

  defp source_review_rows(repair) do
    Enum.filter(get_in(repair, ["operator_review_package", "rows"]), &direct_intent_row?/1)
  end

  defp source_import_rows(repair) do
    Enum.filter(get_in(repair, ["cadence_import_manifest", "rows"]), &direct_intent_row?/1)
  end

  defp source_review_index(repair, subject_id) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &(direct_intent_row?(&1) and &1["subject_id"] == subject_id)
    )
  end

  defp source_import_index(repair, subject_id) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &(direct_intent_row?(&1) and &1["subject_id"] == subject_id)
    )
  end

  defp direct_intent_row?(row) do
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
