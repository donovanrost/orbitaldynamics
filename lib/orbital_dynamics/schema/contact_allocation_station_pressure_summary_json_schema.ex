defmodule OrbitalDynamics.Schema.ContactAllocationStationPressureSummaryJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @count_fields [
    "input_contact_count",
    "station_pressure_contact_count",
    "station_pressure_review_contact_count"
  ]

  @stable_id_array_fields [
    "station_pressure_contact_ids",
    "station_pressure_review_contact_ids"
  ]

  @stable_id_array_map_fields [
    "station_pressure_contact_ids_by_ground_station_id",
    "station_pressure_contact_ids_by_availability",
    "station_pressure_contact_ids_by_precedence_availability",
    "station_pressure_contact_ids_by_precedence_rank",
    "station_pressure_contact_ids_by_status"
  ]

  @count_map_fields [
    "station_pressure_contact_counts_by_ground_station_id",
    "station_pressure_contact_counts_by_availability",
    "station_pressure_contact_counts_by_precedence_availability",
    "station_pressure_contact_counts_by_precedence_rank",
    "station_pressure_contact_counts_by_status"
  ]

  def property_field?(field)
      when field in [
             "schema_contract",
             "source_artifact_type",
             "model",
             "source",
             "assumptions",
             "model_limits",
             "rows",
             "review_rows",
             "station_pressure_contact_ids_by_direction_and_ground_station_id"
           ],
      do: true

  def property_field?(field)
      when field in @count_fields or field in @stable_id_array_fields or
             field in @stable_id_array_map_fields or field in @count_map_fields,
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

  def property_opts("station_pressure_contact_ids_by_direction_and_ground_station_id", deps) do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts(field, deps)
      when field in @stable_id_array_fields or field in @stable_id_array_map_fields do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts(_field, _deps), do: []

  def property("schema_contract", opts) do
    %{"type" => "string", "const" => Keyword.fetch!(opts, :schema_contract)}
  end

  def property("source_artifact_type", _opts) do
    %{"type" => "string", "enum" => ["contact_allocation_report.v1"]}
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_contact_allocation_station_pressure_summary"}
  end

  def property("source", _opts) do
    %{"type" => "string"}
  end

  def property("assumptions", opts) do
    Keyword.fetch!(opts, :assumptions_schema)
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property(field, opts) when field in ["rows", "review_rows"] do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :row_schema)}
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, opts) when field in @stable_id_array_fields do
    stable_id_array(opts)
  end

  def property(field, opts) when field in @stable_id_array_map_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array_map()
  end

  def property("station_pressure_contact_ids_by_direction_and_ground_station_id", opts) do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.nested_stable_id_array_map()
  end

  def property(field, _opts) when field in @count_map_fields do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def assumptions_from_deps(deps) do
    deps
    |> assumptions_opts()
    |> assumptions()
  end

  def assumptions_from_context(
        station_unavailable_aliases,
        station_blocking_availability,
        station_availability_precedence,
        provider_direction_aliases
      ) do
    [
      station_unavailable_aliases: station_unavailable_aliases,
      station_blocking_availability: station_blocking_availability,
      station_availability_precedence: station_availability_precedence,
      provider_direction_aliases: provider_direction_aliases
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
          "const" => "not_granted_by_station_pressure_summary"
        },
        "station_unavailable_aliases" =>
          enum_array_const(Keyword.fetch!(opts, :station_unavailable_aliases)),
        "station_blocking_availability" =>
          enum_array_const(Keyword.fetch!(opts, :station_blocking_availability)),
        "station_availability_precedence" => %{
          "type" => "object",
          "const" => Keyword.fetch!(opts, :station_availability_precedence),
          "additionalProperties" => %{"type" => "integer", "minimum" => 0}
        },
        "provider_direction_aliases" => %{
          "type" => "object",
          "const" => Keyword.fetch!(opts, :provider_direction_aliases),
          "additionalProperties" => %{"type" => "string"}
        }
      }
    }
  end

  defp stable_id_array(opts) do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
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
      station_unavailable_aliases: fetch_dep!(deps, :station_unavailable_aliases),
      station_blocking_availability: fetch_dep!(deps, :station_blocking_availability),
      station_availability_precedence: fetch_dep!(deps, :station_availability_precedence),
      provider_direction_aliases: fetch_dep!(deps, :provider_direction_aliases)
    ]
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
