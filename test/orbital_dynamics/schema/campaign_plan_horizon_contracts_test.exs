defmodule OrbitalDynamics.Schema.CampaignPlanHorizonContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  setup do
    artifact =
      "study_results/leo_constellation_campaign.json"
      |> read_json!()
      |> Map.fetch!("campaign_plan")

    %{artifact: artifact}
  end

  test "validates the checked-in V1 planning horizon", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "exports typed positive fields for a declared planning horizon" do
    assert {:ok, schema} = Schema.json_schema("campaign_plan.v1")
    horizon = get_in(schema, ["properties", "planning_horizon"])

    assert horizon["type"] == "object"
    assert horizon["dependentRequired"] == %{"output_step_s" => ["duration_s"]}
    assert get_in(horizon, ["properties", "duration_s", "type"]) == "number"
    assert get_in(horizon, ["properties", "duration_s", "exclusiveMinimum"]) == 0.0
    assert get_in(horizon, ["properties", "output_step_s", "type"]) == "number"
    assert get_in(horizon, ["properties", "output_step_s", "exclusiveMinimum"]) == 0.0
  end

  test "validates declared duration and output cadence as positive numbers", %{
    artifact: artifact
  } do
    invalid_cases = [
      {"$.planning_horizon.duration_s",
       put_in(artifact, ["planning_horizon", "duration_s"], "3600")},
      {"$.planning_horizon.duration_s", put_in(artifact, ["planning_horizon", "duration_s"], 0)},
      {"$.planning_horizon.output_step_s",
       put_in(artifact, ["planning_horizon", "output_step_s"], "60")},
      {"$.planning_horizon.output_step_s",
       put_in(artifact, ["planning_horizon", "output_step_s"], -1)}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "accepts omitted horizon fields for direct planner artifacts", %{artifact: artifact} do
    empty_horizon = Map.put(artifact, "planning_horizon", %{})

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(empty_horizon)
  end

  test "requires duration when output cadence is declared", %{artifact: artifact} do
    without_duration =
      update_in(artifact, ["planning_horizon"], &Map.delete(&1, "duration_s"))

    assert {:error, report} = Schema.validate_artifact(without_duration)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.planning_horizon.duration_s" and
                 &1["message"] == "is required when output_step_s is present")
           )
  end

  test "rejects output cadence beyond the horizon", %{artifact: artifact} do
    invalid = put_in(artifact, ["planning_horizon", "output_step_s"], 3601)

    assert {:error, report} = Schema.validate_artifact(invalid)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.planning_horizon.output_step_s" and
                 &1["message"] == "must not exceed horizon duration")
           )
  end

  test "rejects negative starts across core schedule surfaces", %{artifact: artifact} do
    invalid_cases = [
      {"$.activities[0].starts_at_s",
       put_in(artifact, ["activities", Access.at(0), "starts_at_s"], -1)},
      {"$.candidate_activities[0].starts_at_s",
       put_in(artifact, ["candidate_activities", Access.at(0), "starts_at_s"], -1)},
      {"$.proposed_contacts[0].starts_at_s",
       put_in(artifact, ["proposed_contacts", Access.at(0), "starts_at_s"], -1)},
      {"$.contact_intents[0].starts_at_s",
       put_in(artifact, ["contact_intents", Access.at(0), "starts_at_s"], -1)},
      {"$.ranked_timelines[0].activities[0].starts_at_s",
       put_in(
         artifact,
         ["ranked_timelines", Access.at(0), "activities", Access.at(0), "starts_at_s"],
         -1
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects ends beyond the horizon across core schedule surfaces", %{artifact: artifact} do
    invalid_cases = [
      {"$.activities[0].ends_at_s",
       put_in(artifact, ["activities", Access.at(0), "ends_at_s"], 3601)},
      {"$.candidate_activities[0].ends_at_s",
       put_in(artifact, ["candidate_activities", Access.at(0), "ends_at_s"], 3601)},
      {"$.proposed_contacts[0].ends_at_s",
       put_in(artifact, ["proposed_contacts", Access.at(0), "ends_at_s"], 3601)},
      {"$.contact_intents[0].ends_at_s",
       put_in(artifact, ["contact_intents", Access.at(0), "ends_at_s"], 3601)},
      {"$.ranked_timelines[0].activities[0].ends_at_s",
       put_in(
         artifact,
         ["ranked_timelines", Access.at(0), "activities", Access.at(0), "ends_at_s"],
         3601
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "handles malformed horizon and schedule rows without crashing", %{artifact: artifact} do
    malformed_horizon = Map.put(artifact, "planning_horizon", [])
    malformed_row = Map.put(artifact, "activities", ["not-a-row"])

    assert {:error, horizon_report} = Schema.validate_artifact(malformed_horizon)
    assert Enum.any?(horizon_report["errors"], &(&1["path"] == "$.planning_horizon"))

    assert {:error, row_report} = Schema.validate_artifact(malformed_row)
    assert Enum.any?(row_report["errors"], &(&1["path"] == "$.activities[0]"))
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
