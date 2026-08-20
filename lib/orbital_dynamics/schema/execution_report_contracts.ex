defmodule OrbitalDynamics.Schema.ExecutionReportContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_one_of: 5,
      expect_optional_integer: 4,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_ids: 4]

  alias OrbitalDynamics.Schema.CollectionAggregation

  def statuses,
    do: ["completed", "completed_with_errors", "failed", "running", "created"]

  def validate(issues, path, artifact) do
    issues
    |> validate_stable_ids(path, artifact, ["study_id", "run_id"])
    |> expect_equal(path, artifact, "schema_contract", "execution_report.v1")
    |> expect_one_of(path, artifact, "status", statuses())
    |> expect_type(path, artifact, "execution_mode", :binary)
    |> expect_non_negative_integer(path, artifact, "scenario_count")
    |> expect_non_negative_integer(path, artifact, "completed_scenario_count")
    |> expect_non_negative_integer(path, artifact, "failed_scenario_count")
    |> expect_non_negative_integer(path, artifact, "event_result_count")
    |> expect_type(path, artifact, "failed_scenarios", :list)
    |> expect_type(path, artifact, "assumptions", :map)
    |> expect_optional_type(path, artifact, "run_id", :binary)
    |> expect_optional_type(path, artifact, "backend", :binary)
    |> expect_optional_type(path, artifact, "node", :binary)
    |> expect_optional_type(path, artifact, "model_limits", :list)
    |> validate_string_list_items(path, artifact, "model_limits")
    |> validate_model_limits(path, artifact)
    |> validate_resumability(path, artifact)
    |> expect_optional_type(path, artifact, "batch_propagation", :boolean)
    |> expect_optional_integer(path, artifact, "task_chunk_size")
    |> validate_optional_timeout(path, artifact)
    |> expect_optional_integer(path, artifact, "effective_task_concurrency")
    |> expect_optional_type(path, artifact, "task_supervisor_node", :binary)
    |> expect_optional_type(path, artifact, "task_supervisor_nodes", :list)
    |> expect_optional_type(path, artifact, "execution_plan", :map)
    |> expect_optional_type(path, artifact, "phase_timings_ms", :map)
    |> expect_optional_type(path, artifact, "node_distribution", :map)
    |> validate_rows(
      "#{path}.failed_scenarios",
      Map.get(artifact, "failed_scenarios", []),
      &validate_failure/3
    )
    |> validate_counts(path, artifact)
  end

  defp validate_failure(issues, path, failure) do
    issues
    |> require_fields(path, failure, ["scenario_id", "stage", "error"])
    |> validate_stable_ids(path, failure, ["scenario_id"])
    |> expect_type(path, failure, "stage", :binary)
  end

  defp validate_optional_timeout(issues, path, artifact) do
    case Map.get(artifact, "timeout") do
      nil -> issues
      :null -> issues
      value when is_number(value) or is_binary(value) -> issues
      _value -> [error("#{path}.timeout", "must be a number or string") | issues]
    end
  end

  defp validate_model_limits(issues, path, artifact) do
    case Map.get(artifact, "model_limits") do
      nil ->
        issues

      :null ->
        issues

      limits when is_list(limits) ->
        expected_limits =
          OrbitalDynamics.ResultSet.Artifact.execution_report_model_limits(artifact)

        if limits == expected_limits do
          issues
        else
          [error("#{path}.model_limits", "must match execution report model limits") | issues]
        end

      _value ->
        issues
    end
  end

  defp validate_resumability(issues, path, artifact) do
    execution_plan = Map.get(artifact, "execution_plan")
    assumptions = Map.get(artifact, "assumptions")

    case {execution_plan, assumptions} do
      {%{"resumability" => "failed_scenario_retry"} = plan, %{} = retry_assumptions} ->
        issues
        |> require_fields("#{path}.execution_plan", plan, ["retry"])
        |> expect_type("#{path}.execution_plan", plan, "retry", :map)
        |> require_fields("#{path}.assumptions", retry_assumptions, [
          "resumability",
          "retry_scope",
          "checkpoint_resume",
          "source_results_merged",
          "persistent_queue",
          "automatic_retry"
        ])
        |> expect_field_equals(
          "#{path}.assumptions",
          retry_assumptions,
          "resumability",
          "failed_scenario_retry",
          "must match execution_plan.resumability"
        )
        |> expect_field_equals(
          "#{path}.assumptions",
          retry_assumptions,
          "retry_scope",
          "failed_scenarios_only",
          "must describe the failed-scenario-only retry scope"
        )
        |> expect_field_equals(
          "#{path}.assumptions",
          retry_assumptions,
          "checkpoint_resume",
          false,
          "must remain false for retry batches"
        )
        |> expect_field_equals(
          "#{path}.assumptions",
          retry_assumptions,
          "source_results_merged",
          false,
          "must remain false for retry batches"
        )
        |> expect_field_equals(
          "#{path}.assumptions",
          retry_assumptions,
          "persistent_queue",
          false,
          "must remain false for retry batches"
        )
        |> expect_field_equals(
          "#{path}.assumptions",
          retry_assumptions,
          "automatic_retry",
          false,
          "must remain false for explicit retry batches"
        )

      {%{"resumability" => "not_resumable"}, %{} = ordinary_assumptions} ->
        expect_field_equals(
          issues,
          "#{path}.assumptions",
          ordinary_assumptions,
          "resumability",
          "not_resumable",
          "must match execution_plan.resumability"
        )

      _other ->
        issues
    end
  end

  defp validate_counts(issues, path, artifact) do
    issues
    |> expect_derived_field_equals(
      path,
      artifact,
      "scenario_count",
      CollectionAggregation.row_count_sum(artifact, [
        "completed_scenario_count",
        "failed_scenario_count"
      ])
    )
    |> expect_derived_field_equals(
      path,
      artifact,
      "failed_scenario_count",
      CollectionAggregation.list_count(artifact, "failed_scenarios")
    )
    |> validate_status(path, artifact)
    |> validate_execution_plan_counts(path, artifact)
    |> validate_node_distribution_counts(path, artifact)
  end

  defp validate_status(issues, path, artifact) do
    expect_derived_field_equals(issues, path, artifact, "status", expected_status(artifact))
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

  defp validate_execution_plan_counts(issues, path, artifact) do
    case Map.get(artifact, "execution_plan") do
      %{} = execution_plan ->
        expect_derived_field_equals(
          issues,
          path <> ".execution_plan",
          execution_plan,
          "scenario_count",
          Map.get(artifact, "scenario_count")
        )

      _value ->
        issues
    end
  end

  defp validate_node_distribution_counts(issues, path, artifact) do
    scenario_count = Map.get(artifact, "scenario_count")
    node_distribution = Map.get(artifact, "node_distribution")

    case {scenario_count, node_distribution} do
      {count, distribution} when is_integer(count) and is_map(distribution) ->
        values = Map.values(distribution)

        if Enum.all?(values, &is_number/1) and Enum.sum(values) != count do
          [error(path <> ".node_distribution", "must sum to scenario_count") | issues]
        else
          issues
        end

      _value ->
        issues
    end
  end

  defp expect_derived_field_equals(issues, path, map, field, nil),
    do: expect_field_equals(issues, path, map, field, nil, nil)

  defp expect_derived_field_equals(issues, path, map, field, expected),
    do: expect_field_equals(issues, path, map, field, expected, "must equal #{expected}")
end
