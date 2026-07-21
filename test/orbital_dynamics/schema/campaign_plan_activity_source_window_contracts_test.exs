defmodule OrbitalDynamics.Schema.CampaignPlanActivitySourceWindowContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema
  alias OrbitalDynamics.Schema.CampaignPlanActivitySourceWindowTypeContracts

  setup do
    artifact =
      "study_results/leo_constellation_campaign.json"
      |> File.read!()
      |> :json.decode()
      |> Map.fetch!("campaign_plan")

    %{artifact: artifact}
  end

  test "exports required nested source-window identity on every V1 activity surface" do
    assert {:ok, schema} = Schema.json_schema("campaign_plan.v1")

    for {schema_path, _artifact_path} <- activity_surfaces() do
      activity_schema = get_in(schema, schema_path)

      assert "source_window_id" in activity_schema["required"]
      assert "source_window" in activity_schema["required"]
      assert get_in(activity_schema, ["properties", "source_window", "required"]) == ["id"]
    end
  end

  test "exports current source-window type mappings on every V1 activity surface" do
    assert {:ok, schema} = Schema.json_schema("campaign_plan.v1")

    expected =
      Enum.map(CampaignPlanActivitySourceWindowTypeContracts.activity_type_mappings(), fn
        {activity_type, source_window_type} ->
          %{
            "if" => %{
              "required" => ["type"],
              "properties" => %{"type" => %{"const" => activity_type}}
            },
            "then" => %{
              "properties" => %{
                "source_window" => %{
                  "required" => ["type"],
                  "properties" => %{"type" => %{"const" => source_window_type}}
                }
              }
            }
          }
      end)

    for {schema_path, _artifact_path} <- activity_surfaces() do
      source_window_constraints =
        schema
        |> get_in(schema_path ++ ["allOf"])
        |> Enum.filter(&get_in(&1, ["then", "properties", "source_window"]))

      assert source_window_constraints == expected
    end
  end

  test "requires source-window ID on every V1 activity surface", %{artifact: artifact} do
    for {_schema_path, {access, path}} <- activity_surfaces() do
      invalid = update_in(artifact, access, &Map.delete(&1, "source_window_id"))

      assert {:error, report} = Schema.validate_artifact(invalid)
      assert error?(report, path <> ".source_window_id", "is required")
    end
  end

  test "requires source-window object on every V1 activity surface", %{artifact: artifact} do
    for {_schema_path, {access, path}} <- activity_surfaces() do
      invalid = update_in(artifact, access, &Map.delete(&1, "source_window"))

      assert {:error, report} = Schema.validate_artifact(invalid)
      assert error?(report, path <> ".source_window", "is required")
    end
  end

  test "rejects malformed source-window objects on every V1 activity surface", %{
    artifact: artifact
  } do
    for {_schema_path, {access, path}} <- activity_surfaces() do
      invalid = put_in(artifact, access ++ ["source_window"], [])

      assert {:error, report} = Schema.validate_artifact(invalid)
      assert error?(report, path <> ".source_window", "must be a map")
    end
  end

  test "requires stable nested source-window ID on every V1 activity surface", %{
    artifact: artifact
  } do
    for {_schema_path, {access, path}} <- activity_surfaces() do
      missing = update_in(artifact, access ++ ["source_window"], &Map.delete(&1, "id"))
      assert {:error, missing_report} = Schema.validate_artifact(missing)
      assert error?(missing_report, path <> ".source_window.id", "is required")

      unstable = put_in(artifact, access ++ ["source_window", "id"], "bad id")
      assert {:error, unstable_report} = Schema.validate_artifact(unstable)

      assert Enum.any?(
               unstable_report["errors"],
               &(&1["path"] == path <> ".source_window.id" and
                   String.starts_with?(&1["message"], "must match stable ID pattern"))
             )

      refute error?(
               unstable_report,
               path <> ".source_window.id",
               "must match source_window_id"
             )

      unstable_outer = put_in(artifact, access ++ ["source_window_id"], "bad id")
      assert {:error, unstable_outer_report} = Schema.validate_artifact(unstable_outer)

      assert Enum.any?(
               unstable_outer_report["errors"],
               &(&1["path"] == path <> ".source_window_id" and
                   String.starts_with?(&1["message"], "must match stable ID pattern"))
             )

      refute error?(
               unstable_outer_report,
               path <> ".source_window.id",
               "must match source_window_id"
             )
    end
  end

  test "reconciles nested source-window identity on every V1 activity surface", %{
    artifact: artifact
  } do
    for {_schema_path, {access, path}} <- activity_surfaces() do
      invalid = put_in(artifact, access ++ ["source_window", "id"], "different_window")

      assert {:error, report} = Schema.validate_artifact(invalid)
      assert error?(report, path <> ".source_window.id", "must match source_window_id")
    end
  end

  test "requires current source-window type on every V1 activity surface", %{
    artifact: artifact
  } do
    for {activity_type, _source_window_type} <-
          CampaignPlanActivitySourceWindowTypeContracts.activity_type_mappings(),
        {_schema_path, {access, path}} <- activity_surfaces() do
      invalid =
        update_in(artifact, access, fn activity ->
          activity
          |> activity_with_type(activity_type)
          |> update_in(["source_window"], &Map.delete(&1, "type"))
        end)

      assert {:error, report} = Schema.validate_artifact(invalid)

      source_window_type_path = path <> ".source_window.type"

      assert [
               %{
                 "path" => ^source_window_type_path,
                 "message" => "is required"
               }
             ] = Enum.filter(report["errors"], &(&1["path"] == source_window_type_path))
    end
  end

  test "rejects malformed current source-window type without cascade", %{artifact: artifact} do
    for {activity_type, _source_window_type} <-
          CampaignPlanActivitySourceWindowTypeContracts.activity_type_mappings(),
        {_schema_path, {access, path}} <- activity_surfaces(),
        {value, message} <- [
          {[], "must be a string"},
          {"  ", "must be a non-empty string"}
        ] do
      invalid =
        update_in(artifact, access, fn activity ->
          activity
          |> activity_with_type(activity_type)
          |> put_in(["source_window", "type"], value)
        end)

      assert {:error, report} = Schema.validate_artifact(invalid)

      assert [%{"message" => ^message}] =
               Enum.filter(report["errors"], &(&1["path"] == path <> ".source_window.type"))
    end
  end

  test "reconciles current source-window families on every V1 activity surface", %{
    artifact: artifact
  } do
    for {activity_type, expected_source_window_type} <-
          CampaignPlanActivitySourceWindowTypeContracts.activity_type_mappings(),
        {_schema_path, {access, path}} <- activity_surfaces() do
      invalid =
        update_in(artifact, access, fn activity ->
          activity
          |> activity_with_type(activity_type)
          |> put_in(
            ["source_window", "type"],
            wrong_source_window_type(expected_source_window_type)
          )
        end)

      assert {:error, report} = Schema.validate_artifact(invalid)

      assert error?(
               report,
               path <> ".source_window.type",
               "must equal #{inspect(expected_source_window_type)} for #{activity_type} activity"
             )
    end
  end

  test "keeps future source-window families open", %{artifact: artifact} do
    artifact =
      update_in(
        artifact,
        ["candidate_activities", Access.at(0)],
        fn activity ->
          activity
          |> Map.put("type", "future_activity")
          |> put_in(["cadence_import", "activity_type"], "future_dispatch")
          |> update_in(["source_window"], &Map.delete(&1, "type"))
        end
      )

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "retains downlink source-window shape validation", %{artifact: artifact} do
    invalid =
      update_in(
        artifact,
        ["candidate_activities", Access.at(0)],
        &Map.delete(&1, "source_window")
      )

    assert {:error, report} = Schema.validate_artifact(invalid)
    assert error?(report, "$.candidate_activities[0].source_window", "must be a map")
  end

  defp error?(report, path, message) do
    Enum.any?(report["errors"], &(&1["path"] == path and &1["message"] == message))
  end

  defp activity_with_type(activity, type) do
    source_window_type =
      CampaignPlanActivitySourceWindowTypeContracts.activity_type_mappings()
      |> List.keyfind(type, 0)
      |> elem(1)

    activity
    |> Map.put("type", type)
    |> put_in(["source_window", "type"], source_window_type)
    |> put_in(["cadence_import", "activity_type"], cadence_activity_type(type))
    |> maybe_add_contact_fields(type)
  end

  defp maybe_add_contact_fields(activity, "observe"), do: activity

  defp maybe_add_contact_fields(activity, type) do
    activity
    |> Map.put("ground_station_id", "equator_prime")
    |> Map.put("direction", type)
  end

  defp cadence_activity_type("observe"), do: "observation"
  defp cadence_activity_type("command"), do: "command"
  defp cadence_activity_type(_type), do: "contact"

  defp wrong_source_window_type("target_visibility"), do: "ground_station_access"
  defp wrong_source_window_type("ground_station_access"), do: "target_visibility"

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
       ], {["candidate_activities", Access.at(1)], "$.candidate_activities[1]"}},
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
