defmodule OrbitalDynamics.Schema.LinkCapacityReportJsonSchema do
  @moduledoc false

  @integer_fields [
    "contact_count",
    "selected_contact_count",
    "effective_contact_count",
    "ignored_contact_count",
    "ignored_selected_contact_count",
    "ambiguous_selected_contact_id_count",
    "duplicate_contact_candidate_count",
    "duplicate_contact_id_count",
    "unmatched_selected_contact_count",
    "required_downlink_contact_count",
    "actual_throughput_contact_count",
    "actual_completion_contact_count",
    "unmatched_actual_throughput_contact_count",
    "ambiguous_actual_throughput_contact_count",
    "unmatched_actual_completion_contact_count",
    "ambiguous_actual_completion_contact_count",
    "invalid_contact_input_count",
    "invalid_selected_contact_input_count",
    "invalid_policy_required_downlink_station_count",
    "downlink_link_budget_count"
  ]

  @stable_id_array_fields [
    "actual_throughput_contact_ids",
    "ignored_contact_ids",
    "ignored_selected_contact_ids",
    "ambiguous_selected_contact_ids",
    "unmatched_selected_contact_ids",
    "actual_completion_contact_ids",
    "unmatched_actual_throughput_contact_ids",
    "ambiguous_actual_throughput_contact_ids",
    "unmatched_actual_completion_contact_ids",
    "ambiguous_actual_completion_contact_ids",
    "invalid_contact_input_ids",
    "invalid_selected_contact_input_ids",
    "station_reservation_ids",
    "downlink_link_budget_ids"
  ]

  @string_array_fields [
    "required_downlink_contact_ids",
    "invalid_policy_required_downlink_station_ids",
    "downlink_completion_sources",
    "station_reserved_bys",
    "station_reservation_statuses"
  ]

  @number_array_fields ["station_reservation_expires_at_s"]

  @count_map_fields [
    "ignored_contact_reason_counts",
    "ignored_selected_contact_reason_counts",
    "station_reservation_match_status_counts"
  ]

  @invalid_input_fields [
    "invalid_contact_inputs",
    "invalid_selected_contact_inputs"
  ]

  def property_field?(field)
      when field in [
             "rows",
             "source",
             "model",
             "model_limits",
             "assumptions",
             "actual_downlink_completion_ratio",
             "selected_capacity_utilization_fraction",
             "actual_data_rate_throughput_derivations",
             "downlink_link_budgets"
           ],
      do: true

  def property_field?(field)
      when field in @integer_fields or field in @stable_id_array_fields or
             field in @string_array_fields or field in @number_array_fields or
             field in @count_map_fields or field in @invalid_input_fields,
      do: true

  def property_field?(_field), do: false

  def property_opts("rows", deps) do
    [row_schema: fetch_dep!(deps, :row_schema)]
  end

  def property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts("assumptions", deps) do
    [assumptions_schema: fetch_dep!(deps, :assumptions_schema)]
  end

  def property_opts("downlink_link_budgets", _deps), do: []

  def property_opts(field, deps) when field in @stable_id_array_fields do
    [stable_id_array_schema: fetch_dep!(deps, :stable_id_array_schema)]
  end

  def property_opts(field, deps) when field in @string_array_fields do
    [string_array_schema: fetch_dep!(deps, :string_array_schema)]
  end

  def property_opts(field, deps) when field in @count_map_fields do
    [count_map_schema: fetch_dep!(deps, :count_map_schema)]
  end

  def property_opts(field, deps) when field in @number_array_fields do
    [number_array_schema: fetch_dep!(deps, :number_array_schema)]
  end

  def property_opts("actual_data_rate_throughput_derivations", deps) do
    [
      actual_data_rate_throughput_derivations_schema:
        fetch_dep!(deps, :actual_data_rate_throughput_derivations_schema)
    ]
  end

  def property_opts(_field, _deps), do: []

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property_fun_from_context(deps) when is_list(deps) do
    fn field -> property_from_context(field, deps) end
  end

  def row_from_deps(deps) do
    deps
    |> row_opts()
    |> row()
  end

  def row_from_context(
        stable_id_pattern,
        probability_schema,
        stable_id_array_schema,
        string_array_schema,
        count_map_schema,
        actual_data_rate_throughput_derivations_schema,
        policy_decision_schema
      ) do
    [
      stable_id_pattern: stable_id_pattern,
      probability_schema: probability_schema,
      stable_id_array_schema: stable_id_array_schema,
      string_array_schema: string_array_schema,
      count_map_schema: count_map_schema,
      actual_data_rate_throughput_derivations_schema:
        actual_data_rate_throughput_derivations_schema,
      policy_decision_schema: policy_decision_schema
    ]
    |> row_opts()
    |> row()
  end

  def row(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    probability_schema = Keyword.fetch!(opts, :probability_schema)
    stable_id_array_schema = Keyword.fetch!(opts, :stable_id_array_schema)
    string_array_schema = Keyword.fetch!(opts, :string_array_schema)
    count_map_schema = Keyword.fetch!(opts, :count_map_schema)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "ground_station_id",
        "contact_count",
        "selected_contact_count",
        "estimated_throughput_mb",
        "selected_estimated_throughput_mb",
        "contact_ids",
        "selected_contact_ids"
      ],
      "properties" => %{
        "ground_station_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "contact_count" => integer_schema(),
        "selected_contact_count" => integer_schema(),
        "estimated_throughput_mb" => %{"type" => "number"},
        "selected_estimated_throughput_mb" => %{"type" => "number"},
        "capacity_adjusted_throughput_mb" => %{"type" => "number"},
        "selected_capacity_adjusted_throughput_mb" => %{"type" => "number"},
        "unused_capacity_adjusted_throughput_mb" => %{"type" => "number"},
        "selected_capacity_utilization_fraction" =>
          property("selected_capacity_utilization_fraction", []),
        "selection_utilization_status" => %{"type" => "string"},
        "capacity_fraction_min" => probability_schema,
        "capacity_fraction_max" => probability_schema,
        "effective_contact_count" => integer_schema(),
        "ignored_contact_count" => integer_schema(),
        "ignored_contact_ids" => stable_id_array_schema,
        "ignored_contact_reason_counts" => count_map_schema,
        "ignored_selected_contact_count" => integer_schema(),
        "ignored_selected_contact_ids" => stable_id_array_schema,
        "ignored_selected_contact_reason_counts" => count_map_schema,
        "ambiguous_selected_contact_id_count" => integer_schema(),
        "ambiguous_selected_contact_ids" => stable_id_array_schema,
        "duplicate_contact_candidate_count" => integer_schema(),
        "duplicate_contact_ids" => stable_id_array_schema,
        "station_calendar_entry_ids" => stable_id_array_schema,
        "station_calendar_provider_ids" => stable_id_array_schema,
        "station_calendar_provider_entry_ids" => stable_id_array_schema,
        "station_calendar_directions" => string_array_schema,
        "station_availability" => %{"type" => "string"},
        "station_reservation_ids" => stable_id_array_schema,
        "station_reserved_bys" => string_array_schema,
        "station_reservation_statuses" => string_array_schema,
        "station_reservation_match_statuses" => string_array_schema,
        "contact_ids" => string_array_schema,
        "selected_contact_ids" => string_array_schema,
        "required_downlink_contact_count" => integer_schema(),
        "required_downlink_contact_ids" => string_array_schema,
        "actual_throughput_mb" => %{"type" => "number"},
        "actual_throughput_contact_count" => integer_schema(),
        "actual_throughput_contact_ids" => stable_id_array_schema,
        "actual_completion_contact_count" => integer_schema(),
        "actual_completion_contact_ids" => stable_id_array_schema,
        "unmatched_actual_throughput_contact_count" => integer_schema(),
        "unmatched_actual_throughput_contact_ids" => stable_id_array_schema,
        "ambiguous_actual_throughput_contact_count" => integer_schema(),
        "ambiguous_actual_throughput_contact_ids" => stable_id_array_schema,
        "unmatched_actual_completion_contact_count" => integer_schema(),
        "unmatched_actual_completion_contact_ids" => stable_id_array_schema,
        "ambiguous_actual_completion_contact_count" => integer_schema(),
        "ambiguous_actual_completion_contact_ids" => stable_id_array_schema,
        "actual_downlink_completion_ratio" => property("actual_downlink_completion_ratio", []),
        "actual_data_rate_throughput_derivations" =>
          Keyword.fetch!(opts, :actual_data_rate_throughput_derivations_schema),
        "policy_decision" => Keyword.fetch!(opts, :policy_decision_schema),
        "downlink_link_budget_count" => integer_schema(),
        "downlink_link_budget_ids" => stable_id_array_schema,
        "downlink_link_budget_contact_ids" => stable_id_array_schema
      }
    }
  end

  def property("rows", opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :row_schema)
    }
  end

  def property("source", _opts) do
    %{"type" => "string"}
  end

  def property("model", _opts) do
    %{
      "type" => "string",
      "const" => "fixed_rate_downlink_capacity_summary"
    }
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    budget_model_limits =
      OrbitalDynamics.Communications.LinkCapacity.report_model_limits([:present])

    %{
      "type" => "array",
      "oneOf" => [
        %{"const" => model_limits},
        %{"const" => budget_model_limits}
      ],
      "items" => %{"type" => "string", "enum" => Enum.uniq(model_limits ++ budget_model_limits)}
    }
  end

  def property("assumptions", opts) do
    Keyword.fetch!(opts, :assumptions_schema)
  end

  def property(field, opts) when field in @stable_id_array_fields do
    Keyword.fetch!(opts, :stable_id_array_schema)
  end

  def property("actual_downlink_completion_ratio", _opts) do
    %{"type" => "number", "minimum" => 0, "maximum" => 1}
  end

  def property("selected_capacity_utilization_fraction", _opts) do
    %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0}
  end

  def property(field, _opts) when field in @integer_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, opts) when field in @string_array_fields do
    Keyword.fetch!(opts, :string_array_schema)
  end

  def property(field, opts) when field in @count_map_fields do
    Keyword.fetch!(opts, :count_map_schema)
  end

  def property(field, opts) when field in @number_array_fields do
    Keyword.fetch!(opts, :number_array_schema)
  end

  def property(field, _opts) when field in @invalid_input_fields do
    %{"type" => "array", "items" => %{"type" => "object", "additionalProperties" => true}}
  end

  def property("actual_data_rate_throughput_derivations", opts) do
    Keyword.fetch!(opts, :actual_data_rate_throughput_derivations_schema)
  end

  def property("downlink_link_budgets", opts) do
    %{
      "type" => "array",
      "items" => OrbitalDynamics.Schema.DownlinkLinkBudgetJsonSchema.artifact_schema(opts)
    }
  end

  def assumptions_from_deps(deps, required_properties) do
    deps
    |> assumptions_opts(required_properties)
    |> assumptions()
  end

  def assumptions(opts) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => Keyword.fetch!(opts, :required_properties),
      "properties" => %{
        "downlink_rate_mb_s" => %{"type" => "number"},
        "execution_boundary" => %{
          "type" => "string",
          "const" => "artifact_only_no_provider_reservation_or_schedule_mutation"
        },
        "source" => %{"type" => "string", "const" => "link_capacity_report.v1"},
        "operator_authority" => %{"type" => "string", "const" => "not_granted_by_summary"},
        "station_unavailable_aliases" =>
          enum_array_const(Keyword.fetch!(opts, :station_unavailable_aliases)),
        "station_availability_precedence" => %{
          "type" => "object",
          "const" => Keyword.fetch!(opts, :station_availability_precedence),
          "additionalProperties" => %{"type" => "integer", "minimum" => 0}
        },
        "station_capacity_value_paths" => %{
          "type" => "array",
          "const" => Keyword.fetch!(opts, :station_capacity_value_paths),
          "items" => capacity_value_path()
        },
        "source_station_capacity_value_paths" => %{
          "type" => "array",
          "const" => Keyword.fetch!(opts, :source_station_capacity_value_paths),
          "items" => capacity_value_path()
        },
        "provider_direction_aliases" => %{
          "type" => "object",
          "const" => Keyword.fetch!(opts, :provider_direction_aliases),
          "additionalProperties" => %{
            "type" => "string",
            "enum" => ["command", "uplink", "downlink", "tracking", "health_check"]
          }
        }
      }
    }
  end

  def capacity_value_path do
    %{
      "type" => "object",
      "additionalProperties" => false,
      "required" => ["unit", "path"],
      "properties" => %{
        "unit" => %{"type" => "string", "enum" => ["fraction", "percent"]},
        "path" => OrbitalDynamics.Schema.CommonJsonSchema.string_array()
      }
    }
  end

  defp integer_schema do
    %{"type" => "integer", "minimum" => 0}
  end

  defp enum_array_const(values) do
    %{
      "type" => "array",
      "const" => values,
      "items" => %{"type" => "string", "enum" => values}
    }
  end

  defp row_opts(deps) do
    [
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern),
      probability_schema: fetch_dep!(deps, :probability_schema),
      stable_id_array_schema: fetch_dep!(deps, :stable_id_array_schema),
      string_array_schema: fetch_dep!(deps, :string_array_schema),
      count_map_schema: fetch_dep!(deps, :count_map_schema),
      actual_data_rate_throughput_derivations_schema:
        fetch_dep!(deps, :actual_data_rate_throughput_derivations_schema),
      policy_decision_schema: fetch_dep!(deps, :policy_decision_schema)
    ]
  end

  defp assumptions_opts(deps, required_properties) do
    [
      required_properties: required_properties,
      station_unavailable_aliases: fetch_dep!(deps, :station_unavailable_aliases),
      station_availability_precedence: fetch_dep!(deps, :station_availability_precedence),
      station_capacity_value_paths:
        capacity_value_path_assumptions(fetch_dep!(deps, :station_capacity_value_paths)),
      source_station_capacity_value_paths:
        capacity_value_path_assumptions(fetch_dep!(deps, :source_station_capacity_value_paths)),
      provider_direction_aliases: fetch_dep!(deps, :provider_direction_aliases)
    ]
  end

  defp capacity_value_path_assumptions(paths) do
    Enum.map(paths, fn %{unit: unit, path: path} ->
      %{"unit" => Atom.to_string(unit), "path" => path}
    end)
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
