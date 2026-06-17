defmodule OrbitalDynamics.Schema.StudyBenchmarkContracts do
  @moduledoc false

  def validate(issues, path, artifact, callbacks) when is_list(callbacks) do
    benchmark_options = Map.get(artifact, "benchmark_options", %{})
    results = Map.get(artifact, "results", [])

    issues
    |> expect_equal(callbacks, path, artifact, "schema_version", 1)
    |> expect_type(callbacks, path, artifact, "manifest", :map)
    |> expect_type(callbacks, path, artifact, "benchmark_options", :map)
    |> expect_type(callbacks, path, artifact, "results", :list)
    |> validate_optional_schema_contract(callbacks, path, artifact, "study_benchmark.v1")
    |> validate_options(callbacks, "#{path}.benchmark_options", benchmark_options)
    |> validate_rows(callbacks, "#{path}.results", results, fn acc, row_path, result ->
      validate_result(acc, row_path, result, callbacks)
    end)
    |> validate_result_options(callbacks, path, benchmark_options, results)
  end

  defp validate_options(issues, callbacks, path, options) when is_map(options) do
    issues
    |> expect_optional_type(callbacks, path, options, "modes", :list)
    |> expect_optional_type(callbacks, path, options, "propagators", :list)
    |> expect_optional_type(callbacks, path, options, "task_supervisor_node", :binary)
    |> expect_optional_non_negative_integer(callbacks, path, options, "max_concurrency")
    |> expect_optional_non_negative_integer(callbacks, path, options, "repetitions")
    |> expect_optional_type(callbacks, path, options, "max_concurrencies", :list)
    |> expect_optional_type(callbacks, path, options, "monte_carlo_counts", :list)
    |> expect_optional_type(callbacks, path, options, "task_chunk_sizes", :list)
    |> validate_string_list_items(callbacks, path, options, "modes")
    |> validate_string_list_items(callbacks, path, options, "propagators")
    |> validate_non_negative_integer_list_items(callbacks, path, options, "max_concurrencies")
    |> validate_non_negative_integer_list_items(callbacks, path, options, "monte_carlo_counts")
    |> validate_non_negative_integer_list_items(callbacks, path, options, "task_chunk_sizes")
  end

  defp validate_options(issues, _callbacks, _path, _options), do: issues

  defp validate_result(issues, path, result, callbacks) do
    issues
    |> expect_type(callbacks, path, result, "id", :binary)
    |> expect_optional_type(callbacks, path, result, "backend", :binary)
    |> expect_optional_type(callbacks, path, result, "execution_mode", :binary)
    |> expect_optional_type(callbacks, path, result, "mode", :binary)
    |> expect_optional_type(callbacks, path, result, "propagator", :binary)
    |> expect_optional_type(callbacks, path, result, "task_supervisor_node", :binary)
    |> expect_optional_type(callbacks, path, result, "batch_propagation", :boolean)
    |> expect_optional_type(callbacks, path, result, "matches_baseline", :boolean)
    |> expect_optional_type(callbacks, path, result, "output_signature", :map)
    |> expect_optional_type(callbacks, path, result, "per_node_trajectory_counts", :map)
    |> expect_optional_type(callbacks, path, result, "runtime_telemetry", :map)
    |> validate_result_integer_fields(callbacks, path, result)
    |> validate_result_number_fields(callbacks, path, result)
    |> validate_non_negative_integer_count_map(
      callbacks,
      "#{path}.per_node_trajectory_counts",
      Map.get(result, "per_node_trajectory_counts", %{})
    )
    |> validate_output_signature(callbacks, path, Map.get(result, "output_signature"))
    |> validate_result_counts(callbacks, path, result)
  end

  defp validate_result_integer_fields(issues, callbacks, path, result) do
    Enum.reduce(
      [
        "effective_task_concurrency",
        "failure_count",
        "max_concurrency",
        "monte_carlo_count",
        "repetition",
        "repetitions",
        "scenario_count",
        "task_chunk_size",
        "trajectory_count"
      ],
      issues,
      fn field, acc ->
        expect_optional_non_negative_integer(acc, callbacks, path, result, field)
      end
    )
  end

  defp validate_result_number_fields(issues, callbacks, path, result) do
    Enum.reduce(
      [
        "artifact_build_ms",
        "duration_ms",
        "event_detection_ms",
        "overhead_ms",
        "overhead_percent",
        "propagation_ms",
        "scenarios_per_second"
      ],
      issues,
      fn field, acc ->
        expect_optional_non_negative_number(acc, callbacks, path, result, field)
      end
    )
  end

  defp validate_output_signature(issues, callbacks, path, signature)
       when is_map(signature) do
    signature_path = "#{path}.output_signature"

    issues
    |> expect_optional_type(callbacks, signature_path, signature, "constraints", :list)
    |> expect_optional_type(callbacks, signature_path, signature, "ranking", :list)
    |> expect_optional_type(callbacks, signature_path, signature, "scenario_ids", :list)
    |> validate_string_list_items(callbacks, signature_path, signature, "ranking")
    |> validate_string_list_items(callbacks, signature_path, signature, "scenario_ids")
  end

  defp validate_output_signature(issues, _callbacks, _path, _signature), do: issues

  defp validate_result_counts(issues, callbacks, path, result) do
    signature = Map.get(result, "output_signature")

    issues
    |> expect_field_equals(
      callbacks,
      path,
      result,
      "scenario_count",
      scenario_count(signature),
      "must equal output_signature scenario_ids count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      result,
      "trajectory_count",
      trajectory_count(Map.get(result, "per_node_trajectory_counts")),
      "must equal per_node_trajectory_counts sum"
    )
  end

  defp scenario_count(%{"scenario_ids" => scenario_ids}) when is_list(scenario_ids),
    do: length(scenario_ids)

  defp scenario_count(_signature), do: nil

  defp trajectory_count(counts) when is_map(counts) do
    values = Map.values(counts)

    if Enum.all?(values, &(is_integer(&1) and &1 >= 0)),
      do: Enum.sum(values),
      else: nil
  end

  defp trajectory_count(_counts), do: nil

  defp validate_result_options(issues, callbacks, path, options, results)
       when is_map(options) and is_list(results) do
    repetitions = Map.get(options, "repetitions")
    modes = Map.get(options, "modes")

    results
    |> Enum.with_index()
    |> Enum.reduce(issues, fn
      {result, index}, acc when is_map(result) ->
        result_path = "#{path}.results[#{index}]"

        acc
        |> expect_field_equals(
          callbacks,
          result_path,
          result,
          "repetitions",
          option_repetitions(repetitions),
          "must equal benchmark_options repetitions"
        )
        |> expect_optional_one_of(
          callbacks,
          result_path,
          result,
          "mode",
          option_modes(modes)
        )

      {_result, _index}, acc ->
        acc
    end)
  end

  defp validate_result_options(issues, _callbacks, _path, _options, _results), do: issues

  defp option_repetitions(value) when is_integer(value) and value >= 0, do: value
  defp option_repetitions(_value), do: nil

  defp option_modes(modes) when is_list(modes), do: modes
  defp option_modes(_modes), do: []

  defp validate_optional_schema_contract(issues, callbacks, path, artifact, expected),
    do:
      apply(Keyword.fetch!(callbacks, :validate_optional_schema_contract), [
        issues,
        path,
        artifact,
        expected
      ])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_optional_non_negative_integer(issues, callbacks, path, map, field),
    do:
      apply(Keyword.fetch!(callbacks, :expect_optional_non_negative_integer), [
        issues,
        path,
        map,
        field
      ])

  defp expect_optional_non_negative_number(issues, callbacks, path, map, field),
    do:
      apply(Keyword.fetch!(callbacks, :expect_optional_non_negative_number), [
        issues,
        path,
        map,
        field
      ])

  defp expect_optional_one_of(issues, callbacks, path, map, field, allowed),
    do:
      apply(Keyword.fetch!(callbacks, :expect_optional_one_of), [
        issues,
        path,
        map,
        field,
        allowed
      ])

  defp expect_field_equals(issues, callbacks, path, map, field, expected, message),
    do:
      apply(Keyword.fetch!(callbacks, :expect_field_equals_with_message), [
        issues,
        path,
        map,
        field,
        expected,
        message
      ])

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(Keyword.fetch!(callbacks, :validate_rows), [issues, path, rows, validator])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_non_negative_integer_list_items(issues, callbacks, path, map, field),
    do:
      apply(Keyword.fetch!(callbacks, :validate_non_negative_integer_list_items), [
        issues,
        path,
        map,
        field
      ])

  defp validate_non_negative_integer_count_map(issues, callbacks, path, map),
    do:
      apply(Keyword.fetch!(callbacks, :validate_non_negative_integer_count_map), [
        issues,
        path,
        map
      ])
end
