defmodule OrbitalDynamics.Schema.CampaignRepairProducedSurfaceContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  @produced_fields ~w(
    study_id
    source_planner
    change_summary
    preserved_activities
    approval_rule_matches
  )

  setup do
    %{
      repair: read_json!("study_results/leo_constellation_campaign_repair_v2.json"),
      readiness_repair:
        read_json!("study_results/campaign_repair_readiness_source_handoff_v2.json")
    }
  end

  test "validates the complete checked V2 produced surface", context do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")
    declared_fields = schema["properties"] |> Map.keys() |> MapSet.new()

    for artifact <- [context.repair, context.readiness_repair] do
      assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
               Schema.validate_artifact(artifact)

      assert artifact
             |> Map.keys()
             |> MapSet.new()
             |> MapSet.subset?(declared_fields)
    end
  end

  test "keeps produced-surface fields optional for older repairs", %{repair: repair} do
    artifact =
      repair
      |> Map.drop(@produced_fields)
      |> update_in(
        ["repair_metadata"],
        &Map.drop(&1, ["candidate_window_count", "repaired_activity_count"])
      )

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)
  end

  test "rejects produced-surface drift", context do
    approval_match = hd(context.repair["approval_rule_matches"])
    moved_activity = hd(context.readiness_repair["activities"])

    invalid_cases = [
      {"$.study_id", Map.put(context.repair, "study_id", "not a stable id")},
      {"$.source_planner", Map.put(context.repair, "source_planner", 2)},
      {"$.change_summary", put_in(context.repair, ["change_summary", "canceled"], 2)},
      {"$.change_summary.canceled", put_in(context.repair, ["change_summary", "canceled"], -1)},
      {"$.repair_metadata.source_plan_id",
       put_in(context.repair, ["repair_metadata", "source_plan_id"], "source:drift")},
      {"$.repair_metadata.delta_count",
       put_in(context.repair, ["repair_metadata", "delta_count"], 2)},
      {"$.repair_metadata.approval_required_count",
       put_in(context.repair, ["repair_metadata", "approval_required_count"], 2)},
      {"$.repair_metadata.candidate_window_count",
       put_in(context.repair, ["repair_metadata", "candidate_window_count"], 2)},
      {"$.repair_metadata.repaired_activity_count",
       put_in(context.repair, ["repair_metadata", "repaired_activity_count"], 2)},
      {"$.preserved_activities",
       Map.put(context.readiness_repair, "preserved_activities", [moved_activity])},
      {"$.approval_rule_matches[0].classification",
       put_in(
         context.repair,
         ["approval_rule_matches", Access.at(0)],
         Map.put(approval_match, "classification", "silently_approved")
       )},
      {"$.approval_rule_matches", Map.put(context.repair, "approval_rule_matches", %{})}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, validation_report} = Schema.validate_artifact(invalid)
      assert Enum.any?(validation_report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "exports every produced-surface field with its runtime type" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")

    assert get_in(schema, ["properties", "study_id", "type"]) == "string"
    assert get_in(schema, ["properties", "source_planner", "type"]) == "string"
    assert get_in(schema, ["properties", "change_summary", "type"]) == "object"
    assert get_in(schema, ["properties", "preserved_activities", "type"]) == "array"
    assert get_in(schema, ["properties", "approval_rule_matches", "type"]) == "array"
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
