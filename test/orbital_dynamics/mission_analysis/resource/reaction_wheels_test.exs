defmodule OrbitalDynamics.MissionAnalysis.Resource.ReactionWheelsTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.MissionAnalysis.Resource.ReactionWheels, as: Wheels
  alias OrbitalDynamics.MissionAnalysis.Attitude.Quaternion, as: Q
  alias OrbitalDynamics.Vector3, as: V

  defp config,
    do: %{
      "frame" => "body_principal_axes",
      "wheel_axes_body" => [[1, 0, 0], [0, 1, 0], [0, 0, 1]],
      "principal_moments_kg_m2" => [2, 3, 4],
      "initial_momentum_nms" => [0, 0, 0],
      "momentum_capacity_nms" => [10, 10, 10],
      "max_motor_torque_nm" => [1, 1, 1],
      "disturbance_torque_body_nm" => [0, 0, 0.02],
      "max_unload_torque_body_nm" => [0, 0, 0.06],
      "unload_modes" => %{"dump" => %{"external_torque_body_nm" => [0, 0, -0.055]}}
    }

  defp session(c), do: elem(Wheels.prepare(nil, nil, c), 1)

  defp pose(q \\ {1, 0, 0, 0}, w \\ [0, 0, 0]),
    do: %{
      "epoch_s" => 0,
      "quaternion_wxyz" => Tuple.to_list(q),
      "angular_velocity_inertial_deg_s" => w,
      "angular_acceleration_inertial_deg_s2" => [0, 0, 0]
    }

  defp input(p),
    do: %{
      kinematics_start: p,
      kinematics_mid: p,
      kinematics_end: p,
      phase: "hold",
      activity_type: nil,
      mode: %{"name" => "idle", "parameters" => %{}}
    }

  defp failed(r, id), do: Enum.any?(r.checks, &(&1.id == id and &1.status == :violated))

  test "constant disturbance accumulates signed rotor momentum independently of zero body momentum" do
    s = session(config())
    state = Wheels.initial(s)
    assert {:ok, next, r} = Wheels.step(state, input(pose()), 10, s)
    assert_in_delta elem(Wheels.vector(next), 2), 0.2, 1.0e-12
    assert_in_delta Enum.at(r.metrics["motor_torque_mid_nm"], 2), 0.02, 1.0e-12
    assert Enum.all?(r.checks, &(&1.status == :supported))
  end

  test "external unload torque changes momentum continuously rather than resetting it" do
    s = session(Map.put(config(), "initial_momentum_nms", [0, 0, 0.4]))

    i = %{
      input(pose())
      | phase: "activity",
        activity_type: "momentum_unload",
        mode: %{"name" => "dump", "parameters" => %{"momentum_unloading" => true}}
    }

    assert {:ok, next, r} = Wheels.step(Wheels.initial(s), i, 20, s)
    assert_in_delta elem(Wheels.vector(next), 2), -0.3, 1.0e-12
    assert_in_delta Enum.at(r.metrics["motor_torque_mid_nm"], 2), -0.035, 1.0e-12
    moving = %{i | kinematics_mid: pose({1, 0, 0, 0}, [0, 0, 1])}
    assert {:ok, _, bad} = Wheels.step(Wheels.initial(s), moving, 20, s)
    assert failed(bad, "unload_stationary_body")

    assert {:ok, _, missing} =
             Wheels.step(
               Wheels.initial(s),
               %{i | mode: %{"name" => "idle", "parameters" => %{}}},
               20,
               s
             )

    assert failed(missing, "unload_mode_declared")
  end

  test "zero external torque conserves total inertial momentum while rotor components rotate in body axes" do
    c =
      config()
      |> Map.put("disturbance_torque_body_nm", [0, 0, 0])
      |> Map.put("initial_momentum_nms", [0.1, 0.2, 0.3])

    s = session(c)

    i =
      input(pose({1, 0, 0, 0}, [0, 0, 90]))
      |> Map.put(:kinematics_mid, pose(Q.increment({0, 0, 45}), [0, 0, 90]))
      |> Map.put(:kinematics_end, pose(Q.increment({0, 0, 90}), [0, 0, 90]))

    assert {:ok, next, r} = Wheels.step(Wheels.initial(s), i, 1, s)

    for {a, b} <- Enum.zip(Tuple.to_list(Wheels.vector(next)), [0.2, -0.1, 0.3]),
        do: assert_in_delta(a, b, 1.0e-12)

    expected = {0.1, 0.2, 0.3 + 4 * :math.pi() / 2}
    actual = r.metrics["total_inertial_angular_momentum_nms"] |> List.to_tuple()
    assert V.norm(V.subtract(actual, expected)) < 1.0e-12
  end

  test "motor torque includes stored-wheel gyroscopic coupling and checks initial overcapacity" do
    c =
      config()
      |> Map.put("disturbance_torque_body_nm", [0, 0, 0])
      |> Map.put("initial_momentum_nms", [0.5, 0.1, 0.3])
      |> Map.put("max_motor_torque_nm", [1, 1, 0.5])

    s = session(c)
    p = pose({1, 0, 0, 0}, [180 / :math.pi(), 180 / :math.pi(), 0])
    assert {:ok, _, r} = Wheels.step(Wheels.initial(s), input(p), 0, s)

    for {a, b} <- Enum.zip(r.metrics["motor_torque_mid_nm"], [-0.3, 0.3, -0.6]),
        do: assert_in_delta(a, b, 1.0e-12)

    assert failed(r, "wheel_3_motor_torque")
    s = session(Map.put(c, "momentum_capacity_nms", [0.4, 10, 10]))
    assert {:ok, _, r} = Wheels.step(Wheels.initial(s), input(p), 0, s)
    assert failed(r, "wheel_1_momentum")
  end

  test "allocation respects explicit signed/permuted wheel axes and rejects unsupported arrays" do
    c = Map.put(config(), "wheel_axes_body", [[0, 0, -1], [1, 0, 0], [0, 1, 0]])
    s = session(c)
    assert {:ok, next, _} = Wheels.step(Wheels.initial(s), input(pose()), 10, s)
    assert_in_delta elem(Wheels.vector(next), 0), -0.2, 1.0e-12

    for bad <- [
          Map.put(c, "wheel_axes_body", [[1, 0, 0], [1, 0, 0], [0, 0, 1]]),
          Map.put(c, "wheel_axes_body", [[1, 0, 0], [0, 1, 0]]),
          Map.put(c, "initial_momentum_nms", [0, 0]),
          put_in(c, ["unload_modes", "dump", "external_torque_body_nm"], [0, 0, -1])
        ] do
      assert_raise ArgumentError, fn -> session(bad) end
    end

    assert {:ok, _, r} = Wheels.step(Wheels.initial(s), %{}, 1, s)
    assert hd(r.checks).status == :unknown
  end
end
