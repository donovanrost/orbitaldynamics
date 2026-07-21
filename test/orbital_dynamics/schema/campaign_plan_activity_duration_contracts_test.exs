defmodule OrbitalDynamics.Schema.CampaignPlanActivityDurationContractsTest do
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

  test "validates checked-in V1 activity durations", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "exports non-negative duration constraints on every V1 activity surface" do
    assert {:ok, schema} = Schema.json_schema("campaign_plan.v1")

    assert get_in(schema, [
             "properties",
             "activities",
             "items",
             "properties",
             "duration_s",
             "minimum"
           ]) == 0.0

    assert get_in(schema, [
             "properties",
             "candidate_activities",
             "items",
             "properties",
             "duration_s",
             "minimum"
           ]) == 0.0

    assert get_in(schema, [
             "properties",
             "ranked_timelines",
             "items",
             "properties",
             "activities",
             "items",
             "properties",
             "duration_s",
             "minimum"
           ]) == 0.0
  end

  test "requires duration on every V1 activity surface", %{artifact: artifact} do
    for {access, path} <- activity_surfaces() do
      invalid = update_in(artifact, access, &Map.delete(&1, "duration_s"))

      assert {:error, report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               report["errors"],
               &(&1["path"] == path and &1["message"] == "is required")
             )
    end
  end

  test "rejects malformed duration on every V1 activity surface", %{artifact: artifact} do
    for {access, path} <- activity_surfaces() do
      invalid = put_in(artifact, access ++ ["duration_s"], "300")

      assert {:error, report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               report["errors"],
               &(&1["path"] == path and &1["message"] == "must be a number")
             )
    end
  end

  test "rejects negative duration on every V1 activity surface", %{artifact: artifact} do
    for {access, path} <- activity_surfaces() do
      invalid = put_in(artifact, access ++ ["duration_s"], -1.0)

      assert {:error, report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               report["errors"],
               &(&1["path"] == path and &1["message"] == "must be non-negative")
             )

      refute Enum.any?(
               report["errors"],
               &(&1["path"] == path and
                   &1["message"] == "must equal ends_at_s - starts_at_s")
             )
    end
  end

  test "reconciles duration to the interval on every V1 activity surface", %{
    artifact: artifact
  } do
    for {access, path} <- activity_surfaces() do
      invalid = update_in(artifact, access ++ ["duration_s"], &(&1 + 1.0))

      assert {:error, report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               report["errors"],
               &(&1["path"] == path and
                   &1["message"] == "must equal ends_at_s - starts_at_s")
             )
    end
  end

  test "preserves zero-length interval compatibility", %{artifact: artifact} do
    artifact =
      artifact
      |> put_in(["candidate_activities", Access.at(0), "ends_at_s"], 0.0)
      |> put_in(["candidate_activities", Access.at(0), "duration_s"], 0.0)

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  defp activity_surfaces do
    [
      {["activities", Access.at(0)], "$.activities[0].duration_s"},
      {["candidate_activities", Access.at(0)], "$.candidate_activities[0].duration_s"},
      {[
         "ranked_timelines",
         Access.at(0),
         "activities",
         Access.at(0)
       ], "$.ranked_timelines[0].activities[0].duration_s"}
    ]
  end
end
