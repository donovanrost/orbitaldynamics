defmodule OrbitalDynamics.Study.Manifest.SchemaDocument do
  @moduledoc false

  import OrbitalDynamics.Study.Manifest.SchemaProperty
  import OrbitalDynamics.Study.Manifest.ValueSchema

  alias OrbitalDynamics.Schema

  alias OrbitalDynamics.Study.Manifest.{
    ActivityInput,
    ActivitySchema,
    RealizedActivitySchema
  }

  def build(config) when is_map(config) do
    %{
      "$schema" => config.json_schema_draft,
      "$id" =>
        "https://orbital-dynamics.local/schemas/#{config.json_schema_contract}.schema.json",
      "title" => "OrbitalDynamics #{config.json_schema_contract}",
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["schema_version", "study_id", "outputs"],
      "anyOf" =>
        Enum.map(
          [
            "scenarios",
            "mission_plans",
            "campaign",
            "candidate_refresh",
            "search",
            "monte_carlo"
          ],
          &%{"required" => [&1]}
        ),
      "properties" => manifest_schema_properties(config),
      "x-orbital-dynamics" => %{
        "schema_contract" => config.json_schema_contract,
        "manifest_family" => "study_manifest",
        "schema_version" => config.schema_version,
        "validation_mode" => "top_level_manifest_compatibility_export",
        "compatibility_policy_version" => Schema.compatibility_policy()["policy_version"],
        "compatibility_policy" => Schema.compatibility_policy(),
        "identity_policy_version" => Schema.identity_policy()["policy_version"],
        "identity_policy" => Schema.identity_policy(),
        "executable_validator" => config.semantic_validator,
        "lint_error_codes" => config.lint_error_codes,
        "lint_task" => "mix orbital_dynamics.manifest.lint --manifest PATH",
        "schema_export_task" =>
          "mix orbital_dynamics.manifest.schema.export --output schemas/study_manifest.v1.schema.json",
        "nested_contracts" => [
          "accepted_planning_state.v1",
          "resource_summary.v1",
          "station_calendar_provider.v1"
        ],
        "executable_contract" => false
      }
    }
  end

  defp manifest_schema_properties(config) do
    %{
      "schema_version" => %{
        "type" => "integer",
        "const" => config.schema_version,
        "description" => "Study manifest schema version."
      },
      "study_id" => string_property("Stable identifier for the study run."),
      "central_body" => %{
        "oneOf" => [
          %{"type" => "string", "const" => "earth"},
          object_property(%{
            "name" => string_property(),
            "mu_km3_s2" => number_property(),
            "equatorial_radius_km" => number_property(),
            "j2" => number_property()
          })
        ]
      },
      "propagator" => enum_property(config.propagators),
      "propagator_opts" =>
        object_property(%{
          "max_step_s" => number_property(),
          "integration" => enum_property(["fixed_step", "adaptive_step"]),
          "min_step_s" => number_property(),
          "adaptive_position_tolerance_km" => number_property(),
          "adaptive_velocity_tolerance_km_s" => number_property()
        }),
      "outputs" => %{
        "type" => "array",
        "items" => enum_property(config.outputs),
        "minItems" => 1
      },
      "run_options" =>
        object_property(%{
          "max_concurrency" => integer_property(),
          "timeout" => integer_property(),
          "task_chunk_size" => integer_property(),
          "task_supervisor_node" => string_property(),
          "task_supervisor_nodes" => array_property(string_property())
        }),
      "ground_stations" => array_property(ground_station_schema()),
      "ground_track_crossings" => array_property(ground_track_crossing_schema()),
      "sun_direction" => vector3_schema(),
      "scenarios" => array_property(scenario_schema()),
      "mission_plans" => array_property(mission_plan_schema()),
      "campaign" => campaign_schema(),
      "candidate_refresh" => candidate_refresh_schema(),
      "search" => search_schema(config.search_objectives),
      "monte_carlo" => monte_carlo_schema(config.search_objectives),
      "constraints" => array_property(constraint_schema()),
      "seed_manifest" => object_property(),
      "metadata" => object_property()
    }
  end

  defp scenario_schema do
    %{
      "oneOf" => [
        object_property(%{
          "generator" => %{"type" => "string", "const" => "circular_leo"},
          "count" => integer_property(),
          "duration_s" => number_property(),
          "output_step_s" => number_property(),
          "radius_km" => number_property(),
          "dry_mass_kg" => number_property(),
          "id_prefix" => string_property(),
          "epoch" => epoch_schema(),
          "frame" => frame_schema()
        }),
        explicit_scenario_schema()
      ]
    }
  end

  defp explicit_scenario_schema do
    object_property(
      %{
        "id" => string_property(),
        "spacecraft" => spacecraft_schema(),
        "initial_state" => state_vector_schema(),
        "duration_s" => number_property(),
        "output_step_s" => number_property(),
        "maneuvers" => array_property(maneuver_schema())
      },
      ["id", "spacecraft", "initial_state", "duration_s", "output_step_s"]
    )
  end

  defp mission_plan_schema do
    object_property(
      %{
        "id" => string_property(),
        "spacecraft" => spacecraft_schema(),
        "initial_state" => state_vector_schema(),
        "horizon_s" => number_property(),
        "output_step_s" => number_property(),
        "activities" => array_property(activity_schema()),
        "metadata" => object_property()
      },
      ["id", "spacecraft", "initial_state", "horizon_s", "output_step_s"]
    )
  end

  defp activity_schema, do: ActivitySchema.json_schema()

  defp maneuver_schema do
    object_property(
      %{
        "id" => string_property(),
        "epoch" => epoch_schema(),
        "delta_v_km_s" => vector3_schema(),
        "frame" => frame_schema()
      },
      ["id", "epoch", "delta_v_km_s"]
    )
  end

  defp campaign_schema do
    object_property(
      %{
        "planning_horizon" =>
          object_property(
            %{
              "duration_s" => number_property(),
              "output_step_s" => number_property()
            },
            ["duration_s", "output_step_s"]
          ),
        "spacecraft" => array_property(campaign_spacecraft_schema()),
        "targets" => array_property(target_schema()),
        "constraints" =>
          object_property(%{
            "min_activity_duration_s" => number_property(),
            "max_timeline_activities" => integer_property(),
            "avoid_eclipse" => boolean_property()
          }),
        "scoring_policy" =>
          object_property(%{
            "target_value_weight" => number_property(),
            "contact_value_weight" => number_property(),
            "eclipse_penalty_weight" => number_property(),
            "activity_count_penalty" => number_property(),
            "rank_limit" => integer_property()
          }),
        "ground_network" => array_property(ground_network_entry_schema()),
        "resource_summaries" => array_property(object_property())
      },
      ["planning_horizon", "spacecraft", "targets"]
    )
  end

  defp campaign_spacecraft_schema do
    object_property(
      Map.merge(%{"initial_state" => state_vector_schema()}, spacecraft_fields()),
      ["id", "dry_mass_kg", "initial_state"]
    )
  end

  defp candidate_refresh_schema do
    object_property(
      %{
        "accepted_planning_state" => artifact_json_schema("accepted_planning_state.v1"),
        "orbit_data" => orbit_data_schema(),
        "current_epoch_s" => number_property(),
        "current_epoch" => epoch_schema(),
        "remaining_horizon" =>
          object_property(
            %{
              "starts_at_s" => number_property(),
              "ends_at_s" => number_property(),
              "duration_s" => number_property(),
              "output_step_s" => number_property()
            },
            ["output_step_s"]
          ),
        "targets" => array_property(target_schema()),
        "constraints" =>
          object_property(%{
            "min_activity_duration_s" => number_property(),
            "avoid_eclipse" => boolean_property()
          }),
        "scoring_policy" =>
          object_property(%{
            "target_value_weight" => number_property(),
            "contact_value_weight" => number_property(),
            "eclipse_penalty_weight" => number_property(),
            "downlink_rate_mb_s" => number_property(),
            "downlink_completion_weight" => number_property(),
            "observation_objective_weight" => number_property(),
            "collection_latency_observation_weight" => number_property()
          }),
        "objectives" => array_property(object_property()),
        "freshness_policy" => freshness_policy_schema(),
        "resource_filter_policy" => resource_filter_policy_schema(),
        "candidate_limit_policy" => candidate_limit_policy_schema(),
        "approval_policy" => object_property(),
        "operational_feedback" => operational_feedback_schema(),
        "mission_state" => object_property(),
        "source_timeline_feedback_report" => artifact_json_schema("timeline_feedback_report.v1"),
        "timeline_feedback_report" => artifact_json_schema("timeline_feedback_report.v1"),
        "source_operational_timeline_report" => operational_timeline_report_input_schema(),
        "operational_timeline_report" => operational_timeline_report_input_schema(),
        "model_assumptions" => object_property(),
        "resource_summaries" => array_property(resource_summary_input_schema()),
        "ground_network" => array_property(ground_network_entry_schema()),
        "prior_candidate_activities" => array_property(prior_candidate_activity_schema())
      },
      ["remaining_horizon"]
    )
    |> Map.put("anyOf", [
      %{"required" => ["accepted_planning_state"]},
      %{"required" => ["orbit_data"]},
      %{"required" => ["mission_state"]}
    ])
  end

  defp operational_timeline_report_input_schema do
    %{
      "oneOf" => [
        artifact_json_schema("operational_timeline_report.v1"),
        array_property(artifact_json_schema("operational_timeline_report.v1"))
      ]
    }
  end

  defp search_schema(search_objectives) do
    object_property(
      %{
        "generator" => %{"type" => "string", "const" => "impulsive_burn_grid"},
        "base_scenario" => explicit_scenario_schema(),
        "burn_epoch_s" => array_property(number_property()),
        "delta_v_km_s" => array_property(vector3_schema()),
        "id_prefix" => string_property(),
        "objective" => enum_property(Enum.sort(search_objectives)),
        "objective_direction" => enum_property(["maximize", "minimize"]),
        "rank_limit" => integer_property()
      },
      ["base_scenario", "burn_epoch_s", "delta_v_km_s"]
    )
  end

  defp monte_carlo_schema(search_objectives) do
    object_property(
      %{
        "generator" => %{"type" => "string", "const" => "state_vector_dispersion"},
        "base_scenario" => explicit_scenario_schema(),
        "count" => integer_property(),
        "seed" => integer_property(),
        "position_sigma_km" => vector3_schema(),
        "velocity_sigma_km_s" => vector3_schema(),
        "id_prefix" => string_property(),
        "objective" => enum_property(Enum.sort(search_objectives)),
        "objective_direction" => enum_property(["maximize", "minimize"]),
        "rank_limit" => integer_property()
      },
      ["base_scenario", "count", "seed", "position_sigma_km", "velocity_sigma_km_s"]
    )
  end

  defp constraint_schema do
    object_property(
      %{
        "id" => string_property(),
        "metric" => string_property(),
        "operator" => enum_property(["<", "<=", "==", ">=", ">"]),
        "value" => number_property()
      },
      ["id", "metric", "operator", "value"]
    )
  end

  defp spacecraft_schema do
    object_property(spacecraft_fields(), ["id", "dry_mass_kg"])
  end

  defp spacecraft_fields do
    %{
      "id" => string_property(),
      "dry_mass_kg" => number_property(),
      "propellant_mass_kg" => number_property(),
      "area_m2" => number_property(),
      "drag_coefficient" => number_property()
    }
  end

  defp state_vector_schema do
    object_property(
      %{
        "position_km" => vector3_schema(),
        "velocity_km_s" => vector3_schema(),
        "epoch" => epoch_schema(),
        "frame" => frame_schema()
      },
      ["position_km", "velocity_km_s", "epoch"]
    )
  end

  defp epoch_schema do
    object_property(
      %{
        "seconds_since_j2000" => number_property(),
        "scale" => enum_property(["tdb", "tai", "utc"]),
        "time_scale" => enum_property(["tdb", "tai", "utc"])
      },
      ["seconds_since_j2000"]
    )
  end

  defp frame_schema, do: %{"type" => "string", "const" => "earth_inertial_j2000"}

  defp ground_station_schema do
    object_property(
      %{
        "id" => string_property(),
        "latitude_deg" => number_property(),
        "longitude_deg" => number_property(),
        "altitude_km" => number_property(),
        "minimum_elevation_deg" => number_property()
      },
      ["id", "latitude_deg", "longitude_deg"]
    )
  end

  defp target_schema do
    object_property(
      %{
        "id" => string_property(),
        "latitude_deg" => number_property(),
        "longitude_deg" => number_property(),
        "altitude_km" => number_property(),
        "minimum_elevation_deg" => number_property(),
        "priority" => number_property()
      },
      ["id", "latitude_deg", "longitude_deg"]
    )
  end

  defp ground_track_crossing_schema do
    object_property(%{
      "id" => string_property(),
      "crossing" => enum_property(["latitude", "longitude"]),
      "latitude_deg" => number_property(),
      "longitude_deg" => number_property(),
      "frame" => enum_property(["inertial", "body_fixed"]),
      "rotation_rate_rad_s" => number_property(),
      "rotation_epoch_s" => number_property(),
      "rotation_angle_offset_rad" => number_property(),
      "earth_rotation_provider" => earth_rotation_provider_schema()
    })
  end

  defp earth_rotation_provider_schema do
    %{
      "oneOf" => [
        enum_property(["constant_earth_rotation", "tabular_earth_orientation"]),
        object_property(%{
          "provider" => enum_property(["constant_earth_rotation", "tabular_earth_orientation"]),
          "provider_id" => string_property(),
          "source" => string_property(),
          "samples" => array_property(earth_rotation_sample_schema())
        })
      ]
    }
  end

  defp earth_rotation_sample_schema do
    object_property(%{
      "seconds_since_j2000" => number_property(),
      "epoch_s" => number_property(),
      "earth_rotation_angle_rad" => number_property(),
      "rotation_angle_rad" => number_property(),
      "earth_rotation_rate_rad_s" => number_property(),
      "rotation_rate_rad_s" => number_property()
    })
  end

  defp ground_network_entry_schema do
    object_property(%{
      "id" => string_property(),
      "ground_station_id" => string_property(),
      "station_id" => string_property(),
      "status" => string_property(),
      "availability" => station_availability_property(),
      "starts_at_s" => number_property(),
      "ends_at_s" => number_property(),
      "capacity_fraction" => number_property(),
      "available" => boolean_property(),
      "station_calendar_entry_id" => string_property(),
      "station_calendar_provider_id" => string_property(),
      "station_calendar_provider_entry_id" => string_property(),
      "station_calendar_directions" => array_property(string_property()),
      "station_calendar_status" => string_property(),
      "station_calendar_trust_boundary_status" => string_property(),
      "station_contention_status" => string_property(),
      "reservation_id" => string_property(),
      "reserved_by" => string_property(),
      "reservation_status" => string_property(),
      "station_reservation_match_status" => string_property(),
      "provenance" => object_property()
    })
    |> Map.put("anyOf", [
      %{"required" => ["ground_station_id"]},
      %{"required" => ["station_id"]}
    ])
  end

  defp orbit_data_schema do
    object_property(
      %{
        "snapshot_id" => string_property(),
        "accepted_at" => string_property(),
        "state_estimates" => array_property(planning_state_row_schema()),
        "maneuver_execution_deltas" => array_property(object_property()),
        "source" => object_property(),
        "quality" => object_property(),
        "provenance" => object_property()
      },
      ["snapshot_id", "accepted_at", "state_estimates", "source", "quality", "provenance"]
    )
  end

  defp planning_state_row_schema do
    object_property(
      %{
        "spacecraft_id" => string_property(),
        "scenario_id" => string_property(),
        "dry_mass_kg" => number_property(),
        "epoch" => epoch_schema(),
        "seconds_since_j2000" => number_property(),
        "time_scale" => enum_property(["tdb", "tai", "utc"]),
        "scale" => enum_property(["tdb", "tai", "utc"]),
        "frame" => frame_schema(),
        "state_vector" =>
          object_property(
            %{
              "position_km" => vector3_schema(),
              "velocity_km_s" => vector3_schema()
            },
            ["position_km", "velocity_km_s"]
          ),
        "position_km" => vector3_schema(),
        "velocity_km_s" => vector3_schema(),
        "source" => object_property(),
        "quality" => object_property(),
        "metadata" => object_property()
      },
      ["spacecraft_id", "source"]
    )
    |> Map.put("anyOf", [%{"required" => ["epoch"]}, %{"required" => ["seconds_since_j2000"]}])
    |> Map.put("allOf", [
      %{
        "anyOf" => [
          %{"required" => ["state_vector"]},
          %{"required" => ["position_km", "velocity_km_s"]}
        ]
      }
    ])
  end

  defp resource_summary_input_schema do
    object_property(
      %{
        "schema_contract" => %{"type" => "string", "const" => "resource_summary.v1"},
        "spacecraft_id" => string_property(),
        "mode" => string_property(),
        "fuel_margin" => number_property(),
        "power_margin" => number_property(),
        "storage_capacity_mb" => number_property(),
        "storage_used_mb" => number_property(),
        "storage_margin" => number_property(),
        "downlink_capacity_mb" => number_property(),
        "downlink_margin" => number_property(),
        "source_quality" => string_property(),
        "payload_available" => boolean_property(),
        "antenna_available" => boolean_property(),
        "assumptions" => object_property(),
        "provenance" => object_property()
      },
      ["spacecraft_id"]
    )
  end

  defp freshness_policy_schema do
    object_property(%{
      "max_state_age_s" => number_property(),
      "max_candidate_age_s" => number_property(),
      "stale_candidate_action" => string_property()
    })
  end

  defp resource_filter_policy_schema do
    object_property(%{
      "min_activity_fuel_margin" => number_property(),
      "min_observe_power_margin" => number_property(),
      "min_observe_storage_margin" => number_property(),
      "min_downlink_power_margin" => number_property(),
      "min_downlink_margin" => number_property()
    })
  end

  defp candidate_limit_policy_schema do
    object_property(%{
      "max_candidate_activities" => integer_property()
    })
  end

  defp operational_feedback_schema do
    object_property(%{
      "trust_boundary" => string_property(),
      "provenance" => object_property(),
      "source" => object_property(),
      "metadata" => object_property(),
      "contact_success_rate" => numeric_feedback_map_schema(),
      "observation_success_rate" => numeric_feedback_map_schema(),
      "station_throughput_factor" => numeric_feedback_map_schema(),
      "downlink_demand_mb" => numeric_feedback_map_schema(),
      "target_priority_overrides" => numeric_feedback_map_schema(),
      "resource_margin_overrides" => object_property(),
      "resource_availability_overrides" => object_property(),
      "availability_overrides" => object_property(),
      "realized_activities" => array_property(realized_activity_input_schema()),
      "realized_state" => object_property(),
      "station_calendar" => array_property(ground_network_entry_schema())
    })
  end

  defp numeric_feedback_map_schema do
    %{
      "type" => "object",
      "additionalProperties" => number_property(),
      "properties" => %{}
    }
  end

  defp realized_activity_input_schema, do: RealizedActivitySchema.json_schema()

  defp prior_candidate_activity_schema do
    object_property(%{
      "id" => string_property(),
      "type" => string_property(),
      "activity_type" => string_property(),
      "scenario_id" => string_property(),
      "target_id" => string_property(),
      "ground_station_id" => string_property(),
      "station_id" => string_property(),
      "station" => ground_station_identity_schema(),
      "ground_station" => ground_station_identity_schema(),
      "direction" => contact_direction_property(),
      "start_s" => number_property(),
      "end_s" => number_property(),
      "starts_at_s" => number_property(),
      "ends_at_s" => number_property(),
      "source_window_id" => string_property(),
      "source_window" => object_property(),
      "metadata" => object_property()
    })
  end

  defp artifact_json_schema(contract_name) do
    {:ok, schema} = Schema.json_schema(contract_name)

    schema
    |> Map.drop(["$schema", "$id", "title"])
    |> Map.put(
      "description",
      "Embedded #{contract_name} artifact accepted by the manifest loader."
    )
  end

  defp contact_direction_property, do: ActivityInput.contact_direction_property()
end
