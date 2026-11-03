defmodule OrbitalDynamics.EventSearch.SearchTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.{Epoch, Frame, StateVector, Trajectory, EventDetector, EventSearch}
  alias OrbitalDynamics.EventSearch.{Source, Function}
  alias OrbitalDynamics.EventDetectors.{Nodes, Apsides, Thresholds}
  defp frame, do: Frame.new!(:toy, :toy, :inertial)
  defp state(t), do: StateVector.new!({t, 1, 0}, {1, 0, 0}, Epoch.new!(t, :tai), frame())

  defp source(callback \\ fn t -> {:ok, state(t)} end, a \\ 0, b \\ 10),
    do:
      Source.new!(callback, Epoch.new!(a, :tai), Epoch.new!(b, :tai), frame(), %{
        "evaluation" => "analytic_test_state"
      })

  defp function(id, fun, opts \\ []),
    do: Function.new!(id, fun, [units: "test", value_tolerance: 1.0e-10] ++ opts)

  defp controls(opts \\ []),
    do:
      Keyword.merge(
        [
          starts_at: Epoch.new!(0, :tai),
          ends_at: Epoch.new!(10, :tai),
          max_check_step_s: 3,
          time_tolerance_s: 1.0e-7,
          max_iterations: 64,
          max_evaluations: 10000,
          include_samples: true
        ],
        opts
      )

  defp search(f, opts \\ [], s \\ source()), do: EventSearch.run(s, List.wrap(f), controls(opts))
  defp result(report), do: hd(report["results"])

  test "refines directed crossings and estimated windows with explicit timing brackets" do
    f =
      function("cross", fn s -> {:ok, s.epoch.seconds_since_j2000 - 4.3, 1, %{}} end,
        condition: :nonnegative
      )

    assert {:ok, report} = search(f)
    assert report["status"] == "complete_under_search_policy"
    [event] = result(report)["events"]
    assert event["direction"] == "increasing"
    assert event["bracket_start_s"] <= 4.3 and event["bracket_end_s"] >= 4.3
    assert event["bracket_width_s"] <= 1.0e-7
    assert event["timing_target"] == "event_function_zero"
    [window] = result(report)["condition_windows"]
    assert_in_delta window["starts_at_s"], 4.3, 1.0e-7
    assert window["ends_at_s"] == 10
    assert window["start_boundary"]["kind"] == "estimated_event"
    assert window["end_boundary"]["kind"] == "scan_or_search_clip"
    assert :json.encode(report) |> IO.iodata_length() > 0
  end

  test "observed derivative extremum discovers two roots hidden within a scan interval" do
    f =
      function(
        "island",
        fn s ->
          t = s.epoch.seconds_since_j2000
          {:ok, (t - 5) * (t - 5) - 1, 2 * (t - 5), %{}}
        end,
        condition: :nonpositive
      )

    assert {:ok, r} = search(f, max_check_step_s: 10)

    assert Enum.map(result(r)["events"], & &1["epoch_s"])
           |> Enum.zip([4, 6])
           |> Enum.all?(fn {a, b} -> abs(a - b) < 1.0e-7 end)

    [window] = result(r)["condition_windows"]
    assert_in_delta window["starts_at_s"], 4, 1.0e-7
    assert_in_delta window["ends_at_s"], 6, 1.0e-7
  end

  test "grazing tolerance contacts identify a stationary point without claiming a scalar zero" do
    f =
      function("graze", fn s ->
        t = s.epoch.seconds_since_j2000
        {:ok, (t - 4.3) * (t - 4.3), 2 * (t - 4.3), %{}}
      end)

    assert {:ok, r} = search(f, max_check_step_s: 10)
    [event] = result(r)["events"]
    assert event["direction"] == "touching"
    assert_in_delta event["epoch_s"], 4.3, 1.0e-7
    assert event["timing_target"] == "stationary_point_not_proven_function_zero"
    assert event["value"] <= 1.0e-10

    near =
      function("near", fn s ->
        t = s.epoch.seconds_since_j2000
        {:ok, (t - 4.3) * (t - 4.3) + 1.0e-11, 2 * (t - 4.3), %{}}
      end)

    assert {:ok, r} = search(near, max_check_step_s: 10)
    assert hd(result(r)["events"])["value"] > 0
    assert hd(result(r)["events"])["event_class"] == "stationary_contact_within_value_tolerance"
  end

  test "grazes without derivative evidence are explicitly outside the discovery guarantee" do
    f =
      function("no_rate", fn s ->
        t = s.epoch.seconds_since_j2000
        {:ok, (t - 4.3) * (t - 4.3), nil, %{}}
      end)

    assert {:ok, r} = search(f, max_check_step_s: 10)
    assert result(r)["events"] == []
    assert Enum.any?(r["limits"], &String.contains?(&1, "no proof"))
  end

  test "flat and near-flat zero paths do not fabricate isolated events" do
    for value <- [0, 1.0e-12] do
      f = function("flat", fn _ -> {:ok, value, 0, %{}} end)
      assert {:ok, r} = search(f)
      assert r["status"] == "unknown"
      assert result(r)["events"] == []

      assert Enum.all?(
               result(r)["uncovered_intervals"],
               &(&1["reason"] == "nonisolated_or_underresolved_zero")
             )
    end
  end

  test "unknown scan or refinement samples are never bridged; providers and budgets fail closed" do
    f = function("cross", fn s -> {:ok, s.epoch.seconds_since_j2000 - 5.3, 1, %{}} end)

    hole =
      source(fn t ->
        if t > 4 and t < 6, do: {:unknown, :missing_state}, else: {:ok, state(t)}
      end)

    assert {:ok, r} = search(f, [], hole)
    assert r["status"] == "unknown"
    assert result(r)["events"] == []
    assert result(r)["uncovered_intervals"] != []
    assert {:error, :source_down} = search(f, [], source(fn _ -> {:error, :source_down} end))
    assert {:error, :event_search_evaluation_budget_exhausted} = search(f, max_evaluations: 1)
    assert {:ok, r} = search(f, max_iterations: 1)
    assert r["status"] == "unknown"
    assert result(r)["events"] == []
  end

  test "bounded source coverage leaves gaps while retaining observed interior events" do
    f = function("cross", fn s -> {:ok, s.epoch.seconds_since_j2000 - 5, 1, %{}} end)

    assert {:ok, r} =
             search(f, [starts_at: Epoch.new!(-3, :tai), ends_at: Epoch.new!(13, :tai)], source())

    assert r["status"] == "unknown"
    assert length(result(r)["events"]) == 1
    assert Enum.any?(result(r)["uncovered_intervals"], &(&1["starts_at_s"] < 0))
    assert Enum.any?(result(r)["uncovered_intervals"], &(&1["ends_at_s"] > 10))
  end

  test "exact sample roots deduplicate, direction filters apply and boundary ambiguity is explicit" do
    f = function("root", fn s -> {:ok, s.epoch.seconds_since_j2000 - 3, 1, %{}} end)
    assert {:ok, r} = search(f)
    assert length(result(r)["events"]) == 1
    f = %{f | direction: :decreasing}
    assert {:ok, r} = search(f)
    assert result(r)["events"] == []

    f =
      function("boundary", fn s -> {:ok, s.epoch.seconds_since_j2000, nil, %{}} end,
        direction: :increasing
      )

    assert {:ok, r} = search(f)
    assert r["status"] == "unknown"
  end

  test "source/frame/time validation is strict and shared state queries are cached across functions" do
    sampler = fn t ->
      send(self(), {:queried, t * 1.0})
      {:ok, state(t)}
    end

    make = fn id -> function(id, fn s -> {:ok, s.epoch.seconds_since_j2000 - 4.3, 1, %{}} end) end
    assert {:ok, r} = search([make.("a"), make.("b")], [], source(sampler))
    times = drain([])
    assert length(times) == length(Enum.uniq(times))
    assert length(times) == r["source_query_count"]
    assert r["function_evaluation_count"] > r["source_query_count"]
    wrong = source(fn t -> {:ok, %{state(t) | frame: Frame.earth_inertial_j2000()}} end)
    assert {:error, {:invalid_event_search, _}} = search(make.("a"), [], wrong)

    assert {:error, {:invalid_event_search, _}} =
             search(make.("a"), starts_at: Epoch.new!(0, :utc))

    assert {:error, {:invalid_event_search, _}} = search([make.("a"), make.("a")])
  end

  defp drain(acc) do
    receive do
      {:queried, t} -> drain([t | acc])
    after
      0 -> acc
    end
  end

  test "explicit Hermite source preserves polynomial state/velocity and its timing scope" do
    poly = fn t ->
      StateVector.new!({t * t, 1, 0}, {2 * t, 0, 0}, Epoch.new!(t, :tai), frame())
    end

    trajectory = %Trajectory{scenario_id: "poly", states: [poly.(0), poly.(10)], assumptions: %{}}
    source = Source.from_trajectory!(trajectory, interpolation: :cubic_hermite)
    assert {:ok, state} = Source.at(source, 3.5)
    assert_in_delta elem(state.position_km, 0), 12.25, 1.0e-12
    assert_in_delta elem(state.velocity_km_s, 0), 7, 1.0e-12

    f =
      Thresholds.scalar(
        "x",
        fn s -> {:ok, elem(s.position_km, 0), elem(s.velocity_km_s, 0), %{}} end,
        25,
        units: "km",
        value_tolerance: 1.0e-9
      )

    assert {:ok, r} = search(f, [], source)
    assert_in_delta hd(result(r)["events"])["epoch_s"], 5, 1.0e-7
    assert r["source"]["provenance"]["evaluation"] == "cubic_hermite_sample_interpolant"
  end

  defp ellipse(t) do
    a = 2.0
    e = 0.25
    n = :math.sqrt(1 / (a * a * a))
    mean = n * t + 0.37

    anomaly =
      Enum.reduce(1..20, mean, fn _, x ->
        x - (x - e * :math.sin(x) - mean) / (1 - e * :math.cos(x))
      end)

    factor = :math.sqrt(1 - e * e)
    x = a * (:math.cos(anomaly) - e)
    y = a * factor * :math.sin(anomaly)
    vx = -a * n * :math.sin(anomaly) / (1 - e * :math.cos(anomaly))
    vy = a * n * factor * :math.cos(anomaly) / (1 - e * :math.cos(anomaly))
    inclination = :math.pi() / 6

    StateVector.new!(
      {x, y * :math.cos(inclination), y * :math.sin(inclination)},
      {vx, vy * :math.cos(inclination), vy * :math.sin(inclination)},
      Epoch.new!(t, :tai),
      frame()
    )
  end

  test "nodes and apsides match independently specified Kepler contact times" do
    n = :math.sqrt(1 / 8)
    period = 2 * :math.pi() / n
    src = source(fn t -> {:ok, ellipse(t)} end, 0, period * 1.1)

    functions = [
      Nodes.function("nodes", {0, 0, 1}, value_tolerance: 1.0e-10),
      Apsides.function("apsides", value_tolerance: 1.0e-10)
    ]

    assert {:ok, r} =
             EventDetector.search(
               src,
               functions,
               controls(ends_at: Epoch.new!(period * 1.1, :tai), max_check_step_s: 1)
             )

    for result <- r["results"] do
      assert length(result["events"]) == 2

      for {event, time} <-
            Enum.zip(result["events"], [(:math.pi() - 0.37) / n, (2 * :math.pi() - 0.37) / n]),
          do: assert_in_delta(event["epoch_s"], time, 1.0e-7)
    end

    assert Enum.map(Enum.at(r["results"], 0)["events"], & &1["type"]) == [
             "descending_node",
             "ascending_node"
           ]

    assert Enum.map(Enum.at(r["results"], 1)["events"], & &1["type"]) == ["apoapsis", "periapsis"]
  end

  test "detector behaviour adapters require explicit interpolation and retain model evidence" do
    states = Enum.map(0..20, &ellipse/1)
    trajectory = %Trajectory{scenario_id: "ellipse", states: states, assumptions: %{}}

    assert {:ok, events} =
             Nodes.detect(trajectory,
               normal: {0, 0, 1},
               value_tolerance: 1.0e-10,
               interpolation: :cubic_hermite,
               search: controls(ends_at: Epoch.new!(20, :tai), max_check_step_s: 1)
             )

    assert Enum.map(events, & &1.type) == [:descending_node, :ascending_node]

    assert hd(events).metadata["state_source"]["provenance"]["evaluation"] ==
             "cubic_hermite_sample_interpolant"

    assert {:ok, events} =
             Apsides.detect(trajectory,
               value_tolerance: 1.0e-10,
               interpolation: :cubic_hermite,
               search: controls(ends_at: Epoch.new!(20, :tai), max_check_step_s: 1)
             )

    assert Enum.map(events, & &1.type) == [:apoapsis, :periapsis]

    assert {:error, {:invalid_event_search, _}} =
             Nodes.detect(trajectory,
               normal: {0, 0, 1},
               value_tolerance: 1.0e-10,
               search: controls()
             )
  end

  test "window midpoint contradictions cannot fabricate a full interval or conceal an observed island" do
    for sign <- [-1, 1] do
      f =
        function(
          "island",
          fn s ->
            t = s.epoch.seconds_since_j2000
            {:ok, sign * ((t - 0.5) * (t - 0.5) - 0.1), nil, %{}}
          end,
          condition: :nonpositive
        )

      assert {:ok, r} = search(f, max_check_step_s: 1, ends_at: Epoch.new!(1, :tai))
      assert r["status"] == "unknown"
      assert result(r)["condition_windows"] == []

      assert hd(result(r)["uncovered_intervals"])["reason"] ==
               "unresolved_crossings_observed_by_window_midpoint"
    end
  end

  test "small endpoint residuals do not excuse observed failures outside root uncertainty bands" do
    f =
      function(
        "island",
        fn s ->
          t = s.epoch.seconds_since_j2000
          {:ok, (t - 1.0e-12) * (t - 0.48) * (t - 0.9), nil, %{}}
        end,
        condition: :nonnegative
      )

    assert {:ok, r} = search(f, max_check_step_s: 1, ends_at: Epoch.new!(1, :tai))
    assert r["status"] == "unknown"

    refute Enum.any?(
             result(r)["condition_windows"],
             &(&1["starts_at_s"] == 0 and &1["ends_at_s"] == 1)
           )

    assert result(r)["uncovered_intervals"] != []
  end

  test "invalid nested rates and ignored nested provider errors fail closed and restore context" do
    bad = function("bad", fn _ -> {:ok, 1, :invalid_rate, %{}} end, condition: :nonnegative)
    composite = Function.combine("parent", [{bad, 1}], :all, value_tolerance: 1.0e-10)
    assert {:error, {:invalid_event_search, _}} = search(composite)
    down = source(fn _ -> {:error, :nested_provider_down} end)

    outer =
      function("outer", fn state ->
        Source.at(down, state.epoch.seconds_since_j2000)
        {:ok, 1, 0, %{}}
      end)

    assert {:error, :nested_provider_down} = search(outer)
    assert {:error, :nested_provider_down} = Source.at(down, 0)
    assert {:ok, _} = search(function("valid", fn _ -> {:ok, 1, 0, %{}} end))
  end

  test "circular apsides and equatorial nodes have no invented isolated event times" do
    circle =
      source(fn t ->
        {:ok,
         StateVector.new!(
           {:math.cos(t), :math.sin(t), 0},
           {-:math.sin(t), :math.cos(t), 0},
           Epoch.new!(t, :tai),
           frame()
         )}
      end)

    assert {:ok, r} =
             search(
               [
                 Apsides.function("apsides", value_tolerance: 1.0e-10),
                 Nodes.function("nodes", {0, 0, 1}, value_tolerance: 1.0e-10)
               ],
               [],
               circle
             )

    assert r["status"] == "unknown"
    assert Enum.all?(r["results"], &(&1["events"] == []))
  end

  test "optional function observations retain nested refinement evidence without extra work or changing ordinary reports" do
    model =
      function("model", fn s -> {:ok, 1, nil, %{"epoch" => s.epoch.seconds_since_j2000}} end)

    crossing =
      function("constraint", fn s ->
        {:ok, _, _, m} = Function.call(model, s)
        {:ok, m["epoch"] - 4.3, nil, %{}}
      end)

    fs = [model, crossing]
    assert {:ok, ordinary} = EventSearch.run(source(), fs, controls())

    assert {:ok, recorded} =
             EventSearch.run(source(), fs, controls(record_function_observations: ["model"]))

    assert Map.drop(recorded, ["recorded_function_ids", "function_observations"]) == ordinary

    assert Enum.any?(
             recorded["function_observations"],
             &(&1["epoch_s"] == 4.5 and &1["metadata"]["epoch"] == 4.5)
           )

    assert {:error, {:invalid_event_search, _}} =
             EventSearch.run(source(), fs, controls(record_function_observations: ["missing"]))

    assert OrbitalDynamics.EventSearch.Context.current() == nil
  end
end
