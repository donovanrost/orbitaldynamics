defmodule OrbitalDynamics.Schema.ExecutionReportJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.ValidationJsonSchema

  @count_fields [
    "scenario_count",
    "completed_scenario_count",
    "failed_scenario_count",
    "event_result_count"
  ]

  @stable_id_fields [
    "study_id",
    "run_id"
  ]

  @string_fields [
    "status",
    "execution_mode",
    "backend",
    "node",
    "task_supervisor_node"
  ]

  @integer_fields [
    "task_chunk_size",
    "effective_task_concurrency"
  ]

  @object_fields [
    "execution_plan",
    "phase_timings_ms",
    "node_distribution"
  ]

  def property("schema_contract", opts) do
    %{
      "type" => "string",
      "const" => Keyword.fetch!(opts, :schema_contract),
      "description" => "Stable executable contract identifier"
    }
  end

  def property(field, opts) when field in @stable_id_fields do
    %{"type" => "string", "pattern" => Keyword.fetch!(opts, :stable_id_pattern)}
  end

  def property(field, _opts) when field in @string_fields do
    %{"type" => "string"}
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "items" => %{
        "type" => "string",
        "enum" => model_limits
      }
    }
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, _opts) when field in @integer_fields do
    %{"type" => "integer"}
  end

  def property("batch_propagation", _opts) do
    %{"type" => "boolean"}
  end

  def property(field, _opts) when field in @object_fields do
    %{"type" => "object"}
  end

  def property("assumptions", _opts) do
    %{"type" => "object"}
  end

  def property("timeout", _opts) do
    %{"oneOf" => [%{"type" => "number"}, %{"type" => "string"}, %{"type" => "null"}]}
  end

  def property("task_supervisor_nodes", _opts) do
    %{
      "oneOf" => [
        %{"type" => "array", "items" => %{"type" => "string"}},
        %{"type" => "null"}
      ]
    }
  end

  def property("failed_scenarios", opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :failure_schema)
    }
  end

  def failure(stable_id_pattern) do
    ValidationJsonSchema.execution_failure(stable_id_pattern)
  end
end
