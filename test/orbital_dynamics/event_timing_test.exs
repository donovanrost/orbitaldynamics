defmodule OrbitalDynamics.EventTimingTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Epoch, EventTiming, Frame, StateVector, Trajectory}

  defmodule StructProbe do
    defstruct [:scale, :seconds_since_j2000]
  end

  @safe_number_bound 1_000_000_000_000_000

  test "builds detector-wide timing policy from trajectory cadence" do
    trajectory = trajectory([0.0, 30.0, 90.0])

    assert %{
             event_timing_policy: :sampled_state_linear_boundary,
             event_detector: :access_windows,
             interpolation: :linear_sample_crossing,
             event_time_tolerance_s: 60.0,
             max_sample_step_s: 60.0,
             confidence: :bounded_by_sample_cadence
           } = EventTiming.policy(trajectory, :access_windows)
  end

  test "builds local boundary timing policy from bracket epochs" do
    [before_state, after_state] = trajectory([10.0, 25.0]).states

    assert %{
             event_timing_policy: :sampled_state_linear_boundary,
             interpolation: :linear_sample_crossing,
             event_time_tolerance_s: 15.0,
             event_time_bracket_s: 15.0,
             before_epoch_s: 10.0,
             after_epoch_s: 25.0,
             root_solved: false,
             confidence: :bounded_by_sample_cadence
           } = EventTiming.boundary_policy(before_state.epoch, after_state.epoch)
  end

  test "public boundary timing accepts only closed finite Epoch structs" do
    for scale <- [:tdb, :tai, :utc] do
      assert %{
               event_time_bracket_s: 15.0,
               before_epoch_s: 10.0,
               after_epoch_s: 25.0
             } =
               EventTiming.boundary_policy(
                 Epoch.new!(10.0, scale),
                 Epoch.new!(25.0, scale)
               )
    end

    for bad_epoch <- [
          %{seconds_since_j2000: 10.0},
          %{"seconds_since_j2000" => 10.0},
          %{"seconds_since_j2000" => 10.0, seconds_since_j2000: 10.0},
          %{__struct__: Epoch, scale: :tdb, seconds_since_j2000: 10.0, caller_shadow: true},
          %{__struct__: Epoch, scale: :tdb},
          %{__struct__: Epoch, seconds_since_j2000: 10.0},
          %StructProbe{scale: :tdb, seconds_since_j2000: 10.0},
          %Epoch{scale: :gps, seconds_since_j2000: 10.0},
          %Epoch{scale: :unknown, seconds_since_j2000: 10.0},
          %Epoch{scale: :tdb, seconds_since_j2000: 1.0e16},
          %Epoch{scale: :tdb, seconds_since_j2000: :not_numeric}
        ] do
      assert {:error, {:invalid_epoch, :before_epoch}} =
               EventTiming.boundary_policy(bad_epoch, Epoch.new!(25.0, :tdb))
    end

    assert {:error, {:invalid_trajectory, :epoch_seconds_since_j2000}} =
             EventTiming.policy(
               trajectory_with_epoch(%Epoch{
                 scale: :gps,
                 seconds_since_j2000: 0.0
               }),
               :eclipses
             )

    assert {:error, {:invalid_trajectory, :epoch_seconds_since_j2000}} =
             EventTiming.policy(
               trajectory_with_epoch(%{
                 __struct__: Epoch,
                 scale: :tdb,
                 seconds_since_j2000: 0.0,
                 caller_shadow: true
               }),
               :eclipses
             )
  end

  test "annotates event metadata without removing detector fields" do
    trajectory = trajectory([0.0, 60.0])

    event = %{
      type: :ground_station_access,
      metadata: %{ground_station_id: :equator, interpolation: :linear_sample_crossing}
    }

    assert %{
             metadata: %{
               ground_station_id: :equator,
               event_detector: :access_windows,
               event_time_tolerance_s: 60.0,
               confidence: :bounded_by_sample_cadence
             }
           } = EventTiming.annotate_event(event, trajectory, :access_windows)

    assert %{
             metadata: %{
               sun_direction: {1.0, 0.0, 0.0},
               event_detector: :eclipses
             }
           } =
             EventTiming.annotate_event(
               %{metadata: %{sun_direction: {1.0, 0.0, 0.0}}},
               trajectory,
               :eclipses
             )

    vector_metadata = %{
      sun_direction: {1.0, 0.0, 0.0},
      sun_direction_at_start_sample: {1.0, 0.0, 0.0},
      sun_direction_at_end_sample: {0.0, 1.0, 0.0},
      end_boundary_detail: %{
        before_sun_direction: {1.0, 0.0, 0.0},
        after_sun_direction: {0.0, 1.0, 0.0}
      }
    }

    assert %{
             metadata: %{
               sun_direction_at_start_sample: {1.0, 0.0, 0.0},
               sun_direction_at_end_sample: {0.0, 1.0, 0.0},
               end_boundary_detail: %{
                 before_sun_direction: {1.0, 0.0, 0.0},
                 after_sun_direction: {0.0, 1.0, 0.0}
               },
               event_detector: :eclipses
             }
           } = EventTiming.annotate_event(%{metadata: vector_metadata}, trajectory, :eclipses)
  end

  test "public timing boundaries reject hostile input with typed errors" do
    trajectory = trajectory([0.0, 60.0])

    assert {:error, {:invalid_container, :opts}} =
             EventTiming.policy(trajectory, :eclipses, [
               {:interpolation, :linear_sample_crossing} | :tail
             ])

    assert {:error, {:invalid_container, :opts}} =
             EventTiming.policy(trajectory, :eclipses, audit_payload: %{42 => "bad key"})

    assert {:error, {:atom_string_alias_collision, "probe"}} =
             EventTiming.policy(trajectory, :eclipses, audit_payload: %{"probe" => 1, probe: 2})

    callback_probe = fn -> send(self(), :event_timing_callback_invoked) end

    for bad_value <- [
          %StructProbe{scale: :tdb, seconds_since_j2000: 0.0},
          self(),
          make_ref(),
          callback_probe,
          {:tuple, :not_json}
        ] do
      assert {:error, {:invalid_container, :opts}} =
               EventTiming.policy(trajectory, :eclipses, audit_payload: bad_value)

      refute_receive :event_timing_callback_invoked
    end

    assert {:error, {:invalid_option, :trajectory}} =
             EventTiming.policy(:not_a_trajectory, :eclipses)

    assert {:error, {:invalid_trajectory, :nonmonotonic_epochs}} =
             EventTiming.policy(trajectory([60.0, 0.0]), :eclipses)

    assert {:error, {:invalid_container, :states}} =
             EventTiming.policy(
               %Trajectory{trajectory | states: [List.first(trajectory.states) | :tail]},
               :eclipses
             )

    assert {:error, {:invalid_epoch, :before_epoch}} =
             EventTiming.boundary_policy(
               %{seconds_since_j2000: 1.0e16},
               Epoch.new!(0.0, :tdb)
             )

    assert {:error, {:invalid_event, :metadata}} =
             EventTiming.annotate_event(%{metadata: [:bad]}, trajectory, :eclipses)

    assert {:error, {:invalid_container, :metadata}} =
             EventTiming.annotate_event(
               %{metadata: %StructProbe{scale: :tdb, seconds_since_j2000: 0.0}},
               trajectory,
               :eclipses
             )

    assert {:error, {:atom_string_alias_collision, "probe"}} =
             EventTiming.annotate_event(
               %{metadata: %{"probe" => 1, probe: 2}},
               trajectory,
               :eclipses
             )

    assert {:error, {:invalid_container, :metadata}} =
             EventTiming.annotate_event(
               %{metadata: %{"probe" => callback_probe}},
               trajectory,
               :eclipses
             )

    refute_receive :event_timing_callback_invoked

    assert {:error, {:invalid_container, :metadata}} =
             EventTiming.annotate_event(
               %{metadata: %{sun_direction: {1.0, 0.0, :bad}}},
               trajectory,
               :eclipses
             )

    assert {:error, {:invalid_container, :metadata}} =
             EventTiming.annotate_event(
               %{metadata: %{caller_vector: {1.0, 2.0, 3.0}}},
               trajectory,
               :eclipses
             )

    assert {:error, {:invalid_container, :metadata}} =
             EventTiming.annotate_event(
               %{metadata: %{activity_context: %{caller_vector: {1.0, 2.0, 3.0}}}},
               trajectory,
               :eclipses
             )

    for key <- metadata_vector_keys() do
      assert {:error, {:invalid_container, :metadata}} =
               EventTiming.annotate_event(
                 %{metadata: %{key => {@safe_number_bound + 1, 0.0, 0.0}}},
                 trajectory,
                 :eclipses
               ),
             "#{key} bound+1 vector component was admitted"

      assert {:error, {:invalid_container, :metadata}} =
               EventTiming.annotate_event(
                 %{metadata: %{key => {huge_integer(), 0.0, 0.0}}},
                 trajectory,
                 :eclipses
               ),
             "#{key} huge vector component was admitted"

      for {label, nonfinite} <- nonfinite_float_values() do
        assert {:error, {:invalid_container, :metadata}} =
                 EventTiming.annotate_event(
                   %{metadata: %{key => {nonfinite, 0.0, 0.0}}},
                   trajectory,
                   :eclipses
                 ),
               "#{label} #{key} vector component was admitted"
      end
    end

    assert {:error, {:invalid_option, :event}} =
             EventTiming.annotate_event(:not_an_event, trajectory, :eclipses)
  end

  defp trajectory(epoch_seconds) do
    %Trajectory{
      scenario_id: :event_timing_test,
      states:
        Enum.map(epoch_seconds, fn seconds ->
          StateVector.new!(
            {7000.0, 0.0, 0.0},
            {0.0, 7.5, 0.0},
            Epoch.new!(seconds, :tdb),
            Frame.earth_inertial_j2000()
          )
        end),
      assumptions: %{force_model: :manual}
    }
  end

  defp trajectory_with_epoch(epoch) do
    %Trajectory{
      scenario_id: :event_timing_test,
      states: [
        StateVector.new!(
          {7000.0, 0.0, 0.0},
          {0.0, 7.5, 0.0},
          Epoch.new!(0.0, :tdb),
          Frame.earth_inertial_j2000()
        )
        |> Map.put(:epoch, epoch)
      ],
      assumptions: %{force_model: :manual}
    }
  end

  defp metadata_vector_keys do
    [
      :sun_direction,
      :before_sun_direction,
      :after_sun_direction,
      :sun_direction_at_start_sample,
      :sun_direction_at_end_sample
    ]
  end

  defp huge_integer, do: :erlang.bsl(1, 1_000_000)

  defp nonfinite_float_values do
    [
      {"nan", :erlang.binary_to_term(<<131, 70, 127, 248, 0, 0, 0, 0, 0, 1>>, [:safe])},
      {"positive infinity",
       :erlang.binary_to_term(<<131, 70, 127, 240, 0, 0, 0, 0, 0, 0>>, [:safe])},
      {"negative infinity",
       :erlang.binary_to_term(<<131, 70, 255, 240, 0, 0, 0, 0, 0, 0>>, [:safe])}
    ]
  end
end
