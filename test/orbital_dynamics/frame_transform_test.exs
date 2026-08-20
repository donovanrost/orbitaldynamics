defmodule OrbitalDynamics.FrameTransformTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Environment.{
    ConstantEarthRotationProvider,
    FixedSunProvider,
    TabularEarthOrientationProvider
  }

  alias OrbitalDynamics.FrameTransform
  alias OrbitalDynamics.FrameTransform.ProviderPolicy
  alias OrbitalDynamics.{CentralBody, Epoch, Frame, StateVector}

  defmodule NetworkEarthRotationProvider do
    @behaviour OrbitalDynamics.Environment.Provider

    @impl true
    def capabilities do
      %{
        "id" => "environment.provider.earth_rotation.network_test",
        "schema_contract" => "environment_provider_capability.v1",
        "category" => "body_rotation",
        "model" => "network_test_rotation",
        "source" => "test_network",
        "validation_level" => "test_only",
        "coverage" => %{
          "starts_at_s" => nil,
          "ends_at_s" => nil,
          "time_scale" => "seconds_since_j2000"
        },
        "interpolation" => "test",
        "supported_bodies" => ["earth"],
        "network_access" => true,
        "trust_boundary" => "test_only",
        "outputs" => ["earth_rotation"],
        "known_limits" => ["test only"]
      }
    end

    @impl true
    def fetch(:earth_rotation, _opts), do: raise("network provider must not be fetched")
  end

  test "declares the narrow opt-in educational transform envelope" do
    assert %{
             model: :earth_j2000_provider_defined_earth_fixed_state_transform,
             validation_level: :educational,
             supported_bodies: [:earth],
             supported_time_scales: [:tdb],
             provider_policy: :explicit_immutable_caller_supplied,
             public_facades: [:frame_transform_provider_policy, :transform_state_frame],
             round_trip_tolerances: %{
               position_km: 1.0e-9,
               velocity_km_s: 1.0e-12
             },
             known_limits: known_limits
           } = FrameTransform.capabilities()

    assert :no_authoritative_eop_source in known_limits
    assert :not_flight_certified in known_limits
    assert :no_time_scale_conversion in known_limits

    assert OrbitalDynamics.capability_catalog().analysis.frame_transform ==
             FrameTransform.capabilities()
  end

  test "captures one explicit provider policy with coverage and source revision" do
    samples = quarter_rotation_samples()

    assert {:ok, %ProviderPolicy{} = policy} =
             OrbitalDynamics.frame_transform_provider_policy(
               TabularEarthOrientationProvider,
               provider_opts: [samples: samples, source: "checked_in_test_fixture"],
               source_revision: "quarter-rotation-fixture.v1"
             )

    assert policy.provider == TabularEarthOrientationProvider
    assert policy.source_revision == "quarter-rotation-fixture.v1"
    assert policy.capability["source"] == "checked_in_test_fixture"
    assert policy.capability["network_access"] == false
    assert policy.capability["coverage"]["starts_at_s"] == 0.0
    assert policy.capability["coverage"]["ends_at_s"] == 2.0
    assert policy.capability["parameters"]["sample_count"] == 2

    assert {:error, {:missing_option, :source_revision}} =
             FrameTransform.provider_policy(ConstantEarthRotationProvider)

    assert {:error, {:invalid_earth_rotation_provider, :network_access}} =
             FrameTransform.provider_policy(NetworkEarthRotationProvider,
               source_revision: "network-test.v1"
             )
  end

  test "at epoch zero preserves position and applies the velocity transport term" do
    earth = CentralBody.earth()
    rate_rad_s = 7.2921150e-5

    state =
      state(
        {7_000.0, 0.0, 0.0},
        {0.0, 7.5, 0.0},
        0.0,
        Frame.earth_inertial_j2000()
      )

    assert {:ok, result} =
             OrbitalDynamics.transform_state_frame(
               state,
               Frame.earth_fixed(),
               earth,
               constant_policy()
             )

    assert_vector_in_delta(result.state.position_km, {7_000.0, 0.0, 0.0}, 1.0e-12)

    assert_vector_in_delta(
      result.state.velocity_km_s,
      {0.0, 7.5 - rate_rad_s * 7_000.0, 0.0},
      1.0e-12
    )

    assert result.state.epoch == state.epoch
    assert result.state.frame == Frame.earth_fixed()

    assert result.evidence.velocity.model == :rotating_frame_transport_term

    assert result.evidence.velocity.operation ==
             :subtract_omega_cross_earth_fixed_position_after_rotation

    assert_vector_in_delta(
      result.evidence.velocity.transport_term_km_s,
      {0.0, rate_rad_s * 7_000.0, 0.0},
      1.0e-12
    )
  end

  test "applies a known quarter rotation from the declared provider table" do
    state =
      state(
        {2.0, 0.0, 3.0},
        {0.0, 0.0, 0.0},
        1.0,
        Frame.earth_inertial_j2000()
      )

    assert {:ok, result} =
             FrameTransform.transform(
               state,
               Frame.earth_fixed(),
               CentralBody.earth(),
               tabular_policy()
             )

    assert_vector_in_delta(result.state.position_km, {0.0, -2.0, 3.0}, 1.0e-12)
    assert_vector_in_delta(result.state.velocity_km_s, {-:math.pi(), 0.0, 0.0}, 1.0e-12)

    assert_in_delta result.evidence.rotation.earth_rotation_angle_rad,
                    :math.pi() / 2.0,
                    1.0e-12

    assert_in_delta result.evidence.rotation.earth_rotation_rate_rad_s,
                    :math.pi() / 2.0,
                    1.0e-12

    assert_in_delta result.evidence.rotation.position_rotation_rad,
                    -:math.pi() / 2.0,
                    1.0e-12

    assert result.evidence.provider == %{
             id: "environment.provider.earth_orientation.tabular_rotation",
             model: "tabular_earth_orientation_rotation",
             source: "checked_in_test_fixture",
             source_revision: "quarter-rotation-fixture.v1",
             coverage: %{
               "coverage_policy" => "declared_samples",
               "ends_at_s" => 2.0,
               "starts_at_s" => 0.0,
               "time_scale" => "seconds_since_j2000"
             },
             interpolation: "linear_declared_rotation_sample",
             network_access: false,
             validation_level: "assumption_declared",
             known_limits: [
               "declared_sample_table_only",
               "linear_interpolation_between_declared_rotation_samples",
               "no_iers_or_bulletin_fetch",
               "not_consumed_by_current_propagators"
             ]
           }
  end

  test "forward and inverse transforms round trip within the declared tolerance" do
    initial =
      state(
        {7_000.0, -1_200.0, 400.0},
        {1.25, 7.1, -0.4},
        0.75,
        Frame.earth_inertial_j2000()
      )

    policy = tabular_policy()

    assert {:ok, forward} =
             FrameTransform.transform(initial, Frame.earth_fixed(), CentralBody.earth(), policy)

    assert forward.evidence.round_trip.within_tolerance

    assert forward.evidence.round_trip.position_error_km <=
             forward.evidence.round_trip.position_tolerance_km

    assert forward.evidence.round_trip.velocity_error_km_s <=
             forward.evidence.round_trip.velocity_tolerance_km_s

    assert {:ok, inverse} =
             FrameTransform.transform(
               forward.state,
               Frame.earth_inertial_j2000(),
               CentralBody.earth(),
               policy
             )

    assert_vector_in_delta(inverse.state.position_km, initial.position_km, 1.0e-9)
    assert_vector_in_delta(inverse.state.velocity_km_s, initial.velocity_km_s, 1.0e-12)

    assert inverse.evidence.direction ==
             :provider_defined_earth_fixed_to_earth_inertial_j2000
  end

  test "accepts provider coverage boundaries and rejects epochs outside them" do
    policy = tabular_policy()
    earth = CentralBody.earth()

    for epoch_s <- [0.0, 2.0] do
      boundary_state =
        state({7_000.0, 0.0, 0.0}, {0.0, 7.5, 0.0}, epoch_s, Frame.earth_inertial_j2000())

      assert {:ok, _result} =
               FrameTransform.transform(boundary_state, Frame.earth_fixed(), earth, policy)
    end

    for epoch_s <- [-0.001, 2.001] do
      outside_state =
        state({7_000.0, 0.0, 0.0}, {0.0, 7.5, 0.0}, epoch_s, Frame.earth_inertial_j2000())

      assert {:error, {:unsupported_provider_coverage, ^epoch_s}} =
               FrameTransform.transform(outside_state, Frame.earth_fixed(), earth, policy)
    end
  end

  test "rejects unsupported time scales, frames, central bodies, and provider products" do
    earth = CentralBody.earth()
    policy = constant_policy()

    inertial_state =
      state({7_000.0, 0.0, 0.0}, {0.0, 7.5, 0.0}, 0.0, Frame.earth_inertial_j2000())

    utc_state = %{inertial_state | epoch: Epoch.new!(0.0, :utc)}

    assert {:error, {:unsupported_time_scale, :utc}} =
             FrameTransform.transform(utc_state, Frame.earth_fixed(), earth, policy)

    moon = CentralBody.new!(:moon, 4_902.800066)

    assert {:error, {:unsupported_central_body, :moon}} =
             FrameTransform.transform(inertial_state, Frame.earth_fixed(), moon, policy)

    unsupported_source = %{
      inertial_state
      | frame: Frame.new!(:earth_inertial_of_date, :earth, :true_of_date)
    }

    assert {:error, {:unsupported_frame_transform, {:earth_inertial_of_date, :earth_body_fixed}}} =
             FrameTransform.transform(unsupported_source, Frame.earth_fixed(), earth, policy)

    unsupported_target = Frame.new!(:earth_fixed_other, :earth, :other_orientation)

    assert {:error, {:unsupported_frame_transform, {:eci_j2000, :earth_fixed_other}}} =
             FrameTransform.transform(inertial_state, unsupported_target, earth, policy)

    assert {:ok, sun_policy} =
             FrameTransform.provider_policy(FixedSunProvider,
               source_revision: "fixed-sun.v1"
             )

    assert {:error, {:unsupported_environment_request, :earth_rotation}} =
             FrameTransform.transform(inertial_state, Frame.earth_fixed(), earth, sun_policy)
  end

  test "repeated transforms return identical data and external-term bytes" do
    state =
      state(
        {7_000.0, 20.0, -3.0},
        {-0.1, 7.4, 0.02},
        1.0,
        Frame.earth_inertial_j2000()
      )

    policy = tabular_policy()

    assert {:ok, first} =
             FrameTransform.transform(state, Frame.earth_fixed(), CentralBody.earth(), policy)

    assert {:ok, second} =
             FrameTransform.transform(state, Frame.earth_fixed(), CentralBody.earth(), policy)

    assert first == second

    assert :erlang.term_to_binary(first, [:deterministic]) ==
             :erlang.term_to_binary(second, [:deterministic])
  end

  defp constant_policy do
    assert {:ok, policy} =
             FrameTransform.provider_policy(ConstantEarthRotationProvider,
               source_revision: "internal-simplified-geometry.v1"
             )

    policy
  end

  defp tabular_policy do
    assert {:ok, policy} =
             FrameTransform.provider_policy(TabularEarthOrientationProvider,
               provider_opts: [
                 samples: quarter_rotation_samples(),
                 source: "checked_in_test_fixture"
               ],
               source_revision: "quarter-rotation-fixture.v1"
             )

    policy
  end

  defp quarter_rotation_samples do
    [
      %{seconds_since_j2000: 0.0, earth_rotation_angle_rad: 0.0},
      %{seconds_since_j2000: 2.0, earth_rotation_angle_rad: :math.pi()}
    ]
  end

  defp state(position_km, velocity_km_s, seconds_since_j2000, frame) do
    StateVector.new!(
      position_km,
      velocity_km_s,
      Epoch.new!(seconds_since_j2000, :tdb),
      frame
    )
  end

  defp assert_vector_in_delta({actual_x, actual_y, actual_z}, {x, y, z}, tolerance) do
    assert_in_delta actual_x, x, tolerance
    assert_in_delta actual_y, y, tolerance
    assert_in_delta actual_z, z, tolerance
  end
end
