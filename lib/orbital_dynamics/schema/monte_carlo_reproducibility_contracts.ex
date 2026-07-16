defmodule OrbitalDynamics.Schema.MonteCarloReproducibilityContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_number: 4,
      expect_number_vector: 3,
      expect_optional_type: 5,
      expect_type: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [reject_duplicate_ids: 3, validate_stable_id_list: 3]

  def model_limits do
    OrbitalDynamics.Search.MonteCarlo.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end

  def validate(issues, path, report) do
    issues
    |> expect_equal(path, report, "schema_contract", "monte_carlo_reproducibility_report.v1")
    |> expect_equal(path, report, "model", "seeded_independent_normal_cartesian_dispersion")
    |> expect_type(path, report, "source", :binary)
    |> expect_type(path, report, "generator", :binary)
    |> expect_type(path, report, "rng", :binary)
    |> expect_type(path, report, "sampling_method", :binary)
    |> expect_type(path, report, "deterministic_seed", :boolean)
    |> expect_number(path, report, "seed")
    |> expect_non_negative_integer(path, report, "requested_count")
    |> expect_non_negative_integer(path, report, "generated_scenario_count")
    |> expect_type(path, report, "generated_scenario_ids", :list)
    |> validate_stable_id_list(
      path <> ".generated_scenario_ids",
      Map.get(report, "generated_scenario_ids", [])
    )
    |> expect_number_vector(path <> ".position_sigma_km", Map.get(report, "position_sigma_km"))
    |> expect_number_vector(
      path <> ".velocity_sigma_km_s",
      Map.get(report, "velocity_sigma_km_s")
    )
    |> expect_type(path, report, "seed_manifest", :map)
    |> expect_type(path, report, "assumptions", :map)
    |> expect_type(path, report, "known_limits", :list)
    |> validate_string_list_items(path, report, "known_limits")
    |> validate_known_limits(path, report)
    |> expect_optional_type(path, report, "model_limits", :list)
    |> validate_string_list_items(path, report, "model_limits")
    |> validate_model_limits(path, report)
    |> validate_counts(path, report)
  end

  defp validate_counts(issues, path, report) do
    generated_scenario_ids = list_value(report, "generated_scenario_ids")
    generated_scenario_count = length(generated_scenario_ids)

    issues
    |> expect_field_equals(
      path,
      report,
      "generated_scenario_count",
      generated_scenario_count,
      "must equal #{generated_scenario_count}"
    )
    |> reject_duplicate_ids(path <> ".generated_scenario_ids", generated_scenario_ids)
  end

  defp validate_known_limits(issues, path, report) do
    case Map.get(report, "known_limits") do
      limits when is_list(limits) ->
        if limits == model_limits() do
          issues
        else
          [
            error("#{path}.known_limits", "must match Monte Carlo capability known limits")
            | issues
          ]
        end

      _value ->
        issues
    end
  end

  defp validate_model_limits(issues, path, report) do
    case Map.get(report, "model_limits") do
      nil ->
        issues

      :null ->
        issues

      limits when is_list(limits) ->
        if limits == model_limits() do
          issues
        else
          [
            error("#{path}.model_limits", "must match Monte Carlo capability model limits")
            | issues
          ]
        end

      _value ->
        issues
    end
  end

  defp list_value(map, key) when is_map(map), do: Map.get(map, key) || []
  defp list_value(_map, _key), do: []
end
