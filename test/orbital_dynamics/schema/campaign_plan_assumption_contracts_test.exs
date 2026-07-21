defmodule OrbitalDynamics.Schema.CampaignPlanAssumptionContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CampaignPlanner, ResultSet, Schema}

  @fixed_fields %{
    "activity_builder" => "windows_to_observe_and_downlink_candidates",
    "timeline_selector" => "per_spacecraft_greedy_non_overlapping",
    "resource_filter" => "resource_summary_availability_and_margin_filter",
    "contact_filter" => "ground_network_availability_filter_before_ranking",
    "cadence_integration" => "artifact_only_no_api_or_database_writes"
  }

  @required_fields Map.keys(@fixed_fields) ++ ["constraints", "scoring_policy"]

  setup do
    artifact =
      "study_results/leo_constellation_campaign.json"
      |> read_json!()
      |> Map.fetch!("campaign_plan")

    %{artifact: artifact}
  end

  test "validates checked-in V1 assumptions", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "validates direct generated V1 assumptions" do
    result_set =
      ResultSet.new!(%{
        study_id: :assumption_test,
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

    assert Map.take(artifact["assumptions"], Map.keys(@fixed_fields)) == @fixed_fields

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "exports required typed V1 assumptions" do
    assert {:ok, schema} = Schema.json_schema("campaign_plan.v1")
    assumptions = get_in(schema, ["properties", "assumptions"])

    assert assumptions["type"] == "object"
    assert MapSet.new(assumptions["required"]) == MapSet.new(@required_fields)

    for {field, expected} <- @fixed_fields do
      assert get_in(assumptions, ["properties", field]) == %{
               "type" => "string",
               "const" => expected
             }
    end

    assert get_in(assumptions, ["properties", "constraints", "type"]) == "object"
    assert get_in(assumptions, ["properties", "scoring_policy", "type"]) == "object"
  end

  test "rejects missing assumption fields", %{artifact: artifact} do
    for field <- @required_fields do
      invalid = update_in(artifact, ["assumptions"], &Map.delete(&1, field))

      assert {:error, report} = Schema.validate_artifact(invalid)

      assert Enum.count(report["errors"], &(&1["path"] == "$.assumptions.#{field}")) == 1
    end
  end

  test "rejects stale fixed assumption values", %{artifact: artifact} do
    for field <- Map.keys(@fixed_fields) do
      invalid = put_in(artifact, ["assumptions", field], "legacy_model")

      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == "$.assumptions.#{field}"))
    end
  end

  test "rejects malformed constraint and scoring policy assumptions", %{artifact: artifact} do
    invalid_cases = [
      {"constraints", put_in(artifact, ["assumptions", "constraints"], [])},
      {"scoring_policy", put_in(artifact, ["assumptions", "scoring_policy"], [])}
    ]

    for {field, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == "$.assumptions.#{field}"))
    end
  end

  test "handles a malformed assumption object without crashing", %{artifact: artifact} do
    invalid = Map.put(artifact, "assumptions", [])

    assert {:error, report} = Schema.validate_artifact(invalid)
    assert Enum.any?(report["errors"], &(&1["path"] == "$.assumptions"))
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
