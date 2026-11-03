defmodule OrbitalDynamics.EventSearch.Reference do
  @moduledoc "Synthetic analytic orbit demonstration of the bounded event catalog; no command execution."
  alias OrbitalDynamics.{Epoch, Frame, StateVector, CentralBody, Target, EventSearch}
  alias OrbitalDynamics.EventSearch.Source

  alias OrbitalDynamics.EventDetectors.{
    Nodes,
    Apsides,
    Thresholds,
    Geometry,
    Occultations,
    Extrema
  }

  alias OrbitalDynamics.MissionAnalysis.{SphericalScene, Environments.Fixed}
  alias OrbitalDynamics.MissionAnalysis.Attitude.Pointing

  def run! do
    frame = Frame.new!(:toy, :toy, :inertial)
    epoch = fn t -> Epoch.new!(t, :tai) end

    observer =
      Source.new!(fn t -> {:ok, orbit(t, 0.37, frame)} end, epoch.(-1), epoch.(21), frame, %{
        "evaluation" => "analytic_two_body_ellipse",
        "mu_km3_s2" => 1,
        "a_km" => 2,
        "eccentricity" => 0.25,
        "inclination_deg" => 30
      })

    other =
      Source.new!(fn t -> {:ok, orbit(t, 1.37, frame)} end, epoch.(-1), epoch.(21), frame, %{
        "evaluation" => "analytic_phase_offset_orbit"
      })

    fixed = fn position ->
      Source.new!(
        fn t -> {:ok, StateVector.new!(position, {0, 0, 0}, epoch.(t), frame)} end,
        epoch.(-1),
        epoch.(21),
        frame,
        %{"evaluation" => "fixed_reference_position"}
      )
    end

    sun = fixed.({100, 0, 10})
    body = fixed.({0, 0, 0})

    env =
      Fixed.new!(frame, epoch.(0),
        starts_at_s: -1,
        ends_at_s: 21,
        sun_direction: {100, 0, 10},
        rotation_rate_rad_s: 0.2,
        rotation_angle_rad: 0
      )

    scene =
      SphericalScene.new!(
        CentralBody.new!(:toy, 1, equatorial_radius_km: 1),
        frame,
        :tai,
        {Fixed, env}
      )

    target = Target.new!("station", 0, 0, minimum_elevation_deg: 0)
    access = Geometry.access("access", scene, target, 0, value_tolerance: 1.0e-10)

    functions =
      [
        Nodes.function("nodes", {0, 0, 1}, value_tolerance: 1.0e-10),
        Apsides.function("apsides", value_tolerance: 1.0e-10),
        Thresholds.altitude("altitude", 1, 1, value_tolerance: 1.0e-10, condition: :nonnegative),
        Thresholds.true_anomaly("true_anomaly", 1, 1.0e-8, 90, value_tolerance: 1.0e-10),
        Geometry.latitude("latitude", scene, 10, value_tolerance: 1.0e-10),
        Geometry.longitude("longitude", scene, 0, value_tolerance: 1.0e-10),
        Geometry.region("region", scene, 0, 0, 30, value_tolerance: 1.0e-10),
        access,
        Geometry.ground_night("night", scene, target, 0, value_tolerance: 1.0e-10),
        Extrema.function("elevation_extrema", observer, access, 0.001, value_tolerance: 1.0e-5),
        Geometry.relative_distance("relative_range", other, 2, value_tolerance: 1.0e-10),
        Geometry.closest_approach("closest_approach", other, value_tolerance: 1.0e-10),
        Geometry.intersatellite_visibility("link", other, 1, value_tolerance: 1.0e-10),
        Geometry.field_of_view(
          "camera",
          body,
          fn _ -> {:ok, Pointing.new!(frame, {1, 0, 0, 0})} end,
          {-1, 0, 0},
          20,
          value_tolerance: 1.0e-10
        ),
        Geometry.angular_separation("sun_body_separation", sun, body, 30,
          value_tolerance: 1.0e-10
        ),
        Geometry.beta_angle("beta", sun, 0, value_tolerance: 1.0e-10),
        Geometry.limb_clearance(
          "limb",
          fn _ -> {:ok, Pointing.new!(frame, {1, 0, 0, 0})} end,
          {-1, 0, 0},
          1,
          value_tolerance: 1.0e-10
        )
      ] ++ Occultations.functions("eclipse", sun, 10, body, 1, value_tolerance: 1.0e-12)

    case EventSearch.run(observer, functions,
           starts_at: epoch.(0),
           ends_at: epoch.(20),
           max_check_step_s: 0.1,
           time_tolerance_s: 1.0e-6,
           max_iterations: 64,
           max_evaluations: 100_000
         ) do
      {:ok, report} ->
        Map.put(
          report,
          "reference_limits",
          "Synthetic toy body/orbit with oversized apparent Sun for observable contacts; no actual mission, hardware, light-time or fidelity validation implied."
        )

      {:error, reason} ->
        raise ArgumentError, "reference event search failed: #{inspect(reason)}"
    end
  end

  defp orbit(t, phase, frame) do
    n = :math.sqrt(1 / 8)
    e = 0.25
    mean = n * t + phase

    anomaly =
      Enum.reduce(1..20, mean, fn _, x ->
        x - (x - e * :math.sin(x) - mean) / (1 - e * :math.cos(x))
      end)

    s = :math.sqrt(1 - e * e)
    x = 2 * (:math.cos(anomaly) - e)
    y = 2 * s * :math.sin(anomaly)
    vx = -2 * n * :math.sin(anomaly) / (1 - e * :math.cos(anomaly))
    vy = 2 * n * s * :math.cos(anomaly) / (1 - e * :math.cos(anomaly))
    inclination = :math.pi() / 6

    StateVector.new!(
      {x, y * :math.cos(inclination), y * :math.sin(inclination)},
      {vx, vy * :math.cos(inclination), vy * :math.sin(inclination)},
      Epoch.new!(t, :tai),
      frame
    )
  end
end
