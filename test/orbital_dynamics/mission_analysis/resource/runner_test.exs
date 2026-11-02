defmodule OrbitalDynamics.MissionAnalysis.Resource.RunnerTest do
  use ExUnit.Case, async: true
  alias OrbitalDynamics.{Epoch, Frame, StateVector, Trajectory}
  alias OrbitalDynamics.MissionAnalysis
  alias OrbitalDynamics.MissionAnalysis.{Asset, Request, WindowRefinement}

  defmodule Model do
    @behaviour OrbitalDynamics.MissionAnalysis.Model
    def capabilities, do: %{"id" => "resource-test-model"}
    def prepare(r, _, _), do: {:ok, r.parameters, %{}}

    def evaluate(_, _, _),
      do:
        {:ok,
         OrbitalDynamics.MissionAnalysis.Evaluation.new!(
           [%{"id" => "physical", "passed" => true}],
           %{}
         )}

    def activity_mode(_, _),
      do:
        {:ok,
         OrbitalDynamics.MissionAnalysis.Path.Result.new!(
           [%{"id" => "mode", "status" => "supported"}],
           %{}
         )}

    def pointing(state, c, _),
      do:
        {:ok,
         OrbitalDynamics.MissionAnalysis.Attitude.Pointing.new!(
           state.frame,
           OrbitalDynamics.MissionAnalysis.Attitude.Quaternion.increment({0, 0, c["angle"]})
         )}
  end

  defmodule Guard do
    @behaviour OrbitalDynamics.MissionAnalysis.Path.Check
    def prepare(_, _, _), do: {:ok, nil, %{}}

    def evaluate(_, _, _, _),
      do:
        {:ok,
         OrbitalDynamics.MissionAnalysis.Path.Result.new!(
           [%{"id" => "guard", "status" => "supported"}],
           %{}
         )}
  end

  defmodule Fuel do
    @behaviour OrbitalDynamics.MissionAnalysis.Resource.Model
    def prepare(_, context, c) do
      token = make_ref()
      send(self(), {:prepared, token})

      {:ok,
       %{
         token: token,
         fail: c["fail"],
         context: context,
         nonlinear: c["nonlinear"],
         reserve: Map.get(c, "reserve", 0),
         switch_units: c["switch_units"],
         unknown: c["unknown"]
       }, %{"units" => "kg"}}
    end

    def initial(_), do: %{"fuel_kg" => 100.0}
    def boundaries(_), do: []

    def step(state, input, dt, session) do
      send(self(), {:stepped, session.token})

      if session.fail do
        {:error, :resource_provider_down}
      else
        burn = if session.nonlinear, do: state["fuel_kg"] * 0.01, else: 0.1
        next = %{"fuel_kg" => state["fuel_kg"] - dt * burn}
        margin = next["fuel_kg"] - session.reserve

        checks = [
          %{
            "id" => "fuel",
            "status" => if(margin >= 0, do: "supported", else: "violated"),
            "margin" => margin,
            "margin_unit" => if(session.switch_units && input.epoch_s > 0, do: "g", else: "kg")
          }
        ]

        checks =
          if session.unknown,
            do: checks ++ [%{"id" => "dynamics", "status" => "unknown"}],
            else: checks

        {:ok, next, OrbitalDynamics.MissionAnalysis.Path.Result.new!(checks, %{})}
      end
    end
  end

  defp frame, do: Frame.new!(:toy, :toy, :inertial)
  defp state(t), do: StateVector.new!({2000, 0, 0}, {0, 0, 0}, Epoch.new!(t, :tai), frame())

  defp asset,
    do:
      Asset.new!(
        "a",
        %Trajectory{
          scenario_id: "resource",
          states: Enum.map(0..200//5, &state/1),
          assumptions: %{}
        },
        %{Model => %{}},
        %{"tokens" => 10, "energy_wh" => 100}
      )

  defp request(id, opts \\ []) do
    Request.new!(id, Model, :opaque,
      activity_type: "test",
      starts_at_s: Keyword.get(opts, :start, 20),
      ends_at_s: Keyword.get(opts, :stop, 30),
      duration_s: Keyword.get(opts, :duration, 10),
      time_scale: :tai,
      value: Keyword.get(opts, :value, 1),
      parameters: %{"angle" => Keyword.get(opts, :angle, 0)},
      resource_costs: Keyword.get(opts, :costs, %{"tokens" => 1})
    )
  end

  defp battery(opts \\ []) do
    phases =
      ~w(activity brake hold slew_accelerate slew_cruise slew_decelerate settle ramp_to_tracking)

    %{
      "initial_wh" => Keyword.get(opts, :initial, 35),
      "capacity_wh" => 100,
      "reserve_wh" => Keyword.get(opts, :reserve, 10),
      "charge_efficiency" => 1,
      "discharge_efficiency" => 1,
      "phase_load_w" =>
        Map.new(
          phases,
          &{&1,
           if(&1 in ~w(brake slew_accelerate slew_cruise slew_decelerate ramp_to_tracking),
             do: Keyword.get(opts, :motion, 0),
             else: 0
           )}
        ),
      "generation" => Keyword.get(opts, :generation, %{"kind" => "constant", "power_w" => 0})
    }
  end

  defp policy(requests, opts) do
    path =
      OrbitalDynamics.MissionAnalysis.Path.Policy.new!(
        %{
          "a" => %{
            activity_modes: Map.new(requests, &{&1.id, "active"}),
            transition_mode: "transit",
            modes: %{
              "active" => %{"power_load_w" => Keyword.get(opts, :active_load, 360)},
              "transit" => %{"power_load_w" => Keyword.get(opts, :idle_load, 0)},
              "standby" => %{"power_load_w" => Keyword.get(opts, :idle_load, 0)}
            },
            rules: [%{id: "guard", module: Guard, configuration: %{}}]
          }
        },
        sample_steps_s: [5, 1],
        max_evaluations: 100_000,
        max_samples_per_segment: 1000
      )

    resource =
      OrbitalDynamics.MissionAnalysis.Resource.Policy.new!(
        %{
          "a" => [
            %{
              id: "store",
              module:
                Keyword.get(opts, :module, OrbitalDynamics.MissionAnalysis.Resource.Battery),
              configuration: Keyword.get(opts, :configuration, battery(opts)),
              exclusive_cost_keys: ["energy_wh"]
            }
          ]
        },
        sample_steps_s: Keyword.get(opts, :steps, [7, 1]),
        max_intervals_per_asset: Keyword.get(opts, :intervals, 2000),
        max_evaluations: Keyword.get(opts, :budget, 100_000)
      )

    initial = %{
      epoch: Epoch.new!(0, :tai),
      frame: frame(),
      quaternion: {1, 0, 0, 0},
      angular_velocity_deg_s: {0, 0, 0}
    }

    OrbitalDynamics.MissionAnalysis.Attitude.Policy.new!(
      %{
        "a" => %{
          max_rate_deg_s: 10,
          max_accel_deg_s2: 5,
          settling_s: 0,
          initial: initial,
          pointing_configurations: %{Model => %{}}
        }
      },
      profile_step_s: 1,
      derivative_step_s: 0.1,
      search_step_s: 1,
      max_candidate_starts: 128,
      max_evaluations: 100_000,
      path_constraints: path,
      resources: resource,
      horizon: %{
        start: Epoch.new!(0, :tai),
        stop: Epoch.new!(Keyword.get(opts, :stop, 50), :tai),
        terminals: %{"a" => %{frame: frame(), quaternion: {1, 0, 0, 0}, mode: "standby"}}
      }
    )
  end

  defp run(requests, opts \\ []) do
    p = Keyword.get_lazy(opts, :policy, fn -> policy(requests, opts) end)

    refinement =
      WindowRefinement.new!(
        state_at: fn _, t -> {:ok, state(t)} end,
        tracking_lookback_s: 1,
        time_tolerance_s: 0.01,
        max_extra_evaluations: 128
      )

    MissionAnalysis.run(Keyword.get(opts, :assets, [asset()]), requests, nil,
      max_sample_gap_s: 5,
      asset_separation_s: 0,
      window_refinement: refinement,
      attitude: p
    )
  end

  defp energy(report), do: report["attitude_planning"]["resource_feasibility"]
  defp levels(report), do: energy(report)["assets"]["a"]["models"] |> hd() |> Map.fetch!("levels")

  test "constant idle draw integrates analytically across every cadence" do
    assert {:ok, report} =
             run([], stop: 180, idle_load: 100, initial: 10, reserve: 4, steps: [37, 11])

    assert energy(report)["status"] == "supported"
    assert report["attitude_planning"]["planning_status"] == "supported"

    for level <- levels(report) do
      assert_in_delta level["final_state"]["energy_wh"], 5, 1.0e-10
      assert_in_delta level["state_extrema"]["energy_wh"]["min"], 5, 1.0e-10
      assert level["uncovered_intervals"] == []
      assert level["evaluated_through_s"] == 180
      times = Enum.map(level["samples"], & &1["epoch_s"])
      assert Enum.all?(Enum.chunk_every(times, 2, 1, :discard), fn [a, b] -> b > a end)
      assert level["propagated_interval_count"] == level["requested_interval_count"]
      assert level["maximum_requested_interval_s"] <= level["sample_step_s"]
    end
  end

  test "declared charging boundaries and capacity clipping cannot borrow curtailed energy" do
    generation = %{
      "kind" => "piecewise_constant",
      "intervals" => [
        %{"starts_at_s" => 0, "ends_at_s" => 60, "power_w" => 360},
        %{"starts_at_s" => 60, "ends_at_s" => 120, "power_w" => 0}
      ]
    }

    c = %{battery(initial: 8, reserve: 8, generation: generation) | "capacity_wh" => 10}
    assert {:ok, report} = run([], stop: 120, idle_load: 180, configuration: c, steps: [50, 17])
    assert energy(report)["status"] == "violated"
    assert report["attitude_planning"]["horizon_coverage"]["status"] == "supported"

    for l <- levels(report) do
      assert_in_delta l["final_state"]["energy_wh"], 7, 1.0e-10
      assert_in_delta l["final_state"]["curtailed_wh"], 1, 1.0e-10
      assert Enum.any?(l["samples"], &(&1["epoch_s"] == 60))
      assert l["first_issue"]["scope"] == "terminal"
    end
  end

  test "candidate must pay both acquisition and terminal maneuver energy" do
    r = request("r", angle: 90)
    assert {:ok, report} = run([r], motion: 3600, initial: 35, reserve: 10)

    assert length(report["activities"]) == 1

    for l <- levels(report), do: assert_in_delta(l["final_state"]["energy_wh"], 12, 1.0e-8)
    assert report["remaining_resource_budgets"]["a"]["tokens"] == 9

    assert {:ok, report} = run([r], motion: 3600, initial: 30, reserve: 10)
    assert report["activities"] == []
    [decision] = report["selection_decisions"]
    assert decision["reason"] == "planning_start_grid_infeasible"

    assert hd(decision["attitude_assessment"]["attempts"])["reason"] ==
             ":resource_feasibility_violated"

    assert energy(report)["status"] == "supported"
    for l <- levels(report), do: assert(l["final_state"]["energy_wh"] == 30)
  end

  test "insertion replays successors instead of checking only the inserted activity" do
    future = request("future", start: 80, stop: 95, duration: 15, value: 100)
    earlier = request("earlier", start: 20, stop: 35, duration: 15)

    assert {:ok, report} =
             run([earlier, future], stop: 120, active_load: 3600, initial: 25, reserve: 5)

    assert Enum.map(report["activities"], & &1["request_id"]) == ["future"]
    d = Enum.find(report["selection_decisions"], &(&1["request_id"] == "earlier"))
    resource = hd(d["attitude_assessment"]["attempts"])["resource_checks"]
    assert resource["status"] == "violated"

    for l <- hd(resource["models"])["levels"],
        do: assert(l["first_issue"]["scope"] == "activity:future")

    for l <- levels(report), do: assert_in_delta(l["final_state"]["energy_wh"], 10, 1.0e-9)
  end

  test "unknown generation or missing loads stop propagation and preserve the uncovered suffix" do
    gap = %{
      "kind" => "piecewise_constant",
      "intervals" => [%{"starts_at_s" => 0, "ends_at_s" => 20, "power_w" => 0}]
    }

    for opts <- [
          [generation: gap],
          [idle_load: :null],
          [configuration: put_in(battery(), ["phase_load_w"], %{})]
        ] do
      assert {:ok, report} = run([], opts)
      assert energy(report)["status"] == "unknown"

      for l <- levels(report) do
        assert l["final_state"] == :null
        assert l["uncovered_intervals"] != []
        assert l["evaluated_through_s"] < 50
      end
    end

    assert {:ok, report} = run([request("r")], generation: gap)
    assert report["activities"] == []
    assert energy(report)["status"] == "unknown"
  end

  test "idle reserve failure is reported even with no selected requests" do
    assert {:ok, report} = run([], idle_load: 360, initial: 12, reserve: 8)
    assert energy(report)["status"] == "violated"
    assert report["attitude_planning"]["planning_status"] == "violated"

    for l <- levels(report) do
      assert l["uncovered_intervals"] == []
      assert l["first_issue"]["starts_at_s"] <= 40
      assert l["first_issue"]["ends_at_s"] > 40
      assert l["final_state"]["energy_wh"] > 6.99
    end
  end

  test "integration interval limits stay unknown and callback budgets fail closed" do
    assert {:ok, report} = run([], intervals: 2)
    assert energy(report)["status"] == "unknown"
    assert {:error, :resource_evaluation_budget_exhausted} = run([], budget: 1)

    assert {:error, :resource_provider_down} =
             run([], module: Fuel, configuration: %{"fail" => true})
  end

  test "opaque generic model sessions are prepared once and replayed from initial state" do
    assert {:ok, report} = run([request("r")], module: Fuel, configuration: %{}, steps: [7, 3])
    assert_receive {:prepared, token}
    refute_receive {:prepared, _}
    assert_receive {:stepped, ^token}
    for l <- levels(report), do: assert_in_delta(l["final_state"]["fuel_kg"], 95, 1.0e-9)
    assert energy(report)["status"] == "supported"
  end

  test "static consumption cannot double count a managed dynamic resource" do
    assert {:error, {:invalid_mission_analysis, message}} =
             run([request("r", costs: %{"energy_wh" => 1})])

    assert message =~ "overlaps static cost energy_wh"
  end

  test "an idle asset without resource declarations keeps the fleet result unknown" do
    p = policy([], [])
    b = %{asset() | id: "b"}

    p = %{
      p
      | assets: Map.put(p.assets, "b", p.assets["a"]),
        horizon: %{
          p.horizon
          | terminals: Map.put(p.horizon.terminals, "b", p.horizon.terminals["a"])
        },
        path_constraints: %{
          p.path_constraints
          | assets: Map.put(p.path_constraints.assets, "b", p.path_constraints.assets["a"])
        }
    }

    assert {:ok, report} = run([], assets: [asset(), b], policy: p)
    assert report["attitude_planning"]["horizon_coverage"]["status"] == "supported"
    assert energy(report)["status"] == "unknown"
    assert energy(report)["assets"]["a"]["status"] == "supported"
    assert energy(report)["assets"]["b"]["reason"] == "resource_configuration_missing"
  end

  test "a violation on any integration cadence vetoes resource support" do
    assert {:ok, report} =
             run([],
               module: Fuel,
               configuration: %{"nonlinear" => true, "reserve" => 55},
               steps: [50, 1]
             )

    [model] = energy(report)["assets"]["a"]["models"]
    assert model["status"] == "violated"
    assert model["resolution_status"] == "changes_across_tested_steps"
    assert Enum.map(model["levels"], & &1["status"]) == ["violated", "supported"]
  end

  test "generic margins cannot silently change units during a replay" do
    assert {:error, {:invalid_mission_analysis, message}} =
             run([], module: Fuel, configuration: %{"switch_units" => true})

    assert message =~ "margin units changed"
  end

  test "explicit unknown battery parameters stay unknown instead of acquiring defaults" do
    for key <- ~w(initial_wh capacity_wh reserve_wh charge_efficiency discharge_efficiency) do
      c = Map.put(battery(), key, :null)
      assert {:ok, report} = run([], configuration: c)
      assert energy(report)["status"] == "unknown"
      for l <- levels(report), do: assert(l["final_state"] == :null)
    end
  end

  test "a known violation cannot hide unknown dynamics and fabricate a final resource state" do
    assert {:ok, report} =
             run([], module: Fuel, configuration: %{"reserve" => 200, "unknown" => true})

    assert energy(report)["status"] == "violated"

    for l <- levels(report) do
      assert l["final_state"] == :null
      assert l["uncovered_intervals"] != []
      assert l["evaluated_through_s"] == 0
    end
  end
end
