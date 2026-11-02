defmodule OrbitalDynamics.MissionAnalysis.Attitude.Motion do
  @moduledoc "Constructive rate/acceleration-bounded SO(3) transitions with explicit endpoint angular velocities."
  alias OrbitalDynamics.Vector3, as: V
  alias OrbitalDynamics.MissionAnalysis.Attitude.Quaternion, as: Q

  def transition(source, destination, limits) do
    q0 = Q.new!(source["quaternion_wxyz"])
    q1 = Q.new!(destination["quaternion_wxyz"])

    w0 =
      OrbitalDynamics.MissionAnalysis.Input.vector!(
        source["angular_velocity_inertial_deg_s"],
        "source angular velocity"
      )

    w1 =
      OrbitalDynamics.MissionAnalysis.Input.vector!(
        destination["angular_velocity_inertial_deg_s"],
        "target angular velocity"
      )

    speed0 = V.norm(w0)
    speed1 = V.norm(w1)
    vmax = limits.max_rate_deg_s
    accel = limits.max_accel_deg_s2
    brake = speed0 / accel
    ramp = speed1 / accel
    stopped = Q.multiply(Q.increment(V.scale(w0, brake / 2)), q0)
    preramp = Q.multiply(Q.increment(V.scale(w1, -ramp / 2)), q1)
    rotation = Q.delta(stopped, preramp)
    angle = V.norm(rotation)
    peak = min(vmax, :math.sqrt(angle * accel))
    accelerate = peak / accel
    cruise = if peak == 0, do: 0.0, else: max(0.0, (angle - peak * peak / accel) / peak)
    duration = brake + 2 * accelerate + cruise + limits.settling_s + ramp
    gap = destination["epoch_s"] - source["epoch_s"]

    evidence = %{
      "source_epoch_s" => source["epoch_s"],
      "destination_epoch_s" => destination["epoch_s"],
      "available_s" => gap,
      "required_s" => duration,
      "time_margin_s" => gap - duration,
      "brake_s" => brake,
      "slew_angle_deg" => angle,
      "slew_s" => 2 * accelerate + cruise,
      "settling_s" => limits.settling_s,
      "ramp_s" => ramp,
      "peak_rate_deg_s" => max(peak, max(speed0, speed1)),
      "max_accel_deg_s2" => accel
    }

    cond do
      speed0 > vmax or speed1 > vmax ->
        {:infeasible, Map.merge(evidence, %{"reason" => "endpoint_rate_exceeds_limit"})}

      gap < duration ->
        {:infeasible, Map.merge(evidence, %{"reason" => "insufficient_transition_time"})}

      true ->
        axis = if angle > 0, do: V.scale(rotation, 1 / angle), else: {0.0, 0.0, 0.0}

        commands = [
          {brake, if(speed0 > 0, do: V.scale(w0, -accel / speed0), else: {0.0, 0.0, 0.0}),
           "brake"},
          {gap - duration, {0.0, 0.0, 0.0}, "hold"},
          {accelerate, V.scale(axis, accel), "slew_accelerate"},
          {cruise, {0.0, 0.0, 0.0}, "slew_cruise"},
          {accelerate, V.scale(axis, -accel), "slew_decelerate"},
          {limits.settling_s, {0.0, 0.0, 0.0}, "settle"},
          {ramp, if(speed1 > 0, do: V.scale(w1, accel / speed1), else: {0.0, 0.0, 0.0}),
           "ramp_to_tracking"}
        ]

        {phases, {_, q, w}} =
          Enum.map_reduce(commands, {0.0, q0, w0}, fn {d, a, kind}, {t, q, w} ->
            phase = %{
              "kind" => kind,
              "starts_after_s" => t,
              "ends_after_s" => t + d,
              "quaternion_wxyz" => Tuple.to_list(q),
              "angular_velocity_inertial_deg_s" => Tuple.to_list(w),
              "angular_acceleration_inertial_deg_s2" => Tuple.to_list(a)
            }

            {nextq, nextw} = advance(q, w, a, d)
            # Roundoff after a braking phase must not accumulate a fictitious drift during a hold.
            nextw = if kind in ["brake", "slew_decelerate"], do: {0.0, 0.0, 0.0}, else: nextw
            {phase, {t + d, nextq, nextw}}
          end)

        {:ok,
         Map.merge(evidence, %{
           "status" => "supported_by_kinematic_model",
           "phases" => phases,
           "terminal_orientation_residual_deg" => Q.distance_deg(q, q1),
           "terminal_rate_residual_deg_s" => V.norm(V.subtract(w, w1))
         })}
    end
  end

  def at(plan, elapsed_s) do
    phases = Enum.filter(plan["phases"], &(&1["ends_after_s"] > &1["starts_after_s"]))
    phase = Enum.find(phases, &(elapsed_s <= &1["ends_after_s"])) || List.last(plan["phases"])

    dt =
      max(
        0.0,
        min(elapsed_s - phase["starts_after_s"], phase["ends_after_s"] - phase["starts_after_s"])
      )

    q = Q.new!(phase["quaternion_wxyz"])
    w = List.to_tuple(phase["angular_velocity_inertial_deg_s"])
    a = List.to_tuple(phase["angular_acceleration_inertial_deg_s2"])
    {q, w} = advance(q, w, a, dt)
    %{quaternion: q, angular_velocity_deg_s: w, angular_acceleration_deg_s2: a}
  end

  defp advance(q, w, a, t),
    do:
      {Q.multiply(Q.increment(V.add(V.scale(w, t), V.scale(a, t * t / 2))), q),
       V.add(w, V.scale(a, t))}
end
