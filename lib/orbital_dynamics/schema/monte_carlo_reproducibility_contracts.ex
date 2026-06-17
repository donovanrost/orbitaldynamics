defmodule OrbitalDynamics.Schema.MonteCarloReproducibilityContracts do
  @moduledoc false

  def validate(issues, path, report, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(
      callbacks,
      path,
      report,
      "schema_contract",
      "monte_carlo_reproducibility_report.v1"
    )
    |> expect_equal(
      callbacks,
      path,
      report,
      "model",
      "seeded_independent_normal_cartesian_dispersion"
    )
    |> expect_type(callbacks, path, report, "source", :binary)
    |> expect_type(callbacks, path, report, "generator", :binary)
    |> expect_type(callbacks, path, report, "rng", :binary)
    |> expect_type(callbacks, path, report, "sampling_method", :binary)
    |> expect_type(callbacks, path, report, "deterministic_seed", :boolean)
    |> expect_number(callbacks, path, report, "seed")
    |> expect_non_negative_integer(callbacks, path, report, "requested_count")
    |> expect_non_negative_integer(callbacks, path, report, "generated_scenario_count")
    |> expect_type(callbacks, path, report, "generated_scenario_ids", :list)
    |> validate_stable_id_list(
      callbacks,
      path <> ".generated_scenario_ids",
      Map.get(report, "generated_scenario_ids", [])
    )
    |> expect_number_vector(
      callbacks,
      path <> ".position_sigma_km",
      Map.get(report, "position_sigma_km")
    )
    |> expect_number_vector(
      callbacks,
      path <> ".velocity_sigma_km_s",
      Map.get(report, "velocity_sigma_km_s")
    )
    |> expect_type(callbacks, path, report, "seed_manifest", :map)
    |> expect_type(callbacks, path, report, "assumptions", :map)
    |> expect_type(callbacks, path, report, "known_limits", :list)
    |> validate_string_list_items(callbacks, path, report, "known_limits")
    |> validate_known_limits(callbacks, path, report)
    |> expect_optional_type(callbacks, path, report, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, report, "model_limits")
    |> validate_model_limits(callbacks, path, report)
    |> validate_counts(callbacks, path, report)
  end

  defp validate_counts(issues, callbacks, path, report) do
    generated_scenario_ids = list_value(callbacks, report, "generated_scenario_ids")

    issues
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "generated_scenario_count",
      length(generated_scenario_ids)
    )
    |> reject_duplicate_ids(callbacks, path <> ".generated_scenario_ids", generated_scenario_ids)
  end

  defp validate_known_limits(issues, callbacks, path, report) do
    case Map.get(report, "known_limits") do
      limits when is_list(limits) ->
        if limits == model_limits(callbacks) do
          issues
        else
          [
            error(
              callbacks,
              "#{path}.known_limits",
              "must match Monte Carlo capability known limits"
            )
            | issues
          ]
        end

      _value ->
        issues
    end
  end

  defp validate_model_limits(issues, callbacks, path, report) do
    case Map.get(report, "model_limits") do
      nil ->
        issues

      :null ->
        issues

      limits when is_list(limits) ->
        if limits == model_limits(callbacks) do
          issues
        else
          [
            error(
              callbacks,
              "#{path}.model_limits",
              "must match Monte Carlo capability model limits"
            )
            | issues
          ]
        end

      _value ->
        issues
    end
  end

  defp model_limits(callbacks),
    do: apply(Keyword.fetch!(callbacks, :monte_carlo_reproducibility_model_limits), [])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_number(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :expect_number), [issues, path, map, field])

  defp expect_non_negative_integer(issues, callbacks, path, map, field),
    do:
      apply(Keyword.fetch!(callbacks, :expect_non_negative_integer), [
        issues,
        path,
        map,
        field
      ])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_field_equals(issues, callbacks, path, map, field, expected),
    do:
      apply(Keyword.fetch!(callbacks, :expect_field_equals), [issues, path, map, field, expected])

  defp expect_number_vector(issues, callbacks, path, value),
    do: apply(Keyword.fetch!(callbacks, :expect_number_vector), [issues, path, value])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_stable_id_list(issues, callbacks, path, values),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_id_list), [issues, path, values])

  defp list_value(callbacks, map, field),
    do: apply(Keyword.fetch!(callbacks, :list_value), [map, field])

  defp reject_duplicate_ids(issues, callbacks, path, ids),
    do: apply(Keyword.fetch!(callbacks, :reject_duplicate_ids), [issues, path, ids])

  defp error(callbacks, path, message),
    do: apply(Keyword.fetch!(callbacks, :error), [path, message])
end
