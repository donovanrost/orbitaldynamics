defmodule OrbitalDynamics.Schema.CampaignRepairCandidateRefreshRemainingHorizonContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  @source_field "source_candidate_refresh_remaining_horizon"

  setup do
    artifact = read_json!("study_results/leo_constellation_campaign_repair_v2.json")

    source_horizon = %{
      "starts_at_s" => 1_080.0,
      "ends_at_s" => 3_600.0,
      "output_step_s" => 60.0
    }

    %{artifact: Map.put(artifact, @source_field, source_horizon)}
  end

  test "validates schema-contract-free and tagged source horizons and keeps the field optional",
       %{
         artifact: artifact
       } do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             artifact
             |> update_in([@source_field], fn horizon ->
               Map.merge(horizon, %{
                 "schema_contract" => "remaining_horizon.v1",
                 "duration_s" => 2_520.0
               })
             end)
             |> Schema.validate_artifact()

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             artifact
             |> Map.delete(@source_field)
             |> Schema.validate_artifact()
  end

  test "rejects a non-map source horizon", %{artifact: artifact} do
    assert {:error, report} =
             artifact
             |> Map.put(@source_field, [])
             |> Schema.validate_artifact()

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.#{@source_field}" and String.contains?(&1["message"], "map"))
           )
  end

  test "rejects missing and invalid source timing at exact nested paths", %{artifact: artifact} do
    invalid_cases = [
      {Map.delete(artifact[@source_field], "starts_at_s"), ".starts_at_s"},
      {Map.put(artifact[@source_field], "ends_at_s", 1_000.0), ""},
      {Map.put(artifact[@source_field], "output_step_s", 0.0), ".output_step_s"},
      {Map.put(artifact[@source_field], "output_step_s", 3_000.0), ".output_step_s"},
      {Map.put(artifact[@source_field], "schema_contract", "unexpected.v1"), ".schema_contract"},
      {Map.put(artifact[@source_field], "duration_s", 2_500.0), ".duration_s"}
    ]

    Enum.each(invalid_cases, fn {source_horizon, path_suffix} ->
      assert {:error, report} =
               artifact
               |> Map.put(@source_field, source_horizon)
               |> Schema.validate_artifact()

      assert Enum.any?(
               report["errors"],
               &(&1["path"] == "$.#{@source_field}#{path_suffix}")
             )
    end)
  end

  test "exports the optional source horizon with typed sampling fields" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")
    source_horizon = get_in(schema, ["properties", @source_field])

    assert source_horizon["required"] == ["starts_at_s", "ends_at_s", "output_step_s"]
    assert get_in(source_horizon, ["properties", "starts_at_s", "type"]) == "number"
    assert get_in(source_horizon, ["properties", "ends_at_s", "type"]) == "number"

    assert get_in(source_horizon, ["properties", "output_step_s", "exclusiveMinimum"]) ==
             0

    assert get_in(source_horizon, ["properties", "schema_contract", "const"]) ==
             "remaining_horizon.v1"
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
