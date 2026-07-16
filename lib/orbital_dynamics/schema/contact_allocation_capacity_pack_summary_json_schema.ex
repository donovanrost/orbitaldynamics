defmodule OrbitalDynamics.Schema.ContactAllocationCapacityPackSummaryJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @count_fields [
    "input_contact_count",
    "capacity_pack_contact_count",
    "reduced_capacity_pack_group_count"
  ]

  @count_map_fields [
    "reduced_capacity_pack_status_counts",
    "capacity_pack_status_counts",
    "required_capacity_fraction_source_counts"
  ]

  @stable_id_array_map_fields [
    "capacity_pack_contact_ids_by_status",
    "capacity_pack_contact_ids_by_ground_station_id",
    "capacity_pack_selected_contact_ids_by_ground_station_id",
    "capacity_pack_deferred_contact_ids_by_ground_station_id",
    "capacity_pack_contact_ids_by_direction",
    "capacity_pack_selected_contact_ids_by_direction",
    "capacity_pack_deferred_contact_ids_by_direction",
    "required_capacity_fraction_contact_ids_by_source",
    "capacity_pack_group_ids_by_status"
  ]

  @stable_id_array_fields [
    "reduced_capacity_packed_contact_ids",
    "reduced_capacity_deferred_contact_ids",
    "capacity_pack_group_ids"
  ]

  @number_fields [
    "capacity_pack_required_capacity_fraction",
    "capacity_pack_selected_required_capacity_fraction",
    "capacity_pack_deferred_required_capacity_fraction"
  ]

  @number_map_fields [
    "capacity_pack_required_capacity_fraction_by_status",
    "capacity_pack_required_capacity_fraction_by_ground_station_id",
    "capacity_pack_selected_required_capacity_fraction_by_ground_station_id",
    "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id",
    "capacity_pack_required_capacity_fraction_by_direction",
    "capacity_pack_selected_required_capacity_fraction_by_direction",
    "capacity_pack_deferred_required_capacity_fraction_by_direction"
  ]

  def property_field?(field)
      when field in [
             "schema_contract",
             "model",
             "model_limits",
             "assumptions",
             "source_artifact_type",
             "source",
             "rows",
             "review_rows",
             "reduced_capacity_pack_groups",
             "capacity_pack_review_status"
           ],
      do: true

  def property_field?(field)
      when field in @count_fields or field in @count_map_fields or
             field in @stable_id_array_map_fields or field in @stable_id_array_fields or
             field in @number_fields or field in @number_map_fields,
      do: true

  def property_field?(_field), do: false

  def property_fun_from_context(deps) when is_list(deps) do
    fn field -> property_from_context(field, deps) end
  end

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property_opts("schema_contract", deps) do
    [schema_contract: fetch_dep!(deps, :schema_contract)]
  end

  def property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts("assumptions", deps) do
    [assumptions_schema: fetch_dep!(deps, :assumptions_schema)]
  end

  def property_opts(field, deps) when field in ["rows", "review_rows"] do
    [row_schema: fetch_dep!(deps, :row_schema)]
  end

  def property_opts("reduced_capacity_pack_groups", deps) do
    [capacity_pack_group_schema: fetch_dep!(deps, :capacity_pack_group_schema)]
  end

  def property_opts(field, deps)
      when field in @stable_id_array_map_fields or field in @stable_id_array_fields do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts(_field, _deps), do: []

  def property("schema_contract", opts) do
    %{"type" => "string", "const" => Keyword.fetch!(opts, :schema_contract)}
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_contact_allocation_capacity_pack_summary"}
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

  def property("source_artifact_type", _opts) do
    %{"type" => "string", "enum" => ["contact_allocation_report.v1"]}
  end

  def property("source", _opts) do
    %{"type" => "string"}
  end

  def property(field, opts) when field in ["rows", "review_rows"] do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :row_schema)}
  end

  def property("reduced_capacity_pack_groups", opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :capacity_pack_group_schema)}
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("capacity_pack_review_status", _opts) do
    %{"type" => "string", "enum" => ["clear", "review_required"]}
  end

  def property(field, _opts) when field in @count_map_fields do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def property(field, opts) when field in @stable_id_array_map_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array_map()
  end

  def property(field, opts) when field in @stable_id_array_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property(field, _opts) when field in @number_fields do
    %{"type" => "number", "minimum" => 0.0}
  end

  def property(field, _opts) when field in @number_map_fields do
    CommonJsonSchema.non_negative_number_map()
  end

  def assumptions_from_deps(deps) do
    deps
    |> assumptions_opts()
    |> assumptions()
  end

  def assumptions_from_context(
        capacity_pack_statuses,
        reduced_capacity_pack_statuses,
        required_capacity_fraction_source_values,
        required_capacity_value_paths,
        default_required_capacity_value_paths
      ) do
    [
      capacity_pack_statuses: capacity_pack_statuses,
      reduced_capacity_pack_statuses: reduced_capacity_pack_statuses,
      required_capacity_fraction_source_values: required_capacity_fraction_source_values,
      required_capacity_value_paths: required_capacity_value_paths,
      default_required_capacity_value_paths: default_required_capacity_value_paths
    ]
    |> assumptions_opts()
    |> assumptions()
  end

  def assumptions(opts) do
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
        "operator_authority" => %{
          "type" => "string",
          "const" => "not_granted_by_capacity_pack_summary"
        },
        "capacity_pack_statuses" =>
          enum_array_const(Keyword.fetch!(opts, :capacity_pack_statuses)),
        "reduced_capacity_pack_statuses" =>
          enum_array_const(Keyword.fetch!(opts, :reduced_capacity_pack_statuses)),
        "required_capacity_fraction_source_values" =>
          enum_array_const(Keyword.fetch!(opts, :required_capacity_fraction_source_values)),
        "required_capacity_value_paths" => %{
          "type" => "array",
          "const" => Keyword.fetch!(opts, :required_capacity_value_paths),
          "items" =>
            OrbitalDynamics.Schema.ContactAllocationReportJsonSchema.capacity_value_path()
        },
        "default_required_capacity_value_paths" => %{
          "type" => "array",
          "const" => Keyword.fetch!(opts, :default_required_capacity_value_paths),
          "items" =>
            OrbitalDynamics.Schema.ContactAllocationReportJsonSchema.capacity_value_path()
        }
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
      capacity_pack_statuses: fetch_dep!(deps, :capacity_pack_statuses),
      reduced_capacity_pack_statuses: fetch_dep!(deps, :reduced_capacity_pack_statuses),
      required_capacity_fraction_source_values:
        fetch_dep!(deps, :required_capacity_fraction_source_values),
      required_capacity_value_paths:
        capacity_value_path_assumptions(fetch_dep!(deps, :required_capacity_value_paths)),
      default_required_capacity_value_paths:
        capacity_value_path_assumptions(fetch_dep!(deps, :default_required_capacity_value_paths))
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
