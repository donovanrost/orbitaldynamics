defmodule OrbitalDynamics.MissionAnalysis.Models.Illumination do
  @moduledoc """
  First-order flat-mirror illumination of a centered circular surface region.

  Normal bisects spacecraft-to-Sun and spacecraft-to-target unit vectors. Power
  is incident irradiance times projected mirror area, reflectivity, and declared
  atmospheric transmission. The finite solar disk gives a nominal beam diameter
  `2 range tan(solar_angular_diameter/2)`; its planar ground projection is an
  ellipse. Irradiance is nominal uniform-disk ground irradiance, not a measured
  lower bound. Finite aperture edges, limb darkening, flexible optics, clouds,
  pointing errors, penumbra, and achieved attitude are unmodeled.
  """
  @behaviour OrbitalDynamics.MissionAnalysis.Model
  alias OrbitalDynamics.Vector3
  alias OrbitalDynamics.MissionAnalysis.{Evaluation, SphericalScene}
  alias OrbitalDynamics.MissionAnalysis.Models.SurfaceSupport, as: Support

  @payload_fields ~w(mirror_area_m2 mirror_max_dimension_m reflectivity atmospheric_transmission
    solar_irradiance_w_m2 solar_angular_diameter_deg max_mirror_incidence_deg max_tracking_rate_deg_s)
  @request_fields ~w(minimum_elevation_deg maximum_target_sun_elevation_deg minimum_irradiance_w_m2 target_radius_km)

  @impl true
  def capabilities do
    %{
      "id" => "flat_mirror_illumination.v1",
      "validation_level" => "unvalidated_analytic_estimate",
      "outcomes" => [
        "nominal_irradiance_w_m2",
        "nominal_footprint_minor_km",
        "nominal_footprint_major_km"
      ],
      "pointing_model" => "ideal_specular_normal",
      "tracking_model" => "sample_secant_rate"
    }
  end

  @impl true
  def prepare(request, payload, %SphericalScene{} = scene) do
    geometry = Support.context!(request, scene)
    Support.fields!(payload, @payload_fields, "mirror payload")
    Support.fields!(request.parameters, @request_fields, "illumination parameters")
    area = Support.positive!(payload, "mirror_area_m2")
    dimension = Support.positive!(payload, "mirror_max_dimension_m")

    if area > dimension * dimension,
      do: raise(ArgumentError, "mirror area exceeds bounding square")

    p = request.parameters

    values = %{
      area: area,
      dimension: dimension,
      reflectivity: Support.number!(payload, "reflectivity", 0, 1),
      transmission: Support.number!(payload, "atmospheric_transmission", 0, 1),
      solar_flux: Support.positive!(payload, "solar_irradiance_w_m2"),
      solar_angle: Support.number!(payload, "solar_angular_diameter_deg", 0.001, 10),
      max_incidence: Support.number!(payload, "max_mirror_incidence_deg", 0, 89.9),
      max_rate: Support.positive!(payload, "max_tracking_rate_deg_s"),
      min_elevation:
        max(
          request.subject.minimum_elevation_deg,
          Support.number!(p, "minimum_elevation_deg", 0, 89.9)
        ),
      max_sun_elevation: Support.number!(p, "maximum_target_sun_elevation_deg", -90, 90),
      min_irradiance: Support.positive!(p, "minimum_irradiance_w_m2"),
      target_radius: Support.number!(p, "target_radius_km", 0, 1.0e6),
      scene: scene,
      target: request.subject
    }

    {:ok, values,
     %{
       "geometry" => geometry,
       "payload" => payload,
       "requirements" => p,
       "optics" => "uniform_solar_disk_small_flat_mirror_planar_ground_projection",
       "small_mirror_limit" => "max mirror dimension <= 5% of nominal solar-image diameter",
       "known_limits" => [
         "no focusing or optical deformation",
         "no limb darkening or finite aperture edge convolution",
         "constant declared atmospheric transmission; no cloud prediction",
         "no pointing error or attitude dynamics",
         "tracking is a sampled secant, not a bound on instantaneous rate",
         "no initial acquisition or settling model"
       ]
     }}
  end

  def prepare(_request, _payload, _context), do: {:error, :illumination_requires_spherical_scene}

  @impl true
  def evaluate(state, previous, session) do
    with {:ok, scene} <- SphericalScene.at(session.scene, state, session.target),
         {:ok, rate} <- Support.rate(state, previous, session, &normal/1) do
      n = normal(scene)
      cosine = if n, do: max(0, Vector3.dot(n, scene.sun_direction)), else: 0.0
      incidence = SphericalScene.degrees(:math.acos(SphericalScene.clamp(cosine)))
      ground_cosine = max(0.0, :math.sin(SphericalScene.radians(scene.elevation_deg)))

      diameter_m =
        2 * scene.slant_range_km * 1000 *
          :math.tan(SphericalScene.radians(session.solar_angle) / 2)

      beam_area_m2 = :math.pi() * :math.pow(diameter_m / 2, 2)

      power_w =
        session.solar_flux * session.area * cosine * session.reflectivity * session.transmission

      # Report physically available power only while the ideal point-Sun is visible.
      power_w = if scene.spacecraft_sunlit?, do: power_w, else: 0.0
      irradiance = power_w * ground_cosine / beam_area_m2
      minor_km = diameter_m / 1000
      major_km = if ground_cosine > 1.0e-9, do: minor_km / ground_cosine, else: nil

      checks = [
        Support.check(
          "solar_image_above_tangent_horizon",
          scene.elevation_deg > session.solar_angle / 2,
          scene.elevation_deg,
          session.solar_angle / 2,
          :strict_min,
          "deg"
        ),
        Support.check(
          "minimum_elevation_deg",
          scene.elevation_deg >= session.min_elevation,
          scene.elevation_deg,
          session.min_elevation,
          :min,
          "deg"
        ),
        Support.check(
          "maximum_target_sun_elevation_deg",
          scene.target_sun_elevation_deg <= session.max_sun_elevation,
          scene.target_sun_elevation_deg,
          session.max_sun_elevation,
          :max,
          "deg"
        ),
        Support.check(
          "spacecraft_sunlit",
          scene.spacecraft_sunlit?,
          scene.spacecraft_sunlit?,
          true
        ),
        Support.check("specular_geometry", n != nil, n != nil, true),
        Support.check(
          "maximum_mirror_incidence_deg",
          incidence <= session.max_incidence,
          incidence,
          session.max_incidence,
          :max,
          "deg"
        ),
        Support.check("tracking_rate_known", rate != nil, rate != nil, true),
        Support.check(
          "maximum_tracking_rate_deg_s",
          rate != nil and rate <= session.max_rate,
          rate,
          session.max_rate,
          :max,
          "deg/s"
        ),
        Support.check(
          "small_mirror_approximation",
          session.dimension <= 0.05 * diameter_m,
          session.dimension / diameter_m,
          0.05,
          :max,
          "ratio"
        ),
        Support.check(
          "target_contained_in_nominal_footprint",
          ground_cosine > 0 and 2 * session.target_radius <= minor_km,
          if(ground_cosine > 0, do: 2 * session.target_radius, else: nil),
          minor_km,
          :max,
          "km"
        ),
        Support.check(
          "minimum_nominal_irradiance_w_m2",
          irradiance >= session.min_irradiance,
          irradiance,
          session.min_irradiance,
          :min,
          "W/m2"
        )
      ]

      metrics =
        Map.merge(SphericalScene.metrics(scene), %{
          "mirror_normal" => if(n, do: Tuple.to_list(n), else: nil),
          "mirror_incidence_deg" => incidence,
          "required_tracking_rate_deg_s" => rate,
          "reflected_transmitted_power_w" => power_w,
          "nominal_irradiance_w_m2" => irradiance,
          "nominal_footprint_minor_km" => minor_km,
          "nominal_footprint_major_km" => major_km
        })

      {:ok, Evaluation.new!(checks, metrics)}
    end
  end

  @impl true
  def opportunity_functions(session, source, lookback) do
    specs = [
      {"solar_image_above_tangent_horizon", "deg", 1.0e-9, true},
      {"minimum_elevation_deg", "deg", 1.0e-9},
      {"maximum_target_sun_elevation_deg", "deg", 1.0e-9},
      {"spacecraft_sunlit", "km", 1.0e-8},
      {"specular_geometry", "1", 1.0e-14},
      {"maximum_mirror_incidence_deg", "deg", 1.0e-9},
      {"tracking_rate_known", "1", 0},
      {"maximum_tracking_rate_deg_s", "deg/s", 1.0e-9},
      {"small_mirror_approximation", "ratio", 1.0e-12},
      {"target_contained_in_nominal_footprint", "km", 1.0e-9},
      {"minimum_nominal_irradiance_w_m2", "W/m2", 1.0e-12}
    ]

    overrides = %{
      "spacecraft_sunlit" => fn state, _, _ ->
        with {:ok, environment} <- SphericalScene.environment_at(session.scene, state) do
          axial = Vector3.dot(state.position_km, environment.sun_direction)

          perpendicular =
            Vector3.norm(
              Vector3.subtract(state.position_km, Vector3.scale(environment.sun_direction, axial))
            )

          {:ok, max(axial, perpendicular - session.scene.body.equatorial_radius_km), nil,
           %{"model" => "point_sun_cylindrical_shadow_margin"}}
        end
      end,
      "specular_geometry" => fn state, _, _ ->
        with {:ok, g} <- SphericalScene.at(session.scene, state, session.target) do
          {:ok, Vector3.norm(Vector3.add(g.sun_direction, g.target_direction)) - 1.0e-12, nil,
           %{}}
        end
      end,
      "minimum_nominal_irradiance_w_m2" => fn _, sample, check ->
        # The existing service model switches power off in shadow. Treat that
        # branch as outside this scalar's known domain; the separate continuous
        # sunlight constraint handles its boundary without inventing a zero of
        # a discontinuous irradiance margin.
        if sample["metrics"]["spacecraft_sunlit"],
          do: {:ok, check["margin"], nil, %{}},
          else: {:unknown, :irradiance_shadow_branch}
      end
    }

    {:ok,
     OrbitalDynamics.MissionAnalysis.Opportunity.Functions.from_evaluation(
       __MODULE__,
       session,
       source,
       lookback,
       specs,
       overrides
     )}
  end

  def normal(scene) do
    vector = Vector3.add(scene.sun_direction, scene.target_direction)
    norm = Vector3.norm(vector)
    if norm < 1.0e-12, do: nil, else: Vector3.scale(vector, 1.0 / norm)
  end

  @impl true
  def pointing(state, session, configuration) do
    with {:ok, scene} <- SphericalScene.at(session.scene, state, session.target) do
      direction = normal(scene)

      if direction == nil,
        do: {:unknown, :pointing_direction_undefined},
        else:
          OrbitalDynamics.MissionAnalysis.Attitude.Pointing.from_direction(
            direction,
            state.frame,
            configuration
          )
    end
  end

  @impl true
  def activity_mode(mode, _session) do
    behavior = Map.get(mode["parameters"], "optical_behavior", "unknown")

    status =
      case behavior do
        "reflecting" -> "supported"
        "blocked_by_assumption" -> "violated"
        _ -> "unknown"
      end

    {:ok,
     OrbitalDynamics.MissionAnalysis.Path.Result.new!(
       [
         %{
           "id" => "service_operating_mode",
           "status" => status,
           "reason" => "declared_optical_behavior:#{inspect(behavior)}"
         }
       ],
       %{"mode" => mode}
     )}
  end
end
