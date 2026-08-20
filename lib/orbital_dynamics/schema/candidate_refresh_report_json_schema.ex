defmodule OrbitalDynamics.Schema.CandidateRefreshReportJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @freshness_report "freshness_report.v1"
  @refresh_budget_report "refresh_budget_report.v1"
  @refreshed_window "refreshed_window.v1"
  @remaining_horizon "remaining_horizon.v1"

  @freshness_string_array_fields [
    "stale_reasons",
    "unknown_reasons",
    "allowed_state_quality_levels"
  ]

  @freshness_number_fields [
    "current_epoch_s",
    "horizon_starts_at_s",
    "accepted_snapshot_age_s",
    "horizon_start_offset_s",
    "max_snapshot_age_s",
    "max_horizon_start_offset_s"
  ]

  @freshness_string_fields ["accepted_at", "generated_at"]

  @freshness_object_fields ["accepted_state_quality_level", "state_quality_status"]

  @refresh_budget_count_fields [
    "input_candidate_count",
    "kept_candidate_count",
    "dropped_candidate_count",
    "max_candidate_activities"
  ]

  @refreshed_window_id_fields ["id", "scenario_id", "target_id", "ground_station_id"]

  @refreshed_window_number_fields [
    "starts_at_s",
    "ends_at_s",
    "minimum_elevation_deg",
    "max_elevation_deg",
    "target_priority"
  ]

  @candidate_refresh_array_item_fields [
    "source_window_lineage",
    "invalidated_candidates",
    "candidate_activities",
    "contact_intents",
    "resource_summaries",
    "validation_records"
  ]

  @candidate_refresh_array_item_schema_options %{
    "source_window_lineage" => :source_window_lineage_schema,
    "invalidated_candidates" => :invalidated_candidate_schema,
    "candidate_activities" => :candidate_activity_schema,
    "contact_intents" => :contact_intent_schema,
    "resource_summaries" => :resource_summary_schema,
    "validation_records" => :validation_record_schema
  }

  @candidate_refresh_embedded_report_fields [
    "candidate_diff_report",
    "contact_allocation_report",
    "contact_filter_report",
    "freshness_report",
    "resource_filter_report"
  ]

  @candidate_refresh_embedded_report_contracts %{
    "candidate_diff_report" => "candidate_diff_report.v1",
    "contact_allocation_report" => "contact_allocation_report.v1",
    "contact_filter_report" => "contact_filter_report.v1",
    "freshness_report" => "freshness_report.v1",
    "resource_filter_report" => "resource_filter_report.v1"
  }

  @execution_count_fields ~w(
    spacecraft_state_count
    ground_station_count
    trajectory_count
    trajectory_sample_count
    event_result_count
    access_window_count
    eclipse_interval_count
    candidate_activity_count
    downlink_candidate_count
  )

  @execution_policy_fields ~w(propagation environment access eclipse)

  @candidate_refresh_publication_lineage_id_array_fields [
    "source_report_timeline_publication_ids",
    "source_report_timeline_publication_source_artifact_ids",
    "source_report_timeline_publication_supersedes_artifact_ids",
    "source_report_timeline_publication_downstream_product_ids",
    "source_report_timeline_publication_invalidated_downstream_product_ids",
    "source_report_timeline_publication_impacted_source_activity_ids",
    "source_report_timeline_publication_impacted_source_timeline_ids",
    "source_report_timeline_publication_dependent_activity_ids",
    "source_report_timeline_publication_dependent_timeline_ids",
    "source_report_timeline_publication_source_dependent_activity_ids",
    "source_report_timeline_publication_source_dependent_timeline_ids",
    "source_report_timeline_publication_replacement_dependent_activity_ids",
    "source_report_timeline_publication_replacement_dependent_timeline_ids",
    "source_report_operational_readiness_publication_ids",
    "source_report_operational_readiness_source_artifact_ids",
    "source_report_operational_readiness_supersedes_artifact_ids",
    "source_report_operational_readiness_downstream_product_ids",
    "source_report_operational_readiness_invalidated_downstream_product_ids",
    "source_report_quality_gate_publication_ids",
    "source_report_quality_gate_source_artifact_ids",
    "source_report_quality_gate_supersedes_artifact_ids",
    "source_report_quality_gate_downstream_product_ids",
    "source_report_quality_gate_invalidated_downstream_product_ids"
  ]

  @candidate_refresh_publication_lineage_count_map_fields [
    "source_report_timeline_publication_downstream_invalidation_reason_counts",
    "source_report_timeline_publication_source_artifact_type_counts",
    "source_report_operational_readiness_timeline_publication_source_artifact_type_counts",
    "source_report_quality_gate_timeline_publication_source_artifact_type_counts"
  ]

  @candidate_refresh_publication_lineage_stable_id_array_map_fields [
    "source_report_timeline_publication_invalidated_downstream_product_ids_by_reason"
  ]

  @candidate_refresh_resource_availability_count_fields [
    "source_report_operational_readiness_resource_availability_pressure_count",
    "source_report_quality_gate_resource_availability_pressure_count"
  ]

  @candidate_refresh_resource_availability_count_map_fields [
    "source_report_operational_readiness_resource_availability_reason_counts",
    "source_report_operational_readiness_station_availability_reason_counts",
    "source_report_operational_readiness_resource_blocking_dimension_counts",
    "source_report_quality_gate_resource_availability_reason_counts",
    "source_report_quality_gate_station_availability_reason_counts",
    "source_report_quality_gate_resource_blocking_dimension_counts"
  ]

  @candidate_refresh_resource_availability_string_array_fields [
    "source_report_operational_readiness_resource_availability_reason_ids",
    "source_report_operational_readiness_station_availability_reason_ids",
    "source_report_operational_readiness_unavailable_resource_reason_ids",
    "source_report_quality_gate_resource_availability_reason_ids",
    "source_report_quality_gate_station_availability_reason_ids",
    "source_report_quality_gate_unavailable_resource_reason_ids"
  ]

  def candidate_refresh_property_field?(field) do
    field in @candidate_refresh_array_item_fields or
      field in @candidate_refresh_embedded_report_fields or
      field == "candidate_refresh_execution" or
      field == "model_limits" or
      field == "warnings" or
      field == "remaining_horizon" or
      field == "accepted_planning_state" or
      field in ["operational_feedback", "provenance"] or
      field in @candidate_refresh_publication_lineage_id_array_fields or
      field in @candidate_refresh_publication_lineage_count_map_fields or
      field in @candidate_refresh_publication_lineage_stable_id_array_map_fields or
      field in @candidate_refresh_resource_availability_count_fields or
      field in @candidate_refresh_resource_availability_count_map_fields or
      field in @candidate_refresh_resource_availability_string_array_fields
  end

  def candidate_refresh_property_from_context(field, deps) when is_list(deps) do
    candidate_refresh_property(field, candidate_refresh_property_opts(field, deps))
  end

  def candidate_refresh_property_fun_from_context(deps) when is_list(deps) do
    fn field ->
      candidate_refresh_property_from_context(field, deps)
    end
  end

  def auxiliary_report_property_from_context(field, contract_name, deps) when is_list(deps) do
    auxiliary_report_property(
      field,
      contract_name,
      auxiliary_report_property_opts(field, contract_name, deps)
    )
  end

  def auxiliary_report_property_fun_from_context(deps) when is_list(deps) do
    contract_name = fetch_dep!(deps, :contract_name)

    fn field ->
      auxiliary_report_property_from_context(field, contract_name, deps)
    end
  end

  def auxiliary_report_property_field?(field, @freshness_report) do
    field in ["schema_contract", "model", "status", "model_limits"] or
      field in @freshness_string_array_fields or
      field in @freshness_number_fields or
      field in @freshness_string_fields or
      field in @freshness_object_fields
  end

  def auxiliary_report_property_field?(field, @refresh_budget_report) do
    field in [
      "schema_contract",
      "model",
      "model_limits",
      "selection_order",
      "invalid_candidate_limit_policy",
      "assumptions",
      "kept_candidate_ids",
      "dropped_candidate_ids"
    ] or field in @refresh_budget_count_fields
  end

  def auxiliary_report_property_field?(field, @refreshed_window) do
    field in ["schema_contract", "sample_count", "type", "assumptions"] or
      field in @refreshed_window_id_fields or
      field in @refreshed_window_number_fields
  end

  def auxiliary_report_property_field?(field, @remaining_horizon) do
    field in ["schema_contract", "starts_at_s", "ends_at_s", "output_step_s"]
  end

  def auxiliary_report_property(field, @freshness_report, opts) do
    freshness_property(field, opts)
  end

  def auxiliary_report_property(field, @refresh_budget_report, opts) do
    refresh_budget_property(field, opts)
  end

  def auxiliary_report_property(field, @refreshed_window, opts) do
    refreshed_window_property(field, opts)
  end

  def auxiliary_report_property(field, @remaining_horizon, opts) do
    remaining_horizon_property(field, opts)
  end

  def auxiliary_report_property_opts("model_limits", contract_name, deps)
      when contract_name in [@freshness_report, @refresh_budget_report] do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def auxiliary_report_property_opts(field, @refresh_budget_report, deps)
      when field in ["kept_candidate_ids", "dropped_candidate_ids"] do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def auxiliary_report_property_opts(field, @refreshed_window, deps)
      when field in @refreshed_window_id_fields do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def auxiliary_report_property_opts(_field, _contract_name, _deps), do: []

  def candidate_refresh_property_opts(field, deps)
      when field in @candidate_refresh_array_item_fields do
    item_schema_option = Map.fetch!(@candidate_refresh_array_item_schema_options, field)
    [{item_schema_option, fetch_dep!(deps, item_schema_option)}]
  end

  def candidate_refresh_property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def candidate_refresh_property_opts("accepted_planning_state", deps) do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def candidate_refresh_property_opts("candidate_refresh_execution", deps) do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def candidate_refresh_property_opts("operational_feedback", deps) do
    [operational_feedback_schema: fetch_dep!(deps, :operational_feedback_schema)]
  end

  def candidate_refresh_property_opts("provenance", deps) do
    [
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern),
      provider_counteroffer_actions: fetch_dep!(deps, :provider_counteroffer_actions),
      safety_case_count_fields: fetch_dep!(deps, :safety_case_count_fields)
    ]
  end

  def candidate_refresh_property_opts(field, deps)
      when field in @candidate_refresh_embedded_report_fields do
    [embedded_contract_schema: fetch_dep!(deps, :embedded_contract_schema)]
  end

  def candidate_refresh_property_opts(field, deps)
      when field in @candidate_refresh_publication_lineage_id_array_fields or
             field in @candidate_refresh_publication_lineage_stable_id_array_map_fields do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def candidate_refresh_property_opts(_field, _deps), do: []

  def freshness_property("schema_contract", _opts) do
    %{"type" => "string", "const" => "freshness_report.v1"}
  end

  def freshness_property("model", _opts) do
    %{"type" => "string", "const" => "accepted_snapshot_horizon_and_quality_freshness"}
  end

  def freshness_property("status", _opts) do
    %{"type" => "string", "enum" => ["current", "stale", "unknown"]}
  end

  def freshness_property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def freshness_property(field, _opts) when field in @freshness_string_array_fields do
    string_array_schema()
  end

  def freshness_property(field, _opts) when field in @freshness_number_fields do
    %{"type" => "number"}
  end

  def freshness_property(field, _opts) when field in @freshness_string_fields do
    %{"type" => "string"}
  end

  def freshness_property(field, _opts) when field in @freshness_object_fields do
    %{"type" => "object"}
  end

  def refresh_budget_property("schema_contract", _opts) do
    %{"type" => "string", "const" => "refresh_budget_report.v1"}
  end

  def refresh_budget_property(field, opts)
      when field in ["kept_candidate_ids", "dropped_candidate_ids"] do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> stable_id_array_schema()
  end

  def refresh_budget_property("model", _opts) do
    %{"type" => "string", "const" => "deterministic_candidate_limit_after_filters"}
  end

  def refresh_budget_property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def refresh_budget_property("selection_order", _opts) do
    %{"type" => "string"}
  end

  def refresh_budget_property("invalid_candidate_limit_policy", _opts) do
    %{"type" => "boolean"}
  end

  def refresh_budget_property(field, _opts) when field in @refresh_budget_count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def refresh_budget_property("assumptions", _opts) do
    %{"type" => "object"}
  end

  def refreshed_window_property("schema_contract", _opts) do
    %{"type" => "string", "const" => "refreshed_window.v1"}
  end

  def refreshed_window_property(field, opts) when field in @refreshed_window_id_fields do
    %{"type" => "string", "pattern" => Keyword.fetch!(opts, :stable_id_pattern)}
  end

  def refreshed_window_property(field, _opts) when field in @refreshed_window_number_fields do
    %{"type" => "number"}
  end

  def refreshed_window_property("sample_count", _opts) do
    %{"type" => "integer", "minimum" => 0}
  end

  def refreshed_window_property("type", _opts) do
    %{"type" => "string"}
  end

  def refreshed_window_property("assumptions", _opts) do
    %{"type" => "object"}
  end

  def candidate_refresh_property(field, opts)
      when field in @candidate_refresh_array_item_fields do
    item_schema_option = Map.fetch!(@candidate_refresh_array_item_schema_options, field)

    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, item_schema_option)
    }
  end

  def candidate_refresh_property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{
        "type" => "string",
        "enum" => model_limits
      }
    }
  end

  def candidate_refresh_property("accepted_planning_state", opts) do
    accepted_planning_state_ref(Keyword.fetch!(opts, :stable_id_pattern))
  end

  def candidate_refresh_property("candidate_refresh_execution", opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => false,
      "required" => [
        "schema_contract",
        "bundle_id",
        "execution_mode",
        "policy_fingerprint",
        "snapshot_id",
        "counts",
        "policies",
        "external_validation",
        "model_limits"
      ],
      "properties" => %{
        "schema_contract" => %{
          "type" => "string",
          "const" => "candidate_refresh_execution.v1"
        },
        "bundle_id" => %{
          "type" => "string",
          "const" => "candidate_refresh.earth_j2_drag_access_eclipse.v1"
        },
        "execution_mode" => %{"type" => "string", "const" => "offline_deterministic"},
        "policy_fingerprint" => %{"type" => "string", "pattern" => "^[0-9a-f]{64}$"},
        "snapshot_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "counts" => execution_counts_schema(),
        "policies" => execution_policies_schema(),
        "external_validation" => execution_external_validation_schema(),
        "model_limits" => %{
          "type" => "array",
          "const" => OrbitalDynamics.CandidateRefresh.ExecutionPolicy.model_limits(),
          "items" => %{"type" => "string"}
        }
      }
    }
  end

  def candidate_refresh_property("warnings", _opts) do
    CommonJsonSchema.string_array()
  end

  def candidate_refresh_property("remaining_horizon", _opts) do
    embedded_remaining_horizon()
  end

  def candidate_refresh_property("operational_feedback", opts) do
    Keyword.fetch!(opts, :operational_feedback_schema)
  end

  def candidate_refresh_property("provenance", opts) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "source_reports" =>
          source_reports(
            stable_id_pattern: Keyword.fetch!(opts, :stable_id_pattern),
            provider_counteroffer_actions: Keyword.fetch!(opts, :provider_counteroffer_actions),
            safety_case_count_fields: Keyword.fetch!(opts, :safety_case_count_fields)
          ),
        "run_input_sources" => %{
          "type" => "object",
          "additionalProperties" => CommonJsonSchema.string_array()
        }
      }
    }
  end

  def candidate_refresh_property(field, opts)
      when field in @candidate_refresh_embedded_report_fields do
    embedded_contract_schema = Keyword.fetch!(opts, :embedded_contract_schema)
    contract_name = Map.fetch!(@candidate_refresh_embedded_report_contracts, field)

    embedded_contract_schema.(contract_name)
  end

  def candidate_refresh_property(field, opts)
      when field in @candidate_refresh_publication_lineage_id_array_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def candidate_refresh_property(field, _opts)
      when field in @candidate_refresh_publication_lineage_count_map_fields do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def candidate_refresh_property(field, opts)
      when field in @candidate_refresh_publication_lineage_stable_id_array_map_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array_map()
  end

  def candidate_refresh_property(field, _opts)
      when field in @candidate_refresh_resource_availability_count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def candidate_refresh_property(field, _opts)
      when field in @candidate_refresh_resource_availability_count_map_fields do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def candidate_refresh_property(field, _opts)
      when field in @candidate_refresh_resource_availability_string_array_fields do
    CommonJsonSchema.string_array()
  end

  defp execution_counts_schema do
    %{
      "type" => "object",
      "additionalProperties" => false,
      "required" => @execution_count_fields,
      "properties" =>
        Map.new(@execution_count_fields, fn field ->
          {field, %{"type" => "integer", "minimum" => 0}}
        end)
    }
  end

  defp execution_policies_schema do
    %{
      "type" => "object",
      "additionalProperties" => false,
      "required" => @execution_policy_fields,
      "properties" =>
        Map.new(@execution_policy_fields, fn field ->
          {field, %{"type" => "object"}}
        end)
    }
  end

  defp execution_external_validation_schema do
    %{
      "type" => "object",
      "additionalProperties" => false,
      "required" => ["case_id", "validation_scope", "status"],
      "properties" => %{
        "case_id" => %{
          "type" => "string",
          "const" => "orekit_13_1_7_leo_j2_drag_access_eclipse"
        },
        "validation_scope" => %{"type" => "string", "const" => "exact_case_only"},
        "status" => %{
          "type" => "string",
          "const" => "referenced_not_evaluated_by_runner"
        }
      }
    }
  end

  def source_report_summary(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" =>
        %{
          "contract" => %{"type" => "string"},
          "paths" => CommonJsonSchema.string_array(),
          "count" => non_negative_integer(),
          "row_count" => non_negative_integer(),
          "analysis_mode_counts" => CommonJsonSchema.non_negative_integer_count_map(),
          "source_summary_model_counts" => CommonJsonSchema.non_negative_integer_count_map(),
          "source_summary_schema_contract_counts" =>
            CommonJsonSchema.non_negative_integer_count_map(),
          "trust_boundary_status" => %{"type" => "string"},
          "trust_boundaries" => CommonJsonSchema.string_array(),
          "station_reservation_evidence_row_count" => non_negative_integer(),
          "station_reservation_expiration_evidence_row_count" => non_negative_integer(),
          "plan_impact_summary_count" => non_negative_integer(),
          "plan_impact_status_counts" => CommonJsonSchema.non_negative_integer_count_map(),
          "import_readiness_summary_count" => non_negative_integer(),
          "import_readiness_status_counts" => CommonJsonSchema.non_negative_integer_count_map(),
          "import_classification_counts" => CommonJsonSchema.non_negative_integer_count_map(),
          "provider_counteroffer_import_status_counts" =>
            CommonJsonSchema.non_negative_integer_count_map(),
          "counteroffer_lock_deadline_status_counts" =>
            CommonJsonSchema.non_negative_integer_count_map(),
          "counteroffer_ids_by_import_status" =>
            CommonJsonSchema.stable_id_array_map(stable_id_pattern),
          "counteroffer_ids_by_required_import_action" =>
            CommonJsonSchema.stable_id_array_map(stable_id_pattern),
          "counteroffer_ids_by_lock_deadline_status" =>
            CommonJsonSchema.stable_id_array_map(stable_id_pattern),
          "review_counteroffer_ids" => CommonJsonSchema.stable_id_array(stable_id_pattern),
          "no_import_required_counteroffer_ids" =>
            CommonJsonSchema.stable_id_array(stable_id_pattern),
          "affected_station_calendar_entry_ids" => CommonJsonSchema.string_array(),
          "affected_provider_entry_ids" => CommonJsonSchema.string_array(),
          "impact_counteroffer_ids" => CommonJsonSchema.string_array(),
          "timing_shift_counteroffer_ids" => CommonJsonSchema.string_array(),
          "cost_delta_counteroffer_ids" => CommonJsonSchema.string_array()
        }
        |> Map.merge(
          OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema.resource_context_properties(
            opts
          )
        )
        |> Map.merge(
          OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema.adapter_boundary_context_properties()
        )
        |> Map.merge(
          OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema.cadence_import_context_properties()
        )
        |> Map.merge(link_capacity_context_properties())
        |> Map.merge(constraint_context_properties())
        |> Map.merge(resource_projection_context_properties(opts))
        |> Map.merge(resource_filter_context_properties(opts))
        |> Map.merge(contact_contention_context_properties())
        |> Map.merge(candidate_rejection_context_properties())
        |> Map.merge(station_pressure_context_properties())
        |> Map.merge(contact_filter_context_properties(opts))
        |> Map.merge(station_calendar_context_properties(opts))
        |> Map.merge(timeline_activity_context_properties())
        |> Map.merge(timeline_publication_context_properties(opts))
        |> Map.merge(model_acceptance_context_properties())
        |> Map.merge(passive_replay_context_properties(opts))
    }
  end

  def source_reports(opts) do
    source_report_schema = source_report_summary(opts)
    timeline_action_routing_schema = timeline_activity_state_action_routing(opts)

    %{
      "type" => "object",
      "additionalProperties" => source_report_schema,
      "properties" => %{
        "candidate_diff_report" => candidate_diff_source_report(source_report_schema, []),
        "candidate_rejection_report" =>
          candidate_rejection_source_report(source_report_schema, []),
        "command_window_report" =>
          command_window_source_report(source_report_schema,
            stable_id_pattern: Keyword.fetch!(opts, :stable_id_pattern),
            direction_routing_schema: command_window_direction_routing(opts)
          ),
        "constraint_report" => constraint_source_report(source_report_schema, []),
        "contact_allocation_report" =>
          contact_allocation_source_report(source_report_schema,
            stable_id_pattern: Keyword.fetch!(opts, :stable_id_pattern),
            direction_routing_schema: contact_allocation_direction_routing(opts)
          ),
        "contact_contention_report" =>
          contact_contention_source_report(source_report_schema,
            stable_id_pattern: Keyword.fetch!(opts, :stable_id_pattern),
            direction_routing_schema: contact_contention_direction_routing(opts)
          ),
        "contact_contention_resolution_report" =>
          contact_contention_resolution_source_report(source_report_schema,
            stable_id_pattern: Keyword.fetch!(opts, :stable_id_pattern),
            direction_routing_schema: contact_contention_resolution_direction_routing(opts)
          ),
        "contact_filter_report" =>
          contact_filter_source_report(source_report_schema,
            stable_id_pattern: Keyword.fetch!(opts, :stable_id_pattern),
            direction_routing_schema: contact_filter_direction_routing(opts)
          ),
        "contact_intent" =>
          contact_intent_source_report(source_report_schema,
            stable_id_pattern: Keyword.fetch!(opts, :stable_id_pattern)
          ),
        "link_capacity_report" =>
          link_capacity_source_report(source_report_schema,
            stable_id_pattern: Keyword.fetch!(opts, :stable_id_pattern),
            direction_routing_schema: link_capacity_direction_routing(opts)
          ),
        "maneuver_review_report" => maneuver_review_source_report(source_report_schema, []),
        "model_acceptance_report" => model_acceptance_source_report(source_report_schema, []),
        "freshness_report" =>
          passive_replay_source_report(source_report_schema,
            stable_id_pattern: Keyword.fetch!(opts, :stable_id_pattern)
          ),
        "objective_satisfaction_report" =>
          objective_satisfaction_source_report(source_report_schema, []),
        "objective_tradeoff_report" => objective_tradeoff_source_report(source_report_schema, []),
        "score_term_report" => score_term_source_report(source_report_schema, []),
        "refresh_budget_report" =>
          passive_replay_source_report(source_report_schema,
            stable_id_pattern: Keyword.fetch!(opts, :stable_id_pattern)
          ),
        "operational_readiness_report" =>
          operational_readiness_source_report(source_report_schema,
            stable_id_pattern: Keyword.fetch!(opts, :stable_id_pattern)
          ),
        "operational_timeline_report" =>
          operational_timeline_source_report(source_report_schema, []),
        "quality_gate_report" =>
          quality_gate_source_report(source_report_schema,
            stable_id_pattern: Keyword.fetch!(opts, :stable_id_pattern)
          ),
        "provider_counteroffer_report" =>
          provider_counteroffer_source_report(source_report_schema,
            provider_counteroffer_actions: Keyword.fetch!(opts, :provider_counteroffer_actions)
          ),
        "resource_projection_report" =>
          resource_projection_source_report(source_report_schema,
            stable_id_pattern: Keyword.fetch!(opts, :stable_id_pattern)
          ),
        "resource_filter_report" =>
          resource_filter_source_report(source_report_schema,
            stable_id_pattern: Keyword.fetch!(opts, :stable_id_pattern),
            direction_routing_schema: resource_filter_direction_routing(opts)
          ),
        "schema_validation_report" => schema_validation_source_report(source_report_schema, []),
        "station_calendar_report" =>
          source_report_with_direction_routing(
            source_report_schema,
            station_calendar_direction_routing(opts)
          ),
        "station_reservation_report" =>
          source_report_with_direction_routing(
            source_report_schema,
            station_reservation_direction_routing(opts)
          ),
        "validation_safety_case_summary" =>
          validation_safety_case_source_report(source_report_schema,
            safety_case_count_fields: Keyword.fetch!(opts, :safety_case_count_fields)
          ),
        "timeline_feedback_report" => timeline_feedback_source_report(source_report_schema, []),
        "timeline_diff_report" => timeline_diff_source_report(source_report_schema, []),
        "timeline_integrity_report" => timeline_integrity_source_report(source_report_schema, []),
        "timeline_activity_lifecycle_state" =>
          timeline_activity_lifecycle_source_report(source_report_schema,
            action_routing_schema: timeline_action_routing_schema
          ),
        "timeline_lifecycle_state_summary" =>
          timeline_lifecycle_state_source_report(source_report_schema,
            stable_id_pattern: Keyword.fetch!(opts, :stable_id_pattern),
            review_routing_schema: timeline_action_routing_schema
          ),
        "timeline_activity_precondition_summary" =>
          timeline_activity_precondition_source_report(source_report_schema, []),
        "timeline_publication_summary" =>
          timeline_publication_source_report(source_report_schema,
            stable_id_pattern: Keyword.fetch!(opts, :stable_id_pattern)
          ),
        "timeline_dependency_impact_summary" =>
          timeline_dependency_impact_source_report(source_report_schema, []),
        "timeline_transition_application_report" =>
          timeline_transition_application_source_report(source_report_schema, []),
        "timeline_activity_state" =>
          timeline_activity_state_source_report(source_report_schema,
            action_routing_schema: timeline_action_routing_schema
          )
      }
    }
  end

  def timeline_activity_state_action_routing(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => %{
        "type" => "object",
        "additionalProperties" => true,
        "properties" => %{
          "review_count" => %{"type" => "integer", "minimum" => 0},
          "activity_ids" => stable_id_array_schema(stable_id_pattern),
          "timeline_ids" => stable_id_array_schema(stable_id_pattern),
          "status_transition_categories" => string_array_schema(),
          "approval_transition_categories" => string_array_schema(),
          "protection_categories" => string_array_schema()
        }
      }
    }
  end

  def source_report_with_direction_routing(source_report_schema, direction_routing_schema) do
    put_in(source_report_schema, ["properties", "direction_routing"], direction_routing_schema)
  end

  def candidate_diff_source_report(source_report_schema, _opts) do
    update_in(source_report_schema, ["properties"], fn properties ->
      properties
      |> Map.merge(
        CommonJsonSchema.non_negative_integer_properties([
          "retained_candidate_count",
          "new_candidate_count",
          "invalidated_candidate_count"
        ])
      )
      |> Map.merge(
        count_map_properties([
          "diff_reason_counts",
          "invalidated_reason_counts",
          "semantic_change_reason_counts",
          "candidate_diff_changed_field_counts",
          "candidate_diff_candidate_id_counts",
          "candidate_diff_ground_station_counts"
        ])
      )
    end)
  end

  def station_calendar_direction_routing(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => %{
        "type" => "object",
        "additionalProperties" => true,
        "properties" => %{
          "contact_count" => %{"type" => "integer", "minimum" => 0},
          "contact_ids" => stable_id_array_schema(stable_id_pattern),
          "station_calendar_entry_ids" => stable_id_array_schema(stable_id_pattern),
          "station_reservation_ids" => stable_id_array_schema(stable_id_pattern),
          "station_capacity_fractions" => CommonJsonSchema.number_array(),
          "provider_contention_group_count" => %{"type" => "integer", "minimum" => 0},
          "provider_contention_group_ids" => stable_id_array_schema(stable_id_pattern),
          "provider_contention_source_entry_ids" => stable_id_array_schema(stable_id_pattern),
          "provider_contention_provider_entry_ids" => stable_id_array_schema(stable_id_pattern),
          "provider_contention_capacity_fractions" => CommonJsonSchema.number_array()
        }
      }
    }
  end

  def station_calendar_context_properties(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "affected_contact_ground_station_counts" =>
        CommonJsonSchema.non_negative_integer_count_map(),
      "affected_contact_availability_counts" => CommonJsonSchema.non_negative_integer_count_map(),
      "affected_contact_count" => %{"type" => "integer", "minimum" => 0},
      "affected_contact_ids" => stable_id_array_schema(stable_id_pattern),
      "affected_station_calendar_entry_ids" => stable_id_array_schema(stable_id_pattern),
      "affected_station_reservation_ids" => stable_id_array_schema(stable_id_pattern),
      "direction_counts" => CommonJsonSchema.non_negative_integer_count_map(),
      "contact_ids_by_direction" => CommonJsonSchema.stable_id_array_map(stable_id_pattern),
      "station_calendar_entry_ids_by_direction" =>
        CommonJsonSchema.stable_id_array_map(stable_id_pattern),
      "station_reservation_ids_by_direction" =>
        CommonJsonSchema.stable_id_array_map(stable_id_pattern),
      "station_capacity_fractions_by_direction" => CommonJsonSchema.number_array_map(),
      "direction_routing" => station_calendar_direction_routing(opts),
      "provider_calendar_contention_provider_counts" =>
        CommonJsonSchema.non_negative_integer_count_map(),
      "provider_calendar_contention_ground_station_counts" =>
        CommonJsonSchema.non_negative_integer_count_map(),
      "provider_calendar_contention_group_count" => %{"type" => "integer", "minimum" => 0},
      "provider_calendar_contention_group_ids" => stable_id_array_schema(stable_id_pattern),
      "provider_calendar_contention_source_entry_ids" =>
        stable_id_array_schema(stable_id_pattern),
      "provider_calendar_contention_provider_entry_ids" =>
        stable_id_array_schema(stable_id_pattern),
      "provider_calendar_contention_capacity_fractions" => CommonJsonSchema.number_array(),
      "provider_calendar_contention_minimum_capacity_fraction" => %{
        "type" => "number",
        "minimum" => 0.0
      },
      "provider_calendar_contention_direction_counts" =>
        CommonJsonSchema.non_negative_integer_count_map(),
      "provider_calendar_contention_group_ids_by_direction" =>
        CommonJsonSchema.stable_id_array_map(stable_id_pattern),
      "provider_calendar_contention_source_entry_ids_by_direction" =>
        CommonJsonSchema.stable_id_array_map(stable_id_pattern),
      "provider_calendar_contention_provider_entry_ids_by_direction" =>
        CommonJsonSchema.stable_id_array_map(stable_id_pattern),
      "provider_calendar_contention_capacity_fractions_by_direction" =>
        CommonJsonSchema.number_array_map()
    }
  end

  def station_reservation_direction_routing(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => %{
        "type" => "object",
        "additionalProperties" => true,
        "properties" => %{
          "contact_count" => %{"type" => "integer", "minimum" => 0},
          "contact_ids" => stable_id_array_schema(stable_id_pattern),
          "reservation_hold_ids" => stable_id_array_schema(stable_id_pattern),
          "reservation_hold_contact_ids" => stable_id_array_schema(stable_id_pattern)
        }
      }
    }
  end

  def contact_allocation_source_report(source_report_schema, opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    direction_routing_schema = Keyword.fetch!(opts, :direction_routing_schema)

    update_in(source_report_schema, ["properties"], fn properties ->
      Map.merge(properties, %{
        "direction_routing" => direction_routing_schema,
        "provider_reservation_no_request_contact_ids_by_direction_and_ground_station" =>
          CommonJsonSchema.nested_stable_id_array_map(stable_id_pattern),
        "provider_reservation_request_contact_ids_by_direction_and_ground_station" =>
          CommonJsonSchema.nested_stable_id_array_map(stable_id_pattern),
        "provider_reservation_review_contact_ids_by_direction_and_ground_station" =>
          CommonJsonSchema.nested_stable_id_array_map(stable_id_pattern)
      })
    end)
  end

  def contact_allocation_direction_routing(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => %{
        "type" => "object",
        "additionalProperties" => true,
        "properties" => %{
          "contact_count" => %{"type" => "integer", "minimum" => 0},
          "contact_ids" => stable_id_array_schema(stable_id_pattern),
          "station_pressure_contact_count" => %{"type" => "integer", "minimum" => 0},
          "station_pressure_contact_ids" => stable_id_array_schema(stable_id_pattern),
          "reservation_conflict_contact_count" => %{"type" => "integer", "minimum" => 0},
          "reservation_conflict_contact_ids" => stable_id_array_schema(stable_id_pattern),
          "provider_reservation_no_request_contact_ids" =>
            stable_id_array_schema(stable_id_pattern),
          "provider_reservation_request_contact_ids" => stable_id_array_schema(stable_id_pattern),
          "provider_reservation_review_contact_ids" => stable_id_array_schema(stable_id_pattern)
        }
      }
    }
  end

  def contact_contention_source_report(source_report_schema, opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    direction_routing_schema = Keyword.fetch!(opts, :direction_routing_schema)

    update_in(source_report_schema, ["properties"], fn properties ->
      Map.merge(properties, %{
        "conflict_group_count" => %{"type" => "integer", "minimum" => 0},
        "invalid_contact_input_count" => %{"type" => "integer", "minimum" => 0},
        "invalid_contact_input_ids" => stable_id_array_schema(stable_id_pattern),
        "resource_scope_counts" => CommonJsonSchema.non_negative_integer_count_map(),
        "direction_counts" => CommonJsonSchema.non_negative_integer_count_map(),
        "contact_ids_by_direction" => CommonJsonSchema.stable_id_array_map(stable_id_pattern),
        "required_operator_action_counts" => CommonJsonSchema.non_negative_integer_count_map(),
        "direction_routing" => direction_routing_schema
      })
    end)
  end

  def contact_contention_resolution_source_report(source_report_schema, opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    direction_routing_schema = Keyword.fetch!(opts, :direction_routing_schema)

    update_in(source_report_schema, ["properties"], fn properties ->
      properties
      |> Map.merge(
        CommonJsonSchema.non_negative_integer_properties([
          "conflict_group_count",
          "recommendation_count",
          "review_recommendation_count",
          "deferred_contact_count"
        ])
      )
      |> Map.merge(
        count_map_properties([
          "resolution_status_counts",
          "selection_reason_counts",
          "resource_scope_counts",
          "direction_counts",
          "required_operator_action_counts"
        ])
      )
      |> Map.merge(
        stable_id_array_properties(stable_id_pattern, [
          "recommendation_group_ids",
          "review_group_ids",
          "ambiguous_group_ids",
          "ambiguous_duplicate_contact_ids",
          "selected_contact_ids",
          "deferred_contact_ids",
          "review_contact_ids"
        ])
      )
      |> Map.merge(
        stable_id_array_map_properties(stable_id_pattern, [
          "ambiguous_duplicate_contact_ids_by_group_id",
          "selected_contact_ids_by_group_id",
          "deferred_contact_ids_by_group_id",
          "review_contact_ids_by_group_id",
          "selected_contact_ids_by_selection_reason",
          "selected_contact_ids_by_ground_station",
          "deferred_contact_ids_by_ground_station",
          "selected_contact_ids_by_resource_scope",
          "deferred_contact_ids_by_resource_scope",
          "review_contact_ids_by_resource_scope",
          "contact_ids_by_direction",
          "review_contact_ids_by_action"
        ])
      )
      |> Map.put("direction_routing", direction_routing_schema)
    end)
  end

  def contact_contention_direction_routing(opts) do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> contact_direction_routing()
  end

  def contact_contention_resolution_direction_routing(opts) do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> contact_direction_routing()
  end

  def candidate_rejection_source_report(source_report_schema, _opts) do
    update_in(source_report_schema, ["properties"], fn properties ->
      properties
      |> Map.merge(
        CommonJsonSchema.non_negative_integer_properties([
          "rejected_count",
          "reviewable_count",
          "invalid_candidate_input_count"
        ])
      )
      |> Map.merge(
        count_map_properties([
          "rejection_reason_counts",
          "required_operator_action_counts"
        ])
      )
      |> Map.merge(candidate_rejection_context_properties())
    end)
  end

  def constraint_source_report(source_report_schema, _opts) do
    update_in(source_report_schema, ["properties"], fn properties ->
      properties
      |> Map.merge(
        CommonJsonSchema.non_negative_integer_properties([
          "downlink_gap_row_count",
          "resource_margin_row_count"
        ])
      )
      |> Map.merge(
        count_map_properties([
          "status_counts",
          "ground_station_counts",
          "constraint_id_counts",
          "source_activity_id_counts"
        ])
      )
      |> Map.merge(constraint_context_properties())
    end)
  end

  def link_capacity_source_report(source_report_schema, opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    direction_routing_schema = Keyword.fetch!(opts, :direction_routing_schema)

    update_in(source_report_schema, ["properties"], fn properties ->
      properties
      |> Map.merge(
        CommonJsonSchema.non_negative_integer_properties([
          "selected_shortfall_row_count",
          "actual_shortfall_row_count",
          "actual_throughput_row_count",
          "capacity_adjusted_throughput_row_count"
        ])
      )
      |> Map.merge(
        CommonJsonSchema.number_properties([
          "capacity_adjusted_throughput_mb_total",
          "selected_capacity_adjusted_throughput_mb_total",
          "unused_capacity_adjusted_throughput_mb_total"
        ])
      )
      |> Map.merge(
        count_map_properties([
          "ground_station_counts",
          "spacecraft_counts",
          "direction_counts",
          "selected_contact_id_counts",
          "actual_throughput_contact_id_counts",
          "downlink_requirement_status_counts"
        ])
      )
      |> Map.merge(
        numeric_map_properties([
          "capacity_adjusted_throughput_mb_by_ground_station",
          "selected_capacity_adjusted_throughput_mb_by_ground_station",
          "unused_capacity_adjusted_throughput_mb_by_ground_station",
          "capacity_adjusted_throughput_mb_by_direction",
          "selected_capacity_adjusted_throughput_mb_by_direction",
          "unused_capacity_adjusted_throughput_mb_by_direction"
        ])
      )
      |> Map.merge(
        stable_id_array_properties(stable_id_pattern, [
          "selected_contact_ids",
          "selected_source_window_ids",
          "selected_station_calendar_entry_ids",
          "selected_station_calendar_provider_entry_ids",
          "actual_throughput_contact_ids",
          "actual_throughput_source_window_ids",
          "actual_throughput_station_calendar_entry_ids",
          "actual_throughput_station_calendar_provider_entry_ids"
        ])
      )
      |> Map.merge(
        stable_id_array_map_properties(stable_id_pattern, [
          "contact_ids_by_direction",
          "source_window_ids_by_direction",
          "station_calendar_entry_ids_by_direction",
          "station_calendar_provider_entry_ids_by_direction",
          "contact_ids_by_ground_station",
          "source_window_ids_by_ground_station",
          "station_calendar_entry_ids_by_ground_station",
          "station_calendar_provider_entry_ids_by_ground_station",
          "contact_ids_by_spacecraft",
          "source_window_ids_by_spacecraft",
          "station_calendar_entry_ids_by_spacecraft",
          "station_calendar_provider_entry_ids_by_spacecraft",
          "contact_ids_by_requirement_status",
          "source_window_ids_by_requirement_status",
          "station_calendar_entry_ids_by_requirement_status",
          "station_calendar_provider_entry_ids_by_requirement_status"
        ])
      )
      |> Map.merge(%{
        "directions" => string_array_schema(),
        "direction_routing" => direction_routing_schema
      })
    end)
  end

  def link_capacity_direction_routing(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => %{
        "type" => "object",
        "additionalProperties" => true,
        "properties" => %{
          "contact_count" => %{"type" => "integer", "minimum" => 0},
          "contact_ids" => stable_id_array_schema(stable_id_pattern),
          "source_window_ids" => stable_id_array_schema(stable_id_pattern),
          "station_calendar_entry_ids" => stable_id_array_schema(stable_id_pattern),
          "station_calendar_provider_entry_ids" => stable_id_array_schema(stable_id_pattern),
          "capacity_adjusted_throughput_mb" => %{"type" => "number"},
          "selected_capacity_adjusted_throughput_mb" => %{"type" => "number"},
          "unused_capacity_adjusted_throughput_mb" => %{"type" => "number"}
        }
      }
    }
  end

  def contact_filter_source_report(source_report_schema, opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    direction_routing_schema = Keyword.fetch!(opts, :direction_routing_schema)

    update_in(source_report_schema, ["properties"], fn properties ->
      properties
      |> Map.merge(
        CommonJsonSchema.non_negative_integer_properties([
          "suppressed_candidate_count",
          "invalid_contact_input_count",
          "station_suppression_count"
        ])
      )
      |> Map.merge(
        count_map_properties([
          "suppressed_reason_counts",
          "direction_counts",
          "station_suppression_ground_station_counts",
          "station_suppression_availability_counts",
          "station_suppression_status_counts"
        ])
      )
      |> Map.merge(stable_id_array_properties(stable_id_pattern, ["invalid_contact_input_ids"]))
      |> Map.merge(
        stable_id_array_map_properties(stable_id_pattern, [
          "contact_ids_by_suppressed_reason",
          "contact_ids_by_direction",
          "station_suppression_contact_ids_by_ground_station",
          "station_suppression_contact_ids_by_availability",
          "station_suppression_contact_ids_by_status",
          "station_suppression_station_calendar_entry_ids_by_ground_station",
          "station_suppression_station_calendar_entry_ids_by_availability",
          "station_suppression_station_calendar_entry_ids_by_status",
          "station_suppression_station_calendar_provider_entry_ids_by_ground_station",
          "station_suppression_station_calendar_provider_entry_ids_by_availability",
          "station_suppression_station_calendar_provider_entry_ids_by_status",
          "station_suppression_station_reservation_ids_by_ground_station",
          "station_suppression_station_reservation_ids_by_availability",
          "station_suppression_station_reservation_ids_by_status"
        ])
      )
      |> Map.merge(%{
        "directions" => string_array_schema(),
        "direction_routing" => direction_routing_schema
      })
    end)
  end

  def contact_filter_context_properties(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "invalid_contact_input_ids" => stable_id_array_schema(stable_id_pattern),
      "station_suppression_count" => %{"type" => "integer", "minimum" => 0},
      "station_suppression_ground_station_counts" =>
        CommonJsonSchema.non_negative_integer_count_map(),
      "station_suppression_availability_counts" =>
        CommonJsonSchema.non_negative_integer_count_map(),
      "station_suppression_status_counts" => CommonJsonSchema.non_negative_integer_count_map()
    }
  end

  def resource_filter_context_properties(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "resource_filter_spacecraft_counts" => CommonJsonSchema.non_negative_integer_count_map(),
      "resource_filter_resource_counts" => CommonJsonSchema.non_negative_integer_count_map(),
      "resource_filter_blocking_dimension_counts" =>
        CommonJsonSchema.non_negative_integer_count_map(),
      "invalid_resource_summary_input_ids" => stable_id_array_schema(stable_id_pattern)
    }
  end

  def contact_contention_context_properties do
    count_map_properties([
      "contact_contention_ground_station_counts",
      "contact_contention_contact_id_counts"
    ])
  end

  def candidate_rejection_context_properties do
    count_map_properties([
      "candidate_rejection_candidate_id_counts",
      "candidate_rejection_ground_station_counts"
    ])
  end

  def station_pressure_context_properties do
    %{
      "station_pressure_contact_count" => %{"type" => "integer", "minimum" => 0}
    }
    |> Map.merge(
      count_map_properties([
        "station_pressure_ground_station_counts",
        "station_pressure_availability_counts",
        "station_pressure_precedence_availability_counts",
        "station_pressure_precedence_rank_counts"
      ])
    )
  end

  def link_capacity_context_properties do
    count_map_properties([
      "ground_station_counts",
      "target_counts",
      "collection_counts",
      "selected_contact_id_counts",
      "actual_throughput_contact_id_counts"
    ])
  end

  def constraint_context_properties do
    count_map_properties([
      "constraint_metric_counts",
      "constraint_resource_counts",
      "constraint_spacecraft_counts"
    ])
  end

  def timeline_activity_context_properties do
    %{
      "invalid_activity_input_count" => %{"type" => "integer", "minimum" => 0},
      "invalid_activity_input_reason_counts" => CommonJsonSchema.non_negative_integer_count_map(),
      "invalid_activity_input_reasons" => string_array_schema()
    }
  end

  def timeline_activity_state_source_report(source_report_schema, opts) do
    action_routing_schema = Keyword.fetch!(opts, :action_routing_schema)

    update_in(source_report_schema, ["properties"], fn properties ->
      properties
      |> Map.merge(
        CommonJsonSchema.non_negative_integer_properties([
          "review_required_count",
          "invalid_activity_input_count"
        ])
      )
      |> Map.merge(
        count_map_properties([
          "invalid_activity_input_reason_counts",
          "state_status_counts",
          "transition_decision_counts",
          "planned_status_category_counts",
          "realized_status_category_counts",
          "planned_approval_category_counts",
          "realized_approval_category_counts",
          "status_transition_category_counts",
          "approval_transition_category_counts",
          "required_operator_action_counts",
          "import_action_counts",
          "activity_id_counts",
          "timeline_id_counts",
          "review_activity_id_counts"
        ])
      )
      |> Map.merge(%{
        "invalid_activity_input_reasons" => string_array_schema(),
        "action_routing" => action_routing_schema
      })
    end)
  end

  def timeline_integrity_context_properties do
    CommonJsonSchema.non_negative_integer_properties([
      "timeline_integrity_issue_count",
      "timeline_integrity_review_count",
      "dependency_issue_count",
      "exclusivity_issue_count"
    ])
    |> Map.merge(
      count_map_properties([
        "timeline_integrity_status_counts",
        "timeline_integrity_issue_type_counts",
        "required_operator_action_counts",
        "operator_action_reason_counts",
        "review_activity_id_counts",
        "review_timeline_id_counts",
        "missing_dependency_activity_id_counts",
        "missing_dependency_timeline_id_counts",
        "self_dependency_activity_id_counts",
        "self_dependency_timeline_id_counts",
        "dependency_cycle_activity_id_counts",
        "dependency_cycle_timeline_id_counts",
        "dependency_order_violation_activity_id_counts",
        "dependency_order_violation_timeline_id_counts",
        "exclusivity_violation_activity_id_counts",
        "exclusivity_violation_timeline_id_counts",
        "exclusivity_violation_group_counts"
      ])
    )
  end

  def timeline_integrity_source_report(source_report_schema, _opts) do
    update_in(source_report_schema, ["properties"], fn properties ->
      Map.merge(properties, timeline_integrity_context_properties())
    end)
  end

  def timeline_dependency_impact_context_properties do
    CommonJsonSchema.non_negative_integer_properties([
      "source_activity_count",
      "replacement_activity_count",
      "changed_source_activity_count",
      "changed_source_timeline_count",
      "dependent_activity_count",
      "source_dependent_activity_count",
      "replacement_dependent_activity_count"
    ])
    |> Map.merge(
      count_map_properties([
        "dependency_impact_status_counts",
        "dependency_impact_scope_counts",
        "required_operator_action_counts",
        "impacted_source_activity_id_counts",
        "impacted_source_timeline_id_counts",
        "impacted_dependency_activity_id_counts",
        "impacted_dependency_timeline_id_counts",
        "impacted_exclusive_activity_id_counts",
        "impacted_exclusive_timeline_id_counts",
        "dependent_activity_id_counts",
        "dependent_timeline_id_counts"
      ])
    )
  end

  def timeline_dependency_impact_source_report(source_report_schema, _opts) do
    update_in(source_report_schema, ["properties"], fn properties ->
      Map.merge(properties, timeline_dependency_impact_context_properties())
    end)
  end

  def timeline_publication_context_properties(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    count_map_properties([
      "publication_status_counts",
      "downstream_invalidation_status_counts",
      "downstream_invalidation_reason_counts",
      "dependency_impact_status_counts",
      "publication_authority_counts",
      "source_artifact_type_counts",
      "timeline_publication_source_artifact_type_counts",
      "changed_field_counts"
    ])
    |> Map.merge(
      stable_id_array_properties(stable_id_pattern, [
        "publication_ids",
        "source_artifact_ids",
        "supersedes_artifact_ids",
        "downstream_product_ids",
        "invalidated_downstream_product_ids",
        "impacted_source_activity_ids",
        "impacted_source_timeline_ids",
        "dependent_activity_ids",
        "dependent_timeline_ids",
        "source_dependent_activity_ids",
        "source_dependent_timeline_ids",
        "replacement_dependent_activity_ids",
        "replacement_dependent_timeline_ids",
        "impacted_dependency_activity_ids",
        "impacted_dependency_timeline_ids",
        "impacted_exclusive_with_activity_ids",
        "impacted_exclusive_with_timeline_ids",
        "changed_timeline_ids",
        "review_timeline_ids"
      ])
    )
    |> Map.merge(
      stable_id_array_map_properties(stable_id_pattern, [
        "invalidated_downstream_product_ids_by_reason",
        "timeline_ids_by_changed_field"
      ])
    )
    |> Map.merge(
      CommonJsonSchema.non_negative_integer_properties([
        "dependency_impact_row_count",
        "timeline_diff_row_count",
        "timeline_diff_changed_count",
        "timeline_diff_review_required_count"
      ])
    )
  end

  def timeline_publication_source_report(source_report_schema, opts) do
    update_in(source_report_schema, ["properties"], fn properties ->
      Map.merge(properties, timeline_publication_context_properties(opts))
    end)
  end

  def timeline_transition_application_source_report(source_report_schema, _opts) do
    update_in(source_report_schema, ["properties"], fn properties ->
      properties
      |> Map.merge(
        CommonJsonSchema.non_negative_integer_properties([
          "application_count",
          "selected_activity_count",
          "selected_timeline_integrity_review_count",
          "selected_timeline_integrity_issue_count",
          "review_required_count",
          "preserved_source_count",
          "recorded_replacement_count",
          "withheld_review_count",
          "duplicate_timeline_identity_count",
          "duplicate_source_timeline_identity_count",
          "duplicate_replacement_timeline_identity_count"
        ])
      )
      |> Map.merge(
        count_map_properties([
          "selected_activity_id_counts",
          "review_activity_id_counts",
          "selected_timeline_integrity_issue_type_counts",
          "application_status_counts",
          "transition_decision_counts",
          "required_operator_action_counts",
          "duplicate_timeline_identity_scope_counts"
        ])
      )
    end)
  end

  def timeline_activity_precondition_context_properties do
    CommonJsonSchema.non_negative_integer_properties([
      "blocked_precondition_count",
      "review_precondition_count",
      "invalid_activity_input_count"
    ])
    |> Map.merge(
      count_map_properties([
        "source_summary_model_counts",
        "source_summary_schema_contract_counts",
        "precondition_status_counts",
        "blocked_precondition_type_counts",
        "review_precondition_type_counts",
        "invalid_activity_input_reason_counts",
        "activity_id_counts",
        "timeline_id_counts",
        "dependency_activity_id_counts",
        "dependency_timeline_id_counts",
        "exclusive_with_activity_id_counts",
        "exclusive_with_timeline_id_counts",
        "duplicate_dependency_activity_id_counts",
        "duplicate_dependency_timeline_id_counts",
        "duplicate_exclusivity_activity_id_counts",
        "duplicate_exclusivity_timeline_id_counts",
        "allow_overlap_counts"
      ])
    )
    |> Map.merge(%{
      "invalid_activity_input_reasons" => string_array_schema()
    })
  end

  def timeline_activity_precondition_source_report(source_report_schema, _opts) do
    update_in(source_report_schema, ["properties"], fn properties ->
      Map.merge(properties, timeline_activity_precondition_context_properties())
    end)
  end

  def timeline_activity_lifecycle_context_properties(opts) do
    action_routing_schema = Keyword.fetch!(opts, :action_routing_schema)

    CommonJsonSchema.non_negative_integer_properties([
      "review_required_count",
      "transition_application_provenance_count"
    ])
    |> Map.merge(
      count_map_properties([
        "source_summary_model_counts",
        "source_summary_schema_contract_counts",
        "transition_decision_counts",
        "status_transition_decision_counts",
        "approval_transition_decision_counts",
        "required_operator_action_counts",
        "import_action_counts",
        "planned_status_category_counts",
        "realized_status_category_counts",
        "planned_approval_category_counts",
        "realized_approval_category_counts",
        "status_transition_category_counts",
        "approval_transition_category_counts",
        "transition_application_provenance_helper_counts",
        "transition_application_provenance_category_counts",
        "transition_application_provenance_operator_action_reason_counts",
        "protection_decision_counts",
        "protection_category_counts",
        "activity_id_counts",
        "timeline_id_counts",
        "review_activity_id_counts"
      ])
    )
    |> Map.merge(%{
      "action_routing" => action_routing_schema
    })
  end

  def timeline_activity_lifecycle_source_report(source_report_schema, opts) do
    update_in(source_report_schema, ["properties"], fn properties ->
      properties
      |> Map.merge(timeline_activity_context_properties())
      |> Map.merge(timeline_activity_lifecycle_context_properties(opts))
    end)
  end

  def timeline_lifecycle_state_context_properties(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    review_routing_schema = Keyword.fetch!(opts, :review_routing_schema)

    CommonJsonSchema.non_negative_integer_properties([
      "planned_activity_count",
      "realized_activity_count",
      "recordable_count",
      "preserved_count",
      "review_required_count",
      "duplicate_timeline_identity_count",
      "invalid_activity_input_count",
      "transition_application_provenance_count"
    ])
    |> Map.merge(
      count_map_properties([
        "source_summary_model_counts",
        "source_summary_schema_contract_counts",
        "transition_decision_counts",
        "required_operator_action_counts",
        "import_action_counts",
        "planned_status_category_counts",
        "realized_status_category_counts",
        "planned_approval_category_counts",
        "realized_approval_category_counts",
        "status_transition_category_counts",
        "approval_transition_category_counts",
        "transition_application_provenance_helper_counts",
        "transition_application_provenance_category_counts",
        "transition_application_provenance_operator_action_reason_counts"
      ])
    )
    |> Map.merge(
      stable_id_array_properties(stable_id_pattern, [
        "recordable_timeline_ids",
        "preserved_timeline_ids",
        "review_timeline_ids",
        "review_activity_ids",
        "invalid_activity_input_ids"
      ])
    )
    |> Map.merge(
      stable_id_array_map_properties(stable_id_pattern, [
        "review_timeline_ids_by_required_operator_action",
        "review_timeline_ids_by_status_transition_category",
        "review_timeline_ids_by_approval_transition_category"
      ])
    )
    |> Map.merge(%{
      "review_routing" => review_routing_schema
    })
  end

  def timeline_lifecycle_state_source_report(source_report_schema, opts) do
    update_in(source_report_schema, ["properties"], fn properties ->
      Map.merge(properties, timeline_lifecycle_state_context_properties(opts))
    end)
  end

  def resource_filter_source_report(source_report_schema, opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    direction_routing_schema = Keyword.fetch!(opts, :direction_routing_schema)

    update_in(source_report_schema, ["properties"], fn properties ->
      properties
      |> Map.merge(
        CommonJsonSchema.non_negative_integer_properties([
          "suppressed_candidate_count",
          "invalid_resource_summary_input_count"
        ])
      )
      |> Map.merge(
        count_map_properties([
          "suppressed_reason_counts",
          "resource_filter_spacecraft_counts",
          "resource_filter_resource_counts",
          "resource_filter_blocking_dimension_counts",
          "direction_counts"
        ])
      )
      |> Map.merge(
        stable_id_array_properties(stable_id_pattern, ["invalid_resource_summary_input_ids"])
      )
      |> Map.merge(
        stable_id_array_map_properties(stable_id_pattern, [
          "candidate_ids_by_suppressed_reason",
          "candidate_ids_by_spacecraft",
          "candidate_ids_by_resource",
          "candidate_ids_by_blocking_dimension",
          "candidate_ids_by_direction"
        ])
      )
      |> Map.merge(%{
        "directions" => string_array_schema(),
        "direction_routing" => direction_routing_schema
      })
    end)
  end

  def contact_filter_direction_routing(opts) do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> contact_direction_routing()
  end

  def resource_filter_direction_routing(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => %{
        "type" => "object",
        "additionalProperties" => true,
        "properties" => %{
          "candidate_count" => %{"type" => "integer", "minimum" => 0},
          "candidate_ids" => stable_id_array_schema(stable_id_pattern)
        }
      }
    }
  end

  def resource_projection_source_report(source_report_schema, opts) do
    update_in(source_report_schema, ["properties"], fn properties ->
      Map.merge(properties, resource_projection_context_properties(opts))
    end)
  end

  def resource_projection_context_properties(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "projected_resource_count" => %{"type" => "integer", "minimum" => 0},
      "invalid_resource_summary_input_count" => %{"type" => "integer", "minimum" => 0},
      "invalid_activity_input_ids" => stable_id_array_schema(stable_id_pattern),
      "invalid_resource_summary_input_ids" => stable_id_array_schema(stable_id_pattern),
      "resource_pressure_status_counts" => CommonJsonSchema.non_negative_integer_count_map(),
      "resource_projection_spacecraft_counts" =>
        CommonJsonSchema.non_negative_integer_count_map(),
      "resource_pressure_type_counts" => CommonJsonSchema.non_negative_integer_count_map(),
      "resource_pressure_activity_id_counts" => CommonJsonSchema.non_negative_integer_count_map(),
      "resource_pressure_activity_ids_by_status" =>
        CommonJsonSchema.stable_id_array_map(stable_id_pattern),
      "resource_pressure_activity_ids_by_type" =>
        CommonJsonSchema.stable_id_array_map(stable_id_pattern),
      "resource_pressure_activity_ids_by_ground_station" =>
        CommonJsonSchema.stable_id_array_map(stable_id_pattern),
      "resource_pressure_activity_ids_by_spacecraft" =>
        CommonJsonSchema.stable_id_array_map(stable_id_pattern),
      "resource_pressure_direction_counts" => CommonJsonSchema.non_negative_integer_count_map(),
      "resource_pressure_directions" => string_array_schema(),
      "resource_pressure_activity_ids_by_direction" =>
        CommonJsonSchema.stable_id_array_map(stable_id_pattern),
      "resource_pressure_direction_routing" => resource_projection_direction_routing(opts),
      "resource_pressure_ground_station_ids_by_type" =>
        CommonJsonSchema.stable_id_array_map(stable_id_pattern),
      "resource_pressure_source_window_ids_by_status" =>
        CommonJsonSchema.stable_id_array_map(stable_id_pattern),
      "resource_pressure_source_window_ids_by_type" =>
        CommonJsonSchema.stable_id_array_map(stable_id_pattern),
      "resource_pressure_station_calendar_entry_ids_by_status" =>
        CommonJsonSchema.stable_id_array_map(stable_id_pattern),
      "resource_pressure_station_calendar_entry_ids_by_type" =>
        CommonJsonSchema.stable_id_array_map(stable_id_pattern),
      "resource_pressure_station_calendar_provider_ids_by_status" =>
        CommonJsonSchema.stable_id_array_map(stable_id_pattern),
      "resource_pressure_station_calendar_provider_ids_by_type" =>
        CommonJsonSchema.stable_id_array_map(stable_id_pattern),
      "resource_pressure_station_calendar_provider_entry_ids_by_status" =>
        CommonJsonSchema.stable_id_array_map(stable_id_pattern),
      "resource_pressure_station_calendar_provider_entry_ids_by_type" =>
        CommonJsonSchema.stable_id_array_map(stable_id_pattern),
      "source_artifact_type_counts" => CommonJsonSchema.non_negative_integer_count_map(),
      "source_flow_summary_model_counts" => CommonJsonSchema.non_negative_integer_count_map()
    }
  end

  def resource_projection_direction_routing(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => %{
        "type" => "object",
        "additionalProperties" => true,
        "properties" => %{
          "pressure_count" => %{"type" => "integer", "minimum" => 0},
          "activity_ids" => stable_id_array_schema(stable_id_pattern)
        }
      }
    }
  end

  def command_window_source_report(source_report_schema, opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    direction_routing_schema = Keyword.fetch!(opts, :direction_routing_schema)

    update_in(source_report_schema, ["properties"], fn properties ->
      properties
      |> Map.merge(CommonJsonSchema.non_negative_integer_properties(["command_feedback_count"]))
      |> Map.merge(count_map_properties(["direction_counts", "required_operator_action_counts"]))
      |> Map.merge(
        stable_id_array_map_properties(stable_id_pattern, [
          "activity_ids_by_direction",
          "window_ids_by_direction"
        ])
      )
      |> Map.merge(%{
        "input_keys" => string_array_schema(),
        "direction_routing" => direction_routing_schema
      })
    end)
  end

  def command_window_direction_routing(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => %{
        "type" => "object",
        "additionalProperties" => true,
        "properties" => %{
          "activity_count" => %{"type" => "integer", "minimum" => 0},
          "activity_ids" => stable_id_array_schema(stable_id_pattern),
          "window_ids" => stable_id_array_schema(stable_id_pattern)
        }
      }
    }
  end

  def timeline_feedback_source_report(source_report_schema, _opts) do
    update_in(source_report_schema, ["properties"], fn properties ->
      properties
      |> Map.merge(%{"input_keys" => string_array_schema()})
      |> Map.merge(
        count_map_properties([
          "status_counts",
          "feedback_kind_counts",
          "match_strategy_counts",
          "activity_id_counts",
          "cadence_import_status_counts"
        ])
      )
    end)
  end

  def timeline_diff_source_report(source_report_schema, _opts) do
    update_in(source_report_schema, ["properties"], fn properties ->
      properties
      |> Map.merge(
        CommonJsonSchema.non_negative_integer_properties([
          "duplicate_timeline_identity_count",
          "duplicate_source_timeline_identity_count",
          "duplicate_replacement_timeline_identity_count",
          "removed_downlink_count",
          "removed_observation_count",
          "changed_downlink_shortfall_count",
          "changed_contact_feedback_count",
          "changed_observation_count",
          "changed_observation_quality_feedback_count",
          "changed_command_feedback_count",
          "changed_maneuver_feedback_count"
        ])
      )
      |> Map.merge(
        count_map_properties([
          "diff_status_counts",
          "required_operator_action_counts",
          "duplicate_timeline_identity_scope_counts",
          "source_activity_id_counts",
          "replacement_activity_id_counts"
        ])
      )
    end)
  end

  def operational_timeline_source_report(source_report_schema, _opts) do
    update_in(source_report_schema, ["properties"], fn properties ->
      properties
      |> Map.merge(%{"input_keys" => string_array_schema()})
      |> Map.merge(
        CommonJsonSchema.non_negative_integer_properties([
          "contact_feedback_count",
          "command_feedback_count",
          "maneuver_feedback_count",
          "observation_feedback_count",
          "station_throughput_feedback_count",
          "timeline_integrity_issue_count",
          "dependency_integrity_issue_count",
          "exclusivity_integrity_issue_count"
        ])
      )
      |> Map.merge(
        count_map_properties([
          "operational_kind_counts",
          "activity_id_counts",
          "activity_status_counts",
          "approval_status_counts",
          "required_operator_action_counts",
          "cadence_import_status_counts",
          "timeline_integrity_issue_type_counts"
        ])
      )
    end)
  end

  def operational_readiness_source_report(source_report_schema, opts) do
    update_in(source_report_schema, ["properties"], fn properties ->
      properties
      |> Map.merge(
        OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema.resource_context_properties(
          opts
        )
      )
      |> Map.merge(
        OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema.adapter_boundary_context_properties()
      )
      |> Map.merge(
        OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema.cadence_import_context_properties()
      )
      |> Map.merge(
        CommonJsonSchema.non_negative_integer_properties([
          "gate_count",
          "passed_gate_count",
          "review_gate_count",
          "analysis_gate_count",
          "blocked_gate_count",
          "review_required_count",
          "source_model_limit_count"
        ])
      )
      |> Map.merge(
        count_map_properties([
          "readiness_level_counts",
          "import_classification_counts",
          "status_counts",
          "review_type_counts",
          "import_action_counts",
          "source_review_type_counts"
        ])
      )
    end)
  end

  def quality_gate_source_report(source_report_schema, opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    update_in(source_report_schema, ["properties"], fn properties ->
      properties
      |> Map.merge(
        OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema.resource_context_properties(
          opts
        )
      )
      |> Map.merge(
        OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema.adapter_boundary_context_properties()
      )
      |> Map.merge(
        OrbitalDynamics.Schema.OperationalReadinessContextJsonSchema.cadence_import_context_properties()
      )
      |> Map.merge(
        CommonJsonSchema.non_negative_integer_properties([
          "gate_count",
          "passed_gate_count",
          "review_gate_count",
          "analysis_gate_count",
          "blocked_gate_count",
          "non_passed_gate_count",
          "source_readiness_report_count"
        ])
      )
      |> Map.merge(
        count_map_properties([
          "readiness_level_counts",
          "import_classification_counts",
          "status_counts",
          "gate_status_counts",
          "gate_classification_counts"
        ])
      )
      |> Map.merge(
        stable_id_array_map_properties(stable_id_pattern, [
          "quality_gate_row_ids_by_status",
          "quality_gate_ids_by_status",
          "quality_gate_row_ids_by_classification",
          "quality_gate_ids_by_classification"
        ])
      )
      |> Map.merge(
        stable_id_array_properties(stable_id_pattern, [
          "passed_gate_ids",
          "review_required_gate_ids",
          "analysis_only_gate_ids",
          "blocked_gate_ids",
          "non_passed_gate_ids",
          "non_passed_quality_gate_row_ids",
          "review_required_quality_gate_row_ids",
          "blocked_quality_gate_row_ids",
          "ready_quality_gate_row_ids",
          "analysis_only_quality_gate_row_ids",
          "stale_or_unknown_freshness_quality_gate_row_ids",
          "import_preparation_quality_gate_row_ids",
          "blocked_import_quality_gate_row_ids",
          "import_readiness_gate_ids"
        ])
      )
      |> Map.merge(
        CommonJsonSchema.string_array_properties([
          "freshness_status_ids",
          "import_status_ids",
          "cadence_import_status_ids",
          "schema_validation_status_ids"
        ])
      )
    end)
  end

  def maneuver_review_source_report(source_report_schema, _opts) do
    update_in(source_report_schema, ["properties"], fn properties ->
      properties
      |> Map.merge(
        CommonJsonSchema.non_negative_integer_properties([
          "maneuver_success_feedback_count",
          "execution_uncertainty_declared_count",
          "execution_uncertainty_missing_count"
        ])
      )
      |> Map.merge(
        count_map_properties(["maneuver_id_counts", "required_operator_action_counts"])
      )
      |> Map.merge(%{"input_keys" => string_array_schema()})
    end)
  end

  def provider_counteroffer_source_report(source_report_schema, opts) do
    provider_counteroffer_actions = Keyword.fetch!(opts, :provider_counteroffer_actions)

    update_in(source_report_schema, ["properties"], fn properties ->
      properties
      |> Map.merge(
        CommonJsonSchema.non_negative_integer_properties([
          "reviewable_count",
          "counteroffer_cost_delta_count",
          "counteroffer_timing_shift_count",
          "counteroffer_start_delta_count",
          "counteroffer_end_delta_count",
          "counteroffer_duration_delta_count",
          "counteroffer_lock_deadline_count"
        ])
      )
      |> Map.merge(
        CommonJsonSchema.number_properties([
          "counteroffer_cost_delta_total",
          "earliest_counteroffer_lock_deadline_s"
        ])
      )
      |> Map.merge(%{
        "counteroffer_status_counts" => CommonJsonSchema.non_negative_integer_count_map(),
        "required_operator_action_counts" =>
          CommonJsonSchema.enum_count_map(provider_counteroffer_actions)
      })
    end)
  end

  def schema_validation_source_report(source_report_schema, _opts) do
    update_in(source_report_schema, ["properties"], fn properties ->
      properties
      |> Map.merge(
        CommonJsonSchema.non_negative_integer_properties([
          "error_count",
          "warning_count",
          "remediation_count"
        ])
      )
      |> Map.merge(
        count_map_properties([
          "status_counts",
          "validated_contract_counts",
          "validation_mode_counts",
          "remediation_action_counts",
          "remediation_category_counts",
          "remediation_path_counts"
        ])
      )
    end)
  end

  def model_acceptance_source_report(source_report_schema, _opts) do
    update_in(source_report_schema, ["properties"], fn properties ->
      properties
      |> Map.merge(
        CommonJsonSchema.non_negative_integer_properties([
          "record_count",
          "model_count",
          "accepted_count",
          "review_required_count",
          "blocked_count",
          "unknown_model_count"
        ])
      )
      |> Map.merge(
        count_map_properties([
          "intended_use_counts",
          "status_counts",
          "validation_level_counts"
        ])
      )
      |> Map.merge(model_acceptance_context_properties())
    end)
  end

  def model_acceptance_context_properties do
    %{
      "model_ids_by_status" => CommonJsonSchema.string_list_map(),
      "model_ids_by_validation_level" => CommonJsonSchema.string_list_map(),
      "model_ids_by_intended_use" => CommonJsonSchema.string_list_map()
    }
  end

  def passive_replay_source_report(source_report_schema, opts) do
    update_in(source_report_schema, ["properties"], fn properties ->
      Map.merge(properties, passive_replay_context_properties(opts))
    end)
  end

  def passive_replay_context_properties(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "status_counts" => CommonJsonSchema.non_negative_integer_count_map(),
      "stale_reason_count" => %{"type" => "integer", "minimum" => 0},
      "stale_reasons" => string_array_schema(),
      "stale_reason_counts" => CommonJsonSchema.non_negative_integer_count_map(),
      "unknown_reason_count" => %{"type" => "integer", "minimum" => 0},
      "unknown_reasons" => string_array_schema(),
      "unknown_reason_counts" => CommonJsonSchema.non_negative_integer_count_map(),
      "input_candidate_count" => %{"type" => "integer", "minimum" => 0},
      "kept_candidate_count" => %{"type" => "integer", "minimum" => 0},
      "dropped_candidate_count" => %{"type" => "integer", "minimum" => 0},
      "invalid_candidate_limit_policy_count" => %{"type" => "integer", "minimum" => 0},
      "invalid_candidate_limit_policy_reason_counts" =>
        CommonJsonSchema.non_negative_integer_count_map(),
      "kept_candidate_ids" => stable_id_array_schema(stable_id_pattern),
      "dropped_candidate_ids" => stable_id_array_schema(stable_id_pattern),
      "validated_contract_counts" => CommonJsonSchema.non_negative_integer_count_map(),
      "validation_mode_counts" => CommonJsonSchema.non_negative_integer_count_map(),
      "error_count" => %{"type" => "integer", "minimum" => 0},
      "warning_count" => %{"type" => "integer", "minimum" => 0},
      "remediation_count" => %{"type" => "integer", "minimum" => 0},
      "remediation_action_counts" => CommonJsonSchema.non_negative_integer_count_map(),
      "remediation_category_counts" => CommonJsonSchema.non_negative_integer_count_map(),
      "remediation_path_counts" => CommonJsonSchema.non_negative_integer_count_map()
    }
  end

  def objective_satisfaction_source_report(source_report_schema, _opts) do
    source_report_schema
    |> put_objective_gap_properties(["gap_row_count"])
    |> put_objective_count_maps(["objective_type_counts"])
  end

  def objective_tradeoff_source_report(source_report_schema, _opts) do
    put_objective_gap_properties(source_report_schema, [])
  end

  def score_term_source_report(source_report_schema, _opts) do
    source_report_schema
    |> put_objective_gap_properties([])
    |> put_objective_count_maps(["term_key_counts"])
  end

  def validation_safety_case_source_report(source_report_schema, opts) do
    safety_case_count_fields = Keyword.fetch!(opts, :safety_case_count_fields)

    update_in(source_report_schema, ["properties"], fn properties ->
      properties
      |> Map.merge(
        CommonJsonSchema.non_negative_integer_properties(
          [
            "accepted_evidence_count",
            "review_required_evidence_count",
            "blocked_evidence_count"
          ] ++ safety_case_count_fields
        )
      )
      |> Map.merge(
        count_map_properties(["status_counts", "evidence_status_counts", "input_contract_counts"])
      )
      |> Map.merge(%{
        "evidence_refs_by_status" => CommonJsonSchema.string_list_map(),
        "evidence_refs_by_contract" => CommonJsonSchema.string_list_map()
      })
    end)
  end

  def contact_intent_source_report(source_report_schema, opts) do
    update_in(source_report_schema, ["properties"], fn properties ->
      Map.merge(properties, contact_intent_context_properties(opts))
    end)
  end

  def contact_intent_context_properties(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "station_feedback_count" => %{"type" => "integer", "minimum" => 0},
      "station_calendar_status_counts" => CommonJsonSchema.non_negative_integer_count_map(),
      "cadence_import_status_counts" => CommonJsonSchema.non_negative_integer_count_map(),
      "policy_classification_counts" => CommonJsonSchema.non_negative_integer_count_map(),
      "capacity_pack_required_contact_count" => %{"type" => "integer", "minimum" => 0},
      "capacity_pack_required_capacity_fraction" => %{
        "type" => ["number", "null"],
        "minimum" => 0.0
      },
      "capacity_pack_required_capacity_fraction_by_ground_station" =>
        CommonJsonSchema.non_negative_number_map(),
      "capacity_pack_required_capacity_fraction_by_direction" =>
        CommonJsonSchema.non_negative_number_map(),
      "capacity_pack_required_capacity_fraction_by_direction_and_ground_station" =>
        CommonJsonSchema.nested_non_negative_number_map(),
      "required_capacity_fraction_source_counts" =>
        CommonJsonSchema.non_negative_integer_count_map(),
      "required_capacity_fraction_contact_ids_by_source" =>
        CommonJsonSchema.stable_id_array_map(stable_id_pattern),
      "capacity_pack_contact_ids_by_ground_station" =>
        CommonJsonSchema.stable_id_array_map(stable_id_pattern),
      "contact_ids_by_ground_station" => CommonJsonSchema.stable_id_array_map(stable_id_pattern),
      "capacity_pack_contact_ids_by_direction" =>
        CommonJsonSchema.stable_id_array_map(stable_id_pattern),
      "capacity_pack_contact_ids_by_direction_and_ground_station" =>
        CommonJsonSchema.nested_stable_id_array_map(stable_id_pattern),
      "contact_ids_by_direction_and_ground_station" =>
        CommonJsonSchema.nested_stable_id_array_map(stable_id_pattern),
      "directions" => string_array_schema(),
      "direction_counts" => CommonJsonSchema.non_negative_integer_count_map(),
      "contact_ids_by_direction" => CommonJsonSchema.stable_id_array_map(stable_id_pattern),
      "direction_routing" => contact_intent_direction_routing(opts)
    }
  end

  def contact_intent_direction_routing(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => %{
        "type" => "object",
        "additionalProperties" => true,
        "properties" => %{
          "contact_count" => %{"type" => "integer", "minimum" => 0},
          "contact_ids" => stable_id_array_schema(stable_id_pattern),
          "capacity_pack_required_capacity_fraction" => %{"type" => "number", "minimum" => 0.0},
          "capacity_pack_contact_ids" => stable_id_array_schema(stable_id_pattern),
          "ground_station_ids" => stable_id_array_schema(stable_id_pattern),
          "contact_ids_by_ground_station_id" =>
            CommonJsonSchema.stable_id_array_map(stable_id_pattern),
          "capacity_pack_required_capacity_fraction_by_ground_station_id" =>
            CommonJsonSchema.non_negative_number_map(),
          "capacity_pack_contact_ids_by_ground_station_id" =>
            CommonJsonSchema.stable_id_array_map(stable_id_pattern),
          "contact_ids_by_ground_station" =>
            CommonJsonSchema.stable_id_array_map(stable_id_pattern),
          "capacity_pack_required_capacity_fraction_by_ground_station" =>
            CommonJsonSchema.non_negative_number_map(),
          "capacity_pack_contact_ids_by_ground_station" =>
            CommonJsonSchema.stable_id_array_map(stable_id_pattern)
        }
      }
    }
  end

  def remaining_horizon_property("schema_contract", _opts) do
    %{"type" => "string", "const" => "remaining_horizon.v1"}
  end

  def remaining_horizon_property(field, _opts)
      when field in ["starts_at_s", "ends_at_s", "output_step_s"] do
    %{"type" => "number"}
  end

  def embedded_remaining_horizon do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["starts_at_s", "ends_at_s", "output_step_s"],
      "properties" => %{
        "schema_contract" => %{"type" => "string", "const" => "remaining_horizon.v1"},
        "starts_at_s" => %{"type" => "number"},
        "ends_at_s" => %{"type" => "number"},
        "output_step_s" => %{"type" => "number", "exclusiveMinimum" => 0},
        "duration_s" => %{"type" => "number", "minimum" => 0}
      }
    }
  end

  def accepted_planning_state_ref(stable_id_pattern) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["snapshot_id", "spacecraft_state_count"],
      "properties" => %{
        "snapshot_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "accepted_at" => %{"type" => "string"},
        "spacecraft_state_count" => %{"type" => "integer", "minimum" => 0},
        "maneuver_execution_delta_count" => %{"type" => "integer", "minimum" => 0}
      }
    }
  end

  defp stable_id_array_schema(stable_id_pattern) do
    %{"type" => "array", "items" => %{"type" => "string", "pattern" => stable_id_pattern}}
  end

  defp count_map_properties(fields) do
    Map.new(fields, &{&1, CommonJsonSchema.non_negative_integer_count_map()})
  end

  defp numeric_map_properties(fields) do
    Map.new(fields, &{&1, CommonJsonSchema.numeric_map()})
  end

  defp stable_id_array_properties(stable_id_pattern, fields) do
    Map.new(fields, &{&1, CommonJsonSchema.stable_id_array(stable_id_pattern)})
  end

  defp stable_id_array_map_properties(stable_id_pattern, fields) do
    Map.new(fields, &{&1, CommonJsonSchema.stable_id_array_map(stable_id_pattern)})
  end

  defp contact_direction_routing(stable_id_pattern) do
    %{
      "type" => "object",
      "additionalProperties" => %{
        "type" => "object",
        "additionalProperties" => true,
        "properties" => %{
          "contact_count" => %{"type" => "integer", "minimum" => 0},
          "contact_ids" => stable_id_array_schema(stable_id_pattern)
        }
      }
    }
  end

  defp put_objective_gap_properties(source_report_schema, extra_count_fields) do
    update_in(source_report_schema, ["properties"], fn properties ->
      properties
      |> Map.merge(
        CommonJsonSchema.non_negative_integer_properties(
          extra_count_fields ++
            [
              "downlink_gap_row_count",
              "target_gap_row_count",
              "collection_latency_gap_row_count"
            ]
        )
      )
      |> Map.merge(objective_source_count_maps())
    end)
  end

  defp put_objective_count_maps(source_report_schema, fields) do
    update_in(source_report_schema, ["properties"], fn properties ->
      Map.merge(properties, count_map_properties(fields))
    end)
  end

  defp objective_source_count_maps do
    count_map_properties([
      "ground_station_counts",
      "target_counts",
      "collection_counts",
      "source_activity_id_counts"
    ])
  end

  defp non_negative_integer do
    %{"type" => "integer", "minimum" => 0}
  end

  defp string_array_schema do
    %{"type" => "array", "items" => %{"type" => "string"}}
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
