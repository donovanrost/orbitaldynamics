defmodule OrbitalDynamics.Schema.ExecutionReportContracts do
  @moduledoc false

  def validate(issues, path, artifact, callbacks) when is_list(callbacks) do
    issues
    |> validate_stable_ids(callbacks, path, artifact, ["study_id", "run_id"])
    |> expect_equal(callbacks, path, artifact, "schema_contract", "execution_report.v1")
    |> expect_one_of(callbacks, path, artifact, "status", execution_statuses(callbacks))
    |> expect_type(callbacks, path, artifact, "execution_mode", :binary)
    |> expect_non_negative_integer(callbacks, path, artifact, "scenario_count")
    |> expect_non_negative_integer(callbacks, path, artifact, "completed_scenario_count")
    |> expect_non_negative_integer(callbacks, path, artifact, "failed_scenario_count")
    |> expect_non_negative_integer(callbacks, path, artifact, "event_result_count")
    |> expect_type(callbacks, path, artifact, "failed_scenarios", :list)
    |> expect_type(callbacks, path, artifact, "assumptions", :map)
    |> expect_optional_type(callbacks, path, artifact, "run_id", :binary)
    |> expect_optional_type(callbacks, path, artifact, "backend", :binary)
    |> expect_optional_type(callbacks, path, artifact, "node", :binary)
    |> expect_optional_type(callbacks, path, artifact, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, artifact, "model_limits")
    |> validate_model_limits(callbacks, path, artifact)
    |> expect_optional_type(callbacks, path, artifact, "batch_propagation", :boolean)
    |> expect_optional_integer(callbacks, path, artifact, "task_chunk_size")
    |> validate_optional_timeout(callbacks, path, artifact)
    |> expect_optional_integer(callbacks, path, artifact, "effective_task_concurrency")
    |> expect_optional_type(callbacks, path, artifact, "task_supervisor_node", :binary)
    |> expect_optional_type(callbacks, path, artifact, "task_supervisor_nodes", :list)
    |> expect_optional_type(callbacks, path, artifact, "execution_plan", :map)
    |> expect_optional_type(callbacks, path, artifact, "phase_timings_ms", :map)
    |> expect_optional_type(callbacks, path, artifact, "node_distribution", :map)
    |> validate_rows(
      callbacks,
      "#{path}.failed_scenarios",
      Map.get(artifact, "failed_scenarios", []),
      fn acc, row_path, failure -> validate_failure(acc, row_path, failure, callbacks) end
    )
    |> validate_counts(callbacks, path, artifact)
  end

  defp validate_failure(issues, path, failure, callbacks) do
    issues
    |> require_fields(callbacks, path, failure, ["scenario_id", "stage", "error"])
    |> validate_stable_ids(callbacks, path, failure, ["scenario_id"])
    |> expect_type(callbacks, path, failure, "stage", :binary)
  end

  defp validate_optional_timeout(issues, callbacks, path, artifact) do
    case Map.get(artifact, "timeout") do
      nil -> issues
      :null -> issues
      value when is_number(value) or is_binary(value) -> issues
      _value -> [error(callbacks, "#{path}.timeout", "must be a number or string") | issues]
    end
  end

  defp validate_model_limits(issues, callbacks, path, artifact) do
    case Map.get(artifact, "model_limits") do
      nil ->
        issues

      :null ->
        issues

      limits when is_list(limits) ->
        if limits == execution_report_model_limits(callbacks) do
          issues
        else
          [
            error(callbacks, "#{path}.model_limits", "must match execution report model limits")
            | issues
          ]
        end

      _value ->
        issues
    end
  end

  defp validate_counts(issues, callbacks, path, artifact) do
    issues
    |> expect_field_equals(
      callbacks,
      path,
      artifact,
      "scenario_count",
      row_count_sum(callbacks, artifact, ["completed_scenario_count", "failed_scenario_count"])
    )
    |> expect_field_equals(
      callbacks,
      path,
      artifact,
      "failed_scenario_count",
      list_count(callbacks, artifact, "failed_scenarios")
    )
    |> validate_status(callbacks, path, artifact)
    |> validate_execution_plan_counts(callbacks, path, artifact)
    |> validate_node_distribution_counts(callbacks, path, artifact)
  end

  defp validate_status(issues, callbacks, path, artifact) do
    expect_field_equals(
      issues,
      callbacks,
      path,
      artifact,
      "status",
      expected_status(artifact)
    )
  end

  defp expected_status(artifact) do
    scenario_count = Map.get(artifact, "scenario_count")
    completed_count = Map.get(artifact, "completed_scenario_count")
    failed_count = Map.get(artifact, "failed_scenario_count")

    cond do
      not (is_integer(scenario_count) and is_integer(completed_count) and is_integer(failed_count)) ->
        nil

      completed_count + failed_count != scenario_count ->
        nil

      scenario_count <= 0 ->
        nil

      failed_count == 0 and completed_count == scenario_count ->
        "completed"

      failed_count > 0 and completed_count > 0 ->
        "completed_with_errors"

      failed_count > 0 and completed_count == 0 ->
        "failed"

      true ->
        nil
    end
  end

  defp validate_execution_plan_counts(issues, callbacks, path, artifact) do
    case Map.get(artifact, "execution_plan") do
      %{} = execution_plan ->
        expect_field_equals(
          issues,
          callbacks,
          path <> ".execution_plan",
          execution_plan,
          "scenario_count",
          Map.get(artifact, "scenario_count")
        )

      _value ->
        issues
    end
  end

  defp validate_node_distribution_counts(issues, callbacks, path, artifact) do
    scenario_count = Map.get(artifact, "scenario_count")
    node_distribution = Map.get(artifact, "node_distribution")

    case {scenario_count, node_distribution} do
      {count, distribution} when is_integer(count) and is_map(distribution) ->
        values = Map.values(distribution)

        if Enum.all?(values, &is_number/1) and Enum.sum(values) != count do
          [error(callbacks, path <> ".node_distribution", "must sum to scenario_count") | issues]
        else
          issues
        end

      _value ->
        issues
    end
  end

  defp execution_statuses(callbacks),
    do: apply(Keyword.fetch!(callbacks, :execution_statuses), [])

  defp execution_report_model_limits(callbacks),
    do: apply(Keyword.fetch!(callbacks, :execution_report_model_limits), [])

  defp row_count_sum(callbacks, report, fields),
    do: apply(Keyword.fetch!(callbacks, :row_count_sum), [report, fields])

  defp list_count(callbacks, map, field),
    do: apply(Keyword.fetch!(callbacks, :list_count), [map, field])

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :require_fields), [issues, path, map, fields])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_one_of(issues, callbacks, path, map, field, allowed),
    do: apply(Keyword.fetch!(callbacks, :expect_one_of), [issues, path, map, field, allowed])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_optional_integer(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_integer), [issues, path, map, field])

  defp expect_non_negative_integer(issues, callbacks, path, map, field),
    do:
      apply(Keyword.fetch!(callbacks, :expect_non_negative_integer), [
        issues,
        path,
        map,
        field
      ])

  defp expect_field_equals(issues, callbacks, path, map, field, expected),
    do:
      apply(Keyword.fetch!(callbacks, :expect_field_equals), [issues, path, map, field, expected])

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(Keyword.fetch!(callbacks, :validate_rows), [issues, path, rows, validator])

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp error(callbacks, path, message),
    do: apply(Keyword.fetch!(callbacks, :error), [path, message])
end
