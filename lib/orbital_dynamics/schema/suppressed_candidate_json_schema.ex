defmodule OrbitalDynamics.Schema.SuppressedCandidateJsonSchema do
  @moduledoc false

  def schema_from_context(
        stable_id_pattern,
        stable_id_array_schema,
        string_array_schema,
        suppression_reasons,
        policy_decision_schema
      ) do
    schema(
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: stable_id_array_schema,
      string_array_schema: string_array_schema,
      suppression_reasons: suppression_reasons,
      policy_decision_schema: policy_decision_schema
    )
  end

  def schema_from_context(deps) when is_list(deps) do
    schema(
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern),
      stable_id_array_schema: fetch_dep!(deps, :stable_id_array_schema),
      string_array_schema: fetch_dep!(deps, :string_array_schema),
      suppression_reasons: fetch_dep!(deps, :suppression_reasons),
      policy_decision_schema: fetch_dep!(deps, :policy_decision_schema)
    )
  end

  def schema(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["id", "type", "scenario_id", "suppressed_reason"],
      "properties" => %{
        "id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "type" => %{"type" => "string"},
        "scenario_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "spacecraft_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "suppressed_reason" => %{
          "type" => "string",
          "enum" => Keyword.fetch!(opts, :suppression_reasons)
        },
        "starts_at_s" => %{"type" => "number"},
        "ends_at_s" => %{"type" => "number"},
        "capacity_fraction" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0},
        "source_window_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "ground_station_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "station_calendar_entry_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "station_calendar_provider_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "station_calendar_provider_entry_id" => %{
          "type" => "string",
          "pattern" => stable_id_pattern
        },
        "station_calendar_status" => %{"type" => "string"},
        "station_calendar_precedence_rank" => %{"type" => "integer", "minimum" => 0},
        "station_calendar_precedence_availability" => %{"type" => "string"},
        "station_calendar_trust_boundary_status" => %{"type" => "string"},
        "station_availability" => %{"type" => "string"},
        "station_contention_status" => %{"type" => "string"},
        "station_calendar_directions" => Keyword.fetch!(opts, :string_array_schema),
        "station_calendar_reservation_ids" => Keyword.fetch!(opts, :stable_id_array_schema),
        "station_calendar_reservation_overlap_count" => %{"type" => "integer", "minimum" => 0},
        "station_calendar_reservation_statuses" => Keyword.fetch!(opts, :string_array_schema),
        "station_calendar_reserved_by" => Keyword.fetch!(opts, :string_array_schema),
        "station_reservation_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "station_reservation_expires_at_s" => %{"type" => "number"},
        "station_reserved_by" => %{"type" => "string"},
        "station_reservation_status" => %{"type" => "string"},
        "station_reservation_match_status" => %{"type" => "string"},
        "direction" => %{"type" => "string"},
        "resource_blocking_dimension" => %{"type" => "string"},
        "resource_source_quality" => %{"type" => "string"},
        "resource_trust_boundary_status" => %{"type" => "string"},
        "source_resource_summary" => %{"type" => "object", "additionalProperties" => true},
        "fuel_margin" => %{"type" => "number"},
        "power_margin" => %{"type" => "number"},
        "storage_margin" => %{"type" => "number"},
        "downlink_margin" => %{"type" => "number"},
        "source_station_calendar_entry" => %{
          "type" => "object",
          "additionalProperties" => true
        },
        "source_station_calendar_overlaps" => %{
          "type" => "array",
          "items" => %{"type" => "object", "additionalProperties" => true}
        },
        "incompatible_activity_types" => Keyword.fetch!(opts, :string_array_schema),
        "suppressed_activity_types" => Keyword.fetch!(opts, :string_array_schema),
        "policy_decision" => Keyword.fetch!(opts, :policy_decision_schema)
      }
    }
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      value when is_function(value, 0) -> value.()
      value -> value
    end
  end
end
