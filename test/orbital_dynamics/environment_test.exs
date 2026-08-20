defmodule OrbitalDynamics.EnvironmentTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Environment, Schema}

  test "declares internal environment provider capabilities" do
    assert [
             %{
               "id" => "environment.provider.solar.fixed_inertial_direction",
               "schema_contract" => "environment_provider_capability.v1",
               "model" => "fixed_inertial_solar_direction",
               "interpolation" => "constant",
               "network_access" => false
             },
             %{
               "id" => "environment.provider.earth_rotation.constant_rate",
               "schema_contract" => "environment_provider_capability.v1",
               "model" => "constant_earth_rotation",
               "interpolation" => "analytic_constant_rate",
               "network_access" => false
             },
             %{
               "id" => "environment.provider.earth_orientation.tabular_rotation",
               "schema_contract" => "environment_provider_capability.v1",
               "model" => "tabular_earth_orientation_rotation",
               "interpolation" => "linear_declared_rotation_sample",
               "network_access" => false
             },
             %{
               "id" => "environment.provider.atmosphere.exponential_reference",
               "schema_contract" => "environment_provider_capability.v1",
               "model" => "single_scale_height_exponential_atmosphere",
               "interpolation" => "analytic_single_scale_height",
               "network_access" => false
             }
           ] = Environment.provider_capabilities()

    assert Enum.all?(Environment.provider_capabilities(), fn capability ->
             :ok == Environment.validate_provider_capability(capability)
           end)

    assert Enum.all?(Environment.provider_capabilities(), fn capability ->
             match?(
               {:ok, %{"schema_contract" => "environment_provider_capability.v1"}},
               Schema.validate_artifact(capability)
             )
           end)

    stale_provider =
      Environment.provider_capabilities()
      |> List.first()
      |> Map.put("known_limits", ["not an ephemeris provider"])

    assert {:error, {:invalid_field, "known_limits"}} =
             Environment.validate_provider_capability(stale_provider)

    assert {:error, stale_provider_report} = Schema.validate_artifact(stale_provider)

    assert Enum.any?(
             stale_provider_report["errors"],
             &(&1["path"] == "$.known_limits" and
                 &1["message"] == "must match Environment.provider_capabilities known limits")
           )
  end

  test "validates provider capability time-span coverage" do
    [fixed_sun | _providers] = Environment.provider_capabilities()

    assert Environment.provider_covers_time_span?(fixed_sun, %{
             starts_at_s: 0.0,
             ends_at_s: 86_400.0
           })

    finite_provider =
      put_in(fixed_sun, ["coverage"], %{
        "starts_at_s" => 10.0,
        "ends_at_s" => 20.0,
        "time_scale" => "seconds_since_j2000"
      })

    assert Environment.provider_covers_time_span?(finite_provider, %{
             starts_at_s: 10.0,
             ends_at_s: 20.0
           })

    refute Environment.provider_covers_time_span?(finite_provider, %{
             starts_at_s: 0.0,
             ends_at_s: 20.0
           })

    refute Environment.provider_covers_time_span?(finite_provider, %{
             starts_at_s: 20.0,
             ends_at_s: 10.0
           })
  end

  test "validates provider request fit by time span, body, and output" do
    [fixed_sun | _providers] = Environment.provider_capabilities()

    request = %{
      starts_at_s: 0.0,
      ends_at_s: 86_400.0,
      body: :earth,
      output: :sun_direction
    }

    assert Environment.provider_supports_request?(fixed_sun, request)

    refute Environment.provider_supports_request?(fixed_sun, %{request | body: :mars})
    refute Environment.provider_supports_request?(fixed_sun, %{request | output: :density_kg_m3})

    finite_provider =
      put_in(fixed_sun, ["coverage"], %{
        "starts_at_s" => 10.0,
        "ends_at_s" => 20.0,
        "time_scale" => "seconds_since_j2000"
      })

    refute Environment.provider_supports_request?(finite_provider, request)

    assert Environment.provider_supports_request?(finite_provider, %{
             "starts_at_s" => 10.0,
             "ends_at_s" => 20.0,
             "bodies" => ["earth"],
             "outputs" => ["sun_direction"]
           })

    assert [
             %{
               "id" => "environment.provider.solar.fixed_inertial_direction",
               "model" => "fixed_inertial_solar_direction"
             }
           ] = Environment.provider_capabilities_for_request(request)

    assert [] = Environment.provider_capabilities_for_request(%{request | output: :not_declared})
  end

  test "selects Earth rotation providers from product-level requests" do
    request = %{
      starts_at_s: 0.0,
      ends_at_s: 86_400.0,
      body: :earth,
      kind: :earth_rotation
    }

    assert [
             %{
               "id" => "environment.provider.earth_rotation.constant_rate",
               "outputs" => constant_outputs
             },
             %{
               "id" => "environment.provider.earth_orientation.tabular_rotation",
               "outputs" => tabular_outputs
             }
           ] = Environment.provider_capabilities_for_request(request)

    assert "earth_rotation" in constant_outputs
    assert "earth_rotation" in tabular_outputs

    tabular_provider =
      Environment.provider_capabilities()
      |> Enum.find(&(&1["id"] == "environment.provider.earth_orientation.tabular_rotation"))

    assert Environment.provider_supports_request?(tabular_provider, %{
             starts_at_s: request.starts_at_s,
             ends_at_s: request.ends_at_s,
             body: request.body,
             output: :earth_rotation_angle_rad
           })

    assert Environment.provider_supports_request?(tabular_provider, %{
             starts_at_s: request.starts_at_s,
             ends_at_s: request.ends_at_s,
             body: request.body,
             product: "earth_rotation"
           })
  end

  test "derives configured tabular Earth-orientation provider coverage from declared samples" do
    samples = [
      %{seconds_since_j2000: 100.0, earth_rotation_angle_rad: 0.1},
      %{seconds_since_j2000: 0.0, earth_rotation_angle_rad: 0.0},
      %{seconds_since_j2000: 200.0, earth_rotation_angle_rad: 0.2}
    ]

    assert {:ok,
            %{
              "id" => "environment.provider.earth_orientation.tabular_rotation",
              "parameters" => %{
                "sample_count" => 3,
                "coverage_source" => "declared_samples"
              }
            } = capability} =
             Environment.configured_provider_capability(
               OrbitalDynamics.Environment.TabularEarthOrientationProvider,
               samples: samples
             )

    assert get_in(capability, ["coverage", "starts_at_s"]) == 0.0
    assert get_in(capability, ["coverage", "ends_at_s"]) == 200.0
    assert get_in(capability, ["coverage", "coverage_policy"]) == "declared_samples"
    assert :ok = Environment.validate_provider_capability(capability)

    assert Environment.provider_supports_request?(capability, %{
             starts_at_s: 10.0,
             ends_at_s: 190.0,
             body: :earth,
             output: :earth_rotation
           })

    assert Environment.configured_provider_supports_request?(
             {OrbitalDynamics.Environment.TabularEarthOrientationProvider, samples: samples},
             %{
               starts_at_s: 10.0,
               ends_at_s: 190.0,
               body: :earth,
               output: :earth_rotation
             }
           )

    assert OrbitalDynamics.configured_environment_provider_supports_request?(
             OrbitalDynamics.Environment.TabularEarthOrientationProvider,
             %{
               starts_at_s: 10.0,
               ends_at_s: 190.0,
               body: :earth,
               output: :earth_rotation
             },
             samples: samples
           )

    refute Environment.provider_supports_request?(capability, %{
             starts_at_s: -10.0,
             ends_at_s: 190.0,
             body: :earth,
             output: :earth_rotation
           })

    refute Environment.configured_provider_supports_request?(
             {OrbitalDynamics.Environment.TabularEarthOrientationProvider, samples: samples},
             %{
               starts_at_s: -10.0,
               ends_at_s: 190.0,
               body: :earth,
               output: :earth_rotation
             }
           )

    refute Environment.configured_provider_supports_request?(
             {OrbitalDynamics.Environment.TabularEarthOrientationProvider,
              samples: [
                %{seconds_since_j2000: 0.0, earth_rotation_angle_rad: 0.0},
                %{seconds_since_j2000: 0.0, earth_rotation_angle_rad: 0.1}
              ]},
             %{
               starts_at_s: 0.0,
               ends_at_s: 10.0,
               body: :earth,
               output: :earth_rotation
             }
           )

    assert {:ok, ^capability} =
             OrbitalDynamics.configured_environment_provider_capability(
               {OrbitalDynamics.Environment.TabularEarthOrientationProvider, samples: samples}
             )

    assert {:error, {:invalid_option, :samples}} =
             Environment.configured_provider_capability(
               OrbitalDynamics.Environment.TabularEarthOrientationProvider,
               samples: [
                 %{seconds_since_j2000: 0.0, earth_rotation_angle_rad: 0.0},
                 %{seconds_since_j2000: 0.0, earth_rotation_angle_rad: 0.1}
               ]
             )
  end

  test "sorts unordered unique tabular rotation samples before interpolation" do
    samples = [
      %{seconds_since_j2000: 100.0, earth_rotation_angle_rad: 1.0},
      %{seconds_since_j2000: 0.0, earth_rotation_angle_rad: 0.0}
    ]

    assert {:ok, product} =
             OrbitalDynamics.Environment.TabularEarthOrientationProvider.fetch(
               :earth_rotation,
               samples: samples,
               seconds_since_j2000: 50.0
             )

    assert product["coverage_starts_at_s"] == 0.0
    assert product["coverage_ends_at_s"] == 100.0
    assert product["earth_rotation_angle_rad"] == 0.5
  end

  test "requires trust boundaries for network-backed provider capabilities" do
    provider =
      Environment.provider_capabilities()
      |> List.first()
      |> Map.merge(%{
        "id" => "environment.provider.external.ephemeris",
        "source" => "external_ephemeris_service",
        "network_access" => true,
        "coverage" => %{
          "starts_at_s" => 0.0,
          "ends_at_s" => 86_400.0,
          "time_scale" => "seconds_since_j2000"
        }
      })

    assert {:error, {:missing_trust_boundary, "network_access"}} =
             Environment.validate_provider_capability(provider)

    assert {:error, report} = Schema.validate_artifact(provider)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.trust_boundary" and
                 &1["message"] ==
                   "is required when environment provider network_access is true")
           )

    assert :ok =
             provider
             |> Map.put("trust_boundary", "external_ephemeris_adapter")
             |> Environment.validate_provider_capability()

    assert {:ok, %{"schema_contract" => "environment_provider_capability.v1"}} =
             provider
             |> Map.put("trust_boundary", "external_ephemeris_adapter")
             |> Schema.validate_artifact()

    assert :ok =
             provider
             |> Map.put("provenance", %{"trust_boundary" => "external_ephemeris_adapter"})
             |> Environment.validate_provider_capability()

    assert {:ok, %{"schema_contract" => "environment_provider_capability.v1"}} =
             provider
             |> Map.put("provenance", %{"trust_boundary" => "external_ephemeris_adapter"})
             |> Schema.validate_artifact()
  end

  test "public facades expose environment provider capability checks" do
    assert OrbitalDynamics.environment_model_capabilities() ==
             Environment.model_capabilities()

    assert [
             %{"schema_contract" => "environment_model_capability.v1"},
             %{"schema_contract" => "environment_model_capability.v1"}
           ] = OrbitalDynamics.environment_model_capabilities()

    [fixed_sun | _providers] = OrbitalDynamics.environment_provider_capabilities()

    assert OrbitalDynamics.environment_provider_capabilities() ==
             Environment.provider_capabilities()

    assert OrbitalDynamics.validate_environment_provider_capability(fixed_sun) ==
             Environment.validate_provider_capability(fixed_sun)

    request = %{starts_at_s: 0.0, ends_at_s: 86_400.0}

    assert OrbitalDynamics.environment_provider_covers_time_span?(fixed_sun, request) ==
             Environment.provider_covers_time_span?(fixed_sun, request)

    assert OrbitalDynamics.environment_provider_supports_request?(
             fixed_sun,
             Map.merge(request, %{body: :earth, output: :sun_direction})
           ) ==
             Environment.provider_supports_request?(
               fixed_sun,
               Map.merge(request, %{body: :earth, output: :sun_direction})
             )

    assert OrbitalDynamics.environment_provider_capabilities_for_request(
             Map.merge(request, %{body: :earth, output: :sun_direction})
           ) ==
             Environment.provider_capabilities_for_request(
               Map.merge(request, %{body: :earth, output: :sun_direction})
             )

    assert {:ok, %{"schema_contract" => "environment_provider_capability.v1"}} =
             Schema.validate_artifact(fixed_sun)
  end

  test "internal providers fetch declared environment products" do
    assert {:ok,
            %{
              "provider_id" => "environment.provider.solar.fixed_inertial_direction",
              "sun_direction" => sun_direction,
              "model" => "fixed_inertial_solar_direction"
            }} =
             OrbitalDynamics.Environment.FixedSunProvider.fetch(:sun_direction,
               sun_direction: {-1.0, 0.0, 0.0}
             )

    assert sun_direction == [-1.0, 0.0, 0.0]

    assert {:ok,
            %{
              "provider_id" => "environment.provider.earth_rotation.constant_rate",
              "earth_rotation_rate_rad_s" => 7.2921150e-5,
              "earth_rotation_angle_rad" => angle_rad,
              "model" => "constant_earth_rotation"
            }} =
             OrbitalDynamics.Environment.ConstantEarthRotationProvider.fetch(:earth_rotation,
               seconds_since_j2000: 10.0
             )

    assert_in_delta angle_rad, 7.2921150e-4, 1.0e-12

    assert {:ok,
            %{
              "provider_id" => "environment.provider.earth_orientation.tabular_rotation",
              "model" => "tabular_earth_orientation_rotation",
              "earth_rotation_angle_rad" => table_angle_rad,
              "earth_rotation_rate_rad_s" => table_rate_rad_s,
              "interpolation" => "linear_declared_rotation_sample"
            }} =
             OrbitalDynamics.Environment.TabularEarthOrientationProvider.fetch(:earth_rotation,
               seconds_since_j2000: 50.0,
               samples: [
                 %{seconds_since_j2000: 0.0, earth_rotation_angle_rad: 0.0},
                 %{seconds_since_j2000: 100.0, earth_rotation_angle_rad: :math.pi() / 2.0}
               ]
             )

    assert_in_delta table_angle_rad, :math.pi() / 4.0, 1.0e-12
    assert_in_delta table_rate_rad_s, :math.pi() / 200.0, 1.0e-12

    assert {:error, {:outside_coverage, :earth_rotation}} =
             OrbitalDynamics.Environment.TabularEarthOrientationProvider.fetch(:earth_rotation,
               seconds_since_j2000: 150.0,
               samples: [
                 %{seconds_since_j2000: 0.0, earth_rotation_angle_rad: 0.0},
                 %{seconds_since_j2000: 100.0, earth_rotation_angle_rad: :math.pi() / 2.0}
               ]
             )

    assert {:error, {:invalid_option, :samples}} =
             OrbitalDynamics.Environment.TabularEarthOrientationProvider.fetch(:earth_rotation,
               seconds_since_j2000: 0.0,
               samples: [
                 %{seconds_since_j2000: 0.0, earth_rotation_angle_rad: 0.0},
                 %{seconds_since_j2000: 0.0, earth_rotation_angle_rad: :math.pi() / 2.0}
               ]
             )

    assert {:ok,
            %{
              "provider_id" => "environment.provider.atmosphere.exponential_reference",
              "model" => "single_scale_height_exponential_atmosphere",
              "altitude_km" => 400.0,
              "density_kg_m3" => density,
              "force_model_status" => "consumed_by_opt_in_two_body_drag_and_j2_drag_propagators"
            }} =
             OrbitalDynamics.Environment.ExponentialAtmosphereProvider.fetch(
               :atmosphere_density,
               altitude_km: 400.0
             )

    assert_in_delta density, 3.89e-12, 1.0e-18

    assert {:error, {:invalid_option, :scale_height_km}} =
             OrbitalDynamics.Environment.ExponentialAtmosphereProvider.fetch(
               :atmosphere_density,
               altitude_km: 400.0,
               scale_height_km: 0.0
             )
  end

  test "declares fixed Sun direction as an assumption-level capability" do
    record = Environment.fixed_sun_direction({-1.0, 0.0, 0.0})

    assert record["id"] == "environment.solar.fixed_inertial_direction"
    assert record["schema_contract"] == "environment_model_capability.v1"
    assert record["model"] == "fixed_inertial_solar_direction"
    assert record["validation_level"] == "assumption_declared"
    assert record["network_access"] == false
    assert record["parameters"]["sun_direction"] == [-1.0, 0.0, 0.0]
    assert "not an ephemeris provider" in record["known_limits"]
    assert :ok = Environment.validate_capability(record)

    assert {:ok, %{"schema_contract" => "environment_model_capability.v1"}} =
             Schema.validate_artifact(record)

    stale_record = Map.put(record, "known_limits", ["not an ephemeris provider"])

    assert {:error, {:invalid_field, "known_limits"}} =
             Environment.validate_capability(stale_record)

    assert {:error, stale_record_report} = Schema.validate_artifact(stale_record)

    assert Enum.any?(
             stale_record_report["errors"],
             &(&1["path"] == "$.known_limits" and
                 &1["message"] == "must match Environment.model_capabilities known limits")
           )
  end

  test "requires trust boundaries for network-backed environment model capabilities" do
    model =
      Environment.fixed_sun_direction({-1.0, 0.0, 0.0})
      |> Map.merge(%{
        "id" => "environment.solar.external_ephemeris",
        "model" => "external_solar_ephemeris",
        "source" => "external_ephemeris_service",
        "network_access" => true
      })

    assert {:error, {:missing_trust_boundary, "network_access"}} =
             Environment.validate_capability(model)

    assert {:error, report} = Schema.validate_artifact(model)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.trust_boundary" and
                 &1["message"] == "is required when environment model network_access is true")
           )

    assert :ok =
             model
             |> Map.put("trust_boundary", "external_ephemeris_adapter")
             |> Environment.validate_capability()

    assert {:ok, %{"schema_contract" => "environment_model_capability.v1"}} =
             model
             |> Map.put("trust_boundary", "external_ephemeris_adapter")
             |> Schema.validate_artifact()

    assert :ok =
             model
             |> Map.put("provenance", %{"trust_boundary" => "external_ephemeris_adapter"})
             |> Environment.validate_capability()

    assert {:ok, %{"schema_contract" => "environment_model_capability.v1"}} =
             model
             |> Map.put("provenance", %{"trust_boundary" => "external_ephemeris_adapter"})
             |> Schema.validate_artifact()
  end

  test "public facades expose environment model capability records" do
    sun_record = OrbitalDynamics.fixed_sun_direction({-1.0, 0.0, 0.0})
    rotation_record = OrbitalDynamics.constant_earth_rotation()

    assert sun_record == Environment.fixed_sun_direction({-1.0, 0.0, 0.0})
    assert rotation_record == Environment.constant_earth_rotation()

    assert :ok = OrbitalDynamics.validate_environment_model_capability(sun_record)
    assert :ok = OrbitalDynamics.validate_environment_model_capability(rotation_record)

    assert {:ok, %{"schema_contract" => "environment_model_capability.v1"}} =
             Schema.validate_artifact(sun_record)
  end

  test "declares constant Earth rotation as a simplified geometry capability" do
    record = Environment.constant_earth_rotation()

    assert record["id"] == "environment.earth_rotation.constant_rate"
    assert record["schema_contract"] == "environment_model_capability.v1"
    assert record["model"] == "constant_earth_rotation"
    assert record["network_access"] == false
    assert record["parameters"]["earth_rotation_rate_rad_s"] == 7.2921150e-5
    assert record["parameters"]["geometry_model"] == "simplified_spherical_earth_rotation"
    assert "no Earth orientation parameters" in record["known_limits"]
    assert :ok = Environment.validate_capability(record)

    assert {:ok, %{"schema_contract" => "environment_model_capability.v1"}} =
             Schema.validate_artifact(record)
  end

  test "schema rejects invalid provider coverage" do
    provider =
      Environment.provider_capabilities()
      |> List.first()
      |> put_in(["coverage"], %{"starts_at_s" => 20.0, "ends_at_s" => 10.0})

    assert {:error, report} = Schema.validate_artifact(provider)
    assert Enum.any?(report["errors"], &(&1["path"] == "$.coverage.ends_at_s"))
  end

  test "selects environment records from atom or string outputs" do
    assert [
             %{"id" => "environment.solar.fixed_inertial_direction"},
             %{"id" => "environment.earth_rotation.constant_rate"}
           ] =
             Environment.records_for_assumptions(%{
               outputs: [:eclipses, :access_windows],
               sun_direction: {-1.0, 0.0, 0.0}
             })

    assert [
             %{"id" => "environment.earth_rotation.constant_rate"}
           ] = Environment.records_for_assumptions(%{"outputs" => ["target_visibility"]})

    assert [] =
             Environment.records_for_assumptions(%{
               outputs: [:ground_track_crossings],
               ground_track_crossings: [%{crossing: :longitude, frame: :inertial}]
             })

    assert [
             %{"id" => "environment.earth_rotation.constant_rate"}
           ] =
             Environment.records_for_assumptions(%{
               outputs: [:ground_track_crossings],
               ground_track_crossings: [%{crossing: :longitude, frame: :body_fixed}]
             })

    assert [] = Environment.records_for_assumptions(%{outputs: [:trajectories]})
  end

  test "public API accepts assumptions or result-set-like maps" do
    assert [
             %{"id" => "environment.solar.fixed_inertial_direction"}
           ] = OrbitalDynamics.environment_models(%{outputs: [:eclipses]})

    assert [
             %{"id" => "environment.earth_rotation.constant_rate"}
           ] =
             OrbitalDynamics.environment_models(%{
               "assumptions" => %{"outputs" => ["access_windows"]}
             })
  end

  test "validates required capability record shape" do
    assert {:error, {:missing_keys, ["known_limits"]}} =
             Environment.validate_capability(%{
               "id" => "environment.test",
               "schema_contract" => "environment_model_capability.v1",
               "category" => "test",
               "model" => "test",
               "source" => "test",
               "validation_level" => "test",
               "time_span" => "test",
               "supported_bodies" => [],
               "network_access" => false,
               "parameters" => %{}
             })

    assert {:error, {:invalid_field, "network_access"}} =
             Environment.validate_capability(%{
               Environment.constant_earth_rotation()
               | "network_access" => "false"
             })

    assert {:error, {:invalid_field, "known_limits"}} =
             Environment.validate_capability(%{
               Environment.constant_earth_rotation()
               | "known_limits" => ["no Earth orientation parameters", :not_a_string]
             })

    assert {:error, model_report} =
             Schema.validate_artifact(%{
               Environment.constant_earth_rotation()
               | "supported_bodies" => ["earth", 42]
             })

    assert Enum.any?(
             model_report["errors"],
             &(&1["path"] == "$.supported_bodies[1]" and &1["message"] == "must be a string")
           )

    assert {:error, {:invalid_field, "outputs"}} =
             Environment.validate_provider_capability(%{
               List.first(Environment.provider_capabilities())
               | "outputs" => ["sun_direction", :not_a_string]
             })

    assert {:error, {:invalid_field, "model"}} =
             Environment.validate_provider_capability(%{
               List.first(Environment.provider_capabilities())
               | "model" => :fixed_inertial_solar_direction
             })

    assert {:error, provider_report} =
             Schema.validate_artifact(%{
               List.first(Environment.provider_capabilities())
               | "outputs" => ["sun_direction", 42]
             })

    assert Enum.any?(
             provider_report["errors"],
             &(&1["path"] == "$.outputs[1]" and &1["message"] == "must be a string")
           )
  end
end
