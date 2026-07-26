defmodule OrbitalDynamics.Schema.CampaignRepairRefreshedWindowsSourceContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  @source_field "source_refreshed_windows"

  setup do
    artifact = read_json!("study_results/leo_constellation_campaign_repair_v2.json")

    source_windows =
      "study_results/candidate_refresh_v1.json"
      |> read_json!()
      |> get_in(["candidate_refresh", "refreshed_windows"])

    %{artifact: Map.put(artifact, @source_field, source_windows)}
  end

  test "validates every raw CandidateRefresh window at the Repair V2 source path", %{
    artifact: artifact
  } do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             artifact
             |> Map.delete(@source_field)
             |> Schema.validate_artifact()
  end

  test "rejects indexed sample-coverage drift", %{artifact: artifact} do
    invalid =
      put_in(
        artifact,
        [@source_field, "access_windows", Access.at(0), "sample_count"],
        0
      )

    assert {:error, report} = Schema.validate_artifact(invalid)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.#{@source_field}.access_windows[0].sample_count" and
                 String.contains?(&1["message"], "must cover window duration"))
           )
  end

  test "rejects malformed collection and top-level shapes", %{artifact: artifact} do
    invalid_collection = put_in(artifact, [@source_field, "access_windows"], %{})

    assert {:error, collection_report} = Schema.validate_artifact(invalid_collection)

    assert Enum.any?(
             collection_report["errors"],
             &(&1["path"] == "$.#{@source_field}.access_windows")
           )

    invalid_shape = Map.put(artifact, @source_field, [])

    assert {:error, shape_report} = Schema.validate_artifact(invalid_shape)
    assert Enum.any?(shape_report["errors"], &(&1["path"] == "$.#{@source_field}"))
  end

  test "exports the optional raw refreshed-window source property" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")
    assert get_in(schema, ["properties", @source_field, "type"]) == "object"

    assert {:ok, refreshed_window_schema} = Schema.json_schema("refreshed_window.v1")
    assert get_in(refreshed_window_schema, ["properties", "sample_count", "type"]) == "integer"
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
