defmodule OrbitalDynamics.EventDetectors.Geometry do
  @moduledoc "Opt-in event functions for spherical ground geometry, circular FOV and relative spacecraft geometry."
  alias OrbitalDynamics.Vector3, as: V
  alias OrbitalDynamics.{Frame, Target}
  alias OrbitalDynamics.EventSearch.{Function, Source}
  alias OrbitalDynamics.MissionAnalysis.{Input, SphericalScene}
  alias OrbitalDynamics.MissionAnalysis.Attitude.{Pointing, Quaternion}

  def access(id, %SphericalScene{} = scene, %Target{} = target, min_elevation_deg, opts) do
    Input.number!(min_elevation_deg, "minimum elevation", -90, 90)

    Function.new!(
      id,
      fn state ->
        case SphericalScene.at(scene, state, target) do
          {:ok, g} ->
            {:ok, g.elevation_deg - min_elevation_deg, nil,
             %{"elevation_deg" => g.elevation_deg, "slant_range_km" => g.slant_range_km}}

          other ->
            environment_result(other)
        end
      end,
      [units: "deg", assumptions: SphericalScene.describe(scene, target)] ++
        Keyword.put_new(opts, :condition, :nonnegative)
    )
  end

  def ground_night(id, %SphericalScene{} = scene, %Target{} = target, max_sun_elevation_deg, opts) do
    Input.number!(max_sun_elevation_deg, "ground lighting threshold", -90, 90)

    Function.new!(
      id,
      fn state ->
        case SphericalScene.at(scene, state, target) do
          {:ok, g} ->
            {:ok, max_sun_elevation_deg - g.target_sun_elevation_deg, nil,
             %{"target_sun_elevation_deg" => g.target_sun_elevation_deg}}

          other ->
            environment_result(other)
        end
      end,
      [units: "deg", assumptions: SphericalScene.describe(scene, target)] ++
        Keyword.put_new(opts, :condition, :nonnegative)
    )
  end

  def latitude(id, %SphericalScene{} = scene, latitude_deg, opts) do
    Input.number!(latitude_deg, "latitude", -90, 90)
    sine = :math.sin(latitude_deg * :math.pi() / 180)

    Function.new!(
      id,
      fn state ->
        with {:ok, _env} <- SphericalScene.environment_at(scene, state) do
          r = V.norm(state.position_km)
          {_, _, z} = state.position_km
          {_, _, vz} = state.velocity_km_s
          rate = vz / r - z * V.dot(state.position_km, state.velocity_km_s) / (r * r * r)

          {:ok, z / r - sine, rate,
           %{"latitude_deg" => :math.asin(max(-1.0, min(1.0, z / r))) * 180 / :math.pi()}}
        else
          other -> environment_result(other)
        end
      end,
      [units: "1", assumptions: scene_description(scene)] ++ opts
    )
  end

  def longitude(id, %SphericalScene{} = scene, longitude_deg, opts) do
    Input.number!(longitude_deg, "longitude", -180, 180)
    angle = longitude_deg * :math.pi() / 180

    Function.new!(
      id,
      fn state ->
        with {:ok, env} <- SphericalScene.environment_at(scene, state) do
          {x, y, _} = fixed(state.position_km, env.rotation_angle_rad)
          rho = :math.sqrt(x * x + y * y)

          if rho == 0,
            do: {:unknown, :longitude_undefined_at_pole},
            else:
              {:ok, (y * :math.cos(angle) - x * :math.sin(angle)) / rho, nil,
               %{"forward_half_plane" => x * :math.cos(angle) + y * :math.sin(angle) > 0}}
        else
          other -> environment_result(other)
        end
      end,
      [
        units: "1",
        root_filter: fn m -> m["forward_half_plane"] end,
        assumptions: scene_description(scene)
      ] ++ opts
    )
  end

  def region(id, %SphericalScene{} = scene, latitude_deg, longitude_deg, angular_radius_deg, opts) do
    Input.number!(latitude_deg, "region latitude", -90, 90)
    Input.number!(longitude_deg, "region longitude", -180, 180)
    Input.number!(angular_radius_deg, "region angular radius", 0.000001, 180)
    lat = latitude_deg * :math.pi() / 180
    lon = longitude_deg * :math.pi() / 180
    center = {:math.cos(lat) * :math.cos(lon), :math.cos(lat) * :math.sin(lon), :math.sin(lat)}
    limit = :math.cos(angular_radius_deg * :math.pi() / 180)

    Function.new!(
      id,
      fn state ->
        with {:ok, env} <- SphericalScene.environment_at(scene, state) do
          unit =
            V.scale(
              fixed(state.position_km, env.rotation_angle_rad),
              1 / V.norm(state.position_km)
            )

          {:ok, V.dot(unit, center) - limit, nil, %{}}
        else
          other -> environment_result(other)
        end
      end,
      [
        units: "1",
        assumptions:
          Map.merge(scene_description(scene), %{
            "region_model" => "geocentric_spherical_cap",
            "angular_radius_deg" => angular_radius_deg
          })
      ] ++ Keyword.put_new(opts, :condition, :nonnegative)
    )
  end

  def relative_distance(id, %Source{} = other, threshold_km, opts) do
    Input.number!(threshold_km, "relative distance", 0, 1.0e15)

    Function.new!(
      id,
      fn state ->
        with {:ok, b} <- secondary(other, state) do
          delta = V.subtract(b.position_km, state.position_km)
          distance = V.norm(delta)

          rate =
            if distance == 0,
              do: nil,
              else: V.dot(delta, V.subtract(b.velocity_km_s, state.velocity_km_s)) / distance

          {:ok, distance - threshold_km, rate, %{"distance_km" => distance}}
        end
      end,
      [
        units: "km",
        assumptions: %{
          "secondary" => Source.describe(other),
          "threshold_km" => threshold_km,
          "geometry" => "simultaneous_geometric_relative_distance"
        }
      ] ++ opts
    )
  end

  def closest_approach(id, %Source{} = other, opts) do
    Function.new!(
      id,
      fn state ->
        with {:ok, b} <- secondary(other, state) do
          r = V.subtract(b.position_km, state.position_km)
          v = V.subtract(b.velocity_km_s, state.velocity_km_s)
          {:ok, V.dot(r, v), nil, %{"distance_km" => V.norm(r)}}
        end
      end,
      [
        units: "km2/s",
        labels: %{increasing: "closest_approach", decreasing: "farthest_separation"},
        assumptions: %{
          "secondary" => Source.describe(other),
          "limits" => "geometric closest approach only; no covariance or collision-risk model"
        }
      ] ++ Keyword.put_new(opts, :direction, :increasing)
    )
  end

  def intersatellite_visibility(id, %Source{} = other, body_radius_km, opts) do
    Input.positive!(body_radius_km, "occulting radius")

    Function.new!(
      id,
      fn state ->
        with {:ok, b} <- secondary(other, state) do
          a = state.position_km
          d = V.subtract(b.position_km, a)
          length2 = V.dot(d, d)

          cond do
            V.norm(a) <= body_radius_km or V.norm(b.position_km) <= body_radius_km ->
              {:error, :link_endpoint_inside_occulting_body}

            length2 == 0 ->
              {:unknown, :coincident_link_endpoints}

            true ->
              u = max(0.0, min(1.0, -V.dot(a, d) / length2))
              clearance = V.norm(V.add(a, V.scale(d, u))) - body_radius_km
              {:ok, clearance, nil, %{"body_limb_clearance_km" => clearance}}
          end
        end
      end,
      [
        units: "km",
        assumptions: %{
          "secondary" => Source.describe(other),
          "body_radius_km" => body_radius_km,
          "geometry" => "segment_occultation_by_sphere_at_common_frame_origin"
        }
      ] ++ Keyword.put_new(opts, :condition, :nonnegative)
    )
  end

  def field_of_view(id, %Source{} = target, pose_at, boresight_body, half_angle_deg, opts)
      when is_function(pose_at, 1) do
    axis = Input.unit!(boresight_body, "FOV body boresight")
    Input.number!(half_angle_deg, "FOV half angle", 0.000001, 180)
    limit = :math.cos(half_angle_deg * :math.pi() / 180)

    Function.new!(
      id,
      fn state ->
        with {:ok, t} <- secondary(target, state),
             {:ok, %Pointing{} = pose} <- pose_at.(state.epoch) do
          unless Frame.compatible?(pose.frame, state.frame),
            do: raise(ArgumentError, "FOV pointing frame mismatch")

          ray = V.subtract(t.position_km, state.position_km)
          distance = V.norm(ray)

          if distance == 0,
            do: {:unknown, :FOV_target_coincident},
            else:
              {:ok,
               V.dot(Quaternion.rotate(pose.quaternion, axis), V.scale(ray, 1 / distance)) - limit,
               nil, %{}}
        end
      end,
      [
        units: "1",
        assumptions: %{
          "target" => Source.describe(target),
          "geometry" => "circular_cone_single_target_center",
          "half_angle_deg" => half_angle_deg,
          "limits" => "no target extent, lens distortion or body occultation inferred"
        }
      ] ++ Keyword.put_new(opts, :condition, :nonnegative)
    )
  end

  def angular_separation(id, %Source{} = a, %Source{} = b, threshold_deg, opts) do
    Input.number!(threshold_deg, "angular separation", 0, 180)

    Function.new!(
      id,
      fn state ->
        with {:ok, a} <- secondary(a, state), {:ok, b} <- secondary(b, state) do
          u = V.subtract(a.position_km, state.position_km)
          v = V.subtract(b.position_km, state.position_km)

          if V.norm(u) == 0 or V.norm(v) == 0,
            do: {:unknown, :angular_direction_undefined},
            else:
              {:ok,
               :math.atan2(V.norm(V.cross(u, v)), V.dot(u, v)) * 180 / :math.pi() - threshold_deg,
               nil, %{}}
        end
      end,
      [
        units: "deg",
        assumptions: %{
          "a" => Source.describe(a),
          "b" => Source.describe(b),
          "geometry" => "simultaneous_geometric_angular_separation"
        }
      ] ++ opts
    )
  end

  def cylindrical_shadow(id, %SphericalScene{} = scene, opts) do
    Function.new!(
      id,
      fn state ->
        with {:ok, env} <- SphericalScene.environment_at(scene, state) do
          axial = V.dot(state.position_km, env.sun_direction)
          perpendicular = V.norm(V.subtract(state.position_km, V.scale(env.sun_direction, axial)))
          margin = max(axial, perpendicular - scene.body.equatorial_radius_km)
          {:ok, margin, nil, %{"spacecraft_sunlit" => margin >= 0}}
        else
          other -> environment_result(other)
        end
      end,
      [
        units: "km",
        assumptions:
          Map.merge(scene_description(scene), %{
            "geometry" => "cylindrical_point_sun_shadow",
            "limits" => "binary parallel-ray shadow; no finite-source penumbra or antumbra"
          })
      ] ++ Keyword.put_new(opts, :condition, :nonpositive)
    )
  end

  def limb_clearance(id, pose_at, axis_body, body_radius_km, opts) when is_function(pose_at, 1) do
    axis = Input.unit!(axis_body, "limb body axis")
    Input.positive!(body_radius_km, "body limb radius")

    Function.new!(
      id,
      fn state ->
        radius = V.norm(state.position_km)

        if radius <= body_radius_km do
          {:error, :observer_inside_limb_body}
        else
          with {:ok, %Pointing{} = pose} <- pose_at.(state.epoch) do
            unless Frame.compatible?(pose.frame, state.frame),
              do: raise(ArgumentError, "limb pointing frame mismatch")

            ray = Quaternion.rotate(pose.quaternion, axis)
            nadir = V.scale(state.position_km, -1 / radius)
            separation = :math.atan2(V.norm(V.cross(ray, nadir)), V.dot(ray, nadir))
            angular_radius = :math.asin(body_radius_km / radius)

            {:ok, separation - angular_radius, nil,
             %{
               "axis_body_separation_rad" => separation,
               "body_angular_radius_rad" => angular_radius
             }}
          end
        end
      end,
      [
        units: "rad",
        assumptions: %{
          "geometry" => "body_axis_clearance_from_sphere_at_frame_origin",
          "body_radius_km" => body_radius_km,
          "limits" =>
            "geometric tangent limb; no atmosphere, terrain or extended target footprint"
        }
      ] ++ Keyword.put_new(opts, :condition, :nonnegative)
    )
  end

  def beta_angle(id, %Source{} = sun, threshold_deg, opts) do
    Input.number!(threshold_deg, "beta angle threshold", -90, 90)

    Function.new!(
      id,
      fn state ->
        if state.frame.orientation == :body_fixed,
          do: raise(ArgumentError, "beta angle requires inertial axes")

        with {:ok, s} <- secondary(sun, state) do
          h = V.cross(state.position_km, state.velocity_km_s)
          ray = V.subtract(s.position_km, state.position_km)
          length = V.norm(h) * V.norm(ray)

          if length == 0,
            do: {:unknown, :beta_angle_undefined},
            else:
              {:ok,
               :math.asin(max(-1.0, min(1.0, V.dot(h, ray) / length))) * 180 / :math.pi() -
                 threshold_deg, nil, %{}}
        end
      end,
      [
        units: "deg",
        assumptions: %{
          "sun" => Source.describe(sun),
          "geometry" => "instantaneous_orbital_plane_sun_beta_angle"
        }
      ] ++ opts
    )
  end

  def secondary(source, state) do
    unless Frame.compatible?(source.frame, state.frame) and
             source.start.scale == state.epoch.scale,
           do:
             raise(
               ArgumentError,
               "event geometry sources require a common origin, axes and scale"
             )

    Source.at(source, state.epoch.seconds_since_j2000)
  end

  defp fixed({x, y, z}, angle),
    do:
      {x * :math.cos(angle) + y * :math.sin(angle), -x * :math.sin(angle) + y * :math.cos(angle),
       z}

  defp scene_description(scene),
    do: %{
      "model" => "spherical_geocentric_z_axis_rotation",
      "body" => Atom.to_string(scene.body.name),
      "radius_km" => scene.body.equatorial_radius_km,
      "environment" => scene.environment_provider.describe(scene.environment_config)
    }

  defp environment_result({:error, :environment_outside_coverage}),
    do: {:unknown, :event_environment_outside_coverage}

  defp environment_result({:error, {:outside_coverage, _}}),
    do: {:unknown, :event_environment_outside_coverage}

  defp environment_result(other), do: other
end
