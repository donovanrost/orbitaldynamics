defmodule OrbitalDynamics.MissionAnalysis.ActivitySegmentTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.{Epoch, Frame, StateVector, Trajectory}
  alias OrbitalDynamics.MissionAnalysis
  alias OrbitalDynamics.MissionAnalysis.{Asset, Request, Evaluation, WindowRefinement}
  alias OrbitalDynamics.MissionAnalysis.Attitude.{Policy, Pointing, Quaternion, Motion}
  alias OrbitalDynamics.MissionAnalysis.Scheduling

  defmodule ClockModel do
    def capabilities, do: %{"id" => "original_request_clock"}
    def prepare(r, _, _), do: {:ok, %{start: r.starts_at_s, duration: r.duration_s}, %{}}

    def evaluate(_, _, _),
      do: {:ok, Evaluation.new!([%{"id" => "physical", "passed" => true}], %{})}

    def pointing(state, s, _),
      do:
        {:ok,
         Pointing.new!(
           state.frame,
           Quaternion.increment(
             {0, 0, 120 * (state.epoch.seconds_since_j2000 - s.start) / s.duration}
           )
         )}

    def activity_mode(_, _),
      do:
        {:ok,
         OrbitalDynamics.MissionAnalysis.Path.Result.new!(
           [%{"id" => "mode", "status" => "supported"}],
           %{}
         )}
  end

  defmodule Rule do
    def prepare(_, _, _), do: {:ok, nil, %{}}

    def evaluate(_, _, _, _),
      do:
        {:ok,
         OrbitalDynamics.MissionAnalysis.Path.Result.new!(
           [%{"id" => "declared", "status" => "supported"}],
           %{}
         )}
  end

  defp frame, do: Frame.new!(:toy, :toy, :inertial)
  defp state(t), do: StateVector.new!({2000, 0, 0}, {0, 0, 0}, Epoch.new!(t, :tai), frame())

  defp request(start, stop, duration, cost, value),
    do:
      Request.new!("r", ClockModel, nil,
        activity_type: "science",
        starts_at_s: start,
        ends_at_s: stop,
        duration_s: duration,
        time_scale: :tai,
        value: value,
        parameters: %{},
        resource_costs: cost
      )

  defp segment(original),
    do: %{request: original, starts_at_s: 20, ends_at_s: 40, asset_id: "a", kind: :remaining}

  test "generic continuation preserves the original model's duration and clock rather than preparing a truncated request" do
    original = request(20, 60, 20, %{"tokens" => 1}, 10)
    tail = request(25, 40, 15, %{}, 10) |> Request.with_segment!(segment(original))

    asset =
      Asset.new!(
        "a",
        %Trajectory{scenario_id: "toy", states: Enum.map(0..100//2, &state/1), assumptions: %{}},
        %{ClockModel => %{}},
        %{"tokens" => 0}
      )

    path =
      OrbitalDynamics.MissionAnalysis.Path.Policy.new!(
        %{
          "a" => %{
            activity_modes: %{"r" => "work"},
            transition_mode: "idle",
            modes: %{"idle" => %{}, "work" => %{}},
            rules: [%{id: "declared", module: Rule, configuration: %{}}]
          }
        },
        sample_steps_s: [1],
        max_evaluations: 10000,
        max_samples_per_segment: 1000
      )

    policy =
      Policy.new!(
        %{
          "a" => %{
            max_rate_deg_s: 20,
            max_accel_deg_s2: 20,
            settling_s: 2,
            continuation_request_id: "r",
            initial: %{
              epoch: Epoch.new!(25, :tai),
              frame: frame(),
              quaternion: Quaternion.increment({0, 0, 30}),
              angular_velocity_deg_s: {0, 0, 6}
            },
            pointing_configurations: %{ClockModel => %{}}
          }
        },
        profile_step_s: 1,
        derivative_step_s: 0.1,
        search_step_s: 1,
        max_candidate_starts: 16,
        max_evaluations: 10000,
        path_constraints: path,
        horizon: %{
          start: Epoch.new!(25, :tai),
          stop: Epoch.new!(100, :tai),
          terminals: %{"a" => %{frame: frame(), quaternion: {1, 0, 0, 0}, mode: "idle"}}
        }
      )

    refinement =
      WindowRefinement.new!(
        state_at: fn _, t -> {:ok, state(t)} end,
        tracking_lookback_s: 1,
        time_tolerance_s: 0.01,
        max_extra_evaluations: 100
      )

    scheduling =
      Scheduling.Policy.new!(Scheduling.Greedy,
        max_trials: 1,
        protected_activities: [
          %{"request_id" => "r", "asset_id" => "a", "starts_at_s" => 25, "ends_at_s" => 40}
        ]
      )

    assert {:ok, r} =
             MissionAnalysis.run([asset], [tail], nil,
               max_sample_gap_s: 2,
               asset_separation_s: 0,
               window_refinement: refinement,
               attitude: policy,
               scheduling: scheduling
             )

    assert r["attitude_planning"]["planning_status"] == "supported"
    [a] = r["activities"]
    point = hd(a["attitude_profile"])

    assert Quaternion.distance_deg(point["quaternion_wxyz"], Quaternion.increment({0, 0, 30})) <
             1.0e-8

    assert_in_delta point["rate_deg_s"], 6, 1.0e-8
    assert a["activity_segment"]["original_duration_s"] == 20
    assert hd(r["attitude_planning"]["transitions"])["required_s"] == 0
  end

  test "segments cannot refund costs, change original timing, nest or invent credit" do
    original = request(20, 60, 20, %{"tokens" => 1}, 10)

    for bad <- [
          request(25, 40, 15, %{"tokens" => 1}, 10),
          request(25, 40, 15, %{}, 11),
          request(25, 39, 14, %{}, 10)
        ] do
      assert_raise ArgumentError, fn -> Request.with_segment!(bad, segment(original)) end
    end

    valid = request(25, 40, 15, %{}, 10) |> Request.with_segment!(segment(original))

    assert_raise ArgumentError, fn ->
      Request.with_segment!(valid, %{segment(original) | request: valid})
    end
  end

  test "continuity never waives a real pose/rate change or ordinary settling" do
    source = %{
      "epoch_s" => 25,
      "quaternion_wxyz" => [1, 0, 0, 0],
      "angular_velocity_inertial_deg_s" => [0, 0, 0]
    }

    limits = %{max_rate_deg_s: 2, max_accel_deg_s2: 0.2, settling_s: 2}
    assert {:infeasible, _} = Motion.transition(source, source, limits)
    assert {:ok, _} = Motion.continuity(source, source, limits)

    assert {:infeasible, _} =
             Motion.continuity(
               source,
               %{source | "angular_velocity_inertial_deg_s" => [0, 0, 0.1]},
               limits
             )

    assert {:infeasible, _} = Motion.continuity(source, %{source | "epoch_s" => 26}, limits)
  end

  test "terminal roundoff correction preserves tiny requested targets and exact UTC hold boundaries" do
    q0 = Quaternion.increment({10, 20, 30})
    q1 = Quaternion.multiply(Quaternion.increment({0, 0, 1.0e-10}), q0)

    source = %{
      "epoch_s" => 820_497_600,
      "quaternion_wxyz" => Tuple.to_list(q0),
      "angular_velocity_inertial_deg_s" => [0, 0, 0]
    }

    destination = %{source | "epoch_s" => 820_497_700, "quaternion_wxyz" => Tuple.to_list(q1)}
    limits = %{max_rate_deg_s: 2, max_accel_deg_s2: 0.2, settling_s: 2}
    {:ok, plan} = Motion.transition(source, destination, limits, :terminal)

    hold =
      Enum.find(
        plan["phases"],
        &(&1["kind"] == "hold" and &1["ends_after_s"] > &1["starts_after_s"])
      )

    pose = Motion.at_epoch(plan, source["epoch_s"] + hold["starts_after_s"])
    assert Quaternion.distance_deg(pose.quaternion, q1) < 1.0e-12
    assert Quaternion.distance_deg(pose.quaternion, q0) > 5.0e-11

    for phase <- plan["phases"], correction = phase["orientation_roundoff_correction_deg"] do
      assert correction <= 1.0e-12
    end
  end
end
