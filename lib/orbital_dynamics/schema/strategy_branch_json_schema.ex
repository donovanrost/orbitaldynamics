defmodule OrbitalDynamics.Schema.StrategyBranchJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @object_fields [
    "candidate_plan",
    "derived_source",
    "label",
    "repair_result",
    "resource_impacts",
    "resource_projection_report"
  ]

  @approval_status_values [
    "auto_approvable",
    "operator_review_required",
    "blocked_by_policy"
  ]

  @property_fields [
    "schema_contract",
    "branch_id",
    "probability",
    "score",
    "events",
    "warnings",
    "risk_indicators",
    "approval_requirements",
    "tradeoffs",
    "score_terms",
    "policy_decision",
    "approval_status"
    | @object_fields
  ]

  def property_field?(field) when field in @property_fields, do: true
  def property_field?(_field), do: false

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property_from_context(
        field,
        stable_id_pattern,
        event_schema,
        risk_schema,
        approval_requirement_schema,
        numeric_map_schema,
        policy_decision_schema
      ) do
    deps = [
      stable_id_pattern: stable_id_pattern,
      event_schema: event_schema,
      risk_schema: risk_schema,
      approval_requirement_schema: approval_requirement_schema,
      numeric_map_schema: numeric_map_schema,
      policy_decision_schema: policy_decision_schema
    ]

    property_from_context(field, deps)
  end

  def property_fun_from_context(deps) when is_list(deps) do
    fn field ->
      property_from_context(field, deps)
    end
  end

  def property_fun_from_context(
        stable_id_pattern,
        event_schema,
        risk_schema,
        approval_requirement_schema,
        numeric_map_schema,
        policy_decision_schema
      ) do
    deps = [
      stable_id_pattern: stable_id_pattern,
      event_schema: event_schema,
      risk_schema: risk_schema,
      approval_requirement_schema: approval_requirement_schema,
      numeric_map_schema: numeric_map_schema,
      policy_decision_schema: policy_decision_schema
    ]

    fn field ->
      property_from_context(field, deps)
    end
  end

  def property_opts("branch_id", deps) do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts("events", deps) do
    [event_schema: fetch_dep!(deps, :event_schema)]
  end

  def property_opts("risk_indicators", deps) do
    [risk_schema: fetch_dep!(deps, :risk_schema)]
  end

  def property_opts("approval_requirements", deps) do
    [approval_requirement_schema: fetch_dep!(deps, :approval_requirement_schema)]
  end

  def property_opts("tradeoffs", _deps) do
    [tradeoff_schema: tradeoff()]
  end

  def property_opts("score_terms", deps) do
    [numeric_map_schema: fetch_dep!(deps, :numeric_map_schema)]
  end

  def property_opts("policy_decision", deps) do
    [policy_decision_schema: fetch_dep!(deps, :policy_decision_schema)]
  end

  def property_opts(_field, _deps), do: []

  def property("schema_contract", _opts) do
    %{"type" => "string", "const" => "strategy_branch.v1"}
  end

  def property("branch_id", opts) do
    %{"type" => "string", "pattern" => Keyword.fetch!(opts, :stable_id_pattern)}
  end

  def property("probability", _opts) do
    %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0}
  end

  def property("score", _opts) do
    %{"type" => "number"}
  end

  def property("events", opts) do
    array(Keyword.fetch!(opts, :event_schema))
  end

  def property("warnings", _opts) do
    CommonJsonSchema.string_array()
  end

  def property("risk_indicators", opts) do
    array(Keyword.fetch!(opts, :risk_schema))
  end

  def property("approval_requirements", opts) do
    array(Keyword.fetch!(opts, :approval_requirement_schema))
  end

  def property("tradeoffs", opts) do
    array(Keyword.fetch!(opts, :tradeoff_schema))
  end

  def property(field, _opts) when field in @object_fields do
    object_property(field)
  end

  def property("score_terms", opts) do
    Keyword.fetch!(opts, :numeric_map_schema)
  end

  def property("policy_decision", opts) do
    Keyword.fetch!(opts, :policy_decision_schema)
  end

  def property("approval_status", _opts) do
    %{"type" => "string", "enum" => @approval_status_values}
  end

  def branch(opts) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "branch_id",
        "probability",
        "events",
        "candidate_plan",
        "repair_result",
        "score",
        "score_terms",
        "warnings",
        "risk_indicators",
        "approval_status",
        "approval_requirements",
        "policy_decision"
      ],
      "properties" => %{
        "branch_id" => %{
          "type" => "string",
          "pattern" => Keyword.fetch!(opts, :stable_id_pattern)
        },
        "label" => %{"type" => "string"},
        "rank" => %{"type" => "integer"},
        "selected" => %{"type" => "boolean"},
        "probability" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0},
        "score" => %{"type" => "number"},
        "score_terms" => Keyword.fetch!(opts, :numeric_map_schema),
        "warnings" => Keyword.fetch!(opts, :string_array_schema),
        "events" => array(Keyword.fetch!(opts, :event_schema)),
        "candidate_plan" => %{"type" => "object", "additionalProperties" => true},
        "repair_result" => %{"type" => "object", "additionalProperties" => true},
        "resource_impacts" => %{"type" => "object", "additionalProperties" => true},
        "resource_projection_report" => %{"type" => "object", "additionalProperties" => true},
        "risk_indicators" => array(Keyword.fetch!(opts, :risk_schema)),
        "approval_requirements" => array(Keyword.fetch!(opts, :approval_requirement_schema)),
        "approval_rule_matches" =>
          array(Keyword.fetch!(opts, :policy_decision_rule_match_schema)),
        "tradeoffs" => array(Keyword.fetch!(opts, :tradeoff_schema)),
        "approval_status" => %{"type" => "string", "enum" => @approval_status_values},
        "policy_decision" => Keyword.fetch!(opts, :policy_decision_schema),
        "derived_source" => %{"type" => "string"},
        "feasibility_summary" => %{"type" => "object", "additionalProperties" => true},
        "feedback_adjustments" => %{"type" => "object", "additionalProperties" => true},
        "objective_satisfaction" => %{"type" => "object", "additionalProperties" => true},
        "assumptions" => Keyword.fetch!(opts, :assumptions_schema),
        "provenance" => Keyword.fetch!(opts, :provenance_schema)
      }
    }
  end

  def assumptions(opts) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "branch_id" => %{
          "type" => "string",
          "pattern" => Keyword.fetch!(opts, :stable_id_pattern)
        },
        "candidate_source" => candidate_source(opts),
        "what_if_events" => %{"type" => "array", "items" => Keyword.fetch!(opts, :event_schema)},
        "model_limits" => Keyword.fetch!(opts, :string_array_schema),
        "repair_policy" => %{"type" => "object", "additionalProperties" => true},
        "repair_scoring_policy" => %{"type" => "object", "additionalProperties" => true},
        "strategy_policy" => %{"type" => "object", "additionalProperties" => true}
      }
    }
  end

  def provenance(opts) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "source_plan_id" => %{
          "type" => "string",
          "pattern" => Keyword.fetch!(opts, :stable_id_pattern)
        },
        "branch_id" => %{
          "type" => "string",
          "pattern" => Keyword.fetch!(opts, :stable_id_pattern)
        },
        "branch_metadata" => %{"type" => "object", "additionalProperties" => true},
        "candidate_source" => candidate_source(opts)
      }
    }
  end

  def candidate_source(opts) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "type" => %{"type" => "string"},
        "scope" => %{"type" => "string"},
        "refresh_id" => %{
          "type" => "string",
          "pattern" => Keyword.fetch!(opts, :stable_id_pattern)
        },
        "snapshot_id" => %{
          "type" => "string",
          "pattern" => Keyword.fetch!(opts, :stable_id_pattern)
        },
        "generated_at" => %{"type" => "string", "format" => "date-time"},
        "candidate_count" => %{"type" => "integer", "minimum" => 0},
        "invalidated_candidate_count" => %{"type" => "integer", "minimum" => 0},
        "maneuver_execution_delta_count" => %{"type" => "integer", "minimum" => 0},
        "operational_feedback_input_keys" => Keyword.fetch!(opts, :string_array_schema),
        "operational_feedback_trust_boundary_status" => %{"type" => "string"},
        "source_report_input_paths" => Keyword.fetch!(opts, :string_array_schema),
        "source_operational_feedback_provenance" => %{
          "type" => "object",
          "additionalProperties" => true,
          "properties" => %{
            "source_path" => %{"type" => "string"},
            "input_keys" => Keyword.fetch!(opts, :string_array_schema),
            "trust_boundary_status" => %{"type" => "string"}
          }
        }
      }
    }
  end

  def tradeoff do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["dimension", "baseline", "recommended", "delta"],
      "properties" => %{
        "dimension" => %{"type" => "string"},
        "baseline" => %{"type" => "number"},
        "recommended" => %{"type" => "number"},
        "delta" => %{"type" => "number"}
      }
    }
  end

  def risk(stable_id_pattern, scoped_downlink_context_properties) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["type", "severity", "reason"],
      "properties" =>
        %{
          "type" => %{"type" => "string"},
          "severity" => %{"type" => "string"},
          "reason" => %{"type" => "string"},
          "value" => %{"type" => "number"},
          "station_reservation_expiration_status" => %{"type" => "string"},
          "station_calendar_provider_id" => %{
            "type" => "string",
            "pattern" => stable_id_pattern
          },
          "station_calendar_provider_entry_id" => %{
            "type" => "string",
            "pattern" => stable_id_pattern
          },
          "provider_counteroffer_id" => %{
            "type" => "string",
            "pattern" => stable_id_pattern
          },
          "provider_counteroffer_status" => %{"type" => "string"},
          "provider_counteroffer_reason_code" => %{"type" => "string"},
          "provider_counteroffer_cost_delta" => %{"type" => "number"},
          "provider_counteroffer_lock_deadline_s" => %{"type" => "number"},
          "provider_counteroffer_starts_at_s" => %{"type" => "number"},
          "provider_counteroffer_ends_at_s" => %{"type" => "number"},
          "provider_counteroffer_start_delta_s" => %{"type" => "number"},
          "provider_counteroffer_end_delta_s" => %{"type" => "number"},
          "provider_counteroffer_duration_delta_s" => %{"type" => "number"},
          "source_provider_counteroffer" => %{"type" => "object"},
          "first_resource_pressure_station_calendar_provider_id" => %{
            "type" => "string",
            "pattern" => stable_id_pattern
          },
          "first_resource_pressure_station_calendar_provider_entry_id" => %{
            "type" => "string",
            "pattern" => stable_id_pattern
          }
        }
        |> Map.merge(scoped_downlink_context_properties)
    }
  end

  def event(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    stable_id_array_schema = Keyword.fetch!(opts, :stable_id_array_schema)
    semantic_change_details_schema = Keyword.fetch!(opts, :semantic_change_details_schema)
    numeric_map_schema = Keyword.fetch!(opts, :numeric_map_schema)
    string_list_map_schema = Keyword.fetch!(opts, :string_list_map_schema)
    count_map_schema = Keyword.fetch!(opts, :non_negative_integer_count_map_schema)
    string_array_schema = CommonJsonSchema.string_array()
    number_array_schema = CommonJsonSchema.number_array()

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["type"],
      "properties" => %{
        "type" => %{"type" => "string"},
        "objective_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "objective_type" => %{"type" => "string"},
        "scenario_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "branch_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "source_branch_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "source_branch_ids" => stable_id_array_schema,
        "target_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "source_target_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "source_target" => %{"type" => "object", "additionalProperties" => true},
        "target_latitude_deg" => %{"type" => "number"},
        "target_longitude_deg" => %{"type" => "number"},
        "target_minimum_elevation_deg" => %{"type" => "number"},
        "ground_station_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "spacecraft_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "station_calendar_entry_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "station_calendar_provider_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "station_calendar_provider_entry_id" => %{
          "type" => "string",
          "pattern" => stable_id_pattern
        },
        "source_activity_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "source_activity_ids" => stable_id_array_schema,
        "missed_downlink_activity_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "missed_downlink_activity_ids" => stable_id_array_schema,
        "source_window_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "source_window_ids" => stable_id_array_schema,
        "collection_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "collection_ids" => stable_id_array_schema,
        "product_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "product_ids" => stable_id_array_schema,
        "payload_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "payload_ids" => stable_id_array_schema,
        "instrument_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "instrument_ids" => stable_id_array_schema,
        "starts_at_s" => %{"type" => "number"},
        "ends_at_s" => %{"type" => "number"},
        "actual_starts_at_s" => %{"type" => "number"},
        "actual_ends_at_s" => %{"type" => "number"},
        "priority" => %{"type" => "number", "minimum" => 0.0},
        "target_priority" => %{"type" => "number", "minimum" => 0.0},
        "target_priority_source" => %{"type" => "string"},
        "target_priority_objective_ids" => stable_id_array_schema,
        "target_priority_objective_type" => %{"type" => "string"},
        "semantic_change_details" => semantic_change_details_schema,
        "changed_fields" => string_array_schema,
        "candidate_diff_changed_fields" => string_array_schema,
        "candidate_diff_changed_field_count" => %{"type" => "integer", "minimum" => 0},
        "required_contacts" => %{"type" => "number", "minimum" => 0.0},
        "planned_contacts" => %{"type" => "number", "minimum" => 0.0},
        "required_downlink_mb" => %{"type" => "number", "minimum" => 0.0},
        "planned_downlink_mb" => %{"type" => "number", "minimum" => 0.0},
        "max_latency_s" => %{"type" => "number", "minimum" => 0.0},
        "planned_latency_s" => %{"type" => "number", "minimum" => 0.0},
        "required_observations" => %{"type" => "integer", "minimum" => 0},
        "planned_observations" => %{"type" => "number", "minimum" => 0.0},
        "latency_objective" => %{"type" => "boolean"},
        "contact_success_factor" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0},
        "command_success_factor" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0},
        "capacity_fraction" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0},
        "observation_success_factor" => %{
          "type" => "number",
          "minimum" => 0.0,
          "maximum" => 1.0
        },
        "image_quality_score" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0},
        "image_quality_status" => %{"type" => "string"},
        "image_quality_source" => %{"type" => "string"},
        "cloud_cover_fraction" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0},
        "blur_score" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0},
        "maneuver_success_factor" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0},
        "station_throughput_factor" => %{
          "type" => "number",
          "minimum" => 0.0,
          "maximum" => 1.0
        },
        "feedback_weight" => %{"type" => "number", "minimum" => 0.0},
        "feedback_weight_source" => %{"type" => "string"},
        "feedback_sample_weight" => %{"type" => "number", "minimum" => 0.0},
        "feedback_sample_weight_source" => %{"type" => "string"},
        "sample_weight" => %{"type" => "number", "minimum" => 0.0},
        "sample_weight_source" => %{"type" => "string"},
        "confidence_weight" => %{"type" => "number", "minimum" => 0.0},
        "confidence_weight_source" => %{"type" => "string"},
        "score_term_key" => %{"type" => "string"},
        "score_term_value" => %{"type" => "number"},
        "timeline_score" => %{"type" => "number"},
        "score_terms" => numeric_map_schema,
        "model_ids_by_status" => string_list_map_schema,
        "model_ids_by_validation_level" => string_list_map_schema,
        "model_ids_by_intended_use" => string_list_map_schema,
        "validation_safety_case_status" => %{"type" => "string"},
        "evidence_status" => %{"type" => "string"},
        "input_contract" => %{"type" => "string"},
        "input_contracts" => string_array_schema,
        "evidence_ref" => %{"type" => "string"},
        "evidence_count" => %{"type" => "integer", "minimum" => 0},
        "accepted_evidence_count" => %{"type" => "integer", "minimum" => 0},
        "review_required_evidence_count" => %{"type" => "integer", "minimum" => 0},
        "blocked_evidence_count" => %{"type" => "integer", "minimum" => 0},
        "schema_error_count" => %{"type" => "integer", "minimum" => 0},
        "schema_warning_count" => %{"type" => "integer", "minimum" => 0},
        "model_blocked_count" => %{"type" => "integer", "minimum" => 0},
        "quality_gate_review_count" => %{"type" => "integer", "minimum" => 0},
        "quality_gate_blocked_count" => %{"type" => "integer", "minimum" => 0},
        "evidence_status_counts" => count_map_schema,
        "evidence_refs_by_status" => string_list_map_schema,
        "evidence_refs_by_contract" => string_list_map_schema,
        "station_availability" => %{"type" => "string"},
        "station_calendar_status" => %{"type" => "string"},
        "station_calendar_directions" => string_array_schema,
        "station_calendar_overlap_count" => %{"type" => "integer", "minimum" => 0},
        "station_calendar_overlap_entry_ids" => stable_id_array_schema,
        "station_calendar_overlap_availabilities" => string_array_schema,
        "station_calendar_entry_ambiguous" => %{"type" => "boolean"},
        "station_calendar_ambiguous_entry_count" => %{"type" => "integer", "minimum" => 0},
        "station_calendar_ambiguous_entry_ids" => stable_id_array_schema,
        "station_calendar_reservation_overlap_count" => %{"type" => "integer", "minimum" => 0},
        "station_calendar_reservation_ids" => stable_id_array_schema,
        "station_calendar_reserved_by" => string_array_schema,
        "station_calendar_reservation_statuses" => string_array_schema,
        "station_calendar_reservation_expires_at_s" => number_array_schema,
        "provider_counteroffer_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "provider_counteroffer_status" => %{"type" => "string"},
        "provider_counteroffer_negotiation_state" => %{
          "type" => "string",
          "enum" => Keyword.fetch!(opts, :provider_counteroffer_negotiation_states)
        },
        "provider_counteroffer_reason_code" => %{"type" => "string"},
        "provider_counteroffer_cost_delta" => %{"type" => "number"},
        "provider_counteroffer_lock_deadline_s" => %{"type" => "number"},
        "provider_counteroffer_starts_at_s" => %{"type" => "number"},
        "provider_counteroffer_ends_at_s" => %{"type" => "number"},
        "provider_counteroffer_start_delta_s" => %{"type" => "number"},
        "provider_counteroffer_end_delta_s" => %{"type" => "number"},
        "provider_counteroffer_duration_delta_s" => %{"type" => "number"},
        "station_calendar_trust_boundary_status" => %{
          "type" => "string",
          "enum" => ["declared", "missing"]
        },
        "station_contention_status" => %{"type" => "string"},
        "station_reservation_match_status" => %{"type" => "string"},
        "station_reservation_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "station_reservation_expires_at_s" => %{"type" => "number"},
        "station_reserved_by" => %{"type" => "string"},
        "station_reservation_status" => %{"type" => "string"},
        "reservation_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "reservation_expires_at_s" => %{"type" => "number"},
        "reserved_by" => %{"type" => "string"},
        "reservation_status" => %{"type" => "string"},
        "downlink_demand_sources" => string_array_schema,
        "downlink_completion_source" => %{"type" => "string"},
        "downlink_completion_sources" => string_array_schema,
        "capacity_pack_group_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "capacity_pack_status" => %{"type" => "string"},
        "capacity_pack_capacity_fraction" => %{
          "type" => "number",
          "minimum" => 0.0,
          "maximum" => 1.0
        },
        "capacity_pack_used_fraction" => %{
          "type" => "number",
          "minimum" => 0.0,
          "maximum" => 1.0
        },
        "capacity_pack_unused_fraction" => %{
          "type" => "number",
          "minimum" => 0.0,
          "maximum" => 1.0
        },
        "required_capacity_fraction" => %{
          "type" => "number",
          "minimum" => 0.0,
          "maximum" => 1.0
        },
        "required_capacity_fraction_source" => %{"type" => "string"},
        "derivation_reason" => %{"type" => "string"},
        "derivation_reasons" => string_array_schema,
        "feedback_source" => %{"type" => "string"},
        "feedback_scope" => %{"type" => "string"},
        "trust_boundary" => %{"type" => "string"},
        "provenance" => %{"type" => "object", "additionalProperties" => true}
      }
    }
  end

  defp array(item_schema) do
    %{"type" => "array", "items" => item_schema}
  end

  defp object_property(field) when field in ["derived_source", "label"] do
    %{"type" => "object"}
  end

  defp object_property(_field) do
    %{"type" => "object", "additionalProperties" => true}
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
