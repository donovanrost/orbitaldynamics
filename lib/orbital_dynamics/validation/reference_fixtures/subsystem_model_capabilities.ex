defmodule OrbitalDynamics.Validation.ReferenceFixtures.SubsystemModelCapabilities do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.subsystem_model_capability.battery" => %{
      "id" => "fixture.artifact.subsystem_model_capability.battery",
      "model_id" => "artifact.subsystem_model_capability.v1",
      "reference_case" => "checked-in battery energy storage subsystem capability artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/subsystem_model_capability_v1.json",
        "contract" => "subsystem_model_capability.v1"
      },
      "expected" => %{
        "schema_contract" => "subsystem_model_capability.v1",
        "id" => "subsystem.power.battery.energy_storage.planning_grade",
        "subsystem" => "power",
        "model" => "battery_energy_storage_planning_grade",
        "source" => "resource_projection_activity_energy_hints",
        "validation_level" => "assumption_declared",
        "fidelity_tier" => "planning_grade",
        "resource_dimension_count" => 1,
        "resource_dimensions" => "battery",
        "activity_effect_field_count" => 4,
        "activity_effect_fields" =>
          "energy_consumed_wh|energy_generated_wh|battery_energy_used_wh|battery_energy_generated_wh",
        "activity_effect_type_count" => 2,
        "activity_effect_types" => "consumption|generation",
        "time_span" => "selected_activity_sequence",
        "state_variable_count" => 3,
        "state_variables" => "capacity_wh|energy_remaining_wh|state_of_charge_fraction",
        "parameter_count" => 4,
        "parameter_keys" =>
          "capacity_wh|max_state_of_charge_fraction|min_state_of_charge_fraction|round_trip_efficiency",
        "capacity_wh" => 1000,
        "min_state_of_charge_fraction" => 0.2,
        "max_state_of_charge_fraction" => 1,
        "round_trip_efficiency" => 1,
        "known_limit_count" => 4,
        "known_limit_keys" =>
          "selected_activity_sequence_only|declared_energy_hints_only|no_continuous_power_bus_or_thermal_coupling|no_battery_degradation_or_charge_dynamics",
        "selected_activity_sequence_only" => true,
        "declared_energy_hints_only" => true,
        "no_continuous_power_bus_or_thermal_coupling" => true,
        "no_battery_degradation_or_charge_dynamics" => true
      },
      "tolerances" => %{
        "resource_dimension_count" => 0,
        "activity_effect_field_count" => 0,
        "activity_effect_type_count" => 0,
        "state_variable_count" => 0,
        "parameter_count" => 0,
        "capacity_wh" => 0,
        "min_state_of_charge_fraction" => 0.0,
        "max_state_of_charge_fraction" => 0.0,
        "round_trip_efficiency" => 0.0,
        "known_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external subsystem validation",
        "checks declared battery planning-grade resource model boundaries and known limits only"
      ]
    },
    "fixture.artifact.subsystem_model_capability.storage" => %{
      "id" => "fixture.artifact.subsystem_model_capability.storage",
      "model_id" => "artifact.subsystem_model_capability.v1",
      "reference_case" => "checked-in data recorder storage subsystem capability artifact",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_internal_artifact_regression",
      "inputs" => %{
        "artifact_path" => "study_results/subsystem_model_capability_storage_v1.json",
        "contract" => "subsystem_model_capability.v1"
      },
      "expected" => %{
        "schema_contract" => "subsystem_model_capability.v1",
        "id" => "subsystem.data_recorder.storage_buffer.planning_grade",
        "subsystem" => "data_recorder",
        "model" => "data_storage_buffer_planning_grade",
        "source" => "resource_projection_activity_data_volume_hints",
        "validation_level" => "assumption_declared",
        "fidelity_tier" => "planning_grade",
        "resource_dimension_count" => 2,
        "resource_dimensions" => "storage|downlink",
        "activity_effect_field_count" => 6,
        "activity_effect_fields" =>
          "planned_data_volume_mb|data_volume_mb|estimated_data_volume_mb|estimated_storage_mb|required_downlink_mb|selected_downlink_mb",
        "activity_effect_type_count" => 2,
        "activity_effect_types" => "downlink|production",
        "time_span" => "selected_activity_sequence",
        "state_variable_count" => 4,
        "state_variables" =>
          "storage_capacity_mb|storage_used_mb|storage_remaining_mb|storage_margin",
        "parameter_count" => 3,
        "parameter_keys" => "downlink_completion_policy|min_storage_margin|storage_capacity_mb",
        "storage_capacity_mb" => 1000,
        "min_storage_margin" => 0,
        "downlink_completion_policy" => "selected_activity_order",
        "known_limit_count" => 4,
        "known_limit_keys" =>
          "selected_activity_sequence_only|declared_data_volume_hints_only|storage_limited_downlink_arithmetic_only|no_partition_priority_deletion_or_latency_model",
        "selected_activity_sequence_only" => true,
        "declared_data_volume_hints_only" => true,
        "storage_limited_downlink_arithmetic_only" => true,
        "no_partition_priority_deletion_or_latency_model" => true
      },
      "tolerances" => %{
        "resource_dimension_count" => 0,
        "activity_effect_field_count" => 0,
        "activity_effect_type_count" => 0,
        "state_variable_count" => 0,
        "parameter_count" => 0,
        "storage_capacity_mb" => 0,
        "min_storage_margin" => 0,
        "known_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-linted by mix orbital_dynamics.schema.lint"
      ],
      "known_limits" => [
        "internal checked-in artifact regression, not external subsystem validation",
        "checks declared storage planning-grade resource model boundaries and known limits only"
      ]
    }
  }

  def all, do: @fixtures
end
