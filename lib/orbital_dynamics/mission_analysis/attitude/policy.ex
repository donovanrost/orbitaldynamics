defmodule OrbitalDynamics.MissionAnalysis.Attitude.Policy do
  @moduledoc "Explicit per-asset angular motion assumptions and bounded search/sampling controls."
  alias OrbitalDynamics.{Epoch, Frame}
  alias OrbitalDynamics.MissionAnalysis.Input
  alias OrbitalDynamics.MissionAnalysis.Attitude.Quaternion
  alias OrbitalDynamics.Schema.JsonSafety

  @enforce_keys [
    :assets,
    :profile_step_s,
    :derivative_step_s,
    :search_step_s,
    :max_candidate_starts,
    :max_evaluations
  ]
  defstruct @enforce_keys ++ [path_constraints: nil, horizon: nil, resources: nil]

  def new!(assets, opts) when is_map(assets) do
    keys =
      ~w(profile_step_s derivative_step_s search_step_s max_candidate_starts max_evaluations)a

    unless Keyword.keyword?(opts) and
             Enum.sort(Keyword.keys(opts) -- [:path_constraints, :horizon, :resources]) ==
               Enum.sort(keys) and
             length(Keyword.keys(opts)) == length(Enum.uniq(Keyword.keys(opts))),
           do: raise(ArgumentError, "explicit attitude sampling and search options required")

    path =
      case Keyword.get(opts, :path_constraints) do
        nil ->
          nil

        %OrbitalDynamics.MissionAnalysis.Path.Policy{} = p ->
          OrbitalDynamics.MissionAnalysis.Path.Policy.validate!(p)

        _ ->
          raise ArgumentError, "path_constraints must be a Path.Policy"
      end

    resources =
      case Keyword.get(opts, :resources) do
        nil ->
          nil

        %OrbitalDynamics.MissionAnalysis.Resource.Policy{} = p ->
          OrbitalDynamics.MissionAnalysis.Resource.Policy.validate!(p)

        _ ->
          raise ArgumentError, "resources must be a Resource.Policy"
      end

    if resources != nil and Keyword.get(opts, :horizon) == nil,
      do: raise(ArgumentError, "dynamic resources require an explicit full planning horizon")

    derivative = Input.positive!(opts[:derivative_step_s], "derivative_step_s")

    assets =
      Map.new(assets, fn {id, a} ->
        Input.id!(id)

        unless Enum.sort(Map.keys(a) -- [:rigid_body, :continuation_request_id, :saved_motion]) ==
                 Enum.sort(
                   ~w(max_rate_deg_s max_accel_deg_s2 settling_s initial pointing_configurations)a
                 ),
               do: raise(ArgumentError, "invalid per-asset attitude options")

        rate = Input.positive!(a.max_rate_deg_s, "max_rate_deg_s")

        if 2 * derivative * rate >= 180,
          do:
            raise(ArgumentError, "derivative interval cannot resolve the declared rate envelope")

        configs =
          Map.new(a.pointing_configurations, fn {model, config} ->
            unless is_atom(model) and is_map(config),
              do:
                raise(ArgumentError, "pointing configurations map trusted model modules to maps")

            {model, JsonSafety.normalize_input!(config, "pointing configuration")}
          end)

        initial =
          case a.initial do
            :unknown ->
              :unknown

            %{
              epoch: %Epoch{} = epoch,
              frame: %Frame{} = frame,
              quaternion: q,
              angular_velocity_deg_s: omega
            } = initial
            when map_size(initial) == 4 ->
              Input.number!(epoch.seconds_since_j2000, "initial attitude epoch", -1.0e12, 1.0e12)

              unless epoch.scale in [:utc, :tai, :tdb],
                do: raise(ArgumentError, "explicit initial attitude time scale required")

              %{
                epoch: epoch,
                frame: frame,
                quaternion: Quaternion.new!(q),
                angular_velocity_deg_s: Input.vector!(omega, "initial angular velocity")
              }

            _ ->
              raise ArgumentError, "initial attitude must be explicit or :unknown"
          end

        normalized = %{
          max_rate_deg_s: rate,
          max_accel_deg_s2: Input.positive!(a.max_accel_deg_s2, "max_accel_deg_s2"),
          settling_s: Input.number!(a.settling_s, "settling_s", 0, 1.0e9),
          initial: initial,
          pointing_configurations: configs
        }

        normalized =
          if Map.has_key?(a, :rigid_body),
            do:
              Map.put(
                normalized,
                :rigid_body,
                OrbitalDynamics.MissionAnalysis.Attitude.RigidBody.new!(a.rigid_body)
              ),
            else: normalized

        normalized =
          if a[:continuation_request_id],
            do:
              Map.put(normalized, :continuation_request_id, Input.id!(a.continuation_request_id)),
            else: normalized

        normalized =
          if a[:saved_motion],
            do:
              Map.put(
                normalized,
                :saved_motion,
                OrbitalDynamics.MissionAnalysis.Attitude.SavedMotion.validate!(a.saved_motion)
              ),
            else: normalized

        {id, normalized}
      end)

    %__MODULE__{
      assets: assets,
      path_constraints: path,
      resources: resources,
      horizon: OrbitalDynamics.MissionAnalysis.Attitude.Horizon.new!(Keyword.get(opts, :horizon)),
      profile_step_s: Input.positive!(opts[:profile_step_s], "profile_step_s"),
      derivative_step_s: derivative,
      search_step_s: Input.positive!(opts[:search_step_s], "search_step_s"),
      max_candidate_starts: integer!(opts[:max_candidate_starts], "max_candidate_starts", 1024),
      max_evaluations: integer!(opts[:max_evaluations], "max_evaluations", 1_000_000)
    }
  end

  def validate!(%__MODULE__{} = p),
    do:
      new!(p.assets,
        profile_step_s: p.profile_step_s,
        derivative_step_s: p.derivative_step_s,
        search_step_s: p.search_step_s,
        max_candidate_starts: p.max_candidate_starts,
        max_evaluations: p.max_evaluations,
        path_constraints: p.path_constraints,
        horizon: p.horizon,
        resources: p.resources
      )

  defp integer!(x, label, upper) do
    unless is_integer(x) and x in 1..upper,
      do: raise(ArgumentError, "#{label} must be 1..#{upper}")

    x
  end

  def describe(p) do
    %{
      "resources" => OrbitalDynamics.MissionAnalysis.Resource.Policy.describe(p.resources),
      "horizon" => OrbitalDynamics.MissionAnalysis.Attitude.Horizon.describe(p.horizon),
      "model" => "three_axis_sampled_kinematics_and_constructive_transitions",
      "quaternion_convention" => "Hamilton_wxyz_active_body_to_inertial",
      "angular_velocity_convention" => "inertial_components_deg_s",
      "angular_acceleration_convention" => "inertial_components_deg_s2",
      "profile_step_s" => p.profile_step_s,
      "derivative_step_s" => p.derivative_step_s,
      "search_step_s" => p.search_step_s,
      "max_candidate_starts_per_opportunity" => p.max_candidate_starts,
      "max_evaluations" => p.max_evaluations,
      "path_constraints" =>
        if(p.path_constraints,
          do: OrbitalDynamics.MissionAnalysis.Path.Policy.describe(p.path_constraints),
          else: :null
        ),
      "assets" =>
        Map.new(p.assets, fn {id, a} ->
          initial =
            case a.initial do
              :unknown ->
                %{"status" => "unknown"}

              s ->
                %{
                  "status" => "declared",
                  "epoch_s" => s.epoch.seconds_since_j2000,
                  "time_scale" => Atom.to_string(s.epoch.scale),
                  "frame" => Atom.to_string(s.frame.name),
                  "frame_center" => Atom.to_string(s.frame.center),
                  "frame_orientation" => Atom.to_string(s.frame.orientation),
                  "quaternion_wxyz" => Tuple.to_list(s.quaternion),
                  "angular_velocity_inertial_deg_s" => Tuple.to_list(s.angular_velocity_deg_s)
                }
            end

          described = %{
            "max_rate_deg_s" => a.max_rate_deg_s,
            "max_accel_deg_s2" => a.max_accel_deg_s2,
            "settling_s" => a.settling_s,
            "initial" => initial,
            "pointing_configurations" =>
              Map.new(a.pointing_configurations, fn {m, c} -> {Atom.to_string(m), c} end)
          }

          described =
            if a[:rigid_body],
              do:
                Map.put(
                  described,
                  "rigid_body",
                  OrbitalDynamics.MissionAnalysis.Attitude.RigidBody.describe(a.rigid_body)
                ),
              else: described

          described =
            if a[:continuation_request_id],
              do: Map.put(described, "continuation_request_id", a.continuation_request_id),
              else: described

          {id, described}
        end),
      "limits" => [
        "declared initial state and limits, not telemetry or achieved attitude",
        "sampled quaternion finite differences; internal violations and angular aliasing can remain",
        "constructed brake/hold/shortest-axis slew/settle/ramp transitions; not globally minimum time",
        "inertial angular velocity convention; unlimited jerk and no actuator torque, momentum, flexible-body or disturbance model",
        "discrete bounded start search; rejection is relative to tested starts, not proof of no feasible schedule",
        "settling is a declared rest dwell before ramping into tracking; no settling dynamics model",
        "intermediate transition paths are not screened for Sun/keep-out, ground illumination, occultation or communications constraints"
      ]
    }
    |> then(fn d ->
      if Enum.any?(p.assets, fn {_, a} -> Map.has_key?(a, :rigid_body) end),
        do:
          Map.update!(d, "limits", fn xs ->
            Enum.reject(
              xs,
              &String.starts_with?(&1, "inertial angular velocity convention; unlimited jerk")
            ) ++
              [
                "rigid-body torque checked only for configured assets; no wheel momentum, actuator allocation, external disturbances, flexible-body or jerk model"
              ]
          end),
        else: d
    end)
    |> then(fn d ->
      if p.resources &&
           Enum.any?(p.resources.assets, fn {_, models} ->
             Enum.any?(
               models,
               &(&1.module == OrbitalDynamics.MissionAnalysis.Resource.ReactionWheels)
             )
           end) do
        Map.update!(d, "limits", fn xs ->
          Enum.reject(xs, &String.starts_with?(&1, "rigid-body torque checked only")) ++
            [
              "configured three-wheel arrays additionally check rotor momentum, motor torque and declared disturbance/unloading torque at resource samples; no redundant allocation, flexible body, jerk or real unloading-mechanism validation"
            ]
        end)
      else
        d
      end
    end)
    |> then(fn d ->
      if p.path_constraints,
        do:
          Map.update!(d, "limits", fn limits ->
            Enum.reject(
              limits,
              &String.starts_with?(&1, "intermediate transition paths are not screened")
            ) ++
              [
                "only declared path rules at tested epochs are checked; mode switches remain declared instantaneous assumptions"
              ]
          end),
        else: d
    end)
  end
end
