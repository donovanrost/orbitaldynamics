defmodule OrbitalDynamics.Schema.CampaignPlanIdentityContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema.CampaignPlanIdentityContracts
  alias OrbitalDynamics.{CampaignPlanner, ResultSet, Schema}

  setup do
    artifact =
      "study_results/leo_constellation_campaign.json"
      |> read_json!()
      |> Map.fetch!("campaign_plan")

    %{artifact: artifact}
  end

  test "validates the checked-in V1 plan identity", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "validates a directly generated V1 plan identity" do
    result_set =
      ResultSet.new!(%{
        study_id: :identity_test,
        trajectory_results: [],
        event_results: [],
        errors: [],
        assumptions: %{},
        metadata: %{}
      })

    artifact =
      CampaignPlanner.build(result_set,
        generated_at: ~U[2026-07-20 12:34:56Z],
        campaign: %{}
      )

    assert artifact["plan_id"] == "campaign_plan:identity_test:2026-07-20T12:34:56Z"

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "exports generated_at as a date-time string" do
    assert {:ok, schema} = Schema.json_schema("campaign_plan.v1")

    assert get_in(schema, ["properties", "generated_at"]) == %{
             "type" => "string",
             "format" => "date-time"
           }
  end

  test "rejects non-string and malformed generation times", %{artifact: artifact} do
    invalid_cases = [
      Map.put(artifact, "generated_at", 1_774_000_000),
      Map.put(artifact, "generated_at", "2026-07-20")
    ]

    for invalid <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == "$.generated_at"))
    end
  end

  test "rejects a stale plan ID", %{artifact: artifact} do
    invalid = Map.put(artifact, "plan_id", "campaign_plan:stale:2026-05-14T00:00:00Z")

    assert {:error, report} = Schema.validate_artifact(invalid)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.plan_id" and
                 &1["message"] == "must equal campaign_plan:<study_id>:<generated_at>")
           )
  end

  test "rejects a study identity that no longer matches the plan ID", %{artifact: artifact} do
    invalid = Map.put(artifact, "study_id", "replacement_study")

    assert {:error, report} = Schema.validate_artifact(invalid)
    assert Enum.any?(report["errors"], &(&1["path"] == "$.plan_id"))
  end

  test "handles malformed identity fields without crashing", %{artifact: artifact} do
    invalid =
      artifact
      |> Map.put("generated_at", %{})
      |> Map.put("plan_id", [])

    assert {:error, report} = Schema.validate_artifact(invalid)
    paths = Enum.map(report["errors"], & &1["path"])

    assert "$.generated_at" in paths
    assert "$.plan_id" in paths
  end

  test "rejects duplicate ranked timeline scenario identities" do
    issues =
      CampaignPlanIdentityContracts.validate([], %{
        "ranked_timelines" => [
          %{"scenario_id" => "leo_1", "activities" => []},
          %{"scenario_id" => "leo_1", "activities" => []}
        ]
      })

    assert %{
             "path" => "$.ranked_timelines[1].scenario_id",
             "message" => "must be unique across ranked timelines",
             "severity" => "error"
           } in issues
  end

  test "reconciles activity scenario identity with its enclosing ranked timeline" do
    issues =
      CampaignPlanIdentityContracts.validate([], %{
        "ranked_timelines" => [
          %{
            "scenario_id" => "leo_2",
            "activities" => [%{"scenario_id" => "leo_1"}]
          }
        ]
      })

    assert %{
             "path" => "$.ranked_timelines[0].activities[0].scenario_id",
             "message" => "must match enclosing ranked timeline scenario_id",
             "severity" => "error"
           } in issues
  end

  test "rejects synchronized activity ownership drift through artifact validation", %{
    artifact: artifact
  } do
    rewrite_scenarios = fn activities ->
      Enum.map(activities, &Map.put(&1, "scenario_id", "leo_2"))
    end

    invalid =
      artifact
      |> Map.update!("activities", rewrite_scenarios)
      |> Map.update!("candidate_activities", rewrite_scenarios)
      |> update_in(
        ["ranked_timelines", Access.at(0), "activities"],
        rewrite_scenarios
      )

    assert {:error, report} = Schema.validate_artifact(invalid)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.ranked_timelines[0].activities[0].scenario_id" and
                 &1["message"] == "must match enclosing ranked timeline scenario_id")
           )
  end

  test "accepts unique empty timelines and aligned activity scenarios" do
    issues =
      CampaignPlanIdentityContracts.validate([], %{
        "ranked_timelines" => [
          %{"scenario_id" => "leo_1", "activities" => [%{"scenario_id" => "leo_1"}]},
          %{"scenario_id" => "leo_2", "activities" => []}
        ]
      })

    assert issues == []
  end

  test "leaves malformed scenario fields to field-level validators" do
    issues =
      CampaignPlanIdentityContracts.validate([], %{
        "ranked_timelines" => [
          %{"scenario_id" => "bad id", "activities" => [%{"scenario_id" => "leo_1"}]},
          %{"scenario_id" => "leo_2", "activities" => [%{"scenario_id" => []}]}
        ]
      })

    assert issues == []
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
