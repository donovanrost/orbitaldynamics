defmodule OrbitalDynamics.Schema.ExecutionMetricContracts do
  @moduledoc false

  def validate_optional_actual_data_rate_throughput_derivation(
        issues,
        path,
        map,
        field,
        callbacks
      )
      when is_map(map) and is_list(callbacks) do
    case Map.get(map, field) do
      %{} = derivation ->
        validate_actual_data_rate_throughput_derivation(
          issues,
          "#{path}.#{field}",
          derivation,
          callbacks
        )

      _value ->
        issues
    end
  end

  def validate_optional_actual_data_rate_throughput_derivations(
        issues,
        path,
        map,
        field,
        callbacks
      )
      when is_map(map) and is_list(callbacks) do
    case Map.get(map, field) do
      derivations when is_list(derivations) ->
        derivations
        |> Enum.with_index()
        |> Enum.reduce(issues, fn
          {%{} = derivation, index}, acc ->
            validate_actual_data_rate_throughput_derivation(
              acc,
              "#{path}.#{field}[#{index}]",
              derivation,
              callbacks
            )

          {_value, index}, acc ->
            [error(callbacks, "#{path}.#{field}[#{index}]", "must be an object") | acc]
        end)

      _value ->
        issues
    end
  end

  def validate_optional_execution_uncertainty(issues, path, map, field, callbacks)
      when is_map(map) and is_list(callbacks) do
    case Map.get(map, field) do
      %{} = uncertainty ->
        validate_execution_uncertainty(issues, "#{path}.#{field}", uncertainty, callbacks)

      _value ->
        issues
    end
  end

  defp validate_actual_data_rate_throughput_derivation(issues, path, derivation, callbacks) do
    issues
    |> expect_optional_type(callbacks, path, derivation, "derivation", :binary)
    |> expect_optional_type(callbacks, path, derivation, "rate_unit", :binary)
    |> expect_optional_number(callbacks, path, derivation, "actual_data_rate_mbps")
    |> expect_optional_number(callbacks, path, derivation, "actual_data_rate_mb_s")
    |> expect_optional_number(callbacks, path, derivation, "duration_s")
    |> expect_optional_number(callbacks, path, derivation, "actual_throughput_mb")
  end

  defp validate_execution_uncertainty(issues, path, uncertainty, callbacks) do
    issues
    |> expect_optional_number(callbacks, path, uncertainty, "timing_3sigma_s")
    |> expect_optional_number_vector(callbacks, path, uncertainty, "delta_v_3sigma_km_s")
    |> expect_optional_number(callbacks, path, uncertainty, "delta_v_3sigma_magnitude_km_s")
    |> expect_optional_type(callbacks, path, uncertainty, "source", :binary)
    |> expect_optional_type(callbacks, path, uncertainty, "model", :binary)
  end

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [
        issues,
        path,
        map,
        field,
        type
      ])

  defp expect_optional_number(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_optional_number), [
        issues,
        path,
        map,
        field
      ])

  defp expect_optional_number_vector(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_optional_number_vector), [
        issues,
        path,
        map,
        field
      ])

  defp error(callbacks, path, message),
    do: apply(require_callback(callbacks, :error), [path, message])

  defp require_callback(callbacks, name) do
    Keyword.fetch!(callbacks, name)
  end
end
