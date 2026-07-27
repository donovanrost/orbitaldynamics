Code.require_file("../campaign_planner/support.exs", __DIR__)

defmodule OrbitalDynamics.Schema.CampaignRepairSourceModelAcceptanceHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.TestSupport
  alias OrbitalDynamics.Schema

  @repair_source "campaign_repair.source_model_acceptance_report.rows"

  setup_all do
    source_report = source_report()

    candidate_refresh =
      "study_results/candidate_refresh_v1.json"
      |> read_json!()
      |> put_in(["candidate_refresh", "source_model_acceptance_report"], [source_report])

    repair =
      TestSupport.repair(
        %{"activities" => [], "candidate_activities" => []},
        realized_state: %{activities: []},
        current_epoch_s: 0.0,
        candidate_refresh: candidate_refresh
      )

    %{repair: repair, source_report: source_report}
  end

  test "validates Repair source model-acceptance handoffs in producer order", %{
    repair: repair,
    source_report: source_report
  } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    expected = [
      {@repair_source, "event.access_windows", "review_required"},
      {@repair_source, "propagator.two_body", "blocked"}
    ]

    review_rows =
      repair
      |> get_in(["operator_review_package", "rows"])
      |> Enum.filter(&model_acceptance_source?/1)

    assert expected ==
             Enum.map(
               review_rows,
               &{row_source(&1), &1["subject_id"], &1["model_acceptance_status"]}
             )

    expected_source_rows =
      Enum.filter(
        source_report["rows"],
        &(Map.get(&1, "status") not in [nil, "accepted", "accepted_for_use"])
      )

    expected_context = model_acceptance_context(source_report)

    assert Enum.map(review_rows, & &1["source_model_acceptance_row"]) == expected_source_rows
    assert Enum.all?(review_rows, &(&1["source_model_acceptance_report"] == expected_context))

    refute Enum.any?(
             get_in(repair, ["cadence_import_manifest", "rows"]),
             &(&1["source_review_type"] == "model_acceptance_review")
           )
  end

  test "keeps additive source model-acceptance handoffs optional", %{repair: repair} do
    assert {:ok, %{"schema_version" => 2}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    older =
      update_in(repair, ["operator_review_package", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if model_acceptance_source?(row) do
            Map.drop(row, ["source_model_acceptance_row", "source_model_acceptance_report"])
          else
            row
          end
        end)
      end)

    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(older)
  end

  test "rejects Repair source model-acceptance handoff drift", %{repair: repair} do
    review_index = model_acceptance_review_index(repair)
    wrong_source = @repair_source <> ".legacy"

    source_drift =
      put_in(
        repair,
        ["operator_review_package", "rows", Access.at(review_index), "source"],
        wrong_source
      )

    row_drift =
      put_in(
        repair,
        [
          "operator_review_package",
          "rows",
          Access.at(review_index),
          "source_model_acceptance_row",
          "validation_level"
        ],
        "educational"
      )

    context_drift =
      update_in(
        repair,
        ["operator_review_package", "rows"],
        fn rows ->
          Enum.map(rows, fn row ->
            if model_acceptance_source?(row) do
              row
              |> put_in(["source_model_acceptance_report", "model_count"], 4)
              |> Map.put("model_acceptance_model_count", 4)
            else
              row
            end
          end)
        end
      )

    eligibility_drift =
      Map.put(
        repair,
        "source_model_acceptance_report",
        OrbitalDynamics.validation_model_acceptance_report(
          ["orbit_data.simple_json"],
          intended_use: :operational_import
        )
      )

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source", source_drift},
      {"$.operator_review_package.rows[#{review_index}].source_model_acceptance_row", row_drift},
      {"$.operator_review_package.rows[#{review_index}].source_model_acceptance_report",
       context_drift},
      {"$.operator_review_package.rows", eligibility_drift}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  defp source_report do
    OrbitalDynamics.validation_model_acceptance_report(
      ["orbit_data.simple_json", "event.access_windows", "propagator.two_body"],
      intended_use: :operational_import
    )
  end

  defp model_acceptance_context(report) do
    Map.take(report, [
      "schema_contract",
      "schema_version",
      "model",
      "report_id",
      "intended_use",
      "status",
      "model_count",
      "accepted_count",
      "review_required_count",
      "blocked_count",
      "unknown_model_count",
      "status_counts",
      "validation_level_counts",
      "model_ids_by_status",
      "model_ids_by_validation_level",
      "model_ids_by_intended_use",
      "assumptions",
      "model_limits"
    ])
  end

  defp model_acceptance_review_index(repair) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &model_acceptance_source?/1
    )
  end

  defp model_acceptance_source?(row), do: row_source(row) == @repair_source

  defp row_source(row) do
    Map.get(row, "source") || get_in(row, ["source_review_row", "source"])
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
