defmodule OrbitalDynamics.Schema.StationCalendarReportJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @trust_boundary_count_fields [
    "calendar_entry_trust_boundary_status_counts",
    "station_calendar_trust_boundary_status_counts"
  ]

  @count_map_fields [
    "affected_contact_availability_counts",
    "affected_contact_ground_station_counts",
    "direction_counts",
    "station_calendar_status_counts",
    "station_reservation_match_status_counts"
  ]

  @string_list_map_fields [
    "affected_contact_ids_by_reservation_match_status",
    "affected_contact_ids_by_station_calendar_trust_boundary_status"
  ]

  @count_fields [
    "input_contact_count",
    "calendar_entry_count",
    "affected_contact_count",
    "duplicate_affected_contact_id_count",
    "duplicate_affected_contact_row_count",
    "provider_calendar_contention_group_count",
    "provider_counteroffer_count"
  ]

  def property_field?(field)
      when field in [
             "affected_contacts",
             "model",
             "affected_duration_s",
             "provider_calendar_contention_groups",
             "model_limits"
           ],
      do: true

  def property_field?(field)
      when field in @trust_boundary_count_fields or field in @count_map_fields or
             field in @string_list_map_fields or field in @count_fields,
      do: true

  def property_field?(_field), do: false

  def property_opts("affected_contacts", deps) do
    [contact_schema: fetch_dep!(deps, :contact_schema)]
  end

  def property_opts("model", deps) do
    [model: fetch_dep!(deps, :model)]
  end

  def property_opts("provider_calendar_contention_groups", deps) do
    [provider_contention_group_schema: fetch_dep!(deps, :provider_contention_group_schema)]
  end

  def property_opts("entries", deps) do
    [entry_schema: fetch_dep!(deps, :entry_schema)]
  end

  def property_opts(field, deps) when field in @trust_boundary_count_fields do
    [trust_boundary_status_count_schema: fetch_dep!(deps, :trust_boundary_status_count_schema)]
  end

  def property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts(_field, _deps), do: []

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property_fun_from_context(deps) when is_list(deps) do
    fn field -> property_from_context(field, deps) end
  end

  def property("affected_contacts", opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :contact_schema)}
  end

  def property("model", opts) do
    %{"type" => "string", "const" => Keyword.fetch!(opts, :model)}
  end

  def property("provider_calendar_contention_groups", opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :provider_contention_group_schema)
    }
  end

  def property("entries", opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :entry_schema)}
  end

  def property("affected_duration_s", _opts) do
    %{"type" => "number"}
  end

  def property(field, opts) when field in @trust_boundary_count_fields do
    Keyword.fetch!(opts, :trust_boundary_status_count_schema)
  end

  def property(field, _opts) when field in @count_map_fields do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def property(field, _opts) when field in @string_list_map_fields do
    CommonJsonSchema.string_list_map()
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def contact(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    negotiation_states = Keyword.fetch!(opts, :provider_counteroffer_negotiation_states)
    source_entry_schema = Keyword.fetch!(opts, :source_entry_schema)
    approval_requirement_schema = Keyword.fetch!(opts, :approval_requirement_schema)
    policy_decision_rule_match_schema = Keyword.fetch!(opts, :policy_decision_rule_match_schema)
    policy_decision_schema = Keyword.fetch!(opts, :policy_decision_schema)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "id",
        "contact_id",
        "scenario_id",
        "ground_station_id",
        "station_calendar_entry_id",
        "status",
        "station_availability"
      ],
      "properties" => %{
        "id" => stable_id(stable_id_pattern),
        "contact_id" => stable_id(stable_id_pattern),
        "scenario_id" => stable_id(stable_id_pattern),
        "ground_station_id" => stable_id(stable_id_pattern),
        "starts_at_s" => %{"type" => "number"},
        "ends_at_s" => %{"type" => "number"},
        "overlap_starts_at_s" => %{"type" => "number"},
        "overlap_ends_at_s" => %{"type" => "number"},
        "overlap_duration_s" => %{"type" => "number"},
        "station_calendar_entry_id" => stable_id(stable_id_pattern),
        "station_calendar_provider_id" => stable_id(stable_id_pattern),
        "station_calendar_provider_entry_id" => stable_id(stable_id_pattern),
        "first_resource_pressure_station_calendar_provider_id" => stable_id(stable_id_pattern),
        "first_resource_pressure_station_calendar_provider_entry_id" =>
          stable_id(stable_id_pattern),
        "station_calendar_directions" => CommonJsonSchema.string_array(),
        "station_calendar_precedence_rank" => %{"type" => "integer", "minimum" => 0},
        "station_calendar_precedence_availability" => %{"type" => "string"},
        "contact_type" => %{"type" => "string"},
        "direction" => %{"type" => "string"},
        "contact_success" => %{"type" => "boolean"},
        "contact_result" => %{"type" => "string"},
        "contact_success_factor" => probability(),
        "contact_success_factor_source" => %{"type" => "string"},
        "command_success" => %{"type" => "boolean"},
        "command_result" => %{"type" => "string"},
        "command_success_factor" => probability(),
        "command_success_factor_source" => %{"type" => "string"},
        "status" => %{"type" => "string"},
        "station_availability" => %{
          "type" => "string",
          "enum" => ["available", "unavailable", "reduced_capacity", "maintenance", "reserved"]
        },
        "capacity_fraction" => probability(),
        "station_calendar_overlap_count" => %{"type" => "integer", "minimum" => 0},
        "station_calendar_overlap_entry_ids" =>
          CommonJsonSchema.stable_id_array(stable_id_pattern),
        "station_calendar_overlap_availabilities" => CommonJsonSchema.string_array(),
        "station_calendar_entry_ambiguous" => %{"type" => "boolean"},
        "station_calendar_ambiguous_entry_count" => %{"type" => "integer", "minimum" => 0},
        "station_calendar_ambiguous_entry_ids" =>
          CommonJsonSchema.stable_id_array(stable_id_pattern),
        "station_calendar_reservation_overlap_count" => %{
          "type" => "integer",
          "minimum" => 0
        },
        "station_calendar_reservation_ids" => CommonJsonSchema.stable_id_array(stable_id_pattern),
        "station_calendar_reserved_by" => CommonJsonSchema.string_array(),
        "station_calendar_reservation_statuses" => CommonJsonSchema.string_array(),
        "station_calendar_reservation_expires_at_s" => CommonJsonSchema.number_array(),
        "provider_counteroffer_id" => stable_id(stable_id_pattern),
        "provider_counteroffer_status" => %{"type" => "string"},
        "provider_counteroffer_negotiation_state" => %{
          "type" => "string",
          "enum" => negotiation_states
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
        "station_reservation_id" => stable_id(stable_id_pattern),
        "station_reservation_expires_at_s" => %{"type" => "number"},
        "station_reserved_by" => %{"type" => "string"},
        "station_reservation_status" => %{"type" => "string"},
        "station_reservation_match_status" => %{"type" => "string"},
        "trust_boundary" => %{"type" => "string"},
        "provenance" => %{"type" => "object", "additionalProperties" => true},
        "source_station_calendar_entry" => source_entry_schema,
        "source_station_calendar_overlaps" => %{
          "type" => "array",
          "items" => source_entry_schema
        },
        "required_operator_action" => %{"type" => "string"},
        "operator_action_reason" => %{"type" => "string"},
        "approval_status" => %{
          "type" => "string",
          "enum" => ["auto_approvable", "operator_review_required", "blocked_by_policy"]
        },
        "approval_requirements" => %{
          "type" => "array",
          "items" => approval_requirement_schema
        },
        "approval_rule_matches" => %{
          "type" => "array",
          "items" => policy_decision_rule_match_schema
        },
        "policy_decision" => policy_decision_schema
      }
    }
  end

  def source_entry(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    negotiation_states = Keyword.fetch!(opts, :provider_counteroffer_negotiation_states)
    availability = ["available", "unavailable", "reduced_capacity", "maintenance", "reserved"]

    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "id" => stable_id(stable_id_pattern),
        "ground_station_id" => stable_id(stable_id_pattern),
        "provider_id" => stable_id(stable_id_pattern),
        "provider_entry_id" => stable_id(stable_id_pattern),
        "availability" => %{"type" => "string", "enum" => availability},
        "status" => %{"type" => "string", "enum" => ["ambiguous" | availability]},
        "capacity_fraction" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0},
        "reservation_id" => stable_id(stable_id_pattern),
        "reserved_by" => %{"type" => "string"},
        "reservation_status" => %{"type" => "string"},
        "provider_counteroffer_id" => stable_id(stable_id_pattern),
        "provider_counteroffer_status" => %{"type" => "string"},
        "provider_counteroffer_negotiation_state" => %{
          "type" => "string",
          "enum" => negotiation_states
        },
        "provider_counteroffer_reason_code" => %{"type" => "string"},
        "provider_counteroffer_cost_delta" => %{"type" => "number"},
        "provider_counteroffer_lock_deadline_s" => %{"type" => "number"},
        "provider_counteroffer_starts_at_s" => %{"type" => "number"},
        "provider_counteroffer_ends_at_s" => %{"type" => "number"},
        "provider_counteroffer_start_delta_s" => %{"type" => "number"},
        "provider_counteroffer_end_delta_s" => %{"type" => "number"},
        "provider_counteroffer_duration_delta_s" => %{"type" => "number"},
        "directions" => CommonJsonSchema.string_array(),
        "starts_at_s" => %{"type" => ["number", "null"]},
        "ends_at_s" => %{"type" => ["number", "null"]},
        "station_calendar_entry_ambiguous" => %{"type" => "boolean"},
        "station_calendar_ambiguous_entry_count" => %{"type" => "integer", "minimum" => 0},
        "station_calendar_ambiguous_entry_ids" =>
          CommonJsonSchema.stable_id_array(stable_id_pattern),
        "trust_boundary" => %{"type" => "string"},
        "provenance" => %{"type" => "object", "additionalProperties" => true}
      }
    }
  end

  def provider_contention_group(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    policy_decision_schema = Keyword.fetch!(opts, :policy_decision_schema)
    provider_contention_pair_schema = Keyword.fetch!(opts, :provider_contention_pair_schema)
    provider_entry_schema = Keyword.fetch!(opts, :provider_entry_schema)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "id",
        "provider_calendar_contention_status",
        "required_operator_action",
        "approval_status",
        "ground_station_id",
        "entry_count",
        "entry_ids",
        "overlap_pairs"
      ],
      "properties" => %{
        "id" => stable_id(stable_id_pattern),
        "provider_calendar_contention_status" => %{
          "type" => "string",
          "enum" => ["provider_calendar_overlap"]
        },
        "required_operator_action" => %{
          "type" => "string",
          "enum" => ["review_station_provider_contention"]
        },
        "approval_status" => %{
          "type" => "string",
          "enum" => ["auto_approvable", "operator_review_required", "blocked_by_policy"]
        },
        "operator_action_reason" => %{"type" => "string"},
        "ground_station_id" => stable_id(stable_id_pattern),
        "starts_at_s" => %{"type" => "number"},
        "ends_at_s" => %{"type" => "number"},
        "overlap_duration_s" => %{"type" => "number"},
        "entry_count" => %{"type" => "integer", "minimum" => 0},
        "entry_ids" => CommonJsonSchema.stable_id_array(stable_id_pattern),
        "provider_ids" => CommonJsonSchema.string_array(),
        "provider_entry_ids" => CommonJsonSchema.string_array(),
        "availabilities" => CommonJsonSchema.string_array(),
        "directions" => CommonJsonSchema.string_array(),
        "reservation_ids" => CommonJsonSchema.string_array(),
        "reserved_by" => CommonJsonSchema.string_array(),
        "reservation_statuses" => CommonJsonSchema.string_array(),
        "reservation_expires_at_s" => CommonJsonSchema.number_array(),
        "trust_boundary_statuses" => %{
          "type" => "array",
          "items" => %{"type" => "string", "enum" => ["declared", "missing"]}
        },
        "approval_requirements" => %{"type" => "array"},
        "approval_rule_matches" => %{"type" => "array"},
        "policy_decision" => policy_decision_schema,
        "overlap_pairs" => %{
          "type" => "array",
          "items" => provider_contention_pair_schema
        },
        "source_station_calendar_entries" => %{
          "type" => "array",
          "items" => provider_entry_schema
        }
      }
    }
  end

  def provider_contention_pair(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    CommonJsonSchema.provider_calendar_contention_overlap_pair(stable_id_pattern)
  end

  def provider_entry(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    negotiation_states = Keyword.fetch!(opts, :provider_counteroffer_negotiation_states)

    availability = [
      "available",
      "unavailable",
      "outage",
      "down",
      "offline",
      "reduced_capacity",
      "maintenance",
      "reserved",
      "hold",
      "held",
      "on_hold",
      "onhold",
      "reservation_held",
      "reserved_hold",
      "reservation_hold"
    ]

    %{
      "type" => "object",
      "additionalProperties" => true,
      "anyOf" => [
        %{"required" => ["ground_station_id"]},
        %{"required" => ["station_id"]}
      ],
      "allOf" => [
        %{
          "anyOf" => [
            %{"required" => ["availability"]},
            %{"required" => ["status"]}
          ]
        }
      ],
      "properties" => %{
        "id" => stable_id(stable_id_pattern),
        "ground_station_id" => stable_id(stable_id_pattern),
        "station_id" => stable_id(stable_id_pattern),
        "availability" => %{
          "oneOf" => [
            %{"type" => "string", "enum" => availability},
            probability()
          ]
        },
        "status" => %{"type" => "string", "enum" => availability},
        "capacity_pack_capacity_fraction" => probability(),
        "capacity_fraction" => probability(),
        "reservation_id" => stable_id(stable_id_pattern),
        "reservation_hold_id" => stable_id(stable_id_pattern),
        "hold_id" => stable_id(stable_id_pattern),
        "reservation_expires_at_s" => %{"type" => "number"},
        "reservation_hold_expires_at_s" => %{"type" => "number"},
        "hold_expires_at_s" => %{"type" => "number"},
        "expires_at_s" => %{"type" => "number"},
        "expires_at" => %{"type" => "number"},
        "valid_until_s" => %{"type" => "number"},
        "reserved_by" => %{"type" => "string"},
        "held_by" => %{"type" => "string"},
        "hold_owner" => %{"type" => "string"},
        "reservation_status" => %{"type" => "string"},
        "hold_status" => %{"type" => "string"},
        "provider_counteroffer_id" => stable_id(stable_id_pattern),
        "counteroffer_id" => stable_id(stable_id_pattern),
        "offer_id" => stable_id(stable_id_pattern),
        "provider_counteroffer_status" => %{"type" => "string"},
        "counteroffer_status" => %{"type" => "string"},
        "offer_status" => %{"type" => "string"},
        "negotiation_status" => %{"type" => "string"},
        "provider_counteroffer_negotiation_state" => %{
          "type" => "string",
          "enum" => negotiation_states
        },
        "counteroffer_negotiation_state" => %{"type" => "string"},
        "provider_counteroffer_reason_code" => %{"type" => "string"},
        "counteroffer_reason_code" => %{"type" => "string"},
        "offer_reason_code" => %{"type" => "string"},
        "provider_reason_code" => %{"type" => "string"},
        "reason_code" => %{"type" => "string"},
        "provider_counteroffer_cost_delta" => %{"type" => "number"},
        "counteroffer_cost_delta" => %{"type" => "number"},
        "cost_delta" => %{"type" => "number"},
        "price_delta" => %{"type" => "number"},
        "provider_counteroffer_lock_deadline_s" => %{"type" => "number"},
        "counteroffer_lock_deadline_s" => %{"type" => "number"},
        "schedule_lock_deadline_s" => %{"type" => "number"},
        "lock_deadline_s" => %{"type" => "number"},
        "provider_counteroffer_starts_at_s" => %{"type" => "number"},
        "counteroffer_starts_at_s" => %{"type" => "number"},
        "counteroffer_start_s" => %{"type" => "number"},
        "offered_starts_at_s" => %{"type" => "number"},
        "offered_start_s" => %{"type" => "number"},
        "provider_counteroffer_ends_at_s" => %{"type" => "number"},
        "provider_counteroffer_start_delta_s" => %{"type" => "number"},
        "provider_counteroffer_end_delta_s" => %{"type" => "number"},
        "provider_counteroffer_duration_delta_s" => %{"type" => "number"},
        "counteroffer_ends_at_s" => %{"type" => "number"},
        "counteroffer_end_s" => %{"type" => "number"},
        "offered_ends_at_s" => %{"type" => "number"},
        "offered_end_s" => %{"type" => "number"},
        "direction" => %{"type" => "string"},
        "directions" => CommonJsonSchema.string_array(),
        "station_calendar_directions" => CommonJsonSchema.string_array(),
        "trust_boundary" => %{"type" => "string"},
        "provenance" => %{"type" => "object", "additionalProperties" => true},
        "starts_at_s" => %{"type" => "number"},
        "ends_at_s" => %{"type" => "number"},
        "start_s" => %{"type" => "number"},
        "end_s" => %{"type" => "number"}
      }
    }
  end

  defp stable_id(stable_id_pattern) do
    %{"type" => "string", "pattern" => stable_id_pattern}
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end

  defp probability do
    %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0}
  end
end
