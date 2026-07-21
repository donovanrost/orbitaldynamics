defmodule OrbitalDynamics.Schema.CampaignPlanWarningContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CampaignPlanner, ResultSet, Schema}

  setup do
    artifact =
      "study_results/leo_constellation_campaign.json"
      |> read_json!()
      |> Map.fetch!("campaign_plan")

    %{artifact: artifact}
  end

  test "validates checked-in V1 warnings", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "validates direct generated warnings" do
    result_set =
      ResultSet.new!(%{
        study_id: :warning_test,
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

    assert length(artifact["warnings"]) == 4
    assert artifact["warnings"] == Enum.uniq(artifact["warnings"])
    assert Enum.all?(artifact["warnings"], &(String.trim(&1) != ""))

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "exports non-empty unique warning strings" do
    assert {:ok, schema} = Schema.json_schema("campaign_plan.v1")
    warnings = get_in(schema, ["properties", "warnings"])

    assert warnings["type"] == "array"
    assert warnings["uniqueItems"] == true
    assert warnings["items"] == %{"type" => "string", "minLength" => 1, "pattern" => "\\S"}
  end

  test "rejects non-string and blank warning entries", %{artifact: artifact} do
    invalid_cases = [
      {0, Map.put(artifact, "warnings", [%{}])},
      {0, Map.put(artifact, "warnings", [""])},
      {1, Map.put(artifact, "warnings", ["valid warning", "   "])}
    ]

    for {index, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == "$.warnings[#{index}]"))
    end
  end

  test "rejects duplicate warnings", %{artifact: artifact} do
    invalid = Map.put(artifact, "warnings", ["review contact", "review contact"])

    assert {:error, report} = Schema.validate_artifact(invalid)
    assert Enum.any?(report["errors"], &(&1["path"] == "$.warnings"))
  end

  test "handles a malformed warning collection without crashing", %{artifact: artifact} do
    invalid = Map.put(artifact, "warnings", %{})

    assert {:error, report} = Schema.validate_artifact(invalid)
    assert Enum.any?(report["errors"], &(&1["path"] == "$.warnings"))
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
