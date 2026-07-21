defmodule OrbitalDynamics.Schema.CampaignPlanAssumptionContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [expect_equal: 5, expect_type: 5, require_fields: 4]

  @fixed_fields [
    {"activity_builder", "windows_to_observe_and_downlink_candidates"},
    {"timeline_selector", "per_spacecraft_greedy_non_overlapping"},
    {"resource_filter", "resource_summary_availability_and_margin_filter"},
    {"contact_filter", "ground_network_availability_filter_before_ranking"},
    {"cadence_integration", "artifact_only_no_api_or_database_writes"}
  ]

  @required_fields Enum.map(@fixed_fields, &elem(&1, 0)) ++ ["constraints", "scoring_policy"]

  def validate(issues, artifact) when is_map(artifact) do
    case Map.get(artifact, "assumptions") do
      %{} = assumptions -> validate_assumptions(issues, assumptions)
      _assumptions -> issues
    end
  end

  defp validate_assumptions(issues, assumptions) do
    issues
    |> require_fields("$.assumptions", assumptions, @required_fields)
    |> validate_fixed_fields(assumptions)
    |> validate_map_field(assumptions, "constraints")
    |> validate_map_field(assumptions, "scoring_policy")
  end

  defp validate_fixed_fields(issues, assumptions) do
    Enum.reduce(@fixed_fields, issues, fn {field, expected}, acc ->
      if Map.has_key?(assumptions, field) do
        expect_equal(acc, "$.assumptions", assumptions, field, expected)
      else
        acc
      end
    end)
  end

  defp validate_map_field(issues, assumptions, field) do
    if Map.has_key?(assumptions, field) do
      expect_type(issues, "$.assumptions", assumptions, field, :map)
    else
      issues
    end
  end
end
