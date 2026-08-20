defmodule OrbitalDynamics.Validation.ReferenceFixtures.EnvironmentCapabilities do
  @moduledoc false

  @fixtures %{
    "fixture.artifact.environment_model_capability.fixed_sun" => %{
      "id" => "fixture.artifact.environment_model_capability.fixed_sun",
      "model_id" => "artifact.environment_model_capability.v1",
      "reference_case" => "runtime fixed inertial Sun direction environment model capability",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_runtime_capability_regression",
      "inputs" => %{
        "source_facade" => "OrbitalDynamics.Environment.model_capabilities/0",
        "capability_id" => "environment.solar.fixed_inertial_direction",
        "contract" => "environment_model_capability.v1"
      },
      "expected" => %{
        "schema_contract" => "environment_model_capability.v1",
        "id" => "environment.solar.fixed_inertial_direction",
        "category" => "solar_direction",
        "model" => "fixed_inertial_solar_direction",
        "source" => "study_runner_option",
        "validation_level" => "assumption_declared",
        "coordinate_frame" => "eci_j2000_inertial",
        "interpolation" => "constant",
        "time_span" => "study_horizon",
        "supported_body_count" => 1,
        "network_access" => false,
        "parameter_count" => 1,
        "sun_direction_dimension" => 3,
        "sun_direction_order" => "1.0|0.0|0.0",
        "known_limit_count" => 3
      },
      "tolerances" => %{
        "supported_body_count" => 0,
        "parameter_count" => 0,
        "sun_direction_dimension" => 0,
        "known_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-validated from OrbitalDynamics.Environment.model_capabilities/0"
      ],
      "known_limits" => [
        "runtime capability regression, not external environment-model validation",
        "checks public model capability identity and declared assumption boundaries only"
      ]
    },
    "fixture.artifact.environment_model_capability.constant_earth_rotation" => %{
      "id" => "fixture.artifact.environment_model_capability.constant_earth_rotation",
      "model_id" => "artifact.environment_model_capability.v1",
      "reference_case" => "runtime constant Earth rotation environment model capability",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_runtime_capability_regression",
      "inputs" => %{
        "source_facade" => "OrbitalDynamics.Environment.model_capabilities/0",
        "capability_id" => "environment.earth_rotation.constant_rate",
        "contract" => "environment_model_capability.v1"
      },
      "expected" => %{
        "schema_contract" => "environment_model_capability.v1",
        "id" => "environment.earth_rotation.constant_rate",
        "category" => "body_rotation",
        "model" => "constant_earth_rotation",
        "source" => "internal_simplified_geometry",
        "validation_level" => "assumption_declared",
        "coordinate_frame" => "earth_body_fixed_to_eci_j2000_approximation",
        "interpolation" => "analytic_constant_rate",
        "time_span" => "study_horizon",
        "supported_body_count" => 1,
        "network_access" => false,
        "parameter_count" => 2,
        "earth_rotation_rate_rad_s" => 7.292115e-5,
        "geometry_model" => "simplified_spherical_earth_rotation",
        "known_limit_count" => 3
      },
      "tolerances" => %{
        "supported_body_count" => 0,
        "parameter_count" => 0,
        "earth_rotation_rate_rad_s" => 0.0,
        "known_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-validated from OrbitalDynamics.Environment.model_capabilities/0"
      ],
      "known_limits" => [
        "runtime capability regression, not external environment-model validation",
        "checks public model capability identity and declared assumption boundaries only"
      ]
    },
    "fixture.artifact.environment_provider_capability.fixed_sun" => %{
      "id" => "fixture.artifact.environment_provider_capability.fixed_sun",
      "model_id" => "artifact.environment_provider_capability.v1",
      "reference_case" => "runtime fixed inertial Sun direction environment provider capability",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_runtime_capability_regression",
      "inputs" => %{
        "source_facade" => "OrbitalDynamics.Environment.provider_capabilities/0",
        "capability_id" => "environment.provider.solar.fixed_inertial_direction",
        "contract" => "environment_provider_capability.v1"
      },
      "expected" => %{
        "schema_contract" => "environment_provider_capability.v1",
        "id" => "environment.provider.solar.fixed_inertial_direction",
        "category" => "solar_direction",
        "model" => "fixed_inertial_solar_direction",
        "source" => "internal_fixed_sun_assumption",
        "validation_level" => "assumption_declared",
        "interpolation" => "constant",
        "coverage_policy" => "all_times",
        "coverage_time_scale" => "seconds_since_j2000",
        "output_count" => 1,
        "supported_body_count" => 1,
        "network_access" => false,
        "parameter_count" => 0,
        "known_limit_count" => 3
      },
      "tolerances" => %{
        "output_count" => 0,
        "supported_body_count" => 0,
        "parameter_count" => 0,
        "known_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-validated from OrbitalDynamics.Environment.provider_capabilities/0"
      ],
      "known_limits" => [
        "runtime capability regression, not external environment-provider validation",
        "checks public provider capability identity and declared network boundary only"
      ]
    },
    "fixture.artifact.environment_provider_capability.constant_earth_rotation" => %{
      "id" => "fixture.artifact.environment_provider_capability.constant_earth_rotation",
      "model_id" => "artifact.environment_provider_capability.v1",
      "reference_case" => "runtime constant Earth rotation environment provider capability",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_runtime_capability_regression",
      "inputs" => %{
        "source_facade" => "OrbitalDynamics.Environment.provider_capabilities/0",
        "capability_id" => "environment.provider.earth_rotation.constant_rate",
        "contract" => "environment_provider_capability.v1"
      },
      "expected" => %{
        "schema_contract" => "environment_provider_capability.v1",
        "id" => "environment.provider.earth_rotation.constant_rate",
        "category" => "body_rotation",
        "model" => "constant_earth_rotation",
        "source" => "internal_simplified_geometry",
        "validation_level" => "assumption_declared",
        "interpolation" => "analytic_constant_rate",
        "coverage_policy" => "all_times",
        "coverage_time_scale" => "seconds_since_j2000",
        "output_count" => 3,
        "supported_body_count" => 1,
        "network_access" => false,
        "parameter_count" => 2,
        "known_limit_count" => 3
      },
      "tolerances" => %{
        "output_count" => 0,
        "supported_body_count" => 0,
        "parameter_count" => 0,
        "known_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-validated from OrbitalDynamics.Environment.provider_capabilities/0"
      ],
      "known_limits" => [
        "runtime capability regression, not external environment-provider validation",
        "checks public provider capability identity and declared network boundary only"
      ]
    },
    "fixture.artifact.environment_provider_capability.tabular_earth_orientation" => %{
      "id" => "fixture.artifact.environment_provider_capability.tabular_earth_orientation",
      "model_id" => "artifact.environment_provider_capability.v1",
      "reference_case" =>
        "runtime declared table Earth orientation environment provider capability",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_runtime_capability_regression",
      "inputs" => %{
        "source_facade" => "OrbitalDynamics.Environment.provider_capabilities/0",
        "capability_id" => "environment.provider.earth_orientation.tabular_rotation",
        "contract" => "environment_provider_capability.v1"
      },
      "expected" => %{
        "schema_contract" => "environment_provider_capability.v1",
        "id" => "environment.provider.earth_orientation.tabular_rotation",
        "category" => "body_rotation",
        "model" => "tabular_earth_orientation_rotation",
        "source" => "declared_earth_orientation_table",
        "validation_level" => "assumption_declared",
        "interpolation" => "linear_declared_rotation_sample",
        "coverage_policy" => "declared_samples",
        "coverage_time_scale" => "seconds_since_j2000",
        "output_count" => 3,
        "supported_body_count" => 1,
        "network_access" => false,
        "parameter_count" => 2,
        "known_limit_count" => 4
      },
      "tolerances" => %{
        "output_count" => 0,
        "supported_body_count" => 0,
        "parameter_count" => 0,
        "known_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-validated from OrbitalDynamics.Environment.provider_capabilities/0"
      ],
      "known_limits" => [
        "runtime capability regression, not external environment-provider validation",
        "checks public provider capability identity and declared network boundary only"
      ]
    },
    "fixture.artifact.environment_provider_capability.exponential_atmosphere" => %{
      "id" => "fixture.artifact.environment_provider_capability.exponential_atmosphere",
      "model_id" => "artifact.environment_provider_capability.v1",
      "reference_case" => "runtime exponential atmosphere environment provider capability",
      "validation_level" => "artifact_contract",
      "fixture_type" => "curated_runtime_capability_regression",
      "inputs" => %{
        "source_facade" => "OrbitalDynamics.Environment.provider_capabilities/0",
        "capability_id" => "environment.provider.atmosphere.exponential_reference",
        "contract" => "environment_provider_capability.v1"
      },
      "expected" => %{
        "schema_contract" => "environment_provider_capability.v1",
        "id" => "environment.provider.atmosphere.exponential_reference",
        "category" => "atmosphere_density",
        "model" => "single_scale_height_exponential_atmosphere",
        "source" => "internal_reference_model",
        "validation_level" => "assumption_declared",
        "interpolation" => "analytic_single_scale_height",
        "coverage_policy" => "all_times",
        "coverage_time_scale" => "seconds_since_j2000",
        "output_count" => 2,
        "supported_body_count" => 1,
        "network_access" => false,
        "parameter_count" => 3,
        "known_limit_count" => 3
      },
      "tolerances" => %{
        "output_count" => 0,
        "supported_body_count" => 0,
        "parameter_count" => 0,
        "known_limit_count" => 0
      },
      "evidence" => [
        "checked by OrbitalDynamics.Validation.verify_reference_fixture/2",
        "schema-validated from OrbitalDynamics.Environment.provider_capabilities/0"
      ],
      "known_limits" => [
        "runtime capability regression, not external environment-provider validation",
        "checks public provider capability identity and declared network boundary only"
      ]
    }
  }

  def all, do: @fixtures
end
