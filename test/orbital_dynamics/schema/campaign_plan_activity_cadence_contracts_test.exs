defmodule OrbitalDynamics.Schema.CampaignPlanActivityCadenceContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema
  alias OrbitalDynamics.Schema.CampaignPlanActivityCadenceContracts

  setup do
    artifact =
      "study_results/leo_constellation_campaign.json"
      |> File.read!()
      |> :json.decode()
      |> Map.fetch!("campaign_plan")

    %{artifact: artifact}
  end

  test "exports required typed Cadence identity on every V1 activity surface" do
    assert {:ok, schema} = Schema.json_schema("campaign_plan.v1")

    for {schema_path, _artifact_path} <- activity_surfaces() do
      activity_schema = get_in(schema, schema_path)
      cadence_schema = get_in(activity_schema, ["properties", "cadence_import"])

      assert "cadence_import" in activity_schema["required"]
      assert cadence_schema["required"] == ["external_id", "activity_type"]

      assert get_in(cadence_schema, ["properties", "external_id", "pattern"]) ==
               Schema.identity_policy()["stable_id_pattern"]

      assert get_in(cadence_schema, ["properties", "activity_type"]) == %{
               "type" => "string",
               "minLength" => 1,
               "pattern" => "\\S"
             }
    end
  end

  test "exports current Cadence dispatch mappings on every V1 activity surface" do
    assert {:ok, schema} = Schema.json_schema("campaign_plan.v1")

    expected =
      Enum.map(CampaignPlanActivityCadenceContracts.activity_type_mappings(), fn
        {activity_type, cadence_type} ->
          %{
            "if" => %{
              "required" => ["type"],
              "properties" => %{"type" => %{"const" => activity_type}}
            },
            "then" => %{
              "properties" => %{
                "cadence_import" => %{
                  "properties" => %{"activity_type" => %{"const" => cadence_type}}
                }
              }
            }
          }
      end)

    for {schema_path, _artifact_path} <- activity_surfaces() do
      cadence_constraints =
        schema
        |> get_in(schema_path ++ ["allOf"])
        |> Enum.filter(
          &get_in(&1, [
            "then",
            "properties",
            "cadence_import",
            "properties",
            "activity_type"
          ])
        )

      assert cadence_constraints == expected
    end
  end

  test "requires Cadence envelope on every V1 activity surface", %{artifact: artifact} do
    for {_schema_path, {access, path}} <- activity_surfaces() do
      invalid = update_in(artifact, access, &Map.delete(&1, "cadence_import"))

      assert {:error, report} = Schema.validate_artifact(invalid)
      assert error?(report, path <> ".cadence_import", "is required")
    end
  end

  test "rejects malformed Cadence envelope on every V1 activity surface", %{
    artifact: artifact
  } do
    for {_schema_path, {access, path}} <- activity_surfaces() do
      invalid = put_in(artifact, access ++ ["cadence_import"], [])

      assert {:error, report} = Schema.validate_artifact(invalid)
      assert error?(report, path <> ".cadence_import", "must be a map")
    end
  end

  test "requires nested Cadence identity fields on every V1 activity surface", %{
    artifact: artifact
  } do
    for {_schema_path, {access, path}} <- activity_surfaces(),
        field <- ["external_id", "activity_type"] do
      invalid = update_in(artifact, access ++ ["cadence_import"], &Map.delete(&1, field))

      assert {:error, report} = Schema.validate_artifact(invalid)
      assert error?(report, "#{path}.cadence_import.#{field}", "is required")
    end
  end

  test "requires stable external ID on every V1 activity surface", %{artifact: artifact} do
    for {_schema_path, {access, path}} <- activity_surfaces() do
      invalid = put_in(artifact, access ++ ["cadence_import", "external_id"], "bad id")

      assert {:error, report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               report["errors"],
               &(&1["path"] == path <> ".cadence_import.external_id" and
                   String.starts_with?(&1["message"], "must match stable ID pattern"))
             )

      refute error?(
               report,
               path <> ".cadence_import.external_id",
               "must match activity id"
             )
    end
  end

  test "requires nonblank Cadence activity type on every V1 activity surface", %{
    artifact: artifact
  } do
    for {_schema_path, {access, path}} <- activity_surfaces() do
      non_string = put_in(artifact, access ++ ["cadence_import", "activity_type"], [])
      assert {:error, non_string_report} = Schema.validate_artifact(non_string)

      assert error?(
               non_string_report,
               path <> ".cadence_import.activity_type",
               "must be a string"
             )

      assert [_error] =
               Enum.filter(
                 non_string_report["errors"],
                 &(&1["path"] == path <> ".cadence_import.activity_type")
               )

      blank = put_in(artifact, access ++ ["cadence_import", "activity_type"], "  ")
      assert {:error, blank_report} = Schema.validate_artifact(blank)

      assert error?(
               blank_report,
               path <> ".cadence_import.activity_type",
               "must be a non-empty string"
             )

      assert [_error] =
               Enum.filter(
                 blank_report["errors"],
                 &(&1["path"] == path <> ".cadence_import.activity_type")
               )
    end
  end

  test "reconciles current Cadence dispatch types on every V1 activity surface", %{
    artifact: artifact
  } do
    for {activity_type, expected_cadence_type} <-
          CampaignPlanActivityCadenceContracts.activity_type_mappings(),
        {_schema_path, {access, path}} <- activity_surfaces() do
      invalid =
        update_in(artifact, access, fn activity ->
          activity
          |> activity_with_type(activity_type)
          |> put_in(["cadence_import", "activity_type"], wrong_type(expected_cadence_type))
        end)

      assert {:error, report} = Schema.validate_artifact(invalid)

      assert error?(
               report,
               path <> ".cadence_import.activity_type",
               "must equal #{inspect(expected_cadence_type)} for #{activity_type} activity"
             )
    end
  end

  test "keeps future Cadence dispatch mappings open", %{artifact: artifact} do
    artifact =
      update_in(
        artifact,
        ["candidate_activities", Access.at(0)],
        fn activity ->
          activity
          |> Map.put("type", "future_activity")
          |> put_in(["cadence_import", "activity_type"], "future_dispatch")
        end
      )
      |> Map.put("proposed_contacts", [])
      |> Map.put("contact_intents", [])

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "reconciles external ID on every V1 activity surface", %{artifact: artifact} do
    for {_schema_path, {access, path}} <- activity_surfaces() do
      invalid = put_in(artifact, access ++ ["cadence_import", "external_id"], "other_activity")

      assert {:error, report} = Schema.validate_artifact(invalid)
      assert error?(report, path <> ".cadence_import.external_id", "must match activity id")
    end
  end

  test "retains single downlink Cadence shape remediation", %{artifact: artifact} do
    for invalid <- [
          update_in(
            artifact,
            ["candidate_activities", Access.at(0)],
            &Map.delete(&1, "cadence_import")
          ),
          put_in(artifact, ["candidate_activities", Access.at(0), "cadence_import"], [])
        ] do
      assert {:error, report} = Schema.validate_artifact(invalid)

      cadence_errors =
        Enum.filter(
          report["errors"],
          &String.starts_with?(&1["path"], "$.candidate_activities[0].cadence_import")
        )

      assert cadence_errors == [
               %{
                 "severity" => "error",
                 "path" => "$.candidate_activities[0].cadence_import",
                 "message" => "must be a map"
               }
             ]
    end
  end

  defp error?(report, path, message) do
    Enum.any?(report["errors"], &(&1["path"] == path and &1["message"] == message))
  end

  defp activity_with_type(activity, type)
       when type in ["downlink", "command", "tracking", "health_check"] do
    activity
    |> Map.put("type", type)
    |> Map.put("ground_station_id", "equator_prime")
    |> Map.put("direction", type)
  end

  defp activity_with_type(activity, type), do: Map.put(activity, "type", type)

  defp wrong_type("observation"), do: "contact"
  defp wrong_type("contact"), do: "command"
  defp wrong_type("command"), do: "observation"

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
