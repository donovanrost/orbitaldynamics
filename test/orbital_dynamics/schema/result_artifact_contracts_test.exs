defmodule OrbitalDynamics.Schema.ResultArtifactContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  test "exports and validates top-level result artifact contracts" do
    artifact = read_json!("study_results/ground_track_crossings.json")

    assert {:ok, %{"schema_contract" => "result_artifact.v1"}} =
             Schema.validate_artifact(artifact, schema_contract: "result_artifact.v1")

    assert {:ok, schema} = Schema.json_schema("result_artifact.v1")
    assert schema["required"] |> Enum.member?("ground_track_crossings")

    assert get_in(schema, [
             "properties",
             "ground_track_crossings",
             "items",
             "properties",
             "event_type",
             "enum"
           ]) == ["latitude_crossing", "longitude_crossing"]

    assert get_in(schema, [
             "properties",
             "payload_metrics",
             "properties",
             "schema_contract",
             "const"
           ]) == "result_payload_metrics.v1"
  end

  test "validates every required trajectory field" do
    artifact = result_artifact_fixture()

    for field <- [
          "scenario_id",
          "sample_count",
          "starts_at_s",
          "ends_at_s",
          "final_position_km",
          "final_velocity_km_s",
          "assumptions"
        ] do
      invalid_artifact = update_trajectory(artifact, &Map.delete(&1, field))

      assert {:error, report} = validate(invalid_artifact)

      assert Enum.any?(report["errors"], fn issue ->
               issue["path"] == "$.trajectories[0].#{field}" and
                 issue["message"] == "is required"
             end)
    end
  end

  test "rejects malformed required trajectory values at their field paths" do
    artifact = result_artifact_fixture()

    invalid_values = [
      {"scenario_id", "not a stable id", "stable ID"},
      {"sample_count", 1.5, "must be a integer"},
      {"starts_at_s", "0.0", "must be a number"},
      {"ends_at_s", nil, "must be a number"},
      {"assumptions", [], "must be a map"}
    ]

    for {field, value, expected_message} <- invalid_values do
      invalid_artifact = update_trajectory(artifact, &Map.put(&1, field, value))

      assert {:error, report} = validate(invalid_artifact)

      assert Enum.any?(report["errors"], fn issue ->
               issue["path"] == "$.trajectories[0].#{field}" and
                 issue["message"] =~ expected_message
             end)
    end
  end

  test "rejects malformed trajectory vector lengths and contents" do
    artifact = result_artifact_fixture()

    for field <- ["final_position_km", "final_velocity_km_s"],
        value <- [[1.0, 2.0], [1.0, 2.0, "three"]] do
      invalid_artifact = update_trajectory(artifact, &Map.put(&1, field, value))

      assert {:error, report} = validate(invalid_artifact)

      assert Enum.any?(report["errors"], fn issue ->
               issue["path"] == "$.trajectories[0].#{field}" and
                 issue["message"] == "must be a three-element number array"
             end)
    end
  end

  test "rejects non-object trajectory rows" do
    artifact = result_artifact_fixture()
    invalid_artifact = Map.put(artifact, "trajectories", ["not-an-object"])

    assert {:error, report} = validate(invalid_artifact)

    assert Enum.any?(report["errors"], fn issue ->
             issue["path"] == "$.trajectories[0]" and
               issue["message"] == "must be an object"
           end)
  end

  test "accepts a string or absent trajectory node and rejects every present non-string" do
    artifact = result_artifact_fixture()

    assert {:ok, _report} =
             artifact
             |> update_trajectory(&Map.put(&1, "node", "worker@host"))
             |> validate()

    assert {:ok, _report} =
             artifact
             |> update_trajectory(&Map.delete(&1, "node"))
             |> validate()

    for value <- [nil, :null, %{}, [], 17, :worker_node] do
      invalid_artifact = update_trajectory(artifact, &Map.put(&1, "node", value))

      assert {:error, report} = validate(invalid_artifact)

      assert Enum.any?(report["errors"], fn issue ->
               issue["path"] == "$.trajectories[0].node" and
                 issue["message"] == "must be a string"
             end)
    end
  end

  defp result_artifact_fixture,
    do: read_json!("study_results/ground_track_crossings.json")

  defp update_trajectory(%{"trajectories" => [trajectory]} = artifact, update) do
    Map.put(artifact, "trajectories", [update.(trajectory)])
  end

  defp validate(artifact),
    do: Schema.validate_artifact(artifact, schema_contract: "result_artifact.v1")

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
