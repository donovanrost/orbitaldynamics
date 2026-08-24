defmodule OrbitalDynamics.Schema.ValidationPolicyContracts do
  @moduledoc false

  alias OrbitalDynamics.Validation.ImplementationKey

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_type: 5,
      require_nested: 4,
      validate_string_list_items: 4
    ]

  def level_names do
    [
      "analysis",
      "artifact_contract",
      "assumption_declared",
      "educational",
      "validated"
    ]
  end

  def validate_tolerance_policy(issues, path, artifact) do
    issues
    |> expect_equal(path, artifact, "schema_contract", "validation_tolerance_policy.v1")
    |> expect_type(path, artifact, "comparison_model", :map)
    |> expect_type(path, artifact, "event_timing", :map)
    |> expect_type(path, artifact, "artifact_regressions", :map)
    |> expect_type(path, artifact, "validation_levels", :map)
    |> require_nested(
      "#{path}.event_timing",
      Map.get(artifact, "event_timing", %{}),
      ["current_policy", "event_time_tolerance_s", "confidence", "limit"]
    )
    |> validate_tolerance_policy_levels(artifact)
  end

  def validate_backend_acceptance_policy(issues, path, artifact) do
    issues
    |> expect_equal(path, artifact, "schema_contract", "backend_acceptance_policy.v1")
    |> expect_type(path, artifact, "reference_backend", :map)
    |> expect_type(path, artifact, "acceptance_tiers", :map)
    |> expect_type(path, artifact, "implementation_tiers", :map)
    |> expect_type(path, artifact, "comparison_requirements", :map)
    |> expect_type(path, artifact, "benchmark_reference_cases", :list)
    |> expect_type(path, artifact, "known_limits", :list)
    |> expect_equal(
      "#{path}.comparison_requirements",
      Map.get(artifact, "comparison_requirements", %{}),
      "numeric_tolerance_policy",
      "validation_tolerance_policy.v1"
    )
    |> validate_backend_acceptance_policy_references(artifact)
  end

  defp validate_tolerance_policy_levels(issues, artifact) do
    case Map.get(artifact, "validation_levels") do
      %{} = levels ->
        observed_levels = levels |> Map.keys() |> Enum.sort()
        expected_levels = level_names()

        issues
        |> validate_tolerance_policy_level_names(observed_levels, expected_levels)
        |> validate_tolerance_policy_level_descriptions(levels)

      _levels ->
        issues
    end
  end

  defp validate_tolerance_policy_level_names(
         issues,
         observed_levels,
         expected_levels
       ) do
    if observed_levels == expected_levels do
      issues
    else
      [
        error(
          "$.validation_levels",
          "must match validation tolerance policy level names"
        )
        | issues
      ]
    end
  end

  defp validate_tolerance_policy_level_descriptions(issues, levels) do
    Enum.reduce(levels, issues, fn {level, description}, acc ->
      cond do
        not is_binary(level) ->
          [
            error("$.validation_levels", "validation level names must be strings")
            | acc
          ]

        not is_binary(description) ->
          [error("$.validation_levels.#{level}", "must be a string") | acc]

        description == "" ->
          [error("$.validation_levels.#{level}", "must not be empty") | acc]

        true ->
          acc
      end
    end)
  end

  defp validate_backend_acceptance_policy_references(issues, artifact) do
    acceptance_tiers = Map.get(artifact, "acceptance_tiers")
    implementation_tiers = Map.get(artifact, "implementation_tiers")
    reference_backend = Map.get(artifact, "reference_backend")
    tier_names = if is_map(acceptance_tiers), do: Map.keys(acceptance_tiers), else: []

    issues
    |> validate_reference_backend(
      reference_backend,
      implementation_tiers,
      tier_names
    )
    |> validate_implementation_tiers(implementation_tiers, tier_names)
  end

  defp validate_reference_backend(
         issues,
         %{} = reference_backend,
         implementation_tiers,
         tier_names
       ) do
    reference_tier = Map.get(reference_backend, "tier")

    issues
    |> expect_type("$.reference_backend", reference_backend, "tier", :binary)
    |> expect_type("$.reference_backend", reference_backend, "implementations", :list)
    |> validate_string_list_items(
      "$.reference_backend",
      reference_backend,
      "implementations"
    )
    |> validate_string_list_items(
      "$.reference_backend",
      reference_backend,
      "validation_basis"
    )
    |> validate_reference_tier(reference_tier, tier_names)
    |> validate_reference_implementations(
      Map.get(reference_backend, "implementations"),
      reference_tier,
      implementation_tiers
    )
  end

  defp validate_reference_backend(
         issues,
         _reference_backend,
         _implementation_tiers,
         _tier_names
       ),
       do: issues

  defp validate_reference_tier(issues, tier, tier_names)
       when is_binary(tier) and tier_names != [] do
    if tier in tier_names do
      issues
    else
      [error("$.reference_backend.tier", "must reference acceptance_tiers") | issues]
    end
  end

  defp validate_reference_tier(issues, _tier, _tier_names), do: issues

  defp validate_reference_implementations(
         issues,
         implementations,
         reference_tier,
         implementation_tiers
       )
       when is_list(implementations) and is_binary(reference_tier) and
              is_map(implementation_tiers) do
    implementations
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {implementation, index}, acc ->
      cond do
        not is_binary(implementation) ->
          acc

        not ImplementationKey.valid?(implementation) ->
          [
            error(
              "$.reference_backend.implementations[#{index}]",
              "must be a valid backend implementation machine identifier"
            )
            | acc
          ]

        Map.get(implementation_tiers, implementation) == reference_tier ->
          acc

        true ->
          [
            error(
              "$.reference_backend.implementations[#{index}]",
              "must be assigned to the reference backend tier"
            )
            | acc
          ]
      end
    end)
  end

  defp validate_reference_implementations(
         issues,
         _implementations,
         _reference_tier,
         _implementation_tiers
       ),
       do: issues

  defp validate_implementation_tiers(issues, %{} = implementation_tiers, tier_names) do
    Enum.reduce(implementation_tiers, issues, fn {implementation, tier}, acc ->
      cond do
        not is_binary(implementation) ->
          [
            error("$.implementation_tiers", "implementation names must be strings")
            | acc
          ]

        not ImplementationKey.valid?(implementation) ->
          [
            error(
              "$.implementation_tiers",
              "implementation names must be valid backend implementation machine identifiers"
            )
            | acc
          ]

        not is_binary(tier) ->
          [error("$.implementation_tiers.#{implementation}", "must be a string") | acc]

        tier_names != [] and tier not in tier_names ->
          [
            error(
              "$.implementation_tiers.#{implementation}",
              "must reference acceptance_tiers"
            )
            | acc
          ]

        true ->
          acc
      end
    end)
  end

  defp validate_implementation_tiers(issues, _implementation_tiers, _tier_names),
    do: issues
end
