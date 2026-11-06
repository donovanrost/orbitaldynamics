defmodule OrbitalDynamics.MissionAnalysis.Path.Checks.ReflectedBeam do
  @moduledoc "Ideal reflected solar cone and conservative spherical exclusion-cap bounds; no delivered-flux prediction."
  @behaviour OrbitalDynamics.MissionAnalysis.Path.Check
  alias OrbitalDynamics.MissionAnalysis.Path.CheckResult
  alias OrbitalDynamics.Vector3, as: V
  alias OrbitalDynamics.MissionAnalysis.{Input, SphericalScene}
  alias OrbitalDynamics.MissionAnalysis.Models.SurfaceSupport, as: S
  alias OrbitalDynamics.MissionAnalysis.Attitude.Quaternion, as: Q
  alias OrbitalDynamics.MissionAnalysis.Path.Result

  @guard_deg 1.0e-8

  def prepare(_asset, %SphericalScene{} = scene, config) do
    S.fields!(
      config,
      ~w(mirror_normal_body back_face_behavior solar_angular_radius_deg beam_padding_deg exclusion_regions),
      "reflected-beam rule"
    )

    normal = Input.unit!(config["mirror_normal_body"], "mirror normal")

    back = config["back_face_behavior"]

    unless back in ~w(unknown non_reflecting_by_assumption two_sided_reflecting_by_assumption),
      do: raise(ArgumentError, "explicit back-face behavior required")

    solar =
      Input.number!(config["solar_angular_radius_deg"], "solar_angular_radius_deg", 0.000001, 10)

    padding = Input.number!(config["beam_padding_deg"], "beam_padding_deg", 0, 10)
    regions = config["exclusion_regions"]

    unless is_list(regions) and length(regions) in 1..100,
      do: raise(ArgumentError, "1..100 exclusion regions required")

    radius = scene.body.equatorial_radius_km

    regions =
      Enum.map(regions, fn r ->
        S.fields!(r, ~w(id latitude_deg longitude_deg radius_km), "exclusion region")

        %{
          id: Input.id!(r["id"]),
          lat: Input.number!(r["latitude_deg"], "latitude_deg", -90, 90),
          lon: Input.number!(r["longitude_deg"], "longitude_deg", -180, 180),
          radius: Input.number!(r["radius_km"], "radius_km", 0, :math.pi() * radius)
        }
      end)

    if length(Enum.uniq_by(regions, & &1.id)) != length(regions),
      do: raise(ArgumentError, "duplicate exclusion region IDs")

    {:ok,
     %{
       scene: scene,
       normal: normal,
       back: back,
       solar: solar,
       cone: solar + padding,
       regions: regions
     },
     %{
       "configuration" => config,
       "environment" => scene.environment_provider.describe(scene.environment_config),
       "body_radius_km" => radius,
       "numerical_guard_deg" => @guard_deg,
       "model" => "parallel_solar_cone_flat_mirror_spherical_cap_enclosing_ball",
       "limits" => [
         "possible overlap is a conservative guard violation, not proof of actual illumination",
         "ideal flat mirror and declared angular padding; no aperture/deformation/scatter or irradiance threshold model",
         "finite solar disk used for full-occultation test; partial occultation retains the whole cone",
         "blocked/non-reflecting modes and back-face behavior are declared assumptions, not verified hardware behavior"
       ]
     }}
  end

  def prepare(_, _, _), do: {:error, :reflected_beam_requires_spherical_scene}

  def evaluate(state, pointing, mode, s) do
    unless OrbitalDynamics.Frame.compatible?(state.frame, pointing.frame),
      do: raise(ArgumentError, "path orientation frame must match state frame")

    case Map.get(mode["parameters"], "optical_behavior", "unknown") do
      behavior when behavior not in ["reflecting", "blocked_by_assumption"] ->
        {:ok,
         Result.build(
           [
             %CheckResult{
               id: "optical_mode",
               status: :unknown,
               details: %{"reason" => "mode_behavior_not_known"}
             }
           ],
           %{"mode" => mode}
         )}

      "blocked_by_assumption" ->
        {:ok,
         Result.build(
           [
             %CheckResult{
               id: "optical_mode",
               status: :supported,
               details: %{"reason" => "blocked_by_explicit_assumption"}
             }
           ],
           %{"mode" => mode}
         )}

      "reflecting" ->
        reflecting(state, pointing, mode, s)
    end
  end

  defp reflecting(state, pointing, mode, s) do
    with {:ok, e} <- SphericalScene.environment_at(s.scene, state) do
      r = state.position_km
      radius = s.scene.body.equatorial_radius_km
      nadir = Input.unit!(V.scale(r, -1), "nadir")
      limb = SphericalScene.degrees(:math.asin(radius / V.norm(r)))
      sun_earth = angle(e.sun_direction, nadir)
      normal = Q.rotate(pointing.quaternion, s.normal)
      cosine = V.dot(normal, e.sun_direction)

      cond do
        sun_earth + s.solar < limb - @guard_deg ->
          empty("solar_disk_fully_occulted", mode)

        cosine <= :math.sin(SphericalScene.radians(s.solar + @guard_deg)) and s.back == "unknown" ->
          {:ok,
           Result.build(
             [
               %CheckResult{
                 id: "back_face",
                 status: :unknown,
                 details: %{"reason" => "back_face_optics_not_known"}
               }
             ],
             %{"mode" => mode}
           )}

        cosine <= -:math.sin(SphericalScene.radians(s.solar + @guard_deg)) and
            s.back == "non_reflecting_by_assumption" ->
          empty("non_reflecting_back_face_by_assumption", mode)

        true ->
          beam =
            Input.unit!(
              V.add(V.scale(e.sun_direction, -1), V.scale(normal, 2 * cosine)),
              "reflected ray"
            )

          hit = ray_hit(r, beam, radius)
          misses = angle(beam, nadir) > limb + s.cone + @guard_deg

          checks =
            Enum.map(s.regions, fn region ->
              region_check(r, beam, radius, e.rotation_angle_rad, s.cone, misses, region)
            end)

          location =
            case hit do
              nil ->
                :null

              p ->
                u = Input.unit!(p, "ray hit")
                {x, y, z} = u

                %{
                  "latitude_deg" => SphericalScene.degrees(:math.asin(SphericalScene.clamp(z))),
                  "longitude_deg" =>
                    wrap(SphericalScene.degrees(:math.atan2(y, x) - e.rotation_angle_rad))
                }
            end

          {:ok,
           Result.build(checks, %{
             "mode" => mode,
             "central_ray_hit" => location,
             "reflected_direction_inertial" => Tuple.to_list(beam),
             "cone_half_angle_deg" => s.cone,
             "cone_misses_body" => misses,
             "solar_disk_fully_visible" => sun_earth - s.solar > limb + @guard_deg
           })}
      end
    end
  end

  defp empty(reason, mode),
    do:
      {:ok,
       Result.build(
         [%CheckResult{id: "illumination", status: :supported, details: %{"reason" => reason}}],
         %{
           "mode" => mode,
           "central_ray_hit" => :null
         }
       )}

  defp region_check(r, beam, radius, rotation, cone, misses, region) do
    phi = SphericalScene.radians(region.lat)
    lambda = SphericalScene.radians(region.lon) + rotation

    center =
      {:math.cos(phi) * :math.cos(lambda), :math.cos(phi) * :math.sin(lambda), :math.sin(phi)}

    cap = region.radius / radius
    visible_cap = :math.acos(radius / V.norm(r))

    invisible =
      angle(Input.unit!(r, "position"), center) >
        SphericalScene.degrees(visible_cap + cap) + @guard_deg

    to_center = V.subtract(V.scale(center, radius), r)
    distance = V.norm(to_center)
    ball = 2 * radius * :math.sin(cap / 2)

    angular_bound =
      if distance <= ball,
        do: 180.0,
        else: SphericalScene.degrees(:math.asin(min(1.0, ball / distance)))

    separation = angle(beam, Input.unit!(to_center, "exclusion line of sight"))
    margin = separation - cone - angular_bound - @guard_deg
    supported = misses or invisible or margin > 0

    %CheckResult{
      id: "region:#{region.id}",
      status:
        if(supported) do
          :supported
        else
          :violated
        end,
      margin:
        if(misses or invisible) do
          :unknown
        else
          margin
        end,
      margin_unit: "deg",
      details: %{
        "reason" =>
          cond do
            misses -> "cone_misses_body"
            invisible -> "region_not_visible"
            margin > 0 -> "cone_clear_of_region_bound"
            true -> "possible_cone_overlap_with_region_bound"
          end
      }
    }
  end

  @doc "Near intersection of a unit ray from outside a sphere, or nil."
  def ray_hit(r, d, radius) do
    b = V.dot(r, d)
    c = V.dot(r, r) - radius * radius
    disc = b * b - c

    if b >= 0 or disc < 0 do
      nil
    else
      distance = c / (-b + :math.sqrt(max(0.0, disc)))
      V.add(r, V.scale(d, distance))
    end
  end

  defp angle(a, b), do: SphericalScene.degrees(:math.atan2(V.norm(V.cross(a, b)), V.dot(a, b)))
  defp wrap(x), do: x - 360 * :math.floor((x + 180) / 360)
end
