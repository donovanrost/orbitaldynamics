defmodule OrbitalDynamics.Schema.OperatorReviewPackageJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @enum_count_fields [
    "review_type_counts",
    "cadence_import_status_counts",
    "source_cadence_import_status_counts",
    "replacement_cadence_import_status_counts"
  ]

  @non_negative_count_map_fields [
    "review_queue_counts",
    "approval_status_counts",
    "required_operator_action_counts"
  ]

  @readiness_scalar_fields [
    "source_readiness_report_id",
    "readiness_level",
    "import_classification",
    "status"
  ]

  @review_import_count_map_fields [
    "calendar_entry_trust_boundary_status_counts",
    "station_reservation_match_status_counts",
    "station_reservation_expiration_status_counts",
    "resource_blocking_dimension_counts",
    "gate_status_counts",
    "gate_classification_counts",
    "required_capacity_fraction_source_counts",
    "provider_reservation_request_status_counts",
    "reduced_capacity_pack_status_counts",
    "station_pressure_contact_counts_by_ground_station_id",
    "station_pressure_contact_counts_by_availability",
    "station_pressure_contact_counts_by_precedence_availability",
    "station_pressure_contact_counts_by_precedence_rank"
  ]

  @review_import_scalar_count_fields [
    "station_reservation_declared_expiration_contact_count",
    "station_reservation_missing_expiration_contact_count",
    "station_pressure_contact_count",
    "station_pressure_review_contact_count",
    "provider_reservation_candidate_contact_count",
    "provider_reservation_request_contact_count",
    "provider_reservation_review_contact_count",
    "provider_reservation_no_request_contact_count",
    "gate_count",
    "passed_gate_count",
    "review_gate_count",
    "analysis_gate_count",
    "blocked_gate_count"
  ]

  @capacity_fraction_fields [
    "capacity_pack_required_capacity_fraction",
    "capacity_pack_selected_required_capacity_fraction",
    "capacity_pack_deferred_required_capacity_fraction"
  ]

  @capacity_fraction_map_fields [
    "capacity_pack_required_capacity_fraction_by_status",
    "capacity_pack_required_capacity_fraction_by_ground_station_id",
    "capacity_pack_selected_required_capacity_fraction_by_ground_station_id",
    "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id"
  ]

  @stable_id_array_fields [
    "station_reservation_ids",
    "station_pressure_contact_ids",
    "station_pressure_review_contact_ids",
    "capacity_pack_group_ids",
    "provider_reservation_request_contact_ids",
    "provider_reservation_review_contact_ids",
    "provider_reservation_no_request_contact_ids",
    "passed_gate_ids",
    "review_required_gate_ids",
    "analysis_only_gate_ids",
    "blocked_gate_ids",
    "reduced_capacity_packed_contact_ids",
    "reduced_capacity_deferred_contact_ids"
  ]

  @stable_id_array_map_fields [
    "station_reservation_contact_ids_by_expiration_status",
    "station_reservation_ids_by_expiration_status",
    "station_reservation_contact_ids_by_match_status",
    "station_reservation_contact_ids_by_status",
    "station_reservation_contact_ids_by_reserved_by",
    "station_reservation_ids_by_match_status",
    "station_reservation_ids_by_status",
    "station_reservation_ids_by_reserved_by",
    "resource_blocked_contact_ids_by_blocking_dimension",
    "resource_blocked_contact_ids_by_spacecraft_id",
    "capacity_pack_contact_ids_by_status",
    "capacity_pack_contact_ids_by_ground_station_id",
    "capacity_pack_selected_contact_ids_by_ground_station_id",
    "capacity_pack_deferred_contact_ids_by_ground_station_id",
    "required_capacity_fraction_contact_ids_by_source",
    "provider_reservation_request_contact_ids_by_ground_station_id",
    "provider_reservation_review_contact_ids_by_ground_station_id",
    "provider_reservation_no_request_contact_ids_by_direction",
    "provider_reservation_request_contact_ids_by_direction",
    "provider_reservation_review_contact_ids_by_direction",
    "reservation_conflict_contact_ids_by_direction",
    "provider_reservation_request_contact_ids_by_match_status",
    "provider_reservation_review_contact_ids_by_match_status",
    "provider_reservation_request_ids_by_match_status",
    "provider_reservation_review_ids_by_match_status",
    "gate_ids_by_status",
    "gate_ids_by_classification",
    "quality_gate_row_ids_by_status",
    "quality_gate_row_ids_by_classification",
    "capacity_pack_group_ids_by_status",
    "station_pressure_contact_ids_by_ground_station_id",
    "station_pressure_contact_ids_by_availability",
    "station_pressure_contact_ids_by_precedence_availability",
    "station_pressure_contact_ids_by_precedence_rank",
    "station_pressure_contact_ids_by_direction"
  ]

  @nested_stable_id_array_map_fields [
    "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id",
    "provider_reservation_request_contact_ids_by_direction_and_ground_station_id",
    "provider_reservation_review_contact_ids_by_direction_and_ground_station_id",
    "reservation_conflict_contact_ids_by_direction_and_ground_station_id"
  ]

  @string_array_fields [
    "station_reserved_bys",
    "station_reservation_statuses"
  ]

  @base_fields [
    "rows",
    "source_artifact_type",
    "model",
    "model_limits"
  ]

  def property_field?(field, scalar_count_fields) do
    field in @base_fields or field in scalar_count_fields or field in @enum_count_fields or
      field in @non_negative_count_map_fields or field in @readiness_scalar_fields or
      field in @review_import_count_map_fields or field in @review_import_scalar_count_fields or
      field in @capacity_fraction_fields or field in @capacity_fraction_map_fields or
      field in @stable_id_array_fields or field in @stable_id_array_map_fields or
      field in @nested_stable_id_array_map_fields or field in @string_array_fields or
      field == "earliest_station_reservation_expires_at_s"
  end

  def property_opts("source_readiness_report_id", deps) do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts(field, deps)
      when field in ["readiness_level", "import_classification", "status"] do
    [readiness_capability: fetch_dep!(deps, :readiness_capability)]
  end

  def property_opts(field, deps)
      when field in @stable_id_array_fields or field in @stable_id_array_map_fields or
             field in @nested_stable_id_array_map_fields do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts("rows", deps) do
    [row_schema: fetch_dep!(deps, :row_schema)]
  end

  def property_opts("source_artifact_type", deps) do
    [capability: fetch_dep!(deps, :capability)]
  end

  def property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts(field, deps) when field in @enum_count_fields do
    [capability: fetch_dep!(deps, :capability)]
  end

  def property_opts(field, deps) do
    scalar_count_fields = fetch_dep!(deps, :scalar_count_fields)

    if field in scalar_count_fields do
      [scalar_count_fields: scalar_count_fields]
    else
      []
    end
  end

  def property_fun_from_context(deps) when is_list(deps) do
    fn field -> property_from_context(field, deps) end
  end

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property("source_readiness_report_id", opts) do
    %{"type" => "string", "pattern" => Keyword.fetch!(opts, :stable_id_pattern)}
  end

  def property("readiness_level", opts) do
    %{
      "type" => "string",
      "enum" => Keyword.fetch!(opts, :readiness_capability).readiness_levels
    }
  end

  def property("import_classification", opts) do
    %{
      "type" => "string",
      "enum" => Keyword.fetch!(opts, :readiness_capability).import_classifications
    }
  end

  def property("status", opts) do
    %{
      "type" => "string",
      "enum" => Keyword.fetch!(opts, :readiness_capability).gate_statuses
    }
  end

  def property(field, _opts) when field in @review_import_count_map_fields do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def property(field, _opts) when field in @review_import_scalar_count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, _opts) when field in @capacity_fraction_fields do
    %{"type" => "number", "minimum" => 0.0}
  end

  def property(field, _opts) when field in @capacity_fraction_map_fields do
    CommonJsonSchema.non_negative_number_map()
  end

  def property("earliest_station_reservation_expires_at_s", _opts) do
    %{"type" => "number"}
  end

  def property(field, opts) when field in @stable_id_array_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property(field, opts) when field in @stable_id_array_map_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array_map()
  end

  def property(field, opts) when field in @nested_stable_id_array_map_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.nested_stable_id_array_map()
  end

  def property(field, _opts) when field in @string_array_fields do
    CommonJsonSchema.string_array()
  end

  def property("rows", opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :row_schema)}
  end

  def property("source_artifact_type", opts) do
    capability = Keyword.fetch!(opts, :capability)

    %{
      "type" => "string",
      "enum" => capability.source_artifact_types
    }
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_operator_review_package"}
  end

  def property("model_limits", opts) do
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

  def property(field, _opts) when field in @non_negative_count_map_fields do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def property(field, opts) when field in @enum_count_fields do
    opts
    |> Keyword.fetch!(:capability)
    |> enum_count_values(field)
    |> CommonJsonSchema.enum_count_map()
  end

  def property(field, opts) do
    scalar_count_fields = Keyword.fetch!(opts, :scalar_count_fields)

    if field in scalar_count_fields do
      %{"type" => "integer", "minimum" => 0}
    else
      raise ArgumentError, "unknown operator review package JSON Schema property: #{field}"
    end
  end

  defp enum_count_values(capability, "review_type_counts"), do: capability.review_types

  defp enum_count_values(capability, "cadence_import_status_counts"),
    do: capability.cadence_import_statuses

  defp enum_count_values(capability, "source_cadence_import_status_counts"),
    do: capability.cadence_import_statuses

  defp enum_count_values(capability, "replacement_cadence_import_status_counts"),
    do: capability.cadence_import_statuses

  defp fetch_dep!(deps, key), do: Keyword.fetch!(deps, key)
end
