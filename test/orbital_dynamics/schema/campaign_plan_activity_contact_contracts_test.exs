defmodule OrbitalDynamics.Schema.CampaignPlanActivityContactContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  @contact_activity_types ["downlink", "command", "tracking", "health_check"]

  setup do
    artifact =
      "study_results/leo_constellation_campaign.json"
      |> File.read!()
      |> :json.decode()
      |> Map.fetch!("campaign_plan")

    %{artifact: artifact}
  end

  test "exports conditional contact-family routing on every V1 activity surface" do
    assert {:ok, schema} = Schema.json_schema("campaign_plan.v1")

    expected =
      Enum.map(@contact_activity_types, fn type ->
        %{
          "if" => %{
            "required" => ["type"],
            "properties" => %{"type" => %{"const" => type}}
          },
          "then" => %{
            "required" => ["ground_station_id", "direction"],
            "properties" => %{"direction" => %{"const" => type}}
          }
        }
      end)

    for {schema_path, _artifact_path} <- activity_surfaces() do
      contact_constraints =
        schema
        |> get_in(schema_path ++ ["allOf"])
        |> Enum.filter(&(get_in(&1, ["then", "required"]) == ["ground_station_id", "direction"]))

      assert contact_constraints == expected
    end
  end

  test "requires station and direction for every contact family and V1 surface", %{
    artifact: artifact
  } do
    for type <- @contact_activity_types,
        {_schema_path, {access, path}} <- activity_surfaces(),
        field <- ["ground_station_id", "direction"] do
      invalid =
        update_in(artifact, access, fn activity ->
          activity
          |> contact_activity(type)
          |> Map.delete(field)
        end)

      assert {:error, report} = Schema.validate_artifact(invalid)
      assert error_path?(report, "#{path}.#{field}")
    end
  end

  test "reconciles direction with contact activity type on every V1 surface", %{
    artifact: artifact
  } do
    for type <- @contact_activity_types,
        {_schema_path, {access, path}} <- activity_surfaces() do
      mismatched_direction = if type == "downlink", do: "command", else: "downlink"

      invalid =
        update_in(artifact, access, fn activity ->
          activity
          |> contact_activity(type)
          |> Map.put("direction", mismatched_direction)
        end)

      assert {:error, report} = Schema.validate_artifact(invalid)
      assert error?(report, path <> ".direction", "must match activity type")
    end
  end

  test "retains one stable station remediation on every V1 contact surface", %{
    artifact: artifact
  } do
    for {_schema_path, {access, path}} <- activity_surfaces() do
      invalid =
        update_in(artifact, access, fn activity ->
          activity
          |> contact_activity("command")
          |> Map.put("ground_station_id", "bad id")
        end)

      assert {:error, report} = Schema.validate_artifact(invalid)

      station_errors =
        Enum.filter(report["errors"], &(&1["path"] == path <> ".ground_station_id"))

      assert [station_error] = station_errors
      assert String.starts_with?(station_error["message"], "must match stable ID pattern")
    end
  end

  test "retains single downlink presence remediation on every V1 surface", %{
    artifact: artifact
  } do
    for {_schema_path, {access, path}} <- activity_surfaces(),
        field <- ["ground_station_id", "direction"] do
      invalid =
        update_in(artifact, access, fn activity ->
          activity
          |> contact_activity("downlink")
          |> Map.delete(field)
        end)

      assert {:error, report} = Schema.validate_artifact(invalid)
      assert [_error] = Enum.filter(report["errors"], &(&1["path"] == "#{path}.#{field}"))
    end
  end

  test "retains single malformed downlink direction remediation on every V1 surface", %{
    artifact: artifact
  } do
    for {_schema_path, {access, path}} <- activity_surfaces(), direction <- ["broadcast", []] do
      invalid =
        update_in(artifact, access, fn activity ->
          activity
          |> contact_activity("downlink")
          |> Map.put("direction", direction)
        end)

      assert {:error, report} = Schema.validate_artifact(invalid)
      assert [_error] = Enum.filter(report["errors"], &(&1["path"] == path <> ".direction"))
    end
  end

  test "keeps non-contact activity vocabulary open", %{artifact: artifact} do
    artifact =
      update_in(
        artifact,
        ["candidate_activities", Access.at(0)],
        fn activity ->
          activity
          |> Map.put("type", "future_activity")
          |> Map.delete("ground_station_id")
          |> Map.delete("direction")
        end
      )

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  defp contact_activity(activity, type) do
    activity
    |> Map.put("type", type)
    |> Map.put("ground_station_id", "equator_prime")
    |> Map.put("direction", type)
  end

  defp error?(report, path, message) do
    Enum.any?(report["errors"], &(&1["path"] == path and &1["message"] == message))
  end

  defp error_path?(report, path) do
    Enum.any?(report["errors"], &(&1["path"] == path))
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
