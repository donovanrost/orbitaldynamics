defmodule OrbitalDynamics.Schema.CandidateDiffJsonSchema do
  @moduledoc false

  @candidate_diff_row "candidate_diff_row.v1"
  @invalidated_candidate "invalidated_candidate.v1"
  @source_window_lineage "source_window_lineage.v1"

  @report_count_fields [
    "prior_candidate_count",
    "refreshed_candidate_count",
    "retained_candidate_count",
    "new_candidate_count",
    "invalidated_candidate_count",
    "valid_prior_candidate_count",
    "invalid_prior_candidate_input_count"
  ]

  @report_property_fields [
    "source_window_lineage",
    "model",
    "invalid_prior_candidate_input_ids",
    "model_limits",
    "invalidated_candidates",
    "retained_candidates",
    "new_candidates"
    | @report_count_fields
  ]

  @shared_stable_id_fields [
    "target_id",
    "collection_id",
    "product_id",
    "payload_id",
    "instrument_id",
    "objective_id",
    "source_activity_id",
    "missed_downlink_activity_id"
  ]

  @shared_stable_id_array_fields [
    "target_ids",
    "collection_ids",
    "product_ids",
    "payload_ids",
    "instrument_ids",
    "objective_ids",
    "source_activity_ids",
    "missed_downlink_activity_ids",
    "collection_latency_objective_ids"
  ]

  @shared_string_fields [
    "direction",
    "type",
    "source_window_type",
    "objective_type",
    "objective_status",
    "source_objective_status",
    "contact_result",
    "realized_status",
    "feedback_source",
    "feedback_scope",
    "trust_boundary",
    "collection_latency_objective_source",
    "downlink_requirement_status",
    "downlink_completion_source"
  ]

  @shared_string_array_fields [
    "objective_types",
    "objective_statuses",
    "source_objective_statuses",
    "contact_results",
    "realized_statuses",
    "feedback_sources",
    "feedback_scopes",
    "trust_boundaries",
    "derivation_reasons",
    "collection_latency_objective_types",
    "downlink_completion_sources"
  ]

  @shared_non_negative_number_fields [
    "max_latency_s",
    "planned_latency_s",
    "required_contacts",
    "planned_contacts",
    "required_downlink_mb",
    "planned_downlink_mb",
    "candidate_downlink_mb",
    "selected_downlink_shortfall_mb"
  ]

  @row_stable_id_fields [
    "id",
    "scenario_id",
    "ground_station_id",
    "source_target_id",
    "matched_prior_candidate_id",
    "source_window_id"
  ]

  @candidate_row_number_fields [
    "starts_at_s",
    "ends_at_s",
    "target_latitude_deg",
    "target_longitude_deg",
    "target_minimum_elevation_deg",
    "target_priority"
  ]

  @candidate_row_string_fields [
    "target_priority_source",
    "target_priority_objective_type"
  ]

  @invalidated_candidate_stable_id_fields [
    "id",
    "scenario_id",
    "ground_station_id",
    "source_target_id",
    "replacement_candidate_id",
    "source_window_id"
  ]

  def reason do
    %{
      "type" => "string",
      "enum" => [
        "present_in_prior_candidate_set",
        "present_in_prior_candidate_set_with_semantic_changes",
        "not_present_in_prior_candidate_set",
        "semantically_similar_prior_candidate_changed",
        "ambiguous_semantic_prior_candidate_match"
      ]
    }
  end

  def report_property_field?(field) when field in @report_property_fields, do: true
  def report_property_field?(_field), do: false

  def report_property_opts("source_window_lineage", deps) do
    [source_window_lineage_schema: fetch_dep!(deps, :source_window_lineage_schema)]
  end

  def report_property_opts("invalid_prior_candidate_input_ids", deps) do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def report_property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def report_property_opts(field, deps) when field in ["retained_candidates", "new_candidates"] do
    [candidate_diff_row_schema: fetch_dep!(deps, :candidate_diff_row_schema)]
  end

  def report_property_opts("invalidated_candidates", deps) do
    [invalidated_candidate_schema: fetch_dep!(deps, :invalidated_candidate_schema)]
  end

  def report_property_opts(_field, _deps), do: []

  def report_property_from_context(field, deps) when is_list(deps) do
    report_property(field, report_property_opts(field, deps))
  end

  def report_property_from_context(
        field,
        source_window_lineage_schema,
        stable_id_pattern,
        model_limits,
        candidate_diff_row_schema,
        invalidated_candidate_schema
      ) do
    report_property_from_context(
      field,
      source_window_lineage_schema: source_window_lineage_schema,
      stable_id_pattern: stable_id_pattern,
      model_limits: model_limits,
      candidate_diff_row_schema: candidate_diff_row_schema,
      invalidated_candidate_schema: invalidated_candidate_schema
    )
  end

  def report_property_fun_from_context(deps) when is_list(deps) do
    fn field -> report_property_from_context(field, deps) end
  end

  def report_property_fun_from_context(
        source_window_lineage_schema,
        stable_id_pattern,
        model_limits,
        candidate_diff_row_schema,
        invalidated_candidate_schema
      ) do
    fn field ->
      report_property_from_context(
        field,
        source_window_lineage_schema: source_window_lineage_schema,
        stable_id_pattern: stable_id_pattern,
        model_limits: model_limits,
        candidate_diff_row_schema: candidate_diff_row_schema,
        invalidated_candidate_schema: invalidated_candidate_schema
      )
    end
  end

  def family_property_field?(field, @candidate_diff_row) do
    row_property_field?(field)
  end

  def family_property_field?(field, @invalidated_candidate) do
    invalidated_candidate_property_field?(field)
  end

  def family_property_field?(field, @source_window_lineage) do
    source_window_lineage_property_field?(field)
  end

  def family_property_field?(_field, _contract_name), do: false

  def family_property_opts(field, contract_name, deps) do
    [
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)
    ] ++ family_property_extra_opts(field, contract_name, deps)
  end

  def family_property_from_context(field, deps) when is_list(deps) do
    contract_name = fetch_dep!(deps, :contract_name)
    family_property(field, contract_name, family_property_opts(field, contract_name, deps))
  end

  def family_property_from_context(
        field,
        contract_name,
        stable_id_pattern,
        scoped_context_properties
      ) do
    family_property_from_context(
      field,
      contract_name: contract_name,
      stable_id_pattern: stable_id_pattern,
      scoped_context_properties: scoped_context_properties
    )
  end

  def family_property_fun_from_context(deps) when is_list(deps) do
    fn field -> family_property_from_context(field, deps) end
  end

  def family_property_fun_from_context(
        contract_name,
        stable_id_pattern,
        scoped_context_properties
      ) do
    fn field ->
      family_property_from_context(
        field,
        contract_name: contract_name,
        stable_id_pattern: stable_id_pattern,
        scoped_context_properties: scoped_context_properties
      )
    end
  end

  def family_property(field, @candidate_diff_row, opts) do
    row_property(field, opts)
  end

  def family_property(field, @invalidated_candidate, opts) do
    invalidated_candidate_property(field, opts)
  end

  def family_property(field, @source_window_lineage, opts) do
    source_window_lineage_property(field, opts)
  end

  defp family_property_extra_opts("source_window", @source_window_lineage, deps) do
    [scoped_context_properties: fetch_dep!(deps, :scoped_context_properties)]
  end

  defp family_property_extra_opts(_field, _contract_name, _deps), do: []

  defp row_property_field?(field) do
    field in ["schema_contract", "source_target", "diff_reason"] or
      shared_candidate_property_field?(field) or
      field in @row_stable_id_fields or
      field in @candidate_row_string_fields or
      field in @candidate_row_number_fields or
      field in candidate_change_fields()
  end

  defp invalidated_candidate_property_field?(field) do
    field in ["schema_contract", "source_target", "invalidated_reason"] or
      shared_candidate_property_field?(field) or
      field in @invalidated_candidate_stable_id_fields or
      field in @candidate_row_string_fields or
      field in @candidate_row_number_fields or
      field in candidate_change_fields()
  end

  defp source_window_lineage_property_field?(field) do
    field in [
      "schema_contract",
      "source_window",
      "candidate_activity_id",
      "source_window_id",
      "scenario_id"
    ] or shared_candidate_property_field?(field)
  end

  defp shared_candidate_property_field?(field) do
    field in @shared_stable_id_fields or
      field in @shared_stable_id_array_fields or
      field in @shared_string_fields or
      field in @shared_string_array_fields or
      field in @shared_non_negative_number_fields or
      field in [
        "target_priority_objective_ids",
        "downlink_completion_ratio",
        "collection_latency_objective_count",
        "latency_objective"
      ]
  end

  defp candidate_change_fields do
    ["semantic_change_reasons", "changed_fields", "candidate_diff_changed_fields"] ++
      ["semantic_change_details", "candidate_diff_changed_field_count"]
  end

  def row_property("schema_contract", _opts) do
    %{"type" => "string", "const" => "candidate_diff_row.v1"}
  end

  def row_property(field, opts) when field in @row_stable_id_fields do
    stable_id_property(opts)
  end

  def row_property(field, opts) when field in @shared_stable_id_fields do
    stable_id_property(opts)
  end

  def row_property(field, opts)
      when field in @shared_stable_id_array_fields or field == "target_priority_objective_ids" do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> stable_id_array_schema()
  end

  def row_property("source_target", _opts) do
    object_schema()
  end

  def row_property(field, _opts) when field in @shared_string_fields do
    %{"type" => "string"}
  end

  def row_property(field, _opts) when field in @candidate_row_string_fields do
    %{"type" => "string"}
  end

  def row_property(field, _opts) when field in @shared_string_array_fields do
    string_array_schema()
  end

  def row_property(field, _opts)
      when field in ["semantic_change_reasons", "changed_fields", "candidate_diff_changed_fields"] do
    string_array_schema()
  end

  def row_property(field, _opts) when field in @shared_non_negative_number_fields do
    non_negative_number_schema()
  end

  def row_property("downlink_completion_ratio", _opts) do
    %{"type" => "number", "minimum" => 0, "maximum" => 1}
  end

  def row_property("collection_latency_objective_count", _opts) do
    non_negative_integer_schema()
  end

  def row_property("latency_objective", _opts) do
    %{"type" => "boolean"}
  end

  def row_property("semantic_change_details", _opts) do
    semantic_change_details()
  end

  def row_property("candidate_diff_changed_field_count", _opts) do
    non_negative_integer_schema()
  end

  def row_property(field, _opts) when field in @candidate_row_number_fields do
    %{"type" => "number"}
  end

  def row_property("diff_reason", _opts) do
    reason()
  end

  def invalidated_candidate_property("schema_contract", _opts) do
    %{"type" => "string", "const" => "invalidated_candidate.v1"}
  end

  def invalidated_candidate_property(field, opts)
      when field in @invalidated_candidate_stable_id_fields do
    stable_id_property(opts)
  end

  def invalidated_candidate_property(field, opts) when field in @shared_stable_id_fields do
    stable_id_property(opts)
  end

  def invalidated_candidate_property(field, opts)
      when field in @shared_stable_id_array_fields or field == "target_priority_objective_ids" do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> stable_id_array_schema()
  end

  def invalidated_candidate_property("source_target", _opts) do
    object_schema()
  end

  def invalidated_candidate_property("invalidated_reason", _opts) do
    %{"type" => "object"}
  end

  def invalidated_candidate_property(field, _opts) when field in @shared_string_fields do
    %{"type" => "string"}
  end

  def invalidated_candidate_property(field, _opts) when field in @candidate_row_string_fields do
    %{"type" => "string"}
  end

  def invalidated_candidate_property(field, _opts) when field in @shared_string_array_fields do
    string_array_schema()
  end

  def invalidated_candidate_property(field, _opts)
      when field in ["semantic_change_reasons", "changed_fields", "candidate_diff_changed_fields"] do
    string_array_schema()
  end

  def invalidated_candidate_property(field, _opts)
      when field in @shared_non_negative_number_fields do
    non_negative_number_schema()
  end

  def invalidated_candidate_property("downlink_completion_ratio", _opts) do
    %{"type" => "number", "minimum" => 0, "maximum" => 1}
  end

  def invalidated_candidate_property("collection_latency_objective_count", _opts) do
    non_negative_integer_schema()
  end

  def invalidated_candidate_property("latency_objective", _opts) do
    %{"type" => "boolean"}
  end

  def invalidated_candidate_property(field, _opts) when field in @candidate_row_number_fields do
    %{"type" => "number"}
  end

  def invalidated_candidate_property("semantic_change_details", _opts) do
    semantic_change_details()
  end

  def invalidated_candidate_property("candidate_diff_changed_field_count", _opts) do
    non_negative_integer_schema()
  end

  def source_window_lineage_property("schema_contract", _opts) do
    %{"type" => "string", "const" => "source_window_lineage.v1"}
  end

  def source_window_lineage_property("source_window", opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    scoped_context_properties = Keyword.fetch!(opts, :scoped_context_properties)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" =>
        %{
          "id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "type" => %{"type" => "string"},
          "scenario_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "starts_at_s" => %{"type" => "number"},
          "ends_at_s" => %{"type" => "number"},
          "duration_s" => %{"type" => "number"}
        }
        |> Map.merge(scoped_context_properties)
    }
  end

  def source_window_lineage_property(field, opts)
      when field in ["candidate_activity_id", "source_window_id", "scenario_id"] do
    stable_id_property(opts)
  end

  def source_window_lineage_property(field, opts) when field in @shared_stable_id_fields do
    stable_id_property(opts)
  end

  def source_window_lineage_property(field, opts) when field in @shared_stable_id_array_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> stable_id_array_schema()
  end

  def source_window_lineage_property(field, _opts) when field in @shared_string_fields do
    %{"type" => "string"}
  end

  def source_window_lineage_property(field, _opts) when field in @shared_string_array_fields do
    string_array_schema()
  end

  def source_window_lineage_property(field, _opts)
      when field in @shared_non_negative_number_fields do
    non_negative_number_schema()
  end

  def source_window_lineage_property("downlink_completion_ratio", _opts) do
    %{"type" => "number", "minimum" => 0, "maximum" => 1}
  end

  def source_window_lineage_property("collection_latency_objective_count", _opts) do
    non_negative_integer_schema()
  end

  def source_window_lineage_property("latency_objective", _opts) do
    %{"type" => "boolean"}
  end

  def report_property("source_window_lineage", opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :source_window_lineage_schema)
    }
  end

  def report_property("model", _opts) do
    %{
      "type" => "string",
      "const" => "candidate_id_set_diff_with_semantic_change_reasons"
    }
  end

  def report_property("invalid_prior_candidate_input_ids", opts) do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> stable_id_array_schema()
  end

  def report_property("model_limits", opts) do
    %{
      "type" => "array",
      "items" => %{"type" => "string", "enum" => Keyword.fetch!(opts, :model_limits)}
    }
  end

  def report_property(field, _opts) when field in @report_count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def report_property(field, opts) when field in ["retained_candidates", "new_candidates"] do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :candidate_diff_row_schema)
    }
  end

  def report_property("invalidated_candidates", opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :invalidated_candidate_schema)
    }
  end

  def source_window_lineage_from_context(stable_id_pattern, scoped_context_properties) do
    source_window_lineage(stable_id_pattern, scoped_context_properties)
  end

  def source_window_lineage_from_context(deps) when is_list(deps) do
    source_window_lineage(
      fetch_dep!(deps, :stable_id_pattern),
      fetch_dep!(deps, :scoped_context_properties)
    )
  end

  def source_window_lineage(stable_id_pattern, scoped_context_properties) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "candidate_activity_id",
        "source_window_id",
        "source_window_type",
        "scenario_id"
      ],
      "properties" =>
        %{
          "candidate_activity_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "source_window_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "source_window_type" => %{"type" => "string"},
          "scenario_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "source_window" => %{
            "type" => "object",
            "additionalProperties" => true,
            "properties" =>
              %{
                "id" => %{"type" => "string", "pattern" => stable_id_pattern},
                "type" => %{"type" => "string"},
                "scenario_id" => %{"type" => "string", "pattern" => stable_id_pattern},
                "starts_at_s" => %{"type" => "number"},
                "ends_at_s" => %{"type" => "number"},
                "duration_s" => %{"type" => "number"}
              }
              |> Map.merge(scoped_context_properties)
          }
        }
        |> Map.merge(scoped_context_properties)
    }
  end

  def invalidated_candidate_from_context(stable_id_pattern, scoped_context_properties) do
    invalidated_candidate(stable_id_pattern, scoped_context_properties)
  end

  def invalidated_candidate_from_context(deps) when is_list(deps) do
    invalidated_candidate(
      fetch_dep!(deps, :stable_id_pattern),
      fetch_dep!(deps, :scoped_context_properties)
    )
  end

  def invalidated_candidate(stable_id_pattern, scoped_context_properties) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["id", "invalidated_reason"],
      "properties" =>
        %{
          "id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "type" => %{"type" => "string"},
          "scenario_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "target_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "ground_station_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "direction" => %{"type" => "string"},
          "source_target_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "source_target" => %{"type" => "object", "additionalProperties" => true},
          "target_latitude_deg" => %{"type" => "number"},
          "target_longitude_deg" => %{"type" => "number"},
          "target_minimum_elevation_deg" => %{"type" => "number"},
          "target_priority" => %{"type" => "number"},
          "target_priority_source" => %{"type" => "string"},
          "target_priority_objective_ids" => stable_id_array_schema(stable_id_pattern),
          "target_priority_objective_type" => %{"type" => "string"},
          "starts_at_s" => %{"type" => "number"},
          "ends_at_s" => %{"type" => "number"},
          "invalidated_reason" => %{"type" => "string"},
          "replacement_candidate_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "source_window_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "semantic_change_reasons" => string_array_schema(),
          "semantic_change_details" => semantic_change_details(),
          "changed_fields" => string_array_schema(),
          "candidate_diff_changed_fields" => string_array_schema(),
          "candidate_diff_changed_field_count" => %{"type" => "integer", "minimum" => 0}
        }
        |> Map.merge(scoped_context_properties)
    }
  end

  def row_from_context(stable_id_pattern, scoped_context_properties) do
    row(stable_id_pattern, scoped_context_properties)
  end

  def row_from_context(deps) when is_list(deps) do
    row(
      fetch_dep!(deps, :stable_id_pattern),
      fetch_dep!(deps, :scoped_context_properties)
    )
  end

  def row(stable_id_pattern, scoped_context_properties) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["id", "type", "scenario_id", "diff_reason"],
      "properties" =>
        %{
          "schema_contract" => %{"type" => "string", "const" => "candidate_diff_row.v1"},
          "id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "type" => %{"type" => "string"},
          "scenario_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "target_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "ground_station_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "direction" => %{"type" => "string"},
          "source_target_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "source_target" => %{"type" => "object", "additionalProperties" => true},
          "target_latitude_deg" => %{"type" => "number"},
          "target_longitude_deg" => %{"type" => "number"},
          "target_minimum_elevation_deg" => %{"type" => "number"},
          "target_priority" => %{"type" => "number"},
          "target_priority_source" => %{"type" => "string"},
          "target_priority_objective_ids" => stable_id_array_schema(stable_id_pattern),
          "target_priority_objective_type" => %{"type" => "string"},
          "starts_at_s" => %{"type" => "number"},
          "ends_at_s" => %{"type" => "number"},
          "matched_prior_candidate_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "source_window_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "semantic_change_reasons" => string_array_schema(),
          "semantic_change_details" => semantic_change_details(),
          "changed_fields" => string_array_schema(),
          "candidate_diff_changed_fields" => string_array_schema(),
          "candidate_diff_changed_field_count" => %{"type" => "integer", "minimum" => 0},
          "diff_reason" => reason()
        }
        |> Map.merge(scoped_context_properties)
    }
  end

  def semantic_change_details do
    %{
      "type" => "array",
      "items" => %{
        "type" => "object",
        "additionalProperties" => true,
        "required" => ["field", "reason", "prior_value", "refreshed_value"],
        "properties" => %{
          "field" => %{"type" => "string"},
          "reason" => %{"type" => "string"},
          "prior_path" => %{"type" => "string"},
          "refreshed_path" => %{"type" => "string"},
          "prior_value" => semantic_change_value(),
          "refreshed_value" => semantic_change_value()
        }
      }
    }
  end

  defp semantic_change_value do
    %{
      "anyOf" => [
        %{"type" => "string"},
        %{"type" => "number"},
        %{"type" => "integer"},
        %{"type" => "boolean"},
        %{"type" => "array"},
        %{"type" => "object"},
        %{"type" => "null"}
      ]
    }
  end

  defp stable_id_array_schema(stable_id_pattern) do
    %{"type" => "array", "items" => %{"type" => "string", "pattern" => stable_id_pattern}}
  end

  defp stable_id_property(opts) do
    %{"type" => "string", "pattern" => Keyword.fetch!(opts, :stable_id_pattern)}
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end

  defp non_negative_integer_schema do
    %{"type" => "integer", "minimum" => 0}
  end

  defp non_negative_number_schema do
    %{"type" => "number", "minimum" => 0}
  end

  defp object_schema do
    %{"type" => "object", "additionalProperties" => true}
  end

  defp string_array_schema do
    %{"type" => "array", "items" => %{"type" => "string"}}
  end
end
