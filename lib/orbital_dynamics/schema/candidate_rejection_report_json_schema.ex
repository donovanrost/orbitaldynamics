defmodule OrbitalDynamics.Schema.CandidateRejectionReportJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @count_fields [
    "candidate_count",
    "row_count",
    "rejected_count",
    "not_rejected_count",
    "reviewable_count",
    "invalid_candidate_input_count"
  ]

  @stable_id_array_fields [
    "rejected_candidate_ids",
    "not_rejected_candidate_ids",
    "reviewable_candidate_ids",
    "invalid_candidate_input_ids"
  ]

  @rejection_reason_fields [
    "rejection_reason_counts",
    "candidate_id_sets_by_rejection_reason"
  ]

  @operator_action_fields [
    "candidate_ids_by_required_operator_action",
    "required_operator_action_counts"
  ]

  def model_limits do
    [
      "artifact_only",
      "does_not_select_candidates",
      "does_not_mutate_schedules",
      "derived_reasons_use_declared_candidate_fields"
    ]
  end

  def property_field?(field)
      when field in [
             "model_limits",
             "rows",
             "model",
             "source"
           ],
      do: true

  def property_field?(field)
      when field in @count_fields or field in @stable_id_array_fields or
             field in @rejection_reason_fields or field in @operator_action_fields,
      do: true

  def property_field?(_field), do: false

  def property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts("rows", deps) do
    [row_schema: fetch_dep!(deps, :row_schema)]
  end

  def property_opts(field, deps) when field in @rejection_reason_fields do
    [
      rejection_reasons: fetch_dep!(deps, :rejection_reasons),
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)
    ]
  end

  def property_opts(field, deps) when field in @operator_action_fields do
    [
      required_operator_actions: fetch_dep!(deps, :required_operator_actions),
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)
    ]
  end

  def property_opts(field, deps) when field in @stable_id_array_fields do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts(_field, _deps), do: []

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property_fun_from_context(deps) when is_list(deps) do
    fn field -> property_from_context(field, deps) end
  end

  def row_from_context(
        stable_id_pattern,
        timeline_capability,
        string_array_schema,
        activity_context_schema
      ) do
    row(
      stable_id_pattern: stable_id_pattern,
      timeline_capability: timeline_capability,
      string_array_schema: string_array_schema,
      activity_context_schema: activity_context_schema
    )
  end

  def row_from_context(deps) when is_list(deps) do
    row(
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern),
      timeline_capability: fetch_dep!(deps, :timeline_capability),
      string_array_schema: fetch_dep!(deps, :string_array_schema),
      activity_context_schema: fetch_dep!(deps, :activity_context_schema)
    )
  end

  def row(opts) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "id",
        "candidate_id",
        "rejection_status",
        "rejection_reasons",
        "reason_count",
        "reviewable",
        "required_operator_action",
        "activity_context"
      ],
      "properties" => candidate_properties(opts)
    }
  end

  def source_from_context(
        stable_id_pattern,
        timeline_capability,
        string_array_schema,
        activity_context_schema
      ) do
    source(
      stable_id_pattern: stable_id_pattern,
      timeline_capability: timeline_capability,
      string_array_schema: string_array_schema,
      activity_context_schema: activity_context_schema
    )
  end

  def source_from_context(deps) when is_list(deps) do
    source_from_context(
      fetch_dep!(deps, :stable_id_pattern),
      fetch_dep!(deps, :timeline_capability),
      fetch_dep!(deps, :string_array_schema),
      fetch_dep!(deps, :activity_context_schema)
    )
  end

  def source(opts) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => candidate_properties(opts)
    }
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property("rows", opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :row_schema)}
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_candidate_rejection_explanation"}
  end

  def property("source", _opts) do
    %{"type" => "string"}
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("rejection_reason_counts", opts) do
    opts
    |> Keyword.fetch!(:rejection_reasons)
    |> CommonJsonSchema.enum_count_map()
  end

  def property("candidate_id_sets_by_rejection_reason", opts) do
    enum_stable_id_array_map(
      Keyword.fetch!(opts, :rejection_reasons),
      Keyword.fetch!(opts, :stable_id_pattern)
    )
  end

  def property("candidate_ids_by_required_operator_action", opts) do
    enum_stable_id_array_map(
      Keyword.fetch!(opts, :required_operator_actions),
      Keyword.fetch!(opts, :stable_id_pattern)
    )
  end

  def property(field, opts) when field in @stable_id_array_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property("required_operator_action_counts", opts) do
    opts
    |> Keyword.fetch!(:required_operator_actions)
    |> CommonJsonSchema.enum_count_map()
  end

  defp enum_stable_id_array_map(values, stable_id_pattern) do
    %{
      "type" => "object",
      "propertyNames" => %{"enum" => values},
      "additionalProperties" => CommonJsonSchema.stable_id_array(stable_id_pattern)
    }
  end

  defp candidate_properties(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    capability = Keyword.fetch!(opts, :timeline_capability)

    %{
      "id" => stable_id_schema(stable_id_pattern),
      "candidate_id" => stable_id_schema(stable_id_pattern),
      "activity_id" => stable_id_schema(stable_id_pattern),
      "timeline_id" => stable_id_schema(stable_id_pattern),
      "activity_type" => %{"type" => "string"},
      "operational_kind" => %{
        "type" => "string",
        "enum" => capability.operational_kinds
      },
      "source_window_id" => stable_id_schema(stable_id_pattern),
      "source_window_type" => %{"type" => "string"},
      "rejection_status" => %{"type" => "string", "enum" => ["rejected", "not_rejected"]},
      "primary_rejection_reason" => %{
        "type" => "string",
        "enum" => capability.candidate_rejection_reasons
      },
      "rejection_reasons" => %{
        "type" => "array",
        "items" => %{
          "type" => "string",
          "enum" => capability.candidate_rejection_reasons
        }
      },
      "reason_count" => %{"type" => "integer", "minimum" => 0},
      "reviewable" => %{"type" => "boolean"},
      "required_operator_action" => %{
        "type" => "string",
        "enum" => capability.candidate_rejection_actions
      },
      "violated_constraint" => %{"type" => "string"},
      "required_margin" => %{"type" => "number"},
      "actual_margin" => %{"type" => "number"},
      "declared_rejection_reasons" => Keyword.fetch!(opts, :string_array_schema),
      "activity_context" => Keyword.fetch!(opts, :activity_context_schema)
    }
  end

  defp stable_id_schema(stable_id_pattern) do
    %{"type" => "string", "pattern" => stable_id_pattern}
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
