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

  @maximum_position_component_km 1.0e9
  @maximum_velocity_component_km_s 2.0e4
  @maximum_epoch_magnitude_s 1.0e12
  @maximum_earth_rotation_angle_magnitude_rad 1.0e12
  @maximum_earth_rotation_rate_magnitude_rad_s 2.0
  @retained_quarter_rotation_rate_rad_s :math.pi() / 2.0
  @position_absolute_tolerance_km 1.0e-9
  @velocity_absolute_tolerance_km_s 1.0e-12
  @round_trip_relative_scale_factor 1.0e-12

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

  defmodule BoundedEarthRotationProvider do
    @behaviour OrbitalDynamics.Environment.Provider

    @impl true
    def capabilities do
      %{
        "id" => "environment.provider.earth_rotation.bounded_test",
        "schema_contract" => "environment_provider_capability.v1",
        "category" => "body_rotation",
        "model" => "bounded_test_rotation",
        "source" => "checked_in_frame_transform_test",
        "validation_level" => "test_only",
        "coverage" => %{
          "starts_at_s" => nil,
          "ends_at_s" => nil,
          "time_scale" => "seconds_since_j2000",
          "coverage_policy" => "all_times"
        },
        "interpolation" => "test_constant",
        "supported_bodies" => ["earth"],
        "network_access" => false,
        "trust_boundary" => "test_only",
        "outputs" => [
          "earth_rotation",
          "earth_rotation_angle_rad",
          "earth_rotation_rate_rad_s"
        ],
        "known_limits" => ["test only"]
      }
    end

    @impl true
    def fetch(:earth_rotation, opts) do
      angle_rad = Keyword.get(opts, :earth_rotation_angle_rad, 0.0)
      rate_rad_s = Keyword.get(opts, :earth_rotation_rate_rad_s, 0.0)

      case Keyword.get(opts, :test_pid) do
        pid when is_pid(pid) ->
          send(pid, {:bounded_earth_rotation_fetched, angle_rad, rate_rad_s})

        _pid -> :ok
      end

      {:ok,
       %{
         "provider_id" =>
           Keyword.get(opts, :product_provider_id, capabilities()["id"]),
         "model" => Keyword.get(opts, :product_model, capabilities()["model"]),
         "earth_rotation_angle_rad" => angle_rad,
         "earth_rotation_rate_rad_s" => rate_rad_s,
         "interpolation" => capabilities()["interpolation"]
       }}
    end
  end

  test "declares the narrow opt-in educational transform envelope" do
    assert %{
             model: :earth_j2000_provider_defined_earth_fixed_state_transform,
             validation_level: :educational,
             supported_bodies: [:earth],
             supported_time_scales: [:tdb],
             provider_policy: :explicit_immutable_caller_supplied,
             provider_policy_integrity: :sha256_same_runtime_content_binding,
             supported_numeric_envelope: %{
               bound_policy: :inclusive,
               scope: :per_call_input_and_provider_product,
               transformed_state_re_admission: :not_guaranteed,
               state: %{
                 position_component_abs_max_km: @maximum_position_component_km,
                 velocity_component_abs_max_km_s: @maximum_velocity_component_km_s,
                 epoch_abs_max_s_since_j2000: @maximum_epoch_magnitude_s
               },
               provider_product: %{
                 earth_rotation_angle_abs_max_rad:
                   @maximum_earth_rotation_angle_magnitude_rad,
                 earth_rotation_rate_abs_max_rad_s:
                   @maximum_earth_rotation_rate_magnitude_rad_s
               }
             },
             public_facades: [:frame_transform_provider_policy, :transform_state_frame],
             round_trip_tolerances: %{
               position_km: @position_absolute_tolerance_km,
               velocity_km_s: @velocity_absolute_tolerance_km_s,
               model: :absolute_floor_plus_realized_scale,
               position_absolute_floor_km: @position_absolute_tolerance_km,
               velocity_absolute_floor_km_s: @velocity_absolute_tolerance_km_s,
               relative_scale_factor: @round_trip_relative_scale_factor
             },
             known_limits: known_limits
           } = FrameTransform.capabilities()

    assert :no_authoritative_eop_source in known_limits
    assert :not_flight_certified in known_limits
    assert :no_time_scale_conversion in known_limits
    assert :input_envelope_not_closed_under_transform in known_limits
    assert @maximum_earth_rotation_rate_magnitude_rad_s >=
             @retained_quarter_rotation_rate_rad_s

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
    assert Regex.match?(~r/\A[0-9a-f]{64}\z/, policy.integrity_sha256)

    assert {:ok, repeated_policy} =
             OrbitalDynamics.frame_transform_provider_policy(
               TabularEarthOrientationProvider,
               provider_opts: [samples: samples, source: "checked_in_test_fixture"],
               source_revision: "quarter-rotation-fixture.v1"
             )

    assert repeated_policy.integrity_sha256 == policy.integrity_sha256

    assert {:error, {:missing_option, :source_revision}} =
             FrameTransform.provider_policy(ConstantEarthRotationProvider)

    assert {:error, {:invalid_earth_rotation_provider, :network_access}} =
             FrameTransform.provider_policy(NetworkEarthRotationProvider,
               source_revision: "network-test.v1"
             )
  end

  test "binds every provider policy field and rejects mutation before provider fetch" do
    policy = bounded_policy(test_pid: self())
    state = nominal_inertial_state()

    assert {:ok, _result} =
             FrameTransform.transform(
               state,
               Frame.earth_fixed(),
               CentralBody.earth(),
               policy
             )

    assert_receive {:bounded_earth_rotation_fetched, 0.0, 0.0}

    mutated_policies = [
      %{policy | provider: ConstantEarthRotationProvider},
      %{
        policy
        | provider_opts: Keyword.put(policy.provider_opts, :earth_rotation_angle_rad, 1.0)
      },
      %{policy | capability: Map.put(policy.capability, "source", "forged")},
      %{policy | capability: Map.put(policy.capability, "model", "forged")},
      %{policy | source_revision: "forged.v1"},
      %{policy | integrity_sha256: String.duplicate("0", 64)},
      Map.delete(policy, :integrity_sha256)
    ]

    Enum.each(mutated_policies, fn mutated_policy ->
      assert {:error, {:invalid_provider_policy, :integrity_sha256}} =
               FrameTransform.transform(
                 state,
                 Frame.earth_fixed(),
                 CentralBody.earth(),
                 mutated_policy
               )
    end)

    refute_receive {:bounded_earth_rotation_fetched, _angle_rad, _rate_rad_s}
  end

  test "admits every state component and epoch at inclusive limits and rejects next floats" do
    policy = bounded_policy()
    earth = CentralBody.earth()
    target = Frame.earth_fixed()

    vector_fields = [
      {:position_km, @maximum_position_component_km, {:unsupported_state, :position_km}},
      {:velocity_km_s, @maximum_velocity_component_km_s,
       {:unsupported_state, :velocity_km_s}}
    ]

    for {field, maximum, expected_error} <- vector_fields,
        component_index <- 0..2,
        sign <- [-1.0, 1.0] do
      boundary_vector = put_elem({0.0, 0.0, 0.0}, component_index, sign * maximum)
      boundary_state = Map.put(nominal_inertial_state(), field, boundary_vector)

      assert {:ok, _result} =
               FrameTransform.transform(boundary_state, target, earth, policy)

      outside_vector =
        put_elem({0.0, 0.0, 0.0}, component_index, sign * next_up(maximum))

      outside_state = Map.put(nominal_inertial_state(), field, outside_vector)

      assert {:error, ^expected_error} =
               FrameTransform.transform(outside_state, target, earth, policy)
    end

    for sign <- [-1.0, 1.0] do
      boundary_epoch = sign * @maximum_epoch_magnitude_s

      assert {:ok, _result} =
               nominal_inertial_state(boundary_epoch)
               |> FrameTransform.transform(target, earth, policy)

      outside_epoch = sign * next_up(@maximum_epoch_magnitude_s)

      assert {:error, {:unsupported_time, :seconds_since_j2000}} =
               nominal_inertial_state(outside_epoch)
               |> FrameTransform.transform(target, earth, policy)
    end
  end

  test "returns typed errors for numeric extremes, sentinels, and malformed public states" do
    policy = bounded_policy()
    earth = CentralBody.earth()
    target = Frame.earth_fixed()
    base = nominal_inertial_state()
    huge_integer = Integer.pow(2, 4096)

    cases = [
      {%{base | position_km: {huge_integer, 0.0, 0.0}},
       {:error, {:unsupported_state, :position_km}}},
      {%{base | velocity_km_s: {0.0, huge_integer, 0.0}},
       {:error, {:unsupported_state, :velocity_km_s}}},
      {%{base | epoch: Epoch.new!(huge_integer, :tdb)},
       {:error, {:unsupported_time, :seconds_since_j2000}}},
      {%{base | position_km: {1.0e308, 0.0, 0.0}},
       {:error, {:unsupported_state, :position_km}}},
      {%{base | velocity_km_s: {0.0, 1.0e308, 0.0}},
       {:error, {:unsupported_state, :velocity_km_s}}},
      {%{base | epoch: Epoch.new!(1.0e308, :tdb)},
       {:error, {:unsupported_time, :seconds_since_j2000}}},
      {%{base | position_km: {:nan, 0.0, 0.0}},
       {:error, {:invalid_state, :state_vector}}},
      {%{base | velocity_km_s: {0.0, :infinity, 0.0}},
       {:error, {:invalid_state, :state_vector}}},
      {%{base | epoch: %{base.epoch | seconds_since_j2000: :infinity}},
       {:error, {:invalid_state, :state_vector}}},
      {%{base | position_km: {7_000.0, 0.0}}, {:error, {:invalid_state, :state_vector}}},
      {%{base | velocity_km_s: [0.0, 7.5, 0.0]}, {:error, {:invalid_state, :state_vector}}},
      {%{base | epoch: %{scale: :tdb, seconds_since_j2000: 0.0}},
       {:error, {:invalid_state, :state_vector}}}
    ]

    Enum.each(cases, fn {bad_state, expected} ->
      assert ^expected = FrameTransform.transform(bad_state, target, earth, policy)
    end)

    invalid_scale_state = %{base | epoch: %{base.epoch | scale: :ut1}}

    assert {:error, {:unsupported_time_scale, :ut1}} =
             FrameTransform.transform(invalid_scale_state, target, earth, policy)
  end

  test "totalizes malformed tagged frames and central bodies before provider fetch" do
    policy = bounded_policy(test_pid: self())
    state = nominal_inertial_state()
    target = Frame.earth_fixed()
    earth = CentralBody.earth()
    huge_integer = Integer.pow(2, 4096)

    malformed_body_cases =
      Enum.map([:name, :mu_km3_s2, :equatorial_radius_km, :j2], fn field ->
        {Map.delete(earth, field), {:error, {:invalid_central_body, field}}}
      end) ++
        [
          {%{earth | name: "earth"}, {:error, {:invalid_central_body, :name}}},
          {%{earth | mu_km3_s2: nil}, {:error, {:invalid_central_body, :mu_km3_s2}}},
          {%{earth | mu_km3_s2: 0.0}, {:error, {:invalid_central_body, :mu_km3_s2}}},
          {%{earth | mu_km3_s2: -huge_integer},
           {:error, {:invalid_central_body, :mu_km3_s2}}},
          {%{earth | equatorial_radius_km: :infinity},
           {:error, {:invalid_central_body, :equatorial_radius_km}}},
          {%{earth | equatorial_radius_km: 0.0},
           {:error, {:invalid_central_body, :equatorial_radius_km}}},
          {%{earth | equatorial_radius_km: -huge_integer},
           {:error, {:invalid_central_body, :equatorial_radius_km}}},
          {%{earth | j2: :nan}, {:error, {:invalid_central_body, :j2}}},
          {%{earth | j2: -1.0e-3}, {:error, {:invalid_central_body, :j2}}},
          {%{earth | j2: -huge_integer}, {:error, {:invalid_central_body, :j2}}}
        ]

    malformed_cases =
      Enum.map([:name, :center, :orientation], fn field ->
        {%{state | frame: Map.delete(state.frame, field)}, target, earth,
         {:error, {:invalid_state, :frame}}}
      end) ++
        Enum.map([:name, :center, :orientation], fn field ->
          {state, Map.delete(target, field), earth,
           {:error, {:invalid_input, :target_frame}}}
        end) ++
        Enum.map(malformed_body_cases, fn {candidate_body, expected} ->
          {state, target, candidate_body, expected}
        end)

    Enum.each(malformed_cases, fn {candidate_state, candidate_target, candidate_body, expected} ->
      assert ^expected =
               FrameTransform.transform(
                 candidate_state,
                 candidate_target,
                 candidate_body,
                 policy
               )
    end)

    refute_receive {:bounded_earth_rotation_fetched, _angle_rad, _rate_rad_s}

    nil_optional_body = %{earth | equatorial_radius_km: nil, j2: nil}

    assert {:ok, _result} =
             FrameTransform.transform(state, target, nil_optional_body, policy)

    assert_receive {:bounded_earth_rotation_fetched, 0.0, 0.0}

    huge_positive_body = %{
      earth
      | mu_km3_s2: huge_integer,
        equatorial_radius_km: huge_integer,
        j2: huge_integer
    }

    assert {:ok, _result} =
             FrameTransform.transform(state, target, huge_positive_body, policy)

    assert_receive {:bounded_earth_rotation_fetched, 0.0, 0.0}
  end

  test "preserves state central-body epoch source-frame and target-frame error precedence" do
    policy = bounded_policy(test_pid: self())
    state = nominal_inertial_state()
    malformed_source_state = %{state | frame: Map.delete(state.frame, :name)}
    malformed_target = Map.delete(Frame.earth_fixed(), :name)
    moon = CentralBody.new!(:moon, 4_902.800066)
    malformed_source_utc_state =
      %{malformed_source_state | epoch: Epoch.new!(0.0, :utc)}

    invalid_malformed_source_utc_state =
      %{malformed_source_utc_state | position_km: :invalid}

    assert {:error, {:invalid_state, :state_vector}} =
             FrameTransform.transform(
               invalid_malformed_source_utc_state,
               malformed_target,
               moon,
               policy
             )

    assert {:error, {:unsupported_central_body, :moon}} =
             FrameTransform.transform(
               malformed_source_utc_state,
               malformed_target,
               moon,
               policy
             )

    assert {:error, {:unsupported_time_scale, :utc}} =
             FrameTransform.transform(
               malformed_source_utc_state,
               malformed_target,
               CentralBody.earth(),
               policy
             )

    assert {:error, {:invalid_state, :frame}} =
             FrameTransform.transform(
               malformed_source_state,
               malformed_target,
               CentralBody.earth(),
               policy
             )

    assert {:error, {:invalid_input, :target_frame}} =
             FrameTransform.transform(
               state,
               malformed_target,
               CentralBody.earth(),
               policy
             )

    refute_receive {:bounded_earth_rotation_fetched, _angle_rad, _rate_rad_s}
  end

  test "admits non-axial envelope corners and rejects adjacent values" do
    earth = CentralBody.earth()
    target = Frame.earth_fixed()

    non_axial_state =
      state(
        {7_000.0, -1_200.0, 400.0},
        {1.25, 7.1, -0.4},
        0.0,
        Frame.earth_inertial_j2000()
      )

    provider_fields = [
      {:earth_rotation_angle_rad, @maximum_earth_rotation_angle_magnitude_rad,
       :earth_rotation_angle_rad},
      {:earth_rotation_rate_rad_s, @maximum_earth_rotation_rate_magnitude_rad_s,
       :earth_rotation_rate_rad_s}
    ]

    for {option, maximum, error_field} <- provider_fields,
        sign <- [-1.0, 1.0] do
      assert {:ok, _result} =
               FrameTransform.transform(
                 non_axial_state,
                 target,
                 earth,
                 bounded_policy([{option, sign * maximum}])
               )

      assert {:error, {:unsupported_environment_product, ^error_field}} =
               FrameTransform.transform(
                 non_axial_state,
                 target,
                 earth,
                 bounded_policy([{option, sign * next_up(maximum)}])
               )
    end

    for {corner_source_frame, corner_target_frame} <- [
          {Frame.earth_inertial_j2000(), Frame.earth_fixed()},
          {Frame.earth_fixed(), Frame.earth_inertial_j2000()}
        ],
        position_corner <- signed_corners(@maximum_position_component_km),
        velocity_corner <- signed_corners(@maximum_velocity_component_km_s),
        epoch_sign <- [-1.0, 1.0],
        angle_sign <- [-1.0, 1.0],
        rate_sign <- [-1.0, 1.0] do
      envelope_corner_state =
        state(
          position_corner,
          velocity_corner,
          epoch_sign * @maximum_epoch_magnitude_s,
          corner_source_frame
        )

      assert {:ok, _result} =
               FrameTransform.transform(
                 envelope_corner_state,
                 corner_target_frame,
                 earth,
                 bounded_policy(
                   earth_rotation_angle_rad:
                     angle_sign * @maximum_earth_rotation_angle_magnitude_rad,
                   earth_rotation_rate_rad_s:
                     rate_sign * @maximum_earth_rotation_rate_magnitude_rad_s
                 )
               )
    end

    positive_corner_state =
      state(
        {@maximum_position_component_km, @maximum_position_component_km,
         @maximum_position_component_km},
        {@maximum_velocity_component_km_s, @maximum_velocity_component_km_s,
         @maximum_velocity_component_km_s},
        @maximum_epoch_magnitude_s,
        Frame.earth_inertial_j2000()
      )

    positive_corner_policy =
      bounded_policy(
        earth_rotation_angle_rad: @maximum_earth_rotation_angle_magnitude_rad,
        earth_rotation_rate_rad_s: @maximum_earth_rotation_rate_magnitude_rad_s
      )

    assert {:ok, non_closed_result} =
             FrameTransform.transform(
               positive_corner_state,
               target,
               earth,
               positive_corner_policy
             )

    assert maximum_component_magnitude(non_closed_result.state.velocity_km_s) >
             @maximum_velocity_component_km_s

    assert non_closed_result.evidence.round_trip.tolerance_model ==
             :absolute_floor_plus_realized_scale

    combined_adjacent_cases = [
      {%{
         positive_corner_state
         | position_km:
             {next_up(@maximum_position_component_km),
              @maximum_position_component_km, @maximum_position_component_km}
       }, positive_corner_policy, {:error, {:unsupported_state, :position_km}}},
      {%{
         positive_corner_state
         | velocity_km_s:
             {next_up(@maximum_velocity_component_km_s),
              @maximum_velocity_component_km_s, @maximum_velocity_component_km_s}
       }, positive_corner_policy, {:error, {:unsupported_state, :velocity_km_s}}},
      {%{
         positive_corner_state
         | epoch: Epoch.new!(next_up(@maximum_epoch_magnitude_s), :tdb)
       }, positive_corner_policy, {:error, {:unsupported_time, :seconds_since_j2000}}},
      {positive_corner_state,
       bounded_policy(
         earth_rotation_angle_rad: next_up(@maximum_earth_rotation_angle_magnitude_rad),
         earth_rotation_rate_rad_s: @maximum_earth_rotation_rate_magnitude_rad_s
       ), {:error, {:unsupported_environment_product, :earth_rotation_angle_rad}}},
      {positive_corner_state,
       bounded_policy(
         earth_rotation_angle_rad: @maximum_earth_rotation_angle_magnitude_rad,
         earth_rotation_rate_rad_s: next_up(@maximum_earth_rotation_rate_magnitude_rad_s)
       ), {:error, {:unsupported_environment_product, :earth_rotation_rate_rad_s}}}
    ]

    Enum.each(combined_adjacent_cases, fn {candidate_state, candidate_policy, expected} ->
      assert ^expected =
               FrameTransform.transform(candidate_state, target, earth, candidate_policy)
    end)

    huge_integer = Integer.pow(2, 4096)

    for {option, value, expected} <- [
          {:earth_rotation_angle_rad, huge_integer,
           {:error, {:unsupported_environment_product, :earth_rotation_angle_rad}}},
          {:earth_rotation_rate_rad_s, 1.0e308,
           {:error, {:unsupported_environment_product, :earth_rotation_rate_rad_s}}},
          {:earth_rotation_angle_rad, :nan,
           {:error, {:invalid_environment_product, :earth_rotation_angle_rad}}},
          {:earth_rotation_rate_rad_s, :infinity,
           {:error, {:invalid_environment_product, :earth_rotation_rate_rad_s}}}
        ] do
      assert ^expected =
               FrameTransform.transform(
                 non_axial_state,
                 target,
                 earth,
                 bounded_policy([{option, value}])
               )
    end

    assert {:error, {:invalid_environment_product, :provider_id}} =
             FrameTransform.transform(
               non_axial_state,
               target,
               earth,
               bounded_policy(product_provider_id: "forged")
             )

    assert {:error, {:invalid_environment_product, :model}} =
             FrameTransform.transform(
               non_axial_state,
               target,
               earth,
               bounded_policy(product_model: "forged")
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
                    @retained_quarter_rotation_rate_rad_s,
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
    assert maximum_component_magnitude(forward.state.velocity_km_s) > 1.0e3

    assert maximum_component_magnitude(forward.state.velocity_km_s) <=
             @maximum_velocity_component_km_s

    assert forward.evidence.round_trip.tolerance_model ==
             :absolute_floor_plus_realized_scale

    assert forward.evidence.round_trip.position_tolerance_km ==
             max(
               @position_absolute_tolerance_km,
               @round_trip_relative_scale_factor *
                 forward.evidence.round_trip.position_scale_km
             )

    assert forward.evidence.round_trip.velocity_tolerance_km_s ==
             max(
               @velocity_absolute_tolerance_km_s,
               @round_trip_relative_scale_factor *
                 forward.evidence.round_trip.velocity_scale_km_s
             )

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

  test "repeated transforms return identical data and same-runtime term bytes" do
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

  defp bounded_policy(provider_opts \\ []) do
    assert {:ok, policy} =
             FrameTransform.provider_policy(BoundedEarthRotationProvider,
               provider_opts: provider_opts,
               source_revision: "bounded-frame-transform-test.v1"
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

  defp nominal_inertial_state(seconds_since_j2000 \\ 0.0) do
    state(
      {7_000.0, 0.0, 0.0},
      {0.0, 7.5, 0.0},
      seconds_since_j2000,
      Frame.earth_inertial_j2000()
    )
  end

  defp next_up(value) when is_float(value) and value >= 0.0 do
    <<bits::unsigned-integer-size(64)>> = <<value::float-size(64)>>
    <<next::float-size(64)>> = <<(bits + 1)::unsigned-integer-size(64)>>
    next
  end

  defp signed_corners(maximum) do
    for x <- [-maximum, maximum],
        y <- [-maximum, maximum],
        z <- [-maximum, maximum],
        do: {x, y, z}
  end

  defp maximum_component_magnitude({x, y, z}) do
    max(abs(x), max(abs(y), abs(z)))
  end

  defp assert_vector_in_delta({actual_x, actual_y, actual_z}, {x, y, z}, tolerance) do
    assert_in_delta actual_x, x, tolerance
    assert_in_delta actual_y, y, tolerance
    assert_in_delta actual_z, z, tolerance
  end
end
