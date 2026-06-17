defmodule OrbitalDynamics.Schema.ResultArtifactJsonSchema do
  @moduledoc false

  @object_fields [
    "run",
    "assumptions",
    "metadata",
    "campaign_plan",
    "candidate_refresh",
    "monte_carlo_reproducibility_report",
    "constraint_report",
    "maneuver_review_report"
  ]

  def property("schema_version", opts) do
    %{
      "type" => "integer",
      "const" => Keyword.fetch!(opts, :schema_version),
      "description" => "Artifact schema version"
    }
  end

  def property("generated_at", _opts) do
    %{"type" => "string"}
  end

  def property("study_id", opts) do
    %{"type" => "string", "pattern" => Keyword.fetch!(opts, :stable_id_pattern)}
  end

  def property(field, _opts) when field in @object_fields do
    %{"type" => "object"}
  end

  def property("errors", _opts) do
    %{"type" => "array"}
  end

  def property("maneuver_recommendations", _opts) do
    %{"type" => "array"}
  end

  def property("trajectories", opts) do
    array_of(trajectory(Keyword.fetch!(opts, :stable_id_pattern)))
  end

  def property("access_windows", opts) do
    array_of(access_window(Keyword.fetch!(opts, :stable_id_pattern)))
  end

  def property("eclipse_intervals", opts) do
    array_of(eclipse_interval(Keyword.fetch!(opts, :stable_id_pattern)))
  end

  def property("target_visibility_windows", opts) do
    array_of(target_visibility_window(Keyword.fetch!(opts, :stable_id_pattern)))
  end

  def property("ground_track_crossings", opts) do
    array_of(ground_track_crossing(Keyword.fetch!(opts, :stable_id_pattern)))
  end

  def property("execution_report", opts) do
    Keyword.fetch!(opts, :execution_report_schema)
  end

  def property("payload_metrics", _opts) do
    payload_metrics()
  end

  def trajectory(stable_id_pattern) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "scenario_id",
        "sample_count",
        "starts_at_s",
        "ends_at_s",
        "final_position_km",
        "final_velocity_km_s",
        "assumptions"
      ],
      "properties" => %{
        "scenario_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "node" => %{"type" => "string"},
        "sample_count" => %{"type" => "integer"},
        "starts_at_s" => %{"type" => "number"},
        "ends_at_s" => %{"type" => "number"},
        "final_position_km" => numeric_triplet(),
        "final_velocity_km_s" => numeric_triplet(),
        "final_radius_km" => %{"type" => "number"},
        "final_speed_km_s" => %{"type" => "number"},
        "semi_major_axis_km" => %{"type" => "number"},
        "eccentricity" => %{"type" => "number"},
        "assumptions" => %{"type" => "object", "additionalProperties" => true}
      }
    }
  end

  def access_window(stable_id_pattern) do
    event_interval(
      stable_id_pattern,
      [
        "scenario_id",
        "ground_station_id",
        "starts_at_s",
        "ends_at_s"
      ]
    )
  end

  def eclipse_interval(stable_id_pattern) do
    event_interval(stable_id_pattern, ["scenario_id", "starts_at_s", "ends_at_s"])
  end

  def target_visibility_window(stable_id_pattern) do
    event_interval(stable_id_pattern, ["scenario_id", "target_id", "starts_at_s", "ends_at_s"])
  end

  def ground_track_crossing(stable_id_pattern) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "scenario_id",
        "event_type",
        "crossing",
        "target_deg",
        "frame",
        "starts_at_s",
        "assumptions"
      ],
      "properties" => %{
        "scenario_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "request_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "event_type" => %{
          "type" => "string",
          "enum" => ["latitude_crossing", "longitude_crossing"]
        },
        "crossing" => %{"type" => "string", "enum" => ["latitude", "longitude"]},
        "target_deg" => %{"type" => "number"},
        "frame" => %{"type" => "string", "enum" => ["inertial", "body_fixed"]},
        "starts_at_s" => %{"type" => "number"},
        "crossing_direction" => %{"type" => "string"},
        "start_sample_index" => %{"type" => "integer"},
        "end_sample_index" => %{"type" => "integer"},
        "sample_index" => %{"type" => "integer"},
        "assumptions" => %{"type" => "object", "additionalProperties" => true}
      }
    }
  end

  def payload_metrics do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "schema_contract",
        "encoding",
        "artifact_body_bytes",
        "top_level_key_count",
        "sections"
      ],
      "properties" => %{
        "schema_contract" => %{
          "type" => "string",
          "const" => "result_payload_metrics.v1"
        },
        "encoding" => %{"type" => "string"},
        "artifact_body_bytes" => %{"type" => "integer"},
        "top_level_key_count" => %{"type" => "integer"},
        "sections" => %{
          "type" => "object",
          "additionalProperties" => %{
            "type" => "object",
            "additionalProperties" => true,
            "required" => ["bytes", "row_count"],
            "properties" => %{
              "bytes" => %{"type" => "integer"},
              "row_count" => %{"type" => ["integer", "null"]}
            }
          }
        }
      }
    }
  end

  defp event_interval(stable_id_pattern, required) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => required,
      "properties" => %{
        "scenario_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "ground_station_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "target_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "starts_at_s" => %{"type" => "number"},
        "ends_at_s" => %{"type" => "number"},
        "duration_s" => %{"type" => "number"},
        "sample_count" => %{"type" => "integer"},
        "assumptions" => %{"type" => "object", "additionalProperties" => true}
      }
    }
  end

  defp array_of(items) do
    %{
      "type" => "array",
      "items" => items
    }
  end

  defp numeric_triplet do
    %{
      "type" => "array",
      "minItems" => 3,
      "maxItems" => 3,
      "items" => %{"type" => "number"}
    }
  end
end
