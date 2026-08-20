defmodule OrbitalDynamics.Schema.ContactAllocationReportJsonSchema do
  @moduledoc false

  @count_fields [
    "input_contact_count",
    "allocated_contact_count",
    "deferred_contact_count",
    "blocked_contact_count",
    "returned_allocated_contact_count",
    "policy_blocked_allocated_contact_count",
    "status_blocked_contact_count",
    "resource_blocked_contact_count",
    "duplicate_contact_candidate_count",
    "duplicate_contact_id_count",
    "invalid_contact_input_count",
    "reduced_capacity_pack_group_count",
    "station_reservation_declared_expiration_contact_count",
    "station_reservation_missing_expiration_contact_count"
  ]

  @stable_id_array_fields [
    "invalid_contact_input_ids",
    "resource_blocked_contact_ids",
    "reduced_capacity_packed_contact_ids",
    "reduced_capacity_deferred_contact_ids",
    "status_blocked_contact_ids",
    "station_reservation_ids"
  ]

  @stable_id_array_map_fields [
    "station_pressure_contact_ids_by_ground_station_id",
    "station_pressure_contact_ids_by_availability",
    "station_pressure_contact_ids_by_precedence_availability",
    "station_pressure_contact_ids_by_precedence_rank",
    "station_pressure_contact_ids_by_status",
    "resource_blocked_contact_ids_by_blocking_dimension",
    "resource_blocked_contact_ids_by_spacecraft_id",
    "station_reservation_contact_ids_by_expiration_status",
    "station_reservation_ids_by_expiration_status",
    "station_reservation_contact_ids_by_match_status",
    "station_reservation_contact_ids_by_status",
    "station_reservation_contact_ids_by_reserved_by",
    "station_reservation_ids_by_match_status",
    "station_reservation_ids_by_status",
    "station_reservation_ids_by_reserved_by",
    "capacity_pack_contact_ids_by_status",
    "required_capacity_fraction_contact_ids_by_source"
  ]

  @string_array_fields ["station_reserved_bys", "station_reservation_statuses"]

  @trust_boundary_count_map_fields [
    "calendar_entry_trust_boundary_status_counts",
    "station_calendar_trust_boundary_status_counts"
  ]

  @enum_count_map_fields [
    "allocation_status_counts",
    "effective_allocation_status_counts"
  ]

  @count_map_fields [
    "allocation_reason_counts",
    "station_pressure_contact_counts_by_ground_station_id",
    "station_pressure_contact_counts_by_availability",
    "station_pressure_contact_counts_by_precedence_availability",
    "station_pressure_contact_counts_by_precedence_rank",
    "station_pressure_contact_counts_by_status",
    "resource_blocking_dimension_counts",
    "station_reservation_expiration_status_counts",
    "reduced_capacity_pack_status_counts",
    "capacity_pack_status_counts",
    "required_capacity_fraction_source_counts",
    "station_reservation_match_status_counts"
  ]

  @non_negative_number_fields [
    "capacity_pack_required_capacity_fraction",
    "capacity_pack_selected_required_capacity_fraction",
    "capacity_pack_deferred_required_capacity_fraction"
  ]

  @non_negative_number_map_fields [
    "capacity_pack_required_capacity_fraction_by_status",
    "capacity_pack_required_capacity_fraction_by_ground_station_id",
    "capacity_pack_selected_required_capacity_fraction_by_ground_station_id",
    "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id"
  ]

  def property_field?(field)
      when field in [
             "rows",
             "reduced_capacity_pack_groups",
             "model",
             "source",
             "model_limits",
             "station_pressure_contact_ids_by_direction_and_ground_station_id",
             "earliest_station_reservation_expires_at_s"
           ],
      do: true

  def property_field?(field)
      when field in @count_fields or field in @stable_id_array_fields or
             field in @stable_id_array_map_fields or field in @string_array_fields or
             field in @trust_boundary_count_map_fields or field in @enum_count_map_fields or
             field in @count_map_fields or field in @non_negative_number_fields or
             field in @non_negative_number_map_fields,
      do: true

  def property_field?(_field), do: false

  def property_fun_from_context(deps) when is_list(deps) do
    fn field -> property_from_context(field, deps) end
  end

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property_opts("rows", deps) do
    [row_schema: fetch_dep!(deps, :row_schema)]
  end

  def property_opts("reduced_capacity_pack_groups", deps) do
    [capacity_pack_group_schema: fetch_dep!(deps, :capacity_pack_group_schema)]
  end

  def property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts(field, deps)
      when field in @stable_id_array_fields or field in @stable_id_array_map_fields do
    [stable_id_array_schema: fetch_dep!(deps, :stable_id_array_schema)]
  end

  def property_opts("station_pressure_contact_ids_by_direction_and_ground_station_id", deps) do
    [nested_stable_id_array_map_schema: fetch_dep!(deps, :nested_stable_id_array_map_schema)]
  end

  def property_opts(field, deps) when field in @string_array_fields do
    [string_array_schema: fetch_dep!(deps, :string_array_schema)]
  end

  def property_opts(field, deps) when field in @trust_boundary_count_map_fields do
    [trust_boundary_count_map_schema: fetch_dep!(deps, :trust_boundary_count_map_schema)]
  end

  def property_opts(field, deps) when field in @enum_count_map_fields do
    [
      contact_allocation_capability: fetch_dep!(deps, :contact_allocation_capability),
      enum_count_map_schema: fetch_dep!(deps, :enum_count_map_schema)
    ]
  end

  def property_opts(field, deps) when field in @count_map_fields do
    [count_map_schema: fetch_dep!(deps, :count_map_schema)]
  end

  def property_opts(field, deps) when field in @non_negative_number_map_fields do
    [non_negative_number_map_schema: fetch_dep!(deps, :non_negative_number_map_schema)]
  end

  def property_opts(_field, _deps), do: []

  def row_from_deps(deps) do
    deps
    |> row_opts()
    |> row()
  end

  def row_from_context(
        stable_id_pattern,
        stable_id_array_schema,
        string_array_schema,
        number_array_schema,
        actual_data_rate_throughput_derivation_schema,
        approval_requirement_schema,
        policy_decision_rule_match_schema,
        policy_decision_schema,
        source_contention_recommendation_schema,
        contact_allocation_capability,
        station_calendar_capability,
        deferred_priority_schema,
        priority_field_evidence_counts_schema
      ) do
    [
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: stable_id_array_schema,
      string_array_schema: string_array_schema,
      number_array_schema: number_array_schema,
      actual_data_rate_throughput_derivation_schema:
        actual_data_rate_throughput_derivation_schema,
      approval_requirement_schema: approval_requirement_schema,
      policy_decision_rule_match_schema: policy_decision_rule_match_schema,
      policy_decision_schema: policy_decision_schema,
      source_contention_recommendation_schema: source_contention_recommendation_schema,
      contact_allocation_capability: contact_allocation_capability,
      station_calendar_capability: station_calendar_capability,
      deferred_priority_schema: deferred_priority_schema,
      priority_field_evidence_counts_schema: priority_field_evidence_counts_schema
    ]
    |> row_opts()
    |> row()
  end

  def row(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    stable_id_array_schema = Keyword.fetch!(opts, :stable_id_array_schema)
    string_array_schema = Keyword.fetch!(opts, :string_array_schema)
    number_array_schema = Keyword.fetch!(opts, :number_array_schema)
    contact_allocation_capability = Keyword.fetch!(opts, :contact_allocation_capability)
    station_calendar_capability = Keyword.fetch!(opts, :station_calendar_capability)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "id",
        "contact_id",
        "allocation_status",
        "effective_allocation_status"
      ],
      "properties" => %{
        "id" => stable_id_schema(stable_id_pattern),
        "contact_id" => stable_id_schema(stable_id_pattern),
        "scenario_id" => stable_id_schema(stable_id_pattern),
        "ground_station_id" => stable_id_schema(stable_id_pattern),
        "spacecraft_id" => stable_id_schema(stable_id_pattern),
        "source_window_id" => stable_id_schema(stable_id_pattern),
        "source_window_revision" => %{"type" => "string", "minLength" => 1},
        "contention_group_id" => stable_id_schema(stable_id_pattern),
        "capacity_pack_group_id" => stable_id_schema(stable_id_pattern),
        "capacity_pack_status" => %{"type" => "string"},
        "capacity_pack_capacity_fraction" => probability_schema(),
        "capacity_pack_used_fraction" => probability_schema(),
        "required_capacity_fraction" => probability_schema(),
        "required_capacity_fraction_source" => %{"type" => "string"},
        "capacity_fraction" => probability_schema(),
        "actual_throughput_mb" => %{"type" => "number"},
        "actual_data_rate_throughput_derivation" =>
          Keyword.fetch!(opts, :actual_data_rate_throughput_derivation_schema),
        "completed_fraction" => probability_schema(),
        "required_downlink_mb" => non_negative_number_schema(),
        "candidate_downlink_mb" => non_negative_number_schema(),
        "downlink_link_budget" =>
          OrbitalDynamics.Schema.DownlinkLinkBudgetJsonSchema.artifact_schema(
            stable_id_pattern: stable_id_pattern
          ),
        "downlink_link_budget_id" => stable_id_schema(stable_id_pattern),
        "downlink_completion_ratio" => probability_schema(),
        "selected_downlink_shortfall_mb" => non_negative_number_schema(),
        "downlink_requirement_status" => %{"type" => "string"},
        "downlink_completion_source" => %{"type" => "string"},
        "downlink_completion_sources" => string_array_schema,
        "contact_success" => %{"type" => "boolean"},
        "contact_result" => %{"type" => "string"},
        "contact_success_factor" => probability_schema(),
        "contact_success_factor_source" => %{"type" => "string"},
        "command_success" => %{"type" => "boolean"},
        "command_result" => %{"type" => "string"},
        "command_success_factor" => probability_schema(),
        "command_success_factor_source" => %{"type" => "string"},
        "starts_at_s" => %{"type" => "number"},
        "ends_at_s" => %{"type" => "number"},
        "direction" => %{"type" => "string"},
        "type" => %{"type" => "string"},
        "selected" => %{"type" => "boolean"},
        "selected_contact_id" => stable_id_schema(stable_id_pattern),
        "allocation_status" => %{
          "type" => "string",
          "enum" => contact_allocation_capability.row_statuses
        },
        "effective_allocation_status" => %{
          "type" => "string",
          "enum" => contact_allocation_capability.effective_row_statuses
        },
        "allocation_reason" => %{"type" => "string"},
        "contact_status" => %{"type" => "string"},
        "source_approval_status" => %{"type" => "string"},
        "review_status" => %{"type" => "string"},
        "approval_status" => %{
          "type" => "string",
          "enum" => ["auto_approvable", "operator_review_required", "blocked_by_policy"]
        },
        "approval_requirements" => %{
          "type" => "array",
          "items" => Keyword.fetch!(opts, :approval_requirement_schema)
        },
        "approval_rule_matches" => %{
          "type" => "array",
          "items" => Keyword.fetch!(opts, :policy_decision_rule_match_schema)
        },
        "policy_decision" => Keyword.fetch!(opts, :policy_decision_schema),
        "source_contention_recommendation" =>
          Keyword.fetch!(opts, :source_contention_recommendation_schema),
        "source_contact_suppression" => %{"type" => "object"},
        "source_resource_suppression" => %{"type" => "object"},
        "provider_counteroffer_id" => stable_id_schema(stable_id_pattern),
        "provider_counteroffer_status" => %{"type" => "string"},
        "provider_counteroffer_negotiation_state" => %{
          "type" => "string",
          "enum" => station_calendar_capability.provider_counteroffer_negotiation_states
        },
        "provider_counteroffer_reason_code" => %{"type" => "string"},
        "provider_counteroffer_cost_delta" => %{"type" => "number"},
        "provider_counteroffer_lock_deadline_s" => %{"type" => "number"},
        "provider_counteroffer_starts_at_s" => %{"type" => "number"},
        "provider_counteroffer_ends_at_s" => %{"type" => "number"},
        "provider_counteroffer_start_delta_s" => %{"type" => "number"},
        "provider_counteroffer_end_delta_s" => %{"type" => "number"},
        "provider_counteroffer_duration_delta_s" => %{"type" => "number"},
        "suppressed_reason" => %{"type" => "string"},
        "resource_blocking_dimension" => %{"type" => "string"},
        "resource_source_quality" => %{"type" => "string"},
        "resource_trust_boundary" => %{"type" => "string"},
        "resource_trust_boundary_status" => %{"type" => "string"},
        "resource_provenance" => %{"type" => "object"},
        "source_resource_summary" => %{"type" => "object"},
        "fuel_margin" => %{"type" => "number"},
        "power_margin" => %{"type" => "number"},
        "storage_margin" => %{"type" => "number"},
        "downlink_margin" => %{"type" => "number"},
        "thermal_margin_c" => %{"type" => "number"},
        "battery_capacity_wh" => %{"type" => "number"},
        "battery_energy_used_wh" => %{"type" => "number"},
        "battery_energy_generated_wh" => non_negative_number_schema(),
        "battery_state_of_charge" => probability_schema(),
        "spacecraft_available" => %{"type" => "boolean"},
        "payload_available" => %{"type" => "boolean"},
        "antenna_available" => %{"type" => "boolean"},
        "degraded" => %{"type" => "boolean"},
        "mode" => %{"type" => "string"},
        "incompatible_activity_types" => string_array_schema,
        "suppressed_activity_types" => string_array_schema,
        "source_station_calendar_contact" => %{"type" => "object"},
        "source_station_calendar_entry" => %{"type" => "object"},
        "source_station_calendar_overlaps" => %{"type" => "array"},
        "station_availability" => %{"type" => "string"},
        "station_calendar_status" => %{"type" => "string"},
        "station_calendar_precedence_rank" => integer_schema(),
        "station_calendar_precedence_availability" => %{"type" => "string"},
        "station_calendar_entry_id" => stable_id_schema(stable_id_pattern),
        "station_calendar_provider_id" => stable_id_schema(stable_id_pattern),
        "station_calendar_provider_entry_id" => stable_id_schema(stable_id_pattern),
        "station_calendar_directions" => string_array_schema,
        "station_calendar_trust_boundary_status" => %{"type" => "string"},
        "trust_boundary" => %{"type" => "string"},
        "provenance" => %{"type" => "object", "additionalProperties" => true},
        "station_calendar_overlap_count" => integer_schema(),
        "station_calendar_overlap_entry_ids" => stable_id_array_schema,
        "station_calendar_overlap_availabilities" => string_array_schema,
        "station_calendar_entry_ambiguous" => %{"type" => "boolean"},
        "station_calendar_ambiguous_entry_count" => integer_schema(),
        "station_calendar_ambiguous_entry_ids" => stable_id_array_schema,
        "station_calendar_reservation_overlap_count" => integer_schema(),
        "station_calendar_reservation_ids" => stable_id_array_schema,
        "station_calendar_reserved_by" => string_array_schema,
        "station_calendar_reservation_statuses" => string_array_schema,
        "station_calendar_reservation_expires_at_s" => number_array_schema,
        "station_contention_status" => %{"type" => "string"},
        "station_reservation_id" => stable_id_schema(stable_id_pattern),
        "station_reservation_expires_at_s" => %{"type" => "number"},
        "station_reserved_by" => %{"type" => "string"},
        "station_reservation_status" => %{"type" => "string"},
        "station_reservation_match_status" => %{"type" => "string"},
        "deferred_contact_ids" => stable_id_array_schema,
        "selected_priority" => %{"type" => "number"},
        "selected_priority_source" => %{"type" => "string"},
        "deferred_contact_priorities" => %{
          "type" => "array",
          "items" => Keyword.fetch!(opts, :deferred_priority_schema)
        },
        "requested_priority_fields" => string_array_schema,
        "priority_field_evidence_counts" =>
          Keyword.fetch!(opts, :priority_field_evidence_counts_schema),
        "priority_fields_without_numeric_evidence_count" => integer_schema(),
        "priority_fields_without_numeric_evidence" => string_array_schema,
        "resolution_priority_override_count" => integer_schema(),
        "resolution_priority_override_contact_ids" => stable_id_array_schema,
        "ignored_priority_override_count" => integer_schema(),
        "ignored_priority_override_keys" => string_array_schema,
        "ignored_priority_override_contact_ids" => stable_id_array_schema,
        "ignored_priority_override_input" => %{"type" => "string"}
      }
    }
  end

  def capacity_pack_group_from_deps(deps) do
    deps
    |> capacity_pack_group_opts()
    |> capacity_pack_group()
  end

  def capacity_pack_group_from_context(
        stable_id_pattern,
        stable_id_array_schema,
        capacity_requirement_row_schema,
        source_contention_recommendation_schema
      ) do
    [
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: stable_id_array_schema,
      capacity_requirement_row_schema: capacity_requirement_row_schema,
      source_contention_recommendation_schema: source_contention_recommendation_schema
    ]
    |> capacity_pack_group_opts()
    |> capacity_pack_group()
  end

  def capacity_pack_group(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "contention_group_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "ground_station_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "capacity_fraction" => probability_schema(),
        "used_capacity_fraction" => probability_schema(),
        "unused_capacity_fraction" => probability_schema(),
        "input_contact_ids" => Keyword.fetch!(opts, :stable_id_array_schema),
        "selected_contact_ids" => Keyword.fetch!(opts, :stable_id_array_schema),
        "capacity_packed_contact_ids" => Keyword.fetch!(opts, :stable_id_array_schema),
        "deferred_contact_ids" => Keyword.fetch!(opts, :stable_id_array_schema),
        "capacity_requirement_rows" => %{
          "type" => "array",
          "items" => Keyword.fetch!(opts, :capacity_requirement_row_schema)
        },
        "default_required_capacity_fraction" => probability_schema(),
        "pack_status" => %{"type" => "string"},
        "source_contention_recommendation" =>
          Keyword.fetch!(opts, :source_contention_recommendation_schema)
      }
    }
  end

  def capacity_requirement_row_from_deps(deps) do
    deps
    |> capacity_requirement_row_opts()
    |> capacity_requirement_row()
  end

  def capacity_requirement_row_from_context(stable_id_pattern) do
    [stable_id_pattern: stable_id_pattern]
    |> capacity_requirement_row_opts()
    |> capacity_requirement_row()
  end

  def capacity_requirement_row(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "contact_id",
        "required_capacity_fraction",
        "required_capacity_fraction_source"
      ],
      "properties" => %{
        "contact_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "allocation_status" => %{"type" => "string"},
        "allocation_reason" => %{"type" => "string"},
        "capacity_pack_status" => %{"type" => "string"},
        "required_capacity_fraction" => probability_schema(),
        "required_capacity_fraction_source" => %{"type" => "string"}
      }
    }
  end

  def summary_assumptions_from_deps(deps) do
    deps
    |> summary_assumptions_opts()
    |> summary_assumptions()
  end

  def summary_assumptions_from_context(
        row_statuses,
        effective_row_statuses,
        station_unavailable_aliases,
        station_blocking_availability,
        station_availability_precedence,
        capacity_pack_statuses,
        reduced_capacity_pack_statuses,
        station_reservation_match_statuses,
        station_reservation_expiration_statuses,
        required_capacity_fraction_source_values,
        required_capacity_value_paths,
        default_required_capacity_value_paths,
        provider_direction_aliases
      ) do
    [
      row_statuses: row_statuses,
      effective_row_statuses: effective_row_statuses,
      station_unavailable_aliases: station_unavailable_aliases,
      station_blocking_availability: station_blocking_availability,
      station_availability_precedence: station_availability_precedence,
      capacity_pack_statuses: capacity_pack_statuses,
      reduced_capacity_pack_statuses: reduced_capacity_pack_statuses,
      station_reservation_match_statuses: station_reservation_match_statuses,
      station_reservation_expiration_statuses: station_reservation_expiration_statuses,
      required_capacity_fraction_source_values: required_capacity_fraction_source_values,
      required_capacity_value_paths: required_capacity_value_paths,
      default_required_capacity_value_paths: default_required_capacity_value_paths,
      provider_direction_aliases: provider_direction_aliases
    ]
    |> summary_assumptions_opts()
    |> summary_assumptions()
  end

  def summary_assumptions(opts) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["execution_boundary", "source", "operator_authority"],
      "properties" => %{
        "execution_boundary" => %{
          "type" => "string",
          "const" => "artifact_only_no_provider_reservation_or_schedule_mutation"
        },
        "source" => %{"type" => "string", "const" => "contact_allocation_report.v1"},
        "operator_authority" => %{"type" => "string", "const" => "not_granted_by_summary"},
        "row_statuses" => enum_array_const(Keyword.fetch!(opts, :row_statuses)),
        "effective_row_statuses" =>
          enum_array_const(Keyword.fetch!(opts, :effective_row_statuses)),
        "station_unavailable_aliases" =>
          enum_array_const(Keyword.fetch!(opts, :station_unavailable_aliases)),
        "station_blocking_availability" =>
          enum_array_const(Keyword.fetch!(opts, :station_blocking_availability)),
        "station_availability_precedence" => %{
          "type" => "object",
          "const" => Keyword.fetch!(opts, :station_availability_precedence),
          "additionalProperties" => %{"type" => "integer", "minimum" => 0}
        },
        "capacity_pack_statuses" =>
          enum_array_const(Keyword.fetch!(opts, :capacity_pack_statuses)),
        "reduced_capacity_pack_statuses" =>
          enum_array_const(Keyword.fetch!(opts, :reduced_capacity_pack_statuses)),
        "station_reservation_match_statuses" =>
          enum_array_const(Keyword.fetch!(opts, :station_reservation_match_statuses)),
        "station_reservation_expiration_statuses" =>
          enum_array_const(Keyword.fetch!(opts, :station_reservation_expiration_statuses)),
        "required_capacity_fraction_source_values" =>
          enum_array_const(Keyword.fetch!(opts, :required_capacity_fraction_source_values)),
        "required_capacity_value_paths" => %{
          "type" => "array",
          "const" => Keyword.fetch!(opts, :required_capacity_value_paths),
          "items" => capacity_value_path()
        },
        "default_required_capacity_value_paths" => %{
          "type" => "array",
          "const" => Keyword.fetch!(opts, :default_required_capacity_value_paths),
          "items" => capacity_value_path()
        },
        "provider_direction_aliases" => %{
          "type" => "object",
          "const" => Keyword.fetch!(opts, :provider_direction_aliases),
          "additionalProperties" => %{"type" => "string"}
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

  def property("rows", opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :row_schema)}
  end

  def property("reduced_capacity_pack_groups", opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :capacity_pack_group_schema)}
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "deterministic_station_contact_allocation"}
  end

  def property("source", _opts) do
    %{"type" => "string"}
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, opts) when field in @stable_id_array_fields do
    Keyword.fetch!(opts, :stable_id_array_schema)
  end

  def property(field, opts) when field in @stable_id_array_map_fields do
    %{
      "type" => "object",
      "additionalProperties" => Keyword.fetch!(opts, :stable_id_array_schema)
    }
  end

  def property("station_pressure_contact_ids_by_direction_and_ground_station_id", opts) do
    Keyword.fetch!(opts, :nested_stable_id_array_map_schema)
  end

  def property(field, opts) when field in @string_array_fields do
    Keyword.fetch!(opts, :string_array_schema)
  end

  def property(field, opts) when field in @trust_boundary_count_map_fields do
    Keyword.fetch!(opts, :trust_boundary_count_map_schema)
  end

  def property(field, opts) when field in @enum_count_map_fields do
    capability = Keyword.fetch!(opts, :contact_allocation_capability)
    enum_count_map_schema = Keyword.fetch!(opts, :enum_count_map_schema)

    values =
      case field do
        "allocation_status_counts" -> capability.row_statuses
        "effective_allocation_status_counts" -> capability.effective_row_statuses
      end

    enum_count_map_schema.(values)
  end

  def property(field, opts) when field in @count_map_fields do
    Keyword.fetch!(opts, :count_map_schema)
  end

  def property("earliest_station_reservation_expires_at_s", _opts) do
    %{"type" => "number"}
  end

  def property(field, _opts) when field in @non_negative_number_fields do
    %{"type" => "number", "minimum" => 0.0}
  end

  def property(field, opts) when field in @non_negative_number_map_fields do
    Keyword.fetch!(opts, :non_negative_number_map_schema)
  end

  defp probability_schema do
    %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0}
  end

  defp enum_array_const(values) do
    %{
      "type" => "array",
      "const" => values,
      "items" => %{"type" => "string", "enum" => values}
    }
  end

  defp non_negative_number_schema do
    %{"type" => "number", "minimum" => 0.0}
  end

  defp integer_schema do
    %{"type" => "integer", "minimum" => 0}
  end

  defp stable_id_schema(stable_id_pattern) do
    %{"type" => "string", "pattern" => stable_id_pattern}
  end

  defp row_opts(deps) do
    [
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern),
      stable_id_array_schema: fetch_dep!(deps, :stable_id_array_schema),
      string_array_schema: fetch_dep!(deps, :string_array_schema),
      number_array_schema: fetch_dep!(deps, :number_array_schema),
      actual_data_rate_throughput_derivation_schema:
        fetch_dep!(deps, :actual_data_rate_throughput_derivation_schema),
      approval_requirement_schema: fetch_dep!(deps, :approval_requirement_schema),
      policy_decision_rule_match_schema: fetch_dep!(deps, :policy_decision_rule_match_schema),
      policy_decision_schema: fetch_dep!(deps, :policy_decision_schema),
      source_contention_recommendation_schema:
        fetch_dep!(deps, :source_contention_recommendation_schema),
      contact_allocation_capability: fetch_dep!(deps, :contact_allocation_capability),
      station_calendar_capability: fetch_dep!(deps, :station_calendar_capability),
      deferred_priority_schema: fetch_dep!(deps, :deferred_priority_schema),
      priority_field_evidence_counts_schema:
        fetch_dep!(deps, :priority_field_evidence_counts_schema)
    ]
  end

  defp capacity_pack_group_opts(deps) do
    [
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern),
      stable_id_array_schema: fetch_dep!(deps, :stable_id_array_schema),
      capacity_requirement_row_schema: fetch_dep!(deps, :capacity_requirement_row_schema),
      source_contention_recommendation_schema:
        fetch_dep!(deps, :source_contention_recommendation_schema)
    ]
  end

  defp capacity_requirement_row_opts(deps) do
    [
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)
    ]
  end

  defp summary_assumptions_opts(deps) do
    [
      row_statuses: fetch_dep!(deps, :row_statuses),
      effective_row_statuses: fetch_dep!(deps, :effective_row_statuses),
      station_unavailable_aliases: fetch_dep!(deps, :station_unavailable_aliases),
      station_blocking_availability: fetch_dep!(deps, :station_blocking_availability),
      station_availability_precedence: fetch_dep!(deps, :station_availability_precedence),
      capacity_pack_statuses: fetch_dep!(deps, :capacity_pack_statuses),
      reduced_capacity_pack_statuses: fetch_dep!(deps, :reduced_capacity_pack_statuses),
      station_reservation_match_statuses: fetch_dep!(deps, :station_reservation_match_statuses),
      station_reservation_expiration_statuses:
        fetch_dep!(deps, :station_reservation_expiration_statuses),
      required_capacity_fraction_source_values:
        fetch_dep!(deps, :required_capacity_fraction_source_values),
      required_capacity_value_paths:
        capacity_value_path_assumptions(fetch_dep!(deps, :required_capacity_value_paths)),
      default_required_capacity_value_paths:
        capacity_value_path_assumptions(fetch_dep!(deps, :default_required_capacity_value_paths)),
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
