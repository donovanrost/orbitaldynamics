defmodule OrbitalDynamics.Schema.ContactFilterReportJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @count_fields [
    "input_candidate_count",
    "kept_candidate_count",
    "suppressed_candidate_count",
    "invalid_contact_input_count",
    "duplicate_suppressed_candidate_row_count",
    "duplicate_suppressed_candidate_id_count"
  ]

  @count_map_fields [
    "suppression_reason_counts",
    "station_reservation_match_status_counts"
  ]

  @string_list_map_fields [
    "suppressed_candidate_ids_by_reason",
    "suppressed_candidate_ids_by_reservation_match_status",
    "suppressed_candidate_ids_by_station_calendar_trust_boundary_status"
  ]

  def property_field?(field)
      when field in [
             "invalid_contact_input_ids",
             "station_calendar_trust_boundary_status_counts",
             "model_limits",
             "model",
             "assumptions",
             "suppressed_candidates"
           ],
      do: true

  def property_field?(field)
      when field in @count_fields or field in @count_map_fields or
             field in @string_list_map_fields,
      do: true

  def property_field?(_field), do: false

  def property_fun_from_context(deps) when is_list(deps) do
    fn field -> property_from_context(field, deps) end
  end

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property_opts("invalid_contact_input_ids", deps) do
    [stable_id_pattern: fetch_dep!(deps, :stable_id_pattern)]
  end

  def property_opts("station_calendar_trust_boundary_status_counts", deps) do
    [trust_boundary_count_map_schema: fetch_dep!(deps, :trust_boundary_count_map_schema)]
  end

  def property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts("assumptions", deps) do
    [assumptions_schema: fetch_dep!(deps, :assumptions_schema)]
  end

  def property_opts("suppressed_candidates", deps) do
    [suppressed_candidate_schema: fetch_dep!(deps, :suppressed_candidate_schema)]
  end

  def property_opts(_field, _deps), do: []

  def property("invalid_contact_input_ids", opts) do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("station_calendar_trust_boundary_status_counts", opts) do
    Keyword.fetch!(opts, :trust_boundary_count_map_schema)
  end

  def property(field, _opts) when field in @count_map_fields do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def property(field, _opts) when field in @string_list_map_fields do
    CommonJsonSchema.string_list_map()
  end

  def property("model_limits", opts) do
    %{
      "type" => "array",
      "items" => %{"type" => "string", "enum" => Keyword.fetch!(opts, :model_limits)}
    }
  end

  def property("model", _opts) do
    %{
      "type" => "string",
      "const" => "thin_ground_network_availability_filter"
    }
  end

  def property("assumptions", opts) do
    Keyword.fetch!(opts, :assumptions_schema)
  end

  def property("suppressed_candidates", opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :suppressed_candidate_schema)}
  end

  def assumptions_from_deps(deps) do
    deps
    |> assumptions_opts()
    |> assumptions()
  end

  def assumptions_from_context(
        suppressed_directions,
        suppression_reasons,
        station_unavailable_aliases,
        station_availability_precedence,
        station_capacity_value_paths,
        contact_capacity_value_paths,
        provider_direction_aliases
      ) do
    [
      suppressed_directions: suppressed_directions,
      suppression_reasons: suppression_reasons,
      station_unavailable_aliases: station_unavailable_aliases,
      station_availability_precedence: station_availability_precedence,
      station_capacity_value_paths: station_capacity_value_paths,
      contact_capacity_value_paths: contact_capacity_value_paths,
      provider_direction_aliases: provider_direction_aliases
    ]
    |> assumptions_opts()
    |> assumptions()
  end

  def assumptions(opts) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["execution_boundary", "operator_authority"],
      "properties" => %{
        "execution_boundary" => %{
          "type" => "string",
          "const" => "artifact_only_no_provider_reservation_or_schedule_mutation"
        },
        "operator_authority" => %{"type" => "string", "const" => "not_granted_by_filter"},
        "suppressed_directions" => enum_array_const(Keyword.fetch!(opts, :suppressed_directions)),
        "suppression_reasons" => enum_array_const(Keyword.fetch!(opts, :suppression_reasons)),
        "station_unavailable_aliases" =>
          enum_array_const(Keyword.fetch!(opts, :station_unavailable_aliases)),
        "station_availability_precedence" => %{
          "type" => "object",
          "const" => Keyword.fetch!(opts, :station_availability_precedence),
          "additionalProperties" => %{"type" => "integer", "minimum" => 0}
        },
        "station_capacity_value_paths" => %{
          "type" => "array",
          "const" => Keyword.fetch!(opts, :station_capacity_value_paths),
          "items" => capacity_value_path()
        },
        "contact_capacity_value_paths" => %{
          "type" => "array",
          "const" => Keyword.fetch!(opts, :contact_capacity_value_paths),
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
        "path" => CommonJsonSchema.string_array()
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
      suppressed_directions: fetch_dep!(deps, :suppressed_directions),
      suppression_reasons: fetch_dep!(deps, :suppression_reasons),
      station_unavailable_aliases: fetch_dep!(deps, :station_unavailable_aliases),
      station_availability_precedence: fetch_dep!(deps, :station_availability_precedence),
      station_capacity_value_paths:
        capacity_value_path_assumptions(fetch_dep!(deps, :station_capacity_value_paths)),
      contact_capacity_value_paths:
        capacity_value_path_assumptions(fetch_dep!(deps, :contact_capacity_value_paths)),
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
