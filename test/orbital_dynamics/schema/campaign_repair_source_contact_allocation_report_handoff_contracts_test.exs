Code.require_file("../campaign_planner/support.exs", __DIR__)

defmodule OrbitalDynamics.Schema.CampaignRepairSourceContactAllocationReportHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.TestSupport
  alias OrbitalDynamics.Schema

  @repair_source "campaign_repair.source_contact_allocation_report.rows"

  setup_all do
    candidate_refresh = read_json!("study_results/candidate_refresh_v1.json")

    repair =
      TestSupport.repair(
        %{"activities" => [], "candidate_activities" => []},
        realized_state: %{activities: []},
        current_epoch_s: 0.0,
        candidate_refresh: candidate_refresh
      )

    %{repair: repair, source_report: repair["source_contact_allocation_report"]}
  end

  test "validates Repair source contact-allocation-report primary-row handoffs in producer order",
       %{
         repair: repair,
         source_report: source_report
       } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    review_rows = source_review_rows(repair)
    import_rows = source_import_rows(repair)

    assert Enum.map(review_rows, & &1["contact_id"]) ==
             Enum.map(source_report["rows"], & &1["contact_id"])

    assert Enum.map(import_rows, & &1["contact_id"]) ==
             Enum.map(source_report["rows"], & &1["contact_id"])

    assert Enum.all?(review_rows, &(row_source(&1) == @repair_source))
    assert Enum.all?(import_rows, &(row_source(&1) == @repair_source))

    assert Enum.map(review_rows, & &1["source_contact_allocation"]) ==
             source_report["rows"]

    assert Enum.map(import_rows, & &1["source_contact_allocation"]) ==
             source_report["rows"]

    assert Enum.map(
             import_rows,
             &get_in(&1, ["source_review_row", "source_contact_allocation"])
           ) == source_report["rows"]
  end

  test "keeps additive source contact-allocation-report primary-row handoffs optional", %{
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
          if source_allocation_row?(row),
            do: Map.delete(row, "source_contact_allocation"),
            else: row
        end)
      end)
      |> update_in(["cadence_import_manifest", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if source_allocation_row?(row) do
            row
            |> Map.delete("source_contact_allocation")
            |> update_in(["source_review_row"], &Map.delete(&1, "source_contact_allocation"))
          else
            row
          end
        end)
      end)

    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(older)
  end

  test "rejects Repair source contact-allocation-report primary-row handoff drift", %{
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
          "source_contact_allocation",
          "contact_status"
        ],
        "drifted"
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
          "source_contact_allocation",
          "contact_status"
        ],
        "drifted"
      )

    import_nested_copy_drift =
      put_in(
        repair,
        [
          "cadence_import_manifest",
          "rows",
          Access.at(import_index),
          "source_review_row",
          "source_contact_allocation",
          "contact_status"
        ],
        "drifted"
      )

    eligibility_drift =
      Map.put(
        repair,
        "source_contact_allocation_report",
        OrbitalDynamics.contact_allocation_report([], [])
      )

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source", review_source_drift},
      {"$.operator_review_package.rows[#{review_index}].source_contact_allocation",
       review_copy_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source", import_source_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source",
       import_nested_source_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_contact_allocation",
       import_outer_copy_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_contact_allocation",
       import_nested_copy_drift},
      {"$.operator_review_package.rows", eligibility_drift},
      {"$.cadence_import_manifest.rows", eligibility_drift}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  defp source_review_rows(repair) do
    Enum.filter(get_in(repair, ["operator_review_package", "rows"]), &source_allocation_row?/1)
  end

  defp source_import_rows(repair) do
    Enum.filter(get_in(repair, ["cadence_import_manifest", "rows"]), &source_allocation_row?/1)
  end

  defp source_review_index(repair) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &source_allocation_row?/1
    )
  end

  defp source_import_index(repair) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &source_allocation_row?/1
    )
  end

  defp source_allocation_row?(row) do
    row_source(row) == @repair_source and
      (row["review_type"] == "contact_allocation_review" or
         row["source_review_type"] == "contact_allocation_review")
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
