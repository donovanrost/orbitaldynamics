Code.require_file("../campaign_planner/support.exs", __DIR__)

defmodule OrbitalDynamics.Schema.CampaignRepairSourceProviderCounterofferImportReadinessSummaryHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.TestSupport
  alias OrbitalDynamics.Schema

  @repair_source "campaign_repair.source_provider_counteroffer_import_readiness_summary.import_readiness_rows"
  @summary_context_fields [
    "model",
    "schema_contract",
    "source",
    "source_artifact_type",
    "source_artifact_id",
    "counteroffer_count",
    "reviewable_count",
    "review_counteroffer_ids",
    "counteroffer_review_status",
    "counteroffer_status_counts",
    "counteroffer_negotiation_state_counts",
    "counteroffer_lock_deadline_count",
    "earliest_counteroffer_lock_deadline_s",
    "expired_counteroffer_lock_deadline_count",
    "active_counteroffer_lock_deadline_count",
    "missing_counteroffer_lock_deadline_count",
    "import_readiness_status",
    "import_classification",
    "provider_counteroffer_import_status_counts",
    "required_import_action_counts",
    "plan_impact_status",
    "counteroffer_lock_deadline_status_counts",
    "counteroffer_ids_by_lock_deadline_status",
    "assumptions"
  ]

  setup_all do
    source_summary = source_summary()

    candidate_refresh =
      "study_results/candidate_refresh_v1.json"
      |> read_json!()
      |> put_in(
        ["candidate_refresh", "source_provider_counteroffer_import_readiness_summary"],
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

  test "validates Repair source provider-counteroffer import-readiness-summary handoffs in producer order",
       %{repair: repair, source_summary: source_summary} do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    expected_source_rows = enriched_import_readiness_rows(source_summary)
    review_rows = source_review_rows(repair)
    import_rows = source_import_rows(repair)

    assert ["provider_offer_1", "provider_offer_3"] ==
             Enum.map(review_rows, & &1["provider_counteroffer_id"])

    assert ["provider_offer_1", "provider_offer_3"] ==
             Enum.map(import_rows, & &1["provider_counteroffer_id"])

    assert Enum.all?(review_rows, &(row_source(&1) == @repair_source))
    assert Enum.all?(import_rows, &(row_source(&1) == @repair_source))

    assert Enum.map(review_rows, & &1["source_provider_counteroffer"]) ==
             expected_source_rows

    assert Enum.map(import_rows, & &1["source_provider_counteroffer"]) ==
             expected_source_rows

    assert Enum.map(
             import_rows,
             &get_in(&1, ["source_review_row", "source_provider_counteroffer"])
           ) == expected_source_rows
  end

  test "keeps additive source provider-counteroffer import-readiness-summary handoffs optional",
       %{
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
          if source_counteroffer_row?(row),
            do: Map.delete(row, "source_provider_counteroffer"),
            else: row
        end)
      end)
      |> update_in(["cadence_import_manifest", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if source_counteroffer_row?(row) do
            row
            |> Map.delete("source_provider_counteroffer")
            |> update_in(["source_review_row"], &Map.delete(&1, "source_provider_counteroffer"))
          else
            row
          end
        end)
      end)

    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(older)
  end

  test "rejects Repair source provider-counteroffer import-readiness-summary handoff drift", %{
    repair: repair
  } do
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
          "source_provider_counteroffer",
          "source_provider_counteroffer_summary",
          "import_readiness_status"
        ],
        "clear"
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
          "source_provider_counteroffer",
          "source_provider_counteroffer_summary",
          "import_readiness_status"
        ],
        "clear"
      )

    import_nested_copy_drift =
      put_in(
        repair,
        [
          "cadence_import_manifest",
          "rows",
          Access.at(import_index),
          "source_review_row",
          "source_provider_counteroffer",
          "source_provider_counteroffer_summary",
          "import_readiness_status"
        ],
        "clear"
      )

    eligibility_drift =
      Map.put(
        repair,
        "source_provider_counteroffer_import_readiness_summary",
        no_import_summary()
      )

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source", review_source_drift},
      {"$.operator_review_package.rows[#{review_index}].source_provider_counteroffer",
       review_copy_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source", import_source_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source",
       import_nested_source_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_provider_counteroffer",
       import_outer_copy_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_provider_counteroffer",
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
    source_report()
    |> OrbitalDynamics.provider_counteroffer_import_readiness_summary(now_s: 360.0)
  end

  defp no_import_summary do
    source_report()
    |> mark_ineligible(0)
    |> mark_ineligible(2)
    |> OrbitalDynamics.provider_counteroffer_import_readiness_summary(now_s: 360.0)
  end

  defp source_report do
    [
      %{
        id: :review_window,
        provider_id: :ops_calendar,
        ground_station_id: :dss_14,
        starts_at_s: 130.0,
        ends_at_s: 170.0,
        counteroffer_id: :provider_offer_1,
        counteroffer_status: :proposed,
        counteroffer_reason_code: :provider_shifted_window,
        counteroffer_cost_delta: 125.5,
        counteroffer_lock_deadline_s: 150.0,
        counteroffer_starts_at_s: 160.0,
        counteroffer_ends_at_s: 210.0
      },
      %{
        id: :no_review_window,
        provider_id: :ops_calendar,
        ground_station_id: :dss_24,
        starts_at_s: 230.0,
        ends_at_s: 270.0,
        counteroffer_id: :provider_offer_2,
        counteroffer_status: :accepted,
        counteroffer_reason_code: :accepted,
        counteroffer_cost_delta: 0.0,
        counteroffer_lock_deadline_s: 250.0,
        counteroffer_starts_at_s: 230.0,
        counteroffer_ends_at_s: 270.0
      },
      %{
        id: :second_review_window,
        provider_id: :ops_calendar,
        ground_station_id: :dss_34,
        starts_at_s: 330.0,
        ends_at_s: 370.0,
        counteroffer_id: :provider_offer_3,
        counteroffer_status: :proposed,
        counteroffer_reason_code: :provider_shifted_window,
        counteroffer_cost_delta: 45.0,
        counteroffer_lock_deadline_s: 350.0,
        counteroffer_starts_at_s: 345.0,
        counteroffer_ends_at_s: 390.0
      }
    ]
    |> OrbitalDynamics.provider_counteroffer_report(source: :candidate_refresh_v2_handoff)
    |> mark_ineligible(1)
  end

  defp mark_ineligible(report, index) do
    report
    |> put_in(["rows", Access.at(index), "reviewable"], false)
    |> put_in(["rows", Access.at(index), "required_operator_action"], "none")
    |> Map.update!("reviewable_count", &max(&1 - 1, 0))
    |> Map.update!("required_operator_action_counts", fn counts ->
      counts
      |> Map.update("review_provider_counteroffer", 0, &max(&1 - 1, 0))
      |> Map.update("none", 1, &(&1 + 1))
      |> Enum.reject(fn {_action, count} -> count == 0 end)
      |> Map.new()
    end)
  end

  defp enriched_import_readiness_rows(summary) do
    context = summary_context(summary)

    summary["import_readiness_rows"]
    |> Enum.filter(
      &(&1["reviewable"] == true and
          &1["required_operator_action"] == "review_provider_counteroffer")
    )
    |> Enum.map(&Map.put(&1, "source_provider_counteroffer_summary", context))
  end

  defp summary_context(summary) do
    summary
    |> Map.take(@summary_context_fields)
    |> Enum.reject(fn {_field, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp source_review_rows(repair) do
    Enum.filter(get_in(repair, ["operator_review_package", "rows"]), &source_counteroffer_row?/1)
  end

  defp source_import_rows(repair) do
    Enum.filter(get_in(repair, ["cadence_import_manifest", "rows"]), &source_counteroffer_row?/1)
  end

  defp source_review_index(repair) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &source_counteroffer_row?/1
    )
  end

  defp source_import_index(repair) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &source_counteroffer_row?/1
    )
  end

  defp source_counteroffer_row?(row) do
    row_source(row) == @repair_source and
      (row["review_type"] == "provider_counteroffer_review" or
         row["source_review_type"] == "provider_counteroffer_review")
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
