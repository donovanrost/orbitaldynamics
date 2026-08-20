defmodule OrbitalDynamics.Validation.ExternalTruth.OrekitLeoCase do
  @moduledoc """
  Content-bound Orekit comparison for one exact six-hour Earth J2-drag LEO case.

  `verify/1` first verifies every source/result identity in the checked-in
  bundle, then independently runs the declared scalar OrbitalDynamics J2Drag,
  access, and eclipse paths. The result is a standalone
  `validation_reference_report.v1`; it is intentionally not part of the shared
  aggregate fixture rollup.
  """

  alias OrbitalDynamics.EventDetectors.{AccessWindows, Eclipses}
  alias OrbitalDynamics.Propagators.J2Drag
  alias OrbitalDynamics.Validation.ExternalTruth.StrictBundle

  alias OrbitalDynamics.{
    CentralBody,
    Epoch,
    Frame,
    GroundStation,
    Scenario,
    Spacecraft,
    StateVector
  }

  @case_id "external_truth.orekit_13_1_7.earth_j2_drag_rk4_10s_access_eclipse_6h"
  @model_id "earth_j2_drag_rk4_10s_spherical_access_fixed_sun_cylindrical_eclipse_6h"
  @bundle_relative_path "priv/validation/external_truth/orekit_13_1_7_leo_j2_drag_access_eclipse"

  @manifest_sha256 "f4dbcf59007ac1552bb447d13aa9166b7846d393e7fc23d1d60a04fa841e91cd"
  @manifest_byte_count 7_694
  @source_manifest_sha256 "4b6e875b2cbee2c20e83b268c5b07cedeb8c6ff96ce36a2de7dbf9741a217c93"
  @source_manifest_byte_count 455
  @result_sha256 "88f0ab20bd24a78bda74cfa8091f9e0546e85eee0e2c4719bde988ad2c66649f"
  @result_byte_count 549_022

  @source_files [
    %{
      path: "case.properties",
      byte_count: 1_323,
      sha256: "9f391cb0314f68dda8eaef851626b5ef3b2448e0623359bb5ebb5699b970106d"
    },
    %{
      path: "pom.xml",
      byte_count: 828,
      sha256: "325f8acbb143b0861994ae2f62290e4dd1d24499e25690addb04150a268c2651"
    },
    %{
      path: "dependencies.lock",
      byte_count: 1_536,
      sha256: "90b0b2e85a0fae9d586567895c894f0d59ce835e84127ba088cd9a2ed84ce388"
    },
    %{
      path: "generate.sh",
      byte_count: 1_925,
      sha256: "04ebbd4172379cb064516bfe6efed9e4b1fc4595e932d6c84a81ebc6b2cfba45"
    },
    %{
      path: "src/main/java/org/orbitaldynamics/validation/OrekitTruthGenerator.java",
      byte_count: 21_504,
      sha256: "a420e8a12e149cc69ce879e0768f96028b974b6e0816ce8fd4decedb418aec74"
    }
  ]
  @source_total_byte_count 27_116

  @horizon_s 21_600.0
  @output_step_s 10.0
  @max_step_s 10.0
  @initial_position_km {7_000.0, 0.0, 0.0}
  @initial_velocity_km_s {0.0, 4.68721425101214, 5.913792592089408}
  @spacecraft_dry_mass_kg 100.0
  @spacecraft_propellant_mass_kg 20.0
  @spacecraft_mass_kg @spacecraft_dry_mass_kg + @spacecraft_propellant_mass_kg
  @spacecraft_drag_area_m2 4.0
  @spacecraft_drag_coefficient 2.2
  @station_latitude_deg 0.0
  @station_longitude_deg -60.0
  @station_altitude_km 0.0
  @station_minimum_elevation_deg 5.0
  @access_root_tolerance_s 1.0e-6
  @access_root_max_iterations 64
  @sun_direction {1.0, 0.0, 0.0}
  @state_epochs_s Enum.map(0..2_160, &(&1 * @output_step_s))
  @position_tolerance_m 0.01
  @velocity_tolerance_m_s 0.00001
  @access_tolerance_s 0.001
  @eclipse_tolerance_s 0.05

  @expected_config %{
    "atmosphere_model" => "SimpleExponentialAtmosphere",
    "atmosphere_reference_altitude_m" => "400000.0",
    "atmosphere_reference_density_kg_m3" => "3.89e-12",
    "atmosphere_scale_height_m" => "60000.0",
    "atmospheric_refraction" => "none",
    "body_flattening" => "0.0",
    "case_id" => "orekit_13_1_7_earth_j2_drag_rk4_10s_access_eclipse_6h",
    "earth_rotation_angle_at_epoch_rad" => "0.0",
    "earth_rotation_rate_rad_s" => "7.2921150e-5",
    "eclipse_model" => "cylindrical_spherical_body",
    "eop_source" => "none",
    "ephemeris_source" => "fixed_sun_direction_input",
    "epoch" => "2000-01-01T12:00:00_TDB",
    "equatorial_radius_m" => "6378136.3",
    "event_max_check_s" => "60.0",
    "event_max_iterations" => "100",
    "event_threshold_s" => "1.0e-9",
    "frame" => "EME2000",
    "generated_at_utc" => "2026-08-20T09:10:00Z",
    "horizon_s" => "21600.0",
    "initial_position_m" => "7000000.0,0.0,0.0",
    "initial_velocity_m_s" => "0.0,4687.21425101214,5913.792592089408",
    "integrator" => "ClassicalRungeKuttaIntegrator",
    "integrator_step_s" => "10.0",
    "j2" => "1.08262668e-3",
    "mu_m3_s2" => "3.986004418e14",
    "orekit_data_revision" => "none",
    "orekit_version" => "13.1.7",
    "output_float_format" => "%.17e",
    "spacecraft_drag_area_m2" => "4.0",
    "spacecraft_drag_coefficient" => "2.2",
    "spacecraft_mass_kg" => "120.0",
    "state_output_end_s" => "21600.0",
    "state_output_start_s" => "0.0",
    "state_output_step_s" => "10.0",
    "station_altitude_m" => "0.0",
    "station_latitude_deg" => "0.0",
    "station_longitude_deg" => "-60.0",
    "station_minimum_elevation_deg" => "5.0",
    "sun_direction_eme2000" => "1.0,0.0,0.0",
    "sun_provider_distance_m" => "1.0e11",
    "terrain_mask" => "none",
    "time_scale" => "TDB_J2000_RELATIVE_SECONDS"
  }

  @expected_dependencies [
    %{
      filename: "orekit-13.1.7.jar",
      sha256: "43ab5155fd327ca39287caa5440d9ae50473d911eda1b7f0e819197dcfbf63b3",
      url: "https://repo.maven.apache.org/maven2/org/orekit/orekit/13.1.7/orekit-13.1.7.jar"
    },
    %{
      filename: "hipparchus-core-4.0.3.jar",
      sha256: "5af54dc3c21b8d85e1264157ee91d93fa67e68c825cfb38834dc2bbb9b0f6583",
      url:
        "https://repo.maven.apache.org/maven2/org/hipparchus/hipparchus-core/4.0.3/hipparchus-core-4.0.3.jar"
    },
    %{
      filename: "hipparchus-geometry-4.0.3.jar",
      sha256: "19594d5106ec6a46951e859e2924bfcade02a834c06c56bd3d2130a74f0fbb7e",
      url:
        "https://repo.maven.apache.org/maven2/org/hipparchus/hipparchus-geometry/4.0.3/hipparchus-geometry-4.0.3.jar"
    },
    %{
      filename: "hipparchus-ode-4.0.3.jar",
      sha256: "75f0f0b3fdcd99d13e9c394b7ae809cce5a9c22f1c14b1b90a5109ed951467fe",
      url:
        "https://repo.maven.apache.org/maven2/org/hipparchus/hipparchus-ode/4.0.3/hipparchus-ode-4.0.3.jar"
    },
    %{
      filename: "hipparchus-fitting-4.0.3.jar",
      sha256: "3712c3b4f43d9c12bf7b7aad187764f4b3c09cc962504899d8951eb310b1e4be",
      url:
        "https://repo.maven.apache.org/maven2/org/hipparchus/hipparchus-fitting/4.0.3/hipparchus-fitting-4.0.3.jar"
    },
    %{
      filename: "hipparchus-optim-4.0.3.jar",
      sha256: "4bc0dbb5c6d5fefda5db9d92141c6cbb807174a1d491a85df46bcc57a67b8992",
      url:
        "https://repo.maven.apache.org/maven2/org/hipparchus/hipparchus-optim/4.0.3/hipparchus-optim-4.0.3.jar"
    },
    %{
      filename: "hipparchus-filtering-4.0.3.jar",
      sha256: "279eece43411f372bd8340355cb89101def0bf9b1b6824231b76181d1ec63a81",
      url:
        "https://repo.maven.apache.org/maven2/org/hipparchus/hipparchus-filtering/4.0.3/hipparchus-filtering-4.0.3.jar"
    },
    %{
      filename: "hipparchus-stat-4.0.3.jar",
      sha256: "8b066e3060dc119efcce241fb0720a3b9e59c026d0f5fe9e70abfd5e22d3817b",
      url:
        "https://repo.maven.apache.org/maven2/org/hipparchus/hipparchus-stat/4.0.3/hipparchus-stat-4.0.3.jar"
    }
  ]

  @expected_reference_tool %{
    "name" => "Apache Orekit",
    "version" => "13.1.7",
    "release_commit" => "cc18cc1",
    "license" => "Apache-2.0",
    "official_release_url" => "https://github.com/CS-SI/Orekit/releases/tag/13.1.7",
    "official_api_url" => "https://www.orekit.org/static/apidocs/",
    "container_image" => "docker.io/library/maven:3.9.11-eclipse-temurin-21",
    "container_digest" =>
      "sha256:6fdc855a6ed81d288ca7ca37ac6ff5e9308b612485c0801d70b25a858c83d237",
    "container_image_id" =>
      "sha256:3ead0ff36a4b796440e451013a4ce803dbd02f07b6c5b634cc2ad67927dfcc10",
    "container_platform" => "linux/arm64",
    "java_runtime" => "21.0.9+10-LTS",
    "maven_version" => "3.9.11",
    "curl_version" => "8.5.0"
  }

  @expected_dependency_declaration %{
    "lock_path" => "dependencies.lock",
    "orekit" => "org.orekit:orekit:13.1.7",
    "hipparchus_version" => "4.0.3",
    "artifact_count" => 8,
    "checksum_algorithm" => "sha256",
    "repository" => "https://repo.maven.apache.org/maven2/"
  }

  @expected_data_sources %{
    "orekit_data_revision" => "none",
    "eop_source" => "none",
    "earth_orientation_model" => "constant_z_axis_rotation_from_zero_angle_at_case_epoch",
    "sun_source" => "fixed_unit_direction_from_case.properties",
    "sun_direction_eme2000" => [1.0, 0.0, 0.0],
    "sun_provider_distance_m" => 100_000_000_000.0,
    "network_data_used_during_propagation" => false
  }

  @expected_reference_model %{
    "frame" => "EME2000",
    "epoch" => "2000-01-01T12:00:00_TDB",
    "time_scale" => "TDB_J2000_RELATIVE_SECONDS",
    "horizon_starts_at_s" => 0.0,
    "horizon_ends_at_s" => @horizon_s,
    "state_output_grid" => %{
      "starts_at_s" => 0.0,
      "ends_at_s" => @horizon_s,
      "step_s" => @output_step_s,
      "epoch_count" => 2_161,
      "coverage_policy" => "inclusive_full_horizon_exact_grid"
    },
    "position_unit" => "meter",
    "velocity_unit" => "meter_per_second",
    "mu_m3_s2" => 398_600_441_800_000.0,
    "equatorial_radius_m" => 6_378_136.3,
    "j2" => 1.08262668e-3,
    "initial_position_m" => [7_000_000.0, 0.0, 0.0],
    "initial_velocity_m_s" => [0.0, 4_687.21425101214, 5_913.792592089408],
    "force_models" => [
      "NewtonianAttraction",
      "J2OnlyPerturbation",
      "DragForce",
      "SimpleExponentialAtmosphere",
      "IsotropicDrag"
    ],
    "excluded_force_models" => [
      "third_body",
      "solid_tides",
      "solar_radiation_pressure",
      "maneuvers"
    ],
    "atmosphere_model" => "SimpleExponentialAtmosphere",
    "atmosphere_reference_altitude_m" => 400_000.0,
    "atmosphere_reference_density_kg_m3" => 3.89e-12,
    "atmosphere_scale_height_m" => 60_000.0,
    "atmosphere_rotation" => "rigid_constant_rate_body_frame",
    "spacecraft_mass_kg" => @spacecraft_mass_kg,
    "spacecraft_drag_area_m2" => @spacecraft_drag_area_m2,
    "spacecraft_drag_coefficient" => @spacecraft_drag_coefficient,
    "orbit_type" => "CARTESIAN",
    "integrator" => "ClassicalRungeKuttaIntegrator",
    "integrator_step_s" => @max_step_s
  }

  @expected_access_model %{
    "detector" => "ElevationDetector",
    "body_shape" => "OneAxisEllipsoid_sphere",
    "body_flattening" => 0.0,
    "earth_rotation_rate_rad_s" => 7.292115e-5,
    "earth_rotation_angle_at_epoch_rad" => 0.0,
    "station_latitude_deg" => @station_latitude_deg,
    "station_longitude_deg" => @station_longitude_deg,
    "station_altitude_m" => @station_altitude_km * 1_000.0,
    "minimum_elevation_deg" => @station_minimum_elevation_deg,
    "atmospheric_refraction" => "none",
    "terrain_mask" => "none",
    "event_definition" =>
      "aos_is_increasing_zero_of_geometric_elevation_minus_5_deg;los_is_decreasing_zero",
    "max_check_s" => 60.0,
    "root_threshold_s" => 1.0e-9,
    "max_iterations" => 100
  }

  @expected_eclipse_model %{
    "detector" => "CylindricalShadowEclipseDetector",
    "occulting_body" => "spherical_earth",
    "occulting_body_radius_m" => 6_378_136.3,
    "light_source" => "infinitely_distant_fixed_positive_eme2000_x_direction",
    "event_definition" =>
      "ingress_is_decreasing_zero_and_egress_is_increasing_zero_of_cylindrical_shadow_switching_function",
    "penumbra" => "none",
    "max_check_s" => 60.0,
    "root_threshold_s" => 1.0e-9,
    "max_iterations" => 100
  }

  @expected_orbital_dynamics_path %{
    "propagator" => "OrbitalDynamics.Propagators.J2Drag",
    "frame" => "earth_inertial_j2000",
    "epoch_scale" => "tdb",
    "output_step_s" => @output_step_s,
    "max_step_s" => @max_step_s,
    "atmosphere_provider" => "OrbitalDynamics.Environment.ExponentialAtmosphereProvider",
    "atmosphere_source_revision" => "exponential-reference.v1",
    "earth_rotation_provider" => "OrbitalDynamics.Environment.ConstantEarthRotationProvider",
    "earth_rotation_source_revision" => "constant-earth-rotation.v1",
    "spacecraft_mass_kg" => @spacecraft_mass_kg,
    "spacecraft_drag_area_m2" => @spacecraft_drag_area_m2,
    "spacecraft_drag_coefficient" => @spacecraft_drag_coefficient,
    "access_detector" => "OrbitalDynamics.EventDetectors.AccessWindows",
    "access_boundary_refinement" => "bracketed_bisection_cubic_hermite_state",
    "access_root_tolerance_s" => @access_root_tolerance_s,
    "access_root_max_iterations" => @access_root_max_iterations,
    "eclipse_detector" => "OrbitalDynamics.EventDetectors.Eclipses",
    "eclipse_boundary_refinement" => "linear_shadow_margin_between_10s_samples"
  }

  @expected_tolerances %{
    "position_max_component_error_m" => @position_tolerance_m,
    "velocity_max_component_error_m_s" => @velocity_tolerance_m_s,
    "access_boundary_absolute_error_s" => @access_tolerance_s,
    "eclipse_boundary_absolute_error_s" => @eclipse_tolerance_s
  }

  @expected_output %{
    "format" => "JSON",
    "schema" => "orekit_external_truth_raw.v1",
    "float_format" => "%.17e",
    "state_epoch_count" => 2_161,
    "access_boundary_count" => 4,
    "eclipse_boundary_count" => 8
  }

  @expected_claim_boundary %{
    "validated_combination" =>
      "earth_j2_plus_simple_exponential_atmospheric_drag_rk4_10s_plus_spherical_constant_rotation_access_plus_fixed_sun_cylindrical_eclipse_over_0_to_21600_tdb_seconds",
    "not_promoted" => [
      "two_body",
      "j2_only",
      "two_body_drag",
      "accelerator_backends",
      "linear_access_boundary_mode",
      "time_varying_sun_provider",
      "campaign_environment_provider",
      "conical_eclipse",
      "other_atmosphere_providers",
      "other_ballistic_coefficients",
      "other_stations",
      "other_initial_states",
      "other_horizons"
    ],
    "not_claimed" => [
      "flight_certification",
      "operational_acceptance",
      "full_physical_fidelity",
      "authoritative_earth_orientation",
      "space_weather_calibrated_atmosphere",
      "winds",
      "terrain_or_refraction_effects"
    ]
  }

  @expected_semantic_manifest %{
    "schema" => "external_numerical_truth_bundle.v1",
    "case_id" => "orekit_13_1_7_earth_j2_drag_rk4_10s_access_eclipse_6h",
    "validation_status" => "validated_external_reference_for_exact_declared_case",
    "generated_at_utc" => "2026-08-20T09:10:00Z",
    "reference_tool" => @expected_reference_tool,
    "dependencies" => @expected_dependency_declaration,
    "data_sources" => @expected_data_sources,
    "reference_model" => @expected_reference_model,
    "access_model" => @expected_access_model,
    "eclipse_model" => @expected_eclipse_model,
    "orbital_dynamics_path" => @expected_orbital_dynamics_path,
    "tolerances" => @expected_tolerances,
    "output" => @expected_output,
    "claim_boundary" => @expected_claim_boundary
  }

  @doc "Returns the stable registration for this exact external truth case."
  def registration do
    %{
      "id" => @case_id,
      "model" => @model_id,
      "implementation" => __MODULE__ |> Atom.to_string() |> String.trim_leading("Elixir."),
      "validation_level" => "validated",
      "covered_regime" =>
        "all 2161 ten-second states for one Earth/EME2000/TDB J2-plus-simple-exponential-drag RK4 LEO case, spherical constant-rate access, and fixed-Sun cylindrical eclipse boundaries over 0..21600 s",
      "tolerances" => %{
        "position_max_component_error_m" => @position_tolerance_m,
        "velocity_max_component_error_m_s" => @velocity_tolerance_m_s,
        "access_boundary_absolute_error_s" => @access_tolerance_s,
        "eclipse_boundary_absolute_error_s" => @eclipse_tolerance_s
      },
      "evidence" => [
        "content-bound Apache Orekit 13.1.7 raw output",
        "independent executable comparison through OrbitalDynamics.Propagators.J2Drag, AccessWindows, and Eclipses"
      ],
      "intended_uses" => ["numerical_regression", "bounded_analysis_evidence"],
      "known_limits" => [
        "registration applies only to the exact combined case and finite horizon",
        "drag evidence applies only to the pinned exponential atmosphere, constant co-rotation, 120 kg mass, 4 m2 area, and coefficient 2.2",
        "fixed Sun direction, spherical station geometry, constant Earth rotation, and cylindrical shadow",
        "no EOP, space-weather calibration, winds, terrain, refraction, third body, tides, SRP, or maneuvers",
        "not flight certification or operational acceptance"
      ]
    }
  end

  @doc "Returns the installed bundle directory."
  def bundle_path do
    Application.app_dir(:orbital_dynamics, @bundle_relative_path)
  end

  @doc "Verifies the checked-in bundle and independently executes the exact project path."
  def verify(opts \\ [])

  def verify(opts) when is_list(opts) do
    root = Keyword.get(opts, :bundle_path, bundle_path())

    case StrictBundle.load(root, expectations()) do
      {:ok, bundle} -> verify_loaded_bundle(bundle)
      {:error, reason} -> {:error, failure_report(reason)}
    end
  end

  def verify(_opts), do: {:error, failure_report(:invalid_verifier_options)}

  @doc false
  def observations do
    try do
      body = CentralBody.earth()

      scenario =
        Scenario.new!(
          :orekit_external_truth_case,
          Spacecraft.new!(:orekit_external_truth_satellite, @spacecraft_dry_mass_kg,
            propellant_mass_kg: @spacecraft_propellant_mass_kg,
            area_m2: @spacecraft_drag_area_m2,
            drag_coefficient: @spacecraft_drag_coefficient
          ),
          StateVector.new!(
            @initial_position_km,
            @initial_velocity_km_s,
            Epoch.new!(0.0, :tdb),
            Frame.earth_inertial_j2000()
          ),
          duration_s: @horizon_s,
          output_step_s: @output_step_s,
          central_body: body
        )

      with {:ok, trajectory} <- J2Drag.propagate(scenario, max_step_s: @max_step_s),
           {:ok, access_events} <- detect_access(trajectory, body),
           {:ok, eclipse_events} <- detect_eclipses(trajectory, body) do
        {:ok,
         %{
           states: observed_states(trajectory),
           access: observed_access_boundaries(access_events),
           eclipse: observed_eclipse_boundaries(eclipse_events),
           path_identity: path_identity(trajectory, access_events, eclipse_events),
           runtime_semantics:
             runtime_semantics(scenario, body, trajectory, access_events, eclipse_events),
           horizon: observed_horizon(trajectory)
         }}
      end
    rescue
      error -> {:error, {:orbital_dynamics_execution_failed, Exception.message(error)}}
    catch
      kind, reason -> {:error, {:orbital_dynamics_execution_failed, {kind, reason}}}
    end
  end

  @doc false
  def compare_observations(observations, opts \\ [])

  def compare_observations(observations, opts) when is_map(observations) and is_list(opts) do
    root = Keyword.get(opts, :bundle_path, bundle_path())

    case StrictBundle.load(root, expectations()) do
      {:ok, bundle} -> compare_loaded_bundle(bundle, observations)
      {:error, reason} -> {:error, failure_report(reason)}
    end
  end

  def compare_observations(_observations, _opts),
    do: {:error, failure_report(:invalid_observations)}

  defp expectations do
    %{
      manifest_sha256: @manifest_sha256,
      manifest_byte_count: @manifest_byte_count,
      source_manifest_sha256: @source_manifest_sha256,
      source_manifest_byte_count: @source_manifest_byte_count,
      result_sha256: @result_sha256,
      result_byte_count: @result_byte_count,
      source_files: @source_files,
      source_total_byte_count: @source_total_byte_count
    }
  end

  defp verify_loaded_bundle(bundle) do
    with {:ok, _semantic_checks} <- validate_bundle_semantics(bundle),
         {:ok, observed} <- observations() do
      compare_loaded_bundle(bundle, observed)
    else
      {:error, %{} = report} -> {:error, report}
      {:error, reason} -> {:error, failure_report(reason)}
    end
  end

  defp compare_loaded_bundle(bundle, observations) do
    case validate_bundle_semantics(bundle) do
      {:ok, semantic_checks} ->
        checks =
          semantic_checks ++ comparison_checks(bundle.reference, bundle.manifest, observations)

        report_result(checks)

      {:error, report} ->
        {:error, report}
    end
  end

  @doc false
  def validate_semantic_seal(bundle) when is_map(bundle) do
    checks = manifest_checks(bundle)

    if passing?(checks) do
      {:ok, checks}
    else
      {:error, report(checks)}
    end
  end

  def validate_semantic_seal(_bundle),
    do: {:error, failure_report(:invalid_semantic_seal_input)}

  defp validate_bundle_semantics(bundle) do
    checks = identity_checks(bundle) ++ manifest_checks(bundle)

    reference_shape_check =
      case validate_reference_shape(bundle.reference, bundle.manifest) do
        :ok ->
          exact_check("reference_output.structure", "complete_and_unique", "complete_and_unique")

        {:error, reason} ->
          exact_check("reference_output.structure", "complete_and_unique", reason)
      end

    checks = checks ++ [reference_shape_check]

    if passing?(checks) do
      {:ok, checks}
    else
      {:error, report(checks)}
    end
  end

  defp identity_checks(bundle) do
    [
      exact_check("bundle.manifest_sha256", @manifest_sha256, sha256(bundle.manifest_bytes)),
      exact_check(
        "bundle.source_manifest_sha256",
        @source_manifest_sha256,
        sha256(bundle.source_manifest_bytes)
      ),
      exact_check("bundle.result_sha256", @result_sha256, sha256(bundle.reference_bytes)),
      exact_check("bundle.case_properties", @expected_config, bundle.config),
      exact_check("bundle.dependencies", @expected_dependencies, bundle.dependencies)
    ]
  end

  defp manifest_checks(bundle) do
    manifest = Map.get(bundle, :manifest, %{})

    semantic_manifest =
      Map.drop(manifest, ["source_identity", "result_identity", "bundle_read_limits"])

    expected_keys =
      @expected_semantic_manifest
      |> Map.keys()
      |> Kernel.++(["source_identity", "result_identity", "bundle_read_limits"])
      |> Enum.sort()

    [
      exact_check("bundle.manifest.keys", expected_keys, manifest |> Map.keys() |> Enum.sort()),
      exact_check(
        "bundle.manifest.semantic_declarations",
        @expected_semantic_manifest,
        semantic_manifest
      ),
      exact_check(
        "bundle.manifest.case_properties_semantics",
        config_semantic_projection(Map.get(bundle, :config, %{})),
        manifest_config_projection(manifest)
      ),
      exact_check(
        "bundle.manifest.dependency_lock_semantics",
        dependency_semantic_projection(Map.get(bundle, :dependencies, [])),
        manifest["dependencies"]
      ),
      exact_check(
        "bundle.manifest.generator_container_ref",
        expected_generator_container_ref(manifest),
        generator_container_ref(Map.get(bundle, :source_bytes, %{}))
      ),
      exact_check(
        "bundle.manifest.toolchain_source_semantics",
        expected_toolchain_source_semantics(manifest),
        toolchain_source_semantics(Map.get(bundle, :source_bytes, %{}))
      )
    ]
  end

  defp config_semantic_projection(config) do
    %{
      "case_id" => config["case_id"],
      "generated_at_utc" => config["generated_at_utc"],
      "orekit_version" => config["orekit_version"],
      "reference_model" => %{
        "frame" => config["frame"],
        "epoch" => config["epoch"],
        "time_scale" => config["time_scale"],
        "horizon_starts_at_s" => config_number(config, "state_output_start_s"),
        "horizon_ends_at_s" => config_number(config, "horizon_s"),
        "state_output_grid" => %{
          "starts_at_s" => config_number(config, "state_output_start_s"),
          "ends_at_s" => config_number(config, "state_output_end_s"),
          "step_s" => config_number(config, "state_output_step_s")
        },
        "mu_m3_s2" => config_number(config, "mu_m3_s2"),
        "equatorial_radius_m" => config_number(config, "equatorial_radius_m"),
        "j2" => config_number(config, "j2"),
        "initial_position_m" => config_vector(config, "initial_position_m"),
        "initial_velocity_m_s" => config_vector(config, "initial_velocity_m_s"),
        "atmosphere_model" => config["atmosphere_model"],
        "atmosphere_reference_altitude_m" =>
          config_number(config, "atmosphere_reference_altitude_m"),
        "atmosphere_reference_density_kg_m3" =>
          config_number(config, "atmosphere_reference_density_kg_m3"),
        "atmosphere_scale_height_m" => config_number(config, "atmosphere_scale_height_m"),
        "spacecraft_mass_kg" => config_number(config, "spacecraft_mass_kg"),
        "spacecraft_drag_area_m2" => config_number(config, "spacecraft_drag_area_m2"),
        "spacecraft_drag_coefficient" => config_number(config, "spacecraft_drag_coefficient"),
        "integrator" => config["integrator"],
        "integrator_step_s" => config_number(config, "integrator_step_s")
      },
      "data_sources" => %{
        "orekit_data_revision" => config["orekit_data_revision"],
        "eop_source" => config["eop_source"],
        "sun_direction_eme2000" => config_vector(config, "sun_direction_eme2000"),
        "sun_provider_distance_m" => config_number(config, "sun_provider_distance_m")
      },
      "access_model" => %{
        "body_flattening" => config_number(config, "body_flattening"),
        "earth_rotation_rate_rad_s" => config_number(config, "earth_rotation_rate_rad_s"),
        "earth_rotation_angle_at_epoch_rad" =>
          config_number(config, "earth_rotation_angle_at_epoch_rad"),
        "station_latitude_deg" => config_number(config, "station_latitude_deg"),
        "station_longitude_deg" => config_number(config, "station_longitude_deg"),
        "station_altitude_m" => config_number(config, "station_altitude_m"),
        "minimum_elevation_deg" => config_number(config, "station_minimum_elevation_deg"),
        "atmospheric_refraction" => config["atmospheric_refraction"],
        "terrain_mask" => config["terrain_mask"],
        "max_check_s" => config_number(config, "event_max_check_s"),
        "root_threshold_s" => config_number(config, "event_threshold_s"),
        "max_iterations" => config_number(config, "event_max_iterations")
      },
      "eclipse_model" => %{
        "occulting_body_radius_m" => config_number(config, "equatorial_radius_m"),
        "max_check_s" => config_number(config, "event_max_check_s"),
        "root_threshold_s" => config_number(config, "event_threshold_s"),
        "max_iterations" => config_number(config, "event_max_iterations")
      },
      "output" => %{"float_format" => config["output_float_format"]}
    }
  end

  defp manifest_config_projection(manifest) do
    %{
      "case_id" => manifest["case_id"],
      "generated_at_utc" => manifest["generated_at_utc"],
      "orekit_version" => get_in(manifest, ["reference_tool", "version"]),
      "reference_model" =>
        manifest
        |> Map.get("reference_model", %{})
        |> Map.take([
          "frame",
          "epoch",
          "time_scale",
          "horizon_starts_at_s",
          "horizon_ends_at_s",
          "mu_m3_s2",
          "equatorial_radius_m",
          "j2",
          "initial_position_m",
          "initial_velocity_m_s",
          "atmosphere_model",
          "atmosphere_reference_altitude_m",
          "atmosphere_reference_density_kg_m3",
          "atmosphere_scale_height_m",
          "spacecraft_mass_kg",
          "spacecraft_drag_area_m2",
          "spacecraft_drag_coefficient",
          "integrator",
          "integrator_step_s"
        ])
        |> Map.put(
          "state_output_grid",
          manifest
          |> get_in(["reference_model", "state_output_grid"])
          |> then(fn grid ->
            if is_map(grid), do: Map.take(grid, ~w(starts_at_s ends_at_s step_s)), else: grid
          end)
        ),
      "data_sources" =>
        manifest
        |> Map.get("data_sources", %{})
        |> Map.take(
          ~w(orekit_data_revision eop_source sun_direction_eme2000 sun_provider_distance_m)
        ),
      "access_model" =>
        manifest
        |> Map.get("access_model", %{})
        |> Map.take([
          "body_flattening",
          "earth_rotation_rate_rad_s",
          "earth_rotation_angle_at_epoch_rad",
          "station_latitude_deg",
          "station_longitude_deg",
          "station_altitude_m",
          "minimum_elevation_deg",
          "atmospheric_refraction",
          "terrain_mask",
          "max_check_s",
          "root_threshold_s",
          "max_iterations"
        ]),
      "eclipse_model" =>
        manifest
        |> Map.get("eclipse_model", %{})
        |> Map.take(~w(occulting_body_radius_m max_check_s root_threshold_s max_iterations)),
      "output" => manifest |> Map.get("output", %{}) |> Map.take(["float_format"])
    }
  end

  defp dependency_semantic_projection(dependencies) when is_list(dependencies) do
    orekit_version =
      dependencies
      |> Enum.find_value(&version_from_filename(&1.filename, ~r/^orekit-(.+)\.jar$/))

    hipparchus_versions =
      dependencies
      |> Enum.map(&version_from_filename(&1.filename, ~r/^hipparchus-[a-z]+-(.+)\.jar$/))
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    repository = "https://repo.maven.apache.org/maven2/"

    %{
      "lock_path" => "dependencies.lock",
      "orekit" => if(orekit_version, do: "org.orekit:orekit:#{orekit_version}"),
      "hipparchus_version" => single_value(hipparchus_versions),
      "artifact_count" => length(dependencies),
      "checksum_algorithm" =>
        if(Enum.all?(dependencies, &Regex.match?(~r/^[0-9a-f]{64}$/, &1.sha256)),
          do: "sha256",
          else: :invalid
        ),
      "repository" =>
        if(Enum.all?(dependencies, &String.starts_with?(&1.url, repository)),
          do: repository,
          else: :invalid
        )
    }
  end

  defp dependency_semantic_projection(dependencies), do: {:invalid_dependencies, dependencies}

  defp version_from_filename(filename, regex) do
    case Regex.run(regex, filename, capture: :all_but_first) do
      [version] -> version
      _match -> nil
    end
  end

  defp single_value([value]), do: value
  defp single_value(values), do: values

  defp expected_generator_container_ref(manifest) do
    "docker.io/library/maven@#{get_in(manifest, ["reference_tool", "container_digest"])}"
  end

  defp generator_container_ref(source_bytes) do
    source_bytes
    |> Map.get("generate.sh", "")
    |> extract_source_value(~r/container_image="([^"]+)"/)
  end

  defp expected_toolchain_source_semantics(manifest) do
    java_runtime = get_in(manifest, ["reference_tool", "java_runtime"])

    %{
      "container_platform" => get_in(manifest, ["reference_tool", "container_platform"]),
      "java_release" => java_runtime |> to_string() |> String.split(".") |> List.first(),
      "orekit_pom_version" => get_in(manifest, ["reference_tool", "version"]),
      "orekit_generator_version" => get_in(manifest, ["reference_tool", "version"])
    }
  end

  defp toolchain_source_semantics(source_bytes) do
    generate_script = Map.get(source_bytes, "generate.sh", "")
    pom = Map.get(source_bytes, "pom.xml", "")

    generator =
      Map.get(
        source_bytes,
        "src/main/java/org/orbitaldynamics/validation/OrekitTruthGenerator.java",
        ""
      )

    %{
      "container_platform" => extract_source_value(generate_script, ~r/--platform=([^\s\\]+)/),
      "java_release" => extract_source_value(generate_script, ~r/javac --release (\d+)/),
      "orekit_pom_version" => extract_source_value(pom, ~r/<orekit.version>([^<]+)</),
      "orekit_generator_version" =>
        extract_source_value(
          generator,
          ~r/exact\(config, "orekit_version", "([^"]+)"\)/
        )
    }
  end

  defp extract_source_value(bytes, regex) do
    case Regex.run(regex, bytes, capture: :all_but_first) do
      [value] -> value
      _match -> :missing
    end
  end

  defp config_number(config, key) do
    case Float.parse(Map.get(config, key, "")) do
      {value, ""} -> value
      _other -> {:invalid_number, key, Map.get(config, key)}
    end
  end

  defp config_vector(config, key) do
    values =
      config
      |> Map.get(key, "")
      |> String.split(",", trim: false)
      |> Enum.map(fn value ->
        case Float.parse(value) do
          {number, ""} -> number
          _other -> {:invalid_number, value}
        end
      end)

    if length(values) == 3 and Enum.all?(values, &is_number/1),
      do: values,
      else: {:invalid_vector, key, values}
  end

  defp validate_reference_shape(reference, manifest) when is_map(reference) do
    with :ok <-
           exact_keys(
             reference,
             ~w(case_id events generated_at_utc horizon_s identity model schema source_identity_sha256 states tool)
           ),
         :ok <- exact_keys(reference["tool"], ~w(java_runtime name version)),
         :ok <-
           exact_keys(
             reference["model"],
             ~w(access_detector drag eclipse_detector gravity integrator integrator_step_s orbit_type propagator)
           ),
         :ok <-
           exact_keys(
             reference["identity"],
             ~w(eop_source ephemeris_source epoch frame orekit_data_revision time_scale)
           ),
         :ok <- exact_keys(reference["events"], ~w(access eclipse)),
         :ok <- exact_reference_identity(reference, manifest),
         :ok <- validate_state_rows(reference["states"]),
         :ok <-
           validate_event_rows(reference["events"]["access"],
             expected_types: ~w(aos los aos los),
             horizon_s: @horizon_s
           ),
         :ok <-
           validate_event_rows(reference["events"]["eclipse"],
             expected_types: ~w(ingress egress ingress egress ingress egress ingress egress),
             horizon_s: @horizon_s
           ) do
      :ok
    end
  end

  defp validate_reference_shape(_reference, _manifest),
    do: {:error, :reference_output_must_be_object}

  defp exact_reference_identity(reference, manifest) do
    expected = %{
      "schema" => "orekit_external_truth_raw.v1",
      "case_id" => "orekit_13_1_7_earth_j2_drag_rk4_10s_access_eclipse_6h",
      "source_identity_sha256" => @source_manifest_sha256,
      "generated_at_utc" => "2026-08-20T09:10:00Z",
      "tool" => %{
        "name" => "Apache Orekit",
        "version" => "13.1.7",
        "java_runtime" => "21.0.9+10-LTS"
      },
      "model" => %{
        "propagator" => "NumericalPropagator",
        "orbit_type" => "CARTESIAN",
        "integrator" => "ClassicalRungeKuttaIntegrator",
        "integrator_step_s" => @max_step_s,
        "gravity" => "NewtonianAttraction_plus_J2OnlyPerturbation",
        "drag" => "DragForce_plus_SimpleExponentialAtmosphere_plus_IsotropicDrag",
        "access_detector" => "ElevationDetector",
        "eclipse_detector" => "CylindricalShadowEclipseDetector"
      },
      "identity" => %{
        "frame" => "EME2000",
        "epoch" => "2000-01-01T12:00:00_TDB",
        "time_scale" => "TDB_J2000_RELATIVE_SECONDS",
        "orekit_data_revision" => "none",
        "eop_source" => "none",
        "ephemeris_source" => "fixed_sun_direction_input"
      },
      "horizon_s" => @horizon_s
    }

    observed = Map.take(reference, Map.keys(expected))

    cond do
      expected != observed ->
        {:error, {:reference_identity_mismatch, expected, observed}}

      reference["horizon_s"] != get_in(manifest, ["reference_model", "horizon_ends_at_s"]) ->
        {:error, :reference_manifest_horizon_mismatch}

      true ->
        :ok
    end
  end

  defp validate_state_rows(states) when is_list(states) do
    epochs = Enum.map(states, &Map.get(&1, "epoch_s"))

    cond do
      length(states) != length(@state_epochs_s) ->
        {:error, {:state_epoch_count, length(states)}}

      epochs != @state_epochs_s ->
        {:error, {:state_epochs, epochs}}

      length(Enum.uniq(epochs)) != length(epochs) ->
        {:error, :duplicate_state_epochs}

      true ->
        validate_rows(states, fn row ->
          with :ok <- exact_keys(row, ~w(epoch_s position_m velocity_m_s)),
               true <- finite_number?(row["epoch_s"]),
               true <- numeric_triplet?(row["position_m"]),
               true <- numeric_triplet?(row["velocity_m_s"]) do
            :ok
          else
            false -> {:error, :malformed_state_row}
            {:error, _reason} = error -> error
          end
        end)
    end
  end

  defp validate_state_rows(_states), do: {:error, :states_must_be_array}

  defp validate_event_rows(rows, opts) when is_list(rows) do
    expected_types = Keyword.fetch!(opts, :expected_types)
    horizon_s = Keyword.fetch!(opts, :horizon_s)
    observed_types = Enum.map(rows, &Map.get(&1, "type"))
    event_keys = Enum.map(rows, &{Map.get(&1, "type"), Map.get(&1, "epoch_s")})

    cond do
      observed_types != expected_types ->
        {:error, {:event_type_sequence, expected_types, observed_types}}

      length(Enum.uniq(event_keys)) != length(event_keys) ->
        {:error, :duplicate_event_keys}

      not strictly_increasing?(Enum.map(rows, &Map.get(&1, "epoch_s"))) ->
        {:error, :non_increasing_event_epochs}

      true ->
        validate_rows(rows, fn row ->
          with :ok <- exact_keys(row, ~w(epoch_s type)),
               true <- is_binary(row["type"]),
               true <- finite_number?(row["epoch_s"]),
               true <- row["epoch_s"] >= 0.0 and row["epoch_s"] <= horizon_s do
            :ok
          else
            false -> {:error, :malformed_event_row}
            {:error, _reason} = error -> error
          end
        end)
    end
  end

  defp validate_event_rows(_rows, _opts), do: {:error, :events_must_be_arrays}

  defp comparison_checks(reference, manifest, observations) do
    [
      exact_check(
        "orbital_dynamics.manifest_runtime_semantics",
        runtime_manifest_projection(manifest),
        Map.get(observations, :runtime_semantics)
      ),
      exact_check(
        "orbital_dynamics.path_identity",
        expected_path_identity(),
        Map.get(observations, :path_identity)
      ),
      exact_check(
        "orbital_dynamics.horizon_coverage",
        %{starts_at_s: 0.0, ends_at_s: @horizon_s, sample_count: 2_161},
        Map.get(observations, :horizon)
      )
    ] ++
      state_checks(reference["states"], Map.get(observations, :states)) ++
      event_checks(
        "access",
        reference["events"]["access"],
        Map.get(observations, :access),
        @access_tolerance_s
      ) ++
      event_checks(
        "eclipse",
        reference["events"]["eclipse"],
        Map.get(observations, :eclipse),
        @eclipse_tolerance_s
      )
  end

  defp state_checks(reference_states, observed_states)
       when is_list(reference_states) and is_list(observed_states) do
    reference_states
    |> Enum.zip(observed_states)
    |> Enum.flat_map(fn {expected, observed} ->
      epoch = expected["epoch_s"]

      [
        numeric_check(
          "state.#{format_epoch(epoch)}.epoch_s",
          epoch,
          Map.get(observed, :epoch_s),
          0.0
        ),
        vector_check(
          "state.#{format_epoch(epoch)}.position_m",
          expected["position_m"],
          Map.get(observed, :position_m),
          @position_tolerance_m
        ),
        vector_check(
          "state.#{format_epoch(epoch)}.velocity_m_s",
          expected["velocity_m_s"],
          Map.get(observed, :velocity_m_s),
          @velocity_tolerance_m_s
        )
      ]
    end)
    |> then(fn checks ->
      if length(reference_states) == length(observed_states) do
        checks
      else
        [exact_check("state.count", length(reference_states), length(observed_states)) | checks]
      end
    end)
  end

  defp state_checks(reference_states, observed_states),
    do: [exact_check("state.rows", reference_states, observed_states)]

  defp event_checks(prefix, expected_rows, observed_rows, tolerance)
       when is_list(expected_rows) and is_list(observed_rows) do
    paired_checks =
      expected_rows
      |> Enum.zip(observed_rows)
      |> Enum.with_index(1)
      |> Enum.flat_map(fn {{expected, observed}, index} ->
        [
          exact_check("#{prefix}.#{index}.type", expected["type"], Map.get(observed, :type)),
          numeric_check(
            "#{prefix}.#{index}.epoch_s",
            expected["epoch_s"],
            Map.get(observed, :epoch_s),
            tolerance
          )
        ]
      end)

    if length(expected_rows) == length(observed_rows) do
      paired_checks
    else
      [
        exact_check("#{prefix}.count", length(expected_rows), length(observed_rows))
        | paired_checks
      ]
    end
  end

  defp event_checks(prefix, expected_rows, observed_rows, _tolerance),
    do: [exact_check("#{prefix}.rows", expected_rows, observed_rows)]

  defp detect_access(trajectory, body) do
    station =
      GroundStation.new!(
        :orekit_external_truth_station,
        @station_latitude_deg,
        @station_longitude_deg,
        altitude_km: @station_altitude_km,
        minimum_elevation_deg: @station_minimum_elevation_deg
      )

    AccessWindows.detect(trajectory,
      ground_station: station,
      central_body: body,
      boundary_refinement: :bracketed_bisection,
      root_tolerance_s: @access_root_tolerance_s,
      root_max_iterations: @access_root_max_iterations
    )
  end

  defp detect_eclipses(trajectory, body) do
    Eclipses.detect(trajectory,
      central_body: body,
      sun_direction: @sun_direction
    )
  end

  defp observed_states(trajectory) do
    states_by_epoch =
      Map.new(trajectory.states, fn state -> {state.epoch.seconds_since_j2000, state} end)

    Enum.map(@state_epochs_s, fn epoch_s ->
      case Map.fetch(states_by_epoch, epoch_s) do
        {:ok, state} ->
          %{
            epoch_s: epoch_s,
            position_m: state.position_km |> Tuple.to_list() |> Enum.map(&(&1 * 1_000.0)),
            velocity_m_s: state.velocity_km_s |> Tuple.to_list() |> Enum.map(&(&1 * 1_000.0))
          }

        :error ->
          %{epoch_s: epoch_s, position_m: nil, velocity_m_s: nil}
      end
    end)
  end

  defp observed_access_boundaries(events) do
    Enum.flat_map(events, fn event ->
      [
        %{type: "aos", epoch_s: event.starts_at.seconds_since_j2000},
        %{type: "los", epoch_s: event.ends_at.seconds_since_j2000}
      ]
    end)
  end

  defp observed_eclipse_boundaries(events) do
    Enum.flat_map(events, fn event ->
      [
        %{type: "ingress", epoch_s: event.starts_at.seconds_since_j2000},
        %{type: "egress", epoch_s: event.ends_at.seconds_since_j2000}
      ]
    end)
  end

  defp path_identity(trajectory, access_events, eclipse_events) do
    assumptions = trajectory.assumptions

    %{
      propagator: "OrbitalDynamics.Propagators.J2Drag",
      force_model: assumptions.force_model,
      force_models: assumptions.force_models,
      force_composition: assumptions.force_composition,
      numerical_method: assumptions.numerical_method,
      frame: assumptions.frame,
      epoch_scale: assumptions.epoch_scale,
      output_step_s: @output_step_s,
      max_step_s: assumptions.max_step_s,
      atmosphere_provider_id: assumptions.atmosphere_provider_id,
      atmosphere_provider: "OrbitalDynamics.Environment.ExponentialAtmosphereProvider",
      atmosphere_provider_model: assumptions.atmosphere_provider_model,
      atmosphere_source_revision: assumptions.atmosphere_provider_source_revision,
      atmosphere_parameters: assumptions.atmosphere_provider.parameters,
      earth_rotation_provider_id: assumptions.earth_rotation_provider_id,
      earth_rotation_provider: "OrbitalDynamics.Environment.ConstantEarthRotationProvider",
      earth_rotation_source_revision: assumptions.earth_rotation_source_revision,
      earth_rotation_rate_rad_s: assumptions.earth_rotation_rate_rad_s,
      spacecraft_mass_kg: assumptions.spacecraft_mass_kg,
      drag_area_m2: assumptions.drag_area_m2,
      drag_coefficient: assumptions.drag_coefficient,
      access_detector: "OrbitalDynamics.EventDetectors.AccessWindows",
      access_root_tolerance_s: @access_root_tolerance_s,
      access_root_max_iterations: @access_root_max_iterations,
      access_boundaries:
        boundary_metadata(access_events, :boundary_refinement, :aos_los_bracketed_bisection),
      eclipse_detector: "OrbitalDynamics.EventDetectors.Eclipses",
      eclipse_boundaries:
        boundary_metadata(
          eclipse_events,
          :boundary_refinement,
          :eclipse_linear_shadow_margin_interpolation
        )
    }
  end

  defp expected_path_identity do
    %{
      propagator: "OrbitalDynamics.Propagators.J2Drag",
      force_model: :earth_j2_atmospheric_drag,
      force_models: [:point_mass_two_body, :j2, :atmospheric_drag],
      force_composition: :single_acceleration_sum_per_rk4_stage,
      numerical_method: :rk4_fixed_step,
      frame: :eci_j2000,
      epoch_scale: :tdb,
      output_step_s: @output_step_s,
      max_step_s: @max_step_s,
      atmosphere_provider_id: "environment.provider.atmosphere.exponential_reference",
      atmosphere_provider: "OrbitalDynamics.Environment.ExponentialAtmosphereProvider",
      atmosphere_provider_model: "single_scale_height_exponential_atmosphere",
      atmosphere_source_revision: "exponential-reference.v1",
      atmosphere_parameters: %{
        "reference_altitude_km" => 400.0,
        "reference_density_kg_m3" => 3.89e-12,
        "scale_height_km" => 60.0
      },
      earth_rotation_provider_id: "environment.provider.earth_rotation.constant_rate",
      earth_rotation_provider: "OrbitalDynamics.Environment.ConstantEarthRotationProvider",
      earth_rotation_source_revision: "constant-earth-rotation.v1",
      earth_rotation_rate_rad_s: 7.292115e-5,
      spacecraft_mass_kg: 120.0,
      drag_area_m2: 4.0,
      drag_coefficient: 2.2,
      access_detector: "OrbitalDynamics.EventDetectors.AccessWindows",
      access_root_tolerance_s: @access_root_tolerance_s,
      access_root_max_iterations: @access_root_max_iterations,
      access_boundaries: :aos_los_bracketed_bisection,
      eclipse_detector: "OrbitalDynamics.EventDetectors.Eclipses",
      eclipse_boundaries: :eclipse_linear_shadow_margin_interpolation
    }
  end

  defp runtime_semantics(scenario, body, trajectory, access_events, eclipse_events) do
    path = path_identity(trajectory, access_events, eclipse_events)
    spacecraft = scenario.spacecraft
    initial_state = scenario.initial_state

    %{
      "reference_model" => %{
        "frame" => external_frame_name(initial_state.frame.name),
        "epoch" => external_epoch_name(initial_state.epoch),
        "time_scale" => external_time_scale(initial_state.epoch.scale),
        "horizon_starts_at_s" => initial_state.epoch.seconds_since_j2000,
        "horizon_ends_at_s" => scenario.duration_s,
        "state_output_grid" => %{
          "starts_at_s" => initial_state.epoch.seconds_since_j2000,
          "ends_at_s" => scenario.duration_s,
          "step_s" => scenario.output_step_s,
          "epoch_count" => length(@state_epochs_s),
          "coverage_policy" => "inclusive_full_horizon_exact_grid"
        },
        "mu_m3_s2" => body.mu_km3_s2 * 1.0e9,
        "equatorial_radius_m" => body.equatorial_radius_km * 1_000.0,
        "j2" => body.j2,
        "initial_position_m" => tuple_scale_to_list(initial_state.position_km, 1_000.0),
        "initial_velocity_m_s" => tuple_scale_to_list(initial_state.velocity_km_s, 1_000.0),
        "spacecraft_mass_kg" => spacecraft.dry_mass_kg + spacecraft.propellant_mass_kg,
        "spacecraft_drag_area_m2" => spacecraft.area_m2,
        "spacecraft_drag_coefficient" => spacecraft.drag_coefficient,
        "integrator_step_s" => path.max_step_s
      },
      "data_sources" => %{
        "orekit_data_revision" => "none",
        "eop_source" => "none",
        "earth_orientation_model" => "constant_z_axis_rotation_from_zero_angle_at_case_epoch",
        "sun_source" => "fixed_unit_direction_from_case.properties",
        "sun_direction_eme2000" => Tuple.to_list(@sun_direction),
        "sun_provider_distance_m" => 100_000_000_000.0,
        "network_data_used_during_propagation" => false
      },
      "access_model" => @expected_access_model,
      "eclipse_model" =>
        Map.put(
          @expected_eclipse_model,
          "occulting_body_radius_m",
          body.equatorial_radius_km * 1_000.0
        ),
      "orbital_dynamics_path" => runtime_path_declaration(path),
      "tolerances" => @expected_tolerances
    }
  end

  defp runtime_manifest_projection(manifest) do
    reference_model = Map.get(manifest, "reference_model", %{})

    %{
      "reference_model" =>
        Map.take(reference_model, [
          "frame",
          "epoch",
          "time_scale",
          "horizon_starts_at_s",
          "horizon_ends_at_s",
          "state_output_grid",
          "mu_m3_s2",
          "equatorial_radius_m",
          "j2",
          "initial_position_m",
          "initial_velocity_m_s",
          "spacecraft_mass_kg",
          "spacecraft_drag_area_m2",
          "spacecraft_drag_coefficient",
          "integrator_step_s"
        ]),
      "data_sources" => Map.get(manifest, "data_sources"),
      "access_model" => Map.get(manifest, "access_model"),
      "eclipse_model" => Map.get(manifest, "eclipse_model"),
      "orbital_dynamics_path" => Map.get(manifest, "orbital_dynamics_path"),
      "tolerances" => Map.get(manifest, "tolerances")
    }
  end

  defp runtime_path_declaration(path) do
    %{
      "propagator" => path.propagator,
      "frame" => internal_frame_name(path.frame),
      "epoch_scale" => Atom.to_string(path.epoch_scale),
      "output_step_s" => path.output_step_s,
      "max_step_s" => path.max_step_s,
      "atmosphere_provider" => path.atmosphere_provider,
      "atmosphere_source_revision" => path.atmosphere_source_revision,
      "earth_rotation_provider" => path.earth_rotation_provider,
      "earth_rotation_source_revision" => path.earth_rotation_source_revision,
      "spacecraft_mass_kg" => path.spacecraft_mass_kg,
      "spacecraft_drag_area_m2" => path.drag_area_m2,
      "spacecraft_drag_coefficient" => path.drag_coefficient,
      "access_detector" => path.access_detector,
      "access_boundary_refinement" => access_refinement_name(path.access_boundaries),
      "access_root_tolerance_s" => path.access_root_tolerance_s,
      "access_root_max_iterations" => path.access_root_max_iterations,
      "eclipse_detector" => path.eclipse_detector,
      "eclipse_boundary_refinement" => eclipse_refinement_name(path.eclipse_boundaries)
    }
  end

  defp external_frame_name(:eci_j2000), do: "EME2000"
  defp external_frame_name(frame), do: {:unexpected_frame, frame}

  defp internal_frame_name(:eci_j2000), do: "earth_inertial_j2000"
  defp internal_frame_name(frame), do: {:unexpected_frame, frame}

  defp external_epoch_name(%Epoch{seconds_since_j2000: seconds, scale: :tdb})
       when seconds == 0.0,
       do: "2000-01-01T12:00:00_TDB"

  defp external_epoch_name(epoch), do: {:unexpected_epoch, epoch}

  defp external_time_scale(:tdb), do: "TDB_J2000_RELATIVE_SECONDS"
  defp external_time_scale(scale), do: {:unexpected_time_scale, scale}

  defp access_refinement_name(:aos_los_bracketed_bisection),
    do: "bracketed_bisection_cubic_hermite_state"

  defp access_refinement_name(value), do: {:unexpected_access_refinement, value}

  defp eclipse_refinement_name(:eclipse_linear_shadow_margin_interpolation),
    do: "linear_shadow_margin_between_10s_samples"

  defp eclipse_refinement_name(value), do: {:unexpected_eclipse_refinement, value}

  defp tuple_scale_to_list(tuple, factor) do
    tuple |> Tuple.to_list() |> Enum.map(&(&1 * factor))
  end

  defp boundary_metadata(events, key, expected) do
    values = events |> Enum.map(&Map.get(&1.metadata, key)) |> Enum.uniq()
    if values == [expected], do: expected, else: values
  end

  defp observed_horizon(trajectory) do
    states = trajectory.states

    %{
      starts_at_s: states |> List.first() |> then(& &1.epoch.seconds_since_j2000),
      ends_at_s: states |> List.last() |> then(& &1.epoch.seconds_since_j2000),
      sample_count: length(states)
    }
  end

  defp exact_keys(map, expected_keys) when is_map(map) do
    observed_keys = map |> Map.keys() |> Enum.sort()
    expected_keys = Enum.sort(expected_keys)

    if observed_keys == expected_keys,
      do: :ok,
      else: {:error, {:object_keys, expected_keys, observed_keys}}
  end

  defp exact_keys(_map, expected_keys), do: {:error, {:object_keys, expected_keys, :not_object}}

  defp validate_rows(rows, validator) do
    rows
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {row, index}, :ok ->
      case validator.(row) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, {:row, index, reason}}}
      end
    end)
  end

  defp strictly_increasing?(values) do
    Enum.all?(Enum.chunk_every(values, 2, 1, :discard), fn [left, right] ->
      finite_number?(left) and finite_number?(right) and left < right
    end)
  end

  defp numeric_triplet?(values) when is_list(values) and length(values) == 3,
    do: Enum.all?(values, &finite_number?/1)

  defp numeric_triplet?(_values), do: false

  defp finite_number?(value) when is_integer(value), do: true

  defp finite_number?(value) when is_float(value) do
    value == value and value not in [:infinity, :neg_infinity]
  end

  defp finite_number?(_value), do: false

  defp report_result(checks) do
    report = report(checks)
    if report["status"] == "pass", do: {:ok, report}, else: {:error, report}
  end

  defp report(checks) do
    status = if passing?(checks), do: "pass", else: "fail"

    %{
      "schema_contract" => "validation_reference_report.v1",
      "fixture_id" => @case_id,
      "model_id" => @model_id,
      "validation_level" => "validated",
      "status" => status,
      "status_counts" => checks |> Enum.map(& &1["status"]) |> Enum.frequencies(),
      "checks" => checks,
      "bundle_identity" => %{
        "manifest_sha256" => @manifest_sha256,
        "source_identity_sha256" => @source_manifest_sha256,
        "result_sha256" => @result_sha256
      },
      "claim_boundary" => registration()["known_limits"]
    }
  end

  defp failure_report(reason) do
    report([
      exact_check("bundle.verification", "content_bound_bundle_and_executable_comparison", reason)
    ])
  end

  defp exact_check(field, expected, observed) do
    %{
      "field" => field,
      "status" => if(expected == observed, do: "pass", else: "fail"),
      "expected" => json_safe(expected),
      "observed" => json_safe(observed),
      "tolerance" => "exact"
    }
  end

  defp numeric_check(field, expected, observed, tolerance)
       when is_number(expected) and is_number(observed) do
    error = abs(expected - observed)

    %{
      "field" => field,
      "status" => if(error <= tolerance, do: "pass", else: "fail"),
      "expected" => expected,
      "observed" => observed,
      "error" => error,
      "tolerance" => tolerance
    }
  end

  defp numeric_check(field, expected, observed, tolerance) do
    %{
      "field" => field,
      "status" => "fail",
      "expected" => expected,
      "observed" => json_safe(observed),
      "tolerance" => tolerance,
      "reason" => "missing_or_invalid_numeric_observation"
    }
  end

  defp vector_check(field, expected, observed, tolerance)
       when is_list(expected) and is_list(observed) and length(expected) == length(observed) do
    if Enum.all?(expected ++ observed, &is_number/1) do
      max_abs_error =
        expected
        |> Enum.zip(observed)
        |> Enum.map(fn {expected_value, observed_value} ->
          abs(expected_value - observed_value)
        end)
        |> Enum.max(fn -> 0.0 end)

      %{
        "field" => field,
        "status" => if(max_abs_error <= tolerance, do: "pass", else: "fail"),
        "expected" => expected,
        "observed" => observed,
        "max_abs_error" => max_abs_error,
        "tolerance" => tolerance
      }
    else
      exact_check(field, expected, observed) |> Map.put("tolerance", tolerance)
    end
  end

  defp vector_check(field, expected, observed, tolerance) do
    exact_check(field, expected, observed) |> Map.put("tolerance", tolerance)
  end

  defp passing?(checks), do: Enum.all?(checks, &(&1["status"] == "pass"))

  defp json_safe(value) when value in [true, false, nil], do: value
  defp json_safe(value) when is_atom(value), do: Atom.to_string(value)

  defp json_safe(value) when is_tuple(value),
    do: value |> Tuple.to_list() |> Enum.map(&json_safe/1)

  defp json_safe(value) when is_list(value), do: Enum.map(value, &json_safe/1)

  defp json_safe(value) when is_map(value) do
    Map.new(value, fn {key, nested_value} -> {to_string(key), json_safe(nested_value)} end)
  end

  defp json_safe(value), do: value

  defp format_epoch(epoch_s), do: epoch_s |> trunc() |> Integer.to_string()
  defp sha256(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)
end
