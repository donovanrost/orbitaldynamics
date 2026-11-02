defmodule OrbitalDynamics.MissionAnalysis.SphericalScene do
  @moduledoc """
  Shared spherical-body surface geometry for illumination and imaging models.

  The central body, inertial frame, time scale, and environment provider are
  explicit. Target coordinates are spherical/geocentric latitude and longitude.
  Solar directions are treated as parallel rays; eclipse is a cylindrical
  point-Sun approximation. No terrain, refraction, ellipsoid, or penumbra model.
  """
  alias OrbitalDynamics.{CentralBody, Frame, StateVector, Target, Vector3}
  alias OrbitalDynamics.MissionAnalysis.Input

  @enforce_keys [:body, :frame, :time_scale, :environment_provider, :environment_config]
  defstruct @enforce_keys

  def new!(%CentralBody{} = body, %Frame{} = frame, scale, {provider, config}) do
    Input.positive!(body.equatorial_radius_km, "body radius")

    unless frame.center == body.name and frame.orientation != :body_fixed and
             scale in [:tdb, :tai, :utc],
           do:
             raise(
               ArgumentError,
               "scene requires a matching inertial body frame and explicit time scale"
             )

    unless Code.ensure_loaded?(provider) and function_exported?(provider, :at, 2) and
             function_exported?(provider, :describe, 1),
           do: raise(ArgumentError, "scene environment must implement at/2 and describe/1")

    %__MODULE__{
      body: body,
      frame: frame,
      time_scale: scale,
      environment_provider: provider,
      environment_config: config
    }
  end

  @doc "Validates a state and returns normalized Sun and body-rotation inputs without a target."
  def environment_at(%__MODULE__{} = scene, %StateVector{} = state) do
    cond do
      not Frame.compatible?(state.frame, scene.frame) ->
        {:error, :scene_frame_mismatch}

      state.epoch.scale != scene.time_scale ->
        {:error, :scene_time_scale_mismatch}

      Vector3.norm(state.position_km) <= scene.body.equatorial_radius_km ->
        {:error, :spacecraft_inside_reference_body}

      true ->
        with {:ok, environment} <-
               scene.environment_provider.at(state.epoch, scene.environment_config) do
          unless Frame.compatible?(environment.frame, scene.frame) and
                   environment.epoch == state.epoch,
                 do:
                   raise(ArgumentError, "environment frame/epoch does not match requested scene")

          {:ok,
           %{
             environment
             | sun_direction: Input.unit!(environment.sun_direction, "environment sun direction"),
               rotation_angle_rad:
                 Input.number!(
                   environment.rotation_angle_rad,
                   "environment rotation angle",
                   -1.0e15,
                   1.0e15
                 )
           }}
        end
    end
  end

  def at(%__MODULE__{} = scene, %StateVector{} = state, %Target{} = target) do
    cond do
      not Frame.compatible?(state.frame, scene.frame) ->
        {:error, :scene_frame_mismatch}

      state.epoch.scale != scene.time_scale ->
        {:error, :scene_time_scale_mismatch}

      Vector3.norm(state.position_km) <= scene.body.equatorial_radius_km ->
        {:error, :spacecraft_inside_reference_body}

      true ->
        with {:ok, environment} <-
               scene.environment_provider.at(state.epoch, scene.environment_config) do
          unless Frame.compatible?(environment.frame, scene.frame) and
                   environment.epoch == state.epoch,
                 do:
                   raise(ArgumentError, "environment frame/epoch does not match requested scene")

          sun = Input.unit!(environment.sun_direction, "environment sun direction")

          rotation =
            Input.number!(
              environment.rotation_angle_rad,
              "environment rotation angle",
              -1.0e15,
              1.0e15
            )

          phi = radians(target.latitude_deg)
          lambda = radians(target.longitude_deg) + rotation

          up =
            {:math.cos(phi) * :math.cos(lambda), :math.cos(phi) * :math.sin(lambda),
             :math.sin(phi)}

          ground = Vector3.scale(up, scene.body.equatorial_radius_km + target.altitude_km)
          to_spacecraft = Vector3.subtract(state.position_km, ground)
          range = Vector3.norm(to_spacecraft)
          if range <= 0, do: raise(ArgumentError, "zero target slant range")
          elevation = degrees(:math.asin(clamp(Vector3.dot(to_spacecraft, up) / range)))
          direction = Vector3.scale(to_spacecraft, -1.0 / range)
          nadir = Input.unit!(Vector3.scale(state.position_km, -1), "nadir")
          axial = Vector3.dot(state.position_km, sun)
          perpendicular = Vector3.subtract(state.position_km, Vector3.scale(sun, axial))

          {:ok,
           %{
             elevation_deg: elevation,
             slant_range_km: range,
             target_direction: direction,
             target_sun_elevation_deg: degrees(:math.asin(clamp(Vector3.dot(up, sun)))),
             spacecraft_sunlit?:
               not (axial < 0 and Vector3.norm(perpendicular) < scene.body.equatorial_radius_km),
             off_nadir_deg: degrees(:math.acos(clamp(Vector3.dot(direction, nadir)))),
             sun_direction: sun
           }}
        end
    end
  end

  def describe(scene, target) do
    Target.new!(target.id, target.latitude_deg, target.longitude_deg,
      altitude_km: target.altitude_km,
      minimum_elevation_deg: target.minimum_elevation_deg
    )

    Input.number!(target.altitude_km, "target altitude", 0, 1.0e6)

    %{
      "geometry_model" => "spherical_rotating_body_parallel_sun_cylindrical_shadow",
      "body" => Atom.to_string(scene.body.name),
      "radius_km" => scene.body.equatorial_radius_km,
      "frame" => Atom.to_string(scene.frame.name),
      "frame_orientation" => Atom.to_string(scene.frame.orientation),
      "time_scale" => Atom.to_string(scene.time_scale),
      "target" => %{
        "id" => to_string(target.id),
        "latitude_deg" => target.latitude_deg,
        "longitude_deg" => target.longitude_deg,
        "altitude_km" => target.altitude_km,
        "minimum_elevation_deg" => target.minimum_elevation_deg
      },
      "environment" => scene.environment_provider.describe(scene.environment_config),
      "known_limits" => [
        "spherical surface",
        "no terrain or refraction",
        "parallel solar rays",
        "no penumbra",
        "required pointing only; no achieved attitude prediction"
      ]
    }
  end

  def tracking_rate(nil, _direction, _epoch_s, _previous_epoch_s), do: nil

  def tracking_rate(previous_direction, direction, epoch_s, previous_epoch_s) do
    # atan2 is well-conditioned for small tracking angles as well as antipodes.
    angle =
      :math.atan2(
        Vector3.norm(Vector3.cross(previous_direction, direction)),
        Vector3.dot(previous_direction, direction)
      )

    degrees(angle) / (epoch_s - previous_epoch_s)
  end

  def metrics(scene) do
    %{
      "elevation_deg" => scene.elevation_deg,
      "slant_range_km" => scene.slant_range_km,
      "target_sun_elevation_deg" => scene.target_sun_elevation_deg,
      "spacecraft_sunlit" => scene.spacecraft_sunlit?,
      "off_nadir_deg" => scene.off_nadir_deg,
      "target_direction" => Tuple.to_list(scene.target_direction)
    }
  end

  def radians(degrees), do: degrees * :math.pi() / 180.0
  def degrees(radians), do: radians * 180.0 / :math.pi()
  def clamp(value), do: max(-1.0, min(1.0, value))
end
