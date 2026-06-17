defmodule OrbitalDynamics.Schema.AcceptedStateContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  test "exports nested accepted planning state spacecraft state schema" do
    assert {:ok, schema} = Schema.json_schema("accepted_planning_state.v1")

    assert [
             %{
               "if" => %{"properties" => %{"provenance" => %{"anyOf" => provenance_any_of}}},
               "then" => %{"properties" => %{"provenance" => provenance_then}}
             }
           ] = schema["allOf"]

    assert %{"required" => ["import_adapter"]} in provenance_any_of
    assert provenance_then["required"] == ["trust_boundary"]

    state_schema = get_in(schema, ["properties", "spacecraft_states", "items"])

    assert state_schema["type"] == "object"
    assert "state_vector" in state_schema["required"]

    assert get_in(state_schema, ["properties", "spacecraft_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(state_schema, ["properties", "scenario_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(state_schema, ["properties", "epoch", "required"]) == [
             "seconds_since_j2000",
             "time_scale"
           ]

    assert get_in(state_schema, ["properties", "state_vector", "required"]) == [
             "position_km",
             "velocity_km_s"
           ]

    assert get_in(state_schema, [
             "properties",
             "state_vector",
             "properties",
             "position_km",
             "minItems"
           ]) == 3

    assert get_in(state_schema, [
             "properties",
             "quality",
             "properties",
             "velocity_sigma_km_s",
             "items",
             "type"
           ]) == "number"

    assert get_in(state_schema, [
             "properties",
             "quality",
             "properties",
             "covariance_reference_frame",
             "type"
           ]) == "string"

    assert get_in(state_schema, [
             "properties",
             "metadata",
             "properties",
             "object_id",
             "type"
           ]) == "string"

    assert get_in(state_schema, [
             "properties",
             "metadata",
             "properties",
             "covariance_reference_frame",
             "type"
           ]) == "string"

    assert get_in(state_schema, [
             "properties",
             "metadata",
             "properties",
             "ccsds_oem_version",
             "type"
           ]) == "string"

    assert get_in(state_schema, [
             "properties",
             "metadata",
             "properties",
             "sample_index",
             "type"
           ]) == "integer"

    assert %{"required" => ["trust_boundary"]} in state_schema["anyOf"]

    delta_schema = get_in(schema, ["properties", "maneuver_execution_deltas", "items"])

    assert delta_schema["type"] == "object"
    assert delta_schema["required"] == ["activity_id", "status", "source", "quality"]

    assert get_in(delta_schema, ["properties", "activity_id", "pattern"]) ==
             Schema.identity_policy()["stable_id_pattern"]

    assert get_in(delta_schema, ["properties", "delta_v_km_s", "minItems"]) == 3

    assert get_in(delta_schema, ["properties", "metadata", "properties", "maneuver_index", "type"]) ==
             "integer"

    assert %{"required" => ["trust_boundary"]} in delta_schema["anyOf"]
  end

  test "validates accepted planning state snapshots" do
    assert {:ok, report} = Schema.validate_artifact(accepted_planning_state())

    assert report["schema_contract"] == "accepted_planning_state.v1"
    assert report["artifact_family"] == "accepted_planning_state"

    invalid_import_provenance =
      accepted_planning_state()
      |> put_in(["provenance"], %{
        "import_adapter" => "OrbitalDynamics.OrbitData.import_simple_json/2",
        "input_format" => "simple_json_state_estimate_batch"
      })

    assert {:error, invalid_report} = Schema.validate_artifact(invalid_import_provenance)

    assert Enum.any?(
             invalid_report["errors"],
             &(&1["path"] == "$.provenance.trust_boundary" and
                 &1["message"] =~ "accepted_planning_state.v1 import provenance requires")
           )
  end

  test "validates standalone state-estimate and maneuver-delta fixtures" do
    state_estimate = read_json!("study_results/spacecraft_state_estimate_v1.json")
    maneuver_delta = read_json!("study_results/maneuver_execution_delta_v1.json")

    assert {:ok, %{"schema_contract" => "spacecraft_state_estimate.v1"}} =
             Schema.validate_artifact(state_estimate)

    assert {:ok, %{"schema_contract" => "maneuver_execution_delta.v1"}} =
             Schema.validate_artifact(maneuver_delta)

    invalid_state =
      put_in(state_estimate, ["state_vector", "position_km"], [7000.0, 0.0])

    assert {:error, state_report} = Schema.validate_artifact(invalid_state)

    assert Enum.any?(
             state_report["errors"],
             &(&1["path"] == "$.state_vector.position_km" and
                 &1["message"] == "must be a three-element number array")
           )

    invalid_delta = Map.delete(maneuver_delta, "activity_id")

    assert {:error, delta_report} = Schema.validate_artifact(invalid_delta)
    assert Enum.any?(delta_report["errors"], &(&1["path"] == "$.activity_id"))

    state_missing_trust =
      state_estimate
      |> Map.delete("trust_boundary")
      |> Map.delete("provenance")

    assert {:error, state_trust_report} = Schema.validate_artifact(state_missing_trust)

    assert Enum.any?(
             state_trust_report["errors"],
             &(&1["path"] == "$.trust_boundary" and
                 &1["message"] =~ "spacecraft_state_estimate.v1 requires trust_boundary")
           )

    delta_missing_trust =
      maneuver_delta
      |> Map.delete("trust_boundary")
      |> Map.delete("provenance")

    assert {:error, delta_trust_report} = Schema.validate_artifact(delta_missing_trust)

    assert Enum.any?(
             delta_trust_report["errors"],
             &(&1["path"] == "$.trust_boundary" and
                 &1["message"] =~ "maneuver_execution_delta.v1 requires trust_boundary")
           )
  end

  test "reports invalid state-vector arrays in accepted planning state snapshots" do
    artifact =
      update_in(accepted_planning_state(), ["spacecraft_states", Access.at(0), "state_vector"], fn
        state_vector -> Map.put(state_vector, "position_km", [7000.0, 0.0])
      end)

    assert {:error, report} = Schema.validate_artifact(artifact)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.spacecraft_states[0].state_vector.position_km")
           )
  end

  test "requires trust-boundary provenance on accepted planning state rows" do
    artifact =
      accepted_planning_state()
      |> update_in(["spacecraft_states", Access.at(0)], fn state ->
        state
        |> Map.delete("trust_boundary")
        |> Map.delete("provenance")
      end)
      |> update_in(["maneuver_execution_deltas", Access.at(0)], fn delta ->
        delta
        |> Map.delete("trust_boundary")
        |> Map.delete("provenance")
      end)

    assert {:error, report} = Schema.validate_artifact(artifact)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.spacecraft_states[0].trust_boundary" and
                 &1["message"] =~ "spacecraft_state_estimate.v1 requires trust_boundary")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.maneuver_execution_deltas[0].trust_boundary" and
                 &1["message"] =~ "maneuver_execution_delta.v1 requires trust_boundary")
           )
  end

  test "rejects non-list maneuver execution deltas in accepted planning state snapshots" do
    artifact =
      Map.put(accepted_planning_state(), "maneuver_execution_deltas", %{
        "activity_id" => "burn_1",
        "status" => "completed"
      })

    assert {:error, report} = Schema.validate_artifact(artifact)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.maneuver_execution_deltas" and &1["message"] == "must be a list")
           )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end

  defp accepted_planning_state do
    %{
      "schema_version" => 1,
      "artifact_type" => "accepted_planning_state",
      "snapshot_id" => "ops-state-2026-05-14",
      "accepted_at" => "2026-05-14T00:00:00Z",
      "spacecraft_states" => [
        %{
          "spacecraft_id" => "sat_1",
          "scenario_id" => "leo_1",
          "epoch" => %{"seconds_since_j2000" => 0.0, "time_scale" => "tdb"},
          "frame" => "earth_inertial_j2000",
          "state_vector" => %{
            "position_km" => [7000.0, 0.0, 0.0],
            "velocity_km_s" => [0.0, 7.5, 0.0]
          },
          "source" => %{"system" => "operator_import", "source_id" => "state_estimate_1"},
          "provenance" => %{"trust_boundary" => "operator_supplied"},
          "quality" => %{
            "level" => "accepted",
            "position_sigma_km" => [0.1, 0.1, 0.1],
            "velocity_sigma_km_s" => [0.001, 0.001, 0.001]
          }
        }
      ],
      "maneuver_execution_deltas" => [
        %{
          "activity_id" => "burn_1",
          "status" => "completed",
          "source" => %{"system" => "ops_log"},
          "provenance" => %{"trust_boundary" => "operator_supplied"},
          "quality" => %{"level" => "operator_reported"}
        }
      ],
      "source" => %{"system" => "cadence_snapshot", "source_id" => "snapshot_1"},
      "quality" => %{"level" => "planning_accepted"},
      "provenance" => %{"created_by" => "test"}
    }
  end
end
