defmodule OrbitalDynamics.MissionAnalysis.Attitude.MotionTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.Vector3, as: V
  alias OrbitalDynamics.MissionAnalysis.Attitude.{Motion, Quaternion, Pointing}
  alias OrbitalDynamics.Frame
  defp limits, do: %{max_rate_deg_s: 10, max_accel_deg_s2: 5, settling_s: 0}

  defp pose(t, q, w \\ {0, 0, 0}),
    do: %{
      "epoch_s" => t,
      "quaternion_wxyz" => Tuple.to_list(q),
      "angular_velocity_inertial_deg_s" => Tuple.to_list(w)
    }

  test "Hamilton composition and antipodal representation preserve rotations" do
    x = Quaternion.increment({90, 0, 0})
    z = Quaternion.increment({0, 0, 90})
    assert V.norm(V.subtract(Quaternion.rotate(x, {0, 1, 0}), {0, 0, 1})) < 1.0e-12
    product = Quaternion.multiply(z, x)
    assert V.norm(V.subtract(Quaternion.rotate(product, {0, 1, 0}), {0, 0, 1})) < 1.0e-12
    {w, a, b, c} = product
    assert Quaternion.distance_deg(product, {-w, -a, -b, -c}) < 1.0e-12
  end

  test "roll convention and payload mount produce the requested inertial boresight" do
    frame = Frame.earth_inertial_j2000()
    mount = Quaternion.increment({0, 90, 0})

    config = %{
      "body_to_payload_quaternion" => Tuple.to_list(mount),
      "roll_reference_inertial" => [0, 0, 1]
    }

    assert {:ok, p} = Pointing.from_direction({1, 0, 0}, frame, config)
    body_boresight = Quaternion.rotate(Quaternion.inverse(mount), {0, 0, 1})

    assert V.norm(V.subtract(Quaternion.rotate(p.quaternion, body_boresight), {1, 0, 0})) <
             1.0e-12

    assert {:unknown, :roll_reference_singular} = Quaternion.from_direction({0, 0, 1}, {0, 0, 1})
    assert_raise ArgumentError, fn -> Quaternion.new!([0, 0, 0, 0]) end
  end

  test "triangular and trapezoidal rest slews have analytic durations and bounded phases" do
    source = pose(0, {1, 0, 0, 0})

    assert {:ok, triangle} =
             Motion.transition(source, pose(2, Quaternion.increment({0, 0, 5})), limits())

    assert_in_delta triangle["required_s"], 2, 1.0e-12
    assert_in_delta triangle["peak_rate_deg_s"], 5, 1.0e-12

    assert {:ok, trapezoid} =
             Motion.transition(source, pose(11, Quaternion.increment({0, 0, 90})), limits())

    assert_in_delta trapezoid["required_s"], 11, 1.0e-12
    assert_in_delta trapezoid["peak_rate_deg_s"], 10, 1.0e-12

    for i <- 0..110 do
      state = Motion.at(trapezoid, i / 10)
      assert V.norm(state.angular_velocity_deg_s) <= 10 + 1.0e-10
      assert V.norm(state.angular_acceleration_deg_s2) <= 5 + 1.0e-10
    end

    assert Quaternion.distance_deg(
             Motion.at(trapezoid, 11).quaternion,
             Quaternion.increment({0, 0, 90})
           ) < 1.0e-10

    assert {:infeasible, e} =
             Motion.transition(source, pose(10.9, Quaternion.increment({0, 0, 90})), limits())

    assert e["reason"] == "insufficient_transition_time"
  end

  test "braking, settling and ramping connect nonzero inertial endpoint velocities" do
    q0 = Quaternion.increment({20, 5, -12})
    q1 = Quaternion.increment({-50, 10, 30})
    source = pose(100, q0, {3, 2, 1})
    target = pose(150, q1, {-2, 4, 1})
    assert {:ok, plan} = Motion.transition(source, target, %{limits() | settling_s: 2})
    final = Motion.at(plan, 50)
    assert Quaternion.distance_deg(final.quaternion, q1) < 1.0e-10
    assert V.norm(V.subtract(final.angular_velocity_deg_s, {-2, 4, 1})) < 1.0e-10
    assert_in_delta plan["brake_s"], :math.sqrt(14) / 5, 1.0e-12
    assert_in_delta plan["ramp_s"], :math.sqrt(21) / 5, 1.0e-12
    settle = Enum.find(plan["phases"], &(&1["kind"] == "settle"))
    assert_in_delta settle["ends_after_s"] - settle["starts_after_s"], 2, 1.0e-12

    for i <- 0..500 do
      s = Motion.at(plan, i / 10)
      assert V.norm(s.angular_velocity_deg_s) <= 10 + 1.0e-9
      assert V.norm(s.angular_acceleration_deg_s2) <= 5 + 1.0e-9
    end
  end

  test "zero-angle transitions still enforce declared settling and endpoint rate limits" do
    p = pose(0, {1, 0, 0, 0})

    assert {:infeasible, _} =
             Motion.transition(p, pose(1, {1, 0, 0, 0}), %{limits() | settling_s: 2})

    assert {:ok, plan} = Motion.transition(p, pose(2, {1, 0, 0, 0}), %{limits() | settling_s: 2})
    assert plan["slew_s"] == 0
    assert {:infeasible, e} = Motion.transition(p, pose(50, {1, 0, 0, 0}, {11, 0, 0}), limits())
    assert e["reason"] == "endpoint_rate_exceeds_limit"
  end

  test "identical and antipodal orientations require exactly zero rest slew without a small-angle cutoff" do
    q = Quaternion.increment({12, -7, 3})
    {w, x, y, z} = q
    assert Quaternion.delta(q, q) == {0.0, 0.0, 0.0}
    assert Quaternion.delta(q, {-w, -x, -y, -z}) == {0.0, 0.0, 0.0}
    assert {:ok, plan} = Motion.transition(pose(0, q), pose(0, q), limits())
    assert plan["required_s"] == 0
    assert {:ok, settled} = Motion.transition(pose(0, q), pose(2, q), %{limits() | settling_s: 2})
    assert settled["required_s"] == 2
    tiny = Quaternion.increment({0, 0, 1.0e-13})
    assert Quaternion.distance_deg({1, 0, 0, 0}, tiny) > 0
  end

  test "terminal holds stay at rest and reject incompatible target rates" do
    source = pose(0, Quaternion.increment({20, 10, 0}), {1, 2, 0})
    destination = pose(30, Quaternion.increment({0, 0, 90}))
    assert {:ok, plan} = Motion.transition(source, destination, limits(), :terminal)
    hold = List.last(plan["phases"])
    assert hold["kind"] == "hold"
    assert hold["ends_after_s"] > hold["starts_after_s"]

    for t <- [hold["starts_after_s"], (hold["starts_after_s"] + 30) / 2, 30] do
      state = Motion.at(plan, t)
      assert Quaternion.distance_deg(state.quaternion, Quaternion.increment({0, 0, 90})) < 1.0e-10
      assert V.norm(state.angular_velocity_deg_s) < 1.0e-10
    end

    assert_raise ArgumentError, fn ->
      Motion.transition(source, pose(30, {1, 0, 0, 0}, {0, 0, 1}), limits(), :terminal)
    end

    assert_raise ArgumentError, fn ->
      apply(Motion, :transition, [source, destination, limits(), :unsupported])
    end
  end
end
