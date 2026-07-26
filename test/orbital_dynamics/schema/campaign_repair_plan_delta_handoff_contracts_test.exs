defmodule OrbitalDynamics.Schema.CampaignRepairPlanDeltaHandoffContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  setup do
    %{
      repair: read_json!("study_results/leo_constellation_campaign_repair_v2.json"),
      readiness_repair:
        read_json!("study_results/campaign_repair_readiness_source_handoff_v2.json")
    }
  end

  test "validates checked Repair plan-delta review handoffs", context do
    for artifact <- [context.repair, context.readiness_repair] do
      assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
               Schema.validate_artifact(artifact)
    end
  end

  test "keeps additive plan-delta review handoffs optional", %{repair: repair} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             repair
             |> Map.drop(["operator_review_package", "cadence_import_manifest"])
             |> Schema.validate_artifact()

    review_index = plan_delta_review_index(repair)
    cadence_index = plan_delta_import_index(repair)

    older =
      repair
      |> update_in(
        ["operator_review_package", "rows", Access.at(review_index)],
        &Map.delete(&1, "source_delta")
      )
      |> update_in(
        ["cadence_import_manifest", "rows", Access.at(cadence_index)],
        &Map.delete(&1, "source_delta")
      )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(older)
  end

  test "rejects Repair plan-delta review handoff drift", %{repair: repair} do
    review_index = plan_delta_review_index(repair)
    cadence_index = plan_delta_import_index(repair)

    review_drift =
      update_in(
        repair,
        ["operator_review_package", "rows", Access.at(review_index)],
        fn row ->
          row
          |> Map.put("reason", "drifted delta reason")
          |> put_in(["source_delta", "reason"], "drifted delta reason")
        end
      )

    cadence_drift =
      update_in(
        repair,
        ["cadence_import_manifest", "rows", Access.at(cadence_index)],
        fn row ->
          row
          |> Map.put("reason", "drifted delta reason")
          |> put_in(["source_delta", "reason"], "drifted delta reason")
        end
      )

    invalid_cases = [
      {"$.operator_review_package.plan_delta_count",
       put_in(repair, ["operator_review_package", "plan_delta_count"], 2)},
      {"$.operator_review_package.rows[#{review_index}].source_delta", review_drift},
      {"$.cadence_import_manifest.rows[#{cadence_index}].source_delta", cadence_drift}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  defp plan_delta_review_index(repair) do
    Enum.find_index(
      get_in(repair, ["operator_review_package", "rows"]),
      &(Map.get(&1, "review_type") == "plan_delta_review")
    )
  end

  defp plan_delta_import_index(repair) do
    Enum.find_index(
      get_in(repair, ["cadence_import_manifest", "rows"]),
      &(Map.get(&1, "source_review_type") == "plan_delta_review")
    )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
