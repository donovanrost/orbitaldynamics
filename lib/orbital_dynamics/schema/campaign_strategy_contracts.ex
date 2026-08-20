defmodule OrbitalDynamics.Schema.CampaignStrategyContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation,
    only: [sanitize_list_field: 4, validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [expect_equal: 5, expect_type: 5, require_fields: 4, require_nested: 4]

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_ids: 4]

  def validate(
        issues,
        artifact,
        required_fields,
        operational_feedback_validator,
        branch_validator,
        recommendation_validator,
        branch_comparison_validator,
        ranking_comparison_validator,
        operator_review_package_validator
      )
      when is_function(operational_feedback_validator, 3) and
             is_function(branch_validator, 3) and
             is_function(recommendation_validator, 3) and
             is_function(branch_comparison_validator, 2) and
             is_function(ranking_comparison_validator, 2) and
             is_function(operator_review_package_validator, 2) do
    {issues, artifact} = sanitize_strategy_collections(issues, artifact)

    issues
    |> require_fields("$", artifact, required_fields)
    |> validate_stable_ids("$", artifact, ["source_plan_id"])
    |> expect_equal("$", artifact, "schema_version", 3)
    |> expect_equal(
      "$",
      artifact,
      "planner",
      "OrbitalDynamics.CampaignPlanner.V3"
    )
    |> expect_type("$", artifact, "mission_state_snapshot", :map)
    |> expect_type("$", artifact, "branches", :list)
    |> expect_type("$", artifact, "recommendation", :map)
    |> expect_type("$", artifact, "strategy_metadata", :map)
    |> OrbitalDynamics.Schema.AuthorityContextContracts.validate_campaign_boundary("$", artifact)
    |> operational_feedback_validator.(
      "$",
      Map.get(artifact, "operational_feedback")
    )
    |> validate_rows(
      "$.branches",
      Map.get(artifact, "branches", []),
      branch_validator
    )
    |> recommendation_validator.(
      "$.recommendation",
      Map.get(artifact, "recommendation", %{})
    )
    |> branch_comparison_validator.(Map.get(artifact, "branch_comparison_report"))
    |> ranking_comparison_validator.(Map.get(artifact, "ranking_comparison_report"))
    |> operator_review_package_validator.(Map.get(artifact, "operator_review_package"))
    |> require_nested(
      "$.strategy_metadata",
      Map.get(artifact, "strategy_metadata", %{}),
      ["strategy_id", "branch_count", "baseline_branch_id", "cadence_integration"]
    )
    |> validate_stable_ids(
      "$.strategy_metadata",
      Map.get(artifact, "strategy_metadata", %{}),
      ["strategy_id", "baseline_branch_id"]
    )
    |> OrbitalDynamics.Schema.CampaignStrategyProducedSurfaceContracts.validate(artifact)
    |> OrbitalDynamics.Schema.AuthorityContextContracts.validate_strategy_propagation(artifact)
  end

  defp sanitize_strategy_collections(issues, artifact) do
    {issues, artifact} = sanitize_list_field(issues, "$", artifact, "branches")

    [
      {"operator_review_package", "$.operator_review_package"},
      {"cadence_import_manifest", "$.cadence_import_manifest"},
      {"branch_comparison_report", "$.branch_comparison_report"}
    ]
    |> Enum.reduce({issues, artifact}, fn {field, path}, {acc, current_artifact} ->
      case Map.get(current_artifact, field) do
        %{} = container ->
          {acc, container} = sanitize_list_field(acc, path, container, "rows")
          {acc, Map.put(current_artifact, field, container)}

        _container ->
          {acc, current_artifact}
      end
    end)
  end
end
