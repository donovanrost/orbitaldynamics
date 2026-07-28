Code.require_file("../campaign_planner/support.exs", __DIR__)

defmodule OrbitalDynamics.Schema.CampaignRepairSourceSchemaValidationBatchHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.TestSupport
  alias OrbitalDynamics.Schema

  @repair_source_prefix "campaign_repair.source_schema_validation_batch_report"

  setup_all do
    source_batch = source_batch()

    candidate_refresh =
      "study_results/candidate_refresh_v1.json"
      |> read_json!()
      |> put_in(
        ["candidate_refresh", "source_schema_validation_batch_report"],
        [source_batch]
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

  test "validates Repair source schema-validation-batch handoffs in producer order", %{
    repair: repair
  } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    expected = [
      {
        @repair_source_prefix <> ".reports[0].report.errors",
        "$.plan_id",
        "missing_required_field",
        "study_results/report-owned.json",
        "study_results/batch-entry-0.json"
      },
      {
        @repair_source_prefix <> ".reports[0].report.warnings",
        "$.score",
        "review_low_score",
        "study_results/report-owned.json",
        "study_results/batch-entry-0.json"
      },
      {
        @repair_source_prefix <> ".reports[1].report.warnings",
        "$.capacity",
        "review_low_capacity",
        "study_results/batch-entry-1.json",
        "study_results/batch-entry-1.json"
      }
    ]

    assert expected ==
             repair
             |> get_in(["operator_review_package", "rows"])
             |> Enum.filter(&schema_validation_source?/1)
             |> Enum.map(&row_evidence/1)

    assert expected ==
             repair
             |> get_in(["cadence_import_manifest", "rows"])
             |> Enum.filter(&schema_validation_source?/1)
             |> Enum.map(&row_evidence/1)
  end

  test "keeps additive source schema-validation-batch handoffs optional", %{repair: repair} do
    assert {:ok, %{"schema_version" => 2}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    older =
      repair
      |> update_in(["operator_review_package", "rows"], fn rows ->
        Enum.map(rows, &drop_optional_evidence/1)
      end)
      |> update_in(["cadence_import_manifest", "rows"], fn rows ->
        Enum.map(rows, fn row ->
          if schema_validation_source?(row) do
            row
            |> drop_optional_evidence()
            |> update_in(["source_review_row"], &drop_optional_evidence/1)
          else
            row
          end
        end)
      end)

    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(older)
  end

  test "rejects Repair source schema-validation-batch handoff drift", %{repair: repair} do
    review_index = schema_validation_review_index(repair)
    import_index = schema_validation_import_index(repair)
    wrong_source = @repair_source_prefix <> ".reports[9].report.errors"

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

    review_issue_drift =
      put_in(
        repair,
        [
          "operator_review_package",
          "rows",
          Access.at(review_index),
          "source_validation_issue",
          "message"
        ],
        "modified but valid"
      )

    cadence_issue_drift =
      update_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(import_index)],
        fn row ->
          row
          |> put_in(["source_validation_issue", "message"], "modified but valid")
          |> put_in(
            ["source_review_row", "source_validation_issue", "message"],
            "modified but valid"
          )
        end
      )

    review_remediation_drift =
      put_in(
        repair,
        [
          "operator_review_package",
          "rows",
          Access.at(review_index),
          "source_validation_remediation",
          "action"
        ],
        "Modified but valid"
      )

    cadence_remediation_drift =
      update_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(import_index)],
        fn row ->
          row
          |> put_in(["source_validation_remediation", "action"], "Modified but valid")
          |> put_in(
            ["source_review_row", "source_validation_remediation", "action"],
            "Modified but valid"
          )
        end
      )

    review_report_drift =
      put_in(
        repair,
        [
          "operator_review_package",
          "rows",
          Access.at(review_index),
          "source_schema_validation_report",
          "artifact_path"
        ],
        "study_results/other_valid_campaign.json"
      )

    cadence_report_drift =
      update_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(import_index)],
        fn row ->
          row
          |> put_in(
            ["source_schema_validation_report", "artifact_path"],
            "study_results/other_valid_campaign.json"
          )
          |> put_in(
            ["source_review_row", "source_schema_validation_report", "artifact_path"],
            "study_results/other_valid_campaign.json"
          )
        end
      )

    review_batch_path_drift =
      put_in(
        repair,
        [
          "operator_review_package",
          "rows",
          Access.at(review_index),
          "source_schema_validation_report",
          "batch_entry_path"
        ],
        "study_results/other_batch_entry.json"
      )

    eligibility_drift =
      repair
      |> put_in(
        [
          "source_schema_validation_batch_report",
          "reports",
          Access.at(0),
          "report",
          "warnings"
        ],
        []
      )
      |> put_in(
        [
          "source_schema_validation_batch_report",
          "reports",
          Access.at(0),
          "report",
          "warning_count"
        ],
        0
      )
      |> update_in(
        [
          "source_schema_validation_batch_report",
          "reports",
          Access.at(0),
          "report",
          "remediation"
        ],
        &Enum.reject(&1, fn remediation -> remediation["path"] == "$.score" end)
      )
      |> put_in(
        [
          "source_schema_validation_batch_report",
          "reports",
          Access.at(0),
          "report",
          "remediation_count"
        ],
        1
      )
      |> put_in(["source_schema_validation_batch_report", "warning_count"], 1)
      |> put_in(["source_schema_validation_batch_report", "remediation_count"], 2)

    stale_handoffs = Map.delete(repair, "source_schema_validation_batch_report")

    invalid_cases = [
      {"$.operator_review_package.rows[#{review_index}].source", review_source_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source", cadence_source_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source",
       cadence_source_drift},
      {"$.operator_review_package.rows[#{review_index}].source_validation_issue",
       review_issue_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_validation_issue",
       cadence_issue_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_validation_issue",
       cadence_issue_drift},
      {"$.operator_review_package.rows[#{review_index}].source_validation_remediation",
       review_remediation_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_validation_remediation",
       cadence_remediation_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_validation_remediation",
       cadence_remediation_drift},
      {"$.operator_review_package.rows[#{review_index}].source_schema_validation_report",
       review_report_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_schema_validation_report",
       cadence_report_drift},
      {"$.cadence_import_manifest.rows[#{import_index}].source_review_row.source_schema_validation_report",
       cadence_report_drift},
      {"$.operator_review_package.rows[#{review_index}].source_schema_validation_report",
       review_batch_path_drift},
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

  defp source_batch do
    first_report =
      source_report(%{
        "status" => "fail",
        "artifact_path" => "study_results/report-owned.json",
        "error_count" => 1,
        "warning_count" => 1,
        "errors" => [
          %{"path" => "$.plan_id", "message" => "is required", "severity" => "error"}
        ],
        "warnings" => [
          %{"path" => "$.score", "message" => "is low", "severity" => "warning"}
        ],
        "remediation_count" => 2,
        "remediation" => [
          remediation("$.plan_id", "missing_required_field", "Populate this required field"),
          remediation("$.score", "review_low_score", "Review the low score")
        ]
      })

    second_report =
      source_report(%{
        "status" => "pass",
        "error_count" => 0,
        "warning_count" => 1,
        "errors" => [],
        "warnings" => [
          %{"path" => "$.capacity", "message" => "is low", "severity" => "warning"}
        ],
        "remediation_count" => 1,
        "remediation" => [
          remediation("$.capacity", "review_low_capacity", "Review the low capacity")
        ]
      })
      |> Map.delete("artifact_path")

    "study_results/schema_validation_batch_report_v1.json"
    |> read_json!()
    |> Map.merge(%{
      "input_dir" => "source_artifacts",
      "file_count" => 2,
      "artifact_count" => 2,
      "skipped_count" => 0,
      "error_count" => 1,
      "warning_count" => 2,
      "remediation_count" => 3,
      "status" => "fail",
      "status_counts" => %{"fail" => 1, "pass" => 1},
      "skipped_artifacts" => [],
      "reports" => [
        %{"path" => "study_results/batch-entry-0.json", "report" => first_report},
        %{"path" => "study_results/batch-entry-1.json", "report" => second_report}
      ]
    })
  end

  defp source_report(overrides) do
    "study_results/schema_validation_report_v1.json"
    |> read_json!()
    |> Map.merge(overrides)
  end

  defp remediation(path, category, action) do
    %{
      "path" => path,
      "category" => category,
      "action" => action,
      "source_message" => "is low"
    }
  end

  defp schema_validation_review_index(repair) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &schema_validation_source?/1
    )
  end

  defp schema_validation_import_index(repair) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &schema_validation_source?/1
    )
  end

  defp row_evidence(row) do
    report = Map.get(row, "source_schema_validation_report", %{})

    {
      row_source(row),
      get_in(row, ["source_validation_issue", "path"]),
      get_in(row, ["source_validation_remediation", "category"]),
      Map.get(report, "artifact_path"),
      Map.get(report, "batch_entry_path")
    }
  end

  defp drop_optional_evidence(row) do
    if schema_validation_source?(row) do
      Map.drop(row, [
        "source_validation_issue",
        "source_validation_remediation",
        "source_schema_validation_report"
      ])
    else
      row
    end
  end

  defp schema_validation_source?(row) do
    case row_source(row) do
      source when is_binary(source) -> String.starts_with?(source, @repair_source_prefix)
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
