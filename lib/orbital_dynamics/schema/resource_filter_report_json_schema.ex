defmodule OrbitalDynamics.Schema.ResourceFilterReportJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @stable_id_array_fields [
    "invalid_candidate_input_ids",
    "invalid_resource_summary_input_ids"
  ]

  @count_fields [
    "input_resource_summary_count",
    "valid_resource_summary_count",
    "invalid_resource_summary_input_count",
    "input_candidate_count",
    "kept_candidate_count",
    "suppressed_candidate_count",
    "invalid_candidate_input_count",
    "duplicate_suppressed_candidate_row_count",
    "duplicate_suppressed_candidate_id_count"
  ]

  @count_map_fields [
    "resource_source_quality_counts",
    "resource_trust_boundary_status_counts",
    "suppressed_resource_source_quality_counts",
    "suppressed_resource_trust_boundary_status_counts"
  ]

  @stable_id_array_map_fields [
    "suppressed_candidate_ids_by_resource_source_quality",
    "suppressed_candidate_ids_by_resource_trust_boundary_status"
  ]

  def property_field?(field)
      when field in [
             "model",
             "model_limits",
             "assumptions",
             "suppressed_candidates"
           ],
      do: true

  def property_field?(field)
      when field in @stable_id_array_fields or field in @count_fields or
             field in @count_map_fields or field in @stable_id_array_map_fields,
      do: true

  def property_field?(_field), do: false

  def property_fun_from_context(deps) when is_list(deps) do
    fn field -> property_from_context(field, deps) end
  end

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts("assumptions", deps) do
    [assumptions_schema: fetch_dep!(deps, :assumptions_schema)]
  end

  def property_opts("suppressed_candidates", deps) do
    [suppressed_candidate_schema: fetch_dep!(deps, :suppressed_candidate_schema)]
  end

  def property_opts(field, deps)
      when field in @stable_id_array_fields or field in @stable_id_array_map_fields do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts(_field, _deps), do: []

  def property("model", _opts) do
    %{"type" => "string", "const" => "resource_summary_availability_and_margin_filter"}
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property("assumptions", opts) do
    Keyword.fetch!(opts, :assumptions_schema)
  end

  def property("suppressed_candidates", opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :suppressed_candidate_schema)}
  end

  def property(field, opts) when field in @stable_id_array_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, _opts) when field in @count_map_fields do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def property(field, opts) when field in @stable_id_array_map_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array_map()
  end

  def assumptions_from_deps(deps) do
    deps
    |> assumptions_opts()
    |> assumptions()
  end

  def assumptions_from_context(
        string_array_schema,
        resource_filter_policy_fields,
        resource_availability_aliases,
        resource_degraded_aliases,
        resource_margin_aliases,
        resource_power_margin_source_aliases,
        resource_availability_true_tokens,
        resource_availability_false_tokens,
        provider_direction_aliases,
        station_calendar_direction_aliases,
        provider_result_map_value_keys,
        candidate_stable_identity_fields,
        station_calendar_id_list_fields,
        suppression_reasons,
        row_review_statuses
      ) do
    [
      string_array_schema: string_array_schema,
      resource_filter_policy_fields: resource_filter_policy_fields,
      resource_availability_aliases: resource_availability_aliases,
      resource_degraded_aliases: resource_degraded_aliases,
      resource_margin_aliases: resource_margin_aliases,
      resource_power_margin_source_aliases: resource_power_margin_source_aliases,
      resource_availability_true_tokens: resource_availability_true_tokens,
      resource_availability_false_tokens: resource_availability_false_tokens,
      provider_direction_aliases: provider_direction_aliases,
      station_calendar_direction_aliases: station_calendar_direction_aliases,
      provider_result_map_value_keys: provider_result_map_value_keys,
      candidate_stable_identity_fields: candidate_stable_identity_fields,
      station_calendar_id_list_fields: station_calendar_id_list_fields,
      suppression_reasons: suppression_reasons,
      row_review_statuses: row_review_statuses
    ]
    |> assumptions_opts()
    |> assumptions()
  end

  def assumptions(opts) do
    string_array_schema = Keyword.fetch!(opts, :string_array_schema)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["execution_boundary", "operator_authority", "resource_state_propagation"],
      "properties" => %{
        "execution_boundary" => %{
          "type" => "string",
          "const" => "artifact_only_no_schedule_mutation"
        },
        "operator_authority" => %{
          "type" => "string",
          "const" => "not_granted_by_resource_filter"
        },
        "resource_state_propagation" => %{"type" => "string", "const" => "not_performed"},
        "resource_filter_policy_fields" =>
          enum_array_const(Keyword.fetch!(opts, :resource_filter_policy_fields)),
        "resource_availability_aliases" => %{
          "type" => "object",
          "const" => Keyword.fetch!(opts, :resource_availability_aliases),
          "additionalProperties" => string_array_schema
        },
        "resource_degraded_aliases" =>
          enum_array_const(Keyword.fetch!(opts, :resource_degraded_aliases)),
        "resource_margin_aliases" => %{
          "type" => "object",
          "const" => Keyword.fetch!(opts, :resource_margin_aliases),
          "additionalProperties" => string_array_schema
        },
        "resource_power_margin_source_aliases" =>
          enum_array_const(Keyword.fetch!(opts, :resource_power_margin_source_aliases)),
        "resource_availability_true_tokens" =>
          enum_array_const(Keyword.fetch!(opts, :resource_availability_true_tokens)),
        "resource_availability_false_tokens" =>
          enum_array_const(Keyword.fetch!(opts, :resource_availability_false_tokens)),
        "provider_direction_aliases" => %{
          "type" => "object",
          "const" => Keyword.fetch!(opts, :provider_direction_aliases),
          "additionalProperties" => %{"type" => "string"}
        },
        "station_calendar_direction_aliases" => %{
          "type" => "object",
          "const" => Keyword.fetch!(opts, :station_calendar_direction_aliases),
          "additionalProperties" => %{"type" => "string"}
        },
        "provider_result_map_value_keys" =>
          enum_array_const(Keyword.fetch!(opts, :provider_result_map_value_keys)),
        "candidate_stable_identity_fields" =>
          enum_array_const(Keyword.fetch!(opts, :candidate_stable_identity_fields)),
        "station_calendar_id_list_fields" =>
          enum_array_const(Keyword.fetch!(opts, :station_calendar_id_list_fields)),
        "suppression_reasons" => enum_array_const(Keyword.fetch!(opts, :suppression_reasons)),
        "row_review_statuses" => enum_array_const(Keyword.fetch!(opts, :row_review_statuses))
      }
    }
  end

  defp enum_array_const(values) do
    %{
      "type" => "array",
      "const" => values,
      "items" => %{"type" => "string", "enum" => values}
    }
  end

  defp assumptions_opts(deps) do
    [
      string_array_schema: fetch_dep!(deps, :string_array_schema),
      resource_filter_policy_fields: fetch_dep!(deps, :resource_filter_policy_fields),
      resource_availability_aliases: fetch_dep!(deps, :resource_availability_aliases),
      resource_degraded_aliases: fetch_dep!(deps, :resource_degraded_aliases),
      resource_margin_aliases: fetch_dep!(deps, :resource_margin_aliases),
      resource_power_margin_source_aliases:
        fetch_dep!(deps, :resource_power_margin_source_aliases),
      resource_availability_true_tokens: fetch_dep!(deps, :resource_availability_true_tokens),
      resource_availability_false_tokens: fetch_dep!(deps, :resource_availability_false_tokens),
      provider_direction_aliases: fetch_dep!(deps, :provider_direction_aliases),
      station_calendar_direction_aliases: fetch_dep!(deps, :station_calendar_direction_aliases),
      provider_result_map_value_keys: fetch_dep!(deps, :provider_result_map_value_keys),
      candidate_stable_identity_fields: fetch_dep!(deps, :candidate_stable_identity_fields),
      station_calendar_id_list_fields: fetch_dep!(deps, :station_calendar_id_list_fields),
      suppression_reasons: fetch_dep!(deps, :suppression_reasons),
      row_review_statuses: fetch_dep!(deps, :row_review_statuses)
    ]
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
