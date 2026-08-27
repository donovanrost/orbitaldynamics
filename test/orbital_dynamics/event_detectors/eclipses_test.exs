defmodule OrbitalDynamics.EventDetectors.EclipsesTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.EventDetectors.Eclipses
  alias OrbitalDynamics.{CentralBody, Epoch, Frame, StateVector, Trajectory}

  @safe_number_bound 1_000_000_000_000_000

  defmodule StructProbe do
    defstruct [:value]
  end

  defmodule RaisingSunCapabilityProvider do
    def capabilities, do: raise("sun capability failure")
    def fetch(_kind, _opts), do: {:error, :unexpected_fetch}
  end

  defmodule RaisingSunFetchProvider do
    alias OrbitalDynamics.Environment.FixedSunProvider

    def capabilities, do: FixedSunProvider.capabilities()
    def fetch(_kind, _opts), do: raise("sun fetch failure")
  end

  defmodule CollidingSunProductProvider do
    alias OrbitalDynamics.Environment.FixedSunProvider

    def capabilities, do: FixedSunProvider.capabilities()

    def fetch(:sun_direction, _opts) do
      with {:ok, product} <- FixedSunProvider.fetch(:sun_direction, []) do
        {:ok, Map.put(product, :provider_id, product["provider_id"])}
      end
    end
  end

  defmodule BadSunProductProvider do
    alias OrbitalDynamics.Environment.FixedSunProvider

    def capabilities, do: FixedSunProvider.capabilities()

    def fetch(:sun_direction, _opts) do
      with {:ok, product} <- FixedSunProvider.fetch(:sun_direction, []) do
        {:ok, Map.put(product, "provenance", [:not_a_map])}
      end
    end
  end

  test "declares detector capabilities" do
    assert %{
             detector: :eclipses,
             model: :cylindrical_central_body_shadow,
             validation_level: :analysis,
             timing_policy: :sampled_state_linear_boundary,
             interpolation: :linear_sample_crossing,
             boundary_refinement: :eclipse_linear_shadow_margin_interpolation,
             lighting_summary_model: :sampled_eclipse_overlap_fraction,
             known_limits: known_limits
           } = Eclipses.capabilities()

    assert :sample_cadence_limited in known_limits
    assert :refinement_not_root_solved in known_limits
    assert :no_penumbra_model in known_limits
  end

  test "classifies sampled eclipse overlap lighting summary" do
    assert Eclipses.lighting_summary(100.0, 0.0) == %{
             "lighting_condition" => "sunlit",
             "lighting_condition_detail" => "sunlit",
             "lighting_condition_model" => "sampled_eclipse_overlap_tag",
             "lighting_detail_model" => "sampled_eclipse_overlap_fraction_tag",
             "eclipse_overlap_fraction" => 0.0,
             "lighting_confidence" => "bounded_by_sampled_eclipse_overlap"
           }

    assert Eclipses.lighting_summary(100.0, 80.0) == %{
             "lighting_condition" => "partial_eclipse",
             "lighting_condition_detail" => "mostly_eclipsed",
             "lighting_condition_model" => "sampled_eclipse_overlap_tag",
             "lighting_detail_model" => "sampled_eclipse_overlap_fraction_tag",
             "eclipse_overlap_fraction" => 0.8,
             "lighting_confidence" => "bounded_by_sampled_eclipse_overlap"
           }

    assert Eclipses.lighting_summary(0.0, 10.0)["lighting_condition_detail"] == "unknown"
  end

  test "detects one eclipse interval from contiguous shadow samples" do
    earth = CentralBody.earth()

    trajectory =
      trajectory([
        anti_sunward_inside_shadow(earth, 0.0),
        anti_sunward_inside_shadow(earth, 60.0),
        sunward(earth, 120.0)
      ])

    assert {:ok, [event]} =
             Eclipses.detect(trajectory, central_body: earth, sun_direction: {1.0, 0.0, 0.0})

    assert event.type == :eclipse
    assert event.starts_at.seconds_since_j2000 == 0.0
    assert event.ends_at.seconds_since_j2000 > 60.0
    assert event.ends_at.seconds_since_j2000 < 120.0
    assert event.metadata.scenario_id == :eclipse_test
    assert event.metadata.shadow_model == :cylindrical_central_body_shadow
    assert event.metadata.interpolation == :linear_sample_crossing
    assert event.metadata.boundary_refinement == :eclipse_linear_shadow_margin_interpolation
    assert event.metadata.start_boundary == :clipped_start
    assert event.metadata.end_boundary == :interpolated
    assert event.metadata.start_boundary_detail.boundary == :clipped_start
    assert event.metadata.start_boundary_detail.interpolation == :clipped_to_sample
    assert event.metadata.start_boundary_detail.root_solved == false
    assert event.metadata.end_boundary_detail.boundary == :eclipse_exit
    assert event.metadata.end_boundary_detail.edge == :end
    assert event.metadata.end_boundary_detail.interpolation == :linear_sample_crossing
    assert event.metadata.end_boundary_detail.interpolation_fraction > 0.0
    assert event.metadata.end_boundary_detail.interpolation_fraction < 1.0

    assert event.metadata.end_boundary_detail.event_timing_policy ==
             :sampled_state_linear_boundary

    assert event.metadata.end_boundary_detail.event_time_bracket_s == 60.0
    assert event.metadata.end_boundary_detail.before_epoch_s == 60.0
    assert event.metadata.end_boundary_detail.after_epoch_s == 120.0
    assert event.metadata.end_boundary_detail.before_eclipsed == true
    assert event.metadata.end_boundary_detail.after_eclipsed == false
    assert event.metadata.end_boundary_detail.root_solved == false
    assert event.metadata.sample_count == 2
    assert event.metadata.sun_direction == {1.0, 0.0, 0.0}
    assert event.metadata.maximum_shadow_margin_km > earth.equatorial_radius_km - 1.0
    assert event.metadata.event_timing_policy == :sampled_state_linear_boundary
    assert event.metadata.event_detector == :eclipses
    assert event.metadata.event_time_tolerance_s == 60.0
  end

  test "public API detects eclipse intervals" do
    earth = CentralBody.earth()
    trajectory = trajectory([anti_sunward_inside_shadow(earth, 0.0)])

    assert {:ok, [%{type: :eclipse}]} =
             OrbitalDynamics.eclipse_intervals(trajectory,
               central_body: earth,
               sun_direction: {1.0, 0.0, 0.0}
             )
  end

  test "refines bracketed eclipse entry and exit boundaries" do
    earth = CentralBody.earth()

    before_entry = sunward(earth, 0.0)
    after_entry = anti_sunward_inside_shadow(earth, 60.0)

    assert {:ok, entry} =
             Eclipses.refine_eclipse_boundary(before_entry, after_entry,
               central_body: earth,
               sun_direction: {1.0, 0.0, 0.0}
             )

    assert entry.boundary == :eclipse_entry
    assert entry.interpolation == :linear_sample_crossing
    assert entry.interpolation_fraction > 0.0
    assert entry.interpolation_fraction < 1.0
    assert entry.epoch.seconds_since_j2000 > 0.0
    assert entry.epoch.seconds_since_j2000 < 60.0
    assert entry.before_eclipsed == false
    assert entry.after_eclipsed == true
    assert entry.assumptions.root_solved == false
    assert entry.assumptions.event_time_bracket_s == 60.0
    assert entry.assumptions.before_epoch_s == 0.0
    assert entry.assumptions.after_epoch_s == 60.0

    assert {:ok, exit_boundary} =
             OrbitalDynamics.refine_eclipse_boundary(after_entry, sunward(earth, 120.0),
               central_body: earth,
               sun_direction: {1.0, 0.0, 0.0}
             )

    assert exit_boundary.boundary == :eclipse_exit
    assert exit_boundary.epoch.seconds_since_j2000 > 60.0
    assert exit_boundary.epoch.seconds_since_j2000 < 120.0
  end

  test "rejects unbracketed eclipse boundary refinement" do
    earth = CentralBody.earth()

    assert {:error, :not_bracketed} =
             Eclipses.refine_eclipse_boundary(
               anti_sunward_inside_shadow(earth, 0.0),
               anti_sunward_inside_shadow(earth, 60.0),
               central_body: earth,
               sun_direction: {1.0, 0.0, 0.0}
             )
  end

  test "returns no intervals for sunward or outside-cylinder samples" do
    earth = CentralBody.earth()

    trajectory =
      trajectory([
        sunward(earth, 0.0),
        anti_sunward_outside_shadow(earth, 60.0)
      ])

    assert {:ok, []} =
             Eclipses.detect(trajectory, central_body: earth, sun_direction: {1.0, 0.0, 0.0})
  end

  test "splits separated eclipsed samples into separate intervals" do
    earth = CentralBody.earth()

    trajectory =
      trajectory([
        anti_sunward_inside_shadow(earth, 0.0),
        sunward(earth, 60.0),
        anti_sunward_inside_shadow(earth, 120.0)
      ])

    assert {:ok, [first, second]} =
             Eclipses.detect(trajectory, central_body: earth, sun_direction: {1.0, 0.0, 0.0})

    assert first.starts_at.seconds_since_j2000 == 0.0
    assert first.ends_at.seconds_since_j2000 > 0.0
    assert first.ends_at.seconds_since_j2000 < 60.0
    assert second.starts_at.seconds_since_j2000 > 60.0
    assert second.starts_at.seconds_since_j2000 < 120.0
    assert second.ends_at.seconds_since_j2000 == 120.0
  end

  test "rejects invalid detector options" do
    earth = CentralBody.earth()
    trajectory = trajectory([anti_sunward_inside_shadow(earth, 0.0)])

    assert {:error, {:invalid_option, :sun_direction}} =
             Eclipses.detect(trajectory, central_body: earth, sun_direction: {0.0, 0.0, 0.0})
  end

  test "public eclipse boundaries reject hostile inputs with typed errors" do
    earth = CentralBody.earth()
    before_state = sunward(earth, 0.0)
    after_state = anti_sunward_inside_shadow(earth, 60.0)
    trajectory = trajectory([before_state, after_state])

    assert {:error, {:invalid_option, :trajectory}} =
             Eclipses.detect(:not_a_trajectory, central_body: earth)

    assert {:error, {:invalid_container, :opts}} =
             Eclipses.detect(trajectory, [{:sun_direction, {1.0, 0.0, 0.0}} | :tail])

    assert {:error, {:container_depth_exceeded, :opts}} =
             Eclipses.detect(trajectory,
               central_body: earth,
               sun_direction: {1.0, 0.0, 0.0},
               audit_payload: deep_value(10)
             )

    assert {:error, {:invalid_container, :opts}} =
             Eclipses.detect(trajectory,
               central_body: earth,
               sun_direction: {1.0, 0.0, 0.0},
               audit_payload: %{42 => "bad key"}
             )

    assert {:error, {:invalid_container, :opts}} =
             Eclipses.detect(trajectory,
               central_body: earth,
               sun_direction: {1.0, 0.0, 0.0},
               ignored: @safe_number_bound + 1
             )

    assert {:error, {:invalid_container, :opts}} =
             Eclipses.detect(trajectory,
               central_body: earth,
               sun_direction: {1.0, 0.0, 0.0},
               ignored: huge_integer()
             )

    assert {:error, {:unsupported_option, :ignored}} =
             Eclipses.detect(trajectory,
               central_body: earth,
               sun_direction: {1.0, 0.0, 0.0},
               ignored: "safe"
             )

    assert {:error, {:invalid_container, :states}} =
             Eclipses.detect(
               %Trajectory{trajectory | states: [before_state | :tail]},
               central_body: earth,
               sun_direction: {1.0, 0.0, 0.0}
             )

    assert {:error, {:invalid_state, :state}} =
             Eclipses.detect(
               %Trajectory{
                 trajectory
                 | states: [%{before_state | position_km: {1.0e16, 0.0, 0.0}}]
               },
               central_body: earth,
               sun_direction: {1.0, 0.0, 0.0}
             )

    assert {:error, {:invalid_trajectory, :non_increasing_epochs}} =
             Eclipses.detect(
               trajectory([after_state, before_state]),
               central_body: earth,
               sun_direction: {1.0, 0.0, 0.0}
             )

    assert {:error, {:invalid_central_body, :equatorial_radius_km}} =
             Eclipses.detect(trajectory,
               central_body: %{earth | equatorial_radius_km: 1.0e16},
               sun_direction: {1.0, 0.0, 0.0}
             )

    assert {:error, {:invalid_option, :sun_direction}} =
             Eclipses.detect(trajectory, central_body: earth, sun_direction: {1.0e16, 0.0, 0.0})

    assert {:ok, [_event]} =
             Eclipses.detect(trajectory,
               central_body: earth,
               sun_direction: {@safe_number_bound, 0.0, 0.0}
             )

    assert {:error, {:invalid_option, :sun_direction}} =
             Eclipses.detect(trajectory,
               central_body: earth,
               sun_direction: {@safe_number_bound + 1, 0.0, 0.0}
             )

    assert {:error, {:invalid_option, :sun_direction}} =
             Eclipses.detect(trajectory,
               central_body: earth,
               sun_direction: {huge_integer(), 0.0, 0.0}
             )

    assert {:error, {:invalid_container, :opts}} =
             Eclipses.detect(trajectory, central_body: earth, sun_direction: {:not_a_vector, 0.0})

    assert {:error, {:invalid_central_body, :equatorial_radius_km}} =
             Eclipses.detect(trajectory,
               central_body: %{earth | equatorial_radius_km: @safe_number_bound + 1},
               sun_direction: {1.0, 0.0, 0.0}
             )

    assert {:error, {:invalid_central_body, :equatorial_radius_km}} =
             Eclipses.detect(trajectory,
               central_body: %{earth | equatorial_radius_km: huge_integer()},
               sun_direction: {1.0, 0.0, 0.0}
             )

    for {label, nonfinite} <- nonfinite_float_values() do
      assert {:error, {:invalid_option, :sun_direction}} =
               Eclipses.detect(trajectory,
                 central_body: earth,
                 sun_direction: {nonfinite, 0.0, 0.0}
               ),
             "#{label} eclipse sun direction component was admitted"

      assert {:error, {:invalid_central_body, :equatorial_radius_km}} =
               Eclipses.detect(trajectory,
                 central_body: %{earth | equatorial_radius_km: nonfinite},
                 sun_direction: {1.0, 0.0, 0.0}
               ),
             "#{label} eclipse central body numeric field was admitted"
    end

    callback_probe = fn -> send(self(), :eclipse_callback_invoked) end

    for {label, bad_value} <- hostile_option_values(callback_probe) do
      assert {:error, {:invalid_container, :opts}} =
               Eclipses.detect(trajectory,
                 central_body: earth,
                 sun_direction: {1.0, 0.0, 0.0},
                 ignored: bad_value
               ),
             "#{label} ignored eclipse option was admitted"

      assert {:error, {:invalid_container, :opts}} =
               Eclipses.detect(trajectory,
                 central_body: earth,
                 sun_direction: bad_value
               ),
             "#{label} sun_direction option was admitted"

      assert {:error, {:invalid_container, :opts}} =
               Eclipses.detect(trajectory,
                 central_body: %{earth | name: bad_value},
                 sun_direction: {1.0, 0.0, 0.0}
               ),
             "#{label} central body field was admitted"

      assert {:error, {:invalid_container, :opts}} =
               Eclipses.detect(trajectory,
                 central_body: earth,
                 sun_direction_provider: {RaisingSunFetchProvider, ignored: bad_value}
               ),
             "#{label} nested sun provider ignored option was admitted"

      refute_receive :eclipse_callback_invoked
    end

    assert {:error, {:invalid_option, :duration_s}} =
             Eclipses.lighting_summary(1.0e16, 0.0)

    assert {:error, {:invalid_option, :eclipse_overlap_s}} =
             Eclipses.lighting_summary(100.0, 1.0e16)

    assert {:error, {:invalid_option, :eclipse_boundary}} =
             Eclipses.refine_eclipse_boundary(:before, after_state,
               central_body: earth,
               sun_direction: {1.0, 0.0, 0.0}
             )

    assert {:error, {:invalid_state, :before_state}} =
             Eclipses.refine_eclipse_boundary(
               %{before_state | velocity_km_s: {0.0, 1.0e16, 0.0}},
               after_state,
               central_body: earth,
               sun_direction: {1.0, 0.0, 0.0}
             )

    assert {:error, {:container_limit_exceeded, :opts}} =
             Eclipses.refine_eclipse_boundary(before_state, after_state,
               central_body: earth,
               sun_direction: {1.0, 0.0, 0.0},
               audit_payload: wide_map(129)
             )
  end

  test "provider-backed eclipse detection rejects bad callbacks and product shapes" do
    earth = CentralBody.earth()
    trajectory = trajectory([anti_sunward_inside_shadow(earth, 0.0)])

    assert {:error,
            {:environment_provider_callback_failed, RaisingSunCapabilityProvider, :capabilities}} =
             Eclipses.detect(trajectory,
               central_body: earth,
               sun_direction_provider: RaisingSunCapabilityProvider
             )

    assert {:error, {:environment_provider_callback_failed, RaisingSunFetchProvider, :fetch}} =
             Eclipses.detect(trajectory,
               central_body: earth,
               sun_direction_provider: RaisingSunFetchProvider
             )

    assert {:error, {:atom_string_alias_collision, "provider_id"}} =
             Eclipses.detect(trajectory,
               central_body: earth,
               sun_direction_provider: CollidingSunProductProvider
             )

    assert {:error, {:invalid_environment_product, "provenance"}} =
             Eclipses.detect(trajectory,
               central_body: earth,
               sun_direction_provider: BadSunProductProvider
             )
  end

  defp trajectory(states) do
    %Trajectory{
      scenario_id: :eclipse_test,
      states: states,
      assumptions: %{force_model: :manual}
    }
  end

  defp anti_sunward_inside_shadow(earth, seconds_since_j2000) do
    state({-(earth.equatorial_radius_km + 500.0), 0.0, 0.0}, seconds_since_j2000)
  end

  defp anti_sunward_outside_shadow(earth, seconds_since_j2000) do
    state(
      {-(earth.equatorial_radius_km + 500.0), earth.equatorial_radius_km + 1.0, 0.0},
      seconds_since_j2000
    )
  end

  defp sunward(earth, seconds_since_j2000) do
    state({earth.equatorial_radius_km + 500.0, 0.0, 0.0}, seconds_since_j2000)
  end

  defp state(position_km, seconds_since_j2000) do
    StateVector.new!(
      position_km,
      {0.0, 0.0, 0.0},
      Epoch.new!(seconds_since_j2000, :tdb),
      Frame.earth_inertial_j2000()
    )
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
