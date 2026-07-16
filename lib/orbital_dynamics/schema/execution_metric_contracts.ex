defmodule OrbitalDynamics.Schema.ExecutionMetricContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.PrimitiveValidation

  def validate_optional_actual_data_rate_throughput_derivation(issues, path, map, field)
      when is_map(map) do
    case Map.get(map, field) do
      %{} = derivation ->
        validate_actual_data_rate_throughput_derivation(
          issues,
          "#{path}.#{field}",
          derivation
        )

      _value ->
        issues
    end
  end

  def validate_optional_actual_data_rate_throughput_derivations(issues, path, map, field)
      when is_map(map) do
    case Map.get(map, field) do
      derivations when is_list(derivations) ->
        derivations
        |> Enum.with_index()
        |> Enum.reduce(issues, fn
          {%{} = derivation, index}, acc ->
            validate_actual_data_rate_throughput_derivation(
              acc,
              "#{path}.#{field}[#{index}]",
              derivation
            )

          {_value, index}, acc ->
            [PrimitiveValidation.error("#{path}.#{field}[#{index}]", "must be an object") | acc]
        end)

      _value ->
        issues
    end
  end

  def validate_optional_execution_uncertainty(issues, path, map, field) when is_map(map) do
    case Map.get(map, field) do
      %{} = uncertainty ->
        validate_execution_uncertainty(issues, "#{path}.#{field}", uncertainty)

      _value ->
        issues
    end
  end

  defp validate_actual_data_rate_throughput_derivation(issues, path, derivation) do
    issues
    |> PrimitiveValidation.expect_optional_type(path, derivation, "derivation", :binary)
    |> PrimitiveValidation.expect_optional_type(path, derivation, "rate_unit", :binary)
    |> PrimitiveValidation.expect_optional_number(path, derivation, "actual_data_rate_mbps")
    |> PrimitiveValidation.expect_optional_number(path, derivation, "actual_data_rate_mb_s")
    |> PrimitiveValidation.expect_optional_number(path, derivation, "duration_s")
    |> PrimitiveValidation.expect_optional_number(path, derivation, "actual_throughput_mb")
  end

  defp validate_execution_uncertainty(issues, path, uncertainty) do
    issues
    |> PrimitiveValidation.expect_optional_number(path, uncertainty, "timing_3sigma_s")
    |> PrimitiveValidation.expect_optional_number_vector(
      path,
      uncertainty,
      "delta_v_3sigma_km_s"
    )
    |> PrimitiveValidation.expect_optional_number(
      path,
      uncertainty,
      "delta_v_3sigma_magnitude_km_s"
    )
    |> PrimitiveValidation.expect_optional_type(path, uncertainty, "source", :binary)
    |> PrimitiveValidation.expect_optional_type(path, uncertainty, "model", :binary)
  end
end
