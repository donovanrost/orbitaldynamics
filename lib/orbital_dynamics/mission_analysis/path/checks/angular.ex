defmodule OrbitalDynamics.MissionAnalysis.Path.Checks.Angular do
  @moduledoc "Sun, spherical Earth/body-limb and fixed inertial angular envelopes for a declared body axis."
  @behaviour OrbitalDynamics.MissionAnalysis.Path.Check
  alias OrbitalDynamics.MissionAnalysis.Path.CheckResult
  alias OrbitalDynamics.Vector3, as: V
  alias OrbitalDynamics.MissionAnalysis.{Input, SphericalScene}
  alias OrbitalDynamics.MissionAnalysis.Models.SurfaceSupport, as: S
  alias OrbitalDynamics.MissionAnalysis.Attitude.Quaternion, as: Q
  alias OrbitalDynamics.MissionAnalysis.Path.Result

  def prepare(asset, context, config) do
    S.fields!(
      config,
      ~w(body_axis reference minimum_angle_deg maximum_angle_deg),
      "angular path rule"
    )

    axis = Input.unit!(config["body_axis"], "body axis")
    reference = config["reference"]
    kind = reference["kind"]

    direction =
      case kind do
        "inertial" ->
          S.fields!(reference, ~w(kind direction), "inertial reference")
          Input.unit!(reference["direction"], "inertial direction")

        k when k in ["sun", "body_limb"] ->
          S.fields!(reference, ~w(kind), "environment reference")

          unless match?(%SphericalScene{}, context),
            do:
              raise(
                ArgumentError,
                "environment angular rules require an explicit spherical scene"
              )

          nil

        _ ->
          raise ArgumentError, "unknown angular reference"
      end

    low = Input.number!(config["minimum_angle_deg"], "minimum_angle_deg", -180, 180)
    high = Input.number!(config["maximum_angle_deg"], "maximum_angle_deg", -180, 180)
    if low > high, do: raise(ArgumentError, "angular envelope minimum exceeds maximum")
    first = hd(asset.trajectory.states)

    {:ok, %{axis: axis, kind: kind, direction: direction, scene: context, low: low, high: high},
     %{
       "configuration" => config,
       "reference_frame" => Atom.to_string(first.frame.name),
       "limits" => [
         "spherical apparent limb, no atmosphere/refraction/terrain",
         "declared body axis and angular thresholds, not spacecraft requirements"
       ]
     }}
  end

  def evaluate(state, pointing, _mode, s) do
    unless OrbitalDynamics.Frame.compatible?(state.frame, pointing.frame),
      do: raise(ArgumentError, "path orientation frame must match state frame")

    with {:ok, reference, offset} <- reference(state, s) do
      axis = Q.rotate(pointing.quaternion, s.axis)

      angle =
        SphericalScene.degrees(
          :math.atan2(V.norm(V.cross(axis, reference)), V.dot(axis, reference))
        ) - offset

      checks = [
        %CheckResult{
          id: "minimum_angle",
          status:
            if(angle >= s.low) do
              :supported
            else
              :violated
            end,
          margin: angle - s.low,
          margin_unit: "deg"
        },
        %CheckResult{
          id: "maximum_angle",
          status:
            if(angle <= s.high) do
              :supported
            else
              :violated
            end,
          margin: s.high - angle,
          margin_unit: "deg"
        }
      ]

      {:ok, Result.build(checks, %{"angle_deg" => angle, "reference" => s.kind})}
    end
  end

  defp reference(_state, %{kind: "inertial"} = s), do: {:ok, s.direction, 0.0}

  defp reference(state, s) do
    with {:ok, e} <- SphericalScene.environment_at(s.scene, state) do
      if s.kind == "sun",
        do: {:ok, e.sun_direction, 0.0},
        else:
          {:ok, Input.unit!(V.scale(state.position_km, -1), "nadir"),
           SphericalScene.degrees(
             :math.asin(s.scene.body.equatorial_radius_km / V.norm(state.position_km))
           )}
    end
  end
end
