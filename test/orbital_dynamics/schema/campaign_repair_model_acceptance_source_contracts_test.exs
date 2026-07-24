defmodule OrbitalDynamics.Schema.CampaignRepairModelAcceptanceSourceContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  setup do
    artifact = read_json!("study_results/leo_constellation_campaign_repair_v2.json")

    source_report =
      OrbitalDynamics.validation_model_acceptance_report(
        ["orbit_data.simple_json", "event.access_windows", "propagator.two_body"],
        intended_use: :operational_import
      )

    %{artifact: Map.put(artifact, "source_model_acceptance_report", source_report)}
  end

  test "validates the optional V2 source model-acceptance report", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "model_acceptance_report.v1"}} =
             artifact
             |> Map.fetch!("source_model_acceptance_report")
             |> Schema.validate_artifact()

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             artifact
             |> Map.delete("source_model_acceptance_report")
             |> Schema.validate_artifact()
  end

  test "rejects V2 source model-acceptance drift at the source path", %{artifact: artifact} do
    invalid_model =
      put_in(
        artifact,
        ["source_model_acceptance_report", "model"],
        "legacy_model_acceptance_classifier"
      )

    assert {:error, model_report} = Schema.validate_artifact(invalid_model)

    assert Enum.any?(
             model_report["errors"],
             &(&1["path"] == "$.source_model_acceptance_report.model")
           )

    invalid_shape = Map.put(artifact, "source_model_acceptance_report", [])

    assert {:error, shape_report} = Schema.validate_artifact(invalid_shape)

    assert Enum.any?(
             shape_report["errors"],
             &(&1["path"] == "$.source_model_acceptance_report")
           )
  end

  test "exports the source model-acceptance property" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")

    assert get_in(schema, ["properties", "source_model_acceptance_report", "type"]) ==
             "object"

    assert get_in(schema, ["$defs", "model_acceptance_report.v1", "type"]) == "object"
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
