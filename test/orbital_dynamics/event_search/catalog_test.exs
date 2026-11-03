defmodule OrbitalDynamics.EventSearch.CatalogTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.{Epoch, Frame, StateVector, CentralBody, Target, EventSearch}
  alias OrbitalDynamics.EventSearch.{Source, Function}
  alias OrbitalDynamics.EventDetectors.{Geometry, Occultations, Extrema, Thresholds}
  alias OrbitalDynamics.MissionAnalysis.{SphericalScene, Environments.Fixed}
  alias OrbitalDynamics.MissionAnalysis.Attitude.Pointing
  defp frame, do: Frame.new!(:toy, :toy, :inertial)
  defp state(t, p, v \\ {0, 0, 0}), do: StateVector.new!(p, v, Epoch.new!(t, :tai), frame())

  defp source(fun),
    do:
      Source.new!(fun, Epoch.new!(-1, :tai), Epoch.new!(11, :tai), frame(), %{
        "evaluation" => "analytic_catalog_fixture"
      })

  defp fixed(p), do: source(fn t -> {:ok, state(t, p)} end)

  defp run(functions, source \\ fixed({0, 0, 0}), opts \\ []) do
    EventSearch.run(
      source,
      List.wrap(functions),
      Keyword.merge(
        [
          starts_at: Epoch.new!(0, :tai),
          ends_at: Epoch.new!(10, :tai),
          max_check_step_s: 0.5,
          time_tolerance_s: 1.0e-7,
          max_iterations: 64,
          max_evaluations: 30000
        ],
        opts
      )
    )
  end

  defp times(r), do: hd(r["results"])["events"] |> Enum.map(& &1["epoch_s"])

  defp scene do
    env =
      Fixed.new!(frame(), Epoch.new!(0, :tai),
        starts_at_s: -1,
        ends_at_s: 11,
        sun_direction: {1, 0, 0},
        rotation_rate_rad_s: :math.pi() / 5,
        rotation_angle_rad: 0
      )

    SphericalScene.new!(
      CentralBody.new!(:toy, 1, equatorial_radius_km: 1),
      frame(),
      :tai,
      {Fixed, env}
    )
  end

  test "ground access, night/twilight and spherical-cap boundaries match analytic rotations" do
    target = Target.new!("station", 0, 0, minimum_elevation_deg: 0)
    access = Geometry.access("access", scene(), target, 0, value_tolerance: 1.0e-10)
    night = Geometry.ground_night("night", scene(), target, 0, value_tolerance: 1.0e-10)
    cap = Geometry.region("cap", scene(), 0, 0, 30, value_tolerance: 1.0e-10)
    assert {:ok, r} = run([access, night, cap], fixed({2, 0, 0}))

    assert r["status"] == "complete_under_search_policy",
           inspect(Enum.map(r["results"], &{&1["function"]["id"], &1["uncovered_intervals"]}),
             limit: :infinity
           )

    for {result, expected} <-
          Enum.zip(r["results"], [[10 / 6, 50 / 6], [2.5, 7.5], [10 / 12, 110 / 12]]) do
      assert length(result["events"]) == 2

      for {event, t} <- Enum.zip(result["events"], expected),
          do: assert_in_delta(event["epoch_s"], t, 1.0e-7)
    end

    assert length(Enum.at(r["results"], 0)["condition_windows"]) == 2
    assert length(Enum.at(r["results"], 1)["condition_windows"]) == 1
  end

  test "meridian filter rejects the antipodal crossing and latitude handles equatorial degeneracy" do
    longitude = Geometry.longitude("meridian", scene(), 90, value_tolerance: 1.0e-10)
    assert {:ok, r} = run(longitude, fixed({2, 0, 0}))
    assert length(times(r)) == 1
    assert_in_delta hd(times(r)), 7.5, 1.0e-7
    latitude = Geometry.latitude("equator", scene(), 0, value_tolerance: 1.0e-10)
    assert {:ok, r} = run(latitude, fixed({2, 0, 0}))
    assert r["status"] == "unknown"
    assert times(r) == []
  end

  test "generic extrema find maximum elevation with explicit derivative-source padding and model scope" do
    observer = fixed({2, 0, 0})
    target = Target.new!("station", 0, 0, minimum_elevation_deg: 0)
    elevation = Geometry.access("elevation", scene(), target, 0, value_tolerance: 1.0e-10)

    extrema =
      Extrema.function("elevation_extrema", observer, elevation, 0.001, value_tolerance: 1.0e-5)

    assert {:ok, r} =
             run(extrema, observer,
               starts_at: Epoch.new!(-0.2, :tai),
               ends_at: Epoch.new!(9.8, :tai)
             )

    events = hd(r["results"])["events"]
    assert length(events) == 2
    assert Enum.map(events, & &1["type"]) == ["local_maximum", "local_minimum"]
    assert_in_delta hd(events)["epoch_s"], 0, 1.0e-6
    assert_in_delta hd(events)["metadata"]["quantity_value"], 90, 1.0e-5

    short =
      Source.new!(
        fn t -> {:ok, state(t, {2, 0, 0})} end,
        Epoch.new!(0, :tai),
        Epoch.new!(10, :tai),
        frame(),
        %{}
      )

    extrema = Extrema.function("padded", short, elevation, 0.01, value_tolerance: 1.0e-5)
    assert {:ok, r} = run(extrema, short)
    assert r["status"] == "unknown"
  end

  test "relative range, closest approach and intersatellite sphere clearance are distinct calculations" do
    observer = fixed({-2, 0, 0})
    other = source(fn t -> {:ok, state(t, {2, t - 5, 0}, {0, 1, 0})} end)

    distance =
      Geometry.relative_distance("range", other, 5,
        value_tolerance: 1.0e-10,
        condition: :nonpositive
      )

    closest = Geometry.closest_approach("closest", other, value_tolerance: 1.0e-10)
    los = Geometry.intersatellite_visibility("link", other, 1, value_tolerance: 1.0e-10)
    assert {:ok, r} = run([distance, closest, los], observer)
    expected = [[2, 8], [5], [5 - 4 / :math.sqrt(3), 5 + 4 / :math.sqrt(3)]]

    for {result, expected} <- Enum.zip(r["results"], expected) do
      assert length(result["events"]) == length(expected)

      for {e, t} <- Enum.zip(result["events"], expected),
          do: assert_in_delta(e["epoch_s"], t, 1.0e-7)
    end

    assert hd(Enum.at(r["results"], 1)["events"])["metadata"]["distance_km"] == 4
  end

  test "FOV and angular separation yield matching analytic cone crossings" do
    target = source(fn t -> {:ok, state(t, {10, t - 5, 0}, {0, 1, 0})} end)
    angle = :math.atan(0.2) * 180 / :math.pi()

    fov =
      Geometry.field_of_view(
        "fov",
        target,
        fn _ -> {:ok, Pointing.new!(frame(), {1, 0, 0, 0})} end,
        {1, 0, 0},
        angle,
        value_tolerance: 1.0e-12
      )

    separation =
      Geometry.angular_separation("separation", fixed({10, 0, 0}), target, angle,
        value_tolerance: 1.0e-10,
        condition: :nonpositive
      )

    assert {:ok, r} = run([fov, separation])

    for result <- r["results"] do
      assert length(result["events"]) == 2

      for {event, t} <- Enum.zip(result["events"], [3, 7]),
          do: assert_in_delta(event["epoch_s"], t, 1.0e-7)
    end
  end

  test "beta-angle thresholds and normalized Boolean conditions share the scalar search" do
    observer =
      source(fn t ->
        {:ok,
         state(
           t,
           {2 * :math.cos(t), 2 * :math.sin(t), 0},
           {-2 * :math.sin(t), 2 * :math.cos(t), 0}
         )}
      end)

    sun = source(fn t -> {:ok, state(t, {100, 0, t - 5}, {0, 0, 1})} end)
    beta = Geometry.beta_angle("beta", sun, 0, value_tolerance: 1.0e-9)
    assert {:ok, r} = run(beta, observer)
    assert_in_delta hd(times(r)), 5, 1.0e-7

    a =
      Function.new!("a", fn s -> {:ok, s.epoch.seconds_since_j2000 - 2, 1, %{}} end,
        units: "s",
        condition: :nonnegative,
        value_tolerance: 1.0e-10
      )

    b =
      Function.new!("b", fn s -> {:ok, 8 - s.epoch.seconds_since_j2000, -1, %{}} end,
        units: "s",
        condition: :nonnegative,
        value_tolerance: 1.0e-10
      )

    conjunction = Function.combine("both", [{a, 1}, {b, 1}], :all, value_tolerance: 1.0e-10)
    assert {:ok, r} = run(conjunction)
    [window] = hd(r["results"])["condition_windows"]
    assert_in_delta window["starts_at_s"], 2, 1.0e-7
    assert_in_delta window["ends_at_s"], 8, 1.0e-7
  end

  test "finite-source total and partial contacts match independent straight-line contact formulas" do
    sun = fixed({100, 0, 0})
    body = source(fn t -> {:ok, state(t, {10, t - 5, 0}, {0, 1, 0})} end)
    fs = Occultations.functions("eclipse", sun, 10, body, 2, value_tolerance: 1.0e-12)
    assert {:ok, r} = run(fs)
    assert r["status"] == "complete_under_search_policy"
    outer = 3 / :math.sqrt(0.99)
    inner = 1 / :math.sqrt(0.99)

    expected = [
      [5 - outer, 5 + outer],
      [5 - inner, 5 + inner],
      [],
      [5 - outer, 5 - inner, 5 + inner, 5 + outer]
    ]

    for {result, expected} <- Enum.zip(r["results"], expected) do
      assert length(result["events"]) == length(expected)

      for {e, t} <- Enum.zip(result["events"], expected),
          do: assert_in_delta(e["epoch_s"], t, 1.0e-7)
    end

    assert length(Enum.at(r["results"], 3)["condition_windows"]) == 2
    assert {:ok, g} = Occultations.geometry(state(5, {0, 0, 0}), sun, 10, body, 2)
    assert g.metadata["regime"] == "umbra"
    assert g.metadata["visible_fraction"] == 0
  end

  test "annular geometry stays partially illuminated and the overlap formula has analytic limits" do
    observer = state(5, {0, 0, 0})
    sun = fixed({100, 0, 0})
    small = fixed({10, 0, 0})
    assert {:ok, g} = Occultations.geometry(observer, sun, 10, small, 0.25)
    assert g.metadata["regime"] == "antumbra"
    expected = 1 - :math.pow(:math.asin(0.025) / :math.asin(0.1), 2)
    assert_in_delta g.metadata["visible_fraction"], expected, 1.0e-12
    assert g.metadata["visible_fraction"] > 0 and g.metadata["visible_fraction"] < 1

    assert_in_delta Occultations.visible_fraction(0.1, 0.1, 0.1),
                    1 / 3 + :math.sqrt(3) / (2 * :math.pi()),
                    1.0e-12

    assert Occultations.visible_fraction(0.1, 0.2, 0) == 0
    assert Occultations.visible_fraction(0.1, 0.2, 0.4) == 1
    moving = source(fn t -> {:ok, state(t, {10, t - 5, 0}, {0, 1, 0})} end)

    assert {:ok, r} =
             run(
               Occultations.functions("annular", sun, 10, moving, 0.25, value_tolerance: 1.0e-12)
             )

    assert Enum.at(r["results"], 1)["events"] == []
    assert length(Enum.at(r["results"], 2)["events"]) == 2
  end

  test "occultation background ordering, overlap and frame mismatch do not silently become eclipses" do
    observer = state(0, {0, 0, 0})
    assert {:ok, g} = Occultations.geometry(observer, fixed({10, 0, 0}), 1, fixed({100, 0, 0}), 2)
    assert g.metadata["visible_fraction"] == 1

    assert {:error, :overlapping_occultation_bodies} =
             Occultations.geometry(observer, fixed({10, 0, 0}), 2, fixed({11, 0, 0}), 2)

    bad =
      Source.new!(
        fn t -> {:ok, %{state(t, {10, 0, 0}) | frame: Frame.earth_inertial_j2000()}} end,
        Epoch.new!(-1, :tai),
        Epoch.new!(11, :tai),
        Frame.earth_inertial_j2000(),
        %{}
      )

    assert_raise ArgumentError, fn ->
      Occultations.geometry(observer, bad, 1, fixed({2, 0, 0}), 0.2)
    end
  end

  test "osculating true anomaly returns unknown for a circular orbit" do
    mu = 8.0

    circle =
      source(fn t ->
        {:ok,
         state(
           t,
           {2 * :math.cos(t), 2 * :math.sin(t), 0},
           {-2 * :math.sin(t), 2 * :math.cos(t), 0}
         )}
      end)

    f = Thresholds.true_anomaly("anomaly", mu, 1.0e-8, 90, value_tolerance: 1.0e-10)
    assert {:ok, r} = run(f, circle)
    assert r["status"] == "unknown"
    assert times(r) == []
  end

  test "secondary queries and finite-difference callbacks share the global budget and cache" do
    observer = fixed({-2, 0, 0})

    other =
      source(fn t ->
        send(self(), {:secondary_query, t})
        {:ok, state(t, {2, t - 5, 0}, {0, 1, 0})}
      end)

    a = Geometry.relative_distance("a", other, 5, value_tolerance: 1.0e-10)
    b = Geometry.relative_distance("b", other, 5, value_tolerance: 1.0e-10)
    assert {:ok, r} = run([a, b], observer)
    queries = secondary_queries([])
    assert length(queries) == length(Enum.uniq_by(queries, &(&1 * 1.0)))
    assert r["source_query_count"] >= 2 * length(queries)

    assert {:error, :event_search_evaluation_budget_exhausted} =
             run(a, observer, max_evaluations: 5)

    target = Target.new!("station", 0, 0, minimum_elevation_deg: 0)
    scalar = Geometry.access("elevation", scene(), target, 0, value_tolerance: 1.0e-10)
    extrema = Extrema.function("maximum", observer, scalar, 0.001, value_tolerance: 1.0e-5)

    assert {:error, :event_search_evaluation_budget_exhausted} =
             run(extrema, observer, max_evaluations: 8)

    # A failed search must not leave a process-local budget active.
    assert {:ok, _} = run(a, observer)
  end

  defp secondary_queries(acc) do
    receive do
      {:secondary_query, t} -> secondary_queries([t | acc])
    after
      0 -> acc
    end
  end

  test "existing detector families expose the same canonical search engine" do
    station = OrbitalDynamics.GroundStation.new!("station", 0, 0, minimum_elevation_deg: 0)
    target = Target.new!("target", 0, 0, minimum_elevation_deg: 0)

    controls = [
      starts_at: Epoch.new!(0, :tai),
      ends_at: Epoch.new!(10, :tai),
      max_check_step_s: 0.5,
      time_tolerance_s: 1.0e-7,
      max_iterations: 64,
      max_evaluations: 10000
    ]

    assert {:ok, a} =
             OrbitalDynamics.EventDetectors.AccessWindows.search(
               fixed({2, 0, 0}),
               scene(),
               station,
               1.0e-10,
               controls
             )

    assert {:ok, b} =
             OrbitalDynamics.EventDetectors.TargetVisibility.search(
               fixed({2, 0, 0}),
               scene(),
               target,
               1.0e-10,
               controls
             )

    assert hd(a["results"])["condition_windows"] == hd(b["results"])["condition_windows"]

    assert {:ok, r} =
             OrbitalDynamics.EventDetectors.GroundTrackCrossings.search(
               fixed({2, 0, 0}),
               scene(),
               :longitude,
               90,
               1.0e-10,
               controls
             )

    assert_in_delta hd(times(r)), 7.5, 1.0e-7
    body = source(fn t -> {:ok, state(t, {10, t - 5, 0}, {0, 1, 0})} end)

    assert {:ok, r} =
             OrbitalDynamics.EventDetectors.Eclipses.search(
               fixed({0, 0, 0}),
               fixed({100, 0, 0}),
               10,
               body,
               2,
               1.0e-12,
               controls
             )

    assert length(r["results"]) == 4
  end

  test "umbra/antumbra contact functions stay continuous when apparent radii exchange order" do
    observer = state(0, {0, 0, 0})
    sun = fixed({100, 0, 0})
    body = source(fn t -> {:ok, state(t, {9 + 0.2 * t, 0, 0}, {0.2, 0, 0})} end)

    for t <- [4.9999, 5.0001] do
      assert {:ok, g} =
               Occultations.geometry(%{observer | epoch: Epoch.new!(t, :tai)}, sun, 10, body, 1)

      assert abs(g.umbra) < 1.0e-5
      assert abs(g.antumbra) < 1.0e-5
    end

    assert {:ok, r} =
             run(Occultations.functions("swap", sun, 10, body, 1, value_tolerance: 1.0e-12))

    umbra = Enum.at(r["results"], 1)
    antumbra = Enum.at(r["results"], 2)
    assert_in_delta hd(umbra["events"])["epoch_s"], 5, 1.0e-7
    assert_in_delta hd(antumbra["events"])["epoch_s"], 5, 1.0e-7
  end

  test "composition honors negative-is-true conditions and rejects point-only children" do
    a =
      Function.new!("negative", fn s -> {:ok, s.epoch.seconds_since_j2000 - 5, 1, %{}} end,
        units: "s",
        value_tolerance: 1.0e-10,
        condition: :nonpositive
      )

    b =
      Function.new!("positive", fn s -> {:ok, s.epoch.seconds_since_j2000 - 2, 1, %{}} end,
        units: "s",
        value_tolerance: 1.0e-10,
        condition: :nonnegative
      )

    f = Function.combine("mixed", [{a, 1}, {b, 1}], :all, value_tolerance: 1.0e-10)
    assert {:ok, r} = run(f)
    [window] = hd(r["results"])["condition_windows"]
    assert_in_delta window["starts_at_s"], 2, 1.0e-7
    assert_in_delta window["ends_at_s"], 5, 1.0e-7

    assert_raise ArgumentError, fn ->
      Function.combine("bad", [{%{b | condition: :none}, 1}], :all, value_tolerance: 1.0e-10)
    end
  end

  test "body-axis limb contacts follow the apparent spherical angular radius" do
    pose = fn epoch ->
      {:ok,
       Pointing.new!(
         frame(),
         OrbitalDynamics.MissionAnalysis.Attitude.Quaternion.increment(
           {0, 0, (epoch.seconds_since_j2000 - 5) * 10}
         )
       )}
    end

    f = Geometry.limb_clearance("limb", pose, {-1, 0, 0}, 1, value_tolerance: 1.0e-10)
    assert {:ok, r} = run(f, fixed({2, 0, 0}))
    assert length(times(r)) == 2

    for {time, expected} <- Enum.zip(times(r), [2, 8]),
        do: assert_in_delta(time, expected, 1.0e-7)
  end
end
