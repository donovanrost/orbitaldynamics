defmodule OrbitalDynamics.Schema.StudyBenchmarkContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]
  import OrbitalDynamics.Schema.SchemaContractField, only: [validate_optional: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_equal: 5,
      expect_field_equals: 6,
      expect_optional_non_negative_integer: 4,
      expect_optional_non_negative_number: 4,
      expect_optional_one_of: 5,
      expect_optional_type: 5,
      expect_type: 5,
      validate_non_negative_integer_count_map: 3,
      validate_non_negative_integer_list_items: 4,
      validate_string_list_items: 4
    ]

  def validate(issues, path, artifact) do
    benchmark_options = Map.get(artifact, "benchmark_options", %{})
    results = Map.get(artifact, "results", [])

    issues
    |> expect_equal(path, artifact, "schema_version", 1)
    |> expect_type(path, artifact, "manifest", :map)
    |> expect_type(path, artifact, "benchmark_options", :map)
    |> expect_type(path, artifact, "results", :list)
    |> validate_optional(path, artifact, "study_benchmark.v1")
    |> validate_options("#{path}.benchmark_options", benchmark_options)
    |> validate_rows("#{path}.results", results, &validate_result/3)
    |> validate_result_options(path, benchmark_options, results)
  end

  defp validate_options(issues, path, options) when is_map(options) do
    issues
    |> expect_optional_type(path, options, "modes", :list)
    |> expect_optional_type(path, options, "propagators", :list)
    |> expect_optional_type(path, options, "task_supervisor_node", :binary)
    |> expect_optional_non_negative_integer(path, options, "max_concurrency")
    |> expect_optional_non_negative_integer(path, options, "repetitions")
    |> expect_optional_type(path, options, "max_concurrencies", :list)
    |> expect_optional_type(path, options, "monte_carlo_counts", :list)
    |> expect_optional_type(path, options, "task_chunk_sizes", :list)
    |> validate_string_list_items(path, options, "modes")
    |> validate_string_list_items(path, options, "propagators")
    |> validate_non_negative_integer_list_items(path, options, "max_concurrencies")
    |> validate_non_negative_integer_list_items(path, options, "monte_carlo_counts")
    |> validate_non_negative_integer_list_items(path, options, "task_chunk_sizes")
  end

  defp validate_options(issues, _path, _options), do: issues

  defp validate_result(issues, path, result) do
    issues
    |> expect_type(path, result, "id", :binary)
    |> expect_optional_type(path, result, "backend", :binary)
    |> expect_optional_type(path, result, "execution_mode", :binary)
    |> expect_optional_type(path, result, "mode", :binary)
    |> expect_optional_type(path, result, "propagator", :binary)
    |> expect_optional_type(path, result, "task_supervisor_node", :binary)
    |> expect_optional_type(path, result, "batch_propagation", :boolean)
    |> expect_optional_type(path, result, "matches_baseline", :boolean)
    |> expect_optional_type(path, result, "output_signature", :map)
    |> expect_optional_type(path, result, "per_node_trajectory_counts", :map)
    |> expect_optional_type(path, result, "runtime_telemetry", :map)
    |> validate_result_integer_fields(path, result)
    |> validate_result_number_fields(path, result)
    |> validate_non_negative_integer_count_map(
      "#{path}.per_node_trajectory_counts",
      Map.get(result, "per_node_trajectory_counts", %{})
    )
    |> validate_output_signature(path, Map.get(result, "output_signature"))
    |> validate_result_counts(path, result)
  end

  defp validate_result_integer_fields(issues, path, result) do
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
        expect_optional_non_negative_integer(acc, path, result, field)
      end
    )
  end

  defp validate_result_number_fields(issues, path, result) do
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
        expect_optional_non_negative_number(acc, path, result, field)
      end
    )
  end

  defp validate_output_signature(issues, path, signature) when is_map(signature) do
    signature_path = "#{path}.output_signature"

    issues
    |> expect_optional_type(signature_path, signature, "constraints", :list)
    |> expect_optional_type(signature_path, signature, "ranking", :list)
    |> expect_optional_type(signature_path, signature, "scenario_ids", :list)
    |> validate_string_list_items(signature_path, signature, "ranking")
    |> validate_string_list_items(signature_path, signature, "scenario_ids")
  end

  defp validate_output_signature(issues, _path, _signature), do: issues

  defp validate_result_counts(issues, path, result) do
    signature = Map.get(result, "output_signature")

    issues
    |> expect_field_equals(
      path,
      result,
      "scenario_count",
      scenario_count(signature),
      "must equal output_signature scenario_ids count"
    )
    |> expect_field_equals(
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

  defp validate_result_options(issues, path, options, results)
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
          result_path,
          result,
          "repetitions",
          option_repetitions(repetitions),
          "must equal benchmark_options repetitions"
        )
        |> expect_optional_one_of(
          result_path,
          result,
          "mode",
          option_modes(modes)
        )

      {_result, _index}, acc ->
        acc
    end)
  end

  defp validate_result_options(issues, _path, _options, _results), do: issues

  defp option_repetitions(value) when is_integer(value) and value >= 0, do: value
  defp option_repetitions(_value), do: nil

  defp option_modes(modes) when is_list(modes), do: modes
  defp option_modes(_modes), do: []
end
