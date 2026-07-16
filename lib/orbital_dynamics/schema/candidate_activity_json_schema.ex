defmodule OrbitalDynamics.Schema.CandidateActivityJsonSchema do
  @moduledoc false

  def schema_from_context(deps) when is_list(deps) do
    schema(
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern),
      stable_id_array_schema: fetch_dep!(deps, :stable_id_array_schema),
      string_array_schema: fetch_dep!(deps, :string_array_schema),
      source_window_schema: fetch_dep!(deps, :source_window_schema),
      probability_schema: fetch_dep!(deps, :probability_schema),
      number_or_string_schema: fetch_dep!(deps, :number_or_string_schema),
      activity_context_schema: fetch_dep!(deps, :activity_context_schema)
    )
  end

  def schema_from_context(
        stable_id_pattern,
        stable_id_array_schema,
        string_array_schema,
        source_window_schema,
        probability_schema,
        number_or_string_schema,
        activity_context_schema
      ) do
    schema(
      stable_id_pattern: stable_id_pattern,
      stable_id_array_schema: stable_id_array_schema,
      string_array_schema: string_array_schema,
      source_window_schema: source_window_schema,
      probability_schema: probability_schema,
      number_or_string_schema: number_or_string_schema,
      activity_context_schema: activity_context_schema
    )
  end

  def schema(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "id",
        "type",
        "scenario_id",
        "starts_at_s",
        "ends_at_s",
        "duration_s",
        "score",
        "score_terms",
        "source_window_id",
        "source_window"
      ],
      "properties" => %{
        "schema_contract" => %{"type" => "string", "const" => "candidate_activity.v1"},
        "id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "type" => %{"type" => "string"},
        "scenario_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "spacecraft_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "target_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "source_target_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "source_target" => %{"type" => "object", "additionalProperties" => true},
        "target_latitude_deg" => %{"type" => "number"},
        "target_longitude_deg" => %{"type" => "number"},
        "target_minimum_elevation_deg" => %{"type" => "number"},
        "ground_station_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "collection_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "payload_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "instrument_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "product_ids" => Keyword.fetch!(opts, :stable_id_array_schema),
        "starts_at_s" => %{"type" => "number"},
        "ends_at_s" => %{"type" => "number"},
        "duration_s" => %{"type" => "number"},
        "score" => %{"type" => "number"},
        "score_terms" => %{"type" => "object", "additionalProperties" => true},
        "source_window_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "source_window" => Keyword.fetch!(opts, :source_window_schema),
        "observation_objective_ids" => Keyword.fetch!(opts, :stable_id_array_schema),
        "observation_objective_count" => %{"type" => "integer", "minimum" => 0},
        "observation_objective_source" => %{"type" => "string"},
        "observation_objective_types" => Keyword.fetch!(opts, :string_array_schema),
        "target_priority_objective_ids" => Keyword.fetch!(opts, :stable_id_array_schema),
        "target_priority" => %{"type" => "number"},
        "target_priority_source" => %{"type" => "string"},
        "target_priority_objective_type" => %{"type" => "string"},
        "collection_latency_objective_ids" => Keyword.fetch!(opts, :stable_id_array_schema),
        "collection_latency_objective_count" => %{"type" => "integer", "minimum" => 0},
        "collection_latency_objective_source" => %{"type" => "string"},
        "collection_latency_objective_types" => Keyword.fetch!(opts, :string_array_schema),
        "required_observations" => %{"type" => "number", "minimum" => 0},
        "required_downlink_mb" => %{"type" => "number", "minimum" => 0},
        "max_latency_s" => %{"type" => "number", "minimum" => 0},
        "direction" => %{
          "type" => "string",
          "enum" => ["downlink", "uplink", "command", "tracking", "health_check"]
        },
        "estimated_throughput_mb" => %{"type" => "number"},
        "throughput_model" => %{"type" => "object", "additionalProperties" => true},
        "station_availability" => %{"type" => "string"},
        "station_contention_status" => %{"type" => "string"},
        "station_calendar_directions" => Keyword.fetch!(opts, :string_array_schema),
        "station_reservation_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "station_reservation_expires_at_s" => %{"type" => "number"},
        "station_reserved_by" => %{"type" => "string"},
        "station_reservation_status" => %{"type" => "string"},
        "schedule_conflict_status" => %{"type" => "string"},
        "eclipse_overlap_s" => %{"type" => "number"},
        "eclipse_overlap_fraction" => Keyword.fetch!(opts, :probability_schema),
        "lighting_condition" => %{"type" => "string"},
        "lighting_condition_detail" => %{"type" => "string"},
        "lighting_condition_model" => %{"type" => "string"},
        "lighting_detail_model" => %{"type" => "string"},
        "lighting_confidence" => Keyword.fetch!(opts, :number_or_string_schema),
        "image_quality_score" => Keyword.fetch!(opts, :probability_schema),
        "image_quality_status" => %{"type" => "string"},
        "image_quality_source" => %{"type" => "string"},
        "cloud_cover_fraction" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0},
        "blur_score" => %{"type" => "number", "minimum" => 0.0, "maximum" => 1.0},
        "activity_context" => Keyword.fetch!(opts, :activity_context_schema),
        "cadence_import" => %{"type" => "object", "additionalProperties" => true}
      }
    }
  end

  def source_window_from_context(deps) when is_list(deps) do
    source_window(stable_id_pattern: fetch_dep!(deps, :stable_id_pattern))
  end

  def source_window_from_context(stable_id_pattern) when is_binary(stable_id_pattern) do
    source_window(stable_id_pattern: stable_id_pattern)
  end

  def source_window(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "type" => %{"type" => "string"},
        "scenario_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "target_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "ground_station_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "starts_at_s" => %{"type" => "number"},
        "ends_at_s" => %{"type" => "number"},
        "duration_s" => %{"type" => "number"},
        "max_elevation_deg" => %{"type" => "number"},
        "minimum_elevation_deg" => %{"type" => "number"},
        "event_timing_policy" => %{"type" => "string"},
        "event_detector" => %{"type" => "string"},
        "event_time_tolerance_s" => %{"type" => "number"},
        "max_sample_step_s" => %{"type" => "number"},
        "confidence" => %{"type" => "string"}
      }
    }
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
