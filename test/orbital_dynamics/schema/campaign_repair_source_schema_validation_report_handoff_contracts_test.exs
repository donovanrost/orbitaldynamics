Code.require_file("../campaign_planner/support.exs", __DIR__)

defmodule OrbitalDynamics.Schema.CampaignRepairSourceSchemaValidationReportHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.TestSupport
  alias OrbitalDynamics.Schema

  @repair_source_prefix "campaign_repair.source_schema_validation_report"

  setup_all do
    source_report = source_report()

    candidate_refresh =
      "study_results/candidate_refresh_v1.json"
      |> read_json!()
      |> put_in(["candidate_refresh", "source_schema_validation_report"], source_report)

    repair =
      TestSupport.repair(
        %{"activities" => [], "candidate_activities" => []},
        realized_state: %{activities: []},
        current_epoch_s: 0.0,
        candidate_refresh: candidate_refresh
      )

    %{repair: repair, source_report: source_report}
  end

  test "validates Repair source schema-validation-report handoffs in producer order", %{
    repair: repair,
    source_report: source_report
  } do
    assert {:ok, %{"schema_version" => 2}} = Schema.validate_artifact(repair)

    expected = [
      {@repair_source_prefix <> ".errors", "$.plan_id", "missing_required_field"},
      {@repair_source_prefix <> ".warnings", "$.score", "review_low_score"}
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

    assert repair
           |> get_in(["operator_review_package", "rows"])
           |> Enum.filter(&schema_validation_source?/1)
           |> Enum.all?(&(&1["source_schema_validation_report"] == source_report))

    assert repair
           |> get_in(["cadence_import_manifest", "rows"])
           |> Enum.filter(&schema_validation_source?/1)
           |> Enum.all?(fn row ->
             row["source_schema_validation_report"] == source_report and
               get_in(row, ["source_review_row", "source_schema_validation_report"]) ==
                 source_report
           end)
  end

  test "keeps additive source schema-validation-report handoffs optional", %{repair: repair} do
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

  test "rejects Repair source schema-validation-report handoff drift", %{
    repair: repair
  } do
    review_index = schema_validation_review_index(repair)
    import_index = schema_validation_import_index(repair)
    wrong_source = @repair_source_prefix

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

    eligibility_drift =
      repair
      |> put_in(["source_schema_validation_report", "warnings"], [])
      |> put_in(["source_schema_validation_report", "warning_count"], 0)

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
      {"$.operator_review_package.rows", eligibility_drift},
      {"$.cadence_import_manifest.rows", eligibility_drift}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  defp source_report do
    "study_results/schema_validation_report_v1.json"
    |> read_json!()
    |> Map.merge(%{
      "status" => "fail",
      "artifact_path" => "study_results/bad_campaign.json",
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
        %{
          "path" => "$.plan_id",
          "category" => "missing_required_field",
          "action" => "Populate this required field",
          "source_message" => "is required"
        },
        %{
          "path" => "$.score",
          "category" => "review_low_score",
          "action" => "Review the low score",
          "source_message" => "is low"
        }
      ]
    })
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
    {
      row_source(row),
      get_in(row, ["source_validation_issue", "path"]),
      get_in(row, ["source_validation_remediation", "category"])
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
