Code.require_file("../campaign_planner/support.exs", __DIR__)

defmodule OrbitalDynamics.Schema.CampaignRepairSourceValidationSafetyCaseHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.TestSupport
  alias OrbitalDynamics.Schema

  @repair_source "campaign_repair.source_validation_safety_case_summary.evidence"

  setup_all do
    source_summary = read_json!("study_results/validation_safety_case_summary_v1.json")

    candidate_refresh =
      "study_results/candidate_refresh_v1.json"
      |> read_json!()
      |> put_in(
        ["candidate_refresh", "source_validation_safety_case_summary"],
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

  test "validates Repair source validation-safety-case handoffs in producer order", %{
    repair: repair,
    source_summary: source_summary
  } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    expected = [
      {@repair_source, 1, "review_required"},
      {@repair_source, 3, "blocked"},
      {@repair_source, 4, "blocked"}
    ]

    review_rows =
      repair
      |> get_in(["operator_review_package", "rows"])
      |> Enum.filter(&safety_case_source?/1)

    assert expected ==
             Enum.map(review_rows, fn row ->
               {
                 row_source(row),
                 get_in(row, ["source_validation_safety_case_evidence", "rank"]),
                 row["validation_safety_case_evidence_status"]
               }
             end)

    expected_source_rows =
      Enum.filter(
        source_summary["evidence"],
        &(Map.get(&1, "status") in ["blocked", "review_required"])
      )

    expected_context = safety_case_context(source_summary)

    assert Enum.map(review_rows, & &1["source_validation_safety_case_evidence"]) ==
             expected_source_rows

    assert Enum.all?(
             review_rows,
             &(&1["source_validation_safety_case_summary"] == expected_context)
           )

    refute Enum.any?(
             get_in(repair, ["cadence_import_manifest", "rows"]),
             &(&1["source_review_type"] == "validation_safety_case_review")
           )
  end

  test "keeps additive source validation-safety-case handoffs optional", %{repair: repair} do
    assert {:ok, %{"schema_version" => 2}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    older =
      update_in(repair, ["operator_review_package", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if safety_case_source?(row) do
            Map.drop(row, [
              "source_validation_safety_case_evidence",
              "source_validation_safety_case_summary"
            ])
          else
            row
          end
        end)
      end)

    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(older)
  end

  test "rejects Repair source validation-safety-case handoff drift", %{repair: repair} do
    review_index = safety_case_review_index(repair)
    wrong_source = @repair_source <> ".legacy"

    source_drift =
      put_in(
        repair,
        ["operator_review_package", "rows", Access.at(review_index), "source"],
        wrong_source
      )

    evidence_drift =
      put_in(
        repair,
        [
          "operator_review_package",
          "rows",
          Access.at(review_index),
          "source_validation_safety_case_evidence",
          "rank"
        ],
        99
      )

    context_drift =
      update_in(repair, ["operator_review_package", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if safety_case_source?(row) do
            row
            |> put_in(
              ["source_validation_safety_case_summary", "blocked_evidence_count"],
              3
            )
            |> Map.put("validation_safety_case_blocked_evidence_count", 3)
          else
            row
          end
        end)
      end)

    eligibility_drift =
      Map.put(
        repair,
        "source_validation_safety_case_summary",
        OrbitalDynamics.validation_safety_case_summary(
          [
            %{
              "schema_contract" => "schema_validation_report.v1",
              "status" => "pass",
              "validated_contract" => "candidate_refresh.v1",
              "error_count" => 0,
              "warning_count" => 0
            }
          ],
          case_id: "case:accepted-only"
        )
      )

    stale_handoffs = Map.delete(repair, "source_validation_safety_case_summary")

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source", source_drift},
      {"$.operator_review_package.rows[#{review_index}].source_validation_safety_case_evidence",
       evidence_drift},
      {"$.operator_review_package.rows[#{review_index}].source_validation_safety_case_summary",
       context_drift},
      {"$.operator_review_package.rows", eligibility_drift},
      {"$.operator_review_package.rows", stale_handoffs}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  defp safety_case_context(summary) do
    Map.take(summary, [
      "schema_contract",
      "schema_version",
      "model",
      "source",
      "summary_id",
      "case_id",
      "status",
      "evidence_count",
      "input_contracts",
      "evidence_status_counts",
      "evidence_refs_by_status",
      "evidence_refs_by_contract",
      "blocked_evidence_count",
      "review_required_evidence_count",
      "accepted_evidence_count",
      "model_accepted_count",
      "model_review_required_count",
      "model_blocked_count",
      "unknown_model_count",
      "readiness_review_required_count",
      "readiness_blocked_count",
      "ready_for_import_count",
      "quality_gate_review_count",
      "quality_gate_blocked_count",
      "schema_error_count",
      "schema_warning_count",
      "schema_validation_report_count",
      "schema_validation_failed_report_count",
      "fixture_passed_count",
      "fixture_failed_count",
      "assumptions",
      "model_limits"
    ])
  end

  defp safety_case_review_index(repair) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &safety_case_source?/1
    )
  end

  defp safety_case_source?(row), do: row_source(row) == @repair_source

  defp row_source(row) do
    Map.get(row, "source") || get_in(row, ["source_review_row", "source"])
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
