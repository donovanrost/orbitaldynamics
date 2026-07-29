defmodule OrbitalDynamics.Schema.CampaignStrategyProducedSurfaceContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  @produced_fields ~w(
    source_repair_id
    score_term_report
    objective_tradeoff_report
    pareto_frontier_report
    operational_feedback_provenance
    cadence_import_manifest
  )

  setup_all do
    %{strategy: read_json!("study_results/leo_constellation_campaign_strategy_v3.json")}
  end

  test "validates the complete checked V3 produced top-level surface", %{strategy: strategy} do
    assert {:ok, schema} = Schema.json_schema("campaign_strategy.v3")
    declared_fields = schema["properties"] |> Map.keys() |> MapSet.new()

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3"}} =
             Schema.validate_artifact(strategy)

    assert strategy
           |> Map.keys()
           |> MapSet.new()
           |> MapSet.subset?(declared_fields)
  end

  test "keeps produced-surface fields optional for older strategies", %{strategy: strategy} do
    artifact = Map.drop(strategy, @produced_fields)

    assert {:ok, %{"schema_contract" => "campaign_strategy.v3"}} =
             Schema.validate_artifact(artifact)
  end

  test "rejects CampaignStrategy branch metadata drift", %{strategy: strategy} do
    nonbaseline_branch_id =
      strategy["branches"]
      |> Enum.find(&(&1["branch_id"] != "baseline"))
      |> Map.fetch!("branch_id")

    invalid_cases = [
      {"$.strategy_metadata.branch_count",
       put_in(strategy, ["strategy_metadata", "branch_count"], 0)},
      {"$.strategy_metadata.baseline_branch_id",
       put_in(
         strategy,
         ["strategy_metadata", "baseline_branch_id"],
         nonbaseline_branch_id
       )}
    ]

    for {expected_path, invalid} <- invalid_cases do
      assert {:error, report} = Schema.validate_artifact(invalid)
      assert Enum.any?(report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "rejects produced-surface drift at nested paths", %{strategy: strategy} do
    invalid =
      strategy
      |> Map.put("source_repair_id", "not a stable id")
      |> put_in(["score_term_report", "schema_contract"], "score_term_report.v0")
      |> put_in(
        ["objective_tradeoff_report", "schema_contract"],
        "objective_tradeoff_report.v0"
      )
      |> put_in(["pareto_frontier_report", "schema_contract"], "pareto_frontier_report.v0")
      |> put_in(["operational_feedback_provenance", "source_count"], 2)
      |> put_in(["cadence_import_manifest", "schema_contract"], "cadence_import_manifest.v0")

    assert {:error, validation_report} = Schema.validate_artifact(invalid)

    expected_paths = [
      "$.source_repair_id",
      "$.score_term_report.schema_contract",
      "$.objective_tradeoff_report.schema_contract",
      "$.pareto_frontier_report.schema_contract",
      "$.operational_feedback_provenance.source_count",
      "$.cadence_import_manifest.schema_contract"
    ]

    for expected_path <- expected_paths do
      assert Enum.any?(validation_report["errors"], &(&1["path"] == expected_path))
    end
  end

  test "exports direct schemas for every produced-surface report" do
    assert {:ok, schema} = Schema.json_schema("campaign_strategy.v3")
    properties = schema["properties"]

    assert properties["source_repair_id"]["type"] == ["string", "null"]

    assert get_in(properties, ["score_term_report", "properties", "schema_contract", "const"]) ==
             "score_term_report.v1"

    assert get_in(properties, [
             "objective_tradeoff_report",
             "properties",
             "schema_contract",
             "const"
           ]) == "objective_tradeoff_report.v1"

    assert get_in(properties, [
             "pareto_frontier_report",
             "properties",
             "schema_contract",
             "const"
           ]) == "pareto_frontier_report.v1"

    assert get_in(properties, [
             "cadence_import_manifest",
             "properties",
             "schema_contract",
             "const"
           ]) == "cadence_import_manifest.v1"

    assert get_in(properties, [
             "operational_feedback_provenance",
             "properties",
             "source_count"
           ]) == %{"minimum" => 0, "type" => "integer"}
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end
end
