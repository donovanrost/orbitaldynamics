defmodule OrbitalDynamics.Schema.CampaignRepairCandidateRefreshOperationalFeedbackContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  @source_field "source_candidate_refresh_operational_feedback"

  setup do
    artifact = read_json!("study_results/leo_constellation_campaign_repair_v2.json")

    feedback = %{
      "station_throughput_factor" => %{"equator_prime" => 0.5},
      "downlink_demand_mb" => %{"leo_1" => 120.0},
      "image_quality_status" => %{"target_a" => "accepted"},
      "resource_margin_overrides" => %{"leo_1" => %{"battery_margin_wh" => 40.0}},
      "extra_feedback_family" => %{"source" => "future_adapter"}
    }

    %{artifact: Map.put(artifact, @source_field, feedback)}
  end

  test "validates populated and empty source feedback and keeps the field optional", %{
    artifact: artifact
  } do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             artifact
             |> Map.put(@source_field, %{})
             |> Schema.validate_artifact()

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             artifact
             |> Map.delete(@source_field)
             |> Schema.validate_artifact()
  end

  test "rejects a non-map source feedback value at the source field", %{artifact: artifact} do
    assert {:error, report} =
             artifact
             |> Map.put(@source_field, [])
             |> Schema.validate_artifact()

    assert Enum.any?(report["errors"], fn error ->
             error["path"] == "$.#{@source_field}" and
               String.contains?(error["message"], "object")
           end)
  end

  test "rejects invalid known feedback families at exact nested source paths", %{
    artifact: artifact
  } do
    invalid_cases = [
      {put_in(artifact[@source_field], ["station_throughput_factor", "equator_prime"], 1.2),
       ".station_throughput_factor.equator_prime"},
      {put_in(artifact[@source_field], ["downlink_demand_mb", "leo_1"], -1.0),
       ".downlink_demand_mb.leo_1"},
      {put_in(artifact[@source_field], ["image_quality_status", "target_a"], 5),
       ".image_quality_status.target_a"},
      {put_in(artifact[@source_field], ["resource_margin_overrides", "leo_1"], []),
       ".resource_margin_overrides.leo_1"}
    ]

    Enum.each(invalid_cases, fn {feedback, path_suffix} ->
      assert {:error, report} =
               artifact
               |> Map.put(@source_field, feedback)
               |> Schema.validate_artifact()

      assert Enum.any?(
               report["errors"],
               &(&1["path"] == "$.#{@source_field}#{path_suffix}")
             )
    end)
  end

  test "exports the detailed optional CandidateRefresh feedback schema" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")
    feedback = get_in(schema, ["properties", @source_field])

    assert feedback["type"] == "object"
    assert feedback["additionalProperties"] == true

    assert get_in(feedback, ["properties", "station_throughput_factor", "type"]) ==
             "object"

    assert get_in(feedback, [
             "properties",
             "station_throughput_factor",
             "additionalProperties",
             "maximum"
           ]) ==
             1

    assert get_in(feedback, [
             "properties",
             "downlink_demand_mb",
             "additionalProperties",
             "minimum"
           ]) ==
             0

    assert get_in(feedback, ["properties", "realized_activities", "items", "type"]) ==
             "object"
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
