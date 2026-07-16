defmodule OrbitalDynamics.Schema.ContactContentionJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @contact_contention_report "contact_contention_report.v1"
  @contact_contention_resolution_report "contact_contention_resolution_report.v1"
  @contact_contention_resolution_summary "contact_contention_resolution_summary.v1"

  @report_count_fields [
    "input_contact_count",
    "conflicted_contact_count",
    "conflict_group_count",
    "duplicate_contact_candidate_count",
    "duplicate_contact_id_count",
    "invalid_contact_input_count"
  ]

  @summary_count_fields [
    "conflict_group_count",
    "recommendation_count",
    "review_recommendation_count"
  ]

  @summary_count_map_fields [
    "resource_scope_counts",
    "selection_reason_counts",
    "action_counts",
    "required_capacity_fraction_source_counts"
  ]

  @summary_number_fields [
    "capacity_pack_required_capacity_fraction",
    "capacity_pack_selected_required_capacity_fraction",
    "capacity_pack_deferred_required_capacity_fraction"
  ]

  @summary_number_map_fields [
    "capacity_pack_required_capacity_fraction_by_status",
    "capacity_pack_required_capacity_fraction_by_ground_station_id",
    "capacity_pack_selected_required_capacity_fraction_by_ground_station_id",
    "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id"
  ]

  @summary_stable_id_array_fields [
    "recommendation_group_ids",
    "review_group_ids",
    "selected_contact_ids",
    "deferred_contact_ids",
    "ambiguous_group_ids",
    "ambiguous_duplicate_contact_ids",
    "review_contact_ids"
  ]

  @summary_stable_id_array_map_fields [
    "selected_contact_ids_by_group_id",
    "deferred_contact_ids_by_group_id",
    "ambiguous_duplicate_contact_ids_by_group_id",
    "review_contact_ids_by_group_id",
    "selected_contact_ids_by_resource_scope",
    "deferred_contact_ids_by_resource_scope",
    "review_contact_ids_by_resource_scope",
    "selected_contact_ids_by_selection_reason",
    "review_contact_ids_by_action",
    "required_capacity_fraction_contact_ids_by_source"
  ]

  def property_field?(field, @contact_contention_report)
      when field in [
             "conflict_groups",
             "invalid_contact_input_ids",
             "invalid_contact_inputs",
             "model",
             "model_limits",
             "assumptions"
           ],
      do: true

  def property_field?(field, @contact_contention_report)
      when field in @report_count_fields,
      do: true

  def property_field?(field, @contact_contention_resolution_report)
      when field in [
             "conflict_group_count",
             "recommendation_count",
             "model",
             "model_limits",
             "recommendations",
             "policy"
           ],
      do: true

  def property_field?(field, @contact_contention_resolution_summary)
      when field in [
             "schema_contract",
             "source_artifact_type",
             "model",
             "model_limits",
             "policy"
           ],
      do: true

  def property_field?(field, @contact_contention_resolution_summary)
      when field in @summary_count_fields or field in @summary_count_map_fields or
             field in @summary_number_fields or field in @summary_number_map_fields or
             field in @summary_stable_id_array_fields or
             field in @summary_stable_id_array_map_fields,
      do: true

  def property_field?(_field, _contract_name), do: false

  def property_fun_from_context(deps) when is_list(deps) do
    fn field -> property_from_context(field, deps) end
  end

  def property_from_context(field, deps) when is_list(deps) do
    contract_name = fetch_dep!(deps, :contract_name)

    property(
      field,
      contract_name,
      property_opts(field, contract_name, deps)
    )
  end

  def property_opts("conflict_groups", @contact_contention_report, deps) do
    [conflict_group_schema: fetch_dep!(deps, :conflict_group_schema)]
  end

  def property_opts("invalid_contact_input_ids", @contact_contention_report, deps) do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts("model_limits", contract_name, deps)
      when contract_name in [
             @contact_contention_report,
             @contact_contention_resolution_report,
             @contact_contention_resolution_summary
           ] do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts("assumptions", @contact_contention_report, deps) do
    [report_assumptions_schema: fetch_dep!(deps, :report_assumptions_schema)]
  end

  def property_opts("recommendations", @contact_contention_resolution_report, deps) do
    [recommendation_schema: fetch_dep!(deps, :recommendation_schema)]
  end

  def property_opts("policy", contract_name, deps)
      when contract_name in [
             @contact_contention_resolution_report,
             @contact_contention_resolution_summary
           ] do
    [resolution_policy_schema: fetch_dep!(deps, :resolution_policy_schema)]
  end

  def property_opts("schema_contract", @contact_contention_resolution_summary, deps) do
    [schema_contract: fetch_dep!(deps, :schema_contract)]
  end

  def property_opts("source_artifact_type", @contact_contention_resolution_summary, deps) do
    [source_artifact_type: fetch_dep!(deps, :source_artifact_type)]
  end

  def property_opts(field, @contact_contention_resolution_summary, deps)
      when field in @summary_stable_id_array_fields or
             field in @summary_stable_id_array_map_fields do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts(_field, _contract_name, _deps), do: []

  def property("conflict_groups", @contact_contention_report, opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :conflict_group_schema)}
  end

  def property("invalid_contact_input_ids", @contact_contention_report, opts) do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property("invalid_contact_inputs", @contact_contention_report, _opts) do
    %{
      "type" => "array",
      "items" => %{"type" => "object", "additionalProperties" => true}
    }
  end

  def property("model", @contact_contention_report, _opts) do
    %{"type" => "string", "const" => "single_station_interval_overlap"}
  end

  def property(field, @contact_contention_report, _opts) when field in @report_count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("model_limits", @contact_contention_report, opts) do
    %{
      "type" => "array",
      "items" => %{"type" => "string", "enum" => Keyword.fetch!(opts, :model_limits)}
    }
  end

  def property("assumptions", @contact_contention_report, opts) do
    Keyword.fetch!(opts, :report_assumptions_schema)
  end

  def property(field, @contact_contention_resolution_report, _opts)
      when field in ["conflict_group_count", "recommendation_count"] do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("model", @contact_contention_resolution_report, _opts) do
    %{"type" => "string", "const" => "deterministic_contact_contention_recommendation"}
  end

  def property("model_limits", @contact_contention_resolution_report, opts) do
    %{
      "type" => "array",
      "items" => %{"type" => "string", "enum" => Keyword.fetch!(opts, :model_limits)}
    }
  end

  def property("recommendations", @contact_contention_resolution_report, opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :recommendation_schema)}
  end

  def property("policy", @contact_contention_resolution_report, opts) do
    Keyword.fetch!(opts, :resolution_policy_schema)
  end

  def property("schema_contract", @contact_contention_resolution_summary, opts) do
    %{"type" => "string", "const" => Keyword.fetch!(opts, :schema_contract)}
  end

  def property("source_artifact_type", @contact_contention_resolution_summary, opts) do
    %{"type" => "string", "enum" => [Keyword.fetch!(opts, :source_artifact_type)]}
  end

  def property("model", @contact_contention_resolution_summary, _opts) do
    %{"type" => "string", "const" => "artifact_only_contact_contention_resolution_summary"}
  end

  def property("model_limits", @contact_contention_resolution_summary, opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property("policy", @contact_contention_resolution_summary, opts) do
    Keyword.fetch!(opts, :resolution_policy_schema)
  end

  def property(field, @contact_contention_resolution_summary, _opts)
      when field in @summary_count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, @contact_contention_resolution_summary, _opts)
      when field in @summary_count_map_fields do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def property(field, @contact_contention_resolution_summary, _opts)
      when field in @summary_number_fields do
    %{"type" => "number", "minimum" => 0}
  end

  def property(field, @contact_contention_resolution_summary, _opts)
      when field in @summary_number_map_fields do
    CommonJsonSchema.non_negative_number_map()
  end

  def property(field, @contact_contention_resolution_summary, opts)
      when field in @summary_stable_id_array_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property(field, @contact_contention_resolution_summary, opts)
      when field in @summary_stable_id_array_map_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array_map()
  end

  def group(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "id",
        "ground_station_id",
        "contact_count",
        "starts_at_s",
        "ends_at_s",
        "direction",
        "required_operator_action",
        "approval_status",
        "contact_ids",
        "source_window_ids",
        "scenario_ids"
      ],
      "properties" => %{
        "id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "resource_scope" => %{"type" => "string"},
        "ground_station_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "ground_station_ids" => Keyword.fetch!(opts, :stable_id_array_schema),
        "spacecraft_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "spacecraft_ids" => Keyword.fetch!(opts, :stable_id_array_schema),
        "contact_count" => %{"type" => "integer", "minimum" => 0},
        "starts_at_s" => %{"type" => "number"},
        "ends_at_s" => %{"type" => "number"},
        "contention_window_s" => %{"type" => "number"},
        "total_contact_duration_s" => %{"type" => "number"},
        "overlap_duration_s" => %{"type" => "number"},
        "max_concurrent_contacts" => %{"type" => "integer", "minimum" => 0},
        "overlap_contact_pair_count" => %{"type" => "integer", "minimum" => 0},
        "direction" => %{"type" => "string"},
        "directions" => Keyword.fetch!(opts, :string_array_schema),
        "required_operator_action" => %{"type" => "string"},
        "approval_status" => %{"type" => "string"},
        "operator_action_reason" => %{"type" => "string"},
        "actual_throughput_mb" => %{"type" => "number"},
        "actual_data_rate_throughput_derivations" =>
          Keyword.fetch!(opts, :actual_data_rate_throughput_derivations_schema),
        "station_availability" => %{"type" => "string"},
        "station_calendar_status" => %{"type" => "string"},
        "station_calendar_reservation_expires_at_s" => Keyword.fetch!(opts, :number_array_schema),
        "capacity_fraction" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0},
        "capacity_fraction_min" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0},
        "capacity_fraction_max" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0},
        "contact_ids" => Keyword.fetch!(opts, :string_array_schema),
        "source_window_ids" => Keyword.fetch!(opts, :string_array_schema),
        "scenario_ids" => Keyword.fetch!(opts, :string_array_schema),
        "duplicate_contact_candidate_count" => %{"type" => "integer", "minimum" => 0},
        "duplicate_contact_id_count" => %{"type" => "integer", "minimum" => 0},
        "duplicate_contact_ids" => Keyword.fetch!(opts, :stable_id_array_schema),
        "source_contact_candidates" => %{
          "type" => "array",
          "items" => Keyword.fetch!(opts, :source_contact_candidate_schema)
        },
        "policy_decision" => Keyword.fetch!(opts, :policy_decision_schema)
      }
    }
  end

  def group_from_context(
        stable_id_pattern,
        stable_id_array_schema,
        string_array_schema,
        number_array_schema,
        actual_data_rate_throughput_derivations_schema,
        source_contact_candidate_schema,
        policy_decision_schema
      ) do
    group(
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: stable_id_array_schema,
      string_array_schema: string_array_schema,
      number_array_schema: number_array_schema,
      actual_data_rate_throughput_derivations_schema:
        actual_data_rate_throughput_derivations_schema,
      source_contact_candidate_schema: source_contact_candidate_schema,
      policy_decision_schema: policy_decision_schema
    )
  end

  def group_from_context(deps) when is_list(deps) do
    group(
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern),
      stable_id_array_schema: fetch_dep!(deps, :stable_id_array_schema),
      string_array_schema: fetch_dep!(deps, :string_array_schema),
      number_array_schema: fetch_dep!(deps, :number_array_schema),
      actual_data_rate_throughput_derivations_schema:
        fetch_dep!(deps, :actual_data_rate_throughput_derivations_schema),
      source_contact_candidate_schema: fetch_dep!(deps, :source_contact_candidate_schema),
      policy_decision_schema: fetch_dep!(deps, :policy_decision_schema)
    )
  end

  def recommendation(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "group_id",
        "ground_station_id",
        "starts_at_s",
        "ends_at_s",
        "selected_contact_id",
        "deferred_contact_ids",
        "candidate_count",
        "selection_reason",
        "action",
        "review_status"
      ],
      "properties" => %{
        "group_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "resource_scope" => %{"type" => "string"},
        "ground_station_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "ground_station_ids" => Keyword.fetch!(opts, :stable_id_array_schema),
        "spacecraft_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "spacecraft_ids" => Keyword.fetch!(opts, :stable_id_array_schema),
        "starts_at_s" => %{"type" => "number"},
        "ends_at_s" => %{"type" => "number"},
        "direction" => %{"type" => "string"},
        "directions" => Keyword.fetch!(opts, :string_array_schema),
        "contention_window_s" => %{"type" => "number"},
        "total_contact_duration_s" => %{"type" => "number"},
        "overlap_duration_s" => %{"type" => "number"},
        "max_concurrent_contacts" => %{"type" => "integer", "minimum" => 0},
        "overlap_contact_pair_count" => %{"type" => "integer", "minimum" => 0},
        "selected_contact_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "selected_scenario_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "selected_priority" => %{"type" => "number"},
        "selected_priority_source" => %{"type" => "string"},
        "actual_throughput_mb" => %{"type" => "number"},
        "actual_data_rate_throughput_derivations" =>
          Keyword.fetch!(opts, :actual_data_rate_throughput_derivations_schema),
        "station_availability" => %{"type" => "string"},
        "station_calendar_status" => %{"type" => "string"},
        "station_calendar_reservation_expires_at_s" => Keyword.fetch!(opts, :number_array_schema),
        "capacity_fraction" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0},
        "capacity_fraction_min" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0},
        "capacity_fraction_max" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0},
        "deferred_contact_ids" => Keyword.fetch!(opts, :string_array_schema),
        "deferred_contact_priorities" => %{
          "type" => "array",
          "items" => Keyword.fetch!(opts, :deferred_priority_schema)
        },
        "candidate_count" => %{"type" => "integer", "minimum" => 0},
        "selection_reason" => %{"type" => "string"},
        "source_contact_candidates" => %{
          "type" => "array",
          "items" => Keyword.fetch!(opts, :source_contact_candidate_schema)
        },
        "resolution_selection_rule" => %{"type" => "string"},
        "resolution_priority_fields" => Keyword.fetch!(opts, :string_array_schema),
        "requested_priority_fields" => Keyword.fetch!(opts, :string_array_schema),
        "priority_field_evidence_counts" =>
          Keyword.fetch!(opts, :priority_field_evidence_counts_schema),
        "priority_fields_without_numeric_evidence_count" => %{
          "type" => "integer",
          "minimum" => 0
        },
        "priority_fields_without_numeric_evidence" => Keyword.fetch!(opts, :string_array_schema),
        "resolution_tie_breakers" => Keyword.fetch!(opts, :string_array_schema),
        "resolution_priority_override_count" => %{"type" => "integer", "minimum" => 0},
        "resolution_priority_override_contact_ids" =>
          Keyword.fetch!(opts, :stable_id_array_schema),
        "ignored_priority_override_count" => %{"type" => "integer", "minimum" => 0},
        "ignored_priority_override_keys" => Keyword.fetch!(opts, :string_array_schema),
        "ignored_priority_override_contact_ids" => Keyword.fetch!(opts, :stable_id_array_schema),
        "ignored_priority_override_input" => %{"type" => "string"},
        "requested_selection_rule" => %{"type" => "string"},
        "ignored_tie_breakers" => Keyword.fetch!(opts, :string_array_schema),
        "ignored_policy_input" => %{"type" => "string"},
        "policy_warnings" => Keyword.fetch!(opts, :string_array_schema),
        "action" => %{"type" => "string"},
        "review_status" => %{"type" => "string"},
        "policy_decision" => Keyword.fetch!(opts, :policy_decision_schema)
      }
    }
  end

  def recommendation_from_context(
        stable_id_pattern,
        stable_id_array_schema,
        string_array_schema,
        number_array_schema,
        actual_data_rate_throughput_derivations_schema,
        deferred_priority_schema,
        source_contact_candidate_schema,
        priority_field_evidence_counts_schema,
        policy_decision_schema
      ) do
    recommendation(
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: stable_id_array_schema,
      string_array_schema: string_array_schema,
      number_array_schema: number_array_schema,
      actual_data_rate_throughput_derivations_schema:
        actual_data_rate_throughput_derivations_schema,
      deferred_priority_schema: deferred_priority_schema,
      source_contact_candidate_schema: source_contact_candidate_schema,
      priority_field_evidence_counts_schema: priority_field_evidence_counts_schema,
      policy_decision_schema: policy_decision_schema
    )
  end

  def recommendation_from_context(deps) when is_list(deps) do
    recommendation(
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern),
      stable_id_array_schema: fetch_dep!(deps, :stable_id_array_schema),
      string_array_schema: fetch_dep!(deps, :string_array_schema),
      number_array_schema: fetch_dep!(deps, :number_array_schema),
      actual_data_rate_throughput_derivations_schema:
        fetch_dep!(deps, :actual_data_rate_throughput_derivations_schema),
      deferred_priority_schema: fetch_dep!(deps, :deferred_priority_schema),
      source_contact_candidate_schema: fetch_dep!(deps, :source_contact_candidate_schema),
      priority_field_evidence_counts_schema:
        fetch_dep!(deps, :priority_field_evidence_counts_schema),
      policy_decision_schema: fetch_dep!(deps, :policy_decision_schema)
    )
  end

  def source_contact_candidate(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "scenario_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "source_window_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "ground_station_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "spacecraft_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "type" => %{"type" => "string"},
        "direction" => %{"type" => "string"},
        "starts_at_s" => %{"type" => "number"},
        "ends_at_s" => %{"type" => "number"},
        "score" => %{"type" => "number"}
      }
    }
  end

  def source_contact_candidate_from_context(stable_id_pattern)
      when is_binary(stable_id_pattern) do
    source_contact_candidate(stable_id_pattern: stable_id_pattern)
  end

  def source_contact_candidate_from_context(deps) when is_list(deps) do
    source_contact_candidate(stable_id_pattern: fetch_dep!(deps, :stable_id_pattern))
  end

  def resolution_policy(opts) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "selection_rule" => %{"type" => "string"},
        "priority_fields" => Keyword.fetch!(opts, :string_array_schema),
        "requested_priority_fields" => Keyword.fetch!(opts, :string_array_schema),
        "tie_breakers" => Keyword.fetch!(opts, :string_array_schema),
        "action" => %{"type" => "string"},
        "requested_selection_rule" => %{"type" => "string"},
        "ignored_tie_breakers" => Keyword.fetch!(opts, :string_array_schema),
        "ignored_policy_input" => %{"type" => "string"},
        "policy_warnings" => Keyword.fetch!(opts, :string_array_schema),
        "priority_overrides" => %{
          "type" => "object",
          "additionalProperties" => %{"type" => "number"}
        },
        "priority_override_count" => %{"type" => "integer", "minimum" => 0},
        "priority_override_contact_ids" => Keyword.fetch!(opts, :stable_id_array_schema),
        "ignored_priority_override_count" => %{"type" => "integer", "minimum" => 0},
        "ignored_priority_override_keys" => Keyword.fetch!(opts, :string_array_schema),
        "ignored_priority_override_contact_ids" => Keyword.fetch!(opts, :stable_id_array_schema),
        "ignored_priority_override_input" => %{"type" => "string"}
      }
    }
  end

  def resolution_policy_from_context(stable_id_array_schema, string_array_schema) do
    resolution_policy(
      stable_id_array_schema: stable_id_array_schema,
      string_array_schema: string_array_schema
    )
  end

  def resolution_policy_from_context(deps) when is_list(deps) do
    resolution_policy(
      stable_id_array_schema: fetch_dep!(deps, :stable_id_array_schema),
      string_array_schema: fetch_dep!(deps, :string_array_schema)
    )
  end

  def deferred_priority(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "contact_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "priority" => %{"type" => "number"},
        "priority_source" => %{"type" => "string"}
      }
    }
  end

  def deferred_priority_from_context(stable_id_pattern) when is_binary(stable_id_pattern) do
    deferred_priority(stable_id_pattern: stable_id_pattern)
  end

  def deferred_priority_from_context(deps) when is_list(deps) do
    deferred_priority(stable_id_pattern: fetch_dep!(deps, :stable_id_pattern))
  end

  def report_assumptions_from_capabilities(capabilities) do
    report_assumptions(
      contact_types: Map.fetch!(capabilities, :contact_types),
      contact_directions: Map.fetch!(capabilities, :contact_directions),
      row_review_statuses: Map.fetch!(capabilities, :row_review_statuses),
      station_unavailable_aliases: Map.fetch!(capabilities, :station_unavailable_aliases),
      station_availability_precedence: Map.fetch!(capabilities, :station_availability_precedence),
      station_capacity_value_paths:
        capabilities
        |> Map.fetch!(:station_capacity_value_paths)
        |> capacity_value_path_assumptions(),
      source_station_capacity_value_paths:
        capabilities
        |> Map.fetch!(:source_station_capacity_value_paths)
        |> capacity_value_path_assumptions(),
      required_capacity_value_paths:
        capabilities
        |> Map.fetch!(:required_capacity_value_paths)
        |> capacity_value_path_assumptions(),
      required_capacity_fraction_source_values:
        Map.fetch!(capabilities, :required_capacity_fraction_source_values),
      station_reservation_priority_match_statuses:
        Map.fetch!(capabilities, :station_reservation_priority_match_statuses),
      station_reservation_priority_statuses:
        Map.fetch!(capabilities, :station_reservation_priority_statuses),
      resolution_selection_rules: Map.fetch!(capabilities, :resolution_selection_rules),
      resolution_tie_breakers: Map.fetch!(capabilities, :resolution_tie_breakers),
      default_resolution_priority_fields:
        Map.fetch!(capabilities, :default_resolution_priority_fields),
      resolution_priority_override_aliases:
        Map.fetch!(capabilities, :resolution_priority_override_aliases),
      provider_direction_aliases: Map.fetch!(capabilities, :provider_direction_aliases),
      provider_result_map_value_keys: Map.fetch!(capabilities, :provider_result_map_value_keys),
      contact_stable_identity_fields: Map.fetch!(capabilities, :contact_stable_identity_fields),
      command_contact_directions: Map.fetch!(capabilities, :command_contact_directions)
    )
  end

  def report_assumptions(opts) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "contact_types" => enum_array_const(Keyword.fetch!(opts, :contact_types)),
        "contact_directions" => enum_array_const(Keyword.fetch!(opts, :contact_directions)),
        "row_review_statuses" => enum_array_const(Keyword.fetch!(opts, :row_review_statuses)),
        "station_unavailable_aliases" =>
          enum_array_const(Keyword.fetch!(opts, :station_unavailable_aliases)),
        "station_availability_precedence" => %{
          "type" => "object",
          "const" => Keyword.fetch!(opts, :station_availability_precedence),
          "additionalProperties" => %{"type" => "integer", "minimum" => 0}
        },
        "station_capacity_value_paths" =>
          capacity_value_paths(Keyword.fetch!(opts, :station_capacity_value_paths)),
        "source_station_capacity_value_paths" =>
          capacity_value_paths(Keyword.fetch!(opts, :source_station_capacity_value_paths)),
        "required_capacity_value_paths" =>
          capacity_value_paths(Keyword.fetch!(opts, :required_capacity_value_paths)),
        "required_capacity_fraction_source_values" =>
          enum_array_const(Keyword.fetch!(opts, :required_capacity_fraction_source_values)),
        "station_reservation_priority_match_statuses" =>
          enum_array_const(Keyword.fetch!(opts, :station_reservation_priority_match_statuses)),
        "station_reservation_priority_statuses" =>
          enum_array_const(Keyword.fetch!(opts, :station_reservation_priority_statuses)),
        "resolution_selection_rules" =>
          enum_array_const(Keyword.fetch!(opts, :resolution_selection_rules)),
        "resolution_tie_breakers" =>
          enum_array_const(Keyword.fetch!(opts, :resolution_tie_breakers)),
        "default_resolution_priority_fields" =>
          enum_array_const(Keyword.fetch!(opts, :default_resolution_priority_fields)),
        "resolution_priority_override_aliases" =>
          enum_array_const(Keyword.fetch!(opts, :resolution_priority_override_aliases)),
        "provider_direction_aliases" => %{
          "type" => "object",
          "const" => Keyword.fetch!(opts, :provider_direction_aliases),
          "additionalProperties" => %{"type" => "string"}
        },
        "provider_result_map_value_keys" =>
          enum_array_const(Keyword.fetch!(opts, :provider_result_map_value_keys)),
        "contact_stable_identity_fields" =>
          enum_array_const(Keyword.fetch!(opts, :contact_stable_identity_fields)),
        "command_contact_directions" =>
          enum_array_const(Keyword.fetch!(opts, :command_contact_directions))
      }
    }
  end

  defp capacity_value_path_assumptions(paths) do
    Enum.map(paths, fn %{unit: unit, path: path} ->
      %{"unit" => Atom.to_string(unit), "path" => path}
    end)
  end

  defp enum_array_const(values) do
    %{
      "type" => "array",
      "const" => values,
      "items" => %{"type" => "string", "enum" => values}
    }
  end

  defp capacity_value_paths(paths) do
    %{
      "type" => "array",
      "const" => paths,
      "items" => capacity_value_path()
    }
  end

  defp capacity_value_path do
    %{
      "type" => "object",
      "additionalProperties" => false,
      "required" => ["unit", "path"],
      "properties" => %{
        "unit" => %{"type" => "string", "enum" => ["fraction", "percent"]},
        "path" => CommonJsonSchema.string_array()
      }
    }
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      value when is_function(value, 0) -> value.()
      value -> value
    end
  end
end
