defmodule OrbitalDynamics.Schema.AcceptedStateJsonSchema do
  @moduledoc false

  @property_fields ["spacecraft_states", "maneuver_execution_deltas"]

  def property_field?(field) when field in @property_fields, do: true
  def property_field?(_field), do: false

  def property_fun_from_context(deps) when is_list(deps) do
    fn field ->
      property(field, property_opts(field, deps))
    end
  end

  def property_opts("spacecraft_states", deps) do
    [spacecraft_state_estimate_schema: fetch_dep!(deps, :spacecraft_state_estimate_schema)]
  end

  def property_opts("maneuver_execution_deltas", deps) do
    [maneuver_execution_delta_schema: fetch_dep!(deps, :maneuver_execution_delta_schema)]
  end

  def property_opts(_field, _deps), do: []

  def property("spacecraft_states", opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :spacecraft_state_estimate_schema)
    }
  end

  def property("maneuver_execution_deltas", opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :maneuver_execution_delta_schema)
    }
  end

  def spacecraft_state_estimate_from_context(deps) when is_list(deps) do
    spacecraft_state_estimate(
      fetch_dep!(deps, :stable_id_pattern),
      fetch_dep!(deps, :numeric_triplet_schema)
    )
  end

  def spacecraft_state_estimate_from_context(stable_id_pattern, numeric_triplet_schema) do
    spacecraft_state_estimate(stable_id_pattern, numeric_triplet_schema)
  end

  def spacecraft_state_estimate(stable_id_pattern, numeric_triplet_schema) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "spacecraft_id",
        "scenario_id",
        "epoch",
        "frame",
        "state_vector",
        "source",
        "quality"
      ],
      "properties" => %{
        "schema_contract" => %{"type" => "string", "const" => "spacecraft_state_estimate.v1"},
        "spacecraft_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "scenario_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "trust_boundary" => %{"type" => "string"},
        "provenance" => trust_boundary_provenance(),
        "epoch" => %{
          "type" => "object",
          "additionalProperties" => true,
          "required" => ["seconds_since_j2000", "time_scale"],
          "properties" => %{
            "seconds_since_j2000" => %{"type" => "number"},
            "time_scale" => %{"type" => "string"}
          }
        },
        "frame" => %{"type" => "string"},
        "state_vector" => %{
          "type" => "object",
          "additionalProperties" => true,
          "required" => ["position_km", "velocity_km_s"],
          "properties" => %{
            "position_km" => numeric_triplet_schema,
            "velocity_km_s" => numeric_triplet_schema
          }
        },
        "source" => %{
          "oneOf" => [
            %{"type" => "string"},
            %{"type" => "object", "additionalProperties" => true}
          ]
        },
        "quality" => %{
          "type" => "object",
          "additionalProperties" => true,
          "properties" => %{
            "level" => %{"type" => "string"},
            "position_sigma_km" => numeric_triplet_schema,
            "velocity_sigma_km_s" => numeric_triplet_schema,
            "covariance_reference_frame" => %{"type" => "string"},
            "covariance_status" => %{"type" => "string"}
          }
        },
        "metadata" => %{
          "type" => "object",
          "additionalProperties" => true,
          "properties" => %{
            "input_format" => %{"type" => "string"},
            "ccsds_opm_version" => %{"type" => "string"},
            "ccsds_oem_version" => %{"type" => "string"},
            "object_name" => %{"type" => "string"},
            "object_id" => %{"type" => "string"},
            "center_name" => %{"type" => "string"},
            "ref_frame" => %{"type" => "string"},
            "time_system" => %{"type" => "string"},
            "interpolation" => %{"type" => "string"},
            "interpolation_degree" => %{"type" => "string"},
            "sample_index" => %{"type" => "integer"},
            "sample_epoch" => %{"type" => "string"},
            "covariance_reference_frame" => %{"type" => "string"}
          }
        }
      },
      "anyOf" => trust_boundary_any_of()
    }
  end

  def maneuver_execution_delta_from_context(deps) when is_list(deps) do
    maneuver_execution_delta(
      fetch_dep!(deps, :stable_id_pattern),
      fetch_dep!(deps, :numeric_triplet_schema)
    )
  end

  def maneuver_execution_delta_from_context(stable_id_pattern, numeric_triplet_schema) do
    maneuver_execution_delta(stable_id_pattern, numeric_triplet_schema)
  end

  def maneuver_execution_delta(stable_id_pattern, numeric_triplet_schema) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["activity_id", "status", "source", "quality"],
      "properties" => %{
        "schema_contract" => %{"type" => "string", "const" => "maneuver_execution_delta.v1"},
        "activity_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "status" => %{"type" => "string"},
        "source" => %{"type" => "object", "additionalProperties" => true},
        "quality" => %{"type" => "object", "additionalProperties" => true},
        "epoch_s" => %{"type" => "number"},
        "delta_v_km_s" => numeric_triplet_schema,
        "trust_boundary" => %{"type" => "string"},
        "provenance" => trust_boundary_provenance(),
        "metadata" => %{
          "type" => "object",
          "additionalProperties" => true,
          "properties" => %{
            "input_format" => %{"type" => "string"},
            "source_format" => %{"type" => "string"},
            "maneuver_index" => %{"type" => "integer"},
            "maneuver_count" => %{"type" => "integer"},
            "maneuver_metadata_status" => %{"type" => "string"},
            "maneuver_epoch_ignition" => %{"type" => "string"},
            "maneuver_reference_frame" => %{"type" => "string"},
            "maneuver_duration_s" => %{"type" => "number"},
            "maneuver_delta_mass_kg" => %{"type" => "number"},
            "maneuver_delta_v_source" => %{"type" => "string"},
            "no_propagation_status" => %{"type" => "string"}
          }
        }
      },
      "anyOf" => trust_boundary_any_of()
    }
  end

  defp trust_boundary_provenance do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{"trust_boundary" => %{"type" => "string"}}
    }
  end

  defp trust_boundary_any_of do
    [
      %{"required" => ["trust_boundary"]},
      %{
        "required" => ["provenance"],
        "properties" => %{
          "provenance" => %{
            "type" => "object",
            "required" => ["trust_boundary"],
            "properties" => %{"trust_boundary" => %{"type" => "string"}},
            "additionalProperties" => true
          }
        }
      }
    ]
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
