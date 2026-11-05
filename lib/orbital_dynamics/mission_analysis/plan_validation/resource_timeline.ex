defmodule OrbitalDynamics.MissionAnalysis.PlanValidation.ResourceTimeline do
  @moduledoc "Independent saved-phase/activity partition for resource accounting. No producer motion, pointing or resource helpers."
  alias OrbitalDynamics.MissionAnalysis.PlanValidation.MotionHistory

  def segments(i, r, asset) do
    path = i["study"]["path_constraints"]["assets"][asset]
    h = i["study"]["horizon"]
    requests = Map.new(i["mission"]["requests"], &{&1["id"], &1})
    acts = Enum.filter(r["activities"], &(&1["asset_id"] == asset))
    transitions = Enum.filter(r["attitude_planning"]["transitions"], &(&1["asset_id"] == asset))

    terminal =
      get_in(r, ["attitude_planning", "horizon_coverage", "assets", asset, "terminal_motion"])

    motion =
      Enum.flat_map(transitions ++ if(is_map(terminal), do: [terminal], else: []), fn plan ->
        terminal? = plan == terminal
        default = if terminal?, do: h["terminals"][asset]["mode"], else: path["transition_mode"]

        for p <- plan["phases"], p["ends_after_s"] > p["starts_after_s"] do
          %{
            a: plan["source_epoch_s"] + p["starts_after_s"],
            b: plan["source_epoch_s"] + p["ends_after_s"],
            phase: p["kind"],
            mode: Map.get(p, "mode_name", default),
            scope: if(terminal?, do: "terminal", else: "transition"),
            source: {:phase, p, plan["source_epoch_s"]},
            activity_type: nil
          }
        end
      end)

    activities =
      Enum.map(acts, fn a ->
        %{
          a: a["starts_at_s"],
          b: a["ends_at_s"],
          phase: "activity",
          mode: path["activity_modes"][a["request_id"]],
          scope: "activity:" <> a["request_id"],
          source: {:activity, a, requests[a["request_id"]]},
          activity_type: requests[a["request_id"]]["activity_type"]
        }
      end)

    segments = Enum.sort_by(motion ++ activities, & &1.a)

    unless segments != [] and hd(segments).a == h["starts_at_s"] and
             List.last(segments).b == h["ends_at_s"] and
             Enum.all?(segments, &(&1.b > &1.a and is_map(path["modes"][&1.mode]))) and
             Enum.all?(Enum.chunk_every(segments, 2, 1, :discard), fn [a, b] -> a.b == b.a end),
           do: raise(ArgumentError, "resource phases must partition the declared horizon exactly")

    segments
  end

  def pose(%{source: {:phase, p, origin}}, t), do: MotionHistory.phase_pose(p, origin, t)

  def pose(%{source: {:activity, _a, %{"model" => "fixed_attitude"} = q}}, t),
    do: %{
      "epoch_s" => t,
      "quaternion_wxyz" => q["parameters"]["quaternion_wxyz"],
      "angular_velocity_inertial_deg_s" => [0, 0, 0],
      "angular_acceleration_inertial_deg_s2" => [0, 0, 0]
    }

  def pose(%{source: {:activity, a, _}}, t),
    do: Enum.find(a["attitude_profile"], &(&1["epoch_s"] == t))
end
