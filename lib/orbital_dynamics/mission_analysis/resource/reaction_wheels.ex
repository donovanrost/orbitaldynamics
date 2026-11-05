defmodule OrbitalDynamics.MissionAnalysis.Resource.ReactionWheels do
  @moduledoc "Three orthogonal ideal wheels with signed rotor momentum, motor torque and declared external unloading torque. Prescribed attitude and sampled capacity checks, not closed-loop control."
  @behaviour OrbitalDynamics.MissionAnalysis.Resource.Model
  alias OrbitalDynamics.MissionAnalysis.{Input, Models.SurfaceSupport}
  alias OrbitalDynamics.MissionAnalysis.Attitude.Quaternion, as: Q
  alias OrbitalDynamics.MissionAnalysis.Path.Result
  alias OrbitalDynamics.Vector3, as: V
  @rad :math.pi() / 180
  @keys ~w(wheel_1_momentum_nms wheel_2_momentum_nms wheel_3_momentum_nms)

  def prepare(_, _, c) do
    SurfaceSupport.fields!(
      c,
      ~w(frame wheel_axes_body principal_moments_kg_m2 initial_momentum_nms momentum_capacity_nms max_motor_torque_nm disturbance_torque_body_nm max_unload_torque_body_nm unload_modes),
      "reaction wheels"
    )

    unless c["frame"] == "body_principal_axes",
      do: raise(ArgumentError, "wheel frame must be body_principal_axes")

    unless is_list(c["wheel_axes_body"]) and length(c["wheel_axes_body"]) == 3,
      do: raise(ArgumentError, "exactly three wheel axes required")

    axes = Enum.map(c["wheel_axes_body"], &Input.vector!(&1, "wheel axis"))

    unless Enum.all?(axes, &(abs(V.norm(&1) - 1) <= 1.0e-10)) and
             Enum.all?([{0, 1}, {0, 2}, {1, 2}], fn {a, b} ->
               abs(V.dot(Enum.at(axes, a), Enum.at(axes, b))) <= 1.0e-10
             end),
           do: raise(ArgumentError, "three orthonormal body wheel axes required")

    [first, second, third] = axes
    first = V.scale(first, 1 / V.norm(first))
    second = V.subtract(second, V.scale(first, V.dot(first, second)))
    second = V.scale(second, 1 / V.norm(second))
    normal = V.cross(first, second)
    third = V.scale(normal, if(V.dot(normal, third) < 0, do: -1.0, else: 1.0))
    axes = [first, second, third]
    inertia = positive(c["principal_moments_kg_m2"], "wheel model principal inertia")
    [x, y, z] = Tuple.to_list(inertia)

    unless x <= y + z and y <= x + z and z <= x + y,
      do: raise(ArgumentError, "wheel model inertia violates triangle inequalities")

    capacity = positive(c["momentum_capacity_nms"], "wheel momentum capacity")
    motor = positive(c["max_motor_torque_nm"], "wheel motor torque")
    initial = Input.vector!(c["initial_momentum_nms"], "initial wheel momentum")
    disturbance = Input.vector!(c["disturbance_torque_body_nm"], "disturbance torque")

    unload_cap =
      Input.vector!(c["max_unload_torque_body_nm"], "external unloading torque capacity")

    unless Enum.all?(Tuple.to_list(unload_cap), &(&1 >= 0)) and is_map(c["unload_modes"]) and
             map_size(c["unload_modes"]) <= 16,
           do:
             raise(
               ArgumentError,
               "bounded unload modes and nonnegative external torque capacity required"
             )

    modes =
      Map.new(c["unload_modes"], fn {name, mode} ->
        Input.id!(name)
        SurfaceSupport.fields!(mode, ~w(external_torque_body_nm), "unload mode")
        torque = Input.vector!(mode["external_torque_body_nm"], "external unload torque")

        unless Enum.zip(Tuple.to_list(torque), Tuple.to_list(unload_cap))
               |> Enum.all?(fn {v, cap} -> abs(v) <= cap end),
               do: raise(ArgumentError, "unload mode exceeds external torque capacity")

        {name, torque}
      end)

    {:ok,
     %{
       axes: axes,
       inertia: inertia,
       capacity: capacity,
       motor: motor,
       initial: initial,
       disturbance: disturbance,
       unload_modes: modes
     },
     %{
       "model" => "orthogonal_three_wheel_momentum.v1",
       "comparison_tolerance" => %{"Nm" => 1.0e-12, "Nms" => 1.0e-12},
       "configuration" => c,
       "normalized_wheel_axes_body" => Enum.map(axes, &Tuple.to_list/1),
       "integration" =>
         "inertial total momentum update with midpoint external torque; endpoint attitude/rate separates rotor momentum from body momentum",
       "checks" =>
         "start/midpoint/end rotor momentum and motor torque at each configured resource interval; no continuous certification",
       "limits" => [
         "constant principal inertia and three orthogonal ideal wheel axes",
         "constant body disturbance and declared external unloading torques, not magnetic/thruster feasibility",
         "unloading requires a stationary body and an explicit momentum_unload activity/mode",
         "no wheel speed conversion, motor power model, redundant allocation or flexible-body dynamics",
         "violated prescribed-path demand is retained for diagnostics, not achievable execution"
       ]
     }}
  end

  def initial(s), do: state(s.initial)
  def boundaries(_), do: []
  def vector(state), do: @keys |> Enum.map(&Map.fetch!(state, &1)) |> List.to_tuple()
  defp state(v), do: Map.new(Enum.zip(@keys, Tuple.to_list(v)))

  def step(current, input, dt, s) do
    Input.number!(dt, "wheel interval duration", 0, 1.0e12)

    if Enum.all?(
         [:kinematics_start, :kinematics_mid, :kinematics_end],
         &is_map(Map.get(input, &1))
       ) do
      evaluate(current, input, dt, s)
    else
      {:ok, current,
       Result.new!(
         [
           %{
             "id" => "wheel_kinematics",
             "status" => "unknown",
             "reason" => "endpoint_and_midpoint_attitude_rate_acceleration_required"
           }
         ],
         %{}
       )}
    end
  end

  defp evaluate(current, input, dt, s) do
    start = input.kinematics_start
    mid = input.kinematics_mid
    stop = input.kinematics_end
    h0 = vector(current)
    w0 = body_rate(start)
    body_h0 = V.add(diagonal(s.inertia, w0), body(s.axes, h0))
    total0 = Q.rotate(Q.new!(start["quaternion_wxyz"]), body_h0)
    mode = input.mode["name"]
    unload = s.unload_modes[mode]
    requested = Map.get(input, :activity_type) == "momentum_unload"

    active =
      unload != nil and requested and input.phase == "activity" and
        get_in(input.mode, ["parameters", "momentum_unloading"]) == true

    stationary =
      Enum.all?(
        [start, mid, stop],
        &(V.norm(Input.vector!(&1["angular_velocity_inertial_deg_s"], "unload rate")) <= 1.0e-8 and
            V.norm(
              Input.vector!(&1["angular_acceleration_inertial_deg_s2"], "unload acceleration")
            ) <= 1.0e-8)
      )

    external = V.add(s.disturbance, if(active and stationary, do: unload, else: {0, 0, 0}))
    torque_i = Q.rotate(Q.new!(mid["quaternion_wxyz"]), external)
    total_mid = V.add(total0, V.scale(torque_i, dt / 2))
    total_end = V.add(total0, V.scale(torque_i, dt))
    hm = rotor(s, mid, total_mid)
    h1 = rotor(s, stop, total_end)
    hs = [h0, hm, h1]

    torques =
      Enum.zip([start, mid, stop], hs)
      |> Enum.map(fn {p, h} ->
        w = body_rate(p)
        a = body_accel(p)

        required =
          V.add(
            diagonal(s.inertia, a),
            V.cross(w, V.add(diagonal(s.inertia, w), body(s.axes, h)))
          )

        project(s.axes, V.subtract(external, required))
      end)

    checks =
      for axis <- 0..2,
          {values, caps, suffix, unit} <- [
            {hs, s.capacity, "momentum", "Nms"},
            {torques, s.motor, "motor_torque", "Nm"}
          ] do
        peak = Enum.map(values, &abs(elem(&1, axis))) |> Enum.max()
        margin = elem(caps, axis) - peak

        %{
          "id" => "wheel_#{axis + 1}_#{suffix}",
          "status" => if(margin >= -1.0e-12, do: "supported", else: "violated"),
          "margin" => margin,
          "margin_unit" => unit
        }
      end

    checks =
      checks ++
        [
          %{
            "id" => "unload_mode_declared",
            "status" =>
              if((requested and active) or (not requested and unload == nil),
                do: "supported",
                else: "violated"
              )
          },
          %{
            "id" => "unload_stationary_body",
            "status" => if(not active or stationary, do: "supported", else: "violated")
          }
        ]

    {:ok, state(h1),
     Result.new!(checks, %{
       "rotor_momentum_mid_nms" => Tuple.to_list(hm),
       "motor_torque_mid_nm" => torques |> Enum.at(1) |> Tuple.to_list(),
       "disturbance_torque_body_nm" => Tuple.to_list(s.disturbance),
       "applied_unload_torque_body_nm" =>
         if(active and stationary, do: Tuple.to_list(unload), else: [0, 0, 0]),
       "total_inertial_angular_momentum_nms" => Tuple.to_list(total_end)
     })}
  end

  defp rotor(s, p, total),
    do:
      project(
        s.axes,
        V.subtract(
          Q.rotate(Q.inverse(Q.new!(p["quaternion_wxyz"])), total),
          diagonal(s.inertia, body_rate(p))
        )
      )

  defp body_rate(p),
    do:
      p["angular_velocity_inertial_deg_s"]
      |> Input.vector!("wheel body rate")
      |> V.scale(@rad)
      |> then(&Q.rotate(Q.inverse(Q.new!(p["quaternion_wxyz"])), &1))

  defp body_accel(p),
    do:
      p["angular_acceleration_inertial_deg_s2"]
      |> Input.vector!("wheel body acceleration")
      |> V.scale(@rad)
      |> then(&Q.rotate(Q.inverse(Q.new!(p["quaternion_wxyz"])), &1))

  defp body(axes, v),
    do:
      axes
      |> Enum.zip(Tuple.to_list(v))
      |> Enum.reduce({0, 0, 0}, fn {a, k}, acc -> V.add(acc, V.scale(a, k)) end)

  defp project(axes, v), do: axes |> Enum.map(&V.dot(&1, v)) |> List.to_tuple()
  defp diagonal({x, y, z}, {a, b, c}), do: {x * a, y * b, z * c}

  defp positive(v, label) do
    v = Input.vector!(v, label)

    unless Enum.all?(Tuple.to_list(v), &(&1 > 0)),
      do: raise(ArgumentError, "#{label} must be positive")

    v
  end
end
