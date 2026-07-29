defmodule OrbitalDynamics.Schema.CampaignRepairApprovalRequirementActivityContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  setup do
    %{
      cancellation_repair: read_json!("study_results/leo_constellation_campaign_repair_v2.json"),
      selected_activity_repair:
        read_json!("study_results/campaign_repair_readiness_source_handoff_v2.json")
    }
  end

  test "validates selected-activity and cancellation approval relationships", context do
    for artifact <- [context.selected_activity_repair, context.cancellation_repair] do
      assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
               Schema.validate_artifact(artifact)
    end
  end

  test "keeps additive approval activity contexts optional", %{
    selected_activity_repair: repair
  } do
    older =
      repair
      |> update_in(
        ["approval_requirements", Access.at(0)],
        &Map.delete(&1, "activity_context")
      )
      |> drop_approval_handoffs()

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(older)
  end

  test "keeps additive approval requirement types optional", context do
    for artifact <- [context.selected_activity_repair, context.cancellation_repair] do
      older =
        artifact
        |> update_in(
          ["approval_requirements", Access.at(0)],
          &Map.delete(&1, "requirement_type")
        )
        |> drop_approval_handoffs()

      assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
               Schema.validate_artifact(older)
    end
  end

  test "rejects selected Repair approval activity context drift", %{
    selected_activity_repair: repair
  } do
    invalid =
      repair
      |> put_in(
        ["approval_requirements", Access.at(0), "activity_context", "duration_s"],
        61
      )
      |> drop_approval_handoffs()

    assert {:error, report} = Schema.validate_artifact(invalid)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.approval_requirements[0].activity_context")
           )
  end

  test "rejects Repair approval root and context activity identity drift", %{
    cancellation_repair: cancellation,
    selected_activity_repair: selected
  } do
    invalid_cases = [
      {"$.approval_requirements[0].activity_id",
       put_in(
         cancellation,
         ["approval_requirements", Access.at(0), "activity_id"],
         "drifted_activity"
       )},
      {"$.approval_requirements[0].activity_type",
       put_in(
         selected,
         ["approval_requirements", Access.at(0), "activity_type"],
         "observe"
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} =
               invalid
               |> drop_approval_handoffs()
               |> Schema.validate_artifact()

      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects Repair approval requirement-type derivation drift", context do
    for artifact <- [context.selected_activity_repair, context.cancellation_repair] do
      invalid =
        artifact
        |> put_in(
          ["approval_requirements", Access.at(0), "requirement_type"],
          "operator_review"
        )
        |> drop_approval_handoffs()

      assert {:error, report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               report["errors"],
               &(&1["path"] == "$.approval_requirements[0].requirement_type")
             )
    end
  end

  defp drop_approval_handoffs(repair) do
    Map.drop(repair, ["operator_review_package", "cadence_import_manifest"])
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
