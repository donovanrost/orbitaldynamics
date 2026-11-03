defmodule OrbitalDynamics.MissionAnalysis.Models.Imaging do
  @moduledoc """
  Steerable optical imaging using the same scene and generic analysis runner.

  Predicts nominal small-angle footprint and center worst-axis ground sampling distance for
  a target-centered square field of view. This is a geometric estimate; it does
  not model MTF, exposure, smear, clouds, terrain, or achieved attitude.
  """
  @behaviour OrbitalDynamics.MissionAnalysis.Model
  alias OrbitalDynamics.MissionAnalysis.{Evaluation, SphericalScene}
  alias OrbitalDynamics.MissionAnalysis.Models.SurfaceSupport, as: Support

  @impl true
  def capabilities do
    %{
      "id" => "steerable_optical_imaging.v1",
      "validation_level" => "unvalidated_analytic_estimate",
      "outcomes" => ["nominal_center_worst_axis_gsd_m", "nominal_footprint_minor_km"],
      "pointing_model" => "target_centered_boresight",
      "tracking_model" => "sample_secant_rate"
    }
  end

  @impl true
  def prepare(request, payload, %SphericalScene{} = scene) do
    geometry = Support.context!(request, scene)

    Support.fields!(
      payload,
      ~w(field_of_view_deg pixels_across max_off_nadir_deg max_tracking_rate_deg_s),
      "camera payload"
    )

    Support.fields!(
      request.parameters,
      ~w(minimum_elevation_deg minimum_target_sun_elevation_deg maximum_gsd_m target_radius_km),
      "imaging parameters"
    )

    pixels = Map.fetch!(payload, "pixels_across")

    unless is_integer(pixels) and pixels in 1..1_000_000,
      do: raise(ArgumentError, "pixels_across must be a positive integer <= 1000000")

    p = request.parameters

    session = %{
      scene: scene,
      target: request.subject,
      fov: Support.number!(payload, "field_of_view_deg", 0.001, 10),
      pixels: pixels,
      max_off_nadir: Support.number!(payload, "max_off_nadir_deg", 0, 89.9),
      max_rate: Support.positive!(payload, "max_tracking_rate_deg_s"),
      min_elevation:
        max(
          request.subject.minimum_elevation_deg,
          Support.number!(p, "minimum_elevation_deg", 0, 89.9)
        ),
      min_sun_elevation: Support.number!(p, "minimum_target_sun_elevation_deg", -90, 90),
      max_gsd: Support.positive!(p, "maximum_gsd_m"),
      target_radius: Support.number!(p, "target_radius_km", 0, 1.0e6)
    }

    {:ok, session,
     %{
       "geometry" => geometry,
       "payload" => payload,
       "requirements" => p,
       "known_limits" => [
         "nominal small-angle target-centered field of view; full FOV <= 10 degrees",
         "GSD is a center differential estimate, not a fieldwide worst-pixel bound",
         "no optical MTF, exposure, smear, or clouds",
         "no pointing error or achieved attitude",
         "tracking is a sampled secant, not an instantaneous bound"
       ]
     }}
  end

  def prepare(_request, _payload, _context), do: {:error, :imaging_requires_spherical_scene}

  @impl true
  def evaluate(state, previous, session) do
    with {:ok, scene} <- SphericalScene.at(session.scene, state, session.target),
         {:ok, rate} <- Support.rate(state, previous, session, & &1.target_direction) do
      cosine = max(0.0, :math.sin(SphericalScene.radians(scene.elevation_deg)))

      width_m =
        2 * scene.slant_range_km * 1000 * :math.tan(SphericalScene.radians(session.fov) / 2)

      gsd = if cosine > 1.0e-9, do: width_m / session.pixels / cosine, else: nil

      corner_angle =
        SphericalScene.degrees(
          :math.atan(:math.sqrt(2) * :math.tan(SphericalScene.radians(session.fov) / 2))
        )

      checks = [
        Support.check(
          "field_of_view_above_tangent_horizon",
          scene.elevation_deg > corner_angle,
          scene.elevation_deg,
          corner_angle,
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
          "minimum_target_sun_elevation_deg",
          scene.target_sun_elevation_deg >= session.min_sun_elevation,
          scene.target_sun_elevation_deg,
          session.min_sun_elevation,
          :min,
          "deg"
        ),
        Support.check(
          "maximum_off_nadir_deg",
          scene.off_nadir_deg <= session.max_off_nadir,
          scene.off_nadir_deg,
          session.max_off_nadir,
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
          "target_contained_in_nominal_footprint",
          cosine > 0 and 2 * session.target_radius <= width_m / 1000,
          if(cosine > 0, do: 2 * session.target_radius, else: nil),
          width_m / 1000,
          :max,
          "km"
        ),
        Support.check(
          "maximum_nominal_center_gsd_m",
          gsd != nil and gsd <= session.max_gsd,
          gsd,
          session.max_gsd,
          :max,
          "m"
        )
      ]

      {:ok,
       Evaluation.new!(
         checks,
         Map.merge(SphericalScene.metrics(scene), %{
           "required_tracking_rate_deg_s" => rate,
           "nominal_center_worst_axis_gsd_m" => gsd,
           "nominal_footprint_minor_km" => width_m / 1000
         })
       )}
    end
  end

  @impl true
  def opportunity_functions(session, source, lookback) do
    specs = [
      {"field_of_view_above_tangent_horizon", "deg", 1.0e-9, true},
      {"minimum_elevation_deg", "deg", 1.0e-9},
      {"minimum_target_sun_elevation_deg", "deg", 1.0e-9},
      {"maximum_off_nadir_deg", "deg", 1.0e-9},
      {"tracking_rate_known", "1", 0},
      {"maximum_tracking_rate_deg_s", "deg/s", 1.0e-9},
      {"target_contained_in_nominal_footprint", "km", 1.0e-9},
      {"maximum_nominal_center_gsd_m", "m", 1.0e-9}
    ]

    {:ok,
     OrbitalDynamics.MissionAnalysis.Opportunity.Functions.from_evaluation(
       __MODULE__,
       session,
       source,
       lookback,
       specs
     )}
  end

  @impl true
  def pointing(state, session, configuration) do
    with {:ok, scene} <- SphericalScene.at(session.scene, state, session.target) do
      direction = scene.target_direction

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
    behavior = Map.get(mode["parameters"], "imaging_behavior", "unknown")

    status =
      case behavior do
        "enabled" -> "supported"
        "disabled_by_assumption" -> "violated"
        _ -> "unknown"
      end

    {:ok,
     OrbitalDynamics.MissionAnalysis.Path.Result.new!(
       [
         %{
           "id" => "service_operating_mode",
           "status" => status,
           "reason" => "declared_imaging_behavior:#{inspect(behavior)}"
         }
       ],
       %{"mode" => mode}
     )}
  end
end
