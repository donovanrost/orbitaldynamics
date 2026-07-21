defmodule OrbitalDynamics.Schema.CampaignPlanProvenanceContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{CampaignPlanner, ResultSet, Schema}

  @required_fields ["run_id", "manifest", "git_revision", "propagator", "propagator_opts"]

  setup do
    artifact =
      "study_results/leo_constellation_campaign.json"
      |> read_json!()
      |> Map.fetch!("campaign_plan")

    %{artifact: artifact}
  end

  test "validates checked-in file-backed V1 provenance", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "validates nullable direct-plan provenance" do
    result_set =
      ResultSet.new!(%{
        study_id: :provenance_test,
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

    assert Map.take(artifact["provenance"], @required_fields) ==
             Map.new(@required_fields, &{&1, nil})

    assert {:ok, %{"schema_contract" => "campaign_plan.v1"}} =
             Schema.validate_artifact(artifact)
  end

  test "exports required nullable V1 provenance fields" do
    assert {:ok, schema} = Schema.json_schema("campaign_plan.v1")
    provenance = get_in(schema, ["properties", "provenance"])

    assert provenance["type"] == "object"
    assert provenance["required"] == @required_fields

    for field <- ["run_id", "git_revision", "propagator"] do
      assert get_in(provenance, ["properties", field, "type"]) == ["string", "null"]
      assert get_in(provenance, ["properties", field, "minLength"]) == 1
    end

    assert get_in(provenance, ["properties", "manifest", "type"]) == ["object", "null"]

    assert get_in(provenance, ["properties", "manifest", "properties", "sha256", "pattern"]) ==
             "^[0-9a-f]{64}$"

    assert get_in(provenance, ["properties", "propagator_opts", "type"]) == [
             "object",
             "null"
           ]
  end

  test "rejects missing provenance fields", %{artifact: artifact} do
    for field <- @required_fields do
      invalid = update_in(artifact, ["provenance"], &Map.delete(&1, field))

      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.count(report["errors"], &(&1["path"] == "$.provenance.#{field}")) == 1
    end
  end

  test "rejects malformed non-null provenance values", %{artifact: artifact} do
    invalid_cases = [
      {"run_id", put_in(artifact, ["provenance", "run_id"], %{})},
      {"git_revision", put_in(artifact, ["provenance", "git_revision"], [])},
      {"propagator", put_in(artifact, ["provenance", "propagator"], 1)},
      {"manifest", put_in(artifact, ["provenance", "manifest"], [])},
      {"propagator_opts", put_in(artifact, ["provenance", "propagator_opts"], [])}
    ]

    for {field, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == "$.provenance.#{field}"))
    end
  end

  test "rejects malformed manifest path and SHA evidence", %{artifact: artifact} do
    invalid_cases = [
      {"path", put_in(artifact, ["provenance", "manifest", "path"], "  ")},
      {"sha256", put_in(artifact, ["provenance", "manifest", "sha256"], "abc")},
      {"sha256", put_in(artifact, ["provenance", "manifest", "sha256"], [])}
    ]

    for {field, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)

      assert Enum.any?(
               report["errors"],
               &(&1["path"] == "$.provenance.manifest.#{field}")
             )
    end
  end

  test "handles a malformed provenance object without crashing", %{artifact: artifact} do
    invalid = Map.put(artifact, "provenance", [])

    assert {:error, report} = Schema.validate_artifact(invalid)
    assert Enum.any?(report["errors"], &(&1["path"] == "$.provenance"))
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
