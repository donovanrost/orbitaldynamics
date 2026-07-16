defmodule OrbitalDynamics.Schema.RelayDataPathSummaryJsonSchema do
  @moduledoc false

  @summary "relay_data_path_summary.v1"

  @integer_fields [
    "route_count",
    "relay_route_count",
    "direct_downlink_route_count"
  ]

  @number_fields [
    "maximum_latency_s",
    "maximum_latency_limit_s"
  ]

  @count_map_fields [
    "custody_status_counts",
    "latency_status_counts",
    "risk_status_counts"
  ]

  @stable_id_array_fields [
    "route_ids",
    "source_spacecraft_ids",
    "relay_spacecraft_ids",
    "ground_station_ids",
    "ground_downlink_contact_ids"
  ]

  @stable_id_array_map_fields [
    "route_ids_by_custody_status",
    "route_ids_by_latency_status",
    "route_ids_by_risk_status",
    "route_ids_by_ground_station_id"
  ]

  def property_field?(field)
      when field in [
             "schema_contract",
             "schema_version",
             "model",
             "source",
             "model_limits",
             "assumptions",
             "rows"
           ],
      do: true

  def property_field?(field)
      when field in @integer_fields or field in @number_fields or field in @count_map_fields or
             field in @stable_id_array_fields or field in @stable_id_array_map_fields,
      do: true

  def property_field?(_field), do: false

  def property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts("assumptions", deps) do
    [assumptions_schema: fetch_dep!(deps, :assumptions_schema)]
  end

  def property_opts("rows", deps) do
    [row_schema: fetch_dep!(deps, :row_schema)]
  end

  def property_opts(field, deps) when field in @count_map_fields do
    [count_map_schema: fetch_dep!(deps, :count_map_schema)]
  end

  def property_opts(field, deps) when field in @stable_id_array_fields do
    [stable_id_array_schema: fetch_dep!(deps, :stable_id_array_schema)]
  end

  def property_opts(field, deps) when field in @stable_id_array_map_fields do
    [stable_id_array_map_schema: fetch_dep!(deps, :stable_id_array_map_schema)]
  end

  def property_opts(_field, _deps), do: []

  def property_fun_from_context(deps) when is_list(deps) do
    fn field -> property_from_context(field, deps) end
  end

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property("schema_contract", _opts) do
    %{"type" => "string", "const" => @summary}
  end

  def property("schema_version", _opts) do
    %{"type" => "integer", "const" => 1}
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_relay_data_path_summary"}
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

  def property("assumptions", opts) do
    Keyword.fetch!(opts, :assumptions_schema)
  end

  def property("rows", opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :row_schema)}
  end

  def property(field, _opts) when field in @integer_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property(field, _opts) when field in @number_fields do
    %{"type" => "number"}
  end

  def property(field, opts) when field in @count_map_fields do
    Keyword.fetch!(opts, :count_map_schema)
  end

  def property(field, opts) when field in @stable_id_array_fields do
    Keyword.fetch!(opts, :stable_id_array_schema)
  end

  def property(field, opts) when field in @stable_id_array_map_fields do
    Keyword.fetch!(opts, :stable_id_array_map_schema)
  end

  def row_from_deps(deps) do
    deps
    |> row_opts()
    |> row()
  end

  def row_from_context(
        stable_id_pattern,
        stable_id_array_schema,
        string_array_schema,
        custody_statuses,
        latency_statuses,
        risk_statuses
      ) do
    [
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: stable_id_array_schema,
      string_array_schema: string_array_schema,
      custody_statuses: custody_statuses,
      latency_statuses: latency_statuses,
      risk_statuses: risk_statuses
    ]
    |> row_opts()
    |> row()
  end

  def row(opts) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "route_id",
        "source_spacecraft_id",
        "relay_chain_spacecraft_ids",
        "relay_hop_count",
        "ground_station_id",
        "ground_downlink_contact_id",
        "custody_status",
        "latency_status",
        "risk_status",
        "risk_reasons",
        "product_ids",
        "collection_ids"
      ],
      "properties" => row_properties(opts)
    }
  end

  def assumptions do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "execution_boundary",
        "crosslink_visibility_model",
        "custody_acknowledgement_delivery",
        "provider_reservation",
        "operator_authority"
      ],
      "properties" => %{
        "execution_boundary" => %{
          "type" => "string",
          "const" => "artifact_only_no_relay_scheduling_or_schedule_mutation"
        },
        "crosslink_visibility_model" => %{"type" => "string", "const" => "not_evaluated"},
        "custody_acknowledgement_delivery" => %{
          "type" => "string",
          "const" => "not_performed"
        },
        "provider_reservation" => %{"type" => "string", "const" => "not_performed"},
        "operator_authority" => %{"type" => "string", "const" => "not_granted_by_summary"}
      }
    }
  end

  defp row_properties(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    stable_id_array_schema = Keyword.fetch!(opts, :stable_id_array_schema)

    %{
      "route_id" => stable_id_schema(stable_id_pattern),
      "source_spacecraft_id" => stable_id_schema(stable_id_pattern),
      "relay_chain_spacecraft_ids" => stable_id_array_schema,
      "relay_hop_count" => %{"type" => "integer", "minimum" => 0},
      "ground_station_id" => stable_id_schema(stable_id_pattern),
      "ground_downlink_contact_id" => stable_id_schema(stable_id_pattern),
      "custody_status" => %{"type" => "string", "enum" => Keyword.fetch!(opts, :custody_statuses)},
      "latency_s" => %{"type" => "number"},
      "latency_limit_s" => %{"type" => "number"},
      "latency_status" => %{"type" => "string", "enum" => Keyword.fetch!(opts, :latency_statuses)},
      "risk_status" => %{"type" => "string", "enum" => Keyword.fetch!(opts, :risk_statuses)},
      "risk_reasons" => Keyword.fetch!(opts, :string_array_schema),
      "product_ids" => stable_id_array_schema,
      "collection_ids" => stable_id_array_schema
    }
  end

  defp stable_id_schema(stable_id_pattern) do
    %{"type" => "string", "pattern" => stable_id_pattern}
  end

  defp row_opts(deps) do
    [
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern),
      stable_id_array_schema: fetch_dep!(deps, :stable_id_array_schema),
      string_array_schema: fetch_dep!(deps, :string_array_schema),
      custody_statuses: fetch_dep!(deps, :custody_statuses),
      latency_statuses: fetch_dep!(deps, :latency_statuses),
      risk_statuses: fetch_dep!(deps, :risk_statuses)
    ]
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
