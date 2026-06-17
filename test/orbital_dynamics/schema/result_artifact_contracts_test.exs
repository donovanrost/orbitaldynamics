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

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
