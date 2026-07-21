defmodule OrbitalDynamics.Schema.CampaignPlanActivityCadenceSchemaContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema
  alias OrbitalDynamics.Schema.CampaignPlanActivityCadenceSchemaContracts

  setup do
    artifact =
      "study_results/leo_constellation_campaign.json"
      |> File.read!()
      |> :json.decode()
      |> Map.fetch!("campaign_plan")

    %{artifact: artifact}
  end

  test "exports contact import schema on every V1 activity surface" do
    assert {:ok, schema} = Schema.json_schema("campaign_plan.v1")

    expected =
      Enum.map(CampaignPlanActivityCadenceSchemaContracts.activity_type_mappings(), fn
        {activity_type, schema_contract} ->
          %{
            "if" => %{
              "required" => ["type"],
              "properties" => %{"type" => %{"const" => activity_type}}
            },
            "then" => %{
              "properties" => %{
                "cadence_import" => %{
                  "required" => ["schema_contract"],
                  "properties" => %{"schema_contract" => %{"const" => schema_contract}}
                }
              }
            }
          }
      end)

    for {schema_path, _artifact_path} <- activity_surfaces() do
      schema_contract_constraints =
        schema
        |> get_in(schema_path ++ ["allOf"])
        |> Enum.filter(
          &get_in(&1, [
            "then",
            "properties",
            "cadence_import",
            "properties",
            "schema_contract"
          ])
        )

      assert schema_contract_constraints == expected
    end
  end

  test "requires contact import schema on every current contact surface", %{artifact: artifact} do
    for {activity_type, _schema_contract} <-
          CampaignPlanActivityCadenceSchemaContracts.activity_type_mappings(),
        {_schema_path, {access, path}} <- activity_surfaces() do
      invalid =
        update_in(artifact, access, fn activity ->
          activity
          |> contact_activity(activity_type)
          |> update_in(["cadence_import"], &Map.delete(&1, "schema_contract"))
        end)

      assert {:error, report} = Schema.validate_artifact(invalid)

      assert [
               %{
                 "message" => "is required"
               }
             ] = schema_contract_errors(report, path)
    end
  end

  test "rejects malformed or stale contact import schema without cascade", %{
    artifact: artifact
  } do
    for {activity_type, expected_contract} <-
          CampaignPlanActivityCadenceSchemaContracts.activity_type_mappings(),
        {_schema_path, {access, path}} <- activity_surfaces(),
        {value, message} <- [
          {[], "must be a string"},
          {"  ", "must be a non-empty string"},
          {"planned_activity.v1",
           "must equal #{inspect(expected_contract)} for #{activity_type} activity"}
        ] do
      invalid =
        update_in(artifact, access, fn activity ->
          activity
          |> contact_activity(activity_type)
          |> put_in(["cadence_import", "schema_contract"], value)
        end)

      assert {:error, report} = Schema.validate_artifact(invalid)
      assert [%{"message" => ^message}] = schema_contract_errors(report, path)
    end
  end

  test "keeps observation and future import schema optional", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)

    future =
      update_in(
        artifact,
        ["candidate_activities", Access.at(0)],
        fn activity ->
          activity
          |> Map.put("type", "future_activity")
          |> put_in(["cadence_import", "activity_type"], "future_dispatch")
          |> update_in(["cadence_import"], &Map.delete(&1, "schema_contract"))
          |> update_in(["source_window"], &Map.delete(&1, "type"))
        end
      )
      |> Map.put("proposed_contacts", [])

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(future)
  end

  defp contact_activity(activity, type) do
    activity
    |> Map.put("type", type)
    |> Map.put("ground_station_id", "equator_prime")
    |> Map.put("direction", type)
    |> put_in(["source_window", "type"], "ground_station_access")
    |> put_in(["cadence_import", "activity_type"], cadence_activity_type(type))
    |> put_in(["cadence_import", "schema_contract"], "proposed_contact.v1")
  end

  defp cadence_activity_type("command"), do: "command"
  defp cadence_activity_type(_type), do: "contact"

  defp schema_contract_errors(report, path) do
    Enum.filter(
      report["errors"],
      &(&1["path"] == path <> ".cadence_import.schema_contract")
    )
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
