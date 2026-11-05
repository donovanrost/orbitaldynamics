defmodule OrbitalDynamics.MissionAnalysis.Attitude.SavedMotion do
  @moduledoc "Finite saved-motion intervals with original phase clocks and explicit endpoint joins."
  alias OrbitalDynamics.MissionAnalysis.Attitude.{Motion, Quaternion, RigidBody}
  alias OrbitalDynamics.MissionAnalysis.Input
  alias OrbitalDynamics.Vector3, as: V

  def validate!(nil), do: nil

  def validate!(c) do
    unless is_map(c) and Enum.sort(Map.keys(c)) == ~w(acquisitions committed terminal),
      do: raise(ArgumentError, "invalid saved asset motion")

    unless is_map(c["acquisitions"]) and map_size(c["acquisitions"]) <= 100,
      do: raise(ArgumentError, "bounded saved acquisitions required")

    for {id, r} <- c["acquisitions"],
        do:
          (
            Input.id!(id)
            record!(r)
          )

    for key <- ~w(terminal committed), c[key] != :null, do: record!(c[key])
    c
  end

  def record!(r) do
    unless is_map(r) and
             Enum.sort(Map.keys(r)) == ~w(ends_at_s mode source_plan starts_at_s strict),
           do: raise(ArgumentError, "invalid saved motion interval")

    Input.id!(r["mode"])
    p = r["source_plan"]

    unless is_map(p) and is_list(p["phases"]) and length(p["phases"]) in 1..1024 and
             is_boolean(r["strict"]),
           do: raise(ArgumentError, "bounded saved phases and explicit strictness required")

    a = Input.number!(r["starts_at_s"], "saved motion start", -1.0e12, 1.0e12)
    b = Input.number!(r["ends_at_s"], "saved motion end", a, 1.0e12)

    unless is_number(p["source_epoch_s"]) and is_number(p["destination_epoch_s"]) and
             a >= p["source_epoch_s"] and b <= p["destination_epoch_s"] and b > a,
           do: raise(ArgumentError, "saved motion must be a positive covered interval")

    r
  end

  def pose(plan, t) do
    k = Motion.at_epoch(plan, t)

    %{
      "epoch_s" => t,
      "quaternion_wxyz" => Tuple.to_list(k.quaternion),
      "angular_velocity_inertial_deg_s" => Tuple.to_list(k.angular_velocity_deg_s)
    }
  end

  def matches?(a, b),
    do:
      a["epoch_s"] == b["epoch_s"] and
        Quaternion.distance_deg(a["quaternion_wxyz"], b["quaternion_wxyz"]) <= 1.0e-8 and
        V.norm(
          V.subtract(
            List.to_tuple(a["angular_velocity_inertial_deg_s"]),
            List.to_tuple(b["angular_velocity_inertial_deg_s"])
          )
        ) <= 1.0e-8

  def resolve(r, source, destination, limits) do
    plan = clip(r)

    if matches?(source, pose(plan, plan["source_epoch_s"])) and
         matches?(destination, pose(plan, plan["destination_epoch_s"])) do
      validate_plan!(plan, limits)
    else
      if r["strict"],
        do:
          {:infeasible, %{"reason" => "saved_motion_endpoint_mismatch", "status" => "violated"}},
        else: :miss
    end
  end

  def clip(r) do
    a = r["starts_at_s"]
    b = r["ends_at_s"]
    p = r["source_plan"]
    origin = p["source_epoch_s"]

    phases =
      Enum.flat_map(p["phases"], fn phase ->
        first = max(a, origin + phase["starts_after_s"])
        last = min(b, origin + phase["ends_after_s"])

        if last > first do
          k = Motion.kinematics_at_phase(phase, origin, first)
          # Keep the original evaluation clock, even across repeated checkpoints.
          clock =
            phase["source_phase"] ||
              %{"source_epoch_s" => origin, "phase" => Map.delete(phase, "source_phase")}

          [
            %{
              "kind" => phase["kind"],
              "starts_after_s" => first - a,
              "ends_after_s" => last - a,
              "quaternion_wxyz" => Tuple.to_list(k.quaternion),
              "angular_velocity_inertial_deg_s" => Tuple.to_list(k.angular_velocity_deg_s),
              "angular_acceleration_inertial_deg_s2" =>
                Tuple.to_list(k.angular_acceleration_deg_s2),
              "source_phase" => clock,
              "mode_name" => Map.get(phase, "mode_name", r["mode"])
            }
          ]
        else
          []
        end
      end)

    unless phases != [], do: raise(ArgumentError, "saved motion interval has no phase coverage")

    %{
      "source_epoch_s" => a,
      "destination_epoch_s" => b,
      "available_s" => b - a,
      "required_s" => b - a,
      "time_margin_s" => 0.0,
      "status" => "supported_by_saved_motion",
      "phases" => phases,
      "terminal_orientation_residual_deg" => 0.0,
      "terminal_rate_residual_deg_s" => 0.0
    }
  end

  def validate_plan!(p, limits) do
    phases = Enum.filter(p["phases"], &(&1["ends_after_s"] > &1["starts_after_s"]))
    start = p["source_epoch_s"]
    stop = p["destination_epoch_s"]

    unless phases != [] and abs(hd(phases)["starts_after_s"]) <= 1.0e-7 and
             abs(List.last(phases)["ends_after_s"] - (stop - start)) <= 1.0e-7,
           do: raise(ArgumentError, "saved motion does not cover its interval")

    checks =
      Enum.all?(phases, fn phase ->
        k0 = Motion.kinematics_at_phase(phase, start, start + phase["starts_after_s"])
        k1 = Motion.kinematics_at_phase(phase, start, start + phase["ends_after_s"])

        V.norm(V.cross(k0.angular_velocity_deg_s, k0.angular_acceleration_deg_s2)) <=
          1.0e-12 *
            max(1, V.norm(k0.angular_velocity_deg_s) * V.norm(k0.angular_acceleration_deg_s2)) and
          V.norm(k0.angular_velocity_deg_s) <= limits.max_rate_deg_s + 1.0e-9 and
          V.norm(k1.angular_velocity_deg_s) <= limits.max_rate_deg_s + 1.0e-9 and
          V.norm(k0.angular_acceleration_deg_s2) <= limits.max_accel_deg_s2 + 1.0e-9
      end)

    joined =
      Enum.all?(Enum.chunk_every(phases, 2, 1, :discard), fn [x, y] ->
        t = start + x["ends_after_s"]

        abs(x["ends_after_s"] - y["starts_after_s"]) <= 1.0e-7 and
          matches?(phase_pose(x, start, t), phase_pose(y, start, t))
      end)

    unless joined, do: raise(ArgumentError, "saved motion phases are discontinuous")

    if checks do
      if limits[:rigid_body] do
        torque = RigidBody.transition(p, limits.rigid_body)

        if torque["status"] == "supported",
          do: {:ok, Map.put(p, "rigid_body_torque", torque)},
          else: {:infeasible, Map.put(p, "reason", "rigid_body_torque_exceeds_limit")}
      else
        {:ok, p}
      end
    else
      {:infeasible, Map.put(p, "reason", "saved_motion_exceeds_limits")}
    end
  end

  defp phase_pose(p, origin, t) do
    k = Motion.kinematics_at_phase(p, origin, t)

    %{
      "epoch_s" => t,
      "quaternion_wxyz" => Tuple.to_list(k.quaternion),
      "angular_velocity_inertial_deg_s" => Tuple.to_list(k.angular_velocity_deg_s)
    }
  end

  def acquire(source, dest, limits, id, fallback) do
    r = get_in(limits, [:saved_motion, "acquisitions", id])
    result = if r, do: resolve(r, source, dest, limits), else: :miss

    case result do
      :miss -> prefix(source, dest, limits, :before_slew, id, fallback)
      other -> other
    end
  end

  def terminal(source, dest, limits, fallback) do
    r = get_in(limits, [:saved_motion, "terminal"])
    result = if is_map(r), do: resolve(r, source, dest, limits), else: :miss

    case result do
      :miss -> prefix(source, dest, limits, :terminal, nil, fallback)
      other -> other
    end
  end

  defp prefix(source, dest, limits, position, id, fallback) do
    r = get_in(limits, [:saved_motion, "committed"])

    if is_map(r) and source["epoch_s"] == r["starts_at_s"] do
      plan = clip(r)
      last = pose(plan, plan["destination_epoch_s"])

      with true <- dest["epoch_s"] >= last["epoch_s"],
           true <- matches?(source, pose(plan, plan["source_epoch_s"])),
           {:ok, plan} <- validate_plan!(plan, limits),
           {:ok, tail} <-
             if(dest["epoch_s"] == last["epoch_s"],
               do: Motion.continuity(last, dest, limits),
               else: Motion.transition(last, dest, Map.delete(limits, :saved_motion), position)
             ) do
        shift = last["epoch_s"] - source["epoch_s"]

        phases =
          plan["phases"] ++
            Enum.map(
              tail["phases"],
              &(&1
                |> Map.update!("starts_after_s", fn x -> x + shift end)
                |> Map.update!("ends_after_s", fn x -> x + shift end))
            )

        validate_plan!(
          %{
            plan
            | "destination_epoch_s" => dest["epoch_s"],
              "available_s" => dest["epoch_s"] - source["epoch_s"],
              "phases" => phases
          },
          limits
        )
      else
        _ ->
          {:infeasible, %{"reason" => "committed_motion_conflict", "request_id" => id || :null}}
      end
    else
      fallback.()
    end
  end
end
