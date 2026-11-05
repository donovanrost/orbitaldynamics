defmodule OrbitalDynamics.MissionAnalysis.Attitude.RigidBody do
  @moduledoc "Ideal rigid-body torque demand in declared body principal axes; no wheel allocation, stored wheel momentum or external disturbances."
  alias OrbitalDynamics.MissionAnalysis.Input
  alias OrbitalDynamics.MissionAnalysis.Attitude.Quaternion, as: Q
  alias OrbitalDynamics.Vector3, as: V
  @rad :math.pi() / 180

  def new!(c) when is_map(c) do
    unless Enum.sort(Map.keys(c)) == ~w(frame max_body_torque_nm principal_moments_kg_m2)a and
             c.frame == :body_principal_axes,
           do:
             raise(
               ArgumentError,
               "rigid_body requires frame: :body_principal_axes, principal_moments_kg_m2 and max_body_torque_nm"
             )

    moments = Input.vector!(c.principal_moments_kg_m2, "principal inertia kg m^2")
    capacity = Input.vector!(c.max_body_torque_nm, "body torque capacity Nm")

    unless Enum.all?(Tuple.to_list(moments), &(&1 > 0)) and
             Enum.all?(Tuple.to_list(capacity), &(&1 > 0)),
           do: raise(ArgumentError, "principal moments and torque capacities must be positive")

    [x, y, z] = Tuple.to_list(moments)

    unless x <= y + z and y <= x + z and z <= x + y,
      do:
        raise(
          ArgumentError,
          "principal inertia moments violate the rigid-body triangle inequalities"
        )

    %{frame: :body_principal_axes, principal_moments_kg_m2: moments, max_body_torque_nm: capacity}
  end

  def new!(_), do: raise(ArgumentError, "rigid_body must be an explicit model map")

  def describe(c),
    do: %{
      "model" => "ideal_principal_axes_euler_torque.v1",
      "frame" => "body_principal_axes",
      "principal_moments_kg_m2" => Tuple.to_list(c.principal_moments_kg_m2),
      "max_body_torque_nm" => Tuple.to_list(c.max_body_torque_nm),
      "equation" => "tau_body = I alpha_body + omega_body cross (I omega_body)",
      "assumptions" => [
        "spacecraft body axes coincide with fixed principal axes about the center of mass",
        "symmetric independent positive/negative torque limits on each body axis",
        "zero external disturbance torque and no rotor angular momentum coupling",
        "no actuator allocation, power dependence, wheel-speed/momentum, flexible-body or jerk limits"
      ]
    }

  def at(pose, c) do
    q = Q.new!(pose["quaternion_wxyz"])

    w =
      pose["angular_velocity_inertial_deg_s"]
      |> Input.vector!("angular velocity")
      |> V.scale(@rad)
      |> then(&Q.rotate(Q.inverse(q), &1))

    a =
      pose["angular_acceleration_inertial_deg_s2"]
      |> Input.vector!("angular acceleration")
      |> V.scale(@rad)
      |> then(&Q.rotate(Q.inverse(q), &1))

    torque =
      V.add(
        diagonal(c.principal_moments_kg_m2, a),
        V.cross(w, diagonal(c.principal_moments_kg_m2, w))
      )

    required = torque |> Tuple.to_list() |> Enum.map(&abs/1)
    margins = Enum.zip_with(Tuple.to_list(c.max_body_torque_nm), required, &(&1 - &2))

    %{
      "status" => if(Enum.all?(margins, &(&1 >= 0)), do: "supported", else: "violated"),
      "required_body_torque_nm" => Tuple.to_list(torque),
      "absolute_body_torque_nm" => required,
      "capacity_body_torque_nm" => Tuple.to_list(c.max_body_torque_nm),
      "margin_body_torque_nm" => margins,
      "frame" => "body_principal_axes",
      "epoch_s" => pose["epoch_s"]
    }
  end

  @doc "Endpoint envelope for the generated fixed-axis, constant-acceleration phases, including both sides of acceleration switches."
  def transition(plan, c) do
    assessments =
      plan["phases"]
      |> Enum.filter(&(&1["ends_after_s"] > &1["starts_after_s"]))
      |> Enum.flat_map(fn p ->
        w = List.to_tuple(p["angular_velocity_inertial_deg_s"])
        a = List.to_tuple(p["angular_acceleration_inertial_deg_s2"])
        # Generated brake/slew/ramp phases have a fixed rotation axis. In these
        # phases the body components of alpha are constant and the gyro term is
        # affine in speed squared, so each component's extrema occur at endpoints.
        unless V.norm(V.cross(w, a)) <= 1.0e-12 * max(1, V.norm(w) * V.norm(a)),
          do:
            raise(
              ArgumentError,
              "rigid-body phase envelope requires collinear rate and acceleration"
            )

        duration = p["ends_after_s"] - p["starts_after_s"]

        for {dt, side} <- [{0.0, "start"}, {duration, "end"}] do
          pose = %{
            "epoch_s" => plan["source_epoch_s"] + p["starts_after_s"] + dt,
            "quaternion_wxyz" => p["quaternion_wxyz"],
            "angular_velocity_inertial_deg_s" => V.add(w, V.scale(a, dt)) |> Tuple.to_list(),
            "angular_acceleration_inertial_deg_s2" => p["angular_acceleration_inertial_deg_s2"]
          }

          pose =
            if p["source_phase"] do
              k =
                OrbitalDynamics.MissionAnalysis.Attitude.Motion.kinematics_at_phase(
                  p,
                  plan["source_epoch_s"],
                  pose["epoch_s"]
                )

              %{
                pose
                | "quaternion_wxyz" => Tuple.to_list(k.quaternion),
                  "angular_velocity_inertial_deg_s" => Tuple.to_list(k.angular_velocity_deg_s),
                  "angular_acceleration_inertial_deg_s2" =>
                    Tuple.to_list(k.angular_acceleration_deg_s2)
              }
            else
              pose
            end

          # Rotation about the phase axis leaves its body components unchanged;
          # the initial quaternion therefore transforms both endpoint vectors.
          at(pose, c) |> Map.merge(%{"phase" => p["kind"], "side" => side})
        end
      end)

    peak =
      for axis <- 0..2,
          do:
            Enum.reduce(assessments, 0.0, &max(Enum.at(&1["absolute_body_torque_nm"], axis), &2))

    margins = Enum.zip_with(Tuple.to_list(c.max_body_torque_nm), peak, &(&1 - &2))

    %{
      "status" => if(Enum.all?(margins, &(&1 >= 0)), do: "supported", else: "violated"),
      "coverage" => "fixed_axis_phase_endpoint_envelope",
      "frame" => "body_principal_axes",
      "maximum_absolute_body_torque_nm" => peak,
      "capacity_body_torque_nm" => Tuple.to_list(c.max_body_torque_nm),
      "minimum_margin_body_torque_nm" => margins,
      "first_violation" => Enum.find(assessments, &(&1["status"] == "violated")) || :null,
      "phase_endpoint_count" => length(assessments),
      "phase_endpoints" => assessments
    }
  end

  defp diagonal({x, y, z}, {a, b, c}), do: {x * a, y * b, z * c}
end
