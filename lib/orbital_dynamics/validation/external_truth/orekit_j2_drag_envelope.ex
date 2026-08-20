defmodule OrbitalDynamics.Validation.ExternalTruth.OrekitJ2DragEnvelope do
  @moduledoc """
  Content-bound Orekit comparison for the declared D3 J2-plus-drag envelope.

  Eight independently generated cases exercise six combined-force trajectories
  plus the supported zero-density J2 and zero-J2 drag branches. Every case is
  evaluated through `OrbitalDynamics.Propagators.J2Drag`; the checked-in
  reference states are never produced by the Elixir implementation.
  """

  alias OrbitalDynamics.Environment.ExponentialAtmosphereProvider
  alias OrbitalDynamics.Propagators.J2Drag
  alias OrbitalDynamics.Validation.ExternalTruth.StrictBundle

  alias OrbitalDynamics.{CentralBody, Epoch, Frame, Scenario, Spacecraft, StateVector}

  @case_id "external_truth.orekit_13_1_7.earth_j2_drag_bounded_envelope_v1"
  @model_id "earth_j2_drag_bounded_sample_envelope_v1"
  @bundle_relative_path "priv/validation/external_truth/orekit_13_1_7_j2_drag_envelope"

  @manifest_sha256 "cc086ad9429291abd257b9907cb84b9d71ac0e05accd7cd4dda5c4206e030400"
  @manifest_byte_count 10_407
  @source_manifest_sha256 "d84b2c94435f61fe0bce7a0f32bd8dcec11c14337ffe02ccb72de4fa32e0cb66"
  @source_manifest_byte_count 464
  @result_sha256 "5398bf4f44ace3b9928d069b768690aa14fd75a91b7560d22b845689afcddc38"
  @result_byte_count 64_725
  @source_total_byte_count 33_949

  @position_tolerance_m 0.01
  @velocity_tolerance_m_s 0.00001
  @state_count_per_case 25
  @total_state_count 200

  @case_ids [
    "combined_low_250km_i28_5deg_1h_step5s",
    "combined_equatorial_300km_3h_step10s",
    "combined_nominal_400km_i51_6deg_6h_step10s",
    "combined_eccentric_300x800km_i63_4deg_12h_step15s",
    "combined_mid_650km_i75deg_18h_step20s",
    "combined_high_800km_i98deg_24h_step30s",
    "j2_only_zero_density_500km_i45deg_6h_step10s",
    "drag_only_zero_j2_300km_polar_6h_step10s"
  ]

  @source_files [
    %{
      path: "case.properties",
      byte_count: 6_079,
      sha256: "956dfd7a5194007b853bc5b41add2a215f351a00746b47be3d7073b2b424a4dd"
    },
    %{
      path: "pom.xml",
      byte_count: 830,
      sha256: "eadb68a7ad2fe8ac558d5c4a8a7bce14e0feb660ff933b2f7d023cf4815f5f94"
    },
    %{
      path: "dependencies.lock",
      byte_count: 1_536,
      sha256: "90b0b2e85a0fae9d586567895c894f0d59ce835e84127ba088cd9a2ed84ce388"
    },
    %{
      path: "generate.sh",
      byte_count: 1_945,
      sha256: "c57a698f49c28ed9ffe18753e21ec155c51174d4efe7033ff0eb47b1dc6848a6"
    },
    %{
      path: "src/main/java/org/orbitaldynamics/validation/OrekitJ2DragEnvelopeGenerator.java",
      byte_count: 23_559,
      sha256: "2a106e4c4ac28a7c5c998d098b92ac3945a4ef01e7c796cd463c4ba62d0dd94a"
    }
  ]

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
    "network_data_used_during_propagation" => false
  }

  @expected_reference_model %{
    "frame" => "EME2000",
    "epoch" => "2000-01-01T12:00:00_TDB",
    "time_scale" => "TDB_J2000_RELATIVE_SECONDS",
    "position_unit" => "meter",
    "velocity_unit" => "meter_per_second",
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
    "atmosphere_rotation" => "rigid_constant_rate_body_frame",
    "orbit_type" => "CARTESIAN",
    "integrator" => "ClassicalRungeKuttaIntegrator"
  }

  @expected_validation_envelope %{
    "central_body" => "earth",
    "mu_km3_s2" => 398_600.4418,
    "equatorial_radius_km" => 6_378.1363,
    "j2_values" => [0.0, 0.00108262668],
    "initial_altitude_km" => %{
      "minimum" => 250.0,
      "maximum" => 800.0,
      "sampled" => [250.0, 300.0, 400.0, 500.0, 650.0, 800.0]
    },
    "inclination_deg" => %{
      "minimum" => 0.0,
      "maximum" => 98.0,
      "sampled" => [0.0, 28.5, 45.0, 51.6, 63.4, 75.0, 90.0, 98.0]
    },
    "eccentricity" => %{
      "minimum" => 0.0,
      "maximum" => 0.036084741,
      "sampled" => [0.0, 0.03608474042290421]
    },
    "duration_s" => %{
      "minimum" => 3_600.0,
      "maximum" => 86_400.0,
      "sampled" => [3_600.0, 10_800.0, 21_600.0, 43_200.0, 64_800.0, 86_400.0]
    },
    "fixed_rk4_step_s" => %{
      "minimum" => 5.0,
      "maximum" => 30.0,
      "sampled" => [5.0, 10.0, 15.0, 20.0, 30.0]
    },
    "spacecraft_mass_kg" => %{
      "minimum" => 100.0,
      "maximum" => 500.0,
      "sampled" => [100.0, 120.0, 150.0, 200.0, 250.0, 350.0, 500.0]
    },
    "drag_area_m2" => %{
      "minimum" => 1.0,
      "maximum" => 8.0,
      "sampled" => [1.0, 2.0, 4.0, 5.0, 6.0, 8.0]
    },
    "drag_coefficient" => %{
      "minimum" => 2.0,
      "maximum" => 2.4,
      "sampled" => [2.0, 2.1, 2.2, 2.3, 2.4]
    },
    "atmosphere_reference_altitude_km" => 400.0,
    "atmosphere_reference_density_kg_m3" => %{
      "minimum" => 0.0,
      "maximum" => 2.0e-11,
      "positive_sampled" => [1.0e-12, 2.0e-12, 3.89e-12, 5.0e-12, 1.0e-11, 2.0e-11]
    },
    "atmosphere_scale_height_km" => %{
      "minimum" => 50.0,
      "maximum" => 70.0,
      "sampled" => [50.0, 55.0, 60.0, 65.0, 70.0]
    },
    "earth_rotation_rate_rad_s" => 7.292115e-5,
    "force_branches" => [
      "point_mass_j2_drag",
      "point_mass_j2_zero_density_drag",
      "point_mass_zero_j2_drag"
    ],
    "case_count" => 8,
    "state_sample_count_per_case" => @state_count_per_case,
    "total_state_sample_count" => @total_state_count
  }

  @expected_orbital_dynamics_path %{
    "propagator" => "OrbitalDynamics.Propagators.J2Drag",
    "frame" => "earth_inertial_j2000",
    "epoch_scale" => "tdb",
    "atmosphere_provider" => "OrbitalDynamics.Environment.ExponentialAtmosphereProvider",
    "atmosphere_source_revision" => "exponential-reference.v1",
    "earth_rotation_provider" => "OrbitalDynamics.Environment.ConstantEarthRotationProvider",
    "earth_rotation_source_revision" => "constant-earth-rotation.v1",
    "force_composition" => "single_acceleration_sum_per_rk4_stage",
    "execution_mode" => "offline_deterministic"
  }

  @expected_tolerances %{
    "position_max_component_error_m" => @position_tolerance_m,
    "velocity_max_component_error_m_s" => @velocity_tolerance_m_s
  }

  @expected_output %{
    "format" => "JSON",
    "schema" => "orekit_j2_drag_envelope_raw.v1",
    "float_format" => "%.17e",
    "case_count" => 8,
    "state_sample_count_per_case" => @state_count_per_case,
    "total_state_sample_count" => @total_state_count
  }

  @expected_claim_boundary %{
    "validated_combination" =>
      "earth_eme2000_tdb_fixed_rk4_point_mass_j2_simple_exponential_drag_over_the_declared_eight_case_leo_sample_envelope",
    "validated_state_error_claim" =>
      "every one of 200 full-horizon sampled Cartesian states is within the declared per-component position and velocity tolerances of independently generated Orekit output",
    "not_promoted" => [
      "public_numeric_guard_envelope_outside_the_declared_validation_envelope",
      "unsampled_continuous_parameter_combinations",
      "other_atmosphere_providers",
      "accelerator_backends",
      "adaptive_integration",
      "other_frames_or_time_scales",
      "durations_over_24_hours"
    ],
    "not_claimed" => [
      "flight_certification",
      "operational_acceptance",
      "full_physical_fidelity",
      "authoritative_earth_orientation",
      "space_weather_calibrated_atmosphere",
      "winds",
      "third_body",
      "tides",
      "solar_radiation_pressure",
      "maneuvers"
    ]
  }

  @doc "Returns the stable external-truth registration for the bounded D3 corpus."
  def registration do
    %{
      "id" => @case_id,
      "model" => @model_id,
      "implementation" => __MODULE__ |> Atom.to_string() |> String.trim_leading("Elixir."),
      "validation_level" => "validated",
      "covered_regime" =>
        "200 full-horizon states across eight Earth/EME2000/TDB fixed-RK4 cases: six combined J2-drag trajectories spanning 250..800 km, 1..24 hours, and 5..30 second steps plus zero-density J2 and zero-J2 drag branches",
      "tolerances" => @expected_tolerances,
      "evidence" => [
        "content-bound Apache Orekit 13.1.7 envelope corpus generated only through upstream NumericalPropagator force models",
        "offline executable comparison of every sampled state through OrbitalDynamics.Propagators.J2Drag",
        "counterfactual tests perturb position and velocity observations beyond tolerance on combined and controlled force branches"
      ],
      "intended_uses" => ["numerical_regression", "bounded_analysis_evidence"],
      "known_limits" => [
        "validation applies only to the declared eight-case bounded sample envelope and exact force/provider identity",
        "unsampled continuous parameter combinations and the broader public numeric guard envelope are not promoted",
        "fixed Earth constants, EME2000/TDB, simple exponential atmosphere, constant co-rotation, and fixed-step scalar RK4 only",
        "no EOP, space-weather calibration, winds, third body, tides, SRP, maneuvers, covariance, or accelerated backend",
        "not flight certification or operational acceptance"
      ]
    }
  end

  @doc "Returns the installed bundle directory."
  def bundle_path, do: Application.app_dir(:orbital_dynamics, @bundle_relative_path)

  @doc "Verifies the content-bound corpus and independently executes the production path."
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
  def observations(opts \\ [])

  def observations(opts) when is_list(opts) do
    root = Keyword.get(opts, :bundle_path, bundle_path())

    with {:ok, bundle} <- StrictBundle.load(root, expectations()),
         {:ok, cases} <- config_cases(bundle.config) do
      execute_cases(cases)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def observations(_opts), do: {:error, :invalid_observation_options}

  @doc false
  def compare_observations(observations, opts \\ [])

  def compare_observations(observations, opts)
      when is_map(observations) and is_list(opts) do
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
    with {:ok, semantic_checks, cases} <- validate_bundle(bundle),
         {:ok, observations} <- execute_cases(cases) do
      compare_validated_bundle(bundle, cases, observations, semantic_checks)
    else
      {:error, %{} = report} -> {:error, report}
      {:error, reason} -> {:error, failure_report(reason)}
    end
  end

  defp compare_loaded_bundle(bundle, observations) do
    with {:ok, semantic_checks, cases} <- validate_bundle(bundle) do
      compare_validated_bundle(bundle, cases, observations, semantic_checks)
    else
      {:error, %{} = report} -> {:error, report}
      {:error, reason} -> {:error, failure_report(reason)}
    end
  end

  defp compare_validated_bundle(bundle, cases, observations, semantic_checks) do
    checks =
      semantic_checks ++
        comparison_checks(bundle.reference, cases, Map.get(observations, :cases))

    report_result(checks)
  end

  defp validate_bundle(bundle) do
    with {:ok, cases} <- config_cases(bundle.config) do
      checks = identity_checks(bundle) ++ manifest_checks(bundle, cases)

      reference_shape_check =
        case validate_reference_shape(bundle.reference, cases) do
          :ok ->
            exact_check(
              "reference_output.structure",
              "complete_and_unique",
              "complete_and_unique"
            )

          {:error, reason} ->
            exact_check("reference_output.structure", "complete_and_unique", reason)
        end

      checks = checks ++ [reference_shape_check]

      if passing?(checks),
        do: {:ok, checks, cases},
        else: {:error, report(checks)}
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
      exact_check("bundle.dependencies", @expected_dependencies, bundle.dependencies),
      exact_check("bundle.case_order", @case_ids, config_case_ids(bundle.config))
    ]
  end

  defp manifest_checks(bundle, cases) do
    manifest = bundle.manifest

    expected_core = %{
      "schema" => "external_numerical_truth_corpus.v1",
      "corpus_id" => "orekit_13_1_7_earth_j2_drag_bounded_envelope_v1",
      "validation_status" => "validated_external_reference_for_declared_bounded_sample_envelope",
      "generated_at_utc" => "2026-08-20T15:30:00Z",
      "reference_tool" => @expected_reference_tool,
      "dependencies" => @expected_dependency_declaration,
      "data_sources" => @expected_data_sources,
      "reference_model" => @expected_reference_model,
      "validation_envelope" => @expected_validation_envelope,
      "orbital_dynamics_path" => @expected_orbital_dynamics_path,
      "tolerances" => @expected_tolerances,
      "output" => @expected_output,
      "claim_boundary" => @expected_claim_boundary
    }

    expected_keys =
      expected_core
      |> Map.keys()
      |> Kernel.++(["source_identity", "result_identity", "bundle_read_limits", "cases"])
      |> Enum.sort()

    generator =
      Map.get(
        bundle.source_bytes,
        "src/main/java/org/orbitaldynamics/validation/OrekitJ2DragEnvelopeGenerator.java",
        ""
      )

    [
      exact_check("bundle.manifest.keys", expected_keys, manifest |> Map.keys() |> Enum.sort()),
      exact_check(
        "bundle.manifest.semantic_declarations",
        expected_core,
        Map.take(manifest, Map.keys(expected_core))
      ),
      exact_check(
        "bundle.manifest.case_matrix",
        manifest_case_projection(cases),
        manifest["cases"]
      ),
      exact_check(
        "bundle.manifest.reference_inputs",
        config_case_inputs(cases),
        reference_case_inputs(bundle.reference["cases"])
      ),
      exact_check(
        "bundle.manifest.generator_upstream_models",
        true,
        Enum.all?(
          [
            "NumericalPropagator",
            "J2OnlyPerturbation",
            "DragForce",
            "SimpleExponentialAtmosphere",
            "IsotropicDrag"
          ],
          &String.contains?(generator, &1)
        )
      ),
      exact_check(
        "bundle.manifest.generator_container_ref",
        "docker.io/library/maven@#{@expected_reference_tool["container_digest"]}",
        source_value(bundle.source_bytes["generate.sh"], ~r/container_image="([^"]+)"/)
      ),
      exact_check(
        "bundle.manifest.generator_toolchain",
        %{java_release: "21", orekit_version: "13.1.7"},
        %{
          java_release:
            source_value(bundle.source_bytes["generate.sh"], ~r/javac --release (\d+)/),
          orekit_version:
            source_value(generator, ~r/exact\(config, "orekit_version", "([^"]+)"\)/)
        }
      )
    ]
  end

  defp validate_reference_shape(reference, cases) when is_map(reference) do
    with :ok <-
           exact_keys(
             reference,
             ~w(cases corpus_id generated_at_utc identity model schema source_identity_sha256 tool units)
           ),
         true <- reference["schema"] == "orekit_j2_drag_envelope_raw.v1",
         true <- reference["corpus_id"] == "orekit_13_1_7_earth_j2_drag_bounded_envelope_v1",
         true <- reference["source_identity_sha256"] == @source_manifest_sha256,
         true <- reference["generated_at_utc"] == "2026-08-20T15:30:00Z",
         true <-
           reference["tool"] == %{
             "name" => "Apache Orekit",
             "version" => "13.1.7",
             "java_runtime" => "21.0.9+10-LTS"
           },
         true <-
           reference["identity"] == %{
             "frame" => "EME2000",
             "epoch" => "2000-01-01T12:00:00_TDB",
             "time_scale" => "TDB_J2000_RELATIVE_SECONDS",
             "orekit_data_revision" => "none",
             "eop_source" => "none"
           },
         true <-
           reference["model"] == %{
             "propagator" => "NumericalPropagator",
             "orbit_type" => "CARTESIAN",
             "integrator" => "ClassicalRungeKuttaIntegrator",
             "gravity" => "NewtonianAttraction_plus_J2OnlyPerturbation",
             "drag" => "DragForce_plus_SimpleExponentialAtmosphere_plus_IsotropicDrag",
             "earth_rotation" => "constant_z_axis_rotation_from_zero_angle_at_case_epoch"
           },
         true <-
           reference["units"] == %{
             "epoch" => "second_since_case_epoch",
             "position" => "meter",
             "velocity" => "meter_per_second",
             "mu" => "kilometer_cubed_per_second_squared",
             "density" => "kilogram_per_cubic_meter"
           },
         true <- is_list(reference["cases"]),
         true <- Enum.map(reference["cases"], & &1["id"]) == @case_ids,
         :ok <- validate_reference_cases(reference["cases"], cases) do
      :ok
    else
      false -> {:error, :reference_identity_or_case_order_mismatch}
      {:error, _reason} = error -> error
    end
  end

  defp validate_reference_shape(_reference, _cases),
    do: {:error, :reference_output_must_be_object}

  defp validate_reference_cases(reference_cases, cases) do
    reference_cases
    |> Enum.zip(cases)
    |> Enum.reduce_while(:ok, fn {reference_case, case_config}, :ok ->
      expected_epochs =
        Enum.map(0..(@state_count_per_case - 1), &(&1 * case_config["output_step_s"]))

      states = reference_case["states"]

      result =
        with :ok <- exact_keys(reference_case, ~w(force_branch id inputs states)),
             true <- reference_case["id"] == case_config["id"],
             true <- reference_case["force_branch"] == case_config["force_branch"],
             true <- reference_case["inputs"] == case_inputs(case_config),
             true <- is_list(states) and length(states) == @state_count_per_case,
             true <- Enum.map(states, & &1["epoch_s"]) == expected_epochs,
             true <- Enum.all?(states, &valid_state_row?/1) do
          :ok
        else
          false -> {:error, {:invalid_reference_case, case_config["id"]}}
          {:error, reason} -> {:error, {:invalid_reference_case, case_config["id"], reason}}
        end

      case result do
        :ok -> {:cont, :ok}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
  end

  defp execute_cases(cases) do
    try do
      cases
      |> Enum.reduce_while({:ok, []}, fn case_config, {:ok, observations} ->
        case execute_case(case_config) do
          {:ok, observed} -> {:cont, {:ok, [observed | observations]}}
          {:error, reason} -> {:halt, {:error, {case_config["id"], reason}}}
        end
      end)
      |> case do
        {:ok, reversed} -> {:ok, %{cases: Enum.reverse(reversed)}}
        {:error, reason} -> {:error, reason}
      end
    rescue
      error -> {:error, {:orbital_dynamics_execution_failed, Exception.message(error)}}
    catch
      kind, reason -> {:error, {:orbital_dynamics_execution_failed, {kind, reason}}}
    end
  end

  defp execute_case(case_config) do
    body =
      CentralBody.new!(:earth, case_config["mu_km3_s2"],
        equatorial_radius_km: case_config["equatorial_radius_km"],
        j2: case_config["j2"]
      )

    spacecraft =
      Spacecraft.new!("orekit-envelope:#{case_config["id"]}", case_config["spacecraft_mass_kg"],
        area_m2: case_config["spacecraft_drag_area_m2"],
        drag_coefficient: case_config["spacecraft_drag_coefficient"]
      )

    initial_state =
      StateVector.new!(
        List.to_tuple(case_config["initial_position_km"]),
        List.to_tuple(case_config["initial_velocity_km_s"]),
        Epoch.new!(0.0, :tdb),
        Frame.earth_inertial_j2000()
      )

    scenario =
      Scenario.new!("orekit-envelope:#{case_config["id"]}", spacecraft, initial_state,
        duration_s: case_config["duration_s"],
        output_step_s: case_config["output_step_s"],
        central_body: body
      )

    provider_opts = [
      reference_altitude_km: case_config["atmosphere_reference_altitude_km"],
      reference_density_kg_m3: case_config["atmosphere_reference_density_kg_m3"],
      scale_height_km: case_config["atmosphere_scale_height_km"]
    ]

    case J2Drag.propagate(scenario,
           max_step_s: case_config["integrator_step_s"],
           atmosphere_provider: {ExponentialAtmosphereProvider, provider_opts}
         ) do
      {:ok, trajectory} ->
        {:ok,
         %{
           id: case_config["id"],
           force_branch: case_config["force_branch"],
           inputs: case_inputs(case_config),
           states: observed_states(trajectory),
           path_identity: observed_path_identity(trajectory)
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp observed_states(trajectory) do
    Enum.map(trajectory.states, fn state ->
      %{
        epoch_s: state.epoch.seconds_since_j2000,
        position_m: state.position_km |> Tuple.to_list() |> Enum.map(&(&1 * 1_000.0)),
        velocity_m_s: state.velocity_km_s |> Tuple.to_list() |> Enum.map(&(&1 * 1_000.0))
      }
    end)
  end

  defp observed_path_identity(trajectory) do
    assumptions = trajectory.assumptions

    %{
      propagator: "OrbitalDynamics.Propagators.J2Drag",
      force_models: assumptions.force_models,
      force_composition: assumptions.force_composition,
      numerical_method: assumptions.numerical_method,
      max_step_s: assumptions.max_step_s,
      frame: assumptions.frame,
      epoch_scale: assumptions.epoch_scale,
      mu_km3_s2: assumptions.mu_km3_s2,
      equatorial_radius_km: assumptions.equatorial_radius_km,
      j2: assumptions.j2,
      j2_enabled: assumptions.force_component_assumptions.j2.enabled,
      spacecraft_mass_kg: assumptions.spacecraft_mass_kg,
      drag_area_m2: assumptions.drag_area_m2,
      drag_coefficient: assumptions.drag_coefficient,
      atmosphere_provider_id: assumptions.atmosphere_provider_id,
      atmosphere_source_revision: assumptions.atmosphere_provider_source_revision,
      atmosphere_parameters: assumptions.atmosphere_provider.parameters,
      earth_rotation_provider_id: assumptions.earth_rotation_provider_id,
      earth_rotation_source_revision: assumptions.earth_rotation_source_revision,
      earth_rotation_rate_rad_s: assumptions.earth_rotation_rate_rad_s,
      environment_policy: assumptions.environment_policy
    }
  end

  defp expected_path_identity(case_config) do
    %{
      propagator: "OrbitalDynamics.Propagators.J2Drag",
      force_models: [:point_mass_two_body, :j2, :atmospheric_drag],
      force_composition: :single_acceleration_sum_per_rk4_stage,
      numerical_method: :rk4_fixed_step,
      max_step_s: case_config["integrator_step_s"],
      frame: :eci_j2000,
      epoch_scale: :tdb,
      mu_km3_s2: case_config["mu_km3_s2"],
      equatorial_radius_km: case_config["equatorial_radius_km"],
      j2: case_config["j2"],
      j2_enabled: case_config["j2"] > 0.0,
      spacecraft_mass_kg: case_config["spacecraft_mass_kg"],
      drag_area_m2: case_config["spacecraft_drag_area_m2"],
      drag_coefficient: case_config["spacecraft_drag_coefficient"],
      atmosphere_provider_id: "environment.provider.atmosphere.exponential_reference",
      atmosphere_source_revision: "exponential-reference.v1",
      atmosphere_parameters: %{
        "reference_altitude_km" => case_config["atmosphere_reference_altitude_km"],
        "reference_density_kg_m3" => case_config["atmosphere_reference_density_kg_m3"],
        "scale_height_km" => case_config["atmosphere_scale_height_km"]
      },
      earth_rotation_provider_id: "environment.provider.earth_rotation.constant_rate",
      earth_rotation_source_revision: "constant-earth-rotation.v1",
      earth_rotation_rate_rad_s: case_config["earth_rotation_rate_rad_s"],
      environment_policy: :offline_immutable_captured_once_before_integration
    }
  end

  defp comparison_checks(reference, cases, observed_cases)
       when is_list(observed_cases) do
    reference_cases = reference["cases"]

    order_checks = [
      exact_check("orbital_dynamics.case_count", length(cases), length(observed_cases)),
      exact_check("orbital_dynamics.case_order", @case_ids, Enum.map(observed_cases, & &1[:id]))
    ]

    case_checks =
      cases
      |> Enum.zip(reference_cases)
      |> Enum.zip(observed_cases)
      |> Enum.flat_map(fn {{case_config, reference_case}, observed_case} ->
        prefix = "case.#{case_config["id"]}"

        [
          exact_check(
            "#{prefix}.force_branch",
            reference_case["force_branch"],
            observed_case[:force_branch]
          ),
          exact_check("#{prefix}.inputs", reference_case["inputs"], observed_case[:inputs]),
          exact_check(
            "#{prefix}.path_identity",
            expected_path_identity(case_config),
            observed_case[:path_identity]
          )
        ] ++ state_checks(prefix, reference_case["states"], observed_case[:states])
      end)

    order_checks ++ case_checks
  end

  defp comparison_checks(_reference, _cases, observed_cases),
    do: [exact_check("orbital_dynamics.cases", :case_list, observed_cases)]

  defp state_checks(prefix, reference_states, observed_states)
       when is_list(reference_states) and is_list(observed_states) do
    count_check =
      exact_check("#{prefix}.state_count", length(reference_states), length(observed_states))

    row_checks =
      reference_states
      |> Enum.zip(observed_states)
      |> Enum.flat_map(fn {expected, observed} ->
        epoch = format_epoch(expected["epoch_s"])

        [
          numeric_check(
            "#{prefix}.state.#{epoch}.epoch_s",
            expected["epoch_s"],
            observed[:epoch_s],
            0.0
          ),
          vector_check(
            "#{prefix}.state.#{epoch}.position_m",
            expected["position_m"],
            observed[:position_m],
            @position_tolerance_m
          ),
          vector_check(
            "#{prefix}.state.#{epoch}.velocity_m_s",
            expected["velocity_m_s"],
            observed[:velocity_m_s],
            @velocity_tolerance_m_s
          )
        ]
      end)

    [count_check | row_checks]
  end

  defp state_checks(prefix, expected, observed),
    do: [exact_check("#{prefix}.states", expected, observed)]

  defp config_cases(config) when is_map(config) do
    with {:ok, count} <- parse_integer(config["case_count"]),
         true <- count == length(@case_ids) do
      cases = Enum.map(1..count, &config_case(config, &1))

      if Enum.all?(cases, &valid_config_case?/1) and Enum.map(cases, & &1["id"]) == @case_ids,
        do: {:ok, cases},
        else: {:error, :invalid_case_configuration}
    else
      _value -> {:error, :invalid_case_count}
    end
  end

  defp config_cases(_config), do: {:error, :invalid_case_configuration}

  defp config_case(config, index) do
    prefix = "case.#{index}."

    %{
      "id" => config[prefix <> "id"],
      "force_branch" => config[prefix <> "force_branch"],
      "duration_s" => parse_number(config[prefix <> "duration_s"]),
      "output_step_s" => parse_number(config[prefix <> "output_step_s"]),
      "integrator_step_s" => parse_number(config[prefix <> "integrator_step_s"]),
      "mu_km3_s2" => parse_number(config[prefix <> "mu_km3_s2"]),
      "equatorial_radius_km" => parse_number(config[prefix <> "equatorial_radius_km"]),
      "j2" => parse_number(config[prefix <> "j2"]),
      "initial_position_km" => parse_vector(config[prefix <> "initial_position_km"]),
      "initial_velocity_km_s" => parse_vector(config[prefix <> "initial_velocity_km_s"]),
      "atmosphere_reference_altitude_km" =>
        parse_number(config[prefix <> "atmosphere_reference_altitude_km"]),
      "atmosphere_reference_density_kg_m3" =>
        parse_number(config[prefix <> "atmosphere_reference_density_kg_m3"]),
      "atmosphere_scale_height_km" =>
        parse_number(config[prefix <> "atmosphere_scale_height_km"]),
      "spacecraft_mass_kg" => parse_number(config[prefix <> "spacecraft_mass_kg"]),
      "spacecraft_drag_area_m2" => parse_number(config[prefix <> "spacecraft_drag_area_m2"]),
      "spacecraft_drag_coefficient" =>
        parse_number(config[prefix <> "spacecraft_drag_coefficient"]),
      "earth_rotation_rate_rad_s" => parse_number(config[prefix <> "earth_rotation_rate_rad_s"])
    }
  end

  defp valid_config_case?(case_config) do
    case_config["force_branch"] in [
      "point_mass_j2_drag",
      "point_mass_j2_zero_density_drag",
      "point_mass_zero_j2_drag"
    ] and
      Enum.all?(
        ~w(duration_s output_step_s integrator_step_s mu_km3_s2 equatorial_radius_km j2 atmosphere_reference_altitude_km atmosphere_reference_density_kg_m3 atmosphere_scale_height_km spacecraft_mass_kg spacecraft_drag_area_m2 spacecraft_drag_coefficient earth_rotation_rate_rad_s),
        &finite_number?(case_config[&1])
      ) and numeric_triplet?(case_config["initial_position_km"]) and
      numeric_triplet?(case_config["initial_velocity_km_s"])
  end

  defp case_inputs(case_config) do
    Map.take(case_config, [
      "duration_s",
      "output_step_s",
      "integrator_step_s",
      "mu_km3_s2",
      "equatorial_radius_km",
      "j2",
      "initial_position_km",
      "initial_velocity_km_s",
      "atmosphere_reference_altitude_km",
      "atmosphere_reference_density_kg_m3",
      "atmosphere_scale_height_km",
      "spacecraft_mass_kg",
      "spacecraft_drag_area_m2",
      "spacecraft_drag_coefficient",
      "earth_rotation_rate_rad_s"
    ])
  end

  defp reference_case_inputs(rows) when is_list(rows),
    do: Enum.map(rows, &%{"id" => &1["id"], "inputs" => &1["inputs"]})

  defp reference_case_inputs(_rows), do: :invalid_reference_cases

  defp config_case_inputs(cases),
    do: Enum.map(cases, &%{"id" => &1["id"], "inputs" => case_inputs(&1)})

  defp manifest_case_projection(cases) do
    inclinations = [28.5, 0.0, 51.6, 63.4, 75.0, 98.0, 45.0, 90.0]

    cases
    |> Enum.zip(inclinations)
    |> Enum.map(fn {case_config, inclination_deg} ->
      case_config
      |> Map.take([
        "id",
        "force_branch",
        "duration_s",
        "output_step_s",
        "integrator_step_s",
        "spacecraft_mass_kg",
        "spacecraft_drag_area_m2",
        "spacecraft_drag_coefficient",
        "atmosphere_reference_density_kg_m3",
        "atmosphere_scale_height_km"
      ])
      |> Map.put("initial_altitude_km", initial_altitude_km(case_config))
      |> Map.put("inclination_deg", inclination_deg)
      |> Map.put("state_sample_count", @state_count_per_case)
    end)
  end

  defp initial_altitude_km(case_config) do
    case_config["initial_position_km"]
    |> Enum.map(&(&1 * &1))
    |> Enum.sum()
    |> :math.sqrt()
    |> Kernel.-(case_config["equatorial_radius_km"])
    |> Float.round(6)
  end

  defp config_case_ids(config) do
    case parse_integer(config["case_count"]) do
      {:ok, count} -> Enum.map(1..count, &config["case.#{&1}.id"])
      _error -> :invalid_case_count
    end
  end

  defp valid_state_row?(row) when is_map(row) do
    Map.keys(row) |> Enum.sort() == ~w(epoch_s position_m velocity_m_s) and
      finite_number?(row["epoch_s"]) and numeric_triplet?(row["position_m"]) and
      numeric_triplet?(row["velocity_m_s"])
  end

  defp valid_state_row?(_row), do: false

  defp exact_keys(map, expected_keys) when is_map(map) do
    if map |> Map.keys() |> Enum.sort() == Enum.sort(expected_keys),
      do: :ok,
      else: {:error, {:object_keys, expected_keys, Map.keys(map)}}
  end

  defp exact_keys(_map, expected_keys),
    do: {:error, {:object_keys, expected_keys, :not_object}}

  defp parse_number(value) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> number
      _other -> {:invalid_number, value}
    end
  end

  defp parse_number(value), do: {:invalid_number, value}

  defp parse_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {number, ""} -> {:ok, number}
      _other -> {:error, :invalid_integer}
    end
  end

  defp parse_integer(_value), do: {:error, :invalid_integer}

  defp parse_vector(value) when is_binary(value) do
    values = value |> String.split(",", trim: false) |> Enum.map(&parse_number/1)
    if numeric_triplet?(values), do: values, else: {:invalid_vector, value}
  end

  defp parse_vector(value), do: {:invalid_vector, value}

  defp numeric_triplet?(values) when is_list(values) and length(values) == 3,
    do: Enum.all?(values, &finite_number?/1)

  defp numeric_triplet?(_values), do: false

  defp finite_number?(value) when is_integer(value), do: true

  defp finite_number?(value) when is_float(value) do
    value == value and abs(value) < 1.0e308
  end

  defp finite_number?(_value), do: false

  defp source_value(bytes, regex) when is_binary(bytes) do
    case Regex.run(regex, bytes, capture: :all_but_first) do
      [value] -> value
      _match -> :missing
    end
  end

  defp source_value(_bytes, _regex), do: :missing

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
      "provenance" => %{
        "reference_tool" => "Apache Orekit 13.1.7",
        "source_manifest_sha256" => @source_manifest_sha256,
        "reference_output_sha256" => @result_sha256,
        "execution_mode" => "offline_deterministic"
      },
      "claim_boundary" => registration()["known_limits"]
    }
  end

  defp failure_report(reason) do
    report([exact_check("external_truth.verification", "pass", reason)])
  end

  defp exact_check(field, expected, observed) do
    status = if expected == observed, do: "pass", else: "fail"

    %{
      "field" => field,
      "status" => status,
      "expected" => json_safe(expected),
      "observed" => json_safe(observed),
      "tolerance" => 0
    }
  end

  defp numeric_check(field, expected, observed, tolerance)
       when is_number(expected) and is_number(observed) and is_number(tolerance) do
    error = abs(expected - observed)
    status = if error <= tolerance, do: "pass", else: "fail"

    %{
      "field" => field,
      "status" => status,
      "expected" => expected,
      "observed" => observed,
      "tolerance" => tolerance,
      "error" => error
    }
  end

  defp numeric_check(field, expected, observed, tolerance) do
    exact_check(field, expected, observed) |> Map.put("tolerance", tolerance)
  end

  defp vector_check(field, expected, observed, tolerance)
       when is_list(expected) and is_list(observed) and length(expected) == 3 and
              length(observed) == 3 do
    errors = Enum.zip_with(expected, observed, fn left, right -> abs(left - right) end)
    max_error = Enum.max(errors)
    status = if max_error <= tolerance, do: "pass", else: "fail"

    %{
      "field" => field,
      "status" => status,
      "expected" => expected,
      "observed" => observed,
      "tolerance" => tolerance,
      "error" => max_error,
      "component_errors" => errors
    }
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
    Map.new(value, fn {key, nested} -> {to_string(key), json_safe(nested)} end)
  end

  defp json_safe(value), do: value

  defp format_epoch(epoch_s) when is_float(epoch_s) and trunc(epoch_s) == epoch_s,
    do: epoch_s |> trunc() |> Integer.to_string()

  defp format_epoch(epoch_s), do: to_string(epoch_s)
  defp sha256(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)
end
