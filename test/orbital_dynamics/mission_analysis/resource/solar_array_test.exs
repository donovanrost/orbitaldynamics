defmodule OrbitalDynamics.MissionAnalysis.Resource.SolarArrayTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.{CentralBody, Epoch, Frame, StateVector, Vector3}
  alias OrbitalDynamics.MissionAnalysis.{SphericalScene, Environments.Fixed}
  alias OrbitalDynamics.MissionAnalysis.Attitude.{Pointing, Quaternion}
  alias OrbitalDynamics.MissionAnalysis.Resource.{Battery, Generation.SolarArray}

  defp frame, do: Frame.new!(:toy, :toy, :inertial)

  defp scene(provider \\ Fixed) do
    environment =
      Fixed.new!(frame(), Epoch.new!(0, :tai),
        starts_at_s: 0,
        ends_at_s: 4000,
        sun_direction: {1, 0, 0},
        rotation_rate_rad_s: 0,
        rotation_angle_rad: 0
      )

    SphericalScene.new!(
      CentralBody.new!(:toy, 1, equatorial_radius_km: 1),
      frame(),
      :tai,
      {provider, environment}
    )
  end

  defp config do
    %{
      "kind" => "solar_array",
      "shadow_model" => "cylindrical_point_sun",
      "solar_irradiance_w_m2" => 1000,
      "bus_efficiency" => 0.8,
      "panels" => [
        %{"id" => "panel", "area_m2" => 2, "efficiency" => 0.25, "normal_body" => [1, 0, 0]}
      ]
    }
  end

  defp input(position \\ {2, 0, 0}, q \\ {1, 0, 0, 0}, t \\ 0) do
    %{
      epoch_s: t,
      interval_start_s: t,
      interval_end_s: t,
      spacecraft_state: StateVector.new!(position, {0, 0, 0}, Epoch.new!(t, :tai), frame()),
      pointing: Pointing.new!(frame(), q),
      phase: "hold",
      mode: %{"name" => "standby", "parameters" => %{"power_load_w" => 100}}
    }
  end

  defp session(c \\ config(), context \\ scene()) do
    {:ok, session, _} = SolarArray.prepare(nil, context, c)
    session
  end

  test "panel projection, one-sidedness and electrical efficiencies have analytic outputs" do
    s = session()
    assert {:ok, watts, metrics} = SolarArray.evaluate(input(), s)
    assert_in_delta watts, 400, 1.0e-12
    assert metrics["spacecraft_sunlit"]

    assert {:ok, watts, _} =
             SolarArray.evaluate(input({2, 0, 0}, Quaternion.increment({0, 0, 60})), s)

    assert_in_delta watts, 200, 1.0e-10

    assert {:ok, watts, _} =
             SolarArray.evaluate(input({2, 0, 0}, Quaternion.increment({0, 0, 90})), s)

    assert abs(watts) < 1.0e-10

    assert {:ok, +0.0, _} =
             SolarArray.evaluate(input({2, 0, 0}, Quaternion.increment({0, 0, 180})), s)

    c = put_in(config(), ["panels", Access.at(0), "normal_body"], [0, 0, 1])

    assert {:ok, watts, _} =
             SolarArray.evaluate(input({2, 0, 0}, Quaternion.increment({0, 90, 0})), session(c))

    assert_in_delta watts, 400, 1.0e-10
  end

  test "opposed panels remain single-sided and do not count a back face twice" do
    [p] = config()["panels"]
    c = %{config() | "panels" => [p, %{p | "id" => "rear", "normal_body" => [-1, 0, 0]}]}
    assert {:ok, watts, metrics} = SolarArray.evaluate(input(), session(c))
    assert_in_delta watts, 400, 1.0e-12
    assert Enum.map(metrics["panels"], & &1["generation_w"]) == [400.0, 0.0]
  end

  test "cylindrical shadow distinguishes umbra, near-limb and explicitly defined tangency" do
    s = session()

    for position <- [{-2, 0, 0}, {-2, 1 - 1.0e-7, 0}] do
      assert {:ok, +0.0, metrics} = SolarArray.evaluate(input(position), s)
      refute metrics["spacecraft_sunlit"]
      assert metrics["shadow_margin_km"] < 0
    end

    for position <- [{-2, 1 + 1.0e-7, 0}, {-2, 1, 0}, {2, 0, 0}] do
      assert {:ok, watts, metrics} = SolarArray.evaluate(input(position), s)
      assert watts == 400
      assert metrics["spacecraft_sunlit"]
    end
  end

  test "shadow entry and exit agree with independent circular-orbit contact angles" do
    # A radius-2 circle around a radius-1 sphere and Sun along +X has
    # contacts pi +/- asin(1/2), or t=50 and70 for a 120-second period.
    s = session()

    for {t, expected} <- [{49.9999, true}, {50.0001, false}, {69.9999, false}, {70.0001, true}] do
      theta = 2 * :math.pi() * t / 120

      assert {:ok, _, m} =
               SolarArray.evaluate(
                 input({2 * :math.cos(theta), 2 * :math.sin(theta), 0}, {1, 0, 0, 0}, t),
                 s
               )

      assert m["spacecraft_sunlit"] == expected
    end
  end

  test "seeded shadow cases match a separate forward ray-sphere intersection calculation" do
    :rand.seed(:exsss, {711, 903, 112})
    s = session()

    for _ <- 1..128 do
      r = {6 * :rand.uniform() - 3, 6 * :rand.uniform() - 3, 6 * :rand.uniform() - 3}

      if Vector3.norm(r) > 1.01 do
        # Ray from spacecraft toward Sun: |r + t*[1,0,0]|² =1.
        {x, _, _} = r
        b = 2 * x
        c = Vector3.dot(r, r) - 1
        disc = b * b - 4 * c
        hit = disc > 0 and ((-b - :math.sqrt(disc)) / 2 > 0 or (-b + :math.sqrt(disc)) / 2 > 0)
        assert {:ok, _, m} = SolarArray.evaluate(input(r), s)
        assert m["spacecraft_sunlit"] == not hit
      end
    end
  end

  test "missing environment, finite coverage and unknown panel inputs cannot become zero charging" do
    assert {:unknown, :solar_environment_missing} =
             SolarArray.evaluate(input(), session(config(), nil))

    assert {:unknown, :solar_environment_outside_coverage} =
             SolarArray.evaluate(input({2, 0, 0}, {1, 0, 0, 0}, 4001), session())

    assert {:unknown, :solar_environment_outside_coverage} =
             SolarArray.evaluate(%{input() | interval_end_s: 4001}, session())

    for c <- [
          Map.put(config(), "solar_irradiance_w_m2", :null),
          Map.put(config(), "bus_efficiency", :null),
          put_in(config(), ["panels", Access.at(0), "normal_body"], :null),
          put_in(config(), ["panels", Access.at(0), "area_m2"], :null)
        ] do
      assert {:unknown, :solar_configuration_unknown} = SolarArray.evaluate(input(), session(c))
    end

    assert {:error, :solar_pointing_frame_mismatch} =
             SolarArray.evaluate(
               %{input() | pointing: Pointing.new!(Frame.earth_inertial_j2000(), {1, 0, 0, 0})},
               session()
             )
  end

  defmodule Down do
    def at(_, _), do: {:error, :solar_source_down}
    def describe(_), do: %{"coverage" => %{"starts_at_s" => 0, "ends_at_s" => 4000}}
  end

  test "provider failure remains an analysis error and bad array configuration is rejected" do
    assert {:error, :solar_source_down} =
             SolarArray.evaluate(input(), session(config(), scene(Down)))

    assert_raise ArgumentError, fn ->
      session(put_in(config(), ["panels", Access.at(0), "efficiency"], 1.1))
    end

    assert_raise ArgumentError, fn ->
      session(put_in(config(), ["panels", Access.at(0), "normal_body"], [0, 0, 0]))
    end
  end

  defp battery_config do
    %{
      "initial_wh" => 10,
      "capacity_wh" => 1000,
      "reserve_wh" => 0,
      "charge_efficiency" => 0.9,
      "discharge_efficiency" => 0.8,
      "phase_load_w" => %{"hold" => 0},
      "generation" => config()
    }
  end

  test "solar bus conversion and battery charge conversion apply once each" do
    {:ok, b, _} = Battery.prepare(nil, scene(), battery_config())
    assert {:ok, next, result} = Battery.step(Battery.initial(b), input(), 3600, b)
    assert_in_delta result.metrics["generation_w"], 400, 1.0e-12
    assert_in_delta result.metrics["battery_power_w"], 270, 1.0e-12
    assert_in_delta next["energy_wh"], 280, 1.0e-10
  end

  defmodule Custom do
    @behaviour OrbitalDynamics.MissionAnalysis.Resource.Generation
    def prepare(_, _, c) do
      token = make_ref()
      send(self(), {:source_prepared, token})
      {:ok, %{token: token, config: c}, Map.get(c, "assumptions", %{})}
    end

    def boundaries(_), do: [10]

    def evaluate(input, s) do
      send(self(), {:source_evaluated, s.token, input.phase})

      case s.config["status"] do
        "unknown" -> {:unknown, :source_unknown}
        "error" -> {:error, :source_down}
        _ -> {:ok, 200, %{"source" => "custom"}}
      end
    end
  end

  test "trusted generation providers capture opaque sessions once and validate assumptions" do
    {:ok, b, _} = Battery.prepare_with_generation(nil, nil, battery_config(), {Custom, %{}})
    assert_receive {:source_prepared, token}
    assert Battery.boundaries(b) == [10]
    assert {:ok, next, _} = Battery.step(Battery.initial(b), input(), 1, b)
    assert {:ok, _, _} = Battery.step(next, input(), 1, b)
    assert_receive {:source_evaluated, ^token, "hold"}
    assert_receive {:source_evaluated, ^token, "hold"}
    refute_receive {:source_prepared, _}

    for assumptions <- [nil, [], %{"bad" => make_ref()}] do
      assert_raise ArgumentError, fn ->
        Battery.prepare_with_generation(
          nil,
          nil,
          battery_config(),
          {Custom, %{"assumptions" => assumptions}}
        )
      end
    end

    {:ok, b, _} =
      Battery.prepare_with_generation(
        nil,
        nil,
        battery_config(),
        {Custom, %{"status" => "error"}}
      )

    assert {:error, :source_down} = Battery.step(Battery.initial(b), input(), 1, b)

    {:ok, b, _} =
      Battery.prepare_with_generation(
        nil,
        nil,
        battery_config(),
        {Custom, %{"status" => "unknown"}}
      )

    assert {:ok, _, result} = Battery.step(Battery.initial(b), input(), 1, b)
    assert OrbitalDynamics.MissionAnalysis.Path.Result.status(result) == "unknown"
  end

  test "solar direction is an explicit scene input rather than a fixed inertial axis" do
    original = scene()

    context = %{
      original
      | environment_config: %{original.environment_config | sun_direction: {0, 1, 0}}
    }

    s = session(config(), context)
    q = Quaternion.increment({0, 0, 90})
    assert {:ok, watts, m} = SolarArray.evaluate(input({0, 2, 0}, q), s)
    assert_in_delta watts, 400, 1.0e-10
    assert m["sun_direction_inertial"] == [0.0, 1.0, 0.0]
    assert {:ok, watts, m} = SolarArray.evaluate(input({0, -2, 0}, q), s)
    assert watts == 0
    refute m["spacecraft_sunlit"]
  end

  defp finite_config do
    Map.merge(config(), %{
      "shadow_model" => "finite_sun",
      "solar_radius_km" => 1,
      "solar_distance_km" => 100,
      "event_search" => %{
        "max_check_step_s" => 0.1,
        "time_tolerance_s" => 0.00001,
        "max_iterations" => 64,
        "max_evaluations" => 10000
      }
    })
  end

  test "finite-Sun power distinguishes full sunlight, penumbra and umbra" do
    s = session(finite_config())
    assert {:ok, lit, m} = SolarArray.evaluate(input(), s)
    assert_in_delta lit, 400, 1.0e-10
    assert m["visible_fraction"] == 1
    assert {:ok, +0.0, m} = SolarArray.evaluate(input({-2, 0, 0}), s)
    assert m["occultation_regime"] == "umbra"
    assert m["visible_fraction"] == 0
    assert {:ok, partial, m} = SolarArray.evaluate(input({-2, 1.02, 0}), s)
    assert m["occultation_regime"] == "penumbra"
    assert m["visible_fraction"] > 0 and m["visible_fraction"] < 1
    assert partial > 0 and partial < lit
  end

  test "finite-Sun contacts use the supplied runtime source, return brackets and fail closed on gaps/budget" do
    alias OrbitalDynamics.EventSearch.Source

    source =
      Source.new!(
        fn t ->
          {:ok,
           StateVector.new!(
             {2 * :math.cos(t), 2 * :math.sin(t), 0},
             {-2 * :math.sin(t), 2 * :math.cos(t), 0},
             Epoch.new!(t, :tai),
             frame()
           )}
        end,
        Epoch.new!(0, :tai),
        Epoch.new!(2 * :math.pi(), :tai),
        frame(),
        %{"evaluation" => "analytic_circle"}
      )

    s = session(finite_config())
    assert {:ok, boundaries, report} = SolarArray.search_boundaries(s, source)
    contacts = Enum.flat_map(report["results"], & &1["events"])
    assert length(contacts) == 4
    assert Enum.all?(contacts, &(&1["bracket_width_s"] <= 0.00001))
    assert Enum.all?(contacts, &(&1["epoch_s"] in boundaries))
    assert report["source"]["provenance"]["evaluation"] == "analytic_circle"

    gap = %{source | sampler: fn _ -> {:unknown, :missing_state} end}
    assert {:unknown, %{"status" => "unknown"}} = SolarArray.search_boundaries(s, gap)
    context = scene()
    context = %{context | environment_config: %{context.environment_config | ends_at_s: 1}}
    short_environment = session(finite_config(), context)

    assert {:unknown, %{"status" => "unknown"}} =
             SolarArray.search_boundaries(short_environment, source)

    small_budget = session(put_in(finite_config(), ["event_search", "max_evaluations"], 2))
    assert {:error, _} = SolarArray.search_boundaries(small_budget, source)
  end
end
