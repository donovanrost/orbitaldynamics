defmodule OrbitalDynamics.Schema.CampaignStrategyContracts do
  @moduledoc false

  def validate(issues, artifact, required_fields, callbacks) when is_list(callbacks) do
    issues
    |> call(callbacks, :require_fields, ["$", artifact, required_fields])
    |> call(callbacks, :validate_stable_ids, ["$", artifact, ["source_plan_id"]])
    |> call(callbacks, :expect_equal, ["$", artifact, "schema_version", 3])
    |> call(callbacks, :expect_equal, [
      "$",
      artifact,
      "planner",
      "OrbitalDynamics.CampaignPlanner.V3"
    ])
    |> call(callbacks, :expect_type, ["$", artifact, "mission_state_snapshot", :map])
    |> call(callbacks, :expect_type, ["$", artifact, "branches", :list])
    |> call(callbacks, :expect_type, ["$", artifact, "recommendation", :map])
    |> call(callbacks, :expect_type, ["$", artifact, "strategy_metadata", :map])
    |> call(callbacks, :validate_operational_feedback, [
      "$",
      Map.get(artifact, "operational_feedback")
    ])
    |> call(callbacks, :validate_rows, [
      "$.branches",
      Map.get(artifact, "branches", []),
      callback(callbacks, :validate_branch)
    ])
    |> call(callbacks, :validate_recommendation, [
      "$.recommendation",
      Map.get(artifact, "recommendation", %{})
    ])
    |> call(callbacks, :validate_optional_branch_comparison_report, [
      Map.get(artifact, "branch_comparison_report")
    ])
    |> call(callbacks, :validate_optional_ranking_comparison_report, [
      Map.get(artifact, "ranking_comparison_report")
    ])
    |> call(callbacks, :validate_optional_operator_review_package, [
      Map.get(artifact, "operator_review_package")
    ])
    |> call(callbacks, :require_nested, [
      "$.strategy_metadata",
      Map.get(artifact, "strategy_metadata", %{}),
      ["strategy_id", "branch_count", "baseline_branch_id", "cadence_integration"]
    ])
    |> call(callbacks, :validate_stable_ids, [
      "$.strategy_metadata",
      Map.get(artifact, "strategy_metadata", %{}),
      ["strategy_id", "baseline_branch_id"]
    ])
  end

  defp callback(callbacks, name), do: Keyword.fetch!(callbacks, name)

  defp call(issues, callbacks, name, args),
    do: apply(callback(callbacks, name), [issues | args])
end
