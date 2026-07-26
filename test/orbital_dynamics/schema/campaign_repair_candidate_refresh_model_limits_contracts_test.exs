defmodule OrbitalDynamics.Schema.CampaignRepairCandidateRefreshModelLimitsContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  @source_field "source_candidate_refresh_model_limits"

  setup do
    artifact = read_json!("study_results/leo_constellation_campaign_repair_v2.json")

    %{
      artifact: Map.put(artifact, @source_field, OrbitalDynamics.CandidateRefresh.model_limits())
    }
  end

  test "validates the exact source limits and keeps the field optional", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             artifact
             |> Map.delete(@source_field)
             |> Schema.validate_artifact()
  end

  test "rejects a non-list source limit field", %{artifact: artifact} do
    assert {:error, report} =
             artifact
             |> Map.put(@source_field, %{})
             |> Schema.validate_artifact()

    assert Enum.any?(report["errors"], fn error ->
             error["path"] == "$.#{@source_field}" and
               String.contains?(error["message"], "list")
           end)
  end

  test "rejects stale or reordered source limits at the exact path", %{artifact: artifact} do
    invalid_limits = [
      ["stale_candidate_refresh_limit"],
      Enum.reverse(OrbitalDynamics.CandidateRefresh.model_limits())
    ]

    Enum.each(invalid_limits, fn model_limits ->
      assert {:error, report} =
               artifact
               |> Map.put(@source_field, model_limits)
               |> Schema.validate_artifact()

      assert Enum.any?(
               report["errors"],
               &(&1["path"] == "$.#{@source_field}" and
                   &1["message"] == "must match candidate refresh model limits")
             )
    end)
  end

  test "exports the same exact list schema as CandidateRefresh" do
    assert {:ok, repair_schema} = Schema.json_schema("campaign_repair.v2")
    assert {:ok, refresh_schema} = Schema.json_schema("candidate_refresh.v1")

    assert get_in(repair_schema, ["properties", @source_field]) ==
             get_in(refresh_schema, ["properties", "model_limits"])
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
