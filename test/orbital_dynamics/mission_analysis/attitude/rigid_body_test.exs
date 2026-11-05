defmodule OrbitalDynamics.MissionAnalysis.Attitude.RigidBodyTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.MissionAnalysis.Attitude.{
    RigidBody,
    Motion,
    Quaternion,
    Policy,
    Profile,
    Pointing
  }

  alias OrbitalDynamics.MissionAnalysis.{
    Asset,
    Request,
    Evaluation,
    WindowRefinement
  }

  alias OrbitalDynamics.{Epoch, Frame, StateVector, Trajectory}
  @deg 180 / :math.pi()
  defp body(moments \\ [2, 3, 4], capacities \\ [10, 10, 10]),
    do:
      RigidBody.new!(%{
        frame: :body_principal_axes,
        principal_moments_kg_m2: moments,
        max_body_torque_nm: capacities
      })

  defp pose(w, a, q \\ {1, 0, 0, 0}),
    do: %{
      "epoch_s" => 5,
      "quaternion_wxyz" => Tuple.to_list(q),
      "angular_velocity_inertial_deg_s" => Enum.map(w, &(&1 * @deg)),
      "angular_acceleration_inertial_deg_s2" => Enum.map(a, &(&1 * @deg))
    }

  test "Euler torque includes gyroscopic coupling and converts radians and body axes correctly" do
    e = RigidBody.at(pose([1, 2, 3], [0.1, 0.2, 0.3]), body())

    for {actual, expected} <- Enum.zip(e["required_body_torque_nm"], [6.2, -5.4, 3.2]),
        do: assert_in_delta(actual, expected, 1.0e-12)

    rotated = RigidBody.at(pose([1, 0, 0], [1, 0, 0], Quaternion.increment({0, 0, 90})), body())

    for {actual, expected} <- Enum.zip(rotated["required_body_torque_nm"], [0, -3, 0]),
        do: assert_in_delta(actual, expected, 1.0e-12)

    gyro = RigidBody.at(pose([1, 1, 0], [0, 0, 0]), body([2, 3, 4], [10, 10, 0.5]))
    assert gyro["status"] == "violated"
    assert_in_delta Enum.at(gyro["required_body_torque_nm"], 2), 1, 1.0e-12
    sphere = RigidBody.at(pose([1, 2, 3], [0, 0, 0]), body([3, 3, 3]))
    assert Enum.all?(sphere["required_body_torque_nm"], &(abs(&1) < 1.0e-12))
  end

  test "Euler demand agrees with an independent finite difference of inertial angular momentum" do
    alias OrbitalDynamics.Vector3, as: V
    q = Quaternion.increment({20, 30, 40})
    w = {1, 2, 3}
    a = {0.1, 0.2, -0.3}
    h = 1.0e-5

    angular_momentum = fn t ->
      angle = V.add(V.scale(w, t * @deg), V.scale(a, 0.5 * t * t * @deg))
      qt = Quaternion.multiply(Quaternion.increment(angle), q)
      {x, y, z} = Quaternion.rotate(Quaternion.inverse(qt), V.add(w, V.scale(a, t)))
      Quaternion.rotate(qt, {2 * x, 3 * y, 4 * z})
    end

    inertial_torque =
      V.scale(V.subtract(angular_momentum.(h), angular_momentum.(-h)), 1 / (2 * h))

    expected = Quaternion.rotate(Quaternion.inverse(q), inertial_torque) |> Tuple.to_list()

    actual =
      RigidBody.at(pose(Tuple.to_list(w), Tuple.to_list(a), q), body())["required_body_torque_nm"]

    for {got, want} <- Enum.zip(actual, expected), do: assert_in_delta(got, want, 2.0e-8)
  end

  test "kinematically valid transitions fail torque capacity, while a gentler constructed motion fits" do
    source = %{
      "epoch_s" => 0,
      "quaternion_wxyz" => [1, 0, 0, 0],
      "angular_velocity_inertial_deg_s" => [0, 0, 0]
    }

    target = %{
      source
      | "epoch_s" => 100,
        "quaternion_wxyz" => Tuple.to_list(Quaternion.increment({0, 0, 45}))
    }

    limits = %{max_rate_deg_s: 10, max_accel_deg_s2: 5, settling_s: 0}
    assert {:ok, _} = Motion.transition(source, target, limits)
    limited = Map.put(limits, :rigid_body, body([50, 50, 50], [1, 1, 1]))
    assert {:infeasible, e} = Motion.transition(source, target, limited)
    assert e["reason"] == "rigid_body_torque_exceeds_limit"
    assert e["rigid_body_torque"]["coverage"] == "fixed_axis_phase_endpoint_envelope"

    assert_in_delta Enum.at(e["rigid_body_torque"]["maximum_absolute_body_torque_nm"], 2),
                    50 * 5 / @deg,
                    1.0e-12

    assert {:ok, slow} = Motion.transition(source, target, %{limited | max_accel_deg_s2: 0.5})
    assert slow["rigid_body_torque"]["status"] == "supported"

    assert_in_delta Enum.at(slow["rigid_body_torque"]["maximum_absolute_body_torque_nm"], 2),
                    50 * 0.5 / @deg,
                    1.0e-12
  end

  test "phase envelopes include cruise coupling and acceleration-switch sides and bound dense actual motion samples" do
    source = %{
      "epoch_s" => 0,
      "quaternion_wxyz" => [1, 0, 0, 0],
      "angular_velocity_inertial_deg_s" => [0, 0, 0]
    }

    target = %{
      source
      | "epoch_s" => 30,
        "quaternion_wxyz" =>
          Tuple.to_list(Quaternion.increment({90 / :math.sqrt(2), 90 / :math.sqrt(2), 0}))
    }

    limits = %{max_rate_deg_s: 10, max_accel_deg_s2: 5, settling_s: 1}
    assert {:ok, plan} = Motion.transition(source, target, limits)
    c = body()
    e = RigidBody.transition(plan, c)

    assert Enum.any?(
             e["phase_endpoints"],
             &(&1["phase"] == "slew_accelerate" and &1["side"] == "end")
           )

    assert Enum.any?(
             e["phase_endpoints"],
             &(&1["phase"] == "slew_decelerate" and &1["side"] == "start")
           )

    for phase <- plan["phases"], phase["ends_after_s"] > phase["starts_after_s"], i <- 1..25 do
      t = phase["starts_after_s"] + (phase["ends_after_s"] - phase["starts_after_s"]) * i / 26
      actual = Motion.at(plan, t)

      p = %{
        "epoch_s" => t,
        "quaternion_wxyz" => Tuple.to_list(actual.quaternion),
        "angular_velocity_inertial_deg_s" => Tuple.to_list(actual.angular_velocity_deg_s),
        "angular_acceleration_inertial_deg_s2" =>
          Tuple.to_list(actual.angular_acceleration_deg_s2)
      }

      torque = RigidBody.at(p, c)

      for {value, bound} <-
            Enum.zip(torque["absolute_body_torque_nm"], e["maximum_absolute_body_torque_nm"]),
          do: assert(value <= bound + 1.0e-12)
    end

    assert {:infeasible, _} =
             Motion.transition(
               source,
               target,
               Map.put(limits, :rigid_body, body([2, 3, 4], [1, 1, 0.01]))
             )
  end

  defmodule Tracking do
    def pointing(s, _, _),
      do:
        {:ok,
         Pointing.new!(
           s.frame,
           Quaternion.increment(
             {s.epoch.seconds_since_j2000 * 20, s.epoch.seconds_since_j2000 * 20, 0}
           )
         )}

    def evaluate(_, _, _),
      do: {:ok, Evaluation.new!([%{"id" => "eligible", "passed" => true}], %{})}
  end

  test "tracking rejects gyro torque despite passing rate and acceleration limits" do
    frame = Frame.new!(:toy, :toy, :inertial)
    at = fn t -> StateVector.new!({2000, 0, 0}, {0, 0, 0}, Epoch.new!(t, :tai), frame) end

    asset =
      Asset.new!(
        "a",
        %Trajectory{scenario_id: "torque", states: [at.(0), at.(100)], assumptions: %{}},
        %{Tracking => %{}},
        %{}
      )

    request =
      Request.new!("r", Tracking, nil,
        activity_type: "service",
        starts_at_s: 0,
        ends_at_s: 100,
        duration_s: 10,
        time_scale: :tai,
        value: 1,
        parameters: %{},
        resource_costs: %{}
      )

    limits = %{
      max_rate_deg_s: 40,
      max_accel_deg_s2: 1,
      settling_s: 0,
      initial: :unknown,
      pointing_configurations: %{Tracking => %{}}
    }

    opts = [
      profile_step_s: 1,
      derivative_step_s: 0.01,
      search_step_s: 1,
      max_candidate_starts: 10,
      max_evaluations: 1000
    ]

    state_at = fn _, t -> {:ok, at.(t)} end

    refinement =
      WindowRefinement.new!(
        state_at: state_at,
        tracking_lookback_s: 1,
        time_tolerance_s: 0.01,
        max_extra_evaluations: 100
      )

    p = Policy.new!(%{"a" => limits}, opts)

    assert {:ok, _, _} =
             Profile.tracking(asset, request, nil, 10, 20, %{}, p, refinement, state_at, %{
               values: %{},
               evaluations: 0
             })

    c = body([2, 3, 4], [1, 1, 0.05])
    p = Policy.new!(%{"a" => Map.put(limits, :rigid_body, c)}, opts)

    assert {:infeasible, {:tracking_torque_exceeds_limit, _, e}, _} =
             Profile.tracking(asset, request, nil, 10, 20, %{}, p, refinement, state_at, %{
               values: %{},
               evaluations: 0
             })

    assert_in_delta Enum.at(e["required_body_torque_nm"], 2), :math.pow(20 / @deg, 2), 1.0e-8
  end

  test "malformed, nonphysical inertia and ambiguous frame declarations are rejected" do
    for c <- [
          %{frame: :inertial, principal_moments_kg_m2: [1, 1, 1], max_body_torque_nm: [1, 1, 1]},
          %{
            frame: :body_principal_axes,
            principal_moments_kg_m2: [1, 1, 3],
            max_body_torque_nm: [1, 1, 1]
          },
          %{
            frame: :body_principal_axes,
            principal_moments_kg_m2: [0, 1, 1],
            max_body_torque_nm: [1, 1, 1]
          },
          %{
            frame: :body_principal_axes,
            principal_moments_kg_m2: [1, 1, 1],
            max_body_torque_nm: [0, 1, 1]
          }
        ] do
      assert_raise ArgumentError, fn -> RigidBody.new!(c) end
    end

    assert body([1, 1, 2])
  end
end
