defmodule OrbitalDynamics.Schema.CampaignRepairRealizedFeedbackHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CadenceImport, OperatorReview, Schema, TimelineFeedback}

  @repair_feedback_source "campaign_repair.source_timeline_feedback_report.rows"

  setup do
    %{
      repair: read_json!("study_results/leo_constellation_campaign_repair_v2.json"),
      readiness_repair:
        read_json!("study_results/campaign_repair_readiness_source_handoff_v2.json")
    }
  end

  test "validates checked Repair realized-feedback review handoffs", context do
    for artifact <- [context.repair, context.readiness_repair] do
      assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
               Schema.validate_artifact(artifact)
    end
  end

  test "keeps additive realized-feedback review handoffs optional", %{repair: repair} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    review_index = feedback_review_index(repair)
    cadence_index = feedback_import_index(repair)

    older =
      repair
      |> update_in(
        ["operator_review_package", "rows", Access.at(review_index)],
        &Map.delete(&1, "source_feedback")
      )
      |> update_in(
        ["cadence_import_manifest", "rows", Access.at(cadence_index)],
        fn row ->
          row
          |> Map.delete("source_feedback")
          |> update_in(["source_review_row"], &Map.delete(&1, "source_feedback"))
        end
      )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(older)
  end

  test "does not require review handoffs for planned-only feedback rows", %{repair: repair} do
    planned_only_report =
      repair["activities"]
      |> TimelineFeedback.reconcile([])
      |> Map.put("source", "campaign_repair.realized_state_snapshot.activities")

    compatible = Map.put(repair, "source_timeline_feedback_report", planned_only_report)
    review_package = OperatorReview.from_repair_artifact(compatible)

    compatible =
      compatible
      |> Map.put("operator_review_package", review_package)
      |> then(&Map.put(&1, "cadence_import_manifest", CadenceImport.from_repair_artifact(&1)))

    assert Enum.all?(planned_only_report["rows"], &(&1["status"] == "planned_only"))

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(compatible)
  end

  test "rejects Repair realized-feedback review handoff drift", %{repair: repair} do
    review_index = feedback_review_index(repair)
    cadence_index = feedback_import_index(repair)

    review_count_drift =
      put_in(
        repair,
        ["operator_review_package", "rows", Access.at(review_index), "source"],
        "campaign_repair.timeline_feedback_report.rows"
      )

    cadence_count_drift =
      update_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(cadence_index)],
        fn row ->
          row
          |> Map.put("source", "campaign_repair.timeline_feedback_report.rows")
          |> put_in(
            ["source_review_row", "source"],
            "campaign_repair.timeline_feedback_report.rows"
          )
        end
      )

    cadence_nested_source_drift =
      put_in(
        repair,
        [
          "cadence_import_manifest",
          "rows",
          Access.at(cadence_index),
          "source_review_row",
          "source"
        ],
        "campaign_repair.timeline_feedback_report.rows"
      )

    review_copy_drift =
      update_in(
        repair,
        ["operator_review_package", "rows", Access.at(review_index), "source_feedback"],
        &Map.put(&1, "reason", "drifted feedback reason")
      )

    cadence_copy_drift =
      update_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(cadence_index)],
        fn row ->
          row
          |> update_in(["source_feedback"], &Map.put(&1, "reason", "drifted feedback reason"))
          |> update_in(
            ["source_review_row", "source_feedback"],
            &Map.put(&1, "reason", "drifted feedback reason")
          )
        end
      )

    invalid_cases = [
      {"$.operator_review_package.rows", review_count_drift},
      {"$.cadence_import_manifest.rows", cadence_count_drift},
      {"$.cadence_import_manifest.rows[#{cadence_index}].source_review_row.source",
       cadence_nested_source_drift},
      {"$.operator_review_package.rows[#{review_index}].source_feedback", review_copy_drift},
      {"$.cadence_import_manifest.rows[#{cadence_index}].source_feedback", cadence_copy_drift},
      {"$.cadence_import_manifest.rows[#{cadence_index}].source_review_row.source_feedback",
       cadence_copy_drift}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  defp feedback_review_index(repair) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &(Map.get(&1, "review_type") == "realized_feedback" and
          Map.get(&1, "source") == @repair_feedback_source)
    )
  end

  defp feedback_import_index(repair) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &(Map.get(&1, "source_review_type") == "realized_feedback" and
          Map.get(&1, "source") == @repair_feedback_source)
    )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
