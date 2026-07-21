defmodule OrbitalDynamics.Schema.CampaignPlanActivityTypeContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  setup do
    artifact =
      "study_results/leo_constellation_campaign.json"
      |> File.read!()
      |> :json.decode()
      |> Map.fetch!("campaign_plan")

    %{artifact: artifact}
  end

  test "exports nonblank type constraints without freezing the vocabulary" do
    assert {:ok, schema} = Schema.json_schema("campaign_plan.v1")

    for {schema_path, _artifact_path} <- activity_surfaces() do
      type_schema = get_in(schema, schema_path ++ ["properties", "type"])

      assert type_schema == %{
               "type" => "string",
               "minLength" => 1,
               "pattern" => "\\S"
             }

      refute Map.has_key?(type_schema, "enum")
    end
  end

  test "requires type on every V1 activity surface", %{artifact: artifact} do
    for {_schema_path, {access, path}} <- activity_surfaces() do
      invalid = update_in(artifact, access, &Map.delete(&1, "type"))

      assert {:error, report} = Schema.validate_artifact(invalid)
      assert error?(report, path <> ".type", "is required")
    end
  end

  test "rejects non-string type on every V1 activity surface", %{artifact: artifact} do
    for {_schema_path, {access, path}} <- activity_surfaces() do
      invalid = put_in(artifact, access ++ ["type"], [])

      assert {:error, report} = Schema.validate_artifact(invalid)
      assert error?(report, path <> ".type", "must be a string")
    end
  end

  test "rejects blank type on every V1 activity surface", %{artifact: artifact} do
    for {_schema_path, {access, path}} <- activity_surfaces(), value <- ["", "  "] do
      invalid = put_in(artifact, access ++ ["type"], value)

      assert {:error, report} = Schema.validate_artifact(invalid)
      assert error?(report, path <> ".type", "must be a non-empty string")
    end
  end

  test "keeps nonblank future activity tokens compatible", %{artifact: artifact} do
    artifact =
      put_in(
        artifact,
        ["candidate_activities", Access.at(0), "type"],
        "future_activity"
      )

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  defp error?(report, path, message) do
    Enum.any?(report["errors"], &(&1["path"] == path and &1["message"] == message))
  end

  defp activity_surfaces do
    [
      {[
         "properties",
         "activities",
         "items"
       ], {["activities", Access.at(0)], "$.activities[0]"}},
      {[
         "properties",
         "candidate_activities",
         "items"
       ], {["candidate_activities", Access.at(0)], "$.candidate_activities[0]"}},
      {[
         "properties",
         "ranked_timelines",
         "items",
         "properties",
         "activities",
         "items"
       ],
       {[
          "ranked_timelines",
          Access.at(0),
          "activities",
          Access.at(0)
        ], "$.ranked_timelines[0].activities[0]"}}
    ]
  end
end
