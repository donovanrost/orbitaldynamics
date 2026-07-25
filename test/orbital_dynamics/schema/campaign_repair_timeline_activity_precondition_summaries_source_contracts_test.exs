defmodule OrbitalDynamics.Schema.CampaignRepairTimelineActivityPreconditionSummariesSourceContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  @source_field "source_timeline_activity_precondition_summaries"

  setup do
    artifact = read_json!("study_results/leo_constellation_campaign_repair_v2.json")
    source_summary = read_json!("study_results/timeline_activity_precondition_summary_v1.json")

    %{artifact: Map.put(artifact, @source_field, [source_summary])}
  end

  test "validates every optional V2 source activity-precondition summary", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    assert Enum.all?(artifact[@source_field], fn summary ->
             match?(
               {:ok, %{"schema_contract" => "timeline_activity_precondition_summary.v1"}},
               Schema.validate_artifact(summary)
             )
           end)

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             artifact
             |> Map.delete(@source_field)
             |> Schema.validate_artifact()
  end

  test "rejects indexed source activity-precondition drift at the distinct V2 path", %{
    artifact: artifact
  } do
    invalid_count =
      put_in(artifact, [@source_field, Access.at(0), "blocked_precondition_count"], 999)

    assert {:error, count_report} = Schema.validate_artifact(invalid_count)

    assert Enum.any?(
             count_report["errors"],
             &(&1["path"] == "$.#{@source_field}[0].blocked_precondition_count")
           )

    invalid_shape = Map.put(artifact, @source_field, %{})

    assert {:error, shape_report} = Schema.validate_artifact(invalid_shape)
    assert Enum.any?(shape_report["errors"], &(&1["path"] == "$.#{@source_field}"))
  end

  test "exports the plural source activity-precondition property" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")
    assert get_in(schema, ["properties", @source_field, "type"]) == "array"

    assert get_in(schema, ["$defs", "timeline_activity_precondition_summary.v1", "type"]) ==
             "object"
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
