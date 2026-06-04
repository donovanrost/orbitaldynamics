defmodule OrbitalDynamics.EventTimingTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Epoch, EventTiming, Frame, StateVector, Trajectory}

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
end
