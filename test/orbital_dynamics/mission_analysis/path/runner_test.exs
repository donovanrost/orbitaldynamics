defmodule OrbitalDynamics.MissionAnalysis.Path.RunnerTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.{Epoch, Frame, StateVector, Trajectory}
  alias OrbitalDynamics.MissionAnalysis
  alias OrbitalDynamics.MissionAnalysis.{Asset, Request, Evaluation, WindowRefinement}
  alias OrbitalDynamics.MissionAnalysis.Attitude.{Pointing, Quaternion, Motion}
  alias OrbitalDynamics.MissionAnalysis.Attitude.Policy, as: AttitudePolicy
  alias OrbitalDynamics.MissionAnalysis.Path.{Policy, Result, Runner}

  defmodule Model do
    def capabilities, do: %{"id" => "path-test"}
    def prepare(r, _, _), do: {:ok, r.parameters, %{}}

    def evaluate(_, _, _),
      do: {:ok, Evaluation.new!([%{"id" => "physical", "passed" => true}], %{})}

    def pointing(state, p, _),
      do: {:ok, Pointing.new!(state.frame, Quaternion.increment({0, 0, p["angle"]}))}

    def activity_mode(mode, _) do
      status =
        case mode["parameters"]["service"] do
          "enabled" -> "supported"
          "disabled" -> "violated"
          _ -> "unknown"
        end

      {:ok, Result.new!([%{"id" => "service", "status" => status}], %{})}
    end
  end

  defmodule Check do
    @behaviour OrbitalDynamics.MissionAnalysis.Path.Check
    def prepare(_, _, config) do
      revision = Process.get(:path_prepare_count, 0) + 1
      Process.put(:path_prepare_count, revision)
      {:ok, {config, revision}, %{"revision" => revision}}
    end

    def evaluate(state, p, mode, {config, revision}) do
      t = state.epoch.seconds_since_j2000
      angle = Quaternion.distance_deg({1, 0, 0, 0}, p.quaternion)

      status =
        case config["kind"] do
          "dip" ->
            if t > 12.1 and t < 12.9, do: "violated", else: "supported"

          "orientation" ->
            if angle < 10, do: "violated", else: "supported"

          "outgoing" ->
            if t > 30 and t < 39 and angle > 40 and angle < 50, do: "violated", else: "supported"

          "unknown" ->
            "unknown"

          "error" ->
            :error

          _ ->
            "supported"
        end

      if status == :error,
        do: {:error, :source_down},
        else:
          {:ok,
           Result.new!([%{"id" => "guard", "status" => status}], %{
             "revision" => revision,
             "angle_deg" => angle,
             "mode" => mode
           })}
    end
  end

  defp frame, do: Frame.new!(:toy, :toy, :inertial)
  defp state(t), do: StateVector.new!({2000, 0, 0}, {0, 0, 0}, Epoch.new!(t, :tai), frame())

  defp asset,
    do:
      Asset.new!(
        "a",
        %Trajectory{scenario_id: "toy", states: Enum.map(0..100//5, &state/1), assumptions: %{}},
        %{Model => %{}},
        %{}
      )

  defp request(id \\ "r", opts \\ []) do
    Request.new!(id, Model, :opaque,
      activity_type: "activity",
      starts_at_s: Keyword.get(opts, :start, 20),
      ends_at_s: Keyword.get(opts, :stop, 30),
      duration_s: Keyword.get(opts, :duration, 2),
      time_scale: :tai,
      value: Keyword.get(opts, :value, 1),
      parameters: %{"angle" => Keyword.get(opts, :angle, 0)},
      resource_costs: %{}
    )
  end

  defp policy(kind, steps \\ [5, 0.25], opts \\ []) do
    modes =
      Keyword.get(opts, :modes, %{
        "on" => %{"service" => "enabled"},
        "off" => %{"service" => "disabled"},
        "unknown" => %{}
      })

    names = Keyword.get(opts, :requests, ["r"])
    activity_mode = Keyword.get(opts, :activity_mode, "on")

    a = %{
      activity_modes: Map.new(names, &{&1, activity_mode}),
      transition_mode: Keyword.get(opts, :transition_mode, "on"),
      modes: modes,
      rules: [%{id: "guard", module: Check, configuration: %{"kind" => kind}}]
    }

    Policy.new!(%{"a" => a},
      sample_steps_s: steps,
      max_evaluations: Keyword.get(opts, :budget, 10000),
      max_samples_per_segment: Keyword.get(opts, :samples, 1000)
    )
  end

  defp initial,
    do: %{
      epoch: Epoch.new!(0, :tai),
      frame: frame(),
      quaternion: {1, 0, 0, 0},
      angular_velocity_deg_s: {0, 0, 0}
    }

  defp plan(angle \\ 0) do
    pose = fn t ->
      %{
        "epoch_s" => t,
        "quaternion_wxyz" => Tuple.to_list(Quaternion.increment({0, 0, angle})),
        "angular_velocity_inertial_deg_s" => [0, 0, 0]
      }
    end

    {:ok, p} =
      Motion.transition(pose.(10), pose.(20), %{
        max_rate_deg_s: 10,
        max_accel_deg_s2: 10,
        settling_s: 0
      })

    p
  end

  defp runtime(p, requests \\ [request()]),
    do: %{path: Runner.prepare(p, %{"a" => asset()}, requests, nil)}

  defp run(p, requests \\ [request()]) do
    attitude = attitude(p)

    refinement =
      WindowRefinement.new!(
        state_at: fn _, t -> {:ok, state(t)} end,
        tracking_lookback_s: 1,
        time_tolerance_s: 0.01,
        max_extra_evaluations: 128
      )

    MissionAnalysis.run([asset()], requests, nil,
      max_sample_gap_s: 5,
      asset_separation_s: 0,
      window_refinement: refinement,
      attitude: attitude
    )
  end

  defp attitude(p, horizon \\ nil) do
    AttitudePolicy.new!(
      %{
        "a" => %{
          max_rate_deg_s: 10,
          max_accel_deg_s2: 10,
          settling_s: 0,
          initial: initial(),
          pointing_configurations: %{Model => %{}}
        }
      },
      profile_step_s: 1,
      derivative_step_s: 0.1,
      search_step_s: 1,
      max_candidate_starts: 100,
      max_evaluations: 10000,
      horizon: horizon,
      path_constraints: p
    )
  end

  test "coarse support and fine violation are both retained and any observed violation vetoes the path" do
    p = policy("dip")

    assert {:infeasible, :path_constraint_violated, evidence, _} =
             Runner.transition(
               asset(),
               plan(),
               "test",
               fn _, t -> {:ok, state(t)} end,
               runtime(p)
             )

    assert evidence["resolution_status"] == "changes_across_tested_steps"
    [coarse, fine] = evidence["levels"]
    assert coarse["status"] == "supported"
    assert fine["status"] == "violated"
    assert fine["first_issue"]["epoch_s"] == 12.25
    assert fine["coverage"] == "prefix_stopped_at_first_unsupported_sample"
    assert {:ok, coarse_plan} = run(policy("dip", [5]))
    assert length(coarse_plan["activities"]) == 1
    assert {:ok, fine_plan} = run(p)
    assert fine_plan["activities"] == []
  end

  test "cache identity includes orientation and captured check sessions are reused" do
    cache = runtime(policy("orientation", [5]))

    assert {:infeasible, _, _, cache} =
             Runner.transition(asset(), plan(0), "test", fn _, t -> {:ok, state(t)} end, cache)

    assert {:ok, evidence, cache} =
             Runner.transition(asset(), plan(90), "test", fn _, t -> {:ok, state(t)} end, cache)

    assert evidence["status"] == "supported"
    assert Process.get(:path_prepare_count) == 1
    assert Runner.describe(cache.path)["rule_evaluation_count"] == 4
    assert hd(Runner.describe(cache.path)["captured_rules"])["assumptions"]["revision"] == 1
  end

  test "unknown modes, sample limits and unavailable path coverage cannot become supported" do
    cache = runtime(policy("pass", [1], transition_mode: "not-declared"))

    assert {:unknown, :payload_mode_not_declared, _, _} =
             Runner.transition(asset(), plan(), "test", fn _, t -> {:ok, state(t)} end, cache)

    cache = runtime(policy("pass", [1], samples: 2))

    assert {:unknown, :path_constraint_unknown, e, _} =
             Runner.transition(asset(), plan(), "test", fn _, t -> {:ok, state(t)} end, cache)

    assert hd(e["levels"])["reason"] == "path_sample_budget_exhausted"
    beyond = %{plan() | "source_epoch_s" => -1}

    assert {:unknown, :path_outside_coverage, _, _} =
             Runner.transition(
               asset(),
               beyond,
               "test",
               fn _, t -> {:ok, state(t)} end,
               runtime(policy("pass"))
             )
  end

  test "provider failures and shared path-evaluation budget exhaustion abort instead of looking feasible" do
    assert {:error, {:path_rule_error, "guard", :source_down}, _} =
             Runner.transition(
               asset(),
               plan(),
               "test",
               fn _, t -> {:ok, state(t)} end,
               runtime(policy("error"))
             )

    assert {:error, :path_evaluation_budget_exhausted, _} =
             Runner.transition(
               asset(),
               plan(),
               "test",
               fn _, t -> {:ok, state(t)} end,
               runtime(policy("pass", [1], budget: 1))
             )
  end

  test "service-incompatible activity modes never fulfill a physically eligible request" do
    assert {:ok, report} = run(policy("pass", [1], activity_mode: "off"))
    assert report["activities"] == []
    attempt = hd(hd(report["selection_decisions"])["attitude_assessment"]["attempts"])
    assert attempt["path_checks"]["activity"]["status"] == "violated"
    assert {:ok, report} = run(policy("pass", [1], activity_mode: "unknown"))
    assert hd(report["selection_decisions"])["reason"] == "attitude_feasibility_unknown"
  end

  test "inserting a new activity cannot create an unchecked violating successor slew" do
    future = request("future", start: 40, stop: 50, duration: 5, value: 100)
    earlier = request("earlier", start: 20, stop: 25, duration: 5, angle: 90)
    p = policy("outgoing", [1], requests: ["future", "earlier"])
    assert {:ok, report} = run(p, [future, earlier])
    assert Enum.map(report["activities"], & &1["request_id"]) == ["future"]
    rejected = Enum.find(report["selection_decisions"], &(&1["request_id"] == "earlier"))
    attempt = hd(rejected["attitude_assessment"]["attempts"])
    assert attempt["path_checks"]["outgoing"]["status"] == "violated"

    assert hd(report["attitude_planning"]["transitions"])["path_evidence"]["status"] ==
             "supported"
  end

  test "releasing an asset preserves other cache hits, provenance and exact exhausted-budget behavior" do
    a = asset()
    b = %{a | id: "b"}
    p = policy("pass", [5])
    p = %{p | assets: Map.put(p.assets, b.id, p.assets[a.id])}
    sampler = fn _, t -> {:ok, state(t)} end
    at = fn _, c -> {:ok, {1, 0, 0, 0}, c} end
    cache = %{path: Runner.prepare(p, %{"a" => a, "b" => b}, [request()], nil)}
    assert {:ok, _, cache} = Runner.activity(a, request(), %{}, 20, 22, at, sampler, cache)
    assert {:ok, evidence, cache} = Runner.transition(b, plan(), "test", sampler, cache)
    assert Enum.any?(Map.keys(cache.path.values["a"]), &(elem(&1, 0) == :service_mode))
    b_values = cache.path.values["b"]
    count = cache.path.evaluations
    cache = put_in(cache.path.policy.max_evaluations, count)
    before = Runner.describe(cache.path)
    released = Runner.release_asset(cache, "a")
    refute Map.has_key?(released.path.values, "a")
    assert released.path.values["b"] === b_values
    assert Runner.describe(released.path) === before
    assert {:ok, ^evidence, same} = Runner.transition(b, plan(), "test", sampler, released)
    assert same.path.evaluations == count

    assert {:error, :path_evaluation_budget_exhausted, _} =
             Runner.transition(b, plan(90), "test", sampler, same)

    assert_raise ArgumentError, ~r/path cache for asset a has been released/, fn ->
      Runner.activity(a, request(), %{}, 20, 22, at, sampler, released)
    end

    assert_raise ArgumentError, ~r/path cache for asset a has been released/, fn ->
      Runner.transition(a, plan(), "test", sampler, released)
    end

    finished = Runner.release(released)
    assert finished.path.values == %{}
    assert Runner.describe(finished.path) === before
    assert Runner.release(finished) === finished
    assert Runner.release_asset(%{path: nil}, "a") == %{path: nil}
    assert Runner.release(%{path: nil}) == %{path: nil}
  end

  test "final horizon retires supported, violated and unknown assets while keeping evidence and errors" do
    alias OrbitalDynamics.MissionAnalysis.Attitude.Horizon
    a = asset()
    b = %{a | id: "b"}
    assets = %{"a" => a, "b" => b}
    sampler = fn _, t -> {:ok, state(t)} end
    terminal = %{frame: frame(), quaternion: {1, 0, 0, 0}, mode: "on"}

    h = %{
      start: Epoch.new!(0, :tai),
      stop: Epoch.new!(100, :tai),
      terminals: %{"a" => terminal, "b" => terminal}
    }

    for {kind, status} <- [{"pass", "supported"}, {"dip", "violated"}] do
      p = policy(kind, [0.25])
      p = %{p | assets: Map.put(p.assets, "b", p.assets["a"])}
      ap = attitude(p, h)
      ap = %{ap | assets: Map.put(ap.assets, "b", %{ap.assets["a"] | initial: :unknown})}
      cache = %{path: Runner.prepare(p, assets, [request()], nil)}
      assert {:ok, report, cache} = Horizon.finish(assets, [], ap, sampler, cache)
      assert report["assets"]["a"]["status"] == status
      assert report["assets"]["b"]["status"] == "unknown"

      assert OrbitalDynamics.MissionAnalysis.ReportData.encode(report)["assets"]["a"][
               "terminal_path_evidence"
             ]["levels"] != []

      assert cache.path.values == %{}
      assert cache.path.released_assets == MapSet.new(["a", "b"])
      assert cache.path.evaluations > 0
    end

    p = policy("pass", [5], budget: 1)
    cache = runtime(p)

    assert {:error, :path_evaluation_budget_exhausted} =
             Horizon.finish(
               %{"a" => a},
               [],
               attitude(p, %{h | terminals: %{"a" => terminal}}),
               sampler,
               cache
             )
  end

  test "result admission rejects empty/invalid evidence and keeps unknown separate from supported" do
    assert_raise ArgumentError, fn -> Result.new!([], %{}) end
    assert_raise ArgumentError, fn -> Result.new!([%{"id" => "x", "status" => "safe"}], %{}) end

    r =
      Result.new!(
        [%{"id" => "x", "status" => "supported"}, %{"id" => "y", "status" => "unknown"}],
        %{}
      )

    assert Result.status(r) == "unknown"
  end
end
