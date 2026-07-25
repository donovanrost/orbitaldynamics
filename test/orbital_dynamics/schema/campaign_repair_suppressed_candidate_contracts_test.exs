defmodule OrbitalDynamics.Schema.CampaignRepairSuppressedCandidateContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  @eligible_field "source_candidate_activities"
  @suppressed_field "source_suppressed_candidate_activities"

  setup do
    artifact = read_json!("study_results/leo_constellation_campaign_repair_v2.json")
    eligible_candidate = read_json!("study_results/candidate_activity_v1.json")

    suppressed_window_id = "window:leo_1:target_visibility:target_a:2"

    suppressed_candidate =
      eligible_candidate
      |> Map.put("id", "leo_1_observe_target_a_2")
      |> Map.put("source_window_id", suppressed_window_id)
      |> put_in(["source_window", "id"], suppressed_window_id)

    artifact =
      artifact
      |> Map.put(@eligible_field, [eligible_candidate])
      |> Map.put(@suppressed_field, [suppressed_candidate])
      |> put_in(["repair_metadata", "candidate_source", "candidate_count"], 2)

    %{
      artifact: artifact,
      eligible_candidate: eligible_candidate,
      suppressed_candidate: suppressed_candidate
    }
  end

  test "validates the eligible and suppressed CandidateRefresh partition", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             artifact
             |> Map.delete(@suppressed_field)
             |> Schema.validate_artifact()
  end

  test "rejects malformed and inconsistent partition collections", %{
    artifact: artifact,
    eligible_candidate: eligible_candidate,
    suppressed_candidate: suppressed_candidate
  } do
    invalid_shape = Map.put(artifact, @suppressed_field, %{})
    assert_error_path(invalid_shape, "$.#{@suppressed_field}")

    empty_collection = Map.put(artifact, @suppressed_field, [])
    assert_error_path(empty_collection, "$.#{@suppressed_field}")

    duplicate_suppressed =
      artifact
      |> Map.put(@suppressed_field, [suppressed_candidate, suppressed_candidate])
      |> put_in(["repair_metadata", "candidate_source", "candidate_count"], 3)

    assert_error_path(duplicate_suppressed, "$.#{@suppressed_field}")

    overlapping_partition = Map.put(artifact, @suppressed_field, [eligible_candidate])
    assert_error_path(overlapping_partition, "$.#{@suppressed_field}")

    stale_source_count =
      put_in(artifact, ["repair_metadata", "candidate_source", "candidate_count"], 3)

    assert_error_path(
      stale_source_count,
      "$.repair_metadata.candidate_source.candidate_count"
    )
  end

  test "rejects malformed suppressed candidates at the exact indexed path", %{artifact: artifact} do
    invalid =
      put_in(
        artifact,
        [@suppressed_field, Access.at(0), "source_window_id"],
        "window:leo_1:target_visibility:target_a:stale"
      )

    assert_error_path(invalid, "$.#{@suppressed_field}[0].source_window_id")
  end

  test "reuses the CandidateActivity schema for both repair candidate collections" do
    assert {:ok, repair_schema} = Schema.json_schema("campaign_repair.v2")

    assert repair_schema["properties"][@suppressed_field] ==
             repair_schema["properties"][@eligible_field]

    assert get_in(repair_schema, [
             "properties",
             @suppressed_field,
             "items",
             "properties",
             "id",
             "pattern"
           ]) ==
             Schema.identity_policy()["stable_id_pattern"]
  end

  defp assert_error_path(artifact, path) do
    assert {:error, report} = Schema.validate_artifact(artifact)
    assert Enum.any?(report["errors"], &(&1["path"] == path))
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
