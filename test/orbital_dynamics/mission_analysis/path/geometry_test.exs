defmodule OrbitalDynamics.MissionAnalysis.Path.GeometryTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.{CentralBody, Epoch, Frame, StateVector, Trajectory, Vector3}
  alias OrbitalDynamics.MissionAnalysis.{Asset, SphericalScene, Input}
  alias OrbitalDynamics.MissionAnalysis.Environments.Fixed
  alias OrbitalDynamics.MissionAnalysis.Attitude.{Pointing, Quaternion}
  alias OrbitalDynamics.MissionAnalysis.Path.{Result, Checks.Angular, Checks.ReflectedBeam}
  alias OrbitalDynamics.MissionAnalysis.Models.{Illumination, Imaging}

  defp scene(sun \\ {0, 1, 0}) do
    body = CentralBody.new!(:toy, 1000, equatorial_radius_km: 1000, j2: 0)
    frame = Frame.new!(:toy, :toy, :inertial)

    env =
      Fixed.new!(frame, Epoch.new!(0, :tai),
        sun_direction: sun,
        rotation_angle_rad: 0,
        rotation_rate_rad_s: 0,
        starts_at_s: -1,
        ends_at_s: 10
      )

    SphericalScene.new!(body, frame, :tai, {Fixed, env})
  end

  defp state(s), do: StateVector.new!({1100, 0, 0}, {0, 0, 0}, Epoch.new!(0, :tai), s.frame)

  defp pose(s, normal) do
    {:ok, q} = Quaternion.from_direction(normal, {0, 0, 1})
    Pointing.new!(s.frame, q)
  end

  defp asset(s),
    do:
      Asset.new!(
        "a",
        %Trajectory{
          scenario_id: "toy",
          states: [state(s), %{state(s) | epoch: Epoch.new!(1, :tai)}],
          assumptions: %{}
        },
        %{},
        %{}
      )

  defp config(
         regions \\ [
           %{"id" => "near", "latitude_deg" => 0, "longitude_deg" => 0, "radius_km" => 5}
         ]
       ),
       do: %{
         "mirror_normal_body" => [0, 0, 1],
         "back_face_behavior" => "two_sided_reflecting_by_assumption",
         "solar_angular_radius_deg" => 0.265,
         "beam_padding_deg" => 0,
         "exclusion_regions" => regions
       }

  defp mode(parameters \\ %{"optical_behavior" => "reflecting"}),
    do: %{"name" => "declared", "parameters" => parameters}

  defp evaluate(s, normal, c \\ config(), m \\ mode()) do
    {:ok, session, _} = ReflectedBeam.prepare(asset(s), s, c)
    {:ok, r} = ReflectedBeam.evaluate(state(s), pose(s, normal), m, session)
    r
  end

  test "central ray reflection and near intersection locate a forbidden ground cap on an arbitrary body" do
    s = scene()
    normal = Input.unit!({-1, 1, 0}, "normal")
    r = evaluate(s, normal)
    assert Result.status(r) == "violated"
    assert_in_delta r.metrics["central_ray_hit"]["latitude_deg"], 0, 1.0e-10
    assert_in_delta r.metrics["central_ray_hit"]["longitude_deg"], 0, 1.0e-10

    assert Vector3.norm(
             Vector3.subtract(ReflectedBeam.ray_hit({1100, 0, 0}, {-1, 0, 0}, 1000), {1000, 0, 0})
           ) < 1.0e-9

    far = [%{"id" => "far", "latitude_deg" => 0, "longitude_deg" => 180, "radius_km" => 5}]
    assert Result.status(evaluate(s, normal, config(far))) == "supported"
  end

  test "a cone can overlap a tangent exclusion while its central ray misses the body" do
    s = scene()
    limb = :math.asin(1000 / 1100)

    beam =
      {-:math.cos(limb + 0.1 * :math.pi() / 180), :math.sin(limb + 0.1 * :math.pi() / 180), 0}

    normal = Input.unit!(Vector3.add({0, 1, 0}, beam), "bisector")
    tangent_lon = :math.acos(1000 / 1100) * 180 / :math.pi()

    region = [
      %{"id" => "limb", "latitude_deg" => 0, "longitude_deg" => tangent_lon, "radius_km" => 1}
    ]

    r = evaluate(s, normal, config(region))
    assert r.metrics["central_ray_hit"] == :null
    refute r.metrics["cone_misses_body"]
    assert Result.status(r) == "violated"
  end

  test "finite solar visibility retains partial-umbra exposure and treats complete occultation separately" do
    limb = :math.asin(1000 / 1100)
    sun = {-:math.cos(limb - 0.1 * :math.pi() / 180), :math.sin(limb - 0.1 * :math.pi() / 180), 0}
    normal = Input.unit!(Vector3.add(sun, {-1, 0, 0}), "normal")
    r = evaluate(scene(sun), normal)
    refute r.metrics["solar_disk_fully_visible"]
    assert Result.status(r) == "violated"
    r = evaluate(scene({-1, 0, 0}), {-1, 0, 0})
    assert Result.status(r) == "supported"
    assert hd(r.checks)["reason"] == "solar_disk_fully_occulted"
  end

  test "unknown back optics remain unknown when even a positive-center Sun disk reaches the back face" do
    s = scene()
    c = Map.put(config(), "back_face_behavior", "unknown")
    normal = {:math.cos(0.1 * :math.pi() / 180), :math.sin(0.1 * :math.pi() / 180), 0}
    r = evaluate(s, normal, c)
    assert Result.status(r) == "unknown"
    assert hd(r.checks)["reason"] == "back_face_optics_not_known"
  end

  test "off is not a blocked mirror, and a blocked mirror cannot fulfill illumination service" do
    s = scene()
    n = Input.unit!({-1, 1, 0}, "normal")

    assert Result.status(evaluate(s, n, config(), %{"name" => "off", "parameters" => %{}})) ==
             "unknown"

    blocked =
      mode(%{"optical_behavior" => "blocked_by_assumption", "imaging_behavior" => "enabled"})

    assert Result.status(evaluate(s, n, config(), blocked)) == "supported"
    assert {:ok, service} = Illumination.activity_mode(blocked, nil)
    assert Result.status(service) == "violated"
    assert {:ok, camera} = Imaging.activity_mode(blocked, nil)
    assert Result.status(camera) == "supported"
  end

  test "Sun, limb and fixed-axis envelopes use the full orientation" do
    s = scene()
    common = %{"body_axis" => [0, 0, 1], "minimum_angle_deg" => 0, "maximum_angle_deg" => 180}

    {:ok, limb, _} =
      Angular.prepare(asset(s), s, Map.put(common, "reference", %{"kind" => "body_limb"}))

    {:ok, r} = Angular.evaluate(state(s), pose(s, {-1, 0, 0}), mode(), limb)
    assert Result.status(r) == "violated"
    sun = common |> Map.put("reference", %{"kind" => "sun"}) |> Map.put("minimum_angle_deg", 50)
    {:ok, sun, _} = Angular.prepare(asset(s), s, sun)
    {:ok, r} = Angular.evaluate(state(s), pose(s, Input.unit!({-1, 1, 0}, "normal")), mode(), sun)
    assert Result.status(r) == "violated"

    fixed =
      common
      |> Map.put("reference", %{"kind" => "inertial", "direction" => [1, 0, 0]})
      |> Map.put("maximum_angle_deg", 5)

    {:ok, fixed, _} = Angular.prepare(asset(s), nil, fixed)
    {:ok, r} = Angular.evaluate(state(s), pose(s, {1, 0, 0}), mode(), fixed)
    assert Result.status(r) == "supported"
  end

  test "unrecognized structured mode parameters remain unknown without enum interpolation failures" do
    descriptor = %{
      "name" => "odd-mode",
      "parameters" => %{
        "optical_behavior" => %{"unsupported" => true},
        "imaging_behavior" => ["unsupported"]
      }
    }

    assert {:ok, mirror} = Illumination.activity_mode(descriptor, nil)
    assert Result.status(mirror) == "unknown"
    assert {:ok, camera} = Imaging.activity_mode(descriptor, nil)
    assert Result.status(camera) == "unknown"
  end
end
