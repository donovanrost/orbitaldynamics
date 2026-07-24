defmodule OrbitalDynamics.Schema.CampaignRepairObjectiveTradeoffSourceContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  setup do
    artifact = read_json!("study_results/leo_constellation_campaign_repair_v2.json")
    source_report = read_json!("study_results/objective_tradeoff_report_v1.json")

    %{artifact: Map.put(artifact, "source_objective_tradeoff_report", source_report)}
  end

  test "validates the optional V2 source objective-tradeoff report", %{artifact: artifact} do
    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             Schema.validate_artifact(artifact)

    assert {:ok, %{"schema_contract" => "objective_tradeoff_report.v1"}} =
             artifact
             |> Map.fetch!("source_objective_tradeoff_report")
             |> Schema.validate_artifact()

    assert {:ok, %{"schema_contract" => "campaign_repair.v2"}} =
             artifact
             |> Map.delete("source_objective_tradeoff_report")
             |> Schema.validate_artifact()
  end

  test "rejects V2 source objective-tradeoff drift at the source path", %{
    artifact: artifact
  } do
    invalid_model =
      put_in(
        artifact,
        ["source_objective_tradeoff_report", "model"],
        "legacy_tradeoff_model"
      )

    assert {:error, model_report} = Schema.validate_artifact(invalid_model)

    assert Enum.any?(
             model_report["errors"],
             &(&1["path"] == "$.source_objective_tradeoff_report.model")
           )

    invalid_shape = Map.put(artifact, "source_objective_tradeoff_report", [])

    assert {:error, shape_report} = Schema.validate_artifact(invalid_shape)

    assert Enum.any?(
             shape_report["errors"],
             &(&1["path"] == "$.source_objective_tradeoff_report")
           )
  end

  test "exports the source objective-tradeoff property" do
    assert {:ok, schema} = Schema.json_schema("campaign_repair.v2")

    assert get_in(schema, ["properties", "source_objective_tradeoff_report", "type"]) ==
             "object"

    assert get_in(schema, ["$defs", "objective_tradeoff_report.v1", "type"]) == "object"
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
