defmodule OrbitalDynamics.Schema.ContactAllocationProviderReservationRequestSummaryJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.{CommonJsonSchema, ContactAllocationCapabilityContext}

  @row_fields [
    "rows",
    "provider_reservation_request_rows",
    "provider_reservation_review_rows"
  ]

  @count_fields [
    "input_contact_count",
    "provider_reservation_candidate_contact_count",
    "provider_reservation_request_contact_count",
    "provider_reservation_review_contact_count",
    "provider_reservation_no_request_contact_count"
  ]

  @stable_id_array_fields [
    "provider_reservation_request_contact_ids",
    "provider_reservation_review_contact_ids",
    "provider_reservation_no_request_contact_ids"
  ]

  @stable_id_array_map_fields [
    "provider_reservation_request_contact_ids_by_ground_station_id",
    "provider_reservation_review_contact_ids_by_ground_station_id",
    "provider_reservation_no_request_contact_ids_by_direction",
    "provider_reservation_request_contact_ids_by_direction",
    "provider_reservation_review_contact_ids_by_direction",
    "provider_reservation_request_contact_ids_by_match_status",
    "provider_reservation_review_contact_ids_by_match_status",
    "provider_reservation_request_ids_by_match_status",
    "provider_reservation_review_ids_by_match_status"
  ]

  @match_status_route_fields [
    "provider_reservation_request_contact_ids_by_match_status",
    "provider_reservation_review_contact_ids_by_match_status",
    "provider_reservation_request_ids_by_match_status",
    "provider_reservation_review_ids_by_match_status"
  ]

  @nested_stable_id_array_map_fields [
    "provider_reservation_no_request_contact_ids_by_direction_and_ground_station_id",
    "provider_reservation_request_contact_ids_by_direction_and_ground_station_id",
    "provider_reservation_review_contact_ids_by_direction_and_ground_station_id"
  ]

  def property_field?(field)
      when field in [
             "schema_contract",
             "source_artifact_type",
             "model",
             "source",
             "model_limits",
             "assumptions",
             "provider_reservation_request_status"
           ],
      do: true

  def property_field?(field)
      when field in @row_fields or field in @count_fields or
             field in @stable_id_array_fields or field in @stable_id_array_map_fields or
             field in @nested_stable_id_array_map_fields,
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

  def property_opts(field, deps) when field in @row_fields do
    [row_schema: fetch_dep!(deps, :row_schema)]
  end

  def property_opts(field, deps)
      when field in @stable_id_array_fields or field in @stable_id_array_map_fields or
             field in @nested_stable_id_array_map_fields do
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
    %{
      "type" => "string",
      "const" => "artifact_only_contact_allocation_provider_reservation_request_summary"
    }
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

  def property(field, opts) when field in @row_fields do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :row_schema)}
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("provider_reservation_request_status", _opts) do
    %{"type" => "string", "enum" => ["clear", "request_ready", "review_required"]}
  end

  def property(field, opts) when field in @stable_id_array_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property(field, opts) when field in @match_status_route_fields do
    match_statuses =
      ContactAllocationCapabilityContext.contact_allocation_capabilities()
      |> Map.fetch!(:station_reservation_match_statuses)

    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.enum_stable_id_array_map(match_statuses)
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

  def assumptions_from_deps(deps) do
    deps
    |> assumptions_opts()
    |> assumptions()
  end

  def assumptions_from_context(
        provider_reservation_request_statuses,
        station_reservation_match_statuses,
        provider_direction_aliases
      ) do
    [
      provider_reservation_request_statuses: provider_reservation_request_statuses,
      station_reservation_match_statuses: station_reservation_match_statuses,
      provider_direction_aliases: provider_direction_aliases
    ]
    |> assumptions_opts()
    |> assumptions()
  end

  def assumptions(opts) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "execution_boundary",
        "source",
        "provider_reservation_execution",
        "operator_authority"
      ],
      "properties" => %{
        "execution_boundary" => %{
          "type" => "string",
          "const" => "artifact_only_no_provider_reservation_or_schedule_mutation"
        },
        "source" => %{"type" => "string", "const" => "contact_allocation_report.v1"},
        "provider_reservation_execution" => %{
          "type" => "string",
          "const" => "not_performed_by_summary"
        },
        "operator_authority" => %{
          "type" => "string",
          "const" => "not_granted_by_provider_reservation_request_summary"
        },
        "provider_reservation_request_statuses" =>
          enum_array_const(Keyword.fetch!(opts, :provider_reservation_request_statuses)),
        "station_reservation_match_statuses" =>
          enum_array_const(Keyword.fetch!(opts, :station_reservation_match_statuses)),
        "provider_direction_aliases" => %{
          "type" => "object",
          "const" => Keyword.fetch!(opts, :provider_direction_aliases),
          "additionalProperties" => %{"type" => "string"}
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
      provider_reservation_request_statuses:
        fetch_dep!(deps, :provider_reservation_request_statuses),
      station_reservation_match_statuses: fetch_dep!(deps, :station_reservation_match_statuses),
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
