defmodule OrbitalDynamics.Schema.ProposedContactJsonSchema do
  @moduledoc false

  @status_string_fields ["station_availability", "schedule_conflict_status"]

  @base_fields [
    "direction",
    "source_window",
    "cadence_import",
    "timeline_identity",
    "model_limits"
  ]

  def property_field?(field) do
    field in @base_fields or field in @status_string_fields
  end

  def property_from_context(field, deps) when is_list(deps) do
    property(field, property_opts(field, deps))
  end

  def property_fun_from_context(deps) when is_list(deps) do
    fn field ->
      property_from_context(field, deps)
    end
  end

  def property_opts("source_window", deps) do
    [source_window_schema: fetch_dep!(deps, :source_window_schema)]
  end

  def property_opts("cadence_import", deps) do
    [cadence_import_schema: fetch_dep!(deps, :cadence_import_schema)]
  end

  def property_opts("timeline_identity", deps) do
    [timeline_identity_schema: fetch_dep!(deps, :timeline_identity_schema)]
  end

  def property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts(_field, _deps), do: []

  def row_from_context(
        stable_id_pattern,
        string_array_schema,
        source_window_schema,
        cadence_import_schema
      ) do
    row(
      stable_id_pattern: stable_id_pattern,
      string_array_schema: string_array_schema,
      source_window_schema: source_window_schema,
      cadence_import_schema: cadence_import_schema
    )
  end

  def row_from_context(deps) do
    row(
      stable_id_pattern: fetch_dep!(deps, :stable_id_pattern),
      string_array_schema: fetch_dep!(deps, :string_array_schema),
      source_window_schema: fetch_dep!(deps, :source_window_schema),
      cadence_import_schema: fetch_dep!(deps, :cadence_import_schema)
    )
  end

  def row(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "id",
        "type",
        "scenario_id",
        "ground_station_id",
        "starts_at_s",
        "ends_at_s",
        "direction",
        "estimated_throughput_mb",
        "source_window",
        "cadence_import"
      ],
      "properties" => %{
        "id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "type" => %{"type" => "string", "const" => "downlink"},
        "scenario_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "ground_station_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "starts_at_s" => %{"type" => "number"},
        "ends_at_s" => %{"type" => "number"},
        "duration_s" => %{"type" => "number"},
        "direction" => property("direction", []),
        "estimated_throughput_mb" => %{"type" => "number"},
        "throughput_model" => %{"type" => "object", "additionalProperties" => true},
        "station_availability" => property("station_availability", []),
        "station_contention_status" => %{"type" => "string"},
        "station_calendar_directions" => Keyword.fetch!(opts, :string_array_schema),
        "station_reservation_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "station_reservation_expires_at_s" => %{"type" => "number"},
        "station_reserved_by" => %{"type" => "string"},
        "station_reservation_status" => %{"type" => "string"},
        "station_calendar_entry_id" => %{"type" => "string"},
        "station_calendar_status" => %{"type" => "string"},
        "station_capacity_fraction" => %{"type" => "number"},
        "schedule_conflict_status" => property("schedule_conflict_status", []),
        "score" => %{"type" => "number"},
        "score_terms" => %{"type" => "object", "additionalProperties" => true},
        "source_window_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "source_window" =>
          property("source_window",
            source_window_schema: Keyword.fetch!(opts, :source_window_schema)
          ),
        "cadence_import" =>
          property("cadence_import",
            cadence_import_schema: Keyword.fetch!(opts, :cadence_import_schema)
          )
      }
    }
  end

  def property("direction", _opts) do
    %{
      "type" => "string",
      "enum" => ["downlink", "uplink", "command", "tracking"]
    }
  end

  def property("source_window", opts) do
    Keyword.fetch!(opts, :source_window_schema)
  end

  def property("cadence_import", opts) do
    Keyword.fetch!(opts, :cadence_import_schema)
  end

  def property("timeline_identity", opts) do
    Keyword.fetch!(opts, :timeline_identity_schema)
  end

  def property(field, _opts) when field in @status_string_fields do
    %{"type" => "string"}
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      value when is_function(value, 0) -> value.()
      value -> value
    end
  end
end
