defmodule OrbitalDynamics.MissionAnalysis.PhysicsTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.{CentralBody, Epoch, Frame, StateVector, Target, Vector3}
  alias OrbitalDynamics.MissionAnalysis.{Evaluation, OrbitDesign, Request, SphericalScene}
  alias OrbitalDynamics.MissionAnalysis.Environments.{Campaign, Fixed}
  alias OrbitalDynamics.MissionAnalysis.Models.{Illumination, Imaging}
  alias OrbitalDynamics.Environment.CampaignEnvironmentProvider, as: Provider

  defp scene(sun, body \\ CentralBody.earth()) do
    frame = Frame.new!(:analytic, body.name, :inertial)
    epoch = Epoch.new!(0, :tai)

    env =
      Fixed.new!(frame, epoch,
        sun_direction: sun,
        rotation_rate_rad_s: 0,
        rotation_angle_rad: 0,
        starts_at_s: -100,
        ends_at_s: 100
      )

    SphericalScene.new!(body, frame, :tai, {Fixed, env})
  end

  defp state(scene, altitude \\ 600, time \\ 0),
    do:
      StateVector.new!(
        {scene.body.equatorial_radius_km + altitude, 0, 0},
        {0, 0, 0},
        Epoch.new!(time, :tai),
        scene.frame
      )

  defp target, do: Target.new!("site", 0, 0, minimum_elevation_deg: 10)

  defp payload,
    do: %{
      "mirror_area_m2" => 400,
      "mirror_max_dimension_m" => 20,
      "reflectivity" => 0.9,
      "atmospheric_transmission" => 0.8,
      "solar_irradiance_w_m2" => 1361,
      "solar_angular_diameter_deg" => 0.53,
      "max_mirror_incidence_deg" => 80,
      "max_tracking_rate_deg_s" => 2
    }

  defp params,
    do: %{
      "minimum_elevation_deg" => 10,
      "maximum_target_sun_elevation_deg" => -6,
      "minimum_irradiance_w_m2" => 0.0001,
      "target_radius_km" => 1
    }

  defp request(model, params),
    do:
      Request.new!("r", model, target(),
        activity_type: "activity",
        starts_at_s: 0,
        ends_at_s: 100,
        duration_s: 10,
        time_scale: :tai,
        value: 1,
        parameters: params,
        resource_costs: %{}
      )

  defp night_sun, do: {-:math.sin(:math.pi() / 18), :math.cos(:math.pi() / 18), 0}

  defp evaluate(model, scene, payload, params, altitude \\ 600) do
    {:ok, session, _} = model.prepare(request(model, params), payload, scene)

    {:ok, evaluation} =
      model.evaluate(state(scene, altitude), state(scene, altitude, -10), session)

    evaluation
  end

  defp passed?(e, id), do: Enum.find(e.checks, &(&1["id"] == id))["passed"]

  test "ideal mirror normal reflects incoming sunlight exactly toward target" do
    s = scene(night_sun())
    {:ok, geometry} = SphericalScene.at(s, state(s), target())
    n = Illumination.normal(geometry)
    incoming = Vector3.scale(geometry.sun_direction, -1)
    reflected = Vector3.subtract(incoming, Vector3.scale(n, 2 * Vector3.dot(incoming, n)))
    assert Vector3.norm(Vector3.subtract(reflected, geometry.target_direction)) < 1.0e-12
  end

  test "nominal footprint conserves transmitted power and scales with distance squared" do
    s = scene(night_sun())
    a = evaluate(Illumination, s, payload(), params())
    b = evaluate(Illumination, s, payload(), params(), 1200)
    assert Evaluation.feasible?(a)
    m = a.metrics

    area =
      :math.pi() * m["nominal_footprint_minor_km"] * m["nominal_footprint_major_km"] * 1.0e6 / 4

    assert_in_delta m["nominal_irradiance_w_m2"] * area,
                    m["reflected_transmitted_power_w"],
                    1.0e-7

    assert_in_delta m["nominal_irradiance_w_m2"] / b.metrics["nominal_irradiance_w_m2"],
                    4,
                    1.0e-10

    assert_in_delta b.metrics["nominal_footprint_minor_km"] / m["nominal_footprint_minor_km"],
                    2,
                    1.0e-10

    assert_in_delta m["target_sun_elevation_deg"], -10, 1.0e-10
  end

  test "darkness, eclipse, throughput, unknown tracking and degenerate reflection fail eligibility" do
    s = scene(night_sun())

    for key <- ["reflectivity", "atmospheric_transmission"] do
      e = evaluate(Illumination, s, Map.put(payload(), key, 0), params())
      refute passed?(e, "minimum_nominal_irradiance_w_m2")
    end

    day = evaluate(Illumination, scene({1, 0, 0}), payload(), params())
    refute passed?(day, "maximum_target_sun_elevation_deg")
    refute passed?(day, "specular_geometry")
    shadow = evaluate(Illumination, scene({-1, 0, 0}), payload(), params())
    refute passed?(shadow, "spacecraft_sunlit")
    assert shadow.metrics["reflected_transmitted_power_w"] == 0
    {:ok, session, _} = Illumination.prepare(request(Illumination, params()), payload(), s)
    {:ok, first} = Illumination.evaluate(state(s), nil, session)
    refute passed?(first, "tracking_rate_known")
  end

  test "camera nadir GSD follows angle and pixel count; night and strict resolution fail" do
    payload = %{
      "field_of_view_deg" => 5,
      "pixels_across" => 4096,
      "max_off_nadir_deg" => 70,
      "max_tracking_rate_deg_s" => 2
    }

    params = %{
      "minimum_elevation_deg" => 10,
      "minimum_target_sun_elevation_deg" => 5,
      "maximum_gsd_m" => 100,
      "target_radius_km" => 1
    }

    e = evaluate(Imaging, scene({1, 0, 0}), payload, params)
    assert Evaluation.feasible?(e)

    assert_in_delta e.metrics["nominal_center_worst_axis_gsd_m"],
                    2 * 600_000 * :math.tan(5 * :math.pi() / 360) / 4096,
                    1.0e-10

    refute evaluate(Imaging, scene(night_sun()), payload, params)
           |> passed?("minimum_target_sun_elevation_deg")

    refute evaluate(Imaging, scene({1, 0, 0}), payload, Map.put(params, "maximum_gsd_m", 1))
           |> passed?("maximum_nominal_center_gsd_m")
  end

  test "finite camera and solar cones must stay above the local tangent horizon" do
    s = scene({1, 0, 0})
    elevation = 5 * :math.pi() / 180

    position =
      {s.body.equatorial_radius_km + 600 * :math.sin(elevation), 600 * :math.cos(elevation), 0}

    now = %{state(s) | position_km: position}
    previous = %{state(s, 600, -10) | position_km: position}

    camera = %{
      "field_of_view_deg" => 10,
      "pixels_across" => 1_000_000,
      "max_off_nadir_deg" => 89.9,
      "max_tracking_rate_deg_s" => 2
    }

    requirements = %{
      "minimum_elevation_deg" => 0,
      "minimum_target_sun_elevation_deg" => -90,
      "maximum_gsd_m" => 100,
      "target_radius_km" => 0
    }

    r = %{
      request(Imaging, requirements)
      | subject: Target.new!("low", 0, 0, minimum_elevation_deg: 0)
    }

    {:ok, session, _} = Imaging.prepare(r, camera, s)
    {:ok, e} = Imaging.evaluate(now, previous, session)
    refute passed?(e, "field_of_view_above_tangent_horizon")

    assert_raise ArgumentError, fn ->
      Imaging.prepare(r, Map.put(camera, "field_of_view_deg", 40), s)
    end

    # A 10-degree solar disk at 5-degree elevation touches the tangent horizon.
    # Use 0.1 degree elevation with the ordinary solar disk to avoid equality tolerances.
    angle = 0.1 * :math.pi() / 180
    position = {s.body.equatorial_radius_km + 600 * :math.sin(angle), 600 * :math.cos(angle), 0}
    r = %{request(Illumination, params()) | subject: r.subject}
    {:ok, session, _} = Illumination.prepare(r, payload(), s)

    {:ok, e} =
      Illumination.evaluate(
        %{now | position_km: position},
        %{previous | position_km: position},
        session
      )

    refute passed?(e, "solar_image_above_tangent_horizon")
  end

  test "tracking check rejects a required rate above the configured capability" do
    s = scene(night_sun())

    {:ok, session, _} =
      Illumination.prepare(
        request(Illumination, params()),
        Map.put(payload(), "max_tracking_rate_deg_s", 0.0001),
        s
      )

    prior = %{state(s, 600, -1) | position_km: {s.body.equatorial_radius_km + 600, -10, 0}}
    {:ok, e} = Illumination.evaluate(state(s), prior, session)
    assert passed?(e, "tracking_rate_known")
    refute passed?(e, "maximum_tracking_rate_deg_s")
  end

  test "surface geometry is body-independent and environment coverage fails closed" do
    body = CentralBody.new!(:toy, 1000, equatorial_radius_km: 1000, j2: 0)
    s = scene(night_sun(), body)
    assert Evaluation.feasible?(evaluate(Illumination, s, payload(), params()))

    assert {:error, :environment_outside_coverage} =
             SphericalScene.at(s, state(s, 600, 101), target())

    assert {:error, _} =
             SphericalScene.at(s, %{state(s) | frame: Frame.earth_inertial_j2000()}, target())
  end

  test "campaign adapter preserves provider vectors and rejects incompatible time" do
    {:ok, dataset} = Provider.load(Provider.checked_in_options())
    epoch = Epoch.new!(820_497_600, :utc)

    {:ok, direct} =
      Provider.fetch(:sun_direction, dataset: dataset, seconds_since_j2000: 820_497_600)

    {:ok, env} = Campaign.at(epoch, dataset)
    assert env.sun_direction == direct["sun_direction"]
    assert {:error, _} = Campaign.at(%{epoch | scale: :tdb}, dataset)
    assert {:error, _} = Campaign.at(Epoch.shift(epoch, -1), dataset)
  end

  test "circular SSO estimate has expected retrograde inclination and nodal rate" do
    body = CentralBody.earth()
    year = 31_556_925.216
    i = OrbitDesign.sun_synchronous_inclination_deg!(body, 600, year)
    assert_in_delta i, 97.78767, 0.0001
    a = body.equatorial_radius_km + 600

    rate =
      -1.5 * body.j2 * :math.sqrt(body.mu_km3_s2 / :math.pow(a, 3)) *
        :math.pow(body.equatorial_radius_km / a, 2) * :math.cos(i * :math.pi() / 180)

    assert_in_delta rate, 2 * :math.pi() / year, 1.0e-15
    assert OrbitDesign.sun_synchronous_inclination_deg!(body, 800, year) > i

    assert_raise ArgumentError, fn ->
      OrbitDesign.sun_synchronous_inclination_deg!(%{body | j2: 0}, 600, year)
    end
  end
end
