defmodule OrbitalDynamics.Schema.CampaignPlanTargetCommitmentContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  setup do
    artifact =
      "study_results/leo_constellation_campaign.json"
      |> read_json!()
      |> Map.fetch!("campaign_plan")

    %{artifact: artifact}
  end

  test "validates checked-in V1 target commitments", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "keeps target commitments optional", %{artifact: artifact} do
    artifact = Map.delete(artifact, "target_commitments")

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "exports typed inline target commitment rows" do
    assert {:ok, schema} = Schema.json_schema("campaign_plan.v1")
    item = get_in(schema, ["properties", "target_commitments", "items"])

    assert item["type"] == "object"

    assert item["required"] == [
             "target_id",
             "candidate_activity_count",
             "candidate_duration_s",
             "selected_activity_count",
             "selected_duration_s",
             "selected_activity_ids",
             "status"
           ]

    assert get_in(item, ["properties", "candidate_activity_count", "minimum"]) == 0
    assert get_in(item, ["properties", "candidate_duration_s", "minimum"]) == 0.0
    assert get_in(item, ["properties", "priority", "type"]) == ["number", "string"]
    assert get_in(item, ["properties", "selected_activity_ids", "uniqueItems"]) == true

    assert get_in(item, ["properties", "status", "enum"]) == [
             "selected",
             "candidate_available",
             "no_candidate_window"
           ]
  end

  test "rejects invalid target commitment row fields", %{artifact: artifact} do
    invalid_cases = [
      {"$.target_commitments[0].priority",
       put_in(artifact, ["target_commitments", Access.at(0), "priority"], %{})},
      {"$.target_commitments[0].candidate_activity_count",
       put_in(artifact, ["target_commitments", Access.at(0), "candidate_activity_count"], -1)},
      {"$.target_commitments[0].candidate_duration_s",
       put_in(artifact, ["target_commitments", Access.at(0), "candidate_duration_s"], -1.0)},
      {"$.target_commitments[0].selected_activity_ids[0]",
       put_in(
         artifact,
         ["target_commitments", Access.at(0), "selected_activity_ids"],
         ["invalid activity"]
       )},
      {"$.target_commitments[0].status",
       put_in(artifact, ["target_commitments", Access.at(0), "status"], "legacy")}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects stale candidate and selected activity evidence", %{artifact: artifact} do
    invalid_cases = [
      {"$.target_commitments[0].candidate_activity_count",
       update_in(
         artifact,
         ["target_commitments", Access.at(0), "candidate_activity_count"],
         &(&1 + 1)
       )},
      {"$.target_commitments[0].candidate_duration_s",
       update_in(
         artifact,
         ["target_commitments", Access.at(0), "candidate_duration_s"],
         &(&1 + 1.0)
       )},
      {"$.target_commitments[0].selected_activity_count",
       put_in(artifact, ["target_commitments", Access.at(0), "selected_activity_count"], 0)},
      {"$.target_commitments[0].selected_duration_s",
       update_in(
         artifact,
         ["target_commitments", Access.at(0), "selected_duration_s"],
         &(&1 + 1.0)
       )},
      {"$.target_commitments[0].selected_activity_ids",
       put_in(artifact, ["target_commitments", Access.at(0), "selected_activity_ids"], [])},
      {"$.target_commitments[0].status",
       put_in(
         artifact,
         ["target_commitments", Access.at(0), "status"],
         "candidate_available"
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects duplicate or incomplete target rows", %{artifact: artifact} do
    [first | _rest] = artifact["target_commitments"]

    duplicate =
      update_in(artifact, ["target_commitments"], &(&1 ++ [first]))

    incomplete =
      update_in(artifact, ["target_commitments"], &Enum.take(&1, 1))

    assert {:error, duplicate_report} = Schema.validate_artifact(duplicate)
    assert Enum.any?(duplicate_report["errors"], &(&1["path"] == "$.target_commitments"))

    assert {:error, incomplete_report} = Schema.validate_artifact(incomplete)
    assert Enum.any?(incomplete_report["errors"], &(&1["path"] == "$.target_commitments"))
  end

  test "rejects malformed commitment list and row shapes without crashing", %{artifact: artifact} do
    invalid_list = Map.put(artifact, "target_commitments", %{})
    invalid_row = Map.put(artifact, "target_commitments", ["not-a-row"])

    assert {:error, list_shape} = Schema.validate_artifact(invalid_list)
    assert Enum.any?(list_shape["errors"], &(&1["path"] == "$.target_commitments"))

    assert {:error, row_shape} = Schema.validate_artifact(invalid_row)
    assert Enum.any?(row_shape["errors"], &(&1["path"] == "$.target_commitments[0]"))
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
