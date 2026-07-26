defmodule OrbitalDynamics.Schema.CampaignRepairCandidateRejectionHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  @repair_rejection_source "campaign_repair.source_candidate_rejection_report.rows"

  setup do
    %{
      repair: read_json!("study_results/leo_constellation_campaign_repair_v2.json"),
      readiness_repair:
        read_json!("study_results/campaign_repair_readiness_source_handoff_v2.json")
    }
  end

  test "validates checked Repair candidate-rejection review handoffs", context do
    for artifact <- [context.repair, context.readiness_repair] do
      assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
               Schema.validate_artifact(artifact)
    end
  end

  test "keeps additive candidate-rejection review handoffs optional", %{repair: repair} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    review_index = rejection_review_index(repair)
    cadence_index = rejection_import_index(repair)

    older =
      repair
      |> update_in(
        ["operator_review_package", "rows", Access.at(review_index)],
        &Map.delete(&1, "source_candidate_rejection")
      )
      |> update_in(
        ["cadence_import_manifest", "rows", Access.at(cadence_index)],
        fn row ->
          row
          |> Map.delete("source_candidate_rejection")
          |> update_in(["source_review_row"], &Map.delete(&1, "source_candidate_rejection"))
        end
      )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(older)
  end

  test "rejects Repair candidate-rejection review handoff drift", %{repair: repair} do
    review_index = rejection_review_index(repair)
    cadence_index = rejection_import_index(repair)

    review_count_drift =
      put_in(
        repair,
        ["operator_review_package", "rows", Access.at(review_index), "source"],
        "campaign_repair.other_candidate_rejection_report.rows"
      )

    cadence_count_drift =
      repair
      |> put_in(
        ["cadence_import_manifest", "rows", Access.at(cadence_index), "source"],
        "campaign_repair.other_candidate_rejection_report.rows"
      )
      |> put_in(
        [
          "cadence_import_manifest",
          "rows",
          Access.at(cadence_index),
          "source_review_row",
          "source"
        ],
        "campaign_repair.other_candidate_rejection_report.rows"
      )

    review_copy_drift =
      update_in(
        repair,
        ["operator_review_package", "rows", Access.at(review_index)],
        &drift_rejection_row/1
      )

    cadence_copy_drift =
      update_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(cadence_index)],
        fn row ->
          row
          |> drift_rejection_row()
          |> update_in(["source_review_row"], &drift_rejection_row/1)
        end
      )

    invalid_cases = [
      {"$.operator_review_package.rows", review_count_drift},
      {"$.cadence_import_manifest.rows", cadence_count_drift},
      {"$.operator_review_package.rows[#{review_index}].source_candidate_rejection",
       review_copy_drift},
      {"$.cadence_import_manifest.rows[#{cadence_index}].source_candidate_rejection",
       cadence_copy_drift},
      {"$.cadence_import_manifest.rows[#{cadence_index}].source_review_row.source_candidate_rejection",
       cadence_copy_drift}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  defp drift_rejection_row(row) do
    row
    |> Map.put("primary_rejection_reason", "drifted_reason")
    |> put_in(["source_candidate_rejection", "primary_rejection_reason"], "drifted_reason")
  end

  defp rejection_review_index(repair) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &(Map.get(&1, "review_type") == "candidate_rejection_review" and
          Map.get(&1, "source") == @repair_rejection_source)
    )
  end

  defp rejection_import_index(repair) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &(Map.get(&1, "source_review_type") == "candidate_rejection_review" and
          Map.get(&1, "source") == @repair_rejection_source)
    )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
