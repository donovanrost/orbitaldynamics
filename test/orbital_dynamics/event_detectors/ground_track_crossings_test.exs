defmodule OrbitalDynamics.EventDetectors.GroundTrackCrossingsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.EventDetectors.GroundTrackCrossings
  alias OrbitalDynamics.{Epoch, Frame, StateVector, Trajectory}

  @safe_number_bound 1_000_000_000_000_000

  defmodule StructProbe do
    defstruct [:value]
  end

  defmodule CounterfeitCampaignCapabilityProvider do
    alias OrbitalDynamics.Environment.CampaignEnvironmentProvider

    def capabilities, do: CampaignEnvironmentProvider.capabilities()
    def fetch(_kind, _opts), do: raise("counterfeit provider must be rejected before fetch")
  end

  defmodule CounterfeitCampaignProductProvider do
    alias OrbitalDynamics.Environment.ConstantEarthRotationProvider

    def capabilities, do: ConstantEarthRotationProvider.capabilities()

    def fetch(:earth_rotation, opts) do
      with {:ok, product} <- ConstantEarthRotationProvider.fetch(:earth_rotation, opts) do
        {:ok,
         product
         |> Map.put(
           "provider_id",
           "environment.provider.campaign.jpl_de441_iers_finals2000a"
         )
         |> Map.put("provenance", %{
           "provider_id" => "environment.provider.campaign.jpl_de441_iers_finals2000a",
           "trust_boundary" => "sha256_verified_checked_in_campaign_table"
         })}
      end
    end
  end

  defmodule BoundNoncampaignProvider do
    @rate 10.0 * :math.pi() / 180.0 / 100.0
    @semantic_sha256 String.duplicate("1", 64)
    @content_sha256 String.duplicate("2", 64)
    @known_limits ["caller-bound finite test provider"]
    @provenance %{
      "provider_revision" => "bound_provider.v1",
      "dataset_revision" => "bound_dataset.v1",
      "dataset_semantic_sha256" => @semantic_sha256,
      "content_sha256" => @content_sha256,
      "source_table_id" => "bound_noncampaign_table.v1",
      "trust_boundary" => "caller_configured_noncampaign_test"
    }

    def capabilities do
      %{
        "id" => "environment.provider.test.bound_noncampaign_rotation",
        "schema_contract" => "environment_provider_capability.v1",
        "category" => "body_rotation",
        "model" => "bound_noncampaign_rotation",
        "source" => "bound_noncampaign_table.v1",
        "validation_level" => "test",
        "coverage" => %{"starts_at_s" => 0.0, "ends_at_s" => 100.0},
        "interpolation" => "analytic_test_rate",
        "supported_bodies" => ["earth"],
        "network_access" => false,
        "outputs" => ["earth_rotation", "earth_rotation_angle_rad"],
        "parameters" => %{
          "provider_revision" => "bound_provider.v1",
          "dataset_revision" => "bound_dataset.v1",
          "dataset_semantic_sha256" => @semantic_sha256,
          "sample_count" => 2
        },
        "provenance" => @provenance,
        "known_limits" => @known_limits
      }
    end

    def configured_capability(_opts), do: {:ok, capabilities()}

    def fetch(:earth_rotation, opts) do
      seconds_since_j2000 = Keyword.fetch!(opts, :seconds_since_j2000)

      product = %{
        "provider_id" => capabilities()["id"],
        "model" => capabilities()["model"],
        "earth_rotation_angle_rad" => @rate * seconds_since_j2000,
        "earth_rotation_rate_rad_s" => @rate,
        "provider_revision" => @provenance["provider_revision"],
        "dataset_revision" => @provenance["dataset_revision"],
        "dataset_semantic_sha256" => @semantic_sha256,
        "content_sha256" => @content_sha256,
        "source_table_id" => @provenance["source_table_id"],
        "provenance" => @provenance,
        "known_limits" => @known_limits,
        "coverage_starts_at_s" => 0.0,
        "coverage_ends_at_s" => 100.0,
        "sample_count" => 2
      }

      case Keyword.get(opts, :tamper) do
        :revision ->
          {:ok, Map.put(product, "provider_revision", "bound_provider.v2")}

        :semantic_digest ->
          {:ok, Map.put(product, "dataset_semantic_sha256", String.duplicate("3", 64))}

        :known_limits ->
          {:ok, Map.put(product, "known_limits", ["counterfeit limit"])}

        :omit_provenance ->
          {:ok, Map.delete(product, "provenance")}

        :provenance ->
          {:ok,
           Map.put(product, "provenance", Map.put(@provenance, "dataset_revision", "forged"))}

        _untampered ->
          {:ok, product}
      end
    end
  end

  defmodule RaisingRotationCapabilityProvider do
    def capabilities, do: raise("rotation capability failure")
    def fetch(_kind, _opts), do: {:error, :unexpected_fetch}
  end

  defmodule RaisingRotationFetchProvider do
    alias OrbitalDynamics.Environment.ConstantEarthRotationProvider

    def capabilities, do: ConstantEarthRotationProvider.capabilities()
    def fetch(_kind, _opts), do: raise("rotation fetch failure")
  end

  defmodule CollidingRotationProductProvider do
    alias OrbitalDynamics.Environment.ConstantEarthRotationProvider

    def capabilities, do: ConstantEarthRotationProvider.capabilities()

    def fetch(:earth_rotation, opts) do
      with {:ok, product} <- ConstantEarthRotationProvider.fetch(:earth_rotation, opts) do
        {:ok, Map.put(product, :provider_id, product["provider_id"])}
      end
    end
  end

  defmodule UnsafeRotationProductProvider do
    alias OrbitalDynamics.Environment.ConstantEarthRotationProvider

    def capabilities, do: ConstantEarthRotationProvider.capabilities()

    def fetch(:earth_rotation, opts) do
      with {:ok, product} <- ConstantEarthRotationProvider.fetch(:earth_rotation, opts) do
        {:ok, Map.put(product, "earth_rotation_angle_rad", 1.0e16)}
      end
    end
  end

  test "declares detector capabilities" do
    assert %{
             detector: :ground_track_crossings,
             validation_level: :analysis,
             timing_policy: :sampled_state_linear_boundary,
             interpolation: :linear_sample_crossing,
             boundary_refinement: :ground_track_linear_margin_interpolation,
             supported_frames: [:inertial, :body_fixed],
             coordinate_models: coordinate_models,
             supported_body_fixed_rotation_options: rotation_options,
             known_limits: known_limits
           } = GroundTrackCrossings.capabilities()

    assert :geocentric_spherical_inertial in coordinate_models
    assert :geocentric_spherical_body_fixed_constant_rotation in coordinate_models
    assert :geocentric_spherical_body_fixed_configured_constant_rotation in coordinate_models
    assert :rotation_rate_rad_s in rotation_options
    assert :rotation_epoch_s in rotation_options
    assert :rotation_angle_offset_rad in rotation_options
    assert :earth_rotation_provider in rotation_options
    assert :sample_cadence_limited in known_limits
    assert :configured_constant_rotation_only in known_limits
    assert :refinement_not_root_solved in known_limits
    assert :no_earth_orientation_parameters in known_limits
  end

  test "detects latitude crossings with interpolated epochs and direction" do
    trajectory =
      trajectory([
        state({1.0, 0.0, -1.0}, 0.0),
        state({1.0, 0.0, 1.0}, 60.0)
      ])

    assert {:ok, [event]} =
             GroundTrackCrossings.detect(trajectory, crossing: :latitude, latitude_deg: 0.0)

    assert event.type == :latitude_crossing
    assert event.starts_at.seconds_since_j2000 > 0.0
    assert event.starts_at.seconds_since_j2000 < 60.0
    assert event.metadata.crossing == :latitude
    assert event.metadata.target_deg == 0.0
    assert event.metadata.coordinate_model == :geocentric_spherical_inertial
    assert event.metadata.crossing_direction == :northbound
    assert event.metadata.interpolation == :linear_sample_crossing
    assert event.metadata.timing_boundary.event_time_bracket_s == 60.0
    assert event.metadata.timing_boundary.before_epoch_s == 0.0
    assert event.metadata.timing_boundary.after_epoch_s == 60.0
    assert event.metadata.event_timing_policy == :sampled_state_linear_boundary
    assert event.metadata.event_detector == :ground_track_crossings
    assert event.metadata.event_time_tolerance_s == 60.0
  end

  test "detects longitude crossings across the antimeridian" do
    trajectory =
      trajectory([
        state(from_lon_lat(170.0, 0.0), 0.0),
        state(from_lon_lat(-170.0, 0.0), 60.0)
      ])

    assert {:ok, [event]} =
             GroundTrackCrossings.detect(trajectory, crossing: :longitude, longitude_deg: 180.0)

    assert event.type == :longitude_crossing
    assert event.starts_at.seconds_since_j2000 > 0.0
    assert event.starts_at.seconds_since_j2000 < 60.0
    assert event.metadata.crossing_direction == :eastbound
  end

  test "does not treat antimeridian motion as a prime-meridian crossing" do
    trajectory =
      trajectory([
        state(from_lon_lat(170.0, 0.0), 0.0),
        state(from_lon_lat(-170.0, 0.0), 60.0)
      ])

    assert {:ok, []} =
             GroundTrackCrossings.detect(trajectory, crossing: :longitude, longitude_deg: 0.0)
  end

  test "detects body-fixed longitude crossings with constant Earth rotation" do
    ten_degrees_s = 10.0 * :math.pi() / 180.0 / 7.2921150e-5

    trajectory =
      trajectory([
        state({1.0, 0.0, 0.0}, 0.0),
        state({1.0, 0.0, 0.0}, ten_degrees_s)
      ])

    assert {:ok, []} =
             GroundTrackCrossings.detect(trajectory, crossing: :longitude, longitude_deg: -5.0)

    assert {:ok, [event]} =
             GroundTrackCrossings.detect(trajectory,
               crossing: :longitude,
               longitude_deg: -5.0,
               frame: :body_fixed
             )

    assert_in_delta event.starts_at.seconds_since_j2000, ten_degrees_s / 2.0, 1.0e-9
    assert event.metadata.frame == :body_fixed
    assert event.metadata.coordinate_model == :geocentric_spherical_body_fixed_constant_rotation
    assert event.metadata.earth_rotation_rate_rad_s == 7.2921150e-5
    assert event.metadata.crossing_direction == :westbound
  end

  test "detects body-fixed longitude crossings with configured constant rotation" do
    rotation_rate_rad_s = 10.0 * :math.pi() / 180.0 / 100.0

    trajectory =
      trajectory([
        state({1.0, 0.0, 0.0}, 0.0),
        state({1.0, 0.0, 0.0}, 100.0)
      ])

    assert {:ok, [event]} =
             GroundTrackCrossings.detect(trajectory,
               crossing: :longitude,
               longitude_deg: -5.0,
               frame: :body_fixed,
               rotation_rate_rad_s: rotation_rate_rad_s,
               rotation_epoch_s: 0.0,
               rotation_angle_offset_rad: 0.0
             )

    assert_in_delta event.starts_at.seconds_since_j2000, 50.0, 1.0e-9

    assert event.metadata.coordinate_model ==
             :geocentric_spherical_body_fixed_configured_constant_rotation

    assert event.metadata.earth_rotation_rate_rad_s == rotation_rate_rad_s
    assert event.metadata.rotation_epoch_s == 0.0
    assert event.metadata.rotation_angle_offset_rad == 0.0
  end

  test "detects body-fixed longitude crossings with an Earth-rotation provider" do
    ten_degrees_s = 10.0 * :math.pi() / 180.0 / 7.2921150e-5

    trajectory =
      trajectory([
        state({1.0, 0.0, 0.0}, 0.0),
        state({1.0, 0.0, 0.0}, ten_degrees_s)
      ])

    assert {:ok, [event]} =
             GroundTrackCrossings.detect(trajectory,
               crossing: :longitude,
               longitude_deg: -5.0,
               frame: :body_fixed,
               earth_rotation_provider: OrbitalDynamics.Environment.ConstantEarthRotationProvider
             )

    assert_in_delta event.starts_at.seconds_since_j2000, ten_degrees_s / 2.0, 1.0e-9

    assert event.metadata.coordinate_model ==
             :geocentric_spherical_body_fixed_provider_rotation

    assert event.metadata.earth_rotation_provider ==
             OrbitalDynamics.Environment.ConstantEarthRotationProvider

    assert event.metadata.earth_rotation_provider_id ==
             "environment.provider.earth_rotation.constant_rate"

    assert event.metadata.earth_rotation_model == "constant_earth_rotation"
    assert event.metadata.earth_rotation_rate_rad_s == 7.2921150e-5
    assert event.metadata.before_earth_rotation_angle_rad == 0.0

    assert_in_delta event.metadata.after_earth_rotation_angle_rad,
                    10.0 * :math.pi() / 180.0,
                    1.0e-12
  end

  test "detects body-fixed longitude crossings with a configured tabular Earth-orientation provider" do
    rotation_samples = [
      %{seconds_since_j2000: 0.0, earth_rotation_angle_rad: 0.0},
      %{seconds_since_j2000: 100.0, earth_rotation_angle_rad: 10.0 * :math.pi() / 180.0}
    ]

    trajectory =
      trajectory([
        state({1.0, 0.0, 0.0}, 0.0),
        state({1.0, 0.0, 0.0}, 100.0)
      ])

    assert {:ok, [event]} =
             GroundTrackCrossings.detect(trajectory,
               crossing: :longitude,
               longitude_deg: -5.0,
               frame: :body_fixed,
               earth_rotation_provider:
                 {OrbitalDynamics.Environment.TabularEarthOrientationProvider,
                  samples: rotation_samples}
             )

    assert_in_delta event.starts_at.seconds_since_j2000, 50.0, 1.0e-9

    assert event.metadata.coordinate_model ==
             :geocentric_spherical_body_fixed_provider_rotation

    assert event.metadata.earth_rotation_provider ==
             OrbitalDynamics.Environment.TabularEarthOrientationProvider

    assert event.metadata.earth_rotation_provider_id ==
             "environment.provider.earth_orientation.tabular_rotation"

    assert event.metadata.earth_rotation_model == "tabular_earth_orientation_rotation"
    assert event.metadata.earth_rotation_interpolation == "linear_declared_rotation_sample"
    assert_in_delta event.metadata.earth_rotation_rate_rad_s, :math.pi() / 1800.0, 1.0e-12
    assert event.metadata.earth_rotation_provider_coverage_starts_at_s == 0.0
    assert event.metadata.earth_rotation_provider_coverage_ends_at_s == 100.0
    assert event.metadata.earth_rotation_provider_sample_count == 2
  end

  test "rejects generic providers that claim reserved campaign capability or product evidence" do
    trajectory =
      trajectory([
        state({1.0, 0.0, 0.0}, 0.0),
        state({1.0, 0.0, 0.0}, 100.0)
      ])

    assert {:error,
            {:untrusted_campaign_environment_provider, CounterfeitCampaignCapabilityProvider}} =
             GroundTrackCrossings.detect(trajectory,
               crossing: :longitude,
               longitude_deg: 0.0,
               frame: :body_fixed,
               earth_rotation_provider: CounterfeitCampaignCapabilityProvider
             )

    assert {:error,
            {:untrusted_campaign_environment_evidence, CounterfeitCampaignProductProvider}} =
             GroundTrackCrossings.detect(trajectory,
               crossing: :longitude,
               longitude_deg: 0.0,
               frame: :body_fixed,
               earth_rotation_provider: CounterfeitCampaignProductProvider
             )
  end

  test "rejects caller-supplied campaign provenance on a noncampaign provider" do
    trajectory =
      trajectory([
        state({1.0, 0.0, 0.0}, 0.0),
        state({1.0, 0.0, 0.0}, 100.0)
      ])

    assert {:error, {:untrusted_campaign_environment_evidence, :ground_track}} =
             GroundTrackCrossings.detect(trajectory,
               crossing: :longitude,
               longitude_deg: 0.0,
               frame: :body_fixed,
               earth_rotation_provider: OrbitalDynamics.Environment.ConstantEarthRotationProvider,
               campaign_environment: %{
                 "provider_id" => "environment.provider.campaign.jpl_de441_iers_finals2000a"
               }
             )
  end

  test "binds legitimate noncampaign revisions, digests, limits, and provenance to capability" do
    trajectory =
      trajectory([
        state({1.0, 0.0, 0.0}, 0.0),
        state({1.0, 0.0, 0.0}, 100.0)
      ])

    opts = [
      crossing: :longitude,
      longitude_deg: -5.0,
      frame: :body_fixed
    ]

    assert {:ok, [_event]} =
             GroundTrackCrossings.detect(
               trajectory,
               Keyword.put(opts, :earth_rotation_provider, BoundNoncampaignProvider)
             )

    for {tamper, field} <- [
          {:revision, "provider_revision"},
          {:semantic_digest, "dataset_semantic_sha256"},
          {:known_limits, "known_limits"},
          {:provenance, "provenance"}
        ] do
      assert {:error, {:environment_provider_product_mismatch, ^field, _expected, _actual}} =
               GroundTrackCrossings.detect(
                 trajectory,
                 Keyword.put(
                   opts,
                   :earth_rotation_provider,
                   {BoundNoncampaignProvider, tamper: tamper}
                 )
               )
    end

    assert {:error, {:invalid_environment_product, "provenance"}} =
             GroundTrackCrossings.detect(
               trajectory,
               Keyword.put(
                 opts,
                 :earth_rotation_provider,
                 {BoundNoncampaignProvider, tamper: :omit_provenance}
               )
             )
  end

  test "refines bracketed latitude and longitude crossing boundaries" do
    before_latitude = state({1.0, 0.0, -1.0}, 0.0)
    after_latitude = state({1.0, 0.0, 1.0}, 60.0)

    assert {:ok, latitude} =
             GroundTrackCrossings.refine_crossing_boundary(before_latitude, after_latitude,
               crossing: :latitude,
               latitude_deg: 0.0
             )

    assert latitude.boundary == :latitude_crossing
    assert latitude.crossing == :latitude
    assert latitude.crossing_direction == :northbound
    assert latitude.interpolation == :linear_sample_crossing
    assert latitude.interpolation_fraction > 0.0
    assert latitude.interpolation_fraction < 1.0
    assert latitude.epoch.seconds_since_j2000 > 0.0
    assert latitude.epoch.seconds_since_j2000 < 60.0
    assert latitude.assumptions.root_solved == false
    assert latitude.assumptions.confidence == :bounded_by_sample_cadence
    assert latitude.assumptions.coordinate_model == :geocentric_spherical_inertial
    assert latitude.assumptions.event_time_bracket_s == 60.0
    assert latitude.assumptions.before_epoch_s == 0.0
    assert latitude.assumptions.after_epoch_s == 60.0

    before_longitude = state(from_lon_lat(-10.0, 0.0), 0.0)
    after_longitude = state(from_lon_lat(10.0, 0.0), 60.0)

    assert {:ok, longitude} =
             OrbitalDynamics.refine_ground_track_crossing_boundary(
               before_longitude,
               after_longitude,
               crossing: :longitude,
               longitude_deg: 0.0
             )

    assert longitude.boundary == :longitude_crossing
    assert longitude.crossing_direction == :eastbound
    assert_in_delta longitude.epoch.seconds_since_j2000, 30.0, 1.0e-9
  end

  test "refines body-fixed longitude crossings with configured rotation assumptions" do
    rotation_rate_rad_s = 10.0 * :math.pi() / 180.0 / 100.0

    assert {:ok, refined} =
             GroundTrackCrossings.refine_crossing_boundary(
               state({1.0, 0.0, 0.0}, 0.0),
               state({1.0, 0.0, 0.0}, 100.0),
               crossing: "longitude",
               longitude_deg: -5.0,
               frame: :body_fixed,
               rotation_rate_rad_s: rotation_rate_rad_s,
               rotation_epoch_s: 0.0,
               rotation_angle_offset_rad: 0.0
             )

    assert refined.crossing == :longitude
    assert refined.crossing_direction == :westbound
    assert_in_delta refined.epoch.seconds_since_j2000, 50.0, 1.0e-9

    assert refined.assumptions.coordinate_model ==
             :geocentric_spherical_body_fixed_configured_constant_rotation

    assert refined.assumptions.earth_rotation_rate_rad_s == rotation_rate_rad_s
    assert refined.assumptions.rotation_epoch_s == 0.0
    assert refined.assumptions.rotation_angle_offset_rad == 0.0
  end

  test "rejects unbracketed ground-track crossing boundary refinement" do
    assert {:error, :not_bracketed} =
             GroundTrackCrossings.refine_crossing_boundary(
               state({1.0, 0.0, 1.0}, 0.0),
               state({1.0, 0.0, 2.0}, 60.0),
               crossing: :latitude,
               latitude_deg: 0.0
             )
  end

  test "public API detects latitude and longitude crossings" do
    trajectory =
      trajectory([
        state({1.0, 0.0, -1.0}, 0.0),
        state({1.0, 0.0, 1.0}, 60.0)
      ])

    assert {:ok, [%{type: :latitude_crossing}]} =
             OrbitalDynamics.latitude_crossings(trajectory, 0.0)

    trajectory =
      trajectory([
        state(from_lon_lat(-10.0, 0.0), 0.0),
        state(from_lon_lat(10.0, 0.0), 60.0)
      ])

    assert {:ok, [%{type: :longitude_crossing}]} =
             OrbitalDynamics.longitude_crossings(trajectory, 0.0)
  end

  test "rejects invalid detector options and zero-position states" do
    trajectory = trajectory([state({1.0, 0.0, 0.0}, 0.0)])

    assert {:error, {:invalid_option, :latitude_deg}} =
             GroundTrackCrossings.detect(trajectory, crossing: :latitude, latitude_deg: 91.0)

    trajectory = trajectory([state({0.0, 0.0, 0.0}, 0.0)])

    assert {:error, {:invalid_trajectory, :zero_position}} =
             GroundTrackCrossings.detect(trajectory, crossing: :latitude, latitude_deg: 0.0)

    assert {:error, {:invalid_option, :frame}} =
             GroundTrackCrossings.detect(trajectory,
               crossing: :latitude,
               latitude_deg: 0.0,
               frame: :unsupported
             )

    assert {:error, {:invalid_option, :rotation_rate_rad_s}} =
             GroundTrackCrossings.detect(trajectory,
               crossing: :longitude,
               longitude_deg: 0.0,
               frame: :body_fixed,
               rotation_rate_rad_s: :fast
             )
  end

  test "provider request admission rejects hostile map aliases and containers" do
    request = %{
      starts_at_s: 0.0,
      ends_at_s: 100.0,
      body: :earth,
      output: :earth_rotation
    }

    assert {:error, {:atom_string_alias_collision, "starts_at_s"}} =
             GroundTrackCrossings.validate_earth_rotation_provider(
               OrbitalDynamics.Environment.ConstantEarthRotationProvider,
               Map.put(request, "starts_at_s", 0.0)
             )

    assert {:error, {:invalid_field, "starts_at_s"}} =
             GroundTrackCrossings.validate_earth_rotation_provider(
               OrbitalDynamics.Environment.ConstantEarthRotationProvider,
               %{request | starts_at_s: 1.0e16}
             )

    assert {:error, {:invalid_field, "starts_at_s"}} =
             GroundTrackCrossings.validate_earth_rotation_provider(
               OrbitalDynamics.Environment.ConstantEarthRotationProvider,
               %{request | starts_at_s: @safe_number_bound + 1}
             )

    assert {:error, {:invalid_field, "starts_at_s"}} =
             GroundTrackCrossings.validate_earth_rotation_provider(
               OrbitalDynamics.Environment.ConstantEarthRotationProvider,
               %{request | starts_at_s: huge_integer()}
             )

    for {label, nonfinite} <- nonfinite_float_values() do
      assert {:error, {:invalid_field, "starts_at_s"}} =
               GroundTrackCrossings.validate_earth_rotation_provider(
                 OrbitalDynamics.Environment.ConstantEarthRotationProvider,
                 %{request | starts_at_s: nonfinite}
               ),
             "#{label} provider request start was admitted"
    end

    assert {:error, {:invalid_field, "ends_at_s"}} =
             GroundTrackCrossings.validate_earth_rotation_provider(
               OrbitalDynamics.Environment.ConstantEarthRotationProvider,
               %{request | starts_at_s: 10.0, ends_at_s: 0.0}
             )

    assert {:error, {:container_limit_exceeded, :provider_request}} =
             GroundTrackCrossings.validate_earth_rotation_provider(
               RaisingRotationCapabilityProvider,
               Map.merge(request, wide_map(129))
             )

    for invalid_key <- [42, {:tuple, :key}] do
      assert {:error, {:invalid_container, :provider_request}} =
               GroundTrackCrossings.validate_earth_rotation_provider(
                 RaisingRotationCapabilityProvider,
                 Map.put(request, invalid_key, "safe")
               ),
             "top-level invalid provider request key #{inspect(invalid_key)} reached provider"
    end

    assert {:error, {:invalid_container, :provider_request}} =
             GroundTrackCrossings.validate_earth_rotation_provider(
               OrbitalDynamics.Environment.ConstantEarthRotationProvider,
               Map.put(request, :outputs, ["earth_rotation" | :tail])
             )

    assert {:error, {:unsupported_key, :provider_request}} =
             GroundTrackCrossings.validate_earth_rotation_provider(
               OrbitalDynamics.Environment.ConstantEarthRotationProvider,
               Map.put(request, :ignored, "safe")
             )

    assert {:error, {:invalid_container, :provider_request}} =
             GroundTrackCrossings.validate_earth_rotation_provider(
               OrbitalDynamics.Environment.ConstantEarthRotationProvider,
               Map.put(request, :ignored, huge_integer())
             )

    for key <- [:body, :output, :product, :frame],
        safe_wrong_type <- [42, @safe_number_bound] do
      wrong_type_request = wrong_type_request(request, key, safe_wrong_type)

      assert {:error, {:environment_provider_request_mismatch, mismatch_request}} =
               GroundTrackCrossings.validate_earth_rotation_provider(
                 OrbitalDynamics.Environment.ConstantEarthRotationProvider,
                 wrong_type_request
               ),
             "#{key} safe wrong-type value #{safe_wrong_type} did not use provider mismatch"

      assert Map.fetch!(mismatch_request, key) == safe_wrong_type
    end

    for {key, field_name} <- provider_request_non_time_keys() do
      assert {:error, {:invalid_field, ^field_name}} =
               GroundTrackCrossings.validate_earth_rotation_provider(
                 OrbitalDynamics.Environment.ConstantEarthRotationProvider,
                 Map.put(request, key, @safe_number_bound + 1)
               ),
             "#{key} bound+1 numeric was admitted"

      assert {:error, {:invalid_field, ^field_name}} =
               GroundTrackCrossings.validate_earth_rotation_provider(
                 OrbitalDynamics.Environment.ConstantEarthRotationProvider,
                 Map.put(request, key, huge_integer())
               ),
             "#{key} huge integer was admitted"

      for {label, nonfinite} <- nonfinite_float_values() do
        assert {:error, {:invalid_field, ^field_name}} =
                 GroundTrackCrossings.validate_earth_rotation_provider(
                   OrbitalDynamics.Environment.ConstantEarthRotationProvider,
                   Map.put(request, key, nonfinite)
                 ),
               "#{label} #{inspect(key)} value was admitted"
      end
    end

    callback_probe = fn -> send(self(), :ground_track_request_callback_invoked) end

    for {label, bad_value} <- hostile_option_values(callback_probe) do
      assert {:error, {:invalid_container, :provider_request}} =
               GroundTrackCrossings.validate_earth_rotation_provider(
                 OrbitalDynamics.Environment.ConstantEarthRotationProvider,
                 Map.put(request, :ignored, bad_value)
               ),
             "#{label} ignored provider request value was admitted"

      assert {:error, {:invalid_container, :provider_request}} =
               GroundTrackCrossings.validate_earth_rotation_provider(
                 OrbitalDynamics.Environment.ConstantEarthRotationProvider,
                 Map.put(request, :output, bad_value)
               ),
             "#{label} provider request output value was admitted"

      refute_receive :ground_track_request_callback_invoked
    end
  end

  test "public ground-track boundaries reject hostile inputs with typed errors" do
    before_state = state({1.0, 0.0, -1.0}, 0.0)
    after_state = state({1.0, 0.0, 1.0}, 60.0)
    trajectory = trajectory([before_state, after_state])

    assert {:error, {:missing_option, :latitude_deg}} =
             GroundTrackCrossings.detect(trajectory, crossing: :latitude)

    assert {:error, {:invalid_container, :opts}} =
             GroundTrackCrossings.detect(trajectory, [{:crossing, :latitude} | :tail])

    assert {:error, {:container_depth_exceeded, :opts}} =
             GroundTrackCrossings.detect(trajectory,
               crossing: :latitude,
               latitude_deg: 0.0,
               audit_payload: deep_value(13)
             )

    assert {:error, {:invalid_container, :opts}} =
             GroundTrackCrossings.detect(trajectory,
               crossing: :latitude,
               latitude_deg: 0.0,
               audit_payload: %{42 => "bad key"}
             )

    assert {:error, {:invalid_container, :opts}} =
             GroundTrackCrossings.detect(trajectory,
               crossing: :latitude,
               latitude_deg: 0.0,
               ignored: @safe_number_bound + 1
             )

    assert {:error, {:invalid_container, :opts}} =
             GroundTrackCrossings.detect(trajectory,
               crossing: :latitude,
               latitude_deg: 0.0,
               ignored: huge_integer()
             )

    assert {:error, {:unsupported_option, :ignored}} =
             GroundTrackCrossings.detect(trajectory,
               crossing: :latitude,
               latitude_deg: 0.0,
               ignored: "safe"
             )

    assert {:error, {:invalid_option, :trajectory}} =
             GroundTrackCrossings.detect(:not_a_trajectory,
               crossing: :latitude,
               latitude_deg: 0.0
             )

    assert {:error, {:invalid_container, :states}} =
             GroundTrackCrossings.detect(
               %Trajectory{trajectory | states: [before_state | :tail]},
               crossing: :latitude,
               latitude_deg: 0.0
             )

    assert {:error, {:invalid_state, :state}} =
             GroundTrackCrossings.detect(
               %Trajectory{
                 trajectory
                 | states: [%{before_state | position_km: {1.0e16, 0.0, 0.0}}]
               },
               crossing: :latitude,
               latitude_deg: 0.0
             )

    assert {:error, {:invalid_trajectory, :non_increasing_epochs}} =
             GroundTrackCrossings.detect(
               trajectory([after_state, before_state]),
               crossing: :latitude,
               latitude_deg: 0.0
             )

    assert {:error, {:invalid_option, :rotation_rate_rad_s}} =
             GroundTrackCrossings.detect(trajectory,
               crossing: :longitude,
               longitude_deg: 0.0,
               frame: :body_fixed,
               rotation_rate_rad_s: 1.0e16
             )

    assert {:ok, exact_bound_events} =
             GroundTrackCrossings.detect(trajectory,
               crossing: :longitude,
               longitude_deg: 0.0,
               frame: :body_fixed,
               rotation_epoch_s: @safe_number_bound,
               rotation_rate_rad_s: 0.0
             )

    assert is_list(exact_bound_events)

    assert {:error, {:invalid_option, :rotation_rate_rad_s}} =
             GroundTrackCrossings.detect(trajectory,
               crossing: :longitude,
               longitude_deg: 0.0,
               frame: :body_fixed,
               rotation_rate_rad_s: @safe_number_bound + 1
             )

    assert {:error, {:invalid_option, :rotation_rate_rad_s}} =
             GroundTrackCrossings.detect(trajectory,
               crossing: :longitude,
               longitude_deg: 0.0,
               frame: :body_fixed,
               rotation_rate_rad_s: huge_integer()
             )

    for {label, nonfinite} <- nonfinite_float_values() do
      assert {:error, {:invalid_option, :rotation_rate_rad_s}} =
               GroundTrackCrossings.detect(trajectory,
                 crossing: :longitude,
                 longitude_deg: 0.0,
                 frame: :body_fixed,
                 rotation_rate_rad_s: nonfinite
               ),
             "#{label} rotation rate option was admitted"
    end

    for key <- [:body, :output, :product, :frame],
        {label, bad_value} <-
          [{"bound+1", @safe_number_bound + 1}, {"huge", huge_integer()}] ++
            nonfinite_float_values() do
      assert {:error, {:invalid_container, :opts}} =
               GroundTrackCrossings.detect(trajectory,
                 crossing: :longitude,
                 longitude_deg: 0.0,
                 frame: :body_fixed,
                 earth_rotation_provider: {RaisingRotationFetchProvider, [{key, bad_value}]}
               ),
             "#{label} nested rotation provider #{key} option reached fetch"
    end

    callback_probe = fn -> send(self(), :ground_track_callback_invoked) end

    for {label, bad_value} <- hostile_option_values(callback_probe) do
      assert {:error, {:invalid_container, :opts}} =
               GroundTrackCrossings.detect(trajectory,
                 crossing: :latitude,
                 latitude_deg: 0.0,
                 ignored: bad_value
               ),
             "#{label} ignored ground-track option was admitted"

      assert {:error, {:invalid_container, :opts}} =
               GroundTrackCrossings.detect(trajectory,
                 crossing: :longitude,
                 longitude_deg: 0.0,
                 frame: :body_fixed,
                 earth_rotation_provider:
                   {OrbitalDynamics.Environment.ConstantEarthRotationProvider, ignored: bad_value}
               ),
             "#{label} nested rotation provider option was admitted"

      assert {:error, {:invalid_container, :opts}} =
               GroundTrackCrossings.detect(trajectory,
                 crossing: :longitude,
                 longitude_deg: 0.0,
                 frame: :body_fixed,
                 earth_rotation_provider:
                   {OrbitalDynamics.Environment.ConstantEarthRotationProvider, body: bad_value}
               ),
             "#{label} nested rotation provider body option was admitted"

      assert {:error, {:invalid_container, :opts}} =
               GroundTrackCrossings.refine_crossing_boundary(
                 before_state,
                 after_state,
                 crossing: :latitude,
                 latitude_deg: 0.0,
                 ignored: bad_value
               ),
             "#{label} refine ignored ground-track option was admitted"

      refute_receive :ground_track_callback_invoked
    end

    assert {:error, {:invalid_option, :crossing_boundary}} =
             GroundTrackCrossings.refine_crossing_boundary(:before, after_state,
               crossing: :latitude,
               latitude_deg: 0.0
             )

    assert {:error, {:invalid_state, :before_state}} =
             GroundTrackCrossings.refine_crossing_boundary(
               %{before_state | velocity_km_s: {0.0, 1.0e16, 0.0}},
               after_state,
               crossing: :latitude,
               latitude_deg: 0.0
             )

    assert {:error, {:container_limit_exceeded, :opts}} =
             GroundTrackCrossings.refine_crossing_boundary(
               before_state,
               after_state,
               crossing: :latitude,
               latitude_deg: 0.0,
               audit_payload: wide_map(129)
             )
  end

  test "provider-backed ground-track detection rejects bad callbacks and products" do
    trajectory =
      trajectory([
        state({1.0, 0.0, 0.0}, 0.0),
        state({1.0, 0.0, 0.0}, 100.0)
      ])

    base_opts = [
      crossing: :longitude,
      longitude_deg: 0.0,
      frame: :body_fixed
    ]

    assert {:error,
            {:environment_provider_callback_failed, RaisingRotationCapabilityProvider,
             :capabilities}} =
             GroundTrackCrossings.detect(
               trajectory,
               Keyword.put(base_opts, :earth_rotation_provider, RaisingRotationCapabilityProvider)
             )

    assert {:error, {:environment_provider_callback_failed, RaisingRotationFetchProvider, :fetch}} =
             GroundTrackCrossings.detect(
               trajectory,
               Keyword.put(base_opts, :earth_rotation_provider, RaisingRotationFetchProvider)
             )

    assert {:error, {:atom_string_alias_collision, "provider_id"}} =
             GroundTrackCrossings.detect(
               trajectory,
               Keyword.put(base_opts, :earth_rotation_provider, CollidingRotationProductProvider)
             )

    assert {:error, {:invalid_container, :environment_product}} =
             GroundTrackCrossings.detect(
               trajectory,
               Keyword.put(base_opts, :earth_rotation_provider, UnsafeRotationProductProvider)
             )
  end

  defp trajectory(states) do
    %Trajectory{
      scenario_id: :ground_track_test,
      states: states,
      assumptions: %{force_model: :manual}
    }
  end

  defp state(position_km, seconds_since_j2000) do
    StateVector.new!(
      position_km,
      {0.0, 0.0, 0.0},
      Epoch.new!(seconds_since_j2000, :tdb),
      Frame.earth_inertial_j2000()
    )
  end

  defp from_lon_lat(longitude_deg, latitude_deg) do
    longitude_rad = longitude_deg * :math.pi() / 180.0
    latitude_rad = latitude_deg * :math.pi() / 180.0
    cos_latitude = :math.cos(latitude_rad)

    {
      cos_latitude * :math.cos(longitude_rad),
      cos_latitude * :math.sin(longitude_rad),
      :math.sin(latitude_rad)
    }
  end

  defp deep_value(depth) do
    Enum.reduce(1..depth, "leaf", fn index, acc -> %{"level_#{index}" => acc} end)
  end

  defp wide_map(count) do
    Map.new(1..count, fn index -> {"k#{index}", index} end)
  end

  defp hostile_option_values(callback_probe) do
    [
      {"struct", %StructProbe{value: :nested}},
      {"pid", self()},
      {"reference", make_ref()},
      {"function", callback_probe},
      {"tuple", {:tuple, :not_json}}
    ] ++ port_probe_values()
  end

  defp port_probe_values do
    case Port.list() do
      [port | _rest] -> [{"port", port}]
      [] -> []
    end
  end

  defp provider_request_non_time_keys do
    [
      {:body, "body"},
      {"body", "body"},
      {:bodies, "bodies"},
      {"bodies", "bodies"},
      {:central_body, "central_body"},
      {"central_body", "central_body"},
      {:output, "output"},
      {"output", "output"},
      {:outputs, "outputs"},
      {"outputs", "outputs"},
      {:product, "product"},
      {"product", "product"},
      {:kind, "kind"},
      {"kind", "kind"},
      {:frame, "frame"},
      {"frame", "frame"},
      {:frames, "frames"},
      {"frames", "frames"},
      {:time_scale, "time_scale"},
      {"time_scale", "time_scale"},
      {:time_scales, "time_scales"},
      {"time_scales", "time_scales"}
    ]
  end

  defp wrong_type_request(request, :product, value),
    do: request |> Map.delete(:output) |> Map.put(:product, value)

  defp wrong_type_request(request, key, value), do: Map.put(request, key, value)

  defp huge_integer, do: :erlang.bsl(1, 1_000_000)

  defp nonfinite_float_values do
    [
      {"nan", <<131, 70, 127, 248, 0, 0, 0, 0, 0, 1>>},
      {"positive infinity", <<131, 70, 127, 240, 0, 0, 0, 0, 0, 0>>},
      {"negative infinity", <<131, 70, 255, 240, 0, 0, 0, 0, 0, 0>>}
    ]
    |> Enum.flat_map(fn {label, bytes} ->
      case construct_nonfinite_float(bytes) do
        {:ok, value} -> [{label, value}]
        :error -> []
      end
    end)
  end

  defp construct_nonfinite_float(bytes) do
    {:ok, :erlang.binary_to_term(bytes)}
  rescue
    _error in [ArgumentError] -> :error
  end
end
