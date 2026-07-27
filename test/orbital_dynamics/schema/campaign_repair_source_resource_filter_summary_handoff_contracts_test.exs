Code.require_file("../campaign_planner/support.exs", __DIR__)

defmodule OrbitalDynamics.Schema.CampaignRepairSourceResourceFilterSummaryHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.TestSupport
  alias OrbitalDynamics.OperatorReview.FilterReview
  alias OrbitalDynamics.ResourceFilter
  alias OrbitalDynamics.Schema

  @source_prefix "campaign_repair.source_resource_filter_summary"
  @source @source_prefix <> ".review_rows"

  setup_all do
    resource_filter_summary = read_json!("study_results/resource_filter_summary_v1.json")

    candidate_refresh =
      "study_results/candidate_refresh_v1.json"
      |> read_json!()
      |> put_in(
        ["candidate_refresh", "source_resource_filter_summary"],
        resource_filter_summary
      )

    repair =
      TestSupport.repair(
        %{"activities" => [], "candidate_activities" => []},
        realized_state: %{activities: []},
        current_epoch_s: 0.0,
        candidate_refresh: candidate_refresh
      )

    expected_rows = FilterReview.resource_rows(resource_filter_summary, @source_prefix)

    %{repair: repair, expected_rows: expected_rows}
  end

  test "validates every source resource-filter summary row in producer order", %{
    repair: repair,
    expected_rows: expected_rows
  } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    review_rows = source_review_rows(repair)
    import_rows = source_import_rows(repair)

    expected_subject_ids = [
      "leo_1_observe_target_a_1",
      "leo_1_downlink_equator_prime_1"
    ]

    assert Enum.map(review_rows, &{&1["source"], &1["subject_id"]}) ==
             Enum.map(expected_subject_ids, &{@source, &1})

    assert Enum.map(import_rows, &{row_source(&1), &1["subject_id"]}) ==
             Enum.map(expected_subject_ids, &{@source, &1})

    assert Enum.map(review_rows, & &1["source_resource_suppression"]) ==
             Enum.map(expected_rows, & &1["source_resource_suppression"])

    assert Enum.map(
             import_rows,
             &get_in(&1, ["source_review_row", "source_resource_suppression"])
           ) ==
             Enum.map(expected_rows, & &1["source_resource_suppression"])
  end

  test "preserves invalid-summary rows before suppression review rows" do
    resource_filter_summary =
      %{
        "schema_contract" => "resource_filter_report.v1",
        "input_candidate_count" => 2,
        "kept_candidate_count" => 1,
        "suppressed_candidates" => [
          %{
            "id" => "summary_observe_payload_block",
            "type" => "observe",
            "scenario_id" => "leo_1",
            "spacecraft_id" => "leo_1",
            "resource_id" => "payload_1",
            "suppressed_reason" => "payload_unavailable",
            "resource_blocking_dimension" => "payload",
            "resource_source_quality" => "operator_supplied",
            "resource_trust_boundary_status" => "declared"
          }
        ],
        "invalid_resource_summary_inputs" => [
          %{
            "resource_summary_id" => "summary_bad_resource",
            "spacecraft_id" => "leo_1",
            "invalid_resource_summary_input_reason" => "invalid_power_margin",
            "source_resource_summary" => %{"power_margin" => 1.2}
          }
        ]
      }
      |> ResourceFilter.summary()

    candidate_refresh =
      "study_results/candidate_refresh_v1.json"
      |> read_json!()
      |> put_in(
        ["candidate_refresh", "source_resource_filter_summary"],
        resource_filter_summary
      )

    repair =
      TestSupport.repair(
        %{"activities" => [], "candidate_activities" => []},
        realized_state: %{activities: []},
        current_epoch_s: 0.0,
        candidate_refresh: candidate_refresh
      )

    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    assert Enum.map(source_review_rows(repair), &{&1["source"], &1["subject_id"]}) == [
             {@source_prefix <> ".invalid_resource_summary_inputs", "summary_bad_resource"},
             {@source, "summary_observe_payload_block"}
           ]

    assert Enum.map(source_import_rows(repair), &{row_source(&1), &1["subject_id"]}) == [
             {@source_prefix <> ".invalid_resource_summary_inputs", "summary_bad_resource"},
             {@source, "summary_observe_payload_block"}
           ]
  end

  test "keeps additive review packages and source copies optional", %{repair: repair} do
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
          if source_summary_row?(row) do
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

  test "rejects source resource-filter summary identity drift at every produced path", %{
    repair: repair
  } do
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

  test "rejects source resource-filter summary copy drift at every evidence path", %{
    repair: repair
  } do
    review_index = source_review_index(repair)
    import_index = source_import_index(repair)

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source_resource_suppression",
       put_in(
         repair,
         summary_count_path("operator_review_package", review_index, false),
         99
       )},
      {"$.cadence_import_manifest.rows[#{import_index}].source_resource_suppression",
       put_in(
         repair,
         summary_count_path("cadence_import_manifest", import_index, false),
         99
       )},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_resource_suppression",
       put_in(
         repair,
         summary_count_path("cadence_import_manifest", import_index, true),
         99
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects coordinated summary-context drift, missing rows, and stale handoffs", %{
    repair: repair
  } do
    review_index = source_review_index(repair)
    import_index = source_import_index(repair)

    coordinated_drift =
      repair
      |> put_in(summary_count_path("operator_review_package", review_index, false), 99)
      |> put_in(summary_count_path("cadence_import_manifest", import_index, false), 99)
      |> put_in(summary_count_path("cadence_import_manifest", import_index, true), 99)

    missing_review =
      update_in(repair, ["operator_review_package", "rows"], fn rows ->
        List.delete_at(rows, review_index)
      end)

    missing_import =
      update_in(repair, ["cadence_import_manifest", "rows"], fn rows ->
        List.delete_at(rows, import_index)
      end)

    stale_handoffs = Map.delete(repair, "source_resource_filter_summary")

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source_resource_suppression",
       coordinated_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_resource_suppression",
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

  defp summary_count_path(package, index, nested?) do
    prefix = [package, "rows", Access.at(index)]

    evidence_path =
      if nested?,
        do: ["source_review_row", "source_resource_suppression"],
        else: ["source_resource_suppression"]

    prefix ++
      evidence_path ++ ["source_resource_filter_summary", "suppressed_candidate_count"]
  end

  defp drop_source_copy(row) do
    if source_summary_row?(row),
      do: Map.delete(row, "source_resource_suppression"),
      else: row
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
    case row_source(row) do
      source when is_binary(source) -> String.starts_with?(source, @source_prefix)
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
