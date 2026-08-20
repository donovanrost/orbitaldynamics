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
      {%{"resumability" => "local_checkpoint_resume"} = plan, %{} = checkpoint_assumptions} ->
        issues
        |> require_fields("#{path}.execution_plan", plan, ["checkpoint"])
        |> expect_type("#{path}.execution_plan", plan, "checkpoint", :map)
        |> validate_checkpoint_plan(path, plan)
        |> require_fields("#{path}.assumptions", checkpoint_assumptions, [
          "resumability",
          "checkpoint_resume",
          "checkpoint_scope",
          "checkpoint_results_reused",
          "within_scenario_checkpoint",
          "distributed_recovery",
          "batch_recovery",
          "persistent_queue",
          "automatic_retry"
        ])
        |> expect_field_equals(
          "#{path}.assumptions",
          checkpoint_assumptions,
          "resumability",
          "local_checkpoint_resume",
          "must match execution_plan.resumability"
        )
        |> expect_field_equals(
          "#{path}.assumptions",
          checkpoint_assumptions,
          "checkpoint_resume",
          get_in(plan, ["checkpoint", "checkpoint_mode"]) == "resume",
          "must match whether this invocation resumed a checkpoint"
        )
        |> expect_field_equals(
          "#{path}.assumptions",
          checkpoint_assumptions,
          "checkpoint_scope",
          "completed_scenario_propagation_outcomes",
          "must describe the between-scenario checkpoint scope"
        )
        |> expect_field_equals(
          "#{path}.assumptions",
          checkpoint_assumptions,
          "checkpoint_results_reused",
          checkpoint_results_reused?(plan),
          "must match the completed checkpoint reuse count"
        )
        |> expect_field_equals(
          "#{path}.assumptions",
          checkpoint_assumptions,
          "within_scenario_checkpoint",
          false,
          "must remain false for the local checkpoint contract"
        )
        |> expect_field_equals(
          "#{path}.assumptions",
          checkpoint_assumptions,
          "distributed_recovery",
          false,
          "must remain false for the local checkpoint contract"
        )
        |> expect_field_equals(
          "#{path}.assumptions",
          checkpoint_assumptions,
          "batch_recovery",
          false,
          "must remain false for the local checkpoint contract"
        )
        |> expect_field_equals(
          "#{path}.assumptions",
          checkpoint_assumptions,
          "persistent_queue",
          false,
          "must remain false for checkpoint recovery"
        )
        |> expect_field_equals(
          "#{path}.assumptions",
          checkpoint_assumptions,
          "automatic_retry",
          false,
          "must remain false for checkpoint recovery"
        )

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

  defp validate_checkpoint_plan(issues, path, plan) do
    checkpoint = Map.get(plan, "checkpoint")

    case checkpoint do
      %{} ->
        issues
        |> require_fields("#{path}.execution_plan.checkpoint", checkpoint, [
          "schema_contract",
          "schema_version",
          "checkpoint_path",
          "checkpoint_sha256",
          "checkpoint_mode",
          "ordering",
          "scenario_count",
          "reused_scenario_count",
          "run_scenario_count",
          "reused_scenario_indexes",
          "run_scenario_indexes",
          "completed_scenario_count",
          "completed_chunk_count",
          "run_completed_chunk_count",
          "checkpoint_chunk_size",
          "manifest_sha256",
          "study_sha256",
          "model_sha256",
          "run_options_sha256"
        ])
        |> expect_field_equals(
          "#{path}.execution_plan.checkpoint",
          checkpoint,
          "schema_contract",
          "study_checkpoint.v1",
          "must identify the local study checkpoint contract"
        )
        |> expect_field_equals(
          "#{path}.execution_plan.checkpoint",
          checkpoint,
          "schema_version",
          1,
          "must use checkpoint schema version 1"
        )
        |> expect_one_of(
          "#{path}.execution_plan.checkpoint",
          checkpoint,
          "checkpoint_mode",
          ["create", "resume"]
        )
        |> expect_field_equals(
          "#{path}.execution_plan.checkpoint",
          checkpoint,
          "ordering",
          "source_manifest_scenario_order",
          "must preserve source manifest scenario order"
        )
        |> expect_type(
          "#{path}.execution_plan.checkpoint",
          checkpoint,
          "checkpoint_path",
          :binary
        )
        |> expect_type(
          "#{path}.execution_plan.checkpoint",
          checkpoint,
          "checkpoint_sha256",
          :binary
        )
        |> expect_type(
          "#{path}.execution_plan.checkpoint",
          checkpoint,
          "reused_scenario_indexes",
          :list
        )
        |> expect_type(
          "#{path}.execution_plan.checkpoint",
          checkpoint,
          "run_scenario_indexes",
          :list
        )
        |> expect_non_negative_integer(
          "#{path}.execution_plan.checkpoint",
          checkpoint,
          "scenario_count"
        )
        |> expect_non_negative_integer(
          "#{path}.execution_plan.checkpoint",
          checkpoint,
          "reused_scenario_count"
        )
        |> expect_non_negative_integer(
          "#{path}.execution_plan.checkpoint",
          checkpoint,
          "run_scenario_count"
        )
        |> expect_non_negative_integer(
          "#{path}.execution_plan.checkpoint",
          checkpoint,
          "completed_scenario_count"
        )
        |> expect_non_negative_integer(
          "#{path}.execution_plan.checkpoint",
          checkpoint,
          "completed_chunk_count"
        )
        |> expect_non_negative_integer(
          "#{path}.execution_plan.checkpoint",
          checkpoint,
          "run_completed_chunk_count"
        )
        |> expect_non_negative_integer(
          "#{path}.execution_plan.checkpoint",
          checkpoint,
          "checkpoint_chunk_size"
        )
        |> validate_checkpoint_hashes(path, checkpoint)
        |> validate_checkpoint_plan_counts(path, plan, checkpoint)

      _value ->
        issues
    end
  end

  defp checkpoint_results_reused?(plan) do
    case get_in(plan, ["checkpoint", "reused_scenario_count"]) do
      count when is_integer(count) -> count > 0
      _value -> false
    end
  end

  defp validate_checkpoint_hashes(issues, path, checkpoint) do
    [
      "checkpoint_sha256",
      "manifest_sha256",
      "study_sha256",
      "model_sha256",
      "run_options_sha256"
    ]
    |> Enum.reduce(issues, fn field, field_issues ->
      case Map.get(checkpoint, field) do
        <<value::binary-size(64)>> ->
          if String.match?(value, ~r/^[0-9a-f]+$/) do
            field_issues
          else
            [
              error("#{path}.execution_plan.checkpoint.#{field}", "must be lowercase SHA-256")
              | field_issues
            ]
          end

        _value ->
          [
            error("#{path}.execution_plan.checkpoint.#{field}", "must be lowercase SHA-256")
            | field_issues
          ]
      end
    end)
  end

  defp validate_checkpoint_plan_counts(issues, path, plan, checkpoint) do
    scenario_count = Map.get(checkpoint, "scenario_count")
    reused_count = Map.get(checkpoint, "reused_scenario_count")
    run_count = Map.get(checkpoint, "run_scenario_count")
    completed_count = Map.get(checkpoint, "completed_scenario_count")
    reused_indexes = Map.get(checkpoint, "reused_scenario_indexes")
    run_indexes = Map.get(checkpoint, "run_scenario_indexes")
    completed_chunk_count = Map.get(checkpoint, "completed_chunk_count")
    run_completed_chunk_count = Map.get(checkpoint, "run_completed_chunk_count")
    checkpoint_chunk_size = Map.get(checkpoint, "checkpoint_chunk_size")

    valid_partition? =
      is_integer(scenario_count) and scenario_count >= 0 and is_integer(reused_count) and
        is_integer(run_count) and is_integer(completed_count) and is_list(reused_indexes) and
        is_list(run_indexes) and length(reused_indexes) == reused_count and
        length(run_indexes) == run_count and reused_count + run_count == scenario_count and
        completed_count == scenario_count and Map.get(plan, "scenario_count") == scenario_count and
        Enum.sort(reused_indexes ++ run_indexes) == scenario_indexes(scenario_count) and
        is_integer(completed_chunk_count) and completed_chunk_count >= 0 and
        is_integer(run_completed_chunk_count) and run_completed_chunk_count >= 0 and
        run_completed_chunk_count <= completed_chunk_count and
        ((run_count == 0 and run_completed_chunk_count == 0) or
           (run_count > 0 and run_completed_chunk_count > 0)) and
        is_integer(checkpoint_chunk_size) and
        checkpoint_chunk_size > 0

    if valid_partition? do
      issues
    else
      [
        error(
          "#{path}.execution_plan.checkpoint",
          "reuse and run rows must partition the execution plan scenarios exactly"
        )
        | issues
      ]
    end
  end

  defp scenario_indexes(0), do: []
  defp scenario_indexes(count), do: Enum.to_list(0..(count - 1))

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
