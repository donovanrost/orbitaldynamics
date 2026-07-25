defmodule OrbitalDynamics.Schema.CampaignRepairValidationRecordsContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  @source_field "source_validation_records"

  setup do
    artifact = read_json!("study_results/leo_constellation_campaign_repair_v2.json")
    validation_record = read_json!("study_results/validation_record_v1.json")

    %{artifact: Map.put(artifact, @source_field, [validation_record])}
  end

  test "validates every optional V2 source validation record", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             artifact
             |> Map.delete(@source_field)
             |> Schema.validate_artifact()

    legacy_record =
      update_in(artifact, [@source_field, Access.at(0)], &Map.delete(&1, "schema_contract"))

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(legacy_record)
  end

  test "rejects validation-record drift at exact indexed paths", %{artifact: artifact} do
    invalid_contract =
      put_in(artifact, [@source_field, Access.at(0), "schema_contract"], "wrong.v1")

    assert {:error, contract_report} = Schema.validate_artifact(invalid_contract)

    assert Enum.any?(
             contract_report["errors"],
             &(&1["path"] == "$.#{@source_field}[0].schema_contract")
           )

    invalid_limits =
      put_in(artifact, [@source_field, Access.at(0), "known_limits"], ["drifted"])

    assert {:error, limit_report} = Schema.validate_artifact(invalid_limits)

    assert Enum.any?(
             limit_report["errors"],
             &(&1["path"] == "$.#{@source_field}[0].known_limits")
           )

    invalid_tolerance =
      put_in(
        artifact,
        [@source_field, Access.at(0), "tolerances", "position_km"],
        -1.0
      )

    assert {:error, tolerance_report} = Schema.validate_artifact(invalid_tolerance)

    assert Enum.any?(
             tolerance_report["errors"],
             &(&1["path"] == "$.#{@source_field}[0].tolerances.position_km")
           )

    invalid_shape = Map.put(artifact, @source_field, %{})
    assert {:error, shape_report} = Schema.validate_artifact(invalid_shape)
    assert Enum.any?(shape_report["errors"], &(&1["path"] == "$.#{@source_field}"))
  end

  test "reuses the CandidateRefresh validation-record collection schema" do
    assert {:ok, repair_schema} = Schema.json_schema("campaign_repair.v2")
    assert {:ok, refresh_schema} = Schema.json_schema("candidate_refresh.v1")

    assert repair_schema["properties"][@source_field] ==
             refresh_schema["properties"]["validation_records"]

    item_schema = get_in(repair_schema, ["properties", @source_field, "items"])

    assert get_in(item_schema, ["properties", "id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(item_schema, ["properties", "evidence", "items", "type"]) == "string"

    assert Enum.any?(
             item_schema["allOf"],
             &(get_in(&1, ["if", "properties", "id", "const"]) ==
                 "propagator.two_body" and
                 get_in(&1, ["then", "properties", "model", "const"]) ==
                   "point_mass_two_body")
           )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
