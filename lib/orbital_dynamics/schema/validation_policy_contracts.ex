defmodule OrbitalDynamics.Schema.ValidationPolicyContracts do
  @moduledoc false

  def level_names do
    [
      "analysis",
      "artifact_contract",
      "assumption_declared",
      "educational",
      "validated"
    ]
  end

  def validate_tolerance_policy(issues, path, artifact, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(
      callbacks,
      path,
      artifact,
      "schema_contract",
      "validation_tolerance_policy.v1"
    )
    |> expect_type(callbacks, path, artifact, "comparison_model", :map)
    |> expect_type(callbacks, path, artifact, "event_timing", :map)
    |> expect_type(callbacks, path, artifact, "artifact_regressions", :map)
    |> expect_type(callbacks, path, artifact, "validation_levels", :map)
    |> require_nested(
      callbacks,
      "#{path}.event_timing",
      Map.get(artifact, "event_timing", %{}),
      ["current_policy", "event_time_tolerance_s", "confidence", "limit"]
    )
    |> validate_tolerance_policy_levels(callbacks, artifact)
  end

  def validate_backend_acceptance_policy(issues, path, artifact, callbacks)
      when is_list(callbacks) do
    issues
    |> expect_equal(callbacks, path, artifact, "schema_contract", "backend_acceptance_policy.v1")
    |> expect_type(callbacks, path, artifact, "reference_backend", :map)
    |> expect_type(callbacks, path, artifact, "acceptance_tiers", :map)
    |> expect_type(callbacks, path, artifact, "implementation_tiers", :map)
    |> expect_type(callbacks, path, artifact, "comparison_requirements", :map)
    |> expect_type(callbacks, path, artifact, "benchmark_reference_cases", :list)
    |> expect_type(callbacks, path, artifact, "known_limits", :list)
    |> expect_equal(
      callbacks,
      "#{path}.comparison_requirements",
      Map.get(artifact, "comparison_requirements", %{}),
      "numeric_tolerance_policy",
      "validation_tolerance_policy.v1"
    )
    |> validate_backend_acceptance_policy_references(callbacks, artifact)
  end

  defp validate_tolerance_policy_levels(issues, callbacks, artifact) do
    case Map.get(artifact, "validation_levels") do
      %{} = levels ->
        observed_levels = levels |> Map.keys() |> Enum.sort()
        expected_levels = tolerance_policy_level_names(callbacks)

        issues
        |> validate_tolerance_policy_level_names(callbacks, observed_levels, expected_levels)
        |> validate_tolerance_policy_level_descriptions(callbacks, levels)

      _levels ->
        issues
    end
  end

  defp validate_tolerance_policy_level_names(
         issues,
         callbacks,
         observed_levels,
         expected_levels
       ) do
    if observed_levels == expected_levels do
      issues
    else
      [
        error(
          callbacks,
          "$.validation_levels",
          "must match validation tolerance policy level names"
        )
        | issues
      ]
    end
  end

  defp validate_tolerance_policy_level_descriptions(issues, callbacks, levels) do
    Enum.reduce(levels, issues, fn {level, description}, acc ->
      cond do
        not is_binary(level) ->
          [
            error(callbacks, "$.validation_levels", "validation level names must be strings")
            | acc
          ]

        not is_binary(description) ->
          [error(callbacks, "$.validation_levels.#{level}", "must be a string") | acc]

        description == "" ->
          [error(callbacks, "$.validation_levels.#{level}", "must not be empty") | acc]

        true ->
          acc
      end
    end)
  end

  defp validate_backend_acceptance_policy_references(issues, callbacks, artifact) do
    acceptance_tiers = Map.get(artifact, "acceptance_tiers")
    implementation_tiers = Map.get(artifact, "implementation_tiers")
    reference_backend = Map.get(artifact, "reference_backend")
    tier_names = if is_map(acceptance_tiers), do: Map.keys(acceptance_tiers), else: []

    issues
    |> validate_reference_backend(
      callbacks,
      reference_backend,
      implementation_tiers,
      tier_names
    )
    |> validate_implementation_tiers(callbacks, implementation_tiers, tier_names)
  end

  defp validate_reference_backend(
         issues,
         callbacks,
         %{} = reference_backend,
         implementation_tiers,
         tier_names
       ) do
    reference_tier = Map.get(reference_backend, "tier")

    issues
    |> expect_type(callbacks, "$.reference_backend", reference_backend, "tier", :binary)
    |> expect_type(callbacks, "$.reference_backend", reference_backend, "implementations", :list)
    |> validate_string_list_items(
      callbacks,
      "$.reference_backend",
      reference_backend,
      "implementations"
    )
    |> validate_string_list_items(
      callbacks,
      "$.reference_backend",
      reference_backend,
      "validation_basis"
    )
    |> validate_reference_tier(callbacks, reference_tier, tier_names)
    |> validate_reference_implementations(
      callbacks,
      Map.get(reference_backend, "implementations"),
      reference_tier,
      implementation_tiers
    )
  end

  defp validate_reference_backend(
         issues,
         _callbacks,
         _reference_backend,
         _implementation_tiers,
         _tier_names
       ),
       do: issues

  defp validate_reference_tier(issues, callbacks, tier, tier_names)
       when is_binary(tier) and tier_names != [] do
    if tier in tier_names do
      issues
    else
      [error(callbacks, "$.reference_backend.tier", "must reference acceptance_tiers") | issues]
    end
  end

  defp validate_reference_tier(issues, _callbacks, _tier, _tier_names), do: issues

  defp validate_reference_implementations(
         issues,
         callbacks,
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

        Map.get(implementation_tiers, implementation) == reference_tier ->
          acc

        true ->
          [
            error(
              callbacks,
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
         _callbacks,
         _implementations,
         _reference_tier,
         _implementation_tiers
       ),
       do: issues

  defp validate_implementation_tiers(issues, callbacks, %{} = implementation_tiers, tier_names) do
    Enum.reduce(implementation_tiers, issues, fn {implementation, tier}, acc ->
      cond do
        not is_binary(implementation) ->
          [
            error(callbacks, "$.implementation_tiers", "implementation names must be strings")
            | acc
          ]

        not is_binary(tier) ->
          [error(callbacks, "$.implementation_tiers.#{implementation}", "must be a string") | acc]

        tier_names != [] and tier not in tier_names ->
          [
            error(
              callbacks,
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

  defp validate_implementation_tiers(issues, _callbacks, _implementation_tiers, _tier_names),
    do: issues

  defp tolerance_policy_level_names(callbacks),
    do: apply(Keyword.fetch!(callbacks, :validation_tolerance_policy_level_names), [])

  defp require_nested(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :require_nested), [issues, path, map, fields])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp error(callbacks, path, message),
    do: apply(Keyword.fetch!(callbacks, :error), [path, message])
end
